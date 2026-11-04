// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType added to a document, written with WriteTo, document type members
// BC versions: 29 (27 and 28 by CI)

codeunit 72081 "LT P83 DocType In Doc"
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
    local procedure TryAdd(Node: XmlDocumentType)
    begin
        Doc.Add(Node);
    end;

    [TryFunction]
    local procedure TryAddElement(E: XmlElement)
    begin
        Doc.Add(E);
    end;

    [TryFunction]
    local procedure TryGetType()
    begin
        Doc.GetDocumentType(Dt);
    end;

    local procedure Written(): Text
    var
        T: Text;
    begin
        Doc.WriteTo(T);
        exit(T);
    end;

    [Test]
    procedure DocumentCreate_WithDocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        asserterror Observer.Observe('only-doctype', Written());
        Observer.ObserveError('af82');
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('with-root', Written());
        Observer.Observe('get-bool', Format(Doc.GetDocumentType(Dt)));
        Observer.Observe('get-name', GName(Dt));
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Expect('af82|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af82|code', 'InvalidOperation');
        Observer.Expect('with-root', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE a PUBLIC "" ""[]>\r\n<a />');
        Observer.Expect('get-bool', 'Yes');
        Observer.Expect('get-name', 'a');
        Observer.Expect('child-count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentCreate_WithDeclarationAndDocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', 'pub', 'sys.dtd', '<!ELEMENT a EMPTY>');
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', 'utf-8', 'yes'), Dt);
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('written', Written());
        Observer.Observe('get-bool', Format(Doc.GetDocumentType(Dt)));
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', '', ''));
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('only-declaration', Written());
        Observer.Expect('written', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<!DOCTYPE a PUBLIC "pub" "sys.dtd"[<!ELEMENT a EMPTY>]>\r\n<a />');
        Observer.Expect('get-bool', 'Yes');
        Observer.Expect('child-count', '2');
        Observer.Expect('only-declaration', '<?xml version="1.0" encoding="" standalone=""?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentAdd_DocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc := XmlDocument.Create();
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('add-first', Format(TryAdd(Dt)));
        Observer.ObserveError('add-first');
        Observer.Observe('add-root', Format(TryAddElement(XmlElement.Create('a'))));
        Observer.ObserveError('add-root');
        Observer.Observe('written', Written());
        Observer.Observe('add-second', Format(TryAdd(XmlDocumentType.Create('b', '', '', ''))));
        Observer.ObserveError('add-second');
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Expect('add-first', 'Yes');
        Observer.Expect('add-first|text', '');
        Observer.Expect('add-first|code', '');
        Observer.Expect('add-root', 'Yes');
        Observer.Expect('add-root|text', '');
        Observer.Expect('add-root|code', '');
        Observer.Expect('written', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE a PUBLIC "" ""[]>\r\n<a />');
        Observer.Expect('add-second', 'No');
        Observer.Expect('add-second|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('add-second|code', 'InvalidOperation');
        Observer.Expect('child-count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentAdd_DocTypeAfterRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc := XmlDocument.Create();
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('add-after-root', Format(TryAdd(XmlDocumentType.Create('a', '', '', ''))));
        Observer.ObserveError('add-after-root');
        Observer.Observe('written', Written());
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Expect('add-after-root', 'No');
        Observer.Expect('add-after-root|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('add-after-root|code', 'InvalidOperation');
        Observer.Expect('written', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('child-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentAdd_DocTypeToElement()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        Dt := XmlDocumentType.Create('a', '', '', '');
        asserterror E.Add(Dt);
        Observer.ObserveError('add-to-element');
        Observer.Observe('element-text', Format(E.HasElements()) + '|' + E.InnerXml());
        Observer.Expect('add-to-element|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('add-to-element|code', 'Argument');
        Observer.Expect('element-text', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentAdd_SameDocTypeTwice()
    var
        Observer: Codeunit "Probe Observer";
        Doc2: XmlDocument;
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('a'));
        Doc2 := XmlDocument.Create();
        Observer.Observe('add-to-second', Format(TryAdd2(Doc2, Dt)));
        Observer.ObserveError('add-to-second');
        Observer.Observe('second-children', Format(Doc2.GetChildNodes().Count()));
        Observer.Observe('first-children', Format(Doc.GetChildNodes().Count()));
        Observer.Observe('first-written', Written());
        Observer.Expect('add-to-second', 'Yes');
        Observer.Expect('add-to-second|text', '');
        Observer.Expect('add-to-second|code', '');
        Observer.Expect('second-children', '1');
        Observer.Expect('first-children', '2');
        Observer.Expect('first-written', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE a PUBLIC "" ""[]>\r\n<a />');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAdd2(D: XmlDocument; Node: XmlDocumentType)
    begin
        D.Add(Node);
    end;

    [Test]
    procedure GetDocumentType_Members()
    var
        Observer: Codeunit "Probe Observer";
        Got: XmlDocumentType;
    begin
        Dt := XmlDocumentType.Create('root', '-//P//EN', 'p.dtd', '<!ENTITY e "v">');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('root'));
        Observer.Observe('bool', Format(Doc.GetDocumentType(Got)));
        Observer.Observe('name', GName(Got));
        Observer.Observe('public', GPub(Got));
        Observer.Observe('system', GSys(Got));
        Observer.Observe('subset', GSub(Got));
        Observer.Expect('bool', 'Yes');
        Observer.Expect('name', 'root');
        Observer.Expect('public', '-//P//EN');
        Observer.Expect('system', 'p.dtd');
        Observer.Expect('subset', '<!ENTITY e "v">');
        Observer.Verify();
    end;

    [Test]
    procedure GetDocumentType_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Observer.Observe('with', Format(TryGetType()));
        Observer.ObserveError('with');
        Doc := XmlDocument.Create();
        Observer.Observe('without', Format(TryGetType()));
        Observer.ObserveError('without');
        Clear(Doc);
        Observer.Observe('default-doc', Format(TryGetType()));
        Observer.ObserveError('default-doc');
        Observer.Expect('with', 'Yes');
        Observer.Expect('with|text', '');
        Observer.Expect('with|code', '');
        Observer.Expect('without', 'No');
        Observer.Expect('without|text', 'The XML node is not set.');
        Observer.Expect('without|code', 'XmlNodeNotFound');
        Observer.Expect('default-doc', 'No');
        Observer.Expect('default-doc|text', 'The XML node is not set.');
        Observer.Expect('default-doc|code', 'XmlNodeNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentWriteTo_ToOutStream_AndSelect()
    var
        Observer: Codeunit "Probe Observer";
        Nodes: XmlNodeList;
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('select-all', Format(Doc.SelectNodes('/*', Nodes)));
        Observer.Observe('select-count', Format(Nodes.Count()));
        Observer.Observe('child-type-1', ChildKind(1));
        Observer.Observe('child-type-2', ChildKind(2));
        Observer.Observe('child-type-3', ChildKind(3));
        Observer.Expect('select-all', 'Yes');
        Observer.Expect('select-count', '1');
        Observer.Expect('child-type-1', 'doctype');
        Observer.Expect('child-type-2', 'element');
        Observer.Expect('child-type-3', 'none');
        Observer.Verify();
    end;

    local procedure ChildKind(Index: Integer): Text
    var
        Nodes: XmlNodeList;
        N: XmlNode;
    begin
        Nodes := Doc.GetChildNodes();
        if not Nodes.Get(Index, N) then
            exit('none');
        if N.IsXmlDocumentType() then
            exit('doctype');
        if N.IsXmlElement() then
            exit('element');
        if N.IsXmlDeclaration() then
            exit('declaration');
        exit('other');
    end;
}
