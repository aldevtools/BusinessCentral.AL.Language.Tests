// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-setencrypted-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 94076
// Probe (writer Y76, al-runtime-rs assumption isolated-storage-overwrite-tx): IsolatedStorage.SetEncrypted over a key that exists (plain or encrypted)
// and Set over a key stored encrypted, each right after a Commit: does Database.IsInWriteTransaction turn true. The plain form is pinned by
// session/lt-cn-session-leads/CnIsolatedStorageLeads.al TO_IsoOverwrite_OutsideWriteTransaction.
// Linux suspect: the Linux CI containers have no encryption key (SetEncrypted raises NavEncryptionKeyNotFoundException), so the encrypted forms are
// not [Test] procedures here. They were run (as tests, with an encryption key created for the run) on the owner's Windows containers BC 27.5 and
// 28.5 and on the SaaS sandbox BC 29 (the Windows container BC 29.0 was down), writer Y76, 2026-11-02: the values asserted below are the same on all
// three. Facts: SetEncrypted over a key that exists (stored plain or encrypted), with the same or another value, and Set over a key stored encrypted,
// outside a write transaction, open the write transaction (Database.IsInWriteTransaction is true afterwards), as a plain Set over a plain key does.
// The Suspect_ procedures are not [Test] procedures: they are run by hand on a container that has an encryption key. The one [Test] procedure
// (Y76_PlainStorage_Transactions) pins the same questions for a plain key, which every container can run.
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

    local procedure RetTx(Ret: Boolean): Text
    begin
        exit('ret=' + Format(Ret) + ' tx=' + Format(Database.IsInWriteTransaction()));
    end;

    [Test]
    procedure Y76_PlainStorage_Transactions()
    begin
        Reset('LTY76plain');
        Obs.Observe('new_plain', RetTx(IsolatedStorage.Set('LTY76plain', 'v1', DataScope::Module)));
        Commit();
        Obs.Observe('before_plain_same', Tx());
        Obs.Observe('plain_same', RetTx(IsolatedStorage.Set('LTY76plain', 'v1', DataScope::Module)));
        Commit();
        Obs.Observe('plain_other', RetTx(IsolatedStorage.Set('LTY76plain', 'v2', DataScope::Module)));
        Commit();
        Obs.Observe('contains', Format(IsolatedStorage.Contains('LTY76plain', DataScope::Module)) + ' tx=' + Tx());
        Obs.Observe('delete', RetTx(IsolatedStorage.Delete('LTY76plain', DataScope::Module)));
        Commit();
        Obs.Observe('delete_missing', RetTx(IsolatedStorage.Delete('LTY76plain', DataScope::Module)));
        Commit();
        Obs.Observe('contains_missing', Format(IsolatedStorage.Contains('LTY76plain', DataScope::Module)) + ' tx=' + Tx());
        Obs.Expect('new_plain', 'ret=Yes tx=Yes');
        Obs.Expect('before_plain_same', 'No');
        Obs.Expect('plain_same', 'ret=Yes tx=Yes');
        Obs.Expect('plain_other', 'ret=Yes tx=Yes');
        Obs.Expect('contains', 'Yes tx=No');
        Obs.Expect('delete', 'ret=Yes tx=Yes');
        Obs.Expect('delete_missing', 'ret=No tx=Yes');
        Obs.Expect('contains_missing', 'No tx=No');
        Obs.Verify();
    end;

    procedure Suspect_EncryptedOverwrite_Transaction()
    var
        KeyCreated: Boolean;
    begin
        if not EncryptionKeyExists() then begin
            CreateEncryptionKey();
            KeyCreated := true;
            Commit();
        end;
        Reset('LTY76iso');
        Obs.Observe('new_encrypted', RetTx(IsolatedStorage.SetEncrypted('LTY76iso', 'v1', DataScope::Module)));
        Commit();
        Obs.Observe('before_encrypted_again', Tx());
        Obs.Observe('encrypted_again', RetTx(IsolatedStorage.SetEncrypted('LTY76iso', 'v2', DataScope::Module)));
        Commit();
        Obs.Observe('encrypted_same', RetTx(IsolatedStorage.SetEncrypted('LTY76iso', 'v2', DataScope::Module)));
        Commit();
        Obs.Observe('plain_over_encrypted', RetTx(IsolatedStorage.Set('LTY76iso', 'v3', DataScope::Module)));
        Commit();
        Obs.Observe('encrypted_over_plain', RetTx(IsolatedStorage.SetEncrypted('LTY76iso', 'v4', DataScope::Module)));
        Commit();
        Obs.Observe('plain_over_encrypted_again', RetTx(IsolatedStorage.Set('LTY76iso', 'v5', DataScope::Module)));
        Commit();
        Obs.Observe('plain_same', RetTx(IsolatedStorage.Set('LTY76iso', 'v5', DataScope::Module)));
        Commit();
        Obs.Observe('contains', Format(IsolatedStorage.Contains('LTY76iso', DataScope::Module)) + ' tx=' + Tx());
        Obs.Observe('delete', RetTx(IsolatedStorage.Delete('LTY76iso', DataScope::Module)));
        Commit();
        Obs.Observe('delete_missing', RetTx(IsolatedStorage.Delete('LTY76iso', DataScope::Module)));
        Commit();
        if KeyCreated then begin
            DeleteEncryptionKey();
            Commit();
        end;
        Obs.Expect('new_encrypted', 'ret=Yes tx=Yes');
        Obs.Expect('before_encrypted_again', 'No');
        Obs.Expect('encrypted_again', 'ret=Yes tx=Yes');
        Obs.Expect('encrypted_same', 'ret=Yes tx=Yes');
        Obs.Expect('plain_over_encrypted', 'ret=Yes tx=Yes');
        Obs.Expect('encrypted_over_plain', 'ret=Yes tx=Yes');
        Obs.Expect('plain_over_encrypted_again', 'ret=Yes tx=Yes');
        Obs.Expect('plain_same', 'ret=Yes tx=Yes');
        Obs.Expect('contains', 'Yes tx=No');
        Obs.Expect('delete', 'ret=Yes tx=Yes');
        Obs.Expect('delete_missing', 'ret=No tx=Yes');
        Obs.Verify();
    end;

    procedure Suspect_EncryptedOverwrite_OtherScopes()
    var
        KeyCreated: Boolean;
    begin
        if not EncryptionKeyExists() then begin
            CreateEncryptionKey();
            KeyCreated := true;
            Commit();
        end;
        Reset('LTY76iso2');
        Obs.Observe('new_encrypted_user', RetTx(IsolatedStorage.SetEncrypted('LTY76iso2', 'v1', DataScope::User)));
        Commit();
        Obs.Observe('encrypted_again_user', RetTx(IsolatedStorage.SetEncrypted('LTY76iso2', 'v2', DataScope::User)));
        Commit();
        Obs.Observe('plain_over_encrypted_user', RetTx(IsolatedStorage.Set('LTY76iso2', 'v3', DataScope::User)));
        Commit();
        Obs.Observe('new_encrypted_company', RetTx(IsolatedStorage.SetEncrypted('LTY76iso2', 'c1', DataScope::Company)));
        Commit();
        Obs.Observe('encrypted_again_company', RetTx(IsolatedStorage.SetEncrypted('LTY76iso2', 'c2', DataScope::Company)));
        Commit();
        Obs.Observe('new_encrypted_default_scope', RetTx(IsolatedStorage.SetEncrypted('LTY76iso3', 'd1')));
        Commit();
        Obs.Observe('encrypted_again_default_scope', RetTx(IsolatedStorage.SetEncrypted('LTY76iso3', 'd2')));
        Commit();
        IsolatedStorage.Delete('LTY76iso2', DataScope::User);
        IsolatedStorage.Delete('LTY76iso2', DataScope::Company);
        IsolatedStorage.Delete('LTY76iso3');
        Commit();
        if KeyCreated then begin
            DeleteEncryptionKey();
            Commit();
        end;
        Obs.Expect('new_encrypted_user', 'ret=Yes tx=Yes');
        Obs.Expect('encrypted_again_user', 'ret=Yes tx=Yes');
        Obs.Expect('plain_over_encrypted_user', 'ret=Yes tx=Yes');
        Obs.Expect('new_encrypted_company', 'ret=Yes tx=Yes');
        Obs.Expect('encrypted_again_company', 'ret=Yes tx=Yes');
        Obs.Expect('new_encrypted_default_scope', 'ret=Yes tx=Yes');
        Obs.Expect('encrypted_again_default_scope', 'ret=Yes tx=Yes');
        Obs.Verify();
    end;
}
