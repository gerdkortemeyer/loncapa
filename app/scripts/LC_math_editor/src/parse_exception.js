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
