// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), YFN Yaml Support (codeunit 79894)
// Probe: AL Runner issue 8580, runner PR 8824. Core tags on scalars (!!int, !!float, !!bool, !!null, !!str and others), core
//   tags on the other kind of node, tags in flow collections and list items, a tagged whole document, tagged and untagged
//   keys. Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
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
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Int_2()
    var
        V: List of [Text];
    begin
        V.AddRange('1.5', '1e3', 'abc', 'yes', 'true', '{~}', '"007"', '''1''', '0.0', '1.', '.5', '+0', '0x', '-0x1F');
        Values('Int2_', '!!int', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Int_3()
    var
        V: List of [Text];
    begin
        V.AddRange('0xFFFFFFFFFFFFFFFF');
        Values('Int3_', '!!int', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Float_1()
    var
        V: List of [Text];
    begin
        V.AddRange('1', '1.5', '1e20', '1E20', '1e400', '100000000000000000000', '.inf', '-.inf', '+.inf', '.Inf', '.INF', '.nan', '.NaN', '.NAN');
        Values('Float1_', '!!float', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Float_2()
    var
        V: List of [Text];
    begin
        V.AddRange('nan', 'inf', '1_000', '0x10', '-0', '0.1', '.5', '5.', '1e-5', '123456789012345678', '3.14159265358979323846', 'abc', '1e5', '1.0e+3');
        Values('Float2_', '!!float', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Float_3()
    var
        V: List of [Text];
    begin
        V.AddRange('"1.5"', '0.30000000000000004', '1e308', '1.7976931348623157e308', '4.9e-324', '1.5e-7', '0.0000001', '-1.5', '+1.5', '1e+20', '12345678901234567890.5', '0.1e1');
        Values('Float3_', '!!float', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Bool_1()
    var
        V: List of [Text];
    begin
        V.AddRange('yes', 'no', 'on', 'off', 'true', 'false', 'True', 'TRUE', 'False', 'FALSE', 'Yes', 'YES', 'No', 'NO');
        Values('Bool1_', '!!bool', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Bool_2()
    var
        V: List of [Text];
    begin
        V.AddRange('On', 'ON', 'Off', 'OFF', 'y', 'n', 'Y', 'N', '1', '0', '{~}', 'abc', '"true"', '''yes''');
        Values('Bool2_', '!!bool', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Bool_3()
    var
        V: List of [Text];
    begin
        V.AddRange('t', 'f', '1.0', 'null');
        Values('Bool3_', '!!bool', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Null_1()
    var
        V: List of [Text];
    begin
        V.AddRange('""', '''''', '{~}', 'null', 'Null', 'NULL', 'x', '0', 'false', '-', '1', '[]');
        Values('Null1_', '!!null', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Str_1()
    var
        V: List of [Text];
    begin
        V.AddRange('1', '1.5', 'true', 'null', '{~}', '0x1F', '007', '""', 'yes', '"x"', '''x''', '1e3', '.inf', '!!int 1');
        Values('Str1_', '!!str', V);
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_TagScalar_Str_2()
    var
        V: List of [Text];
    begin
        V.AddRange('&a x', '|-', '- a');
        Values('Str2_', '!!str', V);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
