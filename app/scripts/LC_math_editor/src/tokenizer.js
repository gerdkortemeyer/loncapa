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
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= 'α' && c <= 'ω') || (c >= 'Α' && c <= 'Ω') || c == 'µ') {
            value = c;
            i++;
            for (;;) {
                c = this.text.charAt(i);
                if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                        (c >= 'α' && c <= 'ω') || (c >= 'Α' && c <= 'Ω') || c == 'µ' ||
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
