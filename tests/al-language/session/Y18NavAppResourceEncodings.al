// al-runner issue 6492: NavApp.GetResource(Name, InStream, Encoding) with UTF8, UTF16, Windows and MSDos (and no encoding),
// on resources saved in different byte forms. The UTF8 InStream read of an ASCII file is pinned in TestNavAppGetResource.al,
// GetResourceAsText encodings of an ASCII file in W5NavAppResources.al.
// The corpus app packages session/res; the five files in session/res/y18 hold the same two lines, 'Zürich' CR LF 'Größe 5 €'
// (no line break at the end), saved as:
//   utf16le-bom.txt    FF FE + UTF-16LE (36 bytes)
//   utf16le-nobom.txt  UTF-16LE, no byte order mark (34 bytes)
//   utf8-bom.txt       EF BB BF + UTF-8 (25 bytes)
//   utf8-nobom.txt     UTF-8, no byte order mark (22 bytes)
//   windows1252.txt    Windows-1252: ü FC, ö F6, ß DF, € 80 (17 bytes)
// Each test reads one file with every encoding, three ways:
//   lines  ReadText until EOS: per line the count ReadText returned and the line
//   read   one InStream.Read(Text) on a fresh stream: the count it returned and the text
//   copy   CopyStream into the Blob of a temporary record, then ReadText until EOS from CreateInStream(TextEncoding::UTF8)
// 'default' is GetResource(Name, InStream) without an encoding (lines only). A read that raises shows as error:<text>|<code>.
// A character outside 32..126 is shown as <code> (its integer value), so the observed text is plain ASCII.

table 91900 "LT Y18 Res Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91901 "LT Y18 Res Encodings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Utf16LeWithBom()
    begin
        ReadAll('y18/utf16le-bom.txt');
    end;

    [Test]
    procedure Utf16LeWithoutBom()
    begin
        ReadAll('y18/utf16le-nobom.txt');
    end;

    [Test]
    procedure Utf8WithBom()
    begin
        ReadAll('y18/utf8-bom.txt');
    end;

    [Test]
    procedure Utf8WithoutBom()
    begin
        ReadAll('y18/utf8-nobom.txt');
    end;

    [Test]
    procedure Windows1252()
    begin
        ReadAll('y18/windows1252.txt');
    end;

    local procedure ReadAll(Name: Text)
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default lines', Probe(Name, 'lines', TextEncoding::UTF8, true));
        Observer.Observe('utf8 lines', Probe(Name, 'lines', TextEncoding::UTF8, false));
        Observer.Observe('utf8 read', Probe(Name, 'read', TextEncoding::UTF8, false));
        Observer.Observe('utf8 copy', Probe(Name, 'copy', TextEncoding::UTF8, false));
        Observer.Observe('utf16 lines', Probe(Name, 'lines', TextEncoding::UTF16, false));
        Observer.Observe('utf16 read', Probe(Name, 'read', TextEncoding::UTF16, false));
        Observer.Observe('utf16 copy', Probe(Name, 'copy', TextEncoding::UTF16, false));
        Observer.Observe('windows lines', Probe(Name, 'lines', TextEncoding::Windows, false));
        Observer.Observe('windows read', Probe(Name, 'read', TextEncoding::Windows, false));
        Observer.Observe('windows copy', Probe(Name, 'copy', TextEncoding::Windows, false));
        Observer.Observe('msdos lines', Probe(Name, 'lines', TextEncoding::MSDos, false));
        Observer.Observe('msdos read', Probe(Name, 'read', TextEncoding::MSDos, false));
        Observer.Observe('msdos copy', Probe(Name, 'copy', TextEncoding::MSDos, false));
        Observer.Finish();
    end;

    // The read as text, or 'error:' + the error text and code when the read raises.
    local procedure Probe(Name: Text; Kind: Text; Encoding: TextEncoding; NoEncoding: Boolean): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryRead(Name, Kind, Encoding, NoEncoding, Result) then
            exit(Result);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRead(Name: Text; Kind: Text; Encoding: TextEncoding; NoEncoding: Boolean; var Result: Text)
    var
        TempRes: Record "LT Y18 Res Blob" temporary;
        S: InStream;
        Back: InStream;
        O: OutStream;
        Content: Text;
        N: Integer;
    begin
        if NoEncoding then
            NavApp.GetResource(Name, S)
        else
            NavApp.GetResource(Name, S, Encoding);
        case Kind of
            'lines':
                Result := ReadLines(S);
            'read':
                begin
                    N := S.Read(Content);
                    Result := Format(N) + ':' + Shown(Content) + '|eos=' + Format(S.EOS());
                end;
            'copy':
                begin
                    TempRes.Id := 1;
                    TempRes.Data.CreateOutStream(O);
                    CopyStream(O, S);
                    TempRes.Insert();
                    TempRes.Data.CreateInStream(Back, TextEncoding::UTF8);
                    Result := ReadLines(Back);
                end;
        end;
    end;

    local procedure ReadLines(var S: InStream): Text
    var
        Line: Text;
        Result: Text;
        N: Integer;
        Guard: Integer;
    begin
        while (not S.EOS()) and (Guard < 10) do begin
            Guard += 1;
            N := S.ReadText(Line);
            Result += Format(N) + ':' + Shown(Line) + '|';
        end;
        exit(Result);
    end;

    local procedure Shown(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if (Code < 32) or (Code > 126) then
                Result += '<' + Format(Code, 0, 9) + '>'
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;
}
