// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatevaluate-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 75140, table 75141, xmlports 75142-75145, test codeunit 75146.
// local object: the enum's captions (different from the names, a name with a space, a member without a caption), the Option field's
//   captions and the ports' schemas are what is under test.
// Probe (observe only): al-runner issue 7781. An XmlPort exports a table with an Enum field and an Option field, then the same file is
//   imported again into the emptied table (the round trip of Microsoft's Master Data Management tests). Ports:
//     Legacy Attr   Format = Xml, FormatEvaluate not set (Legacy), field attributes (the reported shape)
//     Legacy Elem   Format = Xml, FormatEvaluate not set, field elements
//     Xml Attr      Format = Xml, FormatEvaluate = Xml, field attributes
//     VarText       Format = VariableText, field elements
//   Each test records the exported text (lines joined with |), the import result, and each stored row as name, enum ordinal and option
//   ordinal. PWXmlPortFormatEvaluate.al pins the export of one-word captions (Legacy writes the caption, FormatEvaluate = Xml the
//   ordinal) and the import of a member name, ordinal and caption under FormatEvaluate = Xml.
// BC versions: 27, 28, 29 (corpus CI)

enum 75140 "XP EOR Direction"
{
    // local object: captions that differ from the names, with spaces, and one member without a caption.
    Extensible = true;

    value(0; Both) { Caption = 'Both ways'; }
    value(1; ToTarget) { Caption = 'Send data update to target'; }
    value(2; FromTarget) { Caption = 'Get data update from target'; }
    value(3; "With Space") { Caption = 'With Space cap'; }
    value(4; NoCaption) { }
}

table 75141 "XP EOR Mapping"
{
    // local object: an Enum field and an Option field with captions that differ from the member names.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Code[20]) { }
        field(2; Direction; Enum "XP EOR Direction") { }
        field(3; Opt; Option)
        {
            OptionMembers = Both,ToTarget,FromTarget,"With Space";
            OptionCaption = 'Both ways,Send data update to target,Get data update from target,With Space cap';
        }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

xmlport 75142 "XP EOR Legacy Attr"
{
    // local object: the reported schema (Xml, Legacy FormatEvaluate, field attributes) is under test.
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Mapping; "XP EOR Mapping")
            {
                fieldattribute(Name; Mapping.Name) { }
                fieldattribute(Direction; Mapping.Direction) { }
                fieldattribute(Opt; Mapping.Opt) { }
            }
        }
    }
}

xmlport 75143 "XP EOR Legacy Elem"
{
    // local object: Xml, Legacy FormatEvaluate, field elements.
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Mapping; "XP EOR Mapping")
            {
                fieldelement(Name; Mapping.Name) { }
                fieldelement(Direction; Mapping.Direction) { }
                fieldelement(Opt; Mapping.Opt) { }
            }
        }
    }
}

xmlport 75144 "XP EOR Xml Attr"
{
    // local object: Xml, FormatEvaluate = Xml, field attributes.
    Direction = Both;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Mapping; "XP EOR Mapping")
            {
                fieldattribute(Name; Mapping.Name) { }
                fieldattribute(Direction; Mapping.Direction) { }
                fieldattribute(Opt; Mapping.Opt) { }
            }
        }
    }
}

xmlport 75145 "XP EOR VarText"
{
    // local object: VariableText, field elements.
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Mapping; "XP EOR Mapping")
            {
                fieldelement(Name; Mapping.Name) { }
                fieldelement(Direction; Mapping.Direction) { }
                fieldelement(Opt; Mapping.Opt) { }
            }
        }
    }
}

codeunit 75146 "XP EOR Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "XP EOR Mapping";
    begin
        Row.DeleteAll();
        AddRow('A', "XP EOR Direction"::Both, 0);
        AddRow('B', "XP EOR Direction"::ToTarget, 1);
        AddRow('C', "XP EOR Direction"::FromTarget, 2);
        AddRow('D', "XP EOR Direction"::"With Space", 3);
        AddRow('E', "XP EOR Direction"::NoCaption, 0);
        Commit();
    end;

    local procedure AddRow(Name: Code[20]; Dir: Enum "XP EOR Direction"; Opt: Integer)
    var
        Row: Record "XP EOR Mapping";
    begin
        Row.Name := Name;
        Row.Direction := Dir;
        Row.Opt := Opt;
        Row.Insert();
    end;

    local procedure Rows(): Text
    var
        Row: Record "XP EOR Mapping";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row.Name + '/' + Format(Row.Direction.AsInteger()) + '/' + Format(Row.Opt, 0, 2) + ';';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ':' + Result);
    end;

    local procedure ReadAll(var InS: InStream): Text
    var
        Part: Text;
        Result: Text;
    begin
        while not InS.EOS() do begin
            InS.ReadText(Part);
            if Result <> '' then
                Result += '|';
            Result += Part;
        end;
        exit(Result);
    end;

    // Exports every row through port XpId, empties the table, imports the exported file through the same port.
    local procedure RoundTrip(XpId: Integer; Enc: TextEncoding)
    var
        Row: Record "XP EOR Mapping";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XpId, OutS);
        TempBlob.CreateInStream(InS, Enc);
        Observer.Observe('exported', ReadAll(InS));
        Row.DeleteAll();
        Commit();
        TempBlob.CreateInStream(InS);
        if Xmlport.Import(XpId, InS) then
            Observer.Observe('import', 'true')
        else begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end;
        Observer.Observe('rows after import', Rows());
    end;

    [Test]
    procedure EOR_LegacyAttr_RoundTrip()
    begin
        RoundTrip(Xmlport::"XP EOR Legacy Attr", TextEncoding::UTF16);
        Observer.Finish();
    end;

    [Test]
    procedure EOR_LegacyElem_RoundTrip()
    begin
        RoundTrip(Xmlport::"XP EOR Legacy Elem", TextEncoding::UTF16);
        Observer.Finish();
    end;

    [Test]
    procedure EOR_XmlAttr_RoundTrip()
    begin
        RoundTrip(Xmlport::"XP EOR Xml Attr", TextEncoding::UTF16);
        Observer.Finish();
    end;

    [Test]
    procedure EOR_VarText_RoundTrip()
    begin
        RoundTrip(Xmlport::"XP EOR VarText", TextEncoding::MSDos);
        Observer.Finish();
    end;
}
