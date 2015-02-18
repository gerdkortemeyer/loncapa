/*
  This file is part of LON-CAPA.

  LON-CAPA is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  LON-CAPA is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with LON-CAPA.  If not, see <http://www.gnu.org/licenses/>.
*/

library loncapa_daxe;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as h;
import 'package:daxe/daxe.dart';
import 'package:daxe/src/xmldom/xmldom.dart' as x;
import 'package:daxe/src/strings.dart';
import 'package:daxe/src/nodes/nodes.dart' show DNCData, DNText, SimpleTypeControl, ParentUpdatingDNText;
import 'dart:js' as js;

import 'lcd_strings.dart';
part 'nodes/lcd_block.dart';
part 'nodes/tex_mathjax.dart';
part 'nodes/lm.dart';
part 'nodes/perl_block.dart';
part 'lcd_button.dart';


void main() {
  NodeFactory.addCoreDisplayTypes();
  
  addDisplayType('lcdblock',
        (x.Element ref) => new LCDBlock.fromRef(ref),
        (x.Node node, DaxeNode parent) => new LCDBlock.fromNode(node, parent)
    );
  
  addDisplayType('texmathjax',
        (x.Element ref) => new TeXMathJax.fromRef(ref),
        (x.Node node, DaxeNode parent) => new TeXMathJax.fromNode(node, parent)
    );
  
  addDisplayType('lm',
        (x.Element ref) => new Lm.fromRef(ref),
        (x.Node node, DaxeNode parent) => new Lm.fromNode(node, parent)
    );
  
  addDisplayType('perl',
        (x.Element ref) => new PerlBlock.fromRef(ref),
        (x.Node node, DaxeNode parent) => new PerlBlock.fromNode(node, parent)
    );
  
  Future.wait([Strings.load(), LCDStrings.load(), _readTemplates('templates.xml')]).then((List responses) {
    _init_daxe().then((v) {
      // add things to the toolbar
      ToolbarMenu sectionMenu = _makeSectionMenu();
      if (sectionMenu != null)
        page.toolbar.add(sectionMenu);
      x.Element texRef = doc.cfg.elementReference('m');
      if (texRef != null) {
        ToolbarBox insertBox = new ToolbarBox();
        ToolbarButton texButton = new ToolbarButton(
            LCDStrings.get('tex_equation'), 'images/tex.png',
            () => doc.insertNewNode(texRef, 'element'), Toolbar.insertButtonUpdate, 
            data:new ToolbarStyleInfo([texRef], null, null));
        insertBox.add(texButton);
        page.toolbar.add(insertBox);
      }
      h.Element tbh = h.querySelector('.toolbar');
      tbh.replaceWith(page.toolbar.html());
      page.adjustPositionsUnderToolbar();
      page.updateAfterPathChange();
      // add things to the menubar
      if (responses[2] is x.Document) {
        // at this point the menubar html is already in the document, so we have to fix the HTML
        h.Element menubarDiv = h.document.getElementsByClassName('menubar')[0];
        if (doc.filePath.indexOf('&url=') != -1) { // otherwise we are not on LON-CAPA
          MenuItem item = new MenuItem(Strings.get('menu.save'), () => save(), shortcut: 'S');
          Menu fileMenu = page.mbar.menus[0];
          fileMenu.add(item);
          menubarDiv.firstChild.replaceWith(page.mbar.createMenuDiv(fileMenu));
        }
        Menu m = _makeTemplatesMenu(responses[2]);
        page.mbar.add(m);
        menubarDiv.append(page.mbar.createMenuDiv(m));
        page.updateAfterPathChange();
      } else
        print("Error reading templates file, could not build the menu.");
    });
  });
}

Future _init_daxe() {
  Completer completer = new Completer();
  doc = new DaxeDocument();
  page = new WebPage();
  
  // check parameters for a config and file to open
  String file = null;
  String config = null;
  String saveURL = null;
  h.Location location = h.window.location;
  String search = location.search;
  if (search.startsWith('?'))
    search = search.substring(1);
  List<String> parameters = search.split('&');
  for (String param in parameters) {
    List<String> lparam = param.split('=');
    if (lparam.length != 2)
      continue;
    if (lparam[0] == 'config')
      config = lparam[1];
    else if (lparam[0] == 'file')
      file = Uri.decodeComponent(lparam[1]);
    else if (lparam[0] == 'save')
      saveURL = lparam[1];
  }
  if (saveURL != null)
    doc.saveURL = saveURL;
  if (config != null && file != null)
    page.openDocument(file, config).then((v) => completer.complete());
  else if (config != null)
    page.newDocument(config).then((v) => completer.complete());
  else {
    h.window.alert(Strings.get('daxe.missing_config'));
    completer.completeError(Strings.get('daxe.missing_config'));
  }
  return(completer.future);
}

