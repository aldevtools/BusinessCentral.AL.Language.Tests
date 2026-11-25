// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 79893 "YFN Yaml Blob"
// Probe: AL Runner issue 8580 (AI eval datasets in .yaml app resources), the last probe of the topic. Helpers of the
//   JsonYamlFinal*.al test codeunits: reads one YAML document through JsonObject.ReadFromYaml(Text) and
//   JsonObject.ReadFromYaml(InStream) and returns a short result text.
//   Result text: 'ok' when the JSON text that WriteTo gave equals the expected text; else the JSON text with characters
//   outside printable ASCII as <U+XXXX>, or 'F<code>[:<text>]' when ReadFromYaml returned false, or 'X<code>[:<text>]'
//   when it raised an error. A result longer than 200 characters is cut after 100 characters and ends with ' len=<n>'.
//   When the Text and the InStream overload (UTF-8 bytes) differ the result is 'T <text result> | S <stream result>'.
//   Source tokens: '~' line feed, '^' carriage return + line feed, '{T}' tab, '{S}' space, '{~}' tilde, '{\}' backslash,
//   '{uXXXX}' the UTF-16 code unit XXXX (hex).
// BC versions: 27, 28, 29

table 79893 "YFN Yaml Blob"
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

codeunit 79894 "YFN Yaml Support"
{
    var
        JO: JsonObject;
        Ok: Boolean;

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        Ok := false;
        Ok := JO.ReadFromYaml(Src);
    end;

    [TryFunction]
    local procedure TryReadStream(var InS: InStream)
    begin
        Ok := false;
        Ok := JO.ReadFromYaml(InS);
    end;

    procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    procedure Rep(Piece: Text; Count: Integer): Text
    var
        Result: TextBuilder;
        i: Integer;
    begin
        for i := 1 to Count do
            Result.Append(Piece);
        exit(Result.ToText());
    end;

    local procedure HexVal(C: Text): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(C)) - 1);
    end;

    procedure Hex4(Code: Integer): Text
    var
        Hex: Text;
    begin
        Hex := '0123456789ABCDEF';
        exit(CopyStr(Hex, (Code div 4096) + 1, 1) + CopyStr(Hex, ((Code div 256) mod 16) + 1, 1) + CopyStr(Hex, ((Code div 16) mod 16) + 1, 1) + CopyStr(Hex, (Code mod 16) + 1, 1));
    end;

    procedure Doc(Src: Text): Text
    var
        P: Integer;
        Code: Integer;
    begin
        Src := Src.Replace('{~}', Chr(7)).Replace('^', Chr(13) + Chr(10)).Replace('~', Chr(10)).Replace(Chr(7), '~');
        Src := Src.Replace('{T}', Chr(9)).Replace('{S}', ' ').Replace('{\}', Chr(92));
        P := StrPos(Src, '{u');
        while P > 0 do begin
            Code := HexVal(CopyStr(Src, P + 2, 1)) * 4096 + HexVal(CopyStr(Src, P + 3, 1)) * 256 + HexVal(CopyStr(Src, P + 4, 1)) * 16 + HexVal(CopyStr(Src, P + 5, 1));
            Src := CopyStr(Src, 1, P - 1) + Chr(Code) + CopyStr(Src, P + 7);
            P := StrPos(Src, '{u');
        end;
        exit(Src);
    end;

    procedure Esc(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: TextBuilder;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if (Code < 32) or (Code > 126) then
                Result.Append('<U+' + Hex4(Code) + '>')
            else
                Result.Append(CopyStr(Value, i, 1));
        end;
        exit(Result.ToText());
    end;

    local procedure ErrText(Kind: Text): Text
    var
        Msg: Text;
    begin
        Msg := Kind + GetLastErrorCode();
        if GetLastErrorText() <> 'The data does not represent valid YAML.' then
            Msg += ':' + Esc(GetLastErrorText());
        ClearLastError();
        exit(Msg);
    end;

    local procedure Cut(Value: Text): Text
    begin
        if StrLen(Value) > 200 then
            exit(CopyStr(Value, 1, 100) + ' len=' + Format(StrLen(Value)));
        exit(Value);
    end;

    // The result of one read of Src (a real document) into JO as it is; the stream form writes Src as UTF-8 bytes.
    local procedure One(Src: Text; ViaStream: Boolean; Expected: Text; OutEnc: TextEncoding; InEnc: TextEncoding): Text
    var
        Blob: Record "YFN Yaml Blob";
        OutS: OutStream;
        InS: InStream;
        Out: Text;
        Done: Boolean;
    begin
        ClearLastError();
        if ViaStream then begin
            Blob.DeleteAll();
            Blob.Id := 1;
            Blob.Data.CreateOutStream(OutS, OutEnc);
            OutS.WriteText(Src);
            Blob.Insert();
            Blob.CalcFields(Data);
            Blob.Data.CreateInStream(InS, InEnc);
            Done := TryReadStream(InS);
            Blob.DeleteAll();
        end else
            Done := TryRead(Src);
        if not Done then
            exit(ErrText('X'));
        if not Ok then
            exit(ErrText('F'));
        JO.WriteTo(Out);
        if (Expected <> '') and (Out = Expected) then
            exit('ok');
        exit(Cut(Esc(Out)));
    end;

    // Text and stream result of the document Src (tokens); Expected (tokens) is the JSON text that gives 'ok', or '' for none.
    procedure Both(Src: Text; Expected: Text): Text
    var
        T: Text;
        S: Text;
        D: Text;
        E: Text;
    begin
        D := Doc(Src);
        E := Doc(Expected);
        Clear(JO);
        T := One(D, false, E, TextEncoding::UTF8, TextEncoding::UTF8);
        Clear(JO);
        S := One(D, true, E, TextEncoding::UTF8, TextEncoding::UTF8);
        if T = S then
            exit(T);
        exit('T ' + T + ' | S ' + S);
    end;

    // Only the Text overload.
    procedure TextOnly(Src: Text; Expected: Text): Text
    begin
        Clear(JO);
        exit(One(Doc(Src), false, Doc(Expected), TextEncoding::UTF8, TextEncoding::UTF8));
    end;

    // A stream written with OutEnc and read with InEnc.
    procedure Stream(Src: Text; OutEnc: TextEncoding; InEnc: TextEncoding; Expected: Text): Text
    begin
        Clear(JO);
        exit(One(Doc(Src), true, Doc(Expected), OutEnc, InEnc));
    end;

    // JO holds PreJson before the read; the result carries what JO holds after it.
    procedure ReadInto(Src: Text; PreJson: Text): Text
    var
        Out: Text;
        Res: Text;
    begin
        Clear(JO);
        JO.ReadFrom(PreJson);
        ClearLastError();
        if not TryRead(Doc(Src)) then
            Res := ErrText('X')
        else
            if not Ok then
                Res := ErrText('F')
            else
                Res := 'true';
        JO.WriteTo(Out);
        exit(Res + ' after=' + Cut(Esc(Out)));
    end;

    // The result of reading Src as a Text, only its length: 'len=<n>' of the JSON text, or the failure.
    procedure LengthOnly(Src: Text): Text
    var
        Out: Text;
    begin
        Clear(JO);
        ClearLastError();
        if not TryRead(Doc(Src)) then
            exit(ErrText('X'));
        if not Ok then
            exit(ErrText('F'));
        JO.WriteTo(Out);
        exit('len=' + Format(StrLen(Out)));
    end;

    // Whether JO has the key Key after reading Src (Text): 'key' or the result of the read.
    procedure HasKey(Src: Text; "Key": Text): Text
    var
        Out: Text;
    begin
        Clear(JO);
        ClearLastError();
        if not TryRead(Doc(Src)) then
            exit(ErrText('X'));
        if not Ok then
            exit(ErrText('F'));
        if JO.Contains(Doc("Key")) then
            exit('key');
        JO.WriteTo(Out);
        exit(Cut(Esc(Out)));
    end;
}
