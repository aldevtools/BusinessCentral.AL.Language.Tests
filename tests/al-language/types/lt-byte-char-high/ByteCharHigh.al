// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/byte/byte-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Temp Blob (System Application); own test codeunit 93104 (writer Y57)
// Probe: a Byte from 128 to 255 assigned to a Char and back (the helper `C := B` of
//        al-language-onprem-dotnet/lt-y51-blob-stream-position/Y51BlobStreamPosition.al, value 139 from a gzip header): the Char's
//        code (Char to Integer), the code of Format(Char), the Byte after Char to Byte, a Text built from the Char, and the bytes an
//        OutStream writes for the Char (Write(Char), WriteText(Format(Char))). Also a Char above 255 assigned to a Byte.
//        Codes only: some results are control characters and are never put into an observation.
//        Already pinned nearby: types/lt-scalars/ScT70061.al (Char_Conversions, 'q'), types/lt-scalars/ScT70052.al (Byte_Format).
// Facts: Byte to Char is NOT the identity: it maps through a fixed table (CP437 to Windows-1252 style): 139 -> 239, 128 -> 199,
//        200 -> 732, 255 -> 160, also 15 -> 164, 20 -> 182, 21 -> 167 below 128. Char to Byte maps back (Char 8364 -> Byte 177; Char 256 ->
//        Byte 65). A Char made from the Integer 139 is not the Char made from the Byte 139. OutStream.Write(Char) and WriteText(Format(Char))
//        write the original byte back (139, 200, 255). Measured: SaaS sandbox BC 29 and the Linux CI containers BC 27.5, 28.5, 29.0.
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

    // For every Byte in From..UpTo: <byte>:<code of the Char>; the Format(Char) length, its first code and the Byte after Char to Byte
    // are listed only where they differ from what the Char gives (f<len>/<code>, b<byte>).
    local procedure Range(From: Integer; UpTo: Integer): Text
    var
        B: Byte;
        B2: Byte;
        C: Char;
        T: Text;
        N: Integer;
        Back: Integer;
        Result: Text;
    begin
        for N := From to UpTo do begin
            B := N;
            C := B;
            T := Format(C);
            B2 := C;
            Back := B2;
            Result += Format(N) + ':' + Format(CharCode(C));
            if (StrLen(T) <> 1) or (FirstCode(T) <> Format(CharCode(C))) then
                Result += ' f' + Format(StrLen(T)) + '/' + FirstCode(T);
            if Back <> N then
                Result += ' b' + Format(Back);
            Result += ',';
        end;
        exit(Result);
    end;

    local procedure ByteCode(B: Byte): Integer
    var
        I: Integer;
    begin
        I := B;
        exit(I);
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
        I: Integer;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            I := B;
            Result += Format(I) + ',';
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
    procedure ByteChar_Codes_128_159()
    begin
        Observer.Observe('128..143', Range(128, 143));
        Observer.Observe('144..159', Range(144, 159));
        Observer.Expect('128..143', '128:199,129:252,130:233,131:226,132:228,133:224,134:229,135:231,136:234,137:235,138:232,139:239,140:238,141:236,142:196,143:197,');
        Observer.Expect('144..159', '144:201,145:230,146:198,147:244,148:246,149:242,150:251,151:249,152:255,153:214,154:220,155:162,156:163,157:165,158:15,159:402,');
        Observer.Verify();
    end;

    [Test]
    procedure ByteChar_Codes_160_191()
    begin
        Observer.Observe('160..175', Range(160, 175));
        Observer.Observe('176..191', Range(176, 191));
        Observer.Expect('160..175', '160:225,161:237,162:243,163:250,164:241,165:209,166:170,167:186,168:191,169:20,170:172,171:189,172:188,173:161,174:171,175:187,');
        Observer.Expect('176..191', '176:21,177:8364,178:129,179:8218,180:8222,181:8230,182:8224,183:8225,184:710,185:8240,186:352,187:8249,188:338,189:141,190:381,191:143,');
        Observer.Verify();
    end;

    [Test]
    procedure ByteChar_Codes_192_223()
    begin
        Observer.Observe('192..207', Range(192, 207));
        Observer.Observe('208..223', Range(208, 223));
        Observer.Expect('192..207', '192:144,193:8216,194:8217,195:8220,196:8221,197:8226,198:8211,199:8212,200:732,201:8482,202:353,203:8250,204:339,205:157,206:382,207:376,');
        Observer.Expect('208..223', '208:168,209:169,210:173,211:174,212:175,213:179,214:180,215:184,216:185,217:190,218:192,219:193,220:194,221:166,222:195,223:200,');
        Observer.Verify();
    end;

    [Test]
    procedure ByteChar_Codes_224_255()
    begin
        Observer.Observe('224..239', Range(224, 239));
        Observer.Observe('240..255', Range(240, 255));
        Observer.Expect('224..239', '224:202,225:223,226:203,227:204,228:205,229:206,230:181,231:207,232:208,233:210,234:211,235:212,236:213,237:215,238:216,239:217,');
        Observer.Expect('240..255', '240:218,241:177,242:219,243:221,244:222,245:227,246:247,247:240,248:176,249:245,250:183,251:248,252:253,253:178,254:254,255:160,');
        Observer.Verify();
    end;

    [Test]
    procedure ByteChar_Codes_0_127()
    var
        N: Integer;
        Diff: Text;
        B: Byte;
        C: Char;
    begin
        for N := 0 to 127 do begin
            B := N;
            C := B;
            if CharCode(C) <> N then
                Diff += Format(N) + ':' + Format(CharCode(C)) + ',';
        end;
        if Diff = '' then
            Diff := 'all equal';
        Observer.Observe('0..127 char code differs', Diff);
        Observer.Expect('0..127 char code differs', '15:164,20:182,21:167,');
        Observer.Verify();
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
        I := B2;
        Observer.Observe('text_index_back', Format(I));
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
        Observer.Expect('char_code', '239');
        Observer.Expect('char_from_int_equal', 'No');
        Observer.Expect('text_index_code', '239|1');
        Observer.Expect('text_index_back', '139');
        Observer.Expect('text_concat', '1|239');
        Observer.Expect('format_9', '239|1');
        Observer.Expect('stream_write_char', '139,');
        Observer.Expect('stream_writetext_char', '139,');
        Observer.Expect('stream_write_char200', '200,');
        Observer.Expect('stream_writetext_char200', '200,');
        Observer.Expect('stream_write_char255', '255,');
        Observer.Expect('stream_writetext_char255', '255,');
        Observer.Verify();
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
            Observer.Observe('char256', 'ok|' + Format(ByteCode(B)))
        else
            Observer.Observe('char256', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(ByteCode(B)));
        I := 8364;
        C := I;
        B := 7;
        ClearLastError();
        if TryCharToByte(C, B) then
            Observer.Observe('char8364', 'ok|' + Format(ByteCode(B)))
        else
            Observer.Observe('char8364', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(ByteCode(B)));
        Observer.Observe('char8364_write', WriteChar(C));
        Observer.Expect('char256', 'ok|65');
        Observer.Expect('char8364', 'ok|177');
        Observer.Expect('char8364_write', '177,');
        Observer.Verify();
    end;
}
