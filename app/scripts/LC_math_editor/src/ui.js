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

"use strict";

var handleChange = function(math_object) {
    // math_object has 3 fields: ta, output_node, oldtxt
    // we need to pass this object instead of the values because oldtxt will change
    var ta, output_node, txt, parser, output, root, test1, test2;
    ta = math_object.ta;
    output_node = math_object.output_node;
    txt = ta.value;
    
    // automatically add brackets to something like "1;2;3", for LON-CAPA:
    // NOTE: this is ugly and sometimes adds brackets to error messages
    test1 = '';
    test2 = txt;
    while (test2 != test1) {
      test1 = test2;
      test2 = test1.replace(/\[[^\[\]]*\]/g, '');
    }
    if (test2.split("[").length == test2.split("]").length) {
      test1 = '';
      while (test2 != test1) {
        test1 = test2;
        test2 = test1.replace(/\([^\(\)]*\)/g, '');
      }
      if (test2.split("(").length == test2.split(")").length) {
        test1 = '';
        while (test2 != test1) {
          test1 = test2;
          test2 = test1.replace(/\{[^\{\}]*\}/g, '');
        }
        if (test2.split("{").length == test2.split("}").length) {
          if (test2.indexOf(Definitions.ARG_SEPARATOR) != -1) {
            txt = '['+txt+']';
          }
        }
      }
    }
    
    if (txt != math_object.oldtxt) {
        math_object.oldtxt = txt;
        while (output_node.firstChild != null)
            output_node.removeChild(output_node.firstChild);
        output_node.removeAttribute("title");
        if (txt != "") {
            parser = math_object.parser;
            try {
                root = parser.parse(txt);
                if (root != null) {
                    var math = document.createElement("math");
                    math.setAttribute("display", "block");
                    math.appendChild(root.toMathML());
                    output_node.appendChild(math);
                    MathJax.Hub.Queue(["Typeset", MathJax.Hub, output_node]);
                }
            } catch (e) {
                output = "error: " + e;
                output_node.setAttribute("title", output);
                if (e instanceof ParseException) {
                    output_node.appendChild(document.createTextNode(txt.substring(0, e.from)));
                    var span = document.createElement('span');
                    span.appendChild(document.createTextNode(txt.substring(e.from, e.to + 1)));
                    span.className = 'math-error';
                    output_node.appendChild(span);
                    if (e.to < txt.length - 1) {
                        output_node.appendChild(document.createTextNode(txt.substring(e.to + 1)));
                    }
                } else {
                    var tn = document.createTextNode(output);
                    output_node.appendChild(tn);
                }
            }
        }
    }
}

var init_done = false;

/*
  Looks for elements with the "math" class, and
  adds a preview div afterward which is updated automatically.
*/
var initEditors = function() {
    if (init_done)
        return;
    init_done = true;
    var math_objects = [];
    var math_inputs = document.getElementsByClassName('math');
    for (var i=0; i<math_inputs.length; i++) {
        var ta = math_inputs[i];
        if (ta.nodeName == "TEXTAREA" || ta.nodeName == "INPUT") {
            var output_node = document.createElement("span");
            output_node.setAttribute("style", "display:none");
            if (ta.nextSibling)
                ta.parentNode.insertBefore(output_node, ta.nextSibling);
            else
                ta.parentNode.appendChild(output_node);
            var hideNode = function(node) {
                return function(e) { node.setAttribute("style", "display:none"); };
            };
            var showNode = function(node) {
                return function(e) { node.setAttribute("style", "display: inline-block; background-color: #FFFFE0"); };
            };
            ta.addEventListener("blur", hideNode(output_node), false);
            ta.addEventListener("focus", showNode(output_node), false);
            var implicit_operators = (ta.getAttribute("data-implicit_operators") === "true");
            var unit_mode = (ta.getAttribute("data-unit_mode") === "true");
            var constants = ta.getAttribute("data-constants");
            if (constants)
                constants = constants.split(/[\s,]+/);
            var oldtxt = "";
            math_objects[i] = {
                "ta": ta,
                "output_node": output_node,
                "oldtxt": oldtxt,
                "parser": new Parser(implicit_operators, unit_mode, constants)
            };
            var changeObjectN = function(n) {
                return function(e) {
                  var obj = math_objects[n];
                  if (document.activeElement == obj.ta) {
                    // this is useful if there is data in the field with the page default focus
                    // (there might not be a focus event for the active element)
                    obj.output_node.setAttribute("style", "display: inline-block; background-color: #FFFFE0");
                  }
                  handleChange(obj);
                };
            };
            var startChange = changeObjectN(i);
            if (ta.value != oldtxt)
                startChange(); // process non-empty fields even though they are not visible yet
            ta.addEventListener('change', startChange, false);
            ta.addEventListener('keyup', startChange, false);
        }
    }
}

