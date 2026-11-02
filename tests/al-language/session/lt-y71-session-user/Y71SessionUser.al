// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-userid-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunits 93827-93829 (writer Y71, gap cycle 7 spec G7-07)
// Probe: what the session user looks like when a test starts, seen through the public surface of the System Application: every User row (the session
//        user as `me`, the others as `other-N`: state, license type, whether the User Login Time Tracker reports a login in this environment, whether
//        it is a first login, whether a penultimate login time is set, the roles of its Access Control rows), the Environment Information answers,
//        the session type and GuiAllowed, in the first test of a codeunit, in a later test, and in a test with TransactionModel AutoRollback; the
//        loop of the System Application's test library DeleteAllUnLoggedInUsers by hand over two users inserted by the test (never over real users);
//        a Delete of the session user inside AutoRollback.
//        The values depend on the tier (SaaS, Windows container, Linux container, how the test user logged in). Test procedures with EnvData in the
//        name are recorded with the Probe Observer and not asserted: the values per tier are in the hand-off of writer Y71 and in the corpus pull request.

codeunit 93827 "LT Y71 Session User A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Yes');
        exit('No');
    end;

    local procedure Roles(UserSid: Guid) Result: Text
    var
        AC: Record "Access Control";
    begin
        AC.SetRange("User Security ID", UserSid);
        if AC.FindSet() then
            repeat
                if Result <> '' then
                    Result += '+';
                Result += StrSubstNo('%1:%2:company=%3', AC."Role ID", AC.Scope, YesNo(AC."Company Name" <> ''));
            until AC.Next() = 0;
        if Result = '' then
            Result := 'none';
    end;

    local procedure Users() Result: Text
    var
        U: Record User;
        Tracker: Codeunit "User Login Time Tracker";
        Who: Text;
        Index: Integer;
    begin
        if U.FindSet() then
            repeat
                Index += 1;
                if U."User Security ID" = UserSecurityId() then
                    Who := 'me'
                else
                    Who := 'other-' + Format(Index);
                if Result <> '' then
                    Result += ' | ';
                Result += StrSubstNo('%1 state=%2 license=%3 env=%4 first=%5 penultimate=%6 roles=%7', Who, U.State, U."License Type",
                    YesNo(Tracker.UserLoggedInEnvironment(U."User Security ID")), YesNo(Tracker.IsFirstLogin(U."User Security ID")),
                    SetOrBlank(Tracker.GetPenultimateLoginDateTime(U."User Security ID")), Roles(U."User Security ID"));
            until U.Next() = 0;
        if Result = '' then
            Result := 'no users';
    end;

    local procedure SetOrBlank(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('0DT');
        exit('set');
    end;

    local procedure Observations(Name: Text)
    var
        EnvInfo: Codeunit "Environment Information";
        Tracker: Codeunit "User Login Time Tracker";
        U: Record User;
    begin
        Obs.Observe(Name + '|user_count', Format(U.Count()));
        Obs.Observe(Name + '|users', Users());
        Obs.Observe(Name + '|gui_allowed', YesNo(GuiAllowed()));
        Obs.Observe(Name + '|is_saas', YesNo(EnvInfo.IsSaaS()));
        Obs.Observe(Name + '|is_sandbox', YesNo(EnvInfo.IsSandbox()));
        Obs.Observe(Name + '|is_onprem', YesNo(EnvInfo.IsOnPrem()));
        Obs.Observe(Name + '|is_production', YesNo(EnvInfo.IsProduction()));
        Obs.Observe(Name + '|me_logged_in_environment', YesNo(Tracker.UserLoggedInEnvironment(UserSecurityId())));
        Obs.Observe(Name + '|me_first_login', YesNo(Tracker.IsFirstLogin(UserSecurityId())));
        Obs.Observe(Name + '|me_penultimate', SetOrBlank(Tracker.GetPenultimateLoginDateTime()));
        Obs.Observe(Name + '|any_logged_in_since_2000', YesNo(Tracker.AnyUserLoggedInSinceDate(20000101D)));
        Obs.Observe(Name + '|me_in_user_table', YesNo(U.Get(UserSecurityId())));
    end;

    [Test]
    procedure SessionUser_RowsAtTestStart_EnvData()
    begin
        Observations('first_test');
        Obs.Finish();
    end;

    [Test]
    procedure SessionUser_RowsInLaterTest_EnvData()
    begin
        Observations('later_test');
        Obs.Finish();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SessionUser_RowsUnderAutoRollback_EnvData()
    begin
        Observations('auto_rollback');
        Obs.Finish();
    end;
}

codeunit 93828 "LT Y71 Session User Helper"
{
    var
        Mode: Integer;
        Outcome: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        Outcome := '';
    end;

    procedure GetOutcome(): Text
    begin
        exit(Outcome);
    end;

    trigger OnRun()
    var
        U: Record User;
        Tracker: Codeunit "User Login Time Tracker";
    begin
        case Mode of
            1:
                begin
                    // the by-hand loop of DeleteAllUnLoggedInUsers over the two users this test inserted (never over real users)
                    U.SetFilter("User Name", 'LTY71UL*');
                    if U.FindSet() then
                        repeat
                            if not Tracker.UserLoggedInEnvironment(U."User Security ID") then begin
                                U.Delete();
                                Outcome += 'deleted;';
                            end else
                                Outcome += 'kept;';
                        until U.Next() = 0;
                    if Outcome = '' then
                        Outcome := 'no rows';
                end;
            2:
                begin
                    U.Get(UserSecurityId());
                    U.Delete();
                    Outcome := 'deleted';
                end;
            3:
                begin
                    U.Init();
                    U."User Security ID" := CreateGuid();
                    U."User Name" := 'LTY71UL1';
                    U.State := U.State::Enabled;
                    U.Insert();
                    Outcome := 'inserted';
                end;
        end;
    end;
}

codeunit 93829 "LT Y71 Session User Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Run(Name: Text; Mode: Integer)
    var
        Helper: Codeunit "LT Y71 Session User Helper";
    begin
        Helper.SetMode(Mode);
        if Helper.Run() then
            Obs.Observe(Name, 'ok|' + Helper.GetOutcome())
        else begin
            Obs.Observe(Name, 'error|' + Helper.GetOutcome());
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteAllUnLoggedInUsers_Shape_EnvData()
    var
        U: Record User;
    begin
        Run('insert_user', 3);
        Obs.Observe('inserted_visible', Format(U.Count() > 0));
        Run('loop', 1);
        Obs.Finish();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserDelete_SessionUser_EnvData()
    var
        U: Record User;
    begin
        Run('delete_session_user', 2);
        Obs.Observe('session_user_row_after', Format(U.Get(UserSecurityId())));
        Obs.Finish();
    end;
}
