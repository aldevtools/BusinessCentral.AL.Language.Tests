// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (OnPrem app: the platform checks "Authentication Email" only where the service asks for unique authentication emails,
//   see TestUserAuthEmailTrigger.al)
// Fixtures used: Probe Observer (69160); own test codeunit 98720
// Probe (al-runner issue 6662, writer Y66): User.Insert() with an "Authentication Email" whose local part or domain holds characters outside
// letters, digits and ._+-: the reporter's formatted Guid ('{...}@EXAMPLE.COM', user name = the same Guid), braces inside, every RFC 5322
// atext sign, a quoted local part, dots at the edges and doubled, a space, a non-ASCII letter, an IP-literal and a dotless domain, two '@',
// an empty local part or domain, a comment, the display-name form, upper case. Observed: ok and the stored value, or the error text and code.
// Insert() of each address (Modify normalizes the same way: TestUserAuthEmailTrigger.al). Each insert runs under asserterror (a
// TryFunction may not write on the OnPrem tiers) and is rolled back. Every user name starts with LTY66; the test removes them first and last.
// Pinned elsewhere: whitespace trim, display-name and list reduction, the missing '@', uniqueness (TestUserAuthEmailTrigger.al,
// lt-av-user-insert/AvUserInsertErrors.al).
// BC versions: 27, 28, 29

