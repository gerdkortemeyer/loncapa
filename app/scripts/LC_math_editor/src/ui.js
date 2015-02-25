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
                    span.style.border = 'solid 1px red';// this used to be CSS "math-error", but using CSS caused too many problems
                    span.style.minWidth = '1px';
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

var math_objects = [];

/*
  Looks for elements with the "math" class, and
  adds a preview div afterward which is updated automatically.
  Can be called again after math fields have been added, removed, or when options have changed.
*/
var initEditors = function() {
    // to hide the MathJax messages (note: this could be done elsewhere)
    MathJax.Hub.Config({
        messageStyle: "none"
    });
    var math_inputs = document.getElementsByClassName('math');
    // first remove the nodes and objects for the inputs that are gone
    for (var i=0; i<math_objects.length; i++) {
        var ta = math_objects[i].ta;
        var found = false;
        for (var j=0; j<math_inputs.length; j++) {
            if (math_inputs[j] == ta) {
                found = true;
                break;
            }
        }
        if (!found) {
            var output_node = math_objects[i].output_node;
            if (output_node.parentNode) {
                output_node.parentNode.removeChild(output_node);
            }
            math_objects.splice(i, 1);
            i--;
        }
    }
    // then create or update nodes and objects for the new inputs
    for (var i=0; i<math_inputs.length; i++) {
        var ta = math_inputs[i];
        if (ta.nodeName == "TEXTAREA" || ta.nodeName == "INPUT") {
            var ind_math = -1;
            for (var j=0; j<math_objects.length; j++) {
                if (math_objects[j].ta == ta) {
                    ind_math = j;
                    break;
                }
            }
            var implicit_operators = (ta.getAttribute("data-implicit_operators") === "true");
            var unit_mode = (ta.getAttribute("data-unit_mode") === "true");
            var constants = ta.getAttribute("data-constants");
            if (constants)
                constants = constants.split(/[\s,]+/);
            var output_node;
            if (ind_math == -1) {
                output_node = document.createElement("span");
                output_node.style.display = "none";
                output_node.style.position = "absolute";
                output_node.style.backgroundColor = "rgba(255,255,224,0.9)";
                output_node.style.color = "black";
                output_node.style.border = "1px solid #A0A0A0";
                output_node.style.padding = "5px";
                output_node.style.zIndex = "1";
                var getCSSAbsolutePosition = function getCSSAbsolutePosition(el) {
                    var x = 0;
                    var y = 0;
                    while (el && !isNaN(el.offsetLeft) && !isNaN(el.offsetTop)) {
                        x += el.offsetLeft - el.scrollLeft;
                        y += el.offsetTop - el.scrollTop;
                        el = el.offsetParent;
                        if (el) {
                            var style = window.getComputedStyle(el);
                            if (style.position == 'absolute' || style.position == 'relative')
                                break;
                        }
                    }
                    return {top: y, left: x};
                }
                var place = function(ta, output_node) {
                    // position the output_node below or on top of ta
                    var ta_rect = ta.getBoundingClientRect();
                    var root = document.documentElement;
                    var docTop = (window.pageYOffset || root.scrollTop)  - (root.clientTop || 0);
                    var docLeft = (window.pageXOffset || root.scrollLeft) - (root.clientLeft || 0);
                    var ta_pos = getCSSAbsolutePosition(ta);
                    output_node.style.left = ta_pos.left + "px";
                    if (window.innerHeight > ta_rect.bottom + output_node.offsetHeight)
                        output_node.style.top = (ta_pos.top + ta.offsetHeight) + "px";
                    else
                        output_node.style.top = (ta_pos.top - output_node.offsetHeight) + "px";
                }
                if (ta.nextSibling)
                    ta.parentNode.insertBefore(output_node, ta.nextSibling);
                else
                    ta.parentNode.appendChild(output_node);
                var hide_node = function(an_output_node) {
                    // returns a function that will hide the node on any event
                    // (we can't use the node directly because it changes in the loop)
                    return function(e) {
                      an_output_node.style.display = "none";
                    };
                }
                var hide_node_if_no_error = function(an_output_node) {
                    return function(e) {
                      if (!an_output_node.hasAttribute('title'))
                        an_output_node.style.display = "none";
                    };
                }
                var focus = function(a_ta, an_output_node) {
                    return function(e) {
                        if (a_ta.value != '') {
                            an_output_node.style.display = "block";
                            place(a_ta, an_output_node);
                        }
                    };
                };
                ta.addEventListener("blur", hide_node(output_node), false);
                ta.addEventListener("focus", focus(ta, output_node), false);
                output_node.addEventListener("mouseenter", hide_node_if_no_error(output_node), false);
                ind_math = math_objects.length;
                var oldtxt = "";
                math_objects[ind_math] = {
                    "ta": ta,
                    "output_node": output_node,
                    "oldtxt": oldtxt,
                    "parser": new Parser(implicit_operators, unit_mode, constants)
                };
                var changeObjectN = function(n) {
                    return function(e) {
                      var obj = math_objects[n];
                      handleChange(obj);
                      if (document.activeElement == obj.ta) {
                          if (obj.ta.value != '') {
                              obj.output_node.style.display = "block";
                              MathJax.Hub.Queue(function () {
                                  // position the element only when MathJax is done, because the output_node height might change
                                  place(obj.ta, obj.output_node);
                              });
                          } else {
                              obj.output_node.style.display = "none";
                          }
                      }
                    };
                };
                var startChange = changeObjectN(ind_math);
                if (ta.value != oldtxt)
                    startChange(); // process non-empty fields even though they are not visible yet
                ta.addEventListener('change', startChange, false);
                ta.addEventListener('keyup', startChange, false);
            } else {
                // only create a new parser and update the result if the options have changed
                var same_constants;
                var parser = math_objects[ind_math].parser;
                if (!constants && parser.constants.length == 0) {
                    same_constants = true;
                } else {
                    if (constants) {
                        same_constants = parser.constants.length == constants.length;
                        if (same_constants) {
                            for (var j=0; j<constants.length; j++) {
                                if (parser.constants[j] != constants[j]) {
                                    same_constants = false;
                                    break;
                                }
                            }
                        }
                    } else {
                        same_constants = false;
                    }
                }
                if (parser.implicit_operators != implicit_operators || parser.unit_mode != unit_mode || !same_constants) {
                    math_objects[ind_math].parser = new Parser(implicit_operators, unit_mode, constants);
                    if (ta.value != '') {
                        math_objects[ind_math].oldtxt = '';
                        handleChange(math_objects[ind_math]);
                    }
                }
            }
        }
    }
}

