// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-delete-method
// Scope: in-scope, OnPrem app - see "WHY THIS FILE IS IN THE ONPREM APP" in TestUserAuthEmailTrigger.al
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// CLAIM: deleting a User also deletes that user's User Property (2000000121) row - the row the
// platform creates with every User. The platform does this as part of the record delete
// itself, AFTER the table's OnBeforeDelete event subscribers and BEFORE its OnAfterDelete
// event subscribers. So:
//   * an OnBeforeDelete subscriber still finds the user's User Property row;
//   * an OnAfterDelete subscriber no longer finds it;
//   * both hold for Delete() and for a DeleteAll() over the user.
//
// The subscriber (codeunit 61211) is bound manually and acts only on the one User row the test
// names, so the other User writes of the run are untouched. Every user is an "External User",
// for the license reason given in TestUserAuthEmailTrigger.al.
codeunit 61210 "Test User Delete Cascade Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure UserDeleteOrder_OnBeforeDeleteSubscriberStillSeesUserProperty()
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
        Spy: Codeunit "User Delete Cascade Spy";
    begin
        NewUser(UserRec);
        Assert.IsTrue(UserProperty.Get(UserRec."User Security ID"), 'precondition: the platform creates a User Property row with every User');
        Spy.Watch(UserRec."User Security ID");
        BindSubscription(Spy);

        UserRec.Delete();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.BeforeDeleteCalls(), 'the OnBeforeDelete subscriber must have run once for the watched user');
        Assert.AreEqual(1, Spy.PropertyRowsSeenBeforeDelete(), 'an OnBeforeDelete subscriber must still find the user''s User Property row');
        Assert.IsFalse(UserProperty.Get(UserRec."User Security ID"), 'deleting the User must delete its User Property row');
    end;

    [Test]
    procedure UserDeleteOrder_OnAfterDeleteSubscriberNoLongerSeesUserProperty()
    var
        UserRec: Record User;
        Spy: Codeunit "User Delete Cascade Spy";
    begin
        NewUser(UserRec);
        Spy.Watch(UserRec."User Security ID");
        BindSubscription(Spy);

        UserRec.Delete();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.AfterDeleteCalls(), 'the OnAfterDelete subscriber must have run once for the watched user');
        Assert.AreEqual(0, Spy.PropertyRowsSeenAfterDelete(), 'an OnAfterDelete subscriber must find the User Property row already gone');
    end;

    [Test]
    procedure UserDeleteOrder_DeleteAllOnBeforeDeleteSubscriberStillSeesUserProperty()
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
        Spy: Codeunit "User Delete Cascade Spy";
        Sid: Guid;
    begin
        NewUser(UserRec);
        Sid := UserRec."User Security ID";
        Spy.Watch(Sid);
        BindSubscription(Spy);

        UserRec.Reset();
        UserRec.SetRange("User Security ID", Sid);
        UserRec.DeleteAll();
        UnbindSubscription(Spy);

        Assert.AreEqual(1, Spy.BeforeDeleteCalls(), 'DeleteAll over one User must raise OnBeforeDelete once for it');
        Assert.AreEqual(1, Spy.PropertyRowsSeenBeforeDelete(), 'an OnBeforeDelete subscriber must still find the user''s User Property row under DeleteAll');
        Assert.AreEqual(0, Spy.PropertyRowsSeenAfterDelete(), 'an OnAfterDelete subscriber must find the User Property row already gone under DeleteAll');
        Assert.IsFalse(UserProperty.Get(Sid), 'DeleteAll over the User must delete its User Property row');
    end;

    local procedure NewUser(var UserRec: Record User)
    begin
        UserRec.Init();
        UserRec."User Security ID" := CreateGuid();
        UserRec."User Name" := CopyStr('T61210' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 50);
        UserRec."License Type" := UserRec."License Type"::"External User";
        UserRec.Insert();
    end;
}

codeunit 61211 "User Delete Cascade Spy"
{
    EventSubscriberInstance = Manual;

    var
        WatchedSid: Guid;
        BeforeCount: Integer;
        AfterCount: Integer;
        RowsBefore: Integer;
        RowsAfter: Integer;

    procedure Watch(Sid: Guid)
    begin
        WatchedSid := Sid;
        RowsBefore := -1;
        RowsAfter := -1;
    end;

    procedure BeforeDeleteCalls(): Integer
    begin
        exit(BeforeCount);
    end;

    procedure AfterDeleteCalls(): Integer
    begin
        exit(AfterCount);
    end;

    procedure PropertyRowsSeenBeforeDelete(): Integer
    begin
        exit(RowsBefore);
    end;

    procedure PropertyRowsSeenAfterDelete(): Integer
    begin
        exit(RowsAfter);
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteUser(var Rec: Record User; RunTrigger: Boolean)
    begin
        if Rec."User Security ID" <> WatchedSid then
            exit;
        BeforeCount += 1;
        RowsBefore := CountPropertyRows(Rec."User Security ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteUser(var Rec: Record User; RunTrigger: Boolean)
    begin
        if Rec."User Security ID" <> WatchedSid then
            exit;
        AfterCount += 1;
        RowsAfter := CountPropertyRows(Rec."User Security ID");
    end;

    local procedure CountPropertyRows(Sid: Guid): Integer
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.SetRange("User Security ID", Sid);
        exit(UserProperty.Count());
    end;
}