void save() {
  saveOnLONCAPA().then((_) {
    h.window.alert(Strings.get('save.success'));
  }, onError: (DaxeException ex) {
    h.window.alert(Strings.get('save.error') + ': ' + ex.message);
  });
}

/**
 * Send the document with a POST request to LON-CAPA.
 */
Future saveOnLONCAPA() {
  int ind = doc.filePath.indexOf('&url=');
  if (ind == -1)
    return(new Future.error(new DaxeException('bad URL')));
  String path = doc.filePath.substring(ind+5);
  path = Uri.decodeQueryComponent(path);
  ind = path.lastIndexOf('/');
  String filename;
  if (ind == -1)
    filename = path;
  else {
    filename = path.substring(ind+1);
    path = path.substring(0, ind+1);
  }
  Completer completer = new Completer();
  String bound = 'AaB03x';
  h.HttpRequest request = new h.HttpRequest();
  request.onLoad.listen((h.ProgressEvent event) {
    completer.complete(); // TODO: check for something, status is sometimes wrongly OK
  });
  request.onError.listen((h.ProgressEvent event) {
    completer.completeError(new DaxeException(request.status.toString()));
  });
  request.open('POST', '/upload_file');
  request.setRequestHeader('Content-Type', "multipart/form-data; boundary=$bound");
  
  StringBuffer sb = new StringBuffer();
  sb.write("--$bound\r\n");
  sb.write('Content-Disposition: form-data; name="uploads_path"\r\n');
  sb.write('Content-type: text/plain; charset=UTF-8\r\n');
  sb.write('Content-transfer-encoding: 8bit\r\n\r\n');
  sb.write(path);
  sb.write("\r\n--$bound\r\n");
  sb.write('Content-Disposition: form-data; name="uploads"; filename="$filename"\r\n');
  sb.write('Content-Type: application/octet-stream\r\n\r\n');
  doc.dndoc.xmlEncoding = 'UTF-8'; // the document is forced to use UTF-8
  sb.write(doc.toString());
  sb.write('\r\n--$bound--\r\n\r\n');
  request.send(sb.toString());
  return(completer.future);
}

ToolbarMenu _makeSectionMenu() {
  Menu menu = new Menu(LCDStrings.get('Section'));
  List<x.Element> sectionRefs = doc.cfg.elementReferences('section');
  if (sectionRefs == null || sectionRefs.length == 0)
    return(null);
  x.Element h1Ref = doc.cfg.elementReference('h1');
  for (String role in ['introduction', 'conclusion', 'prerequisites', 'objectives',
                       'reminder', 'definition', 'demonstration', 'example', 'advise',
                       'remark', 'warning', 'more_information', 'method',
                       'activity', 'bibliography', 'citation']) {
    MenuItem menuItem = new MenuItem(LCDStrings.get(role), null,
        data:new ToolbarStyleInfo(sectionRefs, null, null));
    menuItem.action = () {
      ToolbarStyleInfo info = menuItem.data;
      x.Element sectionRef = info.validRef;
      LCDBlock section = NodeFactory.create(sectionRef);
      section.state = 1;
      section.setAttribute('class', 'role-' + role);
      LCDBlock h1 = NodeFactory.create(h1Ref);
      h1.state = 1;
      if (doc.insert2(section, page.getSelectionStart())) {
        doc.insertNode(h1, new Position(section, 0));
        page.cursor.moveTo(new Position(h1, 0));
        page.updateAfterPathChange();
      }
    };
    menu.add(menuItem);
  }
  ToolbarMenu tbmenu = new ToolbarMenu(menu, Toolbar.insertMenuUpdate, page.toolbar);
  return(tbmenu);
}

