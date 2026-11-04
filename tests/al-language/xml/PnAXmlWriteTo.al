// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: WriteTo writes through .NET's indenting writer
// Facts: XmlDocument.WriteTo layout: declaration, indentation, empty elements, mixed content, escapes; XmlElement.WriteTo and InnerXml
// BC versions: 29 (27 and 28 by CI)

codeunit 70080 "LT PnA Xml WriteTo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        D: XmlDocument;
        T: Text;
    begin
        if not XmlDocument.ReadFrom(Src, D) then begin
            Observer.Observe(Name, 'read-failed');
            exit;
        end;
        D.WriteTo(T);
        Observer.Observe(Name, T);
    end;

    local procedure Ctl(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    [Test]
    procedure Layout_ElementsAndText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'open-close', '<a></a>');
        Show(Observer, 'self-closing', '<a/>');
        Show(Observer, 'self-closing-space', '<a />');
        Show(Observer, 'two-children', '<r><a/><b/></r>');
        Show(Observer, 'text-child', '<r><a>t</a></r>');
        Show(Observer, 'nested', '<r><a><b>t</b></a></r>');
        Show(Observer, 'mixed', '<r>t<a/>u</r>');
        Show(Observer, 'whitespace-child', '<r> <a/> </r>');
        Show(Observer, 'whitespace-only-text', '<r> </r>');
        Show(Observer, 'cdata', '<r><![CDATA[x<y]]></r>');
        Show(Observer, 'element-then-cdata', '<r><a>x</a><![CDATA[y]]></r>');
        Show(Observer, 'comment', '<r><!--c--></r>');
        Show(Observer, 'pi', '<r><?pi x?></r>');
        Show(Observer, 'default-ns', '<r xmlns="urn:x"><a/></r>');
        Show(Observer, 'prefixed-ns', '<p:r xmlns:p="urn:x"><p:a/></p:r>');
        Show(Observer, 'attributes', '<r a="1" b="2"/>');
        Show(Observer, 'attribute-entities', '<r a="x&quot;y&lt;z&amp;w"/>');
        Show(Observer, 'text-entities', '<r>a &amp; b &lt; c &gt; d &quot; e &apos; f</r>');
        Observer.Expect('open-close', '<?xml version="1.0" encoding="utf-16"?>\r\n<a></a>');
        Observer.Expect('self-closing', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('self-closing-space', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('two-children', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('text-child', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a>t</a>\r\n</r>');
        Observer.Expect('nested', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a>\r\n    <b>t</b>\r\n  </a>\r\n</r>');
        Observer.Expect('mixed', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>t<a />u</r>');
        Observer.Expect('whitespace-child', '<?xml version="1.0" encoding="utf-16"?>\r\n<r> <a /> </r>');
        Observer.Expect('whitespace-only-text', '<?xml version="1.0" encoding="utf-16"?>\r\n<r> </r>');
        Observer.Expect('cdata', '<?xml version="1.0" encoding="utf-16"?>\r\n<r><![CDATA[x<y]]></r>');
        Observer.Expect('element-then-cdata', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a>x</a><![CDATA[y]]></r>');
        Observer.Expect('comment', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <!--c-->\r\n</r>');
        Observer.Expect('pi', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <?pi x?>\r\n</r>');
        Observer.Expect('default-ns', '<?xml version="1.0" encoding="utf-16"?>\r\n<r xmlns="urn:x">\r\n  <a />\r\n</r>');
        Observer.Expect('prefixed-ns', '<?xml version="1.0" encoding="utf-16"?>\r\n<p:r xmlns:p="urn:x">\r\n  <p:a />\r\n</p:r>');
        Observer.Expect('attributes', '<?xml version="1.0" encoding="utf-16"?>\r\n<r a="1" b="2" />');
        Observer.Expect('attribute-entities', '<?xml version="1.0" encoding="utf-16"?>\r\n<r a="x&quot;y&lt;z&amp;w" />');
        Observer.Expect('text-entities', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>a &amp; b &lt; c &gt; d " e '' f</r>');
        Observer.Verify();
    end;

    [Test]
    procedure Layout_Declarations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'none', '<r/>');
        Show(Observer, 'version-only', '<?xml version="1.0"?><r/>');
        Show(Observer, 'utf8', '<?xml version="1.0" encoding="utf-8"?><r/>');
        Show(Observer, 'utf8-standalone', '<?xml version="1.0" encoding="utf-8" standalone="yes"?><r/>');
        Show(Observer, 'utf16', '<?xml version="1.0" encoding="utf-16"?><r/>');
        Show(Observer, 'standalone-no', '<?xml version="1.0" standalone="no"?><r/>');
        Show(Observer, 'leading-ws-before-decl', '<?xml version="1.0"?>' + Ctl(10) + '<r/>');
        Show(Observer, 'text-after-root-ws', '<r/>' + Ctl(10) + Ctl(10));
        Show(Observer, 'comment-before-root', '<!--c--><r/>');
        Show(Observer, 'comment-after-root', '<r/><!--c-->');
        Observer.Expect('none', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('version-only', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('utf8', '<?xml version="1.0" encoding="utf-8"?>\r\n<r />');
        Observer.Expect('utf8-standalone', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<r />');
        Observer.Expect('utf16', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('standalone-no', '<?xml version="1.0" encoding="utf-16" standalone="no"?>\r\n<r />');
        Observer.Expect('leading-ws-before-decl', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('text-after-root-ws', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />\r\n\r\n');
        Observer.Expect('comment-before-root', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--c-->\r\n<r />');
        Observer.Expect('comment-after-root', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />\r\n<!--c-->');
        Observer.Verify();
    end;

    [Test]
    procedure Escapes_Built()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        E: XmlElement;
        T: Text;
    begin
        D := XmlDocument.Create();
        E := XmlElement.Create('r');
        E.SetAttribute('v', 'a"b<c&d>e''f');
        E.SetAttribute('tab', 'x' + Ctl(9) + 'y');
        E.SetAttribute('lf', 'x' + Ctl(10) + 'y');
        E.SetAttribute('cr', 'x' + Ctl(13) + 'y');
        E.Add(XmlText.Create('a"b<c&d>e''f'));
        D.Add(E);
        D.WriteTo(T);
        Observer.Observe('document', T);
        E.WriteTo(T);
        Observer.Observe('element', T);
        Observer.Observe('innerxml', E.InnerXml());
        Observer.Observe('innertext', E.InnerText());
        Observer.Expect('document', '<?xml version="1.0" encoding="utf-16"?>\r\n<r v="a&quot;b&lt;c&amp;d&gt;e''f" tab="x&#x9;y" lf="x&#xA;y" cr="x&#xD;y">a"b&lt;c&amp;d&gt;e''f</r>');
        Observer.Expect('element', '<r v="a&quot;b&lt;c&amp;d&gt;e''f" tab="x&#x9;y" lf="x&#xA;y" cr="x&#xD;y">a"b&lt;c&amp;d&gt;e''f</r>');
        Observer.Expect('innerxml', 'a"b&lt;c&amp;d&gt;e''f');
        Observer.Expect('innertext', 'a"b<c&d>e''f');
        Observer.Verify();
    end;

    [Test]
    procedure Indentation_InnerXmlAndElementWriteTo()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        R: XmlElement;
        T: Text;
    begin
        XmlDocument.ReadFrom('<r><a><b>t</b><c/></a><d x="1"/></r>', D);
        D.GetRoot(R);
        Observer.Observe('root-innerxml', R.InnerXml());
        R.WriteTo(T);
        Observer.Observe('root-writeto', T);
        Observer.Observe('root-innertext', R.InnerText());
        Observer.Observe('doc-innerxml-is-unavailable-so-doc-writeto', Format(StrLen(T) > 0));
        Observer.Expect('root-innerxml', '<a><b>t</b><c /></a><d x="1" />');
        Observer.Expect('root-writeto', '<r>\r\n  <a>\r\n    <b>t</b>\r\n    <c />\r\n  </a>\r\n  <d x="1" />\r\n</r>');
        Observer.Expect('root-innertext', 't');
        Observer.Expect('doc-innerxml-is-unavailable-so-doc-writeto', 'Yes');
        Observer.Verify();
    end;
}