/**
 * Updates display for <span class="math"> and <div class="math"> (LON-CAPA ln and dlm tags)
 */
var updateMathSpanAndDiv = function() {
    var nl = document.getElementsByClassName('math');
    // convert to an array because the nodelist would change as we are removing nodes from the document
    var math_nodes = [];
    for (var i = 0, ref = math_nodes.length = nl.length; i < ref; i++) {
      math_nodes[i] = nl[i];
    }
    for (var i=0; i<math_nodes.length; i++) {
        var el = math_nodes[i];
        if (el.nodeName == "SPAN" || el.nodeName == "DIV") {
            if (el.firstChild == null || el.firstChild.nodeType != 3)
                continue;
            var bspan = (el.nodeName == "SPAN");
            var txt = el.firstChild.nodeValue;
            var implicit_operators = (el.getAttribute("data-implicit_operators") === "true");
            var unit_mode = (el.getAttribute("data-unit_mode") === "true");
            var constants = el.getAttribute("data-constants");
            if (constants)
                constants = constants.split(/[\s,]+/);
            var parser = new Parser(implicit_operators, unit_mode, constants);
            try {
                var root = parser.parse(txt);
                if (root != null) {
                    var math = document.createElement("math");
                    math.setAttribute("display", bspan ? "inline" : "block");
                    math.appendChild(root.toMathML(['#000000']));
                    // at this point it would be nice to replace el by math, but MathJax does not
                    // always typeset math elements when given directly, so we need to typeset the parent...
                    el.classList.remove('math');
                    el.removeChild(el.firstChild);
                    el.appendChild(math);
                    MathJax.Hub.Queue(["Typeset", MathJax.Hub, el]);
                }
            } catch (e) {
                el.firstChild.nodeValue = "[syntax error in math:" + e + "]";
                el.classList.remove('math');
            }
        }
    }
}
