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
  
  PerlBlock.fromRef(x.Element elementRef) : super.fromRef(elementRef);
  
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
    String letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    h.DivElement div = new h.DivElement();
    div.classes.add('perl-colored');
    String text = firstChild.nodeValue;
    StringBuffer sb = new StringBuffer();
    StringBuffer word = new StringBuffer(); // last word in sb
    int i = 0;
    while (i < text.length) {
      String c = text[i];
      if (letters.contains(c)) {
        sb.write(c);
        word.write(c);
      } else {
        if (keywords.contains(word.toString())) {
          if (sb.length > word.length) {
            h.Text htext = new h.Text(sb.toString().substring(0, sb.length - word.length));
            div.append(htext);
          }
          h.SpanElement span = new h.SpanElement();
          span.classes.add('keyword');
          span.appendText(word.toString());
          div.append(span);
          word.clear();
          sb.clear();
        } else {
          word.clear();
        }
        sb.write(c);
      }
      i++;
    }
    if (sb.length > 0) {
      h.Text htext = new h.Text(sb.toString());
      div.append(htext);
    }
    return(div);
  }
}
