// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 91500
// Probe: observe probe (writer Y11, 2026-10-30, al-runner issue 6410); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: the number in "Primary Language ID" of the Windows Language virtual table for a broad set of LCIDs: primary cultures
//   (1030 da-DK, 1031 de-DE, 1033 en-US, ...), regional cultures of the same language (3079 de-AT, 2057 en-GB, 2070 pt-PT, ...),
//   Chinese, Arabic, Serbian and other scripts, and ids that have no row. Each value is "<Language Tag>|<Primary Language ID>",
//   or "no row" when Get fails. record/TestWindowsLanguageTable.al pins only that en-US and en-GB share the value.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure WindowsLanguage_PrimaryLanguageId_AsianAndScripts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveId(Observer, 2052);
        ObserveId(Observer, 1028);
        ObserveId(Observer, 3076);
        ObserveId(Observer, 4100);
        ObserveId(Observer, 5124);
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
