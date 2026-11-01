// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/byte/byte-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Temp Blob (System Application); own test codeunit 93104 (writer Y57)
// Probe: a Byte from 128 to 255 assigned to a Char and back (the helper `C := B` of
//        al-language-onprem-dotnet/lt-y51-blob-stream-position/Y51BlobStreamPosition.al, value 139 from a gzip header): the Char's
//        code (Char to Integer), the code of Format(Char), the Byte after Char to Byte, a Text built from the Char, and the bytes an
//        OutStream writes for the Char (Write(Char), WriteText(Format(Char))). Also a Char above 255 assigned to a Byte.
//        Codes only: characters from 128 to 159 are control characters and are never put into an observation.
//        Already pinned nearby: types/lt-scalars/ScT70061.al (Char_Conversions, 'q'), types/lt-scalars/ScT70052.al (Byte_Format).
// BC versions: 27, 28, 29

codeunit 93104 "LT Byte Char High"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure CharCode(C: Char): Integer
    var
        I: Integer;
    begin
        I := C;
        exit(I);
    end;

    // For every Byte in From..UpTo: the Char's code, the code of the first character of Format(Char), the Byte after Char to Byte;
    // only the values that differ from the Byte itself are listed (b=char/format/back).
    local procedure Range(From: Integer; UpTo: Integer): Text
    var
        B: Byte;
        B2: Byte;
        C: Char;
        T: Text;
        N: Integer;
        Result: Text;
    begin
        for N := From to UpTo do begin
            B := N;
            C := B;
            T := Format(C);
            B2 := C;
            if (CharCode(C) <> N) or (StrLen(T) <> 1) or (B2 <> N) then
                Result += Format(N) + '=' + Format(CharCode(C)) + '/' + Format(StrLen(T)) + ':' + FirstCode(T) + '/' + Format(B2) + ';'
            else
                if (CharCode(T[1]) <> N) then
                    Result += Format(N) + '=fmt' + Format(CharCode(T[1])) + ';';
        end;
        if Result = '' then
            exit('all equal');
        exit(Result);
    end;

    local procedure FirstCode(T: Text): Text
    begin
        if StrLen(T) = 0 then
            exit('none');
        exit(Format(CharCode(T[1])));
    end;

    local procedure StreamBytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Result += Format(CharCode(B)) + ',';
        end;
        exit(Result);
    end;

    local procedure WriteChar(C: Char): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write(C);
        exit(StreamBytes(TempBlob));
    end;

    local procedure WriteCharText(C: Char): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Format(C));
        exit(StreamBytes(TempBlob));
    end;

    [Test]
    procedure ByteChar_HighValues_Codes()
    begin
        Observer.Observe('128..159', Range(128, 159));
        Observer.Observe('160..191', Range(160, 191));
        Observer.Observe('192..223', Range(192, 223));
        Observer.Observe('224..255', Range(224, 255));
        Observer.Observe('0..127', Range(0, 127));
        Observer.Finish();
    end;

    [Test]
    procedure ByteChar_139_Details()
    var
        B: Byte;
        B2: Byte;
        C: Char;
        C2: Char;
        T: Text;
        I: Integer;
    begin
        B := 139;
        C := B;
        Observer.Observe('char_code', Format(CharCode(C)));
        I := 139;
        C2 := I;
        Observer.Observe('char_from_int_equal', Format(C = C2));
        T := 'x';
        T[1] := C;
        Observer.Observe('text_index_code', Format(CharCode(T[1])) + '|' + Format(StrLen(T)));
        B2 := T[1];
        Observer.Observe('text_index_back', Format(CharCode(B2)));
        T := '';
        T += Format(C);
        Observer.Observe('text_concat', Format(StrLen(T)) + '|' + Format(CharCode(T[1])));
        Observer.Observe('format_9', FirstCode(Format(C, 0, 9)) + '|' + Format(StrLen(Format(C, 0, 9))));
        Observer.Observe('stream_write_char', WriteChar(C));
        Observer.Observe('stream_writetext_char', WriteCharText(C));
        B := 200;
        C := B;
        Observer.Observe('stream_write_char200', WriteChar(C));
        Observer.Observe('stream_writetext_char200', WriteCharText(C));
        B := 255;
        C := B;
        Observer.Observe('stream_write_char255', WriteChar(C));
        Observer.Observe('stream_writetext_char255', WriteCharText(C));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryCharToByte(C: Char; var B: Byte)
    begin
        B := C;
    end;

    [Test]
    procedure ByteChar_CharAbove255_ToByte()
    var
        B: Byte;
        C: Char;
        I: Integer;
    begin
        I := 256;
        C := I;
        B := 7;
        ClearLastError();
        if TryCharToByte(C, B) then
            Observer.Observe('char256', 'ok|' + Format(CharCode(B)))
        else
            Observer.Observe('char256', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(CharCode(B)));
        I := 8364;
        C := I;
        B := 7;
        ClearLastError();
        if TryCharToByte(C, B) then
            Observer.Observe('char8364', 'ok|' + Format(CharCode(B)))
        else
            Observer.Observe('char8364', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(CharCode(B)));
        Observer.Observe('char8364_write', WriteChar(C));
        Observer.Finish();
    end;
}
