// Helper of cross-app fixture A for the first-install DataVersion probe (al-runner issue 6367, writer X3). Not an install codeunit.
// The install codeunit of fixture B (al-language-xapp-b/X3XbFirstInstall.al) calls these procedures with its own app id while its install runs,
// the shape of a shared "environment information" codeunit in a dependency app. Nothing here writes or raises.
codeunit 61130 "LT X3 XA Env Info"
{
    procedure DataVersionOf(AppId: Guid): Text
    var
        Info: ModuleInfo;
    begin
        if not NavApp.GetModuleInfo(AppId, Info) then
            exit('<not found>');
        exit(Format(Info.DataVersion()));
    end;

    procedure AppVersionOf(AppId: Guid): Text
    var
        Info: ModuleInfo;
    begin
        if not NavApp.GetModuleInfo(AppId, Info) then
            exit('<not found>');
        exit(Format(Info.AppVersion()));
    end;

    procedure DataMajorOf(AppId: Guid): Integer
    var
        Info: ModuleInfo;
    begin
        if not NavApp.GetModuleInfo(AppId, Info) then
            exit(-1);
        exit(Info.DataVersion().Major());
    end;

    procedure CallerDataVersion(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(Info);
        exit(Format(Info.DataVersion()));
    end;

    procedure CallerAppVersion(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(Info);
        exit(Format(Info.AppVersion()));
    end;

    procedure OwnDataVersion(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Format(Info.DataVersion()));
    end;
}
