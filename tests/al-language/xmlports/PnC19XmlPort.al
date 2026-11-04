// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: XmlPort "running it (Export, Import) is REFUSED: FormatEvaluate, a trigger on a container text element, MinOccurs, MaxOccurs, Occurrence ... Probe wanted: FormatEvaluate = Xml on dates, decimals and booleans; OnAfterAssignVariable and OnBeforePassVariable on a container text element; Occurrence and MinOccurs on import"
// BC versions: 29 (27 and 28 by CI)

codeunit 71148 "LT PnC Log 9"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

table 71097 "LT PnC XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; D; Date) { }
        field(3; Dec; Decimal) { }
        field(4; B; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

xmlport 71096 "LT PnC XP Xml"
{
    Direction = Both;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT PnC XP Row")
            {
                fieldelement(No; Row."No.") { }
                fieldelement(D; Row.D) { }
                fieldelement(Dec; Row.Dec) { }
                fieldelement(B; Row.B) { }
            }
        }
    }
}

xmlport 71097 "LT PnC XP Legacy"
{
    Direction = Both;
    Format = Xml;
    FormatEvaluate = Legacy;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT PnC XP Row")
            {
                fieldelement(No; Row."No.") { }
                fieldelement(D; Row.D) { }
                fieldelement(Dec; Row.Dec) { }
                fieldelement(B; Row.B) { }
            }
        }
    }
}

xmlport 71098 "LT PnC XP Container"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Container)
            {
                textelement(Leaf)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('LeafBeforePass:[' + Leaf + ']');
                        Leaf := 'leaf-set';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('LeafAfterAssign:[' + Leaf + ']');
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('BeforePass:[' + Container + ']');
                    Container := 'set-in-trigger';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('AfterAssign:[' + Container + ']');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnC Log 9";
}

xmlport 71099 "LT PnC XP Occurrence"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Req)
            {
                MinOccurs = Once;
                MaxOccurs = Once;
            }
            textelement(Opt)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('Opt:' + Opt);
                end;
            }
            textelement(Many)
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('Many:' + Many);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnC Log 9";
}

codeunit 72950 "LT PnC XP Runner"
{
    TableNo = "LT PnC Blob";

    trigger OnRun()
    var
        InS: InStream;
    begin
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        if Rec."No." = 1 then
            Xmlport.Import(Xmlport::"LT PnC XP Xml", InS)
        else
            Xmlport.Import(Xmlport::"LT PnC XP Legacy", InS);
    end;
}

