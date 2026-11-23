// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), YFN Yaml Support (codeunit 79894)
// Probe: AL Runner issue 8580, runner PR 8824. Directives (%YAML, %TAG, repeated, to the core prefix), anchor and alias
//   names, aliases as keys and as expansions, key lengths around the 1024 and 3000 character limits, tabs after
//   indentation spaces and inside flow collections, double-quoted escapes of surrogates and out-of-range code points,
//   the nesting depth limit, and a failed or successful read into a JsonObject that already has members.
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: documents are written with the tokens of JsonYamlFinalSupport.al. Most observations read 'document => result'.
//   Key length cells: 'ok' means the key was read with its full length. Depth cells: a string with one character per
//   nesting depth, '.' read, 'D' InvalidJsonData, 'B' YamlBadFormat, '?' anything else.
// BC versions: 27, 28, 29

codeunit 79897 "YFN Yaml Structure"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "YFN Yaml Support";

    local procedure Cells(Prefix: Text; D: List of [Text])
    var
        i: Integer;
    begin
        for i := 1 to D.Count() do
            Observer.Observe(Prefix + Format(i), D.Get(i) + ' => ' + Y.Both(D.Get(i), ''));
    end;

    local procedure KeyCell(Name: Text; Pre: Text; K: Text; Post: Text)
    begin
        Observer.Observe(Name, Y.TextOnly(Pre + K + Post, '{"' + K + '":"1"}'));
    end;

    local procedure DepthMark(Res: Text): Text
    begin
        if Res.StartsWith('{') then
            exit('.');
        if Res.StartsWith('FInvalidJsonData') then
            exit('D');
        if Res.StartsWith('FYamlBadFormat') then
            exit('B');
        exit('?');
    end;

    local procedure DepthDoc(Form: Integer; N: Integer): Text
    var
        Doc: TextBuilder;
        i: Integer;
    begin
        case Form of
            1:
                exit('q: ' + Y.Repeat('[', N) + 'x' + Y.Repeat(']', N));
            2:
                exit('q: ' + Y.Repeat('{a: ', N) + 'x' + Y.Repeat('}', N));
            3:
                exit('k:~' + Y.Repeat('- ', N) + 'x');
            4:
                begin
                    for i := 1 to N do
                        Doc.Append(Y.Repeat(' ', i - 1) + 'a:' + Y.Chr(10));
                    Doc.Append(Y.Repeat(' ', N) + 'x: 1');
                    exit(Doc.ToText());
                end;
            5:
                exit('q: ' + Y.Repeat('[{a: ', N div 2) + 'x' + Y.Repeat('}]', N div 2));
        end;
    end;

    local procedure DepthSweep(Name: Text; Form: Integer; From: Integer; "To": Integer)
    var
        N: Integer;
        Marks: Text;
    begin
        for N := From to "To" do
            Marks += DepthMark(Y.TextOnly(DepthDoc(Form, N), ''));
        Observer.Observe(Name + '-' + Format(From) + 'to' + Format("To"), Marks);
    end;

    local procedure DepthAt(Name: Text; Form: Integer; N: Integer)
    begin
        Observer.Observe(Name + '-' + Format(N), Y.Both(DepthDoc(Form, N), ''));
    end;

    [Test]
    procedure ReadFromYaml_Directives_1()
    var
        D: List of [Text];
    begin
        D.AddRange('%YAML 1.1~---~q: 1',
            '%YAML 1.2~---~q: 1',
            '%YAML 1.2~%YAML 1.2~---~q: 1',
            '%YAML 1.1~%YAML 1.2~---~q: 1',
            '%YAML 1.0~---~q: 1',
            '%YAML 2.0~---~q: 1',
            '%YAML 1~---~q: 1',
            '%YAML 1.10~---~q: 1',
            '%YAML 1.2 #c~---~q: 1',
            '%YAML 1.2 x~---~q: 1',
            '%YAML~---~q: 1',
            '%FOO bar~---~q: 1',
            '%TAG !! tag:yaml.org,2002:~---~q: !!int 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!int 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!str 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!bool yes',
            '%TAG ! tag:yaml.org,2002:~---~q: !int 1',
            '%TAG !! tag:example.com,2000:~---~q: !!int 1',
            '%TAG !! tag:example.com,2000:~---~q: !!str 1',
            '%TAG ! tag:example.com,2000:~---~q: !x 1',
            '%TAG !e! tag:yaml.org,2002:~%TAG !e! tag:yaml.org,2002:~---~q: !e!int 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !f!int 1',
            'q: !e!int 1',
            '%TAG !e! tag:example.com,2000:~---~q: !e!x 1');
        Cells('Directives1_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Directives_2()
    var
        D: List of [Text];
    begin
        D.AddRange('%YAML 1.1~---~q: yes',
            '%YAML 1.1~---~q: [yes, on, 0x1F, 010, 1_000, 0b11, 1:30]',
            '%YAML 1.2~---~q: [yes, on, 0x1F, 010, 1_000, 0b11, 1:30]',
            '%YAML 1.1~---~q: !!int 010',
            '%YAML 1.1~---~q: !!bool yes',
            '%YAML 1.1~---~q: !!int 0x1F',
            '%YAML 1.1~---~q: !!int +5',
            '%YAML 1.1~q: 1',
            '%YAML 1.1~---',
            '%YAML 1.1',
            '---~%YAML 1.1~q: 1',
            '%YAML 1.1~---~q: 1~...',
            '%YAML 1.1~---~q: 1~...~---~n: 2',
            '%YAML 1.1~---~q: 1~...~%YAML 1.1~---~n: 2',
            '%YAML 1.3~---~q: 1',
            '%YAML 1.1 ~---~q: 1',
            '%YAML{T}1.1~---~q: 1',
            '%YAML 1.1~~---~q: 1',
            '# c~%YAML 1.1~---~q: 1');
        Cells('Directives2_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_AnchorNames_1()
    var
        D: List of [Text];
    begin
        D.AddRange('a: &a.b 1~b: *a.b',
            'a: &{u00E9} 1~b: *{u00E9}',
            'a: &a-b 1~b: *a-b',
            'a: &- 1~b: *-',
            'a: &1 1~b: *1',
            'a: &a_b 1~b: *a_b',
            'a: &a/b 1~b: *a/b',
            'a: &a:b 1~b: *a:b',
            'a: &{u00E4}1 1~b: *{u00E4}1',
            'a: &{u4E2D} 1~b: *{u4E2D}',
            'a: &{uD83D}{uDE00} 1~b: *{uD83D}{uDE00}',
            'a: &a#b 1~b: *a#b',
            'a: &a''''b 1~b: *a''''b',
            'a: &a"b 1~b: *a"b',
            'a: &a%b 1~b: *a%b',
            'a: &a@b 1~b: *a@b',
            'a: &a!b 1~b: *a!b',
            'a: &a$b 1~b: *a$b',
            'a: &a*b 1~b: *a*b',
            'a: &a&b 1~b: *a&b');
        Cells('AnchorNames1_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_AnchorNames_2()
    var
        D: List of [Text];
    begin
        D.AddRange('a: &a=b 1~b: *a=b',
            'a: &a+b 1~b: *a+b',
            'a: &a{~}b 1~b: *a{~}b',
            'a: &a|b 1~b: *a|b',
            'a: &a>b 1~b: *a>b',
            'a: &a?b 1~b: *a?b',
            'a: &a{u005E}b 1~b: *a{u005E}b',
            'a: &a(b) 1~b: *a(b)',
            'a: &a;b 1~b: *a;b',
            'a: &a<b 1~b: *a<b',
            'a: &A{u00DF} 1~b: *A{u00DF}');
        Cells('AnchorNames2_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Aliases_1()
    var
        D: List of [Text];
    begin
        D.AddRange('a: &x 1~a: &x 2~b: *x',
            'b: *x~a: &x 1',
            'a: *zz',
            'a: &x~b: *x',
            '&a x: 1~*a : 2',
            'm: &m~  x: 1~*m : b',
            'm: &m [a]~*m : b',
            'm: &m {a: 1}~? *m~: b',
            'a: &x 1~? *x~: 2',
            'a: &x [1]~[*x]: 2',
            'q: [&a x, *a]',
            'a: &x !!int 1~b: *x',
            'a: !!int &x 1~b: *x',
            'a: &x [1, 2]~b: *x~c: *x',
            'a: &x {k: v}~b: *x',
            'a: &x~  - 1~b: *x',
            'a: &x 1~b: &y *x~c: *y',
            'a: &x 1~b: [*x, *x]',
            'a: &x 1~b: {c: *x}',
            'a: &x 1~*x : b',
            'a: &x 1~b: *x~*x : c',
            'a: &x 1~b: "*x"',
            'a: &x 1~b: *x x',
            'a: &x 1~b: * x',
            'a: & x');
        Cells('Aliases1_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Aliases_2()
    var
        D: List of [Text];
    begin
        D.AddRange('a: &',
            'a: *',
            '&x a: 1~b: *x',
            '&x ~q: 1',
            '&x q: 1~r: *x',
            'a: &x 1~<<: *x',
            'a: &x {b: 1}~<<: *x');
        Cells('Aliases2_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Laughs()
    begin
        Observer.Observe('lol3', Y.LengthOnly(Laughs(3)));
        Observer.Observe('lol4', Y.LengthOnly(Laughs(4)));
        Observer.Observe('lol5', Y.LengthOnly(Laughs(5)));
        Observer.Finish();
    end;

    local procedure Laughs(Levels: Integer): Text
    var
        Doc: TextBuilder;
        i: Integer;
        Prev: Text;
        Cur: Text;
    begin
        Doc.Append('l0: &l0 [x, x, x, x, x, x, x, x, x]' + Y.Chr(10));
        for i := 1 to Levels - 1 do begin
            Prev := '*l' + Format(i - 1);
            Doc.Append('l' + Format(i) + ': &l' + Format(i) + ' [' + Prev + ', ' + Prev + ', ' + Prev + ', ' + Prev + ', ' + Prev + ', ' + Prev + ', ' + Prev + ', ' + Prev + ', ' + Prev + ']' + Y.Chr(10));
        end;
        exit(Doc.ToText());
    end;

    [Test]
    procedure ReadFromYaml_KeyLength_Plain()
    var
        L: List of [Integer];
        N: Integer;
    begin
        L.AddRange(1, 1000, 1023, 1024, 1025, 1026, 1100, 1500, 2000, 2047, 2048, 2049, 2999, 3000, 3001, 5000);
        foreach N in L do
            KeyCell('plain-' + Format(N), '', Y.Repeat('k', N), ': 1');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_KeyLength_Forms()
    var
        L: List of [Integer];
        N: Integer;
    begin
        L.AddRange(1023, 1024, 1025, 3000);
        foreach N in L do begin
            KeyCell('single-' + Format(N), '''', Y.Repeat('k', N), ''': 1');
            KeyCell('double-' + Format(N), '"', Y.Repeat('k', N), '": 1');
            KeyCell('nested-' + Format(N), 'o:~  ', Y.Repeat('k', N), ': 1');
            KeyCell('listitem-' + Format(N), 'k:~  - ', Y.Repeat('k', N), ': 1');
            KeyCell('flow-' + Format(N), '{', Y.Repeat('k', N), ': 1}');
            KeyCell('explicit-' + Format(N), '? ', Y.Repeat('k', N), '~: 1');
        end;
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_KeyLength_Layout()
    begin
        Observer.Observe('spaces-before-colon-1100', Y.TextOnly('a' + Y.Repeat('{S}', 1100) + ': 1', '{"a":"1"}'));
        Observer.Observe('spaces-before-colon-100', Y.TextOnly('a' + Y.Repeat('{S}', 100) + ': 1', '{"a":"1"}'));
        Observer.Observe('value-on-next-line-1025', Y.TextOnly(Y.Repeat('k', 1025) + ':~  1', ''));
        Observer.Observe('two-keys-1025', Y.TextOnly(Y.Repeat('k', 1025) + ': 1~' + Y.Repeat('j', 1025) + ': 2', ''));
        Observer.Observe('value-1025', Y.TextOnly('k: ' + Y.Repeat('v', 1025), ''));
        Observer.Observe('emoji-key-512', Y.TextOnly(Y.Repeat('{uD83D}{uDE00}', 512) + ': 1', ''));
        Observer.Observe('emoji-key-513', Y.TextOnly(Y.Repeat('{uD83D}{uDE00}', 513) + ': 1', ''));
        Observer.Observe('emoji-key-600', Y.TextOnly(Y.Repeat('{uD83D}{uDE00}', 600) + ': 1', ''));
        Observer.Observe('emoji-key-1600', Y.TextOnly(Y.Repeat('{uD83D}{uDE00}', 1600) + ': 1', ''));
        Observer.Observe('auml-key-1025', Y.TextOnly(Y.Repeat('{u00E4}', 1025) + ': 1', ''));
        Observer.Observe('auml-key-1024', Y.TextOnly(Y.Repeat('{u00E4}', 1024) + ': 1', ''));
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Tabs_1()
    var
        D: List of [Text];
    begin
        D.AddRange('  {T}q: a',
            ' {T}q: a',
            '{T} q: a',
            '{T}q: a',
            'o:~  {T}q: a',
            'o:~  q: a~  {T}r: b',
            'q: [a,~{T}b]',
            'q: [a,~  {T}b]',
            'q: [a,~ {T}b]',
            'q: {a: 1,~{T}b: 2}',
            'q: "a~{T}b"',
            'q: ''a~{T}b''',
            'q: a~{T}b',
            'q: |~  a~{T}b',
            'q: |~  a~  {T}b',
            'q: |~{T}a',
            'q: >~  a~ {T}b',
            'k:~  - a~  {T}- b',
            '# c~{T}q: a',
            '{T}# c~q: a');
        Cells('Tabs1_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Tabs_2()
    var
        D: List of [Text];
    begin
        D.AddRange('  {T}# c~q: a',
            '~{T}~q: a',
            'q: a~{T}~n: 1',
            'q: a~  {T}~n: 1',
            '---~{T}q: a',
            '---{T}~q: a',
            '--- {T}q: a',
            'q:{T}{T}a',
            'q: a #{T}c',
            'q: a{T}#c',
            'q: [{T}a]',
            'q: [a{T}]',
            'q: [a,{T}b]',
            'q: {{T}a: 1}',
            'k:~  - [a,~  {T}b]',
            '  {T}- a',
            '{T}- a',
            '  {T}k:~  - a',
            'q: [~{T}a]',
            'q: "a{T}b"');
        Cells('Tabs2_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_EscapeSurrogates_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: "{\}uD800"',
            'q: "{\}uDBFF"',
            'q: "{\}uDC00"',
            'q: "{\}uDFFF"',
            'q: "{\}uD83D{\}uDE00"',
            'q: "{\}uD83D"',
            'q: "{\}uD83Dx"',
            'q: "{\}uDE00{\}uD83D"',
            'q: "{\}U0001F600"',
            'q: "{\}U00110000"',
            'q: "{\}U0010FFFF"',
            'q: "{\}U0000D800"',
            'q: "{\}U00000041"',
            'q: "{\}u0041"',
            'q: "{\}uFFFE"',
            'q: "{\}uFFFF"',
            'q: "{\}uFDD0"',
            'q: "{\}u0000"',
            'q: "{\}u0001"',
            'q: "{\}u007F"',
            'q: "{\}u0085"',
            'q: "{\}u2028"',
            'q: "{\}u2029"',
            'q: "{\}uFEFF"',
            'q: "{\}U0000FFFE"');
        Cells('EscapeSurrogates1_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_EscapeSurrogates_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: "{\}UFFFFFFFF"',
            'q: "{\}U7FFFFFFF"',
            'q: "{\}U00200000"',
            'q: "{\}x7F"',
            'q: "{\}x85"',
            'q: "{\}xFF"',
            'q: "{\}x00"',
            'q: "{\}x01"');
        Cells('EscapeSurrogates2_', D);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_FailedRead()
    begin
        Observer.Observe('valid', Y.ReadInto('q: 1', '{"pre":1}'));
        Observer.Observe('valid-same-key', Y.ReadInto('pre: 2', '{"pre":1}'));
        Observer.Observe('valid-nested-pre', Y.ReadInto('q: 1', '{"pre":{"x":1}}'));
        Observer.Observe('invalid-flow', Y.ReadInto('q: [', '{"pre":1}'));
        Observer.Observe('invalid-colon', Y.ReadInto('q: a: b', '{"pre":1}'));
        Observer.Observe('top-list', Y.ReadInto('- a', '{"pre":1}'));
        Observer.Observe('empty', Y.ReadInto('', '{"pre":1}'));
        Observer.Observe('null-top', Y.ReadInto('{~}', '{"pre":1}'));
        Observer.Observe('scalar-top', Y.ReadInto('abc', '{"pre":1}'));
        Observer.Observe('two-docs', Y.ReadInto('a: 1~---~b: 2', '{"pre":1}'));
        Observer.Observe('partial-then-error', Y.ReadInto('a: 1~b: [', '{"pre":1}'));
        Observer.Observe('undefined-alias', Y.ReadInto('a: 1~b: *zz', '{"pre":1}'));
        Observer.Observe('depth-too-deep', Y.ReadInto('q: ' + Y.Repeat('[', 100) + 'x' + Y.Repeat(']', 100), '{"pre":1}'));
        Observer.Observe('bad-escape', Y.ReadInto('q: "{\}q"', '{"pre":1}'));
        Observer.Observe('unmeasured-char-lone', Y.ReadInto('q: a{uD800}b', '{"pre":1}'));
        Observer.Observe('empty-object', Y.ReadInto('q: [', '{}'));
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Depth_Sweep()
    begin
        DepthSweep('flowseq', 1, 40, 110);
        DepthSweep('flowmap', 2, 40, 110);
        DepthSweep('blockseq', 3, 40, 110);
        DepthSweep('blockmap', 4, 40, 110);
        DepthSweep('mixed', 5, 40, 110);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Depth_Far()
    begin
        DepthAt('flowseq', 1, 150);
        DepthAt('flowseq', 1, 200);
        DepthAt('flowseq', 1, 300);
        DepthAt('flowseq', 1, 301);
        DepthAt('flowseq', 1, 302);
        DepthAt('flowseq', 1, 400);
        DepthAt('blockseq', 3, 150);
        DepthAt('blockseq', 3, 301);
        DepthAt('blockseq', 3, 400);
        DepthAt('blockmap', 4, 150);
        DepthAt('blockmap', 4, 301);
        DepthAt('blockmap', 4, 400);
        DepthAt('flowmap', 2, 301);
        Observer.Finish();
    end;
}
