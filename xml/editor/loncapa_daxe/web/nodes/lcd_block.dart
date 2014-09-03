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
 * Generic block element for LON-CAPA
 * Attributes can be edited directly in it.
 * Buttons can be used to collapse the element and the attribute fields.
 * Jaxe display type: 'lcdblock'.
 */
class LCDBlock extends DaxeNode {
  
  List<x.Element> attRefs;
  int state; // 0 = editable attributes, 1 = non-editable attributes, 2 = collapsed element
  HashMap<String, SimpleTypeControl> attributeControls;
  HashMap<DaxeAttr, h.TextInputElement> unknownAttributeFields;
  bool hasContent;
  LCDButton bEditable, bNormal, bCollapsed;
  
  
  LCDBlock.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    state = 0;
    init();
  }
  
  LCDBlock.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    // replace CDATA sections by text
    DaxeNode child = firstChild;
    while (child != null) {
      DaxeNode next = child.nextSibling;
      if (child is DNCData) {
        if (child.previousSibling is DNText && child.previousSibling.nodeValue == '\n')
          removeChild(child.previousSibling);
        if (child.nextSibling is DNText && child.nextSibling.nodeValue == '\n') {
          next = child.nextSibling.nextSibling;
          removeChild(child.nextSibling);
        }
        String text;
        if (child.firstChild != null)
          text = child.firstChild.nodeValue;
        else
          text = null;
        if (text != null)
          insertBefore(new DNText(text), child);
        removeChild(child);
      }
      child = next;
    }
    normalize();
    state = 1;
    init();
    fixLineBreaks();
  }
  
  void init() {
    attRefs = doc.cfg.elementAttributes(ref);
    if (attRefs.length > 0)
      attributeControls = new HashMap<String, SimpleTypeControl>();
    unknownAttributeFields = null;
    hasContent = doc.cfg.canContainText(ref) || doc.cfg.subElements(ref).length > 0;
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    if (!valid)
      div.classes.add('invalid');
    div.classes.add('lcdblock');
    h.DivElement headerDiv = new h.DivElement();
    headerDiv.classes.add('lcdblock-header');
    
    h.DivElement titleDiv = new h.DivElement();
    h.DivElement buttonBox = new h.DivElement();
    buttonBox.classes.add('lcd-button-box');
    bCollapsed = new LCDButton(LCDStrings.get('lcdblock_collapsed'), 'block_collapsed.png',
        () {
      collapsedView();
    }, selected: (state == 2));
    buttonBox.append(bCollapsed.html());
    bNormal = new LCDButton(LCDStrings.get('lcdblock_normal'), 'block_normal.png',
        () {
      normalView();
    }, selected: (state == 1));
    buttonBox.append(bNormal.html());
    bEditable = new LCDButton(LCDStrings.get('lcdblock_editable'), 'block_editable.png',
        () {
      editableView();
    }, enabled: attRefs.length > 0, selected: (state == 0));
    buttonBox.append(bEditable.html());
    titleDiv.append(buttonBox);
    
    h.SpanElement titleSpan = new h.SpanElement();
    titleSpan.classes.add('lcdblock-title');
    titleSpan.append(new h.Text(doc.cfg.elementTitle(ref)));
    titleSpan.onDoubleClick.listen((h.MouseEvent event) {
      page.selectNode(this);
    });
    titleDiv.append(titleSpan);
    
    titleDiv.append(makeHelpButton(ref, null));
    headerDiv.append(titleDiv);
    
    if (state == 0) {
      h.TableElement table = new h.TableElement();
      table.classes.add('expand');
      for (x.Element refAttr in attRefs) {
        table.append(attributeHTML(refAttr));
      }
      for (DaxeAttr att in attributes) {
        bool found = false;
        for (x.Element attref in attRefs) {
          if (att.localName == doc.cfg.attributeName(attref) &&
              att.namespaceURI == doc.cfg.attributeNamespace(attref)) {
            found = true;
            break;
          }
        }
        if (!found) {
          table.append(unknownAttributeHTML(att));
        }
      }
      headerDiv.append(table);
    } else if (state == 1) {
      h.DivElement attDiv = new h.DivElement();
      attDiv.classes.add('lcdblock-attributes');
      for (DaxeAttr att in attributes) {
        attDiv.append(new h.Text(" "));
        h.Element att_name = new h.SpanElement();
        att_name.attributes['class'] = 'attribute_name';
        att_name.text = att.localName;
        attDiv.append(att_name);
        attDiv.append(new h.Text("="));
        h.Element att_val = new h.SpanElement();
        att_val.attributes['class'] = 'attribute_value';
        att_val.text = att.value;
        attDiv.append(att_val);
      }
      attDiv.onClick.listen((h.MouseEvent event) {
        editableView();
      });
      headerDiv.append(attDiv);
    }
    div.append(headerDiv);
    if (state != 2 && hasContent) {
      h.DivElement contents = new h.DivElement();
      contents.id = 'contents-' + id;
      contents.classes.add('indent');
      contents.classes.add('lcdblock-content');
      setStyle(contents);
      DaxeNode dn = firstChild;
      while (dn != null) {
        contents.append(dn.html());
        dn = dn.nextSibling;
      }
      if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
        contents.appendText('\n');
      //this kind of conditional HTML makes it hard to optimize display updates:
      //we have to override updateHTMLAfterChildrenChange
      // also, it seems that in IE this adds a BR instead of a text node !
      div.append(contents);
    }
    return(div);
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTMLAfterChildrenChange(changed);
    if (hasContent && state != 2) {
      h.DivElement contents = getHTMLContentsNode();
      if (contents.nodes.length > 0) {
        h.Node hn = contents.nodes.first;
        while (hn != null) {
          h.Node next = hn.nextNode;
          if (hn is h.Text || hn is h.BRElement)
            hn.remove();
          hn = next;
        }
      }
      if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
        contents.appendText('\n');
    }
  }
  
  @override
  void updateAttributes() {
    if (state == 0) {
      h.DivElement div = getHTMLNode();
      h.TableElement table = h.querySelector("#$id>table");
      int i = 0;
      for (x.Element refAttr in attRefs) {
        String name = doc.cfg.attributeQualifiedName(ref, refAttr);
        String value = getAttribute(name);
        String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
        if (value == null) {
          if (defaultValue != null)
            value = defaultValue;
          else
            value = '';
        }
        attributeControls[name].setValue(value);
        i++;
      }
      updateValidity();
    }
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (state == 2 || !hasContent)
      return(null);
    return(h.document.getElementById('contents-' + id));
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  @override
  bool newlineInside() {
    return(true);
  }
  
  @override
  void attributeDialog([ActionFunction okfct]) {
    state = 0;
    if (getHTMLContentsNode() != null)
      updateHTML();
    if (okfct != null)
      okfct();
  }
  
  @override
  Position firstCursorPositionInside() {
    if (hasContent)
      return(new Position(this, 0));
    else
      return(null);
  }
  
  @override
  Position lastCursorPositionInside() {
    if (hasContent)
      return(new Position(this, offsetLength));
    else
      return(null);
  }
  
  void editableView() {
    bEditable.select();
    bNormal.deselect();
    bCollapsed.deselect();
    state = 0;
    updateHTML();
    if (attRefs.length > 0) {
      String firstAttName = doc.cfg.attributeQualifiedName(ref, attRefs.first);
      attributeControls[firstAttName].focus();
    }
  }
  
  void normalView() {
    bEditable.deselect();
    bNormal.select();
    bCollapsed.deselect();
    state = 1;
    updateHTML();
  }
  
  void collapsedView() {
    bEditable.deselect();
    bNormal.deselect();
    bCollapsed.select();
    state = 2;
    updateHTML();
  }
  
  h.TableRowElement attributeHTML(x.Element refAttr) {
    String name = doc.cfg.attributeQualifiedName(ref, refAttr);
    h.TableRowElement tr = new h.TableRowElement();
    
    h.TableCellElement td = new h.TableCellElement();
    td.classes.add('shrink');
    if (doc.cfg.attributeDocumentation(ref, refAttr) != null) {
      h.ButtonElement bHelp = makeHelpButton(ref, refAttr);
      td.append(bHelp);
    }
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    td.text = doc.cfg.attributeTitle(ref, refAttr);
    if (doc.cfg.requiredAttribute(ref, refAttr))
      td.classes.add('required');
    else
      td.classes.add('optional');
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('expand');
    String value = getAttribute(name);
    String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
    if (value == null) {
      if (defaultValue != null)
        value = defaultValue;
      else
        value = '';
    }
    SimpleTypeControl attributeControl;
    attributeControl = new SimpleTypeControl.forAttribute(ref, refAttr, value,
        valueChanged: () => changeAttributeValue(refAttr, attributeControl), catchUndo: true);
    attributeControls[name] = attributeControl;
    h.Element ht = attributeControl.html();
    if (ht.firstChild is h.TextInputElement)
      (ht.firstChild as h.TextInputElement).classes.add('form_field');
    else if (ht.firstChild is h.DataListElement && ht.firstChild.nextNode is h.TextInputElement)
      (ht.firstChild.nextNode as h.TextInputElement).classes.add('form_field');
    td.append(ht);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    tr.append(td);
    
    return(tr);
  }
  
  h.TableRowElement unknownAttributeHTML(DaxeAttr att) {
    if (unknownAttributeFields == null)
      unknownAttributeFields = new HashMap<DaxeAttr, h.TextInputElement>();
    h.TextInputElement input = new h.TextInputElement();
    input.spellcheck = false;
    input.size = 40;
    input.value = att.value;
    input.classes.add('invalid');
    input.onInput.listen((h.Event event) => changeUnknownAttributeValue(att, input)); // onInput doesn't work with IE9 and backspace
    input.onKeyUp.listen((h.KeyboardEvent event) => changeUnknownAttributeValue(att, input)); // so we use onKeyUp too
    unknownAttributeFields[att] = input;
    
    h.TableRowElement tr = new h.TableRowElement();
    h.TableCellElement td = new h.TableCellElement();
    td.classes.add('shrink');
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    td.appendText(att.name);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('expand');
    td.append(input);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    tr.append(td);
    
    return(tr);
  }
  
  void changeAttributeValue(x.Element refAttr, SimpleTypeControl attributeControl) {
    String value = attributeControl.getValue();
    String name = doc.cfg.attributeQualifiedName(ref, refAttr);
    String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
    DaxeAttr attr;
    if ((value == '' && defaultValue == null) || value == defaultValue)
      attr = new DaxeAttr(name, null); // remove the attribute
    else if (value != '' || defaultValue != null)
      attr = new DaxeAttr(name, value);
    else
      attr = null;
    if (attr != null)
      doc.doNewEdit(new UndoableEdit.changeAttribute(this, attr, updateDisplay: false));
    updateValidity();
  }
  
  void changeUnknownAttributeValue(DaxeAttr att, h.TextInputElement input) {
    String value = input.value;
    if (getAttributeNS(att.namespaceURI, att.localName) != value) {
      String name = att.name;
      DaxeAttr attr;
      if (value == '')
        attr = new DaxeAttr(name, null); // remove the attribute
      else
        attr = new DaxeAttr(name, value);
      doc.doNewEdit(new UndoableEdit.changeAttribute(this, attr, updateDisplay: false));
      updateValidity();
    }
  }
  
  static h.ButtonElement makeHelpButton(final x.Element elementRef, final x.Element attributeRef) {
    h.ButtonElement bHelp = new h.ButtonElement();
    bHelp.attributes['type'] = 'button';
    bHelp.classes.add('help');
    bHelp.value = '?';
    bHelp.text = '?';
    if (attributeRef == null) {
      String title = doc.cfg.documentation(elementRef);
      if (title != null)
        bHelp.title = title;
      bHelp.onClick.listen((h.Event event) => (new HelpDialog.Element(elementRef)).show());
    } else {
      String title = doc.cfg.attributeDocumentation(elementRef, attributeRef);
      if (title != null)
        bHelp.title = title;
      bHelp.onClick.listen((h.Event event) => (new HelpDialog.Attribute(attributeRef, elementRef)).show());
    }
    return(bHelp);
  }
}
