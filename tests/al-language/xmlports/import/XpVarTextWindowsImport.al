// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-textencoding-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-textencoding-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 50000 "ALT Shape 00" (the line table element of the column port), table 50001
//   "ALT Shape 01" (Integer Id, Text[30] Name; the field ports), table 60008 "ALT Blob" (temporary, the source stream); own table 75135,
//   xmlports 75136-75138, test codeunit 75139.
// local object: the schemas and the TextEncoding property of the ports are what is under test; table 75135 keeps one row per line and
//   column of the column port, and no fixture table has an Integer, Integer key with a Text value.
// Probe (observe only): al-runner issue 7775. An XmlPort import into a Format = VariableText port that declares TextEncoding = WINDOWS.
//   Column       the shape of Base Application's "Data Exch. Import - CSV" (the import Subscription Billing's tests reach): Direction =
//                Import, TextEncoding = WINDOWS, a root text element (MinOccurs = Zero), a table element with AutoSave = false, a text
//                element col1 (MinOccurs = Zero, MaxOccurs = Once) and an unbound text element colx (MinOccurs = Zero), each column kept
//                by OnAfterAssignVariable. OnPreXmlPort may call currXMLport.FieldSeparator(';') and currXMLport.TextEncoding(...), as
//                that port does from its Data Exch. Def; Subscription Billing's tests write the file with TextEncoding::UTF8, a header
//                line, ';' between the columns, no quotes, and OutStream.WriteText() for the line end.
//   Fields       a VariableText port with field elements (default separators: `"` around a field, `,` between fields) that declares
//                TextEncoding = WINDOWS, and the same port declaring TextEncoding = UTF8 (Fields Utf8) for comparison.
//   Each document holds characters from 128 up (é U+00E9, ü U+00FC, € U+20AC; in Windows-1252 the bytes E9, FC, 80), written either with
//   TextEncoding::Windows or TextEncoding::UTF8. Every test records the source bytes (hex), the import result and each value with the
//   character codes of its characters from 128 up.
// BC versions: 27, 28, 29 (corpus CI)

table 75135 "XP VTW Cell"
{
    // local object: one row per line and column of the column port.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; LineNo; Integer) { }
        field(2; ColNo; Integer) { }
        field(3; Value; Text[250]) { }
    }

    keys
    {
        key(PK; LineNo, ColNo) { Clustered = true; }
    }
}

