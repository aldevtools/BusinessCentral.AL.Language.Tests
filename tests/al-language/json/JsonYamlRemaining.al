// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 75670 "YRM Yaml Blob"
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
// Results: see the assertions below.
// BC versions: 27, 28, 29

table 75670 "YRM Yaml Blob"
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

codeunit 75671 "YRM Json Yaml Remaining"
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_SeqItem_Indent4()
    begin
        SeqCells('    ');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_SeqItemMixed_Indent4()
    begin
        MixedCells('    ');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_SeqItem_TopLevel()
    begin
        Cell('top-map', '- a: 1~  b: 2', '');
        Cell('top-nest', '- - x', '');
        Cell('top-plain', '- p~- q', '');
        Cell('top-nested-in-map', 'o:~  k:~    - a: 1~      b: 2~    - - x~  r: 2~n: 1', '');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Block3_Folded()
    begin
        BlockCells('>');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Block3_LiteralStrip()
    begin
        BlockCells('|-');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Block3_FoldedKeep()
    begin
        BlockCells('>+');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_DoubleQuotedEscape_ListItem()
    begin
        EscCells('list', 'k:~  - "a{X}b"~  - c');
        Cell('list[literal-e-acute]', 'k:~  - "a{E}b"~  - c', '');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_PlainListItem()
    begin
        CrlfMatrix('k:~  - {V}~  - c', '$.k[0]', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_PlainListMap()
    begin
        CrlfMatrix('k:~  - m: {V}~    r: 2~  - c', '$.k[0].m', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_FoldedStrip()
    begin
        CrlfMatrix('q: >-~  {V}~  {V}~n: 1', '$.q', '{V} {V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_Literal()
    begin
        CrlfMatrix('q: |~  {V}~  {V}~n: 1', '$.q', '{V}~{V}~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_DoubleQuoted()
    begin
        CrlfMatrix('q: "{V}"~n: 1', '$.q', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Crlf_SingleQuoted()
    begin
        CrlfMatrix('q: ''{V}''~n: 1', '$.q', '{V}');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FlowSequence_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: [a, b]', 'q: [a, [b, c]]', 'q: []', 'q: [a, b,]', 'q: [ "a,b", ''c'' ]', 'q: [a: 1]', 'q: [a,~  b]', 'q: [a b, c]',
            'q: [a, # c~  b]', 'q: [1, 2]~n: 1', 'k:~  - [a, b]~  - c', 'q: [a, b] x', 'q: [a, b', 'q: [,]', 'q: [a, , b]', 'q: [ ]');
        Cells('fs', D, 11, 20);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FlowMapping_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: {a: 1, b: 2}', 'q: {}', 'q: {a: [1, 2], b: {c: d}}', 'q: {a, b}', 'q: {a: 1,}', 'q: {a: 1,~  b: 2}', 'q: {"a b": 1}',
            'q: {a: }', 'q: {a:1}', 'q: {a: 1, a: 2}', 'q: {? a : 1}', 'q: {a: 1} x', 'q: {a: 1', 'q: { }', 'o:~  q: {a: 1}~  r: [b]', 'k:~  - {a: 1}~  - {b: 2}');
        Cells('fm', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FlowMapping_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: {a: 1, b: 2}', 'q: {}', 'q: {a: [1, 2], b: {c: d}}', 'q: {a, b}', 'q: {a: 1,}', 'q: {a: 1,~  b: 2}', 'q: {"a b": 1}',
            'q: {a: }', 'q: {a:1}', 'q: {a: 1, a: 2}', 'q: {? a : 1}', 'q: {a: 1} x', 'q: {a: 1', 'q: { }', 'o:~  q: {a: 1}~  r: [b]', 'k:~  - {a: 1}~  - {b: 2}');
        Cells('fm', D, 11, 20);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TopLevelForms_1()
    var
        D: List of [Text];
    begin
        D.AddRange('{a: 1}', '[a]', 'a', '', '{~}', 'null', '# c', '---', '---~', '---~q: a', 'q: a~...', '...', '"a"', '''a''', '{a: 1, b: [c]}', '|~  x', '1', '{}', '[]');
        Cells('tl', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TopLevelForms_2()
    var
        D: List of [Text];
    begin
        D.AddRange('{a: 1}', '[a]', 'a', '', '{~}', 'null', '# c', '---', '---~', '---~q: a', 'q: a~...', '...', '"a"', '''a''', '{a: 1, b: [c]}', '|~  x', '1', '{}', '[]');
        Cells('tl', D, 11, 20);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Documents_1()
    var
        D: List of [Text];
    begin
        D.AddRange('---~q: a', 'q: a~---~r: b', '---~q: a~---~r: b', '--- # c~q: a', '--- |~  x', '---~...', '%YAML 1.2~---~q: a', '%YAML 1.1~---~q: a', '%YAML 1.3~---~q: a',
            '%FOO bar~---~q: a', '%YAML 1.2~q: a', '--- q: a', '---q: a', 'q: a~...~', 'q: a~...~---~r: b', 'q: a~... # c', '--- !!map~q: a', '---~---', '--- &x~q: a', 'q: ---', 'q: ...', 'q: a~--- b');
        Cells('dc', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Documents_2()
    var
        D: List of [Text];
    begin
        D.AddRange('---~q: a', 'q: a~---~r: b', '---~q: a~---~r: b', '--- # c~q: a', '--- |~  x', '---~...', '%YAML 1.2~---~q: a', '%YAML 1.1~---~q: a', '%YAML 1.3~---~q: a',
            '%FOO bar~---~q: a', '%YAML 1.2~q: a', '--- q: a', '---q: a', 'q: a~...~', 'q: a~...~---~r: b', 'q: a~... # c', '--- !!map~q: a', '---~---', '--- &x~q: a', 'q: ---', 'q: ...', 'q: a~--- b');
        Cells('dc', D, 11, 20);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Documents_3()
    var
        D: List of [Text];
    begin
        D.AddRange('---~q: a', 'q: a~---~r: b', '---~q: a~---~r: b', '--- # c~q: a', '--- |~  x', '---~...', '%YAML 1.2~---~q: a', '%YAML 1.1~---~q: a', '%YAML 1.3~---~q: a',
            '%FOO bar~---~q: a', '%YAML 1.2~q: a', '--- q: a', '---q: a', 'q: a~...~', 'q: a~...~---~r: b', 'q: a~... # c', '--- !!map~q: a', '---~---', '--- &x~q: a', 'q: ---', 'q: ...', 'q: a~--- b');
        Cells('dc', D, 21, 30);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_ComplexKeys_1()
    var
        D: List of [Text];
    begin
        D.AddRange('? a~: b', '? [a, b]~: c', '? a~? b', '? |~  x~: 1', '[a, b]: c', '{a: b}: c', '? a', '"a b": 1', '''a'': 1', '? - a~  - b~: c', '1: a', 'null: a', '{~}: a', 'true: a',
            'a b: 1', '"a: b": 1', 'a#b: 1', ': a', '? {~}~: a', '"a": 1~a: 2', '? a~: b~c: d', '? a : b', '"": 1', '''a''''b'': 1', '"a{\}nb": 1', '? a~  b~: c', '*x : 1', '!!str a: 1');
        Cells('ck', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_ComplexKeys_2()
    var
        D: List of [Text];
    begin
        D.AddRange('? a~: b', '? [a, b]~: c', '? a~? b', '? |~  x~: 1', '[a, b]: c', '{a: b}: c', '? a', '"a b": 1', '''a'': 1', '? - a~  - b~: c', '1: a', 'null: a', '{~}: a', 'true: a',
            'a b: 1', '"a: b": 1', 'a#b: 1', ': a', '? {~}~: a', '"a": 1~a: 2', '? a~: b~c: d', '? a : b', '"": 1', '''a''''b'': 1', '"a{\}nb": 1', '? a~  b~: c', '*x : 1', '!!str a: 1');
        Cells('ck', D, 11, 20);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_ComplexKeys_3()
    var
        D: List of [Text];
    begin
        D.AddRange('? a~: b', '? [a, b]~: c', '? a~? b', '? |~  x~: 1', '[a, b]: c', '{a: b}: c', '? a', '"a b": 1', '''a'': 1', '? - a~  - b~: c', '1: a', 'null: a', '{~}: a', 'true: a',
            'a b: 1', '"a: b": 1', 'a#b: 1', ': a', '? {~}~: a', '"a": 1~a: 2', '? a~: b~c: d', '? a : b', '"": 1', '''a''''b'': 1', '"a{\}nb": 1', '? a~  b~: c', '*x : 1', '!!str a: 1');
        Cells('ck', D, 21, 30);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_NullAndEmpty_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q:', 'q: {~}', 'q: null', 'q: Null', 'q: NULL', 'q: nUll', 'q: ""', 'q: ''''', 'q: !!null', 'q:~n: 1', 'k:~  - {~}~  - null~  -~  - ''''', 'q: nul', '{~}: 1', 'q: ~x', 'q: ~ ',
            'q:   ', 'q: ~~', 'k:', 'k:~  -', 'k:~  - ', 'o:~  q:', 'o:~  q:~n: 1', 'q: [{~}, null, ]', 'q: {a: {~}, b: null, c: }');
        Cells('nl', D, 1, 10);
        Observer.Finish();
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
        Observer.Finish();
    end;

    local procedure ScalarCells(Prefix: Text; Items: List of [Text])
    var
        S: Text;
    begin
        foreach S in Items do
            Observer.Observe(Prefix + '[' + S + ']', Both(Doc('q: ' + S, ''), '', ''));
    end;

    [Test]
    procedure ReadFromYaml_NullAndEmpty_3()
    var
        D: List of [Text];
    begin
        D.AddRange('q:', 'q: {~}', 'q: null', 'q: Null', 'q: NULL', 'q: nUll', 'q: ""', 'q: ''''', 'q: !!null', 'q:~n: 1', 'k:~  - {~}~  - null~  -~  - ''''', 'q: nul', '{~}: 1', 'q: ~x', 'q: ~ ',
            'q:   ', 'q: ~~', 'k:', 'k:~  -', 'k:~  - ', 'o:~  q:', 'o:~  q:~n: 1', 'q: [{~}, null, ]', 'q: {a: {~}, b: null, c: }');
        Cells('nl', D, 21, 30);
        Observer.Finish();
    end;

    local procedure ScalarCells(Prefix: Text; Items: List of [Text])
    var
        S: Text;
    begin
        foreach S in Items do
            Observer.Observe(Prefix + '[' + S + ']', Both(Doc('q: ' + S, ''), '', ''));
    end;

    [Test]
    procedure ReadFromYaml_Booleans()
    var
        L: List of [Text];
    begin
        L.AddRange('yes', 'no', 'Yes', 'No', 'YES', 'NO', 'y', 'n', 'Y', 'N', 'on', 'off', 'On', 'Off', 'ON', 'OFF', 'true', 'false', 'True', 'False', 'TRUE', 'FALSE', 'tRue', 'fALSE', 't', 'f');
        ScalarCells('b', L);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Integers()
    var
        L: List of [Text];
    begin
        L.AddRange('0', '1', '-1', '+1', '007', '0x1F', '0X1f', '0o17', '0b101', '017', '1_000', '1,000', '0x', '-0', '+0', '00', '12345678901234567890', '-9223372036854775808', '9223372036854775808',
            '0xFFFFFFFFFFFFFFFF', '0o', '08', '1 000');
        ScalarCells('i', L);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Floats()
    var
        L: List of [Text];
    begin
        L.AddRange('1.5', '.5', '5.', '1e3', '1E3', '1.5e+3', '-1.5E-3', '.inf', '-.inf', '+.inf', '.Inf', '.INF', '.NaN', '.nan', '.NAN', 'inf', 'nan', 'NaN', '1e', '12:30:45', '1:30', '2001-12-14',
            '2001-12-14t21:59:43.10-05:00', '2001-12-14 21:59:43.10 -5', '0.1.2', '1.0', '-0.0', '1e400', '3.14159265358979323846264338327950288');
        ScalarCells('f', L);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BomTabsSpaces_1()
    var
        D: List of [Text];
    begin
        D.AddRange('{B}q: a', 'q: a{B}', 'q: {B}a', '{B}---~q: a', 'q:{T}a', 'q: a{T}', 'q: a{T}b', 'k:~{T}- a', 'k:~  -{T}a', 'k:~  -{T}{T}a', 'o:~{T}q: a', 'q: a   ', 'q:   a', 'q:   ~n: 1',
            '---   ~q: a', 'q: |   ~  x', 'q: |~  x   ~  y   ', 'q: a~~~~', '~~~q: a', '   ', '{T}', 'q: a{0}b', '{0}', 'q: a{S}{S}{S}~n: 1{S}', 'q: a~{S}', 'q: a~{T}');
        Cells('bt', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BomTabsSpaces_2()
    var
        D: List of [Text];
    begin
        D.AddRange('{B}q: a', 'q: a{B}', 'q: {B}a', '{B}---~q: a', 'q:{T}a', 'q: a{T}', 'q: a{T}b', 'k:~{T}- a', 'k:~  -{T}a', 'k:~  -{T}{T}a', 'o:~{T}q: a', 'q: a   ', 'q:   a', 'q:   ~n: 1',
            '---   ~q: a', 'q: |   ~  x', 'q: |~  x   ~  y   ', 'q: a~~~~', '~~~q: a', '   ', '{T}', 'q: a{0}b', '{0}', 'q: a{S}{S}{S}~n: 1{S}', 'q: a~{S}', 'q: a~{T}');
        Cells('bt', D, 11, 20);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BomTabsSpaces_3()
    var
        D: List of [Text];
    begin
        D.AddRange('{B}q: a', 'q: a{B}', 'q: {B}a', '{B}---~q: a', 'q:{T}a', 'q: a{T}', 'q: a{T}b', 'k:~{T}- a', 'k:~  -{T}a', 'k:~  -{T}{T}a', 'o:~{T}q: a', 'q: a   ', 'q:   a', 'q:   ~n: 1',
            '---   ~q: a', 'q: |   ~  x', 'q: |~  x   ~  y   ', 'q: a~~~~', '~~~q: a', '   ', '{T}', 'q: a{0}b', '{0}', 'q: a{S}{S}{S}~n: 1{S}', 'q: a~{S}', 'q: a~{T}');
        Cells('bt', D, 21, 30);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_DuplicateKeys_1()
    var
        D: List of [Text];
    begin
        D.AddRange('a: 1~a: 2', 'o:~  a: 1~  a: 2', 'q: {a: 1, a: 2}', 'a: 1~"a": 2', 'a: 1~''a'': 2', 'k:~  - a: 1~    a: 2', 'a: 1~b: 2~a: 3', 'a: 1~A: 2', 'a: {~}~a: 1', 'a:~a: 1',
            'a: &x 1~a: *x', '<<: {a: 1}~<<: {b: 2}', '1: a~"1": b', 'a: 1~a b: 2~a: 3');
        Cells('dk', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_DuplicateKeys_2()
    var
        D: List of [Text];
    begin
        D.AddRange('a: 1~a: 2', 'o:~  a: 1~  a: 2', 'q: {a: 1, a: 2}', 'a: 1~"a": 2', 'a: 1~''a'': 2', 'k:~  - a: 1~    a: 2', 'a: 1~b: 2~a: 3', 'a: 1~A: 2', 'a: {~}~a: 1', 'a:~a: 1',
            'a: &x 1~a: *x', '<<: {a: 1}~<<: {b: 2}', '1: a~"1": b', 'a: 1~a b: 2~a: 3');
        Cells('dk', D, 11, 20);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Indentation_1()
    var
        D: List of [Text];
    begin
        D.AddRange('  q: a', 'q: a~ r: b', 'o:~  q: a~ r: b', 'o:~  q: a~   r: b', 'o:~    q: a~  r: b', 'o:~ q: a~   r: b', 'o:~  q: a~r: b~  s: c', 'q:a', 'q: - a', 'q: a: b', '"q": a', '''q'': a',
            'q: a~  b: c', 'o:~  q: a~  q2:~    r: b', 'k:~- a~- b', 'k:~- a~  - b', 'k:~  - a~   - b', 'k:~  - a~ - b', 'k:~  - a~- b~n: 1', 'k:~- a~n: 1', 'q: a~r', 'q: a~r:', 'q a', 'q: a~  # c~  b');
        Cells('in', D, 1, 10);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Indentation_2()
    var
        D: List of [Text];
    begin
        D.AddRange('  q: a', 'q: a~ r: b', 'o:~  q: a~ r: b', 'o:~  q: a~   r: b', 'o:~    q: a~  r: b', 'o:~ q: a~   r: b', 'o:~  q: a~r: b~  s: c', 'q:a', 'q: - a', 'q: a: b', '"q": a', '''q'': a',
            'q: a~  b: c', 'o:~  q: a~  q2:~    r: b', 'k:~- a~- b', 'k:~- a~  - b', 'k:~  - a~   - b', 'k:~  - a~ - b', 'k:~  - a~- b~n: 1', 'k:~- a~n: 1', 'q: a~r', 'q: a~r:', 'q a', 'q: a~  # c~  b');
        Cells('in', D, 11, 20);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Indentation_3()
    var
        D: List of [Text];
    begin
        D.AddRange('  q: a', 'q: a~ r: b', 'o:~  q: a~ r: b', 'o:~  q: a~   r: b', 'o:~    q: a~  r: b', 'o:~ q: a~   r: b', 'o:~  q: a~r: b~  s: c', 'q:a', 'q: - a', 'q: a: b', '"q": a', '''q'': a',
            'q: a~  b: c', 'o:~  q: a~  q2:~    r: b', 'k:~- a~- b', 'k:~- a~  - b', 'k:~  - a~   - b', 'k:~  - a~ - b', 'k:~  - a~- b~n: 1', 'k:~- a~n: 1', 'q: a~r', 'q: a~r:', 'q a', 'q: a~  # c~  b');
        Cells('in', D, 21, 30);
        Observer.Finish();
    end;

}
