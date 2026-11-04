// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope, OnPrem app (the platform checks the Windows Security ID on tiers that use Windows authentication; see TestUserAuthEmailTrigger.al)
// Fixtures used: tests/al-language/platform/lt-platform-tables/PtHelper.al (LT PT OnPrem Ops, PtOnPremOps.al)
// Probe: the User system table with a non-blank "Windows Security ID" (field 7): a first User, a second User with the same SID, a User with another SID
// and the same User Name, two Users with a blank SID, a Modify that moves a SID to a SID another User holds, a Modify to a free SID, and a text that is not a SID.
// Every User is an External User (license type 4), as in TestUserAuthEmailTrigger.al. Each request runs in its own Codeunit.Run, so an error is observed as text and code.

codeunit 61234 "LT User Windows SID"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT OnPrem Ops";

    [Test]
    procedure InsertAndModify_SidUniqueness()
    var
        Observer: Codeunit "Probe Observer";
        T: Integer;
    begin
        T := Database::User;
        Observer.Observe('insert_first', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000001};2=LTSID1;7=S-1-5-21-1000-2000-3000-1001;10=4', true));
        Observer.Observe('insert_same_sid_other_name', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000002};2=LTSID2;7=S-1-5-21-1000-2000-3000-1001;10=4', true));
        Observer.Observe('insert_other_sid_same_name', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000003};2=LTSID1;7=S-1-5-21-1000-2000-3000-1002;10=4', true));
        Observer.Observe('insert_other_sid_other_name', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000004};2=LTSID4;7=S-1-5-21-1000-2000-3000-1002;10=4', true));
        Observer.Observe('insert_blank_sid_a', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000005};2=LTSID5;10=4', true));
        Observer.Observe('insert_blank_sid_b', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000006};2=LTSID6;10=4', true));
        Observer.Observe('modify_to_sid_held_by_other', Ops.Perform(T, 'modify', '1={A1000000-0000-0000-0000-000000000005}|7=S-1-5-21-1000-2000-3000-1001', true));
        Observer.Observe('modify_to_free_sid', Ops.Perform(T, 'modify', '1={A1000000-0000-0000-0000-000000000005}|7=S-1-5-21-1000-2000-3000-1003', true));
        Observer.Observe('modify_own_sid_unchanged', Ops.Perform(T, 'modify', '1={A1000000-0000-0000-0000-000000000005}|7=S-1-5-21-1000-2000-3000-1003', true));
        Observer.Observe('modify_sid_to_blank', Ops.Perform(T, 'modify', '1={A1000000-0000-0000-0000-000000000005}|7=', true));
        Observer.Observe('insert_not_a_sid', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000007};2=LTSID7;7=not a sid;10=4', true));
        Observer.Observe('insert_sid_case', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000008};2=LTSID8;7=s-1-5-21-1000-2000-3000-1001;10=4', true));
        Observer.Observe('count_sid_1001', Ops.Perform(T, 'count', '7=S-1-5-21-1000-2000-3000-1001', false));
        Observer.Observe('count_sid_1002', Ops.Perform(T, 'count', '7=S-1-5-21-1000-2000-3000-1002', false));
        Observer.Expect('insert_first', 'ok:Yes');
        Observer.Expect('insert_same_sid_other_name', 'error:The same Windows Account can be connected to only one Business Central user.|UserTableUserWindowsSidMustBeUnique');
        Observer.Expect('insert_other_sid_same_name', 'error:The user name must be unique.|UserTableUserNameMustBeUnique');
        Observer.Expect('insert_other_sid_other_name', 'ok:Yes');
        Observer.Expect('insert_blank_sid_a', 'ok:Yes');
        Observer.Expect('insert_blank_sid_b', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('modify_to_sid_held_by_other', 'error:The same Windows Account can be connected to only one Business Central user.|UserTableUserWindowsSidMustBeUnique');
#else
        Observer.Expect('modify_to_sid_held_by_other', 'error:Windows security identifier is not supported in online environments.|Dialog');
#endif
#if BC29PLUS
        Observer.Expect('modify_to_free_sid', 'ok:Yes');
#else
        Observer.Expect('modify_to_free_sid', 'error:Windows security identifier is not supported in online environments.|Dialog');
#endif
#if BC29PLUS
        Observer.Expect('modify_own_sid_unchanged', 'ok:Yes');
#else
        Observer.Expect('modify_own_sid_unchanged', 'error:Windows security identifier is not supported in online environments.|Dialog');
#endif
        Observer.Expect('modify_sid_to_blank', 'ok:Yes');
        Observer.Expect('insert_not_a_sid', 'ok:Yes');
        Observer.Expect('insert_sid_case', 'ok:Yes');
        Observer.Expect('count_sid_1001', 'ok:1');
        Observer.Expect('count_sid_1002', 'ok:1');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_SameSidDisabledUser()
    var
        Observer: Codeunit "Probe Observer";
        T: Integer;
    begin
        T := Database::User;
        Observer.Observe('insert_disabled', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000011};2=LTSID11;4=1;7=S-1-5-21-1000-2000-3000-1101;10=4', true));
        Observer.Observe('insert_enabled_same_sid', Ops.Perform(T, 'insert', '1={A1000000-0000-0000-0000-000000000012};2=LTSID12;7=S-1-5-21-1000-2000-3000-1101;10=4', true));
        Observer.Observe('modify_disabled_to_enabled', Ops.Perform(T, 'modify', '1={A1000000-0000-0000-0000-000000000011}|4=0', true));
        Observer.Expect('insert_disabled', 'ok:Yes');
        Observer.Expect('insert_enabled_same_sid', 'error:The same Windows Account can be connected to only one Business Central user.|UserTableUserWindowsSidMustBeUnique');
#if BC29PLUS
        Observer.Expect('modify_disabled_to_enabled', 'ok:Yes');
#else
        Observer.Expect('modify_disabled_to_enabled', 'error:Windows security identifier is not supported in online environments.|Dialog');
#endif
        Observer.Verify();
    end;
}
