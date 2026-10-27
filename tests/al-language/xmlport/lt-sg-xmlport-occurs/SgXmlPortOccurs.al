// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in SgXmlPortObjects.al (writer SG, ids 89360-89364); test codeunit 89365
// Probe: export and import of
//  - a field attribute with Occurrence = Required / Optional (and a Required text attribute) whose parent is a text element inside a table
//    element: values set, values blank or zero, no row; import with every attribute, an Optional one missing, a Required one missing;
//  - table elements with MaxOccurs = Once (temporary, MinOccurs = Zero, below a container text element and below the root; real table
//    with the default MinOccurs): export of 0, 1 and 2 rows, import of 0, 1 and 2 elements;
//  - UseDefaultNamespace = true without DefaultNamespace: the namespace of the export, and import with that namespace, without a
//    namespace and with another one.
// Observed on the corpus CI matrix (27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

codeunit 89365 "LT SG XP Occurs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    local procedure Source(Content: Text; var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    // ---- Occurrence on attributes below a text element ----

    local procedure ExportAttr(var Port: XmlPort "LT SG XP Attr Below Text"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ReadAll(TempBlob));
    end;

    [TryFunction]
    local procedure TryImportAttr(var Port: XmlPort "LT SG XP Attr Below Text"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Content, TempBlob, InS);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure ImportAttr(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        Port: XmlPort "LT SG XP Attr Below Text";
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportAttr(Port, Content)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Port.Rows());
        Observer.Observe(Name + ' log', Port.GetLog());
    end;

    [Test]
    procedure SG_AttrBelowText_Export_ValuesSet()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Attr Below Text";
    begin
        Port.AddRow(1, 7, 'n');
        Port.AddRow(2, 8, 'm');
        Observer.Observe('two rows', ExportAttr(Port));
        Observer.Finish();
    end;

    [Test]
    procedure SG_AttrBelowText_Export_BlankAndZero()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Attr Below Text";
    begin
        Port.AddRow(0, 0, '');
        Observer.Observe('blank row', ExportAttr(Port));
        Observer.Finish();
    end;

    [Test]
    procedure SG_AttrBelowText_Export_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Attr Below Text";
    begin
        Observer.Observe('no row', ExportAttr(Port));
        Observer.Finish();
    end;

    [Test]
    procedure SG_AttrBelowText_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportAttr(Observer, 'all present', '<Root><Row Id="1"><Sched EntryNo="7" Note="n" Kind="a"/></Row></Root>');
        ImportAttr(Observer, 'optional missing', '<Root><Row Id="1"><Sched EntryNo="7" Kind="a"/></Row></Root>');
        ImportAttr(Observer, 'required field attribute missing', '<Root><Row Id="1"><Sched Note="n" Kind="a"/></Row></Root>');
        ImportAttr(Observer, 'required text attribute missing', '<Root><Row Id="1"><Sched EntryNo="7" Note="n"/></Row></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure SG_AttrBelowText_Import_Missing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportAttr(Observer, 'required on row missing', '<Root><Row><Sched EntryNo="7" Kind="a"/></Row></Root>');
        ImportAttr(Observer, 'text element missing', '<Root><Row Id="1"/></Root>');
        ImportAttr(Observer, 'second row missing required', '<Root><Row Id="1"><Sched EntryNo="7" Kind="a"/></Row><Row Id="2"><Sched Kind="b"/></Row></Root>');
        ImportAttr(Observer, 'empty value', '<Root><Row Id="1"><Sched EntryNo="" Kind=""/></Row></Root>');
        Observer.Finish();
    end;

    // ---- MaxOccurs = Once on table elements ----

    local procedure ExportOnceTemp(var Port: XmlPort "LT SG XP Once Temp"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ReadAll(TempBlob));
    end;

    [TryFunction]
    local procedure TryExportOnceTemp(var Port: XmlPort "LT SG XP Once Temp"; var Xml: Text)
    begin
        Xml := ExportOnceTemp(Port);
    end;

    local procedure ObserveExportOnceTemp(var Observer: Codeunit "Probe Observer"; Name: Text; var Port: XmlPort "LT SG XP Once Temp")
    var
        Xml: Text;
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryExportOnceTemp(Port, Xml)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' xml', Xml);
    end;

    [TryFunction]
    local procedure TryImportOnceTemp(var Port: XmlPort "LT SG XP Once Temp"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Content, TempBlob, InS);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure ImportOnceTemp(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        Port: XmlPort "LT SG XP Once Temp";
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportOnceTemp(Port, Content)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Port.Rows());
        Observer.Observe(Name + ' log', Port.GetLog());
    end;

    [Test]
    procedure SG_OnceTemp_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Once Temp";
    begin
        ObserveExportOnceTemp(Observer, 'none', Port);
        Observer.Finish();
    end;

    [Test]
    procedure SG_OnceTemp_Export_OneRowEach()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Once Temp";
    begin
        Port.AddReq(1, 'a');
        Port.AddResp(5);
        ObserveExportOnceTemp(Observer, 'one each', Port);
        Observer.Finish();
    end;

    [Test]
    procedure SG_OnceTemp_Export_TwoRowsEach()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Once Temp";
    begin
        Port.AddReq(1, 'a');
        Port.AddReq(2, 'b');
        Port.AddResp(5);
        Port.AddResp(6);
        ObserveExportOnceTemp(Observer, 'two each', Port);
        Observer.Finish();
    end;

    [Test]
    procedure SG_OnceTemp_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportOnceTemp(Observer, 'empty request', '<Root><Request/></Root>');
        ImportOnceTemp(Observer, 'no request', '<Root/>');
        ImportOnceTemp(Observer, 'one each', '<Root><Request><Req><ReqId>1</ReqId><ReqNote>a</ReqNote></Req></Request><Resp><RespId>5</RespId></Resp></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure SG_OnceTemp_Import_Two()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportOnceTemp(Observer, 'two req', '<Root><Request><Req><ReqId>1</ReqId></Req><Req><ReqId>2</ReqId></Req></Request></Root>');
        ImportOnceTemp(Observer, 'two resp', '<Root><Request/><Resp><RespId>5</RespId></Resp><Resp><RespId>6</RespId></Resp></Root>');
        ImportOnceTemp(Observer, 'two request elements', '<Root><Request/><Request/></Root>');
        Observer.Finish();
    end;

    local procedure ResetRealRows(Ids: List of [Integer])
    var
        T: Record "LT SG XP Row";
        Id: Integer;
    begin
        T.DeleteAll();
        foreach Id in Ids do begin
            T.Init();
            T.Id := Id;
            T.Note := 'n' + Format(Id);
            T.Insert();
        end;
        Commit();
    end;

    local procedure RealRows() Result: Text
    var
        T: Record "LT SG XP Row";
    begin
        if T.FindSet() then
            repeat
                Result += Format(T.Id) + ':' + T.Note + ',';
            until T.Next() = 0;
    end;

    [TryFunction]
    local procedure TryExportReal(var Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT SG XP Once Real", OutS);
        Xml := ReadAll(TempBlob);
    end;

    local procedure ObserveExportReal(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Xml: Text;
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryExportReal(Xml)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' xml', Xml);
    end;

    local procedure ImportReal(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Empty: List of [Integer];
    begin
        ResetRealRows(Empty);
        Source(Content, TempBlob, InS);
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(Xmlport.Import(Xmlport::"LT SG XP Once Real", InS)));
        Observer.ObserveError(Name);
        Commit();
        Observer.Observe(Name + ' rows', RealRows());
    end;

    [Test]
    procedure SG_OnceReal_Export()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
    begin
        ResetRealRows(Ids);
        ObserveExportReal(Observer, 'none');
        Ids.Add(1);
        ResetRealRows(Ids);
        ObserveExportReal(Observer, 'one');
        Ids.Add(2);
        ResetRealRows(Ids);
        ObserveExportReal(Observer, 'two');
        Clear(Ids);
        ResetRealRows(Ids);
        Observer.Finish();
    end;

    [Test]
    procedure SG_OnceReal_Import()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
    begin
        ImportReal(Observer, 'none', '<Root/>');
        ImportReal(Observer, 'one', '<Root><T><Id>1</Id><Note>a</Note></T></Root>');
        ImportReal(Observer, 'two', '<Root><T><Id>1</Id><Note>a</Note></T><T><Id>2</Id><Note>b</Note></T></Root>');
        ResetRealRows(Ids);
        Observer.Finish();
    end;

    // ---- UseDefaultNamespace = true without DefaultNamespace ----

    [TryFunction]
    local procedure TryImportNs(var Port: XmlPort "LT SG XP Default Ns"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Content, TempBlob, InS);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure ImportNs(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        Port: XmlPort "LT SG XP Default Ns";
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportNs(Port, Content)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Port.Rows());
    end;

    [Test]
    procedure SG_DefaultNs_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Default Ns";
        Empty: XmlPort "LT SG XP Default Ns";
        TempBlob: Codeunit "Temp Blob";
        EmptyBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Port.AddRow(3, 'x');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('one row', ReadAll(TempBlob));
        EmptyBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Empty.SetDestination(OutS);
        Empty.Export();
        Observer.Observe('no row', ReadAll(EmptyBlob));
        Observer.Finish();
    end;

    [Test]
    procedure SG_DefaultNs_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportNs(Observer, 'with the namespace', '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89364"><Row Note="x"><Id>3</Id></Row></Root>');
        ImportNs(Observer, 'without a namespace', '<Root><Row Note="x"><Id>3</Id></Row></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure SG_DefaultNs_Import_Other()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportNs(Observer, 'another namespace', '<Root xmlns="urn:other"><Row Note="x"><Id>3</Id></Row></Root>');
        ImportNs(Observer, 'namespace on the root only', '<ns:Root xmlns:ns="urn:microsoft-dynamics-nav/xmlports/x89364"><Row Note="x"><Id>3</Id></Row></ns:Root>');
        ImportNs(Observer, 'prefixed everywhere', '<ns:Root xmlns:ns="urn:microsoft-dynamics-nav/xmlports/x89364"><ns:Row Note="x"><ns:Id>3</ns:Id></ns:Row></ns:Root>');
        Observer.Finish();
    end;
}
