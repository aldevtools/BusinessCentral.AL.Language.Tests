// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 85840 (DdStreamLeadObjects.al), System Application
// "Temp Blob", "Base64 Convert", "Data Compression", Base Application "CSV Buffer".
// Topic: corpus issue 671 (odd AL behavior leads, part F), items 61 to 75: CSV Buffer with Windows-1252 bytes, an XML encoding
// header inside a Text, Media and Blob after ChangeCompany, OutStream.Write(InStream), a shorter Blob write, zip entries from one
// reused Temp Blob, Blob field assignment, the UTF-8 BOM, Base64 decoding of line breaks, Base64 and BigText, InStream var parameters,
// and InStream short reads. Items 65, 69, 70 and 71 were pinned already (see the issue comment); only the unpinned parts of 62, 67, 68,
// 72 and 75 are here.
// Facts (BC 29.0 local, checked on 27.5 and 28.5 by CI): CSV Buffer.LoadDataFromStream decodes as UTF-8 whatever the InStream
// encoding (0xE4 becomes U+FFFD); the overload with code page 1252 gives the a-umlaut. An encoding= header inside a Text does not
// change the bytes (default OutStream writes u-umlaut as MSDos 0x81, UTF8 C3 BC, Windows FC, HttpContent C3 BC). Media and Blob
// fields of a record moved with ChangeCompany export the other company's data. OutStream.Write(InStream), direct or as a Variant,
// fails with 'The type InStream is not supported.' (NotSupportedType). Two zip entries added from one reused Temp Blob, larger
// first: the second entry keeps the tail of the first ('small' + 35 L, 40 bytes). A Blob field assigned from a record without
// CalcFields stores nothing. A UTF-8 InStream drops the BOM; XmlDocument.WriteTo writes a BOM and an xml declaration. Base64
// decoding ignores CR LF. An InStream passed by value or by var shares its position with the caller; an InStream created from a
// Temp Blob local to the callee has Length 0 after the callee returns. InStream.Read(Text, 5) on 3 bytes reads 3 and does not
// fail without a return value.
// BC versions: 27.5, 28.5, 29.0

