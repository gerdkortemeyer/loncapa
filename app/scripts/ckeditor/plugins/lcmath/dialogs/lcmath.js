/**
 * @license Copyright (c) 2014, CKSource - Michigan State University Board of Trustees.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

'use strict';

CKEDITOR.dialog.add( 'lcmath', function( editor ) {

	var preview,
		lang = editor.lang.lcmath;

	return {
		title: lang.title,
		minWidth: 350,
		minHeight: 100,
		contents: [
			{
				id: 'info',
				elements: [
					{
						id: 'equation',
						type: 'textarea',
						label: lang.dialogInput,

						onLoad: function( widget ) {
							var that = this;

							if ( !( CKEDITOR.env.ie && CKEDITOR.env.version == 8 ) ) {
								this.getInputElement().on( 'keyup', function() {
									preview.setValue( that.getInputElement().getValue() );
								} );
							}
						},

						setup: function( widget ) {
							this.setValue( widget.data.math );
						},

						commit: function( widget ) {
							widget.setData( 'math', this.getValue() );
						}
					},
					{
						id: 'documentation',
						type: 'html',
						html:
							'<div style="width:100%;text-align:right;margin:-8px 0 10px">' +
								'<a class="cke_lcmath_doc" href="' + lang.docUrl + '" target="_black" style="cursor:pointer;color:#00B2CE;text-decoration:underline">' +
									lang.docLabel +
								'</a>' +
							'</div>'
					},
					( !( CKEDITOR.env.ie && CKEDITOR.env.version == 8 ) ) && {
						id: 'preview',
						type: 'html',
						html:
							'<div style="width:100%;text-align:center;">' +
								'<iframe style="border:0;width:0;height:0;font-size:20px" scrolling="no" frameborder="0" allowTransparency="true" src="' + CKEDITOR.plugins.lcmath.fixSrc + '"></iframe>' +
							'</div>',

						onLoad: function( widget ) {
							var iFrame = CKEDITOR.document.getById( this.domId ).getChild( 0 );
							preview = new CKEDITOR.plugins.lcmath.frameWrapper( iFrame, editor );
						},

						setup: function( widget ) {
							preview.setValue( widget.data.math );
						}
					}
				]
			}
		]
	};
} );
