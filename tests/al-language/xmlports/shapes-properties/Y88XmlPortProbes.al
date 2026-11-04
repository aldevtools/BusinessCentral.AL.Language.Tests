// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); shared table 50000 "ALT Shape 00", xmlports 94702-94705, codeunit 94701 (writer Y88); table 93547 "LT Y67 TF Row" and
//   xmlport 93548 of tests/al-language/xmlport/lt-y67-xmlport-tablefilter/Y67XpTableFilter.al
// Probe: (1) the whole text of the error that Evaluate into a TableFilter field raises for a text without a table name (records/W4PlatformAndMeta.al:598 and
//   Y67XpTableFilter.al:153 pin the head and the sentence "The metadata object Table -1 was not found"), with every control character and backslash
//   written out, so that the joiner between the two parts is visible; (2) what the getters currXMLport.FieldSeparator, FieldDelimiter, RecordSeparator and
//   TableSeparator of a VariableText xmlport return for separators declared as properties ('<CR/LF>', '<LF>', '<CR>', '<TAB>', '<None>', '<NewLine>', a
//   literal), as text, length and character codes.
// BC versions: 27 - 29

xmlport 94702 "LT Y88 Sep A"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    FieldSeparator = '<TAB>';
    FieldDelimiter = '<None>';
    RecordSeparator = '<CR/LF>';
    TableSeparator = '<LF>';

    schema
    {
        textelement(Root)
        {
            tableelement(R; "ALT Shape 00")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    var
        Seen: Text;

    trigger OnPreXmlPort()
    begin
        Seen := currXMLport.FieldSeparator + '#' + currXMLport.FieldDelimiter + '#' + currXMLport.RecordSeparator + '#' + currXMLport.TableSeparator;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 94703 "LT Y88 Sep B"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    FieldSeparator = '<CR>';
    FieldDelimiter = '"';
    RecordSeparator = '<NewLine>';
    TableSeparator = '<CR>';

    schema
    {
        textelement(Root)
        {
            tableelement(R; "ALT Shape 00")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    var
        Seen: Text;

    trigger OnPreXmlPort()
    begin
        Seen := currXMLport.FieldSeparator + '#' + currXMLport.FieldDelimiter + '#' + currXMLport.RecordSeparator + '#' + currXMLport.TableSeparator;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 94704 "LT Y88 Sep C"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    FieldSeparator = '<None>';
    FieldDelimiter = '<None>';
    RecordSeparator = '<None>';
    TableSeparator = '<None>';

    schema
    {
        textelement(Root)
        {
            tableelement(R; "ALT Shape 00")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    var
        Seen: Text;

    trigger OnPreXmlPort()
    begin
        Seen := currXMLport.FieldSeparator + '#' + currXMLport.FieldDelimiter + '#' + currXMLport.RecordSeparator + '#' + currXMLport.TableSeparator;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 94705 "LT Y88 Sep D"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(R; "ALT Shape 00")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    var
        Seen: Text;

    trigger OnPreXmlPort()
    begin
        Seen := currXMLport.FieldSeparator + '#' + currXMLport.FieldDelimiter + '#' + currXMLport.RecordSeparator + '#' + currXMLport.TableSeparator;
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

codeunit 94701 "LT Y88 XmlPort Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Every character below 32 and the backslash as {code}, so that a real CR/LF and the two characters backslash-r are told apart.
    local procedure Show(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if (Code < 32) or (Code = 92) then
                Result += '{' + Format(Code) + '}'
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryEval(var Row: Record "LT Y67 TF Row"; Value: Text)
    begin
        Evaluate(Row.Filt, Value);
    end;

    [TryFunction]
    local procedure TryImport(Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT Y67 TF Export", InS);
    end;

    local procedure ErrorShown(): Text
    var
        Full: Text;
        At: Integer;
    begin
        Full := GetLastErrorText();
        At := StrPos(Full, 'The metadata object Table -1 was not found');
        exit('len=' + Format(StrLen(Full)) + ' at=' + Format(At) + ' code=' + GetLastErrorCode() + ' text=' + Show(Full));
    end;

    [Test]
    procedure Y88_EvaluateTableFilter_UnqualifiedErrorText()
    var
        Row: Record "LT Y67 TF Row";
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if TryEval(Row, 'Id: 1..9') then
            Observer.Observe('evaluate', 'no error')
        else
            Observer.Observe('evaluate', ErrorShown());
        ClearLastError();
        Observer.Expect('evaluate', 'len=376 at=71 code=Evaluate:MetadataNotFound text=The value "Id: 1..9" can''t be evaluated into type TableFilter. {92}      The metadata object Table -1 was not found.{92}      The application might be incompatible with the current compiler. Please unpublish the application that contains the application object Table -1 and republish it. {92}      Or, run a technical upgrade of the application database with the ''Force'' flag set.{92}    ');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_EvaluateTableFilter_UnknownTableErrorText()
    var
        Row: Record "LT Y67 TF Row";
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if TryEval(Row, 'No Such Table: Id=1') then
            Observer.Observe('evaluate', 'no error')
        else
            Observer.Observe('evaluate', ErrorShown());
        ClearLastError();
        Observer.Expect('evaluate', 'len=387 at=82 code=Evaluate:MetadataNotFound text=The value "No Such Table: Id=1" can''t be evaluated into type TableFilter. {92}      The metadata object Table -1 was not found.{92}      The application might be incompatible with the current compiler. Please unpublish the application that contains the application object Table -1 and republish it. {92}      Or, run a technical upgrade of the application database with the ''Force'' flag set.{92}    ');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_XmlPortImport_UnqualifiedFilterErrorText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if TryImport('<Root><R><Id>11</Id><Filter>Id: 1..9</Filter></R></Root>') then
            Observer.Observe('import', 'no error')
        else
            Observer.Observe('import', ErrorShown());
        ClearLastError();
        Observer.Expect('import', 'len=376 at=71 code=Evaluate:MetadataNotFound text=The value "Id: 1..9" can''t be evaluated into type TableFilter. {92}      The metadata object Table -1 was not found.{92}      The application might be incompatible with the current compiler. Please unpublish the application that contains the application object Table -1 and republish it. {92}      Or, run a technical upgrade of the application database with the ''Force'' flag set.{92}    ');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_VariableText_DeclaredSeparatorGetters()
    var
        A: XmlPort "LT Y88 Sep A";
        B: XmlPort "LT Y88 Sep B";
        C: XmlPort "LT Y88 Sep C";
        D: XmlPort "LT Y88 Sep D";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS);
        A.SetDestination(OutS);
        A.Export();
        Observer.Observe('A tab|none|crlf|lf', Show(A.GetSeen()) + ' len=' + Format(StrLen(A.GetSeen())));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        B.SetDestination(OutS);
        B.Export();
        Observer.Observe('B cr|quote|newline|cr', Show(B.GetSeen()) + ' len=' + Format(StrLen(B.GetSeen())));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        C.SetDestination(OutS);
        C.Export();
        Observer.Observe('C none', Show(C.GetSeen()) + ' len=' + Format(StrLen(C.GetSeen())));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        D.SetDestination(OutS);
        D.Export();
        Observer.Observe('D default', Show(D.GetSeen()) + ' len=' + Format(StrLen(D.GetSeen())));
        Observer.Expect('A tab|none|crlf|lf', '{9}##{13}{10}#{10} len=7');
        Observer.Expect('B cr|quote|newline|cr', '{13}#"#{13}{10}#{13} len=8');
        Observer.Expect('C none', '### len=3');
        Observer.Expect('D default', ',#"#{13}{10}#{13}{10}{13}{10} len=11');
        Observer.Verify();
    end;
}
