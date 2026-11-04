// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-fieldseparator-property
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-fielddelimiter-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 50001 "ALT Shape 01", System Application codeunit "Temp Blob"; own xmlports 95480-95493
//   (their separator properties are under test)
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: the separator tokens of a VariableText xmlport in FieldDelimiter and FieldSeparator: <> (the empty token), <None>, <none>, <TAB>,
//   <tab>, <LF>, <CR>, <CR/LF>, <NewLine>, a token after a literal (;<TAB>) and two tokens (<TAB><TAB>). Export of two rows (the bytes, with
//   CR, LF and TAB shown as \r, \n and \t and bytes above 127 as \xNN), and import of lines with and without the delimiter (the rows made).
//   (AL Runner issue 6965: an ISV's import declares FieldDelimiter = '<>' with FieldSeparator = '<TAB>'.)
// Facts (29.0): <> is not a token: export writes the two characters <> as the delimiter (or separator); import of a value with or without
//   the <> around it reads the value. Tokens are case-sensitive: <tab> and <none> are written as these five and six characters. <TAB>, <LF>,
//   <CR>, <CR/LF> (CR LF), <NewLine> (CR LF), <None> (nothing), ;<TAB> and <TAB><TAB> are written as their characters. Export writes the
//   UTF-8 byte order mark first and no record separator after the last row.
// BC versions: 27.5, 28.5, 29.0

