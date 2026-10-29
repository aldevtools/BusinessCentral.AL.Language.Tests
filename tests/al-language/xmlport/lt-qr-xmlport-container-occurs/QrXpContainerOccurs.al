// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 87275, 87276, 87279, xmlport 87277, runner codeunit 87278, test codeunit 87280 (writer QR); writer QS: tests QS_TextAttr_* on table 87360, xmlport 87361, runner 87362 (QsXpTextAttrObjects.al)
// Writer TO: tests TO_* on table 90000, xmlports 90001-90003, runner 90004 (ToXpTextInTableObjects.al): a text element below a table element, with only text attributes or with content.
// Writer TP: tests TP_* on tables 90020-90021, xmlports 90022-90023, runner 90024 (TpXpNestedObjects.al): a text element with one text attribute
//   below a text element below a table element; an optional text element holding an unlinked temporary table element.
// Writer TR: tests TR_* on tables 90060-90063, xmlports 90064-90066, runner 90067 (TrXpReplyObjects.al): request/reply ports with unlinked
//   temporary table elements nested in optional text elements, export after import into the same instance; empty leaf elements on import.
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
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row>|    <entry no="R1" status="open" kind="k1">|      <admission option_value="1">A1</admission>|    </entry>|  </row>|  <row>|    <entry no="R2" status="">|      <admission option_value="2" />|    </entry>|  </row>|  <row>|    <entry no="R3" status="closed" kind="k3">|      <admission option_value="">X</admission>|    </entry>|  </row>|</root>|');
        Observer.Expect('log', 'get R1;pass entry;pass status;pass admission;pass admcode;get R2;pass entry;pass status;pass admission;pass admcode;get R3;pass entry;pass status;pass admission;pass admcode;');
        Observer.Verify();
    end;

    [Test]
    procedure TP_Nested_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TP XP Nested Text";
    begin
        Observer.Observe('xml', TpExportNested(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root />|');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure TP_Nested_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpImport(Observer, 'two rows', 90022, '<root><row><entry no="R1" status="open" kind="k1"><admission option_value="1">A1</admission></entry></row><row><entry no="R2" status="closed" kind="k2"><admission option_value="2">A2</admission></entry></row></root>');
        TpImport(Observer, 'empty admission', 90022, '<root><row><entry no="R1" status="open" kind="k1"><admission option_value="1"/></entry></row></root>');
        TpImport(Observer, 'no kind', 90022, '<root><row><entry no="R1" status="open"><admission option_value="1">A1</admission></entry></row></root>');
        Observer.Expect('two rows', 'ok log=init;no=R1;status=open;admission=A1 admcode=1;entry= kind=k1;before insert R1;after insert;init;no=R2;status=closed;admission=A2 admcode=2;entry= kind=k2;before insert R2;after insert; values: entry= status=closed kind=k2 admission=A2 admcode=2 rows=R1:open/k1/A1/1;R2:closed/k2/A2/2;');
        Observer.Expect('empty admission', 'ok log=init;no=R1;status=open;admission= admcode=1;entry= kind=k1;before insert R1;after insert; values: entry= status=open kind=k1 admission= admcode=1 rows=R1:open/k1//1;');
        Observer.Expect('no kind', 'ok log=init;no=R1;status=open;admission=A1 admcode=1;entry= kind=;before insert R1;after insert; values: entry= status=open kind= admission=A1 admcode=1 rows=R1:open//A1/1;');
        Observer.Verify();
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
        Observer.Expect('admission missing|text', 'Imported XML cannot validate with the schema: The element ''entry'' has incomplete content. List of possible elements expected: ''admission''.');
        Observer.Expect('admission missing|code', 'XmlPortInvalidXml');
        Observer.Expect('option_value missing|text', 'Imported XML cannot validate with the schema: The required attribute ''option_value'' is missing.');
        Observer.Expect('option_value missing|code', 'XmlPortInvalidXml');
        Observer.Expect('status missing|text', 'Imported XML cannot validate with the schema: The required attribute ''status'' is missing.');
        Observer.Expect('status missing|code', 'XmlPortInvalidXml');
        Observer.Expect('entry missing|text', 'Imported XML cannot validate with the schema: The element ''row'' has incomplete content. List of possible elements expected: ''entry''.');
        Observer.Expect('entry missing|code', 'XmlPortInvalidXml');
        Observer.Expect('text in entry', 'ok log=init;no=R1;status=open;admission=A1 admcode=1;entry=T kind=k1;before insert R1;after insert; values: entry=T status=open kind=k1 admission=A1 admcode=1 rows=R1:open/k1/A1/1;');
        Observer.Verify();
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
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row no="R1">|    <attributes>|      <attribute code="A" value="1" />|      <attribute code="B" value="2" />|      <attribute code="C" value="3" />|    </attributes>|    <status>s1</status>|  </row>|  <row no="R2">|    <attributes>|      <attribute code="A" value="1" />|      <attribute code="B" value="2" />|      <attribute code="C" value="3" />|    </attributes>|    <status>s2</status>|  </row>|</root>|');
        Observer.Expect('log', 'get R1;get attr R1/A;get attr R2/B;get attr X/C;get R2;get attr R1/A;get attr R2/B;get attr X/C;');
        Observer.Verify();
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
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<root>|  <row no="R1">|    <attributes />|    <status>s1</status>|  </row>|</root>|');
        Observer.Expect('log', 'get R1;');
        Observer.Verify();
    end;

    [Test]
    procedure TP_Unlinked_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TpImport(Observer, 'two rows', 90023, '<root><row no="R1"><attributes><attribute code="A" value="1"/><attribute code="B" value="2"/></attributes><status>s1</status></row><row no="R2"><attributes><attribute code="A" value="3"/></attributes><status>s2</status></row></root>');
        TpImport(Observer, 'attributes absent', 90023, '<root><row no="R1"><status>s1</status></row><row no="R2"><attributes><attribute code="A" value="1"/></attributes></row></root>');
        TpImport(Observer, 'attributes empty', 90023, '<root><row no="R1"><attributes/><status>s1</status></row></root>');
        Observer.Expect('two rows', 'ok log=init;no=R1;init attr;before insert attr A=1 row=R1;after insert attr;init attr;before insert attr B=2 row=R1;after insert attr;before insert R1 status=s1;after insert;init;no=R2;init attr;before insert attr A=3 row=R2;after insert attr;before insert R2 status=s2;after insert; rows=R1:s1;R2:s2; attrs=R1/A=1;R1/B=2;R2/A=3;');
        Observer.Expect('attributes absent', 'ok log=init;no=R1;before insert R1 status=s1;after insert;init;no=R2;init attr;before insert attr A=1 row=R2;after insert attr;before insert R2 status=;after insert; rows=R1:s1;R2:; attrs=R2/A=1;');
        Observer.Expect('attributes empty', 'ok log=init;no=R1;before insert R1 status=s1;after insert; rows=R1:s1; attrs=');
        Observer.Verify();
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
        Observer.Expect('attributes twice|text', 'Imported XML cannot validate with the schema: The element ''row'' has invalid child element ''attributes''. List of possible elements expected: ''status''.');
        Observer.Expect('attributes twice|code', 'XmlPortInvalidXml');
        Observer.Expect('same code twice|text', 'The record in table LT TP XP Attr already exists. Identification fields and values: Parent=''R1'',Code=''A''');
        Observer.Expect('same code twice|code', 'DB:RecordExists');
        Observer.Expect('code missing|text', 'Imported XML cannot validate with the schema: The required attribute ''code'' is missing.');
        Observer.Expect('code missing|code', 'XmlPortInvalidXml');
        Observer.Expect('status first|text', 'Imported XML cannot validate with the schema: The element ''row'' has invalid child element ''attributes''.');
        Observer.Expect('status first|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    // Writer TQ (NP lane, 2026-10-29): export (and import) of the response-style port 90041/90042 (TqXpResponseObjects.al):
    // a text element with content, MinOccurs = Zero and MaxOccurs = Once, of field elements and leaf text elements below a temporary table element.
    local procedure TqExport(var Port: XmlPort "LT TQ XP Response"): Text
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

    local procedure TqExportNs(var Port: XmlPort "LT TQ XP Response Ns"): Text
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

    local procedure TqImport(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        Runner: Codeunit "LT TQ XP Runner";
    begin
        Runner.SetInput('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure TQ_Response_Export_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TQ XP Response";
    begin
        Observer.Observe('xml', TqExport(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('values', Port.Values());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response />|');
        Observer.Expect('log', '');
        Observer.Expect('values', 'responsecode= responsemessage= tier= validuntil= membership= status=');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Response_Export_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TQ XP Response";
    begin
        Port.AddMember('M1', 'GOLDCLUB', 'Ann Smith', DMY2Date(15, 1, 2026), 150.5, false);
        Port.AddMember('M2', 'BASIC', 'Bob', DMY2Date(1, 2, 2025), 7, true);
        Observer.Observe('xml', TqExport(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('values', Port.Values());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response>|  <member no="M1">|    <status>|      <responsecode>OK-M1</responsecode>|      <responsemessage />|    </status>|    <membership>|      <code>GOLDCLUB</code>|      <name>Ann Smith</name>|      <tier>GOLD</tier>|      <issued>2026-01-15</issued>|      <points>150.50</points>|      <validuntil />|      <blocked>false</blocked>|    </membership>|  </member>|  <member no="M2">|    <status>|      <responsecode>OK-M2</responsecode>|      <responsemessage />|    </status>|    <membership>|      <code>BASIC</code>|      <name>Bob</name>|      <tier />|      <issued>2025-02-01</issued>|      <points>7.00</points>|      <validuntil />|      <blocked>true</blocked>|    </membership>|  </member>|</response>|');
        Observer.Expect('log', 'get M1;pass status;pass responsemessage;pass membership;pass tier;get M2;pass status;pass responsemessage;pass membership;pass tier;');
        Observer.Expect('values', 'responsecode=OK-M2 responsemessage= tier= validuntil= membership= status=');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Response_Export_EmptyValues()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TQ XP Response";
    begin
        Port.AddMember('M3', '', '', 0D, 0, false);
        Observer.Observe('xml', TqExport(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response>|  <member no="M3">|    <status>|      <responsecode>OK-M3</responsecode>|      <responsemessage>no membership</responsemessage>|    </status>|    <membership>|      <code />|      <name />|      <tier />|      <issued />|      <points>0.00</points>|      <validuntil />|      <blocked>false</blocked>|    </membership>|  </member>|</response>|');
        Observer.Expect('log', 'get M3;pass status;pass responsemessage;pass membership;pass tier;');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Response_Export_GlobalLeafSet()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TQ XP Response";
    begin
        Port.AddMember('M1', 'C1', 'N1', DMY2Date(15, 1, 2026), 1.25, false);
        Port.AddMember('M2', '', '', 0D, 0, false);
        Port.SetValidUntil('2027-12-31');
        Observer.Observe('xml', TqExport(Port));
        Observer.Observe('values', Port.Values());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response>|  <member no="M1">|    <status>|      <responsecode>OK-M1</responsecode>|      <responsemessage />|    </status>|    <membership>|      <code>C1</code>|      <name>N1</name>|      <tier />|      <issued>2026-01-15</issued>|      <points>1.25</points>|      <validuntil>2027-12-31</validuntil>|      <blocked>false</blocked>|    </membership>|  </member>|  <member no="M2">|    <status>|      <responsecode>OK-M2</responsecode>|      <responsemessage>no membership</responsemessage>|    </status>|    <membership>|      <code />|      <name />|      <tier />|      <issued />|      <points>0.00</points>|      <validuntil>2027-12-31</validuntil>|      <blocked>false</blocked>|    </membership>|  </member>|</response>|');
        Observer.Expect('values', 'responsecode=OK-M2 responsemessage=no membership tier= validuntil=2027-12-31 membership= status=');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_ResponseNs_Export()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TQ XP Response Ns";
        Port2: XmlPort "LT TQ XP Response Ns";
        Port3: XmlPort "LT TQ XP Response Ns";
    begin
        Observer.Observe('no rows', TqExportNs(Port));
        Port2.AddMember('M1', 'C1', 12.5);
        Port2.AddMember('M2', '', 0);
        Observer.Observe('rows, leaves empty', TqExportNs(Port2));
        Port3.AddMember('M1', 'C1', 12.5);
        Port3.SetLeaves('OK', 'fine', 'GOLD', '2027-12-31');
        Observer.Observe('rows, leaves set', TqExportNs(Port3));
        Observer.Expect('no rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response xmlns="urn:microsoft-dynamics-nav/xmlports/x90042" />|');
        Observer.Expect('rows, leaves empty', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response xmlns="urn:microsoft-dynamics-nav/xmlports/x90042">|  <member>|    <status>|      <responsecode />|      <responsemessage />|    </status>|    <membership>|      <code>C1</code>|      <tier />|      <points>12.50</points>|      <validuntil />|    </membership>|  </member>|  <member>|    <status>|      <responsecode />|      <responsemessage />|    </status>|    <membership>|      <code />|      <tier />|      <points>0.00</points>|      <validuntil />|    </membership>|  </member>|</response>|');
        Observer.Expect('rows, leaves set', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<response xmlns="urn:microsoft-dynamics-nav/xmlports/x90042">|  <member>|    <status>|      <responsecode>OK</responsecode>|      <responsemessage>fine</responsemessage>|    </status>|    <membership>|      <code>C1</code>|      <tier>GOLD</tier>|      <points>12.50</points>|      <validuntil>2027-12-31</validuntil>|    </membership>|  </member>|</response>|');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Response_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqImport(Observer, 'full', '<response><member no="M1"><status><responsecode>OK</responsecode><responsemessage>m</responsemessage></status><membership><code>C1</code><name>N1</name><tier>GOLD</tier><issued>2026-01-15</issued><points>12.5</points><validuntil>2027-12-31</validuntil><blocked>true</blocked></membership></member></response>');
        TqImport(Observer, 'membership absent', '<response><member no="M1"><status><responsecode>OK</responsecode><responsemessage>m</responsemessage></status></member></response>');
        Observer.Expect('full', 'ok log=init;responsecode=OK;tier=GOLD;membership=;before insert M1 code=C1 name=N1 issued=2026-01-15 points=12.5 blocked=true validuntil=2027-12-31; values: responsecode=OK responsemessage=m tier=GOLD validuntil=2027-12-31 membership= status= rows=M1:C1/N1/2026-01-15/12.5/true;');
        Observer.Expect('membership absent', 'ok log=init;responsecode=OK;before insert M1 code= name= issued= points=0 blocked=false validuntil=; values: responsecode=OK responsemessage=m tier= validuntil= membership= status= rows=M1:///0/false;');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Response_Import_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TqImport(Observer, 'optional leaves absent', '<response><member no="M1"><status><responsecode>OK</responsecode><responsemessage /></status><membership><code>C1</code><tier /><issued>2026-01-15</issued><blocked>false</blocked></membership></member></response>');
        TqImport(Observer, 'membership twice', '<response><member no="M1"><status><responsecode>OK</responsecode><responsemessage /></status><membership><code>C1</code><tier /><issued /><blocked>false</blocked></membership><membership><code>C2</code><tier /><issued /><blocked>false</blocked></membership></member></response>');
        TqImport(Observer, 'no rows', '<response />');
        Observer.Expect('optional leaves absent', 'ok log=init;responsecode=OK;tier=;tier=;membership=;before insert M1 code=C1 name= issued=2026-01-15 points=0 blocked=false validuntil=; values: responsecode=OK responsemessage= tier= validuntil= membership= status= rows=M1:C1//2026-01-15/0/false;');
        Observer.Expect('membership twice|text', 'Imported XML cannot validate with the schema: The element ''member'' has invalid child element ''membership''.');
        Observer.Expect('membership twice|code', 'XmlPortInvalidXml');
        Observer.Expect('no rows', 'ok log= values: responsecode= responsemessage= tier= validuntil= membership= status= rows=');
        Observer.Verify();
    end;

    // Writer TR (NP lane, 2026-10-29): request/reply ports 90064-90066 (TrXpReplyObjects.al): unlinked temporary table elements nested
    // in optional text elements below a temporary table element (MaxOccurs = Once), export with 0, 1 and 2 rows at each level after an
    // import into the same instance; import of empty leaf elements written as <x /> and as <x></x>.
    local procedure TrExportBooking(var Port: XmlPort "LT TR XP Booking"): Text
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

    [TryFunction]
    local procedure TrTryExportBooking(var Port: XmlPort "LT TR XP Booking"; var Xml: Text)
    begin
        Xml := TrExportBooking(Port);
    end;

    local procedure TrImportBooking(var Port: XmlPort "LT TR XP Booking"; Body: Text)
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure TrExportMember(var Port: XmlPort "LT TR XP Member Reply"): Text
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

    local procedure TrImportMember(var Port: XmlPort "LT TR XP Member Reply"; Body: Text)
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
    end;

    local procedure TrLeaf(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        Runner: Codeunit "LT TR XP Leaf Runner";
    begin
        Runner.SetInput('<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TrTryExportMember(var Port: XmlPort "LT TR XP Member Reply"; var Xml: Text)
    begin
        Xml := TrExportMember(Port);
    end;

    [Test]
    procedure TR_Booking_Export_Fresh()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
        Xml: Text;
    begin
        // nothing imported, no reply: the request table element (MinOccurs default Once) writes one row from the empty record
        ClearLastError();
        if TrTryExportBooking(Port, Xml) then
            Observer.Observe('xml', Xml)
        else
            Observer.ObserveError('xml');
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="">|    <ticket code="" line_no="0" qty="0" amount="0.00" />|  </request>|</bookings>|');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Booking_ImportThenExport()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
    begin
        // import the request, export (no reply yet), set an error reply on the same instance, export again
        TrImportBooking(Port, '<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064"><request token="T1"><ticket code="ADULT" line_no="1" qty="2" amount="10.5"/><ticket code="CHILD" line_no="2" qty="1"/></request></bookings>');
        Observer.Observe('import log', Port.GetLog());
        Observer.Observe('token', Port.GetToken());
        Observer.Observe('tickets', Port.Tickets());
        Port.ClearLog();
        Observer.Observe('export 1', TrExportBooking(Port));
        Observer.Observe('export 1 log', Port.GetLog());
        Port.ClearLog();
        Port.SetErrorResult('T1', 'Ticket sold out');
        Observer.Observe('export 2', TrExportBooking(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after', Port.ResultMessage());
        Observer.Expect('import log', 'insert ticket ADULT;insert ticket CHILD;');
        Observer.Expect('token', 'T1');
        Observer.Expect('tickets', '1:ADULT/1/2/10.5;2:CHILD/2/1/0;');
        Observer.Expect('export 1', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="T1">|    <ticket code="ADULT" line_no="1" qty="2" amount="10.50" />|    <ticket code="CHILD" line_no="2" qty="1" amount="0.00" />|  </request>|</bookings>|');
        Observer.Expect('export 1 log', '');
        Observer.Expect('export 2', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="T1">|    <ticket code="ADULT" line_no="1" qty="2" amount="10.50" />|    <ticket code="CHILD" line_no="2" qty="1" amount="0.00" />|  </request>|  <results>|    <state>false</state>|    <token>T1</token>|    <message>Ticket sold out</message>|    <details />|  </results>|</bookings>|');
        Observer.Expect('export 2 log', 'get result;pass state;');
        Observer.Expect('after', 'token=T1 message=Ticket sold out state=false');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Booking_Reply_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
    begin
        Port.SetResult(1, 'T9', true, 'OK');
        Observer.Observe('xml', TrExportBooking(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('after', Port.ResultMessage());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="">|    <ticket code="" line_no="0" qty="0" amount="0.00" />|  </request>|  <results>|    <state>true</state>|    <token>T9</token>|    <message>OK</message>|    <details />|  </results>|</bookings>|');
        Observer.Expect('log', 'get result;pass state;');
        Observer.Expect('after', 'token=T9 message=OK state=true');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Booking_Reply_OneLineOnePart()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
    begin
        Port.SetResult(1, 'T9', true, 'OK');
        Port.AddLine(10, 1, true, '');
        Port.AddPart(1, 1, 'ZOO', 501, 2, 12.5, 'Zoo entrance');
        Observer.Observe('xml', TrExportBooking(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('parts after', Port.PartRows());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="">|    <ticket code="" line_no="0" qty="0" amount="0.00" />|  </request>|  <results>|    <state>true</state>|    <token>T9</token>|    <message>OK</message>|    <details>|      <line line_no="1" status="true" message="OK" price="12.5" quantity="1">|        <parts>|          <Part Code="ZOO">|            <Slot ExtNo="501" Type="Open" CanMove="No" UnitPrice="12.5">|              <kind_is option_value="2">Open</kind_is>|            </Slot>|            <Description>Zoo entrance</Description>|          </Part>|        </parts>|      </line>|    </details>|  </results>|</bookings>|');
        Observer.Expect('log', 'get result;pass state;get line 1;pass price;pass quantity;get part ZOO;pass unitprice;pass kind_is;pass kind_id;');
        Observer.Expect('parts after', 'ZOO;');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Booking_Reply_TwoLinesTwoParts()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
    begin
        // each line's OnAfterGetRecord empties the unlinked part table and fills it for that line; parts follow SourceTableView (Kind)
        Port.SetResult(1, 'T9', true, 'OK');
        Port.AddLine(10, 1, true, '');
        Port.AddLine(20, 2, false, 'Sold out');
        Port.AddPart(1, 1, 'ZOO', 501, 2, 12.5, 'Zoo entrance');
        Port.AddPart(2, 1, 'SHOW', 712, 1, 7, 'Evening show');
        Port.AddPart(3, 2, 'PARK', 0, 3, 0, '');
        Port.AddPart(4, 2, 'MUSEUM', 803, 1, 4.25, 'Museum');
        Observer.Observe('xml', TrExportBooking(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('parts after', Port.PartRows());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="">|    <ticket code="" line_no="0" qty="0" amount="0.00" />|  </request>|  <results>|    <state>true</state>|    <token>T9</token>|    <message>OK</message>|    <details>|      <line line_no="1" status="true" message="OK" price="19.5" quantity="2">|        <parts>|          <Part Code="SHOW">|            <Slot ExtNo="712" Type="Timed" Date="2026-03-02" StartTime="10:00:00" EndTime="11:30:00" CanMove="Yes" UnitPrice="7">|              <kind_is option_value="1">Timed</kind_is>|            </Slot>|            <Description>Evening show</Description>|          </Part>|          <Part Code="ZOO">|            <Slot ExtNo="501" Type="Open" CanMove="No" UnitPrice="12.5">|              <kind_is option_value="2">Open</kind_is>|            </Slot>|            <Description>Zoo entrance</Description>|          </Part>|        </parts>|      </line>|      <line line_no="2" status="false" message="Sold out" price="4.25" quantity="2">|        <parts>|          <Part Code="MUSEUM">|            <Slot ExtNo="803" Type="Timed" Date="2026-03-03" StartTime="10:00:00" EndTime="11:30:00" CanMove="Yes" UnitPrice="4.25">|              <kind_is option_value="1">Timed</kind_is>|            </Slot>|            <Description>Museum</Description>|          </Part>|          <Part Code="PARK">|            <Slot ExtNo="0" Type="Open" CanMove="No" UnitPrice="0">|              <kind_is option_value="3">Skipped</kind_is>|            </Slot>|            <Description />|          </Part>|        </parts>|      </line>|    </details>|  </results>|</bookings>|');
        Observer.Expect('log', 'get result;pass state;get line 1;pass price;pass quantity;get part SHOW;pass unitprice;pass kind_is;pass kind_id;get part ZOO;pass unitprice;pass kind_is;pass kind_id;get line 2;pass price;pass quantity;get part MUSEUM;pass unitprice;pass kind_is;pass kind_id;get part PARK;pass unitprice;pass kind_is;pass kind_id;');
        Observer.Expect('parts after', 'PARK;MUSEUM;');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Booking_Reply_LinesWithoutParts()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
        Xml: Text;
    begin
        // lines 1 and 3 get no part rows: the part table element (MinOccurs = Once) still writes one Part, from the record variable as it
        // is (empty before any row was read, the last row read after line 2), its OnAfterGetRecord does not run, its children's triggers do
        Port.SetResult(1, 'T9', true, 'OK');
        Port.AddLine(10, 1, true, '');
        Port.AddLine(20, 2, true, '');
        Port.AddLine(30, 3, true, '');
        Port.AddPart(1, 2, 'ZOO', 501, 2, 12.5, 'Zoo entrance');
        ClearLastError();
        if TrTryExportBooking(Port, Xml) then
            Observer.Observe('xml', Xml)
        else
            Observer.ObserveError('xml');
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="">|    <ticket code="" line_no="0" qty="0" amount="0.00" />|  </request>|  <results>|    <state>true</state>|    <token>T9</token>|    <message>OK</message>|    <details>|      <line line_no="1" status="true" message="OK" price="0" quantity="0">|        <parts>|          <Part Code="">|            <Slot ExtNo="0" Type="" CanMove="" UnitPrice="0">|              <kind_is option_value="0"> </kind_is>|            </Slot>|            <Description />|          </Part>|        </parts>|      </line>|      <line line_no="2" status="true" message="OK" price="12.5" quantity="1">|        <parts>|          <Part Code="ZOO">|            <Slot ExtNo="501" Type="Open" CanMove="No" UnitPrice="12.5">|              <kind_is option_value="2">Open</kind_is>|            </Slot>|            <Description>Zoo entrance</Description>|          </Part>|        </parts>|      </line>|      <line line_no="3" status="true" message="OK" price="0" quantity="0">|        <parts>|          <Part Code="ZOO">|            <Slot ExtNo="501" Type="Open" CanMove="No" UnitPrice="12.5">|              <kind_is option_value="2">Open</kind_is>|            </Slot>|            <Description>Zoo entrance</Description>|          </Part>|        </parts>|      </line>|    </details>|  </results>|</bookings>|');
        Observer.Expect('log', 'get result;pass state;get line 1;pass price;pass quantity;pass unitprice;pass kind_is;pass kind_id;get line 2;pass price;pass quantity;get part ZOO;pass unitprice;pass kind_is;pass kind_id;get line 3;pass price;pass quantity;pass unitprice;pass kind_is;pass kind_id;');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Booking_TwoReplyRows()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Booking";
        Xml: Text;
    begin
        // two rows in the reply table element (MaxOccurs = Once): only the first is written
        Port.SetResult(1, 'T1', true, 'first');
        Port.SetResult(2, 'T2', false, 'second');
        ClearLastError();
        if TrTryExportBooking(Port, Xml) then
            Observer.Observe('xml', Xml)
        else
            Observer.ObserveError('xml');
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('after', Port.ResultMessage());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<bookings xmlns="urn:microsoft-dynamics-nav/xmlports/x90064">|  <request token="">|    <ticket code="" line_no="0" qty="0" amount="0.00" />|  </request>|  <results>|    <state>true</state>|    <token>T1</token>|    <message>first</message>|    <details />|  </results>|</bookings>|');
        Observer.Expect('log', 'get result;pass state;');
        Observer.Expect('after', 'token=T2 message=second state=true');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Member_Export_Fresh()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Member Reply";
    begin
        Observer.Observe('xml', TrExportMember(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065">|  <addmember />|</members>|');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Member_ImportThenExport()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Member Reply";
    begin
        TrImportMember(Port, '<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065"><addmember><request instance="i-1"><firstname>Ann</firstname><email>ann@example.com</email><guardian><membernumber>G1</membernumber><email>g@example.com</email></guardian></request></addmember></members>');
        Observer.Observe('import log', Port.GetLog());
        Observer.Observe('state', Port.Response());
        Port.ClearLog();
        Observer.Observe('export 1', TrExportMember(Port));
        Observer.Observe('export 1 log', Port.GetLog());
        Port.ClearLog();
        Port.AddResponse(5, 'M-100', 'ann@example.com');
        Port.AddCard(1, 'CARD-1', DMY2Date(31, 12, 2027));
        Observer.Observe('export 2', TrExportMember(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after', Port.Response());
        Observer.Expect('import log', 'insert request Ann instance=i-1 guardianemail=g@example.com;');
        Observer.Expect('state', 'status= error= reply=none request=Ann/ann@example.com//G1');
        Observer.Expect('export 1', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065">|  <addmember>|    <request instance="i-1">|      <firstname>Ann</firstname>|      <email>ann@example.com</email>|      <store />|      <guardian>|        <membernumber>G1</membernumber>|        <email>g@example.com</email>|      </guardian>|    </request>|  </addmember>|</members>|');
        Observer.Expect('export 1 log', '');
        Observer.Expect('export 2', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065">|  <addmember>|    <request instance="i-1">|      <firstname>Ann</firstname>|      <email>ann@example.com</email>|      <store />|      <guardian>|        <membernumber>G1</membernumber>|        <email>g@example.com</email>|      </guardian>|    </request>|    <response instance="svc-1">|      <status>1</status>|      <errordescription />|      <member>|        <membernumber>M-100</membernumber>|        <email>ann@example.com</email>|        <card>|          <cardnumber>CARD-1</cardnumber>|          <expirydate>2027-12-31</expirydate>|        </card>|      </member>|    </response>|  </addmember>|</members>|');
        Observer.Expect('export 2 log', 'get reply M-100;pass instance;get card CARD-1;');
        Observer.Expect('after', 'status=1 error= reply=5:M-100 request=Ann/ann@example.com//G1');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Member_Reply_Cards()
    var
        Observer: Codeunit "Probe Observer";
        Port0: XmlPort "LT TR XP Member Reply";
        Port2: XmlPort "LT TR XP Member Reply";
        Xml: Text;
    begin
        // the card table element (MaxOccurs = Once, MinOccurs = Zero, no link): no row writes no card, two rows write only the first
        Port0.AddResponse(5, 'M-100', 'ann@example.com');
        Observer.Observe('no card', TrExportMember(Port0));
        Observer.Observe('no card log', Port0.GetLog());
        Port2.AddResponse(5, 'M-100', 'ann@example.com');
        Port2.AddCard(1, 'CARD-1', DMY2Date(31, 12, 2027));
        Port2.AddCard(2, 'CARD-2', 0D);
        ClearLastError();
        if TrTryExportMember(Port2, Xml) then
            Observer.Observe('two cards', Xml)
        else
            Observer.ObserveError('two cards');
        Observer.Observe('two cards log', Port2.GetLog());
        Observer.Expect('no card', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065">|  <addmember>|    <response instance="svc-1">|      <status>1</status>|      <errordescription />|      <member>|        <membernumber>M-100</membernumber>|        <email>ann@example.com</email>|      </member>|    </response>|  </addmember>|</members>|');
        Observer.Expect('no card log', 'get reply M-100;pass instance;');
        Observer.Expect('two cards', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065">|  <addmember>|    <response instance="svc-1">|      <status>1</status>|      <errordescription />|      <member>|        <membernumber>M-100</membernumber>|        <email>ann@example.com</email>|        <card>|          <cardnumber>CARD-1</cardnumber>|          <expirydate>2027-12-31</expirydate>|        </card>|      </member>|    </response>|  </addmember>|</members>|');
        Observer.Expect('two cards log', 'get reply M-100;pass instance;get card CARD-1;');
        Observer.Verify();
    end;

    [Test]
    procedure TR_Member_ErrorReply()
    var
        Observer: Codeunit "Probe Observer";
        Port: XmlPort "LT TR XP Member Reply";
    begin
        Port.AddErrorResponse('Member not found');
        Observer.Observe('xml', TrExportMember(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('after', Port.Response());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<members xmlns="urn:microsoft-dynamics-nav/xmlports/x90065">|  <addmember>|    <response instance="svc-1">|      <status>0</status>|      <errordescription>Member not found</errordescription>|      <member>|        <membernumber />|        <email />|      </member>|    </response>|  </addmember>|</members>|');
        Observer.Expect('log', 'get reply ;pass instance;');
        Observer.Expect('after', 'status=0 error=Member not found reply=0: request=none');
        Observer.Verify();
    end;

    [Test]
    procedure TR_EmptyLeaf_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <x /> runs a leaf text element's OnAfterAssignVariable twice (below the root, below a table element, inside a text element),
        // <x></x> once; a field element's OnAfterAssignField and a container text element's OnAfterAssignVariable run once either way
        TrLeaf(Observer, 'self-closing', '<root><top /><row no="1"><msg /><direct /><box><inner /></box></row></root>');
        TrLeaf(Observer, 'open-close', '<root><top></top><row no="1"><msg></msg><direct></direct><box><inner></inner></box></row></root>');
        TrLeaf(Observer, 'values', '<root><top>t</top><row no="1"><msg>m</msg><direct>d</direct><box><inner>i</inner></box></row></root>');
        TrLeaf(Observer, 'space', '<root><top> </top><row no="1"><msg> </msg><direct> </direct><box><inner> </inner></box></row></root>');
        TrLeaf(Observer, 'box self-closing', '<root><row no="1"><box /></row></root>');
        TrLeaf(Observer, 'box open-close', '<root><row no="1"><box></box></row></root>');
        TrLeaf(Observer, 'two rows', '<root><top /><row no="1"><direct /></row><row no="2"><direct></direct><box><inner /></box></row></root>');
        Observer.Expect('self-closing', 'ok top=[];top=[];msg=[];direct=[];direct=[];inner=[];inner=[];box=[];insert 1 msg=[];');
        Observer.Expect('open-close', 'ok top=[];msg=[];direct=[];inner=[];box=[];insert 1 msg=[];');
        Observer.Expect('values', 'ok top=[t];msg=[m];direct=[d];inner=[i];box=[];insert 1 msg=[m];');
        Observer.Expect('space', 'ok top=[];msg=[];direct=[];inner=[];box=[];insert 1 msg=[];');
        Observer.Expect('box self-closing', 'ok box=[];insert 1 msg=[];');
        Observer.Expect('box open-close', 'ok box=[];insert 1 msg=[];');
        Observer.Expect('two rows', 'ok top=[];top=[];direct=[];direct=[];insert 1 msg=[];direct=[];inner=[];inner=[];box=[];insert 2 msg=[];');
        Observer.Verify();
    end;
}
