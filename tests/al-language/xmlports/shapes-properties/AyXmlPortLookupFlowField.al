// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autocalcfield-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 80510-80511, xmlports 80512-80513, codeunit 80514
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: an Xml XmlPort with a fieldelement over a Lookup FlowField: the exported text with AutoCalcField default (true) and false, each with and
// without CalcFields on the row in OnAfterGetRecord; an import of the same element: the value the row holds in OnBeforeInsertRecord, the run of
// Import (statement form) and the stored row (the FlowField before and after CalcFields). XmlPortFlowFieldSumCount.al and XmlPortFlowFieldElement.al pin Sum and Count.
// BC versions: 27, 28, 29 (corpus CI)

table 80510 "LT AY Lk Master"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 80511 "LT AY Lk Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; MasterCode; Code[10]) { }
        field(3; MasterName; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT AY Lk Master".Name where(Code = field(MasterCode)));
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 80512 "LT AY Lk Port Auto"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT AY Lk Row")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(MasterCode; Rw.MasterCode) { }
                fieldelement(MasterName; Rw.MasterName) { }

                trigger OnAfterGetRecord()
                begin
                    if CalcInTrigger then
                        Rw.CalcFields(MasterName);
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Seen += 'before-insert=' + Rw.MasterName + ';';
                end;
            }
        }
    }

    var
        CalcInTrigger: Boolean;
        Seen: Text;

    procedure SetCalc(NewCalc: Boolean)
    begin
        CalcInTrigger := NewCalc;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 80513 "LT AY Lk Port NoAuto"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT AY Lk Row")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(MasterCode; Rw.MasterCode) { }
                fieldelement(MasterName; Rw.MasterName)
                {
                    AutoCalcField = false;
                }

                trigger OnAfterGetRecord()
                begin
                    if CalcInTrigger then
                        Rw.CalcFields(MasterName);
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Seen += 'before-insert=' + Rw.MasterName + ';';
                end;
            }
        }
    }

    var
        CalcInTrigger: Boolean;
        Seen: Text;

    procedure SetCalc(NewCalc: Boolean)
    begin
        CalcInTrigger := NewCalc;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