codeunit 71133 "LT PnC XmlPort Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ImportXml(PortId: Integer; Xml: Text): Text
    var
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Insert();
        Buffer."No." := PortId;
        Buffer.Data.CreateOutStream(OutS);
        OutS.WriteText(Xml);
        Buffer.Modify();
        if Codeunit.Run(Codeunit::"LT PnC XP Runner", Buffer) then
            exit('imported');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RowText(): Text
    var
        T: Record "LT PnC XP Row";
    begin
        if not T.FindFirst() then
            exit('norow');
        exit(Format(T."No.") + '|' + Format(T.D, 0, 9) + '|' + Format(T.Dec, 0, 9) + '|' + Format(T.B));
    end;

    local procedure XmlOf(No: Text; D: Text; Dec: Text; B: Text): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8"?><Root><Row><No>' + No + '</No><D>' + D + '</D><Dec>' + Dec + '</Dec><B>' + B + '</B></Row></Root>');
    end;

    [Test]
    procedure Export_BothFormatEvaluates()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC XP Row";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        T.DeleteAll();
        T."No." := 1;
        T.D := DMY2Date(5, 3, 2024);
        T.Dec := 1234.5;
        T.B := true;
        T.Insert();
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT PnC XP Xml", OutS);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line;
        end;
        Observer.Observe('xmlEvaluate', Xml);
        Clear(Xml);
        Buffer.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT PnC XP Legacy", OutS);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line;
        end;
        Observer.Observe('legacyEvaluate', Xml);
        Observer.Expect('xmlEvaluate', ' þ<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root>  <Row>    <No>1</No>    <D>2024-03-05</D>    <Dec>1234.50</Dec>    <B>true</B>  </Row></Root>');
        Observer.Expect('legacyEvaluate', ' þ<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root>  <Row>    <No>1</No>    <D>03/05/24</D>    <Dec>1,234.50</Dec>    <B>Yes</B>  </Row></Root>t>');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Dates_FormatEvaluateXml()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC XP Row";
        Texts: List of [Text];
        Value: Text;
        n: Integer;
    begin
        Texts.Add('2024-03-05');
        Texts.Add('05.03.2024');
        Texts.Add('03/05/2024');
        Texts.Add('3/5/24');
        Texts.Add('2024-03-05T00:00:00');
        Texts.Add('20240305');
        Texts.Add('');
        foreach Value in Texts do begin
            n += 1;
            T.DeleteAll();
            asserterror Observer.Observe('xml.date' + Format(n), ImportXml(1, XmlOf('1', Value, '1', 'true')));
            Observer.ObserveError('af268');
        end;
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Expect('af268|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af268|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Dates_FormatEvaluateLegacy()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC XP Row";
        Texts: List of [Text];
        Value: Text;
        n: Integer;
    begin
        Texts.Add('2024-03-05');
        Texts.Add('05.03.2024');
        Texts.Add('03/05/2024');
        Texts.Add('3/5/24');
        Texts.Add('');
        foreach Value in Texts do begin
            n += 1;
            T.DeleteAll();
            asserterror Observer.Observe('legacy.date' + Format(n), ImportXml(2, XmlOf('1', Value, '1', 'true')));
            Observer.ObserveError('af292');
        end;
        Observer.Expect('af292|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af292|code', 'DB:RecordNotFound');
        Observer.Expect('af292|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af292|code', 'DB:RecordNotFound');
        Observer.Expect('af292|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af292|code', 'DB:RecordNotFound');
        Observer.Expect('af292|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af292|code', 'DB:RecordNotFound');
        Observer.Expect('af292|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af292|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Decimals_And_Booleans()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC XP Row";
        Texts: List of [Text];
        Value: Text;
        n: Integer;
    begin
        Texts.Add('1234.5');
        Texts.Add('1,234.5');
        Texts.Add('1234,5');
        Texts.Add('-0.5');
        Texts.Add('1e3');
        Texts.Add('abc');
        foreach Value in Texts do begin
            n += 1;
            T.DeleteAll();
            asserterror Observer.Observe('xml.dec' + Format(n), ImportXml(1, XmlOf('1', '2024-03-05', Value, 'true')));
            Observer.ObserveError('af317');
        end;
        Clear(Texts);
        Texts.Add('true');
        Texts.Add('false');
        Texts.Add('1');
        Texts.Add('0');
        Texts.Add('Yes');
        Texts.Add('TRUE');
        Clear(n);
        foreach Value in Texts do begin
            n += 1;
            T.DeleteAll();
            asserterror Observer.Observe('xml.bool' + Format(n), ImportXml(1, XmlOf('1', '2024-03-05', '1', Value)));
            Observer.ObserveError('af332');
        end;
        Observer.Expect('af317|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af317|code', 'DB:RecordNotFound');
        Observer.Expect('af317|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af317|code', 'DB:RecordNotFound');
        Observer.Expect('af317|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af317|code', 'DB:RecordNotFound');
        Observer.Expect('af317|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af317|code', 'DB:RecordNotFound');
        Observer.Expect('af317|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af317|code', 'DB:RecordNotFound');
        Observer.Expect('af317|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af317|code', 'DB:RecordNotFound');
        Observer.Expect('af332|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af332|code', 'DB:RecordNotFound');
        Observer.Expect('af332|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af332|code', 'DB:RecordNotFound');
        Observer.Expect('af332|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af332|code', 'DB:RecordNotFound');
        Observer.Expect('af332|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af332|code', 'DB:RecordNotFound');
        Observer.Expect('af332|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af332|code', 'DB:RecordNotFound');
        Observer.Expect('af332|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''1''');
        Observer.Expect('af332|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Decimals_And_Booleans_Legacy()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC XP Row";
        Texts: List of [Text];
        Value: Text;
        n: Integer;
    begin
        Texts.Add('1234.5');
        Texts.Add('1,234.5');
        Texts.Add('1234,5');
        foreach Value in Texts do begin
            n += 1;
            T.DeleteAll();
            asserterror Observer.Observe('legacy.dec' + Format(n), ImportXml(2, XmlOf('1', '2024-03-05', Value, 'true')));
            Observer.ObserveError('af353');
        end;
        Clear(Texts);
        Texts.Add('true');
        Texts.Add('1');
        Texts.Add('Yes');
        Texts.Add('0');
        Clear(n);
        foreach Value in Texts do begin
            n += 1;
            T.DeleteAll();
            asserterror Observer.Observe('legacy.bool' + Format(n), ImportXml(2, XmlOf('1', '2024-03-05', '1', Value)));
            Observer.ObserveError('af367');
        end;
        Observer.Expect('af353|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af353|code', 'DB:RecordNotFound');
        Observer.Expect('af353|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af353|code', 'DB:RecordNotFound');
        Observer.Expect('af353|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af353|code', 'DB:RecordNotFound');
        Observer.Expect('af367|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af367|code', 'DB:RecordNotFound');
        Observer.Expect('af367|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af367|code', 'DB:RecordNotFound');
        Observer.Expect('af367|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af367|code', 'DB:RecordNotFound');
        Observer.Expect('af367|text', 'The LT PnC Blob does not exist. Identification fields and values: No.=''2''');
        Observer.Expect('af367|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}

codeunit 71134 "LT PnC XmlPort Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunPort(PortId: Integer; Xml: Text)
    var
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        OutS.WriteText(Xml);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        if PortId = 1 then
            Xmlport.Import(Xmlport::"LT PnC XP Container", InS)
        else
            Xmlport.Import(Xmlport::"LT PnC XP Occurrence", InS);
    end;

    [Test]
    procedure ContainerTextElement_Export_And_Import()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 9";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Log.Reset();
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT PnC XP Container", OutS);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line;
        end;
        Observer.Observe('export.xml', Xml);
        Observer.Observe('export.log', Log.Joined());
        Log.Reset();
        RunPort(1, '<?xml version="1.0" encoding="UTF-8"?><Root><Container><Leaf>abc</Leaf></Container></Root>');
        Observer.Observe('import.log', Log.Joined());
        Observer.Expect('export.xml', ' þ<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root>  <Container>    <Leaf>leaf-set</Leaf>set-in-trigger</Container></Root>');
        Observer.Expect('export.log', 'BeforePass:[]|LeafBeforePass:[]');
        Observer.Expect('import.log', 'LeafAfterAssign:[abc]|AfterAssign:[]');
        Observer.Verify();
    end;

    [Test]
    procedure Occurrence_Import_Counts()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 9";
    begin
        Log.Reset();
        RunPort(2, '<?xml version="1.0" encoding="UTF-8"?><Root><Req>r</Req></Root>');
        Observer.Observe('onlyReq.log', Log.Joined());
        Log.Reset();
        RunPort(2, '<?xml version="1.0" encoding="UTF-8"?><Root><Req>r</Req><Opt>o</Opt><Many>m1</Many><Many>m2</Many><Many>m3</Many></Root>');
        Observer.Observe('all.log', Log.Joined());
        Log.Reset();
        asserterror RunPort(2, '<?xml version="1.0" encoding="UTF-8"?><Root><Opt>o</Opt></Root>');
        Observer.ObserveError('missingReq');
        Observer.Observe('missingReq.log', Log.Joined());
        Log.Reset();
        asserterror RunPort(2, '<?xml version="1.0" encoding="UTF-8"?><Root><Req>r</Req><Opt>o1</Opt><Opt>o2</Opt></Root>');
        Observer.ObserveError('twoOpt');
        Observer.Observe('twoOpt.log', Log.Joined());
        Log.Reset();
        asserterror RunPort(2, '<?xml version="1.0" encoding="UTF-8"?><Root><Req>r1</Req><Req>r2</Req></Root>');
        Observer.ObserveError('twoReq');
        Observer.Observe('twoReq.log', Log.Joined());
        Log.Reset();
        asserterror RunPort(2, '<?xml version="1.0" encoding="UTF-8"?><Root><Req>r</Req><Many>m</Many><Opt>o</Opt></Root>');
        Observer.ObserveError('wrongOrder');
        Observer.Observe('wrongOrder.log', Log.Joined());
        Observer.Expect('onlyReq.log', '');
        Observer.Expect('all.log', 'Opt:o|Many:m1|Many:m2|Many:m3');
        Observer.Expect('missingReq|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Opt''. List of possible elements expected: ''Req''.');
        Observer.Expect('missingReq|code', 'XmlPortInvalidXml');
        Observer.Expect('missingReq.log', '');
        Observer.Expect('twoOpt|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Opt''. List of possible elements expected: ''Many''.');
        Observer.Expect('twoOpt|code', 'XmlPortInvalidXml');
        Observer.Expect('twoOpt.log', 'Opt:o1');
        Observer.Expect('twoReq|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Req''. List of possible elements expected: ''Opt, Many''.');
        Observer.Expect('twoReq|code', 'XmlPortInvalidXml');
        Observer.Expect('twoReq.log', '');
        Observer.Expect('wrongOrder|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Opt''. List of possible elements expected: ''Many''.');
        Observer.Expect('wrongOrder|code', 'XmlPortInvalidXml');
        Observer.Expect('wrongOrder.log', 'Many:m');
        Observer.Verify();
    end;

    [Test]
    procedure Occurrence_Export()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT PnC XP Occurrence", OutS);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line;
        end;
        Observer.Observe('export.xml', Xml);
        Observer.Expect('export.xml', ' þ<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root>  <Req />  <Opt />  <Many /></Root>');
        Observer.Verify();
    end;
}
