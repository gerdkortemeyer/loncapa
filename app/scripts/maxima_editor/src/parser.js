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
 * @param {boolean} [accept_bad_syntax] - assume hidden multiplication operators in some cases (unlike maxima)
 */
function Parser(accept_bad_syntax) {
    if (typeof accept_bad_syntax == "undefined")
        this.accept_bad_syntax = false;
    else
        this.accept_bad_syntax = true;
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
