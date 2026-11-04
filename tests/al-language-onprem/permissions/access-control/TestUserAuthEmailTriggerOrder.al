// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope, OnPrem app - see "WHY THIS FILE IS IN THE ONPREM APP" in TestUserAuthEmailTrigger.al
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// CLAIM: the platform's User system-table trigger - the one that normalises and checks
// "Authentication Email" (codeunit 61206) - runs AFTER the table's OnBeforeInsert /
// OnBeforeModify event subscribers, as part of the record write itself. So:
//   * a subscriber reads the email exactly as the caller assigned it, not yet normalised;
//   * an email a subscriber assigns is the one the trigger normalises and stores;
//   * an email a subscriber assigns is the one the trigger checks for uniqueness.
//
// The subscriber (codeunit 61209) is bound manually and acts only on the one User row the test
// names, so the other User writes of the run are untouched. Every user is an "External User",
// for the license reason given in TestUserAuthEmailTrigger.al.
codeunit 61208 "Test User Auth Email Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EmailTakenErr: Label 'is already being used by another user', Locked = true;

    [Test]
    procedure AuthEmailOrder_OnBeforeInsertSubscriberSeesTheRawEmail()
    var
        UserRec: Record User;
        Reader: Record User;
        Spy: Codeunit "User Auth Email Order Spy";
        Email: Text;
    begin
        Email := NewEmail();
        InitUser(UserRec, '   ' + Email + '   ');
        Spy.Watch(UserRec."User Security ID");
        BindSubscription(Spy);

        UserRec.Insert();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.InsertCalls(), 'the OnBeforeInsert subscriber must have run once for the watched user');
        Assert.AreEqual('   ' + Email + '   ', Spy.SeenOnInsert(), 'an OnBeforeInsert subscriber must see the email before the platform trims it');
        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'the stored email must still be trimmed');
    end;

    [Test]
    procedure AuthEmailOrder_OnBeforeModifySubscriberSeesTheRawEmail()
    var
        UserRec: Record User;
        Reader: Record User;
        Spy: Codeunit "User Auth Email Order Spy";
        Email: Text;
    begin
        NewUser(UserRec, NewEmail());
        Email := NewEmail();
        Spy.Watch(UserRec."User Security ID");
        BindSubscription(Spy);

        UserRec."Authentication Email" := CopyStr('Test Person <' + Email + '>', 1, MaxStrLen(UserRec."Authentication Email"));
        UserRec.Modify();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.ModifyCalls(), 'the OnBeforeModify subscriber must have run once for the watched user');
        Assert.AreEqual('Test Person <' + Email + '>', Spy.SeenOnModify(), 'an OnBeforeModify subscriber must see the email before the platform reduces it to the address');
        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'the stored email must still be reduced to the address');
    end;

    [Test]
    procedure AuthEmailOrder_EmailSetByOnBeforeInsertSubscriberIsNormalised()
    var
        UserRec: Record User;
        Reader: Record User;
        Spy: Codeunit "User Auth Email Order Spy";
        Email: Text;
    begin
        Email := NewEmail();
        InitUser(UserRec, '');
        Spy.Watch(UserRec."User Security ID");
        Spy.ReplaceWith('  Test Person <' + Email + '>  ');
        BindSubscription(Spy);

        UserRec.Insert();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.InsertCalls(), 'the OnBeforeInsert subscriber must have run once for the watched user');
        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'an email assigned by an OnBeforeInsert subscriber must be normalised by the platform');
    end;

    [Test]
    procedure AuthEmailOrder_EmailSetByOnBeforeModifySubscriberIsNormalised()
    var
        UserRec: Record User;
        Reader: Record User;
        Spy: Codeunit "User Auth Email Order Spy";
        Email: Text;
    begin
        NewUser(UserRec, NewEmail());
        Email := NewEmail();
        Spy.Watch(UserRec."User Security ID");
        Spy.ReplaceWith('    ' + Email + '    ');
        BindSubscription(Spy);

        UserRec."Full Name" := 'Renamed Person';
        UserRec.Modify();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.ModifyCalls(), 'the OnBeforeModify subscriber must have run once for the watched user');
        Reader.Get(UserRec."User Security ID");
        Assert.AreEqual(Email, Reader."Authentication Email", 'an email assigned by an OnBeforeModify subscriber must be normalised by the platform');
        Assert.AreEqual('Renamed Person', Reader."Full Name", 'the Modify must have been written');
    end;

    [Test]
    procedure AuthEmailOrder_EmailSetByOnBeforeInsertSubscriberIsCheckedForUniqueness()
    // The caller assigns an address nobody carries; the subscriber swaps in one an enabled user
    // already has. The platform checks the address it is about to write, so the insert is
    // refused. AuthEmailOrder_EmailSetByOnBeforeInsertSubscriberIsNormalised is the accepted
    // control: a subscriber-assigned address nobody carries is written.
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Reader: Record User;
        Spy: Codeunit "User Auth Email Order Spy";
        TakenEmail: Text;
        Sid: Guid;
    begin
        TakenEmail := NewEmail();
        NewUser(FirstUser, TakenEmail);

        InitUser(SecondUser, NewEmail());
        Sid := SecondUser."User Security ID";
        Spy.Watch(Sid);
        Spy.ReplaceWith(TakenEmail);
        BindSubscription(Spy);

        asserterror SecondUser.Insert();
        Assert.ExpectedError(EmailTakenErr);
        UnbindSubscription(Spy);
        Assert.IsFalse(Reader.Get(Sid), 'a User whose subscriber-assigned email another enabled user carries must not be inserted');
    end;

    [Test]
    procedure AuthEmailOrder_EmailSetByOnBeforeModifySubscriberIsCheckedForUniqueness()
    var
        FirstUser: Record User;
        SecondUser: Record User;
        Spy: Codeunit "User Auth Email Order Spy";
        TakenEmail: Text;
    begin
        TakenEmail := NewEmail();
        NewUser(FirstUser, TakenEmail);
        NewUser(SecondUser, NewEmail());
        Spy.Watch(SecondUser."User Security ID");
        Spy.ReplaceWith(TakenEmail);
        BindSubscription(Spy);

        SecondUser."Full Name" := 'Renamed Person';
        asserterror SecondUser.Modify();
        Assert.ExpectedError(EmailTakenErr);
        UnbindSubscription(Spy);
    end;

    local procedure InitUser(var UserRec: Record User; Email: Text)
    begin
        UserRec.Init();
        UserRec."User Security ID" := CreateGuid();
        UserRec."User Name" := NewUserName();
        UserRec."License Type" := UserRec."License Type"::"External User";
        UserRec."Authentication Email" := CopyStr(Email, 1, MaxStrLen(UserRec."Authentication Email"));
    end;

    local procedure NewUser(var UserRec: Record User; Email: Text)
    begin
        InitUser(UserRec, Email);
        UserRec.Insert();
    end;

    local procedure NewUserName(): Code[50]
    begin
        exit(CopyStr('T61208' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 50));
    end;

    local procedure NewEmail(): Text
    begin
        exit(LowerCase(DelChr(Format(CreateGuid()), '=', '{}-')) + '@t61208.example.com');
    end;
}

