// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: XmlDocument.GetDocumentType is false without a DOCTYPE
// Facts: XmlDocument.GetDocumentType with and without DOCTYPE; DOCTYPE with entity declarations is read and dropped
// BC versions: 29 (27 and 28 by CI)

codeunit 70086 "LT PnA Xml Doctype"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        DocType: XmlDocumentType;

    [TryFunction]
    local procedure TryType()
    begin
        Doc.GetDocumentType(DocType);
    end;

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        XmlDocument.ReadFrom(Src, Doc);
    end;

    [Test]
    procedure WithoutDoctype()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XmlDocument.ReadFrom('<r/>', Doc);
        Observer.Observe('used', Format(Doc.GetDocumentType(DocType)));
        Observer.Observe('statement', Format(TryType()));
        Observer.ObserveError('statement');
        Observer.Expect('used', 'No');
        Observer.Expect('statement', 'No');
        Observer.Expect('statement|text', 'The XML node is not set.');
        Observer.Expect('statement|code', 'XmlNodeNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure WithDoctype()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        T: Text;
    begin
        Observer.Observe('simple-read', Format(XmlDocument.ReadFrom('<!DOCTYPE r><r/>', Doc)));
        Observer.Observe('simple-type', Format(Doc.GetDocumentType(DocType)));
        Doc.WriteTo(T);
        Observer.Observe('simple-writeto', T);
        Observer.Observe('entity-read', Format(TryRead('<!DOCTYPE r [<!ENTITY e "v">]><r>&e;</r>')));
        Observer.ObserveError('entity-read');
        if Doc.GetRoot(Root) then
            Observer.Observe('entity-innertext', Root.InnerText());
        Doc.WriteTo(T);
        Observer.Observe('entity-writeto', T);
        Observer.Observe('entity-type', Format(Doc.GetDocumentType(DocType)));
        Observer.Observe('system-read', Format(TryRead('<!DOCTYPE r SYSTEM "x.dtd"><r/>')));
        Observer.ObserveError('system-read');
        Observer.Observe('public-read', Format(TryRead('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0//EN" "x.dtd"><html/>')));
        Observer.ObserveError('public-read');
        Observer.Expect('simple-read', 'Yes');
        Observer.Expect('simple-type', 'No');
        Observer.Expect('simple-writeto', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('entity-read', 'No');
        Observer.Expect('entity-read|text', 'The following exception was encountered when processing XML data: ''Reference to undeclared entity ''e''. Line 1, position 35.'' at line 1 and position 35.');
        Observer.Expect('entity-read|code', 'Xml:Xml');
        Observer.Expect('entity-innertext', '');
        Observer.Expect('entity-writeto', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('entity-type', 'No');
        Observer.Expect('system-read', 'Yes');
        Observer.Expect('system-read|text', '');
        Observer.Expect('system-read|code', '');
        Observer.Expect('public-read', 'Yes');
        Observer.Expect('public-read|text', '');
        Observer.Expect('public-read|code', '');
        Observer.Verify();
    end;
}
