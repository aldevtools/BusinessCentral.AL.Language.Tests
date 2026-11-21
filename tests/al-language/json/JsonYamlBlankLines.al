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
// Results (same on 27.5, 28.5 and 29.0): blank lines, lines of spaces only, trailing line feeds and whole-text CRLF are
//   ignored in every block, nested, list and flow shape here; the result equals the LF form without blank lines. A
//   top-level list is no object: the Boolean form returns false without an error but sets the last error
//   (InvalidJsonType), the statement form raises it. Literal block scalars keep line feeds (CRLF becomes LF), `|-` and
//   `>-` strip the last one, `>` folds lines into spaces and a blank line into a line feed. Comments are dropped, quoted
//   keys keep their spaces, every scalar but null is text ("1.5", "0010", "yes"); an empty value and `Null` are null.
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
        Observer.Expect('toplist-ret', 'Yes|No|JSON tokens of type ''Array'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('toplist-json', '{}');
        Observer.Expect('toplist-stmt', 'No|JSON tokens of type ''Array'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('keylist0-ret', 'Yes|Yes||');
        Observer.Expect('keylist0-json', '{"k":["a","b"]}');
        Observer.Expect('keylist0-stmt', 'Yes||');
        Observer.Expect('keylist0-two-ret', 'Yes|Yes||');
        Observer.Expect('keylist0-two-json', '{"k":["a","b","c"]}');
        Observer.Expect('keylist0-two-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlankLineNestedList_Read()
    begin
        ReadLf(Observer, 'keylist2', 'k:~  - a~~  - b');
        ReadCrLf(Observer, 'keylist2', 'k:~  - a~~  - b');
        ReadCrLf(Observer, 'keylist2-noblank', 'k:~  - a~  - b');
        Observer.Expect('keylist2-ret', 'Yes|Yes||');
        Observer.Expect('keylist2-json', '{"k":["a","b"]}');
        Observer.Expect('keylist2-stmt', 'Yes||');
        Observer.Expect('keylist2-crlf-ret', 'Yes|Yes||');
        Observer.Expect('keylist2-crlf-json', '{"k":["a","b"]}');
        Observer.Expect('keylist2-crlf-stmt', 'Yes||');
        Observer.Expect('keylist2-noblank-crlf-ret', 'Yes|Yes||');
        Observer.Expect('keylist2-noblank-crlf-json', '{"k":["a","b"]}');
        Observer.Expect('keylist2-noblank-crlf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlankLineNestedKeys_Read()
    begin
        ReadLf(Observer, 'nested', 'a:~  b: 1~~  c: 2');
        ReadCrLf(Observer, 'nested', 'a:~  b: 1~~  c: 2');
        ReadLf(Observer, 'nested-top', 'a:~  b: 1~~c: 2');
        Observer.Expect('nested-ret', 'Yes|Yes||');
        Observer.Expect('nested-json', '{"a":{"b":"1","c":"2"}}');
        Observer.Expect('nested-stmt', 'Yes||');
        Observer.Expect('nested-crlf-ret', 'Yes|Yes||');
        Observer.Expect('nested-crlf-json', '{"a":{"b":"1","c":"2"}}');
        Observer.Expect('nested-crlf-stmt', 'Yes||');
        Observer.Expect('nested-top-ret', 'Yes|Yes||');
        Observer.Expect('nested-top-json', '{"a":{"b":"1"},"c":"2"}');
        Observer.Expect('nested-top-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlankLineListItemMapping_Read()
    begin
        ReadLf(Observer, 'itemmap-inner', 'k:~  - x: 1~~    y: 2');
        ReadLf(Observer, 'itemmap-between', 'k:~  - x: 1~    y: 2~~  - x: 3~    y: 4');
        ReadCrLf(Observer, 'itemmap-between', 'k:~  - x: 1~    y: 2~~  - x: 3~    y: 4');
        Observer.Expect('itemmap-inner-ret', 'Yes|Yes||');
        Observer.Expect('itemmap-inner-json', '{"k":[{"x":"1","y":"2"}]}');
        Observer.Expect('itemmap-inner-stmt', 'Yes||');
        Observer.Expect('itemmap-between-ret', 'Yes|Yes||');
        Observer.Expect('itemmap-between-json', '{"k":[{"x":"1","y":"2"},{"x":"3","y":"4"}]}');
        Observer.Expect('itemmap-between-stmt', 'Yes||');
        Observer.Expect('itemmap-between-crlf-ret', 'Yes|Yes||');
        Observer.Expect('itemmap-between-crlf-json', '{"k":[{"x":"1","y":"2"},{"x":"3","y":"4"}]}');
        Observer.Expect('itemmap-between-crlf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_CrLfNoBlank_Read()
    begin
        ReadCrLf(Observer, 'nested', 'a:~  b: 1');
        ReadCrLf(Observer, 'toplist', '- a~- b');
        ReadCrLf(Observer, 'flow', 'k:~  - [a, b]~  - {x: 1}');
        Observer.Expect('nested-crlf-ret', 'Yes|Yes||');
        Observer.Expect('nested-crlf-json', '{"a":{"b":"1"}}');
        Observer.Expect('nested-crlf-stmt', 'Yes||');
        Observer.Expect('toplist-crlf-ret', 'Yes|No|JSON tokens of type ''Array'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('toplist-crlf-json', '{}');
        Observer.Expect('toplist-crlf-stmt', 'No|JSON tokens of type ''Array'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('flow-crlf-ret', 'Yes|Yes||');
        Observer.Expect('flow-crlf-json', '{"k":[["a","b"],{"x":"1"}]}');
        Observer.Expect('flow-crlf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TrailingLines_Read()
    begin
        ReadLf(Observer, 'nested-lf', 'a:~  b: 1~');
        ReadLf(Observer, 'nested-lflflf', 'a:~  b: 1~~~');
        ReadLf(Observer, 'list-lf', 'k:~  - a~  - b~');
        Observer.Expect('nested-lf-ret', 'Yes|Yes||');
        Observer.Expect('nested-lf-json', '{"a":{"b":"1"}}');
        Observer.Expect('nested-lf-stmt', 'Yes||');
        Observer.Expect('nested-lflflf-ret', 'Yes|Yes||');
        Observer.Expect('nested-lflflf-json', '{"a":{"b":"1"}}');
        Observer.Expect('nested-lflflf-stmt', 'Yes||');
        Observer.Expect('list-lf-ret', 'Yes|Yes||');
        Observer.Expect('list-lf-json', '{"k":["a","b"]}');
        Observer.Expect('list-lf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TrailingLinesCrLf_Read()
    begin
        ReadCrLf(Observer, 'nested-lf', 'a:~  b: 1~');
        ReadCrLf(Observer, 'list-lflf', 'k:~  - a~  - b~~');
        ReadCrLf(Observer, 'flat-lf', 'a: 1~b: 2~');
        Observer.Expect('nested-lf-crlf-ret', 'Yes|Yes||');
        Observer.Expect('nested-lf-crlf-json', '{"a":{"b":"1"}}');
        Observer.Expect('nested-lf-crlf-stmt', 'Yes||');
        Observer.Expect('list-lflf-crlf-ret', 'Yes|Yes||');
        Observer.Expect('list-lflf-crlf-json', '{"k":["a","b"]}');
        Observer.Expect('list-lflf-crlf-stmt', 'Yes||');
        Observer.Expect('flat-lf-crlf-ret', 'Yes|Yes||');
        Observer.Expect('flat-lf-crlf-json', '{"a":"1","b":"2"}');
        Observer.Expect('flat-lf-crlf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_SpacesOnlyLine_Read()
    begin
        ReadLf(Observer, 'list', 'k:~  - a~   ~  - b');
        ReadLf(Observer, 'nested', 'a:~  b: 1~  ~  c: 2');
        ReadLf(Observer, 'flat', 'a: 1~  ~b: 2');
        Observer.Expect('list-ret', 'Yes|Yes||');
        Observer.Expect('list-json', '{"k":["a","b"]}');
        Observer.Expect('list-stmt', 'Yes||');
        Observer.Expect('nested-ret', 'Yes|Yes||');
        Observer.Expect('nested-json', '{"a":{"b":"1","c":"2"}}');
        Observer.Expect('nested-stmt', 'Yes||');
        Observer.Expect('flat-ret', 'Yes|Yes||');
        Observer.Expect('flat-json', '{"a":"1","b":"2"}');
        Observer.Expect('flat-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_SpacesOnlyLineMore_Read()
    begin
        ReadCrLf(Observer, 'list', 'k:~  - a~   ~  - b');
        ReadLf(Observer, 'trailing', 'a:~  b: 1~    ');
        ReadLf(Observer, 'deep', 'a:~  b:~    c: 1~      ~    d: 2');
        Observer.Expect('list-crlf-ret', 'Yes|Yes||');
        Observer.Expect('list-crlf-json', '{"k":["a","b"]}');
        Observer.Expect('list-crlf-stmt', 'Yes||');
        Observer.Expect('trailing-ret', 'Yes|Yes||');
        Observer.Expect('trailing-json', '{"a":{"b":"1"}}');
        Observer.Expect('trailing-stmt', 'Yes||');
        Observer.Expect('deep-ret', 'Yes|Yes||');
        Observer.Expect('deep-json', '{"a":{"b":{"c":"1","d":"2"}}}');
        Observer.Expect('deep-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_FlowInBlockList_Read()
    begin
        ReadLf(Observer, 'flow', 'k:~  - [a, b]~  - {x: 1}');
        ReadLf(Observer, 'flow-blank', 'k:~  - [a, b]~~  - {x: 1}');
        ReadLf(Observer, 'flow-values', 'k: [a, b]~m: {x: 1, y: two words}');
        Observer.Expect('flow-ret', 'Yes|Yes||');
        Observer.Expect('flow-json', '{"k":[["a","b"],{"x":"1"}]}');
        Observer.Expect('flow-stmt', 'Yes||');
        Observer.Expect('flow-blank-ret', 'Yes|Yes||');
        Observer.Expect('flow-blank-json', '{"k":[["a","b"],{"x":"1"}]}');
        Observer.Expect('flow-blank-stmt', 'Yes||');
        Observer.Expect('flow-values-ret', 'Yes|Yes||');
        Observer.Expect('flow-values-json', '{"k":["a","b"],"m":{"x":"1","y":"two words"}}');
        Observer.Expect('flow-values-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_FlowInListItemMapping_Read()
    begin
        ReadLf(Observer, 'itemflow', 'k:~  - tags: [a, "b c"]~    opts: {x: 1}~~  - tags: []');
        ReadCrLf(Observer, 'itemflow', 'k:~  - tags: [a, "b c"]~    opts: {x: 1}~~  - tags: []');
        ReadLf(Observer, 'flow-quoted', 'k: ["x, y", ''z'']');
        Observer.Expect('itemflow-ret', 'Yes|Yes||');
        Observer.Expect('itemflow-json', '{"k":[{"tags":["a","b c"],"opts":{"x":"1"}},{"tags":[]}]}');
        Observer.Expect('itemflow-stmt', 'Yes||');
        Observer.Expect('itemflow-crlf-ret', 'Yes|Yes||');
        Observer.Expect('itemflow-crlf-json', '{"k":[{"tags":["a","b c"],"opts":{"x":"1"}},{"tags":[]}]}');
        Observer.Expect('itemflow-crlf-stmt', 'Yes||');
        Observer.Expect('flow-quoted-ret', 'Yes|Yes||');
        Observer.Expect('flow-quoted-json', '{"k":["x, y","z"]}');
        Observer.Expect('flow-quoted-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_LiteralBlockScalar_Read()
    begin
        ReadLf(Observer, 'literal', 'q: |~  line one~  line two~n: 1');
        ReadLf(Observer, 'literal-strip', 'q: |-~  line one~  line two~n: 1');
        ReadLf(Observer, 'literal-blank', 'q: |~  line one~~  line three~n: 1');
        Observer.Expect('literal-ret', 'Yes|Yes||');
        Observer.Expect('literal-json', '{"q":"line one\nline two\n","n":"1"}');
        Observer.Expect('literal-stmt', 'Yes||');
        Observer.Expect('literal-strip-ret', 'Yes|Yes||');
        Observer.Expect('literal-strip-json', '{"q":"line one\nline two","n":"1"}');
        Observer.Expect('literal-strip-stmt', 'Yes||');
        Observer.Expect('literal-blank-ret', 'Yes|Yes||');
        Observer.Expect('literal-blank-json', '{"q":"line one\n\nline three\n","n":"1"}');
        Observer.Expect('literal-blank-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_FoldedBlockScalar_Read()
    begin
        ReadLf(Observer, 'folded', 'q: >~  line one~  line two~n: 1');
        ReadLf(Observer, 'folded-strip', 'q: >-~  line one~  line two~n: 1');
        ReadLf(Observer, 'folded-blank', 'q: >~  line one~~  line three~n: 1');
        Observer.Expect('folded-ret', 'Yes|Yes||');
        Observer.Expect('folded-json', '{"q":"line one line two\n","n":"1"}');
        Observer.Expect('folded-stmt', 'Yes||');
        Observer.Expect('folded-strip-ret', 'Yes|Yes||');
        Observer.Expect('folded-strip-json', '{"q":"line one line two","n":"1"}');
        Observer.Expect('folded-strip-stmt', 'Yes||');
        Observer.Expect('folded-blank-ret', 'Yes|Yes||');
        Observer.Expect('folded-blank-json', '{"q":"line one\nline three\n","n":"1"}');
        Observer.Expect('folded-blank-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarEnd_Read()
    begin
        ReadLf(Observer, 'literal-last', 'q: |~  line one~  line two');
        ReadLf(Observer, 'literal-last-lf', 'q: |~  line one~  line two~');
        ReadCrLf(Observer, 'literal', 'q: |~  line one~  line two~n: 1');
        Observer.Expect('literal-last-ret', 'Yes|Yes||');
        Observer.Expect('literal-last-json', '{"q":"line one\nline two"}');
        Observer.Expect('literal-last-stmt', 'Yes||');
        Observer.Expect('literal-last-lf-ret', 'Yes|Yes||');
        Observer.Expect('literal-last-lf-json', '{"q":"line one\nline two\n"}');
        Observer.Expect('literal-last-lf-stmt', 'Yes||');
        Observer.Expect('literal-crlf-ret', 'Yes|Yes||');
        Observer.Expect('literal-crlf-json', '{"q":"line one\nline two\n","n":"1"}');
        Observer.Expect('literal-crlf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_BlockScalarInListItem_Read()
    begin
        ReadLf(Observer, 'item-literal', 'k:~  - q: |~      one~      two~    n: 1~~  - q: >-~      three~      four');
        ReadCrLf(Observer, 'item-literal', 'k:~  - q: |~      one~      two~    n: 1~~  - q: >-~      three~      four');
        Observer.Expect('item-literal-ret', 'Yes|Yes||');
        Observer.Expect('item-literal-json', '{"k":[{"q":"one\ntwo\n","n":"1"},{"q":"three four"}]}');
        Observer.Expect('item-literal-stmt', 'Yes||');
        Observer.Expect('item-literal-crlf-ret', 'Yes|Yes||');
        Observer.Expect('item-literal-crlf-json', '{"k":[{"q":"one\ntwo\n","n":"1"},{"q":"three four"}]}');
        Observer.Expect('item-literal-crlf-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_CommentsAndQuotes_Read()
    begin
        ReadLf(Observer, 'comment', '# head~a: 1 # tail~~# between~b: 2');
        ReadLf(Observer, 'quoted-key', '"Some Key": two words~''Other Key'': "x"');
        ReadLf(Observer, 'quoted-escapes', 'a: "say \"hi\"\nnext"~b: ''it''''s''');
        Observer.Expect('comment-ret', 'Yes|Yes||');
        Observer.Expect('comment-json', '{"a":"1","b":"2"}');
        Observer.Expect('comment-stmt', 'Yes||');
        Observer.Expect('quoted-key-ret', 'Yes|Yes||');
        Observer.Expect('quoted-key-json', '{"Some Key":"two words","Other Key":"x"}');
        Observer.Expect('quoted-key-stmt', 'Yes||');
        Observer.Expect('quoted-escapes-ret', 'Yes|Yes||');
        Observer.Expect('quoted-escapes-json', '{"a":"say \"hi\"\nnext","b":"it''s"}');
        Observer.Expect('quoted-escapes-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_ScalarForms_Read()
    begin
        ReadLf(Observer, 'numbers', 'a: 1.5~b: -3~c: 0010~d: 1e3');
        ReadLf(Observer, 'words', 'a: two words here~b: yes~c: ~~d: Null');
        ReadLf(Observer, 'special', 'a: http://x/y~b: x:y~c: "$Var-<CW+1M>$"');
        Observer.Expect('numbers-ret', 'Yes|Yes||');
        Observer.Expect('numbers-json', '{"a":"1.5","b":"-3","c":"0010","d":"1e3"}');
        Observer.Expect('numbers-stmt', 'Yes||');
        Observer.Expect('words-ret', 'Yes|Yes||');
        Observer.Expect('words-json', '{"a":"two words here","b":"yes","c":null,"d":null}');
        Observer.Expect('words-stmt', 'Yes||');
        Observer.Expect('special-ret', 'Yes|Yes||');
        Observer.Expect('special-json', '{"a":"http://x/y","b":"x:y","c":"$Var-<CW+1M>$"}');
        Observer.Expect('special-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DatasetDocument_Read()
    begin
        ReadLf(Observer, 'dataset', DatasetDoc());
        Observer.Expect('dataset-ret', 'Yes|Yes||');
        Observer.Expect('dataset-json', '{"name":"Demo dataset","language":"en-US","tests":[{"name":"First case","description":"Folded text on two lines","question":"Line one\nLine two\n","Expected Amount":"10","expected_data":{"lines":[{"Item No.":"1000","quantity":"2"},{"Item No.":"2000","quantity":"5"}]}},{"name":"Second case","description":"plain multi word value","question":"Only line","Expected Amount":"0","tags":["alpha","beta"],"options":{"mode":"fast","retries":"2"}}]}');
        Observer.Expect('dataset-stmt', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_DatasetDocumentCrLf_Read()
    begin
        ReadCrLf(Observer, 'dataset', DatasetDoc());
        Observer.Expect('dataset-crlf-ret', 'Yes|Yes||');
        Observer.Expect('dataset-crlf-json', '{"name":"Demo dataset","language":"en-US","tests":[{"name":"First case","description":"Folded text on two lines","question":"Line one\nLine two\n","Expected Amount":"10","expected_data":{"lines":[{"Item No.":"1000","quantity":"2"},{"Item No.":"2000","quantity":"5"}]}},{"name":"Second case","description":"plain multi word value","question":"Only line","Expected Amount":"0","tags":["alpha","beta"],"options":{"mode":"fast","retries":"2"}}]}');
        Observer.Expect('dataset-crlf-stmt', 'Yes||');
        Observer.Verify();
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
        Observer.Expect('read', 'Yes|Yes');
        Observer.Expect('has-tests', 'Yes');
        Observer.Expect('tests-is-array', 'Yes');
        Observer.Expect('tests-count', '2');
        Observer.Expect('q0-len', '18');
        Observer.Expect('q0-lf', '9');
        Observer.Expect('d0', 'Folded text on two lines');
        Observer.Expect('amount-is-value', 'Yes');
        Observer.Expect('amount', '10');
        Observer.Expect('name', 'Demo dataset');
        Observer.Verify();
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
