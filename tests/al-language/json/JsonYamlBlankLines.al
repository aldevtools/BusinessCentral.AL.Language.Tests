// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: AL Runner issue 8580 (an install routine imports AI eval datasets, .yaml app resources, through ReadFromYaml).
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: JsonObject.ReadFromYaml of block lists and nested mappings with blank lines between items and keys, blank lines
//   of spaces only, trailing line feeds, whole-text CRLF line endings, block scalars (|, |-, >, >-), comment lines,
//   quoted keys and values, flow lists and flow mappings inside block lists, and one dataset document in the shape the
//   AI Test Toolkit reads (own data). Each document is read in both call forms: the Boolean return value
//   (Ok := ReadFromYaml) and the statement form; then WriteTo of the result.
// BC versions: 27, 28, 29

codeunit 75620 "YBL Json Yaml Blank Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        JO: JsonObject;
        Ok: Boolean;

    [TryFunction]
    local procedure TryReadReturn(Src: Text)
    begin
        Clear(JO);
        Ok := false;
        Ok := JO.ReadFromYaml(Src);
    end;

    [TryFunction]
    local procedure TryReadStatement(Src: Text)
    begin
        Clear(JO);
        JO.ReadFromYaml(Src);
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    local procedure CrLf(): Text
    var
        C: Text[2];
    begin
        C[1] := 13;
        C[2] := 10;
        exit(C);
    end;

    // Src uses '~' for a line break; Read observes the text with LF line breaks, ReadCrLf with CRLF line breaks.
    local procedure Doc(Src: Text; Eol: Text): Text
    begin
        exit(Src.Replace('~', Eol));
    end;

    local procedure Read(var Obs: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        Out: Text;
        Res: Text;
    begin
        ClearLastError();
        Res := Format(TryReadReturn(Src)) + '|' + Format(Ok);
        Obs.Observe(Name + '-ret', Res + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        JO.WriteTo(Out);
        Obs.Observe(Name + '-json', Out);
        ClearLastError();
        Res := Format(TryReadStatement(Src));
        Obs.Observe(Name + '-stmt', Res + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
    end;

    local procedure ReadLf(var Obs: Codeunit "Probe Observer"; Name: Text; Src: Text)
    begin
        Read(Obs, Name, Doc(Src, Lf()));
    end;

    local procedure ReadCrLf(var Obs: Codeunit "Probe Observer"; Name: Text; Src: Text)
    begin
        Read(Obs, Name + '-crlf', Doc(Src, CrLf()));
    end;

    [Test]
    procedure ReadFromYaml_BlankLineTopList_Read()
    begin
        ReadLf(Observer, 'toplist', '- a~~- b');
        ReadLf(Observer, 'keylist0', 'k:~- a~~- b');
        ReadLf(Observer, 'keylist0-two', 'k:~- a~~- b~~- c');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BlankLineNestedList_Read()
    begin
        ReadLf(Observer, 'keylist2', 'k:~  - a~~  - b');
        ReadCrLf(Observer, 'keylist2', 'k:~  - a~~  - b');
        ReadCrLf(Observer, 'keylist2-noblank', 'k:~  - a~  - b');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BlankLineNestedKeys_Read()
    begin
        ReadLf(Observer, 'nested', 'a:~  b: 1~~  c: 2');
        ReadCrLf(Observer, 'nested', 'a:~  b: 1~~  c: 2');
        ReadLf(Observer, 'nested-top', 'a:~  b: 1~~c: 2');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BlankLineListItemMapping_Read()
    begin
        ReadLf(Observer, 'itemmap-inner', 'k:~  - x: 1~~    y: 2');
        ReadLf(Observer, 'itemmap-between', 'k:~  - x: 1~    y: 2~~  - x: 3~    y: 4');
        ReadCrLf(Observer, 'itemmap-between', 'k:~  - x: 1~    y: 2~~  - x: 3~    y: 4');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_CrLfNoBlank_Read()
    begin
        ReadCrLf(Observer, 'nested', 'a:~  b: 1');
        ReadCrLf(Observer, 'toplist', '- a~- b');
        ReadCrLf(Observer, 'flow', 'k:~  - [a, b]~  - {x: 1}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TrailingLines_Read()
    begin
        ReadLf(Observer, 'nested-lf', 'a:~  b: 1~');
        ReadLf(Observer, 'nested-lflflf', 'a:~  b: 1~~~');
        ReadLf(Observer, 'list-lf', 'k:~  - a~  - b~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TrailingLinesCrLf_Read()
    begin
        ReadCrLf(Observer, 'nested-lf', 'a:~  b: 1~');
        ReadCrLf(Observer, 'list-lflf', 'k:~  - a~  - b~~');
        ReadCrLf(Observer, 'flat-lf', 'a: 1~b: 2~');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_SpacesOnlyLine_Read()
    begin
        ReadLf(Observer, 'list', 'k:~  - a~   ~  - b');
        ReadLf(Observer, 'nested', 'a:~  b: 1~  ~  c: 2');
        ReadLf(Observer, 'flat', 'a: 1~  ~b: 2');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_SpacesOnlyLineMore_Read()
    begin
        ReadCrLf(Observer, 'list', 'k:~  - a~   ~  - b');
        ReadLf(Observer, 'trailing', 'a:~  b: 1~    ');
        ReadLf(Observer, 'deep', 'a:~  b:~    c: 1~      ~    d: 2');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FlowInBlockList_Read()
    begin
        ReadLf(Observer, 'flow', 'k:~  - [a, b]~  - {x: 1}');
        ReadLf(Observer, 'flow-blank', 'k:~  - [a, b]~~  - {x: 1}');
        ReadLf(Observer, 'flow-values', 'k: [a, b]~m: {x: 1, y: two words}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FlowInListItemMapping_Read()
    begin
        ReadLf(Observer, 'itemflow', 'k:~  - tags: [a, "b c"]~    opts: {x: 1}~~  - tags: []');
        ReadCrLf(Observer, 'itemflow', 'k:~  - tags: [a, "b c"]~    opts: {x: 1}~~  - tags: []');
        ReadLf(Observer, 'flow-quoted', 'k: ["x, y", ''z'']');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_LiteralBlockScalar_Read()
    begin
        ReadLf(Observer, 'literal', 'q: |~  line one~  line two~n: 1');
        ReadLf(Observer, 'literal-strip', 'q: |-~  line one~  line two~n: 1');
        ReadLf(Observer, 'literal-blank', 'q: |~  line one~~  line three~n: 1');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FoldedBlockScalar_Read()
    begin
        ReadLf(Observer, 'folded', 'q: >~  line one~  line two~n: 1');
        ReadLf(Observer, 'folded-strip', 'q: >-~  line one~  line two~n: 1');
        ReadLf(Observer, 'folded-blank', 'q: >~  line one~~  line three~n: 1');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarEnd_Read()
    begin
        ReadLf(Observer, 'literal-last', 'q: |~  line one~  line two');
        ReadLf(Observer, 'literal-last-lf', 'q: |~  line one~  line two~');
        ReadCrLf(Observer, 'literal', 'q: |~  line one~  line two~n: 1');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarInListItem_Read()
    begin
        ReadLf(Observer, 'item-literal', 'k:~  - q: |~      one~      two~    n: 1~~  - q: >-~      three~      four');
        ReadCrLf(Observer, 'item-literal', 'k:~  - q: |~      one~      two~    n: 1~~  - q: >-~      three~      four');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_CommentsAndQuotes_Read()
    begin
        ReadLf(Observer, 'comment', '# head~a: 1 # tail~~# between~b: 2');
        ReadLf(Observer, 'quoted-key', '"Some Key": two words~''Other Key'': "x"');
        ReadLf(Observer, 'quoted-escapes', 'a: "say \"hi\"\nnext"~b: ''it''''s''');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_ScalarForms_Read()
    begin
        ReadLf(Observer, 'numbers', 'a: 1.5~b: -3~c: 0010~d: 1e3');
        ReadLf(Observer, 'words', 'a: two words here~b: yes~c: ~~d: Null');
        ReadLf(Observer, 'special', 'a: http://x/y~b: x:y~c: "$Var-<CW+1M>$"');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_DatasetDocument_Read()
    begin
        ReadLf(Observer, 'dataset', DatasetDoc());
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_DatasetDocumentCrLf_Read()
    begin
        ReadCrLf(Observer, 'dataset', DatasetDoc());
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_DatasetDocumentGet_Read()
    var
        Tok: JsonToken;
        Tests: JsonArray;
        Item: JsonToken;
    begin
        Observer.Observe('read', Format(TryReadReturn(Doc(DatasetDoc(), Lf()))) + '|' + Format(Ok));
        Observer.Observe('has-tests', Format(JO.Get('tests', Tok)));
        Observer.Observe('tests-is-array', Format(Tok.IsArray()));
        Tests := Tok.AsArray();
        Observer.Observe('tests-count', Format(Tests.Count()));
        Tests.Get(0, Item);
        Item.AsObject().Get('question', Tok);
        Observer.Observe('q0-len', Format(StrLen(Tok.AsValue().AsText())));
        Observer.Observe('q0-lf', Format(Tok.AsValue().AsText().IndexOf(Lf())));
        Item.AsObject().Get('description', Tok);
        Observer.Observe('d0', Tok.AsValue().AsText());
        Item.AsObject().Get('Expected Amount', Tok);
        Observer.Observe('amount-is-value', Format(Tok.IsValue()));
        Observer.Observe('amount', Tok.AsValue().AsText());
        JO.Get('name', Tok);
        Observer.Observe('name', Tok.AsValue().AsText());
        Observer.Finish();
    end;

    // A dataset in the shape the AI Test Toolkit imports: top keys, a `tests` list of mappings, block scalars,
    // comments, quoted keys, flow forms and a blank line between the list items. Own data.
    local procedure DatasetDoc(): Text
    begin
        exit(
            '# Demo evaluation dataset~' +
            'name: Demo dataset~' +
            'language: en-US~' +
            'tests:~' +
            '  - name: "First case"~' +
            '    description: >-~' +
            '      Folded text~' +
            '      on two lines~' +
            '    question: |~' +
            '      Line one~' +
            '      Line two~' +
            '    "Expected Amount": 10~' +
            '    expected_data:~' +
            '      lines:~' +
            '        - "Item No.": "1000"~' +
            '          quantity: 2~' +
            '        - "Item No.": ''2000''~' +
            '          quantity: 5~' +
            '~' +
            '  - name: Second case~' +
            '    description: plain multi word value # a comment~' +
            '    question: |-~' +
            '      Only line~' +
            '    "Expected Amount": 0~' +
            '    tags: [alpha, beta]~' +
            '    options: {mode: fast, retries: 2}~');
    end;
}
