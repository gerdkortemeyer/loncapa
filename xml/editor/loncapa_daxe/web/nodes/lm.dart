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
    h.SpanElement span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    span.classes.add('math');
    if (!valid)
      span.classes.add('invalid');
    span.onClick.listen((h.MouseEvent event) => makeEditable());
    updateEquationDisplay(span);
    return(span);
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
    h.SpanElement span = h.document.getElementById(id);
    updateEquationDisplay(span);
  }
  
  void updateEquationDisplay(h.SpanElement span) {
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
    for (h.Node n in span.childNodes)
      n.remove();
    try {
      js.JsObject root = parser.callMethod('parse', [equationText]);
      if (root != null) {
        h.Element math = h.document.createElement('math');
        math.setAttribute('display', nodeName == 'dlm' ? 'block' : 'inline');
        js.JsObject colors = new js.JsObject.jsify(['#000000']); // to use only black
        math.append(root.callMethod('toMathML', [colors]));
        span.append(math);
        Timer.run(() {
          js.JsArray params = new js.JsObject.jsify( ['Typeset', js.context['MathJax']['Hub'], id] );
          js.context['MathJax']['Hub'].callMethod('Queue', [params]);
          js.context['MathJax']['Hub'].callMethod('Queue', [() => page.cursor.refresh()]);
        });
      }
    } catch (e) {
      span.text = 'Error: ' + e.toString();
    }
  }
  
  void makeEditable() {
    h.SpanElement span = h.document.getElementById(id);
    if (span == null)
      return;
    h.TextInputElement input = new h.TextInputElement();
    input.classes.add('math');
    input.id = id;
    input.setAttribute('data-unit_mode', getAttribute('mode') == 'units' ? 'true' : 'false');
    input.setAttribute('data-constants', constants);
    input.setAttribute('data-implicit_operators', 'true');
    input.setAttribute('spellcheck', 'false');
    if (firstChild != null) {
      input.value = firstChild.nodeValue;
      if (input.value.length > 20)
        input.size = input.value.length;
    }
    span.replaceWith(input);
    h.SelectElement select = new h.SelectElement();
    select.id = id + '_mode';
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
    if (input.nextNode == null)
      input.parent.append(select);
    else
      input.parent.insertBefore(select, input.nextNode);
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
      span = html();
      input.replaceWith(span);
      select.remove();
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
    input.onKeyDown.listen((h.KeyboardEvent event) {
      String equationText = input.value;
      int inputSize = input.size;
      if (equationText != null && equationText.length > inputSize)
        input.size = equationText.length;
    });
  }
}
