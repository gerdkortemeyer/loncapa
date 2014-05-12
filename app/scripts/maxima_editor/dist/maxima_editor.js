(function () {/*

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

/**
 * Operator definitions (see function define() at the end).
 * @constructor
 */
function Definitions() {
    this.operators = [];  /* Array of Operator */
}

Definitions.ARG_SEPARATOR = ";";
Definitions.DECIMAL_SIGN_1 = ".";
Definitions.DECIMAL_SIGN_2 = ",";

/**
 * Creates a new operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} arity - Operator.UNARY, BINARY or TERNARY
 * @param {number} lbp - Left binding power
 * @param {number} rbp - Right binding power
 * @param {function} nud - Null denotation function
 * @param {function} led - Left denotation function
 */
Definitions.prototype.operator = function(id, arity, lbp, rbp, nud, led) {
    this.operators.push(new Operator(id, arity, lbp, rbp, nud, led));
};

/**
 * Creates a new separator operator.
 * @param {string} id - Operator id (text used to recognize it)
 */
Definitions.prototype.separator = function(id) {
    this.operator(id, Operator.BINARY, 0, 0, null, null);
};

/**
 * Creates a new infix operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} lbp - Left binding power
 * @param {number} rbp - Right binding power
 * @param {ledFunction} [led] - Left denotation function
 */
Definitions.prototype.infix = function(id, lbp, rbp, led) {
    var arity, nud;
    arity = Operator.BINARY;
    nud = null;
    led = led || function(p, left) {
        var children = [left, p.expression(rbp)];
        return new ENode(ENode.OPERATOR, this, id, children);
    };
    this.operator(id, arity, lbp, rbp, nud, led);
};

/**
 * Creates a new prefix operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} rbp - Right binding power
 * @param {nudFunction} nud - Null denotation function
 */
Definitions.prototype.prefix = function(id, rbp, nud) {
    var arity, lbp, led;
    arity = Operator.UNARY;
    lbp = 0;
    nud = nud || function(p) {
        var children = [p.expression(rbp)];
        return new ENode(ENode.OPERATOR, this, id, children);
    };
    led = null;
    this.operator(id, arity, lbp, rbp, nud, led);
};

/**
 * Creates a new suffix operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} lbp - Left binding power
 * @param {ledFunction} led - Left denotation function
 */
Definitions.prototype.suffix = function(id, lbp, led) {
    var arity, rbp, nud;
    arity = Operator.UNARY;
    rbp = 0;
    nud = null;
    led = led || function(p, left) {
        var children = [left];
        return new ENode(ENode.OPERATOR, this, id, children);
    };
    this.operator(id, arity, lbp, rbp, nud, led);
};

/**
 * Returns the defined operator with the given id
 * @param {string} id - Operator id (text used to recognize it)
 * @returns {Operator}
 */
Definitions.prototype.findOperator = function(id) {
    for (var i=0; i<this.operators.length; i++) {
        if (this.operators[i].id == id) {
            return(this.operators[i]);
        }
    }
    return null;
}

/**
 * Defines all the operators.
 */
Definitions.prototype.define = function() {
    this.suffix("!", 160);
    this.infix("^", 140, 139);
    this.infix(".", 130, 129);
    this.infix("`", 125, 125); // units, this operator does not bind like in maxima :-/
    // to improve the ` operator, we would need a very special led
    // that would handle 2`a*b and 2`a*3 differently
    // currently, more parenthesis are required than with maxima
    this.infix("*", 120, 120);
    this.infix("/", 120, 120);
    this.infix("+", 100, 100);
    this.operator("-", Operator.BINARY, 100, 134, function(p) {
        // nud (prefix operator)
        var children = [p.expression(134)];
        return new ENode(ENode.OPERATOR, this, "-", children);
    }, function(p, left) {
        // led (infix operator)
        var children = [left, p.expression(100)];
        return new ENode(ENode.OPERATOR, this, "-", children);
    });
    this.infix("=", 80, 80);
    this.infix("#", 80, 80);
    this.infix("<=", 80, 80);
    this.infix(">=", 80, 80);
    this.infix("<", 80, 80);
    this.infix(">", 80, 80);
    
    this.separator(")");
    this.separator(Definitions.ARG_SEPARATOR);
    this.operator("(", Operator.BINARY, 200, 200, function(p) {
        // nud (for parenthesis)
        var e = p.expression(0);
        p.advance(")");
        return e;
    }, function(p, left) {
        // led (for functions)
        if (left.type != ENode.NAME && left.type != ENode.SUBSCRIPT)
            throw new ParseException("Function name expected before a parenthesis.", p.tokens[p.token_nr - 1].from);
        var children = [left];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== ")") {
            while (true) {
                children.push(p.expression(0));
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
            }
        }
        p.advance(")");
        return new ENode(ENode.FUNCTION, this, "(", children);
    });
    
    this.separator("]");
    this.operator("[", Operator.BINARY, 200, 70, function(p) {
        // nud (for vectors)
        var children = [];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== "]") {
            while (true) {
                children.push(p.expression(0));
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
            }
        }
        p.advance("]");
        return new ENode(ENode.VECTOR, this, null, children);
    }, function(p, left) {
        // led (for subscript)
        if (left.type != ENode.NAME && left.type != ENode.SUBSCRIPT)
            throw new ParseException("Name expected before a square bracket.", p.tokens[p.token_nr - 1].from);
        var children = [left];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== "]") {
            while (true) {
                children.push(p.expression(0));
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
            }
        }
        p.advance("]");
        return new ENode(ENode.SUBSCRIPT, this, "[", children);
    });
};

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

