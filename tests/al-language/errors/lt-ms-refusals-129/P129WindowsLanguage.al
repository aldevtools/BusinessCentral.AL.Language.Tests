// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73259
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: rows of the system table "Windows Language" (read only) for many language ids besides 1031, 1033 and 2057: whether Get finds the id and its Name, Language Tag, Abbreviated Name and
// Primary CodePage; the count and the ids of a range filter (1030..1045), a filter on several ids and the id order of the rows.
// Windows check (writer Y52, 2026-11-01): the Linux CI containers build this table from ICU culture data and differ from Windows and SaaS
//   (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:9-17). The [Test] procedures assert only what Windows and Linux agree on; the Suspect_ procedure (no [Test]) holds the Windows/SaaS
//   value of ids 1034, 3082 and 2052 (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, measured by writer Y39). Linux CI gave 'Spanish (Spain, Sort Order=tradnl)', 'Spanish (Spain)' and 'Chinese (China)'.
// BC versions: 29 (27 and 28 by CI)

codeunit 73259 "LT P129 Windows Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(Id: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if not WindowsLanguage.Get(Id) then
            exit('no row');
        exit(WindowsLanguage.Name + '|' + WindowsLanguage."Language Tag" + '|' + WindowsLanguage."Abbreviated Name" + '|' + WindowsLanguage."Primary CodePage" + '|' + Format(WindowsLanguage."Language ID" = Id));
    end;

    local procedure IdsOf(var WindowsLanguage: Record "Windows Language"): Text
    var
        Ids: Text;
    begin
        if WindowsLanguage.FindSet() then
            repeat
                Ids += Format(WindowsLanguage."Language ID") + ',';
            until WindowsLanguage.Next() = 0;
        exit(Ids);
    end;

    [Test]
    procedure P129_WindowsLanguage_Get_NordicAndWestern()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1030', Row(1030));
        Observer.Observe('1035', Row(1035));
        Observer.Observe('1036', Row(1036));
        Observer.Observe('1040', Row(1040));
        Observer.Observe('1043', Row(1043));
        Observer.Observe('1044', Row(1044));
        Observer.Observe('1053', Row(1053));
        Observer.Observe('2070', Row(2070));
        Observer.Expect('1030', 'Danish (Denmark)|da-DK|DAN|850|Yes');
        Observer.Expect('1035', 'Finnish (Finland)|fi-FI|FIN|850|Yes');
        Observer.Expect('1036', 'French (France)|fr-FR|FRA|850|Yes');
        Observer.Expect('1040', 'Italian (Italy)|it-IT|ITA|850|Yes');
        Observer.Expect('1043', 'Dutch (Netherlands)|nl-NL|NLD|850|Yes');
        Observer.Expect('1044', 'Norwegian Bokmål (Norway)|nb-NO|NOR|850|Yes');
        Observer.Expect('1053', 'Swedish (Sweden)|sv-SE|SVE|850|Yes');
        Observer.Expect('2070', 'Portuguese (Portugal)|pt-PT|PTG|850|Yes');
        Observer.Verify();
    end;

    // Held: Linux suspect, Windows 27.5/28.5 and SaaS 29 values (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, ids 1034, 3082; :897).
    procedure Suspect_P129_WindowsLanguage_Get_SpanishSortOrders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1034', Row(1034));
        Observer.Observe('3082', Row(3082));
        Observer.Expect('1034', 'Spanish (Spain, Traditional Sort)|es-ES|ESP|850|Yes');
        Observer.Expect('3082', 'Spanish (Spain, International Sort)|es-ES|ESN|850|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WindowsLanguage_Get_OtherLanguages()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1029', Row(1029));
        Observer.Observe('1038', Row(1038));
        Observer.Observe('1041', Row(1041));
        Observer.Observe('1045', Row(1045));
        Observer.Observe('1049', Row(1049));
        Observer.Observe('1055', Row(1055));
        Observer.Observe('2060', Row(2060));
        Observer.Observe('3079', Row(3079));
        Observer.Observe('4105', Row(4105));
        Observer.Observe('4108', Row(4108));
        Observer.Observe('1', Row(1));
        Observer.Observe('127', Row(127));
        Observer.Observe('4096', Row(4096));
        Observer.Expect('1029', 'Czech (Czechia)|cs-CZ|CSY|852|Yes');
        Observer.Expect('1038', 'Hungarian (Hungary)|hu-HU|HUN|852|Yes');
        Observer.Expect('1041', 'Japanese (Japan)|ja-JP|JPN|932|Yes');
        Observer.Expect('1045', 'Polish (Poland)|pl-PL|PLK|852|Yes');
        Observer.Expect('1049', 'Russian (Russia)|ru-RU|RUS|866|Yes');
        Observer.Expect('1055', 'Turkish (Türkiye)|tr-TR|TRK|857|Yes');
        Observer.Expect('2060', 'French (Belgium)|fr-BE|FRB|850|Yes');
        Observer.Expect('3079', 'German (Austria)|de-AT|DEA|850|Yes');
        Observer.Expect('4105', 'English (Canada)|en-CA|ENC|850|Yes');
        Observer.Expect('4108', 'French (Switzerland)|fr-CH|FRS|850|Yes');
        Observer.Expect('1', 'no row');
        Observer.Expect('127', 'no row');
        Observer.Expect('4096', 'no row');
        Observer.Verify();
    end;

    // Held: Linux suspect, Windows 27.5/28.5 and SaaS 29 value (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, id 2052).
    procedure Suspect_P129_WindowsLanguage_Get_ChineseSimplified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('2052', Row(2052));
        Observer.Expect('2052', 'Chinese (Simplified, China)|zh-CN|CHS|936|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WindowsLanguage_Filters_RangeAndSet()
    var
        Observer: Codeunit "Probe Observer";
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetRange("Language ID", 1030, 1045);
        Observer.Observe('range count', Format(WindowsLanguage.Count()));
        Observer.Observe('range ids', IdsOf(WindowsLanguage));
        WindowsLanguage.Reset();
        WindowsLanguage.SetFilter("Language ID", '1030|1031|1036|2057|1033');
        Observer.Observe('set count', Format(WindowsLanguage.Count()));
        Observer.Observe('set ids', IdsOf(WindowsLanguage));
        WindowsLanguage.Ascending(false);
        Observer.Observe('set ids descending', IdsOf(WindowsLanguage));
        WindowsLanguage.Reset();
        WindowsLanguage.SetRange("Language ID", 1030);
        Observer.Observe('1030 count', Format(WindowsLanguage.Count()));
        Observer.Observe('1030 isempty', Format(WindowsLanguage.IsEmpty()));
        WindowsLanguage.Reset();
        WindowsLanguage.SetFilter("Language ID", '>=1030&<=1031');
        Observer.Observe('1030..1031 ids', IdsOf(WindowsLanguage));
        WindowsLanguage.Reset();
        WindowsLanguage.SetFilter("Language ID", '<1040');
        Observer.Observe('below 1040 has first', Format(WindowsLanguage.FindFirst()));
        Observer.Observe('below 1040 first is lowest', Format(WindowsLanguage."Language ID" < 1040));
        Observer.Expect('range count', '16');
        Observer.Expect('range ids', '1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,');
        Observer.Expect('set count', '5');
        Observer.Expect('set ids', '1030,1031,1033,1036,2057,');
        Observer.Expect('set ids descending', '2057,1036,1033,1031,1030,');
        Observer.Expect('1030 count', '1');
        Observer.Expect('1030 isempty', 'No');
        Observer.Expect('1030..1031 ids', '1030,1031,');
        Observer.Expect('below 1040 has first', 'Yes');
        Observer.Expect('below 1040 first is lowest', 'Yes');
        Observer.Verify();
    end;
}
