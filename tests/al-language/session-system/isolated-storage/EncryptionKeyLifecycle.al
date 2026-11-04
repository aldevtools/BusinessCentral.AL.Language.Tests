// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/encryptionenabled-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 67555
// Probe: EncryptionEnabled and EncryptionKeyExists before and after CreateEncryptionKey and DeleteEncryptionKey, the errors the calls raise, and whether Encrypt works in between. The test always ends with a key in place (other tests encrypt) (issue 581 item 3).
// BC versions: 27+

codeunit 67555 "LT Encryption Key Lifecycle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCreate()
    begin
        CreateEncryptionKey();
    end;

    [TryFunction]
    local procedure TryDelete()
    begin
        DeleteEncryptionKey();
    end;

    [TryFunction]
    local procedure TryEncrypt(var Result: Text)
    begin
        Result := Encrypt('x');
    end;

    local procedure State(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Encrypted: Text;
    begin
        Observer.Observe(Name + '_enabled', Format(EncryptionEnabled()));
        Observer.Observe(Name + '_key_exists', Format(EncryptionKeyExists()));
        if TryEncrypt(Encrypted) then
            Observer.Observe(Name + '_encrypt', 'ok length ' + Format(StrLen(Encrypted)))
        else begin
            Observer.Observe(Name + '_encrypt', 'error');
            Observer.ObserveError(Name + '_encrypt_error');
        end;
    end;

    local procedure Call(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + '_error');
    end;

    [Test]
    procedure EncryptionKey_Lifecycle_StateAfterEachCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        State(Observer, 'start');
        Call(Observer, 'create_when_present', TryCreate());
        State(Observer, 'after_create_when_present');
        Call(Observer, 'delete_when_present', TryDelete());
        State(Observer, 'after_delete');
        Call(Observer, 'delete_when_absent', TryDelete());
        State(Observer, 'after_second_delete');
        Call(Observer, 'create_when_absent', TryCreate());
        State(Observer, 'after_create');
        Call(Observer, 'create_again', TryCreate());
        State(Observer, 'after_second_create');
        if not EncryptionKeyExists() then
            CreateEncryptionKey();
        Observer.Expect('start_enabled', 'Yes');
        Observer.Expect('start_key_exists', 'Yes');
        Observer.Expect('start_encrypt', 'ok length 344');
        Observer.Expect('create_when_present', 'No');
        Observer.Expect('create_when_present_error|text', 'Unable to create a new encryption key. An encryption key already exists.');
        Observer.Expect('create_when_present_error|code', 'EncryptionCreated');
        Observer.Expect('after_create_when_present_enabled', 'Yes');
        Observer.Expect('after_create_when_present_key_exists', 'Yes');
        Observer.Expect('after_create_when_present_encrypt', 'ok length 344');
        Observer.Expect('delete_when_present', 'Yes');
        Observer.Expect('after_delete_enabled', 'No');
        Observer.Expect('after_delete_key_exists', 'No');
        Observer.Expect('after_delete_encrypt', 'error');
        Observer.Expect('after_delete_encrypt_error|text', 'An encryption key is required to complete the request.');
        Observer.Expect('after_delete_encrypt_error|code', 'EncryptionNotCreated');
        Observer.Expect('delete_when_absent', 'Yes');
        Observer.Expect('after_second_delete_enabled', 'No');
        Observer.Expect('after_second_delete_key_exists', 'No');
        Observer.Expect('after_second_delete_encrypt', 'error');
        Observer.Expect('after_second_delete_encrypt_error|text', 'An encryption key is required to complete the request.');
        Observer.Expect('after_second_delete_encrypt_error|code', 'EncryptionNotCreated');
        Observer.Expect('create_when_absent', 'Yes');
        Observer.Expect('after_create_enabled', 'Yes');
        Observer.Expect('after_create_key_exists', 'Yes');
        Observer.Expect('after_create_encrypt', 'ok length 344');
        Observer.Expect('create_again', 'No');
        Observer.Expect('create_again_error|text', 'Unable to create a new encryption key. An encryption key already exists.');
        Observer.Expect('create_again_error|code', 'EncryptionCreated');
        Observer.Expect('after_second_create_enabled', 'Yes');
        Observer.Expect('after_second_create_key_exists', 'Yes');
        Observer.Expect('after_second_create_encrypt', 'ok length 344');
        Observer.Verify();
    end;
}
