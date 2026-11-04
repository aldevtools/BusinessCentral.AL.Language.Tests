// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob; tables 85960-85962, xmlports 85963-85968, test codeunit 85969
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts (corpus issue 671, items 102-104):
//   102 (microsoft/AL#1748): a textelement named like a field of the table element (Type): what an unqualified Type means in triggers.
//   103 (microsoft/AL#7017): the last bytes of an XMLport export (Xml and VariableText, UTF-8 and UTF-16) into a Temp Blob.
//   104 (microsoft/AL#6300): a VariableText XMLport with a table element nested under another (LinkTable/LinkFields) and
//       TableSeparator = '<NewLine><NewLine>' compiles; what export and import do with it.
// BC versions: 29 (27 and 28 by CI)

table 85960 "LT DF Xp Type Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Type; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(3; Note; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 85961 "LT DF Xp Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

table 85962 "LT DF Xp Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DocNo; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; DocNo, LineNo) { Clustered = true; }
    }
}

xmlport 85963 "LT DF Xp Type Name"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT DF Xp Type Row")
            {
                fieldelement(Id; Row.Id) { }
                textelement(Type)
                {
                    trigger OnAfterAssignVariable()
                    begin
                        Row.Note := 'assign=[' + Type + '] field=[' + Format(Row.Type) + ']';
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Row.Note += ' insert=[' + Type + ']';
                    if Type = 'Gamma' then
                        Row.Type := Row.Type::Gamma;
                end;
            }
        }
    }
}

xmlport 85964 "LT DF Xp Xml Utf8"
{
    Format = Xml;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT DF Xp Hdr")
            {
                fieldelement(No; Row.No) { }
            }
        }
    }
}

xmlport 85965 "LT DF Xp Xml Utf16"
{
    Format = Xml;
    Direction = Export;
    Encoding = UTF16;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT DF Xp Hdr")
            {
                fieldelement(No; Row.No) { }
            }
        }
    }
}

xmlport 85966 "LT DF Xp Vt Utf8"
{
    Format = VariableText;
    Direction = Export;
    FieldSeparator = ',';
    RecordSeparator = '<NewLine>';
    TextEncoding = UTF8;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT DF Xp Hdr")
            {
                fieldelement(No; Row.No) { }
                fieldelement(Descr; Row.Descr) { }
            }
        }
    }
}

xmlport 85967 "LT DF Xp Vt Utf16"
{
    Format = VariableText;
    Direction = Export;
    FieldSeparator = ',';
    RecordSeparator = '<NewLine>';
    TextEncoding = UTF16;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT DF Xp Hdr")
            {
                fieldelement(No; Row.No) { }
                fieldelement(Descr; Row.Descr) { }
            }
        }
    }
}

xmlport 85968 "LT DF Xp Vt Nested"
{
    Format = VariableText;
    Direction = Both;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<NewLine>';
    TableSeparator = '<NewLine><NewLine>';
    TextEncoding = UTF8;
    UseRequestPage = false;
    schema
    {
        textelement(ROOT)
        {
            tableelement(PH; "LT DF Xp Hdr")
            {
                fieldelement(No; PH.No) { }
                fieldelement(HDescr; PH.Descr) { }
                tableelement(PL; "LT DF Xp Line")
                {
                    LinkTable = PH;
                    LinkFields = DocNo = field(No);
                    MinOccurs = Zero;
                    fieldelement(LineNo; PL.LineNo) { }
                    fieldelement(LDescr; PL.Descr) { }
                }
            }
        }
    }
}

