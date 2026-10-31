// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (gap cycle 3, C3-03 section P): the stored platform table Privacy Notice Approval (2000000238, Scope = Cloud) on the corpus container:
//   rows at the start, Insert/Get/Modify/DeleteAll, whether the platform fills "Approver User SID", whether the table events fire (a Manual
//   subscriber bound in the test logs them), and the FlowFields Enabled/Disabled of Privacy Notice (2000000237) over the approvals with
//   "User SID Filter" = the null Guid and = UserSecurityId(). User SIDs are shown as null / me / other, never as values.
//   Neighbour: events/lt-platform-triggers/PtObjects.al:93 (Privacy Notice, stored, starts empty).
// BC versions: 27.5, 28.5, 29.0

codeunit 92355 "LT Y35 Privacy Approval Events"
{
    EventSubscriberInstance = Manual;

    var
        Log: Text;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Privacy Notice Approval", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "Privacy Notice Approval"; RunTrigger: Boolean)
    begin
        Log += 'ins(' + Rec.ID + ');';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Privacy Notice Approval", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModify(var Rec: Record "Privacy Notice Approval"; var xRec: Record "Privacy Notice Approval"; RunTrigger: Boolean)
    begin
        Log += 'mod(' + Rec.ID + ');';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Privacy Notice Approval", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDelete(var Rec: Record "Privacy Notice Approval"; RunTrigger: Boolean)
    begin
        Log += 'del(' + Rec.ID + ');';
    end;
}

codeunit 92354 "LT Y35 Privacy Approval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Sid(Value: Guid): Text
    begin
        if IsNullGuid(Value) then
            exit('null');
        if Value = UserSecurityId() then
            exit('me');
        exit('other');
    end;

    local procedure Row(var Approval: Record "Privacy Notice Approval"): Text
    begin
        exit(Approval.ID + '|User SID=' + Sid(Approval."User SID") + '|Approver=' + Sid(Approval."Approver User SID") + '|Approved=' + Format(Approval.Approved));
    end;

    local procedure Rows(var Approval: Record "Privacy Notice Approval"): Text
    var
        Result: Text;
    begin
        if Approval.FindSet() then
            repeat
                Result += '[' + Row(Approval) + ']';
            until Approval.Next() = 0;
        exit(Result);
    end;

    // Insert() as a Boolean: a duplicate key gives false, no error.
    local procedure Insert(Op: Text; Id: Code[50]; UserSid: Guid; Approved: Boolean)
    var
        Approval: Record "Privacy Notice Approval";
    begin
        Approval.Init();
        Approval.ID := Id;
        Approval."User SID" := UserSid;
        Approval.Approved := Approved;
        Observer.Observe(Op, Format(Approval.Insert()) + '|' + Row(Approval));
    end;

    // Deletes the approvals of Id. A Privacy Notice row is not deleted: the app has no Delete permission on it (InherentEntitlements
    // RIMdX; BC 29 SaaS: "Your license does not grant you ... Delete"); the test isolation rolls it back.
    local procedure Clean(Id: Code[50])
    var
        Approval: Record "Privacy Notice Approval";
    begin
        Approval.SetRange(ID, Id);
        Approval.DeleteAll();
    end;

    local procedure Flags(Id: Code[50]): Text
    var
        Notice: Record "Privacy Notice";
        EmptyGuid: Guid;
        Result: Text;
    begin
        Notice.Get(Id);
        Notice.SetRange("User SID Filter", EmptyGuid);
        Notice.CalcFields(Enabled, Disabled);
        Result := 'null:E=' + Format(Notice.Enabled) + ',D=' + Format(Notice.Disabled);
        Notice.SetRange("User SID Filter", UserSecurityId());
        Notice.CalcFields(Enabled, Disabled);
        Result += '|me:E=' + Format(Notice.Enabled) + ',D=' + Format(Notice.Disabled);
        exit(Result);
    end;

    [Test]
    procedure C303_PrivacyApproval_RowsAtStart()
    var
        Approval: Record "Privacy Notice Approval";
    begin
        Observer.Observe('count_start', Format(Approval.Count()));
        Observer.Observe('rows_start', Rows(Approval));
        Observer.Finish();
    end;

    [Test]
    procedure C303_PrivacyApproval_RowsAndWrites()
    var
        Approval: Record "Privacy Notice Approval";
        Events: Codeunit "LT Y35 Privacy Approval Events";
        EmptyGuid: Guid;
    begin
        Clean('LT-C303');
        BindSubscription(Events);
        Insert('insert_admin', 'LT-C303', EmptyGuid, true);
        Insert('insert_user', 'LT-C303', UserSecurityId(), false);
        Insert('insert_dup', 'LT-C303', UserSecurityId(), true);
        Observer.Observe('get_admin', Format(Approval.Get('LT-C303', EmptyGuid)) + '|' + Row(Approval));
        Observer.Observe('get_user', Format(Approval.Get('LT-C303', UserSecurityId())) + '|' + Row(Approval));
        Approval.Approved := true;
        Observer.Observe('modify_user', Format(Approval.Modify()));
        Approval.Get('LT-C303', UserSecurityId());
        Observer.Observe('row_after_modify', Row(Approval));
        Approval.Reset();
        Approval.SetRange(ID, 'LT-C303');
        Observer.Observe('count_own', Format(Approval.Count()));
        Approval.DeleteAll();
        Observer.Observe('count_after_deleteall', Format(Approval.Count()));
        UnbindSubscription(Events);
        Observer.Observe('events', Events.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure C303_PrivacyNotice_FlowFields()
    var
        Notice: Record "Privacy Notice";
        Approval: Record "Privacy Notice Approval";
        EmptyGuid: Guid;
    begin
        Clean('LT-C303P');
        if not Notice.Get('LT-C303P') then begin
            Notice.Init();
            Notice.ID := 'LT-C303P';
            Notice."Integration Service Name" := 'LT Y35';
            Notice.Insert();
        end;
        Observer.Observe('before', Flags('LT-C303P'));
        Insert('insert_admin', 'LT-C303P', EmptyGuid, true);
        Observer.Observe('after_admin_approved', Flags('LT-C303P'));
        Insert('insert_user', 'LT-C303P', UserSecurityId(), false);
        Observer.Observe('after_user_rejected', Flags('LT-C303P'));
        Approval.Get('LT-C303P', EmptyGuid);
        Approval.Delete();
        Observer.Observe('after_admin_deleted', Flags('LT-C303P'));
        Approval.Get('LT-C303P', UserSecurityId());
        Approval.Approved := true;
        Approval.Modify();
        Observer.Observe('after_user_approved', Flags('LT-C303P'));
        Clean('LT-C303P');
        Observer.Observe('after_all_deleted', Flags('LT-C303P'));
        Observer.Finish();
    end;
}