/**
 * Parsed tree node. ENode.toMathML(hcolors) contains the code for the transformation into MathML.
 * @constructor
 * @param {number} type - ENode.UNKNOWN | NAME | NUMBER | OPERATOR | FUNCTION | VECTOR
 * @param {Operator} op - The operator
 * @param {string} value - Node value as a string, null for type VECTOR
 * @param {Array.<ENode>} children - The children nodes, only for types OPERATOR, FUNCTION, VECTOR, SUBSCRIPT
 */
function ENode(type, op, value, children) {
    this.type = type;
    this.op = op;
    this.value = value;
    this.children = children;
}

ENode.UNKNOWN = 0;
ENode.NAME = 1;
ENode.NUMBER = 2;
ENode.OPERATOR = 3;
ENode.FUNCTION = 4;
ENode.VECTOR = 5;
ENode.SUBSCRIPT = 6;
ENode.COLORS = ["#F00000", "#0000FF", "#009000", "#FF00FF", "#00C0C0", "#FFA000", 
                "#800080", "#FF90B0", "#6090F0", "#902000", "#80B060", "#A07060",
                "#4000FF", "#F07060", "#008080", "#808000"];

/**
 * Returns the node as a string, for debug
 * @returns {string}
 */
ENode.prototype.toString = function() {
    var s = '(';
    switch (this.type) {
        case ENode.UNKNOWN:
            s += 'UNKNOWN';
            break;
        case ENode.NAME:
            s += 'NAME';
            break;
        case ENode.NUMBER:
            s += 'NUMBER';
            break;
        case ENode.OPERATOR:
            s += 'OPERATOR';
            break;
        case ENode.FUNCTION:
            s += 'FUNCTION';
            break;
        case ENode.VECTOR:
            s += 'VECTOR';
            break;
        case ENode.SUBSCRIPT:
            s += 'SUBSCRIPT';
            break;
    }
    if (this.op)
        s += " '" + this.op.id + "'";
    if (this.value)
        s += " '" + this.value + "'";
    if (this.children) {
        s += ' [';
        for (var i = 0; i < this.children.length; i++) {
            s += this.children[i].toString();
            if (i != this.children.length - 1)
                s += ',';
        }
        s += ']';
    }
    s+= ')';
    return s;
};

/**
 * Returns the color for an identifier.
 * @param {string} name
 * @param {Object.<string, string>} hcolors
 * @returns {string}
 */
ENode.prototype.getColorForIdentifier = function(name, hcolors) {
    var res = hcolors[name];
    if (!res) {
        res = ENode.COLORS[Object.keys(hcolors).length % ENode.COLORS.length];
        hcolors[name] = res;
    }
    return res;
}

/**
 * Transforms this ENode into a MathML HTML DOM element.
 * @param {Object.<string, string>} [hcolors] - hash identifier->color
 * @returns {Element}
 */
