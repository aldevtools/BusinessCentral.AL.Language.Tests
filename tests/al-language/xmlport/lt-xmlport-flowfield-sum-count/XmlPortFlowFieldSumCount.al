// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-field-element
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 72821-72822, xmlports 72823-72826, runner 72827 (codeunit), test codeunit 72828
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: field elements bound to a Sum and a Count FlowField export the calculated value (rows with and without detail rows), as Xml and as VariableText, with and without a FlowFilter on the table view; import into a FlowField element without and with AutoSave
// BC versions: 29 (27 and 28 by CI)

table 72821 "LT XpFS Parent"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Total; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("LT XpFS Detail".Amount where(ParentId = field(Id), Seq = field("Seq Filter")));
        }
        field(4; Cnt; Integer)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count("LT XpFS Detail" where(ParentId = field(Id), Seq = field("Seq Filter")));
        }
        field(5; "Seq Filter"; Integer)
        {
            FieldClass = FlowFilter;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72822 "LT XpFS Detail"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Seq; Integer) { }
        field(4; Amount; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 72823 "LT XpFS Export Xml"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFS Parent")
            {
                fieldelement(Id; Parent.Id) { }
                fieldelement(Total; Parent.Total) { }
                fieldelement(Cnt; Parent.Cnt) { }
                fieldelement(SeqFilter; Parent."Seq Filter") { }
            }
        }
    }
}

xmlport 72824 "LT XpFS Export Text"
{
    Direction = Export;
    Format = VariableText;
    FieldSeparator = ';';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFS Parent")
            {
                fieldelement(Id; Parent.Id) { }
                fieldelement(Total; Parent.Total) { }
                fieldelement(Cnt; Parent.Cnt) { }
            }
        }
    }
}

xmlport 72825 "LT XpFS Import NoSave"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFS Parent")
            {
                AutoSave = false;

                fieldelement(Id; Parent.Id) { }
                fieldelement(Total; Parent.Total)
                {
                    trigger OnAfterAssignField()
                    begin
                        TotalSeen := Format(Parent.Total);
                    end;
                }
                fieldelement(Cnt; Parent.Cnt) { }
                fieldelement(SeqFilter; Parent."Seq Filter") { }
            }
        }
    }

    var
        TotalSeen: Text;

    procedure GetTotalSeen(): Text
    begin
        exit(TotalSeen);
    end;
}

xmlport 72826 "LT XpFS Import Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFS Parent")
            {
                AutoSave = true;

                fieldelement(Id; Parent.Id) { }
                fieldelement(Total; Parent.Total) { }
                fieldelement(Cnt; Parent.Cnt) { }
            }
        }
    }
}

codeunit 72827 "LT XpFS Runner"
{
    SingleInstance = true;

    var
        Xml: Text;

    procedure SetXml(NewXml: Text)
    begin
        Xml := NewXml;
    end;

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT XpFS Import Save", InS);
    end;
}

