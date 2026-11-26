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
                exit('q: ' + Y.Rep('[', N) + 'x' + Y.Rep(']', N));
            2:
                exit('q: ' + Y.Rep('{a: ', N) + 'x' + Y.Rep('}', N));
            3:
                exit('k:~' + Y.Rep('- ', N) + 'x');
            4:
                begin
                    for i := 1 to N do
                        Doc.Append(Y.Rep(' ', i - 1) + 'a:' + Y.Chr(10));
                    Doc.Append(Y.Rep(' ', N) + 'x: 1');
                    exit(Doc.ToText());
                end;
            5:
                exit('q: ' + Y.Rep('[{a: ', N div 2) + 'x' + Y.Rep('}]', N div 2));
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
        Observer.Expect('Directives1_1', '%YAML 1.1~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives1_2', '%YAML 1.2~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives1_3', '%YAML 1.2~%YAML 1.2~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_4', '%YAML 1.1~%YAML 1.2~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_5', '%YAML 1.0~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives1_6', '%YAML 2.0~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_7', '%YAML 1~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_8', '%YAML 1.10~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_9', '%YAML 1.2 #c~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives1_10', '%YAML 1.2 x~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_11', '%YAML~---~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives1_12', '%FOO bar~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives1_13', '%TAG !! tag:yaml.org,2002:~---~q: !!int 1 => {"q":1}');
        Observer.Expect('Directives1_14', '%TAG !e! tag:yaml.org,2002:~---~q: !e!int 1 => {"q":1}');
        Observer.Expect('Directives1_15', '%TAG !e! tag:yaml.org,2002:~---~q: !e!str 1 => {"q":"1"}');
        Observer.Expect('Directives1_16', '%TAG !e! tag:yaml.org,2002:~---~q: !e!bool yes => {"q":true}');
        Observer.Expect('Directives1_17', '%TAG ! tag:yaml.org,2002:~---~q: !int 1 => {"q":1}');
        Observer.Expect('Directives1_18', '%TAG !! tag:example.com,2000:~---~q: !!int 1 => FYamlBadFormat');
        Observer.Expect('Directives1_19', '%TAG !! tag:example.com,2000:~---~q: !!str 1 => FYamlBadFormat');
        Observer.Expect('Directives1_20', '%TAG ! tag:example.com,2000:~---~q: !x 1 => FYamlBadFormat');
        Observer.Expect('Directives1_21', '%TAG !e! tag:yaml.org,2002:~%TAG !e! tag:yaml.org,2002:~---~q: !e!int 1 => FYamlBadFormat');
        Observer.Expect('Directives1_22', '%TAG !e! tag:yaml.org,2002:~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives1_23', '%TAG !e! tag:yaml.org,2002:~---~q: !f!int 1 => FYamlBadFormat');
        Observer.Expect('Directives1_24', 'q: !e!int 1 => FYamlBadFormat');
        Observer.Expect('Directives1_25', '%TAG !e! tag:example.com,2000:~---~q: !e!x 1 => FYamlBadFormat');
        Observer.Verify();
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
        Observer.Expect('Directives2_1', '%YAML 1.1~---~q: yes => {"q":"yes"}');
        Observer.Expect('Directives2_2', '%YAML 1.1~---~q: [yes, on, 0x1F, 010, 1_000, 0b11, 1:30] => {"q":["yes","on","0x1F","010","1_000","0b11","1:30"]}');
        Observer.Expect('Directives2_3', '%YAML 1.2~---~q: [yes, on, 0x1F, 010, 1_000, 0b11, 1:30] => {"q":["yes","on","0x1F","010","1_000","0b11","1:30"]}');
        Observer.Expect('Directives2_4', '%YAML 1.1~---~q: !!int 010 => {"q":8}');
        Observer.Expect('Directives2_5', '%YAML 1.1~---~q: !!bool yes => {"q":true}');
        Observer.Expect('Directives2_6', '%YAML 1.1~---~q: !!int 0x1F => {"q":31}');
        Observer.Expect('Directives2_7', '%YAML 1.1~---~q: !!int +5 => {"q":5}');
        Observer.Expect('Directives2_8', '%YAML 1.1~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives2_9', '%YAML 1.1~--- => FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('Directives2_10', '%YAML 1.1 => FYamlBadFormat');
        Observer.Expect('Directives2_11', '---~%YAML 1.1~q: 1 => FYamlBadFormat');
        Observer.Expect('Directives2_12', '%YAML 1.1~---~q: 1~... => {"q":"1"}');
        Observer.Expect('Directives2_13', '%YAML 1.1~---~q: 1~...~---~n: 2 => FYamlBadFormat');
        Observer.Expect('Directives2_14', '%YAML 1.1~---~q: 1~...~%YAML 1.1~---~n: 2 => FYamlBadFormat');
        Observer.Expect('Directives2_15', '%YAML 1.3~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives2_16', '%YAML 1.1 ~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives2_17', '%YAML{T}1.1~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives2_18', '%YAML 1.1~~---~q: 1 => {"q":"1"}');
        Observer.Expect('Directives2_19', '# c~%YAML 1.1~---~q: 1 => {"q":"1"}');
        Observer.Verify();
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
        Observer.Expect('AnchorNames1_1', 'a: &a.b 1~b: *a.b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_2', 'a: &{u00E9} 1~b: *{u00E9} => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_3', 'a: &a-b 1~b: *a-b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_4', 'a: &- 1~b: *- => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_5', 'a: &1 1~b: *1 => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_6', 'a: &a_b 1~b: *a_b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_7', 'a: &a/b 1~b: *a/b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_8', 'a: &a:b 1~b: *a:b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_9', 'a: &{u00E4}1 1~b: *{u00E4}1 => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_10', 'a: &{u4E2D} 1~b: *{u4E2D} => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_11', 'a: &{uD83D}{uDE00} 1~b: *{uD83D}{uDE00} => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_12', 'a: &a#b 1~b: *a#b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_13', 'a: &a''''b 1~b: *a''''b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_14', 'a: &a"b 1~b: *a"b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_15', 'a: &a%b 1~b: *a%b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_16', 'a: &a@b 1~b: *a@b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_17', 'a: &a!b 1~b: *a!b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_18', 'a: &a$b 1~b: *a$b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_19', 'a: &a*b 1~b: *a*b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames1_20', 'a: &a&b 1~b: *a&b => {"a":"1","b":"1"}');
        Observer.Verify();
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
        Observer.Expect('AnchorNames2_1', 'a: &a=b 1~b: *a=b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_2', 'a: &a+b 1~b: *a+b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_3', 'a: &a{~}b 1~b: *a{~}b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_4', 'a: &a|b 1~b: *a|b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_5', 'a: &a>b 1~b: *a>b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_6', 'a: &a?b 1~b: *a?b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_7', 'a: &a{u005E}b 1~b: *a{u005E}b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_8', 'a: &a(b) 1~b: *a(b) => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_9', 'a: &a;b 1~b: *a;b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_10', 'a: &a<b 1~b: *a<b => {"a":"1","b":"1"}');
        Observer.Expect('AnchorNames2_11', 'a: &A{u00DF} 1~b: *A{u00DF} => {"a":"1","b":"1"}');
        Observer.Verify();
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
        Observer.Expect('Aliases1_1', 'a: &x 1~a: &x 2~b: *x => {"a":"2","b":"2"}');
        Observer.Expect('Aliases1_2', 'b: *x~a: &x 1 => FYamlBadFormat');
        Observer.Expect('Aliases1_3', 'a: *zz => FYamlBadFormat');
        Observer.Expect('Aliases1_4', 'a: &x~b: *x => {"a":null,"b":null}');
        Observer.Expect('Aliases1_5', '&a x: 1~*a : 2 => {"x":"2"}');
        Observer.Expect('Aliases1_6', 'm: &m~  x: 1~*m : b => {"m":{"x":"1"},"(Collection)":"b"}');
        Observer.Expect('Aliases1_7', 'm: &m [a]~*m : b => {"m":["a"],"(Collection)":"b"}');
        Observer.Expect('Aliases1_8', 'm: &m {a: 1}~? *m~: b => {"m":{"a":"1"},"(Collection)":"b"}');
        Observer.Expect('Aliases1_9', 'a: &x 1~? *x~: 2 => {"a":"1","1":"2"}');
        Observer.Expect('Aliases1_10', 'a: &x [1]~[*x]: 2 => {"a":["1"],"(Collection)":"2"}');
        Observer.Expect('Aliases1_11', 'q: [&a x, *a] => {"q":["x","x"]}');
        Observer.Expect('Aliases1_12', 'a: &x !!int 1~b: *x => {"a":1,"b":1}');
        Observer.Expect('Aliases1_13', 'a: !!int &x 1~b: *x => {"a":1,"b":1}');
        Observer.Expect('Aliases1_14', 'a: &x [1, 2]~b: *x~c: *x => {"a":["1","2"],"b":["1","2"],"c":["1","2"]}');
        Observer.Expect('Aliases1_15', 'a: &x {k: v}~b: *x => {"a":{"k":"v"},"b":{"k":"v"}}');
        Observer.Expect('Aliases1_16', 'a: &x~  - 1~b: *x => {"a":["1"],"b":["1"]}');
        Observer.Expect('Aliases1_17', 'a: &x 1~b: &y *x~c: *y => FYamlBadFormat');
        Observer.Expect('Aliases1_18', 'a: &x 1~b: [*x, *x] => {"a":"1","b":["1","1"]}');
        Observer.Expect('Aliases1_19', 'a: &x 1~b: {c: *x} => {"a":"1","b":{"c":"1"}}');
        Observer.Expect('Aliases1_20', 'a: &x 1~*x : b => {"a":"1","1":"b"}');
        Observer.Expect('Aliases1_21', 'a: &x 1~b: *x~*x : c => {"a":"1","b":"1","1":"c"}');
        Observer.Expect('Aliases1_22', 'a: &x 1~b: "*x" => {"a":"1","b":"*x"}');
        Observer.Expect('Aliases1_23', 'a: &x 1~b: *x x => FYamlBadFormat');
        Observer.Expect('Aliases1_24', 'a: &x 1~b: * x => FYamlBadFormat');
        Observer.Expect('Aliases1_25', 'a: & x => FYamlBadFormat');
        Observer.Verify();
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
        Observer.Expect('Aliases2_1', 'a: & => FYamlBadFormat');
        Observer.Expect('Aliases2_2', 'a: * => FYamlBadFormat');
        Observer.Expect('Aliases2_3', '&x a: 1~b: *x => {"a":"1","b":"a"}');
        Observer.Expect('Aliases2_4', '&x ~q: 1 => {"q":"1"}');
        Observer.Expect('Aliases2_5', '&x q: 1~r: *x => {"q":"1","r":"q"}');
        Observer.Expect('Aliases2_6', 'a: &x 1~<<: *x => {"a":"1","<<":"1"}');
        Observer.Expect('Aliases2_7', 'a: &x {b: 1}~<<: *x => {"a":{"b":"1"},"<<":{"b":"1"}}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Laughs()
    begin
        Observer.Observe('lol3', Y.LengthOnly(Laughs(3)));
        Observer.Observe('lol4', Y.LengthOnly(Laughs(4)));
        Observer.Observe('lol5', Y.LengthOnly(Laughs(5)));
        Observer.Expect('lol3', 'len=3496');
        Observer.Expect('lol4', 'len=31385');
        Observer.Expect('lol5', 'len=282348');
        Observer.Verify();
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
            KeyCell('plain-' + Format(N), '', Y.Rep('k', N), ': 1');
        Observer.Expect('plain-1', 'ok');
        Observer.Expect('plain-1000', 'ok');
        Observer.Expect('plain-1023', 'ok');
        Observer.Expect('plain-1024', 'ok');
        Observer.Expect('plain-1025', 'FYamlBadFormat');
        Observer.Expect('plain-1026', 'FYamlBadFormat');
        Observer.Expect('plain-1100', 'FYamlBadFormat');
        Observer.Expect('plain-1500', 'FYamlBadFormat');
        Observer.Expect('plain-2000', 'FYamlBadFormat');
        Observer.Expect('plain-2047', 'FYamlBadFormat');
        Observer.Expect('plain-2048', 'FYamlBadFormat');
        Observer.Expect('plain-2049', 'FYamlBadFormat');
        Observer.Expect('plain-2999', 'FYamlBadFormat');
        Observer.Expect('plain-3000', 'FYamlBadFormat');
        Observer.Expect('plain-3001', 'FYamlBadFormat');
        Observer.Expect('plain-5000', 'FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_KeyLength_Forms()
    var
        L: List of [Integer];
        N: Integer;
    begin
        L.AddRange(1023, 1024, 1025, 3000);
        foreach N in L do begin
            KeyCell('single-' + Format(N), '''', Y.Rep('k', N), ''': 1');
            KeyCell('double-' + Format(N), '"', Y.Rep('k', N), '": 1');
            KeyCell('nested-' + Format(N), 'o:~  ', Y.Rep('k', N), ': 1');
            KeyCell('listitem-' + Format(N), 'k:~  - ', Y.Rep('k', N), ': 1');
            KeyCell('flow-' + Format(N), '{', Y.Rep('k', N), ': 1}');
            KeyCell('explicit-' + Format(N), '? ', Y.Rep('k', N), '~: 1');
        end;
        Observer.Expect('single-1023', 'FYamlBadFormat');
        Observer.Expect('double-1023', 'FYamlBadFormat');
        Observer.Expect('nested-1023', '{"o":{"kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk len=1037');
        Observer.Expect('listitem-1023', '{"k":[{"kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk len=1039');
        Observer.Expect('flow-1023', 'ok');
        Observer.Expect('explicit-1023', 'ok');
        Observer.Expect('single-1024', 'FYamlBadFormat');
        Observer.Expect('double-1024', 'FYamlBadFormat');
        Observer.Expect('nested-1024', '{"o":{"kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk len=1038');
        Observer.Expect('listitem-1024', '{"k":[{"kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk len=1040');
        Observer.Expect('flow-1024', 'ok');
        Observer.Expect('explicit-1024', 'ok');
        Observer.Expect('single-1025', 'FYamlBadFormat');
        Observer.Expect('double-1025', 'FYamlBadFormat');
        Observer.Expect('nested-1025', 'FYamlBadFormat');
        Observer.Expect('listitem-1025', 'FYamlBadFormat');
        Observer.Expect('flow-1025', 'ok');
        Observer.Expect('explicit-1025', 'ok');
        Observer.Expect('single-3000', 'FYamlBadFormat');
        Observer.Expect('double-3000', 'FYamlBadFormat');
        Observer.Expect('nested-3000', 'FYamlBadFormat');
        Observer.Expect('listitem-3000', 'FYamlBadFormat');
        Observer.Expect('flow-3000', 'ok');
        Observer.Expect('explicit-3000', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_KeyLength_Layout()
    begin
        Observer.Observe('spaces-before-colon-1100', Y.TextOnly('a' + Y.Rep('{S}', 1100) + ': 1', '{"a":"1"}'));
        Observer.Observe('spaces-before-colon-100', Y.TextOnly('a' + Y.Rep('{S}', 100) + ': 1', '{"a":"1"}'));
        Observer.Observe('value-on-next-line-1025', Y.TextOnly(Y.Rep('k', 1025) + ':~  1', ''));
        Observer.Observe('two-keys-1025', Y.TextOnly(Y.Rep('k', 1025) + ': 1~' + Y.Rep('j', 1025) + ': 2', ''));
        Observer.Observe('value-1025', Y.TextOnly('k: ' + Y.Rep('v', 1025), ''));
        Observer.Observe('emoji-key-512', Y.TextOnly(Y.Rep('{uD83D}{uDE00}', 512) + ': 1', ''));
        Observer.Observe('emoji-key-513', Y.TextOnly(Y.Rep('{uD83D}{uDE00}', 513) + ': 1', ''));
        Observer.Observe('emoji-key-600', Y.TextOnly(Y.Rep('{uD83D}{uDE00}', 600) + ': 1', ''));
        Observer.Observe('emoji-key-1600', Y.TextOnly(Y.Rep('{uD83D}{uDE00}', 1600) + ': 1', ''));
        Observer.Observe('auml-key-1025', Y.TextOnly(Y.Rep('{u00E4}', 1025) + ': 1', ''));
        Observer.Observe('auml-key-1024', Y.TextOnly(Y.Rep('{u00E4}', 1024) + ': 1', ''));
        Observer.Expect('spaces-before-colon-1100', 'FYamlBadFormat');
        Observer.Expect('spaces-before-colon-100', 'ok');
        Observer.Expect('value-on-next-line-1025', 'FYamlBadFormat');
        Observer.Expect('two-keys-1025', 'FYamlBadFormat');
        Observer.Expect('value-1025', '{"k":"vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv len=1033');
        Observer.Expect('emoji-key-512', '{"<U+D83D><U+DE00><U+D83D><U+DE00><U+D83D><U+DE00><U+D83D><U+DE00><U+D83D><U+DE00><U+D83D><U+DE00><U len=8200');
        Observer.Expect('emoji-key-513', 'FYamlBadFormat');
        Observer.Expect('emoji-key-600', 'FYamlBadFormat');
        Observer.Expect('emoji-key-1600', 'FYamlBadFormat');
        Observer.Expect('auml-key-1025', 'FYamlBadFormat');
        Observer.Expect('auml-key-1024', '{"<U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U+00E4><U len=8200');
        Observer.Verify();
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
        Observer.Expect('Tabs1_1', '  {T}q: a => {"q":"a"}');
        Observer.Expect('Tabs1_2', ' {T}q: a => {"q":"a"}');
        Observer.Expect('Tabs1_3', '{T} q: a => {"q":"a"}');
        Observer.Expect('Tabs1_4', '{T}q: a => {"q":"a"}');
        Observer.Expect('Tabs1_5', 'o:~  {T}q: a => {"o":{"q":"a"}}');
        Observer.Expect('Tabs1_6', 'o:~  q: a~  {T}r: b => FYamlBadFormat');
        Observer.Expect('Tabs1_7', 'q: [a,~{T}b] => {"q":["a","b"]}');
        Observer.Expect('Tabs1_8', 'q: [a,~  {T}b] => {"q":["a","b"]}');
        Observer.Expect('Tabs1_9', 'q: [a,~ {T}b] => {"q":["a","b"]}');
        Observer.Expect('Tabs1_10', 'q: {a: 1,~{T}b: 2} => {"q":{"a":"1","b":"2"}}');
        Observer.Expect('Tabs1_11', 'q: "a~{T}b" => {"q":"a b"}');
        Observer.Expect('Tabs1_12', 'q: ''a~{T}b'' => {"q":"a b"}');
        Observer.Expect('Tabs1_13', 'q: a~{T}b => FYamlBadFormat');
        Observer.Expect('Tabs1_14', 'q: |~  a~{T}b => FYamlBadFormat');
        Observer.Expect('Tabs1_15', 'q: |~  a~  {T}b => {"q":"a\n\tb"}');
        Observer.Expect('Tabs1_16', 'q: |~{T}a => FYamlBadFormat');
        Observer.Expect('Tabs1_17', 'q: >~  a~ {T}b => FYamlBadFormat');
        Observer.Expect('Tabs1_18', 'k:~  - a~  {T}- b => FYamlBadFormat');
        Observer.Expect('Tabs1_19', '# c~{T}q: a => {"q":"a"}');
        Observer.Expect('Tabs1_20', '{T}# c~q: a => {"q":"a"}');
        Observer.Verify();
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
        Observer.Expect('Tabs2_1', '  {T}# c~q: a => {"q":"a"}');
        Observer.Expect('Tabs2_2', '~{T}~q: a => {"q":"a"}');
        Observer.Expect('Tabs2_3', 'q: a~{T}~n: 1 => FYamlBadFormat');
        Observer.Expect('Tabs2_4', 'q: a~  {T}~n: 1 => {"q":"a","n":"1"}');
        Observer.Expect('Tabs2_5', '---~{T}q: a => {"q":"a"}');
        Observer.Expect('Tabs2_6', '---{T}~q: a => {"q":"a"}');
        Observer.Expect('Tabs2_7', '--- {T}q: a => FYamlBadFormat');
        Observer.Expect('Tabs2_8', 'q:{T}{T}a => {"q":"a"}');
        Observer.Expect('Tabs2_9', 'q: a #{T}c => {"q":"a"}');
        Observer.Expect('Tabs2_10', 'q: a{T}#c => {"q":"a"}');
        Observer.Expect('Tabs2_11', 'q: [{T}a] => {"q":["a"]}');
        Observer.Expect('Tabs2_12', 'q: [a{T}] => {"q":["a"]}');
        Observer.Expect('Tabs2_13', 'q: [a,{T}b] => {"q":["a","b"]}');
        Observer.Expect('Tabs2_14', 'q: {{T}a: 1} => {"q":{"a":"1"}}');
        Observer.Expect('Tabs2_15', 'k:~  - [a,~  {T}b] => {"k":[["a","b"]]}');
        Observer.Expect('Tabs2_16', '  {T}- a => FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('Tabs2_17', '{T}- a => FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('Tabs2_18', '  {T}k:~  - a => FYamlBadFormat');
        Observer.Expect('Tabs2_19', 'q: [~{T}a] => {"q":["a"]}');
        Observer.Expect('Tabs2_20', 'q: "a{T}b" => {"q":"a\tb"}');
        Observer.Verify();
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
        Observer.Expect('EscapeSurrogates1_1', 'q: "{\}uD800" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_2', 'q: "{\}uDBFF" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_3', 'q: "{\}uDC00" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_4', 'q: "{\}uDFFF" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_5', 'q: "{\}uD83D{\}uDE00" => {"q":"<U+D83D><U+DE00>"}');
        Observer.Expect('EscapeSurrogates1_6', 'q: "{\}uD83D" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_7', 'q: "{\}uD83Dx" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_8', 'q: "{\}uDE00{\}uD83D" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_9', 'q: "{\}U0001F600" => {"q":"<U+D83D><U+DE00>"}');
        Observer.Expect('EscapeSurrogates1_10', 'q: "{\}U00110000" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_11', 'q: "{\}U0010FFFF" => {"q":"<U+DBFF><U+DFFF>"}');
        Observer.Expect('EscapeSurrogates1_12', 'q: "{\}U0000D800" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates1_13', 'q: "{\}U00000041" => {"q":"A"}');
        Observer.Expect('EscapeSurrogates1_14', 'q: "{\}u0041" => {"q":"A"}');
        Observer.Expect('EscapeSurrogates1_15', 'q: "{\}uFFFE" => {"q":"<U+FFFE>"}');
        Observer.Expect('EscapeSurrogates1_16', 'q: "{\}uFFFF" => {"q":"<U+FFFF>"}');
        Observer.Expect('EscapeSurrogates1_17', 'q: "{\}uFDD0" => {"q":"<U+FDD0>"}');
        Observer.Expect('EscapeSurrogates1_18', 'q: "{\}u0000" => {"q":"\u0000"}');
        Observer.Expect('EscapeSurrogates1_19', 'q: "{\}u0001" => {"q":"\u0001"}');
        Observer.Expect('EscapeSurrogates1_20', 'q: "{\}u007F" => {"q":"<U+007F>"}');
        Observer.Expect('EscapeSurrogates1_21', 'q: "{\}u0085" => {"q":"\u0085"}');
        Observer.Expect('EscapeSurrogates1_22', 'q: "{\}u2028" => {"q":"\u2028"}');
        Observer.Expect('EscapeSurrogates1_23', 'q: "{\}u2029" => {"q":"\u2029"}');
        Observer.Expect('EscapeSurrogates1_24', 'q: "{\}uFEFF" => {"q":"<U+FEFF>"}');
        Observer.Expect('EscapeSurrogates1_25', 'q: "{\}U0000FFFE" => {"q":"<U+FFFE>"}');
        Observer.Verify();
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
        Observer.Expect('EscapeSurrogates2_1', 'q: "{\}UFFFFFFFF" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates2_2', 'q: "{\}U7FFFFFFF" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates2_3', 'q: "{\}U00200000" => FYamlBadFormat');
        Observer.Expect('EscapeSurrogates2_4', 'q: "{\}x7F" => {"q":"<U+007F>"}');
        Observer.Expect('EscapeSurrogates2_5', 'q: "{\}x85" => {"q":"\u0085"}');
        Observer.Expect('EscapeSurrogates2_6', 'q: "{\}xFF" => {"q":"<U+00FF>"}');
        Observer.Expect('EscapeSurrogates2_7', 'q: "{\}x00" => {"q":"\u0000"}');
        Observer.Expect('EscapeSurrogates2_8', 'q: "{\}x01" => {"q":"\u0001"}');
        Observer.Verify();
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
        Observer.Observe('depth-too-deep', Y.ReadInto('q: ' + Y.Rep('[', 100) + 'x' + Y.Rep(']', 100), '{"pre":1}'));
        Observer.Observe('bad-escape', Y.ReadInto('q: "{\}q"', '{"pre":1}'));
        Observer.Observe('unmeasured-char-lone', Y.ReadInto('q: a{uD800}b', '{"pre":1}'));
        Observer.Observe('empty-object', Y.ReadInto('q: [', '{}'));
        Observer.Expect('valid', 'true after={"q":"1"}');
        Observer.Expect('valid-same-key', 'true after={"pre":"2"}');
        Observer.Expect('valid-nested-pre', 'true after={"q":"1"}');
        Observer.Expect('invalid-flow', 'FYamlBadFormat after={"pre":1}');
        Observer.Expect('invalid-colon', 'FYamlBadFormat after={"pre":1}');
        Observer.Expect('top-list', 'FInvalidJsonType:JSON tokens of type ''Array'' are not supported by this implementation. after={"pre":1}');
        Observer.Expect('empty', 'FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation. after={"pre":1}');
        Observer.Expect('null-top', 'FInvalidJsonType:JSON tokens of type ''Null'' are not supported by this implementation. after={"pre":1}');
        Observer.Expect('scalar-top', 'FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation. after={"pre":1}');
        Observer.Expect('two-docs', 'FYamlBadFormat after={"pre":1}');
        Observer.Expect('partial-then-error', 'FYamlBadFormat after={"pre":1}');
        Observer.Expect('undefined-alias', 'FYamlBadFormat after={"pre":1}');
        Observer.Expect('depth-too-deep', 'FInvalidJsonData:The data does not represent a valid JSON token. after={"pre":1}');
        Observer.Expect('bad-escape', 'FYamlBadFormat after={"pre":1}');
        Observer.Expect('unmeasured-char-lone', 'true after={"q":"a<U+D800>b"}');
        Observer.Expect('empty-object', 'FYamlBadFormat after={}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Depth_Sweep()
    begin
        DepthSweep('flowseq', 1, 40, 110);
        DepthSweep('flowmap', 2, 40, 110);
        DepthSweep('blockseq', 3, 40, 110);
        DepthSweep('blockmap', 4, 40, 110);
        DepthSweep('mixed', 5, 40, 110);
        Observer.Expect('flowseq-40to110', '........................DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');
        Observer.Expect('flowmap-40to110', '........................DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');
        Observer.Expect('blockseq-40to110', '........................DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');
        Observer.Expect('blockmap-40to110', '........................DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');
        Observer.Expect('mixed-40to110', '........................DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');
        Observer.Verify();
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
        Observer.Expect('flowseq-150', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowseq-200', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowseq-300', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowseq-301', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowseq-302', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowseq-400', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('blockseq-150', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('blockseq-301', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('blockseq-400', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('blockmap-150', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('blockmap-301', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('blockmap-400', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Expect('flowmap-301', 'FInvalidJsonData:The data does not represent a valid JSON token.');
        Observer.Verify();
    end;
}
