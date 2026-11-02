// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-setencrypted-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 94076
// Probe (writer Y76, al-runtime-rs assumption isolated-storage-overwrite-tx): IsolatedStorage.SetEncrypted over a key that exists (plain or encrypted)
// and Set over a key stored encrypted, each right after a Commit: does Database.IsInWriteTransaction turn true. The plain form is pinned by
// session/lt-cn-session-leads/CnIsolatedStorageLeads.al TO_IsoOverwrite_OutsideWriteTransaction.
// Linux suspect: the Linux CI containers have no encryption key (SetEncrypted raises NavEncryptionKeyNotFoundException), so the encrypted forms are
// not [Test] procedures here; they were run on the Windows containers BC 27.5, 28.5 and 29.0 (writer Y76, 2026-11-02).
// BC versions: 27, 28, 29

codeunit 94076 "LT Y76 Iso Storage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Reset(KeyName: Text)
    begin
        if IsolatedStorage.Contains(KeyName, DataScope::Module) then
            IsolatedStorage.Delete(KeyName, DataScope::Module);
        Commit();
    end;

    local procedure Tx(): Text
    begin
        exit(Format(Database.IsInWriteTransaction()));
    end;

    [Test]
    procedure Suspect_EncryptedOverwrite_Transaction()
    begin
        Reset('LTY76iso');
        Obs.Observe('new_encrypted_ret', Format(IsolatedStorage.SetEncrypted('LTY76iso', 'v1', DataScope::Module)));
        Obs.Observe('new_encrypted_tx', Tx());
        Commit();
        Obs.Observe('before_encrypted_again', Tx());
        Obs.Observe('encrypted_again_ret', Format(IsolatedStorage.SetEncrypted('LTY76iso', 'v2', DataScope::Module)));
        Obs.Observe('encrypted_again_tx', Tx());
        Commit();
        Obs.Observe('encrypted_same_ret', Format(IsolatedStorage.SetEncrypted('LTY76iso', 'v2', DataScope::Module)));
        Obs.Observe('encrypted_same_tx', Tx());
        Commit();
        Obs.Observe('plain_over_encrypted_ret', Format(IsolatedStorage.Set('LTY76iso', 'v3', DataScope::Module)));
        Obs.Observe('plain_over_encrypted_tx', Tx());
        Commit();
        Obs.Observe('encrypted_over_plain_ret', Format(IsolatedStorage.SetEncrypted('LTY76iso', 'v4', DataScope::Module)));
        Obs.Observe('encrypted_over_plain_tx', Tx());
        Commit();
        Obs.Observe('plain_same_ret', Format(IsolatedStorage.Set('LTY76iso', 'v4', DataScope::Module)));
        Obs.Observe('plain_same_tx', Tx());
        Commit();
        Obs.Observe('contains_tx', Format(IsolatedStorage.Contains('LTY76iso', DataScope::Module)) + ' ' + Tx());
        Obs.Observe('delete_ret', Format(IsolatedStorage.Delete('LTY76iso', DataScope::Module)));
        Obs.Observe('delete_tx', Tx());
        Commit();
        Obs.Observe('delete_missing_ret', Format(IsolatedStorage.Delete('LTY76iso', DataScope::Module)));
        Obs.Observe('delete_missing_tx', Tx());
        Commit();
        Obs.Observe('plain_new_ret', Format(IsolatedStorage.Set('LTY76iso', 'v5', DataScope::Module)));
        Obs.Observe('plain_new_tx', Tx());
        Commit();
        IsolatedStorage.Delete('LTY76iso', DataScope::Module);
        Commit();
        Obs.Observe('encrypted_user_scope', Format(IsolatedStorage.SetEncrypted('LTY76iso', 'v6', DataScope::User)) + ' ' + Tx());
        Commit();
        Obs.Observe('encrypted_user_scope_again', Format(IsolatedStorage.SetEncrypted('LTY76iso', 'v7', DataScope::User)) + ' ' + Tx());
        Commit();
        IsolatedStorage.Delete('LTY76iso', DataScope::User);
        Commit();
        Obs.Finish();
    end;
}
