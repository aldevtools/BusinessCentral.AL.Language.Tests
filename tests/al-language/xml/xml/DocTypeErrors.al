// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType and XmlDeclaration error texts: invalid names and values, uninitialised objects
// BC versions: 29 (27 and 28 by CI)

codeunit 72086 "LT P83 DocType Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dt: XmlDocumentType;
        Decl: XmlDeclaration;
        Doc: XmlDocument;

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
    local procedure TryCreate(N: Text)
    begin
        Dt := XmlDocumentType.Create(N, '', '', '');
    end;

    [TryFunction]
    local procedure TryName()
    var
        T: Text;
    begin
        T := GName(Dt);
    end;

    [TryFunction]
    local procedure TryPublicId()
    var
        T: Text;
    begin
        T := GPub(Dt);
    end;

    [TryFunction]
    local procedure TrySystemId()
    var
        T: Text;
    begin
        T := GSys(Dt);
    end;

    [TryFunction]
    local procedure TrySubset()
    var
        T: Text;
    begin
        T := GSub(Dt);
    end;

    [TryFunction]
    local procedure TrySetName()
    begin
        Dt.SetName('x');
    end;

    [TryFunction]
    local procedure TrySetSubset()
    begin
        Dt.SetInternalSubset('x');
    end;

    [TryFunction]
    local procedure TryWriteTo()
    var
        T: Text;
    begin
        Dt.WriteTo(T);
    end;

    [TryFunction]
    local procedure TryRemove()
    begin
        Dt.Remove();
    end;

    [TryFunction]
    local procedure TryAsNode()
    var
        N: XmlNode;
    begin
        N := Dt.AsXmlNode();
    end;

    [TryFunction]
    local procedure TryDocCreate()
    begin
        Doc := XmlDocument.Create(Dt);
    end;

    [TryFunction]
    local procedure TryDocAdd()
    begin
        Doc := XmlDocument.Create();
        Doc.Add(Dt);
    end;

    [TryFunction]
    local procedure TryDeclVersion()
    var
        T: Text;
    begin
        T := Decl.Version();
    end;

    [TryFunction]
    local procedure TryDeclSetEncoding()
    begin
        Decl.Encoding('utf-8');
    end;

    [TryFunction]
    local procedure TryDeclWriteTo()
    var
        T: Text;
    begin
        Decl.WriteTo(T);
    end;

    [TryFunction]
    local procedure TryDocSetDecl()
    begin
        Doc := XmlDocument.Create();
        Doc.SetDeclaration(Decl);
    end;

    [Test]
    procedure Create_InvalidNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', Format(TryCreate('')));
        Observer.ObserveError('empty');
        Observer.Observe('space', Format(TryCreate(' ')));
        Observer.ObserveError('space');
        Observer.Observe('inner-space', Format(TryCreate('a b')));
        Observer.ObserveError('inner-space');
        Observer.Observe('digit-first', Format(TryCreate('1a')));
        Observer.ObserveError('digit-first');
        Observer.Observe('angle', Format(TryCreate('<a>')));
        Observer.ObserveError('angle');
        Observer.Observe('slash', Format(TryCreate('a/b')));
        Observer.ObserveError('slash');
        Observer.Observe('hyphen-first', Format(TryCreate('-a')));
        Observer.ObserveError('hyphen-first');
        Observer.Observe('quote', Format(TryCreate('a"b')));
        Observer.ObserveError('quote');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('space', 'No');
        Observer.Expect('space|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the '' '' character, hexadecimal value 0x20.'' at line 0 and position 1.');
        Observer.Expect('space|code', 'Xml:Xml');
        Observer.Expect('inner-space', 'No');
        Observer.Expect('inner-space|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('inner-space|code', 'Xml:Xml');
        Observer.Expect('digit-first', 'No');
        Observer.Expect('digit-first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('digit-first|code', 'Xml:Xml');
        Observer.Expect('angle', 'No');
        Observer.Expect('angle|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''<'' character, hexadecimal value 0x3C.'' at line 0 and position 1.');
        Observer.Expect('angle|code', 'Xml:Xml');
        Observer.Expect('slash', 'No');
        Observer.Expect('slash|text', 'The following exception was encountered when processing XML data: ''The ''/'' character, hexadecimal value 0x2F, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('slash|code', 'Xml:Xml');
        Observer.Expect('hyphen-first', 'No');
        Observer.Expect('hyphen-first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''-'' character, hexadecimal value 0x2D.'' at line 0 and position 1.');
        Observer.Expect('hyphen-first|code', 'Xml:Xml');
        Observer.Expect('quote', 'No');
        Observer.Expect('quote|text', 'The following exception was encountered when processing XML data: ''The ''"'' character, hexadecimal value 0x22, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('quote|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Create_InvalidNames_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Dt := XmlDocumentType.Create('', '', '', '');
        Observer.ObserveError('empty');
        asserterror Dt := XmlDocumentType.Create('a b', '', '', '');
        Observer.ObserveError('inner-space');
        asserterror Dt := XmlDocumentType.Create('1', '', '', '');
        Observer.ObserveError('digit');
        Observer.Expect('empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('inner-space|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('inner-space|code', 'Xml:Xml');
        Observer.Expect('digit|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('digit|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialised_Getters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Dt);
        Observer.Observe('name', Format(TryName()));
        Observer.ObserveError('name');
        Observer.Observe('public', Format(TryPublicId()));
        Observer.ObserveError('public');
        Observer.Observe('system', Format(TrySystemId()));
        Observer.ObserveError('system');
        Observer.Observe('subset', Format(TrySubset()));
        Observer.ObserveError('subset');
        Observer.Expect('name', 'No');
        Observer.Expect('name|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('name|code', 'NotInitialized');
        Observer.Expect('public', 'No');
        Observer.Expect('public|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('public|code', 'NotInitialized');
        Observer.Expect('system', 'No');
        Observer.Expect('system|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('system|code', 'NotInitialized');
        Observer.Expect('subset', 'No');
        Observer.Expect('subset|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('subset|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialised_SettersAndMethods()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Dt);
        Observer.Observe('set-name', Format(TrySetName()));
        Observer.ObserveError('set-name');
        Observer.Observe('set-subset', Format(TrySetSubset()));
        Observer.ObserveError('set-subset');
        Observer.Observe('write-to', Format(TryWriteTo()));
        Observer.ObserveError('write-to');
        Observer.Observe('remove', Format(TryRemove()));
        Observer.ObserveError('remove');
        Observer.Observe('as-node', Format(TryAsNode()));
        Observer.ObserveError('as-node');
        Observer.Expect('set-name', 'No');
        Observer.Expect('set-name|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('set-name|code', 'NotInitialized');
        Observer.Expect('set-subset', 'No');
        Observer.Expect('set-subset|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('set-subset|code', 'NotInitialized');
        Observer.Expect('write-to', 'No');
        Observer.Expect('write-to|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('write-to|code', 'NotInitialized');
        Observer.Expect('remove', 'No');
        Observer.Expect('remove|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('remove|code', 'NotInitialized');
        Observer.Expect('as-node', 'Yes');
        Observer.Expect('as-node|text', '');
        Observer.Expect('as-node|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialised_UsedInDocument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Dt);
        Observer.Observe('doc-create', Format(TryDocCreate()));
        Observer.ObserveError('doc-create');
        Observer.Observe('doc-add', Format(TryDocAdd()));
        Observer.ObserveError('doc-add');
        Observer.Expect('doc-create', 'No');
        Observer.Expect('doc-create|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('doc-create|code', 'NotInitialized');
        Observer.Expect('doc-add', 'No');
        Observer.Expect('doc-add|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('doc-add|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialised_Declaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Decl);
        Observer.Observe('version', Format(TryDeclVersion()));
        Observer.ObserveError('version');
        Observer.Observe('set-encoding', Format(TryDeclSetEncoding()));
        Observer.ObserveError('set-encoding');
        Observer.Observe('write-to', Format(TryDeclWriteTo()));
        Observer.ObserveError('write-to');
        Observer.Observe('doc-set-declaration', Format(TryDocSetDecl()));
        Observer.ObserveError('doc-set-declaration');
        Observer.Expect('version', 'No');
        Observer.Expect('version|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDeclaration variable not initialized.');
        Observer.Expect('version|code', 'NotInitialized');
        Observer.Expect('set-encoding', 'No');
        Observer.Expect('set-encoding|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDeclaration variable not initialized.');
        Observer.Expect('set-encoding|code', 'NotInitialized');
        Observer.Expect('write-to', 'No');
        Observer.Expect('write-to|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('write-to|code', 'NotInitialized');
        Observer.Expect('doc-set-declaration', 'No');
        Observer.Expect('doc-set-declaration|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDeclaration variable not initialized.');
        Observer.Expect('doc-set-declaration|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialised_DocumentMembers()
    var
        Observer: Codeunit "Probe Observer";
        Got: XmlDocumentType;
        GotDecl: XmlDeclaration;
    begin
        Clear(Doc);
        Observer.Observe('get-type', Format(TryGetType(Got)));
        Observer.ObserveError('get-type');
        Observer.Observe('get-declaration', Format(TryGetDecl(GotDecl)));
        Observer.ObserveError('get-declaration');
        Observer.Expect('get-type', 'No');
        Observer.Expect('get-type|text', 'The XML node is not set.');
        Observer.Expect('get-type|code', 'XmlNodeNotFound');
        Observer.Expect('get-declaration', 'No');
        Observer.Expect('get-declaration|text', 'The XML node is not set.');
        Observer.Expect('get-declaration|code', 'XmlNodeNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetType(var Got: XmlDocumentType)
    begin
        Doc.GetDocumentType(Got);
    end;

    [TryFunction]
    local procedure TryGetDecl(var Got: XmlDeclaration)
    begin
        Doc.GetDeclaration(Got);
    end;

    [Test]
    procedure FormatOfUninitialisedAndInitialised()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Clear(Dt);
        asserterror Observer.Observe('format-uninit', Format(Dt));
        Observer.ObserveError('af302');
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        Observer.Observe('format-init', Format(Dt));
        Observer.Observe('format-decl', Format(XmlDeclaration.Create('1.0', 'utf-8', 'yes')));
        Observer.Expect('af302|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('af302|code', 'NotInitialized');
        Observer.Expect('format-init', '<!DOCTYPE a PUBLIC "p" "s"[i]>');
        Observer.Expect('format-decl', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>');
        Observer.Verify();
    end;
}
