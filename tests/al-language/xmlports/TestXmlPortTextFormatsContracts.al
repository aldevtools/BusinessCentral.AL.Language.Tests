// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-format-xmlport-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained xmlports 68260..68262, codeunit 68263
// Probe: written against a real BC 27.5 service tier (en-US); every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins VariableText and FixedText ports: import of quoted, unquoted and blank values (and the error
// for a doubled quote inside a quoted value), custom field delimiter, separators and encoding (the
// export starts with a UTF-8 byte order mark), and FixedText export (fields padded and cut to their
// Width, CR LF between rows) and import.
// BC versions: 27.5

xmlport 68260 "Probe XP VT Default"
{
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field") { }
                fieldelement(Dec; U."Decimal Field") { }
                fieldelement(Dt; U."Date Field") { }
            }
        }
    }
}

xmlport 68261 "Probe XP VT Custom"
{
    Direction = Both;
    Format = VariableText;
    FieldSeparator = ';';
    FieldDelimiter = '|';
    RecordSeparator = '<LF>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field") { }
            }
        }
    }
}

xmlport 68262 "Probe XP Fixed"
{
    Direction = Both;
    Format = FixedText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldelement(EntryNo; U."Entry No.") { Width = 5; }
                fieldelement(Txt; U."Text Field") { Width = 8; }
                fieldelement(Dec; U."Decimal Field") { Width = 10; }
            }
        }
    }
}

codeunit 68263 "Probe XmlPort Text Formats"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Commit();
    end;

    local procedure Feed(Text: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Text);
    end;

    local procedure HexOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Value: Byte;
        Result: Text;
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.Read(Value);
            Result += CopyStr(Digits, (Value div 16) + 1, 1) + CopyStr(Digits, (Value mod 16) + 1, 1);
        end;
        exit(Result);
    end;

    local procedure RowsOf(): Text
    var
        ALTUniversal: Record "ALT Universal";
        Result: Text;
    begin
        if ALTUniversal.FindSet() then
            repeat
                Result += Format(ALTUniversal."Entry No.") + '|' + ALTUniversal."Text Field" + '|' + Format(ALTUniversal."Decimal Field", 0, 9) + '|' + Format(ALTUniversal."Date Field", 0, 9) + ' ; ';
            until ALTUniversal.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure VariableText_Import_QuotedUnquotedAndBlankValues()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP VT Default";
        InStr: InStream;
        Cr: Text[1];
        Lf: Text[1];
    begin
        Initialize();
        Cr[1] := 13;
        Lf[1] := 10;
        Feed('"1","a,b","1,234.50","03/05/24"' + Cr + Lf + '"2","plain","0",""' + Cr + Lf + '3,unquoted,5.5,01/02/24', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        Import.Import();
        Commit();

        Assert.AreEqual('1|a,b|1234.5|2024-03-05 ; 2|plain|0| ; 3|unquoted|5.5|2024-01-02 ; ', RowsOf(), 'rows');
    end;

    [Test]
    procedure VariableText_Import_DoubledQuoteInsideAQuotedValue_IsNotAnEscape()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP VT Default";
        InStr: InStream;
    begin
        Initialize();
        Feed('"2","say ""hi""","0",""', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        asserterror Import.Import();

        Assert.AreEqual('The value "hi" can''t be evaluated into type Decimal.', GetLastErrorText(), 'the value is cut at the inner quotes');
    end;

    [Test]
    procedure VariableText_CustomSeparators_ImportAndExportBytes()
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP VT Custom";
        Export: XmlPort "Probe XP VT Custom";
        InStr: InStream;
        OutStr: OutStream;
        Lf: Text[1];
    begin
        Initialize();
        Lf[1] := 10;
        Feed('|1|;|a;b|' + Lf + '|2|;|x|', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);
        Import.Import();
        Commit();
        Assert.AreEqual('1|a;b|0| ; 2|x|0| ; ', RowsOf(), 'a value may contain the separator when it is delimited');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Export.SetDestination(OutStr);
        Export.Export();
        Assert.AreEqual('EFBBBF7C317C3B7C613B627C0A7C327C3B7C787C', HexOf(TempBlob), 'a UTF-8 byte order mark, then |1|;|a;b|, LF, |2|;|x|, no separator after the last row');
    end;

    [Test]
    procedure FixedText_Export_PadsAndCutsToWidth_Import_ReadsByWidth()
    var
        TempBlob: Codeunit "Temp Blob";
        Export: XmlPort "Probe XP Fixed";
        Import: XmlPort "Probe XP Fixed";
        ALTUniversal: Record "ALT Universal";
        OutStr: OutStream;
        InStr: InStream;
        Cr: Text[1];
        Lf: Text[1];
    begin
        Initialize();
        Cr[1] := 13;
        Lf[1] := 10;
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Text Field" := 'abc';
        ALTUniversal."Decimal Field" := 12.5;
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 123456;
        ALTUniversal."Text Field" := 'toolongvalue';
        ALTUniversal."Decimal Field" := -1;
        ALTUniversal.Insert();
        Commit();

        TempBlob.CreateOutStream(OutStr);
        Export.SetDestination(OutStr);
        Export.Export();
        Assert.AreEqual('3120202020616263202020202031322E353020202020200D0A3132333435746F6F6C6F6E67762D312E30302020202020', HexOf(TempBlob), 'bytes: 1    abc     12.50     CRLF12345toolongv-1.00     ');

        Initialize();
        Feed('    1abc        12.50' + Cr + Lf + '    2xyz         3.00', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);
        Import.Import();
        Commit();
        Assert.AreEqual('1|abc|12.5| ; 2|xyz|3| ; ', RowsOf(), 'imported rows');
    end;
}