ENode.prototype.toMathML = function(hcolors) {
    var c0, c1, c2, c3, c4, i, j, el, par, mrow, mo, mtable, mfrac, msub;
    if (typeof hcolors == "undefined")
        hcolors = {};
    if (this.children != null && this.children.length > 0)
        c0 = this.children[0];
    else
        c0 = null;
    if (this.children != null && this.children.length > 1)
        c1 = this.children[1];
    else
        c1 = null;
    if (this.children != null && this.children.length > 2)
        c2 = this.children[2];
    else
        c2 = null;
    if (this.children != null && this.children.length > 3)
        c3 = this.children[3];
    else
        c3 = null;
    if (this.children != null && this.children.length > 4)
        c4 = this.children[4];
    else
        c4 = null;
    
    switch (this.type) {
        case ENode.UNKNOWN:
            el = document.createElement('mtext');
            el.appendChild(document.createTextNode("???"));
            return(el);
        
        case ENode.NAME:
            if (this.value.search(/^[a-zA-Z]+[0-9]+$/) >= 0) {
                var ind = this.value.search(/[0-9]/);
                msub = document.createElement('msub');
                msub.appendChild(this.mi(this.value.substring(0,ind)));
                msub.appendChild(this.mn(this.value.substring(ind)));
                el = msub;
            } else {
                el = this.mi(this.value)
            }
            el.setAttribute("mathcolor", this.getColorForIdentifier(this.value, hcolors));
            return(el);
        
        case ENode.NUMBER:
            return(this.mn(this.value));
        
        case ENode.OPERATOR:
            if (this.value == "/") {
                mfrac = document.createElement('mfrac');
                mfrac.appendChild(c0.toMathML(hcolors));
                mfrac.appendChild(c1.toMathML(hcolors));
                el = mfrac;
            } else if (this.value == "^") {
                if (c0.type == ENode.FUNCTION) {
                    if (c0.value == "sqrt" || c0.value == "abs" || c0.value == "matrix" ||
                            c0.value == "diff")
                        par = false;
                    else
                        par = true;
                } else if (c0.type == ENode.OPERATOR) {
                    par = true;
                } else
                    par = false;
                el = document.createElement('msup');
                if (par)
                    el.appendChild(this.addP(c0, hcolors));
                else
                    el.appendChild(c0.toMathML(hcolors));
                el.appendChild(c1.toMathML(hcolors));
            } else if (this.value == "*") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, hcolors));
                else
                    mrow.appendChild(c0.toMathML(hcolors));
                // should the x operator be visible ? We need to check if there is a number to the left of c1
                var firstinc1 = c1;
                while (firstinc1.type == ENode.OPERATOR) {
                    firstinc1 = firstinc1.children[0];
                }
                if (firstinc1.type == ENode.NUMBER)
                    mrow.appendChild(this.mo("\u22C5"));
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (this.value == "-") {
                mrow = document.createElement('mrow');
                if (this.children.length == 1) {
                    mrow.appendChild(this.mo("-"));
                    mrow.appendChild(c0.toMathML(hcolors));
                } else {
                    mrow.appendChild(c0.toMathML(hcolors));
                    mrow.appendChild(this.mo("-"));
                    if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                        mrow.appendChild(this.addP(c1, hcolors));
                    else
                        mrow.appendChild(c1.toMathML(hcolors));
                }
                el = mrow;
            } else if (this.value == "!") {
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, hcolors));
                else
                    mrow.appendChild(c0.toMathML(hcolors));
                mrow.appendChild(mo);
                el = mrow;
            } else if (this.value == "+") {
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                mrow.appendChild(c0.toMathML(hcolors));
                mrow.appendChild(mo);
                // should we add parenthesis ? We need to check if there is a '-' to the left of c1
                par = false;
                var first = c1;
                while (first.type == ENode.OPERATOR) {
                    if (first.value == "-" && first.children.length == 1) {
                        par = true;
                        break;
                    } else if (first.value == "+" || first.value == "-" || first.value == "*") {
                        first = first.children[0];
                    } else {
                        break;
                    }
                }
                if (par)
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (this.value == ".") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, hcolors));
                else
                    mrow.appendChild(c0.toMathML(hcolors));
                mrow.appendChild(this.mo("\u22C5"));
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (this.value == "`") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, hcolors));
                else
                    mrow.appendChild(c0.toMathML(hcolors));
                // the units should not be in italics
                var mstyle = document.createElement("mstyle");
                mstyle.setAttribute("fontstyle", "normal");
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mstyle.appendChild(this.addP(c1, hcolors));
                else
                    mstyle.appendChild(c1.toMathML(hcolors));
                mrow.appendChild(mstyle);
                el = mrow;
            } else {
                // relational operators
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                mrow.appendChild(c0.toMathML(hcolors));
                mrow.appendChild(mo);
                mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            }
            return(el);
        
        case ENode.FUNCTION: /* TODO: throw exceptions if wrong nb of args ? */
            // c0 contains the function name
            if (c0.value == "sqrt" && c1 != null) {
                el = document.createElement('msqrt');
                el.appendChild(c1.toMathML(hcolors));
            } else if (c0.value == "abs" && c1 != null) {
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("|"));
                mrow.appendChild(c1.toMathML(hcolors));
                mrow.appendChild(this.mo("|"));
                el = mrow;
            } else if (c0.value == "exp" && c1 != null) {
                el = document.createElement('msup');
                el.appendChild(this.mi("e"));
                el.appendChild(c1.toMathML(hcolors));
            } else if (c0.value == "factorial") {
                mrow = document.createElement('mrow');
                mo = this.mo("!");
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                mrow.appendChild(mo);
                el = mrow;
            } else if (c0.value == "diff" && this.children != null && this.children.length == 3) {
                mrow = document.createElement('mrow');
                mfrac = document.createElement('mfrac');
                mfrac.appendChild(this.mi("d"));
                var f2 = document.createElement('mrow');
                f2.appendChild(this.mi("d"));
                f2.appendChild(this.mi(c2.value));
                mfrac.appendChild(f2);
                mrow.appendChild(mfrac);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "diff" && this.children != null && this.children.length == 4) {
                mrow = document.createElement('mrow');
                mfrac = document.createElement('mfrac');
                var msup = document.createElement('msup');
                msup.appendChild(this.mi("d"));
                msup.appendChild(c3.toMathML(hcolors));
                mfrac.appendChild(msup);
                var f2 = document.createElement('mrow');
                f2.appendChild(this.mi("d"));
                msup = document.createElement('msup');
                msup.appendChild(c2.toMathML(hcolors));
                msup.appendChild(c3.toMathML(hcolors));
                f2.appendChild(msup);
                mfrac.appendChild(f2);
                mrow.appendChild(mfrac);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "integrate" && this.children != null && this.children.length == 3) {
                mrow = document.createElement('mrow');
                var mo = this.mo("\u222B");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                mrow.appendChild(mo);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                mrow.appendChild(this.mi("d"));
                mrow.appendChild(c2.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "integrate" && this.children != null && this.children.length == 5) {
                mrow = document.createElement('mrow');
                var msubsup = document.createElement('msubsup');
                var mo = this.mo("\u222B");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                msubsup.appendChild(mo);
                msubsup.appendChild(c3.toMathML(hcolors));
                msubsup.appendChild(c4.toMathML(hcolors));
                mrow.appendChild(msubsup);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                mrow.appendChild(this.mi("d"));
                mrow.appendChild(c2.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "sum" && this.children != null && this.children.length == 5) {
                mrow = document.createElement('mrow');
                var munderover = document.createElement('munderover');
                var mo = this.mo("\u2211");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                munderover.appendChild(mo);
                var mrow2 = document.createElement('mrow');
                mrow2.appendChild(c2.toMathML(hcolors));
                mrow2.appendChild(this.mo("="));
                mrow2.appendChild(c3.toMathML(hcolors));
                munderover.appendChild(mrow2);
                munderover.appendChild(c4.toMathML(hcolors));
                mrow.appendChild(munderover);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "product" && this.children != null && this.children.length == 5) {
                mrow = document.createElement('mrow');
                var munderover = document.createElement('munderover');
                var mo = this.mo("\u220F");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                munderover.appendChild(mo);
                var mrow2 = document.createElement('mrow');
                mrow2.appendChild(c2.toMathML(hcolors));
                mrow2.appendChild(this.mo("="));
                mrow2.appendChild(c3.toMathML(hcolors));
                munderover.appendChild(mrow2);
                munderover.appendChild(c4.toMathML(hcolors));
                mrow.appendChild(munderover);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, hcolors));
                else
                    mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "limit") {
                mrow = document.createElement('mrow');
                if (this.children.length < 4) {
                    mrow.appendChild(this.mo("lim"));
                } else {
                    var munder = document.createElement('munder');
                    munder.appendChild(this.mo("lim"));
                    var mrowunder = document.createElement('mrow');
                    mrowunder.appendChild(c2.toMathML(hcolors));
                    mrowunder.appendChild(this.mo("\u2192"));
                    mrowunder.appendChild(c3.toMathML(hcolors));
                    if (c4 != null) {
                        if (c4.value == "plus")
                            mrowunder.appendChild(this.mo("+"));
                        else if (c4.value == "minus")
                            mrowunder.appendChild(this.mo("-"));
                    }
                    munder.appendChild(mrowunder);
                    mrow.appendChild(munder);
                }
                mrow.appendChild(c1.toMathML(hcolors));
                el = mrow;
            } else if (c0.value == "binomial") {
                // displayed like a vector
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("("));
                mtable = document.createElement('mtable');
                for (i=1; i<this.children.length; i++) {
                    var mtr = document.createElement('mtr');
                    mtr.appendChild(this.children[i].toMathML(hcolors));
                    mtable.appendChild(mtr);
                }
                mrow.appendChild(mtable);
                mrow.appendChild(this.mo(")"));
                el = mrow;
            } else if (c0.value == "matrix") {
                for (i=1; i<this.children.length; i++) {
                    // check that all children are vectors
                    if (this.children[i].type !== ENode.VECTOR) {
                        el = document.createElement('mtext');
                        el.appendChild(document.createTextNode("???")); // could throw here
                        return(el);
                    }
                }
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("("));
                mtable = document.createElement('mtable');
                for (i=1; i<this.children.length; i++) {
                    var mtr = document.createElement('mtr');
                    for (j=0; j<this.children[i].children.length; j++) {
                        mtr.appendChild(this.children[i].children[j].toMathML(hcolors));
                    }
                    mtable.appendChild(mtr);
                }
                mrow.appendChild(mtable);
                mrow.appendChild(this.mo(")"));
                el = mrow;
            } else {
                // default display for a function
                mrow = document.createElement('mrow');
                mrow.appendChild(c0.toMathML(hcolors));
                mrow.appendChild(this.mo("("));
                for (i=1; i<this.children.length; i++) {
                    mrow.appendChild(this.children[i].toMathML(hcolors));
                    if (i < this.children.length - 1)
                        mrow.appendChild(this.mo(Definitions.ARG_SEPARATOR));
                }
                mrow.appendChild(this.mo(")"));
                el = mrow;
            }
            return(el);
        
        case ENode.VECTOR:
            mrow = document.createElement('mrow');
            mrow.appendChild(this.mo("("));
            mtable = document.createElement('mtable');
            for (i=0; i<this.children.length; i++) {
                var mtr = document.createElement('mtr');
                mtr.appendChild(this.children[i].toMathML(hcolors));
                mtable.appendChild(mtr);
            }
            mrow.appendChild(mtable);
            mrow.appendChild(this.mo(")"));
            return(mrow);
            
        case ENode.SUBSCRIPT:
            msub = document.createElement('msub');
            msub.appendChild(c0.toMathML(hcolors));
            if (this.children.length > 2) {
                mrow = document.createElement('mrow');
                for (i=1; i<this.children.length; i++) {
                    mrow.appendChild(this.children[i].toMathML(hcolors));
                    if (i < this.children.length - 1)
                        mrow.appendChild(this.mo(Definitions.ARG_SEPARATOR));
                }
                msub.appendChild(mrow);
            } else {
                msub.appendChild(c1.toMathML(hcolors));
            }
            return(msub);
    }
};

