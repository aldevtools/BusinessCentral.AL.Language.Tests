// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatevaluate-xmlport-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects table 65200, xmlports 65201..65220, codeunit 65221
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

xmlport 65207 "LT AI Imp Df Xml"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Df; T.Df) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65208 "LT AI Imp Df Legacy"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Df; T.Df) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65209 "LT AI Imp Big Xml"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Big; T.Big) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65210 "LT AI Imp Big Legacy"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Big; T.Big) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65211 "LT AI Imp Rid Xml"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Rid; T.Rid) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65212 "LT AI Imp Rid Legacy"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Rid; T.Rid) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65213 "LT AI Imp Blob Xml"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Bl; T.Bl) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65214 "LT AI Imp Blob Legacy"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Bl; T.Bl) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65215 "LT AI Imp Media Xml"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Md; T.Md) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65216 "LT AI Imp MediaSet Xml"
{
    Format = Xml;
    Direction = Import;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Ms; T.Ms) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 65217 "LT AI VT Imp Df Big Xml"
{
    Format = VariableText;
    Direction = Import;
    FormatEvaluate = Xml;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) {  }
                fieldelement(Df; T.Df) {  }
                fieldelement(Big; T.Big) {  }
            }
        }
    }
}

xmlport 65218 "LT AI VT Imp Df Big Legacy"
{
    Format = VariableText;
    Direction = Import;
    FormatEvaluate = Legacy;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) {  }
                fieldelement(Df; T.Df) {  }
                fieldelement(Big; T.Big) {  }
            }
        }
    }
}

xmlport 65219 "LT AI VT Imp Rid Xml"
{
    Format = VariableText;
    Direction = Import;
    FormatEvaluate = Xml;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) {  }
                fieldelement(Rid; T.Rid) {  }
            }
        }
    }
}

xmlport 65220 "LT AI VT Imp Blob Xml"
{
    Format = VariableText;
    Direction = Import;
    FormatEvaluate = Xml;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT AI Table")
            {
                fieldelement(Id; T.Id) {  }
                fieldelement(Bl; T.Bl) {  }
            }
        }
    }
}