codeunit 80514 "LT AY Lk FlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        M: Record "LT AY Lk Master";
        R: Record "LT AY Lk Row";
    begin
        M.DeleteAll();
        R.DeleteAll();
        M.Code := 'A';
        M.Name := 'Alpha';
        M.Insert();
        R.Id := 1;
        R.MasterCode := 'A';
        R.Insert();
        R.Id := 2;
        R.MasterCode := 'Z';
        R.Insert();
    end;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        All: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line.Trim();
        end;
        exit(All.Replace('<?xml version="1.0" encoding="UTF-8" standalone="no"?>', '<?decl?>'));
    end;

    local procedure Export(var Observer: Codeunit "Probe Observer"; Auto: Boolean; Calc: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        XpAuto: XmlPort "LT AY Lk Port Auto";
        XpNo: XmlPort "LT AY Lk Port NoAuto";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Setup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        if Auto then begin
            XpAuto.SetCalc(Calc);
            XpAuto.SetDestination(OutS);
            Ok := XpAuto.Export();
        end else begin
            XpNo.SetCalc(Calc);
            XpNo.SetDestination(OutS);
            Ok := XpNo.Export();
        end;
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('xml', ReadAll(TempBlob));
    end;

    // ends with an error so the imported rows are rolled back; the caller observes the error text
    local procedure Import(var Observer: Codeunit "Probe Observer"; Auto: Boolean)
    var
        R: Record "LT AY Lk Row";
        TempBlob: Codeunit "Temp Blob";
        XpAuto: XmlPort "LT AY Lk Port Auto";
        XpNo: XmlPort "LT AY Lk Port NoAuto";
        OutS: OutStream;
        InS: InStream;
    begin
        Setup();
        // statement form: the value-consuming form is refused while the setup rows are uncommitted (TestXmlPortImportWriteTx.al)
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Row><Id>9</Id><MasterCode>A</MasterCode><MasterName>Typed</MasterName></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        if Auto then begin
            XpAuto.SetSource(InS);
            XpAuto.Import();
            Observer.Observe('seen', XpAuto.GetSeen());
        end else begin
            XpNo.SetSource(InS);
            XpNo.Import();
            Observer.Observe('seen', XpNo.GetSeen());
        end;
        if R.Get(9) then begin
            Observer.Observe('stored', R.MasterCode + '/' + R.MasterName);
            R.CalcFields(MasterName);
            Observer.Observe('stored_calc', R.MasterName);
        end else
            Observer.Observe('stored', '<none>');
        Error('FINISHED');
    end;

    [Test]
    procedure Export_AutoCalc_NoCalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Export(Observer, true, false);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('xml', '<?decl?><Root><Row><Id>1</Id><MasterCode>A</MasterCode><MasterName>Alpha</MasterName></Row><Row><Id>2</Id><MasterCode>Z</MasterCode><MasterName /></Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Export_AutoCalc_CalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Export(Observer, true, true);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('xml', '<?decl?><Root><Row><Id>1</Id><MasterCode>A</MasterCode><MasterName>Alpha</MasterName></Row><Row><Id>2</Id><MasterCode>Z</MasterCode><MasterName /></Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Export_NoAutoCalc_NoCalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Export(Observer, false, false);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('xml', '<?decl?><Root><Row><Id>1</Id><MasterCode>A</MasterCode><MasterName /></Row><Row><Id>2</Id><MasterCode>Z</MasterCode><MasterName /></Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Export_NoAutoCalc_CalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Export(Observer, false, true);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('xml', '<?decl?><Root><Row><Id>1</Id><MasterCode>A</MasterCode><MasterName>Alpha</MasterName></Row><Row><Id>2</Id><MasterCode>Z</MasterCode><MasterName /></Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Import(Observer, true);
        Observer.ObserveError('end');
        Observer.Expect('seen', 'before-insert=;');
        Observer.Expect('stored', 'A/');
        Observer.Expect('stored_calc', 'Alpha');
        Observer.Expect('end|text', 'FINISHED');
        Observer.Expect('end|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NoAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Import(Observer, false);
        Observer.ObserveError('end');
        Observer.Expect('seen', 'before-insert=;');
        Observer.Expect('stored', 'A/');
        Observer.Expect('stored_calc', 'Alpha');
        Observer.Expect('end|text', 'FINISHED');
        Observer.Expect('end|code', 'Dialog');
        Observer.Verify();
    end;

    // ---- writer PY-D (2026-10-20): import into Exist/Min/Max/Average/Lookup/Count FlowField elements, Xml and text formats
    // (objects in PydXmlPortFlowFieldObjects.al) ----

    local procedure PydSetup()
    var
        M: Record "LT AY Lk Master";
        R: Record "LT PYD Xp FF Row";
        D: Record "LT XpFS Detail";
    begin
        M.DeleteAll();
        R.DeleteAll();
        D.DeleteAll();
        M.Code := 'A';
        M.Name := 'Alpha';
        M.Insert();
        D.Id := 1;
        D.ParentId := 9;
        D.Amount := 4;
        D.Insert();
        D.Id := 2;
        D.ParentId := 9;
        D.Amount := 10;
        D.Insert();
    end;

    local procedure PydStored(var Observer: Codeunit "Probe Observer")
    var
        R: Record "LT PYD Xp FF Row";
    begin
        Observer.Observe('rows', Format(R.Count()));
        if R.Get(9) then begin
            Observer.Observe('stored', R.Describe());
            R.CalcFields(HasMaster, MinAmt, MaxAmt, AvgAmt, LkName, CntD);
            Observer.Observe('stored_calc', R.Describe());
        end;
    end;

    local procedure PydImportXml(var Observer: Codeunit "Probe Observer"; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT PYD Xp FF Xml";
        OutS: OutStream;
        InS: InStream;
    begin
        PydSetup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('seen', Xp.GetSeen());
        PydStored(Observer);
    end;

    [Test]
    procedure PYD_Import_Xml_ExistMinMaxAverage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydImportXml(Observer, '<Root><Row><Id>9</Id><MasterCode>A</MasterCode><HasMaster>false</HasMaster><MinAmt>1.5</MinAmt><MaxAmt>99</MaxAmt><AvgAmt>3</AvgAmt><LkName>Typed</LkName><CntD>42</CntD><Note>n</Note></Row></Root>');
        Observer.Expect('seen', 'assign Note=n;before-insert=9/A/No/0/0/0//0/n;');
        Observer.Expect('rows', '1');
        Observer.Expect('stored', '9/A/No/0/0/0//0/n');
        Observer.Expect('stored_calc', '9/A/Yes/4/10/7/Alpha/2/n');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_Import_Xml_FlowFieldValuesOfWrongType_Integer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror PydImportXml(Observer, '<Root><Row><Id>9</Id><MasterCode>A</MasterCode><HasMaster>true</HasMaster><MinAmt>1</MinAmt><MaxAmt>2</MaxAmt><AvgAmt>3</AvgAmt><LkName>Typed</LkName><CntD>many</CntD><Note>n</Note></Row></Root>');
        Observer.ObserveError('int');
        Observer.Expect('int|text', 'Imported XML cannot validate with the schema: The ''CntD'' element is invalid - The value ''many'' is invalid according to its datatype ''http://www.w3.org/2001/XMLSchema:int'' - The string ''many'' is not a valid Int32 value.');
        Observer.Expect('int|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_Import_Xml_FlowFieldValuesOfWrongType_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydImportXml(Observer, '<Root><Row><Id>9</Id><MasterCode>A</MasterCode><HasMaster>true</HasMaster><MinAmt>abc</MinAmt><MaxAmt>2</MaxAmt><AvgAmt>3</AvgAmt><LkName>Typed</LkName><CntD>1</CntD><Note>n</Note></Row></Root>');
        Observer.Expect('seen', 'assign Note=n;before-insert=9/A/No/0/0/0//0/n;');
        Observer.Expect('rows', '1');
        Observer.Expect('stored', '9/A/No/0/0/0//0/n');
        Observer.Expect('stored_calc', '9/A/Yes/4/10/7/Alpha/2/n');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_Import_Xml_FlowFieldValuesOfWrongType_Boolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PydImportXml(Observer, '<Root><Row><Id>9</Id><MasterCode>A</MasterCode><HasMaster>maybe</HasMaster><MinAmt>1</MinAmt><MaxAmt>2</MaxAmt><AvgAmt>3</AvgAmt><LkName>Typed</LkName><CntD>1</CntD><Note>n</Note></Row></Root>');
        Observer.Expect('seen', 'assign Note=n;before-insert=9/A/No/0/0/0//0/n;');
        Observer.Expect('rows', '1');
        Observer.Expect('stored', '9/A/No/0/0/0//0/n');
        Observer.Expect('stored_calc', '9/A/Yes/4/10/7/Alpha/2/n');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_Import_VariableText_FlowFields()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT PYD Xp FF VarText";
        OutS: OutStream;
        InS: InStream;
    begin
        PydSetup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('9;A;Typed;42;1.5;n');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('seen', Xp.GetSeen());
        PydStored(Observer);
        Observer.Expect('seen', 'assign Note=n;before-insert=9/A/No/0/0/0//0/n;');
        Observer.Expect('rows', '1');
        Observer.Expect('stored', '9/A/No/0/0/0//0/n');
        Observer.Expect('stored_calc', '9/A/Yes/4/10/7/Alpha/2/n');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_Import_FixedText_FlowFields()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT PYD Xp FF Fixed";
        OutS: OutStream;
        InS: InStream;
    begin
        PydSetup();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('9  A  Typed 42 nn  ');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('seen', Xp.GetSeen());
        PydStored(Observer);
        Observer.Expect('seen', 'assign Note=nn;before-insert=9/A/No/0/0/0//0/nn;');
        Observer.Expect('rows', '1');
        Observer.Expect('stored', '9/A/No/0/0/0//0/nn');
        Observer.Expect('stored_calc', '9/A/Yes/4/10/7/Alpha/2/nn');
        Observer.Verify();
    end;
}
