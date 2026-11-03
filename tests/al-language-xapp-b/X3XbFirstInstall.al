// Install code of cross-app fixture B for the first-install DataVersion probe (al-runner issue 6367, writer X3).
// While fixture B is installed, its install codeunit records ModuleInfo.DataVersion and AppVersion of fixture B as seen by
//   (a) its own code: NavApp.GetCurrentModuleInfo and NavApp.GetModuleInfo(own app id);
//   (b) code of the dependency fixture A ("LT X3 XA Env Info", 61130): NavApp.GetModuleInfo(fixture B's app id), GetCallerModuleInfo, and A's own DataVersion.
// The test "LT X3 First Install Versions" (90800, tests/al-language/install/lt-x3-first-install/) reads the rows back.
// Install code must never fail (check-install-triggers.py): every write is `if Insert() then;` into a DataPerCompany = false table, nothing else
// writes or raises. The per-company trigger runs once per company; the first company's rows are kept.
table 61140 "LT X3 XB Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Code; Code[40]) { }
        field(2; Txt; Text[250]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 61141 "LT X3 XB Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        LogVersions('PC');
    end;

    trigger OnInstallAppPerDatabase()
    begin
        LogVersions('PD');
    end;

    local procedure LogVersions(Prefix: Text)
    var
        Current: ModuleInfo;
        ById: ModuleInfo;
        EnvInfo: Codeunit "LT X3 XA Env Info";
    begin
        NavApp.GetCurrentModuleInfo(Current);
        Add(Prefix + ' OWN CURRENT DATA', Format(Current.DataVersion()));
        Add(Prefix + ' OWN CURRENT APP', Format(Current.AppVersion()));
        if NavApp.GetModuleInfo(Current.Id(), ById) then begin
            Add(Prefix + ' OWN BYID DATA', Format(ById.DataVersion()));
            Add(Prefix + ' OWN BYID APP', Format(ById.AppVersion()));
        end else
            Add(Prefix + ' OWN BYID DATA', '<not found>');
        Add(Prefix + ' LIB DATA', EnvInfo.DataVersionOf(Current.Id()));
        Add(Prefix + ' LIB APP', EnvInfo.AppVersionOf(Current.Id()));
        Add(Prefix + ' LIB DATA MAJOR', Format(EnvInfo.DataMajorOf(Current.Id())));
        Add(Prefix + ' LIB CALLER DATA', EnvInfo.CallerDataVersion());
        Add(Prefix + ' LIB CALLER APP', EnvInfo.CallerAppVersion());
        Add(Prefix + ' LIB OWN DATA', EnvInfo.OwnDataVersion());
    end;

    local procedure Add(RowCode: Text; Txt: Text)
    var
        Row: Record "LT X3 XB Install Log";
    begin
        Row.Code := CopyStr(RowCode, 1, MaxStrLen(Row.Code));
        Row.Txt := CopyStr(Txt, 1, MaxStrLen(Row.Txt));
        if Row.Insert() then;
    end;
}
