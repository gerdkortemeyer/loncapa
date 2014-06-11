/**
 * @license Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here.
	// For the complete reference:
	// http://docs.ckeditor.com/#!/api/CKEDITOR.config

	// The toolbar groups arrangement, optimized for two toolbar rows.
	config.toolbarGroups = [
		{ name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
		{ name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
		{ name: 'links' },
		{ name: 'insert' },
		{ name: 'forms' },
		{ name: 'tools' },
		{ name: 'document',	   groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'others' },
		'/',
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'paragraph',   groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
		{ name: 'styles' },
		{ name: 'colors' },
		{ name: 'about' }
	];

	// Remove some buttons, provided by the standard plugins, which we don't
	// need to have in the Standard(s) toolbar.
	config.removeButtons = 'Underline,Subscript,Superscript';

	// Se the most common block elements.
	config.format_tags = 'p;h1;h2;h3;pre';

	// Make dialogs simpler.
	config.removeDialogTabs = 'image:advanced;link:advanced';


    // Use the document language
    config.language=document.documentElement.lang;

    config.extraPlugins = 'lcmath';
    
    config.mathJaxLib = '/scripts/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML';

    config.specialChars = [
        /* upercase greek */
            ["\u0393", "Gamma"], ["\u0394", "Delta"], ["\u0398", "Theta"], ["\u039B", "Lamda"],
            ["\u039E", "Xi"], ["\u03A0", "Pi"], ["\u03A3", "Sigma"], ["\u03A5", "Upsilon"],
            ["\u03A6", "Phi"], ["\u03A7", "Chi"], ["\u03A8", "Psi"], ["\u03A9", "Omega"],
            "", "", "", "", "",
        /* lowercase greek */
            ["\u03B1", "alpha"], ["\u03B2", "beta"], ["\u03B3", "gamma"], ["\u03B4", "delta"],
            ["\u03B5", "epsilon"], ["\u03B6", "zeta"], ["\u03B7", "eta"], ["\u03B8", "theta"],
            ["\u03B9", "iota"], ["\u03BA", "kappa"], ["\u03BB", "lambda"], ["\u03BC", "mu"],
            ["\u03BD", "nu"], ["\u03BE", "xi"], ["\u03BF", "omicron"], ["\u03C0", "pi"],
            ["\u03C1", "rho"], ["\u03C2", "final sigma"], ["\u03C3", "sigma"],
            ["\u03C4", "tau"], ["\u03C5", "upsilon"], ["\u03C6", "phi"], ["\u03C7", "chi"],
            ["\u03C8", "psi"], ["\u03C9", "omega"],
            "", 
        /* greek symbols */
            ["\u03D1", "theta symbol"], ["\u03D5", "phi symbol"], ["\u03D6", "pi symbol"],
            "", "", "", "", "",
        /* maths */
            ["\u00AC", "not"], ["\u00B1", "plus-minus"], ["\u00D7", "multiplication"], ["\u2113", "script l"],
            ["\u2102", "double-struck C"], ["\u2115", "double-struck N"], ["\u211A", "double-struck Q"],
            ["\u211D", "double-struck R"], ["\u2124", "double-struck Z"], ["\u212B", "Angstrom"],
            ["\u2190", "leftwards arrow"], ["\u2192", "rightwards arrow"], ["\u2194", "left right arrow"],
            ["\u21D0", "leftwards double arrow"], ["\u21D2", "rightwards double arrow"],
            ["\u21D4", "left right double arrow"],
            ["\u2200", "for all"], ["\u2202", "partial differential"], ["\u2203", "there exists"],
            ["\u2205", "empty set"], ["\u2207", "nabla"], ["\u2208", "element of"],
            ["\u2209", "not an element of"], ["\u2211", "n-ary summation"], ["\u221D", "proportional to"],
            ["\u221E", "infinity"], ["\u2227", "logical and"], ["\u2228", "logical or"],
            ["\u2229", "intersection"], ["\u222A", "union"], ["\u222B", "integral"],
            ["\u223C", "tilde operator"], ["\u2248", "almost equal to"], ["\u2260", "not equal to"],
            ["\u2261", "identical to"], ["\u2264", "less-than or equal to"],
            ["\u2265", "greater-than or equal to"], ["\u2282", "subset of"],
            "", "", "", "", "", "", "", "", "", "", "", "", "",
        /* cursive uppercase */
            ["\uD835\uDC9C", "script A"], ["\u212C", "script B"], ["\uD835\uDC9E", "script C"],
            ["\uD835\uDC9F", "script D"], ["\u2130", "script E"], ["\u2131", "script F"],
            ["\uD835\uDCA2", "script G"], ["\u210B", "script H"], ["\u2110", "script I"],
            ["\uD835\uDCA5", "script J"], ["\uD835\uDCA6", "script K"], ["\u2112", "script L"],
            ["\u2133", "script M"], ["\uD835\uDCA9", "script N"], ["\uD835\uDCAA", "script O"],
            ["\uD835\uDCAB", "script P"], ["\uD835\uDCAC", "script Q"], ["\u211B", "script R"],
            ["\uD835\uDCAE", "script S"], ["\uD835\uDCAF", "script T"], ["\uD835\uDCB0", "script U"],
            ["\uD835\uDCB1", "script V"], ["\uD835\uDCB2", "script W"], ["\uD835\uDCB3", "script X"],
            ["\uD835\uDCB4", "script Y"], ["\uD835\uDCB5", "script Z"]
        ];
};
