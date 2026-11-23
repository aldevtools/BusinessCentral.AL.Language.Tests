// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), YFN Yaml Support (codeunit 79894)
// Probe: AL Runner issue 8580, runner PR 8824. Which characters ReadFromYaml reads, beyond the ones of the JsonYamlUtf8
//   probe: Latin-1 and Latin Extended letters, other scripts, typographic punctuation, CJK, non-BMP characters (surrogate
//   pairs, a ZWJ sequence), control characters, C1 controls, line separators, noncharacters and unpaired surrogates.
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: one observation per character (name U+XXXX, one code unit group per UTF-16 unit). The value holds the results of
//   eleven forms as 'form=result': p plain (q: a<c>b), s single-quoted, d double-quoted, l literal block |-, f folded block >-,
//   k plain key (a<c>b: 1), qk double-quoted key, c in a comment (q: a #<c>), fs flow sequence item, fm flow mapping value,
//   li block list item, e at the start and the end of a plain scalar (q: <c>b<c>). 'ok' means the JSON text equals the
//   document text with the character kept. Anything else is what BC gave (notation: see JsonYamlFinalSupport.al).
//   The Text and the InStream overload agree unless the result reads 'T .. | S ..'.
// BC versions: 27, 28, 29

codeunit 79895 "YFN Yaml Chars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "YFN Yaml Support";

    local procedure CharCell(Name: Text; C: Text)
    var
        Res: Text;
    begin
        Res := 'p=' + Y.Both('q: a' + C + 'b~n: 1', '{"q":"a' + C + 'b","n":"1"}');
        Res += ' s=' + Y.Both('q: ''a' + C + 'b''~n: 1', '{"q":"a' + C + 'b","n":"1"}');
        Res += ' d=' + Y.Both('q: "a' + C + 'b"~n: 1', '{"q":"a' + C + 'b","n":"1"}');
        Res += ' l=' + Y.Both('q: |-~  a' + C + 'b~n: 1', '{"q":"a' + C + 'b","n":"1"}');
        Res += ' f=' + Y.Both('q: >-~  a' + C + 'b~n: 1', '{"q":"a' + C + 'b","n":"1"}');
        Res += ' k=' + Y.Both('a' + C + 'b: 1', '{"a' + C + 'b":"1"}');
        Res += ' qk=' + Y.Both('"a' + C + 'b": 1', '{"a' + C + 'b":"1"}');
        Res += ' c=' + Y.Both('q: a #' + C + '~n: 1', '{"q":"a","n":"1"}');
        Res += ' fs=' + Y.Both('q: [a' + C + 'b, x]', '{"q":["a' + C + 'b","x"]}');
        Res += ' fm=' + Y.Both('q: {a: b' + C + 'c}', '{"q":{"a":"b' + C + 'c"}}');
        Res += ' li=' + Y.Both('k:~  - a' + C + 'b', '{"k":["a' + C + 'b"]}');
        Res += ' e=' + Y.Both('q: ' + C + 'b' + C, '{"q":"' + C + 'b' + C + '"}');
        Observer.Observe(Name, Res);
    end;

    [Test]
    procedure ReadFromYaml_Chars_Latin1_1()
    begin
        CharCell('U+00E4', '{u00E4}');
        CharCell('U+00F6', '{u00F6}');
        CharCell('U+00FC', '{u00FC}');
        CharCell('U+00DF', '{u00DF}');
        CharCell('U+00E9', '{u00E9}');
        CharCell('U+00F1', '{u00F1}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Latin1_2()
    begin
        CharCell('U+00A1', '{u00A1}');
        CharCell('U+00AD', '{u00AD}');
        CharCell('U+00B5', '{u00B5}');
        CharCell('U+00FF', '{u00FF}');
        CharCell('U+00C0', '{u00C0}');
        CharCell('U+00D7', '{u00D7}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Letters_1()
    begin
        CharCell('U+0100', '{u0100}');
        CharCell('U+017F', '{u017F}');
        CharCell('U+0152', '{u0152}');
        CharCell('U+0416', '{u0416}');
        CharCell('U+05D0', '{u05D0}');
        CharCell('U+0627', '{u0627}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Letters_2()
    begin
        CharCell('U+0E01', '{u0E01}');
        CharCell('U+1E9E', '{u1E9E}');
        CharCell('U+3042', '{u3042}');
        CharCell('U+30A2', '{u30A2}');
        CharCell('U+4E2D', '{u4E2D}');
        CharCell('U+AC00', '{uAC00}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Letters_3()
    begin
        CharCell('U+FF21', '{uFF21}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Punct_1()
    begin
        CharCell('U+2010', '{u2010}');
        CharCell('U+2013', '{u2013}');
        CharCell('U+2014', '{u2014}');
        CharCell('U+2018', '{u2018}');
        CharCell('U+2019', '{u2019}');
        CharCell('U+201C', '{u201C}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Punct_2()
    begin
        CharCell('U+201D', '{u201D}');
        CharCell('U+2022', '{u2022}');
        CharCell('U+2026', '{u2026}');
        CharCell('U+20AC', '{u20AC}');
        CharCell('U+2122', '{u2122}');
        CharCell('U+2190', '{u2190}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_NonBmp_1()
    begin
        CharCell('U+D83CDF89', '{uD83C}{uDF89}');
        CharCell('U+D800DC00', '{uD800}{uDC00}');
        CharCell('U+DBFFDFFF', '{uDBFF}{uDFFF}');
        CharCell('U+D83DDC68200DD83DDCBB', '{uD83D}{uDC68}{u200D}{uD83D}{uDCBB}');
        CharCell('U+D83DDE00', '{uD83D}{uDE00}');
        CharCell('U+2603', '{u2603}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Ctrl_1()
    begin
        CharCell('U+0001', '{u0001}');
        CharCell('U+0002', '{u0002}');
        CharCell('U+0008', '{u0008}');
        CharCell('U+0009', '{u0009}');
        CharCell('U+000B', '{u000B}');
        CharCell('U+000C', '{u000C}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Ctrl_2()
    begin
        CharCell('U+000E', '{u000E}');
        CharCell('U+001F', '{u001F}');
        CharCell('U+007F', '{u007F}');
        CharCell('U+0080', '{u0080}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_C1_1()
    begin
        CharCell('U+0081', '{u0081}');
        CharCell('U+0085', '{u0085}');
        CharCell('U+0090', '{u0090}');
        CharCell('U+009F', '{u009F}');
        CharCell('U+00A0', '{u00A0}');
        CharCell('U+2028', '{u2028}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_C1_2()
    begin
        CharCell('U+2029', '{u2029}');
        CharCell('U+200B', '{u200B}');
        CharCell('U+200D', '{u200D}');
        CharCell('U+202E', '{u202E}');
        CharCell('U+2060', '{u2060}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Edge_1()
    begin
        CharCell('U+D7FF', '{uD7FF}');
        CharCell('U+E000', '{uE000}');
        CharCell('U+F8FF', '{uF8FF}');
        CharCell('U+FDD0', '{uFDD0}');
        CharCell('U+FDEF', '{uFDEF}');
        CharCell('U+FFFD', '{uFFFD}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Edge_2()
    begin
        CharCell('U+FEFF', '{uFEFF}');
        CharCell('U+FFFE', '{uFFFE}');
        CharCell('U+FFFF', '{uFFFF}');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFromYaml_Chars_Lone_1()
    begin
        CharCell('U+D800', '{uD800}');
        CharCell('U+DBFF', '{uDBFF}');
        CharCell('U+DC00', '{uDC00}');
        CharCell('U+DFFF', '{uDFFF}');
        Observer.Finish();
    end;
}
