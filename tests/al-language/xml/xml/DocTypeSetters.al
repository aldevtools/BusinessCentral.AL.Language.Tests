// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType setters Name, PublicId, SystemId, InternalSubset and their effect on WriteTo
// BC versions: 29 (27 and 28 by CI)

codeunit 72080 "LT P83 DocType Setters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
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
    local procedure TrySetName(V: Text)
    begin
        Dt.SetName(V);
    end;

    [TryFunction]
    local procedure TrySetPublic(V: Text)
    begin
        Dt.SetPublicId(V);
    end;

    [TryFunction]
    local procedure TrySetSystem(V: Text)
    begin
        Dt.SetSystemId(V);
    end;

    [TryFunction]
    local procedure TrySetSubset(V: Text)
    begin
        Dt.SetInternalSubset(V);
    end;

    local procedure Members(): Text
    begin
        exit('[' + GName(Dt) + '|' + GPub(Dt) + '|' + GSys(Dt) + '|' + GSub(Dt) + ']');
    end;

    local procedure Written(): Text
    var
        T: Text;
    begin
        Dt.WriteTo(T);
        exit(T);
    end;

    [Test]
    procedure SetName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        Observer.Observe('set-ok', Format(TrySetName('b')));
        Observer.ObserveError('set-ok');
        Observer.Observe('after', Members());
        Observer.Observe('set-same', Format(TrySetName('b')));
        Observer.Observe('set-empty', Format(TrySetName('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('set-space', Format(TrySetName('a b')));
        Observer.ObserveError('set-space');
        Observer.Observe('after-space', Members());
        Observer.Expect('set-ok', 'Yes');
        Observer.Expect('set-ok|text', '');
        Observer.Expect('set-ok|code', '');
        Observer.Expect('after', '[b|p|s|i]');
        Observer.Expect('set-same', 'Yes');
        Observer.Expect('set-empty', 'No');
        Observer.Expect('set-empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('set-empty|code', 'Argument');
        Observer.Expect('after-empty', '[b|p|s|i]');
        Observer.Expect('set-space', 'No');
        Observer.Expect('set-space|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('set-space|code', 'Xml:Xml');
        Observer.Expect('after-space', '[b|p|s|i]');
        Observer.Verify();
    end;

    [Test]
    procedure SetPublicId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        Observer.Observe('set-ok', Format(TrySetPublic('q')));
        Observer.ObserveError('set-ok');
        Observer.Observe('after', Members());
        Observer.Observe('set-empty', Format(TrySetPublic('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('set-quote', Format(TrySetPublic('a"b')));
        Observer.ObserveError('set-quote');
        Observer.Observe('after-quote', Members());
        Observer.Observe('set-apos', Format(TrySetPublic('a''b')));
        Observer.ObserveError('set-apos');
        Observer.Observe('after-apos', Members());
        Observer.Observe('set-markup', Format(TrySetPublic('<x>')));
        Observer.ObserveError('set-markup');
        Observer.Observe('after-markup', Members());
        Observer.Expect('set-ok', 'Yes');
        Observer.Expect('set-ok|text', '');
        Observer.Expect('set-ok|code', '');
        Observer.Expect('after', '[a|q|s|i]');
        Observer.Expect('set-empty', 'Yes');
        Observer.Expect('set-empty|text', '');
        Observer.Expect('set-empty|code', '');
        Observer.Expect('after-empty', '[a||s|i]');
        Observer.Expect('set-quote', 'Yes');
        Observer.Expect('set-quote|text', '');
        Observer.Expect('set-quote|code', '');
        Observer.Expect('after-quote', '[a|a"b|s|i]');
        Observer.Expect('set-apos', 'Yes');
        Observer.Expect('set-apos|text', '');
        Observer.Expect('set-apos|code', '');
        Observer.Expect('after-apos', '[a|a''b|s|i]');
        Observer.Expect('set-markup', 'Yes');
        Observer.Expect('set-markup|text', '');
        Observer.Expect('set-markup|code', '');
        Observer.Expect('after-markup', '[a|<x>|s|i]');
        Observer.Verify();
    end;

    [Test]
    procedure SetSystemId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        Observer.Observe('set-ok', Format(TrySetSystem('t')));
        Observer.ObserveError('set-ok');
        Observer.Observe('after', Members());
        Observer.Observe('set-empty', Format(TrySetSystem('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('set-quote', Format(TrySetSystem('a"b')));
        Observer.ObserveError('set-quote');
        Observer.Observe('after-quote', Members());
        Observer.Observe('set-url', Format(TrySetSystem('http://example.com/a.dtd')));
        Observer.ObserveError('set-url');
        Observer.Observe('after-url', Members());
        Observer.Expect('set-ok', 'Yes');
        Observer.Expect('set-ok|text', '');
        Observer.Expect('set-ok|code', '');
        Observer.Expect('after', '[a|p|t|i]');
        Observer.Expect('set-empty', 'Yes');
        Observer.Expect('set-empty|text', '');
        Observer.Expect('set-empty|code', '');
        Observer.Expect('after-empty', '[a|p||i]');
        Observer.Expect('set-quote', 'Yes');
        Observer.Expect('set-quote|text', '');
        Observer.Expect('set-quote|code', '');
        Observer.Expect('after-quote', '[a|p|a"b|i]');
        Observer.Expect('set-url', 'Yes');
        Observer.Expect('set-url|text', '');
        Observer.Expect('set-url|code', '');
        Observer.Expect('after-url', '[a|p|http://example.com/a.dtd|i]');
        Observer.Verify();
    end;

    [Test]
    procedure SetInternalSubset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        Observer.Observe('set-ok', Format(TrySetSubset('<!ELEMENT a EMPTY>')));
        Observer.ObserveError('set-ok');
        Observer.Observe('after', Members());
        Observer.Observe('set-empty', Format(TrySetSubset('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('set-text', Format(TrySetSubset('anything at all')));
        Observer.ObserveError('set-text');
        Observer.Observe('after-text', Members());
        Observer.Observe('set-brackets', Format(TrySetSubset(']>')));
        Observer.ObserveError('set-brackets');
        Observer.Observe('after-brackets', Members());
        Observer.Expect('set-ok', 'Yes');
        Observer.Expect('set-ok|text', '');
        Observer.Expect('set-ok|code', '');
        Observer.Expect('after', '[a|p|s|<!ELEMENT a EMPTY>]');
        Observer.Expect('set-empty', 'Yes');
        Observer.Expect('set-empty|text', '');
        Observer.Expect('set-empty|code', '');
        Observer.Expect('after-empty', '[a|p|s|]');
        Observer.Expect('set-text', 'Yes');
        Observer.Expect('set-text|text', '');
        Observer.Expect('set-text|code', '');
        Observer.Expect('after-text', '[a|p|s|anything at all]');
        Observer.Expect('set-brackets', 'Yes');
        Observer.Expect('set-brackets|text', '');
        Observer.Expect('set-brackets|code', '');
        Observer.Expect('after-brackets', '[a|p|s|]>]');
        Observer.Verify();
    end;

    [Test]
    procedure SettersChangeWrittenText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('start', Written());
        Dt.SetName('b');
        Observer.Observe('name', Written());
        Dt.SetSystemId('s.dtd');
        Observer.Observe('system', Written());
        Dt.SetPublicId('-//P//EN');
        Observer.Observe('public', Written());
        Dt.SetInternalSubset('<!ENTITY e "v">');
        Observer.Observe('subset', Written());
        Dt.SetPublicId('');
        Observer.Observe('public-cleared', Written());
        Dt.SetSystemId('');
        Observer.Observe('system-cleared', Written());
        Dt.SetInternalSubset('');
        Observer.Observe('subset-cleared', Written());
        Observer.Expect('start', '<!DOCTYPE a PUBLIC "" ""[]>');
        Observer.Expect('name', '<!DOCTYPE b PUBLIC "" ""[]>');
        Observer.Expect('system', '<!DOCTYPE b PUBLIC "" "s.dtd"[]>');
        Observer.Expect('public', '<!DOCTYPE b PUBLIC "-//P//EN" "s.dtd"[]>');
        Observer.Expect('subset', '<!DOCTYPE b PUBLIC "-//P//EN" "s.dtd"[<!ENTITY e "v">]>');
        Observer.Expect('public-cleared', '<!DOCTYPE b PUBLIC "" "s.dtd"[<!ENTITY e "v">]>');
        Observer.Expect('system-cleared', '<!DOCTYPE b PUBLIC "" ""[<!ENTITY e "v">]>');
        Observer.Expect('subset-cleared', '<!DOCTYPE b PUBLIC "" ""[]>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('html', '', '', '');
        Observer.Observe('name-only', Written());
        Dt := XmlDocumentType.Create('html', '', 'x.dtd', '');
        Observer.Observe('system', Written());
        Dt := XmlDocumentType.Create('html', 'pub', '', '');
        Observer.Observe('public', Written());
        Dt := XmlDocumentType.Create('html', 'pub', 'x.dtd', '');
        Observer.Observe('public-system', Written());
        Dt := XmlDocumentType.Create('html', '', '', '<!ELEMENT html EMPTY>');
        Observer.Observe('subset', Written());
        Dt := XmlDocumentType.Create('html', 'pub', 'x.dtd', '<!ELEMENT html EMPTY>');
        Observer.Observe('all', Written());
        Dt := XmlDocumentType.Create('html', '', '', ' ');
        Observer.Observe('blank-subset', Written());
        Dt := XmlDocumentType.Create('html', 'p"q', 's"t', '');
        asserterror Observer.Observe('quotes', Written());
        Observer.ObserveError('af214');
        Observer.Expect('name-only', '<!DOCTYPE html PUBLIC "" ""[]>');
        Observer.Expect('system', '<!DOCTYPE html PUBLIC "" "x.dtd"[]>');
        Observer.Expect('public', '<!DOCTYPE html PUBLIC "pub" ""[]>');
        Observer.Expect('public-system', '<!DOCTYPE html PUBLIC "pub" "x.dtd"[]>');
        Observer.Expect('subset', '<!DOCTYPE html PUBLIC "" ""[<!ELEMENT html EMPTY>]>');
        Observer.Expect('all', '<!DOCTYPE html PUBLIC "pub" "x.dtd"[<!ELEMENT html EMPTY>]>');
        Observer.Expect('blank-subset', '<!DOCTYPE html PUBLIC "" ""[ ]>');
        Observer.Expect('af214|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('af214|code', 'Argument');
        Observer.Verify();
    end;
}
