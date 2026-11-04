// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Reading XML with a DOCTYPE, GetDocumentType on the result, WriteTo of the read document
// BC versions: 29 (27 and 28 by CI)

codeunit 72082 "LT P83 DocType Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Dt: XmlDocumentType;

    local procedure GName(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetName(R);
        exit(R);
    end;

    local procedure GPub(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetPublicId(R);
        exit(R);
    end;

    local procedure GSys(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetSystemId(R);
        exit(R);
    end;

    local procedure GSub(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetInternalSubset(R);
        exit(R);
    end;

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        XmlDocument.ReadFrom(Src, Doc);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        T: Text;
    begin
        Clear(Doc);
        Clear(Dt);
        Observer.Observe(Name + '-read', Format(TryRead(Src)));
        Observer.ObserveError(Name + '-read');
        if Doc.GetDocumentType(Dt) then
            Observer.Observe(Name + '-type', GName(Dt) + '|' + GPub(Dt) + '|' + GSys(Dt) + '|' + GSub(Dt))
        else
            Observer.Observe(Name + '-type', 'none');
        Doc.WriteTo(T);
        Observer.Observe(Name + '-written', T);
    end;

    [Test]
    procedure Read_SimpleAndSystem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'simple', '<!DOCTYPE a><a/>');
        Probe(Observer, 'system', '<!DOCTYPE a SYSTEM "a.dtd"><a/>');
        Probe(Observer, 'system-apos', '<!DOCTYPE a SYSTEM ''a.dtd''><a/>');
        Observer.Expect('simple-read', 'Yes');
        Observer.Expect('simple-read|text', '');
        Observer.Expect('simple-read|code', '');
        Observer.Expect('simple-type', 'none');
        Observer.Expect('simple-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('system-read', 'Yes');
        Observer.Expect('system-read|text', '');
        Observer.Expect('system-read|code', '');
        Observer.Expect('system-type', 'none');
        Observer.Expect('system-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('system-apos-read', 'Yes');
        Observer.Expect('system-apos-read|text', '');
        Observer.Expect('system-apos-read|code', '');
        Observer.Expect('system-apos-type', 'none');
        Observer.Expect('system-apos-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Public()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'public', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html/>');
        Probe(Observer, 'public-short', '<!DOCTYPE a PUBLIC "p" "s"><a/>');
        Observer.Expect('public-read', 'Yes');
        Observer.Expect('public-read|text', '');
        Observer.Expect('public-read|code', '');
        Observer.Expect('public-type', 'none');
        Observer.Expect('public-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<html />');
        Observer.Expect('public-short-read', 'Yes');
        Observer.Expect('public-short-read|text', '');
        Observer.Expect('public-short-read|code', '');
        Observer.Expect('public-short-type', 'none');
        Observer.Expect('public-short-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Read_InternalSubset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'subset-element', '<!DOCTYPE a [<!ELEMENT a EMPTY>]><a/>');
        Probe(Observer, 'subset-entity', '<!DOCTYPE a [<!ENTITY e "v">]><a/>');
        Probe(Observer, 'subset-attlist', '<!DOCTYPE a [<!ELEMENT a EMPTY><!ATTLIST a x CDATA "d">]><a/>');
        Probe(Observer, 'subset-empty', '<!DOCTYPE a []><a/>');
        Observer.Expect('subset-element-read', 'Yes');
        Observer.Expect('subset-element-read|text', '');
        Observer.Expect('subset-element-read|code', '');
        Observer.Expect('subset-element-type', 'none');
        Observer.Expect('subset-element-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('subset-entity-read', 'Yes');
        Observer.Expect('subset-entity-read|text', '');
        Observer.Expect('subset-entity-read|code', '');
        Observer.Expect('subset-entity-type', 'none');
        Observer.Expect('subset-entity-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('subset-attlist-read', 'Yes');
        Observer.Expect('subset-attlist-read|text', '');
        Observer.Expect('subset-attlist-read|code', '');
        Observer.Expect('subset-attlist-type', 'none');
        Observer.Expect('subset-attlist-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('subset-empty-read', 'Yes');
        Observer.Expect('subset-empty-read|text', '');
        Observer.Expect('subset-empty-read|code', '');
        Observer.Expect('subset-empty-type', 'none');
        Observer.Expect('subset-empty-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Read_SystemAndSubset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'system-subset', '<!DOCTYPE a SYSTEM "a.dtd" [<!ELEMENT a EMPTY>]><a/>');
        Probe(Observer, 'public-subset', '<!DOCTYPE a PUBLIC "p" "s" [<!ELEMENT a EMPTY>]><a/>');
        Observer.Expect('system-subset-read', 'Yes');
        Observer.Expect('system-subset-read|text', '');
        Observer.Expect('system-subset-read|code', '');
        Observer.Expect('system-subset-type', 'none');
        Observer.Expect('system-subset-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('public-subset-read', 'Yes');
        Observer.Expect('public-subset-read|text', '');
        Observer.Expect('public-subset-read|code', '');
        Observer.Expect('public-subset-type', 'none');
        Observer.Expect('public-subset-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Read_WithDeclarationAndComment()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'declaration', '<?xml version="1.0" encoding="utf-8"?><!DOCTYPE a><a/>');
        Probe(Observer, 'comment-before', '<!--c--><!DOCTYPE a><a/>');
        Probe(Observer, 'comment-after', '<!DOCTYPE a><!--c--><a/>');
        Probe(Observer, 'whitespace', '<!DOCTYPE a>' + '   ' + '<a/>');
        Probe(Observer, 'pi', '<?pi x?><!DOCTYPE a><a/>');
        Observer.Expect('declaration-read', 'Yes');
        Observer.Expect('declaration-read|text', '');
        Observer.Expect('declaration-read|code', '');
        Observer.Expect('declaration-type', 'none');
        Observer.Expect('declaration-written', '<?xml version="1.0" encoding="utf-8"?>\r\n<a />');
        Observer.Expect('comment-before-read', 'Yes');
        Observer.Expect('comment-before-read|text', '');
        Observer.Expect('comment-before-read|code', '');
        Observer.Expect('comment-before-type', 'none');
        Observer.Expect('comment-before-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--c-->\r\n<a />');
        Observer.Expect('comment-after-read', 'Yes');
        Observer.Expect('comment-after-read|text', '');
        Observer.Expect('comment-after-read|code', '');
        Observer.Expect('comment-after-type', 'none');
        Observer.Expect('comment-after-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--c-->\r\n<a />');
        Observer.Expect('whitespace-read', 'Yes');
        Observer.Expect('whitespace-read|text', '');
        Observer.Expect('whitespace-read|code', '');
        Observer.Expect('whitespace-type', 'none');
        Observer.Expect('whitespace-written', '<?xml version="1.0" encoding="utf-16"?>   <a />');
        Observer.Expect('pi-read', 'Yes');
        Observer.Expect('pi-read|text', '');
        Observer.Expect('pi-read|code', '');
        Observer.Expect('pi-type', 'none');
        Observer.Expect('pi-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<?pi x?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Malformed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<!DOCTYPE a<a/>', Doc);
        Observer.ObserveError('unclosed');
        Observer.Observe('unclosed-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<!doctype a><a/>', Doc);
        Observer.ObserveError('lower-case');
        Observer.Observe('lower-case-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<a/><!DOCTYPE a>', Doc);
        Observer.ObserveError('after-root');
        Observer.Observe('after-root-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        XmlDocument.ReadFrom('<!DOCTYPE a><!DOCTYPE b><a/>', Doc);
        Observer.Observe('two', 'no error');
        Observer.Observe('two-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<!DOCTYPE ><a/>', Doc);
        Observer.ObserveError('no-name');
        Observer.Observe('no-name-type', Format(Doc.GetDocumentType(Dt)));
        Observer.Expect('unclosed|text', 'The following exception was encountered when processing XML data: ''Expecting external ID, ''['' or ''>''. Line 1, position 12.'' at line 1 and position 12.');
        Observer.Expect('unclosed|code', 'Xml:Xml');
        Observer.Expect('unclosed-type', 'No');
        Observer.Expect('lower-case|text', 'The following exception was encountered when processing XML data: ''''doctype'' is an unexpected token. The expected token is ''DOCTYPE''. Line 1, position 3.'' at line 1 and position 3.');
        Observer.Expect('lower-case|code', 'Xml:Xml');
        Observer.Expect('lower-case-type', 'No');
        Observer.Expect('after-root|text', 'The following exception was encountered when processing XML data: ''DTD must be defined before the document root element. Line 1, position 5.'' at line 1 and position 5.');
        Observer.Expect('after-root|code', 'Xml:Xml');
        Observer.Expect('after-root-type', 'No');
        Observer.Expect('two', 'no error');
        Observer.Expect('two-type', 'No');
        Observer.Expect('no-name|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''>'' character, hexadecimal value 0x3E. Line 1, position 11.'' at line 1 and position 11.');
        Observer.Expect('no-name|code', 'Xml:Xml');
        Observer.Expect('no-name-type', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Read_RootMismatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'mismatch', '<!DOCTYPE b><a/>');
        asserterror Probe(Observer, 'undeclared-entity-use', '<!DOCTYPE a><a>&e;</a>');
        Observer.ObserveError('af147');
        asserterror Probe(Observer, 'entity-use', '<!DOCTYPE a [<!ENTITY e "v">]><a>&e;</a>');
        Observer.ObserveError('af150');
        Observer.Expect('mismatch-read', 'Yes');
        Observer.Expect('mismatch-read|text', '');
        Observer.Expect('mismatch-read|code', '');
        Observer.Expect('mismatch-type', 'none');
        Observer.Expect('mismatch-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('undeclared-entity-use-read', 'No');
        Observer.Expect('undeclared-entity-use-read|text', 'The following exception was encountered when processing XML data: ''Reference to undeclared entity ''e''. Line 1, position 17.'' at line 1 and position 17.');
        Observer.Expect('undeclared-entity-use-read|code', 'Xml:Xml');
        Observer.Expect('undeclared-entity-use-type', 'none');
        Observer.Expect('af147|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af147|code', 'InvalidOperation');
        Observer.Expect('entity-use-read', 'No');
        Observer.Expect('entity-use-read|text', 'The following exception was encountered when processing XML data: ''Reference to undeclared entity ''e''. Line 1, position 35.'' at line 1 and position 35.');
        Observer.Expect('entity-use-read|code', 'Xml:Xml');
        Observer.Expect('entity-use-type', 'none');
        Observer.Expect('af150|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af150|code', 'InvalidOperation');
        Observer.Verify();
    end;
}