/**
 * Creates a MathML mi element with the given name
 * @param {string} name
 * @returns {Element}
 */
ENode.prototype.mi = function(name) {
    var mi = document.createElement('mi');
    if (ENode.symbols[name])
        name = ENode.symbols[name];
    mi.appendChild(document.createTextNode(name));
    return mi;
};

/**
 * Creates a MathML mn element with the given number or string
 * @param {string} n
 * @returns {Element}
 */
ENode.prototype.mn = function(n) {
    var mn = document.createElement('mn');
    mn.appendChild(document.createTextNode(n));
    return mn;
};

/**
 * Creates a MathML mo element with the given name
 * @param {string} name
 * @returns {Element}
 */
ENode.prototype.mo = function(name) {
    var mo = document.createElement('mo');
    if (ENode.symbols[name])
        name = ENode.symbols[name];
    mo.appendChild(document.createTextNode(name));
    return mo;
};

/**
 * Add parenthesis and returns a MathML element
 * @param {ENode} en
 * @param {Object.<string, string>} [hcolors] - hash identifier->color
 * @returns {Element}
 */
ENode.prototype.addP = function(en, hcolors) {
    var mrow = document.createElement('mrow');
    mrow.appendChild(this.mo("("));
    mrow.appendChild(en.toMathML(hcolors));
    mrow.appendChild(this.mo(")"));
    return mrow;
};

