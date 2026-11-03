// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99250
// Probe (corpus #3): DotNet types from the System.Security.Principal.Windows assembly, declared the way Microsoft's
// Tests-TestLibraries dotnet.al declares them. Every literal asserted below is what BC produced on the corpus CI (Linux) AND on
// an official Microsoft Windows container (BC 27.5 onprem, 29.0 onprem, 29.0 sandbox; runs 39223208230, 39223203793, 39223200014).
// Facts: declaring a WindowsIdentity / SecurityIdentifier variable (IsNull true before assignment); the SecurityIdentifier
// constructor from a SID string and its Value and ToString(); the static WindowsIdentity.GetCurrent() and its Name and User.
// NOT asserted (the two tiers differ; MsDyn365Bc.On.Linux replaces this assembly with a stub): SecurityIdentifier.BinaryLength
// (Windows 16 for S-1-5-32-544, Linux 28), IsAccountSid() (Windows false, Linux true) and the constructor with invalid text
// (Windows raises, Linux accepts it). The Windows values are kept below under LTBK_WINDOWS_PRINCIPAL_PROBE.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Security.Principal.Windows")
    {
        type("System.Security.Principal.WindowsIdentity"; LtBkWindowsIdentity) { }
        type("System.Security.Principal.SecurityIdentifier"; LtBkSecurityIdentifier) { }
    }
}

codeunit 99250 "LT BK Windows Principal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGetCurrent(var Identity: DotNet LtBkWindowsIdentity)
    begin
        Identity := Identity.GetCurrent();
    end;

    [TryFunction]
    local procedure TryNewSid(SidText: Text; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Sid := Sid.SecurityIdentifier(SidText);
    end;

    [TryFunction]
    local procedure TryDescribeSid(var Observer: Codeunit "Probe Observer"; Name: Text; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Observer.Observe(Name + '|value', Sid.Value);
        Observer.Observe(Name + '|tostring', Sid.ToString());
    end;

    [TryFunction]
    local procedure TryIdentityName(var Identity: DotNet LtBkWindowsIdentity; var Name: Text)
    begin
        Name := Identity.Name;
    end;

    [TryFunction]
    local procedure TryIdentityUser(var Identity: DotNet LtBkWindowsIdentity; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Sid := Identity.User;
    end;

    [Test]
    procedure BK_WindowsPrincipal_Declare()
    var
        Observer: Codeunit "Probe Observer";
        Identity: DotNet LtBkWindowsIdentity;
        Sid: DotNet LtBkSecurityIdentifier;
    begin
        Observer.Observe('identity isnull', Format(IsNull(Identity)));
        Observer.Observe('sid isnull', Format(IsNull(Sid)));
        Observer.Expect('identity isnull', 'Yes');
        Observer.Expect('sid isnull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BK_WindowsPrincipal_SidFromText()
    var
        Observer: Codeunit "Probe Observer";
        Sid: DotNet LtBkSecurityIdentifier;
    begin
        ClearLastError();
        if TryNewSid('S-1-5-32-544', Sid) then begin
            Observer.Observe('admins|isnull', Format(IsNull(Sid)));
            if not TryDescribeSid(Observer, 'admins', Sid) then
                Observer.ObserveError('admins|describe');
        end else
            Observer.ObserveError('admins');
        Observer.Expect('admins|isnull', 'No');
        Observer.Expect('admins|value', 'S-1-5-32-544');
        Observer.Expect('admins|tostring', 'S-1-5-32-544');
        Observer.Verify();
    end;

    [Test]
    procedure BK_WindowsPrincipal_GetCurrent()
    var
        Observer: Codeunit "Probe Observer";
        Identity: DotNet LtBkWindowsIdentity;
        Sid: DotNet LtBkSecurityIdentifier;
        Name: Text;
    begin
        // The name and SID of the service account depend on the host, so only their presence is asserted.
        ClearLastError();
        if TryGetCurrent(Identity) then begin
            Observer.Observe('getcurrent|isnull', Format(IsNull(Identity)));
            if TryIdentityName(Identity, Name) then
                Observer.Observe('name|empty', Format(Name = ''))
            else
                Observer.ObserveError('name');
            if TryIdentityUser(Identity, Sid) then
                Observer.Observe('user|isnull', Format(IsNull(Sid)))
            else
                Observer.ObserveError('user');
        end else
            Observer.ObserveError('getcurrent');
        Observer.Expect('getcurrent|isnull', 'No');
        Observer.Expect('name|empty', 'No');
        Observer.Expect('user|isnull', 'No');
        Observer.Verify();
    end;

#if LTBK_WINDOWS_PRINCIPAL_PROBE
    // Windows values (runs 39223208230, 39223203793, 39223200014). MsDyn365Bc.On.Linux answers BinaryLength 28, IsAccountSid true
    // and accepts the invalid text, so this test is not compiled by default.
    [TryFunction]
    local procedure TryDescribeSidBinary(var Observer: Codeunit "Probe Observer"; Name: Text; var Sid: DotNet LtBkSecurityIdentifier)
    begin
        Observer.Observe(Name + '|binarylength', Format(Sid.BinaryLength));
        Observer.Observe(Name + '|isaccountsid', Format(Sid.IsAccountSid()));
    end;

    [Test]
    procedure BK_WindowsPrincipal_SidWindowsOnly()
    var
        Observer: Codeunit "Probe Observer";
        Sid: DotNet LtBkSecurityIdentifier;
    begin
        ClearLastError();
        if TryNewSid('S-1-5-32-544', Sid) then begin
            if not TryDescribeSidBinary(Observer, 'admins', Sid) then
                Observer.ObserveError('admins|describe');
        end else
            Observer.ObserveError('admins');
        ClearLastError();
        if TryNewSid('not a sid', Sid) then
            Observer.Observe('bad', 'no error')
        else
            Observer.ObserveError('bad');
        Observer.Expect('admins|binarylength', '16');
        Observer.Expect('admins|isaccountsid', 'No');
        Observer.Expect('bad|text', 'A call to System.Security.Principal.SecurityIdentifier failed with this message: Value was invalid. (Parameter ''sddlForm'')');
        Observer.Expect('bad|code', 'DotNetInvoke:Argument');
        Observer.Verify();
    end;
#endif
}
