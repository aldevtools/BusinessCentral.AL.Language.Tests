// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatevaluate-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68460, xmlports 68461 and 68462,
//                codeunit 68463
// Probe: written against a real BC 27.5 service tier on Linux (en-US); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins FormatEvaluate on an XML xmlport with Integer, Date, Decimal, Boolean and DateTime fields:
//  - Legacy writes the display text of each value (03/05/24, 1,234.50, Yes, a DateTime without seconds), Xml
//    writes the XML forms (2024-03-05, 1234.50, true, 2024-03-05T12:34:56Z, seconds kept);
//  - an import reads only its own form: the Xml port takes the XML forms and refuses the display text
//    ("The format of the Date '03/05/24' does not match your device's date settings. ..."), the Legacy port takes
//    the display text and refuses the XML date ("The date is not valid."); neither stores a row then.
// BC versions: 27.5

table 68460 "Probe FmtEval Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dec; Decimal) { }
        field(4; Bl; Boolean) { }
        field(5; Dtm; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 68461 "Probe FmtEval Legacy"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "Probe FmtEval Table")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Dt; T.Dt) { }
                fieldelement(Dec; T.Dec) { }
                fieldelement(Bl; T.Bl) { }
                fieldelement(Dtm; T.Dtm) { }
            }
        }
    }
}

xmlport 68462 "Probe FmtEval Xml"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "Probe FmtEval Table")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Dt; T.Dt) { }
                fieldelement(Dec; T.Dec) { }
                fieldelement(Bl; T.Bl) { }
                fieldelement(Dtm; T.Dtm) { }
            }
        }
    }
}

codeunit 68463 "Probe XmlPort FormatEvaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        FmtRec: Record "Probe FmtEval Table";
    begin
        FmtRec.DeleteAll();
        FmtRec.Id := 1;
        FmtRec.Dt := DMY2Date(5, 3, 2024);
        FmtRec.Dec := 1234.5;
        FmtRec.Bl := true;
        FmtRec.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), 123456T);
        FmtRec.Insert();
        Commit();
    end;

    local procedure ExportText(XmlPortId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(XmlPortId, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure ImportText(XmlPortId: Integer; Content: Text; var Imported: Boolean; var ErrorText: Text; var Row: Record "Probe FmtEval Table")
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        Row.DeleteAll();
        Commit();
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        ClearLastError();
        Imported := Xmlport.Import(XmlPortId, InStr);
        ErrorText := GetLastErrorText();
        Commit();
    end;

    [Test]
    procedure Export_Legacy_WritesTheDisplayText()
    begin
        Seed();

        Assert.AreEqual(
            '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Dt>03/05/24</Dt>|    <Dec>1,234.50</Dec>|    <Bl>Yes</Bl>|    <Dtm>03/05/24 12:34 PM</Dtm>|  </T>|</Root>|',
            ExportText(Xmlport::"Probe FmtEval Legacy"), 'legacy export');
    end;

    [Test]
    procedure Export_Xml_WritesTheXmlForms()
    begin
        Seed();

        Assert.AreEqual(
            '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Dt>2024-03-05</Dt>|    <Dec>1234.50</Dec>|    <Bl>true</Bl>|    <Dtm>2024-03-05T12:34:56Z</Dtm>|  </T>|</Root>|',
            ExportText(Xmlport::"Probe FmtEval Xml"), 'xml export');
    end;

    [Test]
    procedure Import_XmlPort_TakesTheXmlForms_AndRefusesTheDisplayText()
    var
        Row: Record "Probe FmtEval Table";
        Imported: Boolean;
        ErrorText: Text;
    begin
        ImportText(Xmlport::"Probe FmtEval Xml", '<Root><T><Id>1</Id><Dt>2024-03-05</Dt><Dec>1234.5</Dec><Bl>true</Bl><Dtm>2024-03-05T12:34:56</Dtm></T></Root>', Imported, ErrorText, Row);
        Assert.IsTrue(Imported, 'xml forms');
        Row.FindFirst();
        Assert.AreEqual('2024-03-05', Format(Row.Dt, 0, 9), 'date');
        Assert.AreEqual('1234.5', Format(Row.Dec, 0, 9), 'decimal');
        Assert.AreEqual('true', Format(Row.Bl, 0, 9), 'boolean');
        Assert.AreEqual('2024-03-05T12:34:56Z', Format(Row.Dtm, 0, 9), 'datetime');

        ImportText(Xmlport::"Probe FmtEval Xml", '<Root><T><Id>1</Id><Dt>03/05/24</Dt><Dec>1,234.5</Dec><Bl>Yes</Bl><Dtm>03/05/24 12:34:56 PM</Dtm></T></Root>', Imported, ErrorText, Row);
        Assert.IsFalse(Imported, 'display text');
        Assert.IsTrue(ErrorText.StartsWith('The format of the Date ''03/05/24'' does not match your device''s date settings.'), 'error text');
        Assert.IsTrue(Row.IsEmpty(), 'no row');
    end;

    [Test]
    procedure Import_LegacyXmlPort_TakesTheDisplayText_AndRefusesTheXmlDate()
    var
        Row: Record "Probe FmtEval Table";
        Imported: Boolean;
        ErrorText: Text;
    begin
        ImportText(Xmlport::"Probe FmtEval Legacy", '<Root><T><Id>1</Id><Dt>03/05/24</Dt><Dec>1,234.5</Dec><Bl>Yes</Bl><Dtm>03/05/24 12:34:56 PM</Dtm></T></Root>', Imported, ErrorText, Row);
        Assert.IsTrue(Imported, 'display text');
        Row.FindFirst();
        Assert.AreEqual('2024-03-05', Format(Row.Dt, 0, 9), 'date');
        Assert.AreEqual('1234.5', Format(Row.Dec, 0, 9), 'decimal');
        Assert.AreEqual('true', Format(Row.Bl, 0, 9), 'boolean');
        Assert.AreEqual('2024-03-05T12:34:56Z', Format(Row.Dtm, 0, 9), 'datetime');

        ImportText(Xmlport::"Probe FmtEval Legacy", '<Root><T><Id>1</Id><Dt>2024-03-05</Dt><Dec>1234.5</Dec><Bl>true</Bl><Dtm>2024-03-05T12:34:56</Dtm></T></Root>', Imported, ErrorText, Row);
        Assert.IsFalse(Imported, 'xml forms');
        Assert.AreEqual('The date is not valid.', ErrorText, 'error text');
        Assert.IsTrue(Row.IsEmpty(), 'no row');
    end;
}
