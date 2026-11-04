// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74651 "LT P143 EnRanges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_EnRanges()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        OldLanguage: Integer;
    begin
        Helper.Seed();
        OldLanguage := GlobalLanguage();
        Helper.ProbeDate(Observer, 'r_both', '01/01/27..01/31/27');
        Helper.ProbeDate(Observer, 'r_open_from', '..01/31/27');
        Helper.ProbeDate(Observer, 'r_open_to', '01/17/27..');
        Helper.ProbeDate(Observer, 'r_or', '01/17/27|10/18/26');
        Helper.ProbeDate(Observer, 'r_lt', '<01/17/27');
        Helper.ProbeDate(Observer, 'r_ge', '>=01/31/27');
        Helper.ProbeDate(Observer, 'r_closing_range', 'C10/18/26..12/31/9999');
        Helper.ProbeDate(Observer, 'r_ne', '<>01/17/27');
        Observer.Observe('language_unchanged', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('r_both_filter', '01/01/27..01/31/27');
        Observer.Expect('r_both_count', Format(4 + Helper.InRows(20270101D, 20270131D)));
        Observer.Expect('r_open_from_filter', '..01/31/27');
        Observer.Expect('r_open_from_count', Format(7 + Helper.InRows(17530101D, 20270131D)));
        Observer.Expect('r_open_to_filter', '01/17/27..');
        Observer.Expect('r_open_to_count', Format(3 + Helper.InRows(20270117D, 99991231D)));
        Observer.Expect('r_or_filter', '01/17/27|10/18/26');
        // One row per listed date (17 Jan 2027, 18 Oct 2026), plus row 7 when Today falls on one of them.
        Observer.Expect('r_or_count', Format(Helper.CountOn(20270117D) + Helper.CountOn(20261018D)));
        Observer.Expect('r_lt_filter', '<01/17/27');
        Observer.Expect('r_lt_count', Format(5 + Helper.InRows(17530101D, 20270116D)));
        Observer.Expect('r_ge_filter', '>=01/31/27');
        Observer.Expect('r_ge_count', Format(2 + Helper.InRows(20270131D, 99991231D)));
        Observer.Expect('r_closing_range_filter', 'C10/18/26..12/31/9999');
        // A plain date sorts before the closing date of the same day, so only later days are in range.
        Observer.Expect('r_closing_range_count', Format(6 + Helper.InRows(20261019D, 99991231D)));
        Observer.Expect('r_ne_filter', '<>01/17/27');
        Observer.Expect('r_ne_count', Format(7 + 2 - Helper.InRows(20270117D, 20270117D)));
        Observer.Expect('language_unchanged', 'Yes');
        Observer.Verify();
    end;
}
