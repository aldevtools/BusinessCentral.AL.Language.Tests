// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: White space is kept inside and outside the root
// Facts: XmlDocument.ReadFrom keeps white space nodes; adjacent text nodes after Add are not merged (child counts)
// BC versions: 29 (27 and 28 by CI)

codeunit 70081 "LT PnA Xml Whitespace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure WhiteSpace_InsideAndOutsideRoot()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        R: XmlElement;
        N: XmlNode;
        T: Text;
    begin
        XmlDocument.ReadFrom('<r> <a/> </r>', D);
        D.GetRoot(R);
        Observer.Observe('inside-count', Format(R.GetChildNodes().Count()));
        Observer.Observe('inside-innerxml', R.InnerXml());
        Observer.Observe('inside-innertext', R.InnerText());
        Observer.Observe('inside-first-is-text', Format(R.GetChildNodes().Get(1, N)));
        Observer.Observe('inside-first-text', Format(N.IsXmlText()));

        XmlDocument.ReadFrom(Lf() + '<r/>' + Lf(), D);
        Observer.Observe('outside-count', Format(D.GetChildNodes().Count()));
        D.WriteTo(T);
        Observer.Observe('outside-writeto', T);

        XmlDocument.ReadFrom('<r>' + Lf() + '  <a>' + Lf() + '    x' + Lf() + '  </a>' + Lf() + '</r>', D);
        D.GetRoot(R);
        Observer.Observe('pretty-count', Format(R.GetChildNodes().Count()));
        Observer.Observe('pretty-innertext', R.InnerText());
        D.WriteTo(T);
        Observer.Observe('pretty-writeto', T);
        Observer.Expect('inside-count', '3');
        Observer.Expect('inside-innerxml', ' <a /> ');
        Observer.Expect('inside-innertext', '  ');
        Observer.Expect('inside-first-is-text', 'Yes');
        Observer.Expect('inside-first-text', 'Yes');
        Observer.Expect('outside-count', '3');
        Observer.Expect('outside-writeto', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />\r\n');
        Observer.Expect('pretty-count', '3');
        Observer.Expect('pretty-innertext', '\n  \n    x\n  \n');
        Observer.Expect('pretty-writeto', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a>\r\n    x\r\n  </a>\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure AdjacentText_AfterAdd()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        E: XmlElement;
        T: Text;
    begin
        E := XmlElement.Create('r');
        E.Add('a');
        Observer.Observe('one-add-count', Format(E.GetChildNodes().Count()));
        E.Add(XmlText.Create('b'));
        Observer.Observe('two-adds-count', Format(E.GetChildNodes().Count()));
        Observer.Observe('two-adds-innertext', E.InnerText());
        Observer.Observe('two-adds-innerxml', E.InnerXml());
        E.Add(XmlText.Create('c'));
        Observer.Observe('three-adds-count', Format(E.GetChildNodes().Count()));
        E.Add(XmlElement.Create('x'));
        E.Add(XmlText.Create('d'));
        Observer.Observe('five-count', Format(E.GetChildNodes().Count()));
        D := XmlDocument.Create();
        D.Add(E);
        D.WriteTo(T);
        Observer.Observe('written', T);
        XmlDocument.ReadFrom(T, D);
        D.GetRoot(E);
        Observer.Observe('reread-count', Format(E.GetChildNodes().Count()));
        Observer.Expect('one-add-count', '1');
        Observer.Expect('two-adds-count', '2');
        Observer.Expect('two-adds-innertext', 'ab');
        Observer.Expect('two-adds-innerxml', 'ab');
        Observer.Expect('three-adds-count', '3');
        Observer.Expect('five-count', '5');
        Observer.Expect('written', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>abc<x />d</r>');
        Observer.Expect('reread-count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure AdjacentText_ReadFromCdataAndEntities()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        E: XmlElement;
    begin
        XmlDocument.ReadFrom('<r>a<![CDATA[b]]>c</r>', D);
        D.GetRoot(E);
        Observer.Observe('cdata-count', Format(E.GetChildNodes().Count()));
        Observer.Observe('cdata-innertext', E.InnerText());
        XmlDocument.ReadFrom('<r>a&amp;b</r>', D);
        D.GetRoot(E);
        Observer.Observe('entity-count', Format(E.GetChildNodes().Count()));
        XmlDocument.ReadFrom('<r>a<!--c-->b</r>', D);
        D.GetRoot(E);
        Observer.Observe('comment-count', Format(E.GetChildNodes().Count()));
        Observer.Observe('comment-innertext', E.InnerText());
        Observer.Expect('cdata-count', '3');
        Observer.Expect('cdata-innertext', 'abc');
        Observer.Expect('entity-count', '1');
        Observer.Expect('comment-count', '3');
        Observer.Expect('comment-innertext', 'ab');
        Observer.Verify();
    end;
}
