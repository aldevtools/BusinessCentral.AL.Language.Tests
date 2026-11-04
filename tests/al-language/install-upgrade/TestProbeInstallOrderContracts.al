// Dialog no-op probe (from writer A): Dialog.Open / Update / Close in a test do not raise. The install trigger probes of the same batch are not published: a per-company table
// written from OnInstallAppPerDatabase fails the install of the whole app with "You must choose a company before you can access the ... table." (an install trigger must never be
// a probe: one failing install breaks the corpus app on every BC version).
codeunit 69820 "PA Dialog Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Dialog_OpenUpdateClose()
    var
        O: Codeunit "Probe Observer";
        D: Dialog;
    begin
        D.Open('Working #1######');
        D.Update(1, 'x');
        D.Update();
        D.Close();
        O.Observe('dialog_open_update_close', 'no error');
        O.Expect('dialog_open_update_close', 'no error');
        O.Verify();
    end;
}
