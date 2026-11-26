// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: "Probe Observer" (codeunit 69160)
// Probe (observe only): Primary CodePage and the other columns of the system table Windows Language (2000000045) for the rows of
//   Unicode-only cultures (the 44 rows that Y39 holds under Utf8CodePage()) and for three controls (1033, 1031, 1049), on the latest
//   Windows BC 27, 28 and 29 builds, which run on .NET 10 (bc-linux issue 238). Each row is printed as
//   "<Primary CodePage>|<Name>|<Abbreviated Name>|<Enabled>|<Globally Enabled>|<Form>|<Report>|<Dataport>|<XMLport>|<STX>|<ETX>|<Help>|<Localization>|<Tag>".
//   The last test lists every row whose Primary CodePage is not a classic OEM page and the row count per Primary CodePage.
// BC versions: 27, 28, 29

codeunit 74945 "LT Y40 WinLang CodePage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(Ids: Text)
    var
        WindowsLanguage: Record "Windows Language";
        Observer: Codeunit "Probe Observer";
        Id: Text;
    begin
        foreach Id in Ids.Split(',') do
            if WindowsLanguage.Get(EvaluateId(Id)) then
                Observer.Observe(Id, WindowsLanguage."Primary CodePage" + '|' + WindowsLanguage.Name + '|' + WindowsLanguage."Abbreviated Name" + '|' +
                    Format(WindowsLanguage.Enabled) + '|' + Format(WindowsLanguage."Globally Enabled") + '|' + Format(WindowsLanguage."Form Enabled") + '|' +
                    Format(WindowsLanguage."Report Enabled") + '|' + Format(WindowsLanguage."Dataport Enabled") + '|' + Format(WindowsLanguage."XMLport Enabled") + '|' +
                    Format(WindowsLanguage."STX File Exist") + '|' + Format(WindowsLanguage."ETX File Exist") + '|' + Format(WindowsLanguage."Help File Exist") + '|' +
                    Format(WindowsLanguage."Localization Exist") + '|' + WindowsLanguage."Language Tag")
            else
                Observer.Observe(Id, 'no row');
        Observer.Finish();
    end;

    local procedure EvaluateId(Id: Text) Value: Integer
    begin
        Evaluate(Value, Id);
    end;

    [Test]
    procedure Controls_1033_1031_1049()
    begin
        Dump('1033,1031,1049');
    end;

    [Test]
    procedure UnicodeOnly_1067_1072_1073_1079_1081_1082_1087_1093()
    begin
        Dump('1067,1072,1073,1079,1081,1082,1087,1093');
    end;

    [Test]
    procedure UnicodeOnly_1094_1095_1096_1097_1098_1099_1100_1101()
    begin
        Dump('1094,1095,1096,1097,1098,1099,1100,1101');
    end;

    [Test]
    procedure UnicodeOnly_1102_1103_1105_1107_1108_1109_1111_1113()
    begin
        Dump('1102,1103,1105,1107,1108,1109,1111,1113');
    end;

    [Test]
    procedure UnicodeOnly_1114_1115_1116_1117_1118_1121_1123_1125()
    begin
        Dump('1114,1115,1116,1117,1118,1121,1123,1125');
    end;

    [Test]
    procedure UnicodeOnly_1138_1139_1143_1144_1153_2117_2121_2128()
    begin
        Dump('1138,1139,1143,1144,1153,2117,2121,2128');
    end;

    [Test]
    procedure UnicodeOnly_2145_2163_3152_4191()
    begin
        Dump('2145,2163,3152,4191');
    end;

    [Test]
    procedure AllRows_CodePageCounts_And_NonOemRows()
    var
        WindowsLanguage: Record "Windows Language";
        Observer: Codeunit "Probe Observer";
        Pages: Dictionary of [Text, Integer];
        PageKey: Text;
    begin
        if WindowsLanguage.FindSet() then
            repeat
                PageKey := '[' + Format(WindowsLanguage."Primary CodePage", 0, 9) + ']';
                if Pages.ContainsKey(PageKey) then
                    Pages.Set(PageKey, Pages.Get(PageKey) + 1)
                else
                    Pages.Add(PageKey, 1);
            until WindowsLanguage.Next() = 0;
        Observer.Observe('rows', Format(WindowsLanguage.Count(), 0, 9));
        foreach PageKey in Pages.Keys() do
            Observer.Observe('count' + PageKey, Format(Pages.Get(PageKey), 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure AllRows_NonOemRows_Ids()
    var
        WindowsLanguage: Record "Windows Language";
        Observer: Codeunit "Probe Observer";
        Ids: Dictionary of [Text, Text];
        PageKey: Text;
    begin
        if WindowsLanguage.FindSet() then
            repeat
                if not (WindowsLanguage."Primary CodePage" in ['437', '720', '737', '775', '850', '852', '855', '857', '862', '866', '874', '932', '936', '949', '950']) then begin
                    PageKey := '[' + Format(WindowsLanguage."Primary CodePage", 0, 9) + ']';
                    if Ids.ContainsKey(PageKey) then
                        Ids.Set(PageKey, Ids.Get(PageKey) + ',' + Format(WindowsLanguage."Language ID", 0, 9))
                    else
                        Ids.Add(PageKey, Format(WindowsLanguage."Language ID", 0, 9));
                end;
            until WindowsLanguage.Next() = 0;
        foreach PageKey in Ids.Keys() do
            Observer.Observe('ids' + PageKey, Ids.Get(PageKey));
        Observer.Finish();
    end;
}
