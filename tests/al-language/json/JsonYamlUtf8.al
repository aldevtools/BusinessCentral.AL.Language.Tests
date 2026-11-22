// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 75622 "YU8 Yaml Blob"
// Probe: AL Runner issue 8580 (AI eval datasets, .yaml app resources, carry a section sign U+00A7 in a `>-` block scalar).
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: JsonObject.ReadFromYaml of text outside printable ASCII. Characters: U+00A7 (section sign), U+00E9, U+00FC,
//   U+00F8 (accented Latin), U+20AC (euro sign, 3 UTF-8 bytes), U+1F600 (emoji, 4 UTF-8 bytes, a UTF-16 surrogate pair in
//   AL Text), and 'e' + U+0301 (a combining mark). Forms: folded block `>-` and `>`, literal block `|` and `|-`, plain,
//   single-quoted and double-quoted scalars, double-quoted escapes (\u, \U, \x, \N, \_, \L, \P), a mapping key, a list
//   item, flow collections, comments, multi-line blocks with the character at line start and line end, the issue's
//   dataset document (LF and CRLF), and the InStream overload over UTF-8 bytes. Special characters: U+00A0, U+0085,
//   U+2028, U+2029, U+FEFF and U+0080 in plain and folded scalars.
// Every observed text shows characters outside printable ASCII (and control characters) as <U+XXXX>, one per UTF-16 code
//   unit, so the JSON text that WriteTo produced can be asserted in ASCII. '-len' is StrLen of the value (UTF-16 code
//   units), '-eq' compares the value with the text the YAML holds.
// Results (corpus CI, BC 27.5, 28.5 and 29.0 gave identical results for every test):
//   Non-ASCII text passes through unchanged into JSON values and keys in every scalar form; StrLen counts UTF-16 code units
//   (U+1F600 = 2, 'e' + U+0301 = 2); folding and chomping match ASCII. WriteTo writes the characters raw, except U+0085, U+2028,
//   U+2029 (escaped as \u) and control characters below U+0020. U+0080, U+00A0 and U+FEFF are kept raw.
//   Raw U+0085, U+2028 or U+2029 in the text: the TryFunction returns true, ReadFromYaml returns false, last error is
//   "The data does not represent valid YAML.", the object stays empty. As double-quoted escapes (\N, \L, \P) they are valid.
//   ReadFromYaml(InStream) decodes the bytes as UTF-8 itself, ignoring the InStream's TextEncoding; bytes written with the
//   default (legacy code page) OutStream encoding give U+FFFD for the invalid sequences.
//   Not measured (refuse): leading BOM, tabs, other C1 controls, unpaired surrogates, |+ and >+, indentation indicators,
//   non-ASCII in anchors and tags, WriteToYaml, UTF-16 streams.
// BC versions: 27, 28, 29

table 75622 "YU8 Yaml Blob"
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

