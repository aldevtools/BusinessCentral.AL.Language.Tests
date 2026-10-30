// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 91500
// Probe: observe probe (writer Y11, 2026-10-30, al-runner issue 6410); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: the number in "Primary Language ID" of the Windows Language virtual table for a broad set of LCIDs: primary cultures
//   (1030 da-DK, 1031 de-DE, 1033 en-US, ...), regional cultures of the same language (3079 de-AT, 2057 en-GB, 2070 pt-PT, ...),
//   Chinese, Arabic, Serbian and other scripts, and ids that have no row. Each value is "<Language Tag>|<Primary Language ID>",
//   or "no row" when Get fails. record/TestWindowsLanguageTable.al pins only that en-US and en-GB share the value.
// Result (SaaS BC 29): the value is a full LCID, the LCID of the language's primary culture: 3079 de-AT -> 1031, 2057 en-GB -> 1033, 2070 pt-PT -> 1046.
//   Not always the "-<country of the language>" culture: 2052 zh-CN -> 1028 (zh-TW), 9242 sr-Latn-RS and 10266 sr-Cyrl-RS -> 1050 (hr-HR),
//   2108 ga-IE -> 1084. The Chinese regional rows 1028, 3076, 4100, 5124 differ on the Linux CI legs and are held (no [Test]) until a Windows check. 2074 and 3098 (old Serbian ids) and 0, 6, 9, 127, 1024, 2048, 4096, 99999 have no row.
// BC versions: 27, 28, 29