codeunit 65221 "LT AI XmlPort Types"
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

    local procedure ExportText(XmlPortId: Integer; Populated: Boolean; Blank: Boolean; Encoding: TextEncoding): Text
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
        TempBlob.CreateInStream(InStr, Encoding);
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
        exit('<?xml version="1.0" encoding="utf-8"?><Root><T><Id>1</Id><' + Element + '>' + Value.Replace('<', '&lt;').Replace('>', '&gt;') + '</' + Element + '></T></Root>');
    end;

    local procedure XmlAttr(AttrName: Text; Value: Text): Text
    begin
        exit('<?xml version="1.0" encoding="utf-8"?><Root><T Id="1" ' + AttrName + '="' + Value + '" /></Root>');
    end;

    [Test]
    procedure Export_Xml_PopulatedRow()
    begin
        Observer.Observe('export_xml_populated', ExportText(Xmlport::"LT AI Xml", true, false, TextEncoding::UTF16));
        Observer.Expect('export_xml_populated', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Df>CM+1D</Df>|    <Big>9223372036854775807</Big>|    <Rid>LT AI Table: 1</Rid>|    <Bl>*</Bl>|    <Md>{00000000-0000-0000-0000-000000000000}</Md>|    <Ms>{00000000-0000-0000-0000-000000000000}</Ms>|  </T>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Xml_BlankRow()
    begin
        Observer.Observe('export_xml_blank', ExportText(Xmlport::"LT AI Xml", false, true, TextEncoding::UTF16));
        Observer.Expect('export_xml_blank', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>2</Id>|    <Df />|    <Big>0</Big>|    <Rid />|    <Bl> </Bl>|    <Md>{00000000-0000-0000-0000-000000000000}</Md>|    <Ms>{00000000-0000-0000-0000-000000000000}</Ms>|  </T>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Legacy_PopulatedAndBlankRow()
    begin
        Observer.Observe('export_legacy_populated', ExportText(Xmlport::"LT AI Legacy", true, false, TextEncoding::UTF16));
        Observer.Observe('export_legacy_blank', ExportText(Xmlport::"LT AI Legacy", false, true, TextEncoding::UTF16));
        Observer.Expect('export_legacy_populated', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Df>CM+1D</Df>|    <Big>9223372036854775807</Big>|    <Rid>LT AI Table: 1</Rid>|    <Bl>*</Bl>|    <Md>{00000000-0000-0000-0000-000000000000}</Md>|    <Ms>{00000000-0000-0000-0000-000000000000}</Ms>|  </T>|</Root>|');
        Observer.Expect('export_legacy_blank', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>2</Id>|    <Df />|    <Big>0</Big>|    <Rid />|    <Bl> </Bl>|    <Md>{00000000-0000-0000-0000-000000000000}</Md>|    <Ms>{00000000-0000-0000-0000-000000000000}</Ms>|  </T>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Attributes_Xml_PopulatedAndBlankRow()
    begin
        Observer.Observe('export_attr_populated', ExportText(Xmlport::"LT AI Attr Xml", true, false, TextEncoding::UTF16));
        Observer.Observe('export_attr_blank', ExportText(Xmlport::"LT AI Attr Xml", false, true, TextEncoding::UTF16));
        Observer.Expect('export_attr_populated', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T Id="1" Df="CM+1D" Big="9223372036854775807" Rid="LT AI Table: 1" />|</Root>|');
        Observer.Expect('export_attr_blank', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T Id="2" Big="0" />|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_VariableText_XmlAndLegacy()
    begin
        Observer.Observe('export_vt_xml_populated', ExportText(Xmlport::"LT AI VarText Xml", true, false, TextEncoding::UTF8));
        Observer.Observe('export_vt_xml_blank', ExportText(Xmlport::"LT AI VarText Xml", false, true, TextEncoding::UTF8));
        Observer.Observe('export_vt_legacy_populated', ExportText(Xmlport::"LT AI VarText Legacy", true, false, TextEncoding::UTF8));
        Observer.Observe('export_vt_legacy_blank', ExportText(Xmlport::"LT AI VarText Legacy", false, true, TextEncoding::UTF8));
        Observer.Expect('export_vt_xml_populated', '"1","CM+1D","9223372036854775807","LT AI Table: 1","*"|');
        Observer.Expect('export_vt_xml_blank', '"2","","0",""," "|');
        Observer.Expect('export_vt_legacy_populated', '"1","CM+1D","9223372036854775807","LT AI Table: 1","*"|');
        Observer.Expect('export_vt_legacy_blank', '"2","","0",""," "|');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_DateFormula()
    begin
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', '<1D>'), 'df_1d');
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', '<CM+1D>'), 'df_cm_plus_1d');
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', '<-1W>'), 'df_minus_1w');
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', '1D'), 'df_no_brackets');
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', '<1T>'), 'df_localized_german');
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', ''), 'df_blank');
        ImportText(Xmlport::"LT AI Imp Df Xml", XmlOne('Df', 'garbage'), 'df_garbage');
        Observer.Expect('df_1d', 'imported=Yes error=[] code=[] stored=[Df=1D Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_cm_plus_1d', 'imported=Yes error=[] code=[] stored=[Df=CM+1D Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_minus_1w', 'imported=Yes error=[] code=[] stored=[Df=-1W Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_no_brackets', 'imported=Yes error=[] code=[] stored=[Df=1D Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_localized_german', 'imported=No error=[The date formula ''1T'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Expect('df_blank', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_garbage', 'imported=No error=[The date formula ''GARBAGE'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Legacy_DateFormula()
    begin
        ImportText(Xmlport::"LT AI Imp Df Legacy", XmlOne('Df', '<1D>'), 'df_1d');
        ImportText(Xmlport::"LT AI Imp Df Legacy", XmlOne('Df', '<CM+1D>'), 'df_cm_plus_1d');
        ImportText(Xmlport::"LT AI Imp Df Legacy", XmlOne('Df', '<-1W>'), 'df_minus_1w');
        ImportText(Xmlport::"LT AI Imp Df Legacy", XmlOne('Df', '<1T>'), 'df_localized_german');
        ImportText(Xmlport::"LT AI Imp Df Legacy", XmlOne('Df', ''), 'df_blank');
        ImportText(Xmlport::"LT AI Imp Df Legacy", XmlOne('Df', 'garbage'), 'df_garbage');
        Observer.Expect('df_1d', 'imported=Yes error=[] code=[] stored=[Df=1D Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_cm_plus_1d', 'imported=Yes error=[] code=[] stored=[Df=CM+1D Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_minus_1w', 'imported=Yes error=[] code=[] stored=[Df=-1W Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_localized_german', 'imported=No error=[The date formula ''1T'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Expect('df_blank', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('df_garbage', 'imported=No error=[The date formula ''GARBAGE'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_BigInteger()
    begin
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', '-9223372036854775808'), 'big_min');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', '0'), 'big_zero');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', '9223372036854775807'), 'big_max');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', '9223372036854775808'), 'big_overflow');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', '1,234'), 'big_thousands');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', '12.5'), 'big_decimal');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', 'abc'), 'big_text');
        ImportText(Xmlport::"LT AI Imp Big Xml", XmlOne('Big', ''), 'big_blank');
        Observer.Expect('big_min', 'imported=Yes error=[] code=[] stored=[Df= Big=-9223372036854775808 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('big_zero', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('big_max', 'imported=Yes error=[] code=[] stored=[Df= Big=9223372036854775807 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('big_overflow', 'imported=No error=[The value "9223372036854775808" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('big_thousands', 'imported=No error=[The value "1,234" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('big_decimal', 'imported=No error=[The value "12.5" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('big_text', 'imported=No error=[The value "abc" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('big_blank', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Legacy_BigInteger()
    begin
        ImportText(Xmlport::"LT AI Imp Big Legacy", XmlOne('Big', '-9223372036854775808'), 'big_min');
        ImportText(Xmlport::"LT AI Imp Big Legacy", XmlOne('Big', '9223372036854775807'), 'big_max');
        ImportText(Xmlport::"LT AI Imp Big Legacy", XmlOne('Big', '1,234'), 'big_thousands');
        ImportText(Xmlport::"LT AI Imp Big Legacy", XmlOne('Big', 'abc'), 'big_text');
        ImportText(Xmlport::"LT AI Imp Big Legacy", XmlOne('Big', ''), 'big_blank');
        Observer.Expect('big_min', 'imported=Yes error=[] code=[] stored=[Df= Big=-9223372036854775808 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('big_max', 'imported=Yes error=[] code=[] stored=[Df= Big=9223372036854775807 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('big_thousands', 'imported=No error=[Imported XML cannot validate with the schema: The ''Big'' element is invalid - The value ''1,234'' is invalid according to its datatype ''http://www.w3.org/2001/XMLSchema:long'' - The string ''1,234'' is not a valid Int64 value.] code=[XmlPortInvalidXml] stored=[no row]');
        Observer.Expect('big_text', 'imported=No error=[The value "abc" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('big_blank', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_RecordId()
    begin
        ImportText(Xmlport::"LT AI Imp Rid Xml", XmlOne('Rid', 'LT AI Table: 1'), 'rid_display');
        ImportText(Xmlport::"LT AI Imp Rid Xml", XmlOne('Rid', 'Table65200: 1'), 'rid_table_id');
        ImportText(Xmlport::"LT AI Imp Rid Xml", XmlOne('Rid', '65200: 1'), 'rid_number');
        ImportText(Xmlport::"LT AI Imp Rid Xml", XmlOne('Rid', ''), 'rid_blank');
        ImportText(Xmlport::"LT AI Imp Rid Xml", XmlOne('Rid', 'garbage'), 'rid_garbage');
        ImportText(Xmlport::"LT AI Imp Rid Legacy", XmlOne('Rid', 'LT AI Table: 1'), 'rid_legacy_display');
        ImportText(Xmlport::"LT AI Imp Rid Legacy", XmlOne('Rid', 'garbage'), 'rid_legacy_garbage');
        Observer.Expect('rid_display', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid=LT AI Table: 1 Bl= Md=No Ms=0]');
        Observer.Expect('rid_table_id', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid=LT AI Table: 1 Bl= Md=No Ms=0]');
        Observer.Expect('rid_number', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid=LT AI Table: 1 Bl= Md=No Ms=0]');
        Observer.Expect('rid_blank', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('rid_garbage', 'imported=No error=[The value "garbage" can''t be evaluated into type RecordID.] code=[Evaluate] stored=[no row]');
        Observer.Expect('rid_legacy_display', 'imported=No error=[The type RecordID is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('rid_legacy_garbage', 'imported=No error=[The type RecordID is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_Blob_MediaAndMediaSet()
    begin
        ImportText(Xmlport::"LT AI Imp Blob Xml", XmlOne('Bl', 'YmxvYiB0ZXh0'), 'blob_base64');
        ImportText(Xmlport::"LT AI Imp Blob Xml", XmlOne('Bl', 'blob text'), 'blob_plain');
        ImportText(Xmlport::"LT AI Imp Blob Xml", XmlOne('Bl', ''), 'blob_blank');
        ImportText(Xmlport::"LT AI Imp Media Xml", XmlOne('Md', ''), 'media_blank');
        ImportText(Xmlport::"LT AI Imp Media Xml", XmlOne('Md', '00000000-0000-0000-0000-000000000000'), 'media_empty_guid');
        ImportText(Xmlport::"LT AI Imp MediaSet Xml", XmlOne('Ms', ''), 'mediaset_blank');
        ImportText(Xmlport::"LT AI Imp Blob Legacy", XmlOne('Bl', 'YmxvYiB0ZXh0'), 'blob_legacy_base64');
        Observer.Expect('blob_base64', 'imported=No error=[The type BLOB is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('blob_plain', 'imported=No error=[The type BLOB is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('blob_blank', 'imported=No error=[The type BLOB is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('media_blank', 'imported=No error=[The type Media is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('media_empty_guid', 'imported=No error=[The type Media is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('mediaset_blank', 'imported=No error=[The type MediaSet is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Expect('blob_legacy_base64', 'imported=No error=[The type BLOB is not supported.] code=[NotSupportedType] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Attributes_Xml_DateFormulaBigIntegerRecordId()
    begin
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Df', '&lt;CM+1D&gt;'), 'attr_df');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Df', 'garbage'), 'attr_df_garbage');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Big', '-5'), 'attr_big');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Big', 'abc'), 'attr_big_text');
        ImportText(Xmlport::"LT AI Attr Xml", XmlAttr('Rid', 'LT AI Table: 1'), 'attr_rid');
        Observer.Expect('attr_df', 'imported=Yes error=[] code=[] stored=[Df=CM+1D Big=0 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('attr_df_garbage', 'imported=No error=[The date formula ''GARBAGE'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Expect('attr_big', 'imported=Yes error=[] code=[] stored=[Df= Big=-5 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('attr_big_text', 'imported=No error=[The value "abc" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('attr_rid', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid=LT AI Table: 1 Bl= Md=No Ms=0]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_VariableText_XmlAndLegacy()
    begin
        ImportText(Xmlport::"LT AI VT Imp Df Big Xml", '1,<CM+1D>,-5', 'vt_xml');
        ImportText(Xmlport::"LT AI VT Imp Df Big Xml", '1,garbage,-5', 'vt_xml_bad_df');
        ImportText(Xmlport::"LT AI VT Imp Df Big Xml", '1,<1D>,abc', 'vt_xml_bad_big');
        ImportText(Xmlport::"LT AI VT Imp Df Big Legacy", '1,<CM+1D>,-5', 'vt_legacy');
        ImportText(Xmlport::"LT AI VT Imp Df Big Legacy", '1,garbage,-5', 'vt_legacy_bad_df');
        ImportText(Xmlport::"LT AI VT Imp Rid Xml", '1,LT AI Table: 1', 'vt_xml_rid');
        ImportText(Xmlport::"LT AI VT Imp Blob Xml", '1,YmxvYiB0ZXh0', 'vt_xml_blob');
        Observer.Expect('vt_xml', 'imported=Yes error=[] code=[] stored=[Df=CM+1D Big=-5 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('vt_xml_bad_df', 'imported=No error=[The date formula ''GARBAGE'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Expect('vt_xml_bad_big', 'imported=No error=[The value "abc" can''t be evaluated into type BigInteger.] code=[Evaluate] stored=[no row]');
        Observer.Expect('vt_legacy', 'imported=Yes error=[] code=[] stored=[Df=CM+1D Big=-5 Rid= Bl= Md=No Ms=0]');
        Observer.Expect('vt_legacy_bad_df', 'imported=No error=[The date formula ''GARBAGE'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.] code=[Evaluate] stored=[no row]');
        Observer.Expect('vt_xml_rid', 'imported=Yes error=[] code=[] stored=[Df= Big=0 Rid=LT AI Table: 1 Bl= Md=No Ms=0]');
        Observer.Expect('vt_xml_blob', 'imported=No error=[The value "YmxvYiB0ZXh0" can''t be evaluated into type BLOB.] code=[Evaluate] stored=[no row]');
        Observer.Verify();
    end;
}
