// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.net.mail.mailaddress
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99050
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: DotNet System.Net.Mail.MailAddress: the constructor with a valid address, with a display name form, with the two-argument form, and with invalid text
// (error text and code); the properties Address, DisplayName, User and Host.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System")
    {
        type("System.Net.Mail.MailAddress"; LtAfMailAddress) { }
    }
}

codeunit 99050 "LT AF MailAddress"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCreate(Text: Text; var Addr: DotNet LtAfMailAddress)
    begin
        Addr := Addr.MailAddress(Text);
    end;

    [TryFunction]
    local procedure TryCreateWithName(Text: Text; DisplayName: Text; var Addr: DotNet LtAfMailAddress)
    begin
        Addr := Addr.MailAddress(Text, DisplayName);
    end;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        Addr: DotNet LtAfMailAddress;
    begin
        ClearLastError();
        if TryCreate(Input, Addr) then begin
            Observer.Observe(Name + '|address', Addr.Address);
            Observer.Observe(Name + '|displayname', Addr.DisplayName);
            Observer.Observe(Name + '|user', Addr.User);
            Observer.Observe(Name + '|host', Addr.Host);
            Observer.Observe(Name + '|tostring', Addr.ToString());
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure AF_MailAddress_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'valid', 'john.doe@example.com');
        Observer.Expect('valid|address', 'john.doe@example.com');
        Observer.Expect('valid|displayname', '');
        Observer.Expect('valid|user', 'john.doe');
        Observer.Expect('valid|host', 'example.com');
        Observer.Expect('valid|tostring', 'john.doe@example.com');
        Observer.Verify();
    end;

    [Test]
    procedure AF_MailAddress_WithDisplayName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'display name', 'John Doe <john.doe@example.com>');
        Observer.Expect('display name|address', 'john.doe@example.com');
        Observer.Expect('display name|displayname', 'John Doe');
        Observer.Expect('display name|user', 'john.doe');
        Observer.Expect('display name|host', 'example.com');
        Observer.Expect('display name|tostring', '"John Doe" <john.doe@example.com>');
        Observer.Verify();
    end;

    [Test]
    procedure AF_MailAddress_Invalid_NoAt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'invalid no at', 'not-an-address');
        Observer.Expect('invalid no at|text', 'A call to System.Net.Mail.MailAddress failed with this message: The specified string is not in the form required for an e-mail address.');
        Observer.Expect('invalid no at|code', 'DotNetInvoke:Format');
        Observer.Verify();
    end;

    [Test]
    procedure AF_MailAddress_Invalid_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'invalid empty', '');
        Observer.Expect('invalid empty|text', 'A call to System.Net.Mail.MailAddress failed with this message: The value cannot be an empty string. (Parameter ''address'')');
        Observer.Expect('invalid empty|code', 'DotNetInvoke:Argument');
        Observer.Verify();
    end;

    [Test]
    procedure AF_MailAddress_Invalid_TwoAt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(Observer, 'invalid two at', 'a@b@c.com');
        Observer.Expect('invalid two at|text', 'A call to System.Net.Mail.MailAddress failed with this message: An invalid character was found in the mail header: ''@''.');
        Observer.Expect('invalid two at|code', 'DotNetInvoke:Format');
        Observer.Verify();
    end;

    [Test]
    procedure AF_MailAddress_TwoArguments()
    var
        Observer: Codeunit "Probe Observer";
        Addr: DotNet LtAfMailAddress;
    begin
        ClearLastError();
        if TryCreateWithName('jane@example.org', 'Jane', Addr) then begin
            Observer.Observe('two args|address', Addr.Address);
            Observer.Observe('two args|displayname', Addr.DisplayName);
            Observer.Observe('two args|user', Addr.User);
            Observer.Observe('two args|host', Addr.Host);
        end else
            Observer.ObserveError('two args');
        Observer.Expect('two args|address', 'jane@example.org');
        Observer.Expect('two args|displayname', 'Jane');
        Observer.Expect('two args|user', 'jane');
        Observer.Expect('two args|host', 'example.org');
        Observer.Verify();
    end;
}
