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
        Observer.Finish();
    end;

    [Test]
    procedure XpNs_EmptyPrefixLast_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Empty Last");
        Observer.Finish();
    end;

    [Test]
    procedure XpNs_EmptyPrefixAmongSeveral_UseDefault()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Empty UseDefault");
        Observer.Finish();
    end;

    [Test]
    procedure XpNs_PrefixedOnly_UnprefixedRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', Xmlport::"LT Y17 Ns Prefixed Only");
        Observer.Finish();
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
        Observer.Finish();
    end;

    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; Xml: Text)
    var
        Row: Record "LT Y17 Ns Row";
        Port: XmlPort "LT Y17 Ns Empty Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Rows: Text;
    begin
        Row.DeleteAll();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        ClearLastError();
        if Port.Import() then
            Observer.Observe(Name, 'ok ' + Port.Got())
        else
            Observer.ObserveError(Name + ' error');
        if Row.FindSet() then
            repeat
                Rows += Format(Row.Id) + '/' + Row.Name + '/' + Format(Row.Amount, 0, 9) + ';';
            until Row.Next() = 0;
        Observer.Observe(Name + ' rows', Rows);
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
