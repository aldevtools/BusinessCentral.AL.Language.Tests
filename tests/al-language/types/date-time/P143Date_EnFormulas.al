// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74656 "LT P143 EnFormulas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_EnFormulas()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        Helper.ProbeFormula(Observer, 'CD', 'CD', Today());
        Helper.ProbeFormula(Observer, 'T', 'T', Today());
        Helper.ProbeFormula(Observer, 'W', 'W', WorkDate());
        Helper.ProbeFormula(Observer, 'lower_CD', 'cd', Today());
        Helper.ProbeFormula(Observer, 'lower_T', 't', Today());
        Helper.ProbeFormula(Observer, 'lower_W', 'w', WorkDate());
        Helper.ProbeFormula(Observer, 'T_range_open', '..T', Today());
        Observer.Observe('count_all', Format(Helper.CountOn(0D) + 0));
        Observer.Observe('language_unchanged', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('CD_count_eq_on_expected', 'No');
        Observer.Expect('CD_filter_is_text', 'No');
        Observer.Expect('CD_filter_is_expected_date', 'No');
        Observer.Expect('T_count_eq_on_expected', 'Yes');
        Observer.Expect('T_filter_is_text', 'No');
        Observer.Expect('T_filter_is_expected_date', 'Yes');
        Observer.Expect('W_count_eq_on_expected', 'Yes');
        Observer.Expect('W_filter_is_text', 'No');
        Observer.Expect('W_filter_is_expected_date', 'Yes');
        Observer.Expect('lower_CD_count_eq_on_expected', 'Yes');
        Observer.Expect('lower_CD_filter_is_text', 'No');
        Observer.Expect('lower_CD_filter_is_expected_date', 'Yes');
        Observer.Expect('lower_T_count_eq_on_expected', 'Yes');
        Observer.Expect('lower_T_filter_is_text', 'No');
        Observer.Expect('lower_T_filter_is_expected_date', 'Yes');
        Observer.Expect('lower_W_count_eq_on_expected', 'Yes');
        Observer.Expect('lower_W_filter_is_text', 'No');
        Observer.Expect('lower_W_filter_is_expected_date', 'Yes');
        Observer.Expect('T_range_open_count_eq_on_expected', 'No');
        Observer.Expect('T_range_open_filter_is_text', 'No');
        Observer.Expect('T_range_open_filter_is_expected_date', 'No');
        Observer.Expect('count_all', '1');
        Observer.Expect('language_unchanged', 'Yes');
        Observer.Verify();
    end;
}
