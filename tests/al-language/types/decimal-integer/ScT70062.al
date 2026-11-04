// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70062
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Option: Evaluate by name and ordinal, comparison with integer, OptionMembers on variables
// BC versions: 29 (27 and 28 by CI)

codeunit 70062 "LT ScT Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Option_EvaluateByName()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,"Gamma Delta","";
    begin
        Observer.Observe('Beta', Format(Evaluate(O, 'Beta')) + '|' + Format(O) + '|' + Format(O, 0, 2));
        Observer.Observe('lower', Format(Evaluate(O, 'alpha')) + '|' + Format(O) + '|' + Format(O, 0, 2));
        Observer.Observe('upper', Format(Evaluate(O, 'GAMMA DELTA')) + '|' + Format(O) + '|' + Format(O, 0, 2));
        Observer.Observe('space', Format(Evaluate(O, 'Gamma Delta')) + '|' + Format(O, 0, 2));
        Observer.Observe('padded', Format(Evaluate(O, ' Beta ')) + '|' + Format(O, 0, 2));
        Observer.Observe('prefix', Format(Evaluate(O, 'Bet')) + '|' + Format(O, 0, 2));
        Observer.Observe('unknown', Format(Evaluate(O, 'Zeta')) + '|' + Format(O, 0, 2));
        Observer.Observe('empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        Observer.Observe('blank', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        Observer.Expect('Beta', 'Yes|Beta|1');
        Observer.Expect('lower', 'Yes|Alpha|0');
        Observer.Expect('upper', 'Yes|Gamma Delta|2');
        Observer.Expect('space', 'Yes|2');
        Observer.Expect('padded', 'Yes|1');
        Observer.Expect('prefix', 'No|1');
        Observer.Expect('unknown', 'No|1');
        Observer.Expect('empty', 'No|1');
        Observer.Expect('blank', 'No|1');
        Observer.Verify();
    end;

    [Test]
    procedure Option_EvaluateByOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,Gamma;
    begin
        Observer.Observe('0', Format(Evaluate(O, '0')) + '|' + Format(O));
        Observer.Observe('1', Format(Evaluate(O, '1')) + '|' + Format(O));
        Observer.Observe('2', Format(Evaluate(O, '2')) + '|' + Format(O));
        Observer.Observe('3', Format(Evaluate(O, '3')) + '|' + Format(O, 0, 2));
        Observer.Observe('100', Format(Evaluate(O, '100')) + '|' + Format(O, 0, 2));
        Observer.Observe('neg', Format(Evaluate(O, '-1')) + '|' + Format(O, 0, 2));
        Observer.Observe('dec', Format(Evaluate(O, '1.5')) + '|' + Format(O, 0, 2));
        Observer.Observe('plus', Format(Evaluate(O, '+1')) + '|' + Format(O, 0, 2));
        Observer.Expect('0', 'Yes|Alpha');
        Observer.Expect('1', 'Yes|Beta');
        Observer.Expect('2', 'Yes|Gamma');
        Observer.Expect('3', 'Yes|3');
        Observer.Expect('100', 'Yes|100');
        Observer.Expect('neg', 'No|100');
        Observer.Expect('dec', 'No|100');
        Observer.Expect('plus', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure Option_ComparisonInteger()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,Gamma;
        I: Integer;
    begin
        O := O::Beta;
        I := O;
        Observer.Observe('to_int', Format(I));
        Observer.Observe('eq_1', Format(O = 1));
        Observer.Observe('eq_0', Format(O = 0));
        Observer.Observe('gt_0', Format(O > 0));
        Observer.Observe('lt_2', Format(O < 2));
        Observer.Observe('eq_member', Format(O = O::Beta));
        Observer.Observe('ne_member', Format(O <> O::Gamma));
        Observer.Observe('lt_member', Format(O < O::Gamma));
        Observer.Observe('eq_int_var', Format(O = I));
        O := 2;
        Observer.Observe('assign_int', Format(O));
        I := 7;
        O := I;
        Observer.Observe('assign_out_of_range', Format(O, 0, 2));
        Observer.Observe('assign_out_of_range_fmt', Format(O));
        I := -1;
        O := I;
        Observer.Observe('assign_neg', 'no error');
        Observer.Expect('to_int', '1');
        Observer.Expect('eq_1', 'Yes');
        Observer.Expect('eq_0', 'No');
        Observer.Expect('gt_0', 'Yes');
        Observer.Expect('lt_2', 'Yes');
        Observer.Expect('eq_member', 'Yes');
        Observer.Expect('ne_member', 'Yes');
        Observer.Expect('lt_member', 'Yes');
        Observer.Expect('eq_int_var', 'Yes');
        Observer.Expect('assign_int', 'Gamma');
        Observer.Expect('assign_out_of_range', '7');
        Observer.Expect('assign_out_of_range_fmt', '7');
        Observer.Expect('assign_neg', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Option_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        O: Option First,Second,Third;
        P: Option;
    begin
        Observer.Observe('default', Format(O));
        Observer.Observe('default_ord', Format(O, 0, 2));
        Observer.Observe('nomembers_len', Format(StrLen(Format(P))));
        Observer.Observe('nomembers_ord', Format(P, 0, 2));
        P := 3;
        Observer.Observe('nomembers_3', Format(P));
        Observer.Observe('nomembers_3_ord', Format(P, 0, 2));
        Clear(O);
        Observer.Observe('clear', Format(O));
        Observer.Expect('default', 'First');
        Observer.Expect('default_ord', '0');
        Observer.Expect('nomembers_len', '1');
        Observer.Expect('nomembers_ord', '0');
        Observer.Expect('nomembers_3', '3');
        Observer.Expect('nomembers_3_ord', '3');
        Observer.Expect('clear', 'First');
        Observer.Verify();
    end;

    [Test]
    procedure Option_Members_Variable()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,Gamma;
    begin
        O := O::Gamma;
        Observer.Observe('fmt_last', Format(O));
        Observer.Observe('eq_const_0', Format(O::Alpha));
        Observer.Observe('eq_const_2', Format(O::Gamma));
        Observer.Observe('const_int', Format(O::Gamma, 0, 2));
        Observer.Expect('fmt_last', 'Gamma');
        Observer.Expect('eq_const_0', 'Alpha');
        Observer.Expect('eq_const_2', 'Gamma');
        Observer.Expect('const_int', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Option_Case()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,Gamma;
        R: Text;
    begin
        O := O::Beta;
        case O of
            O::Alpha:
                R := 'a';
            O::Beta:
                R := 'b';
            else
                R := 'other';
        end;
        Observer.Observe('case_b', R);
        O := 9;
        case O of
            O::Alpha:
                R := 'a';
            O::Beta:
                R := 'b';
            else
                R := 'other';
        end;
        Observer.Observe('case_other', R);
        Observer.Expect('case_b', 'b');
        Observer.Expect('case_other', 'other');
        Observer.Verify();
    end;

    [Test]
    procedure Option_ToText_Variant()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,Gamma;
        V: Variant;
    begin
        O := O::Beta;
        V := O;
        Observer.Observe('variant_is_option', Format(V.IsOption()));
        Observer.Observe('variant_is_integer', Format(V.IsInteger()));
        Observer.Observe('variant_fmt', Format(V));
        Observer.Observe('variant_fmt2', Format(V, 0, 2));
        Observer.Expect('variant_is_option', 'Yes');
        Observer.Expect('variant_is_integer', 'No');
        Observer.Expect('variant_fmt', 'Beta');
        Observer.Expect('variant_fmt2', '1');
        Observer.Verify();
    end;
}