codeunit 75621 "YU8 Json Yaml Utf8"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        JO: JsonObject;
        Ok: Boolean;

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        Clear(JO);
        Ok := false;
        Ok := JO.ReadFromYaml(Src);
    end;

    [TryFunction]
    local procedure TryReadStream(var InS: InStream)
    begin
        Clear(JO);
        Ok := false;
        Ok := JO.ReadFromYaml(InS);
    end;

    local procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    // Src tokens: '~' line feed, '^' carriage return + line feed, {S} U+00A7, {E} U+00E9, {U} U+00FC, {O} U+00F8, {R} U+20AC,
    // {M} U+1F600 (surrogate pair), {C} 'e' + U+0301, {A} U+00A0, {N} U+0085, {L} U+2028, {P} U+2029, {B} U+FEFF, {K} U+0080,
    // {\} a backslash (Chr(92); the YAML escapes are built with it, so that no tool on the way unescapes them before YAML does).
    local procedure Doc(Src: Text): Text
    begin
        Src := Src.Replace('^', Chr(13) + Chr(10)).Replace('~', Chr(10));
        Src := Src.Replace('{S}', Chr(167)).Replace('{E}', Chr(233)).Replace('{U}', Chr(252)).Replace('{O}', Chr(248));
        Src := Src.Replace('{R}', Chr(8364)).Replace('{M}', Chr(55357) + Chr(56832)).Replace('{C}', 'e' + Chr(769));
        Src := Src.Replace('{A}', Chr(160)).Replace('{N}', Chr(133)).Replace('{L}', Chr(8232)).Replace('{P}', Chr(8233));
        Src := Src.Replace('{B}', Chr(65279)).Replace('{K}', Chr(128)).Replace('{\}', Chr(92));
        exit(Src);
    end;

    local procedure Hex4(Code: Integer): Text
    var
        Hex: Text;
    begin
        Hex := '0123456789ABCDEF';
        exit(CopyStr(Hex, (Code div 4096) + 1, 1) + CopyStr(Hex, ((Code div 256) mod 16) + 1, 1) + CopyStr(Hex, ((Code div 16) mod 16) + 1, 1) + CopyStr(Hex, (Code mod 16) + 1, 1));
    end;

    local procedure Esc(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if (Code < 32) or (Code > 126) then
                Result += '<U+' + Hex4(Code) + '>'
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;

    // The plain scalar V as a top-level mapping value, a nested mapping value and a list item.
    local procedure PlainAll(Prefix: Text; V: Text)
    begin
        Cell(Prefix + '-top', 'q: ' + V + '~n: 1', 0, V);
        Cell(Prefix + '-nest', 'o:~  q: ' + V + '~  r: 2~n: 1', 0, '');
        Cell(Prefix + '-list', 'k:~  - ' + V + '~  - c', 2, V);
        Cell(Prefix + '-nestlist', 'o:~  k:~    - ' + V + '~    - c', 0, '');
    end;

    // Mode 0: the value of key 'q'; 1: the first key; 2: the first item of the list under key 'k'.
    local procedure ValueOf(Mode: Integer; var Found: Boolean): Text
    var
        Tok: JsonToken;
        Item: JsonToken;
        Ks: List of [Text];
    begin
        Found := false;
        case Mode of
            0:
                if not JO.Get('q', Tok) then
                    exit('');
            1:
                begin
                    Ks := JO.Keys();
                    if Ks.Count() = 0 then
                        exit('');
                    Found := true;
                    exit(Ks.Get(1));
                end;
            2:
                begin
                    if not JO.Get('k', Tok) then
                        exit('');
                    if not Tok.IsArray() then
                        exit('');
                    if not Tok.AsArray().Get(0, Item) then
                        exit('');
                    Tok := Item;
                end;
        end;
        if not Tok.IsValue() then
            exit('');
        if Tok.AsValue().IsNull() then
            exit('');
        Found := true;
        exit(Tok.AsValue().AsText());
    end;

    local procedure ObserveRead(Name: Text; Ret: Boolean; Mode: Integer; Expected: Text)
    var
        Out: Text;
        Value: Text;
        Found: Boolean;
    begin
        JO.WriteTo(Out);
        Observer.Observe(Name, Format(Ret) + '|' + Format(Ok) + '|' + Esc(GetLastErrorText()) + '|' + Esc(Out));
        Value := ValueOf(Mode, Found);
        if Found then begin
            Observer.Observe(Name + '-len', Format(StrLen(Value)));
            Observer.Observe(Name + '-eq', Format(Value = Doc(Expected)));
        end else
            Observer.Observe(Name + '-len', 'no value');
        ClearLastError();
    end;

    local procedure Cell(Name: Text; Src: Text; Mode: Integer; Expected: Text)
    var
        Ret: Boolean;
    begin
        ClearLastError();
        Ret := TryRead(Doc(Src));
        ObserveRead(Name, Ret, Mode, Expected);
    end;

    // One cell per character: '{X}' in Src and Expected stands for each of {S} {E} {U} {O} {R} {M} {C} in turn.
    local procedure EachChar(Prefix: Text; Src: Text; Mode: Integer; Expected: Text)
    var
        Ks: List of [Text];
        K: Text;
    begin
        Ks.AddRange('S', 'E', 'U', 'O', 'R', 'M', 'C');
        foreach K in Ks do
            Cell(Prefix + '-' + K, Src.Replace('{X}', '{' + K + '}'), Mode, Expected.Replace('{X}', '{' + K + '}'));
    end;

    // The same for the special characters {A} {N} {L} {P} {B} {K}.
    local procedure EachSpecial(Prefix: Text; Src: Text; Mode: Integer; Expected: Text)
    var
        Ks: List of [Text];
        K: Text;
    begin
        Ks.AddRange('A', 'N', 'L', 'P', 'B', 'K');
        foreach K in Ks do
            Cell(Prefix + '-' + K, Src.Replace('{X}', '{' + K + '}'), Mode, Expected.Replace('{X}', '{' + K + '}'));
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedStrip_Read()
    begin
        EachChar('fs', 'q: >-~  a{X}b~n: 1', 0, 'a{X}b');
        Observer.Expect('fs-S', 'Yes|Yes||{"q":"a<U+00A7>b","n":"1"}');
        Observer.Expect('fs-S-len', '3');
        Observer.Expect('fs-S-eq', 'Yes');
        Observer.Expect('fs-E', 'Yes|Yes||{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('fs-E-len', '3');
        Observer.Expect('fs-E-eq', 'Yes');
        Observer.Expect('fs-U', 'Yes|Yes||{"q":"a<U+00FC>b","n":"1"}');
        Observer.Expect('fs-U-len', '3');
        Observer.Expect('fs-U-eq', 'Yes');
        Observer.Expect('fs-O', 'Yes|Yes||{"q":"a<U+00F8>b","n":"1"}');
        Observer.Expect('fs-O-len', '3');
        Observer.Expect('fs-O-eq', 'Yes');
        Observer.Expect('fs-R', 'Yes|Yes||{"q":"a<U+20AC>b","n":"1"}');
        Observer.Expect('fs-R-len', '3');
        Observer.Expect('fs-R-eq', 'Yes');
        Observer.Expect('fs-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b","n":"1"}');
        Observer.Expect('fs-M-len', '4');
        Observer.Expect('fs-M-eq', 'Yes');
        Observer.Expect('fs-C', 'Yes|Yes||{"q":"ae<U+0301>b","n":"1"}');
        Observer.Expect('fs-C-len', '4');
        Observer.Expect('fs-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8Folded_Read()
    begin
        EachChar('fk', 'q: >~  a{X}b~n: 1', 0, 'a{X}b~');
        Observer.Expect('fk-S', 'Yes|Yes||{"q":"a<U+00A7>b\n","n":"1"}');
        Observer.Expect('fk-S-len', '4');
        Observer.Expect('fk-S-eq', 'Yes');
        Observer.Expect('fk-E', 'Yes|Yes||{"q":"a<U+00E9>b\n","n":"1"}');
        Observer.Expect('fk-E-len', '4');
        Observer.Expect('fk-E-eq', 'Yes');
        Observer.Expect('fk-U', 'Yes|Yes||{"q":"a<U+00FC>b\n","n":"1"}');
        Observer.Expect('fk-U-len', '4');
        Observer.Expect('fk-U-eq', 'Yes');
        Observer.Expect('fk-O', 'Yes|Yes||{"q":"a<U+00F8>b\n","n":"1"}');
        Observer.Expect('fk-O-len', '4');
        Observer.Expect('fk-O-eq', 'Yes');
        Observer.Expect('fk-R', 'Yes|Yes||{"q":"a<U+20AC>b\n","n":"1"}');
        Observer.Expect('fk-R-len', '4');
        Observer.Expect('fk-R-eq', 'Yes');
        Observer.Expect('fk-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b\n","n":"1"}');
        Observer.Expect('fk-M-len', '5');
        Observer.Expect('fk-M-eq', 'Yes');
        Observer.Expect('fk-C', 'Yes|Yes||{"q":"ae<U+0301>b\n","n":"1"}');
        Observer.Expect('fk-C-len', '5');
        Observer.Expect('fk-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8Literal_Read()
    begin
        EachChar('lk', 'q: |~  a{X}b~n: 1', 0, 'a{X}b~');
        Observer.Expect('lk-S', 'Yes|Yes||{"q":"a<U+00A7>b\n","n":"1"}');
        Observer.Expect('lk-S-len', '4');
        Observer.Expect('lk-S-eq', 'Yes');
        Observer.Expect('lk-E', 'Yes|Yes||{"q":"a<U+00E9>b\n","n":"1"}');
        Observer.Expect('lk-E-len', '4');
        Observer.Expect('lk-E-eq', 'Yes');
        Observer.Expect('lk-U', 'Yes|Yes||{"q":"a<U+00FC>b\n","n":"1"}');
        Observer.Expect('lk-U-len', '4');
        Observer.Expect('lk-U-eq', 'Yes');
        Observer.Expect('lk-O', 'Yes|Yes||{"q":"a<U+00F8>b\n","n":"1"}');
        Observer.Expect('lk-O-len', '4');
        Observer.Expect('lk-O-eq', 'Yes');
        Observer.Expect('lk-R', 'Yes|Yes||{"q":"a<U+20AC>b\n","n":"1"}');
        Observer.Expect('lk-R-len', '4');
        Observer.Expect('lk-R-eq', 'Yes');
        Observer.Expect('lk-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b\n","n":"1"}');
        Observer.Expect('lk-M-len', '5');
        Observer.Expect('lk-M-eq', 'Yes');
        Observer.Expect('lk-C', 'Yes|Yes||{"q":"ae<U+0301>b\n","n":"1"}');
        Observer.Expect('lk-C-len', '5');
        Observer.Expect('lk-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8LiteralStrip_Read()
    begin
        EachChar('ls', 'q: |-~  a{X}b~n: 1', 0, 'a{X}b');
        Observer.Expect('ls-S', 'Yes|Yes||{"q":"a<U+00A7>b","n":"1"}');
        Observer.Expect('ls-S-len', '3');
        Observer.Expect('ls-S-eq', 'Yes');
        Observer.Expect('ls-E', 'Yes|Yes||{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('ls-E-len', '3');
        Observer.Expect('ls-E-eq', 'Yes');
        Observer.Expect('ls-U', 'Yes|Yes||{"q":"a<U+00FC>b","n":"1"}');
        Observer.Expect('ls-U-len', '3');
        Observer.Expect('ls-U-eq', 'Yes');
        Observer.Expect('ls-O', 'Yes|Yes||{"q":"a<U+00F8>b","n":"1"}');
        Observer.Expect('ls-O-len', '3');
        Observer.Expect('ls-O-eq', 'Yes');
        Observer.Expect('ls-R', 'Yes|Yes||{"q":"a<U+20AC>b","n":"1"}');
        Observer.Expect('ls-R-len', '3');
        Observer.Expect('ls-R-eq', 'Yes');
        Observer.Expect('ls-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b","n":"1"}');
        Observer.Expect('ls-M-len', '4');
        Observer.Expect('ls-M-eq', 'Yes');
        Observer.Expect('ls-C', 'Yes|Yes||{"q":"ae<U+0301>b","n":"1"}');
        Observer.Expect('ls-C-len', '4');
        Observer.Expect('ls-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8Plain_Read()
    begin
        EachChar('pl', 'q: a{X}b~n: 1', 0, 'a{X}b');
        Observer.Expect('pl-S', 'Yes|Yes||{"q":"a<U+00A7>b","n":"1"}');
        Observer.Expect('pl-S-len', '3');
        Observer.Expect('pl-S-eq', 'Yes');
        Observer.Expect('pl-E', 'Yes|Yes||{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('pl-E-len', '3');
        Observer.Expect('pl-E-eq', 'Yes');
        Observer.Expect('pl-U', 'Yes|Yes||{"q":"a<U+00FC>b","n":"1"}');
        Observer.Expect('pl-U-len', '3');
        Observer.Expect('pl-U-eq', 'Yes');
        Observer.Expect('pl-O', 'Yes|Yes||{"q":"a<U+00F8>b","n":"1"}');
        Observer.Expect('pl-O-len', '3');
        Observer.Expect('pl-O-eq', 'Yes');
        Observer.Expect('pl-R', 'Yes|Yes||{"q":"a<U+20AC>b","n":"1"}');
        Observer.Expect('pl-R-len', '3');
        Observer.Expect('pl-R-eq', 'Yes');
        Observer.Expect('pl-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b","n":"1"}');
        Observer.Expect('pl-M-len', '4');
        Observer.Expect('pl-M-eq', 'Yes');
        Observer.Expect('pl-C', 'Yes|Yes||{"q":"ae<U+0301>b","n":"1"}');
        Observer.Expect('pl-C-len', '4');
        Observer.Expect('pl-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8PlainCharOnly_Read()
    begin
        EachChar('po', 'q: {X}~n: 1', 0, '{X}');
        Observer.Expect('po-S', 'Yes|Yes||{"q":"<U+00A7>","n":"1"}');
        Observer.Expect('po-S-len', '1');
        Observer.Expect('po-S-eq', 'Yes');
        Observer.Expect('po-E', 'Yes|Yes||{"q":"<U+00E9>","n":"1"}');
        Observer.Expect('po-E-len', '1');
        Observer.Expect('po-E-eq', 'Yes');
        Observer.Expect('po-U', 'Yes|Yes||{"q":"<U+00FC>","n":"1"}');
        Observer.Expect('po-U-len', '1');
        Observer.Expect('po-U-eq', 'Yes');
        Observer.Expect('po-O', 'Yes|Yes||{"q":"<U+00F8>","n":"1"}');
        Observer.Expect('po-O-len', '1');
        Observer.Expect('po-O-eq', 'Yes');
        Observer.Expect('po-R', 'Yes|Yes||{"q":"<U+20AC>","n":"1"}');
        Observer.Expect('po-R-len', '1');
        Observer.Expect('po-R-eq', 'Yes');
        Observer.Expect('po-M', 'Yes|Yes||{"q":"<U+D83D><U+DE00>","n":"1"}');
        Observer.Expect('po-M-len', '2');
        Observer.Expect('po-M-eq', 'Yes');
        Observer.Expect('po-C', 'Yes|Yes||{"q":"e<U+0301>","n":"1"}');
        Observer.Expect('po-C-len', '2');
        Observer.Expect('po-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SingleQuoted_Read()
    begin
        EachChar('sq', 'q: ''a{X}b''~n: 1', 0, 'a{X}b');
        Observer.Expect('sq-S', 'Yes|Yes||{"q":"a<U+00A7>b","n":"1"}');
        Observer.Expect('sq-S-len', '3');
        Observer.Expect('sq-S-eq', 'Yes');
        Observer.Expect('sq-E', 'Yes|Yes||{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('sq-E-len', '3');
        Observer.Expect('sq-E-eq', 'Yes');
        Observer.Expect('sq-U', 'Yes|Yes||{"q":"a<U+00FC>b","n":"1"}');
        Observer.Expect('sq-U-len', '3');
        Observer.Expect('sq-U-eq', 'Yes');
        Observer.Expect('sq-O', 'Yes|Yes||{"q":"a<U+00F8>b","n":"1"}');
        Observer.Expect('sq-O-len', '3');
        Observer.Expect('sq-O-eq', 'Yes');
        Observer.Expect('sq-R', 'Yes|Yes||{"q":"a<U+20AC>b","n":"1"}');
        Observer.Expect('sq-R-len', '3');
        Observer.Expect('sq-R-eq', 'Yes');
        Observer.Expect('sq-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b","n":"1"}');
        Observer.Expect('sq-M-len', '4');
        Observer.Expect('sq-M-eq', 'Yes');
        Observer.Expect('sq-C', 'Yes|Yes||{"q":"ae<U+0301>b","n":"1"}');
        Observer.Expect('sq-C-len', '4');
        Observer.Expect('sq-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8DoubleQuoted_Read()
    begin
        EachChar('dq', 'q: "a{X}b"~n: 1', 0, 'a{X}b');
        Observer.Expect('dq-S', 'Yes|Yes||{"q":"a<U+00A7>b","n":"1"}');
        Observer.Expect('dq-S-len', '3');
        Observer.Expect('dq-S-eq', 'Yes');
        Observer.Expect('dq-E', 'Yes|Yes||{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('dq-E-len', '3');
        Observer.Expect('dq-E-eq', 'Yes');
        Observer.Expect('dq-U', 'Yes|Yes||{"q":"a<U+00FC>b","n":"1"}');
        Observer.Expect('dq-U-len', '3');
        Observer.Expect('dq-U-eq', 'Yes');
        Observer.Expect('dq-O', 'Yes|Yes||{"q":"a<U+00F8>b","n":"1"}');
        Observer.Expect('dq-O-len', '3');
        Observer.Expect('dq-O-eq', 'Yes');
        Observer.Expect('dq-R', 'Yes|Yes||{"q":"a<U+20AC>b","n":"1"}');
        Observer.Expect('dq-R-len', '3');
        Observer.Expect('dq-R-eq', 'Yes');
        Observer.Expect('dq-M', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b","n":"1"}');
        Observer.Expect('dq-M-len', '4');
        Observer.Expect('dq-M-eq', 'Yes');
        Observer.Expect('dq-C', 'Yes|Yes||{"q":"ae<U+0301>b","n":"1"}');
        Observer.Expect('dq-C-len', '4');
        Observer.Expect('dq-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8MappingKey_Read()
    begin
        EachChar('key', 'a{X}b: 1~n: 2', 1, 'a{X}b');
        Observer.Expect('key-S', 'Yes|Yes||{"a<U+00A7>b":"1","n":"2"}');
        Observer.Expect('key-S-len', '3');
        Observer.Expect('key-S-eq', 'Yes');
        Observer.Expect('key-E', 'Yes|Yes||{"a<U+00E9>b":"1","n":"2"}');
        Observer.Expect('key-E-len', '3');
        Observer.Expect('key-E-eq', 'Yes');
        Observer.Expect('key-U', 'Yes|Yes||{"a<U+00FC>b":"1","n":"2"}');
        Observer.Expect('key-U-len', '3');
        Observer.Expect('key-U-eq', 'Yes');
        Observer.Expect('key-O', 'Yes|Yes||{"a<U+00F8>b":"1","n":"2"}');
        Observer.Expect('key-O-len', '3');
        Observer.Expect('key-O-eq', 'Yes');
        Observer.Expect('key-R', 'Yes|Yes||{"a<U+20AC>b":"1","n":"2"}');
        Observer.Expect('key-R-len', '3');
        Observer.Expect('key-R-eq', 'Yes');
        Observer.Expect('key-M', 'Yes|Yes||{"a<U+D83D><U+DE00>b":"1","n":"2"}');
        Observer.Expect('key-M-len', '4');
        Observer.Expect('key-M-eq', 'Yes');
        Observer.Expect('key-C', 'Yes|Yes||{"ae<U+0301>b":"1","n":"2"}');
        Observer.Expect('key-C-len', '4');
        Observer.Expect('key-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8ListItem_Read()
    begin
        EachChar('item', 'k:~  - a{X}b~  - c', 2, 'a{X}b');
        Observer.Expect('item-S', 'Yes|Yes||{"k":["a<U+00A7>b","c"]}');
        Observer.Expect('item-S-len', '3');
        Observer.Expect('item-S-eq', 'Yes');
        Observer.Expect('item-E', 'Yes|Yes||{"k":["a<U+00E9>b","c"]}');
        Observer.Expect('item-E-len', '3');
        Observer.Expect('item-E-eq', 'Yes');
        Observer.Expect('item-U', 'Yes|Yes||{"k":["a<U+00FC>b","c"]}');
        Observer.Expect('item-U-len', '3');
        Observer.Expect('item-U-eq', 'Yes');
        Observer.Expect('item-O', 'Yes|Yes||{"k":["a<U+00F8>b","c"]}');
        Observer.Expect('item-O-len', '3');
        Observer.Expect('item-O-eq', 'Yes');
        Observer.Expect('item-R', 'Yes|Yes||{"k":["a<U+20AC>b","c"]}');
        Observer.Expect('item-R-len', '3');
        Observer.Expect('item-R-eq', 'Yes');
        Observer.Expect('item-M', 'Yes|Yes||{"k":["a<U+D83D><U+DE00>b","c"]}');
        Observer.Expect('item-M-len', '4');
        Observer.Expect('item-M-eq', 'Yes');
        Observer.Expect('item-C', 'Yes|Yes||{"k":["ae<U+0301>b","c"]}');
        Observer.Expect('item-C-len', '4');
        Observer.Expect('item-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedLineEdges_Read()
    begin
        EachChar('fe', 'q: >-~  {X}one two{X}~  {X}three{X}~n: 1', 0, '{X}one two{X} {X}three{X}');
        Observer.Expect('fe-S', 'Yes|Yes||{"q":"<U+00A7>one two<U+00A7> <U+00A7>three<U+00A7>","n":"1"}');
        Observer.Expect('fe-S-len', '17');
        Observer.Expect('fe-S-eq', 'Yes');
        Observer.Expect('fe-E', 'Yes|Yes||{"q":"<U+00E9>one two<U+00E9> <U+00E9>three<U+00E9>","n":"1"}');
        Observer.Expect('fe-E-len', '17');
        Observer.Expect('fe-E-eq', 'Yes');
        Observer.Expect('fe-U', 'Yes|Yes||{"q":"<U+00FC>one two<U+00FC> <U+00FC>three<U+00FC>","n":"1"}');
        Observer.Expect('fe-U-len', '17');
        Observer.Expect('fe-U-eq', 'Yes');
        Observer.Expect('fe-O', 'Yes|Yes||{"q":"<U+00F8>one two<U+00F8> <U+00F8>three<U+00F8>","n":"1"}');
        Observer.Expect('fe-O-len', '17');
        Observer.Expect('fe-O-eq', 'Yes');
        Observer.Expect('fe-R', 'Yes|Yes||{"q":"<U+20AC>one two<U+20AC> <U+20AC>three<U+20AC>","n":"1"}');
        Observer.Expect('fe-R-len', '17');
        Observer.Expect('fe-R-eq', 'Yes');
        Observer.Expect('fe-M', 'Yes|Yes||{"q":"<U+D83D><U+DE00>one two<U+D83D><U+DE00> <U+D83D><U+DE00>three<U+D83D><U+DE00>","n":"1"}');
        Observer.Expect('fe-M-len', '21');
        Observer.Expect('fe-M-eq', 'Yes');
        Observer.Expect('fe-C', 'Yes|Yes||{"q":"e<U+0301>one twoe<U+0301> e<U+0301>threee<U+0301>","n":"1"}');
        Observer.Expect('fe-C-len', '21');
        Observer.Expect('fe-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedKeepLineEdges_Read()
    begin
        EachChar('fke', 'q: >~  {X}one{X}~~  {X}two{X}~n: 1', 0, '{X}one{X}~{X}two{X}~');
        Observer.Expect('fke-S', 'Yes|Yes||{"q":"<U+00A7>one<U+00A7>\n<U+00A7>two<U+00A7>\n","n":"1"}');
        Observer.Expect('fke-S-len', '12');
        Observer.Expect('fke-S-eq', 'Yes');
        Observer.Expect('fke-E', 'Yes|Yes||{"q":"<U+00E9>one<U+00E9>\n<U+00E9>two<U+00E9>\n","n":"1"}');
        Observer.Expect('fke-E-len', '12');
        Observer.Expect('fke-E-eq', 'Yes');
        Observer.Expect('fke-U', 'Yes|Yes||{"q":"<U+00FC>one<U+00FC>\n<U+00FC>two<U+00FC>\n","n":"1"}');
        Observer.Expect('fke-U-len', '12');
        Observer.Expect('fke-U-eq', 'Yes');
        Observer.Expect('fke-O', 'Yes|Yes||{"q":"<U+00F8>one<U+00F8>\n<U+00F8>two<U+00F8>\n","n":"1"}');
        Observer.Expect('fke-O-len', '12');
        Observer.Expect('fke-O-eq', 'Yes');
        Observer.Expect('fke-R', 'Yes|Yes||{"q":"<U+20AC>one<U+20AC>\n<U+20AC>two<U+20AC>\n","n":"1"}');
        Observer.Expect('fke-R-len', '12');
        Observer.Expect('fke-R-eq', 'Yes');
        Observer.Expect('fke-M', 'Yes|Yes||{"q":"<U+D83D><U+DE00>one<U+D83D><U+DE00>\n<U+D83D><U+DE00>two<U+D83D><U+DE00>\n","n":"1"}');
        Observer.Expect('fke-M-len', '16');
        Observer.Expect('fke-M-eq', 'Yes');
        Observer.Expect('fke-C', 'Yes|Yes||{"q":"e<U+0301>onee<U+0301>\ne<U+0301>twoe<U+0301>\n","n":"1"}');
        Observer.Expect('fke-C-len', '16');
        Observer.Expect('fke-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8LiteralLineEdges_Read()
    begin
        EachChar('le', 'q: |~  {X}one two{X}~  {X}three{X}~n: 1', 0, '{X}one two{X}~{X}three{X}~');
        Observer.Expect('le-S', 'Yes|Yes||{"q":"<U+00A7>one two<U+00A7>\n<U+00A7>three<U+00A7>\n","n":"1"}');
        Observer.Expect('le-S-len', '18');
        Observer.Expect('le-S-eq', 'Yes');
        Observer.Expect('le-E', 'Yes|Yes||{"q":"<U+00E9>one two<U+00E9>\n<U+00E9>three<U+00E9>\n","n":"1"}');
        Observer.Expect('le-E-len', '18');
        Observer.Expect('le-E-eq', 'Yes');
        Observer.Expect('le-U', 'Yes|Yes||{"q":"<U+00FC>one two<U+00FC>\n<U+00FC>three<U+00FC>\n","n":"1"}');
        Observer.Expect('le-U-len', '18');
        Observer.Expect('le-U-eq', 'Yes');
        Observer.Expect('le-O', 'Yes|Yes||{"q":"<U+00F8>one two<U+00F8>\n<U+00F8>three<U+00F8>\n","n":"1"}');
        Observer.Expect('le-O-len', '18');
        Observer.Expect('le-O-eq', 'Yes');
        Observer.Expect('le-R', 'Yes|Yes||{"q":"<U+20AC>one two<U+20AC>\n<U+20AC>three<U+20AC>\n","n":"1"}');
        Observer.Expect('le-R-len', '18');
        Observer.Expect('le-R-eq', 'Yes');
        Observer.Expect('le-M', 'Yes|Yes||{"q":"<U+D83D><U+DE00>one two<U+D83D><U+DE00>\n<U+D83D><U+DE00>three<U+D83D><U+DE00>\n","n":"1"}');
        Observer.Expect('le-M-len', '22');
        Observer.Expect('le-M-eq', 'Yes');
        Observer.Expect('le-C', 'Yes|Yes||{"q":"e<U+0301>one twoe<U+0301>\ne<U+0301>threee<U+0301>\n","n":"1"}');
        Observer.Expect('le-C-len', '22');
        Observer.Expect('le-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedCharOnly_Read()
    begin
        EachChar('fo', 'q: >-~  {X}~n: 1', 0, '{X}');
        Observer.Expect('fo-S', 'Yes|Yes||{"q":"<U+00A7>","n":"1"}');
        Observer.Expect('fo-S-len', '1');
        Observer.Expect('fo-S-eq', 'Yes');
        Observer.Expect('fo-E', 'Yes|Yes||{"q":"<U+00E9>","n":"1"}');
        Observer.Expect('fo-E-len', '1');
        Observer.Expect('fo-E-eq', 'Yes');
        Observer.Expect('fo-U', 'Yes|Yes||{"q":"<U+00FC>","n":"1"}');
        Observer.Expect('fo-U-len', '1');
        Observer.Expect('fo-U-eq', 'Yes');
        Observer.Expect('fo-O', 'Yes|Yes||{"q":"<U+00F8>","n":"1"}');
        Observer.Expect('fo-O-len', '1');
        Observer.Expect('fo-O-eq', 'Yes');
        Observer.Expect('fo-R', 'Yes|Yes||{"q":"<U+20AC>","n":"1"}');
        Observer.Expect('fo-R-len', '1');
        Observer.Expect('fo-R-eq', 'Yes');
        Observer.Expect('fo-M', 'Yes|Yes||{"q":"<U+D83D><U+DE00>","n":"1"}');
        Observer.Expect('fo-M-len', '2');
        Observer.Expect('fo-M-eq', 'Yes');
        Observer.Expect('fo-C', 'Yes|Yes||{"q":"e<U+0301>","n":"1"}');
        Observer.Expect('fo-C-len', '2');
        Observer.Expect('fo-C-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8DoubleQuotedEscapes_Read()
    begin
        Cell('u-upper', 'q: "a{\}u00A7b"', 0, 'a{S}b');
        Cell('u-lower', 'q: "a{\}u00e9b"', 0, 'a{E}b');
        Cell('x', 'q: "a{\}xA7b"', 0, 'a{S}b');
        Cell('u-euro', 'q: "a{\}u20ACb"', 0, 'a{R}b');
        Cell('U-emoji', 'q: "a{\}U0001F600b"', 0, 'a{M}b');
        Cell('u-pair', 'q: "a{\}uD83D{\}uDE00b"', 0, 'a{M}b');
        Cell('u-comb', 'q: "ae{\}u0301b"', 0, 'a{C}b');
        Observer.Expect('u-upper', 'Yes|Yes||{"q":"a<U+00A7>b"}');
        Observer.Expect('u-upper-len', '3');
        Observer.Expect('u-upper-eq', 'Yes');
        Observer.Expect('u-lower', 'Yes|Yes||{"q":"a<U+00E9>b"}');
        Observer.Expect('u-lower-len', '3');
        Observer.Expect('u-lower-eq', 'Yes');
        Observer.Expect('x', 'Yes|Yes||{"q":"a<U+00A7>b"}');
        Observer.Expect('x-len', '3');
        Observer.Expect('x-eq', 'Yes');
        Observer.Expect('u-euro', 'Yes|Yes||{"q":"a<U+20AC>b"}');
        Observer.Expect('u-euro-len', '3');
        Observer.Expect('u-euro-eq', 'Yes');
        Observer.Expect('U-emoji', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b"}');
        Observer.Expect('U-emoji-len', '4');
        Observer.Expect('U-emoji-eq', 'Yes');
        Observer.Expect('u-pair', 'Yes|Yes||{"q":"a<U+D83D><U+DE00>b"}');
        Observer.Expect('u-pair-len', '4');
        Observer.Expect('u-pair-eq', 'Yes');
        Observer.Expect('u-comb', 'Yes|Yes||{"q":"ae<U+0301>b"}');
        Observer.Expect('u-comb-len', '4');
        Observer.Expect('u-comb-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8DoubleQuotedNamedEscapes_Read()
    begin
        Cell('N', 'q: "a{\}Nb"', 0, 'a{N}b');
        Cell('nbsp', 'q: "a{\}_b"', 0, 'a{A}b');
        Cell('L', 'q: "a{\}Lb"', 0, 'a{L}b');
        Cell('P', 'q: "a{\}Pb"', 0, 'a{P}b');
        Cell('sq-literal', 'q: ''a{\}u00A7b''', 0, 'a{\}u00A7b');
        Cell('plain-literal', 'q: a{\}u00A7b', 0, 'a{\}u00A7b');
        Cell('folded-literal', 'q: >-~  a{\}u00A7b~n: 1', 0, 'a{\}u00A7b');
        Observer.Expect('N', 'Yes|Yes||{"q":"a\u0085b"}');
        Observer.Expect('N-len', '3');
        Observer.Expect('N-eq', 'Yes');
        Observer.Expect('nbsp', 'Yes|Yes||{"q":"a<U+00A0>b"}');
        Observer.Expect('nbsp-len', '3');
        Observer.Expect('nbsp-eq', 'Yes');
        Observer.Expect('L', 'Yes|Yes||{"q":"a\u2028b"}');
        Observer.Expect('L-len', '3');
        Observer.Expect('L-eq', 'Yes');
        Observer.Expect('P', 'Yes|Yes||{"q":"a\u2029b"}');
        Observer.Expect('P-len', '3');
        Observer.Expect('P-eq', 'Yes');
        Observer.Expect('sq-literal', 'Yes|Yes||{"q":"a\\u00A7b"}');
        Observer.Expect('sq-literal-len', '8');
        Observer.Expect('sq-literal-eq', 'Yes');
        Observer.Expect('plain-literal', 'Yes|Yes||{"q":"a\\u00A7b"}');
        Observer.Expect('plain-literal-len', '8');
        Observer.Expect('plain-literal-eq', 'Yes');
        Observer.Expect('folded-literal', 'Yes|Yes||{"q":"a\\u00A7b","n":"1"}');
        Observer.Expect('folded-literal-len', '8');
        Observer.Expect('folded-literal-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FlowAndComments_Read()
    begin
        Cell('flow-list', 'k: [a{S}b, "c{R}d", ''e{M}f'']', 2, 'a{S}b');
        Cell('flow-map', 'q: {x{E}: y{M}}', 0, '');
        Cell('comment-line', '# c{S}{R}{M}~q: v', 0, 'v');
        Cell('comment-tail', 'q: v{U} # c{S}{M}', 0, 'v{U}');
        Cell('all-folded', 'q: >-~  {S}{E}{U}{O}{R}{M}{C}~n: 1', 0, '{S}{E}{U}{O}{R}{M}{C}');
        Cell('all-plain', 'q: {S} {E} {U} {O} {R} {M} {C}', 0, '{S} {E} {U} {O} {R} {M} {C}');
        Observer.Expect('flow-list', 'Yes|Yes||{"k":["a<U+00A7>b","c<U+20AC>d","e<U+D83D><U+DE00>f"]}');
        Observer.Expect('flow-list-len', '3');
        Observer.Expect('flow-list-eq', 'Yes');
        Observer.Expect('flow-map', 'Yes|Yes||{"q":{"x<U+00E9>":"y<U+D83D><U+DE00>"}}');
        Observer.Expect('flow-map-len', 'no value');
        Observer.Expect('comment-line', 'Yes|Yes||{"q":"v"}');
        Observer.Expect('comment-line-len', '1');
        Observer.Expect('comment-line-eq', 'Yes');
        Observer.Expect('comment-tail', 'Yes|Yes||{"q":"v<U+00FC>"}');
        Observer.Expect('comment-tail-len', '2');
        Observer.Expect('comment-tail-eq', 'Yes');
        Observer.Expect('all-folded', 'Yes|Yes||{"q":"<U+00A7><U+00E9><U+00FC><U+00F8><U+20AC><U+D83D><U+DE00>e<U+0301>","n":"1"}');
        Observer.Expect('all-folded-len', '9');
        Observer.Expect('all-folded-eq', 'Yes');
        Observer.Expect('all-plain', 'Yes|Yes||{"q":"<U+00A7> <U+00E9> <U+00FC> <U+00F8> <U+20AC> <U+D83D><U+DE00> e<U+0301>"}');
        Observer.Expect('all-plain-len', '15');
        Observer.Expect('all-plain-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8IssueDocument_Read()
    var
        Src: Text;
    begin
        Src := 'name: x~description: >-~  T1 {S} 19.11 ask-order test, two turns. Turn 1: a clear item reference but no~  shipment/invoice number anywhere - the agent must ask~tests:~  - name: t~    description: Ask-order primary question.~';
        Cell('issue', Src, 0, '');
        Cell('issue-crlf', Src.Replace('~', '^'), 0, '');
        Cell('issue-item', 'k:~  - name: t~    description: >-~      T1 {S} 19.11 ask~      next {R} line~    n: 1~  - name: u', 0, '');
        Observer.Expect('issue', 'Yes|Yes||{"name":"x","description":"T1 <U+00A7> 19.11 ask-order test, two turns. Turn 1: a clear item reference but no shipment/invoice number anywhere - the agent must ask","tests":[{"name":"t","description":"Ask-order primary question."}]}');
        Observer.Expect('issue-len', 'no value');
        Observer.Expect('issue-crlf', 'Yes|Yes||{"name":"x","description":"T1 <U+00A7> 19.11 ask-order test, two turns. Turn 1: a clear item reference but no shipment/invoice number anywhere - the agent must ask","tests":[{"name":"t","description":"Ask-order primary question."}]}');
        Observer.Expect('issue-crlf-len', 'no value');
        Observer.Expect('issue-item', 'Yes|Yes||{"k":[{"name":"t","description":"T1 <U+00A7> 19.11 ask next <U+20AC> line","n":"1"},{"name":"u"}]}');
        Observer.Expect('issue-item-len', 'no value');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8IssueDescriptionLen_Read()
    begin
        Cell('desc', 'q: >-~  T1 {S} 19.11 ask-order test, two turns. Turn 1: a clear item reference but no~  shipment/invoice number anywhere - the agent must ask~tests:~  - name: t~    description: Ask-order primary question.~', 0, 'T1 {S} 19.11 ask-order test, two turns. Turn 1: a clear item reference but no shipment/invoice number anywhere - the agent must ask');
        Observer.Expect('desc', 'Yes|Yes||{"q":"T1 <U+00A7> 19.11 ask-order test, two turns. Turn 1: a clear item reference but no shipment/invoice number anywhere - the agent must ask","tests":[{"name":"t","description":"Ask-order primary question."}]}');
        Observer.Expect('desc-len', '129');
        Observer.Expect('desc-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SpecialPlain_Read()
    begin
        EachSpecial('sp', 'q: a{X}b~n: 1', 0, 'a{X}b');
        Observer.Expect('sp-A', 'Yes|Yes||{"q":"a<U+00A0>b","n":"1"}');
        Observer.Expect('sp-A-len', '3');
        Observer.Expect('sp-A-eq', 'Yes');
        Observer.Expect('sp-N', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sp-N-len', 'no value');
        Observer.Expect('sp-L', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sp-L-len', 'no value');
        Observer.Expect('sp-P', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sp-P-len', 'no value');
        Observer.Expect('sp-B', 'Yes|Yes||{"q":"a<U+FEFF>b","n":"1"}');
        Observer.Expect('sp-B-len', '3');
        Observer.Expect('sp-B-eq', 'Yes');
        Observer.Expect('sp-K', 'Yes|Yes||{"q":"a<U+0080>b","n":"1"}');
        Observer.Expect('sp-K-len', '3');
        Observer.Expect('sp-K-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SpecialFolded_Read()
    begin
        EachSpecial('sf', 'q: >-~  a{X}b~n: 1', 0, 'a{X}b');
        Observer.Expect('sf-A', 'Yes|Yes||{"q":"a<U+00A0>b","n":"1"}');
        Observer.Expect('sf-A-len', '3');
        Observer.Expect('sf-A-eq', 'Yes');
        Observer.Expect('sf-N', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sf-N-len', 'no value');
        Observer.Expect('sf-L', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sf-L-len', 'no value');
        Observer.Expect('sf-P', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sf-P-len', 'no value');
        Observer.Expect('sf-B', 'Yes|Yes||{"q":"a<U+FEFF>b","n":"1"}');
        Observer.Expect('sf-B-len', '3');
        Observer.Expect('sf-B-eq', 'Yes');
        Observer.Expect('sf-K', 'Yes|Yes||{"q":"a<U+0080>b","n":"1"}');
        Observer.Expect('sf-K-len', '3');
        Observer.Expect('sf-K-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SpecialDoubleQuoted_Read()
    begin
        EachSpecial('sd', 'q: "a{X}b"~n: 1', 0, 'a{X}b');
        Observer.Expect('sd-A', 'Yes|Yes||{"q":"a<U+00A0>b","n":"1"}');
        Observer.Expect('sd-A-len', '3');
        Observer.Expect('sd-A-eq', 'Yes');
        Observer.Expect('sd-N', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sd-N-len', 'no value');
        Observer.Expect('sd-L', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sd-L-len', 'no value');
        Observer.Expect('sd-P', 'Yes|No|The data does not represent valid YAML.|{}');
        Observer.Expect('sd-P-len', 'no value');
        Observer.Expect('sd-B', 'Yes|Yes||{"q":"a<U+FEFF>b","n":"1"}');
        Observer.Expect('sd-B-len', '3');
        Observer.Expect('sd-B-eq', 'Yes');
        Observer.Expect('sd-K', 'Yes|Yes||{"q":"a<U+0080>b","n":"1"}');
        Observer.Expect('sd-K-len', '3');
        Observer.Expect('sd-K-eq', 'Yes');
        Observer.Verify();
    end;

    local procedure StreamCell(Name: Text; Src: Text; OutEnc: Integer; InEnc: Integer; Expected: Text)
    var
        Blob: Record "YU8 Yaml Blob";
        OutS: OutStream;
        InS: InStream;
        Ret: Boolean;
    begin
        Blob.DeleteAll();
        Blob.Id := 1;
        case OutEnc of
            0:
                Blob.Data.CreateOutStream(OutS);
            1:
                Blob.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        end;
        OutS.WriteText(Doc(Src));
        Blob.Insert();
        Blob.CalcFields(Data);
        case InEnc of
            0:
                Blob.Data.CreateInStream(InS);
            1:
                Blob.Data.CreateInStream(InS, TextEncoding::UTF8);
        end;
        ClearLastError();
        Ret := TryReadStream(InS);
        ObserveRead(Name, Ret, 0, Expected);
        Blob.DeleteAll();
    end;

    [Test]
    procedure ReadFromYaml_Utf8InStream_Read()
    var
        Src: Text;
    begin
        Src := 'q: >-~  T1 {S} {E}{U}{O} {R} {M} {C}~  next~n: 1';
        StreamCell('default-default', Src, 0, 0, 'T1 {S} {E}{U}{O} {R} {M} {C} next');
        StreamCell('utf8-utf8', Src, 1, 1, 'T1 {S} {E}{U}{O} {R} {M} {C} next');
        StreamCell('utf8-default', Src, 1, 0, 'T1 {S} {E}{U}{O} {R} {M} {C} next');
        StreamCell('default-utf8', Src, 0, 1, 'T1 {S} {E}{U}{O} {R} {M} {C} next');
        Observer.Expect('default-default', 'Yes|Yes||{"q":"T1 \u0015 <U+FFFD><U+FFFD><U+FFFD> <U+FFFD> ?? e<U+FFFD> next","n":"1"}');
        Observer.Expect('default-default-len', '21');
        Observer.Expect('default-default-eq', 'No');
        Observer.Expect('utf8-utf8', 'Yes|Yes||{"q":"T1 <U+00A7> <U+00E9><U+00FC><U+00F8> <U+20AC> <U+D83D><U+DE00> e<U+0301> next","n":"1"}');
        Observer.Expect('utf8-utf8-len', '21');
        Observer.Expect('utf8-utf8-eq', 'Yes');
        Observer.Expect('utf8-default', 'Yes|Yes||{"q":"T1 <U+00A7> <U+00E9><U+00FC><U+00F8> <U+20AC> <U+D83D><U+DE00> e<U+0301> next","n":"1"}');
        Observer.Expect('utf8-default-len', '21');
        Observer.Expect('utf8-default-eq', 'Yes');
        Observer.Expect('default-utf8', 'Yes|Yes||{"q":"T1 \u0015 <U+FFFD><U+FFFD><U+FFFD> <U+FFFD> ?? e<U+FFFD> next","n":"1"}');
        Observer.Expect('default-utf8-len', '21');
        Observer.Expect('default-utf8-eq', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_PlainComma_Read()
    begin
        PlainAll('p', 'a, b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainDots_Read()
    begin
        PlainAll('p', 'a ...');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainCommaDots_Read()
    begin
        PlainAll('p', 'Ask-order primary question, then fallthrough ...');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainQuotedColon_Read()
    begin
        PlainAll('p', 'say "a: b" end');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainQuotedColonSingle_Read()
    begin
        PlainAll('p', 'say ''a: b'' end');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainColonNoSpace_Read()
    begin
        PlainAll('p', 'a:b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainSpaceHash_Read()
    begin
        PlainAll('p', 'a #b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainHashNoSpace_Read()
    begin
        PlainAll('p', 'a#b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainParens_Read()
    begin
        PlainAll('p', 'a (b) c');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainSlash_Read()
    begin
        PlainAll('p', 'a/b c');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainApostrophe_Read()
    begin
        PlainAll('p', 'it''s ok');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainDoubleQuoteMid_Read()
    begin
        PlainAll('p', 'a "b" c');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainHyphenLeading_Read()
    begin
        PlainAll('p', '-a b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainHyphenTrailing_Read()
    begin
        PlainAll('p', 'a b-');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainHyphenWord_Read()
    begin
        PlainAll('p', 'a - b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainQuestionMid_Read()
    begin
        PlainAll('p', 'a ? b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainBrackets_Read()
    begin
        PlainAll('p', 'a [b] c');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainPercent_Read()
    begin
        PlainAll('p', 'a % b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_PlainAtAmp_Read()
    begin
        PlainAll('p', 'a @ b & c');
        Observer.Finish();
    end;
}