codeunit 85969 "LT DF XmlPort Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Bytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        All: List of [Integer];
        R: Text;
        i: Integer;
        First: Integer;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            All.Add(B);
        end;
        First := All.Count() - 5;
        if First < 1 then
            First := 1;
        R := Format(All.Count()) + ' last:';
        for i := First to All.Count() do
            R += Format(All.Get(i)) + ',';
        exit(R);
    end;

    local procedure SeedHeaders()
    var
        H: Record "LT DF Xp Hdr";
        L: Record "LT DF Xp Line";
    begin
        L.DeleteAll();
        H.DeleteAll();
        H.No := 'H1';
        H.Descr := 'First';
        H.Insert();
        H.No := 'H2';
        H.Descr := 'Second';
        H.Insert();
    end;

    local procedure ExportBytes(XmlPortId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        exit(Bytes(TempBlob));
    end;

    // Item 103.
    [Test]
    procedure Export_Last_Bytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedHeaders();
        Observer.Observe('xml_utf8', ExportBytes(Xmlport::"LT DF Xp Xml Utf8"));
        Observer.Observe('xml_utf16', ExportBytes(Xmlport::"LT DF Xp Xml Utf16"));
        Observer.Observe('vt_utf8', ExportBytes(Xmlport::"LT DF Xp Vt Utf8"));
        Observer.Observe('vt_utf16', ExportBytes(Xmlport::"LT DF Xp Vt Utf16"));
        Observer.Expect('xml_utf8', '143 last:47,82,111,111,116,62,');
        Observer.Expect('xml_utf16', '290 last:111,0,116,0,62,0,');
        Observer.Expect('vt_utf8', '30 last:101,99,111,110,100,34,');
        Observer.Expect('vt_utf16', '56 last:110,0,100,0,34,0,');
        Observer.Verify();
    end;

    // Item 102.
    [Test]
    procedure TextElement_Named_Like_Field()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DF Xp Type Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<?xml version="1.0" encoding="utf-8"?><Root><Row><Id>1</Id><Type>Beta</Type></Row><Row><Id>2</Id><Type>Gamma</Type></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        ClearLastError();
        Ok := Xmlport.Import(Xmlport::"LT DF Xp Type Name", InS);
        Observer.Observe('imported', Format(Ok));
        Observer.ObserveError('import');
        if Row.FindSet() then
            repeat
                Observer.Observe('row' + Format(Row.Id), 'type=' + Format(Row.Type) + ' ' + Row.Note);
            until Row.Next() = 0;
        Observer.Expect('imported', 'Yes');
        Observer.Expect('import|text', '');
        Observer.Expect('import|code', '');
        Observer.Expect('row1', 'type=Alpha assign=[Beta] field=[Alpha] insert=[Beta]');
        Observer.Expect('row2', 'type=Gamma assign=[Gamma] field=[Alpha] insert=[Gamma]');
        Observer.Verify();
    end;

    local procedure StreamText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        R: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            R += Line + '|';
        end;
        exit(R);
    end;

    local procedure LineRows(): Text
    var
        H: Record "LT DF Xp Hdr";
        L: Record "LT DF Xp Line";
        R: Text;
    begin
        if H.FindSet() then
            repeat
                R += 'H:' + H.No + '/' + H.Descr + ';';
            until H.Next() = 0;
        if L.FindSet() then
            repeat
                R += 'L:' + L.DocNo + '/' + Format(L.LineNo) + '/' + L.Descr + ';';
            until L.Next() = 0;
        exit(R);
    end;

    // Item 104: export.
    [Test]
    procedure VariableText_Nested_Export()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT DF Xp Line";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        SeedHeaders();
        L.DocNo := 'H1';
        L.LineNo := 10;
        L.Descr := 'A';
        L.Insert();
        L.LineNo := 20;
        L.Descr := 'B';
        L.Insert();
        L.DocNo := 'H2';
        L.LineNo := 10;
        L.Descr := 'C';
        L.Insert();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT DF Xp Vt Nested", OutS);
        Observer.Observe('export', StreamText(TempBlob));
        Observer.Expect('export', '"H1","First","10","A"|"20","B"|||"H2","Second","10","C"||');
        Observer.Verify();
    end;

    local procedure ImportNested(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        H: Record "LT DF Xp Hdr";
        L: Record "LT DF Xp Line";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Ok: Boolean;
    begin
        L.DeleteAll();
        H.DeleteAll();
        Commit();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Src);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        ClearLastError();
        Ok := Xmlport.Import(Xmlport::"LT DF Xp Vt Nested", InS);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '_rows', LineRows());
        Commit();
    end;

    // Item 104: import. CRLF between records, an empty line between the header table and the line table (the TableSeparator).
    [Test]
    procedure VariableText_Nested_Import()
    var
        Observer: Codeunit "Probe Observer";
        Crlf: Text[2];
    begin
        Crlf[1] := 13;
        Crlf[2] := 10;
        ImportNested(Observer, 'header_only', '"H1","First"' + Crlf);
        ImportNested(Observer, 'header_then_lines', '"H1","First"' + Crlf + Crlf + '"10","A"' + Crlf + '"20","B"' + Crlf);
        ImportNested(Observer, 'two_headers', '"H1","First"' + Crlf + '"H2","Second"' + Crlf);
        Observer.Expect('header_only', 'Yes');
        Observer.Expect('header_only|text', '');
        Observer.Expect('header_only|code', '');
        Observer.Expect('header_only_rows', 'H:H1/First;');
        Observer.Expect('header_then_lines', 'No');
        Observer.Expect('header_then_lines|text', 'The Element <PL> is unexpected.');
        Observer.Expect('header_then_lines|code', 'XmlPortUnexpectedElement');
        Observer.Expect('header_then_lines_rows', '');
        Observer.Expect('two_headers', 'Yes');
        Observer.Expect('two_headers|text', '');
        Observer.Expect('two_headers|code', '');
        Observer.Expect('two_headers_rows', 'H:H1/First;H:H2/Second;');
        Observer.Verify();
    end;
}