ENode.symbols = {
    /* lowercase greek */
    "alpha": "\u03B1", "beta": "\u03B2", "gamma": "\u03B3",
    "delta": "\u03B4", "epsilon": "\u03B5", "zeta": "\u03B6",
    "eta": "\u03B7", "theta": "\u03B8", "iota": "\u03B9",
    "kappa": "\u03BA", "lambda": "\u03BB", "mu": "\u03BC",
    "nu": "\u03BD", "xi": "\u03BE", "omicron": "\u03BF",
    "pi": "\u03C0", "rho": "\u03C1", "sigma": "\u03C3",
    "tau": "\u03C4", "upsilon": "\u03C5", "phi": "\u03C6",
    "chi": "\u03C7", "psi": "\u03C8", "omega": "\u03C9",
    /* uppercase greek */
    "Alpha": "\u0391", "Beta": "\u0392", "Gamma": "\u0393",
    "Delta": "\u0394", "Epsilon": "\u0395", "Zeta": "\u0396",
    "Eta": "\u0397", "Theta": "\u0398", "Iota": "\u0399",
    "Kappa": "\u039A", "Lambda": "\u039B", "Mu": "\u039C",
    "Nu": "\u039D", "Xi": "\u039E", "Omicron": "\u039F",
    "Pi": "\u03A0", "Rho": "\u03A1", "Sigma": "\u03A3",
    "Tau": "\u03A4", "Upsilon": "\u03A5", "Phi": "\u03A6",
    "Chi": "\u03A7", "Psi": "\u03A8", "Omega": "\u03A9",
    
    /* operators */
    "#":  "\u2260",
    ">=":  "\u2265",
    "<=":  "\u2264",
    
    /* other */
    "inf":  "\u221E",
    "minf":  "-\u221E"
};
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

