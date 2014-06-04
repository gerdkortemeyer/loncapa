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
ENode.COLORS = ["#E01010", "#0010FF", "#009000", "#FF00FF", "#00B0B0", "#F09000", 
                "#800080", "#F080A0", "#6090F0", "#902000", "#70A050", "#A07060",
                "#5000FF", "#E06050", "#008080", "#808000"];

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
 * @param {Object.<string, string>} hcolors - hash identifier->color
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
 * @param {Object} [context] - display context (not needed for the root element)
 * @param {Object.<string, string>} context.hcolors - hash identifier->color
 * @param {number} context.depth - Depth in parenthesis, used for coloring
 * @returns {Element}
 */
ENode.prototype.toMathML = function(context) {
    var c0, c1, c2, c3, c4, i, j, el, par, mrow, mo, mtable, mfrac, msub, msup;
    if (typeof context == "undefined")
        context = { hcolors: {}, depth: 0 };
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
            el.setAttribute("mathcolor", this.getColorForIdentifier(this.value, context.hcolors));
            return(el);
        
        case ENode.NUMBER:
            if (this.value.indexOf('e') != -1 || this.value.indexOf('E') != -1) {
                var index = this.value.indexOf('e');
                if (index == -1)
                    index = this.value.indexOf('E');
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mn(this.value.substring(0, index)));
                mrow.appendChild(this.mo("\u22C5"));
                msup = document.createElement('msup');
                msup.appendChild(this.mn(10));
                msup.appendChild(this.mn(this.value.substring(index + 1)));
                mrow.appendChild(msup);
                return(mrow);
            }
            return(this.mn(this.value));
        
        case ENode.OPERATOR:
            if (this.value == "/") {
                mfrac = document.createElement('mfrac');
                mfrac.appendChild(c0.toMathML(context));
                mfrac.appendChild(c1.toMathML(context));
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
                    el.appendChild(this.addP(c0, context));
                else
                    el.appendChild(c0.toMathML(context));
                el.appendChild(c1.toMathML(context));
            } else if (this.value == "*") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, context));
                else
                    mrow.appendChild(c0.toMathML(context));
                // should the x operator be visible ? We need to check if there is a number to the left of c1
                var firstinc1 = c1;
                while (firstinc1.type == ENode.OPERATOR) {
                    firstinc1 = firstinc1.children[0];
                }
                // ... and if it's an operation between vectors/matrices, the * operator should be displayed
                // (it is ambiguous otherwise)
                // note: this will not work if the matrix is calculated, for instance with 2[1;2]*[3;4]
                if (c0.type == ENode.VECTOR && c1.type == ENode.VECTOR)
                    mrow.appendChild(this.mo("*"));
                else if (firstinc1.type == ENode.NUMBER)
                    mrow.appendChild(this.mo("\u22C5"));
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (this.value == "-") {
                mrow = document.createElement('mrow');
                if (this.children.length == 1) {
                    mrow.appendChild(this.mo("-"));
                    mrow.appendChild(c0.toMathML(context));
                } else {
                    mrow.appendChild(c0.toMathML(context));
                    mrow.appendChild(this.mo("-"));
                    if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                        mrow.appendChild(this.addP(c1, context));
                    else
                        mrow.appendChild(c1.toMathML(context));
                }
                el = mrow;
            } else if (this.value == "!") {
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, context));
                else
                    mrow.appendChild(c0.toMathML(context));
                mrow.appendChild(mo);
                el = mrow;
            } else if (this.value == "+") {
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                mrow.appendChild(c0.toMathML(context));
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
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (this.value == ".") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, context));
                else
                    mrow.appendChild(c0.toMathML(context));
                mrow.appendChild(this.mo("\u22C5"));
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (this.value == "`") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0, context));
                else
                    mrow.appendChild(c0.toMathML(context));
                // the units should not be in italics
                var mstyle = document.createElement("mstyle");
                mstyle.setAttribute("fontstyle", "normal");
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mstyle.appendChild(this.addP(c1, context));
                else
                    mstyle.appendChild(c1.toMathML(context));
                mrow.appendChild(mstyle);
                el = mrow;
            } else {
                // relational operators
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                mrow.appendChild(c0.toMathML(context));
                mrow.appendChild(mo);
                mrow.appendChild(c1.toMathML(context));
                el = mrow;
            }
            return(el);
        
        case ENode.FUNCTION: /* TODO: throw exceptions if wrong nb of args ? */
            // c0 contains the function name
            if (c0.value == "sqrt" && c1 != null) {
                el = document.createElement('msqrt');
                el.appendChild(c1.toMathML(context));
            } else if (c0.value == "abs" && c1 != null) {
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("|"));
                mrow.appendChild(c1.toMathML(context));
                mrow.appendChild(this.mo("|"));
                el = mrow;
            } else if (c0.value == "exp" && c1 != null) {
                el = document.createElement('msup');
                el.appendChild(this.mi("e"));
                el.appendChild(c1.toMathML(context));
            } else if (c0.value == "factorial") {
                mrow = document.createElement('mrow');
                mo = this.mo("!");
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
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
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (c0.value == "diff" && this.children != null && this.children.length == 4) {
                mrow = document.createElement('mrow');
                mfrac = document.createElement('mfrac');
                msup = document.createElement('msup');
                msup.appendChild(this.mi("d"));
                msup.appendChild(c3.toMathML(context));
                mfrac.appendChild(msup);
                var f2 = document.createElement('mrow');
                f2.appendChild(this.mi("d"));
                msup = document.createElement('msup');
                msup.appendChild(c2.toMathML(context));
                msup.appendChild(c3.toMathML(context));
                f2.appendChild(msup);
                mfrac.appendChild(f2);
                mrow.appendChild(mfrac);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (c0.value == "integrate" && this.children != null && this.children.length == 3) {
                mrow = document.createElement('mrow');
                var mo = this.mo("\u222B");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                mrow.appendChild(mo);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                mrow.appendChild(this.mi("d"));
                mrow.appendChild(c2.toMathML(context));
                el = mrow;
            } else if (c0.value == "integrate" && this.children != null && this.children.length == 5) {
                mrow = document.createElement('mrow');
                var msubsup = document.createElement('msubsup');
                var mo = this.mo("\u222B");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                msubsup.appendChild(mo);
                msubsup.appendChild(c3.toMathML(context));
                msubsup.appendChild(c4.toMathML(context));
                mrow.appendChild(msubsup);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                mrow.appendChild(this.mi("d"));
                mrow.appendChild(c2.toMathML(context));
                el = mrow;
            } else if (c0.value == "sum" && this.children != null && this.children.length == 5) {
                mrow = document.createElement('mrow');
                var munderover = document.createElement('munderover');
                var mo = this.mo("\u2211");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                munderover.appendChild(mo);
                var mrow2 = document.createElement('mrow');
                mrow2.appendChild(c2.toMathML(context));
                mrow2.appendChild(this.mo("="));
                mrow2.appendChild(c3.toMathML(context));
                munderover.appendChild(mrow2);
                munderover.appendChild(c4.toMathML(context));
                mrow.appendChild(munderover);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (c0.value == "product" && this.children != null && this.children.length == 5) {
                mrow = document.createElement('mrow');
                var munderover = document.createElement('munderover');
                var mo = this.mo("\u220F");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                munderover.appendChild(mo);
                var mrow2 = document.createElement('mrow');
                mrow2.appendChild(c2.toMathML(context));
                mrow2.appendChild(this.mo("="));
                mrow2.appendChild(c3.toMathML(context));
                munderover.appendChild(mrow2);
                munderover.appendChild(c4.toMathML(context));
                mrow.appendChild(munderover);
                if (c2.type == ENode.OPERATOR && (c2.value == "+" || c2.value == "-"))
                    mrow.appendChild(this.addP(c1, context));
                else
                    mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (c0.value == "limit") {
                mrow = document.createElement('mrow');
                if (this.children.length < 4) {
                    mrow.appendChild(this.mo("lim"));
                } else {
                    var munder = document.createElement('munder');
                    munder.appendChild(this.mo("lim"));
                    var mrowunder = document.createElement('mrow');
                    mrowunder.appendChild(c2.toMathML(context));
                    mrowunder.appendChild(this.mo("\u2192"));
                    mrowunder.appendChild(c3.toMathML(context));
                    if (c4 != null) {
                        if (c4.value == "plus")
                            mrowunder.appendChild(this.mo("+"));
                        else if (c4.value == "minus")
                            mrowunder.appendChild(this.mo("-"));
                    }
                    munder.appendChild(mrowunder);
                    mrow.appendChild(munder);
                }
                mrow.appendChild(c1.toMathML(context));
                el = mrow;
            } else if (c0.value == "binomial") {
                // displayed like a vector
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("("));
                mtable = document.createElement('mtable');
                for (i=1; i<this.children.length; i++) {
                    var mtr = document.createElement('mtr');
                    mtr.appendChild(this.children[i].toMathML(context));
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
                        mtr.appendChild(this.children[i].children[j].toMathML(context));
                    }
                    mtable.appendChild(mtr);
                }
                mrow.appendChild(mtable);
                mrow.appendChild(this.mo(")"));
                el = mrow;
            } else {
                // default display for a function
                mrow = document.createElement('mrow');
                mrow.appendChild(c0.toMathML(context));
                mrow.appendChild(this.mo("("));
                for (i=1; i<this.children.length; i++) {
                    mrow.appendChild(this.children[i].toMathML(context));
                    if (i < this.children.length - 1)
                        mrow.appendChild(this.mo(Definitions.ARG_SEPARATOR));
                }
                mrow.appendChild(this.mo(")"));
                el = mrow;
            }
            return(el);
        
        case ENode.VECTOR:
            var is_matrix = true;
            for (i=0; i<this.children.length; i++) {
                if (this.children[i].type !== ENode.VECTOR)
                    is_matrix = false;
            }
            mrow = document.createElement('mrow');
            mrow.appendChild(this.mo("("));
            mtable = document.createElement('mtable');
            for (i=0; i<this.children.length; i++) {
                var mtr = document.createElement('mtr');
                if (is_matrix) {
                    for (j=0; j<this.children[i].children.length; j++) {
                        mtr.appendChild(this.children[i].children[j].toMathML(context));
                    }
                } else {
                    mtr.appendChild(this.children[i].toMathML(context));
                }
                mtable.appendChild(mtr);
            }
            mrow.appendChild(mtable);
            mrow.appendChild(this.mo(")"));
            return(mrow);
            
        case ENode.SUBSCRIPT:
            msub = document.createElement('msub');
            msub.appendChild(c0.toMathML(context));
            if (this.children.length > 2) {
                mrow = document.createElement('mrow');
                for (i=1; i<this.children.length; i++) {
                    mrow.appendChild(this.children[i].toMathML(context));
                    if (i < this.children.length - 1)
                        mrow.appendChild(this.mo(Definitions.ARG_SEPARATOR));
                }
                msub.appendChild(mrow);
            } else {
                msub.appendChild(c1.toMathML(context));
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
 * @param {Object} [context] - display context (not needed for the root element)
 * @param {Object.<string, string>} context.hcolors - hash identifier->color
 * @param {number} context.depth - Depth in parenthesis, used for coloring
 * @returns {Element}
 */
ENode.prototype.addP = function(en, context) {
    var mrow, mo;
    mrow = document.createElement('mrow');
    mo = this.mo("(");
    mo.setAttribute("mathcolor", ENode.COLORS[context.depth % ENode.COLORS.length]);
    mrow.appendChild(mo);
    context.depth++;
    mrow.appendChild(en.toMathML(context));
    context.depth--;
    mo = this.mo(")");
    mo.setAttribute("mathcolor", ENode.COLORS[context.depth % ENode.COLORS.length]);
    mrow.appendChild(mo);
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
    ">=": "\u2265",
    "<=": "\u2264",
    
    /* other */
    "inf":  "\u221E",
    "minf": "-\u221E",
    "hbar": "\u210F",
    "G":    "\uD835\uDCA2" // 1D4A2
};