codeunit 98720 "LT Y66 Auth Email Local Part"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Stored: Text;
        OkSentinelErr: Label 'LT Y66 written', Locked = true;

    [Test]
    procedure Y66_AuthEmail_ReporterShape()
    var
        User: Record User;
        Sid: Guid;
    begin
        Cleanup();
        User.Init();
        User."User Name" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(User."User Name"));
        User."Authentication Email" := User."User Name" + '@' + 'EXAMPLE.COM';
        User."User Security ID" := CreateGuid();
        User."License Type" := User."License Type"::"External User";
        Sid := User."User Security ID";
        asserterror InsertAndRaise(User);
        if GetLastErrorText() = OkSentinelErr then
            Observer.Observe('insert', 'ok|stored as given=' + Format(Stored = User."User Name" + '@EXAMPLE.COM'))
        else
            Observer.Observe('insert', 'E ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Cleanup();
        Observer.Expect('insert', 'ok|stored as given=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_AuthEmail_LocalParts()
    begin
        Cleanup();
        Probe(1, '{524B1D71-5F95-43BA-AC9B-E1E5E17D8765}@EXAMPLE.COM');
        Probe(2, '{524b1d71-5f95-43ba-ac9b-e1e5e17d8765}@example.com');
        Probe(3, 'a{b}c@example.com');
        Probe(4, '!#$%&''*+/=?^_`{|}~@example.com');
        Probe(5, '"quoted local"@example.com');
        Probe(6, '"a@b"@example.com');
        Cleanup();
        Observer.Expect('1 {524B1D71-5F95-43BA-AC9B-E1E5E17D8765}@EXAMPLE.COM', 'ok|{524B1D71-5F95-43BA-AC9B-E1E5E17D8765}@EXAMPLE.COM');
        Observer.Expect('2 {524b1d71-5f95-43ba-ac9b-e1e5e17d8765}@example.com', 'ok|{524b1d71-5f95-43ba-ac9b-e1e5e17d8765}@example.com');
        Observer.Expect('3 a{b}c@example.com', 'ok|a{b}c@example.com');
        Observer.Expect('4 !#$%&''*+/=?^_`{|}~@example.com', 'ok|!#$%&''*+/=?^_`{|}~@example.com');
        Observer.Expect('5 "quoted local"@example.com', 'ok|"quoted local"@example.com');
        Observer.Expect('6 "a@b"@example.com', 'ok|"a@b"@example.com');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_AuthEmail_Domains()
    begin
        Cleanup();
        Probe(21, 'a@[127.0.0.1]');
        Probe(22, 'a@localhost');
        Probe(23, 'a@b@example.com');
        Probe(24, '@example.com');
        Probe(25, 'a@');
        Probe(26, 'a@ex_ample.com');
        Probe(27, 'a@-example.com');
        Cleanup();
        Observer.Expect('21 a@[127.0.0.1]', 'ok|a@[127.0.0.1]');
        Observer.Expect('22 a@localhost', 'ok|a@localhost');
        Observer.Expect('23 a@b@example.com', 'E You must specify a valid email address.|CannotSpecifyAuthenticationEmail');
        Observer.Expect('24 @example.com', 'E You must specify a valid email address.|CannotSpecifyAuthenticationEmail');
        Observer.Expect('25 a@', 'E You must specify a valid email address.|CannotSpecifyAuthenticationEmail');
        Observer.Expect('26 a@ex_ample.com', 'ok|a@ex_ample.com');
        Observer.Expect('27 a@-example.com', 'ok|a@-example.com');
        Observer.Verify();
    end;

    // BC 29 refuses two addresses BC 27 and 28 accept: a..b@example.com and a@example..com (CI OnPrem legs).
    [Test]
    procedure Y66_AuthEmail_VersionDependent()
    begin
        Cleanup();
        Probe(7, 'a..b@example.com');
        Probe(8, '.a@example.com');
        Probe(9, 'a.@example.com');
        Probe(10, 'a b@example.com');
        Probe(11, 'jürgen@example.com');
        Probe(12, 'a(comment)@example.com');
        Probe(13, 'UPPER.Case@Example.COM');
        Probe(14, 'Y66 Name <{524B1D71-5F95-43BA-AC9B-E1E5E17D8766}@example.com>');
        Probe(28, 'a@example..com');
        Probe(29, 'a@exämple.com');
        Cleanup();
#if BC29PLUS
        Observer.Expect('7 a..b@example.com', 'E You must specify a valid email address.|CannotSpecifyAuthenticationEmail');
#else
        Observer.Expect('7 a..b@example.com', 'ok|a..b@example.com');
#endif
        Observer.Expect('8 .a@example.com', 'E You must specify a valid email address.|CannotSpecifyAuthenticationEmail');
        Observer.Expect('9 a.@example.com', 'ok|a.@example.com');
        Observer.Expect('10 a b@example.com', 'ok|b@example.com');
        Observer.Expect('11 jürgen@example.com', 'ok|jürgen@example.com');
        Observer.Expect('12 a(comment)@example.com', 'ok|a@example.com');
        Observer.Expect('13 UPPER.Case@Example.COM', 'ok|UPPER.Case@Example.COM');
        Observer.Expect('14 Y66 Name <{524B1D71-5F95-43BA-AC9B-E1E5E17D8766}@example.com>', 'ok|{524B1D71-5F95-43BA-AC9B-E1E5E17D8766}@example.com');
#if BC29PLUS
        Observer.Expect('28 a@example..com', 'E You must specify a valid email address.|CannotSpecifyAuthenticationEmail');
#else
        Observer.Expect('28 a@example..com', 'ok|a@example..com');
#endif
        Observer.Expect('29 a@exämple.com', 'ok|a@exämple.com');
        Observer.Verify();
    end;

    local procedure Probe(No: Integer; Email: Text)
    var
        User: Record User;
    begin
        NewUser(User, No, Email);
        asserterror InsertAndRaise(User);
        Observer.Observe(Format(No) + ' ' + Email, Outcome());
    end;

    local procedure NewUser(var User: Record User; No: Integer; Email: Text)
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := 'LTY66-' + Format(No);
        User."License Type" := User."License Type"::"External User";
        User."Authentication Email" := CopyStr(Email, 1, MaxStrLen(User."Authentication Email"));
    end;

    // The insert runs under asserterror, so it is rolled back; a write that succeeds stores the value BC kept and raises the sentinel.
    local procedure InsertAndRaise(var User: Record User)
    var
        Reader: Record User;
    begin
        Stored := '';
        User.Insert();
        Reader.Get(User."User Security ID");
        Stored := Reader."Authentication Email";
        Error(OkSentinelErr);
    end;

    local procedure Outcome(): Text
    begin
        if GetLastErrorText() = OkSentinelErr then
            exit('ok|' + Stored);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Cleanup()
    var
        User: Record User;
    begin
        User.SetFilter("User Name", 'LTY66*');
        User.DeleteAll(true);
        User.Reset();
        User.SetFilter("Authentication Email", '*@EXAMPLE.COM');
        User.SetFilter("User Name", '{*');
        User.DeleteAll(true);
    end;
}
