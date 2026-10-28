// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 87275, 87276, 87279, xmlport 87277, runner codeunit 87278, test codeunit 87280 (writer QR); writer QS: tests QS_TextAttr_* on table 87360, xmlport 87361, runner 87362 (QsXpTextAttrObjects.al)
// Writer TO: tests TO_* on table 90000, xmlports 90001-90003, runner 90004 (ToXpTextInTableObjects.al): a text element below a table element, with only text attributes or with content.
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: MaxOccurs and MinOccurs on CONTAINER text elements (the root text element with MaxOccurs = Once, a required container with
//   MinOccurs = Once and MaxOccurs = Once that holds a temporary table element, an optional container with MinOccurs = Zero and
//   MaxOccurs = Once inside each table row that holds a linked temporary table element, an optional leaf text element): Export with zero,
//   one and many rows (the XML text, lines joined by |), Import with each container absent, present once and present twice (the rows the
//   import made, or the error text and code; the import runs inside Codeunit.Run so a failed import does not end the test).
//   BC (27.5, 28.5, 29.0 alike): Export writes every container once, also when empty (<request />, <lines />, <status />). Import takes the
//   containers absent or once as their MinOccurs allows; a missing required container or a second one fails the schema check with
//   'Imported XML cannot validate with the schema: ...' / XmlPortInvalidXml before any row is made.
// BC versions: 27, 28, 29

table 87275 "LT QR XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 87276 "LT QR XP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}

table 87279 "LT QR XP Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 87277 "LT QR XP Containers"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(envelope)
        {
            MaxOccurs = Once;
            textelement(request)
            {
                MinOccurs = Once;
                MaxOccurs = Once;
                tableelement(head; "LT QR XP Head")
                {
                    UseTemporary = true;
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    fieldattribute(no; head."No.") { }
                    fieldelement(name; head.Name)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                    }
                    textelement(lines)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                        tableelement(line; "LT QR XP Line")
                        {
                            UseTemporary = true;
                            MinOccurs = Zero;
                            MaxOccurs = Unbounded;
                            LinkTable = head;
                            LinkFields = "Head No." = field("No.");
                            fieldattribute(n; line."Line No.") { }
                            fieldelement(qty; line.Qty) { }
                        }
                    }
                }
            }
            textelement(status)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;

                trigger OnBeforePassVariable()
                begin
                    status := StatusText;
                end;

                trigger OnAfterAssignVariable()
                begin
                    StatusText := status;
                end;
            }
        }
    }

    var
        StatusText: Text;

    procedure SetStatus(NewStatus: Text)
    begin
        StatusText := NewStatus;
    end;

    procedure GetStatus(): Text
    begin
        exit(StatusText);
    end;

    procedure AddHead(No: Code[10]; NewName: Text[30])
    begin
        head.Init();
        head."No." := No;
        head.Name := NewName;
        head.Insert();
    end;

    procedure AddLine(HeadNo: Code[10]; LineNo: Integer; NewQty: Integer)
    begin
        line.Init();
        line."Head No." := HeadNo;
        line."Line No." := LineNo;
        line.Qty := NewQty;
        line.Insert();
    end;

    procedure HeadRows() Result: Text
    begin
        head.Reset();
        if head.FindSet() then
            repeat
                Result += head."No." + ':' + head.Name + ';';
            until head.Next() = 0;
    end;

    procedure LineRows() Result: Text
    begin
        line.Reset();
        if line.FindSet() then
            repeat
                Result += line."Head No." + '/' + Format(line."Line No.") + '=' + Format(line.Qty) + ';';
            until line.Next() = 0;
    end;
}

codeunit 87278 "LT QR XP Runner"
{
    var
        Input: Text;
        HeadRows: Text;
        LineRows: Text;
        Status: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Port: XmlPort "LT QR XP Containers";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
        HeadRows := Port.HeadRows();
        LineRows := Port.LineRows();
        Status := Port.GetStatus();
    end;

    procedure SetInput(NewInput: Text)
    begin
        Input := NewInput;
        HeadRows := '';
        LineRows := '';
        Status := '';
    end;

    procedure Result(): Text
    begin
        exit('heads=' + HeadRows + ' lines=' + LineRows + ' status=' + Status);
    end;
}