xmlport 75136 "XP VTW Columns"
{
    // local object: the column port of Data Exch. Import - CSV in generic form (TextEncoding = WINDOWS, unbound text element) is under test.
    Direction = Import;
    Format = VariableText;
    TextEncoding = WINDOWS;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            MinOccurs = Zero;
            tableelement(Row; "ALT Shape 00")
            {
                AutoSave = false;
                XmlName = 'DataExchDocument';
                textelement(col1)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;

                    trigger OnAfterAssignVariable()
                    begin
                        ColumnNo := 1;
                        InsertColumn(ColumnNo, col1);
                    end;
                }
                textelement(colx)
                {
                    MinOccurs = Zero;
                    Unbound = true;

                    trigger OnAfterAssignVariable()
                    begin
                        ColumnNo += 1;
                        InsertColumn(ColumnNo, colx);
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    FileLineNo += 1;
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if Separator <> '' then
            currXMLport.FieldSeparator(Separator);
        case EncodingMode of
            1:
                currXMLport.TextEncoding(TextEncoding::UTF8);
            2:
                currXMLport.TextEncoding(TextEncoding::Windows);
        end;
    end;

    var
        Cell: Record "XP VTW Cell" temporary;
        FileLineNo: Integer;
        ColumnNo: Integer;
        Separator: Text;
        EncodingMode: Integer;

    // Sep: the field separator OnPreXmlPort sets ('' leaves the port's). Mode: 0 no TextEncoding call, 1 UTF8, 2 Windows.
    procedure Configure(Sep: Text; Mode: Integer)
    begin
        Separator := Sep;
        EncodingMode := Mode;
    end;

    local procedure InsertColumn(ColumnNumber: Integer; var ColumnValue: Text)
    begin
        Cell.Init();
        Cell.LineNo := FileLineNo;
        Cell.ColNo := ColumnNumber;
        Cell.Value := CopyStr(ColumnValue, 1, MaxStrLen(Cell.Value));
        Cell.Insert();
        ColumnValue := '';
    end;

    procedure Cells(var Result: Record "XP VTW Cell" temporary)
    begin
        Result.Copy(Cell, true);
    end;
}

xmlport 75137 "XP VTW Fields"
{
    // local object: a VariableText port with field elements that declares TextEncoding = WINDOWS is under test.
    Format = VariableText;
    TextEncoding = WINDOWS;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                UseTemporary = true;

                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    procedure Rows(var Result: Record "ALT Shape 01" temporary)
    begin
        Result.Copy(Row, true);
    end;
}

xmlport 75138 "XP VTW Fields Utf8"
{
    // local object: the same port declaring TextEncoding = UTF8, for comparison.
    Format = VariableText;
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                UseTemporary = true;

                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    procedure Rows(var Result: Record "ALT Shape 01" temporary)
    begin
        Result.Copy(Row, true);
    end;
}

codeunit 75139 "XP VTW Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
    begin
        Cleanup.Initialize();
        Commit();
    end;

    local procedure Ch(Code: Integer): Text
    var
        C: Char;
    begin
        C := Code;
        exit(Format(C));
    end;

    local procedure Crlf(): Text
    begin
        exit(Ch(13) + Ch(10));
    end;

    // The test text: é, ü and € between ASCII letters.
    local procedure Special(): Text
    begin
        exit('caf' + Ch(233) + ' M' + Ch(252) + 'ller ' + Ch(8364) + '5');
    end;

    // The value, then the codes of its characters from 128 up.
    local procedure Show(Value: Text): Text
    var
        Codes: Text;
        Code: Integer;
        I: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            Code := Value[I];
            if Code > 127 then
                Codes += Format(Code, 0, 9) + ',';
        end;
        exit(Value + ' {' + Codes + '}');
    end;

    local procedure WriteSource(var Src: Record "ALT Blob" temporary; Doc: Text; Enc: TextEncoding; var InS: InStream)
    var
        OutS: OutStream;
        Bytes: InStream;
        B: Byte;
        Code: Integer;
        Hex: Text;
        N: Integer;
    begin
        Src.Init();
        Src.Code := 'SRC';
        Src.Data.CreateOutStream(OutS, Enc);
        OutS.WriteText(Doc);
        Src.Insert();
        Src.Data.CreateInStream(Bytes);
        while (not Bytes.EOS()) and (N < 120) do begin
            Bytes.Read(B);
            Code := B;
            Hex += Format(Code, 0, 9) + ' ';
            N += 1;
        end;
        Observer.Observe('source bytes', Hex);
        Src.Data.CreateInStream(InS);
    end;

    // Imports Doc (written with Enc) through the column port; Sep and Mode as in Configure.
    local procedure ImportColumns(Doc: Text; Enc: TextEncoding; Sep: Text; Mode: Integer)
    var
        Src: Record "ALT Blob" temporary;
        Cell: Record "XP VTW Cell" temporary;
        Port: XmlPort "XP VTW Columns";
        InS: InStream;
        Dump: Text;
    begin
        WriteSource(Src, Doc, Enc, InS);
        Port.Configure(Sep, Mode);
        Port.SetSource(InS);
        if Port.Import() then
            Observer.Observe('import', 'true')
        else begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end;
        Port.Cells(Cell);
        if Cell.FindSet() then
            repeat
                Dump += Format(Cell.LineNo) + '/' + Format(Cell.ColNo) + '=[' + Show(Cell.Value) + '];';
            until Cell.Next() = 0;
        Observer.Observe('cells', Format(Cell.Count()) + ':' + Dump);
    end;

    // Imports Doc (written with Enc) through a field port: Which 1 Fields (WINDOWS), 2 Fields Utf8; SetUtf8 calls TextEncoding(UTF8) on
    // the variable before Import.
    local procedure ImportFields(Which: Integer; Doc: Text; Enc: TextEncoding; SetUtf8: Boolean)
    var
        Src: Record "ALT Blob" temporary;
        Row: Record "ALT Shape 01" temporary;
        PortW: XmlPort "XP VTW Fields";
        PortU: XmlPort "XP VTW Fields Utf8";
        InS: InStream;
        Ok: Boolean;
        Dump: Text;
    begin
        WriteSource(Src, Doc, Enc, InS);
        case Which of
            1:
                begin
                    if SetUtf8 then
                        PortW.TextEncoding(TextEncoding::UTF8);
                    PortW.SetSource(InS);
                    Ok := PortW.Import();
                    PortW.Rows(Row);
                end;
            2:
                begin
                    PortU.SetSource(InS);
                    Ok := PortU.Import();
                    PortU.Rows(Row);
                end;
        end;
        Observer.Observe('import', Format(Ok));
        if not Ok then
            Observer.ObserveError('error');
        if Row.FindSet() then
            repeat
                Dump += Format(Row.Id) + '=[' + Show(Row.Name) + '];';
            until Row.Next() = 0;
        Observer.Observe('rows', Format(Row.Count()) + ':' + Dump);
    end;

    // Subscription Billing's file: a header line, ';' between columns, no quotes, CR LF after each line.
    local procedure SbDoc(): Text
    begin
        exit('Customer;Name;Amount' + Crlf() + 'C1;' + Special() + ';12.50' + Crlf() + 'C2;plain;3' + Crlf());
    end;

    // The column port as Subscription Billing's tests run it: written UTF-8, OnPreXmlPort sets ';' and TextEncoding UTF8.
    [Test]
    procedure VTW_Columns_Utf8File_SetUtf8_Semicolon_Import()
    begin
        Initialize();
        ImportColumns(SbDoc(), TextEncoding::UTF8, ';', 1);
        Observer.Finish();
    end;

    // The column port, written with Windows, OnPreXmlPort sets ';' and TextEncoding Windows (File Encoding WINDOWS).
    [Test]
    procedure VTW_Columns_WindowsFile_SetWindows_Semicolon_Import()
    begin
        Initialize();
        ImportColumns(SbDoc(), TextEncoding::Windows, ';', 2);
        Observer.Finish();
    end;

    // The column port, written with Windows, no TextEncoding call (the declared WINDOWS stays).
    [Test]
    procedure VTW_Columns_WindowsFile_Declared_Semicolon_Import()
    begin
        Initialize();
        ImportColumns(SbDoc(), TextEncoding::Windows, ';', 0);
        Observer.Finish();
    end;

    // The column port, written UTF-8, no TextEncoding call: UTF-8 bytes read under the declared WINDOWS.
    [Test]
    procedure VTW_Columns_Utf8File_Declared_Semicolon_Import()
    begin
        Initialize();
        ImportColumns(SbDoc(), TextEncoding::UTF8, ';', 0);
        Observer.Finish();
    end;

    // The column port, written with Windows, OnPreXmlPort sets TextEncoding UTF8: Windows bytes read as UTF-8.
    [Test]
    procedure VTW_Columns_WindowsFile_SetUtf8_Semicolon_Import()
    begin
        Initialize();
        ImportColumns(SbDoc(), TextEncoding::Windows, ';', 1);
        Observer.Finish();
    end;

    // The column port with its default separators: the same file with ',' between columns and quoted fields.
    [Test]
    procedure VTW_Columns_WindowsFile_Declared_DefaultSeparators_Import()
    begin
        Initialize();
        ImportColumns('"C1","' + Special() + '","a;b"' + Crlf() + 'C2,plain,"x,y"' + Crlf(), TextEncoding::Windows, '', 0);
        Observer.Finish();
    end;

    // The column port, ';' set, a field in quotes holding ';', a doubled quote inside quotes, and an empty column.
    [Test]
    procedure VTW_Columns_WindowsFile_Semicolon_Quotes_Import()
    begin
        Initialize();
        ImportColumns('C1;"' + Special() + ';x";"say ""hi"""' + Crlf() + 'C2;;end' + Crlf(), TextEncoding::Windows, ';', 0);
        Observer.Finish();
    end;

    // The column port, ';' set, the last line without CR LF.
    [Test]
    procedure VTW_Columns_Utf8File_SetUtf8_NoFinalLineEnd_Import()
    begin
        Initialize();
        ImportColumns('Customer;Name' + Crlf() + 'C1;' + Special(), TextEncoding::UTF8, ';', 1);
        Observer.Finish();
    end;

    // The field port (WINDOWS), written with Windows, quoted fields.
    [Test]
    procedure VTW_Fields_Windows_WindowsFile_Import()
    begin
        Initialize();
        ImportFields(1, '"1","' + Special() + '"' + Crlf() + '2,' + Ch(233) + Ch(252) + Ch(8364) + Crlf(), TextEncoding::Windows, false);
        Observer.Finish();
    end;

    // The field port (WINDOWS), written UTF-8.
    [Test]
    procedure VTW_Fields_Windows_Utf8File_Import()
    begin
        Initialize();
        ImportFields(1, '"1","' + Special() + '"' + Crlf() + '2,' + Ch(233) + Ch(252) + Ch(8364) + Crlf(), TextEncoding::UTF8, false);
        Observer.Finish();
    end;

    // The field port (WINDOWS) with TextEncoding(UTF8) called on the variable before Import, written UTF-8.
    [Test]
    procedure VTW_Fields_Windows_SetUtf8_Utf8File_Import()
    begin
        Initialize();
        ImportFields(1, '"1","' + Special() + '"' + Crlf() + '2,' + Ch(233) + Ch(252) + Ch(8364) + Crlf(), TextEncoding::UTF8, true);
        Observer.Finish();
    end;

    // The field port declaring UTF8, written UTF-8 (comparison).
    [Test]
    procedure VTW_Fields_Utf8_Utf8File_Import()
    begin
        Initialize();
        ImportFields(2, '"1","' + Special() + '"' + Crlf() + '2,' + Ch(233) + Ch(252) + Ch(8364) + Crlf(), TextEncoding::UTF8, false);
        Observer.Finish();
    end;

    // The field port declaring UTF8, written with Windows (bytes that are not valid UTF-8).
    [Test]
    procedure VTW_Fields_Utf8_WindowsFile_Import()
    begin
        Initialize();
        ImportFields(2, '"1","' + Special() + '"' + Crlf() + '2,' + Ch(233) + Ch(252) + Ch(8364) + Crlf(), TextEncoding::Windows, false);
        Observer.Finish();
    end;

    // The field port (WINDOWS): a doubled quote inside quotes, a comma inside quotes, an unquoted value with a space.
    [Test]
    procedure VTW_Fields_Windows_Quotes_Import()
    begin
        Initialize();
        ImportFields(1, '"1","say ""hi"""' + Crlf() + '"2","a,b ' + Ch(233) + '"' + Crlf() + '3,two words' + Crlf(), TextEncoding::Windows, false);
        Observer.Finish();
    end;
}
