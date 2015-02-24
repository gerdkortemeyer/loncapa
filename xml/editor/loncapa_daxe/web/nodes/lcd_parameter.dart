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
 * Display for the parameter element, based on LCDBlock
 * Jaxe display type: 'parameter'.
 */
class LCDParameter extends LCDBlock {
  static HashMap<String,HashMap<String, LCParameter>> parameters = null;
  
  LCDParameter.fromRef(x.Element elementRef) : super.fromRef(elementRef);
  
  LCDParameter.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent);
  
  Future<bool> _readParameters() {
    Completer<bool> completer = new Completer<bool>();
    x.DOMParser dp = new x.DOMParser();
    dp.parseFromURL('parameters.xml').then((x.Document xdoc) {
      parameters = new HashMap<String,HashMap<String, LCParameter>>();
      x.Element root = xdoc.documentElement;
      for (x.Element context in _getChildrenWithName(root, 'context')) {
        String ancestor = context.getAttribute('ancestor');
        HashMap<String, LCParameter> params = new HashMap<String, LCParameter>();
        parameters[ancestor] = params;
        for (x.Element parameter in _getChildrenWithName(context, 'parameter')) {
          LCParameter param = new LCParameter();
          for (x.Node n=parameter.firstChild; n!=null; n=n.nextSibling) {
            if (n.nodeType == x.Node.ELEMENT_NODE && n.firstChild != null && n.firstChild.nodeType == x.Node.TEXT_NODE) {
              if (n.nodeName == 'name')
                param.name = n.firstChild.nodeValue;
              else if (n.nodeName == 'type')
                param.type = n.firstChild.nodeValue;
              else if (n.nodeName == 'default')
                param.def = n.firstChild.nodeValue;
              else if (n.nodeName == 'title') {
                String lang = (n as x.Element).getAttribute('lang');
                if (lang != null) {
                  if (param.titles == null)
                    param.titles = new HashMap<String, String>();
                  param.titles[lang] = n.firstChild.nodeValue;
                }
              }
            }
          }
          params[param.name] = param;
        }
      }
      completer.complete(true);
    }).catchError((e) => (e) {
      print(e);
      completer.complete(false);
    });
    return(completer.future);
  }
  
  List<x.Element> _getChildrenWithName(x.Element parent, String name) {
    List<x.Element> l = new List<x.Element>();
    for (x.Node n=parent.firstChild; n!=null; n=n.nextSibling) {
      if (n.nodeType == x.Node.ELEMENT_NODE && n.nodeName == name) {
        l.add(n);
      }
    }
    return l;
  }
  
  @override
  h.Element html() {
    h.Element div = super.html();
    if (state != 0)
      return div;
    h.DivElement headerDiv = div.firstChild;
    h.TableElement table = headerDiv.lastChild;
    h.DivElement templateDiv = new h.DivElement();
    Menu menu = new Menu(LCDStrings.get('template'));
    _addTemplates(menu); // this might be async if the config is read
    h.DivElement menuDiv = page.mbar.createMenuDiv(menu);
    h.DivElement menuButtonDiv = new h.DivElement();
    menuButtonDiv.classes.add('toolbar-menu');
    menuButtonDiv.append(menuDiv);
    templateDiv.append(menuButtonDiv);
    headerDiv.insertBefore(templateDiv, table);
    return div;
  }
  
  void _addTemplates(Menu menu) {
    if (parameters == null) {
      _readParameters().then((bool read) {
        if (!read)
          return;
        updateHTML();
      });
      return;
    }
    HashMap<String, LCParameter> context = _getContext();
    if (context == null)
      return;
    for (LCParameter param in context.values) {
      String title = param.titles[LCDStrings.systemLocale];
      if (title == null)
        title = param.titles['en'];
      menu.add(new MenuItem(title, ()=>chooseTemplate(param)));
    }
  }
  
  HashMap<String, LCParameter> _getContext() {
    for (DaxeNode ancestor=parent; ancestor!=null; ancestor=ancestor.parent) {
      if (parameters[ancestor.nodeName] != null) {
        HashMap<String, LCParameter> context = parameters[ancestor.nodeName];
        return context;
      }
    }
    return null;
  }
  
  void chooseTemplate(LCParameter param) {
    LinkedHashMap<String, DaxeAttr> attmap = getAttributesMapCopy();
    attmap['name'] = new DaxeAttr.NS(null, 'name', param.name);
    if (param.type != null)
      attmap['type'] = new DaxeAttr.NS(null, 'type', param.type);
    else
      attmap.remove('type');
    if (param.def != null)
      attmap['default'] = new DaxeAttr.NS(null, 'default', param.def);
    else
      attmap.remove('default');
    if (param.titles != null) {
      String title = param.titles['en']; // using English if possible for the description attribute
      if (title == null)
        title = param.titles[LCDStrings.systemLocale];
      if (title != null)
        attmap['description'] = new DaxeAttr.NS(null, 'description', title);
      else
        attmap.remove('title');
    }
    attmap.remove('id');
    attmap.remove('display');
    UndoableEdit edit = new UndoableEdit.changeAttributes(this, new List.from(attmap.values));
    doc.doNewEdit(edit);
  }
}

class LCParameter {
  String name;
  String type;
  String def;
  HashMap<String, String> titles;
}