codeunit 87280 "LT QR XP Container Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Exported(var Port: XmlPort "LT QR XP Containers"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        Runner: Codeunit "LT QR XP Runner";
    begin
        Runner.SetInput('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure QR_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request />|  <status />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_NoRows_Status()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.SetStatus('ok');
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request />|  <status>ok</status>|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_OneHead_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.AddHead('H1', 'one');
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request>|    <head no="H1">|      <name>one</name>|      <lines />|    </head>|  </request>|  <status />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_OneHead_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.AddHead('H1', 'one');
        Port.AddLine('H1', 10, 5);
        Port.AddLine('H1', 20, 7);
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request>|    <head no="H1">|      <name>one</name>|      <lines>|        <line n="10">|          <qty>5</qty>|        </line>|        <line n="20">|          <qty>7</qty>|        </line>|      </lines>|    </head>|  </request>|  <status />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Export_TwoHeads_LinesOnSecond()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QR XP Containers";
    begin
        Port.AddHead('H1', '');
        Port.AddHead('H2', 'two');
        Port.AddLine('H2', 10, 1);
        Port.AddLine('H9', 10, 9);
        Port.SetStatus('done');
        Observer.Observe('xml', Exported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope>|  <request>|    <head no="H1">|      <name />|      <lines />|    </head>|    <head no="H2">|      <name>two</name>|      <lines>|        <line n="10">|          <qty>1</qty>|        </line>|      </lines>|    </head>|  </request>|  <status>done</status>|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_Present()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'empty request', '<envelope><request/></envelope>');
        Import(Observer, 'empty request with status', '<envelope><request></request><status>s</status></envelope>');
        Import(Observer, 'one head no lines', '<envelope><request><head no="H1"><name>one</name></head></request></envelope>');
        Import(Observer, 'one head no name', '<envelope><request><head no="H1"/></request></envelope>');
        Import(Observer, 'one head empty lines', '<envelope><request><head no="H1"><lines/></head></request></envelope>');
        Import(Observer, 'two heads with lines', '<envelope><request><head no="H1"><name>one</name><lines><line n="10"><qty>5</qty></line><line n="20"><qty>7</qty></line></lines></head><head no="H2"><lines><line n="10"><qty>1</qty></line></lines></head></request></envelope>');
        Observer.Expect('empty request', 'ok heads= lines= status=');
        Observer.Expect('empty request with status', 'ok heads= lines= status=s');
        Observer.Expect('one head no lines', 'ok heads=H1:one; lines= status=');
        Observer.Expect('one head no name', 'ok heads=H1:; lines= status=');
        Observer.Expect('one head empty lines', 'ok heads=H1:; lines= status=');
        Observer.Expect('two heads with lines', 'ok heads=H1:one;H2:; lines=H1/10=5;H1/20=7;H2/10=1; status=');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_MissingOrTwoRequests()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'no request', '<envelope></envelope>');
        Import(Observer, 'no request but status', '<envelope><status>s</status></envelope>');
        Import(Observer, 'two requests', '<envelope><request/><request/></envelope>');
        Observer.Expect('no request|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has incomplete content. List of possible elements expected: ''request''.');
        Observer.Expect('no request|code', 'XmlPortInvalidXml');
        Observer.Expect('no request but status|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''status''. List of possible elements expected: ''request''.');
        Observer.Expect('no request but status|code', 'XmlPortInvalidXml');
        Observer.Expect('two requests|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''request''. List of possible elements expected: ''status''.');
        Observer.Expect('two requests|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_Repeated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'two lines containers', '<envelope><request><head no="H1"><lines/><lines/></head></request></envelope>');
        Import(Observer, 'two names', '<envelope><request><head no="H1"><name>a</name><name>b</name></head></request></envelope>');
        Import(Observer, 'two statuses', '<envelope><request/><status>a</status><status>b</status></envelope>');
        Observer.Expect('two lines containers|text', 'Imported XML cannot validate with the schema: The element ''head'' has invalid child element ''lines''.');
        Observer.Expect('two lines containers|code', 'XmlPortInvalidXml');
        Observer.Expect('two names|text', 'Imported XML cannot validate with the schema: The element ''head'' has invalid child element ''name''. List of possible elements expected: ''lines''.');
        Observer.Expect('two names|code', 'XmlPortInvalidXml');
        Observer.Expect('two statuses|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''status''.');
        Observer.Expect('two statuses|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_WrongRootOrOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'other root', '<other><request/></other>');
        Import(Observer, 'status before request', '<envelope><status>s</status><request/></envelope>');
        Import(Observer, 'lines before name', '<envelope><request><head no="H1"><lines/><name>a</name></head></request></envelope>');
        Observer.Expect('other root|text', 'Imported XML cannot validate with the schema: The ''other'' element is not declared.');
        Observer.Expect('other root|code', 'XmlPortInvalidXml');
        Observer.Expect('status before request|text', 'Imported XML cannot validate with the schema: The element ''envelope'' has invalid child element ''status''. List of possible elements expected: ''request''.');
        Observer.Expect('status before request|code', 'XmlPortInvalidXml');
        Observer.Expect('lines before name|text', 'Imported XML cannot validate with the schema: The element ''head'' has invalid child element ''name''.');
        Observer.Expect('lines before name|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Import_UnknownChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'unknown child', '<envelope><request><extra/></request></envelope>');
        Observer.Expect('unknown child|text', 'Imported XML cannot validate with the schema: The element ''request'' has invalid child element ''extra''. List of possible elements expected: ''head''.');
        Observer.Expect('unknown child|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    local procedure QsExported(var Port: XmlPort "LT QS XP Text Attributes"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    local procedure QsImport(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        Runner: Codeunit "LT QS XP Attr Runner";
    begin
        Runner.SetInput('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure QS_TextAttr_Export_AllEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QS XP Text Attributes";
    begin
        Observer.Observe('xml', QsExported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope version="">|  <body />|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QS_TextAttr_Export_AllSet()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QS XP Text Attributes";
    begin
        Port.SetValues('inst-1', '2', 'tok');
        Port.AddRow('R1', 'ref-1', 'must-1');
        Observer.Observe('xml', QsExported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope cache_instance_id="inst-1" version="2">|  <body token="tok">|    <row no="R1" ref="ref-1" must="must-1" />|  </body>|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QS_TextAttr_Export_OptionalSetRequiredEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT QS XP Text Attributes";
    begin
        Port.SetValues('inst-1', '', '');
        Port.AddRow('R1', '', '');
        Port.AddRow('R2', 'ref-2', '');
        Observer.Observe('xml', QsExported(Port));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<envelope cache_instance_id="inst-1" version="">|  <body>|    <row no="R1" must="" />|    <row no="R2" ref="ref-2" must="" />|  </body>|</envelope>|');
        Observer.Verify();
    end;

    [Test]
    procedure QS_TextAttr_Import_Root()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QsImport(Observer, 'both present', '<envelope cache_instance_id="i1" version="2"/>');
        QsImport(Observer, 'optional missing', '<envelope version="2"/>');
        QsImport(Observer, 'required missing', '<envelope cache_instance_id="i1"/>');
        QsImport(Observer, 'both missing', '<envelope/>');
        QsImport(Observer, 'required empty', '<envelope version=""/>');
        QsImport(Observer, 'optional empty', '<envelope cache_instance_id="" version="2"/>');
        QsImport(Observer, 'unknown attribute', '<envelope version="2" other="x"/>');
        Observer.Expect('both present', 'ok log=instance=i1;version=2; values: instance=i1 version=2 token= ref= must= rows=');
        Observer.Expect('optional missing', 'ok log=version=2; values: instance= version=2 token= ref= must= rows=');
        Observer.Expect('required missing|text', 'Imported XML cannot validate with the schema: The required attribute ''version'' is missing.');
        Observer.Expect('required missing|code', 'XmlPortInvalidXml');
        Observer.Expect('both missing|text', 'Imported XML cannot validate with the schema: The required attribute ''version'' is missing.');
        Observer.Expect('both missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required empty', 'ok log=version=; values: instance= version= token= ref= must= rows=');
        Observer.Expect('optional empty', 'ok log=instance=;version=2; values: instance= version=2 token= ref= must= rows=');
        Observer.Expect('unknown attribute|text', 'Imported XML cannot validate with the schema: The ''other'' attribute is not declared.');
        Observer.Expect('unknown attribute|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure QS_TextAttr_Import_Container()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QsImport(Observer, 'token present', '<envelope version="2"><body token="t1"/></envelope>');
        QsImport(Observer, 'token missing', '<envelope version="2"><body/></envelope>');
        QsImport(Observer, 'body missing', '<envelope version="2"></envelope>');
        Observer.Expect('token present', 'ok log=version=2;token=t1; values: instance= version=2 token=t1 ref= must= rows=');
        Observer.Expect('token missing', 'ok log=version=2; values: instance= version=2 token= ref= must= rows=');
        Observer.Expect('body missing', 'ok log=version=2; values: instance= version=2 token= ref= must= rows=');
        Observer.Verify();
    end;

    [Test]
    procedure QS_TextAttr_Import_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QsImport(Observer, 'rows both present', '<envelope version="2"><body><row no="R1" ref="a" must="m1"/><row no="R2" ref="b" must="m2"/></body></envelope>');
        QsImport(Observer, 'optional on first row only', '<envelope version="2"><body><row no="R1" ref="a" must="m1"/><row no="R2" must="m2"/></body></envelope>');
        QsImport(Observer, 'optional on second row only', '<envelope version="2"><body><row no="R1" must="m1"/><row no="R2" ref="b" must="m2"/></body></envelope>');
        QsImport(Observer, 'required missing on second row', '<envelope version="2"><body><row no="R1" must="m1"/><row no="R2"/></body></envelope>');
        QsImport(Observer, 'required empty', '<envelope version="2"><body><row no="R1" must=""/></body></envelope>');
        Observer.Expect('rows both present', 'ok log=version=2;row R1 ref=a must=m1;row R2 ref=b must=m2; values: instance= version=2 token= ref=b must=m2 rows=R1:a/m1;R2:b/m2;');
        Observer.Expect('optional on first row only', 'ok log=version=2;row R1 ref=a must=m1;row R2 ref=a must=m2; values: instance= version=2 token= ref=a must=m2 rows=R1:a/m1;R2:a/m2;');
        Observer.Expect('optional on second row only', 'ok log=version=2;row R1 ref= must=m1;row R2 ref=b must=m2; values: instance= version=2 token= ref=b must=m2 rows=R1:/m1;R2:b/m2;');
        Observer.Expect('required missing on second row|text', 'Imported XML cannot validate with the schema: The required attribute ''must'' is missing.');
        Observer.Expect('required missing on second row|code', 'XmlPortInvalidXml');
        Observer.Expect('required empty', 'ok log=version=2;row R1 ref= must=; values: instance= version=2 token= ref= must= rows=R1:/;');
        Observer.Verify();
    end;

    local procedure ToRead(var Buffer: Record "LT QR XP Blob" temporary): Text
    var
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    local procedure ToExportTrigger(var Port: XmlPort "LT TO XP Attr Item Trigger"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure ToExportPlain(var Port: XmlPort "LT TO XP Attr Item Plain"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure ToExportContent(var Port: XmlPort "LT TO XP Text Content"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure ToImport(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; Body: Text)
    var
        Runner: Codeunit "LT TO XP Runner";
    begin
        Runner.SetInput(Mode, '<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure TO_AttrItem_Trigger_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TO XP Attr Item Trigger";
    begin
        // The text element's OnBeforePassVariable sets its text, its text attribute's OnBeforePassVariable sets the attribute.
        Port.AddRow('R1', 'REQUIRED', '1');
        Port.AddRow('R2', '', '2');
        Port.AddRow('R3', 'TXT', '');
        Observer.Observe('xml', ToExportTrigger(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row no="R1">|    <item option_value="1">REQUIRED</item>|  </row>|  <row no="R2">|    <item option_value="2" />|  </row>|  <row no="R3">|    <item option_value="">TXT</item>|  </row>|</root>|');
        Observer.Expect('log', 'get R1;pass item;pass attr;get R2;pass item;pass attr;get R3;pass item;pass attr;');
        Observer.Verify();
    end;

    [Test]
    procedure TO_AttrItem_Trigger_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TO XP Attr Item Trigger";
    begin
        Observer.Observe('xml', ToExportTrigger(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root />|');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure TO_AttrItem_Plain_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TO XP Attr Item Plain";
        Empty: XmlPort "LT TO XP Attr Item Plain";
    begin
        // No trigger: the element and the attribute write their variables as they are.
        Port.SetVariables('TEXT', '1');
        Port.AddRow('R1');
        Port.AddRow('R2');
        Observer.Observe('set', ToExportPlain(Port));
        Empty.AddRow('R1');
        Observer.Observe('empty', ToExportPlain(Empty));
        Observer.Expect('set', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row no="R1">|    <item option_value="1">TEXT</item>|  </row>|  <row no="R2">|    <item option_value="1">TEXT</item>|  </row>|</root>|');
        Observer.Expect('empty', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row no="R1">|    <item option_value="" />|  </row>|</root>|');
        Observer.Verify();
    end;

    [Test]
    procedure TO_AttrItem_Trigger_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ToImport(Observer, 'two rows', 90001, '<root><row no="R1"><item option_value="1">REQ</item></row><row no="R2"><item option_value="2">X</item></row></root>');
        ToImport(Observer, 'attribute missing', 90001, '<root><row no="R1"><item>REQ</item></row></root>');
        ToImport(Observer, 'empty element', 90001, '<root><row no="R1"><item option_value="1"/></row></root>');
        Observer.Expect('two rows', 'ok log=init;no=R1;attr=1;item=REQ;before insert R1 item=REQ attr=1;after insert;init;no=R2;attr=2;item=X;before insert R2 item=X attr=2;after insert; values: item=X attr=2 rows=R1:REQ/1;R2:X/2;');
        Observer.Expect('attribute missing|text', 'Imported XML cannot validate with the schema: The required attribute ''option_value'' is missing.');
        Observer.Expect('attribute missing|code', 'XmlPortInvalidXml');
        Observer.Expect('empty element', 'ok log=init;no=R1;attr=1;item=;before insert R1 item= attr=1;after insert; values: item= attr=1 rows=R1:/1;');
        Observer.Verify();
    end;

    [Test]
    procedure TO_AttrItem_Trigger_Import_Missing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ToImport(Observer, 'element missing', 90001, '<root><row no="R1"/></root>');
        ToImport(Observer, 'second row attribute missing', 90001, '<root><row no="R1"><item option_value="1">A</item></row><row no="R2"><item>B</item></row></root>');
        ToImport(Observer, 'child element', 90001, '<root><row no="R1"><item option_value="1">A<x/></item></row></root>');
        Observer.Expect('element missing|text', 'Imported XML cannot validate with the schema: The element ''row'' has incomplete content. List of possible elements expected: ''item''.');
        Observer.Expect('element missing|code', 'XmlPortInvalidXml');
        Observer.Expect('second row attribute missing|text', 'Imported XML cannot validate with the schema: The required attribute ''option_value'' is missing.');
        Observer.Expect('second row attribute missing|code', 'XmlPortInvalidXml');
        Observer.Expect('child element|text', 'Imported XML cannot validate with the schema: The element ''item'' cannot contain child element ''x'' because the parent element''s content model is text only.');
        Observer.Expect('child element|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure TO_AttrItem_Plain_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ToImport(Observer, 'two rows', 90002, '<root><row no="R1"><item option_value="1">REQ</item></row><row no="R2"><item option_value="2">X</item></row></root>');
        ToImport(Observer, 'second row bare', 90002, '<root><row no="R1"><item option_value="1">REQ</item></row><row no="R2"><item/></row></root>');
        Observer.Expect('two rows', 'ok log=before insert R1 item=REQ attr=1;before insert R2 item=X attr=2; values: item=X attr=2 rows=R1:REQ/1;R2:X/2;');
        Observer.Expect('second row bare|text', 'Imported XML cannot validate with the schema: The required attribute ''option_value'' is missing.');
        Observer.Expect('second row bare|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure TO_TextContent_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TO XP Text Content";
    begin
        Port.AddRow('R1', 'N1', 'k1', 's1');
        Port.AddRow('R2', '', '', '');
        Observer.Observe('xml', ToExportContent(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row no="R1">|    <info kind="k1">|      <name>N1</name>|      <sub>s1</sub>|    </info>|  </row>|  <row no="R2">|    <info kind="">|      <name />|      <sub />|    </info>|  </row>|</root>|');
        Observer.Expect('log', 'get R1;pass info;pass kind;pass name;pass sub;get R2;pass info;pass kind;pass name;pass sub;');
        Observer.Verify();
    end;

    [Test]
    procedure TO_TextContent_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ToImport(Observer, 'two rows', 90003, '<root><row no="R1"><info kind="k1"><name>N1</name><sub>s1</sub></info></row><row no="R2"><info kind="k2"><name>N2</name><sub>s2</sub></info></row></root>');
        ToImport(Observer, 'no kind', 90003, '<root><row no="R1"><info><name>N1</name><sub>s1</sub></info></row></root>');
        Observer.Expect('two rows', 'ok log=init;no=R1;kind=k1;name=N1;sub=s1;info=;before insert R1 name=N1 kind=k1 sub=s1;after insert;init;no=R2;kind=k2;name=N2;sub=s2;info=;before insert R2 name=N2 kind=k2 sub=s2;after insert; values: info= kind=k2 sub=s2 rows=R1:N1/k1/s1;R2:N2/k2/s2;');
        Observer.Expect('no kind|text', 'Imported XML cannot validate with the schema: The required attribute ''kind'' is missing.');
        Observer.Expect('no kind|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure TO_TextContent_Import_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ToImport(Observer, 'info missing', 90003, '<root><row no="R1"/></root>');
        ToImport(Observer, 'sub missing', 90003, '<root><row no="R1"><info kind="k1"><name>N1</name></info></row></root>');
        ToImport(Observer, 'empty info', 90003, '<root><row no="R1"><info/></row></root>');
        ToImport(Observer, 'text in info', 90003, '<root><row no="R1"><info kind="k1">T<name>N1</name><sub>s1</sub></info></row></root>');
        Observer.Expect('info missing|text', 'Imported XML cannot validate with the schema: The element ''row'' has incomplete content. List of possible elements expected: ''info''.');
        Observer.Expect('info missing|code', 'XmlPortInvalidXml');
        Observer.Expect('sub missing|text', 'Imported XML cannot validate with the schema: The element ''info'' has incomplete content. List of possible elements expected: ''sub''.');
        Observer.Expect('sub missing|code', 'XmlPortInvalidXml');
        Observer.Expect('empty info|text', 'Imported XML cannot validate with the schema: The required attribute ''kind'' is missing.');
        Observer.Expect('empty info|code', 'XmlPortInvalidXml');
        Observer.Expect('text in info', 'ok log=init;no=R1;kind=k1;name=N1;sub=s1;info=T;before insert R1 name=N1 kind=k1 sub=s1;after insert; values: info=T kind=k1 sub=s1 rows=R1:N1/k1/s1;');
        Observer.Verify();
    end;

    local procedure TpExportNested(var Port: XmlPort "LT TP XP Nested Text"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure TpExportUnlinked(var Port: XmlPort "LT TP XP Unlinked Temp"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure TpImport(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; Body: Text)
    var
        Runner: Codeunit "LT TP XP Runner";
    begin
        Runner.SetInput(Mode, '<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure TP_Nested_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TP XP Nested Text";
    begin
        // table element > text element (field attribute, text attributes) > text element with one text attribute.
        Port.AddRow('R1', 'open', 'k1', 'A1', '1');
        Port.AddRow('R2', '', '', '', '2');
        Port.AddRow('R3', 'closed', 'k3', 'X', '');
        Observer.Observe('xml', TpExportNested(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TP_Nested_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TP XP Nested Text";
    begin
        Observer.Observe('xml', TpExportNested(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TP_Nested_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpImport(Observer, 'two rows', 90022, '<root><row><entry no="R1" status="open" kind="k1"><admission option_value="1">A1</admission></entry></row><row><entry no="R2" status="closed" kind="k2"><admission option_value="2">A2</admission></entry></row></root>');
        TpImport(Observer, 'empty admission', 90022, '<root><row><entry no="R1" status="open" kind="k1"><admission option_value="1"/></entry></row></root>');
        TpImport(Observer, 'no kind', 90022, '<root><row><entry no="R1" status="open"><admission option_value="1">A1</admission></entry></row></root>');
        Observer.Finish();
    end;

    [Test]
    procedure TP_Nested_Import_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpImport(Observer, 'admission missing', 90022, '<root><row><entry no="R1" status="open" kind="k1"/></row></root>');
        TpImport(Observer, 'option_value missing', 90022, '<root><row><entry no="R1" status="open" kind="k1"><admission>A1</admission></entry></row></root>');
        TpImport(Observer, 'status missing', 90022, '<root><row><entry no="R1" kind="k1"><admission option_value="1">A1</admission></entry></row></root>');
        TpImport(Observer, 'entry missing', 90022, '<root><row/></root>');
        TpImport(Observer, 'text in entry', 90022, '<root><row><entry no="R1" status="open" kind="k1">T<admission option_value="1">A1</admission></entry></row></root>');
        Observer.Finish();
    end;

    [Test]
    procedure TP_Unlinked_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TP XP Unlinked Temp";
    begin
        // The inner temporary table element has no LinkTable.
        Port.AddRow('R1', 's1');
        Port.AddRow('R2', 's2');
        Port.AddAttr('R1', 'A', '1');
        Port.AddAttr('R2', 'B', '2');
        Port.AddAttr('X', 'C', '3');
        Observer.Observe('xml', TpExportUnlinked(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TP_Unlinked_Export_NoAttrs()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TP XP Unlinked Temp";
    begin
        Port.AddRow('R1', 's1');
        Observer.Observe('xml', TpExportUnlinked(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TP_Unlinked_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpImport(Observer, 'two rows', 90023, '<root><row no="R1"><attributes><attribute code="A" value="1"/><attribute code="B" value="2"/></attributes><status>s1</status></row><row no="R2"><attributes><attribute code="A" value="3"/></attributes><status>s2</status></row></root>');
        TpImport(Observer, 'attributes absent', 90023, '<root><row no="R1"><status>s1</status></row><row no="R2"><attributes><attribute code="A" value="1"/></attributes></row></root>');
        TpImport(Observer, 'attributes empty', 90023, '<root><row no="R1"><attributes/><status>s1</status></row></root>');
        Observer.Finish();
    end;

    [Test]
    procedure TP_Unlinked_Import_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpImport(Observer, 'attributes twice', 90023, '<root><row no="R1"><attributes><attribute code="A" value="1"/></attributes><attributes><attribute code="B" value="2"/></attributes></row></root>');
        TpImport(Observer, 'same code twice', 90023, '<root><row no="R1"><attributes><attribute code="A" value="1"/><attribute code="A" value="2"/></attributes></row></root>');
        TpImport(Observer, 'code missing', 90023, '<root><row no="R1"><attributes><attribute value="1"/></attributes></row></root>');
        TpImport(Observer, 'status first', 90023, '<root><row no="R1"><status>s1</status><attributes><attribute code="A" value="1"/></attributes></row></root>');
        Observer.Finish();
    end;
}
