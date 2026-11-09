// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatevaluate-xmlport-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects table 65200, xmlports 65201..65205, codeunit 65206
// Probe: observe-only, written to settle which text BC exports and accepts for the XmlPort field types that PWXmlPortFormatEvaluate.al does not cover.
// Facts: export and import of fields of type DateFormula, BigInteger, RecordId, Blob, Media and MediaSet as field elements and as field attributes,
//   with FormatEvaluate = Xml and FormatEvaluate = Legacy, in an XmlPort with Format = Xml and one with Format = VariableText; populated and blank
//   values; import of valid and invalid texts (error text and code).
// local object: the fields under test (DateFormula, BigInteger, RecordId, Blob, Media, MediaSet) are not on any shared fixture table.
// BC versions: 27, 28, 29

table 65200 "LT AI Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Df; DateFormula) { }
        field(3; Big; BigInteger) { }
        field(4; Rid; RecordId) { }
        field(5; Bl; Blob) { }
        field(6; Md; Media) { }
        field(7; Ms; MediaSet) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 65201 "LT AI Xml"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Df; T.Df) { MinOccurs = Zero; }
                fieldelement(Big; T.Big) { MinOccurs = Zero; }
                fieldelement(Rid; T.Rid) { MinOccurs = Zero; }
                fieldelement(Bl; T.Bl) { MinOccurs = Zero; }
                fieldelement(Md; T.Md) { MinOccurs = Zero; }
                fieldelement(Ms; T.Ms) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65202 "LT AI Legacy"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Df; T.Df) { MinOccurs = Zero; }
                fieldelement(Big; T.Big) { MinOccurs = Zero; }
                fieldelement(Rid; T.Rid) { MinOccurs = Zero; }
                fieldelement(Bl; T.Bl) { MinOccurs = Zero; }
                fieldelement(Md; T.Md) { MinOccurs = Zero; }
                fieldelement(Ms; T.Ms) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65203 "LT AI Attr Xml"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldattribute(Id; T.Id) { Occurrence = Optional; }
                fieldattribute(Df; T.Df) { Occurrence = Optional; }
                fieldattribute(Big; T.Big) { Occurrence = Optional; }
                fieldattribute(Rid; T.Rid) { Occurrence = Optional; }
            }
        }
    }
}

xmlport 65204 "LT AI VarText Xml"
{
    Format = VariableText;
    Direction = Both;
    FormatEvaluate = Xml;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Df; T.Df) { }
                fieldelement(Big; T.Big) { }
                fieldelement(Rid; T.Rid) { }
                fieldelement(Bl; T.Bl) { }
            }
        }
    }
}

xmlport 65205 "LT AI VarText Legacy"
{
    Format = VariableText;
    Direction = Both;
    FormatEvaluate = Legacy;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Df; T.Df) { }
                fieldelement(Big; T.Big) { }
                fieldelement(Rid; T.Rid) { }
                fieldelement(Bl; T.Bl) { }
            }
        }
    }
}