codeunit 72828 "LT XpFS FlowField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT XpFS Parent";
        Detail: Record "LT XpFS Detail";
    begin
        Parent.DeleteAll();
        Detail.DeleteAll();
        AddParent(1, 'with details');
        AddParent(2, 'no details');
        AddParent(3, 'one detail');
        AddDetail(1, 1, 1, 10.5);
        AddDetail(2, 1, 2, 4.25);
        AddDetail(3, 1, 2, -1);
        AddDetail(4, 3, 1, 7);
    end;

    local procedure AddParent(ParentNo: Integer; ParentName: Text[20])
    var
        Parent: Record "LT XpFS Parent";
    begin
        Parent.Id := ParentNo;
        Parent.Name := ParentName;
        Parent.Insert();
    end;

    local procedure AddDetail(DetailNo: Integer; ParentNo: Integer; SeqNo: Integer; Amt: Decimal)
    var
        Detail: Record "LT XpFS Detail";
    begin
        Detail.Id := DetailNo;
        Detail.ParentId := ParentNo;
        Detail.Seq := SeqNo;
        Detail.Amount := Amt;
        Detail.Insert();
    end;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure SetInput(var TempBlob: Codeunit "Temp Blob"; Content: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    [Test]
    procedure Export_Xml_SumAndCountFlowFields_Result()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XpFS Export Xml", OutS);
        asserterror Observer.Observe('xml', ReadAll(TempBlob));
        Observer.ObserveError('af252');
        Observer.Expect('af252|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af252|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Text_SumAndCountFlowFields_Result()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XpFS Export Text", OutS);
        Observer.Observe('text', ReadAll(TempBlob));
        Observer.Expect('text', '"1";"13.75";"3"|"2";"0.00";"0"|"3";"7.00";"1"|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Xml_FlowFilterOnView_Result()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT XpFS Export Xml";
        Parent: Record "LT XpFS Parent";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Parent.SetRange("Seq Filter", 2);
        Xp.SetTableView(Parent);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
        asserterror Observer.Observe('xml', ReadAll(TempBlob));
        Observer.ObserveError('af286');
        Observer.Expect('af286|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af286|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Xml_AfterCalcFieldsOnSource_Result()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT XpFS Export Xml";
        Parent: Record "LT XpFS Parent";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Parent.FindSet();
        repeat
            Parent.CalcFields(Total, Cnt);
            Observer.Observe('calc ' + Format(Parent.Id), Format(Parent.Total) + '/' + Format(Parent.Cnt));
        until Parent.Next() = 0;
        Xp.SetTableView(Parent);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
        asserterror Observer.Observe('xml', ReadAll(TempBlob));
        Observer.ObserveError('af310');
        Observer.Expect('calc 1', '13.75/3');
        Observer.Expect('calc 2', '0/0');
        Observer.Expect('calc 3', '7/1');
        Observer.Expect('af310|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af310|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_FlowFieldElementNoSave_Result()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT XpFS Import NoSave";
        Parent: Record "LT XpFS Parent";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Seed();
        SetInput(TempBlob, '<Root><Parent><Id>9</Id><Total>123.5</Total><Cnt>77</Cnt><SeqFilter>2</SeqFilter></Parent></Root>', InS);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('import', 'no error');
        Observer.Observe('total seen', Xp.GetTotalSeen());
        Observer.Observe('parent 9 exists', Format(Parent.Get(9)));
        Observer.Observe('parent count', Format(Parent.Count()));
        Observer.Expect('import', 'no error');
        Observer.Expect('total seen', '');
        Observer.Expect('parent 9 exists', 'No');
        Observer.Expect('parent count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_FlowFieldElementSave_Result()
    var
        Observer: Codeunit "Probe Observer";
        Runner: Codeunit "LT XpFS Runner";
        Parent: Record "LT XpFS Parent";
    begin
        Seed();
        Runner.SetXml('<Root><Parent><Id>9</Id><Total>123.5</Total><Cnt>77</Cnt></Parent></Root>');
        Runner.Run();
        Observer.Observe('import save', 'no error');
        Observer.Observe('parent count', Format(Parent.Count()));
        if Parent.Get(9) then begin
            Parent.CalcFields(Total, Cnt);
            Observer.Observe('total', Format(Parent.Total));
            Observer.Observe('cnt', Format(Parent.Cnt));
        end;
        Observer.Expect('import save', 'no error');
        Observer.Expect('parent count', '4');
        Observer.Expect('total', '0');
        Observer.Expect('cnt', '0');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): port 72823 exports UTF-16 (the default Encoding), so the UTF-8 reads of the Export_Xml_* tests fail;
    // the same exports read through a UTF-16 InStream (lines joined with |).
    local procedure ReadAllUtf16(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure Export_Xml_SumAndCountFlowFields_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XpFS Export Xml", OutS);
        Observer.Observe('len', Format(TempBlob.Length()));
        Observer.Observe('xml', ReadAllUtf16(TempBlob));
        Observer.Expect('len', '832');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Parent>|    <Id>1</Id>|    <Total>13.75</Total>|    <Cnt>3</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|  <Parent>|    <Id>2</Id>|    <Total>0.00</Total>|    <Cnt>0</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|  <Parent>|    <Id>3</Id>|    <Total>7.00</Total>|    <Cnt>1</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Xml_FlowFilterOnView_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT XpFS Export Xml";
        Parent: Record "LT XpFS Parent";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Parent.SetRange("Seq Filter", 2);
        Xp.SetTableView(Parent);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('xml', ReadAllUtf16(TempBlob));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Parent>|    <Id>1</Id>|    <Total>3.25</Total>|    <Cnt>2</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|  <Parent>|    <Id>2</Id>|    <Total>0.00</Total>|    <Cnt>0</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|  <Parent>|    <Id>3</Id>|    <Total>0.00</Total>|    <Cnt>0</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Xml_FlowFilterRangeOnView_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT XpFS Export Xml";
        Parent: Record "LT XpFS Parent";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Parent.SetFilter("Seq Filter", '1..2');
        Xp.SetTableView(Parent);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('xml', ReadAllUtf16(TempBlob));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Parent>|    <Id>1</Id>|    <Total>13.75</Total>|    <Cnt>3</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|  <Parent>|    <Id>2</Id>|    <Total>0.00</Total>|    <Cnt>0</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|  <Parent>|    <Id>3</Id>|    <Total>7.00</Total>|    <Cnt>1</Cnt>|    <SeqFilter>0</SeqFilter>|  </Parent>|</Root>|');
        Observer.Verify();
    end;
}