xmlport 95480 "XP Sep Delim Empty Sep Tab"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<>';
    FieldSeparator = '<TAB>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95481 "XP Sep Delim Empty Sep Comma"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95482 "XP Sep Delim Tab Sep Semi"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<TAB>';
    FieldSeparator = ';';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95483 "XP Sep Delim None Sep Empty"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95484 "XP Sep Sep LF"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<LF>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95485 "XP Sep Sep CR"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<CR>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95486 "XP Sep Sep CRLF"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<CR/LF>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95487 "XP Sep Sep NewLine"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<NewLine>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95488 "XP Sep Sep Tab Lower"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<tab>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95489 "XP Sep Sep Semi Tab"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = ';<TAB>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95490 "XP Sep Sep Tab Tab"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB><TAB>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95491 "XP Sep Sep None"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = '<None>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95492 "XP Sep Delim Empty Sep None"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<>';
    FieldSeparator = '<None>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 95493 "XP Sep Delim None Lower"
{
    // local object: its FieldDelimiter and FieldSeparator are under test
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<none>';
    FieldSeparator = '<TAB>';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

codeunit 95482 "XP Separator Tokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Hex(Value: Integer): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (Value div 16) + 1, 1) + CopyStr(Digits, (Value mod 16) + 1, 1));
    end;

    // Exports the rows 1 'Alpha' and 2 'Be ta' through the port; the bytes as text, a byte above 127 as \xNN.
    local procedure ExportRows(PortId: Integer): Text
    var
        Shape: Record "ALT Shape 01";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        Ch: Text[1];
        Result: Text;
    begin
        Shape.DeleteAll();
        Shape.Id := 1;
        Shape.Name := 'Alpha';
        Shape.Insert();
        Shape.Id := 2;
        Shape.Name := 'Be ta';
        Shape.Insert();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(PortId, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            if (B > 0) and (B < 128) then begin
                Ch[1] := B;
                Result += Ch;
            end else
                Result += '\x' + Hex(B);
        end;
        exit(Result);
    end;

    // Imports Data (written as UTF-8) through the port into an empty table; the rows it made.
    local procedure ImportRows(PortId: Integer; Data: Text): Text
    var
        Shape: Record "ALT Shape 01";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Result: Text;
    begin
        Shape.DeleteAll();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Data);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(PortId, InS);
        if Shape.FindSet() then
            repeat
                Result += Format(Shape.Id) + '=[' + Shape.Name + '];';
            until Shape.Next() = 0;
        exit(Result);
    end;

    local procedure Tab(): Text
    var
        C: Text[1];
    begin
        C[1] := 9;
        exit(C);
    end;

    local procedure Cr(): Text
    var
        C: Text[1];
    begin
        C[1] := 13;
        exit(C);
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure VariableText_Export_DelimEmptySepTab()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '<TAB>'
        Observer.Observe('export', ExportRows(95480));
        Observer.Expect('export', '\xEF\xBB\xBF<>1<>\t<>Alpha<>\r\n<>2<>\t<>Be ta<>');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimEmptySepTab_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '<TAB>'
        Observer.Observe('rows', ImportRows(95480, '1' + Tab + 'Hauptstrasse' + Cr + Lf + '2' + Tab + 'Süd' + Cr + Lf));
        Observer.Expect('rows', '1=[Hauptstrasse];2=[Süd];');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimEmptySepTab_LeadingEmptyToken()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '<TAB>'
        Observer.Observe('rows', ImportRows(95480, '<>1<>' + Tab + '<>Hauptstrasse<>' + Cr + Lf + '<>2<>' + Tab + '<>Süd<>' + Cr + Lf));
        Observer.Expect('rows', '1=[Hauptstrasse];2=[Süd];');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimEmptySepTab_Quoted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '<TAB>'
        asserterror ImportRows(95480, '"1"' + Tab + '"Hauptstrasse"' + Cr + Lf);
        Observer.ObserveError('import');
        Observer.Finish();
    end;

    [Test]
    procedure VariableText_Export_DelimEmptySepComma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '(default)'
        Observer.Observe('export', ExportRows(95481));
        Observer.Expect('export', '\xEF\xBB\xBF<>1<>,<>Alpha<>\r\n<>2<>,<>Be ta<>');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimEmptySepComma_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '(default)'
        Observer.Observe('rows', ImportRows(95481, '1,Alpha' + Cr + Lf + '2,Be ta' + Cr + Lf));
        Observer.Expect('rows', '1=[Alpha];2=[Be ta];');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_DelimTabSepSemi()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<TAB>', FieldSeparator = ';'
        Observer.Observe('export', ExportRows(95482));
        Observer.Expect('export', '\xEF\xBB\xBF\t1\t;\tAlpha\t\r\n\t2\t;\tBe ta\t');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimTabSepSemi_Delimited()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<TAB>', FieldSeparator = ';'
        Observer.Observe('rows', ImportRows(95482, Tab + '1' + Tab + ';' + Tab + 'Alpha' + Tab + Cr + Lf + Tab + '2' + Tab + ';' + Tab + 'Be;ta' + Tab + Cr + Lf));
        Observer.Expect('rows', '1=[Alpha];2=[Be;ta];');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_DelimNoneSepEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<>'
        Observer.Observe('export', ExportRows(95483));
        Observer.Expect('export', '\xEF\xBB\xBF1<>Alpha\r\n2<>Be ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimNoneSepEmpty_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<>'
        asserterror ImportRows(95483, '1Alpha' + Cr + Lf);
        Observer.ObserveError('import');
        Observer.Finish();
    end;

    [Test]
    procedure VariableText_Export_SepLF()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<LF>'
        Observer.Observe('export', ExportRows(95484));
        Observer.Expect('export', '\xEF\xBB\xBF1\nAlpha\r\n2\nBe ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_SepCR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<CR>'
        Observer.Observe('export', ExportRows(95485));
        Observer.Expect('export', '\xEF\xBB\xBF1\rAlpha\r\n2\rBe ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_SepCRLF()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<CR/LF>'
        Observer.Observe('export', ExportRows(95486));
        Observer.Expect('export', '\xEF\xBB\xBF1\r\nAlpha\r\n2\r\nBe ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_SepNewLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<NewLine>'
        Observer.Observe('export', ExportRows(95487));
        Observer.Expect('export', '\xEF\xBB\xBF1\r\nAlpha\r\n2\r\nBe ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_SepTabLower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<tab>'
        Observer.Observe('export', ExportRows(95488));
        Observer.Expect('export', '\xEF\xBB\xBF1<tab>Alpha\r\n2<tab>Be ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_SepTabLower_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<tab>'
        asserterror ImportRows(95488, '1' + Tab + 'Alpha' + Cr + Lf + '2' + Tab + 'Be ta' + Cr + Lf);
        Observer.ObserveError('import');
        Observer.Finish();
    end;

    [Test]
    procedure VariableText_Export_SepSemiTab()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = ';<TAB>'
        Observer.Observe('export', ExportRows(95489));
        Observer.Expect('export', '\xEF\xBB\xBF1;\tAlpha\r\n2;\tBe ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_SepSemiTab_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = ';<TAB>'
        Observer.Observe('rows', ImportRows(95489, '1;' + Tab + 'Alpha' + Cr + Lf + '2;' + Tab + 'Be ta' + Cr + Lf));
        Observer.Expect('rows', '1=[Alpha];2=[Be ta];');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_SepTabTab()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<TAB><TAB>'
        Observer.Observe('export', ExportRows(95490));
        Observer.Expect('export', '\xEF\xBB\xBF1\t\tAlpha\r\n2\t\tBe ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_SepTabTab_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<TAB><TAB>'
        Observer.Observe('rows', ImportRows(95490, '1' + Tab + Tab + 'Alpha' + Cr + Lf + '2' + Tab + Tab + 'Be ta' + Cr + Lf));
        Observer.Expect('rows', '1=[Alpha];2=[Be ta];');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_SepNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<None>', FieldSeparator = '<None>'
        Observer.Observe('export', ExportRows(95491));
        Observer.Expect('export', '\xEF\xBB\xBF1Alpha\r\n2Be ta');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_DelimEmptySepNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<>', FieldSeparator = '<None>'
        Observer.Observe('export', ExportRows(95492));
        Observer.Expect('export', '\xEF\xBB\xBF<>1<><>Alpha<>\r\n<>2<><>Be ta<>');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Export_DelimNoneLower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<none>', FieldSeparator = '<TAB>'
        Observer.Observe('export', ExportRows(95493));
        Observer.Expect('export', '\xEF\xBB\xBF<none>1<none>\t<none>Alpha<none>\r\n<none>2<none>\t<none>Be ta<none>');
        Observer.Verify();
    end;

    [Test]
    procedure VariableText_Import_DelimNoneLower_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // FieldDelimiter = '<none>', FieldSeparator = '<TAB>'
        Observer.Observe('rows', ImportRows(95493, '1' + Tab + 'Alpha' + Cr + Lf));
        Observer.Expect('rows', '1=[Alpha];');
        Observer.Verify();
    end;
}