codeunit 65206 "LT AI XmlPort Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure FillPopulated(var Row: Record "LT AI Table")
    var
        OutStr: OutStream;
    begin
        Row.Init();
        Row.Id := 1;
        Evaluate(Row.Df, '<CM+1D>');
        Row.Big := 9223372036854775807L;
        Row.Rid := Row.RecordId();
        Row.Bl.CreateOutStream(OutStr);
        OutStr.WriteText('blob text');
        Row.Insert();
    end;

    local procedure FillBlank(var Row: Record "LT AI Table")
    begin
        Row.Init();
        Row.Id := 2;
        Row.Insert();
    end;

    local procedure ExportText(XmlPortId: Integer; Populated: Boolean; Blank: Boolean): Text
    var
        Row: Record "LT AI Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Row.DeleteAll();
        if Populated then
            FillPopulated(Row);
        if Blank then
            FillBlank(Row);
        Commit();
        TempBlob.CreateOutStream(OutStr);
        ClearLastError();
        if not TryExport(XmlPortId, OutStr) then
            exit('export failed: [' + GetLastErrorText() + '] code [' + GetLastErrorCode() + ']');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        if Result = '' then
            exit('<empty>');
        exit(Result);
    end;

    [TryFunction]
    local procedure TryExport(XmlPortId: Integer; var OutStr: OutStream)
    begin
        Xmlport.Export(XmlPortId, OutStr);
    end;

    local procedure ReadBlob(var Row: Record "LT AI Table"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Row.CalcFields(Bl);
        if not Row.Bl.HasValue() then
            exit('');
        Row.Bl.CreateInStream(InStr);
        InStr.ReadText(Result);
        exit(Result);
    end;

    local procedure ImportText(XmlPortId: Integer; Content: Text; Name: Text)
    var
        Row: Record "LT AI Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Imported: Boolean;
        Stored: Text;
    begin
        Row.DeleteAll();
        Commit();
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        ClearLastError();
        Imported := TryImport(XmlPortId, InStr);
        if Row.Get(1) then
            Stored := StrSubstNo('Df=%1 Big=%2 Rid=%3 Bl=%4 Md=%5 Ms=%6', Format(Row.Df), Row.Big, Format(Row.Rid), ReadBlob(Row), Row.Md.HasValue(), Row.Ms.Count())
        else
            Stored := 'no row';
        Observer.Observe(Name, StrSubstNo('imported=%1 error=[%2] code=[%3] stored=[%4]', Imported, GetLastErrorText(), GetLastErrorCode(), Stored));
        Commit();
    end;

    [TryFunction]
    local procedure TryImport(XmlPortId: Integer; var InStr: InStream)
    begin
        Xmlport.Import(XmlPortId, InStr);
    end;

    local procedure XmlOne(Element: Text; Value: Text): Text
    begin
        exit('<?xml version="1.0" encoding="utf-8"?><Root><T><Id>1</Id><' + Element + '>' + Value + '</' + Element + '></T></Root>');
    end;

    local procedure XmlAttr(AttrName: Text; Value: Text): Text
    begin
        exit('<?xml version="1.0" encoding="utf-8"?><Root><T Id="1" ' + AttrName + '="' + Value + '" /></Root>');
    end;

    [Test]
    procedure Export_Xml_PopulatedRow()
    begin
        Observer.Observe('export_xml_populated', ExportText(Xmlport::"LT AI Xml", true, false));
        Observer.Finish();
    end;

    [Test]
    procedure Export_Xml_BlankRow()
    begin
        Observer.Observe('export_xml_blank', ExportText(Xmlport::"LT AI Xml", false, true));
        Observer.Finish();
    end;

    [Test]
    procedure Export_Legacy_PopulatedAndBlankRow()
    begin
        Observer.Observe('export_legacy_populated', ExportText(Xmlport::"LT AI Legacy", true, false));
        Observer.Observe('export_legacy_blank', ExportText(Xmlport::"LT AI Legacy", false, true));
        Observer.Finish();
    end;

    [Test]
    procedure Export_Attributes_Xml_PopulatedAndBlankRow()
    begin
        Observer.Observe('export_attr_populated', ExportText(Xmlport::"LT AI Attr Xml", true, false));
        Observer.Observe('export_attr_blank', ExportText(Xmlport::"LT AI Attr Xml", false, true));
        Observer.Finish();
    end;

    [Test]
    procedure Export_VariableText_XmlAndLegacy()
    begin
        Observer.Observe('export_vt_xml_populated', ExportText(Xmlport::"LT AI VarText Xml", true, false));
        Observer.Observe('export_vt_xml_blank', ExportText(Xmlport::"LT AI VarText Xml", false, true));
        Observer.Observe('export_vt_legacy_populated', ExportText(Xmlport::"LT AI VarText Legacy", true, false));
        Observer.Observe('export_vt_legacy_blank', ExportText(Xmlport::"LT AI VarText Legacy", false, true));
        Observer.Finish();
    end;

    [Test]
    procedure Import_Xml_DateFormula()
    begin
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', '<1D>'), 'df_1d');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', '<CM+1D>'), 'df_cm_plus_1d');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', '<-1W>'), 'df_minus_1w');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', '1D'), 'df_no_brackets');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', '<1T>'), 'df_localized_german');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', ''), 'df_blank');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Df', 'garbage'), 'df_garbage');
        Observer.Finish();
    end;

    [Test]
    procedure Import_Legacy_DateFormula()
    begin
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Df', '<1D>'), 'df_1d');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Df', '<CM+1D>'), 'df_cm_plus_1d');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Df', '<-1W>'), 'df_minus_1w');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Df', '<1T>'), 'df_localized_german');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Df', ''), 'df_blank');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Df', 'garbage'), 'df_garbage');
        Observer.Finish();
    end;

    [Test]
    procedure Import_Xml_BigInteger()
    begin
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', '-9223372036854775808'), 'big_min');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', '0'), 'big_zero');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', '9223372036854775807'), 'big_max');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', '9223372036854775808'), 'big_overflow');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', '1,234'), 'big_thousands');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', '12.5'), 'big_decimal');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', 'abc'), 'big_text');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Big', ''), 'big_blank');
        Observer.Finish();
    end;

    [Test]
    procedure Import_Legacy_BigInteger()
    begin
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Big', '-9223372036854775808'), 'big_min');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Big', '9223372036854775807'), 'big_max');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Big', '1,234'), 'big_thousands');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Big', 'abc'), 'big_text');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Big', ''), 'big_blank');
        Observer.Finish();
    end;

    [Test]
    procedure Import_Xml_RecordId()
    begin
        ImportText(Xmlport::"LT AI Xml", XmlOne('Rid', 'LT AI Table: 1'), 'rid_display');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Rid', 'Table65200: 1'), 'rid_table_id');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Rid', '65200: 1'), 'rid_number');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Rid', ''), 'rid_blank');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Rid', 'garbage'), 'rid_garbage');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Rid', 'LT AI Table: 1'), 'rid_legacy_display');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Rid', 'garbage'), 'rid_legacy_garbage');
        Observer.Finish();
    end;

    [Test]
    procedure Import_Xml_Blob_MediaAndMediaSet()
    begin
        ImportText(Xmlport::"LT AI Xml", XmlOne('Bl', 'YmxvYiB0ZXh0'), 'blob_base64');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Bl', 'blob text'), 'blob_plain');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Bl', ''), 'blob_blank');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Md', ''), 'media_blank');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Md', '00000000-0000-0000-0000-000000000000'), 'media_empty_guid');
        ImportText(Xmlport::"LT AI Xml", XmlOne('Ms', ''), 'mediaset_blank');
        ImportText(Xmlport::"LT AI Legacy", XmlOne('Bl', 'YmxvYiB0ZXh0'), 'blob_legacy_base64');
        Observer.Finish();
    end;

    [Test]
    procedure Import_Attributes_Xml_DateFormulaBigIntegerRecordId()
    begin
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Df', '<CM+1D>'), 'attr_df');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Df', 'garbage'), 'attr_df_garbage');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Big', '-5'), 'attr_big');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Big', 'abc'), 'attr_big_text');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Rid', 'LT AI Table: 1'), 'attr_rid');
        Observer.Finish();
    end;

    [Test]
    procedure Import_VariableText_XmlAndLegacy()
    begin
        ImportText(Xmlport::"LT AI VarText Xml", '1,<CM+1D>,-5,LT AI Table: 1,YmxvYiB0ZXh0', 'vt_xml');
        ImportText(Xmlport::"LT AI VarText Xml", '1,garbage,-5,LT AI Table: 1,', 'vt_xml_bad_df');
        ImportText(Xmlport::"LT AI VarText Xml", '1,<1D>,abc,LT AI Table: 1,', 'vt_xml_bad_big');
        ImportText(Xmlport::"LT AI VarText Legacy", '1,<CM+1D>,-5,LT AI Table: 1,YmxvYiB0ZXh0', 'vt_legacy');
        ImportText(Xmlport::"LT AI VarText Legacy", '1,garbage,-5,LT AI Table: 1,', 'vt_legacy_bad_df');
        Observer.Finish();
    end;
}
