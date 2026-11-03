// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-decrypt-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained test codeunit 80204
// Probe: corpus issue 647 item 17 (writer AV). RISKY (own file): the test deletes the tenant encryption key and creates a new one; it ends with a key in place, as
//   EncryptionKeyLifecycle.al does.
// Facts: Decrypt of a text encrypted under the old key, after DeleteEncryptionKey and after a new key was created: result or error text and code.
// BC versions: 27, 28, 29
codeunit 80204 "LT AV Decrypt After Key Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDecrypt(Value: Text; var Result: Text)
    begin
        Result := Decrypt(Value);
    end;

    local procedure ObserveDecrypt(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        Result: Text;
    begin
        if TryDecrypt(Value, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Decrypt_AfterDeleteEncryptionKey_AndAfterNewKey()
    var
        Observer: Codeunit "Probe Observer";
        OldCipher: Text;
        NewCipher: Text;
    begin
        if not EncryptionKeyExists() then
            CreateEncryptionKey();
        OldCipher := Encrypt('lt av secret');
        ObserveDecrypt(Observer, 'with the old key', OldCipher);
        DeleteEncryptionKey();
        Observer.Observe('key exists after delete', Format(EncryptionKeyExists()));
        ObserveDecrypt(Observer, 'old text after delete', OldCipher);
        ObserveDecrypt(Observer, 'empty text after delete', '');
        CreateEncryptionKey();
        Observer.Observe('key exists after create', Format(EncryptionKeyExists()));
        ObserveDecrypt(Observer, 'old text under the new key', OldCipher);
        NewCipher := Encrypt('lt av secret');
        Observer.Observe('new cipher differs', Format(NewCipher <> OldCipher));
        ObserveDecrypt(Observer, 'new text under the new key', NewCipher);
        Observer.Expect('with the old key', 'ok:lt av secret');
        Observer.Expect('key exists after delete', 'No');
        Observer.Expect('old text after delete|text', 'An encryption key is required to complete the request.');
        Observer.Expect('old text after delete|code', 'EncryptionNotCreated');
        Observer.Expect('empty text after delete', 'ok:');
        Observer.Expect('key exists after create', 'Yes');
        Observer.Expect('old text under the new key|text', 'Unable to decrypt data. The data was encrypted using a different key.');
        Observer.Expect('old text under the new key|code', 'Encryption:OpenSslCryptographic');
        Observer.Expect('new cipher differs', 'Yes');
        Observer.Expect('new text under the new key', 'ok:lt av secret');
        Observer.Verify();
    end;
}
