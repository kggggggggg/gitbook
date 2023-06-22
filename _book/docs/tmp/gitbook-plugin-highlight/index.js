var path = require('path');
var hljs = require('highlight.js');

var MAP = {
    'py': 'python',
    'js': 'javascript',
    'json': 'javascript',
    'rb': 'ruby',
    'csharp': 'cs',
};

function normalize(lang) {
    if(!lang) { return null; }

    var lower = lang.toLowerCase();
    return MAP[lower] || lower;
}

function highlight(lang, code) {
    if(!lang) return {
        body: code,
        html: false
    };

    // Normalize lang
    lang = normalize(lang);

    try {
        const lines = hljs.highlight(lang, code).value.split('\n');
        var newLines = [];
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line.includes("//stylebegin")) {
                console.log(line);

                var match = line.match(/\{([^}]+)\}/);
                if (match) {
                    s = match[1];
                    line = "<span style= \"" + s + "\">";
                }
                console.log(line);
            }
            if (line.includes("//styleend")) {
                line = "</span>";
            }
            newLines.push(line);
        }
        x = newLines.join('\n');
        return x;

    } catch(e) { }

    return {
        body: code,
        html: false
    };
}


module.exports = {
    book: {
        assets: './css',
        css: [
            'website.css'
        ]
    },
    ebook: {
        assets: './css',
        css: [
            'ebook.css'
        ]
    },
    blocks: {
        code: function(block) {
            return highlight(block.kwargs.language, block.body);
        }
    }
};
