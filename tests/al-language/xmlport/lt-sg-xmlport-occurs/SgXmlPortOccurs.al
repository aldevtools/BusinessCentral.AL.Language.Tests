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
// Writer TF (2026-10-28, objects in TfXmlPortObjects.al, ids 89835-89838): an explicit MinOccurs = Once on a temporary table element with and without
//   MaxOccurs = Once (TF_MinOnce_*, TF_MinMaxOnce_*), on a real table (TF_MinMaxOnceReal_*), and UseDefaultNamespace = true with a text attribute on the root,
//   a field attribute on a table element, a text attribute and a field attribute on a text element (TF_NsAttr_*): export, import with plain, prefixed and
//   no namespace.
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
        Observer.Expect('two rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row Id="1">|    <Sched EntryNo="7" Note="n" Kind="k1" />|  </Row>|  <Row Id="2">|    <Sched EntryNo="8" Note="m" Kind="k2" />|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SG_AttrBelowText_Export_BlankAndZero()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Attr Below Text";
    begin
        Port.AddRow(0, 0, '');
        Observer.Observe('blank row', ExportAttr(Port));
        Observer.Expect('blank row', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row Id="0">|    <Sched EntryNo="0" Kind="k0" />|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SG_AttrBelowText_Export_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT SG XP Attr Below Text";
    begin
        Observer.Observe('no row', ExportAttr(Port));
        Observer.Expect('no row', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root />|');
        Observer.Verify();
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
        Observer.Expect('all present ok', 'Yes');
        Observer.Expect('all present|text', '');
        Observer.Expect('all present|code', '');
        Observer.Expect('all present rows', '1:7:n,');
        Observer.Expect('all present log', 'Kind=a;Insert 1:7:n;');
        Observer.Expect('optional missing ok', 'Yes');
        Observer.Expect('optional missing|text', '');
        Observer.Expect('optional missing|code', '');
        Observer.Expect('optional missing rows', '1:7:,');
        Observer.Expect('optional missing log', 'Kind=a;Insert 1:7:;');
        Observer.Expect('required field attribute missing ok', 'No');
        Observer.Expect('required field attribute missing|text', 'Imported XML cannot validate with the schema: The required attribute ''EntryNo'' is missing.');
        Observer.Expect('required field attribute missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required field attribute missing rows', '');
        Observer.Expect('required field attribute missing log', '');
        Observer.Expect('required text attribute missing ok', 'No');
        Observer.Expect('required text attribute missing|text', 'Imported XML cannot validate with the schema: The required attribute ''Kind'' is missing.');
        Observer.Expect('required text attribute missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required text attribute missing rows', '');
        Observer.Expect('required text attribute missing log', '');
        Observer.Verify();
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
        Observer.Expect('required on row missing ok', 'No');
        Observer.Expect('required on row missing|text', 'Imported XML cannot validate with the schema: The required attribute ''Id'' is missing.');
        Observer.Expect('required on row missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required on row missing rows', '');
        Observer.Expect('required on row missing log', '');
        Observer.Expect('text element missing ok', 'No');
        Observer.Expect('text element missing|text', 'Imported XML cannot validate with the schema: The element ''Row'' has incomplete content. List of possible elements expected: ''Sched''.');
        Observer.Expect('text element missing|code', 'XmlPortInvalidXml');
        Observer.Expect('text element missing rows', '');
        Observer.Expect('text element missing log', '');
        Observer.Expect('second row missing required ok', 'No');
        Observer.Expect('second row missing required|text', 'Imported XML cannot validate with the schema: The required attribute ''EntryNo'' is missing.');
        Observer.Expect('second row missing required|code', 'XmlPortInvalidXml');
        Observer.Expect('second row missing required rows', '1:7:,');
        Observer.Expect('second row missing required log', 'Kind=a;Insert 1:7:;');
        Observer.Expect('empty value ok', 'Yes');
        Observer.Expect('empty value|text', '');
        Observer.Expect('empty value|code', '');
        Observer.Expect('empty value rows', '1:0:,');
        Observer.Expect('empty value log', 'Kind=;Insert 1:0:;');
        Observer.Verify();
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
        Observer.Expect('none ok', 'Yes');
        Observer.Expect('none|text', '');
        Observer.Expect('none|code', '');
        Observer.Expect('none xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Request />|</Root>|');
        Observer.Verify();
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
        Observer.Expect('one each ok', 'Yes');
        Observer.Expect('one each|text', '');
        Observer.Expect('one each|code', '');
        Observer.Expect('one each xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Request>|    <Req>|      <ReqId>1</ReqId>|      <ReqNote>a</ReqNote>|    </Req>|  </Request>|  <Resp>|    <RespId>5</RespId>|  </Resp>|</Root>|');
        Observer.Verify();
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
        Observer.Expect('two each ok', 'Yes');
        Observer.Expect('two each|text', '');
        Observer.Expect('two each|code', '');
        Observer.Expect('two each xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Request>|    <Req>|      <ReqId>1</ReqId>|      <ReqNote>a</ReqNote>|    </Req>|  </Request>|  <Resp>|    <RespId>5</RespId>|  </Resp>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OnceTemp_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportOnceTemp(Observer, 'empty request', '<Root><Request/></Root>');
        ImportOnceTemp(Observer, 'no request', '<Root/>');
        ImportOnceTemp(Observer, 'one each', '<Root><Request><Req><ReqId>1</ReqId><ReqNote>a</ReqNote></Req></Request><Resp><RespId>5</RespId></Resp></Root>');
        Observer.Expect('empty request ok', 'Yes');
        Observer.Expect('empty request|text', '');
        Observer.Expect('empty request|code', '');
        Observer.Expect('empty request rows', '');
        Observer.Expect('empty request log', '');
        Observer.Expect('no request ok', 'No');
        Observer.Expect('no request|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Request''.');
        Observer.Expect('no request|code', 'XmlPortInvalidXml');
        Observer.Expect('no request rows', '');
        Observer.Expect('no request log', '');
        Observer.Expect('one each ok', 'Yes');
        Observer.Expect('one each|text', '');
        Observer.Expect('one each|code', '');
        Observer.Expect('one each rows', 'req1:a,resp5,');
        Observer.Expect('one each log', 'Req 1;Resp 5;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OnceTemp_Import_Two()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportOnceTemp(Observer, 'two req', '<Root><Request><Req><ReqId>1</ReqId></Req><Req><ReqId>2</ReqId></Req></Request></Root>');
        ImportOnceTemp(Observer, 'two resp', '<Root><Request/><Resp><RespId>5</RespId></Resp><Resp><RespId>6</RespId></Resp></Root>');
        ImportOnceTemp(Observer, 'two request elements', '<Root><Request/><Request/></Root>');
        Observer.Expect('two req ok', 'No');
        Observer.Expect('two req|text', 'Imported XML cannot validate with the schema: The element ''Request'' has invalid child element ''Req''.');
        Observer.Expect('two req|code', 'XmlPortInvalidXml');
        Observer.Expect('two req rows', 'req1:,');
        Observer.Expect('two req log', 'Req 1;');
        Observer.Expect('two resp ok', 'No');
        Observer.Expect('two resp|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Resp''.');
        Observer.Expect('two resp|code', 'XmlPortInvalidXml');
        Observer.Expect('two resp rows', 'resp5,');
        Observer.Expect('two resp log', 'Resp 5;');
        Observer.Expect('two request elements ok', 'No');
        Observer.Expect('two request elements|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Request''. List of possible elements expected: ''Resp''.');
        Observer.Expect('two request elements|code', 'XmlPortInvalidXml');
        Observer.Expect('two request elements rows', '');
        Observer.Expect('two request elements log', '');
        Observer.Verify();
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
        Observer.Expect('none ok', 'Yes');
        Observer.Expect('none|text', '');
        Observer.Expect('none|code', '');
        Observer.Expect('none xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <T>|    <Id>0</Id>|    <Note />|  </T>|</Root>|');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Note>n1</Note>|  </T>|</Root>|');
        Observer.Expect('two ok', 'Yes');
        Observer.Expect('two|text', '');
        Observer.Expect('two|code', '');
        Observer.Expect('two xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Note>n1</Note>|  </T>|</Root>|');
        Observer.Verify();
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
        Observer.Expect('none ok', 'No');
        Observer.Expect('none|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''T''.');
        Observer.Expect('none|code', 'XmlPortInvalidXml');
        Observer.Expect('none rows', '');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one rows', '1:a,');
        Observer.Expect('two ok', 'No');
        Observer.Expect('two|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''T''.');
        Observer.Expect('two|code', 'XmlPortInvalidXml');
        Observer.Expect('two rows', '');
        Observer.Verify();
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
        Observer.Expect('one row', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89364">|  <Row Note="x">|    <Id>3</Id>|  </Row>|</Root>|');
        Observer.Expect('no row', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89364" />|');
        Observer.Verify();
    end;

    [Test]
    procedure SG_DefaultNs_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportNs(Observer, 'with the namespace', '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89364"><Row Note="x"><Id>3</Id></Row></Root>');
        ImportNs(Observer, 'without a namespace', '<Root><Row Note="x"><Id>3</Id></Row></Root>');
        Observer.Expect('with the namespace ok', 'Yes');
        Observer.Expect('with the namespace|text', '');
        Observer.Expect('with the namespace|code', '');
        Observer.Expect('with the namespace rows', '3:x,');
        Observer.Expect('without a namespace ok', 'No');
        Observer.Expect('without a namespace|text', 'The element <Root> cannot be found in the object description.');
        Observer.Expect('without a namespace|code', 'XmlPortElementNotFound');
        Observer.Expect('without a namespace rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure SG_DefaultNs_Import_Other()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportNs(Observer, 'another namespace', '<Root xmlns="urn:other"><Row Note="x"><Id>3</Id></Row></Root>');
        ImportNs(Observer, 'namespace on the root only', '<ns:Root xmlns:ns="urn:microsoft-dynamics-nav/xmlports/x89364"><Row Note="x"><Id>3</Id></Row></ns:Root>');
        ImportNs(Observer, 'prefixed everywhere', '<ns:Root xmlns:ns="urn:microsoft-dynamics-nav/xmlports/x89364"><ns:Row Note="x"><ns:Id>3</ns:Id></ns:Row></ns:Root>');
        Observer.Expect('another namespace ok', 'No');
        Observer.Expect('another namespace|text', 'The element <Root> cannot be found in the object description.');
        Observer.Expect('another namespace|code', 'XmlPortElementNotFound');
        Observer.Expect('another namespace rows', '');
        Observer.Expect('namespace on the root only ok', 'No');
        Observer.Expect('namespace on the root only|text', 'Imported XML cannot validate with the schema: The element ''Root'' in namespace ''urn:microsoft-dynamics-nav/xmlports/x89364'' has invalid child element ''Row''. List of possible elements expected: ''Row'' in namespace ''urn:microsoft-dynamics-nav/xmlports/x89364''.');
        Observer.Expect('namespace on the root only|code', 'XmlPortInvalidXml');
        Observer.Expect('namespace on the root only rows', '');
        Observer.Expect('prefixed everywhere ok', 'Yes');
        Observer.Expect('prefixed everywhere|text', '');
        Observer.Expect('prefixed everywhere|code', '');
        Observer.Expect('prefixed everywhere rows', '3:x,');
        Observer.Verify();
    end;

    // ---- Writer TF: explicit MinOccurs = Once on a table element ----

    [TryFunction]
    local procedure TryExportMinOnce(var Port: XmlPort "LT TF XP Min Once"; var Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Xml := ReadAll(TempBlob);
    end;

    [TryFunction]
    local procedure TryExportMinMaxOnce(var Port: XmlPort "LT TF XP Min Max Once"; var Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Xml := ReadAll(TempBlob);
    end;

    [TryFunction]
    local procedure TryImportMinOnce(var Port: XmlPort "LT TF XP Min Once"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Content, TempBlob, InS);
        Port.SetSource(InS);
        Port.Import();
    end;

    [TryFunction]
    local procedure TryImportMinMaxOnce(var Port: XmlPort "LT TF XP Min Max Once"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Content, TempBlob, InS);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure ObserveMinOnceExport(var Observer: Codeunit "Probe Observer"; Name: Text; Rows: Integer)
    var
        Port: XmlPort "LT TF XP Min Once";
        Xml: Text;
        I: Integer;
    begin
        for I := 1 to Rows do
            Port.AddRow(I, 'n' + Format(I));
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryExportMinOnce(Port, Xml)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' xml', Xml);
    end;

    local procedure ObserveMinMaxOnceExport(var Observer: Codeunit "Probe Observer"; Name: Text; Rows: Integer)
    var
        Port: XmlPort "LT TF XP Min Max Once";
        Xml: Text;
        I: Integer;
    begin
        for I := 1 to Rows do
            Port.AddRow(I, 'n' + Format(I));
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryExportMinMaxOnce(Port, Xml)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' xml', Xml);
    end;

    local procedure ObserveMinOnceImport(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        Port: XmlPort "LT TF XP Min Once";
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportMinOnce(Port, Content)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Port.Rows());
        Observer.Observe(Name + ' log', Port.GetLog());
    end;

    local procedure ObserveMinMaxOnceImport(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        Port: XmlPort "LT TF XP Min Max Once";
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportMinMaxOnce(Port, Content)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Port.Rows());
        Observer.Observe(Name + ' log', Port.GetLog());
    end;

    [Test]
    procedure TF_MinOnce_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMinOnceExport(Observer, 'none', 0);
        ObserveMinOnceExport(Observer, 'one', 1);
        ObserveMinOnceExport(Observer, 'two', 2);
        Observer.Expect('none ok', 'Yes');
        Observer.Expect('none|text', '');
        Observer.Expect('none|code', '');
        Observer.Expect('none xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row>|    <Id>0</Id>|    <Note />|  </Row>|</Root>|');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Note>n1</Note>|  </Row>|</Root>|');
        Observer.Expect('two ok', 'Yes');
        Observer.Expect('two|text', '');
        Observer.Expect('two|code', '');
        Observer.Expect('two xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Note>n1</Note>|  </Row>|  <Row>|    <Id>2</Id>|    <Note>n2</Note>|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure TF_MinOnce_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMinOnceImport(Observer, 'zero', '<Root/>');
        ObserveMinOnceImport(Observer, 'one', '<Root><Row><Id>1</Id><Note>a</Note></Row></Root>');
        ObserveMinOnceImport(Observer, 'two', '<Root><Row><Id>1</Id><Note>a</Note></Row><Row><Id>2</Id><Note>b</Note></Row></Root>');
        ObserveMinOnceImport(Observer, 'three', '<Root><Row><Id>1</Id></Row><Row><Id>2</Id></Row><Row><Id>3</Id></Row></Root>');
        Observer.Expect('zero ok', 'No');
        Observer.Expect('zero|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Row''.');
        Observer.Expect('zero|code', 'XmlPortInvalidXml');
        Observer.Expect('zero rows', '');
        Observer.Expect('zero log', '');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one rows', '1:a,');
        Observer.Expect('one log', 'Insert 1;');
        Observer.Expect('two ok', 'Yes');
        Observer.Expect('two|text', '');
        Observer.Expect('two|code', '');
        Observer.Expect('two rows', '1:a,2:b,');
        Observer.Expect('two log', 'Insert 1;Insert 2;');
        Observer.Expect('three ok', 'Yes');
        Observer.Expect('three|text', '');
        Observer.Expect('three|code', '');
        Observer.Expect('three rows', '1:,2:,3:,');
        Observer.Expect('three log', 'Insert 1;Insert 2;Insert 3;');
        Observer.Verify();
    end;

    [Test]
    procedure TF_MinMaxOnce_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMinMaxOnceExport(Observer, 'none', 0);
        ObserveMinMaxOnceExport(Observer, 'one', 1);
        ObserveMinMaxOnceExport(Observer, 'two', 2);
        Observer.Expect('none ok', 'Yes');
        Observer.Expect('none|text', '');
        Observer.Expect('none|code', '');
        Observer.Expect('none xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row>|    <Id>0</Id>|    <Note />|  </Row>|</Root>|');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Note>n1</Note>|  </Row>|</Root>|');
        Observer.Expect('two ok', 'Yes');
        Observer.Expect('two|text', '');
        Observer.Expect('two|code', '');
        Observer.Expect('two xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Row>|    <Id>1</Id>|    <Note>n1</Note>|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure TF_MinMaxOnce_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMinMaxOnceImport(Observer, 'zero', '<Root/>');
        ObserveMinMaxOnceImport(Observer, 'one', '<Root><Row><Id>1</Id><Note>a</Note></Row></Root>');
        ObserveMinMaxOnceImport(Observer, 'two', '<Root><Row><Id>1</Id><Note>a</Note></Row><Row><Id>2</Id><Note>b</Note></Row></Root>');
        Observer.Expect('zero ok', 'No');
        Observer.Expect('zero|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Row''.');
        Observer.Expect('zero|code', 'XmlPortInvalidXml');
        Observer.Expect('zero rows', '');
        Observer.Expect('zero log', '');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one rows', '1:a,');
        Observer.Expect('one log', 'Insert 1;');
        Observer.Expect('two ok', 'No');
        Observer.Expect('two|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Row''.');
        Observer.Expect('two|code', 'XmlPortInvalidXml');
        Observer.Expect('two rows', '1:a,');
        Observer.Expect('two log', 'Insert 1;');
        Observer.Verify();
    end;

    [Test]
    procedure TF_MinMaxOnceReal_Export()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
    begin
        ResetRealRows(Ids);
        ObserveExportRealTf(Observer, 'none');
        Ids.Add(1);
        ResetRealRows(Ids);
        ObserveExportRealTf(Observer, 'one');
        Ids.Add(2);
        ResetRealRows(Ids);
        ObserveExportRealTf(Observer, 'two');
        Clear(Ids);
        ResetRealRows(Ids);
        Observer.Expect('none ok', 'Yes');
        Observer.Expect('none|text', '');
        Observer.Expect('none|code', '');
        Observer.Expect('none xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <T>|    <Id>0</Id>|    <Note />|  </T>|</Root>|');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Note>n1</Note>|  </T>|</Root>|');
        Observer.Expect('two ok', 'Yes');
        Observer.Expect('two|text', '');
        Observer.Expect('two|code', '');
        Observer.Expect('two xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Note>n1</Note>|  </T>|</Root>|');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryExportRealTf(var Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT TF XP Min Max Once Real", OutS);
        Xml := ReadAll(TempBlob);
    end;

    local procedure ObserveExportRealTf(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Xml: Text;
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryExportRealTf(Xml)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' xml', Xml);
    end;

    [Test]
    procedure TF_MinMaxOnceReal_Import()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
    begin
        ImportRealTf(Observer, 'none', '<Root/>');
        ImportRealTf(Observer, 'one', '<Root><T><Id>1</Id><Note>a</Note></T></Root>');
        ImportRealTf(Observer, 'two', '<Root><T><Id>1</Id><Note>a</Note></T><T><Id>2</Id><Note>b</Note></T></Root>');
        ResetRealRows(Ids);
        Observer.Expect('none ok', 'No');
        Observer.Expect('none|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''T''.');
        Observer.Expect('none|code', 'XmlPortInvalidXml');
        Observer.Expect('none rows', '');
        Observer.Expect('one ok', 'Yes');
        Observer.Expect('one|text', '');
        Observer.Expect('one|code', '');
        Observer.Expect('one rows', '1:a,');
        Observer.Expect('two ok', 'No');
        Observer.Expect('two|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''T''.');
        Observer.Expect('two|code', 'XmlPortInvalidXml');
        Observer.Expect('two rows', '');
        Observer.Verify();
    end;

    local procedure ImportRealTf(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Empty: List of [Integer];
    begin
        ResetRealRows(Empty);
        Source(Content, TempBlob, InS);
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(Xmlport.Import(Xmlport::"LT TF XP Min Max Once Real", InS)));
        Observer.ObserveError(Name);
        Commit();
        Observer.Observe(Name + ' rows', RealRows());
    end;

    // ---- Writer TF: UseDefaultNamespace = true with text attributes ----

    [Test]
    procedure TF_NsAttr_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TF XP Ns Attr";
        Empty: XmlPort "LT TF XP Ns Attr";
        TempBlob: Codeunit "Temp Blob";
        EmptyBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Port.AddRow(3, 9, 'x');
        Port.AddRow(4, 0, '');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('two rows', ReadAll(TempBlob));
        EmptyBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Empty.SetDestination(OutS);
        Empty.Export();
        Observer.Observe('no row', ReadAll(EmptyBlob));
        Observer.Expect('two rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root Ver="v1" xmlns="urn:microsoft-dynamics-nav/xmlports/x89838">|  <Row Id="3" Note="x">|    <Item Kind="k3" EntryNo="9" />|  </Row>|  <Row Id="4">|    <Item Kind="k4" EntryNo="0" />|  </Row>|</Root>|');
        Observer.Expect('no row', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root Ver="v1" xmlns="urn:microsoft-dynamics-nav/xmlports/x89838" />|');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryImportNsAttr(var Port: XmlPort "LT TF XP Ns Attr"; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Source(Content, TempBlob, InS);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure ImportNsAttr(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        Port: XmlPort "LT TF XP Ns Attr";
    begin
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportNsAttr(Port, Content)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' rows', Port.Rows());
        Observer.Observe(Name + ' log', Port.GetLog());
    end;

    [Test]
    procedure TF_NsAttr_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportNsAttr(Observer, 'plain attributes', '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89838" Ver="v9"><Row Id="3" Note="x"><Item Kind="a" EntryNo="9"/></Row></Root>');
        ImportNsAttr(Observer, 'optional missing', '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89838"><Row Id="3"><Item Kind="a"/></Row></Root>');
        ImportNsAttr(Observer, 'required field attribute missing', '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89838"><Row><Item Kind="a"/></Row></Root>');
        ImportNsAttr(Observer, 'required text attribute missing', '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89838"><Row Id="3"><Item/></Row></Root>');
        Observer.Expect('plain attributes ok', 'Yes');
        Observer.Expect('plain attributes|text', '');
        Observer.Expect('plain attributes|code', '');
        Observer.Expect('plain attributes rows', '3:9:x,');
        Observer.Expect('plain attributes log', 'Ver=v9;Kind=a;Insert 3:9:x;');
        Observer.Expect('optional missing ok', 'Yes');
        Observer.Expect('optional missing|text', '');
        Observer.Expect('optional missing|code', '');
        Observer.Expect('optional missing rows', '3:0:,');
        Observer.Expect('optional missing log', 'Kind=a;Insert 3:0:;');
        Observer.Expect('required field attribute missing ok', 'No');
        Observer.Expect('required field attribute missing|text', 'Imported XML cannot validate with the schema: The required attribute ''Id'' is missing.');
        Observer.Expect('required field attribute missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required field attribute missing rows', '');
        Observer.Expect('required field attribute missing log', '');
        Observer.Expect('required text attribute missing ok', 'No');
        Observer.Expect('required text attribute missing|text', 'Imported XML cannot validate with the schema: The required attribute ''Kind'' is missing.');
        Observer.Expect('required text attribute missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required text attribute missing rows', '');
        Observer.Expect('required text attribute missing log', '');
        Observer.Verify();
    end;

    [Test]
    procedure TF_NsAttr_Import_Qualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportNsAttr(Observer, 'prefixed attributes', '<n:Root xmlns:n="urn:microsoft-dynamics-nav/xmlports/x89838" n:Ver="v9"><n:Row n:Id="3" n:Note="x"><n:Item n:Kind="a" n:EntryNo="9"/></n:Row></n:Root>');
        ImportNsAttr(Observer, 'prefixed elements, plain attributes', '<n:Root xmlns:n="urn:microsoft-dynamics-nav/xmlports/x89838" Ver="v9"><n:Row Id="3" Note="x"><n:Item Kind="a" EntryNo="9"/></n:Row></n:Root>');
        ImportNsAttr(Observer, 'no namespace', '<Root Ver="v9"><Row Id="3" Note="x"><Item Kind="a" EntryNo="9"/></Row></Root>');
        ImportNsAttr(Observer, 'other namespace', '<Root xmlns="urn:other" Ver="v9"><Row Id="3" Note="x"><Item Kind="a" EntryNo="9"/></Row></Root>');
        Observer.Expect('prefixed attributes ok', 'No');
        Observer.Expect('prefixed attributes|text', 'Imported XML cannot validate with the schema: The ''urn:microsoft-dynamics-nav/xmlports/x89838:Ver'' attribute is not declared.');
        Observer.Expect('prefixed attributes|code', 'XmlPortInvalidXml');
        Observer.Expect('prefixed attributes rows', '');
        Observer.Expect('prefixed attributes log', '');
        Observer.Expect('prefixed elements, plain attributes ok', 'Yes');
        Observer.Expect('prefixed elements, plain attributes|text', '');
        Observer.Expect('prefixed elements, plain attributes|code', '');
        Observer.Expect('prefixed elements, plain attributes rows', '3:9:x,');
        Observer.Expect('prefixed elements, plain attributes log', 'Ver=v9;Kind=a;Insert 3:9:x;');
        Observer.Expect('no namespace ok', 'No');
        Observer.Expect('no namespace|text', 'The element <Root> cannot be found in the object description.');
        Observer.Expect('no namespace|code', 'XmlPortElementNotFound');
        Observer.Expect('no namespace rows', '');
        Observer.Expect('no namespace log', '');
        Observer.Expect('other namespace ok', 'No');
        Observer.Expect('other namespace|text', 'The element <Root> cannot be found in the object description.');
        Observer.Expect('other namespace|code', 'XmlPortElementNotFound');
        Observer.Expect('other namespace rows', '');
        Observer.Expect('other namespace log', '');
        Observer.Verify();
    end;
}
