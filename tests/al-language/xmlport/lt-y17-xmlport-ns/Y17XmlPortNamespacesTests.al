// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-namespaces-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of Y17XmlPortNamespaces.al
// Probe: gap cycle 1, G15 (corpus writer Y17). See Y17XmlPortNamespaces.al for the facts. Line breaks of the exported text are shown as |.
// BC versions: 27-29

codeunit 91836 "LT Y17 Xp Ns Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y17 Ns Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Amount := 0;
        Row.Insert();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Amount := 1.5;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryExport(XmlPortId: Integer; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
    begin
        Result := '';
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
    end;

    local procedure Export(var Observer: Codeunit "Probe Observer"; Name: Text; XmlPortId: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryExport(XmlPortId, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name + ' error');
        exit(Result);
    end;

    [Test]
    procedure XpNs_EmptyPrefixAmongSeveral_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Empty First");
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Doc xmlns:a="urn:lt-a" xmlns:b="urn:lt-b" xmlns:u="urn:lt-unused" xmlns="urn:lt-d">|  <b:DocId>D1</b:DocId>|  <a:Party>|    <b:EndpointID schemeID="0088">E1</b:EndpointID>|    <Plain>p</Plain>|  </a:Party>|  <a:Line>|    <b:Id>1</b:Id>|    <b:Amount>1.50</b:Amount>|    <Name>one</Name>|  </a:Line>|  <a:Line>|    <b:Id>2</b:Id>|    <b:Amount>0.00</b:Amount>|    <Name>two</Name>|  </a:Line>|</Doc>|');
        Observer.Verify();
    end;

    [Test]
    procedure XpNs_EmptyPrefixLast_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Empty Last");
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Doc xmlns:a="urn:lt-a" xmlns:b="urn:lt-b" xmlns:u="urn:lt-unused" xmlns="urn:lt-d">|  <b:DocId>D1</b:DocId>|  <a:Party>|    <b:EndpointID schemeID="0088">E1</b:EndpointID>|    <Plain>p</Plain>|  </a:Party>|  <a:Line>|    <b:Id>1</b:Id>|    <b:Amount>1.50</b:Amount>|    <Name>one</Name>|  </a:Line>|  <a:Line>|    <b:Id>2</b:Id>|    <b:Amount>0.00</b:Amount>|    <Name>two</Name>|  </a:Line>|</Doc>|');
        Observer.Verify();
    end;

    [Test]
    procedure XpNs_EmptyPrefixAmongSeveral_UseDefault()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Empty UseDefault");
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Doc xmlns:a="urn:lt-a" xmlns:b="urn:lt-b" xmlns:u="urn:lt-unused" xmlns="urn:lt-dflt">|  <b:DocId>D1</b:DocId>|  <a:Party>|    <b:EndpointID schemeID="0088">E1</b:EndpointID>|    <Plain>p</Plain>|  </a:Party>|  <a:Line>|    <b:Id>1</b:Id>|    <b:Amount>1.50</b:Amount>|    <Name>one</Name>|  </a:Line>|  <a:Line>|    <b:Id>2</b:Id>|    <b:Amount>0.00</b:Amount>|    <Name>two</Name>|  </a:Line>|</Doc>|');
        Observer.Verify();
    end;

    [Test]
    procedure XpNs_PrefixedOnly_UnprefixedRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Prefixed Only");
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Doc xmlns:a="urn:lt-a" xmlns:b="urn:lt-b" xmlns:u="urn:lt-unused">|  <b:DocId>D1</b:DocId>|  <a:Party>|    <b:EndpointID schemeID="0088">E1</b:EndpointID>|    <Plain>p</Plain>|  </a:Party>|  <a:Line>|    <b:Id>1</b:Id>|    <b:Amount>1.50</b:Amount>|    <Name>one</Name>|  </a:Line>|  <a:Line>|    <b:Id>2</b:Id>|    <b:Amount>0.00</b:Amount>|    <Name>two</Name>|  </a:Line>|</Doc>|');
        Observer.Verify();
    end;

    local procedure Find(var Observer: Codeunit "Probe Observer"; Doc: XmlDocument; NsMgr: XmlNamespaceManager; XPath: Text)
    var
        Node: XmlNode;
    begin
        if Doc.SelectSingleNode(XPath, NsMgr, Node) then
            Observer.Observe(XPath, 'found ' + Node.AsXmlElement().InnerText())
        else
            Observer.Observe(XPath, 'not found');
    end;

    [Test]
    procedure XpNs_EmptyPrefixAmongSeveral_ParseBack()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        NsMgr: XmlNamespaceManager;
        Text: Text;
    begin
        Seed();
        Observer.Observe('export ok', Format(TryExport(Xmlport::"LT Y17 Ns Empty First", Text)));
        Observer.Observe('read', Format(XmlDocument.ReadFrom(Text.Replace('|', ''), Doc)));
        Doc.GetRoot(Root);
        Observer.Observe('root uri', Root.NamespaceUri());
        Observer.Observe('root local name', Root.LocalName());
        NsMgr.NameTable(Doc.NameTable());
        NsMgr.AddNamespace('d', 'urn:lt-d');
        NsMgr.AddNamespace('a', 'urn:lt-a');
        NsMgr.AddNamespace('b', 'urn:lt-b');
        Find(Observer, Doc, NsMgr, '/d:Doc/a:Party/b:EndpointID');
        Find(Observer, Doc, NsMgr, '/d:Doc/a:Party/d:Plain');
        Find(Observer, Doc, NsMgr, '/d:Doc/a:Party/Plain');
        Find(Observer, Doc, NsMgr, '/d:Doc/a:Line/d:Name');
        Find(Observer, Doc, NsMgr, '/d:Doc/a:Line/Name');
        Find(Observer, Doc, NsMgr, '/Doc');
        Observer.Expect('export ok', 'Yes');
        Observer.Expect('read', 'Yes');
        Observer.Expect('root uri', 'urn:lt-d');
        Observer.Expect('root local name', 'Doc');
        Observer.Expect('/d:Doc/a:Party/b:EndpointID', 'found E1');
        Observer.Expect('/d:Doc/a:Party/d:Plain', 'found p');
        Observer.Expect('/d:Doc/a:Party/Plain', 'not found');
        Observer.Expect('/d:Doc/a:Line/d:Name', 'found one');
        Observer.Expect('/d:Doc/a:Line/Name', 'not found');
        Observer.Expect('/Doc', 'not found');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryImport(var Port: XmlPort "LT Y17 Ns Empty Import"; InS: InStream)
    begin
        Port.SetSource(InS);
        Port.Import();
    end;

    // The import port keeps its rows in a temporary table element, so a failed import writes nothing.
    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; Xml: Text)
    var
        Port: XmlPort "LT Y17 Ns Empty Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        ClearLastError();
        if TryImport(Port, InS) then
            Observer.Observe(Name, 'ok ' + Port.Got())
        else
            Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' rows', Port.Rows());
    end;

    [Test]
    procedure XpNs_EmptyPrefixAmongSeveral_Import()
    var
        Observer: Codeunit "Probe Observer";
        Text: Text;
    begin
        Seed();
        Observer.Observe('export ok', Format(TryExport(Xmlport::"LT Y17 Ns Empty First", Text)));
        Text := Text.Replace('|', '');
        Import(Observer, 'as exported', Text);
        Import(Observer, 'without xmlns', Text.Replace(' xmlns="urn:lt-d"', ''));
        Observer.Finish();
    end;
}
