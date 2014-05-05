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
 * Parsed tree node. ENode.toMathML() contains the code for the transformation into MathML.
 * @constructor
 * @param {number} type - ENode.UNKNOWN | NAME | NUMBER | OPERATOR | FUNCTION | VECTOR
 * @param {Operator} op - The operator
 * @param {string} value - Node value as a string or function name, null for type 5
 * @param {Array.<ENode>} children - The children nodes, only for types OPERATOR, FUNCTION, VECTOR
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
 * Transforms this ENode into a MathML HTML DOM element.
 * @returns {Element}
 */
ENode.prototype.toMathML = function() {
    var c0, c1, c2, c3, i, j, el, par, mrow, mo, mtable, mfrac;
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
    
    switch (this.type) {
        case ENode.UNKNOWN:
            el = document.createElement('mtext');
            el.appendChild(document.createTextNode("???"));
            return(el);
        
        case ENode.NAME:
            return(this.mi(this.value));
        
        case ENode.NUMBER:
            el = document.createElement('mn');
            el.appendChild(document.createTextNode(this.value));
            return(el);
        
        case ENode.OPERATOR:
            if (this.value == "/") {
                mfrac = document.createElement('mfrac');
                mfrac.appendChild(c0.toMathML());
                mfrac.appendChild(c1.toMathML());
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
                    el.appendChild(this.addP(c0));
                else
                    el.appendChild(c0.toMathML());
                el.appendChild(c1.toMathML());
            } else if (this.value == "*") {
                mrow = document.createElement('mrow');
                if (c0.type == ENode.OPERATION && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                // should the x operator be visible ? We need to check if there is a number to the left of c1
                var firstinc1 = c1;
                while (firstinc1.type == ENode.OPERATION) {
                    firstinc1 = firstinc1.children[0];
                }
                if (firstinc1.type == ENode.NUMBER)
                    mrow.appendChild(this.mo("\u22C5"));
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c1));
                else
                    mrow.appendChild(c1.toMathML());
                el = mrow;
            } else if (this.value == "-") {
                mrow = document.createElement('mrow');
                if (this.children.length == 1) {
                    mrow.appendChild(this.mo("-"));
                    mrow.appendChild(c0.toMathML());
                } else {
                    mrow.appendChild(c0.toMathML());
                    mrow.appendChild(this.mo("-"));
                    if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                        mrow.appendChild(this.addP(c1));
                    else
                        mrow.appendChild(c1.toMathML());
                }
                el = mrow;
            } else if (this.value == "!") {
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                mrow.appendChild(mo);
                el = mrow;
            } else if (this.value == "+") {
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                mrow.appendChild(c0.toMathML());
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
                    mrow.appendChild(this.addP(c1));
                else
                    mrow.appendChild(c1.toMathML());
                el = mrow;
            } else {
                // relational operators
                mrow = document.createElement('mrow');
                mo = this.mo(this.value);
                mrow.appendChild(c0.toMathML());
                mrow.appendChild(mo);
                mrow.appendChild(c1.toMathML());
                el = mrow;
            }
            return(el);
        
        case ENode.FUNCTION: /* TODO: throw exceptions if wrong nb of args ? */
            if (this.value == "sqrt" && c0 != null) {
                el = document.createElement('msqrt');
                el.appendChild(c0.toMathML());
            } else if (this.value == "abs" && c0 != null) {
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("|"));
                mrow.appendChild(c0.toMathML());
                mrow.appendChild(this.mo("|"));
                el = mrow;
            } else if (this.value == "exp" && c0 != null) {
                el = document.createElement('msup');
                el.appendChild(this.mi("e"));
                el.appendChild(c0.toMathML());
            } else if (this.value == "factorial") {
                mrow = document.createElement('mrow');
                mo = this.mo("!");
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                mrow.appendChild(mo);
                el = mrow;
            } else if (this.value == "diff" && this.children != null && this.children.length == 2) {
                mrow = document.createElement('mrow');
                mfrac = document.createElement('mfrac');
                mfrac.appendChild(this.mi("d"));
                var f2 = document.createElement('mrow');
                f2.appendChild(this.mi("d"));
                f2.appendChild(this.mi(c1.value));
                mfrac.appendChild(f2);
                mrow.appendChild(mfrac);
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                el = mrow;
            } else if (this.value == "diff" && this.children != null && this.children.length == 3) {
                mrow = document.createElement('mrow');
                mfrac = document.createElement('mfrac');
                var msup = document.createElement('msup');
                msup.appendChild(this.mi("d"));
                msup.appendChild(c2.toMathML());
                mfrac.appendChild(msup);
                var f2 = document.createElement('mrow');
                f2.appendChild(this.mi("d"));
                msup = document.createElement('msup');
                msup.appendChild(c1.toMathML());
                msup.appendChild(c2.toMathML());
                f2.appendChild(msup);
                mfrac.appendChild(f2);
                mrow.appendChild(mfrac);
                if (c0.type == ENode.OPERATOR && (c0.value == "+" || c0.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                el = mrow;
            } else if (this.value == "integrate" && this.children != null && this.children.length == 2) {
                mrow = document.createElement('mrow');
                var mo = this.mo("\u222B");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                mrow.appendChild(mo);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                mrow.appendChild(this.mi("d"));
                mrow.appendChild(c1.toMathML());
                el = mrow;
            } else if (this.value == "integrate" && this.children != null && this.children.length == 4) {
                mrow = document.createElement('mrow');
                var msubsup = document.createElement('msubsup');
                var mo = this.mo("\u222B");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                msubsup.appendChild(mo);
                msubsup.appendChild(c2.toMathML());
                msubsup.appendChild(c3.toMathML());
                mrow.appendChild(msubsup);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                mrow.appendChild(this.mi("d"));
                mrow.appendChild(c1.toMathML());
                el = mrow;
            } else if (this.value == "sum" && this.children != null && this.children.length == 4) {
                mrow = document.createElement('mrow');
                var munderover = document.createElement('munderover');
                var mo = this.mo("\u2211");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                munderover.appendChild(mo);
                var mrow2 = document.createElement('mrow');
                mrow2.appendChild(c1.toMathML());
                mrow2.appendChild(this.mo("="));
                mrow2.appendChild(c2.toMathML());
                munderover.appendChild(mrow2);
                munderover.appendChild(c3.toMathML());
                mrow.appendChild(munderover);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                el = mrow;
            } else if (this.value == "product" && this.children != null && this.children.length == 4) {
                mrow = document.createElement('mrow');
                var munderover = document.createElement('munderover');
                var mo = this.mo("\u220F");
                mo.setAttribute("stretchy", "true"); // doesn't work with MathJax
                munderover.appendChild(mo);
                var mrow2 = document.createElement('mrow');
                mrow2.appendChild(c1.toMathML());
                mrow2.appendChild(this.mo("="));
                mrow2.appendChild(c2.toMathML());
                munderover.appendChild(mrow2);
                munderover.appendChild(c3.toMathML());
                mrow.appendChild(munderover);
                if (c1.type == ENode.OPERATOR && (c1.value == "+" || c1.value == "-"))
                    mrow.appendChild(this.addP(c0));
                else
                    mrow.appendChild(c0.toMathML());
                el = mrow;
            } else if (this.value == "limit") {
                mrow = document.createElement('mrow');
                if (this.children.length < 3) {
                    mrow.appendChild(this.mo("lim"));
                } else {
                    var munder = document.createElement('munder');
                    munder.appendChild(this.mo("lim"));
                    var mrowunder = document.createElement('mrow');
                    mrowunder.appendChild(c1.toMathML());
                    mrowunder.appendChild(this.mo("\u2192"));
                    mrowunder.appendChild(c2.toMathML());
                    if (c3 != null) {
                        if (c3.value == "plus")
                            mrowunder.appendChild(this.mo("+"));
                        else if (c3.value == "minus")
                            mrowunder.appendChild(this.mo("-"));
                    }
                    munder.appendChild(mrowunder);
                    mrow.appendChild(munder);
                }
                mrow.appendChild(c0.toMathML());
                el = mrow;
            } else if (this.value == "binomial") {
                // displayed like a vector
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mo("("));
                mtable = document.createElement('mtable');
                for (i=0; i<this.children.length; i++) {
                    var mtr = document.createElement('mtr');
                    mtr.appendChild(this.children[i].toMathML());
                    mtable.appendChild(mtr);
                }
                mrow.appendChild(mtable);
                mrow.appendChild(this.mo(")"));
                el = mrow;
            } else if (this.value == "matrix") {
                for (i=0; i<this.children.length; i++) {
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
                for (i=0; i<this.children.length; i++) {
                    var mtr = document.createElement('mtr');
                    for (j=0; j<this.children[i].children.length; j++) {
                        mtr.appendChild(this.children[i].children[j].toMathML());
                    }
                    mtable.appendChild(mtr);
                }
                mrow.appendChild(mtable);
                mrow.appendChild(this.mo(")"));
                el = mrow;
            } else {
                // default display for a function
                mrow = document.createElement('mrow');
                mrow.appendChild(this.mi(this.value));
                mrow.appendChild(this.mo("("));
                for (i=0; i<this.children.length; i++) {
                    mrow.appendChild(this.children[i].toMathML());
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
                mtr.appendChild(this.children[i].toMathML());
                mtable.appendChild(mtr);
            }
            mrow.appendChild(mtable);
            mrow.appendChild(this.mo(")"));
            return(mrow);
    }
};

/**
 * Creates a MathML mi element with the given name
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
 * Creates a MathML mo element with the given name
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
 * @returns {Element}
 */
ENode.prototype.addP = function(en) {
    var mrow = document.createElement('mrow');
    mrow.appendChild(this.mo("("));
    mrow.appendChild(en.toMathML());
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
