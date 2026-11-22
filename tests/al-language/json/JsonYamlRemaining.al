// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 79891 "YRM Yaml Blob"
// Probe: AL Runner issue 8580 (AI eval datasets in .yaml app resources); follows corpus PRs 1515 (non-ASCII) and 1519
//   (punctuation matrix) and the runner fix PR 8711. Measures YAML shapes the runner still refuses.
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: JsonObject.ReadFromYaml on Text and on an InStream (UTF-8 bytes), same document each time.
//   Each cell shows one result when both overloads agree, else 'T <text result> | S <stream result>'.
//   A result is the JSON text WriteTo gave (characters outside printable ASCII as <U+XXXX>), or 'F<code>:<text>' when
//   ReadFromYaml returned false, or 'X<code>:<text>' when it raised an error.
//   1. Sequence items that become a mapping or a nested sequence, alone and mixed with plain items, at indent 2 and 4.
//   2. Block scalars (|, >, |-, >+) whose first content line is indented 3 spaces, and explicit indentation indicators.
//   3. Double-quoted escapes \b \t \/ \x41 \0 \e \N \_ \L \P, a literal e acute, and an invalid one (\q).
//   4. CRLF line ends combined with the punctuation cases of the 1519 matrix (': ', ' #', '- ', quotes) in seven
//      scalar positions, compared with the same document in LF; and mixed LF/CRLF documents.
//   5. The shapes of the reporter's dataset files: a list item whose first key opens a nested block mapping with sibling
//      keys after it, multi-key list item mappings with quoted keys, a comment line before the first item, a blank line
//      between items, long double-quoted values with HTML, brackets and ': ', and the reporter's full example verbatim.
// Results (identical on BC 27.5, 28.5 and 29.0, no version guard needed):
//   Tags: !!int, !!float and !!bool resolve to number, number and boolean; !!timestamp gives a date-time text;
//   !!set, !!seq, !!binary and custom tags fail with YamlBadFormat.
//   Merge key '<<' is not merged (the key '<<' stays); anchors and aliases copy the anchored value.
//   A complex (collection) key becomes the key text '(Collection)'. A duplicate key: the last value wins, no error.
//   A top-level document that is not a mapping returns false with InvalidJsonType; a second document ('---') is YamlBadFormat.
//   Flow or block nesting of 100 levels or more is InvalidJsonData. Tab indentation is YamlBadFormat.
//   Plain scalars yes, on, 0x.. and .inf stay text. A byte order mark stays in the first key when read from Text and is
//   removed when read from an InStream.
//   Block scalars: content indented 3 spaces works for |, >, |- and >+; a wrong indentation indicator is YamlBadFormat.
//   Double-quoted escapes \b \t \/ \x41 \0 \e \N \_ \L \P \u00E9 are decoded; \q is YamlBadFormat.
//   Dataset shapes: all of group 5 are read as written (nested mapping under a dash line key, quoted keys, comment and
//   blank lines inside a sequence, HTML text in quoted values); the full example reads back, scalar numbers as text.
//   CRLF line ends: the per-cell result for each punctuation case is asserted (see the Expect lines of the Crlf tests).
// BC versions: 27, 28, 29

table 79891 "YRM Yaml Blob"
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