/**
 * Null denotation function
 * @callback nudFunction
 * @param {Parser} p - the parser
 * @returns {ENode}
 */

/**
 * Left denotation function
 * @callback ledFunction
 * @param {Parser} p - the parser
 * @param {ENode} left - left node
 * @returns {ENode}
 */

/**
 * Parser operator, like "(".
 * @constructor
 * @param {string} id - Characters used to recognize the operator
 * @param {number} arity (UNKNOWN, UNARY, BINARY, TERNARY)
 * @param {number} lbp - left binding power
 * @param {number} rbp - right binding power
 * @param {nudFunction} nud - Null denotation function
 * @param {ledFunction} led - Left denotation function
 */
function Operator(id, arity, lbp, rbp, nud, led) {
    this.id = id;
    this.arity = arity;
    this.lbp = lbp;
    this.rbp = rbp;
    this.nud = nud;
    this.led = led;
}

Operator.UNKNOWN = 0;
Operator.UNARY = 1;
Operator.BINARY = 2;
Operator.TERNARY = 3;
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

/**
 * Parse exception
 * @constructor
 * @param {string} msg - Error message
 * @param {number} from - Character index
 * @param {number} [to] - Character index to (inclusive)
 */
function ParseException(msg, from, to) {
    this.msg = msg;
    this.from = from;
    if (to)
        this.to = to;
    else
        this.to = this.from;
}

/**
 * Returns the exception as a string, for debug
 * @returns {string}
 */
ParseException.prototype.toString = function() {
    return(this.msg + " at " + this.from + " - " + this.to);
};
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

/**
 * Equation parser
 * @constructor
 * @param {boolean} accept_bad_syntax - assume hidden multiplication operators in some cases (unlike maxima)
 */
