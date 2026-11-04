// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); reads the platform table "Windows Language" (2000000045), writes nothing
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: rows of "Windows Language" for LCIDs the Microsoft tests filter on (1026, 1030, 1043 and more): Get, Name, Language Tag, Abbreviated Name; SetRange and SetFilter on "Language ID" with these ids (count, first row, order)
// Windows check (writer Y52, 2026-11-01): the Linux CI containers build this table from ICU culture data and differ from Windows and SaaS
//   (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:9-17). The [Test] procedures assert only what Windows and Linux agree on; the Suspect_ procedure (no [Test]) holds the Windows/SaaS
//   value of id 1034 (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, measured by writer Y39). Linux CI gave 'Spanish (Spain, Sort Order=tradnl)'.
// BC versions: 29 (27 and 28 by CI)

codeunit 74043 "LT P133 Windows Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(Id: Integer): Text
    var
        WinLang: Record "Windows Language";
    begin
        if not WinLang.Get(Id) then
            exit('(no row)');
        exit(WinLang.Name + '|' + WinLang."Language Tag" + '|' + WinLang."Abbreviated Name" + '|' + Format(WinLang."Language ID"));
    end;

    local procedure Ids(var WinLang: Record "Windows Language"): Text
    var
        Result: Text;
    begin
        if WinLang.FindSet() then
            repeat
                Result += Format(WinLang."Language ID") + ',';
            until WinLang.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure P133_WindowsLanguage_Get_EuropeanIds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1026', Describe(1026));
        Observer.Observe('1029', Describe(1029));
        Observer.Observe('1030', Describe(1030));
        Observer.Observe('1032', Describe(1032));
        Observer.Observe('1035', Describe(1035));
        Observer.Observe('1036', Describe(1036));
        Observer.Observe('1038', Describe(1038));
        Observer.Observe('1040', Describe(1040));
        Observer.Observe('1043', Describe(1043));
        Observer.Observe('1044', Describe(1044));
        Observer.Observe('1045', Describe(1045));
        Observer.Observe('1046', Describe(1046));
        Observer.Observe('1049', Describe(1049));
        Observer.Observe('1053', Describe(1053));
        Observer.Observe('1055', Describe(1055));
        Observer.Expect('1026', 'Bulgarian (Bulgaria)|bg-BG|BGR|1026');
        Observer.Expect('1029', 'Czech (Czechia)|cs-CZ|CSY|1029');
        Observer.Expect('1030', 'Danish (Denmark)|da-DK|DAN|1030');
        Observer.Expect('1032', 'Greek (Greece)|el-GR|ELL|1032');
        Observer.Expect('1035', 'Finnish (Finland)|fi-FI|FIN|1035');
        Observer.Expect('1036', 'French (France)|fr-FR|FRA|1036');
        Observer.Expect('1038', 'Hungarian (Hungary)|hu-HU|HUN|1038');
        Observer.Expect('1040', 'Italian (Italy)|it-IT|ITA|1040');
        Observer.Expect('1043', 'Dutch (Netherlands)|nl-NL|NLD|1043');
        Observer.Expect('1044', 'Norwegian Bokmål (Norway)|nb-NO|NOR|1044');
        Observer.Expect('1045', 'Polish (Poland)|pl-PL|PLK|1045');
        Observer.Expect('1046', 'Portuguese (Brazil)|pt-BR|PTB|1046');
        Observer.Expect('1049', 'Russian (Russia)|ru-RU|RUS|1049');
        Observer.Expect('1053', 'Swedish (Sweden)|sv-SE|SVE|1053');
        Observer.Expect('1055', 'Turkish (Türkiye)|tr-TR|TRK|1055');
        Observer.Verify();
    end;

    // Held: Linux suspect, Windows 27.5/28.5 and SaaS 29 value (record/lt-y39-windows-language-table/Y39WindowsLanguageTable.al:72-319, id 1034; :897).
    procedure Suspect_P133_WindowsLanguage_Get_SpanishTraditionalSort()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1034', Describe(1034));
        Observer.Expect('1034', 'Spanish (Spain, Traditional Sort)|es-ES|ESP|1034');
        Observer.Verify();
    end;

    [Test]
    procedure P133_WindowsLanguage_Filters_OnNameAndTag()
    var
        Observer: Codeunit "Probe Observer";
        WinLang: Record "Windows Language";
    begin
        WinLang.SetRange("Language Tag", 'bg-BG');
        Observer.Observe('tag bg-BG ids', Ids(WinLang));
        WinLang.SetRange("Language Tag", 'da-DK');
        Observer.Observe('tag da-DK ids', Ids(WinLang));
        WinLang.SetRange("Language Tag", 'nl-NL');
        Observer.Observe('tag nl-NL ids', Ids(WinLang));
        WinLang.SetRange("Language Tag", 'DA-dk');
        Observer.Observe('tag DA-dk (other case) ids', Ids(WinLang));
        WinLang.SetRange("Language Tag");
        WinLang.SetRange("Abbreviated Name", 'DAN');
        Observer.Observe('abbr DAN ids', Ids(WinLang));
        WinLang.SetRange("Abbreviated Name", 'NLD');
        Observer.Observe('abbr NLD ids', Ids(WinLang));
        WinLang.SetRange("Abbreviated Name", 'BGR');
        Observer.Observe('abbr BGR ids', Ids(WinLang));
        Observer.Expect('tag bg-BG ids', '1026,');
        Observer.Expect('tag da-DK ids', '1030,');
        Observer.Expect('tag nl-NL ids', '1043,');
        Observer.Expect('tag DA-dk (other case) ids', '');
        Observer.Expect('abbr DAN ids', '1030,');
        Observer.Expect('abbr NLD ids', '1043,');
        Observer.Expect('abbr BGR ids', '1026,');
        Observer.Verify();
    end;
}
