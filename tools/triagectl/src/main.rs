use rusqlite::{params, Connection, OptionalExtension};
use serde::Serialize;
use serde_json::{json, Value};
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

#[derive(Debug, Clone)]
struct Args {
    command: String,
    rest: Vec<String>,
}

#[derive(Debug)]
struct CommandOutput {
    argv: Vec<String>,
    ok: bool,
    exit_code: Option<i32>,
    stdout: String,
    stderr: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct PackageSummary {
    schema_version: u8,
    ts: u64,
    total: CountResult,
    explicit: CountResult,
    dependencies: CountResult,
    orphans: CountResult,
    outdated: CountResult,
    last_event: Option<CommandEvent>,
}

#[derive(Serialize)]
struct CountResult {
    ok: bool,
    count: Option<usize>,
    error: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CommandEvent {
    id: i64,
    command_id: String,
    provider: String,
    argv: Vec<String>,
    ts: u64,
    ok: bool,
    exit_code: Option<i32>,
    risk: String,
    trigger: String,
    stderr: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct OrphansResponse {
    schema_version: u8,
    ts: u64,
    packages: Vec<String>,
    event: CommandEvent,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct PackageListResponse {
    schema_version: u8,
    ts: u64,
    category: String,
    packages: Vec<PackageListItem>,
    event: CommandEvent,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
struct PackageListItem {
    name: String,
    old_version: Option<String>,
    new_version: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct QueueResponse {
    schema_version: u8,
    ts: u64,
    added: usize,
    total_queued: usize,
    packages: Vec<String>,
    source_event: CommandEvent,
    internal_event: CommandEvent,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct DecisionsResponse {
    schema_version: u8,
    items: Vec<ReviewItem>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct EventsResponse {
    schema_version: u8,
    events: Vec<CommandEvent>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ReviewItem {
    package: String,
    created_ts: u64,
    source: String,
    latest_decision: Option<Decision>,
    decisions: Vec<Decision>,
}

#[derive(Serialize, Clone)]
struct Decision {
    ts: u64,
    kind: String,
    note: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct WhyResponse {
    schema_version: u8,
    ts: u64,
    package: String,
    installed: bool,
    version: Option<String>,
    description: Option<String>,
    install_reason: Option<String>,
    url: Option<String>,
    requires: Vec<String>,
    required_by: Vec<String>,
    events: Vec<CommandEvent>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct DecideResponse {
    schema_version: u8,
    package: String,
    decision: Decision,
    event: CommandEvent,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ExportResponse {
    schema_version: u8,
    path: String,
}

fn main() {
    if let Err(err) = run() {
        let _ = writeln!(
            io::stderr(),
            "{}",
            serde_json::to_string(&json!({
                "schemaVersion": 1,
                "ok": false,
                "error": err.to_string()
            }))
            .unwrap_or_else(|_| format!("error: {err}"))
        );
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let args = parse_args()?;
    if args.command == "help" || args.command == "--help" || args.command == "-h" {
        print_help();
        return Ok(());
    }

    let conn = open_db()?;
    init_db(&conn)?;

    match args.command.as_str() {
        "summary" => print_json(&summary(&conn)?)?,
        "packages" => {
            let category = required_arg(&args, "packages requires a category")?;
            print_json(&package_list(&conn, category, "manual")?)?;
        }
        "orphans" => print_json(&orphans(&conn, "manual")?)?,
        "queue-orphans" => print_json(&queue_orphans(&conn)?)?,
        "queue-explicit" => print_json(&queue_explicit(&conn)?)?,
        "why" => {
            let package = required_arg(&args, "why requires a package name")?;
            print_json(&why(&conn, package)?)?;
        }
        "decisions" => print_json(&decisions(&conn)?)?,
        "events" => print_json(&events(&conn, parse_limit(&args.rest, 80)?)?)?,
        "decide" => print_json(&decide(&conn, &args.rest)?)?,
        "export-json" => print_json(&export_json(&conn)?)?,
        "export-md" => print_json(&export_md(&conn)?)?,
        other => return Err(format!("unknown command: {other}").into()),
    }

    Ok(())
}

fn parse_args() -> Result<Args> {
    let mut raw: Vec<String> = env::args().skip(1).collect();
    raw.retain(|arg| arg != "--json");

    let Some(command) = raw.first().cloned() else {
        return Ok(Args {
            command: "help".to_string(),
            rest: Vec::new(),
        });
    };

    Ok(Args {
        command,
        rest: raw.into_iter().skip(1).collect(),
    })
}

fn print_help() {
    println!(
        "\
triagectl - Qreep package triage helper

Usage:
  triagectl summary [--json]
  triagectl packages <updates|orphans|dependencies|explicit|total> [--json]
  triagectl orphans [--json]
  triagectl queue-orphans [--json]
  triagectl queue-explicit [--json]
  triagectl why <package> [--json]
  triagectl decisions [--json]
  triagectl events [--limit N] [--json]
  triagectl decide <package> <keep|investigate|plan-remove|skip> [--note TEXT] [--json]
  triagectl export-json
  triagectl export-md

V1 is read-only against the system. It records local Qreep triage state only."
    );
}

fn required_arg<'a>(args: &'a Args, message: &str) -> Result<&'a str> {
    args.rest
        .first()
        .map(|value| value.as_str())
        .ok_or_else(|| message.into())
}

fn parse_limit(args: &[String], default_limit: usize) -> Result<usize> {
    let Some(index) = args.iter().position(|arg| arg == "--limit") else {
        return Ok(default_limit);
    };

    let Some(value) = args.get(index + 1) else {
        return Err("--limit requires a number".into());
    };

    let limit: usize = value.parse()?;
    Ok(limit.clamp(1, 500))
}

fn print_json<T: Serialize>(value: &T) -> Result<()> {
    println!("{}", serde_json::to_string_pretty(value)?);
    Ok(())
}

fn now_ts() -> Result<u64> {
    Ok(SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs())
}

fn data_dir() -> Result<PathBuf> {
    if let Ok(dir) = env::var("QREEP_TRIAGE_DIR") {
        return Ok(PathBuf::from(dir));
    }

    let home = env::var("HOME")?;
    Ok(PathBuf::from(home).join("Data/sqlite/qreep/triage"))
}

fn open_db() -> Result<Connection> {
    let dir = data_dir()?;
    fs::create_dir_all(&dir)?;
    Ok(Connection::open(dir.join("triage.db"))?)
}

fn init_db(conn: &Connection) -> Result<()> {
    conn.execute_batch(
        "\
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS command_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            command_id TEXT NOT NULL,
            provider TEXT NOT NULL,
            argv_json TEXT NOT NULL,
            ts INTEGER NOT NULL,
            ok INTEGER NOT NULL,
            exit_code INTEGER,
            risk TEXT NOT NULL,
            trigger TEXT NOT NULL,
            stdout TEXT,
            stderr TEXT
        );

        CREATE TABLE IF NOT EXISTS review_items (
            package TEXT PRIMARY KEY,
            created_ts INTEGER NOT NULL,
            source TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS decisions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            package TEXT NOT NULL,
            ts INTEGER NOT NULL,
            kind TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY(package) REFERENCES review_items(package)
        );

        CREATE INDEX IF NOT EXISTS idx_decisions_package_ts
            ON decisions(package, ts DESC);
        CREATE INDEX IF NOT EXISTS idx_command_events_ts
            ON command_events(ts DESC);

        PRAGMA user_version = 1;
        ",
    )?;
    Ok(())
}

fn run_command(argv: &[&str]) -> CommandOutput {
    let mut command = Command::new(argv[0]);
    command.args(&argv[1..]);

    match command.output() {
        Ok(output) => CommandOutput {
            argv: argv.iter().map(|part| part.to_string()).collect(),
            ok: output.status.success(),
            exit_code: output.status.code(),
            stdout: String::from_utf8_lossy(&output.stdout).to_string(),
            stderr: String::from_utf8_lossy(&output.stderr).to_string(),
        },
        Err(err) => CommandOutput {
            argv: argv.iter().map(|part| part.to_string()).collect(),
            ok: false,
            exit_code: None,
            stdout: String::new(),
            stderr: err.to_string(),
        },
    }
}

fn record_event(
    conn: &Connection,
    command_id: &str,
    provider: &str,
    output: &CommandOutput,
    ts: u64,
    trigger: &str,
    risk: &str,
) -> Result<CommandEvent> {
    let argv_json = serde_json::to_string(&output.argv)?;
    conn.execute(
        "\
        INSERT INTO command_events
            (command_id, provider, argv_json, ts, ok, exit_code, risk, trigger, stdout, stderr)
        VALUES
            (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)
        ",
        params![
            command_id,
            provider,
            argv_json,
            ts as i64,
            output.ok as i64,
            output.exit_code,
            risk,
            trigger,
            empty_to_none(&output.stdout),
            empty_to_none(&output.stderr),
        ],
    )?;

    Ok(CommandEvent {
        id: conn.last_insert_rowid(),
        command_id: command_id.to_string(),
        provider: provider.to_string(),
        argv: output.argv.clone(),
        ts,
        ok: output.ok,
        exit_code: output.exit_code,
        risk: risk.to_string(),
        trigger: trigger.to_string(),
        stderr: empty_to_none(&output.stderr).map(str::to_string),
    })
}

fn record_internal_event(
    conn: &Connection,
    command_id: &str,
    argv: Vec<String>,
    ts: u64,
    trigger: &str,
) -> Result<CommandEvent> {
    let output = CommandOutput {
        argv,
        ok: true,
        exit_code: Some(0),
        stdout: String::new(),
        stderr: String::new(),
    };
    record_event(
        conn,
        command_id,
        "internal",
        &output,
        ts,
        trigger,
        "local-write",
    )
}

fn empty_to_none(value: &str) -> Option<&str> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed)
    }
}

fn count_lines_output(
    conn: &Connection,
    command_id: &str,
    argv: &[&str],
    trigger: &str,
) -> Result<CountResult> {
    let ts = now_ts()?;
    let output = run_command(argv);
    let event = record_event(conn, command_id, argv[0], &output, ts, trigger, "read-only")?;

    if output.ok {
        Ok(CountResult {
            ok: true,
            count: Some(non_empty_lines(&output.stdout).len()),
            error: None,
        })
    } else {
        Ok(CountResult {
            ok: false,
            count: None,
            error: event.stderr,
        })
    }
}

fn non_empty_lines(output: &str) -> Vec<String> {
    output
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .map(str::to_string)
        .collect()
}

fn summary(conn: &Connection) -> Result<PackageSummary> {
    let ts = now_ts()?;
    let total = count_lines_output(conn, "pacman.installed", &["pacman", "-Qq"], "summary")?;
    let explicit = count_lines_output(conn, "pacman.explicit", &["pacman", "-Qqe"], "summary")?;
    let dependencies =
        count_lines_output(conn, "pacman.dependencies", &["pacman", "-Qqd"], "summary")?;
    let orphans = count_lines_output(conn, "pacman.orphans", &["pacman", "-Qtdq"], "summary")?;
    let outdated = outdated_count(conn)?;

    Ok(PackageSummary {
        schema_version: 1,
        ts,
        total,
        explicit,
        dependencies,
        orphans,
        outdated,
        last_event: last_event(conn)?,
    })
}

fn outdated_count(conn: &Connection) -> Result<CountResult> {
    let ts = now_ts()?;
    let mut output = run_command(&["checkupdates", "--nocolor"]);
    let mut command_id = "checkupdates.outdated";

    if !output.ok && output.exit_code.is_none() {
        output = run_command(&["pacman", "-Qu"]);
        command_id = "pacman.outdated";
    }

    let event = record_event(
        conn,
        command_id,
        output.argv[0].as_str(),
        &output,
        ts,
        "summary",
        "read-only",
    )?;
    if output.ok {
        Ok(CountResult {
            ok: true,
            count: Some(non_empty_lines(&output.stdout).len()),
            error: None,
        })
    } else {
        Ok(CountResult {
            ok: false,
            count: None,
            error: event.stderr,
        })
    }
}

fn orphans(conn: &Connection, trigger: &str) -> Result<OrphansResponse> {
    let ts = now_ts()?;
    let output = run_command(&["pacman", "-Qtdq"]);
    let event = record_event(
        conn,
        "pacman.orphans",
        "pacman",
        &output,
        ts,
        trigger,
        "read-only",
    )?;
    let mut packages = if output.ok {
        non_empty_lines(&output.stdout)
    } else {
        Vec::new()
    };
    packages.sort();
    packages.dedup();

    Ok(OrphansResponse {
        schema_version: 1,
        ts,
        packages,
        event,
    })
}

fn package_list(conn: &Connection, category: &str, trigger: &str) -> Result<PackageListResponse> {
    let ts = now_ts()?;
    let normalized = normalize_category(category)?;
    let (command_id, argv) = package_list_command(&normalized);
    let mut output = run_command(&argv);
    let mut final_command_id = command_id;

    if normalized == "updates" && !output.ok && output.exit_code.is_none() {
        let fallback = package_list_command("updates-fallback");
        final_command_id = fallback.0;
        output = run_command(&fallback.1);
    }

    let event = record_event(
        conn,
        final_command_id,
        output.argv[0].as_str(),
        &output,
        ts,
        trigger,
        "read-only",
    )?;
    let mut packages = if output.ok {
        parse_package_items(&normalized, &output.stdout)
    } else {
        Vec::new()
    };
    packages.sort_by(|left, right| left.name.cmp(&right.name));
    packages.dedup_by(|left, right| left.name == right.name);

    Ok(PackageListResponse {
        schema_version: 1,
        ts,
        category: normalized,
        packages,
        event,
    })
}

fn normalize_category(category: &str) -> Result<String> {
    match category {
        "updates" | "outdated" => Ok("updates".to_string()),
        "orphans" => Ok("orphans".to_string()),
        "dependencies" | "deps" => Ok("dependencies".to_string()),
        "explicit" => Ok("explicit".to_string()),
        "total" | "all" => Ok("total".to_string()),
        _ => Err(format!("unknown package category: {category}").into()),
    }
}

fn package_list_command(category: &str) -> (&'static str, Vec<&'static str>) {
    match category {
        "updates" => ("checkupdates.outdated", vec!["checkupdates", "--nocolor"]),
        "updates-fallback" => ("pacman.outdated", vec!["pacman", "-Qu"]),
        "orphans" => ("pacman.orphans", vec!["pacman", "-Qtdq"]),
        "dependencies" => ("pacman.dependencies", vec!["pacman", "-Qqd"]),
        "explicit" => ("pacman.explicit", vec!["pacman", "-Qqe"]),
        _ => ("pacman.installed", vec!["pacman", "-Qq"]),
    }
}

fn parse_package_items(category: &str, stdout: &str) -> Vec<PackageListItem> {
    if category != "updates" {
        return non_empty_lines(stdout)
            .into_iter()
            .map(|name| PackageListItem {
                name,
                old_version: None,
                new_version: None,
            })
            .collect();
    }

    stdout.lines().filter_map(parse_update_line).collect()
}

fn parse_update_line(line: &str) -> Option<PackageListItem> {
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.is_empty() {
        return None;
    }

    if parts.len() >= 4 && parts[2] == "->" {
        return Some(PackageListItem {
            name: parts[0].to_string(),
            old_version: Some(parts[1].to_string()),
            new_version: Some(parts[3].to_string()),
        });
    }

    Some(PackageListItem {
        name: parts[0].to_string(),
        old_version: None,
        new_version: parts.get(1).map(|version| (*version).to_string()),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_checkupdates_versions() {
        let item = parse_update_line("luajit 2.1.1784360928+14d8a7a-1 -> 2.1.1784528234-1")
            .expect("update row");

        assert_eq!(item.name, "luajit");
        assert_eq!(
            item.old_version.as_deref(),
            Some("2.1.1784360928+14d8a7a-1")
        );
        assert_eq!(item.new_version.as_deref(), Some("2.1.1784528234-1"));
    }
}

fn queue_orphans(conn: &Connection) -> Result<QueueResponse> {
    let scan = orphans(conn, "queue-orphans")?;
    queue_packages(conn, "orphans", scan.packages, scan.ts, scan.event)
}

fn queue_explicit(conn: &Connection) -> Result<QueueResponse> {
    let scan = package_list(conn, "explicit", "queue-explicit")?;
    let packages = scan.packages.into_iter().map(|item| item.name).collect();
    queue_packages(conn, "explicit", packages, scan.ts, scan.event)
}

// Already-queued packages keep their original source and decisions.
fn queue_packages(
    conn: &Connection,
    source: &str,
    packages: Vec<String>,
    ts: u64,
    source_event: CommandEvent,
) -> Result<QueueResponse> {
    let mut added = 0usize;

    for package in &packages {
        let changed = conn.execute(
            "\
            INSERT OR IGNORE INTO review_items (package, created_ts, source)
            VALUES (?1, ?2, ?3)
            ",
            params![package, ts as i64, source],
        )?;
        added += changed;
    }

    let trigger = format!("queue-{source}");
    let internal_event = record_internal_event(
        conn,
        &format!("internal.queue_{source}"),
        vec![trigger.clone(), format!("added={added}")],
        ts,
        &trigger,
    )?;

    let total_queued = conn.query_row("SELECT COUNT(*) FROM review_items", [], |row| {
        row.get::<_, i64>(0)
    })? as usize;

    Ok(QueueResponse {
        schema_version: 1,
        ts,
        added,
        total_queued,
        packages,
        source_event,
        internal_event,
    })
}

fn why(conn: &Connection, package: &str) -> Result<WhyResponse> {
    let ts = now_ts()?;
    let info_output = run_command(&["pacman", "-Qi", package]);
    let info_event = record_event(
        conn,
        "pacman.info",
        "pacman",
        &info_output,
        ts,
        "why",
        "read-only",
    )?;
    let requires_output = run_command(&["pactree", "-d", "1", package]);
    let requires_event = record_event(
        conn,
        "pactree.deps_direct",
        "pactree",
        &requires_output,
        ts,
        "why",
        "read-only",
    )?;
    let reverse_deps_output = run_command(&["pactree", "-r", "-d", "1", package]);
    let reverse_deps_event = record_event(
        conn,
        "pactree.reverse_deps_direct",
        "pactree",
        &reverse_deps_output,
        ts,
        "why",
        "read-only",
    )?;

    let info = if info_output.ok {
        parse_pacman_info(&info_output.stdout)
    } else {
        PackageInfo::default()
    };

    let requires = if requires_output.ok {
        parse_pactree_direct_children(package, &requires_output.stdout)
    } else {
        Vec::new()
    };

    let required_by = if reverse_deps_output.ok {
        parse_pactree_direct_children(package, &reverse_deps_output.stdout)
    } else {
        Vec::new()
    };

    Ok(WhyResponse {
        schema_version: 1,
        ts,
        package: package.to_string(),
        installed: info_output.ok,
        version: info.version,
        description: info.description,
        install_reason: info.install_reason,
        url: info.url,
        requires,
        required_by,
        events: vec![info_event, requires_event, reverse_deps_event],
    })
}

#[derive(Default)]
struct PackageInfo {
    version: Option<String>,
    description: Option<String>,
    install_reason: Option<String>,
    url: Option<String>,
}

fn parse_pacman_info(output: &str) -> PackageInfo {
    let mut info = PackageInfo::default();

    for line in output.lines() {
        let Some((key, value)) = line.split_once(':') else {
            continue;
        };
        let value = value.trim();
        match key.trim() {
            "Version" => info.version = Some(value.to_string()),
            "Description" => info.description = Some(value.to_string()),
            "Install Reason" => info.install_reason = Some(value.to_string()),
            "URL" => info.url = Some(value.to_string()),
            _ => {}
        }
    }

    info
}

fn parse_pactree_direct_children(package: &str, output: &str) -> Vec<String> {
    let mut deps = Vec::new();
    for line in output.lines().skip(1) {
        let cleaned = line
            .trim()
            .trim_start_matches(|c: char| !c.is_alphanumeric() && c != '_' && c != '-' && c != '+')
            .split_whitespace()
            .next()
            .unwrap_or("")
            .trim();
        if !cleaned.is_empty() && cleaned != package {
            deps.push(cleaned.to_string());
        }
    }
    deps.sort();
    deps.dedup();
    deps
}

fn decisions(conn: &Connection) -> Result<DecisionsResponse> {
    let mut stmt = conn.prepare(
        "\
        SELECT package, created_ts, source
        FROM review_items
        ORDER BY package
        ",
    )?;
    let items = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, i64>(1)? as u64,
                row.get::<_, String>(2)?,
            ))
        })?
        .collect::<std::result::Result<Vec<_>, _>>()?;

    let mut out = Vec::new();
    for (package, created_ts, source) in items {
        let history = decision_history(conn, &package)?;
        let latest_decision = history.last().cloned();
        out.push(ReviewItem {
            package,
            created_ts,
            source,
            latest_decision,
            decisions: history,
        });
    }

    Ok(DecisionsResponse {
        schema_version: 1,
        items: out,
    })
}

fn decision_history(conn: &Connection, package: &str) -> Result<Vec<Decision>> {
    let mut stmt = conn.prepare(
        "\
        SELECT ts, kind, note
        FROM decisions
        WHERE package = ?1
        ORDER BY ts ASC, id ASC
        ",
    )?;
    let decisions = stmt
        .query_map(params![package], |row| {
            Ok(Decision {
                ts: row.get::<_, i64>(0)? as u64,
                kind: row.get(1)?,
                note: row.get(2)?,
            })
        })?
        .collect::<std::result::Result<Vec<_>, _>>()?;

    Ok(decisions)
}

fn decide(conn: &Connection, args: &[String]) -> Result<DecideResponse> {
    if args.len() < 2 {
        return Err("decide requires <package> <keep|investigate|plan-remove|skip>".into());
    }

    let package = &args[0];
    let kind = &args[1];
    validate_decision_kind(kind)?;
    let note = parse_note(args);
    let ts = now_ts()?;

    conn.execute(
        "\
        INSERT OR IGNORE INTO review_items (package, created_ts, source)
        VALUES (?1, ?2, 'manual')
        ",
        params![package, ts as i64],
    )?;
    conn.execute(
        "\
        INSERT INTO decisions (package, ts, kind, note)
        VALUES (?1, ?2, ?3, ?4)
        ",
        params![package, ts as i64, kind, note],
    )?;

    let mut argv = vec!["decide".to_string(), package.to_string(), kind.to_string()];
    if let Some(note_text) = note.clone() {
        argv.push("--note".to_string());
        argv.push(note_text);
    }
    let event = record_internal_event(conn, "internal.decide", argv, ts, "decide")?;

    let decision = Decision {
        ts,
        kind: kind.to_string(),
        note,
    };

    Ok(DecideResponse {
        schema_version: 1,
        package: package.to_string(),
        decision,
        event,
    })
}

fn validate_decision_kind(kind: &str) -> Result<()> {
    match kind {
        "keep" | "investigate" | "plan-remove" | "skip" => Ok(()),
        _ => Err(format!("unknown decision kind: {kind}").into()),
    }
}

fn parse_note(args: &[String]) -> Option<String> {
    args.iter()
        .position(|arg| arg == "--note")
        .and_then(|index| args.get(index + 1))
        .cloned()
}

fn export_json(conn: &Connection) -> Result<ExportResponse> {
    let dir = data_dir()?.join("exports");
    fs::create_dir_all(&dir)?;
    let path = dir.join(format!("triage-export-{}.json", now_ts()?));
    let payload = json!({
        "schemaVersion": 1,
        "decisions": decisions(conn)?,
        "events": all_events(conn)?,
    });
    fs::write(&path, serde_json::to_vec_pretty(&payload)?)?;
    Ok(ExportResponse {
        schema_version: 1,
        path: path.display().to_string(),
    })
}

fn export_md(conn: &Connection) -> Result<ExportResponse> {
    let dir = data_dir()?.join("exports");
    fs::create_dir_all(&dir)?;
    let path = dir.join(format!("triage-export-{}.md", now_ts()?));
    let decisions = decisions(conn)?;
    let mut out = String::from("# Qreep Triage Export\n\n");

    for item in decisions.items {
        out.push_str(&format!("## {}\n\n", item.package));
        out.push_str(&format!("- Source: `{}`\n", item.source));
        if let Some(decision) = item.latest_decision {
            out.push_str(&format!("- Latest decision: `{}`\n", decision.kind));
            if let Some(note) = decision.note {
                out.push_str(&format!("- Note: {}\n", note));
            }
        } else {
            out.push_str("- Latest decision: none\n");
        }
        out.push('\n');
    }

    fs::write(&path, out)?;
    Ok(ExportResponse {
        schema_version: 1,
        path: path.display().to_string(),
    })
}

fn events(conn: &Connection, limit: usize) -> Result<EventsResponse> {
    let mut stmt = conn.prepare(
        "\
        SELECT id, command_id, provider, argv_json, ts, ok, exit_code, risk, trigger, stderr
        FROM command_events
        ORDER BY id DESC
        LIMIT ?1
        ",
    )?;
    let events = stmt
        .query_map([limit as i64], |row| {
            let argv_json: String = row.get(3)?;
            let argv: Vec<String> = serde_json::from_str(&argv_json).unwrap_or_default();
            Ok(CommandEvent {
                id: row.get(0)?,
                command_id: row.get(1)?,
                provider: row.get(2)?,
                argv,
                ts: row.get::<_, i64>(4)? as u64,
                ok: row.get::<_, i64>(5)? != 0,
                exit_code: row.get(6)?,
                risk: row.get(7)?,
                trigger: row.get(8)?,
                stderr: row.get(9)?,
            })
        })?
        .collect::<std::result::Result<Vec<_>, _>>()?;

    Ok(EventsResponse {
        schema_version: 1,
        events,
    })
}

fn all_events(conn: &Connection) -> Result<Vec<Value>> {
    let mut stmt = conn.prepare(
        "\
        SELECT id, command_id, provider, argv_json, ts, ok, exit_code, risk, trigger, stderr
        FROM command_events
        ORDER BY ts ASC, id ASC
        ",
    )?;
    let events = stmt
        .query_map([], |row| {
            let argv_json: String = row.get(3)?;
            let argv: Vec<String> = serde_json::from_str(&argv_json).unwrap_or_default();
            Ok(json!({
                "id": row.get::<_, i64>(0)?,
                "commandId": row.get::<_, String>(1)?,
                "provider": row.get::<_, String>(2)?,
                "argv": argv,
                "ts": row.get::<_, i64>(4)?,
                "ok": row.get::<_, i64>(5)? != 0,
                "exitCode": row.get::<_, Option<i32>>(6)?,
                "risk": row.get::<_, String>(7)?,
                "trigger": row.get::<_, String>(8)?,
                "stderr": row.get::<_, Option<String>>(9)?,
            }))
        })?
        .collect::<std::result::Result<Vec<_>, _>>()?;

    Ok(events)
}

fn last_event(conn: &Connection) -> Result<Option<CommandEvent>> {
    conn.query_row(
        "\
        SELECT id, command_id, provider, argv_json, ts, ok, exit_code, risk, trigger, stderr
        FROM command_events
        ORDER BY id DESC
        LIMIT 1
        ",
        [],
        |row| {
            let argv_json: String = row.get(3)?;
            let argv: Vec<String> = serde_json::from_str(&argv_json).unwrap_or_default();
            Ok(CommandEvent {
                id: row.get(0)?,
                command_id: row.get(1)?,
                provider: row.get(2)?,
                argv,
                ts: row.get::<_, i64>(4)? as u64,
                ok: row.get::<_, i64>(5)? != 0,
                exit_code: row.get(6)?,
                risk: row.get(7)?,
                trigger: row.get(8)?,
                stderr: row.get(9)?,
            })
        },
    )
    .optional()
    .map_err(Into::into)
}
