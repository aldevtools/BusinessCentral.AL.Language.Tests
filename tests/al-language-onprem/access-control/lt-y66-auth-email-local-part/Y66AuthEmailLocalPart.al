// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (OnPrem app: the platform checks "Authentication Email" only where the service asks for unique authentication emails,
//   see TestUserAuthEmailTrigger.al)
// Fixtures used: Probe Observer (69160); own test codeunit 98720
// Probe (al-runner issue 6662, writer Y66): User.Insert() with an "Authentication Email" whose local part or domain holds characters outside
// letters, digits and ._+-: the reporter's formatted Guid ('{...}@EXAMPLE.COM', user name = the same Guid), braces inside, every RFC 5322
// atext sign, a quoted local part, dots at the edges and doubled, a space, a non-ASCII letter, an IP-literal and a dotless domain, two '@',
// an empty local part or domain, a comment, the display-name form, upper case. Observed: ok and the stored value, or the error text and code.
// Insert() and Modify() of the same address. Each write runs under asserterror (a TryFunction may not write on the OnPrem tiers) and is
// rolled back. Every user name starts with LTY66; the test removes them first and last.
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
        Observer.Finish();
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
        Probe(7, 'a..b@example.com');
        Probe(8, '.a@example.com');
        Probe(9, 'a.@example.com');
        Probe(10, 'a b@example.com');
        Probe(11, 'jürgen@example.com');
        Probe(12, 'a(comment)@example.com');
        Probe(13, 'UPPER.Case@Example.COM');
        Probe(14, 'Y66 Name <{524B1D71-5F95-43BA-AC9B-E1E5E17D8766}@example.com>');
        Cleanup();
        Observer.Finish();
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
        Probe(28, 'a@example..com');
        Probe(29, 'a@exämple.com');
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y66_AuthEmail_ModifyGuidLocalPart()
    var
        User: Record User;
        Sid: Guid;
    begin
        Cleanup();
        NewUser(User, 31, 'plain.y66@example.com');
        Sid := User."User Security ID";
        User.Insert();
        User.Get(Sid);
        User."Authentication Email" := '{524B1D71-5F95-43BA-AC9B-E1E5E17D8767}@EXAMPLE.COM';
        asserterror ModifyAndRaise(User);
        Observer.Observe('modify', Outcome());
        User.Get(Sid);
        User."Authentication Email" := 'a b@example.com';
        asserterror ModifyAndRaise(User);
        Observer.Observe('modify space', Outcome());
        Cleanup();
        Observer.Finish();
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

    // The write runs under asserterror, so it is rolled back; a write that succeeds stores the value BC kept and raises the sentinel.
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

    local procedure ModifyAndRaise(var User: Record User)
    var
        Reader: Record User;
    begin
        Stored := '';
        User.Modify();
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