Future<x.Document> _readTemplates(String templatesPath) {
  x.DOMParser dp = new x.DOMParser();
  return(dp.parseFromURL(templatesPath));
}

Menu _makeTemplatesMenu(x.Document templatesDoc) {
  Menu menu = new Menu(LCDStrings.get('Templates'));
  x.Element templates = templatesDoc.documentElement;
  for (x.Node child in templates.childNodes) {
    if (child.nodeType == x.Node.ELEMENT_NODE && child.nodeName == 'menu') {
      menu.add(_makeMenu(child));
    }
  }
  return(menu);
}

Menu _makeMenu(x.Element el) {
  String locale = LCDStrings.systemLocale;
  String defaultLocale = LCDStrings.defaultLocale;
  String title;
  for (x.Node child in el.childNodes) {
    if (child.nodeType == x.Node.ELEMENT_NODE && child.nodeName == 'title') {
      if (child.firstChild != null && child.firstChild.nodeType == x.Node.TEXT_NODE) {
        if ((child as x.Element).getAttribute('lang') == locale) {
          title = child.firstChild.nodeValue;
          break;
        } else if ((child as x.Element).getAttribute('lang') == defaultLocale) {
          title = child.firstChild.nodeValue;
        }
      }
    }
  }
  if (title == null)
    title = '?';
  Menu menu = new Menu(title);
  for (x.Node child in el.childNodes) {
    if (child.nodeType == x.Node.ELEMENT_NODE) {
      if (child.nodeName == 'menu') {
        menu.add(_makeMenu(child));
      } else if (child.nodeName == 'item') {
        menu.add(_makeItem(child));
      }
    }
  }
  return(menu);
}

MenuItem _makeItem(x.Element item) {
  String locale = LCDStrings.systemLocale;
  String defaultLocale = LCDStrings.defaultLocale;
  String path, type, title, help;
  for (x.Node child in item.childNodes) {
    if (child.nodeType == x.Node.ELEMENT_NODE) {
      if (child.nodeName == 'title') {
        if (child.firstChild != null && child.firstChild.nodeType == x.Node.TEXT_NODE) {
          if ((child as x.Element).getAttribute('lang') == locale) {
            title = child.firstChild.nodeValue;
          } else if (title == null && (child as x.Element).getAttribute('lang') == defaultLocale) {
            title = child.firstChild.nodeValue;
          }
        }
      } else if (child.nodeName == 'path' && child.firstChild != null && child.firstChild.nodeType == x.Node.TEXT_NODE) {
        path = child.firstChild.nodeValue;
      } else if (child.nodeName == 'type' && child.firstChild != null && child.firstChild.nodeType == x.Node.TEXT_NODE) {
        type = child.firstChild.nodeValue;
      } else if (child.nodeName == 'help') {
        if (child.firstChild != null && child.firstChild.nodeType == x.Node.TEXT_NODE) {
          if ((child as x.Element).getAttribute('lang') == locale) {
            help = child.firstChild.nodeValue;
          } else if (help == null && (child as x.Element).getAttribute('lang') == defaultLocale) {
            help = child.firstChild.nodeValue;
          }
        }
      }
    }
  }
  if (type == null) {
    print("Warning: missing type for template $title\n");
    type = 'problem';
  }
  x.Element refElement = doc.cfg.elementReference(type);
  MenuItem menuItem = new MenuItem(title, () => _insertTemplate(path), data: refElement);
  if (help != null)
    menuItem.toolTipText = help;
  return menuItem;
}

void _insertTemplate(String filePath) {
  try {
    x.DOMParser dp = new x.DOMParser();
    dp.parseFromURL(filePath).then((x.Document templateDoc) {
      x.Element root = templateDoc.documentElement;
      if (root == null)
        return;
      doc.removeWhitespace(root);
      DaxeNode dnRoot = NodeFactory.createFromNode(root, null);
      UndoableEdit edit;
      Position pos = page.getSelectionStart();
      if (dnRoot.nodeName == 'loncapa' && doc.getRootElement() != null)
        edit = doc.insertChildrenEdit(dnRoot, pos, checkValidity:true);
      else
        edit = new UndoableEdit.insertNode(pos, dnRoot);
      doc.doNewEdit(edit);
      page.updateAfterPathChange();
    });
  } on x.DOMException catch(ex) {
    h.window.alert(ex.toString());
  }
}
