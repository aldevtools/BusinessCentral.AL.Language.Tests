// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (writer Y20, al-runner issue 6491): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix. Neighbours: literal and
//   Text variable labels longer than a Code[10] selector raise StringLengthExceeded (TestCaseContracts.al, BN_Case_CodeSelectorAndLabels
//   and PYC_Case_CodeSelector_VariableAndRangeLabels).
// Facts: case labels that are Code[20] variables with a Code[10] selector, and Code[10] labels with a Code[20] selector.
// BC versions: 27, 28, 29

codeunit 92130 "LT Y20 Case Code Label"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Writer Y20 (al-runner issue 6491): labels that are Code[20] variables with a Code[10] selector: values that fit 10 characters, a
    // value of 15 characters before and after the matching label, and a Code[20] selector with Code[10] labels.
    [Test]
    procedure Y20_Case_CodeSelector_LongerCodeVariableLabels()
    var
        Observer: Codeunit "Probe Observer";
        R: Integer;
    begin
        Observer.Observe('fits short', Format(Y20Pick('ABC', 'ABC', 'XYZ')));
        Observer.Observe('fits long', Format(Y20Pick('XYZ', 'ABC', 'XYZ')));
        Observer.Observe('fits none', Format(Y20Pick('Q', 'ABC', 'XYZ')));
        Observer.Observe('fits 10 chars', Format(Y20Pick('ABCDEFGHIJ', 'ABC', 'ABCDEFGHIJ')));
        if Y20TryPick('Q', 'ABCDEFGHIJKLMNO', 'XYZ', R) then
            Observer.Observe('15 chars first, no match', Format(R))
        else
            Observer.ObserveError('15 chars first, no match');
        if Y20TryPick('XYZ', 'ABCDEFGHIJKLMNO', 'XYZ', R) then
            Observer.Observe('15 chars first, second matches', Format(R))
        else
            Observer.ObserveError('15 chars first, second matches');
        if Y20TryPick('ABC', 'ABC', 'ABCDEFGHIJKLMNO', R) then
            Observer.Observe('first matches, 15 chars second', Format(R))
        else
            Observer.ObserveError('first matches, 15 chars second');
        if Y20TryPick('ABCDEFGHIJ', 'ABCDEFGHIJK', 'XYZ', R) then
            Observer.Observe('11 chars, selector its 10-char prefix', Format(R))
        else
            Observer.ObserveError('11 chars, selector its 10-char prefix');
        Observer.Observe('code20 selector, code10 labels', Format(Y20PickWide('ABCDEFGHIJKLMNO', 'ABC', 'XYZ')));
        Observer.Observe('code20 selector, code10 label matches', Format(Y20PickWide('XYZ', 'ABC', 'XYZ')));
        Observer.Finish();
    end;

    local procedure Y20Pick(Selector: Code[10]; Short: Code[20]; Long: Code[20]): Integer
    begin
        case Selector of
            Short:
                exit(1);
            Long:
                exit(2);
        end;
        exit(0);
    end;

    [TryFunction]
    local procedure Y20TryPick(Selector: Code[10]; Short: Code[20]; Long: Code[20]; var R: Integer)
    begin
        R := Y20Pick(Selector, Short, Long);
    end;

    local procedure Y20PickWide(Selector: Code[20]; Short: Code[10]; Long: Code[10]): Integer
    begin
        case Selector of
            Short:
                exit(1);
            Long:
                exit(2);
        end;
        exit(0);
    end;
}
