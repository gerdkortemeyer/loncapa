
var oldtxt = "";
var ta = document.getElementById('input');
var output_div = document.getElementById('output');
var handleChange = function(e) {
    var txt, parser, output, root;
    txt = ta.value;
    if (txt != oldtxt) {
        oldtxt = txt;
        while (output_div.firstChild != null)
            output_div.removeChild(output_div.firstChild);
        output_div.removeAttribute("title");
        if (txt != "") {
            parser = new Parser();
            try {
                root = parser.parse(txt);
                if (root != null) {
                    var math = document.createElement("math");
                    math.setAttribute("display", "block");
                    math.appendChild(root.toMathML());
                    output_div.appendChild(math);
                    MathJax.Hub.Queue(["Typeset", MathJax.Hub, "output"]);
                }
            } catch (e) {
                output = "error: " + e;
                output_div.setAttribute("title", output);
                if (e instanceof ParseException) {
                    output_div.appendChild(document.createTextNode(txt.substring(0, e.from)));
                    var span = document.createElement('span');
                    span.appendChild(document.createTextNode(txt.substring(e.from, e.to + 1)));
                    span.className = 'error';
                    output_div.appendChild(span);
                    if (e.to < txt.length - 1) {
                        output_div.appendChild(document.createTextNode(txt.substring(e.to + 1)));
                    }
                } else {
                    var tn = document.createTextNode(output);
                    output_div.appendChild(tn);
                }
            }
        }
    }
}
ta.addEventListener('change', handleChange, false);
ta.addEventListener('keyup', handleChange, false);
window.addEventListener('load', function(e) { ta.focus(); handleChange(e); }, false);
