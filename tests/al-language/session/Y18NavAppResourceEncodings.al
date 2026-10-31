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
        Observer.Observe('default lines', LinesDefault(Name));
        Observer.Observe('utf8 lines', Lines(Name, TextEncoding::UTF8));
        Observer.Observe('utf8 read', ReadOnce(Name, TextEncoding::UTF8));
        Observer.Observe('utf8 copy', Copied(Name, TextEncoding::UTF8));
        Observer.Observe('utf16 lines', Lines(Name, TextEncoding::UTF16));
        Observer.Observe('utf16 read', ReadOnce(Name, TextEncoding::UTF16));
        Observer.Observe('utf16 copy', Copied(Name, TextEncoding::UTF16));
        Observer.Observe('windows lines', Lines(Name, TextEncoding::Windows));
        Observer.Observe('windows read', ReadOnce(Name, TextEncoding::Windows));
        Observer.Observe('windows copy', Copied(Name, TextEncoding::Windows));
        Observer.Observe('msdos lines', Lines(Name, TextEncoding::MSDos));
        Observer.Observe('msdos read', ReadOnce(Name, TextEncoding::MSDos));
        Observer.Observe('msdos copy', Copied(Name, TextEncoding::MSDos));
        Observer.Finish();
    end;

    local procedure Lines(Name: Text; Encoding: TextEncoding): Text
    var
        S: InStream;
    begin
        NavApp.GetResource(Name, S, Encoding);
        exit(ReadLines(S));
    end;

    local procedure LinesDefault(Name: Text): Text
    var
        S: InStream;
    begin
        NavApp.GetResource(Name, S);
        exit(ReadLines(S));
    end;

    local procedure ReadOnce(Name: Text; Encoding: TextEncoding): Text
    var
        S: InStream;
        Content: Text;
        N: Integer;
    begin
        NavApp.GetResource(Name, S, Encoding);
        N := S.Read(Content);
        exit(Format(N) + ':' + Shown(Content) + '|eos=' + Format(S.EOS()));
    end;

    local procedure Copied(Name: Text; Encoding: TextEncoding): Text
    var
        TempRes: Record "LT Y18 Res Blob" temporary;
        S: InStream;
        Back: InStream;
        O: OutStream;
    begin
        NavApp.GetResource(Name, S, Encoding);
        TempRes.Id := 1;
        TempRes.Data.CreateOutStream(O);
        CopyStream(O, S);
        TempRes.Insert();
        TempRes.Data.CreateInStream(Back, TextEncoding::UTF8);
        exit(ReadLines(Back));
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
