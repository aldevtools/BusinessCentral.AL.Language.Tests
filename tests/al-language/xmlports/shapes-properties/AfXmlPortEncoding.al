// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-encoding-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own xmlports 78311 and 78312, test codeunit 78313; table "LT AF Row" (78301)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: XmlPort property Encoding with UTF8 and UTF16 (Format = Xml): the bytes an export writes (length, first bytes, XML declaration) and what an import
// reads when the document is UTF-8 or UTF-16 with a matching or a non-matching declaration.
// BC versions: 27, 28, 29

xmlport 78311 "LT AF XP Enc Utf8"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AF Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

xmlport 78312 "LT AF XP Enc Utf16"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF16;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AF Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

codeunit 78313 "LT AF XmlPort Encoding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AF Row";
        Umlaut: Text[1];
    begin
        Row.DeleteAll();
        Umlaut[1] := 252;
        Row.Id := 1;
        Row.Name := 'G' + Umlaut + 'n';
        Row.Insert();
    end;

    local procedure Bytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        Result: Text;
        n: Integer;
        Num: Integer;
    begin
        TempBlob.CreateInStream(InS);
        Result := Format(TempBlob.Length()) + ':';
        while (not InS.EOS()) and (n < 8) do begin
            InS.Read(B);
            Num := B;
            Result += Format(Num) + ',';
            n += 1;
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryDecode(var TempBlob: Codeunit "Temp Blob"; Enc: TextEncoding; var Result: Text)
    var
        InS: InStream;
        Line: Text;
    begin
        Result := '';
        TempBlob.CreateInStream(InS, Enc);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
    end;

    local procedure Decl(var TempBlob: Codeunit "Temp Blob"; Enc: TextEncoding): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryDecode(TempBlob, Enc, Result) then
            exit(Result);
        exit('unreadable: ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryExport8(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Enc Utf8";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryExport16(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Enc Utf16";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryImport8(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Enc Utf8";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    [TryFunction]
    local procedure TryImport16(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Enc Utf16";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure Doc(var TempBlob: Codeunit "Temp Blob"; Enc: TextEncoding; Declared: Text; Id: Integer)
    var
        OutS: OutStream;
        Umlaut: Text[1];
    begin
        Umlaut[1] := 252;
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, Enc);
        OutS.WriteText('<?xml version="1.0" encoding="' + Declared + '"?><Root><Row><Id>' + Format(Id) + '</Id><Name>H' + Umlaut + 'r</Name></Row></Root>');
    end;

    local procedure RowName(Id: Integer): Text
    var
        Row: Record "LT AF Row";
        Result: Text;
        i: Integer;
        Code: Integer;
    begin
        if not Row.Get(Id) then
            exit('absent');
        for i := 1 to StrLen(Row.Name) do begin
            Code := Row.Name[i];
            Result += Format(Code) + ',';
        end;
        exit(Result);
    end;

    local procedure ImportCase(var Observer: Codeunit "Probe Observer"; Name: Text; Xport16: Boolean; Enc: TextEncoding; Declared: Text; Id: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Ok: Boolean;
    begin
        Doc(TempBlob, Enc, Declared, Id);
        ClearLastError();
        if Xport16 then
            Ok := TryImport16(TempBlob)
        else
            Ok := TryImport8(TempBlob);
        if Ok then
            Observer.Observe(Name, 'ok ' + RowName(Id))
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure AF_Encoding_Export()
    var
        Umlaut: Text[1];
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Umlaut[1] := 252;
        Seed();
        ClearLastError();
        if TryExport8(TempBlob) then begin
            Observer.Observe('utf8 export bytes', Bytes(TempBlob));
            Observer.Observe('utf8 export as utf8', Decl(TempBlob, TextEncoding::UTF8));
        end else
            Observer.ObserveError('utf8 export');
        Clear(TempBlob);
        ClearLastError();
        if TryExport16(TempBlob) then begin
            Observer.Observe('utf16 export bytes', Bytes(TempBlob));
            Observer.Observe('utf16 export as utf16', Decl(TempBlob, TextEncoding::UTF16));
        end else
            Observer.ObserveError('utf16 export');
        Observer.Expect('utf8 export bytes', '129:60,63,120,109,108,32,118,101,');
        Observer.Expect('utf8 export as utf8', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Row>    <Id>1</Id>    <Name>G' + Umlaut + 'n</Name>  </Row></Root>');
        Observer.Expect('utf16 export bytes', '260:255,254,60,0,63,0,120,0,');
        Observer.Expect('utf16 export as utf16', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root>  <Row>    <Id>1</Id>    <Name>G' + Umlaut + 'n</Name>  </Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Encoding_Import_Utf8Property_Utf8Doc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ImportCase(Observer, 'xp utf8, doc utf8 declared utf-8', false, TextEncoding::UTF8, 'utf-8', 11);
        Observer.Expect('xp utf8, doc utf8 declared utf-8', 'ok 72,252,114,');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Encoding_Import_Utf8Property_Utf16Doc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ImportCase(Observer, 'xp utf8, doc utf16 declared utf-16', false, TextEncoding::UTF16, 'utf-16', 12);
        Observer.Expect('xp utf8, doc utf16 declared utf-16', 'ok 72,252,114,');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Encoding_Import_Utf16Property_Utf8Doc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ImportCase(Observer, 'xp utf16, doc utf8 declared utf-8', true, TextEncoding::UTF8, 'utf-8', 13);
        Observer.Expect('xp utf16, doc utf8 declared utf-8', 'ok 72,252,114,');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Encoding_Import_Utf16Property_Utf16Doc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ImportCase(Observer, 'xp utf16, doc utf16 declared utf-16', true, TextEncoding::UTF16, 'utf-16', 14);
        Observer.Expect('xp utf16, doc utf16 declared utf-16', 'ok 72,252,114,');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Encoding_Import_Utf8Property_Utf8DocDeclaredUtf16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ImportCase(Observer, 'xp utf8, doc utf8 declared utf-16', false, TextEncoding::UTF8, 'utf-16', 15);
        Observer.Expect('xp utf8, doc utf8 declared utf-16|text', 'There is no Unicode byte order mark. Cannot switch to Unicode.');
        Observer.Expect('xp utf8, doc utf8 declared utf-16|code', 'XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Encoding_Import_Utf8Property_Utf16DocDeclaredUtf8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ImportCase(Observer, 'xp utf8, doc utf16 declared utf-8', false, TextEncoding::UTF16, 'utf-8', 16);
        Observer.Expect('xp utf8, doc utf16 declared utf-8|text', 'Name cannot begin with the ''.'' character, hexadecimal value 0x00. Line 1, position 40.');
        Observer.Expect('xp utf8, doc utf16 declared utf-8|code', 'XmlPortImport:Xml');
        Observer.Verify();
    end;
}
