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

var gnuplotjs = new Gnuplot(gnuplotjs_url);
gnuplotjs.onOutput = function(text) {
    console.log('output from gnuplot: ' + text);
};
gnuplotjs.onError = function(text) {
    console.log('error in gnuplot: ' + text);
};

function run_gnuplot_script(gnuplot_script, canvas_id) {
    var generated_js_filename = "out.js";
    var canvas = document.getElementById(canvas_id);
    gnuplot_script = "set terminal canvas size "+canvas.width+","+canvas.height+" name '"+canvas_id+"'\n"  +
        "set output '"+generated_js_filename+"'\n" + gnuplot_script;
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
            // comment out a bug in gnuplot generated JS:
            str = str.replace('if (canvas.attachEvent) {', '//if (canvas.attachEvent) {');
            str = str.replace('else if (canvas.addEventListener)', '//else if (canvas.addEventListener)');
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
