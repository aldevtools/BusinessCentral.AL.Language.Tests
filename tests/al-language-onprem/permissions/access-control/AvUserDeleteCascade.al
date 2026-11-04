// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-delete-method
// Scope: in-scope (OnPrem app: the User, User Property and Access Control platform tables are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 98401 (tests) and 98402 (manual subscriber)
// Probe: corpus issue 647 items 20 and 23 (writer AV). Every test removes the users it created (names start with LTAV) first and last.
// Facts: a user with rows in User Property, User Personalization, Access Control, User Plan and User Setup is deleted with Delete(true) and Delete(false):
//   which rows are gone afterwards, and which still exist when an OnBeforeDeleteEvent and an OnAfterDeleteEvent subscriber of the User table run.
//   ("User Group Member" is removed from the Base Application in BC 27 and later: must-not-compile case 1172.)
// BC versions: 27, 28, 29
codeunit 98401 "LT AV User Delete Cascade"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cleanup()
    var
        UserRec: Record User;
    begin
        UserRec.SetFilter("User Name", 'LTAV*');
        UserRec.DeleteAll(true);
    end;

    local procedure NewUserWithRows(Name: Code[50]) Sid: Guid
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
        UserPers: Record "User Personalization";
        Acl: Record "Access Control";
        UserPlan: RecordRef;
        UserSetup: Record "User Setup";
    begin
        Sid := CreateGuid();
        UserRec.Init();
        UserRec."User Security ID" := Sid;
        UserRec."User Name" := Name;
        UserRec.State := UserRec.State::Enabled;
        UserRec.Insert(false);
        if not UserProperty.Get(Sid) then begin
            UserProperty.Init();
            UserProperty."User Security ID" := Sid;
            UserProperty.Insert();
        end;
        if not UserPers.Get(Sid) then begin
            UserPers.Init();
            UserPers."User SID" := Sid;
            UserPers.Insert();
        end;
        Acl.Init();
        Acl."User Security ID" := Sid;
        Acl."Role ID" := 'LTAVROLE';
        Acl."Company Name" := '';
        Acl.Insert();
        // "User Plan" (9005) is Access = Internal in the System Application: reached through a RecordRef (field 1 User Security ID, field 2 Plan ID).
        UserPlan.Open(9005);
        UserPlan.Init();
        UserPlan.Field(1).Value := Sid;
        UserPlan.Field(2).Value := CreateGuid();
        UserPlan.Insert();
        UserSetup.Init();
        UserSetup."User ID" := Name;
        UserSetup.Insert();
    end;

    local procedure Run(RunTrigger: Boolean; Name: Code[50])
    var
        Observer: Codeunit "Probe Observer";
        Watcher: Codeunit "LT AV User Delete Watcher";
        UserRec: Record User;
        Sid: Guid;
    begin
        Cleanup();
        Sid := NewUserWithRows(Name);
        Observer.Observe('before delete', Watcher.Rows(Sid, Name));
        Watcher.Watch(Sid, Name);
        BindSubscription(Watcher);
        UserRec.Get(Sid);
        UserRec.Delete(RunTrigger);
        UnbindSubscription(Watcher);
        Observer.Observe('subscribers', Watcher.Seen());
        Observer.Observe('after delete', Watcher.Rows(Sid, Name));
        Cleanup();
        Observer.Expect('before delete', 'property=1 personalization=1 access=1 plan=1 setup=1');
        Observer.Expect('subscribers', 'OnBeforeDelete(property=1 personalization=0 access=1 plan=1 setup=1) OnAfterDelete(property=0 personalization=0 access=0 plan=0 setup=1) ');
        Observer.Expect('after delete', 'property=0 personalization=0 access=0 plan=0 setup=1');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteTrue_RowsOfTheUser()
    begin
        Run(true, 'LTAV-DEL-TRUE');
    end;

    [Test]
    procedure DeleteFalse_RowsOfTheUser()
    begin
        Run(false, 'LTAV-DEL-FALSE');
    end;
}

codeunit 98402 "LT AV User Delete Watcher"
{
    EventSubscriberInstance = Manual;

    var
        WatchedSid: Guid;
        WatchedName: Code[50];
        Log: Text;

    procedure Watch(Sid: Guid; Name: Code[50])
    begin
        WatchedSid := Sid;
        WatchedName := Name;
        Log := '';
    end;

    procedure Seen(): Text
    begin
        exit(Log);
    end;

    local procedure Note(Step: Text)
    begin
        Log += Step + '(' + Rows(WatchedSid, WatchedName) + ') ';
    end;

    procedure Rows(Sid: Guid; Name: Code[50]): Text
    var
        UserProperty: Record "User Property";
        UserPers: Record "User Personalization";
        Acl: Record "Access Control";
        UserPlan: RecordRef;
        UserSetup: Record "User Setup";
    begin
        UserPlan.Open(9005);
        UserPlan.Field(1).SetRange(Sid);
        UserProperty.SetRange("User Security ID", Sid);
        UserPers.SetRange("User SID", Sid);
        Acl.SetRange("User Security ID", Sid);
                UserSetup.SetRange("User ID", Name);
        exit(StrSubstNo('property=%1 personalization=%2 access=%3 plan=%4 setup=%5', UserProperty.Count(), UserPers.Count(), Acl.Count(), UserPlan.Count(), UserSetup.Count()));
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDelete(var Rec: Record User; RunTrigger: Boolean)
    begin
        if Rec."User Security ID" = WatchedSid then
            Note('OnBeforeDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDelete(var Rec: Record User; RunTrigger: Boolean)
    begin
        if Rec."User Security ID" = WatchedSid then
            Note('OnAfterDelete');
    end;
}
