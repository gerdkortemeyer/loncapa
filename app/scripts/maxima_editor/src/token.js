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
