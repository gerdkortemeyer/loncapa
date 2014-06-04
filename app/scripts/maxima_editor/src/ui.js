/*

Copyright (C) 2014  Michigan State University Board of Trustees

The JavaScript code in this page is free software: you can
redistribute it and/or modify it under the terms of the GNU
General Public License (GNU GPL) as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.  The code is distributed WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU GPL for more details.

As additional permission under GNU GPL version 3 section 7, you
may distribute non-source (e.g., minimized or compacted) forms of
that code without the copy of the GNU GPL normally required by
section 4, provided you include this license notice and a URL
through which recipients can access the Corresponding Source.

*/

/*
  This script looks for elements with the "maxima" class, and
  adds a preview div afterward which is updated automatically.
*/

var handleChange = function(maxima_object) {
    // maxima_object has 3 fields: ta, output_div, oldtxt
    // we need to pass this object instead of the values because oldtxt will change
    var ta, output_div, txt, parser, output, root;
    ta = maxima_object.ta;
    output_div = maxima_object.output_div;
    txt = ta.value;
    if (txt != maxima_object.oldtxt) {
        maxima_object.oldtxt = txt;
        while (output_div.firstChild != null)
            output_div.removeChild(output_div.firstChild);
        output_div.removeAttribute("title");
        if (txt != "") {
            parser = maxima_object.parser;
            try {
                root = parser.parse(txt);
                if (root != null) {
                    var math = document.createElement("math");
                    math.setAttribute("display", "block");
                    math.appendChild(root.toMathML());
                    output_div.appendChild(math);
                    MathJax.Hub.Queue(["Typeset", MathJax.Hub, output_div]);
                }
            } catch (e) {
                output = "error: " + e;
                output_div.setAttribute("title", output);
                if (e instanceof ParseException) {
                    output_div.appendChild(document.createTextNode(txt.substring(0, e.from)));
                    var span = document.createElement('span');
                    span.appendChild(document.createTextNode(txt.substring(e.from, e.to + 1)));
                    span.className = 'maxima-error';
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

window.addEventListener('load', function(e) {
    var maxima_objects = [];
    var maxima_inputs = document.getElementsByClassName('maxima');
    for (var i=0; i<maxima_inputs.length; i++) {
        var ta = maxima_inputs[i];
        var output_div = document.createElement("div");
        if (ta.nextSibling)
            ta.parentNode.insertBefore(output_div, ta.nextSibling);
        else
            ta.parentNode.appendChild(output_div);
        var implicit_operators = (ta.getAttribute("data-implicit_operators") === "true");
        var unit_mode = (ta.getAttribute("data-unit_mode") === "true");
        var constants = ta.getAttribute("data-constants");
        if (constants)
            constants = constants.split(/[\s,]+/);
        var oldtxt = "";
        maxima_objects[i] = {
            "ta": ta,
            "output_div": output_div,
            "oldtxt": oldtxt,
            "parser": new Parser(implicit_operators, unit_mode, constants)
        };
        var changeObjectN = function(n) {
            return function(e) { handleChange(maxima_objects[n]); };
        }
        var startChange = changeObjectN(i);
        if (ta.value != oldtxt)
            startChange();
        ta.addEventListener('change', startChange , false);
        ta.addEventListener('keyup', startChange , false);
    }
    
}, false);

