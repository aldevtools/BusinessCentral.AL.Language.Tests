// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-blob-storage-file-connectors
// Scope: in-scope
// Fixtures used: Probe Observer (69160); System Application "File Account" (External File Storage module)
// Probe (al-runner issue 6435, writer Y12): "File Account".GetAllAccounts from an app that depends on the System Application only, with no
// file connector app among its dependencies: whether it returns rows or raises an error. Object id 91552.

codeunit 91552 "LT Y12 File Account"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y12_GetAllAccounts_NoConnector()
    var
        TempFileAccount: Record "File Account" temporary;
        FileAccount: Codeunit "File Account";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ok', Format(TryGetAll(FileAccount, TempFileAccount)));
        Observer.ObserveError('error');
        Observer.Observe('count', Format(TempFileAccount.Count()));
        // A row already in the buffer: does GetAllAccounts empty it first?
        TempFileAccount.DeleteAll();
        TempFileAccount.Insert();
        Observer.Observe('prefilled_ok', Format(TryGetAll(FileAccount, TempFileAccount)));
        Observer.ObserveError('prefilled_error');
        Observer.Observe('prefilled_count', Format(TempFileAccount.Count()));
        Observer.Observe('connector_ordinals', Format(Enum::"Ext. File Storage Connector".Ordinals().Count()));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryGetAll(var FileAccount: Codeunit "File Account"; var TempFileAccount: Record "File Account" temporary)
    begin
        FileAccount.GetAllAccounts(TempFileAccount);
    end;
}
