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
 * Displays lm and dlm elements (LON-CAPA inline and display math).
 * Jaxe display type: 'lm'.
 */
class Lm extends DaxeNode {
  
  static String constants = 'c, pi, e, hbar, amu';
  static js.JsObject parser_symbols;
  static js.JsObject parser_units;
  
  Lm.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  Lm.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
  }
  
  @override
  h.Element html() {
    h.Element el;
    if (nodeName == 'dlm')
      el = new h.DivElement();
    else
      el = new h.SpanElement();
    el.id = "$id";
    el.classes.add('dn');
    el.classes.add('math');
    if (!valid)
      el.classes.add('invalid');
    el.onClick.listen((h.MouseEvent event) => makeEditable());
    updateEquationDisplay(el);
    return(el);
  }
  
  @override
  void newNodeCreationUI(ActionFunction okfct) {
    okfct();
    makeEditable();
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
    h.Element el = h.document.getElementById(id);
    updateEquationDisplay(el);
  }
  
  void updateEquationDisplay(h.Element el) {
    String equationText = '?';
    if (firstChild != null && firstChild.nodeValue.trim() != '')
      equationText = firstChild.nodeValue;
    js.JsObject parser;
    if (getAttribute('mode') == 'units') {
      if (parser_units == null)
        parser_units = new js.JsObject(js.context['LCMATH']['Parser'], [true, true, constants]);
      parser = parser_units;
    } else {
      if (parser_symbols == null)
        parser_symbols = new js.JsObject(js.context['LCMATH']['Parser'], [true, false, constants]);
      parser = parser_symbols;
    }
    for (h.Node n in el.childNodes)
      n.remove();
    try {
      js.JsObject root = parser.callMethod('parse', [equationText]);
      if (root != null) {
        h.Element math = h.document.createElement('math');
        math.setAttribute('display', nodeName == 'dlm' ? 'block' : 'inline');
        js.JsObject colors = new js.JsObject.jsify(['#000000']); // to use only black
        math.append(root.callMethod('toMathML', [colors]));
        el.append(math);
        Timer.run(() {
          js.JsArray params = new js.JsObject.jsify( ['Typeset', js.context['MathJax']['Hub'], id] );
          js.context['MathJax']['Hub'].callMethod('Queue', [params]);
          js.context['MathJax']['Hub'].callMethod('Queue', [() => page.cursor.refresh()]);
        });
      }
    } catch (e) {
      el.text = 'Error: ' + e.toString();
    }
  }
  
  void makeEditable() {
    h.Element el = h.document.getElementById(id);
    if (el == null)
      return;
    h.Element editEl;
    if (nodeName == 'dlm')
      editEl = new h.DivElement();
    else
      editEl = new h.SpanElement();
    editEl.id = id;
    h.TextInputElement input = new h.TextInputElement();
    input.classes.add('math');
    input.setAttribute('data-unit_mode', getAttribute('mode') == 'units' ? 'true' : 'false');
    input.setAttribute('data-constants', constants);
    input.setAttribute('data-implicit_operators', 'true');
    input.setAttribute('spellcheck', 'false');
    if (firstChild != null) {
      input.value = firstChild.nodeValue;
      if (input.value.length > 20)
        input.size = input.value.length;
    }
    editEl.append(input);
    h.SelectElement select = new h.SelectElement();
    h.OptionElement symbolsOption = new h.OptionElement();
    symbolsOption.value = 'symbols';
    symbolsOption.appendText(LCDStrings.get('lm_symbols'));
    if (getAttribute('mode') != 'units')
      symbolsOption.setAttribute('selected', 'selected');
    select.append(symbolsOption);
    h.OptionElement unitsOption = new h.OptionElement();
    unitsOption.value = 'units';
    unitsOption.appendText(LCDStrings.get('lm_units'));
    if (getAttribute('mode') == 'units')
      unitsOption.setAttribute('selected', 'selected');
    select.append(unitsOption);
    select.onInput.listen((h.Event event) {
      if (select.value == 'symbols' && getAttribute('mode') == 'units') {
        setAttribute('mode', 'symbols');
        input.setAttribute('data-unit_mode', 'false');
        js.context['LCMATH'].callMethod('initEditors');
      } else if (select.value == 'units' && getAttribute('mode') != 'units') {
        setAttribute('mode', 'units');
        input.setAttribute('data-unit_mode', 'true');
        js.context['LCMATH'].callMethod('initEditors');
      }
      input.focus();
    });
    editEl.append(select);
    el.replaceWith(editEl);
    input.focus();
    js.context['LCMATH'].callMethod('initEditors');
    var switchDisplay = () {
      String equationText = input.value;
      if (equationText != '') {
        if (firstChild != null)
          firstChild.nodeValue = equationText;
        else
          appendChild(new DNText(equationText));
      } else {
        if (firstChild != null)
          removeChild(firstChild);
      }
      editEl.replaceWith(html());
    };
    input.onBlur.listen((h.Event event) {
      Timer.run(() { // timer so that activeElement is updated
        if (h.document.activeElement == select)
          return;
        switchDisplay();
      });
    });
    select.onBlur.listen((h.Event event) {
      Timer.run(() {
        if (h.document.activeElement == input)
          return;
        switchDisplay();
      });
    });
    if (editEl is h.DivElement) {
      editEl.onClick.listen((h.MouseEvent event) {
        if (event.target != input && event.target != select) {
          page.moveCursorTo(new Position(parent, parent.offsetOf(this)+1));
        }
      });
    }
    input.onKeyDown.listen((h.KeyboardEvent event) {
      String equationText = input.value;
      int inputSize = input.size;
      if (equationText != null && equationText.length > inputSize)
        input.size = equationText.length;
    });
  }
}
