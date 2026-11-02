// Install-order probe of cross-app fixture D (writer Y8): logs which rows of fixture A's table 61180 it sees during its own install, then writes
// row 10 with Insert(true). See tests/al-language-xapp-a/Y8XaInstallOrder.al. Install code must never fail: the helper writes only
// `if Insert(..) then;` into DataPerCompany = false tables.

codeunit 61190 "LT Y8 XD Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Helper: Codeunit "LT Y8 XA Install Helper";
    begin
        Helper.LogAndWrite('D', 10);
    end;
}

// Writer Y64 (al-runner issue 6644): install code of D arms fixture A's hub 61351, raises its event and logs telemetry (Probe); the subscribers of
// D below note the app whose install they ran in. B (no dependency path to D) has the same pair. See tests/al-language-xapp-a/Y64XaObjects.al.
// Install code must never fail: the only write is `if Insert() then;` into the DataPerCompany = false table 61354.
codeunit 61365 "LT Y64 XD Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        Hub.Probe('D', 'db');
    end;

    trigger OnInstallAppPerCompany()
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        Hub.Probe('D', 'co');
    end;
}

codeunit 61366 "LT Y64 XD Install Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y64 XA Install Hub", 'OnY64InstallProbe', '', false, false)]
    local procedure OnProbe(InstallingApp: Text)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('D-sub|' + InstallingApp);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Loggers", 'OnRegisterTelemetryLogger', '', false, false)]
    local procedure OnRegisterTelemetryLogger(var Sender: Codeunit "Telemetry Loggers")
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('D-tel|' + Hub.Armed());
    end;
}
