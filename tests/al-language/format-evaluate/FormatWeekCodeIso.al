// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-function
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: The <Week> picture code of Format on a Date: ISO 8601 week numbers around year boundaries (2020-12-31, 2021-01-03, 2024-12-30, 2026-01-01), mid-year weeks, padding with <Week,2>, with <Year4> and <Day> (assumption format-week-code-is-iso); types/lt-datetime/Format.al:156 pins one mid-March date only.
// BC versions: 29 (27 and 28 by CI)

codeunit 70659 "LT FmtWeek Iso"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Name: Text; D: Date)
    begin
        Observer.Observe(Name + '_week', Format(D, 0, '<Week>'));
        Observer.Observe(Name + '_week2', Format(D, 0, '<Week,2>'));
        Observer.Observe(Name + '_dwy', Format(Date2DWY(D, 2)));
    end;

    [Test]
    procedure Week_YearBoundaries_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'd20201231', DMY2Date(31, 12, 2020));
        Obs(Observer, 'd20210101', DMY2Date(1, 1, 2021));
        Obs(Observer, 'd20210103', DMY2Date(3, 1, 2021));
        Obs(Observer, 'd20210104', DMY2Date(4, 1, 2021));
        Obs(Observer, 'd20241229', DMY2Date(29, 12, 2024));
        Obs(Observer, 'd20241230', DMY2Date(30, 12, 2024));
        Obs(Observer, 'd20260101', DMY2Date(1, 1, 2026));
        Observer.Expect('d20201231_week', '53');
        Observer.Expect('d20201231_week2', '53');
        Observer.Expect('d20201231_dwy', '53');
        Observer.Expect('d20210101_week', '53');
        Observer.Expect('d20210101_week2', '53');
        Observer.Expect('d20210101_dwy', '53');
        Observer.Expect('d20210103_week', '53');
        Observer.Expect('d20210103_week2', '53');
        Observer.Expect('d20210103_dwy', '53');
        Observer.Expect('d20210104_week', '1');
        Observer.Expect('d20210104_week2', '01');
        Observer.Expect('d20210104_dwy', '1');
        Observer.Expect('d20241229_week', '52');
        Observer.Expect('d20241229_week2', '52');
        Observer.Expect('d20241229_dwy', '52');
        Observer.Expect('d20241230_week', '1');
        Observer.Expect('d20241230_week2', '01');
        Observer.Expect('d20241230_dwy', '1');
        Observer.Expect('d20260101_week', '1');
        Observer.Expect('d20260101_week2', '01');
        Observer.Expect('d20260101_dwy', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Week_Week53Years_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'd20151231', DMY2Date(31, 12, 2015));
        Obs(Observer, 'd20160101', DMY2Date(1, 1, 2016));
        Obs(Observer, 'd20161231', DMY2Date(31, 12, 2016));
        Obs(Observer, 'd20170101', DMY2Date(1, 1, 2017));
        Obs(Observer, 'd20181231', DMY2Date(31, 12, 2018));
        Obs(Observer, 'd20190101', DMY2Date(1, 1, 2019));
        Observer.Expect('d20151231_week', '53');
        Observer.Expect('d20151231_week2', '53');
        Observer.Expect('d20151231_dwy', '53');
        Observer.Expect('d20160101_week', '53');
        Observer.Expect('d20160101_week2', '53');
        Observer.Expect('d20160101_dwy', '53');
        Observer.Expect('d20161231_week', '52');
        Observer.Expect('d20161231_week2', '52');
        Observer.Expect('d20161231_dwy', '52');
        Observer.Expect('d20170101_week', '52');
        Observer.Expect('d20170101_week2', '52');
        Observer.Expect('d20170101_dwy', '52');
        Observer.Expect('d20181231_week', '1');
        Observer.Expect('d20181231_week2', '01');
        Observer.Expect('d20181231_dwy', '1');
        Observer.Expect('d20190101_week', '1');
        Observer.Expect('d20190101_week2', '01');
        Observer.Expect('d20190101_dwy', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Week_MidYearAndPadding_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'd20220307', DMY2Date(7, 3, 2022));
        Obs(Observer, 'd20220509', DMY2Date(9, 5, 2022));
        Obs(Observer, 'd20220711', DMY2Date(11, 7, 2022));
        Obs(Observer, 'd20221003', DMY2Date(3, 10, 2022));
        Observer.Expect('d20220307_week', '10');
        Observer.Expect('d20220307_week2', '10');
        Observer.Expect('d20220307_dwy', '10');
        Observer.Expect('d20220509_week', '19');
        Observer.Expect('d20220509_week2', '19');
        Observer.Expect('d20220509_dwy', '19');
        Observer.Expect('d20220711_week', '28');
        Observer.Expect('d20220711_week2', '28');
        Observer.Expect('d20220711_dwy', '28');
        Observer.Expect('d20221003_week', '40');
        Observer.Expect('d20221003_week2', '40');
        Observer.Expect('d20221003_dwy', '40');
        Observer.Verify();
    end;

    [Test]
    procedure Week_CombinedWithYearAndDay_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('week_year4_boundary', Format(DMY2Date(3, 1, 2021), 0, '<Week>.<Year4>'));
        Observer.Observe('week_year4_dec30', Format(DMY2Date(30, 12, 2024), 0, '<Week>.<Year4>'));
        Observer.Observe('week_year_short', Format(DMY2Date(1, 1, 2026), 0, '<Week>/<Year>'));
        Observer.Observe('week_day_month', Format(DMY2Date(1, 1, 2026), 0, '<Week> <Day> <Month>'));
        Observer.Observe('week_weekday', Format(DMY2Date(3, 1, 2021), 0, '<Week>-<Weekday>'));
        Observer.Observe('week_empty_date', Format(0D, 0, '<Week>'));
        Observer.Expect('week_year4_boundary', '53.2021');
        Observer.Expect('week_year4_dec30', '1.2024');
        Observer.Expect('week_year_short', '1/26');
        Observer.Expect('week_day_month', '1 1 1');
        Observer.Expect('week_weekday', '53-7');
        Observer.Expect('week_empty_date', '');
        Observer.Verify();
    end;
}
