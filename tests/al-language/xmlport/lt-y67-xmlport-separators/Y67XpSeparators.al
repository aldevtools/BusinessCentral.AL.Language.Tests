// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93611, xmlports 93612-93613, codeunit 93614 (writer Y67, gap cycle 6 follow-up)
// Probe: the separator and encoding members of currXMLport (FieldSeparator, FieldDelimiter, RecordSeparator, TableSeparator, TextEncoding)
//   set by ASSIGNMENT (currXMLport.FieldSeparator := X) in OnPreXmlPort of a VariableText port, with every value form: a text literal, a
//   Text variable, a Text[1] variable, a Char (an element of a Text variable, a Char variable), a Code[1] variable, a token such as '<None>'
//   and '<TAB>', an empty text; TextEncoding with the enum value and a TextEncoding variable. The call form with a Char. Export and import.
//   The members read back through the getter (assignment of currXMLport.X to a Text). Assignment in OnAfterGetRecord (after the first row).
//   The call form with tokens is pinned by platform/lt-xmlport-session-navapp-cookie/P94Fixtures.al:356 (the assignment form is not).
// BC versions: 27, 28, 29

table 93611 "LT Y67 Sep Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 93612 "LT Y67 Sep Export"
{
    Format = VariableText;
    Direction = Export;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<LF>';
    TableSeparator = '<None>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(R; "LT Y67 Sep Row")
            {
                fieldelement(Id; R.Id) { }
                fieldelement(Name; R.Name) { }
                fieldelement(Note; R.Note) { }

                trigger OnAfterGetRecord()
                begin
                    if (Mode >= 100) and (R.Id = 1) then
                        Apply(Mode - 100);
                end;
            }
        }
    }

    var
        Mode: Integer;
        Seen: Text;
        Crlf: Text[2];
        Tab: Text[1];
        Chars: Text[1];
        Code1: Code[1];
        Long: Text;
        Hash: Char;
        Enc: TextEncoding;

    trigger OnPreXmlPort()
    begin
        Crlf[1] := 13;
        Crlf[2] := 10;
        Tab[1] := 9;
        Chars := '|';
        Code1 := 'Z';
        Long := '::';
        Hash := 35;
        Enc := TextEncoding::UTF16;
        if Mode < 100 then
            Apply(Mode);
        Seen := 'sep=[' + currXMLport.FieldSeparator + '] delim=[' + currXMLport.FieldDelimiter + '] rec=[' + currXMLport.RecordSeparator + '] table=[' + currXMLport.TableSeparator + '] enc=' + Format(currXMLport.TextEncoding);
    end;

    local procedure Apply(What: Integer)
    begin
        case What of
            1:
                currXMLport.FieldSeparator := ';';
            2:
                currXMLport.FieldSeparator := Long;
            3:
                currXMLport.FieldSeparator := Chars;
            4:
                currXMLport.FieldSeparator := Tab[1];
            5:
                currXMLport.FieldSeparator := Hash;
            6:
                currXMLport.FieldSeparator := Code1;
            7:
                currXMLport.FieldSeparator(Hash);
            8:
                currXMLport.FieldSeparator := '<TAB>';
            9:
                currXMLport.FieldSeparator := '';
            10:
                currXMLport.FieldDelimiter := '''';
            11:
                currXMLport.FieldDelimiter := Hash;
            12:
                currXMLport.FieldDelimiter := '';
            13:
                currXMLport.FieldDelimiter := '<None>';
            14:
                currXMLport.RecordSeparator := Crlf;
            15:
                currXMLport.RecordSeparator := Hash;
            16:
                currXMLport.RecordSeparator := '<None>';
            17:
                currXMLport.RecordSeparator := Tab[1];
            18:
                currXMLport.RecordSeparator := '<CR/LF>';
            19:
                currXMLport.TableSeparator := Hash;
            20:
                currXMLport.TableSeparator := '<CR/LF>';
            21:
                currXMLport.TextEncoding := TextEncoding::UTF16;
            22:
                currXMLport.TextEncoding := Enc;
            23:
                currXMLport.TextEncoding := TextEncoding::MSDos;
            24:
                currXMLport.TextEncoding := TextEncoding::Windows;
            25:
                currXMLport.TextEncoding := TextEncoding::UTF8;
            26:
                begin
                    currXMLport.FieldSeparator := ';';
                    currXMLport.FieldDelimiter := '''';
                    currXMLport.RecordSeparator := '<CR/LF>';
                end;
        end;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 93613 "LT Y67 Sep Import"
{
    Format = VariableText;
    Direction = Import;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<LF>';
    TableSeparator = '<None>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(R; "LT Y67 Sep Row")
            {
                fieldelement(Id; R.Id) { }
                fieldelement(Name; R.Name) { }
                fieldelement(Note; R.Note) { }
            }
        }
    }

    var
        Mode: Integer;
        Hash: Char;
        Tab: Text[1];

    trigger OnPreXmlPort()
    begin
        Hash := 35;
        Tab[1] := 9;
        case Mode of
            1:
                currXMLport.FieldSeparator := ';';
            2:
                currXMLport.FieldSeparator := Hash;
            3:
                currXMLport.FieldSeparator := Tab[1];
            4:
                currXMLport.FieldDelimiter := '''';
            5:
                currXMLport.RecordSeparator := Hash;
            6:
                currXMLport.RecordSeparator := '<CR/LF>';
            7:
                currXMLport.FieldSeparator(Hash);
        end;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 93614 "LT Y67 Sep Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y67 Sep Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one, "q"';
        Row.Note := 'n;1#x';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Note := '';
        Row.Insert();
    end;

    local procedure Raw(Mode: Integer; Enc: TextEncoding; var Seen: Text): Text
    var
        Xp: XmlPort "LT Y67 Sep Export";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        Xp.SetMode(Mode);
        TempBlob.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Seen := Xp.GetSeen();
        TempBlob.CreateInStream(InS, Enc);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit('len=' + Format(TempBlob.Length()) + ' ' + Result);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    begin
        RunWith(Observer, Mode, TextEncoding::UTF8);
    end;

    local procedure RunWith(var Observer: Codeunit "Probe Observer"; Mode: Integer; Enc: TextEncoding)
    var
        Seen: Text;
        Out: Text;
    begin
        ClearLastError();
        Out := Raw(Mode, Enc, Seen);
        Observer.Observe('m' + Format(Mode) + ' out', Out);
        Observer.Observe('m' + Format(Mode) + ' seen', Seen);
    end;

    local procedure Ch(Code: Integer): Text
    var
        T: Text[1];
    begin
        T[1] := Code;
        exit(T);
    end;

    local procedure Import(Mode: Integer; Content: Text; var Result: Text)
    var
        Xp: XmlPort "LT Y67 Sep Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Row: Record "LT Y67 Sep Row";
    begin
        Row.DeleteAll();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetMode(Mode);
        Xp.SetSource(InS);
        if not Xp.Import() then begin
            Result := 'error ' + GetLastErrorText() + '|' + GetLastErrorCode();
            exit;
        end;
        Result := '';
        if Row.FindSet() then
            repeat
                Result += '[' + Format(Row.Id) + '|' + Row.Name + '|' + Row.Note + ']';
            until Row.Next() = 0;
    end;

    [Test]
    procedure FieldSeparator_AssignForms_Export()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Seed();
        Run(Observer, 0);
        for i := 1 to 9 do
            Run(Observer, i);
        Observer.Finish();
    end;

    [Test]
    procedure FieldDelimiter_AssignForms_Export()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Seed();
        for i := 10 to 13 do
            Run(Observer, i);
        Observer.Finish();
    end;

    [Test]
    procedure RecordAndTableSeparator_AssignForms_Export()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Seed();
        for i := 14 to 20 do
            Run(Observer, i);
        Observer.Finish();
    end;

    [Test]
    procedure TextEncoding_AssignForms_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunWith(Observer, 21, TextEncoding::UTF16);
        RunWith(Observer, 22, TextEncoding::UTF16);
        RunWith(Observer, 23, TextEncoding::MSDos);
        RunWith(Observer, 24, TextEncoding::Windows);
        RunWith(Observer, 25, TextEncoding::UTF8);
        RunWith(Observer, 26, TextEncoding::UTF8);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_InOnAfterGetRecord_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Run(Observer, 101);
        Run(Observer, 111);
        Run(Observer, 114);
        Run(Observer, 121);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Import()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Import(0, '1,"a",b' + Ch(10), Result);
        Observer.Observe('default', Result);
        Import(1, '1;"a";b' + Ch(10), Result);
        Observer.Observe('semicolon text', Result);
        Import(2, '1#a#b', Result);
        Observer.Observe('char var', Result);
        Import(3, '1' + Ch(9) + 'a' + Ch(9) + 'b', Result);
        Observer.Observe('tab element', Result);
        Import(4, '1,''a,x'',b', Result);
        Observer.Observe('delimiter quote', Result);
        Import(5, '1,a,b#2,c,d', Result);
        Observer.Observe('record sep char', Result);
        Import(6, '1,a,b' + Ch(10) + '2,c,d', Result);
        Observer.Observe('record sep crlf token', Result);
        Import(7, '1#a#b', Result);
        Observer.Observe('call form char', Result);
        Observer.Finish();
    end;
}
