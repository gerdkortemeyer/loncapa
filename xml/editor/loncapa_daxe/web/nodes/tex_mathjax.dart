/*
  This file is part of LONCAPA-Daxe.

  LONCAPA-Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  LONCAPA-Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

part of loncapa_daxe;

/**
 * Displays tm and dtm elements (LaTeX inline and display math) with MathJax.
 * Jaxe display type: 'texmathjax'.
 */
class TeXMathJax extends DaxeNode {
  
  TeXMathJax.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  TeXMathJax.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
  }
  
  @override
  h.Element html() {
    h.SpanElement span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    if (!valid)
      span.classes.add('invalid');
    span.classes.add('tex');
    span.onClick.listen((h.MouseEvent event) => editDialog(() => updateEquationDisplay()));
    return(span);
  }
  
  @override
  void newNodeCreationUI(ActionFunction okfct) {
    editDialog(() => okfct());
  }
  
  @override
  Position firstCursorPositionInside() {
    return(null);
  }
  
  @override
  Position lastCursorPositionInside() {
    return(null);
  }
  
  @override
  void afterInsert() {
    updateEquationDisplay();
  }
  
  void updateEquationDisplay() {
    if (firstChild != null) {
      String equationText = firstChild.nodeValue;
      js.JsObject queue = js.context['MathJax']['Hub']['Queue'];
      h.SpanElement span = h.document.getElementById(id);
      span.text = convertForMathJaxe(equationText);
      js.JsArray params = new js.JsObject.jsify( ['Typeset', js.context['MathJax']['Hub'], id] );
      js.context['MathJax']['Hub'].callMethod('Queue', [params]);
    }
  }
  
  void editDialog([ActionFunction okfct]) {
    TeXMathJaxeDialog dlg = new TeXMathJaxeDialog(this, okfct);
    dlg.show();
  }
  
  String convertForMathJaxe(String text) {
    bool hasDelimiters = false;
    js.JsObject queue = js.context['MathJax']['Hub']['Queue'];
    if (nodeName == 'dtm')
      text = "\\[$text\\]";
    else
      text = "\\($text\\)";
    return(text);
  }
}


class TeXMathJaxeDialog {
  TeXMathJax dn;
  ActionFunction _okfct;
  TeXMathJaxeDialog(this.dn, [this._okfct]) {
  }
  
  void show() {
    h.DivElement div1 = new h.DivElement();
    div1.id = 'dlg1';
    div1.classes.add('dlg1');
    h.DivElement div2 = new h.DivElement();
    div2.classes.add('dlg2');
    h.DivElement div3 = new h.DivElement();
    div3.classes.add('dlg3');
    h.FormElement form = new h.FormElement();
    
    h.TextAreaElement ta = new h.TextAreaElement();
    ta.id = 'eqtext';
    if (dn.firstChild != null)
      ta.value = dn.firstChild.nodeValue.trim();
    ta.style.width = '100%';
    ta.style.height = '4em';
    ta.attributes['spellcheck'] = 'false';
    ta.onInput.listen((h.Event event) => input());
    form.append(ta);
    
    h.DivElement preview = new h.DivElement();
    preview.id = 'preview';
    form.append(preview);
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bCancel = new h.ButtonElement();
    bCancel.attributes['type'] = 'button';
    bCancel.appendText(Strings.get("button.Cancel"));
    bCancel.onClick.listen((h.MouseEvent event) => div1.remove());
    div_buttons.append(bCancel);
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.attributes['type'] = 'submit';
    bOk.appendText(Strings.get("button.OK"));
    bOk.onClick.listen((h.MouseEvent event) => ok(event));
    div_buttons.append(bOk);
    form.append(div_buttons);
    
    div3.append(form);
    div2.append(div3);
    div1.append(div2);
    h.document.body.append(div1);
    
    ta.focus();
    input();
  }
  
  void ok(h.MouseEvent event) {
    h.TextAreaElement ta = h.querySelector('textarea#eqtext');
    String equationText = ta.value;
    if (equationText != '') {
      if (dn.firstChild != null)
        dn.firstChild.nodeValue = equationText;
      else
        dn.appendChild(new DNText(equationText));
    } else {
      if (dn.firstChild != null)
        dn.removeChild(dn.firstChild);
    }
    h.querySelector('div#dlg1').remove();
    if (event != null)
      event.preventDefault();
    if (_okfct != null)
      _okfct();
  }
  
  void input() {
    h.TextAreaElement ta = h.querySelector('textarea#eqtext');
    String text = ta.value;
    /* newlines allowed -> must use button to insert equations
    if (text.length > 0 && text.contains('\n')) {
      ta.value = text.replaceAll('\n', '');
      ok(null);
      return;
    }
    */
    h.DivElement previewDiv = h.document.getElementById('preview');
    /* this does not work bec. the initial text has not been processed before
    js.JsObject queue = js.context['MathJax']['Hub']['queue'];
    //math = MathJax.Hub.getAllJax("MathOutput")[0]
    js.JsArray all = js.context['MathJax']['Hub'].callMethod('getAllJax', ['preview']);
    js.JsObject math = all[0];
    // MathJax.Hub.queue.Push(['Text', math, "\\displaystyle{$text}"]);
    js.JsObject params = new js.JsObject.jsify(['Text', math, "\\displaystyle{$text}"]);
    queue.callMethod('Push', [params]);
    */
    previewDiv.text = dn.convertForMathJaxe(text);
    js.JsArray params = new js.JsObject.jsify( ['Typeset', js.context['MathJax']['Hub'], 'preview'] );
    js.context['MathJax']['Hub'].callMethod('Queue', [params]);
    
  }
}
