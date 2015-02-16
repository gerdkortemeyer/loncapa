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
 * Perl block display for LON-CAPA
 * Jaxe display type: 'perl'.
 */
class PerlBlock extends LCDBlock {
  
  static List<String> keywords = [
    'if', 'unless', 'else', 'elsif', 'while', 'until', 'for', 'each', 'foreach', 'next',
    'last', 'break', 'continue', 'return', 'my', 'our', 'local', 'state', 'BEGIN', 'END',
    'package', 'sub', 'do', 'given ', 'when ', 'default', '__END__', '__DATA__',
    '__FILE__', '__LINE__', '__PACKAGE__'];
  
  PerlBlock.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    state = 1;
  }
  
  PerlBlock.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    if (firstChild is DNText && firstChild.nextSibling == null) {
      firstChild.replaceWith(new ParentUpdatingDNText(firstChild.nodeValue));
    }
  }
  
  @override
  h.Element html() {
    h.Element div = super.html();
    if (firstChild == null || firstChild.nextSibling != null || firstChild is! ParentUpdatingDNText)
      return div;
    if (state != 2 && hasContent) {
      h.DivElement contents = div.lastChild;
      contents.classes.add('perl-text');
      h.DivElement overlay = createOverlay();
      contents.style.position = 'relative';
      overlay.style.position = 'absolute';
      overlay.style.top = '0px';
      overlay.style.left = '0px';
      contents.append(overlay);
    }
    return div;
  }
  
  h.Element createOverlay() {
    // NOTE: this is very basic, we might need a real parser to do something more complex
    // TODO: add special highlighting for string redirect << and regular expressions 
    final String letters = '\$@%&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'; // starting chars in names
    final String digits = '0123456789';
    h.DivElement div = new h.DivElement();
    div.classes.add('perl-colored');
    String text = firstChild.nodeValue;
    StringBuffer sb = new StringBuffer();
    bool in_name = false;
    bool in_comment = false;
    bool in_number = false;
    bool in_string = false;
    bool in_backslash = false;
    String string_start;
    int i = 0;
    while (i < text.length) {
      String c = text[i];
      if (!in_string && !in_comment && (letters.contains(c) || in_name && digits.contains(c) ||
          in_name && c == '#' && sb.toString()[sb.length-1] == '\$')) {
        if (!in_name ) {
          if (sb.length > 0) {
            div.append(new h.Text(sb.toString()));
            sb.clear();
          }
          in_name = true;
        }
      } else if (!in_string && !in_name && !in_comment && (digits.contains(c) || (c == '.' && in_number))) {
        if (!in_number) {
          if (sb.length > 0) {
            div.append(new h.Text(sb.toString()));
            sb.clear();
          }
          in_number = true;
        }
      } else {
        if (in_name) {
          String s = sb.toString();
          h.SpanElement span = new h.SpanElement();
          if (keywords.contains(s))
            span.classes.add('keyword');
          else if (s.startsWith('\$') || s.startsWith('@') || s.startsWith('%'))
            span.classes.add('variable');
          else if (s.startsWith('&') || c == '(')
            span.classes.add('function-call');
          else
            span.classes.add('name');
          span.appendText(s);
          div.append(span);
          sb.clear();
          in_name = false;
        } else if (in_number) {
          h.SpanElement span = new h.SpanElement();
          span.classes.add('number');
          span.appendText(sb.toString());
          div.append(span);
          sb.clear();
          in_number = false;
        } else if (in_comment && (c == '\n' || c == '\r')) {
          h.SpanElement span = new h.SpanElement();
          span.classes.add('comment');
          span.appendText(sb.toString());
          div.append(span);
          sb.clear();
          in_comment = false;
        }
        if (!in_comment && (c == '"' || c == "'") && !in_backslash) {
          if (in_string) {
            if (c == string_start) {
              div.append(new h.Text(string_start));
              h.SpanElement span = new h.SpanElement();
              span.classes.add('string');
              span.appendText(sb.toString().substring(1));
              div.append(span);
              sb.clear();
              in_string = false;
            }
          } else {
            if (sb.length > 0) {
              div.append(new h.Text(sb.toString()));
              sb.clear();
            }
            string_start = c;
            in_string = true;
          }
        } else if (!in_string && c == '#') {
          if (sb.length > 0) {
            div.append(new h.Text(sb.toString()));
            sb.clear();
          }
          in_comment = true;
        }
      }
      if (in_string) {
        if (c == '\\')
          in_backslash = !in_backslash;
        else if (in_backslash)
          in_backslash = false;
      }
      sb.write(c);
      i++;
    }
    if (sb.length > 0) {
      if (in_comment) {
        h.SpanElement span = new h.SpanElement();
        span.classes.add('comment');
        span.appendText(sb.toString());
        div.append(span);
      } else
        div.append(new h.Text(sb.toString()));
    }
    return(div);
  }
  
  bool get needsParentUpdatingDNText {
    return true;
  }
}
