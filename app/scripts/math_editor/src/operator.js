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
