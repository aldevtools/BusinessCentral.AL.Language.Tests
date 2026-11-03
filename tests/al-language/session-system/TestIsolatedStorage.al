// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: none (IsolatedStorage is a global scope, no fixture table)
//
// IsolatedStorage Set/Contains/Get/Delete round-trip. Values must round-trip exactly and
// deletes must be observable; a missing key must report false, never throw.
//
// TIER PRECONDITION (#248): the two encryption tests below need the tier to have a TENANT
// ENCRYPTION KEY. Without one BC refuses correctly, with "An encryption key is required to
// complete the request." -- that is BC behaving properly, not a divergence, so the tier is
// what has to satisfy the precondition. Both tiers this corpus runs on now satisfy it with a
// REAL key, and each does so in the only way open to it:
//   * ci.yml (Linux)      -- the tier creates the key itself. MsDyn365Bc.On.Linux#72 turned
//                            StartupHook Patch #26 (the pass-through fake) off and fixed the
//                            real cause: the CRONUS demo backup ships its single
//                            [$ndo$tenantproperty] row with a blank tenantid while the NST
//                            runs tenant 'default', so the UPDATE persisting the key file
//                            name matched zero rows and CreateKey() could not remember the
//                            key it had just written. Nothing in CreateKey() was ever
//                            Windows-only. entrypoint.sh sets that tenantid now.
//   * nightly-windows.yml -- creates the tenant key from AL with CreateEncryptionKey() (a helper
//                            app's install trigger) and verifies it with an Encrypt/Decrypt
//                            round trip; the run fails if it cannot (#253, #282).
//
// So neither tier fakes this any more, and the EncryptDecrypt test below -- removed in the
// Patch #26 era because a pass-through provider structurally could not satisfy it -- is back.

codeunit 60378 "Test Isolated Storage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure IsolatedStorage_SetContainsGet_RoundTripsExactValue()
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsTrue(IsolatedStorage.Set('its-key', 'its-value'), 'IsolatedStorage.Set must return true.');
        Assert.IsTrue(IsolatedStorage.Contains('its-key'), 'IsolatedStorage.Contains must see the stored key.');
        Assert.IsTrue(IsolatedStorage.Get('its-key', Value), 'IsolatedStorage.Get must return true for a stored key.');
        Assert.AreEqual('its-value', Value, 'IsolatedStorage.Get must round-trip the exact value.');
    end;

    [Test]
    procedure IsolatedStorage_Delete_RemovesTheEntry()
    begin
        Initialize();

        IsolatedStorage.Set('its-doomed', 'x');
        Assert.IsTrue(IsolatedStorage.Delete('its-doomed'), 'IsolatedStorage.Delete must return true for an existing key.');
        Assert.IsFalse(IsolatedStorage.Contains('its-doomed'), 'Deleted key must not be contained.');
    end;

    // REINSTATED (was removed, not weakened): this test asserted Encrypt('its-secret') <>
    // 'its-secret' and that Decrypt() round-trips it back. Real, correct BC behavior -- but it
    // was removed while bc-linux's tenant encryption key was StartupHook Patch #26, a
    // pass-through fake that satisfied IsolatedStorage.SetEncrypted's store/retrieve round-trip
    // (below) while never making Encrypt() output differ from its plaintext input. A
    // pass-through provider structurally cannot satisfy the first assertion, so the test was
    // taken out rather than watered down to something the fake could pass.
    //
    // MsDyn365Bc.On.Linux#72 turned that fake off and made this tier do real RSA encryption,
    // which is what the removal note said would have to land first. Measured there on a clean
    // BC 28.4 boot: EncryptText returns 344 bytes of real ciphertext where the proxy returned
    // 16. So the test comes back unchanged in what it claims.
    [Test]
    procedure IsolatedStorage_EncryptDecrypt_RoundTripsAndIsNotPlaintext()
    // CLAIM: Encrypt() returns something that is not its plaintext input, and Decrypt()
    // reverses it exactly. Both halves are asserted -- ciphertext alone would pass against a
    // provider that returned a constant, and a round-trip alone would pass against a
    // pass-through fake, which is the one this test exists to catch.
    // DOCS: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-encrypt-string-method
    var
        Ciphertext: Text;
    begin
        Initialize();

        Ciphertext := System.Encrypt('its-secret');

        Assert.AreNotEqual('its-secret', Ciphertext, 'Encrypt() must not return its plaintext input.');
        Assert.IsTrue(Ciphertext <> '', 'Encrypt() must return a non-empty ciphertext.');
        Assert.AreEqual('its-secret', System.Decrypt(Ciphertext), 'Decrypt() must return the original plaintext.');
    end;

    [Test]
    procedure IsolatedStorage_SetEncrypted_GetRoundTripsPlaintext()
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsTrue(IsolatedStorage.SetEncrypted('its-enc-key', 'its-enc-value'), 'IsolatedStorage.SetEncrypted must return true.');
        Assert.IsTrue(IsolatedStorage.Get('its-enc-key', Value), 'IsolatedStorage.Get must find the encrypted entry.');
        Assert.AreEqual('its-enc-value', Value, 'Encrypted entry must round-trip to plaintext on Get.');
    end;

    [Test]
    procedure IsolatedStorage_Get_MissingKey_ReturnsFalse()
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsFalse(IsolatedStorage.Get('its-absent', Value), 'IsolatedStorage.Get must return false for a missing key.');
        Assert.IsFalse(IsolatedStorage.Contains('its-absent'), 'IsolatedStorage.Contains must be false for a missing key.');
    end;

    local procedure Initialize()
    begin
        // IsolatedStorage has no DeleteAll; each test uses its own unique keys, so no
        // cross-test cleanup is needed.
    end;
}
