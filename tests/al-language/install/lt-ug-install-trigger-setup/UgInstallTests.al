// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (69160); read only: LT UG Setup Log (90363), written by the install subscribers and the trigger setup subscriber of
//   UgInstallFixtures.al while this app was installed.
// Probe: outside issue 6148, see UgInstallFixtures.al.
// BC versions: 27 - 29
codeunit 90367 "LT UG Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        exit('company');
    end;

    [Test]
    procedure TriggerSetup_AskedDuringInstall_CompanyAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT UG Setup Log";
    begin
        Log.SetCurrentKey(Id);
        if Log.FindSet() then
            repeat
                Observer.Observe('row #' + Format(Log.Id), 'table ' + Format(Log."Table Id") + '|' + Tag(Log."Company") + '|context=' + Log."Context" + '|part=' + Log."Install Part" + '|' + Log.Info);
            until Log.Next() = 0;
        Observer.Observe('rows', Format(Log.Count()));
        Observer.Finish();
    end;
}
