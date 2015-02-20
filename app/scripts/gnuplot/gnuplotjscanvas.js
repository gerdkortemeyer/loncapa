// This file provides functions to run Emscripten gnuplot (gnuplot-JS) with a canvas terminal, and draw the plot in a canvas.
// It requires gnuplot.js, gnuplot_api.js, gnuplot_common.js, gnuplot_mouse.js, canvastext.js and canvasmath.js.
// It also requires the URL to gnuplot.js to be in the variable gnuplotjs_url BEFORE this script is executed.
// main function: run_gnuplot_script(gnuplot_script, canvas_id)

function Uint8ToString(u8a) {
    // NOTE: using just String.fromCharCode.apply(null, u8a) would generate RangeError in Chrome
    // This is why we split the task in chunks here
    var CHUNK_SZ = 0x8000;
    var c = [];
    for (var i=0; i < u8a.length; i+=CHUNK_SZ) {
        c.push(String.fromCharCode.apply(null, u8a.subarray(i, i+CHUNK_SZ)));
    }
    return c.join("");
}

function gnuplot_canvas( plot ) { gnuplot.active_plot(); };

function run_gnuplot_script(gnuplot_script, canvas_id) {
    var generated_js_filename = "out_"+canvas_id+".js"; // NOTE: should be the same in lc_xml_lonplot.pm
    var gnuplotjs = new Gnuplot(gnuplotjs_url);
    gnuplotjs.onOutput = function(text) {
        console.log('output from gnuplot: ' + text);
    };
    gnuplotjs.onError = function(text) {
        console.log('error in gnuplot: ' + text);
    };
    gnuplotjs.run(gnuplot_script, function(e) {
        gnuplotjs.getFile(generated_js_filename, function(e) {
            if (!e.content) {
                gnuplotjs.onError("Output file " + generated_js_filename + " not found!");
                return;
            }
            // convert result to a string
            var ab = new Uint8Array(e.content);
            var str = Uint8ToString(ab);
            str = decodeURIComponent(escape(str)); // trying to get UTF-8 (NOTE: this is a hack)
            // Fix for a bug in gnuplot generated JS: on mouseover, re-display on top of previous display (very ugly for transparent plots).
            // We can't really fix that cleanly, because the stupid gnuplot_mouse.js script is using global variables
            // instead of plot-specific variables, as if there was only one plot in the document.
            // So the plot *has* to be re-initialized and re-drawn on mouseover when another plot was selected (but not otherwise).
            // (this bug is actually visible on the gnuplot 4.6 demos with the canvas terminal, but it is fixed in version 5)
            str = str.replace('if (canvas.attachEvent) {canvas.attachEvent(\'mouseover\', '+canvas_id+');}', ''); // forget old IE
            str = str.replace('else if (canvas.addEventListener) {canvas.addEventListener(\'mouseover\', '+canvas_id+', false);}',
                              'canvas.addEventListener(\'mouseover\', function(e){'+
                                'if (gnuplot.active_plot != '+canvas_id+')'+
                                canvas_id+'();'+
                              '}, false);');
            // add the script
            var script = document.createElement('script');
            script.textContent = str;
            document.body.appendChild(script);
            // clear canvas and run the function in the script
            var canvas = document.getElementById(canvas_id);
            var ctx = canvas.getContext("2d");
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            // call the function with the canvas_id name
            window[canvas_id]();
        });
    });
};