function Parser(accept_bad_syntax) {
    this.accept_bad_syntax = accept_bad_syntax ? accept_bad_syntax : false;
    this.defs = new Definitions();
    this.defs.define();
    this.operators = this.defs.operators;
    this.oph = {}; // operator hash table
    for (var i=0; i<this.operators.length; i++)
        this.oph[this.operators[i].id] = this.operators[i];
}

/**
 * Returns the right node at the current token, based on top-down operator precedence.
 * @param {number} rbp - Right binding power
 * @returns {ENode}
 */
Parser.prototype.expression = function(rbp) {
    var left; // ENode
    var t = this.current_token;
    if (t == null)
        throw new ParseException("Expected something at the end",
            this.tokens[this.tokens.length - 1].to + 1);
    this.advance();
    if (t.op == null)
        left = new ENode(t.type, null, t.value, null);
    else if (t.op.nud == null)
        throw new ParseException("Unexpected operator '" + t.op.id + "'", t.from);
    else
        left = t.op.nud(this);
    while (this.current_token != null && this.current_token.op != null &&
            rbp < this.current_token.op.lbp) {
        t = this.current_token;
        this.advance();
        left = t.op.led(this, left);
    }
    return left;
};

/**
 * Advance to the next token,
 * expecting the given operator id if it is provided.
 * Throws a ParseException if a given operator id is not found.
 * @param {string} [id] - Operator id
 */
Parser.prototype.advance = function(id) {
    if (id && (this.current_token == null || this.current_token.op == null ||
            this.current_token.op.id !== id)) {
        if (this.current_token == null)
            throw new ParseException("Expected '" + id + "' at the end",
                this.tokens[this.tokens.length - 1].to + 1);
        else
            throw new ParseException("Expected '" + id + "'", this.current_token.from);
    }
    if (this.token_nr >= this.tokens.length) {
        this.current_token = null;
        return;
    }
    this.current_token = this.tokens[this.token_nr];
    this.token_nr += 1;
};

/**
 * Adds hidden multiplication operators to the token stream
 */
Parser.prototype.addHiddenOperators = function() {
    var multiplication = this.defs.findOperator("*");
    for (var i=0; i<this.tokens.length - 1; i++) {
        var token = this.tokens[i];
        var next_token = this.tokens[i + 1];
        if (
                (token.type == Token.NAME && next_token.type == Token.NAME) ||
                (token.type == Token.NUMBER && next_token.type == Token.NAME) ||
                (token.type == Token.NUMBER && next_token.type == Token.NUMBER) ||
                (token.type == Token.NUMBER && next_token.value == "(") ||
                /*(token.type == Token.NAME && next_token.value == "(") ||*/
                /* name ( could be a function call */
                (token.value == ")" && next_token.type == Token.NAME) ||
                (token.value == ")" && next_token.type == Token.NUMBER) ||
                (token.value == ")" && next_token.value == "(")
           ) {
            var new_token = new Token(Token.OPERATOR, next_token.from,
                next_token.from, multiplication.id, multiplication);
            this.tokens.splice(i+1, 0, new_token);
        }
    }
}

/**
 * Parse the string, returning an ENode tree.
 * @param {string} text - The text to parse.
 * @returns {ENode}
 */
Parser.prototype.parse = function(text) {
    var tokenizer = new Tokenizer(this.defs, text);
    this.tokens = tokenizer.tokenize();
    if (this.tokens.length == 0) {
        return null;
    }
    if (this.accept_bad_syntax) {
        this.addHiddenOperators();
    }
    this.token_nr = 0;
    this.current_token = this.tokens[this.token_nr];
    this.advance();
    var root = this.expression(0);
    if (this.current_token != null) {
        throw new ParseException("Expected the end", this.current_token.from);
    }
    return root;
};
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

/**
 * A token from the equation text.
 * @constructor
 * @param {number} type - Token type: Token.UNKNOWN, NAME, NUMBER, OPERATOR
 * @param {number} from - Index of the token's first character
 * @param {number} to - Index of the token's last character
 * @param {string} value - String content of the token
 * @param {Operator} op - The matching operator, possibly null
 */
function Token(type, from, to, value, op) {
    this.type = type;
    this.from = from;
    this.to = to;
    this.value = value;
    this.op = op;
}