codeunit 91500 "LT Y11 WinLang Primary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveId(var Observer: Codeunit "Probe Observer"; Id: Integer)
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if WindowsLanguage.Get(Id) then
            Observer.Observe(Format(Id), WindowsLanguage."Language Tag" + '|' + Format(WindowsLanguage."Primary Language ID"))
        else
            Observer.Observe(Format(Id), 'no row');
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_GermanicAndNordic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 1030);
        ObserveId(Observer, 1031);
        ObserveId(Observer, 3079);
        ObserveId(Observer, 2055);
        ObserveId(Observer, 4103);
        ObserveId(Observer, 5127);
        ObserveId(Observer, 1043);
        ObserveId(Observer, 2067);
        ObserveId(Observer, 1044);
        ObserveId(Observer, 2068);
        ObserveId(Observer, 1053);
        ObserveId(Observer, 2077);
        ObserveId(Observer, 1035);
        ObserveId(Observer, 1039);
        ObserveId(Observer, 1078);
        Observer.Expect('1030', 'da-DK|1030');
        Observer.Expect('1031', 'de-DE|1031');
        Observer.Expect('3079', 'de-AT|1031');
        Observer.Expect('2055', 'de-CH|1031');
        Observer.Expect('4103', 'de-LU|1031');
        Observer.Expect('5127', 'de-LI|1031');
        Observer.Expect('1043', 'nl-NL|1043');
        Observer.Expect('2067', 'nl-BE|1043');
        Observer.Expect('1044', 'nb-NO|1044');
        Observer.Expect('2068', 'nn-NO|1044');
        Observer.Expect('1053', 'sv-SE|1053');
        Observer.Expect('2077', 'sv-FI|1053');
        Observer.Expect('1035', 'fi-FI|1035');
        Observer.Expect('1039', 'is-IS|1039');
        Observer.Expect('1078', 'af-ZA|1078');
        Observer.Verify();
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 1033);
        ObserveId(Observer, 2057);
        ObserveId(Observer, 3081);
        ObserveId(Observer, 4105);
        ObserveId(Observer, 5129);
        ObserveId(Observer, 6153);
        ObserveId(Observer, 7177);
        ObserveId(Observer, 8201);
        ObserveId(Observer, 10249);
        ObserveId(Observer, 11273);
        ObserveId(Observer, 12297);
        ObserveId(Observer, 13321);
        ObserveId(Observer, 16393);
        ObserveId(Observer, 17417);
        ObserveId(Observer, 18441);
        Observer.Expect('1033', 'en-US|1033');
        Observer.Expect('2057', 'en-GB|1033');
        Observer.Expect('3081', 'en-AU|1033');
        Observer.Expect('4105', 'en-CA|1033');
        Observer.Expect('5129', 'en-NZ|1033');
        Observer.Expect('6153', 'en-IE|1033');
        Observer.Expect('7177', 'en-ZA|1033');
        Observer.Expect('8201', 'en-JM|1033');
        Observer.Expect('10249', 'en-BZ|1033');
        Observer.Expect('11273', 'en-TT|1033');
        Observer.Expect('12297', 'en-ZW|1033');
        Observer.Expect('13321', 'en-PH|1033');
        Observer.Expect('16393', 'en-IN|1033');
        Observer.Expect('17417', 'en-MY|1033');
        Observer.Expect('18441', 'en-SG|1033');
        Observer.Verify();
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_Romance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 1036);
        ObserveId(Observer, 2060);
        ObserveId(Observer, 3084);
        ObserveId(Observer, 4108);
        ObserveId(Observer, 5132);
        ObserveId(Observer, 1040);
        ObserveId(Observer, 2064);
        ObserveId(Observer, 1034);
        ObserveId(Observer, 3082);
        ObserveId(Observer, 2058);
        ObserveId(Observer, 11274);
        ObserveId(Observer, 13322);
        ObserveId(Observer, 1046);
        ObserveId(Observer, 2070);
        ObserveId(Observer, 1048);
        ObserveId(Observer, 1027);
        Observer.Expect('1036', 'fr-FR|1036');
        Observer.Expect('2060', 'fr-BE|1036');
        Observer.Expect('3084', 'fr-CA|1036');
        Observer.Expect('4108', 'fr-CH|1036');
        Observer.Expect('5132', 'fr-LU|1036');
        Observer.Expect('1040', 'it-IT|1040');
        Observer.Expect('2064', 'it-CH|1040');
        Observer.Expect('1034', 'es-ES|1034');
        Observer.Expect('3082', 'es-ES|1034');
        Observer.Expect('2058', 'es-MX|1034');
        Observer.Expect('11274', 'es-AR|1034');
        Observer.Expect('13322', 'es-CL|1034');
        Observer.Expect('1046', 'pt-BR|1046');
        Observer.Expect('2070', 'pt-PT|1046');
        Observer.Expect('1048', 'ro-RO|1048');
        Observer.Expect('1027', 'ca-ES|1027');
        Observer.Verify();
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_AsianAndScripts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 2052);
        ObserveId(Observer, 1041);
        ObserveId(Observer, 1042);
        ObserveId(Observer, 1025);
        ObserveId(Observer, 14337);
        ObserveId(Observer, 3073);
        ObserveId(Observer, 1037);
        ObserveId(Observer, 1054);
        ObserveId(Observer, 1066);
        ObserveId(Observer, 1057);
        ObserveId(Observer, 1086);
        ObserveId(Observer, 2110);
        ObserveId(Observer, 1081);
        Observer.Expect('2052', 'zh-CN|1028');
        Observer.Expect('1041', 'ja-JP|1041');
        Observer.Expect('1042', 'ko-KR|1042');
        Observer.Expect('1025', 'ar-SA|1025');
        Observer.Expect('14337', 'ar-AE|1025');
        Observer.Expect('3073', 'ar-EG|1025');
        Observer.Expect('1037', 'he-IL|1037');
        Observer.Expect('1054', 'th-TH|1054');
        Observer.Expect('1066', 'vi-VN|1066');
        Observer.Expect('1057', 'id-ID|1057');
        Observer.Expect('1086', 'ms-MY|1086');
        Observer.Expect('2110', 'ms-BN|1086');
        Observer.Expect('1081', 'hi-IN|1081');
        Observer.Verify();
    end;

    // Linux suspect, no [Test] attribute until the Windows check: the corpus CI legs run BC in a Linux container, where the Chinese regional
    // rows differ from the SaaS sandbox (BC 29, Windows): 1028 has no row on the 27.5 and 28.5 legs, 3076 has no row on the 29.0 leg (run
    // 41134136570). The values below are the SaaS ones. 2052 zh-CN -> 1028 holds on every leg and is asserted in the test above.
    procedure WindowsLanguage_PrimaryLanguageId_ChineseRegional_HeldLinuxSuspect()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 1028);
        ObserveId(Observer, 3076);
        ObserveId(Observer, 4100);
        ObserveId(Observer, 5124);
        Observer.Expect('1028', 'zh-TW|1028');
        Observer.Expect('3076', 'zh-HK|1028');
        Observer.Expect('4100', 'zh-SG|1028');
        Observer.Expect('5124', 'zh-MO|1028');
        Observer.Verify();
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_SlavicBalticAndOthers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 1049);
        ObserveId(Observer, 1045);
        ObserveId(Observer, 1029);
        ObserveId(Observer, 1051);
        ObserveId(Observer, 1060);
        ObserveId(Observer, 1050);
        ObserveId(Observer, 2074);
        ObserveId(Observer, 3098);
        ObserveId(Observer, 9242);
        ObserveId(Observer, 10266);
        ObserveId(Observer, 1038);
        ObserveId(Observer, 1032);
        ObserveId(Observer, 1055);
        ObserveId(Observer, 1061);
        ObserveId(Observer, 1062);
        ObserveId(Observer, 1063);
        ObserveId(Observer, 1058);
        ObserveId(Observer, 1026);
        Observer.Expect('1049', 'ru-RU|1049');
        Observer.Expect('1045', 'pl-PL|1045');
        Observer.Expect('1029', 'cs-CZ|1029');
        Observer.Expect('1051', 'sk-SK|1051');
        Observer.Expect('1060', 'sl-SI|1060');
        Observer.Expect('1050', 'hr-HR|1050');
        Observer.Expect('2074', 'no row');
        Observer.Expect('3098', 'no row');
        Observer.Expect('9242', 'sr-Latn-RS|1050');
        Observer.Expect('10266', 'sr-Cyrl-RS|1050');
        Observer.Expect('1038', 'hu-HU|1038');
        Observer.Expect('1032', 'el-GR|1032');
        Observer.Expect('1055', 'tr-TR|1055');
        Observer.Expect('1061', 'et-EE|1061');
        Observer.Expect('1062', 'lv-LV|1062');
        Observer.Expect('1063', 'lt-LT|1063');
        Observer.Expect('1058', 'uk-UA|1058');
        Observer.Expect('1026', 'bg-BG|1026');
        Observer.Verify();
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_UnusualIds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 0);
        ObserveId(Observer, 6);
        ObserveId(Observer, 9);
        ObserveId(Observer, 127);
        ObserveId(Observer, 1024);
        ObserveId(Observer, 2048);
        ObserveId(Observer, 4096);
        ObserveId(Observer, 99999);
        ObserveId(Observer, 2108);
        ObserveId(Observer, 1106);
        ObserveId(Observer, 1110);
        ObserveId(Observer, 1069);
        Observer.Expect('0', 'no row');
        Observer.Expect('6', 'no row');
        Observer.Expect('9', 'no row');
        Observer.Expect('127', 'no row');
        Observer.Expect('1024', 'no row');
        Observer.Expect('2048', 'no row');
        Observer.Expect('4096', 'no row');
        Observer.Expect('99999', 'no row');
        Observer.Expect('2108', 'ga-IE|1084');
        Observer.Expect('1106', 'cy-GB|1106');
        Observer.Expect('1110', 'gl-ES|1110');
        Observer.Expect('1069', 'eu-ES|1069');
        Observer.Verify();
    end;
}
