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
    // {M} U+1F600 (surrogate pair), {C} 'e' + U+0301, {A} U+00A0, {N} U+0085, {L} U+2028, {P} U+2029, {B} U+FEFF, {K} U+0080.
    local procedure Doc(Src: Text): Text
    begin
        Src := Src.Replace('^', Chr(13) + Chr(10)).Replace('~', Chr(10));
        Src := Src.Replace('{S}', Chr(167)).Replace('{E}', Chr(233)).Replace('{U}', Chr(252)).Replace('{O}', Chr(248));
        Src := Src.Replace('{R}', Chr(8364)).Replace('{M}', Chr(55357) + Chr(56832)).Replace('{C}', 'e' + Chr(769));
        Src := Src.Replace('{A}', Chr(160)).Replace('{N}', Chr(133)).Replace('{L}', Chr(8232)).Replace('{P}', Chr(8233));
        Src := Src.Replace('{B}', Chr(65279)).Replace('{K}', Chr(128));
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8Folded_Read()
    begin
        EachChar('fk', 'q: >~  a{X}b~n: 1', 0, 'a{X}b~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8Literal_Read()
    begin
        EachChar('lk', 'q: |~  a{X}b~n: 1', 0, 'a{X}b~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8LiteralStrip_Read()
    begin
        EachChar('ls', 'q: |-~  a{X}b~n: 1', 0, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8Plain_Read()
    begin
        EachChar('pl', 'q: a{X}b~n: 1', 0, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8PlainCharOnly_Read()
    begin
        EachChar('po', 'q: {X}~n: 1', 0, '{X}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SingleQuoted_Read()
    begin
        EachChar('sq', 'q: ''a{X}b''~n: 1', 0, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8DoubleQuoted_Read()
    begin
        EachChar('dq', 'q: "a{X}b"~n: 1', 0, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8MappingKey_Read()
    begin
        EachChar('key', 'a{X}b: 1~n: 2', 1, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8ListItem_Read()
    begin
        EachChar('item', 'k:~  - a{X}b~  - c', 2, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedLineEdges_Read()
    begin
        EachChar('fe', 'q: >-~  {X}one two{X}~  {X}three{X}~n: 1', 0, '{X}one two{X} {X}three{X}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedKeepLineEdges_Read()
    begin
        EachChar('fke', 'q: >~  {X}one{X}~~  {X}two{X}~n: 1', 0, '{X}one{X}~{X}two{X}~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8LiteralLineEdges_Read()
    begin
        EachChar('le', 'q: |~  {X}one two{X}~  {X}three{X}~n: 1', 0, '{X}one two{X}~{X}three{X}~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8FoldedCharOnly_Read()
    begin
        EachChar('fo', 'q: >-~  {X}~n: 1', 0, '{X}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8DoubleQuotedEscapes_Read()
    begin
        Cell('u-upper', 'q: "a§b"', 0, 'a{S}b');
        Cell('u-lower', 'q: "aéb"', 0, 'a{E}b');
        Cell('x', 'q: "a\xA7b"', 0, 'a{S}b');
        Cell('u-euro', 'q: "a€b"', 0, 'a{R}b');
        Cell('U-emoji', 'q: "a\U0001F600b"', 0, 'a{M}b');
        Cell('u-pair', 'q: "a😀b"', 0, 'a{M}b');
        Cell('u-comb', 'q: "aéb"', 0, 'a{C}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8DoubleQuotedNamedEscapes_Read()
    begin
        Cell('N', 'q: "a\Nb"', 0, 'a{N}b');
        Cell('nbsp', 'q: "a\_b"', 0, 'a{A}b');
        Cell('L', 'q: "a\Lb"', 0, 'a{L}b');
        Cell('P', 'q: "a\Pb"', 0, 'a{P}b');
        Cell('sq-literal', 'q: ''a§b''', 0, 'a§b');
        Cell('plain-literal', 'q: a§b', 0, 'a§b');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8IssueDescriptionLen_Read()
    begin
        Cell('desc', 'q: >-~  T1 {S} 19.11 ask-order test, two turns. Turn 1: a clear item reference but no~  shipment/invoice number anywhere - the agent must ask~tests:~  - name: t~    description: Ask-order primary question.~', 0, 'T1 {S} 19.11 ask-order test, two turns. Turn 1: a clear item reference but no shipment/invoice number anywhere - the agent must ask');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SpecialPlain_Read()
    begin
        EachSpecial('sp', 'q: a{X}b~n: 1', 0, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SpecialFolded_Read()
    begin
        EachSpecial('sf', 'q: >-~  a{X}b~n: 1', 0, 'a{X}b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Utf8SpecialDoubleQuoted_Read()
    begin
        EachSpecial('sd', 'q: "a{X}b"~n: 1', 0, 'a{X}b');
        Observer.Finish();
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
        Observer.Finish();
    end;
}
