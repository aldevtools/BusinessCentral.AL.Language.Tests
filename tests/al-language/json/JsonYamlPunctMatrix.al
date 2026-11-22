// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: AL Runner issue 8580 (AI eval datasets in .yaml app resources). A matrix of every printable ASCII punctuation character
//   in every scalar position, so that a reader can admit exactly the shapes BC reads.
//   Written against BC 27.5, 28.5 and 29.0; every literal asserted below is what those tiers produced.
// Facts: JsonObject.ReadFromYaml(Text) of a document that holds one item in one position. Items: each of
//   ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~ and the sequences "...", ": ", " #", "- ", "? ".
//   Each item is placed in four slots of the line: S = item + 'ab' (start), M = 'a' + item + 'b' (middle),
//   E = 'ab' + item (end), W = 'a ' + item + ' b' (between words).
//   Positions (one test each): plain top-level mapping value, plain nested mapping value, plain list item, plain value of the
//   first and of the second key of a list-item mapping (`- m: v`), plain nested list item, the two lines of a `>-`, `>`, `|`
//   and `|-` block (the slot text on both lines), a `>-` block as a list-item mapping value, a double-quoted and a
//   single-quoted value.
//   Result per slot: "ok" = ReadFromYaml returned true and the value at the position is exactly the text as written (blocks:
//   the lines joined as YAML folds or keeps them); "F<n>" = ReadFromYaml returned false with error n; "T<n>" = the call raised
//   error n (the TryFunction caught it); otherwise the JSON text the object holds (WriteTo), characters outside printable
//   ASCII as <U+XXXX>. The error texts are listed per test under 'errors'.
// Results: (filled in from the observation)
// BC versions: 27, 28, 29

codeunit 75623 "YPM Json Yaml Punct Matrix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        JO: JsonObject;
        Ok: Boolean;
        Errors: List of [Text];

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        Clear(JO);
        Ok := false;
        Ok := JO.ReadFromYaml(Src);
    end;

    local procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    // Every printable ASCII punctuation character, then the sequences.
    local procedure Items(var Ks: List of [Text])
    var
        Punct: Text;
        i: Integer;
    begin
        Punct := '!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~';
        for i := 1 to StrLen(Punct) do
            Ks.Add(CopyStr(Punct, i, 1));
        Ks.AddRange('...', ': ', ' #', '- ', '? ');
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

    // The number of the last error in this test's list (added when new), then clears it.
    local procedure ErrIndex(): Text
    var
        Msg: Text;
    begin
        Msg := Esc(GetLastErrorText());
        ClearLastError();
        if not Errors.Contains(Msg) then
            Errors.Add(Msg);
        exit(Format(Errors.IndexOf(Msg)));
    end;

    // One slot: reads Src and compares the value at JPath with Expected.
    local procedure Slot(Src: Text; JPath: Text; Expected: Text): Text
    var
        Tok: JsonToken;
        Out: Text;
    begin
        ClearLastError();
        if not TryRead(Src) then
            exit('T' + ErrIndex());
        if not Ok then
            exit('F' + ErrIndex());
        if JO.SelectToken(JPath, Tok) then
            if Tok.IsValue() then
                if not Tok.AsValue().IsNull() then
                    if Tok.AsValue().AsText() = Expected then
                        exit('ok');
        JO.WriteTo(Out);
        exit(Esc(Out));
    end;

    // Tpl and ExpTpl: '~' is a line feed, '{V}' the slot text (put in after the line feeds, so a '~' item stays a '~').
    local procedure Fill(Tpl: Text; V: Text): Text
    begin
        exit(Tpl.Replace('~', Chr(10)).Replace('{V}', V));
    end;

    local procedure Matrix(Tpl: Text; JPath: Text; ExpTpl: Text)
    var
        Ks: List of [Text];
        K: Text;
        Slots: List of [Text];
        Names: Text;
        V: Text;
        i: Integer;
        Line: Text;
        All: Text;
    begin
        Clear(Errors);
        Items(Ks);
        Names := 'SMEW';
        foreach K in Ks do begin
            Clear(Slots);
            Slots.Add(K + 'ab');
            Slots.Add('a' + K + 'b');
            Slots.Add('ab' + K);
            Slots.Add('a ' + K + ' b');
            Line := '';
            for i := 1 to 4 do begin
                V := Slots.Get(i);
                if i > 1 then
                    Line += ' | ';
                Line += CopyStr(Names, i, 1) + ' ' + Slot(Fill(Tpl, V), JPath, Fill(ExpTpl, V));
            end;
            Observer.Observe('[' + K + ']', Line);
        end;
        for i := 1 to Errors.Count() do
            All += Format(i) + ': ' + Errors.Get(i) + ' ';
        Observer.Observe('errors', All);
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainTop_Read()
    begin
        Matrix('q: {V}~n: 1', '$.q', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainTop_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainNested_Read()
    begin
        Matrix('o:~  q: {V}~  r: 2~n: 1', '$.o.q', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainNested_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainListItem_Read()
    begin
        Matrix('k:~  - {V}~  - c', '$.k[0]', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainListItem_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainListMapFirst_Read()
    begin
        Matrix('k:~  - m: {V}~    r: 2~  - c', '$.k[0].m', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainListMapFirst_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainListMapSecond_Read()
    begin
        Matrix('k:~  - r: 2~    m: {V}~  - c', '$.k[0].m', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainListMapSecond_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainNestedList_Read()
    begin
        Matrix('o:~  k:~    - {V}~    - c~n: 1', '$.o.k[0]', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_PlainNestedList_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_FoldedStrip_Read()
    begin
        Matrix('q: >-~  {V}~  {V}~n: 1', '$.q', '{V} {V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_FoldedStrip_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_Folded_Read()
    begin
        Matrix('q: >~  {V}~  {V}~n: 1', '$.q', '{V} {V}~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_Folded_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_Literal_Read()
    begin
        Matrix('q: |~  {V}~  {V}~n: 1', '$.q', '{V}~{V}~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_Literal_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_LiteralStrip_Read()
    begin
        Matrix('q: |-~  {V}~  {V}~n: 1', '$.q', '{V}~{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_LiteralStrip_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_FoldedStripListMap_Read()
    begin
        Matrix('k:~  - m: >-~      {V}~      {V}~    r: 2', '$.k[0].m', '{V} {V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_FoldedStripListMap_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_DoubleQuoted_Read()
    begin
        Matrix('q: "{V}"~n: 1', '$.q', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_DoubleQuoted_Read_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure ReadFromYamlPunct_SingleQuoted_Read()
    begin
        Matrix('q: ''{V}''~n: 1', '$.q', '{V}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYamlPunct_SingleQuoted_Read_More1()
    begin
        Observer.More();
    end;
}