codeunit 61209 "User Auth Email Order Spy"
{
    EventSubscriberInstance = Manual;

    var
        WatchedSid: Guid;
        SeenInsert: Text;
        SeenModify: Text;
        Replacement: Text;
        HasReplacement: Boolean;
        InsertCount: Integer;
        ModifyCount: Integer;

    procedure Watch(Sid: Guid)
    begin
        WatchedSid := Sid;
    end;

    procedure ReplaceWith(Email: Text)
    begin
        Replacement := Email;
        HasReplacement := true;
    end;

    procedure SeenOnInsert(): Text
    begin
        exit(SeenInsert);
    end;

    procedure SeenOnModify(): Text
    begin
        exit(SeenModify);
    end;

    procedure InsertCalls(): Integer
    begin
        exit(InsertCount);
    end;

    procedure ModifyCalls(): Integer
    begin
        exit(ModifyCount);
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertUser(var Rec: Record User; RunTrigger: Boolean)
    begin
        if Rec."User Security ID" <> WatchedSid then
            exit;
        InsertCount += 1;
        SeenInsert := Rec."Authentication Email";
        if HasReplacement then
            Rec."Authentication Email" := CopyStr(Replacement, 1, MaxStrLen(Rec."Authentication Email"));
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyUser(var Rec: Record User; var xRec: Record User; RunTrigger: Boolean)
    begin
        if Rec."User Security ID" <> WatchedSid then
            exit;
        ModifyCount += 1;
        SeenModify := Rec."Authentication Email";
        if HasReplacement then
            Rec."Authentication Email" := CopyStr(Replacement, 1, MaxStrLen(Rec."Authentication Email"));
    end;
}
