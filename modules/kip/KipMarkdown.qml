import QtQuick

// Markdown → Qt rich text, KIP-styled. Qt's own MarkdownText renders, but
// gives no say over spacing or code blocks; this converts the subset models
// actually produce: paragraphs, headings, nested lists, fenced and inline
// code, bold/italic, links, blockquotes and rules. Unfinished markdown (an
// open fence mid-stream) renders as far as it goes instead of breaking.
//
// toRich() returns { html, codeBlocks }. Each fenced block gets a
// "kip-copy:<n>" link; codeBlocks[n] is its exact original text.
QtObject {
    id: rootKipMarkdown

    required property QtObject kipTheme

    function toRich(markdown) {
        const t = kipTheme;
        const lines = String(markdown || "").replace(/\r\n?/g, "\n").split("\n");
        const out = [];
        const codeBlocks = [];
        // Open lists as a stack of { type: "ul"|"ol", indent }.
        const lists = [];
        let paragraph = [];
        let index = 0;

        function flushParagraph() {
            if (paragraph.length === 0)
                return;
            out.push("<p style=\"margin-top:0px; margin-bottom:" + t.answerParagraphGap + "px; line-height:" + t.answerLineHeight + "%;\">" + inline(paragraph.join(" ")) + "</p>");
            paragraph = [];
        }

        function closeLists(toIndent) {
            while (lists.length > 0 && lists[lists.length - 1].indent >= toIndent)
                out.push("</" + lists.pop().type + ">");
        }

        while (index < lines.length) {
            const line = lines[index];
            const fence = /^\s*(```|~~~)\s*([\w+#.-]*)\s*$/.exec(line);

            if (fence) {
                flushParagraph();
                closeLists(0);

                const body = [];

                index++;
                while (index < lines.length && !new RegExp("^\\s*" + fence[1].replace(/~/g, "\\~") + "\\s*$").test(lines[index])) {
                    body.push(lines[index]);
                    index++;
                }
                index++;

                const code = body.join("\n");

                codeBlocks.push(code);
                out.push(codeBlock(code, fence[2], codeBlocks.length - 1));
                continue;
            }

            if (/^\s*$/.test(line)) {
                flushParagraph();
                index++;
                continue;
            }

            const heading = /^(#{1,6})\s+(.*?)\s*#*\s*$/.exec(line);

            if (heading) {
                flushParagraph();
                closeLists(0);
                // Restrained: h1/h2 a touch larger, the rest body-size bold.
                const size = heading[1].length <= 2 ? t.answerPixelSize + 2 : t.answerPixelSize;
                out.push("<p style=\"margin-top:" + t.answerHeadingTopGap + "px; margin-bottom:" + t.answerHeadingBottomGap + "px; font-size:" + size + "px; font-weight:600; color:" + t.answerHeadingColor + ";\">" + inline(heading[2]) + "</p>");
                index++;
                continue;
            }

            if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(line)) {
                flushParagraph();
                closeLists(0);
                out.push("<hr/>");
                index++;
                continue;
            }

            const quote = /^\s*>\s?(.*)$/.exec(line);

            if (quote) {
                flushParagraph();
                closeLists(0);

                const quoted = [quote[1]];

                index++;
                while (index < lines.length && /^\s*>\s?/.test(lines[index])) {
                    quoted.push(lines[index].replace(/^\s*>\s?/, ""));
                    index++;
                }

                out.push("<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"margin-bottom:" + t.answerParagraphGap + "px;\"><tr><td width=\"3\" bgcolor=\"" + t.answerQuoteBarColor + "\"></td><td style=\"padding-left:10px; color:" + t.answerQuoteColor + ";\">" + inline(quoted.join(" ")) + "</td></tr></table>");
                continue;
            }

            const item = /^(\s*)([-*+]|\d+[.)])\s+(.*)$/.exec(line);

            if (item) {
                flushParagraph();

                const indent = item[1].replace(/\t/g, "    ").length;
                const type = /\d/.test(item[2]) ? "ol" : "ul";

                closeLists(indent + 1);
                // Same depth, other kind ("- a" then "1. b"): a new list.
                if (lists.length > 0 && lists[lists.length - 1].indent === indent && lists[lists.length - 1].type !== type)
                    out.push("</" + lists.pop().type + ">");
                if (lists.length === 0 || lists[lists.length - 1].indent < indent) {
                    lists.push({
                        type: type,
                        indent: indent
                    });
                    // Qt nests lists by indent level, not by element nesting.
                    out.push("<" + type + " style=\"margin-top:0px; margin-bottom:" + (lists.length > 1 ? 0 : t.answerParagraphGap) + "px; -qt-list-indent:" + lists.length + ";\">");
                }

                // Continuation lines indented under the item join it.
                const text = [item[3]];

                index++;
                while (index < lines.length && /^\s{2,}\S/.test(lines[index]) && !/^(\s*)([-*+]|\d+[.)])\s+/.test(lines[index]) && !/^\s*(```|~~~)/.test(lines[index])) {
                    text.push(lines[index].trim());
                    index++;
                }

                out.push("<li style=\"margin-bottom:" + t.answerListItemGap + "px; line-height:" + t.answerLineHeight + "%;\">" + inline(text.join(" ")) + "</li>");
                continue;
            }

            if (lists.length > 0 && !/^\s/.test(line))
                closeLists(0);

            paragraph.push(line.trim());
            index++;
        }

        flushParagraph();
        closeLists(0);

        return {
            html: out.join("\n"),
            codeBlocks: codeBlocks
        };
    }

    // A one-cell table is the only reliable block background in Qt rich text.
    function codeBlock(code, language, number) {
        const t = kipTheme;
        const label = language.length > 0 ? escapeHtml(language) : "code";

        return "<table width=\"100%\" cellspacing=\"0\" cellpadding=\"8\" bgcolor=\"" + t.answerCodeBackground + "\" style=\"margin-top:2px; margin-bottom:" + (t.answerParagraphGap + 2) + "px;\">"
            + "<tr><td><span style=\"font-size:" + (t.metaPixelSize) + "px; color:" + t.answerMetaColor + ";\">" + label + "</span>"
            + " &nbsp; <a href=\"kip-copy:" + number + "\" style=\"font-size:" + t.metaPixelSize + "px; color:" + t.answerLinkColor + "; text-decoration:none;\">Copy</a>"
            + "<pre style=\"margin-top:4px; margin-bottom:0px; font-family:'" + t.monoFontFamily + "'; font-size:" + (t.answerPixelSize - 1) + "px; color:" + t.answerCodeColor + ";\">" + escapeHtml(code) + "</pre></td></tr></table>";
    }

    // Escape first, then add markup, so model text can never inject HTML.
    function inline(text) {
        const t = kipTheme;
        const spans = [];
        // Pull code spans out before anything else touches their content.
        let html = escapeHtml(text).replace(/`([^`]+)`/g, (match, code) => {
            spans.push("<span style=\"font-family:'" + t.monoFontFamily + "'; font-size:" + (t.answerPixelSize - 1) + "px; background-color:" + t.answerInlineCodeBackground + "; color:" + t.answerCodeColor + ";\">&nbsp;" + code + "&nbsp;</span>");
            return "\u0000" + (spans.length - 1) + "\u0000";
        });

        html = html.replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, (match, label, url) => "<a href=\"" + url + "\" style=\"color:" + t.answerLinkColor + ";\">" + label + "</a>");
        html = html.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>").replace(/__([^_]+)__/g, "<b>$1</b>");
        html = html.replace(/(^|[^*\w])\*([^*\s][^*]*)\*(?!\w)/g, "$1<i>$2</i>").replace(/(^|[^_\w])_([^_\s][^_]*)_(?!\w)/g, "$1<i>$2</i>");

        return html.replace(/\u0000(\d+)\u0000/g, (match, number) => spans[Number(number)]);
    }

    function escapeHtml(text) {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    // Plain-text copy of the whole answer: markdown markers stripped, code kept.
    function toPlain(markdown) {
        return String(markdown || "").replace(/^\s*(```|~~~)[\w+#.-]*\s*$/gm, "").replace(/^#{1,6}\s+/gm, "").replace(/\*\*([^*]+)\*\*/g, "$1").replace(/`([^`\n]+)`/g, "$1").replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, "$1 ($2)").replace(/\n{3,}/g, "\n\n").trim();
    }
}
