import QtQuick

// A default name for a colour: the nearest CSS named colour, so a fresh
// pick reads "Rosy Brown" instead of "#bc8f8f". Rename it in a palette when
// you know better (American Brown, Timberwolf, ...). Values come from Qt's
// own colour parser, so only the names are listed here.
QtObject {
    readonly property var cssNames: [
        "aliceblue", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "black",
        "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "cadetblue", "chartreuse",
        "chocolate", "coral", "cornflowerblue", "cornsilk", "crimson", "darkblue", "darkcyan",
        "darkgoldenrod", "darkgray", "darkgreen", "darkkhaki", "darkmagenta", "darkolivegreen",
        "darkorange", "darkorchid", "darkred", "darksalmon", "darkseagreen", "darkslateblue",
        "darkslategray", "darkturquoise", "darkviolet", "deeppink", "deepskyblue", "dimgray",
        "dodgerblue", "firebrick", "floralwhite", "forestgreen", "gainsboro", "ghostwhite", "gold",
        "goldenrod", "gray", "green", "greenyellow", "honeydew", "hotpink", "indianred", "indigo",
        "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lemonchiffon", "lightblue",
        "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray", "lightgreen", "lightpink",
        "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightsteelblue",
        "lightyellow", "lime", "limegreen", "linen", "maroon", "mediumaquamarine", "mediumblue",
        "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen",
        "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream", "mistyrose", "moccasin",
        "navajowhite", "navy", "oldlace", "olive", "olivedrab", "orange", "orangered", "orchid",
        "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff",
        "peru", "pink", "plum", "powderblue", "purple", "red", "rosybrown",
        "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell", "sienna",
        "silver", "skyblue", "slateblue", "slategray", "snow", "springgreen", "steelblue", "tan",
        "teal", "thistle", "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow",
        "yellowgreen"
    ]

    // "darkslateblue" -> "Dark Slate Blue"
    readonly property var pretty: ({
            "dark": "Dark ", "light": "Light ", "medium": "Medium ", "pale": "Pale ", "deep": "Deep ",
            "lemon": "Lemon ", "olive": "Olive ", "navajo": "Navajo ", "ghost": "Ghost ", "floral": "Floral ",
            "rosy": "Rosy ", "royal": "Royal ", "saddle": "Saddle ", "sandy": "Sandy ", "slate": "Slate ",
            "spring": "Spring ", "steel": "Steel ", "yellow": "Yellow ", "blanched": "Blanched ",
            "cadet": "Cadet ", "cornflower": "Cornflower ", "dodger": "Dodger ", "fire": "Fire ",
            "forest": "Forest ", "green": "Green ", "hot": "Hot ", "indian": "Indian ", "lavender": "Lavender ",
            "lawn": "Lawn ", "lime": "Lime ", "midnight": "Midnight ", "mint": "Mint ", "misty": "Misty ",
            "old": "Old ", "orange": "Orange ", "papaya": "Papaya ", "peach": "Peach ", "powder": "Powder ",
            "sea": "Sea ", "sky": "Sky ", "white": "White ", "antique": "Antique ",
            "alice": "Alice ", "blue": "Blue ", "burly": "Burly ", "dim": "Dim "
        })

    property var table: []

    Component.onCompleted: {
        table = cssNames.map(name => {
            const c = Qt.color(name);
            return { name: name, rgb: [c.r * 255, c.g * 255, c.b * 255] };
        });
    }

    // Weighted RGB distance ("redmean"): cheap and close enough for naming.
    function nearest(rgb) {
        let best = "";
        let bestDistance = Infinity;

        for (const entry of table) {
            const rMean = (rgb[0] + entry.rgb[0]) / 2;
            const dr = rgb[0] - entry.rgb[0];
            const dg = rgb[1] - entry.rgb[1];
            const db = rgb[2] - entry.rgb[2];
            const distance = (2 + rMean / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rMean) / 256) * db * db;

            if (distance < bestDistance) {
                bestDistance = distance;
                best = entry.name;
            }
        }
        return prettify(best);
    }

    function prettify(name) {
        let rest = name;
        let out = "";

        // Peel known prefixes off the front, longest first.
        const prefixes = Object.keys(pretty).sort((a, b) => b.length - a.length);
        let changed = true;
        while (changed && rest.length > 0) {
            changed = false;
            for (const prefix of prefixes) {
                if (rest.indexOf(prefix) === 0 && rest.length > prefix.length) {
                    out += pretty[prefix];
                    rest = rest.slice(prefix.length);
                    changed = true;
                    break;
                }
            }
        }
        return out + rest.charAt(0).toUpperCase() + rest.slice(1);
    }
}