codeunit 79892 "YRM Json Yaml Remaining"
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

    // '{~}' a tilde, '{T}' tab, '{B}' U+FEFF, '{0}' NUL, '{S}' a space, '~' line feed, '^' carriage return + line feed, '{R}' a lone carriage return, '{\}' a backslash (Chr(92): no tool on the
    // way unescapes it before YAML does), '{E}' U+00E9, '{I}' the indent unit of the test.
    local procedure Doc(Src: Text; Indent: Text): Text
    begin
        Src := Src.Replace('{~}', Chr(7)).Replace('^', Chr(13) + Chr(10)).Replace('~', Chr(10)).Replace(Chr(7), '~');
        Src := Src.Replace('{T}', Chr(9)).Replace('{B}', Chr(65279)).Replace('{0}', Chr(0)).Replace('{S}', ' ');
        Src := Src.Replace('{R}', Chr(13)).Replace('{\}', Chr(92)).Replace('{E}', Chr(233)).Replace('{I}', Indent);
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

    // The result of one read; JPath <> '' and the value there equal to Expected gives 'ok'.
    local procedure Result(Src: Text; ViaStream: Boolean; JPath: Text; Expected: Text): Text
    var
        Blob: Record "YRM Yaml Blob";
        OutS: OutStream;
        InS: InStream;
        Tok: JsonToken;
        Out: Text;
        Done: Boolean;
    begin
        ClearLastError();
        if ViaStream then begin
            Blob.DeleteAll();
            Blob.Id := 1;
            Blob.Data.CreateOutStream(OutS, TextEncoding::UTF8);
            OutS.WriteText(Src);
            Blob.Insert();
            Blob.CalcFields(Data);
            Blob.Data.CreateInStream(InS, TextEncoding::UTF8);
            Done := TryReadStream(InS);
            Blob.DeleteAll();
        end else
            Done := TryRead(Src);
        if not Done then
            exit(ErrText('X'));
        if not Ok then
            exit(ErrText('F'));
        if JPath <> '' then
            if JO.SelectToken(JPath, Tok) then
                if Tok.IsValue() then
                    if not Tok.AsValue().IsNull() then
                        if Tok.AsValue().AsText() = Expected then
                            exit('ok');
        JO.WriteTo(Out);
        exit(Esc(Out));
    end;

    // Text and stream result of one document: one result when equal.
    local procedure Both(Src: Text; JPath: Text; Expected: Text): Text
    var
        T: Text;
        S: Text;
    begin
        T := Result(Src, false, JPath, Expected);
        S := Result(Src, true, JPath, Expected);
        if T = S then
            exit(T);
        exit('T ' + T + ' | S ' + S);
    end;

    local procedure Cell(Name: Text; Src: Text; Indent: Text)
    begin
        Observer.Observe(Name, Both(Doc(Src, Indent), '', ''));
    end;

    // ---- 1. sequence items ----

    local procedure SeqCells(Indent: Text)
    begin
        Cell('map2', 'k:~{I}- a: 1~{I}  b: 2', Indent);
        Cell('map2-sib', 'k:~{I}- a: 1~{I}  b: 2~n: 1', Indent);
        Cell('map-wide', 'k:~{I}-   a: 1~{I}    b: 2', Indent);
        Cell('map-one', 'k:~{I}- a: 1', Indent);
        Cell('nest', 'k:~{I}- - x', Indent);
        Cell('nest2', 'k:~{I}- - x~{I}  - y', Indent);
        Cell('nest-sib', 'k:~{I}- - x~{I}  - y~n: 1', Indent);
        Cell('nest-deep', 'k:~{I}- - - x', Indent);
    end;

    [Test]
    procedure ReadFromYaml_SeqItem_Indent2()
    begin
        SeqCells('  ');
        Observer.Expect('map2', '{"k":[{"a":"1","b":"2"}]}');
        Observer.Expect('map2-sib', '{"k":[{"a":"1","b":"2"}],"n":"1"}');
        Observer.Expect('map-wide', '{"k":[{"a":"1","b":"2"}]}');
        Observer.Expect('map-one', '{"k":[{"a":"1"}]}');
        Observer.Expect('nest', '{"k":[["x"]]}');
        Observer.Expect('nest2', '{"k":[["x","y"]]}');
        Observer.Expect('nest-sib', '{"k":[["x","y"]],"n":"1"}');
        Observer.Expect('nest-deep', '{"k":[[["x"]]]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_SeqItem_Indent4()
    begin
        SeqCells('    ');
        Observer.Expect('map2', '{"k":[{"a":"1","b":"2"}]}');
        Observer.Expect('map2-sib', '{"k":[{"a":"1","b":"2"}],"n":"1"}');
        Observer.Expect('map-wide', '{"k":[{"a":"1","b":"2"}]}');
        Observer.Expect('map-one', '{"k":[{"a":"1"}]}');
        Observer.Expect('nest', '{"k":[["x"]]}');
        Observer.Expect('nest2', '{"k":[["x","y"]]}');
        Observer.Expect('nest-sib', '{"k":[["x","y"]],"n":"1"}');
        Observer.Expect('nest-deep', '{"k":[[["x"]]]}');
        Observer.Verify();
    end;

    local procedure MixedCells(Indent: Text)
    begin
        Cell('plain-map', 'k:~{I}- p~{I}- a: 1~{I}  b: 2~{I}- q', Indent);
        Cell('map-plain', 'k:~{I}- a: 1~{I}  b: 2~{I}- p', Indent);
        Cell('plain-nest', 'k:~{I}- p~{I}- - x~{I}  - y~{I}- q', Indent);
        Cell('nest-plain', 'k:~{I}- - x~{I}  - y~{I}- p', Indent);
        Cell('map-nest', 'k:~{I}- a: 1~{I}  b: 2~{I}- - x~{I}- p', Indent);
        Cell('nest-map', 'k:~{I}- - x~{I}- a: 1~{I}  b: 2', Indent);
        Cell('map-seqvalue', 'k:~{I}- a: 1~{I}  b:~{I}  {I}- x~{I}  c: 3', Indent);
        Cell('map-map-map', 'k:~{I}- a: 1~{I}  b: 2~{I}- c: 3~{I}  d: 4', Indent);
    end;

    [Test]
    procedure ReadFromYaml_SeqItemMixed_Indent2()
    begin
        MixedCells('  ');
        Observer.Expect('plain-map', '{"k":["p",{"a":"1","b":"2"},"q"]}');
        Observer.Expect('map-plain', '{"k":[{"a":"1","b":"2"},"p"]}');
        Observer.Expect('plain-nest', '{"k":["p",["x","y"],"q"]}');
        Observer.Expect('nest-plain', '{"k":[["x","y"],"p"]}');
        Observer.Expect('map-nest', '{"k":[{"a":"1","b":"2"},["x"],"p"]}');
        Observer.Expect('nest-map', '{"k":[["x"],{"a":"1","b":"2"}]}');
        Observer.Expect('map-seqvalue', '{"k":[{"a":"1","b":["x"],"c":"3"}]}');
        Observer.Expect('map-map-map', '{"k":[{"a":"1","b":"2"},{"c":"3","d":"4"}]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_SeqItemMixed_Indent4()
    begin
        MixedCells('    ');
        Observer.Expect('plain-map', '{"k":["p",{"a":"1","b":"2"},"q"]}');
        Observer.Expect('map-plain', '{"k":[{"a":"1","b":"2"},"p"]}');
        Observer.Expect('plain-nest', '{"k":["p",["x","y"],"q"]}');
        Observer.Expect('nest-plain', '{"k":[["x","y"],"p"]}');
        Observer.Expect('map-nest', '{"k":[{"a":"1","b":"2"},["x"],"p"]}');
        Observer.Expect('nest-map', '{"k":[["x"],{"a":"1","b":"2"}]}');
        Observer.Expect('map-seqvalue', '{"k":[{"a":"1","b":["x"],"c":"3"}]}');
        Observer.Expect('map-map-map', '{"k":[{"a":"1","b":"2"},{"c":"3","d":"4"}]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_SeqItem_TopLevel()
    begin
        Cell('top-map', '- a: 1~  b: 2', '');
        Cell('top-nest', '- - x', '');
        Cell('top-plain', '- p~- q', '');
        Cell('top-nested-in-map', 'o:~  k:~    - a: 1~      b: 2~    - - x~  r: 2~n: 1', '');
        Observer.Expect('top-map', 'FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('top-nest', 'FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('top-plain', 'FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('top-nested-in-map', '{"o":{"k":[{"a":"1","b":"2"},["x"]],"r":"2"},"n":"1"}');
        Observer.Verify();
    end;

    // ---- 2. block scalars ----

    // Header H, first content line indented 3 spaces; the variants of the lines that follow.
    local procedure BlockCells(Header: Text)
    begin
        Cell('3-3', 'q: ' + Header + '~   x~   y~n: 1', '');
        Cell('3-5', 'q: ' + Header + '~   x~     y~n: 1', '');
        Cell('3-blank-3', 'q: ' + Header + '~   x~~   y~n: 1', '');
        Cell('3-2', 'q: ' + Header + '~   x~  y~n: 1', '');
        Cell('3-end-blank2', 'q: ' + Header + '~   x~~~n: 1', '');
        Cell('3-nested', 'o:~  q: ' + Header + '~     x~     y~  r: 2~n: 1', '');
        Cell('3-listmap', 'k:~  - m: ' + Header + '~       x~       y~    r: 2', '');
        Cell('3-last', 'q: ' + Header + '~   x~   y', '');
    end;

    [Test]
    procedure ReadFromYaml_Block3_Literal()
    begin
        BlockCells('|');
        Observer.Expect('3-3', '{"q":"x\ny\n","n":"1"}');
        Observer.Expect('3-5', '{"q":"x\n  y\n","n":"1"}');
        Observer.Expect('3-blank-3', '{"q":"x\n\ny\n","n":"1"}');
        Observer.Expect('3-2', 'FYamlBadFormat');
        Observer.Expect('3-end-blank2', '{"q":"x\n","n":"1"}');
        Observer.Expect('3-nested', '{"o":{"q":"x\ny\n","r":"2"},"n":"1"}');
        Observer.Expect('3-listmap', '{"k":[{"m":"x\ny\n","r":"2"}]}');
        Observer.Expect('3-last', '{"q":"x\ny"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Block3_Folded()
    begin
        BlockCells('>');
        Observer.Expect('3-3', '{"q":"x y\n","n":"1"}');
        Observer.Expect('3-5', '{"q":"x\n  y\n","n":"1"}');
        Observer.Expect('3-blank-3', '{"q":"x\ny\n","n":"1"}');
        Observer.Expect('3-2', 'FYamlBadFormat');
        Observer.Expect('3-end-blank2', '{"q":"x\n","n":"1"}');
        Observer.Expect('3-nested', '{"o":{"q":"x y\n","r":"2"},"n":"1"}');
        Observer.Expect('3-listmap', '{"k":[{"m":"x y\n","r":"2"}]}');
        Observer.Expect('3-last', '{"q":"x y"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Block3_LiteralStrip()
    begin
        BlockCells('|-');
        Observer.Expect('3-3', '{"q":"x\ny","n":"1"}');
        Observer.Expect('3-5', '{"q":"x\n  y","n":"1"}');
        Observer.Expect('3-blank-3', '{"q":"x\n\ny","n":"1"}');
        Observer.Expect('3-2', 'FYamlBadFormat');
        Observer.Expect('3-end-blank2', '{"q":"x","n":"1"}');
        Observer.Expect('3-nested', '{"o":{"q":"x\ny","r":"2"},"n":"1"}');
        Observer.Expect('3-listmap', '{"k":[{"m":"x\ny","r":"2"}]}');
        Observer.Expect('3-last', '{"q":"x\ny"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Block3_FoldedKeep()
    begin
        BlockCells('>+');
        Observer.Expect('3-3', '{"q":"x y\n","n":"1"}');
        Observer.Expect('3-5', '{"q":"x\n  y\n","n":"1"}');
        Observer.Expect('3-blank-3', '{"q":"x\ny\n","n":"1"}');
        Observer.Expect('3-2', 'FYamlBadFormat');
        Observer.Expect('3-end-blank2', '{"q":"x\n\n\n","n":"1"}');
        Observer.Expect('3-nested', '{"o":{"q":"x y\n","r":"2"},"n":"1"}');
        Observer.Expect('3-listmap', '{"k":[{"m":"x y\n","r":"2"}]}');
        Observer.Expect('3-last', '{"q":"x y"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlockIndicator()
    begin
        Cell('lit2-at4', 'q: |2~    x~    y~n: 1', '');
        Cell('lit2-at2', 'q: |2~  x~  y~n: 1', '');
        Cell('lit2-at3', 'q: |2~   x~   y~n: 1', '');
        Cell('lit2-at4-then2', 'q: |2~    x~  y~n: 1', '');
        Cell('lit1-at1', 'q: |1~ x~ y~n: 1', '');
        Cell('lit1-at3', 'q: |1~   x~   y~n: 1', '');
        Cell('lit3-at3', 'q: |3~   x~   y~n: 1', '');
        Cell('lit3-at5', 'q: |3~     x~     y~n: 1', '');
        Cell('lit2strip-at4', 'q: |2-~    x~    y~n: 1', '');
        Cell('lit2keep-at4', 'q: |2+~    x~    y~~n: 1', '');
        Cell('lit-strip2-at4', 'q: |-2~    x~    y~n: 1', '');
        Cell('lit-keep2-at4', 'q: |+2~    x~    y~~n: 1', '');
        Cell('fold2-at4', 'q: >2~    x~    y~n: 1', '');
        Cell('fold2strip-at4', 'q: >2-~    x~    y~n: 1', '');
        Cell('fold2keep-at4', 'q: >+2~    x~    y~~n: 1', '');
        Cell('lit2-nested-at6', 'o:~  q: |2~      x~      y~  r: 2~n: 1', '');
        Cell('lit2-nested-at4', 'o:~  q: |2~    x~    y~  r: 2~n: 1', '');
        Cell('lit2-listmap-at8', 'k:~  - m: |2~        x~        y~    r: 2', '');
        Cell('lit2-blank-first', 'q: |2~~    x~n: 1', '');
        Cell('lit0', 'q: |0~  x~n: 1', '');
        Cell('lit10', 'q: |10~  x~n: 1', '');
        Observer.Expect('lit2-at4', '{"q":"  x\n  y\n","n":"1"}');
        Observer.Expect('lit2-at2', '{"q":"x\ny\n","n":"1"}');
        Observer.Expect('lit2-at3', '{"q":" x\n y\n","n":"1"}');
        Observer.Expect('lit2-at4-then2', '{"q":"  x\ny\n","n":"1"}');
        Observer.Expect('lit1-at1', '{"q":"x\ny\n","n":"1"}');
        Observer.Expect('lit1-at3', '{"q":"  x\n  y\n","n":"1"}');
        Observer.Expect('lit3-at3', '{"q":"x\ny\n","n":"1"}');
        Observer.Expect('lit3-at5', '{"q":"  x\n  y\n","n":"1"}');
        Observer.Expect('lit2strip-at4', '{"q":"  x\n  y","n":"1"}');
        Observer.Expect('lit2keep-at4', '{"q":"  x\n  y\n\n","n":"1"}');
        Observer.Expect('lit-strip2-at4', '{"q":"  x\n  y","n":"1"}');
        Observer.Expect('lit-keep2-at4', '{"q":"  x\n  y\n\n","n":"1"}');
        Observer.Expect('fold2-at4', '{"q":"  x\n  y\n","n":"1"}');
        Observer.Expect('fold2strip-at4', '{"q":"  x\n  y","n":"1"}');
        Observer.Expect('fold2keep-at4', '{"q":"  x\n  y\n\n","n":"1"}');
        Observer.Expect('lit2-nested-at6', '{"o":{"q":"  x\n  y\n","r":"2"},"n":"1"}');
        Observer.Expect('lit2-nested-at4', '{"o":{"q":"x\ny\n","r":"2"},"n":"1"}');
        Observer.Expect('lit2-listmap-at8', '{"k":[{"m":"  x\n  y\n","r":"2"}]}');
        Observer.Expect('lit2-blank-first', '{"q":"\n  x\n","n":"1"}');
        Observer.Expect('lit0', 'FYamlBadFormat');
        Observer.Expect('lit10', 'FYamlBadFormat');
        Observer.Verify();
    end;

    // ---- 3. double-quoted escapes ----

    local procedure EscCells(Prefix: Text; Tpl: Text)
    var
        Ks: List of [Text];
        K: Text;
    begin
        Ks.AddRange('b', 't', '/', 'x41', '0', 'e', 'N', '_', 'L', 'P', 'q', 'xE9', 'u00E9', 'a', 'r', 'n', 'v', 'f', '"', '{\}', ' ', 'x4', 'x', 'u12', '1');
        foreach K in Ks do
            if not (K in ['"', '{\}']) or (Prefix = 'top') then
                Cell(Prefix + '[' + K + ']', Tpl.Replace('{X}', '{\}' + K), '');
    end;

    [Test]
    procedure ReadFromYaml_DoubleQuotedEscape_Top()
    begin
        EscCells('top', 'q: "a{X}b"~n: 1');
        Cell('top[literal-e-acute]', 'q: "a{E}b"~n: 1', '');
        Observer.Expect('top[b]', '{"q":"a\bb","n":"1"}');
        Observer.Expect('top[t]', '{"q":"a\tb","n":"1"}');
        Observer.Expect('top[/]', '{"q":"a/b","n":"1"}');
        Observer.Expect('top[x41]', '{"q":"aAb","n":"1"}');
        Observer.Expect('top[0]', '{"q":"a\u0000b","n":"1"}');
        Observer.Expect('top[e]', '{"q":"a\u001bb","n":"1"}');
        Observer.Expect('top[N]', '{"q":"a\u0085b","n":"1"}');
        Observer.Expect('top[_]', '{"q":"a<U+00A0>b","n":"1"}');
        Observer.Expect('top[L]', '{"q":"a\u2028b","n":"1"}');
        Observer.Expect('top[P]', '{"q":"a\u2029b","n":"1"}');
        Observer.Expect('top[q]', 'FYamlBadFormat');
        Observer.Expect('top[xE9]', '{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('top[u00E9]', '{"q":"a<U+00E9>b","n":"1"}');
        Observer.Expect('top[a]', '{"q":"a\u0007b","n":"1"}');
        Observer.Expect('top[r]', '{"q":"a\rb","n":"1"}');
        Observer.Expect('top[n]', '{"q":"a\nb","n":"1"}');
        Observer.Expect('top[v]', '{"q":"a\u000bb","n":"1"}');
        Observer.Expect('top[f]', '{"q":"a\fb","n":"1"}');
        Observer.Expect('top["]', '{"q":"a\"b","n":"1"}');
        Observer.Expect('top[{\}]', '{"q":"a\\b","n":"1"}');
        Observer.Expect('top[ ]', '{"q":"a b","n":"1"}');
        Observer.Expect('top[x4]', '{"q":"aK","n":"1"}');
        Observer.Expect('top[x]', 'FYamlBadFormat');
        Observer.Expect('top[u12]', 'FYamlBadFormat');
        Observer.Expect('top[1]', 'FYamlBadFormat');
        Observer.Expect('top[literal-e-acute]', '{"q":"a<U+00E9>b","n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DoubleQuotedEscape_ListItem()
    begin
        EscCells('list', 'k:~  - "a{X}b"~  - c');
        Cell('list[literal-e-acute]', 'k:~  - "a{E}b"~  - c', '');
        Observer.Expect('list[b]', '{"k":["a\bb","c"]}');
        Observer.Expect('list[t]', '{"k":["a\tb","c"]}');
        Observer.Expect('list[/]', '{"k":["a/b","c"]}');
        Observer.Expect('list[x41]', '{"k":["aAb","c"]}');
        Observer.Expect('list[0]', '{"k":["a\u0000b","c"]}');
        Observer.Expect('list[e]', '{"k":["a\u001bb","c"]}');
        Observer.Expect('list[N]', '{"k":["a\u0085b","c"]}');
        Observer.Expect('list[_]', '{"k":["a<U+00A0>b","c"]}');
        Observer.Expect('list[L]', '{"k":["a\u2028b","c"]}');
        Observer.Expect('list[P]', '{"k":["a\u2029b","c"]}');
        Observer.Expect('list[q]', 'FYamlBadFormat');
        Observer.Expect('list[xE9]', '{"k":["a<U+00E9>b","c"]}');
        Observer.Expect('list[u00E9]', '{"k":["a<U+00E9>b","c"]}');
        Observer.Expect('list[a]', '{"k":["a\u0007b","c"]}');
        Observer.Expect('list[r]', '{"k":["a\rb","c"]}');
        Observer.Expect('list[n]', '{"k":["a\nb","c"]}');
        Observer.Expect('list[v]', '{"k":["a\u000bb","c"]}');
        Observer.Expect('list[f]', '{"k":["a\fb","c"]}');
        Observer.Expect('list[ ]', '{"k":["a b","c"]}');
        Observer.Expect('list[x4]', '{"k":["aK","c"]}');
        Observer.Expect('list[x]', 'FYamlBadFormat');
        Observer.Expect('list[u12]', 'FYamlBadFormat');
        Observer.Expect('list[1]', 'FYamlBadFormat');
        Observer.Expect('list[literal-e-acute]', '{"k":["a<U+00E9>b","c"]}');
        Observer.Verify();
    end;

    // ---- 4. CRLF ----

    // One slot text per position cell: S = item + 'ab', M = 'a' + item + 'b', E = 'ab' + item, W = 'a ' + item + ' b'.
    // The result of the CRLF document, or both results when the LF twin reads differently.
    local procedure CrlfMatrix(Tpl: Text; JPath: Text; ExpTpl: Text)
    var
        Items: List of [Text];
        Item: Text;
        Slots: List of [Text];
        Names: Text;
        V: Text;
        Line: Text;
        Crlf: Text;
        Lf: Text;
        i: Integer;
    begin
        Items.AddRange(': ', ' #', '- ', '"', '''');
        Names := 'SMEW';
        foreach Item in Items do begin
            Clear(Slots);
            Slots.Add(Item + 'ab');
            Slots.Add('a' + Item + 'b');
            Slots.Add('ab' + Item);
            Slots.Add('a ' + Item + ' b');
            Line := '';
            for i := 1 to 4 do begin
                V := Slots.Get(i);
                Crlf := Both(Doc(Tpl.Replace('{V}', V).Replace('~', '^'), ''), JPath, Doc(ExpTpl.Replace('{V}', V), ''));
                Lf := Both(Doc(Tpl.Replace('{V}', V), ''), JPath, Doc(ExpTpl.Replace('{V}', V), ''));
                if i > 1 then
                    Line += ' | ';
                Line += CopyStr(Names, i, 1) + ' ';
                if Crlf = Lf then
                    Line += Crlf
                else
                    Line += 'CRLF ' + Crlf + ' LF ' + Lf;
            end;
            Observer.Observe('[' + Item + ']', Line);
        end;
    end;

    [Test]
    procedure ReadFromYaml_Crlf_PlainTop()
    begin
        CrlfMatrix('q: {V}~n: 1', '$.q', '{V}');
        Observer.Expect('[: ]', 'S FYamlBadFormat | M FYamlBadFormat | E FYamlBadFormat | W FYamlBadFormat');
        Observer.Expect('[ #]', 'S {"q":null,"n":"1"} | M {"q":"a","n":"1"} | E {"q":"ab","n":"1"} | W {"q":"a","n":"1"}');
        Observer.Expect('[- ]', 'S FYamlBadFormat | M ok | E {"q":"ab-","n":"1"} | W ok');
        Observer.Expect('["]', 'S FYamlBadFormat | M ok | E ok | W ok');
        Observer.Expect('['']', 'S FYamlBadFormat | M ok | E ok | W ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_PlainListItem()
    begin
        CrlfMatrix('k:~  - {V}~  - c', '$.k[0]', '{V}');
        Observer.Expect('[: ]', 'S FYamlBadFormat | M {"k":[{"a":"b"},"c"]} | E {"k":[{"ab":null},"c"]} | W {"k":[{"a":"b"},"c"]}');
        Observer.Expect('[ #]', 'S {"k":[null,"c"]} | M {"k":["a","c"]} | E {"k":["ab","c"]} | W {"k":["a","c"]}');
        Observer.Expect('[- ]', 'S {"k":[["ab"],"c"]} | M ok | E {"k":["ab-","c"]} | W ok');
        Observer.Expect('["]', 'S FYamlBadFormat | M ok | E ok | W ok');
        Observer.Expect('['']', 'S FYamlBadFormat | M ok | E ok | W ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_PlainListMap()
    begin
        CrlfMatrix('k:~  - m: {V}~    r: 2~  - c', '$.k[0].m', '{V}');
        Observer.Expect('[: ]', 'S FYamlBadFormat | M FYamlBadFormat | E FYamlBadFormat | W FYamlBadFormat');
        Observer.Expect('[ #]', 'S {"k":[{"m":null,"r":"2"},"c"]} | M {"k":[{"m":"a","r":"2"},"c"]} | E {"k":[{"m":"ab","r":"2"},"c"]} | W {"k":[{"m":"a","r":"2"},"c"]}');
        Observer.Expect('[- ]', 'S FYamlBadFormat | M ok | E {"k":[{"m":"ab-","r":"2"},"c"]} | W ok');
        Observer.Expect('["]', 'S FYamlBadFormat | M ok | E ok | W ok');
        Observer.Expect('['']', 'S FYamlBadFormat | M ok | E ok | W ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_FoldedStrip()
    begin
        CrlfMatrix('q: >-~  {V}~  {V}~n: 1', '$.q', '{V} {V}');
        Observer.Expect('[: ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('[ #]', 'S {"q":"#ab #ab","n":"1"} | M ok | E ok | W ok');
        Observer.Expect('[- ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('["]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('['']', 'S ok | M ok | E ok | W ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_Literal()
    begin
        CrlfMatrix('q: |~  {V}~  {V}~n: 1', '$.q', '{V}~{V}~');
        Observer.Expect('[: ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('[ #]', 'S {"q":"#ab\n#ab\n","n":"1"} | M ok | E ok | W ok');
        Observer.Expect('[- ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('["]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('['']', 'S ok | M ok | E ok | W ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_DoubleQuoted()
    begin
        CrlfMatrix('q: "{V}"~n: 1', '$.q', '{V}');
        Observer.Expect('[: ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('[ #]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('[- ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('["]', 'S FYamlBadFormat | M FYamlBadFormat | E FYamlBadFormat | W FYamlBadFormat');
        Observer.Expect('['']', 'S ok | M ok | E ok | W ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_SingleQuoted()
    begin
        CrlfMatrix('q: ''{V}''~n: 1', '$.q', '{V}');
        Observer.Expect('[: ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('[ #]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('[- ]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('["]', 'S ok | M ok | E ok | W ok');
        Observer.Expect('['']', 'S FYamlBadFormat | M FYamlBadFormat | E FYamlBadFormat | W FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_CrlfMixed_Documents()
    begin
        Cell('all-crlf', 'q: a^n: 1^o:^  r: 2^  s: 3^k:^  - x^  - y^', '');
        Cell('all-lf', 'q: a~n: 1~o:~  r: 2~  s: 3~k:~  - x~  - y~', '');
        Cell('mixed-map', 'q: a^n: 1~o:^  r: 2~  s: 3^k:~  - x^  - y', '');
        Cell('mixed-folded', 'q: >-^  a~  b^  c~n: 1', '');
        Cell('mixed-literal', 'q: |~  a^  b~  c^n: 1', '');
        Cell('mixed-listmap', 'k:^  - m: v~    r: 2^  - c~', '');
        Cell('plain-multiline', 'q: a^  b~  c^n: 1', '');
        Cell('blank-crlf', 'q: a^^n: 1', '');
        Cell('blank-mixed', 'q: a^~n: 1', '');
        Cell('lone-cr', 'q: a{R}n: 1', '');
        Cell('lone-cr-in-block', 'q: |~  a{R}  b~n: 1', '');
        Cell('trailing-cr', 'q: a{R}', '');
        Cell('comment-crlf', '# c^q: a # d^n: 1', '');
        Observer.Expect('all-crlf', '{"q":"a","n":"1","o":{"r":"2","s":"3"},"k":["x","y"]}');
        Observer.Expect('all-lf', '{"q":"a","n":"1","o":{"r":"2","s":"3"},"k":["x","y"]}');
        Observer.Expect('mixed-map', '{"q":"a","n":"1","o":{"r":"2","s":"3"},"k":["x","y"]}');
        Observer.Expect('mixed-folded', '{"q":"a b c","n":"1"}');
        Observer.Expect('mixed-literal', '{"q":"a\nb\nc\n","n":"1"}');
        Observer.Expect('mixed-listmap', '{"k":[{"m":"v","r":"2"},"c"]}');
        Observer.Expect('plain-multiline', '{"q":"a b c","n":"1"}');
        Observer.Expect('blank-crlf', '{"q":"a","n":"1"}');
        Observer.Expect('blank-mixed', '{"q":"a","n":"1"}');
        Observer.Expect('lone-cr', '{"q":"a","n":"1"}');
        Observer.Expect('lone-cr-in-block', '{"q":"a\nb\n","n":"1"}');
        Observer.Expect('trailing-cr', '{"q":"a"}');
        Observer.Expect('comment-crlf', '{"q":"a","n":"1"}');
        Observer.Verify();
    end;
    // The first 240 characters of the result: for large or deep documents.
    local procedure CellShort(Name: Text; Src: Text)
    begin
        Observer.Observe(Name, CopyStr(Both(Doc(Src, ''), '', ''), 1, 240));
    end;

    // The documents From .. To of the list, each observed as '<document> => <result>'.
    local procedure Cells(Prefix: Text; Docs: List of [Text]; FirstNo: Integer; LastNo: Integer)
    var
        i: Integer;
    begin
        for i := FirstNo to LastNo do
            if i <= Docs.Count() then
                Observer.Observe(Prefix + Format(i), Docs.Get(i) + ' => ' + Both(Doc(Docs.Get(i), ''), '', ''));
    end;

    local procedure RepeatText(Unit: Text; Count: Integer): Text
    var
        i: Integer;
        Result: Text;
    begin
        for i := 1 to Count do
            Result += Unit;
        exit(Result);
    end;

    // ---- 5. everything else the YAML 1.2 spec lists ----
    // Cell names are '<group><n>': the document of cell n is the n-th entry of the list in its procedure.

    [Test]
    procedure ReadFromYaml_FlowSequence_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: [a, b]', 'q: [a, [b, c]]', 'q: []', 'q: [a, b,]', 'q: [ "a,b", ''c'' ]', 'q: [a: 1]', 'q: [a,~  b]', 'q: [a b, c]',
            'q: [a, # c~  b]', 'q: [1, 2]~n: 1', 'k:~  - [a, b]~  - c', 'q: [a, b] x', 'q: [a, b', 'q: [,]', 'q: [a, , b]', 'q: [ ]');
        Cells('fs', D, 1, 10);
        Observer.Expect('fs1', 'q: [a, b] => {"q":["a","b"]}');
        Observer.Expect('fs2', 'q: [a, [b, c]] => {"q":["a",["b","c"]]}');
        Observer.Expect('fs3', 'q: [] => {"q":[]}');
        Observer.Expect('fs4', 'q: [a, b,] => {"q":["a","b"]}');
        Observer.Expect('fs5', 'q: [ "a,b", ''c'' ] => {"q":["a,b","c"]}');
        Observer.Expect('fs6', 'q: [a: 1] => {"q":[{"a":"1"}]}');
        Observer.Expect('fs7', 'q: [a,~  b] => {"q":["a","b"]}');
        Observer.Expect('fs8', 'q: [a b, c] => {"q":["a b","c"]}');
        Observer.Expect('fs9', 'q: [a, # c~  b] => {"q":["a","b"]}');
        Observer.Expect('fs10', 'q: [1, 2]~n: 1 => {"q":["1","2"],"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_FlowSequence_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: [a, b]', 'q: [a, [b, c]]', 'q: []', 'q: [a, b,]', 'q: [ "a,b", ''c'' ]', 'q: [a: 1]', 'q: [a,~  b]', 'q: [a b, c]',
            'q: [a, # c~  b]', 'q: [1, 2]~n: 1', 'k:~  - [a, b]~  - c', 'q: [a, b] x', 'q: [a, b', 'q: [,]', 'q: [a, , b]', 'q: [ ]');
        Cells('fs', D, 11, 20);
        Observer.Expect('fs11', 'k:~  - [a, b]~  - c => {"k":[["a","b"],"c"]}');
        Observer.Expect('fs12', 'q: [a, b] x => FYamlBadFormat');
        Observer.Expect('fs13', 'q: [a, b => FYamlBadFormat');
        Observer.Expect('fs14', 'q: [,] => FYamlBadFormat');
        Observer.Expect('fs15', 'q: [a, , b] => FYamlBadFormat');
        Observer.Expect('fs16', 'q: [ ] => {"q":[]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_FlowMapping_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: {a: 1, b: 2}', 'q: {}', 'q: {a: [1, 2], b: {c: d}}', 'q: {a, b}', 'q: {a: 1,}', 'q: {a: 1,~  b: 2}', 'q: {"a b": 1}',
            'q: {a: }', 'q: {a:1}', 'q: {a: 1, a: 2}', 'q: {? a : 1}', 'q: {a: 1} x', 'q: {a: 1', 'q: { }', 'o:~  q: {a: 1}~  r: [b]', 'k:~  - {a: 1}~  - {b: 2}');
        Cells('fm', D, 1, 10);
        Observer.Expect('fm1', 'q: {a: 1, b: 2} => {"q":{"a":"1","b":"2"}}');
        Observer.Expect('fm2', 'q: {} => {"q":{}}');
        Observer.Expect('fm3', 'q: {a: [1, 2], b: {c: d}} => {"q":{"a":["1","2"],"b":{"c":"d"}}}');
        Observer.Expect('fm4', 'q: {a, b} => {"q":{"a":null,"b":null}}');
        Observer.Expect('fm5', 'q: {a: 1,} => {"q":{"a":"1"}}');
        Observer.Expect('fm6', 'q: {a: 1,~  b: 2} => {"q":{"a":"1","b":"2"}}');
        Observer.Expect('fm7', 'q: {"a b": 1} => {"q":{"a b":"1"}}');
        Observer.Expect('fm8', 'q: {a: } => {"q":{"a":null}}');
        Observer.Expect('fm9', 'q: {a:1} => {"q":{"a:1":null}}');
        Observer.Expect('fm10', 'q: {a: 1, a: 2} => {"q":{"a":"2"}}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_FlowMapping_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: {a: 1, b: 2}', 'q: {}', 'q: {a: [1, 2], b: {c: d}}', 'q: {a, b}', 'q: {a: 1,}', 'q: {a: 1,~  b: 2}', 'q: {"a b": 1}',
            'q: {a: }', 'q: {a:1}', 'q: {a: 1, a: 2}', 'q: {? a : 1}', 'q: {a: 1} x', 'q: {a: 1', 'q: { }', 'o:~  q: {a: 1}~  r: [b]', 'k:~  - {a: 1}~  - {b: 2}');
        Cells('fm', D, 11, 20);
        Observer.Expect('fm11', 'q: {? a : 1} => {"q":{"a":"1"}}');
        Observer.Expect('fm12', 'q: {a: 1} x => FYamlBadFormat');
        Observer.Expect('fm13', 'q: {a: 1 => FYamlBadFormat');
        Observer.Expect('fm14', 'q: { } => {"q":{}}');
        Observer.Expect('fm15', 'o:~  q: {a: 1}~  r: [b] => {"o":{"q":{"a":"1"},"r":["b"]}}');
        Observer.Expect('fm16', 'k:~  - {a: 1}~  - {b: 2} => {"k":[{"a":"1"},{"b":"2"}]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TopLevelForms_1()
    var
        D: List of [Text];
    begin
        D.AddRange('{a: 1}', '[a]', 'a', '', '{~}', 'null', '# c', '---', '---~', '---~q: a', 'q: a~...', '...', '"a"', '''a''', '{a: 1, b: [c]}', '|~  x', '1', '{}', '[]');
        Cells('tl', D, 1, 10);
        Observer.Expect('tl1', '{a: 1} => {"a":"1"}');
        Observer.Expect('tl2', '[a] => FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('tl3', 'a => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('tl4', ' => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl5', '{~} => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl6', 'null => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl7', '# c => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl8', '--- => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl9', '---~ => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl10', '---~q: a => {"q":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TopLevelForms_2()
    var
        D: List of [Text];
    begin
        D.AddRange('{a: 1}', '[a]', 'a', '', '{~}', 'null', '# c', '---', '---~', '---~q: a', 'q: a~...', '...', '"a"', '''a''', '{a: 1, b: [c]}', '|~  x', '1', '{}', '[]');
        Cells('tl', D, 11, 20);
        Observer.Expect('tl11', 'q: a~... => {"q":"a"}');
        Observer.Expect('tl12', '... => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('tl13', '"a" => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('tl14', '''a'' => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('tl15', '{a: 1, b: [c]} => {"a":"1","b":["c"]}');
        Observer.Expect('tl16', '|~  x => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('tl17', '1 => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('tl18', '{} => {}');
        Observer.Expect('tl19', '[] => FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Anchors_1()
    var
        D: List of [Text];
    begin
        D.AddRange('a: &x 1~b: *x', 'a: &x [1, 2]~b: *x', 'a: &x~  c: 1~b: *x', 'b: *x', 'a: &x~  c: 1~b:~  <<: *x~  d: 2', 'a: &x~  c: 1~b: &y~  e: 2~f:~  <<: [*x, *y]',
            'k:~  - &x a~  - *x', '*x : 1', 'a: &x *x', 'a: &x', 'a: &x~b: 2', 'a: &x &y 1', 'a: &x 1~a2: &x 2~b: *x', 'a: &x~  c: 1~b:~  <<: *x~  c: 2',
            'a: &x~  c: 1~b:~  c: 2~  <<: *x', '<<: {a: 1}', 'b: {<<: *x}', 'a: &x {c: 1}~b: {<<: *x, d: 2}');
        Cells('an', D, 1, 10);
        Observer.Expect('an1', 'a: &x 1~b: *x => {"a":"1","b":"1"}');
        Observer.Expect('an2', 'a: &x [1, 2]~b: *x => {"a":["1","2"],"b":["1","2"]}');
        Observer.Expect('an3', 'a: &x~  c: 1~b: *x => {"a":{"c":"1"},"b":{"c":"1"}}');
        Observer.Expect('an4', 'b: *x => FYamlBadFormat');
        Observer.Expect('an5', 'a: &x~  c: 1~b:~  <<: *x~  d: 2 => {"a":{"c":"1"},"b":{"<<":{"c":"1"},"d":"2"}}');
        Observer.Expect('an6', 'a: &x~  c: 1~b: &y~  e: 2~f:~  <<: [*x, *y] => {"a":{"c":"1"},"b":{"e":"2"},"f":{"<<":[{"c":"1"},{"e":"2"}]}}');
        Observer.Expect('an7', 'k:~  - &x a~  - *x => {"k":["a","a"]}');
        Observer.Expect('an8', '*x : 1 => FYamlBadFormat');
        Observer.Expect('an9', 'a: &x *x => FYamlBadFormat');
        Observer.Expect('an10', 'a: &x => {"a":null}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Anchors_2()
    var
        D: List of [Text];
    begin
        D.AddRange('a: &x 1~b: *x', 'a: &x [1, 2]~b: *x', 'a: &x~  c: 1~b: *x', 'b: *x', 'a: &x~  c: 1~b:~  <<: *x~  d: 2', 'a: &x~  c: 1~b: &y~  e: 2~f:~  <<: [*x, *y]',
            'k:~  - &x a~  - *x', '*x : 1', 'a: &x *x', 'a: &x', 'a: &x~b: 2', 'a: &x &y 1', 'a: &x 1~a2: &x 2~b: *x', 'a: &x~  c: 1~b:~  <<: *x~  c: 2',
            'a: &x~  c: 1~b:~  c: 2~  <<: *x', '<<: {a: 1}', 'b: {<<: *x}', 'a: &x {c: 1}~b: {<<: *x, d: 2}');
        Cells('an', D, 11, 20);
        Observer.Expect('an11', 'a: &x~b: 2 => {"a":null,"b":"2"}');
        Observer.Expect('an12', 'a: &x &y 1 => FYamlBadFormat');
        Observer.Expect('an13', 'a: &x 1~a2: &x 2~b: *x => {"a":"1","a2":"2","b":"2"}');
        Observer.Expect('an14', 'a: &x~  c: 1~b:~  <<: *x~  c: 2 => {"a":{"c":"1"},"b":{"<<":{"c":"1"},"c":"2"}}');
        Observer.Expect('an15', 'a: &x~  c: 1~b:~  c: 2~  <<: *x => {"a":{"c":"1"},"b":{"c":"2","<<":{"c":"1"}}}');
        Observer.Expect('an16', '<<: {a: 1} => {"<<":{"a":"1"}}');
        Observer.Expect('an17', 'b: {<<: *x} => FYamlBadFormat');
        Observer.Expect('an18', 'a: &x {c: 1}~b: {<<: *x, d: 2} => {"a":{"c":"1"},"b":{"<<":{"c":"1"},"d":"2"}}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Tags_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!str 123', 'q: !!int "1"', 'q: !!float 1', 'q: !!bool yes', 'q: !!null ""', 'q: !!seq [a]', 'q: !!map {a: 1}', 'q: !custom x',
            'q: !<tag:yaml.org,2002:str> x', 'q: !!binary aGk=', 'q: !!set {a, b}', 'q: !!str', '!!str q: 1', 'q: !', 'q: !!timestamp 2001-12-14',
            'q: !e!foo x', '%TAG !e! tag:x,2000:~---~q: !e!foo x', 'q: !!str |~  x', 'q: !!map~  a: 1', 'q: !!seq~  - a', 'k:~  - !!str 1', 'q: !!int abc', 'q: !!str &x a', 'q: &x !!str a');
        Cells('tg', D, 1, 10);
        Observer.Expect('tg1', 'q: !!str 123 => {"q":"123"}');
        Observer.Expect('tg2', 'q: !!int "1" => {"q":1}');
        Observer.Expect('tg3', 'q: !!float 1 => {"q":1.0}');
        Observer.Expect('tg4', 'q: !!bool yes => {"q":true}');
        Observer.Expect('tg5', 'q: !!null "" => FYamlBadFormat');
        Observer.Expect('tg6', 'q: !!seq [a] => FYamlBadFormat');
        Observer.Expect('tg7', 'q: !!map {a: 1} => {"q":{"a":"1"}}');
        Observer.Expect('tg8', 'q: !custom x => FYamlBadFormat');
        Observer.Expect('tg9', 'q: !<tag:yaml.org,2002:str> x => {"q":"x"}');
        Observer.Expect('tg10', 'q: !!binary aGk= => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Tags_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!str 123', 'q: !!int "1"', 'q: !!float 1', 'q: !!bool yes', 'q: !!null ""', 'q: !!seq [a]', 'q: !!map {a: 1}', 'q: !custom x',
            'q: !<tag:yaml.org,2002:str> x', 'q: !!binary aGk=', 'q: !!set {a, b}', 'q: !!str', '!!str q: 1', 'q: !', 'q: !!timestamp 2001-12-14',
            'q: !e!foo x', '%TAG !e! tag:x,2000:~---~q: !e!foo x', 'q: !!str |~  x', 'q: !!map~  a: 1', 'q: !!seq~  - a', 'k:~  - !!str 1', 'q: !!int abc', 'q: !!str &x a', 'q: &x !!str a');
        Cells('tg', D, 11, 20);
        Observer.Expect('tg11', 'q: !!set {a, b} => FYamlBadFormat');
        Observer.Expect('tg12', 'q: !!str => {"q":null}');
        Observer.Expect('tg13', '!!str q: 1 => {"q":"1"}');
        Observer.Expect('tg14', 'q: ! => FYamlBadFormat');
        Observer.Expect('tg15', 'q: !!timestamp 2001-12-14 => {"q":"2001-12-14T00:00:00"}');
        Observer.Expect('tg16', 'q: !e!foo x => FYamlBadFormat');
        Observer.Expect('tg17', '%TAG !e! tag:x,2000:~---~q: !e!foo x => FYamlBadFormat');
        Observer.Expect('tg18', 'q: !!str |~  x => {"q":"x"}');
        Observer.Expect('tg19', 'q: !!map~  a: 1 => {"q":{"a":"1"}}');
        Observer.Expect('tg20', 'q: !!seq~  - a => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Tags_3()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!str 123', 'q: !!int "1"', 'q: !!float 1', 'q: !!bool yes', 'q: !!null ""', 'q: !!seq [a]', 'q: !!map {a: 1}', 'q: !custom x',
            'q: !<tag:yaml.org,2002:str> x', 'q: !!binary aGk=', 'q: !!set {a, b}', 'q: !!str', '!!str q: 1', 'q: !', 'q: !!timestamp 2001-12-14',
            'q: !e!foo x', '%TAG !e! tag:x,2000:~---~q: !e!foo x', 'q: !!str |~  x', 'q: !!map~  a: 1', 'q: !!seq~  - a', 'k:~  - !!str 1', 'q: !!int abc', 'q: !!str &x a', 'q: &x !!str a');
        Cells('tg', D, 21, 30);
        Observer.Expect('tg21', 'k:~  - !!str 1 => {"k":["1"]}');
        Observer.Expect('tg22', 'q: !!int abc => FYamlBadFormat');
        Observer.Expect('tg23', 'q: !!str &x a => {"q":"a"}');
        Observer.Expect('tg24', 'q: &x !!str a => {"q":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Documents_1()
    var
        D: List of [Text];
    begin
        D.AddRange('---~q: a', 'q: a~---~r: b', '---~q: a~---~r: b', '--- # c~q: a', '--- |~  x', '---~...', '%YAML 1.2~---~q: a', '%YAML 1.1~---~q: a', '%YAML 1.3~---~q: a',
            '%FOO bar~---~q: a', '%YAML 1.2~q: a', '--- q: a', '---q: a', 'q: a~...~', 'q: a~...~---~r: b', 'q: a~... # c', '--- !!map~q: a', '---~---', '--- &x~q: a', 'q: ---', 'q: ...', 'q: a~--- b');
        Cells('dc', D, 1, 10);
        Observer.Expect('dc1', '---~q: a => {"q":"a"}');
        Observer.Expect('dc2', 'q: a~---~r: b => FYamlBadFormat');
        Observer.Expect('dc3', '---~q: a~---~r: b => FYamlBadFormat');
        Observer.Expect('dc4', '--- # c~q: a => {"q":"a"}');
        Observer.Expect('dc5', '--- |~  x => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('dc6', '---~... => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('dc7', '%YAML 1.2~---~q: a => {"q":"a"}');
        Observer.Expect('dc8', '%YAML 1.1~---~q: a => {"q":"a"}');
        Observer.Expect('dc9', '%YAML 1.3~---~q: a => {"q":"a"}');
        Observer.Expect('dc10', '%FOO bar~---~q: a => {"q":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Documents_2()
    var
        D: List of [Text];
    begin
        D.AddRange('---~q: a', 'q: a~---~r: b', '---~q: a~---~r: b', '--- # c~q: a', '--- |~  x', '---~...', '%YAML 1.2~---~q: a', '%YAML 1.1~---~q: a', '%YAML 1.3~---~q: a',
            '%FOO bar~---~q: a', '%YAML 1.2~q: a', '--- q: a', '---q: a', 'q: a~...~', 'q: a~...~---~r: b', 'q: a~... # c', '--- !!map~q: a', '---~---', '--- &x~q: a', 'q: ---', 'q: ...', 'q: a~--- b');
        Cells('dc', D, 11, 20);
        Observer.Expect('dc11', '%YAML 1.2~q: a => FYamlBadFormat');
        Observer.Expect('dc12', '--- q: a => FYamlBadFormat');
        Observer.Expect('dc13', '---q: a => {"---q":"a"}');
        Observer.Expect('dc14', 'q: a~...~ => {"q":"a"}');
        Observer.Expect('dc15', 'q: a~...~---~r: b => FYamlBadFormat');
        Observer.Expect('dc16', 'q: a~... # c => {"q":"a"}');
        Observer.Expect('dc17', '--- !!map~q: a => {"q":"a"}');
        Observer.Expect('dc18', '---~--- => FYamlBadFormat');
        Observer.Expect('dc19', '--- &x~q: a => {"q":"a"}');
        Observer.Expect('dc20', 'q: --- => {"q":"---"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Documents_3()
    var
        D: List of [Text];
    begin
        D.AddRange('---~q: a', 'q: a~---~r: b', '---~q: a~---~r: b', '--- # c~q: a', '--- |~  x', '---~...', '%YAML 1.2~---~q: a', '%YAML 1.1~---~q: a', '%YAML 1.3~---~q: a',
            '%FOO bar~---~q: a', '%YAML 1.2~q: a', '--- q: a', '---q: a', 'q: a~...~', 'q: a~...~---~r: b', 'q: a~... # c', '--- !!map~q: a', '---~---', '--- &x~q: a', 'q: ---', 'q: ...', 'q: a~--- b');
        Cells('dc', D, 21, 30);
        Observer.Expect('dc21', 'q: ... => {"q":"..."}');
        Observer.Expect('dc22', 'q: a~--- b => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_ComplexKeys_1()
    var
        D: List of [Text];
    begin
        D.AddRange('? a~: b', '? [a, b]~: c', '? a~? b', '? |~  x~: 1', '[a, b]: c', '{a: b}: c', '? a', '"a b": 1', '''a'': 1', '? - a~  - b~: c', '1: a', 'null: a', '{~}: a', 'true: a',
            'a b: 1', '"a: b": 1', 'a#b: 1', ': a', '? {~}~: a', '"a": 1~a: 2', '? a~: b~c: d', '? a : b', '"": 1', '''a''''b'': 1', '"a{\}nb": 1', '? a~  b~: c', '*x : 1', '!!str a: 1');
        Cells('ck', D, 1, 10);
        Observer.Expect('ck1', '? a~: b => {"a":"b"}');
        Observer.Expect('ck2', '? [a, b]~: c => {"(Collection)":"c"}');
        Observer.Expect('ck3', '? a~? b => {"a":null,"b":null}');
        Observer.Expect('ck4', '? |~  x~: 1 => {"x\n":"1"}');
        Observer.Expect('ck5', '[a, b]: c => {"(Collection)":"c"}');
        Observer.Expect('ck6', '{a: b}: c => {"(Collection)":"c"}');
        Observer.Expect('ck7', '? a => {"a":null}');
        Observer.Expect('ck8', '"a b": 1 => {"a b":"1"}');
        Observer.Expect('ck9', '''a'': 1 => {"a":"1"}');
        Observer.Expect('ck10', '? - a~  - b~: c => {"(Collection)":"c"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_ComplexKeys_2()
    var
        D: List of [Text];
    begin
        D.AddRange('? a~: b', '? [a, b]~: c', '? a~? b', '? |~  x~: 1', '[a, b]: c', '{a: b}: c', '? a', '"a b": 1', '''a'': 1', '? - a~  - b~: c', '1: a', 'null: a', '{~}: a', 'true: a',
            'a b: 1', '"a: b": 1', 'a#b: 1', ': a', '? {~}~: a', '"a": 1~a: 2', '? a~: b~c: d', '? a : b', '"": 1', '''a''''b'': 1', '"a{\}nb": 1', '? a~  b~: c', '*x : 1', '!!str a: 1');
        Cells('ck', D, 11, 20);
        Observer.Expect('ck11', '1: a => {"1":"a"}');
        Observer.Expect('ck12', 'null: a => {"null":"a"}');
        Observer.Expect('ck13', '{~}: a => {"~":"a"}');
        Observer.Expect('ck14', 'true: a => {"true":"a"}');
        Observer.Expect('ck15', 'a b: 1 => {"a b":"1"}');
        Observer.Expect('ck16', '"a: b": 1 => {"a: b":"1"}');
        Observer.Expect('ck17', 'a#b: 1 => {"a#b":"1"}');
        Observer.Expect('ck18', ': a => FYamlBadFormat');
        Observer.Expect('ck19', '? {~}~: a => {"~":"a"}');
        Observer.Expect('ck20', '"a": 1~a: 2 => {"a":"2"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_ComplexKeys_3()
    var
        D: List of [Text];
    begin
        D.AddRange('? a~: b', '? [a, b]~: c', '? a~? b', '? |~  x~: 1', '[a, b]: c', '{a: b}: c', '? a', '"a b": 1', '''a'': 1', '? - a~  - b~: c', '1: a', 'null: a', '{~}: a', 'true: a',
            'a b: 1', '"a: b": 1', 'a#b: 1', ': a', '? {~}~: a', '"a": 1~a: 2', '? a~: b~c: d', '? a : b', '"": 1', '''a''''b'': 1', '"a{\}nb": 1', '? a~  b~: c', '*x : 1', '!!str a: 1');
        Cells('ck', D, 21, 30);
        Observer.Expect('ck21', '? a~: b~c: d => {"a":"b","c":"d"}');
        Observer.Expect('ck22', '? a : b => {"(Collection)":null}');
        Observer.Expect('ck23', '"": 1 => {"":"1"}');
        Observer.Expect('ck24', '''a''''b'': 1 => {"a''b":"1"}');
        Observer.Expect('ck25', '"a{\}nb": 1 => {"a\nb":"1"}');
        Observer.Expect('ck26', '? a~  b~: c => {"a b":"c"}');
        Observer.Expect('ck27', '*x : 1 => FYamlBadFormat');
        Observer.Expect('ck28', '!!str a: 1 => {"a":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_MultilineScalars_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: a~  b~  c', 'q: a~~  b', 'q: a~  b~n: 1', 'k:~  - a~    b~  - c', 'q: ''a~  b''', 'q: ''a~~  b''', 'q: ''a ''''b''''''', 'q: ''''', 'q: ""', 'q: "a~  b"',
            'q: "a{\}~  b"', 'q: "a {\}~   b"', 'q: "a~~b"', 'q: "a  ~  b"', 'q: ''a  ~  b''', 'q: a  b', 'q: a   ', 'q: "a', 'q: ''a', 'q: "a" b', 'q: ''a'' b', 'k:~  - "a~    b"~  - c',
            'q:~  a~  b', 'q:~  "a"', 'q:~  ''a''', 'q:~  a~n: 1', 'q:~~  a');
        Cells('ml', D, 1, 10);
        Observer.Expect('ml1', 'q: a~  b~  c => {"q":"a b c"}');
        Observer.Expect('ml2', 'q: a~~  b => {"q":"a\nb"}');
        Observer.Expect('ml3', 'q: a~  b~n: 1 => {"q":"a b","n":"1"}');
        Observer.Expect('ml4', 'k:~  - a~    b~  - c => {"k":["a b","c"]}');
        Observer.Expect('ml5', 'q: ''a~  b'' => {"q":"a b"}');
        Observer.Expect('ml6', 'q: ''a~~  b'' => {"q":"a\nb"}');
        Observer.Expect('ml7', 'q: ''a ''''b'''''' => {"q":"a ''b''"}');
        Observer.Expect('ml8', 'q: '''' => {"q":""}');
        Observer.Expect('ml9', 'q: "" => {"q":""}');
        Observer.Expect('ml10', 'q: "a~  b" => {"q":"a b"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_MultilineScalars_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: a~  b~  c', 'q: a~~  b', 'q: a~  b~n: 1', 'k:~  - a~    b~  - c', 'q: ''a~  b''', 'q: ''a~~  b''', 'q: ''a ''''b''''''', 'q: ''''', 'q: ""', 'q: "a~  b"',
            'q: "a{\}~  b"', 'q: "a {\}~   b"', 'q: "a~~b"', 'q: "a  ~  b"', 'q: ''a  ~  b''', 'q: a  b', 'q: a   ', 'q: "a', 'q: ''a', 'q: "a" b', 'q: ''a'' b', 'k:~  - "a~    b"~  - c',
            'q:~  a~  b', 'q:~  "a"', 'q:~  ''a''', 'q:~  a~n: 1', 'q:~~  a');
        Cells('ml', D, 11, 20);
        Observer.Expect('ml11', 'q: "a{\}~  b" => {"q":"ab"}');
        Observer.Expect('ml12', 'q: "a {\}~   b" => {"q":"a b"}');
        Observer.Expect('ml13', 'q: "a~~b" => FYamlBadFormat');
        Observer.Expect('ml14', 'q: "a  ~  b" => {"q":"a b"}');
        Observer.Expect('ml15', 'q: ''a  ~  b'' => {"q":"a b"}');
        Observer.Expect('ml16', 'q: a  b => {"q":"a  b"}');
        Observer.Expect('ml17', 'q: a    => {"q":"a"}');
        Observer.Expect('ml18', 'q: "a => FYamlBadFormat');
        Observer.Expect('ml19', 'q: ''a => FYamlBadFormat');
        Observer.Expect('ml20', 'q: "a" b => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_MultilineScalars_3()
    var
        D: List of [Text];
    begin
        D.AddRange('q: a~  b~  c', 'q: a~~  b', 'q: a~  b~n: 1', 'k:~  - a~    b~  - c', 'q: ''a~  b''', 'q: ''a~~  b''', 'q: ''a ''''b''''''', 'q: ''''', 'q: ""', 'q: "a~  b"',
            'q: "a{\}~  b"', 'q: "a {\}~   b"', 'q: "a~~b"', 'q: "a  ~  b"', 'q: ''a  ~  b''', 'q: a  b', 'q: a   ', 'q: "a', 'q: ''a', 'q: "a" b', 'q: ''a'' b', 'k:~  - "a~    b"~  - c',
            'q:~  a~  b', 'q:~  "a"', 'q:~  ''a''', 'q:~  a~n: 1', 'q:~~  a');
        Cells('ml', D, 21, 30);
        Observer.Expect('ml21', 'q: ''a'' b => FYamlBadFormat');
        Observer.Expect('ml22', 'k:~  - "a~    b"~  - c => {"k":["a b","c"]}');
        Observer.Expect('ml23', 'q:~  a~  b => {"q":"a b"}');
        Observer.Expect('ml24', 'q:~  "a" => {"q":"a"}');
        Observer.Expect('ml25', 'q:~  ''a'' => {"q":"a"}');
        Observer.Expect('ml26', 'q:~  a~n: 1 => {"q":"a","n":"1"}');
        Observer.Expect('ml27', 'q:~~  a => {"q":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarsMore_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: |+~  x~~~n: 1', 'q: >+~  x~~~n: 1', 'q: >-~  a~~  b~n: 1', 'q: >~  a~    b~  c~n: 1', 'q: |~n: 1', 'q: >~n: 1', 'q: |~~~n: 1', 'q: |~  - x', 'q: |~  # c~  x',
            'q: |  # c~  x', 'q: | x~  y', 'q: >-~~  x', 'q: |~  a{T}b', 'q: |~    x~  y', 'q: |~  x~ y', 'q: |~  x{S}{S}~  y', 'q: |{S}{S}~  x', 'q: |-~  x~', 'q: |+~  x', 'q: |q~  x',
            'q: |~', 'q: |', 'q: >~  a~  b~~  c', 'q: >~  a~   b~  c', 'q: |~{T}x');
        Cells('bl', D, 1, 10);
        Observer.Expect('bl1', 'q: |+~  x~~~n: 1 => {"q":"x\n\n\n","n":"1"}');
        Observer.Expect('bl2', 'q: >+~  x~~~n: 1 => {"q":"x\n\n\n","n":"1"}');
        Observer.Expect('bl3', 'q: >-~  a~~  b~n: 1 => {"q":"a\nb","n":"1"}');
        Observer.Expect('bl4', 'q: >~  a~    b~  c~n: 1 => {"q":"a\n  b\nc\n","n":"1"}');
        Observer.Expect('bl5', 'q: |~n: 1 => {"q":"","n":"1"}');
        Observer.Expect('bl6', 'q: >~n: 1 => {"q":"","n":"1"}');
        Observer.Expect('bl7', 'q: |~~~n: 1 => {"q":"","n":"1"}');
        Observer.Expect('bl8', 'q: |~  - x => {"q":"- x"}');
        Observer.Expect('bl9', 'q: |~  # c~  x => {"q":"# c\nx"}');
        Observer.Expect('bl10', 'q: |  # c~  x => {"q":"x"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarsMore_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: |+~  x~~~n: 1', 'q: >+~  x~~~n: 1', 'q: >-~  a~~  b~n: 1', 'q: >~  a~    b~  c~n: 1', 'q: |~n: 1', 'q: >~n: 1', 'q: |~~~n: 1', 'q: |~  - x', 'q: |~  # c~  x',
            'q: |  # c~  x', 'q: | x~  y', 'q: >-~~  x', 'q: |~  a{T}b', 'q: |~    x~  y', 'q: |~  x~ y', 'q: |~  x{S}{S}~  y', 'q: |{S}{S}~  x', 'q: |-~  x~', 'q: |+~  x', 'q: |q~  x',
            'q: |~', 'q: |', 'q: >~  a~  b~~  c', 'q: >~  a~   b~  c', 'q: |~{T}x');
        Cells('bl', D, 11, 20);
        Observer.Expect('bl11', 'q: | x~  y => FYamlBadFormat');
        Observer.Expect('bl12', 'q: >-~~  x => {"q":"\nx"}');
        Observer.Expect('bl13', 'q: |~  a{T}b => {"q":"a\tb"}');
        Observer.Expect('bl14', 'q: |~    x~  y => FYamlBadFormat');
        Observer.Expect('bl15', 'q: |~  x~ y => FYamlBadFormat');
        Observer.Expect('bl16', 'q: |~  x{S}{S}~  y => {"q":"x  \ny"}');
        Observer.Expect('bl17', 'q: |{S}{S}~  x => {"q":"x"}');
        Observer.Expect('bl18', 'q: |-~  x~ => {"q":"x"}');
        Observer.Expect('bl19', 'q: |+~  x => {"q":"x"}');
        Observer.Expect('bl20', 'q: |q~  x => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarsMore_3()
    var
        D: List of [Text];
    begin
        D.AddRange('q: |+~  x~~~n: 1', 'q: >+~  x~~~n: 1', 'q: >-~  a~~  b~n: 1', 'q: >~  a~    b~  c~n: 1', 'q: |~n: 1', 'q: >~n: 1', 'q: |~~~n: 1', 'q: |~  - x', 'q: |~  # c~  x',
            'q: |  # c~  x', 'q: | x~  y', 'q: >-~~  x', 'q: |~  a{T}b', 'q: |~    x~  y', 'q: |~  x~ y', 'q: |~  x{S}{S}~  y', 'q: |{S}{S}~  x', 'q: |-~  x~', 'q: |+~  x', 'q: |q~  x',
            'q: |~', 'q: |', 'q: >~  a~  b~~  c', 'q: >~  a~   b~  c', 'q: |~{T}x');
        Cells('bl', D, 21, 30);
        Observer.Expect('bl21', 'q: |~ => {"q":""}');
        Observer.Expect('bl22', 'q: | => {"q":""}');
        Observer.Expect('bl23', 'q: >~  a~  b~~  c => {"q":"a b\nc"}');
        Observer.Expect('bl24', 'q: >~  a~   b~  c => {"q":"a\n b\nc"}');
        Observer.Expect('bl25', 'q: |~{T}x => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Comments_1()
    var
        D: List of [Text];
    begin
        D.AddRange('# c~q: a', 'q: a # c', 'q: # c~  a', 'q:   # c~  r: 1', 'k:~  - a # c~  # d~  - b', 'q: a #c', 'q: a# c', 'q: a  # c', '# c', 'q: a~# c', 'q: a~# c~n: 1',
            'q: a~  # c~n: 1', 'o:~  # c~  q: a', 'o: # c~  q: a', 'k: # c~  - a', 'q: "a" # c', 'q: ''a'' # c', 'q: [a] # c', 'q: {a: 1} # c', 'q: |~  x~# c~n: 1', 'q: |~  x~  # c', 'q: a{T}# c',
            'q: a{T}b', 'q:{T}a', 'k:~  -{T}a', '{T}q: a', 'q: a{T}', '# c{T}d~q: a', '  # c~q: a', 'q: a~ # c~n: 1', '#', '#~q: a');
        Cells('cm', D, 1, 10);
        Observer.Expect('cm1', '# c~q: a => {"q":"a"}');
        Observer.Expect('cm2', 'q: a # c => {"q":"a"}');
        Observer.Expect('cm3', 'q: # c~  a => {"q":"a"}');
        Observer.Expect('cm4', 'q:   # c~  r: 1 => {"q":{"r":"1"}}');
        Observer.Expect('cm5', 'k:~  - a # c~  # d~  - b => {"k":["a","b"]}');
        Observer.Expect('cm6', 'q: a #c => {"q":"a"}');
        Observer.Expect('cm7', 'q: a# c => {"q":"a# c"}');
        Observer.Expect('cm8', 'q: a  # c => {"q":"a"}');
        Observer.Expect('cm9', '# c => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('cm10', 'q: a~# c => {"q":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Comments_2()
    var
        D: List of [Text];
    begin
        D.AddRange('# c~q: a', 'q: a # c', 'q: # c~  a', 'q:   # c~  r: 1', 'k:~  - a # c~  # d~  - b', 'q: a #c', 'q: a# c', 'q: a  # c', '# c', 'q: a~# c', 'q: a~# c~n: 1',
            'q: a~  # c~n: 1', 'o:~  # c~  q: a', 'o: # c~  q: a', 'k: # c~  - a', 'q: "a" # c', 'q: ''a'' # c', 'q: [a] # c', 'q: {a: 1} # c', 'q: |~  x~# c~n: 1', 'q: |~  x~  # c', 'q: a{T}# c',
            'q: a{T}b', 'q:{T}a', 'k:~  -{T}a', '{T}q: a', 'q: a{T}', '# c{T}d~q: a', '  # c~q: a', 'q: a~ # c~n: 1', '#', '#~q: a');
        Cells('cm', D, 11, 20);
        Observer.Expect('cm11', 'q: a~# c~n: 1 => {"q":"a","n":"1"}');
        Observer.Expect('cm12', 'q: a~  # c~n: 1 => {"q":"a","n":"1"}');
        Observer.Expect('cm13', 'o:~  # c~  q: a => {"o":{"q":"a"}}');
        Observer.Expect('cm14', 'o: # c~  q: a => {"o":{"q":"a"}}');
        Observer.Expect('cm15', 'k: # c~  - a => {"k":["a"]}');
        Observer.Expect('cm16', 'q: "a" # c => {"q":"a"}');
        Observer.Expect('cm17', 'q: ''a'' # c => {"q":"a"}');
        Observer.Expect('cm18', 'q: [a] # c => {"q":["a"]}');
        Observer.Expect('cm19', 'q: {a: 1} # c => {"q":{"a":"1"}}');
        Observer.Expect('cm20', 'q: |~  x~# c~n: 1 => {"q":"x\n","n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Comments_3()
    var
        D: List of [Text];
    begin
        D.AddRange('# c~q: a', 'q: a # c', 'q: # c~  a', 'q:   # c~  r: 1', 'k:~  - a # c~  # d~  - b', 'q: a #c', 'q: a# c', 'q: a  # c', '# c', 'q: a~# c', 'q: a~# c~n: 1',
            'q: a~  # c~n: 1', 'o:~  # c~  q: a', 'o: # c~  q: a', 'k: # c~  - a', 'q: "a" # c', 'q: ''a'' # c', 'q: [a] # c', 'q: {a: 1} # c', 'q: |~  x~# c~n: 1', 'q: |~  x~  # c', 'q: a{T}# c',
            'q: a{T}b', 'q:{T}a', 'k:~  -{T}a', '{T}q: a', 'q: a{T}', '# c{T}d~q: a', '  # c~q: a', 'q: a~ # c~n: 1', '#', '#~q: a');
        Cells('cm', D, 21, 30);
        Observer.Expect('cm21', 'q: |~  x~  # c => {"q":"x\n# c"}');
        Observer.Expect('cm22', 'q: a{T}# c => {"q":"a"}');
        Observer.Expect('cm23', 'q: a{T}b => {"q":"a\tb"}');
        Observer.Expect('cm24', 'q:{T}a => {"q":"a"}');
        Observer.Expect('cm25', 'k:~  -{T}a => {"k":["a"]}');
        Observer.Expect('cm26', '{T}q: a => {"q":"a"}');
        Observer.Expect('cm27', 'q: a{T} => {"q":"a"}');
        Observer.Expect('cm28', '# c{T}d~q: a => {"q":"a"}');
        Observer.Expect('cm29', '  # c~q: a => {"q":"a"}');
        Observer.Expect('cm30', 'q: a~ # c~n: 1 => {"q":"a","n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Comments_4()
    var
        D: List of [Text];
    begin
        D.AddRange('# c~q: a', 'q: a # c', 'q: # c~  a', 'q:   # c~  r: 1', 'k:~  - a # c~  # d~  - b', 'q: a #c', 'q: a# c', 'q: a  # c', '# c', 'q: a~# c', 'q: a~# c~n: 1',
            'q: a~  # c~n: 1', 'o:~  # c~  q: a', 'o: # c~  q: a', 'k: # c~  - a', 'q: "a" # c', 'q: ''a'' # c', 'q: [a] # c', 'q: {a: 1} # c', 'q: |~  x~# c~n: 1', 'q: |~  x~  # c', 'q: a{T}# c',
            'q: a{T}b', 'q:{T}a', 'k:~  -{T}a', '{T}q: a', 'q: a{T}', '# c{T}d~q: a', '  # c~q: a', 'q: a~ # c~n: 1', '#', '#~q: a');
        Cells('cm', D, 31, 40);
        Observer.Expect('cm31', '# => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('cm32', '#~q: a => {"q":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_NullAndEmpty_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q:', 'q: {~}', 'q: null', 'q: Null', 'q: NULL', 'q: nUll', 'q: ""', 'q: ''''', 'q: !!null', 'q:~n: 1', 'k:~  - {~}~  - null~  -~  - ''''', 'q: nul', '{~}: 1', 'q: ~x', 'q: ~ ',
            'q:   ', 'q: ~~', 'k:', 'k:~  -', 'k:~  - ', 'o:~  q:', 'o:~  q:~n: 1', 'q: [{~}, null, ]', 'q: {a: {~}, b: null, c: }');
        Cells('nl', D, 1, 10);
        Observer.Expect('nl1', 'q: => {"q":null}');
        Observer.Expect('nl2', 'q: {~} => {"q":null}');
        Observer.Expect('nl3', 'q: null => {"q":null}');
        Observer.Expect('nl4', 'q: Null => {"q":null}');
        Observer.Expect('nl5', 'q: NULL => {"q":null}');
        Observer.Expect('nl6', 'q: nUll => {"q":"nUll"}');
        Observer.Expect('nl7', 'q: "" => {"q":""}');
        Observer.Expect('nl8', 'q: '''' => {"q":""}');
        Observer.Expect('nl9', 'q: !!null => FYamlBadFormat');
        Observer.Expect('nl10', 'q:~n: 1 => {"q":null,"n":"1"}');
        Observer.Verify();
    end;

    local procedure ScalarCells(Prefix: Text; Items: List of [Text])
    var
        S: Text;
    begin
        foreach S in Items do
            Observer.Observe(Prefix + '[' + S + ']', Both(Doc('q: ' + S, ''), '', ''));
    end;

    [Test]
    procedure ReadFromYaml_NullAndEmpty_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q:', 'q: {~}', 'q: null', 'q: Null', 'q: NULL', 'q: nUll', 'q: ""', 'q: ''''', 'q: !!null', 'q:~n: 1', 'k:~  - {~}~  - null~  -~  - ''''', 'q: nul', '{~}: 1', 'q: ~x', 'q: ~ ',
            'q:   ', 'q: ~~', 'k:', 'k:~  -', 'k:~  - ', 'o:~  q:', 'o:~  q:~n: 1', 'q: [{~}, null, ]', 'q: {a: {~}, b: null, c: }');
        Cells('nl', D, 11, 20);
        Observer.Expect('nl11', 'k:~  - {~}~  - null~  -~  - '''' => {"k":[null,null,null,""]}');
        Observer.Expect('nl12', 'q: nul => {"q":"nul"}');
        Observer.Expect('nl13', '{~}: 1 => {"~":"1"}');
        Observer.Expect('nl14', 'q: ~x => FYamlBadFormat');
        Observer.Expect('nl15', 'q: ~  => {"q":null}');
        Observer.Expect('nl16', 'q:    => {"q":null}');
        Observer.Expect('nl17', 'q: ~~ => {"q":null}');
        Observer.Expect('nl18', 'k: => {"k":null}');
        Observer.Expect('nl19', 'k:~  - => {"k":[null]}');
        Observer.Expect('nl20', 'k:~  -  => {"k":[null]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_NullAndEmpty_3()
    var
        D: List of [Text];
    begin
        D.AddRange('q:', 'q: {~}', 'q: null', 'q: Null', 'q: NULL', 'q: nUll', 'q: ""', 'q: ''''', 'q: !!null', 'q:~n: 1', 'k:~  - {~}~  - null~  -~  - ''''', 'q: nul', '{~}: 1', 'q: ~x', 'q: ~ ',
            'q:   ', 'q: ~~', 'k:', 'k:~  -', 'k:~  - ', 'o:~  q:', 'o:~  q:~n: 1', 'q: [{~}, null, ]', 'q: {a: {~}, b: null, c: }');
        Cells('nl', D, 21, 30);
        Observer.Expect('nl21', 'o:~  q: => {"o":{"q":null}}');
        Observer.Expect('nl22', 'o:~  q:~n: 1 => {"o":{"q":null},"n":"1"}');
        Observer.Expect('nl23', 'q: [{~}, null, ] => {"q":[null,null]}');
        Observer.Expect('nl24', 'q: {a: {~}, b: null, c: } => {"q":{"a":null,"b":null,"c":null}}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Booleans()
    var
        L: List of [Text];
    begin
        L.AddRange('yes', 'no', 'Yes', 'No', 'YES', 'NO', 'y', 'n', 'Y', 'N', 'on', 'off', 'On', 'Off', 'ON', 'OFF', 'true', 'false', 'True', 'False', 'TRUE', 'FALSE', 'tRue', 'fALSE', 't', 'f');
        ScalarCells('b', L);
        Observer.Expect('b[yes]', '{"q":"yes"}');
        Observer.Expect('b[no]', '{"q":"no"}');
        Observer.Expect('b[Yes]', '{"q":"Yes"}');
        Observer.Expect('b[No]', '{"q":"No"}');
        Observer.Expect('b[YES]', '{"q":"YES"}');
        Observer.Expect('b[NO]', '{"q":"NO"}');
        Observer.Expect('b[y]', '{"q":"y"}');
        Observer.Expect('b[n]', '{"q":"n"}');
        Observer.Expect('b[Y]', '{"q":"Y"}');
        Observer.Expect('b[N]', '{"q":"N"}');
        Observer.Expect('b[on]', '{"q":"on"}');
        Observer.Expect('b[off]', '{"q":"off"}');
        Observer.Expect('b[On]', '{"q":"On"}');
        Observer.Expect('b[Off]', '{"q":"Off"}');
        Observer.Expect('b[ON]', '{"q":"ON"}');
        Observer.Expect('b[OFF]', '{"q":"OFF"}');
        Observer.Expect('b[true]', '{"q":"true"}');
        Observer.Expect('b[false]', '{"q":"false"}');
        Observer.Expect('b[True]', '{"q":"True"}');
        Observer.Expect('b[False]', '{"q":"False"}');
        Observer.Expect('b[TRUE]', '{"q":"TRUE"}');
        Observer.Expect('b[FALSE]', '{"q":"FALSE"}');
        Observer.Expect('b[tRue]', '{"q":"tRue"}');
        Observer.Expect('b[fALSE]', '{"q":"fALSE"}');
        Observer.Expect('b[t]', '{"q":"t"}');
        Observer.Expect('b[f]', '{"q":"f"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Integers()
    var
        L: List of [Text];
    begin
        L.AddRange('0', '1', '-1', '+1', '007', '0x1F', '0X1f', '0o17', '0b101', '017', '1_000', '1,000', '0x', '-0', '+0', '00', '12345678901234567890', '-9223372036854775808', '9223372036854775808',
            '0xFFFFFFFFFFFFFFFF', '0o', '08', '1 000');
        ScalarCells('i', L);
        Observer.Expect('i[0]', '{"q":"0"}');
        Observer.Expect('i[1]', '{"q":"1"}');
        Observer.Expect('i[-1]', '{"q":"-1"}');
        Observer.Expect('i[+1]', '{"q":"+1"}');
        Observer.Expect('i[007]', '{"q":"007"}');
        Observer.Expect('i[0x1F]', '{"q":"0x1F"}');
        Observer.Expect('i[0X1f]', '{"q":"0X1f"}');
        Observer.Expect('i[0o17]', '{"q":"0o17"}');
        Observer.Expect('i[0b101]', '{"q":"0b101"}');
        Observer.Expect('i[017]', '{"q":"017"}');
        Observer.Expect('i[1_000]', '{"q":"1_000"}');
        Observer.Expect('i[1,000]', '{"q":"1,000"}');
        Observer.Expect('i[0x]', '{"q":"0x"}');
        Observer.Expect('i[-0]', '{"q":"-0"}');
        Observer.Expect('i[+0]', '{"q":"+0"}');
        Observer.Expect('i[00]', '{"q":"00"}');
        Observer.Expect('i[12345678901234567890]', '{"q":"12345678901234567890"}');
        Observer.Expect('i[-9223372036854775808]', '{"q":"-9223372036854775808"}');
        Observer.Expect('i[9223372036854775808]', '{"q":"9223372036854775808"}');
        Observer.Expect('i[0xFFFFFFFFFFFFFFFF]', '{"q":"0xFFFFFFFFFFFFFFFF"}');
        Observer.Expect('i[0o]', '{"q":"0o"}');
        Observer.Expect('i[08]', '{"q":"08"}');
        Observer.Expect('i[1 000]', '{"q":"1 000"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Floats()
    var
        L: List of [Text];
    begin
        L.AddRange('1.5', '.5', '5.', '1e3', '1E3', '1.5e+3', '-1.5E-3', '.inf', '-.inf', '+.inf', '.Inf', '.INF', '.NaN', '.nan', '.NAN', 'inf', 'nan', 'NaN', '1e', '12:30:45', '1:30', '2001-12-14',
            '2001-12-14t21:59:43.10-05:00', '2001-12-14 21:59:43.10 -5', '0.1.2', '1.0', '-0.0', '1e400', '3.14159265358979323846264338327950288');
        ScalarCells('f', L);
        Observer.Expect('f[1.5]', '{"q":"1.5"}');
        Observer.Expect('f[.5]', '{"q":".5"}');
        Observer.Expect('f[5.]', '{"q":"5."}');
        Observer.Expect('f[1e3]', '{"q":"1e3"}');
        Observer.Expect('f[1E3]', '{"q":"1E3"}');
        Observer.Expect('f[1.5e+3]', '{"q":"1.5e+3"}');
        Observer.Expect('f[-1.5E-3]', '{"q":"-1.5E-3"}');
        Observer.Expect('f[.inf]', '{"q":".inf"}');
        Observer.Expect('f[-.inf]', '{"q":"-.inf"}');
        Observer.Expect('f[+.inf]', '{"q":"+.inf"}');
        Observer.Expect('f[.Inf]', '{"q":".Inf"}');
        Observer.Expect('f[.INF]', '{"q":".INF"}');
        Observer.Expect('f[.NaN]', '{"q":".NaN"}');
        Observer.Expect('f[.nan]', '{"q":".nan"}');
        Observer.Expect('f[.NAN]', '{"q":".NAN"}');
        Observer.Expect('f[inf]', '{"q":"inf"}');
        Observer.Expect('f[nan]', '{"q":"nan"}');
        Observer.Expect('f[NaN]', '{"q":"NaN"}');
        Observer.Expect('f[1e]', '{"q":"1e"}');
        Observer.Expect('f[12:30:45]', '{"q":"12:30:45"}');
        Observer.Expect('f[1:30]', '{"q":"1:30"}');
        Observer.Expect('f[2001-12-14]', '{"q":"2001-12-14"}');
        Observer.Expect('f[2001-12-14t21:59:43.10-05:00]', '{"q":"2001-12-14t21:59:43.10-05:00"}');
        Observer.Expect('f[2001-12-14 21:59:43.10 -5]', '{"q":"2001-12-14 21:59:43.10 -5"}');
        Observer.Expect('f[0.1.2]', '{"q":"0.1.2"}');
        Observer.Expect('f[1.0]', '{"q":"1.0"}');
        Observer.Expect('f[-0.0]', '{"q":"-0.0"}');
        Observer.Expect('f[1e400]', '{"q":"1e400"}');
        Observer.Expect('f[3.14159265358979323846264338327950288]', '{"q":"3.14159265358979323846264338327950288"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BomTabsSpaces_1()
    var
        D: List of [Text];
    begin
        D.AddRange('{B}q: a', 'q: a{B}', 'q: {B}a', '{B}---~q: a', 'q:{T}a', 'q: a{T}', 'q: a{T}b', 'k:~{T}- a', 'k:~  -{T}a', 'k:~  -{T}{T}a', 'o:~{T}q: a', 'q: a   ', 'q:   a', 'q:   ~n: 1',
            '---   ~q: a', 'q: |   ~  x', 'q: |~  x   ~  y   ', 'q: a~~~~', '~~~q: a', '   ', '{T}', 'q: a{0}b', '{0}', 'q: a{S}{S}{S}~n: 1{S}', 'q: a~{S}', 'q: a~{T}');
        Cells('bt', D, 1, 10);
        Observer.Expect('bt1', '{B}q: a => T {"<U+FEFF>q":"a"} | S {"q":"a"}');
        Observer.Expect('bt2', 'q: a{B} => {"q":"a<U+FEFF>"}');
        Observer.Expect('bt3', 'q: {B}a => {"q":"<U+FEFF>a"}');
        Observer.Expect('bt4', '{B}---~q: a => T FYamlBadFormat | S {"q":"a"}');
        Observer.Expect('bt5', 'q:{T}a => {"q":"a"}');
        Observer.Expect('bt6', 'q: a{T} => {"q":"a"}');
        Observer.Expect('bt7', 'q: a{T}b => {"q":"a\tb"}');
        Observer.Expect('bt8', 'k:~{T}- a => FYamlBadFormat');
        Observer.Expect('bt9', 'k:~  -{T}a => {"k":["a"]}');
        Observer.Expect('bt10', 'k:~  -{T}{T}a => {"k":["a"]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BomTabsSpaces_2()
    var
        D: List of [Text];
    begin
        D.AddRange('{B}q: a', 'q: a{B}', 'q: {B}a', '{B}---~q: a', 'q:{T}a', 'q: a{T}', 'q: a{T}b', 'k:~{T}- a', 'k:~  -{T}a', 'k:~  -{T}{T}a', 'o:~{T}q: a', 'q: a   ', 'q:   a', 'q:   ~n: 1',
            '---   ~q: a', 'q: |   ~  x', 'q: |~  x   ~  y   ', 'q: a~~~~', '~~~q: a', '   ', '{T}', 'q: a{0}b', '{0}', 'q: a{S}{S}{S}~n: 1{S}', 'q: a~{S}', 'q: a~{T}');
        Cells('bt', D, 11, 20);
        Observer.Expect('bt11', 'o:~{T}q: a => FYamlBadFormat');
        Observer.Expect('bt12', 'q: a    => {"q":"a"}');
        Observer.Expect('bt13', 'q:   a => {"q":"a"}');
        Observer.Expect('bt14', 'q:   ~n: 1 => {"q":null,"n":"1"}');
        Observer.Expect('bt15', '---   ~q: a => {"q":"a"}');
        Observer.Expect('bt16', 'q: |   ~  x => {"q":"x"}');
        Observer.Expect('bt17', 'q: |~  x   ~  y    => {"q":"x   \ny   "}');
        Observer.Expect('bt18', 'q: a~~~~ => {"q":"a"}');
        Observer.Expect('bt19', '~~~q: a => {"q":"a"}');
        Observer.Expect('bt20', '    => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BomTabsSpaces_3()
    var
        D: List of [Text];
    begin
        D.AddRange('{B}q: a', 'q: a{B}', 'q: {B}a', '{B}---~q: a', 'q:{T}a', 'q: a{T}', 'q: a{T}b', 'k:~{T}- a', 'k:~  -{T}a', 'k:~  -{T}{T}a', 'o:~{T}q: a', 'q: a   ', 'q:   a', 'q:   ~n: 1',
            '---   ~q: a', 'q: |   ~  x', 'q: |~  x   ~  y   ', 'q: a~~~~', '~~~q: a', '   ', '{T}', 'q: a{0}b', '{0}', 'q: a{S}{S}{S}~n: 1{S}', 'q: a~{S}', 'q: a~{T}');
        Cells('bt', D, 21, 30);
        Observer.Expect('bt21', '{T} => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('bt22', 'q: a{0}b => {"q":"ab"}');
        Observer.Expect('bt23', '{0} => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('bt24', 'q: a{S}{S}{S}~n: 1{S} => {"q":"a","n":"1"}');
        Observer.Expect('bt25', 'q: a~{S} => {"q":"a"}');
        Observer.Expect('bt26', 'q: a~{T} => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DuplicateKeys_1()
    var
        D: List of [Text];
    begin
        D.AddRange('a: 1~a: 2', 'o:~  a: 1~  a: 2', 'q: {a: 1, a: 2}', 'a: 1~"a": 2', 'a: 1~''a'': 2', 'k:~  - a: 1~    a: 2', 'a: 1~b: 2~a: 3', 'a: 1~A: 2', 'a: {~}~a: 1', 'a:~a: 1',
            'a: &x 1~a: *x', '<<: {a: 1}~<<: {b: 2}', '1: a~"1": b', 'a: 1~a b: 2~a: 3');
        Cells('dk', D, 1, 10);
        Observer.Expect('dk1', 'a: 1~a: 2 => {"a":"2"}');
        Observer.Expect('dk2', 'o:~  a: 1~  a: 2 => {"o":{"a":"2"}}');
        Observer.Expect('dk3', 'q: {a: 1, a: 2} => {"q":{"a":"2"}}');
        Observer.Expect('dk4', 'a: 1~"a": 2 => {"a":"2"}');
        Observer.Expect('dk5', 'a: 1~''a'': 2 => {"a":"2"}');
        Observer.Expect('dk6', 'k:~  - a: 1~    a: 2 => {"k":[{"a":"2"}]}');
        Observer.Expect('dk7', 'a: 1~b: 2~a: 3 => {"a":"3","b":"2"}');
        Observer.Expect('dk8', 'a: 1~A: 2 => {"a":"1","A":"2"}');
        Observer.Expect('dk9', 'a: {~}~a: 1 => {"a":"1"}');
        Observer.Expect('dk10', 'a:~a: 1 => {"a":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DuplicateKeys_2()
    var
        D: List of [Text];
    begin
        D.AddRange('a: 1~a: 2', 'o:~  a: 1~  a: 2', 'q: {a: 1, a: 2}', 'a: 1~"a": 2', 'a: 1~''a'': 2', 'k:~  - a: 1~    a: 2', 'a: 1~b: 2~a: 3', 'a: 1~A: 2', 'a: {~}~a: 1', 'a:~a: 1',
            'a: &x 1~a: *x', '<<: {a: 1}~<<: {b: 2}', '1: a~"1": b', 'a: 1~a b: 2~a: 3');
        Cells('dk', D, 11, 20);
        Observer.Expect('dk11', 'a: &x 1~a: *x => {"a":"1"}');
        Observer.Expect('dk12', '<<: {a: 1}~<<: {b: 2} => {"<<":{"b":"2"}}');
        Observer.Expect('dk13', '1: a~"1": b => {"1":"b"}');
        Observer.Expect('dk14', 'a: 1~a b: 2~a: 3 => {"a":"3","a b":"2"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DeepFlow()
    begin
        CellShort('flowseq-depth10', 'q: ' + RepeatText('[', 10) + 'x' + RepeatText(']', 10));
        CellShort('flowseq-depth50', 'q: ' + RepeatText('[', 50) + 'x' + RepeatText(']', 50));
        CellShort('flowseq-depth100', 'q: ' + RepeatText('[', 100) + 'x' + RepeatText(']', 100));
        CellShort('flowseq-depth300', 'q: ' + RepeatText('[', 300) + 'x' + RepeatText(']', 300));
        CellShort('flowmap-depth50', 'q: ' + RepeatText('{a: ', 50) + 'x' + RepeatText('}', 50));
        CellShort('flowmap-depth100', 'q: ' + RepeatText('{a: ', 100) + 'x' + RepeatText('}', 100));
        CellShort('seq-depth10', 'k:~' + RepeatText('- ', 10) + 'x');
        CellShort('seq-depth50', 'k:~' + RepeatText('- ', 50) + 'x');
        CellShort('seq-depth100', 'k:~' + RepeatText('- ', 100) + 'x');
        CellShort('longvalue-5000', 'q: ' + RepeatText('abcde', 1000));
        CellShort('longvalue-100000', 'q: ' + RepeatText('abcdefghij', 10000));
        Observer.Expect('flowseq-depth10', '{"q":[[[[[[[[[["x"]]]]]]]]]]}');
        Observer.Expect('flowseq-depth50', '{"q":[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["x"]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]}');
        Observer.Expect('flowseq-depth100', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowseq-depth300', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowmap-depth50', '{"q":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":');
        Observer.Expect('flowmap-depth100', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('seq-depth10', '{"k":[[[[[[[[[["x"]]]]]]]]]]}');
        Observer.Expect('seq-depth50', '{"k":[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["x"]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]}');
        Observer.Expect('seq-depth100', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('longvalue-5000', '{"q":"abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcd');
        Observer.Expect('longvalue-100000', '{"q":"abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DeepMappings()
    var
        Doc: Text;
        Res: Text;
        i: Integer;
        Depth: Integer;
        Ks: List of [Integer];
    begin
        Ks.AddRange(10, 20, 50, 100, 200);
        foreach Depth in Ks do begin
            Doc := '';
            for i := 1 to Depth do
                Doc += RepeatText(' ', i - 1) + 'a:' + Chr(10);
            Doc += RepeatText(' ', Depth) + 'x: 1';
            Res := Both(Doc, '', '');
            Observer.Observe('map-depth' + Format(Depth), CopyStr(Res, 1, 60) + ' len=' + Format(StrLen(Res)));
        end;
        Observer.Expect('map-depth10', '{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"x":"1"}} len=69');
        Observer.Expect('map-depth20', '{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a": len=129');
        Observer.Expect('map-depth50', '{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a":{"a": len=309');
        Observer.Expect('map-depth100', 'FInvalidJsonData:The data does not represent a valid JSON to len=64');
        Observer.Expect('map-depth200', 'FInvalidJsonData:The data does not represent a valid JSON to len=64');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_ManyKeys()
    var
        Doc: Text;
        i: Integer;
        Res: Text;
    begin
        for i := 1 to 2000 do
            Doc += 'k' + Format(i) + ': ' + Format(i) + Chr(10);
        Res := Result(Doc, false, '$.k2000', '2000');
        Observer.Observe('keys2000-text', CopyStr(Res, 1, 80) + ' count=' + Format(JO.Keys().Count()));
        Res := Result(Doc, true, '$.k2000', '2000');
        Observer.Observe('keys2000-stream', CopyStr(Res, 1, 80) + ' count=' + Format(JO.Keys().Count()));
        Res := Result(RepeatText('k', 3000) + ': 1', false, '', '');
        Observer.Observe('long-key', CopyStr(Res, 1, 20) + ' len=' + Format(StrLen(Res)));
        Observer.Expect('keys2000-text', 'ok count=2000');
        Observer.Expect('keys2000-stream', 'ok count=2000');
        Observer.Expect('long-key', 'FYamlBadFormat len=14');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Indentation_1()
    var
        D: List of [Text];
    begin
        D.AddRange('  q: a', 'q: a~ r: b', 'o:~  q: a~ r: b', 'o:~  q: a~   r: b', 'o:~    q: a~  r: b', 'o:~ q: a~   r: b', 'o:~  q: a~r: b~  s: c', 'q:a', 'q: - a', 'q: a: b', '"q": a', '''q'': a',
            'q: a~  b: c', 'o:~  q: a~  q2:~    r: b', 'k:~- a~- b', 'k:~- a~  - b', 'k:~  - a~   - b', 'k:~  - a~ - b', 'k:~  - a~- b~n: 1', 'k:~- a~n: 1', 'q: a~r', 'q: a~r:', 'q a', 'q: a~  # c~  b');
        Cells('in', D, 1, 10);
        Observer.Expect('in1', '  q: a => {"q":"a"}');
        Observer.Expect('in2', 'q: a~ r: b => FYamlBadFormat');
        Observer.Expect('in3', 'o:~  q: a~ r: b => FYamlBadFormat');
        Observer.Expect('in4', 'o:~  q: a~   r: b => FYamlBadFormat');
        Observer.Expect('in5', 'o:~    q: a~  r: b => FYamlBadFormat');
        Observer.Expect('in6', 'o:~ q: a~   r: b => FYamlBadFormat');
        Observer.Expect('in7', 'o:~  q: a~r: b~  s: c => FYamlBadFormat');
        Observer.Expect('in8', 'q:a => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('in9', 'q: - a => FYamlBadFormat');
        Observer.Expect('in10', 'q: a: b => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Indentation_2()
    var
        D: List of [Text];
    begin
        D.AddRange('  q: a', 'q: a~ r: b', 'o:~  q: a~ r: b', 'o:~  q: a~   r: b', 'o:~    q: a~  r: b', 'o:~ q: a~   r: b', 'o:~  q: a~r: b~  s: c', 'q:a', 'q: - a', 'q: a: b', '"q": a', '''q'': a',
            'q: a~  b: c', 'o:~  q: a~  q2:~    r: b', 'k:~- a~- b', 'k:~- a~  - b', 'k:~  - a~   - b', 'k:~  - a~ - b', 'k:~  - a~- b~n: 1', 'k:~- a~n: 1', 'q: a~r', 'q: a~r:', 'q a', 'q: a~  # c~  b');
        Cells('in', D, 11, 20);
        Observer.Expect('in11', '"q": a => {"q":"a"}');
        Observer.Expect('in12', '''q'': a => {"q":"a"}');
        Observer.Expect('in13', 'q: a~  b: c => FYamlBadFormat');
        Observer.Expect('in14', 'o:~  q: a~  q2:~    r: b => {"o":{"q":"a","q2":{"r":"b"}}}');
        Observer.Expect('in15', 'k:~- a~- b => {"k":["a","b"]}');
        Observer.Expect('in16', 'k:~- a~  - b => {"k":["a - b"]}');
        Observer.Expect('in17', 'k:~  - a~   - b => {"k":["a - b"]}');
        Observer.Expect('in18', 'k:~  - a~ - b => FYamlBadFormat');
        Observer.Expect('in19', 'k:~  - a~- b~n: 1 => FYamlBadFormat');
        Observer.Expect('in20', 'k:~- a~n: 1 => {"k":["a"],"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Indentation_3()
    var
        D: List of [Text];
    begin
        D.AddRange('  q: a', 'q: a~ r: b', 'o:~  q: a~ r: b', 'o:~  q: a~   r: b', 'o:~    q: a~  r: b', 'o:~ q: a~   r: b', 'o:~  q: a~r: b~  s: c', 'q:a', 'q: - a', 'q: a: b', '"q": a', '''q'': a',
            'q: a~  b: c', 'o:~  q: a~  q2:~    r: b', 'k:~- a~- b', 'k:~- a~  - b', 'k:~  - a~   - b', 'k:~  - a~ - b', 'k:~  - a~- b~n: 1', 'k:~- a~n: 1', 'q: a~r', 'q: a~r:', 'q a', 'q: a~  # c~  b');
        Cells('in', D, 21, 30);
        Observer.Expect('in21', 'q: a~r => FYamlBadFormat');
        Observer.Expect('in22', 'q: a~r: => {"q":"a","r":null}');
        Observer.Expect('in23', 'q a => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('in24', 'q: a~  # c~  b => FYamlBadFormat');
        Observer.Verify();
    end;

    // ---- 5. dataset shapes of issue 8580 (reporter's files) ----

    [Test]
    procedure ReadFromYaml_DatasetShapes()
    begin
        Cell('ds1-open', 'k:~  - t:~      a: 1~      b: 2~    q: x~    e: y', '');
        Cell('ds1-open-only', 'k:~  - t:~      a: 1', '');
        Cell('ds1-open-sib', 'k:~  - t:~      a: 1~    q: x', '');
        Cell('ds1-open-two-items', 'k:~  - t:~      a: 1~    q: x~  - q:~      b: 2~    e: y', '');
        Cell('ds1-open-last', 'k:~  - q: x~    t:~      a: 1', '');
        Cell('ds1-open-seq', 'k:~  - t:~      - a~      - b~    q: x', '');
        Cell('ds1-open-empty', 'k:~  - t:~    q: x', '');
        Cell('ds2-quoted-one', 'k:~  - "Quoted Key": V', '');
        Cell('ds2-quoted-three', 'k:~  - "No.": V~    Name: S~    "E-Mail": a@b.c', '');
        Cell('ds2-quoted-two-items', 'k:~  - "No.": 1~    Name: S~  - "No.": 2~    "E-Mail": a@b.c', '');
        Cell('ds3-comment-first', 'k:~    # c~    - x~    - y', '');
        Cell('ds3-comment-first-map', 'k:~    # a comment line inside the list~    - "Quoted Key": V', '');
        Cell('ds3-comment-indent0', 'k:~# c~    - x', '');
        Cell('ds3-comment-between', 'k:~    - x~    # c~    - y', '');
        Cell('ds4-blank-plain', 'k:~  - a~~  - b', '');
        Cell('ds4-blank-map', 'k:~  - a: 1~~  - b: 2', '');
        Cell('ds4-blank-spaces', 'k:~  - a: 1~    ~  - b: 2', '');
        Cell('ds4-blank-two', 'k:~  - a~~~  - b', '');
        Cell('ds4-blank-after-open', 'k:~  - t:~      a: 1~~    q: x', '');
        Cell('ds5-html', 'q: "<b>Subject:</b> text [MARKER-0001]<br/><b>Body:</b> <p>Hello,</p>"', '');
        Cell('ds5-colon-space', 'q: "a: b [c] <i>d</i> e: f"', '');
        Cell('ds5-in-item', 'k:~  - m: "<b>S:</b> x [M-1]<br/><p>Hello,</p>"~    n: 1', '');
        Cell('ds5-in-nested', 'k:~  - t:~      m: "<b>S:</b> x [M-1]: y"~    q: z', '');
        Cell('ds6-full', 'tests:~  - name: <test name>~    description: <one line>~    turns:~      - turn_setup:~          setup_actions:~            - action_type: <action>~              action_data:~                # a comment line inside the list~                - "Quoted Key": VALUE~            - action_type: <action>~              action_data:~                - "No.": VALUE~                  Name: Some text~                  "E-Mail": someone@example.com~        query:~          from: Some Name~          title: "Quoted text"~          message: "<b>Subject:</b> text [MARKER-0001]<br/><b>Body:</b> <p>Hello,</p>"~        expected_data:~          intervention_request:~            type: Assistance~~      - query:~          intervention:~            instruction: "Quoted text."~        expected_data:~          marker: SOME-MARKER-0001~          expected_quantity: 1', '');
        Observer.Expect('ds1-open', '{"k":[{"t":{"a":"1","b":"2"},"q":"x","e":"y"}]}');
        Observer.Expect('ds1-open-only', '{"k":[{"t":{"a":"1"}}]}');
        Observer.Expect('ds1-open-sib', '{"k":[{"t":{"a":"1"},"q":"x"}]}');
        Observer.Expect('ds1-open-two-items', '{"k":[{"t":{"a":"1"},"q":"x"},{"q":{"b":"2"},"e":"y"}]}');
        Observer.Expect('ds1-open-last', '{"k":[{"q":"x","t":{"a":"1"}}]}');
        Observer.Expect('ds1-open-seq', '{"k":[{"t":["a","b"],"q":"x"}]}');
        Observer.Expect('ds1-open-empty', '{"k":[{"t":null,"q":"x"}]}');
        Observer.Expect('ds2-quoted-one', '{"k":[{"Quoted Key":"V"}]}');
        Observer.Expect('ds2-quoted-three', '{"k":[{"No.":"V","Name":"S","E-Mail":"a@b.c"}]}');
        Observer.Expect('ds2-quoted-two-items', '{"k":[{"No.":"1","Name":"S"},{"No.":"2","E-Mail":"a@b.c"}]}');
        Observer.Expect('ds3-comment-first', '{"k":["x","y"]}');
        Observer.Expect('ds3-comment-first-map', '{"k":[{"Quoted Key":"V"}]}');
        Observer.Expect('ds3-comment-indent0', '{"k":["x"]}');
        Observer.Expect('ds3-comment-between', '{"k":["x","y"]}');
        Observer.Expect('ds4-blank-plain', '{"k":["a","b"]}');
        Observer.Expect('ds4-blank-map', '{"k":[{"a":"1"},{"b":"2"}]}');
        Observer.Expect('ds4-blank-spaces', '{"k":[{"a":"1"},{"b":"2"}]}');
        Observer.Expect('ds4-blank-two', '{"k":["a","b"]}');
        Observer.Expect('ds4-blank-after-open', '{"k":[{"t":{"a":"1"},"q":"x"}]}');
        Observer.Expect('ds5-html', '{"q":"<b>Subject:</b> text [MARKER-0001]<br/><b>Body:</b> <p>Hello,</p>"}');
        Observer.Expect('ds5-colon-space', '{"q":"a: b [c] <i>d</i> e: f"}');
        Observer.Expect('ds5-in-item', '{"k":[{"m":"<b>S:</b> x [M-1]<br/><p>Hello,</p>","n":"1"}]}');
        Observer.Expect('ds5-in-nested', '{"k":[{"t":{"m":"<b>S:</b> x [M-1]: y"},"q":"z"}]}');
        Observer.Expect('ds6-full', '{"tests":[{"name":"<test name>","description":"<one line>","turns":[{"turn_setup":{"setup_actions":[{"action_type":"<action>","action_data":[{"Quoted Key":"VALUE"}]},{"action_type":"<action>","action_data":[{"No.":"VALUE","Name":"Some text","E-Mail":"someone@example.com"}]}]},"query":{"from":"Some Name","title":"Quoted text","message":"<b>Subject:</b> text [MARKER-0001]<br/><b>Body:</b> <p>Hello,</p>"},"expected_data":{"intervention_request":{"type":"Assistance"}}},{"query":{"intervention":{"instruction":"Quoted text."}},"expected_data":{"marker":"SOME-MARKER-0001","expected_quantity":"1"}}]}]}');
        Observer.Verify();
    end;
}
