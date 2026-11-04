// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope, OnPrem app - see the header note below
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP
//   "User" (2000000120) is Scope = Cloud, but the platform runs this validation only when the
//   service topology asks for unique authentication emails - on-premises and container tiers do,
//   Microsoft's own SaaS topology does not. The claims below are therefore on-premises claims, and
//   one of them reads "User Property" (2000000121), which only an OnPrem app can name (AL0296).
//
// CLAIM: the platform's own User system-table trigger - not an AL trigger, and not Validate -
// normalises "Authentication Email" when a User row is written by Insert or Modify: it trims
// surrounding whitespace and reduces the text to the address a mail parser reads out of it
// ("Name <a@b.c>" -> "a@b.c"; "a@b.c, d@e.f" -> "d@e.f"). It refuses an address that does not
// parse, and one already carried by another ENABLED user. On Modify, changing the email clears
// the user's "Authentication Object ID". The same Modify trigger refuses a user name another
// user already carries, as the Insert trigger does.
//
// LICENSE: every User written here is an "External User". The platform's User trigger flags
// a commit-time named-user license check for every license type except Device Only User and
// External User, and on a tier licensed for a fixed number of full users that check - not the
// behaviour under test - refuses the transaction. External users are neither flagged nor
// counted as full or limited users. Device Only User would do the same for the platform, but
// Base Application refuses that type when the tenant is an online (sandbox) environment. The
// email and user-name rules below do not read the license type.
//
// Every refusal is paired with the case that must still be accepted - a disabled user's email
// may be reused, a user may keep its own email and name on Modify - so none of these can be
// satisfied by refusing more. Refusal tests read nothing that an asserterror rollback could
// have undone.
codeunit 61206 "Test User Auth Email Trigger"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        InvalidEmailErr: Label 'You must specify a valid email address', Locked = true;
        EmailTakenErr: Label 'is already being used by another user', Locked = true;
        UniqueNameErr: Label 'The user name must be unique', Locked = true;

    [Test]
    procedure AuthEmail_Insert_TrimsSurroundingWhitespace()
    var
        UserRec: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(UserRec, '   ' + Email + '    ');

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'Insert must store the email without its surrounding whitespace');
    end;

    [Test]
    procedure AuthEmail_Insert_DisplayNameFormReducesToTheAddress()
    var
        UserRec: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(UserRec, 'Test Person <' + Email + '>');

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'Insert must store only the address of a display-name form');
    end;

    [Test]
    procedure AuthEmail_Insert_PlainAddressIsStoredUnchanged()
    // CONTROL: a well-formed address with nothing to strip is stored exactly as assigned.
    var
        UserRec: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(UserRec, Email);

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'a plain address must be stored unchanged');
    end;

    [Test]
    procedure AuthEmail_Validate_DoesNotNormalise()
    // The normalisation belongs to the write, not to Validate: before Insert the record still
    // carries the text exactly as validated, and the Insert is what trims it.
    var
        UserRec: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        UserRec.Init();
        UserRec."User Security ID" := CreateGuid();
        UserRec."User Name" := NewUserName();
        UserRec."License Type" := UserRec."License Type"::"External User";
        UserRec.Validate("Authentication Email", '  ' + Email + '  ');
        Assert.AreEqual('  ' + Email + '  ', UserRec."Authentication Email", 'Validate must leave the email exactly as assigned');

        UserRec.Insert();
        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'the Insert after Validate must trim the email');
    end;

    [Test]
    procedure AuthEmail_Modify_ReducesAListToItsLastAddress()
    var
        UserRec: Record User;
        Reader: Record User;
        First: Text;
        Second: Text;
    begin
        First := NewEmail();
        Second := NewEmail();
        NewUser(UserRec, '');

        UserRec."Authentication Email" := CopyStr(First + ', ' + Second, 1, MaxStrLen(UserRec."Authentication Email"));
        UserRec.Modify();

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Second, Reader."Authentication Email", 'Modify must keep only the last address of a comma-separated list');
    end;

    [Test]
    procedure AuthEmail_Modify_WhitespaceOnlyBecomesEmpty()
    var
        UserRec: Record User;
        Reader: Record User;
    begin
        NewUser(UserRec, NewEmail());

        UserRec."Authentication Email" := '    ';
        UserRec.Modify();

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual('', Reader."Authentication Email", 'Modify must clear a whitespace-only email to empty');
    end;

    [Test]
    procedure AuthEmail_Insert_InvalidAddressIsRefused()
    var
        UserRec: Record User;
        Reader: Record User;
        Sid: Guid;
    begin
        Sid := CreateGuid();
        UserRec.Init();
        UserRec."User Security ID" := Sid;
        UserRec."User Name" := NewUserName();
        UserRec."License Type" := UserRec."License Type"::"External User";
        UserRec."Authentication Email" := 'Abc.example.com';

        asserterror UserRec.Insert();
        Assert.ExpectedError(InvalidEmailErr);
        Assert.IsFalse(Reader.Get(Sid), 'a User with an invalid authentication email must not be inserted');
    end;

    [Test]
    procedure AuthEmail_Insert_EmailOfAnotherEnabledUserIsRefused()
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Reader: Record User;
        Email: Text;
        Sid: Guid;
    begin
        Email := NewEmail();
        NewUser(FirstUser, Email);

        Sid := CreateGuid();
        SecondUser.Init();
        SecondUser."User Security ID" := Sid;
        SecondUser."User Name" := NewUserName();
        SecondUser."License Type" := SecondUser."License Type"::"External User";
        SecondUser."Authentication Email" := CopyStr(' ' + Email, 1, MaxStrLen(SecondUser."Authentication Email"));

        // The padded copy is refused too: uniqueness is checked on the normalised address.
        asserterror SecondUser.Insert();
        Assert.ExpectedError(EmailTakenErr);
        Assert.IsFalse(Reader.Get(Sid), 'a User reusing another enabled user''s email must not be inserted');
    end;

    [Test]
    procedure AuthEmail_Insert_EmailOfADisabledUserIsAccepted()
    // CONTROL for the refusal above: only ENABLED users hold their email exclusively.
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(FirstUser, Email);
        FirstUser.State := FirstUser.State::Disabled;
        FirstUser.Modify();

        NewUser(SecondUser, Email);

        Assert.IsTrue(Reader.Get(SecondUser."User Security ID"), 'a disabled user''s email may be given to a new user');
        Assert.AreEqual(Email, Reader."Authentication Email", 'the new user must carry the reused email');
    end;

    [Test]
    procedure AuthEmail_Modify_EmailOfAnotherEnabledUserIsRefused()
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(FirstUser, Email);
        NewUser(SecondUser, NewEmail());

        SecondUser."Authentication Email" := CopyStr(Email, 1, MaxStrLen(SecondUser."Authentication Email"));
        asserterror SecondUser.Modify();
        Assert.ExpectedError(EmailTakenErr);
    end;

    [Test]
    procedure AuthEmail_Modify_KeepingItsOwnEmailIsAccepted()
    // CONTROL: on Modify the user's own row is not a competitor for its own email.
    var
        UserRec: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(UserRec, Email);

        UserRec."Full Name" := 'Renamed Person';
        UserRec.Modify();

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual('Renamed Person', Reader."Full Name", 'the Modify must have been written');
        Assert.AreEqual(Email, Reader."Authentication Email", 'the user must keep its own email');
    end;

    [Test]
    procedure AuthEmail_Modify_ChangingTheEmailClearsTheAuthenticationObjectId()
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
    begin
        NewUser(UserRec, NewEmail());
        SetAuthenticationObjectId(UserRec."User Security ID", 'OBJECT-ID-61206');

        UserRec."Authentication Email" := CopyStr(NewEmail(), 1, MaxStrLen(UserRec."Authentication Email"));
        UserRec.Modify();

        UserProperty.Get(UserRec."User Security ID");
        Assert.AreEqual('', UserProperty."Authentication Object ID", 'changing the authentication email must clear the Authentication Object ID');
    end;

    [Test]
    procedure AuthEmail_Modify_KeepingTheEmailKeepsTheAuthenticationObjectId()
    // CONTROL for the test above: an unrelated Modify leaves the object id alone.
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
    begin
        NewUser(UserRec, NewEmail());
        SetAuthenticationObjectId(UserRec."User Security ID", 'OBJECT-ID-61206');

        UserRec."Full Name" := 'Renamed Person';
        UserRec.Modify();

        UserProperty.Get(UserRec."User Security ID");
        Assert.AreEqual('OBJECT-ID-61206', UserProperty."Authentication Object ID", 'a Modify that keeps the email must keep the Authentication Object ID');
    end;

    [Test]
    procedure AuthEmail_Insert_DisabledUserWithAnEnabledUsersEmailIsAccepted()
    // Only a row that is itself ENABLED claims its email exclusively: a disabled user may be
    // written carrying an address an enabled user already has.
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(FirstUser, Email);

        SecondUser.Init();
        SecondUser."User Security ID" := CreateGuid();
        SecondUser."User Name" := NewUserName();
        SecondUser."License Type" := SecondUser."License Type"::"External User";
        SecondUser.State := SecondUser.State::Disabled;
        SecondUser."Authentication Email" := CopyStr(Email, 1, MaxStrLen(SecondUser."Authentication Email"));
        SecondUser.Insert();

        Assert.IsTrue(Reader.Get(SecondUser."User Security ID"), 'a disabled user may carry an enabled user''s email');
        Assert.AreEqual(Email, Reader."Authentication Email", 'the disabled user must carry the email as written');
    end;

    [Test]
    procedure AuthEmail_Modify_DisabledUserToAnEnabledUsersEmailIsAccepted()
    // The Modify mirror of the test above.
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Reader: Record User;
        Email: Text;
    begin
        Email := NewEmail();
        NewUser(FirstUser, Email);
        NewUser(SecondUser, NewEmail());
        SecondUser.State := SecondUser.State::Disabled;
        SecondUser.Modify();

        SecondUser."Authentication Email" := CopyStr(Email, 1, MaxStrLen(SecondUser."Authentication Email"));
        SecondUser.Modify();

        Reader.Get(SecondUser."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'a disabled user may be given an enabled user''s email');
    end;

    [Test]
    procedure UserName_Modify_ToAnotherUsersNameIsRefused()
    var
        FirstUser: Record User;
        SecondUser: Record User;
    begin
        NewUser(FirstUser, '');
        NewUser(SecondUser, '');

        SecondUser."User Name" := FirstUser."User Name";
        asserterror SecondUser.Modify();
        Assert.ExpectedError(UniqueNameErr);
    end;

    [Test]
    procedure UserName_Modify_ToAFreshNameIsAccepted()
    // CONTROL: the Modify trigger compares against OTHER users only.
    var
        UserRec: Record User;
        Reader: Record User;
        FreshName: Code[50];
    begin
        NewUser(UserRec, '');
        FreshName := NewUserName();

        UserRec."User Name" := FreshName;
        UserRec.Modify();

        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(FreshName, Reader."User Name", 'a user may be renamed to a name nobody carries');
    end;

    local procedure NewUser(var UserRec: Record User; Email: Text)
    begin
        UserRec.Init();
        UserRec."User Security ID" := CreateGuid();
        UserRec."User Name" := NewUserName();
        UserRec."License Type" := UserRec."License Type"::"External User";
        UserRec."Authentication Email" := CopyStr(Email, 1, MaxStrLen(UserRec."Authentication Email"));
        UserRec.Insert();
    end;

    local procedure SetAuthenticationObjectId(UserSecurityId: Guid; ObjectId: Text[80])
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.Get(UserSecurityId);
        UserProperty."Authentication Object ID" := ObjectId;
        UserProperty.Modify();
    end;

    local procedure NewUserName(): Code[50]
    begin
        exit(CopyStr('T61206' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 50));
    end;

    local procedure NewEmail(): Text
    begin
        exit(LowerCase(DelChr(Format(CreateGuid()), '=', '{}-')) + '@t61206.example.com');
    end;
}