Token.UNKNOWN = 0;
Token.NAME = 1;
Token.NUMBER = 2;
Token.OPERATOR = 3;
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

/**
 * String tokenizer. Recognizes only names, numbers, and parser operators.
 * @constructor
 * @param {Definitions} defs - Operator definitions
 * @param {string} text - The text to tokenize
 */
function Tokenizer(defs, text) {
    this.defs = defs;
    this.text = text;
}

/**
 * Tokenizes the text.
 * Can throw a ParseException.
 * @returns {Array.<Token>}
 */
Tokenizer.prototype.tokenize = function() {
    var c, i, iop, from, tokens, value;
    
    i = 0;
    c = this.text.charAt(i);
    tokens = [];
    
main:
    while (c) {
        from = i;
        
        // ignore whitespace
        if (c <= ' ') {
            i++;
            c = this.text.charAt(i);
            continue;
        }
        
        // check for numbers before operators
        // (numbers starting with . will not be confused with the . operator)
        if ((c >= '0' && c <= '9') ||
                ((c === Definitions.DECIMAL_SIGN_1 || c === Definitions.DECIMAL_SIGN_2) &&
                (this.text.charAt(i+1) >= '0' && this.text.charAt(i+1) <= '9'))) {
            value = '';
            
            if (c !== Definitions.DECIMAL_SIGN_1 && c !== Definitions.DECIMAL_SIGN_2) {
                i++;
                value += c;
                // Look for more digits.
                for (;;) {
                    c = this.text.charAt(i);
                    if (c < '0' || c > '9') {
                        break;
                    }
                    i++;
                    value += c;
                }
            }
            
            // Look for a decimal fraction part.
            if (c === Definitions.DECIMAL_SIGN_1 || c === Definitions.DECIMAL_SIGN_2) {
                i++;
                value += c;
                for (;;) {
                    c = this.text.charAt(i);
                    if (c < '0' || c > '9') {
                        break;
                    }
                    i += 1;
                    value += c;
                }
            }
            
            // Look for an exponent part.
            if (c === 'e' || c === 'E') {
                i++;
                value += c;
                c = this.text.charAt(i);
                if (c === '-' || c === '+') {
                    i++;
                    value += c;
                    c = this.text.charAt(i);
                }
                if (c < '0' || c > '9') {
                    // syntax error in number exponent
                    throw new ParseException("syntax error in number exponent", from, i);
                }
                do {
                    i++;
                    value += c;
                    c = this.text.charAt(i);
                } while (c >= '0' && c <= '9');
            }
            
            /* this is not necessary, as the parser will not recognize the tokens
               if it is not accepted, and if bad syntax is accepted a * operator will be added
            // Make sure the next character is not a letter.
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) {
                // syntax error in number
                throw new ParseException("syntax error in number", from, i);
            }
            */
            
            // Convert the string value to a number. If it is finite, then it is a good token.
            var n = +value.replace(Definitions.DECIMAL_SIGN_1, '.').replace(Definitions.DECIMAL_SIGN_2, '.');
            if (isFinite(n)) {
                tokens.push(new Token(Token.NUMBER, from, i - 1, value, null));
                continue;
            } else {
                // syntax error in number
                throw new ParseException("syntax error in number", from, i);
            }
        }
        
        // check for operators before names (they could be confused with
        // variables if they don't use special characters)
        for (iop = 0; iop < this.defs.operators.length; iop++) {
            var op = this.defs.operators[iop];
            if (this.text.substring(i, i+op.id.length) === op.id) {
                i += op.id.length;
                c = this.text.charAt(i);
                tokens.push(new Token(Token.OPERATOR, from, i - 1, op.id, op));
                continue main;
            }
        }
        
        // names
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) {
            value = c;
            i++;
            for (;;) {
                c = this.text.charAt(i);
                if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                        (c >= '0' && c <= '9') || c === '_') {
                    value += c;
                    i++;
                } else {
                    break;
                }
            }
            tokens.push(new Token(Token.NAME, from, i - 1, value, null));
            continue;
        }
        
        // unrecognized operator
        throw new ParseException("unrecognized operator", from, i);
    }
    return tokens;
};
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
            parser = new Parser(true);
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
        var oldtxt = "";
        maxima_objects[i] = {
            "ta": ta,
            "output_div": output_div,
            "oldtxt": oldtxt
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

}());