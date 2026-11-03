// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: rows of the system table Windows Language for language ids the corpus does not pin (1 and other neutral cultures, 9, 10, 12, 1034, 1036, 3079): found or not, Name, Language Tag, Abbreviated Name; a Language ID filter that takes in language 1 (range, comparison) and the first and last row of it
// Windows check (writer Y52, 2026-11-01): the Linux CI containers build this table from ICU culture data and differ from Windows and SaaS
//   (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:9-17). The [Test] procedures assert only what Windows and Linux agree on; the Suspect_ procedure (no [Test]) holds the Windows/SaaS
//   value of id 1034 (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, measured by writer Y39). Linux CI gave 'Spanish (Spain, Sort Order=tradnl)'.
// BC versions: 29 (27 and 28 by CI)

codeunit 74434 "LT P137 Win Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(var Observer: Codeunit "Probe Observer"; Id: Integer)
    var
        Lang: Record "Windows Language";
    begin
        if Lang.Get(Id) then
            Observer.Observe('get_' + Format(Id), 'Yes|' + Lang.Name + '|' + Lang."Language Tag" + '|' + Lang."Abbreviated Name")
        else
            Observer.Observe('get_' + Format(Id), 'No');
    end;

    [Test]
    procedure P137_WindowsLanguage_RowsByLanguageId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Row(Observer, 0);
        Row(Observer, 1);
        Row(Observer, 2);
        Row(Observer, 7);
        Row(Observer, 9);
        Row(Observer, 10);
        Row(Observer, 12);
        Row(Observer, 1036);
        Row(Observer, 3079);
        Row(Observer, 4105);
        Row(Observer, -1);
        Observer.Expect('get_0', 'No');
        Observer.Expect('get_1', 'No');
        Observer.Expect('get_2', 'No');
        Observer.Expect('get_7', 'No');
        Observer.Expect('get_9', 'No');
        Observer.Expect('get_10', 'No');
        Observer.Expect('get_12', 'No');
        Observer.Expect('get_1036', 'Yes|French (France)|fr-FR|FRA');
        Observer.Expect('get_3079', 'Yes|German (Austria)|de-AT|DEA');
        Observer.Expect('get_4105', 'Yes|English (Canada)|en-CA|ENC');
        Observer.Expect('get_-1', 'No');
        Observer.Verify();
    end;

    // Held: Linux suspect, Windows 27.5/28.5 and SaaS 29 value (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, id 1034; :897).
    procedure Suspect_P137_WindowsLanguage_RowsByLanguageId_Spanish()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Row(Observer, 1034);
        Observer.Expect('get_1034', 'Yes|Spanish (Spain, Traditional Sort)|es-ES|ESP');
        Observer.Verify();
    end;

    [Test]
    procedure P137_WindowsLanguage_LanguageIdFilters()
    var
        Observer: Codeunit "Probe Observer";
        Lang: Record "Windows Language";
    begin
        Lang.SetRange("Language ID", 1);
        Observer.Observe('range_1_count', Format(Lang.Count()));
        if Lang.FindFirst() then
            Observer.Observe('range_1_first', Format(Lang."Language ID") + '|' + Lang.Name)
        else
            Observer.Observe('range_1_first', 'none');
        Lang.SetFilter("Language ID", '1..10');
        Observer.Observe('range_1_10_count', Format(Lang.Count()));
        if Lang.FindFirst() then
            Observer.Observe('range_1_10_first', Format(Lang."Language ID"))
        else
            Observer.Observe('range_1_10_first', 'none');
        if Lang.FindLast() then
            Observer.Observe('range_1_10_last', Format(Lang."Language ID"))
        else
            Observer.Observe('range_1_10_last', 'none');
        Lang.SetFilter("Language ID", '<1000');
        Observer.Observe('below_1000_count', Format(Lang.Count()));
        Lang.SetFilter("Language ID", '1|1031|1033');
        Observer.Observe('or_count', Format(Lang.Count()));
        Lang.SetFilter("Language ID", '<>1033');
        Observer.Observe('not_1033_has_1031', Format(Lang.Get(1031)));
        Lang.Reset();
        Observer.Observe('total_has_rows', Format(Lang.Count() > 3));
        Observer.Expect('range_1_count', '0');
        Observer.Expect('range_1_first', 'none');
        Observer.Expect('range_1_10_count', '0');
        Observer.Expect('range_1_10_first', 'none');
        Observer.Expect('range_1_10_last', 'none');
        Observer.Expect('below_1000_count', '0');
        Observer.Expect('or_count', '2');
        Observer.Expect('not_1033_has_1031', 'Yes');
        Observer.Expect('total_has_rows', 'Yes');
        Observer.Verify();
    end;
}
