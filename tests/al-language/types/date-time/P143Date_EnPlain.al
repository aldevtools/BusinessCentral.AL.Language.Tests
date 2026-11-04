// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74650 "LT P143 EnPlain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_EnPlain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        Helper.ProbeDate(Observer, 'd_0117_27', '01/17/27');
        Helper.ProbeDate(Observer, 'd_closing_1018_26', 'C10/18/26');
        Helper.ProbeDate(Observer, 'd_max', '12/31/9999');
        Helper.ProbeDate(Observer, 'd_1_1_2027', '1/1/2027');
        Helper.ProbeDate(Observer, 'd_empty', '');
        Helper.ProbeDate(Observer, 'd_zero', '0D');
        Helper.ProbeDate(Observer, 'd_0117_2027', '01/17/2027');
        Observer.Observe('language_unchanged', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('d_0117_27_filter', '01/17/27');
        Observer.Expect('d_0117_27_count', Format(1 + Helper.InRows(20270117D, 20270117D)));
        Observer.Expect('d_closing_1018_26_filter', 'C10/18/26');
        Observer.Expect('d_closing_1018_26_count', '1');
        Observer.Expect('d_max_filter', '12/31/9999');
        Observer.Expect('d_max_count', Format(1 + Helper.InRows(99991231D, 99991231D)));
        Observer.Expect('d_1_1_2027_filter', '01/01/27');
        Observer.Expect('d_1_1_2027_count', Format(1 + Helper.InRows(20270101D, 20270101D)));
        Observer.Expect('d_empty_filter', '');
        Observer.Expect('d_empty_count', '10');
        Observer.Expect('d_zero_filter', Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>'));
        // The rows dated Today: row 7, plus a fixed row when Today falls on one of the fixed dates.
        Observer.Expect('d_zero_count', Format(Helper.CountOn(Today())));
        Observer.Expect('d_0117_2027_filter', '01/17/27');
        Observer.Expect('d_0117_2027_count', Format(1 + Helper.InRows(20270117D, 20270117D)));
        Observer.Expect('language_unchanged', 'Yes');
        Observer.Verify();
    end;
}
