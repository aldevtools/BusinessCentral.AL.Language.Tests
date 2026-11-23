// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), YFN Yaml Support (codeunit 79894)
// Probe: AL Runner issue 8580, runner PR 8824. Core tags on scalars (!!int, !!float, !!bool, !!null, !!str and others), core
//   tags on the other kind of node, tags in flow collections and list items, a tagged whole document, tagged and untagged
//   keys, percent escapes in tag handles, suffixes and verbatim tags.
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: one observation per document. The value is 'document => result' (document tokens: ~ line feed, {~} tilde,
//   {S} space; result notation: see JsonYamlFinalSupport.al). Text and InStream overload agree unless 'T .. | S ..'.
// BC versions: 27, 28, 29

codeunit 79896 "YFN Yaml Tags"
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

    local procedure Values(Prefix: Text; Tag: Text; V: List of [Text])
    var
        D: List of [Text];
        X: Text;
    begin
        foreach X in V do
            D.Add('q: ' + Tag + ' ' + X + '~n: 1');
        Cells(Prefix, D);
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Int_1()
    var
        V: List of [Text];
    begin
        V.AddRange('1', '007', '+5', '-0', '-5', '0x1F', '0o17', '0b101', '1_000', '2147483647', '2147483648', '9223372036854775807', '9223372036854775808', '99999999999999999999999');
        Values('Int1_', '!!int', V);
        Observer.Expect('Int1_1', 'q: !!int 1~n: 1 => {"q":1,"n":"1"}');
        Observer.Expect('Int1_2', 'q: !!int 007~n: 1 => {"q":7,"n":"1"}');
        Observer.Expect('Int1_3', 'q: !!int +5~n: 1 => {"q":5,"n":"1"}');
        Observer.Expect('Int1_4', 'q: !!int -0~n: 1 => {"q":0,"n":"1"}');
        Observer.Expect('Int1_5', 'q: !!int -5~n: 1 => {"q":-5,"n":"1"}');
        Observer.Expect('Int1_6', 'q: !!int 0x1F~n: 1 => {"q":31,"n":"1"}');
        Observer.Expect('Int1_7', 'q: !!int 0o17~n: 1 => FYamlBadFormat');
        Observer.Expect('Int1_8', 'q: !!int 0b101~n: 1 => {"q":5,"n":"1"}');
        Observer.Expect('Int1_9', 'q: !!int 1_000~n: 1 => {"q":1000,"n":"1"}');
        Observer.Expect('Int1_10', 'q: !!int 2147483647~n: 1 => {"q":2147483647,"n":"1"}');
        Observer.Expect('Int1_11', 'q: !!int 2147483648~n: 1 => FYamlBadFormat');
        Observer.Expect('Int1_12', 'q: !!int 9223372036854775807~n: 1 => FYamlBadFormat');
        Observer.Expect('Int1_13', 'q: !!int 9223372036854775808~n: 1 => FYamlBadFormat');
        Observer.Expect('Int1_14', 'q: !!int 99999999999999999999999~n: 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Int_2()
    var
        V: List of [Text];
    begin
        V.AddRange('1.5', '1e3', 'abc', 'yes', 'true', '{~}', '"007"', '''1''', '0.0', '1.', '.5', '+0', '0x', '-0x1F');
        Values('Int2_', '!!int', V);
        Observer.Expect('Int2_1', 'q: !!int 1.5~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_2', 'q: !!int 1e3~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_3', 'q: !!int abc~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_4', 'q: !!int yes~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_5', 'q: !!int true~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_6', 'q: !!int {~}~n: 1 => {"q":null,"n":"1"}');
        Observer.Expect('Int2_7', 'q: !!int "007"~n: 1 => {"q":7,"n":"1"}');
        Observer.Expect('Int2_8', 'q: !!int ''1''~n: 1 => {"q":1,"n":"1"}');
        Observer.Expect('Int2_9', 'q: !!int 0.0~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_10', 'q: !!int 1.~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_11', 'q: !!int .5~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_12', 'q: !!int +0~n: 1 => {"q":0,"n":"1"}');
        Observer.Expect('Int2_13', 'q: !!int 0x~n: 1 => FYamlBadFormat');
        Observer.Expect('Int2_14', 'q: !!int -0x1F~n: 1 => {"q":-31,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Int_3()
    var
        V: List of [Text];
    begin
        V.AddRange('0xFFFFFFFFFFFFFFFF');
        Values('Int3_', '!!int', V);
        Observer.Expect('Int3_1', 'q: !!int 0xFFFFFFFFFFFFFFFF~n: 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Float_1()
    var
        V: List of [Text];
    begin
        V.AddRange('1', '1.5', '1e20', '1E20', '1e400', '100000000000000000000', '.inf', '-.inf', '+.inf', '.Inf', '.INF', '.nan', '.NaN', '.NAN');
        Values('Float1_', '!!float', V);
        Observer.Expect('Float1_1', 'q: !!float 1~n: 1 => {"q":1.0,"n":"1"}');
        Observer.Expect('Float1_2', 'q: !!float 1.5~n: 1 => {"q":1.5,"n":"1"}');
        Observer.Expect('Float1_3', 'q: !!float 1e20~n: 1 => {"q":1E+20,"n":"1"}');
        Observer.Expect('Float1_4', 'q: !!float 1E20~n: 1 => {"q":1E+20,"n":"1"}');
        Observer.Expect('Float1_5', 'q: !!float 1e400~n: 1 => {"q":"Infinity","n":"1"}');
        Observer.Expect('Float1_6', 'q: !!float 100000000000000000000~n: 1 => {"q":1E+20,"n":"1"}');
        Observer.Expect('Float1_7', 'q: !!float .inf~n: 1 => {"q":"Infinity","n":"1"}');
        Observer.Expect('Float1_8', 'q: !!float -.inf~n: 1 => {"q":"-Infinity","n":"1"}');
        Observer.Expect('Float1_9', 'q: !!float +.inf~n: 1 => {"q":"Infinity","n":"1"}');
        Observer.Expect('Float1_10', 'q: !!float .Inf~n: 1 => {"q":"Infinity","n":"1"}');
        Observer.Expect('Float1_11', 'q: !!float .INF~n: 1 => {"q":"Infinity","n":"1"}');
        Observer.Expect('Float1_12', 'q: !!float .nan~n: 1 => {"q":"NaN","n":"1"}');
        Observer.Expect('Float1_13', 'q: !!float .NaN~n: 1 => {"q":"NaN","n":"1"}');
        Observer.Expect('Float1_14', 'q: !!float .NAN~n: 1 => {"q":"NaN","n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Float_2()
    var
        V: List of [Text];
    begin
        V.AddRange('nan', 'inf', '1_000', '0x10', '-0', '0.1', '.5', '5.', '1e-5', '123456789012345678', '3.14159265358979323846', 'abc', '1e5', '1.0e+3');
        Values('Float2_', '!!float', V);
        Observer.Expect('Float2_1', 'q: !!float nan~n: 1 => FYamlBadFormat');
        Observer.Expect('Float2_2', 'q: !!float inf~n: 1 => FYamlBadFormat');
        Observer.Expect('Float2_3', 'q: !!float 1_000~n: 1 => {"q":1000.0,"n":"1"}');
        Observer.Expect('Float2_4', 'q: !!float 0x10~n: 1 => FYamlBadFormat');
        Observer.Expect('Float2_5', 'q: !!float -0~n: 1 => {"q":-0.0,"n":"1"}');
        Observer.Expect('Float2_6', 'q: !!float 0.1~n: 1 => {"q":0.1,"n":"1"}');
        Observer.Expect('Float2_7', 'q: !!float .5~n: 1 => {"q":0.5,"n":"1"}');
        Observer.Expect('Float2_8', 'q: !!float 5.~n: 1 => {"q":5.0,"n":"1"}');
        Observer.Expect('Float2_9', 'q: !!float 1e-5~n: 1 => {"q":1E-05,"n":"1"}');
        Observer.Expect('Float2_10', 'q: !!float 123456789012345678~n: 1 => {"q":1.2345678901234568E+17,"n":"1"}');
        Observer.Expect('Float2_11', 'q: !!float 3.14159265358979323846~n: 1 => {"q":3.141592653589793,"n":"1"}');
        Observer.Expect('Float2_12', 'q: !!float abc~n: 1 => FYamlBadFormat');
        Observer.Expect('Float2_13', 'q: !!float 1e5~n: 1 => {"q":100000.0,"n":"1"}');
        Observer.Expect('Float2_14', 'q: !!float 1.0e+3~n: 1 => {"q":1000.0,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Float_3()
    var
        V: List of [Text];
    begin
        V.AddRange('"1.5"', '0.30000000000000004', '1e308', '1.7976931348623157e308', '4.9e-324', '1.5e-7', '0.0000001', '-1.5', '+1.5', '1e+20', '12345678901234567890.5', '0.1e1');
        Values('Float3_', '!!float', V);
        Observer.Expect('Float3_1', 'q: !!float "1.5"~n: 1 => {"q":1.5,"n":"1"}');
        Observer.Expect('Float3_2', 'q: !!float 0.30000000000000004~n: 1 => {"q":0.30000000000000004,"n":"1"}');
        Observer.Expect('Float3_3', 'q: !!float 1e308~n: 1 => {"q":1E+308,"n":"1"}');
        Observer.Expect('Float3_4', 'q: !!float 1.7976931348623157e308~n: 1 => {"q":1.7976931348623157E+308,"n":"1"}');
        Observer.Expect('Float3_5', 'q: !!float 4.9e-324~n: 1 => {"q":5E-324,"n":"1"}');
        Observer.Expect('Float3_6', 'q: !!float 1.5e-7~n: 1 => {"q":1.5E-07,"n":"1"}');
        Observer.Expect('Float3_7', 'q: !!float 0.0000001~n: 1 => {"q":1E-07,"n":"1"}');
        Observer.Expect('Float3_8', 'q: !!float -1.5~n: 1 => {"q":-1.5,"n":"1"}');
        Observer.Expect('Float3_9', 'q: !!float +1.5~n: 1 => {"q":1.5,"n":"1"}');
        Observer.Expect('Float3_10', 'q: !!float 1e+20~n: 1 => {"q":1E+20,"n":"1"}');
        Observer.Expect('Float3_11', 'q: !!float 12345678901234567890.5~n: 1 => {"q":1.2345678901234567E+19,"n":"1"}');
        Observer.Expect('Float3_12', 'q: !!float 0.1e1~n: 1 => {"q":1.0,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Bool_1()
    var
        V: List of [Text];
    begin
        V.AddRange('yes', 'no', 'on', 'off', 'true', 'false', 'True', 'TRUE', 'False', 'FALSE', 'Yes', 'YES', 'No', 'NO');
        Values('Bool1_', '!!bool', V);
        Observer.Expect('Bool1_1', 'q: !!bool yes~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_2', 'q: !!bool no~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool1_3', 'q: !!bool on~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_4', 'q: !!bool off~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool1_5', 'q: !!bool true~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_6', 'q: !!bool false~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool1_7', 'q: !!bool True~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_8', 'q: !!bool TRUE~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_9', 'q: !!bool False~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool1_10', 'q: !!bool FALSE~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool1_11', 'q: !!bool Yes~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_12', 'q: !!bool YES~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool1_13', 'q: !!bool No~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool1_14', 'q: !!bool NO~n: 1 => {"q":false,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Bool_2()
    var
        V: List of [Text];
    begin
        V.AddRange('On', 'ON', 'Off', 'OFF', 'y', 'n', 'Y', 'N', '1', '0', '{~}', 'abc', '"true"', '''yes''');
        Values('Bool2_', '!!bool', V);
        Observer.Expect('Bool2_1', 'q: !!bool On~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool2_2', 'q: !!bool ON~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool2_3', 'q: !!bool Off~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool2_4', 'q: !!bool OFF~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool2_5', 'q: !!bool y~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool2_6', 'q: !!bool n~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool2_7', 'q: !!bool Y~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool2_8', 'q: !!bool N~n: 1 => {"q":false,"n":"1"}');
        Observer.Expect('Bool2_9', 'q: !!bool 1~n: 1 => FYamlBadFormat');
        Observer.Expect('Bool2_10', 'q: !!bool 0~n: 1 => FYamlBadFormat');
        Observer.Expect('Bool2_11', 'q: !!bool {~}~n: 1 => {"q":null,"n":"1"}');
        Observer.Expect('Bool2_12', 'q: !!bool abc~n: 1 => FYamlBadFormat');
        Observer.Expect('Bool2_13', 'q: !!bool "true"~n: 1 => {"q":true,"n":"1"}');
        Observer.Expect('Bool2_14', 'q: !!bool ''yes''~n: 1 => {"q":true,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Bool_3()
    var
        V: List of [Text];
    begin
        V.AddRange('t', 'f', '1.0', 'null');
        Values('Bool3_', '!!bool', V);
        Observer.Expect('Bool3_1', 'q: !!bool t~n: 1 => FYamlBadFormat');
        Observer.Expect('Bool3_2', 'q: !!bool f~n: 1 => FYamlBadFormat');
        Observer.Expect('Bool3_3', 'q: !!bool 1.0~n: 1 => FYamlBadFormat');
        Observer.Expect('Bool3_4', 'q: !!bool null~n: 1 => {"q":null,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Null_1()
    var
        V: List of [Text];
    begin
        V.AddRange('""', '''''', '{~}', 'null', 'Null', 'NULL', 'x', '0', 'false', '-', '1', '[]');
        Values('Null1_', '!!null', V);
        Observer.Expect('Null1_1', 'q: !!null ""~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_2', 'q: !!null ''''~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_3', 'q: !!null {~}~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_4', 'q: !!null null~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_5', 'q: !!null Null~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_6', 'q: !!null NULL~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_7', 'q: !!null x~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_8', 'q: !!null 0~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_9', 'q: !!null false~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_10', 'q: !!null -~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_11', 'q: !!null 1~n: 1 => FYamlBadFormat');
        Observer.Expect('Null1_12', 'q: !!null []~n: 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Str_1()
    var
        V: List of [Text];
    begin
        V.AddRange('1', '1.5', 'true', 'null', '{~}', '0x1F', '007', '""', 'yes', '"x"', '''x''', '1e3', '.inf', '!!int 1');
        Values('Str1_', '!!str', V);
        Observer.Expect('Str1_1', 'q: !!str 1~n: 1 => {"q":"1","n":"1"}');
        Observer.Expect('Str1_2', 'q: !!str 1.5~n: 1 => {"q":"1.5","n":"1"}');
        Observer.Expect('Str1_3', 'q: !!str true~n: 1 => {"q":"true","n":"1"}');
        Observer.Expect('Str1_4', 'q: !!str null~n: 1 => {"q":null,"n":"1"}');
        Observer.Expect('Str1_5', 'q: !!str {~}~n: 1 => {"q":null,"n":"1"}');
        Observer.Expect('Str1_6', 'q: !!str 0x1F~n: 1 => {"q":"0x1F","n":"1"}');
        Observer.Expect('Str1_7', 'q: !!str 007~n: 1 => {"q":"007","n":"1"}');
        Observer.Expect('Str1_8', 'q: !!str ""~n: 1 => {"q":"","n":"1"}');
        Observer.Expect('Str1_9', 'q: !!str yes~n: 1 => {"q":"yes","n":"1"}');
        Observer.Expect('Str1_10', 'q: !!str "x"~n: 1 => {"q":"x","n":"1"}');
        Observer.Expect('Str1_11', 'q: !!str ''x''~n: 1 => {"q":"x","n":"1"}');
        Observer.Expect('Str1_12', 'q: !!str 1e3~n: 1 => {"q":"1e3","n":"1"}');
        Observer.Expect('Str1_13', 'q: !!str .inf~n: 1 => {"q":".inf","n":"1"}');
        Observer.Expect('Str1_14', 'q: !!str !!int 1~n: 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Str_2()
    var
        V: List of [Text];
    begin
        V.AddRange('&a x', '|-', '- a');
        Values('Str2_', '!!str', V);
        Observer.Expect('Str2_1', 'q: !!str &a x~n: 1 => {"q":"x","n":"1"}');
        Observer.Expect('Str2_2', 'q: !!str |-~n: 1 => {"q":"","n":"1"}');
        Observer.Expect('Str2_3', 'q: !!str - a~n: 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagOther_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!timestamp 2001-12-14',
            'q: !!timestamp x',
            'q: !!timestamp 2001-12-14t21:59:43.10-05:00',
            'q: !!timestamp 2001-12-14 21:59:43.10 -5',
            'q: !!timestamp 2002-12-14T21:59:43Z',
            'q: !!binary SGVsbG8=',
            'q: !!merge <<',
            'q: !!value =',
            'q: !!yaml x',
            'q: !!foo x',
            'q: !!set x',
            'q: !!omap x',
            'q: !!pairs x',
            'q: !!seq x',
            'q: !!map x',
            'q: !x 1',
            'q: !<tag:yaml.org,2002:int> 1',
            'q: !<tag:yaml.org,2002:str> 1',
            'q: !<!local> 1',
            'q: ! 1');
        Cells('Other1_', D);
        Observer.Expect('Other1_1', 'q: !!timestamp 2001-12-14 => {"q":"2001-12-14T00:00:00"}');
        Observer.Expect('Other1_2', 'q: !!timestamp x => FYamlBadFormat');
        Observer.Expect('Other1_3', 'q: !!timestamp 2001-12-14t21:59:43.10-05:00 => {"q":"2001-12-15T02:59:43.1+00:00"}');
        Observer.Expect('Other1_4', 'q: !!timestamp 2001-12-14 21:59:43.10 -5 => {"q":"2001-12-15T02:59:43.1+00:00"}');
        Observer.Expect('Other1_5', 'q: !!timestamp 2002-12-14T21:59:43Z => {"q":"2002-12-14T21:59:43Z"}');
        Observer.Expect('Other1_6', 'q: !!binary SGVsbG8= => FYamlBadFormat');
        Observer.Expect('Other1_7', 'q: !!merge << => FYamlBadFormat');
        Observer.Expect('Other1_8', 'q: !!value = => FYamlBadFormat');
        Observer.Expect('Other1_9', 'q: !!yaml x => FYamlBadFormat');
        Observer.Expect('Other1_10', 'q: !!foo x => FYamlBadFormat');
        Observer.Expect('Other1_11', 'q: !!set x => FYamlBadFormat');
        Observer.Expect('Other1_12', 'q: !!omap x => FYamlBadFormat');
        Observer.Expect('Other1_13', 'q: !!pairs x => FYamlBadFormat');
        Observer.Expect('Other1_14', 'q: !!seq x => FYamlBadFormat');
        Observer.Expect('Other1_15', 'q: !!map x => FYamlBadFormat');
        Observer.Expect('Other1_16', 'q: !x 1 => FYamlBadFormat');
        Observer.Expect('Other1_17', 'q: !<tag:yaml.org,2002:int> 1 => {"q":1}');
        Observer.Expect('Other1_18', 'q: !<tag:yaml.org,2002:str> 1 => {"q":"1"}');
        Observer.Expect('Other1_19', 'q: !<!local> 1 => FYamlBadFormat');
        Observer.Expect('Other1_20', 'q: ! 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagOther_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !local 1',
            'q: !!int !!str 1',
            'q: !!str !!int 1',
            'q: !!int{S}{S}1',
            'q: !!int~  1',
            'q: !!int # c~n: 1');
        Cells('Other2_', D);
        Observer.Expect('Other2_1', 'q: !local 1 => FYamlBadFormat');
        Observer.Expect('Other2_2', 'q: !!int !!str 1 => FYamlBadFormat');
        Observer.Expect('Other2_3', 'q: !!str !!int 1 => FYamlBadFormat');
        Observer.Expect('Other2_4', 'q: !!int{S}{S}1 => {"q":1}');
        Observer.Expect('Other2_5', 'q: !!int~  1 => {"q":1}');
        Observer.Expect('Other2_6', 'q: !!int # c~n: 1 => {"q":null,"n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagWrongNode_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!int [a]',
            'q: !!bool {a: 1}',
            'q: !!float [1]',
            'q: !!timestamp {a: 1}',
            'q: !!map x',
            'q: !!seq a',
            'q: !!omap [a]',
            'q: !!pairs [a]',
            'q: ! [a]',
            'q: !!map',
            'q: !!seq',
            'q: !!int',
            'q: !!bool',
            'q: !!float',
            'q: !!str [a]',
            'q: !!str {a: 1}',
            'q: !!map {a: 1}',
            'q: !!set {a}',
            'q: !!null [a]',
            'q: !!null {a: 1}');
        Cells('WrongNode1_', D);
        Observer.Expect('WrongNode1_1', 'q: !!int [a] => FYamlBadFormat');
        Observer.Expect('WrongNode1_2', 'q: !!bool {a: 1} => FYamlBadFormat');
        Observer.Expect('WrongNode1_3', 'q: !!float [1] => FYamlBadFormat');
        Observer.Expect('WrongNode1_4', 'q: !!timestamp {a: 1} => FYamlBadFormat');
        Observer.Expect('WrongNode1_5', 'q: !!map x => FYamlBadFormat');
        Observer.Expect('WrongNode1_6', 'q: !!seq a => FYamlBadFormat');
        Observer.Expect('WrongNode1_7', 'q: !!omap [a] => FYamlBadFormat');
        Observer.Expect('WrongNode1_8', 'q: !!pairs [a] => FYamlBadFormat');
        Observer.Expect('WrongNode1_9', 'q: ! [a] => FYamlBadFormat');
        Observer.Expect('WrongNode1_10', 'q: !!map => {"q":null}');
        Observer.Expect('WrongNode1_11', 'q: !!seq => FYamlBadFormat');
        Observer.Expect('WrongNode1_12', 'q: !!int => {"q":null}');
        Observer.Expect('WrongNode1_13', 'q: !!bool => {"q":null}');
        Observer.Expect('WrongNode1_14', 'q: !!float => {"q":null}');
        Observer.Expect('WrongNode1_15', 'q: !!str [a] => FYamlBadFormat');
        Observer.Expect('WrongNode1_16', 'q: !!str {a: 1} => FYamlBadFormat');
        Observer.Expect('WrongNode1_17', 'q: !!map {a: 1} => {"q":{"a":"1"}}');
        Observer.Expect('WrongNode1_18', 'q: !!set {a} => FYamlBadFormat');
        Observer.Expect('WrongNode1_19', 'q: !!null [a] => FYamlBadFormat');
        Observer.Expect('WrongNode1_20', 'q: !!null {a: 1} => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagWrongNode_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!binary [a]',
            'q: !!int~  - a',
            'q: !!seq~  - a',
            'q: !!map~  a: 1',
            'q: !!str~  a: 1',
            'q: !!str~  - a',
            'q: !!map~  - a',
            'q: !!seq~  a: 1',
            'q: !!map [a]',
            'q: !!seq {a: 1}',
            'q: ! {a: 1}',
            'q: !x [a]',
            'q: !!omap~  - a: 1',
            'q: !!set~  a: 1',
            'q: !!set~  a:',
            'q: !!seq []',
            'q: !!map {}',
            'q: !!str []',
            'q: !!str {}',
            'q: !!seq {}');
        Cells('WrongNode2_', D);
        Observer.Expect('WrongNode2_1', 'q: !!binary [a] => FYamlBadFormat');
        Observer.Expect('WrongNode2_2', 'q: !!int~  - a => FYamlBadFormat');
        Observer.Expect('WrongNode2_3', 'q: !!seq~  - a => FYamlBadFormat');
        Observer.Expect('WrongNode2_4', 'q: !!map~  a: 1 => {"q":{"a":"1"}}');
        Observer.Expect('WrongNode2_5', 'q: !!str~  a: 1 => FYamlBadFormat');
        Observer.Expect('WrongNode2_6', 'q: !!str~  - a => FYamlBadFormat');
        Observer.Expect('WrongNode2_7', 'q: !!map~  - a => FYamlBadFormat');
        Observer.Expect('WrongNode2_8', 'q: !!seq~  a: 1 => FYamlBadFormat');
        Observer.Expect('WrongNode2_9', 'q: !!map [a] => FYamlBadFormat');
        Observer.Expect('WrongNode2_10', 'q: !!seq {a: 1} => FYamlBadFormat');
        Observer.Expect('WrongNode2_11', 'q: ! {a: 1} => FYamlBadFormat');
        Observer.Expect('WrongNode2_12', 'q: !x [a] => FYamlBadFormat');
        Observer.Expect('WrongNode2_13', 'q: !!omap~  - a: 1 => FYamlBadFormat');
        Observer.Expect('WrongNode2_14', 'q: !!set~  a: 1 => FYamlBadFormat');
        Observer.Expect('WrongNode2_15', 'q: !!set~  a: => FYamlBadFormat');
        Observer.Expect('WrongNode2_16', 'q: !!seq [] => FYamlBadFormat');
        Observer.Expect('WrongNode2_17', 'q: !!map {} => {"q":{}}');
        Observer.Expect('WrongNode2_18', 'q: !!str [] => FYamlBadFormat');
        Observer.Expect('WrongNode2_19', 'q: !!str {} => FYamlBadFormat');
        Observer.Expect('WrongNode2_20', 'q: !!seq {} => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagPosition_1()
    var
        D: List of [Text];
    begin
        D.AddRange('q: &a !!int 1',
            'q: !!int &a 1',
            'a: &x 1~q: !!str *x',
            'q: [!!int 1, !!str 2, !!bool yes]',
            'q: {a: !!int 1, b: !!str 2}',
            'k:~  - !!int 1~  - !!str 2~  - !!bool yes',
            'k:~  - !!float 1~  - !!null {~}',
            'q: [!!int [a]]',
            'q: [!!map x]',
            'q: {a: !!int [1]}',
            'q: {a: !!int}',
            'q: [!!int]',
            'q: [!!int , 1]',
            'q: [!!str]',
            'k:~  - !!int',
            'k:~  - !!int [a]',
            'k:~  - !!map {a: 1}',
            'k:~  - !!seq [a]~  - !!str x',
            'q: !!str "a"',
            'q: !!int "1"');
        Cells('Position1_', D);
        Observer.Expect('Position1_1', 'q: &a !!int 1 => {"q":1}');
        Observer.Expect('Position1_2', 'q: !!int &a 1 => {"q":1}');
        Observer.Expect('Position1_3', 'a: &x 1~q: !!str *x => FYamlBadFormat');
        Observer.Expect('Position1_4', 'q: [!!int 1, !!str 2, !!bool yes] => {"q":[1,"2",true]}');
        Observer.Expect('Position1_5', 'q: {a: !!int 1, b: !!str 2} => {"q":{"a":1,"b":"2"}}');
        Observer.Expect('Position1_6', 'k:~  - !!int 1~  - !!str 2~  - !!bool yes => {"k":[1,"2",true]}');
        Observer.Expect('Position1_7', 'k:~  - !!float 1~  - !!null {~} => FYamlBadFormat');
        Observer.Expect('Position1_8', 'q: [!!int [a]] => FYamlBadFormat');
        Observer.Expect('Position1_9', 'q: [!!map x] => FYamlBadFormat');
        Observer.Expect('Position1_10', 'q: {a: !!int [1]} => FYamlBadFormat');
        Observer.Expect('Position1_11', 'q: {a: !!int} => FYamlBadFormat');
        Observer.Expect('Position1_12', 'q: [!!int] => FYamlBadFormat');
        Observer.Expect('Position1_13', 'q: [!!int , 1] => {"q":[null,"1"]}');
        Observer.Expect('Position1_14', 'q: [!!str] => FYamlBadFormat');
        Observer.Expect('Position1_15', 'k:~  - !!int => {"k":[null]}');
        Observer.Expect('Position1_16', 'k:~  - !!int [a] => FYamlBadFormat');
        Observer.Expect('Position1_17', 'k:~  - !!map {a: 1} => {"k":[{"a":"1"}]}');
        Observer.Expect('Position1_18', 'k:~  - !!seq [a]~  - !!str x => FYamlBadFormat');
        Observer.Expect('Position1_19', 'q: !!str "a" => {"q":"a"}');
        Observer.Expect('Position1_20', 'q: !!int "1" => {"q":1}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagPosition_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !!bool "yes"',
            'q: !!int ""',
            'q: !!float "x"',
            'q: !!str ""~n: 1',
            'q: !!null "x"');
        Cells('Position2_', D);
        Observer.Expect('Position2_1', 'q: !!bool "yes" => {"q":true}');
        Observer.Expect('Position2_2', 'q: !!int "" => FYamlBadFormat');
        Observer.Expect('Position2_3', 'q: !!float "x" => FYamlBadFormat');
        Observer.Expect('Position2_4', 'q: !!str ""~n: 1 => {"q":"","n":"1"}');
        Observer.Expect('Position2_5', 'q: !!null "x" => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagTop_1()
    var
        D: List of [Text];
    begin
        D.AddRange('!!int 1',
            '!!bool yes',
            '!!str x',
            '!!map {a: 1}',
            '!!map~a: 1',
            '--- !!map~a: 1',
            '!!str~a: 1',
            '--- !!int 1',
            '!!seq [a]',
            '!!null',
            '!!map~a: !!int 1',
            '--- !!str~a: 1',
            '!!set {a}',
            '! {a: 1}',
            '!!omap [a: 1]',
            '--- !!map~q: 1~...',
            '&a {q: 1}',
            '&a~q: 1',
            '!!str a: 1',
            '{q: !!int 1}');
        Cells('Top1_', D);
        Observer.Expect('Top1_1', '!!int 1 => FInvalidJsonType:JSON tokens of type ''Integer'' are not supported by this implementation.');
        Observer.Expect('Top1_2', '!!bool yes => FInvalidJsonType:JSON tokens of type ''Boolean'' are not supported by this implementation.');
        Observer.Expect('Top1_3', '!!str x => FInvalidJsonType:JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('Top1_4', '!!map {a: 1} => {"a":"1"}');
        Observer.Expect('Top1_5', '!!map~a: 1 => {"a":"1"}');
        Observer.Expect('Top1_6', '--- !!map~a: 1 => {"a":"1"}');
        Observer.Expect('Top1_7', '!!str~a: 1 => FYamlBadFormat');
        Observer.Expect('Top1_8', '--- !!int 1 => FInvalidJsonType:JSON tokens of type ''Integer'' are not supported by this implementation.');
        Observer.Expect('Top1_9', '!!seq [a] => FYamlBadFormat');
        Observer.Expect('Top1_10', '!!null => FYamlBadFormat');
        Observer.Expect('Top1_11', '!!map~a: !!int 1 => {"a":1}');
        Observer.Expect('Top1_12', '--- !!str~a: 1 => FYamlBadFormat');
        Observer.Expect('Top1_13', '!!set {a} => FYamlBadFormat');
        Observer.Expect('Top1_14', '! {a: 1} => FYamlBadFormat');
        Observer.Expect('Top1_15', '!!omap [a: 1] => FYamlBadFormat');
        Observer.Expect('Top1_16', '--- !!map~q: 1~... => {"q":"1"}');
        Observer.Expect('Top1_17', '&a {q: 1} => {"q":"1"}');
        Observer.Expect('Top1_18', '&a~q: 1 => {"q":"1"}');
        Observer.Expect('Top1_19', '!!str a: 1 => {"a":"1"}');
        Observer.Expect('Top1_20', '{q: !!int 1} => {"q":1}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagTop_2()
    var
        D: List of [Text];
    begin
        D.AddRange('!x~q: 1',
            '!!map {}',
            '!!map~q: 1~n: 2');
        Cells('Top2_', D);
        Observer.Expect('Top2_1', '!x~q: 1 => FYamlBadFormat');
        Observer.Expect('Top2_2', '!!map {} => {}');
        Observer.Expect('Top2_3', '!!map~q: 1~n: 2 => {"q":"1","n":"2"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagEscapes_1()
    var
        D: List of [Text];
    begin
        D.AddRange('%TAG !e! tag:yaml.org,2002:~---~q: !e!%32:int 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%32:int 007',
            '%TAG !e! tag:yaml.org,200~---~q: !e!%32:int 007',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%69nt 007',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%73tr 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%62ool yes',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%6Eull x',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%6eull x',
            '%TAG !e! tag%3Ayaml.org,2002:~---~q: !e!int 007',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%ZZ 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!% 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%6 1',
            '%TAG !e! tag:yaml.org,2002:~---~q: !e!%C3%A9 1');
        Cells('Escapes1_', D);
        Observer.Expect('Escapes1_1', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%32:int 1 => FYamlBadFormat');
        Observer.Expect('Escapes1_2', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%32:int 007 => FYamlBadFormat');
        Observer.Expect('Escapes1_3', '%TAG !e! tag:yaml.org,200~---~q: !e!%32:int 007 => {"q":7}');
        Observer.Expect('Escapes1_4', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%69nt 007 => {"q":7}');
        Observer.Expect('Escapes1_5', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%73tr 1 => {"q":"1"}');
        Observer.Expect('Escapes1_6', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%62ool yes => {"q":true}');
        Observer.Expect('Escapes1_7', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%6Eull x => FYamlBadFormat');
        Observer.Expect('Escapes1_8', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%6eull x => FYamlBadFormat');
        Observer.Expect('Escapes1_9', '%TAG !e! tag%3Ayaml.org,2002:~---~q: !e!int 007 => {"q":7}');
        Observer.Expect('Escapes1_10', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%ZZ 1 => FYamlBadFormat');
        Observer.Expect('Escapes1_11', '%TAG !e! tag:yaml.org,2002:~---~q: !e!% 1 => FYamlBadFormat');
        Observer.Expect('Escapes1_12', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%6 1 => FYamlBadFormat');
        Observer.Expect('Escapes1_13', '%TAG !e! tag:yaml.org,2002:~---~q: !e!%C3%A9 1 => FYamlBadFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagEscapes_2()
    var
        D: List of [Text];
    begin
        D.AddRange('q: !%21 1',
            'q: !%21 yes',
            'q: !!%69nt 007',
            'q: !!%62ool yes',
            'q: !!int%20 1',
            'q: !x%41 1',
            'q: !<tag:yaml.org,2002:%69nt> 007',
            'q: !<tag%3Ayaml.org,2002:int> 007',
            'q: !<tag:yaml.org,2002:int%20> 1',
            'q: !<%21> 1',
            '%TAG !e! tag:yaml.org,2002:~---~!e!%69nt 007: a',
            '%TAG !e! tag:yaml.org,2002:~---~q: [!e!%69nt 007]',
            '%TAG !e! tag:yaml.org,2002:~---~q: {a: !e!%69nt 007}',
            '%TAG !e! tag:yaml.org,2002:~---~q:~  - !e!%69nt 007');
        Cells('Escapes2_', D);
        Observer.Expect('Escapes2_1', 'q: !%21 1 => FYamlBadFormat');
        Observer.Expect('Escapes2_2', 'q: !%21 yes => FYamlBadFormat');
        Observer.Expect('Escapes2_3', 'q: !!%69nt 007 => {"q":7}');
        Observer.Expect('Escapes2_4', 'q: !!%62ool yes => {"q":true}');
        Observer.Expect('Escapes2_5', 'q: !!int%20 1 => FYamlBadFormat');
        Observer.Expect('Escapes2_6', 'q: !x%41 1 => FYamlBadFormat');
        Observer.Expect('Escapes2_7', 'q: !<tag:yaml.org,2002:%69nt> 007 => {"q":7}');
        Observer.Expect('Escapes2_8', 'q: !<tag%3Ayaml.org,2002:int> 007 => {"q":7}');
        Observer.Expect('Escapes2_9', 'q: !<tag:yaml.org,2002:int%20> 1 => FYamlBadFormat');
        Observer.Expect('Escapes2_10', 'q: !<%21> 1 => FYamlBadFormat');
        Observer.Expect('Escapes2_11', '%TAG !e! tag:yaml.org,2002:~---~!e!%69nt 007: a => {"7":"a"}');
        Observer.Expect('Escapes2_12', '%TAG !e! tag:yaml.org,2002:~---~q: [!e!%69nt 007] => {"q":[7]}');
        Observer.Expect('Escapes2_13', '%TAG !e! tag:yaml.org,2002:~---~q: {a: !e!%69nt 007} => {"q":{"a":7}}');
        Observer.Expect('Escapes2_14', '%TAG !e! tag:yaml.org,2002:~---~q:~  - !e!%69nt 007 => {"q":[7]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagKeys_1()
    var
        D: List of [Text];
    begin
        D.AddRange('!!bool yes: a',
            '!!int 1: a',
            '!!str : a',
            '!!str a: 1',
            '!!null : a',
            '!!null {~}: a',
            '!!float 1.5: a',
            '!!int 007: a',
            '? !!int 1~: a',
            '!!seq [a]: b',
            '!!map {a: 1}: b',
            '"yes": a',
            '!!bool "yes": a',
            '!!str 1: a',
            '!!int abc: a',
            '!!bool no: a',
            '!!float .inf: a',
            '!x a: b',
            '!!int 1: a~!!str 1: b',
            '!!int 1: a~1: b');
        Cells('Keys1_', D);
        Observer.Expect('Keys1_1', '!!bool yes: a => {"True":"a"}');
        Observer.Expect('Keys1_2', '!!int 1: a => {"1":"a"}');
        Observer.Expect('Keys1_3', '!!str : a => FYamlBadFormat');
        Observer.Expect('Keys1_4', '!!str a: 1 => {"a":"1"}');
        Observer.Expect('Keys1_5', '!!null : a => FYamlBadFormat');
        Observer.Expect('Keys1_6', '!!null {~}: a => FYamlBadFormat');
        Observer.Expect('Keys1_7', '!!float 1.5: a => {"1.5":"a"}');
        Observer.Expect('Keys1_8', '!!int 007: a => {"7":"a"}');
        Observer.Expect('Keys1_9', '? !!int 1~: a => {"1":"a"}');
        Observer.Expect('Keys1_10', '!!seq [a]: b => FYamlBadFormat');
        Observer.Expect('Keys1_11', '!!map {a: 1}: b => {"(Collection)":"b"}');
        Observer.Expect('Keys1_12', '"yes": a => {"yes":"a"}');
        Observer.Expect('Keys1_13', '!!bool "yes": a => {"True":"a"}');
        Observer.Expect('Keys1_14', '!!str 1: a => {"1":"a"}');
        Observer.Expect('Keys1_15', '!!int abc: a => FYamlBadFormat');
        Observer.Expect('Keys1_16', '!!bool no: a => {"False":"a"}');
        Observer.Expect('Keys1_17', '!!float .inf: a => {"Infinity":"a"}');
        Observer.Expect('Keys1_18', '!x a: b => FYamlBadFormat');
        Observer.Expect('Keys1_19', '!!int 1: a~!!str 1: b => {"1":"b"}');
        Observer.Expect('Keys1_20', '!!int 1: a~1: b => {"1":"b"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagKeys_2()
    var
        D: List of [Text];
    begin
        D.AddRange('!!bool yes: a~yes: b',
            '{!!int 1: a}',
            '{!!str a: 1, !!bool true: 2}',
            '!!bool true: a',
            '!!int 0x1F: a',
            '!!null null: a',
            '!!float 1: a',
            '!!str {~}: a');
        Cells('Keys2_', D);
        Observer.Expect('Keys2_1', '!!bool yes: a~yes: b => {"True":"a","yes":"b"}');
        Observer.Expect('Keys2_2', '{!!int 1: a} => {"1":"a"}');
        Observer.Expect('Keys2_3', '{!!str a: 1, !!bool true: 2} => {"a":"1","True":"2"}');
        Observer.Expect('Keys2_4', '!!bool true: a => {"True":"a"}');
        Observer.Expect('Keys2_5', '!!int 0x1F: a => {"31":"a"}');
        Observer.Expect('Keys2_6', '!!null null: a => FYamlBadFormat');
        Observer.Expect('Keys2_7', '!!float 1: a => {"1":"a"}');
        Observer.Expect('Keys2_8', '!!str {~}: a => {"~":"a"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagKeysPlain_1()
    var
        D: List of [Text];
    begin
        D.AddRange('1: a',
            'yes: a',
            'true: a',
            'null: a',
            '{~}: a',
            '1.5: a',
            '0x1F: a',
            '.inf: a',
            '007: a',
            '-0: a',
            '1e3: a',
            'On: a',
            'no: a',
            '"": a',
            ''''': a',
            ': a',
            '? : a',
            '? {~}: a',
            '? x~: a',
            '? x~');
        Cells('KeysPlain1_', D);
        Observer.Expect('KeysPlain1_1', '1: a => {"1":"a"}');
        Observer.Expect('KeysPlain1_2', 'yes: a => {"yes":"a"}');
        Observer.Expect('KeysPlain1_3', 'true: a => {"true":"a"}');
        Observer.Expect('KeysPlain1_4', 'null: a => {"null":"a"}');
        Observer.Expect('KeysPlain1_5', '{~}: a => {"~":"a"}');
        Observer.Expect('KeysPlain1_6', '1.5: a => {"1.5":"a"}');
        Observer.Expect('KeysPlain1_7', '0x1F: a => {"0x1F":"a"}');
        Observer.Expect('KeysPlain1_8', '.inf: a => {".inf":"a"}');
        Observer.Expect('KeysPlain1_9', '007: a => {"007":"a"}');
        Observer.Expect('KeysPlain1_10', '-0: a => {"-0":"a"}');
        Observer.Expect('KeysPlain1_11', '1e3: a => {"1e3":"a"}');
        Observer.Expect('KeysPlain1_12', 'On: a => {"On":"a"}');
        Observer.Expect('KeysPlain1_13', 'no: a => {"no":"a"}');
        Observer.Expect('KeysPlain1_14', '"": a => {"":"a"}');
        Observer.Expect('KeysPlain1_15', ''''': a => {"":"a"}');
        Observer.Expect('KeysPlain1_16', ': a => FYamlBadFormat');
        Observer.Expect('KeysPlain1_17', '? : a => FYamlBadFormat');
        Observer.Expect('KeysPlain1_18', '? {~}: a => {"(Collection)":null}');
        Observer.Expect('KeysPlain1_19', '? x~: a => {"x":"a"}');
        Observer.Expect('KeysPlain1_20', '? x~ => {"x":null}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_TagKeysPlain_2()
    var
        D: List of [Text];
    begin
        D.AddRange('a:~  b: 1~  1: x',
            '1: a~1.0: b',
            '1: a~"1": b',
            'true: a~"true": b',
            'null: a~"null": b');
        Cells('KeysPlain2_', D);
        Observer.Expect('KeysPlain2_1', 'a:~  b: 1~  1: x => {"a":{"b":"1","1":"x"}}');
        Observer.Expect('KeysPlain2_2', '1: a~1.0: b => {"1":"a","1.0":"b"}');
        Observer.Expect('KeysPlain2_3', '1: a~"1": b => {"1":"b"}');
        Observer.Expect('KeysPlain2_4', 'true: a~"true": b => {"true":"b"}');
        Observer.Expect('KeysPlain2_5', 'null: a~"null": b => {"null":"b"}');
        Observer.Verify();
    end;
}
