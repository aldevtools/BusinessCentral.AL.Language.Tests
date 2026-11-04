// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71523 "LT P103 Text IndexOfAny"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P103_TextIndexOfAny_Open()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        Empty: Text;
    begin
        T := 'Hello, World;x';
        Observer.Observe('text', Format(T.IndexOfAny('o,')));
        Observer.Observe('text_start', Format(T.IndexOfAny('o,', 6)));
        Observer.Observe('text_start_1', Format(T.IndexOfAny('o,', 1)));
        Observer.Observe('text_empty', Format(T.IndexOfAny('')));
        Observer.Observe('text_empty_start', Format(T.IndexOfAny('', 3)));
        Observer.Observe('text_miss', Format(T.IndexOfAny('qz')));
        Observer.Observe('text_case', Format(T.IndexOfAny('W')));
        Observer.Observe('text_case_lower', Format(T.IndexOfAny('w')));
        Observer.Observe('text_last', Format(T.IndexOfAny('x')));
        Observer.Observe('empty_src', Format(Empty.IndexOfAny('abc')));
        Observer.Observe('empty_src_empty', Format(Empty.IndexOfAny('')));
        Observer.Expect('text', '5');
        Observer.Expect('text_start', '6');
        Observer.Expect('text_start_1', '5');
        Observer.Expect('text_empty', '0');
        Observer.Expect('text_empty_start', '0');
        Observer.Expect('text_miss', '0');
        Observer.Expect('text_case', '8');
        Observer.Expect('text_case_lower', '0');
        Observer.Expect('text_last', '14');
        Observer.Expect('empty_src', '0');
        Observer.Expect('empty_src_empty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TextIndexOfAny_CodeVar()
    var
        Observer: Codeunit "Probe Observer";
        T: Text[30];
        C: Code[10];
    begin
        T := 'Hello, World';
        C := 'O,';
        Observer.Observe('code_values', Format(T.IndexOfAny(C)));
        Observer.Observe('code_values_start', Format(T.IndexOfAny(C, 6)));
        C := 'o,';
        Observer.Observe('code_lower', Format(T.IndexOfAny(C)));
        Observer.Expect('code_values', '6');
        Observer.Expect('code_values_start', '6');
        Observer.Expect('code_lower', '6');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TextIndexOfAny_Unicode()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'Gr' + 'ü' + 'ße, Ärger';
        Observer.Observe('uml', Format(T.IndexOfAny('ü')));
        Observer.Observe('uml_set', Format(T.IndexOfAny('Äß')));
        Observer.Observe('uml_upper_miss', Format(T.IndexOfAny('Ü')));
        Observer.Observe('uml_start', Format(T.IndexOfAny('ü,', 4)));
        Observer.Expect('uml', '3');
        Observer.Expect('uml_set', '4');
        Observer.Expect('uml_upper_miss', '0');
        Observer.Expect('uml_start', '6');
        Observer.Verify();
    end;
}
