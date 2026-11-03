// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getrangemin-method
// Scope: in-scope. GetRangeMin and GetRangeMax of a Date field filtered by text in short forms (4, 6 and 8 digits, with separators).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained objects 67358 (table) and 67359 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter(Field, '0201'), '02012026', '02-01-26', '2026-02-01' and, in a German session (language 1031), '020126'; the answers of GetRangeMin and GetRangeMax (as XML dates, Format(Date, 0, 9)).
//   Forms without a year take it from a date: WorkDate is set to a fixed date, the test is run with two different WorkDates, so the answers do not depend on the day the test runs.
//   Corpus issue 576 item 4.
// BC versions: 27, 28, 29

table 67358 "LT DTF Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Day; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67359 "LT DTF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRange(FilterText: Text; var Result: Text)
    var
        Rec: Record "LT DTF Table";
    begin
        Rec.SetFilter(Day, FilterText);
        Result := Format(Rec.GetRangeMin(Day), 0, 9) + ' .. ' + Format(Rec.GetRangeMax(Day), 0, 9) + ' | filter ' + Rec.GetFilter(Day);
    end;

    local procedure Run(Name: Text; FilterText: Text; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
    begin
        ClearLastError();
        Result := '';
        if TryRange(FilterText, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure GetRange_DateTextForms_English()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('four_digits', '0201', Observer);
        Run('eight_digits', '02012026', Observer);
        Run('separators_short_year', '02-01-26', Observer);
        Run('separators_iso', '2026-02-01', Observer);
        Run('separators_slash_short_year', '02/01/26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('four_digits', 'ok:2031-02-01 .. 2031-02-01 | filter 02/01/31');
        Observer.Expect('eight_digits', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Expect('separators_short_year', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Expect('separators_iso', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Expect('separators_slash_short_year', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_FourDigits_OtherWorkDate()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2038));
        Run('four_digits', '0201', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('four_digits', 'ok:2038-02-01 .. 2038-02-01 | filter 02/01/38');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_SixDigits_German()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1031);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('six_digits', '020126', Observer);
        Run('eight_digits', '02012026', Observer);
        Run('four_digits', '0201', Observer);
        Run('separators_short_year', '02.01.26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('six_digits', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Expect('eight_digits', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Expect('four_digits', 'ok:2031-02-01 .. 2031-02-01 | filter 02/01/31');
        Observer.Expect('separators_short_year', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_SixDigits_English()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('six_digits', '020126', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('six_digits', 'ok:2026-02-01 .. 2026-02-01 | filter 02/01/26');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_DayAboveTwelve_English()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1033);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('dd_mm_four', '1301', Observer);
        Run('mm_dd_four', '0113', Observer);
        Run('dd_mm_yy_six', '130126', Observer);
        Run('mm_dd_yy_six', '011326', Observer);
        Run('dd_mm_yyyy_eight', '13012026', Observer);
        Run('mm_dd_yyyy_eight', '01132026', Observer);
        Run('dd_mm_yy_separators', '13-01-26', Observer);
        Run('mm_dd_yy_separators', '01-13-26', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('dd_mm_four', 'error:The filter "1301" is not valid for the Day field on the LT DTF Table table. The format of the Date ''1301'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('mm_dd_four', 'ok:2031-01-13 .. 2031-01-13 | filter 01/13/31');
        Observer.Expect('dd_mm_yy_six', 'error:The filter "130126" is not valid for the Day field on the LT DTF Table table. The format of the Date ''130126'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('mm_dd_yy_six', 'ok:2026-01-13 .. 2026-01-13 | filter 01/13/26');
        Observer.Expect('dd_mm_yyyy_eight', 'error:The filter "13012026" is not valid for the Day field on the LT DTF Table table. The format of the Date ''13012026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('mm_dd_yyyy_eight', 'ok:2026-01-13 .. 2026-01-13 | filter 01/13/26');
        Observer.Expect('dd_mm_yy_separators', 'error:The filter "13-01-26" is not valid for the Day field on the LT DTF Table table. The format of the Date ''13-01-26'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('mm_dd_yy_separators', 'ok:2026-01-13 .. 2026-01-13 | filter 01/13/26');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_DayAboveTwelve_German_ShortForms()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1031);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('dd_mm_four', '1301', Observer);
        Run('mm_dd_four', '0113', Observer);
        Run('dd_mm_yy_six', '130126', Observer);
        Run('mm_dd_yy_six', '011326', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('dd_mm_four', 'error:Der Filter ''1301'' ist für das Feld ''Day'' der Tabelle ''LT DTF Table'' nicht gültig. Das Format Date „1301“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Expect('mm_dd_four', 'ok:2031-01-13 .. 2031-01-13 | filter 01/13/31');
        Observer.Expect('dd_mm_yy_six', 'error:Der Filter ''130126'' ist für das Feld ''Day'' der Tabelle ''LT DTF Table'' nicht gültig. Das Format Date „130126“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Expect('mm_dd_yy_six', 'ok:2026-01-13 .. 2026-01-13 | filter 01/13/26');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_DayAboveTwelve_German_EightDigits()
    var
        Observer: Codeunit "Probe Observer";
        SavedLanguage: Integer;
        SavedWorkDate: Date;
    begin
        SavedLanguage := GlobalLanguage();
        SavedWorkDate := WorkDate();
        GlobalLanguage(1031);
        WorkDate(DMY2Date(15, 6, 2031));
        Run('dd_mm_yyyy_eight', '13012026', Observer);
        Run('mm_dd_yyyy_eight', '01132026', Observer);
        WorkDate(SavedWorkDate);
        GlobalLanguage(SavedLanguage);
        Observer.Expect('dd_mm_yyyy_eight', 'error:Der Filter ''13012026'' ist für das Feld ''Day'' der Tabelle ''LT DTF Table'' nicht gültig. Das Format Date „13012026“ stimmt nicht mit den Datumseinstellungen Ihres Geräts überein.\\Stellen Sie sicher, dass Tag, Monat und Jahr die richtige Reihenfolge aufweisen und das richtige Trennzeichen verwendet wird (z. b. - oder /). Alternativ können Sie das Format „jjjj-mm-tt“ verwenden.|Filter:CSide');
        Observer.Expect('mm_dd_yyyy_eight', 'ok:2026-01-13 .. 2026-01-13 | filter 01/13/26');
        Observer.Verify();
    end;
}
