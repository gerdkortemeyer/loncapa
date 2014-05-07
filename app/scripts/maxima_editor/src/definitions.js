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