codeunit 85841 "LT DD Stream Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OtherCompanyTok: Label 'LT DD Other', Locked = true;
        PngTok: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Locked = true;

    // ---------------------------------------------------------------- helpers

    local procedure Hex(var TempBlob: Codeunit "Temp Blob"): Text
    var
        I: InStream;
    begin
        TempBlob.CreateInStream(I);
        exit(HexOf(I, 0));
    end;

    local procedure HexOf(var I: InStream; Skip: Integer): Text
    var
        B: Byte;
        N: Integer;
        Result: Text;
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        while not I.EOS() do begin
            I.Read(B);
            N += 1;
            if N > Skip then begin
                if Result <> '' then
                    Result += ' ';
                Result += CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1);
            end;
        end;
        exit(Result);
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        Result: Text;
        C: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            if Result <> '' then
                Result += ',';
            Result += Format(C);
        end;
        exit(Result);
    end;

    local procedure Chars(A: Integer; B: Integer; C: Integer): Text
    var
        T: Text[3];
    begin
        T[1] := A;
        T[2] := B;
        T[3] := C;
        exit(T);
    end;

    local procedure Crlf(): Text
    var
        T: Text[2];
    begin
        T[1] := 13;
        T[2] := 10;
        exit(T);
    end;

    local procedure WriteBlobText(var Rec: Record "LT DD Blob Row"; Value: Text)
    var
        O: OutStream;
    begin
        Rec.Data.CreateOutStream(O);
        O.WriteText(Value);
    end;

    local procedure ReadBlobText(Id: Integer): Text
    var
        Rec: Record "LT DD Blob Row";
        I: InStream;
        T: Text;
    begin
        Rec.Get(Id);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(I);
        I.ReadText(T);
        exit(T);
    end;

    local procedure NewRow(Id: Integer; Value: Text)
    var
        Rec: Record "LT DD Blob Row";
    begin
        Rec.Init();
        Rec.Id := Id;
        if Value <> '' then
            WriteBlobText(Rec, Value);
        Rec.Insert();
    end;

    // ---------------------------------------------------------------- item 61: CSV Buffer with Windows-1252 bytes

    [Test]
    procedure Item61_CsvBufferWindows1252()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        TempCSV: Record "CSV Buffer" temporary;
        TempCSV2: Record "CSV Buffer" temporary;
        TempCSV3: Record "CSV Buffer" temporary;
        O: OutStream;
        I: InStream;
    begin
        // K;<a-umlaut>x CR LF 1;2 written as Windows-1252 bytes
        TempBlob.CreateOutStream(O, TextEncoding::Windows);
        O.WriteText('K;' + Chars(228, 120, 59) + 'Z' + Crlf() + '1;2');
        Observer.Observe('bytes', Hex(TempBlob));

        TempBlob.CreateInStream(I);
        TempCSV.LoadDataFromStream(I, ';');
        Observer.Observe('default', CsvCells(TempCSV));

        TempBlob.CreateInStream(I, TextEncoding::Windows);
        TempCSV2.LoadDataFromStream(I, ';');
        Observer.Observe('instream windows', CsvCells(TempCSV2));

        TempBlob.CreateInStream(I);
        TempCSV3.LoadDataFromStream(I, ';', '', 1252);
        Observer.Observe('code page 1252', CsvCells(TempCSV3));
        Observer.Expect('bytes', '4B 3B E4 78 3B 5A 0D 0A 31 3B 32');
        Observer.Expect('default', '1/1=K [75];1/2=�x [65533,120];1/3=Z [90];2/1=1 [49];2/2=2 [50];');
        Observer.Expect('instream windows', '1/1=K [75];1/2=�x [65533,120];1/3=Z [90];2/1=1 [49];2/2=2 [50];');
        Observer.Expect('code page 1252', '1/1=K [75];1/2=äx [228,120];1/3=Z [90];2/1=1 [49];2/2=2 [50];');
        Observer.Verify();
    end;

    local procedure CsvCells(var TempCSV: Record "CSV Buffer" temporary): Text
    var
        Result: Text;
    begin
        if TempCSV.FindSet() then
            repeat
                Result += StrSubstNo('%1/%2=%3 [%4];', TempCSV."Line No.", TempCSV."Field No.", TempCSV.Value, Codes(TempCSV.Value));
            until TempCSV.Next() = 0;
        exit(Result);
    end;

    // ---------------------------------------------------------------- item 62: XML encoding header inside a Text

    [Test]
    procedure Item62_XmlEncodingHeaderInText()
    var
        Observer: Codeunit "Probe Observer";
        Header: Text;
        Plain: Text;
    begin
        Header := '<?xml version="1.0" encoding="iso-8859-15"?><a>';
        Plain := '<a>';
        Observer.Observe('outstream default, header', StreamTail(Header, 0));
        Observer.Observe('outstream default, no header', StreamTail(Plain, 0));
        Observer.Observe('outstream utf8, header', StreamTail(Header, 1));
        Observer.Observe('outstream windows, header', StreamTail(Header, 2));
        Observer.Observe('httpcontent, header', ContentTail(Header));
        Observer.Observe('httpcontent, no header', ContentTail(Plain));
        Observer.Expect('outstream default, header', '81 3C 2F 61 3E');
        Observer.Expect('outstream default, no header', '81 3C 2F 61 3E');
        Observer.Expect('outstream utf8, header', 'C3 BC 3C 2F 61 3E');
        Observer.Expect('outstream windows, header', 'FC 3C 2F 61 3E');
        Observer.Expect('httpcontent, header', 'C3 BC 3C 2F 61 3E');
        Observer.Expect('httpcontent, no header', 'C3 BC 3C 2F 61 3E');
        Observer.Verify();
    end;

    // the bytes written for <prefix><u-umlaut></a>, without the bytes of the prefix
    local procedure StreamTail(Prefix: Text; Kind: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        O: OutStream;
        I: InStream;
    begin
        case Kind of
            0:
                TempBlob.CreateOutStream(O);
            1:
                TempBlob.CreateOutStream(O, TextEncoding::UTF8);
            2:
                TempBlob.CreateOutStream(O, TextEncoding::Windows);
        end;
        O.WriteText(Prefix + Chars(252, 60, 47) + 'a>');
        TempBlob.CreateInStream(I);
        exit(HexOf(I, StrLen(Prefix)));
    end;

    local procedure ContentTail(Prefix: Text): Text
    var
        Content: HttpContent;
        I: InStream;
    begin
        Content.WriteFrom(Prefix + Chars(252, 60, 47) + 'a>');
        Content.ReadAs(I);
        exit(HexOf(I, StrLen(Prefix)));
    end;

    // ---------------------------------------------------------------- item 63: Media and Blob after ChangeCompany

    [Test]
    procedure Item63_MediaAfterChangeCompany()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Rec: Record "LT DD Blob Row";
        Other: Record "LT DD Blob Row";
        Here: Record "LT DD Blob Row";
        TempBlob: Codeunit "Temp Blob";
        OutBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        O: OutStream;
        I: InStream;
        T: Text;
    begin
        if Company.Get(OtherCompanyTok) then
            Company.Delete(true);
        Company.Init();
        Company.Name := OtherCompanyTok;
        Company.Insert();
        Here.DeleteAll();

        TempBlob.CreateOutStream(O);
        Base64.FromBase64(PngTok, O);
        TempBlob.CreateInStream(I);
        Rec.ChangeCompany(OtherCompanyTok);
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Pic.ImportStream(I, 'png');
        WriteBlobText(Rec, 'other company text');
        Rec.Insert();

        Other.ChangeCompany(OtherCompanyTok);
        Observer.Observe('get', Format(Other.Get(1)));
        Observer.Observe('local get', Format(Here.Get(1)));
        Observer.Observe('pic hasvalue', Format(Other.Pic.HasValue()));
        Observer.Observe('pic mediaid null', Format(IsNullGuid(Other.Pic.MediaId())));
        OutBlob.CreateOutStream(O);
        Observer.Observe('pic exportstream', Format(Other.Pic.ExportStream(O)));
        Observer.Observe('pic exported length', Format(OutBlob.Length()));
        Other.CalcFields(Data);
        Observer.Observe('data hasvalue', Format(Other.Data.HasValue()));
        Other.Data.CreateInStream(I);
        I.ReadText(T);
        Observer.Observe('data text', T);
        Other.Delete();
        Company.Get(OtherCompanyTok);
        Company.Delete(true);
        Observer.Expect('get', 'Yes');
        Observer.Expect('local get', 'No');
        Observer.Expect('pic hasvalue', 'Yes');
        Observer.Expect('pic mediaid null', 'No');
        Observer.Expect('pic exportstream', 'Yes');
        // BC 27.5, 28.5 and Windows BC 29.0 (Windows BC 29.0 check 2026-10-20) export the 1x1 png as 99 bytes (re-encoded). Before the
        // bc-linux #161 fix Linux BC 29.0 gave 70 (kept the imported bytes).
        Observer.Expect('pic exported length', '99');
        Observer.Expect('data hasvalue', 'Yes');
        Observer.Expect('data text', 'other company text');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 64: OutStream.Write(InStream)

    [Test]
    procedure Item64_OutStreamWriteInStream()
    var
        Observer: Codeunit "Probe Observer";
        Source: Codeunit "Temp Blob";
        Target: Codeunit "Temp Blob";
        O: OutStream;
        I: InStream;
        V: Variant;
    begin
        Source.CreateOutStream(O);
        O.WriteText('fuu');
        Source.CreateInStream(I);
        Target.CreateOutStream(O);
        Observer.Observe('direct ok', Format(TryWriteInStream(O, I)));
        Observer.ObserveError('direct');
        Observer.Observe('direct bytes', Hex(Target));

        Clear(Target);
        Source.CreateInStream(I);
        Target.CreateOutStream(O);
        V := I;
        Observer.Observe('variant ok', Format(TryWriteVariant(O, V)));
        Observer.ObserveError('variant');
        Observer.Observe('variant bytes', Hex(Target));
        Observer.Expect('direct ok', 'No');
        Observer.Expect('direct|text', 'The type InStream is not supported.');
        Observer.Expect('direct|code', 'NotSupportedType');
        Observer.Expect('direct bytes', '');
        Observer.Expect('variant ok', 'No');
        Observer.Expect('variant|text', 'The type InStream is not supported.');
        Observer.Expect('variant|code', 'NotSupportedType');
        Observer.Expect('variant bytes', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWriteInStream(var O: OutStream; var I: InStream)
    begin
        O.Write(I);
    end;

    [TryFunction]
    local procedure TryWriteVariant(var O: OutStream; V: Variant)
    begin
        O.Write(V);
    end;

    // ---------------------------------------------------------------- item 66: zip entries from one reused Temp Blob

    [Test]
    procedure Item66_ZipEntriesFromReusedTempBlob()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('larger first', ZipTwo('LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL', 'small'));
        Observer.Observe('smaller first', ZipTwo('small', 'LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL'));
        Observer.Expect('larger first', 'first.txt 40 LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;second.txt 40 smallLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;');
        Observer.Expect('smaller first', 'first.txt 5 small;second.txt 40 LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;');
        Observer.Verify();
    end;

    local procedure ZipTwo(First: Text; Second: Text): Text
    var
        DataCompression: Codeunit "Data Compression";
        Reader: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ZipBlob: Codeunit "Temp Blob";
        EntryBlob: Codeunit "Temp Blob";
        Entries: List of [Text];
        Entry: Text;
        O: OutStream;
        I: InStream;
        T: Text;
        Len: Integer;
        Result: Text;
    begin
        DataCompression.CreateZipArchive();
        TempBlob.CreateOutStream(O);
        O.WriteText(First);
        TempBlob.CreateInStream(I);
        DataCompression.AddEntry(I, 'first.txt');
        TempBlob.CreateOutStream(O);
        O.WriteText(Second);
        TempBlob.CreateInStream(I);
        DataCompression.AddEntry(I, 'second.txt');
        DataCompression.SaveZipArchive(ZipBlob);
        DataCompression.CloseZipArchive();

        ZipBlob.CreateInStream(I);
        Reader.OpenZipArchive(I, false);
        Reader.GetEntryList(Entries);
        foreach Entry in Entries do begin
            Clear(EntryBlob);
            EntryBlob.CreateOutStream(O);
            Len := Reader.ExtractEntry(Entry, O);
            EntryBlob.CreateInStream(I);
            I.ReadText(T);
            Result += StrSubstNo('%1 %2 %3;', Entry, Len, T);
        end;
        Reader.CloseZipArchive();
        exit(Result);
    end;

    // ---------------------------------------------------------------- item 67: assigning a Blob field to another Blob field

    [Test]
    procedure Item67_BlobFieldAssignment()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT DD Blob Row";
        Target: Record "LT DD Blob Row";
        TempTarget: Record "LT DD Blob Row" temporary;
        I: InStream;
        T: Text;
    begin
        Source.DeleteAll();
        NewRow(1, 'source text');

        // without CalcFields on the source
        Source.Get(1);
        Target.Init();
        Target.Id := 2;
        Target.Data := Source.Data;
        Target.Insert();
        Observer.Observe('no calcfields', ReadBlobText(2));

        // with CalcFields on the source
        Source.Get(1);
        Source.CalcFields(Data);
        Target.Init();
        Target.Id := 3;
        Target.Data := Source.Data;
        Observer.Observe('in memory hasvalue', Format(Target.Data.HasValue()));
        Target.Insert();
        Observer.Observe('calcfields', ReadBlobText(3));

        // a temporary target
        TempTarget.Init();
        TempTarget.Id := 4;
        TempTarget.Data := Source.Data;
        TempTarget.Insert();
        TempTarget.Get(4);
        TempTarget.CalcFields(Data);
        TempTarget.Data.CreateInStream(I);
        I.ReadText(T);
        Observer.Observe('temporary', T);
        Observer.Expect('no calcfields', '');
        Observer.Expect('in memory hasvalue', 'Yes');
        Observer.Expect('calcfields', 'source text');
        Observer.Expect('temporary', 'source text');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 68: UTF-8 BOM

    [Test]
    procedure Item68_Utf8Bom()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        O: OutStream;
        I: InStream;
        T: Text;
        Doc: XmlDocument;
        Decl: XmlDeclaration;
    begin
        TempBlob.CreateOutStream(O);
        WriteBytes(O, 239, 187, 191);
        O.WriteText('abc');
        Observer.Observe('bytes', Hex(TempBlob));
        TempBlob.CreateInStream(I);
        I.ReadText(T);
        Observer.Observe('readtext default', StrSubstNo('%1 [%2]', StrLen(T), Codes(T)));
        TempBlob.CreateInStream(I, TextEncoding::UTF8);
        I.ReadText(T);
        Observer.Observe('readtext utf8', StrSubstNo('%1 [%2]', StrLen(T), Codes(T)));
        TempBlob.CreateInStream(I, TextEncoding::UTF8);
        I.Read(T);
        Observer.Observe('read utf8', StrSubstNo('%1 [%2]', StrLen(T), Codes(T)));
        TempBlob.CreateInStream(I, TextEncoding::Windows);
        I.ReadText(T);
        Observer.Observe('readtext windows', StrSubstNo('%1 [%2]', StrLen(T), Codes(T)));

        Clear(TempBlob);
        TempBlob.CreateOutStream(O, TextEncoding::UTF8);
        O.WriteText('abc');
        Observer.Observe('writetext utf8 bytes', Hex(TempBlob));

        XmlDocument.ReadFrom('<a>x</a>', Doc);
        Clear(TempBlob);
        TempBlob.CreateOutStream(O);
        Doc.WriteTo(O);
        Observer.Observe('xml no declaration', Hex(TempBlob));

        Doc := XmlDocument.Create();
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        Doc.SetDeclaration(Decl);
        Doc.Add(XmlElement.Create('a'));
        Clear(TempBlob);
        TempBlob.CreateOutStream(O);
        Doc.WriteTo(O);
        TempBlob.CreateInStream(I);
        Observer.Observe('xml declaration first bytes', CopyStr(HexOf(I, 0), 1, 17));
        Observer.Expect('bytes', 'EF BB BF 61 62 63');
        Observer.Expect('readtext default', '6 [217,8249,143,97,98,99]');
        Observer.Expect('readtext utf8', '3 [97,98,99]');
        Observer.Expect('read utf8', '3 [97,98,99]');
        Observer.Expect('readtext windows', '6 [239,187,191,97,98,99]');
        Observer.Expect('writetext utf8 bytes', '61 62 63');
        Observer.Expect('xml no declaration', 'EF BB BF 3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 75 74 66 2D 38 22 3F 3E 0D 0A 3C 61 3E 78 3C 2F 61 3E');
        Observer.Expect('xml declaration first bytes', 'EF BB BF 3C 3F 78');
        Observer.Verify();
    end;

    local procedure WriteBytes(var O: OutStream; A: Byte; B: Byte; C: Byte)
    begin
        O.Write(A);
        O.Write(B);
        O.Write(C);
    end;

    // ---------------------------------------------------------------- item 72: Base64 decoding of odd input

    [Test]
    procedure Item72_Base64OddInput()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // missing padding, a bad character and an inner space are pinned in types/PVBase64.al FromBase64_Invalid_Text
        Observer.Observe('crlf inside', Decode('YWJj' + Crlf() + 'ZA=='));
        Observer.Observe('crlf at end', Decode('YWJjZA==' + Crlf()));
        Observer.Observe('crlf every 4', Decode('YW' + Crlf() + 'Jj' + Crlf() + 'ZA' + Crlf() + '=='));
        Observer.Observe('empty', Decode(''));
        Observer.Observe('outstream overload, length 5', DecodeToStream('YWJjZ'));
        Observer.Expect('crlf inside', 'ok: abcd');
        Observer.Expect('crlf at end', 'ok: abcd');
        Observer.Expect('crlf every 4', 'ok: abcd');
        Observer.Expect('empty', 'ok: ');
        // BC 27.5 reports the .NET call (code DotNetInvoke:Format), BC 28.5 and 29.0 code AL:Format without the prefix
#if BC28PLUS
        Observer.Expect('outstream overload, length 5', 'error AL:Format: The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.');
#else
        Observer.Expect('outstream overload, length 5', 'error DotNetInvoke:Format: A call to System.Convert.FromBase64String failed with this message: The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.');
#endif
        Observer.Verify();
    end;

    local procedure Decode(Value: Text): Text
    var
        Result: Text;
    begin
        if TryDecode(Value, Result) then
            exit('ok: ' + Result);
        exit(StrSubstNo('error %1: %2', GetLastErrorCode(), GetLastErrorText()));
    end;

    local procedure DecodeToStream(Value: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        O: OutStream;
    begin
        TempBlob.CreateOutStream(O);
        if TryDecodeToStream(Value, O) then
            exit('ok: ' + Hex(TempBlob));
        exit(StrSubstNo('error %1: %2', GetLastErrorCode(), GetLastErrorText()));
    end;

    [TryFunction]
    local procedure TryDecodeToStream(Value: Text; var O: OutStream)
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Base64.FromBase64(Value, O);
    end;

    [TryFunction]
    local procedure TryDecode(Value: Text; var Result: Text)
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Result := Base64.FromBase64(Value);
    end;

    // ---------------------------------------------------------------- item 73: Base64 decoding of a BigText
    // FromBase64 has no BigText overload and a BigText does not convert to Text (must-not-compile cases 1832, 1833); these are the ways in.

    [Test]
    procedure Item73_Base64FromBigText()
    var
        Observer: Codeunit "Probe Observer";
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        BT: BigText;
        T: Text;
        O: OutStream;
        I: InStream;
    begin
        BT.AddText('YWJj');
        BT.AddText('ZA==');
        Observer.Observe('format', Base64.FromBase64(Format(BT)));
        BT.GetSubText(T, 1);
        Observer.Observe('getsubtext', Base64.FromBase64(T));
        TempBlob.CreateOutStream(O);
        BT.Write(O);
        TempBlob.CreateInStream(I);
        I.ReadText(T);
        Observer.Observe('write then readtext', Base64.FromBase64(T));
        Observer.Expect('format', 'abcd');
        Observer.Expect('getsubtext', 'abcd');
        Observer.Expect('write then readtext', 'abcd');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 74: InStream as var parameter

    [Test]
    procedure Item74_InStreamVarParameter()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        O: OutStream;
        I: InStream;
        T: Text;
        Created: InStream;
    begin
        TempBlob.CreateOutStream(O);
        O.WriteText('abcdef');

        TempBlob.CreateInStream(I);
        ReadTwoVar(I);
        Observer.Observe('var: position', Format(I.Position()));
        I.ReadText(T);
        Observer.Observe('var: rest', T);

        TempBlob.CreateInStream(I);
        ReadTwoValue(I);
        Observer.Observe('value: position', Format(I.Position()));
        I.ReadText(T);
        Observer.Observe('value: rest', T);

        // the repro of microsoft/AL issue 7990: the InStream comes from a Temp Blob local to the callee
        CreateInCallee(Created);
        Observer.Observe('callee temp blob: length', Format(Created.Length()));
        Created.ReadText(T);
        Observer.Observe('callee temp blob: text', T);
        Observer.Expect('var: position', '3');
        Observer.Expect('var: rest', 'cdef');
        Observer.Expect('value: position', '3');
        Observer.Expect('value: rest', 'cdef');
        Observer.Expect('callee temp blob: length', '0');
        Observer.Expect('callee temp blob: text', '');
        Observer.Verify();
    end;

    local procedure ReadTwoVar(var I: InStream)
    var
        T: Text;
    begin
        I.Read(T, 2);
    end;

    local procedure ReadTwoValue(I: InStream)
    var
        T: Text;
    begin
        I.Read(T, 2);
    end;

    local procedure CreateInCallee(var I: InStream)
    var
        LocalBlob: Codeunit "Temp Blob";
        O: OutStream;
    begin
        LocalBlob.CreateOutStream(O);
        O.WriteText('Test Instream As Parameter Issue.');
        LocalBlob.CreateInStream(I);
    end;

    // ---------------------------------------------------------------- item 75: InStream partial reads, EOS, Length, Position

    [Test]
    procedure Item75_InStreamPartialReads()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        EmptyBlob: Codeunit "Temp Blob";
        O: OutStream;
        I: InStream;
        T: Text;
        N: Integer;
        B: Byte;
    begin
        TempBlob.CreateOutStream(O);
        O.WriteText('abc');

        EmptyBlob.CreateInStream(I);
        Observer.Observe('empty: eos', Format(I.EOS()));
        Observer.Observe('empty: length', Format(I.Length()));
        Observer.Observe('empty: position', Format(I.Position()));

        TempBlob.CreateInStream(I);
        Observer.Observe('eos before read', Format(I.EOS()));
        Observer.Observe('length', Format(I.Length()));
        Observer.Observe('position before read', Format(I.Position()));
        N := I.Read(T, 5);
        Observer.Observe('read 5 with return', StrSubstNo('%1 %2', N, T));
        Observer.Observe('position after', Format(I.Position()));
        Observer.Observe('eos after', Format(I.EOS()));
        N := I.Read(T, 5);
        Observer.Observe('read at end with return', StrSubstNo('%1 [%2]', N, T));
        N := I.Read(B);
        Observer.Observe('read byte at end with return', StrSubstNo('%1 %2', N, B));

        I.ResetPosition();
        // A successful TryFunction leaves the last error as it was: clear it first, so an error of an earlier test does not show here
        // (Windows BC 27.5/28.5/29.0 check 2026-10-20 saw the Base64 error of Item72 here).
        ClearLastError();
        Observer.Observe('read 5 without return ok', Format(TryRead(I, 5)));
        Observer.ObserveError('read 5 without return');

        Observer.Expect('empty: eos', 'Yes');
        Observer.Expect('empty: length', '0');
        Observer.Expect('empty: position', '1');
        Observer.Expect('eos before read', 'No');
        Observer.Expect('length', '3');
        Observer.Expect('position before read', '1');
        Observer.Expect('read 5 with return', '3 abc');
        Observer.Expect('position after', '4');
        Observer.Expect('eos after', 'Yes');
        Observer.Expect('read at end with return', '0 []');
        Observer.Expect('read byte at end with return', '0 \u0000');
        Observer.Expect('read 5 without return ok', 'Yes');
        Observer.Expect('read 5 without return|text', '');
        Observer.Expect('read 5 without return|code', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(var I: InStream; Len: Integer)
    var
        T: Text;
    begin
        I.Read(T, Len);
    end;
}
