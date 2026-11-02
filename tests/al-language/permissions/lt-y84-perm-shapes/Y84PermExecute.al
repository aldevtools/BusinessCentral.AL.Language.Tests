// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y84PermObjects.al (94380-94421); Y24PermObjects.al (the target codeunit "LT Y24 Exec Target"); Permissions Mock (131006).
// Probe: al-runtime-rs ADR-062 stage 3, writer Y84: an Execute denial raised inside a table trigger (OnInsert, OnModify, OnDelete; Codeunit.Run and a call on a
//   codeunit variable), inside a page trigger (OnOpenPage, an action's OnAction) and inside an event subscriber. Each case assigns an exact set (table data and
//   the object that holds the code, with and without Execute on the codeunit the code runs), runs ONE operation inside asserterror that ends with
//   'LT Y84 ok <result>', keeps text and code, clears the assignment and only then observes.
// BC versions: 27, 28, 29

codeunit 94393 "LT Y84 Perm Execute"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Binder: Codeunit "LT Y84 Subscriber";

    [Test]
    procedure Y84_Exec_TableInsertA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact('tab_codeunit_run', 'LT Y84 T Tab', 1);
        RunExact('tab_call', 'LT Y84 T Tab', 2);
        RunExact('tabx_codeunit_run', 'LT Y84 T TabX', 1);
        RunExact('tabx_call', 'LT Y84 T TabX', 2);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Exec_TableInsertB()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact('tgt_codeunit_run', 'LT Y84 T Tgt', 1);
        RunExact('tgt_call', 'LT Y84 T Tgt', 2);
        RunExact('both_codeunit_run', 'LT Y84 T Both', 1);
        RunExact('both_call', 'LT Y84 T Both', 2);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Exec_TableModifyDelete()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact('tab_modify', 'LT Y84 T Tab', 3);
        RunExact('tab_delete', 'LT Y84 T Tab', 4);
        RunExact('tgt_modify', 'LT Y84 T Tgt', 3);
        RunExact('tgt_delete', 'LT Y84 T Tgt', 4);
        RunExact('both_modify', 'LT Y84 T Both', 3);
        RunExact('both_delete', 'LT Y84 T Both', 4);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Exec_Subscriber()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        BindSubscription(Binder);
        RunExact('sub_tab', 'LT Y84 S Tab', 5);
        RunExact('sub_sub', 'LT Y84 S Sub', 5);
        RunExact('sub_tgt', 'LT Y84 S Tgt', 5);
        RunExact('sub_both', 'LT Y84 S Both', 5);
        UnbindSubscription(Binder);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Exec_PageOpen()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact('page_page', 'LT Y84 P Page', 6);
        RunExact('page_both', 'LT Y84 P Both', 6);
        Mock.ClearAssignments();
        Seed();
        asserterror Op(6);
        Observer.ObserveError('page_noset');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Exec_PageAction()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact('action_page', 'LT Y84 A Page', 7);
        RunExact('action_both', 'LT Y84 A Both', 7);
        Mock.ClearAssignments();
        Seed();
        asserterror Op(7);
        Observer.ObserveError('action_noset');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    local procedure Seed()
    var
        Trig: Record "LT Y84 Trig Tbl";
        Sub: Record "LT Y84 Sub Tbl";
    begin
        Trig.DeleteAll();
        Sub.DeleteAll();
        Trig.Id := 10;
        Trig.Mode := 0;
        Trig.Insert();
        Trig.Id := 11;
        Trig.Mode := 1;
        Trig.Insert();
        Sub.Id := 1;
        Sub.Insert();
    end;

    local procedure RunExact(Name: Text; SetName: Code[20]; Which: Integer)
    var
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        Seed();
        Mock.SetExactPermissionSet(SetName);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        Observer.Observe(Name + '|text', ErrorText);
        Observer.Observe(Name + '|code', ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        Trig: Record "LT Y84 Trig Tbl";
        Sub: Record "LT Y84 Sub Tbl";
        OpenPage: TestPage "LT Y84 Trig Open";
        ActPage: TestPage "LT Y84 Trig Action";
        Result: Text;
    begin
        case Which of
            1, 2:
                begin
                    Trig.Id := 1;
                    Trig.Mode := Which;
                    Trig.Insert(true);
                    Result := 'inserted';
                end;
            3:
                begin
                    Trig.Get(10);
                    Trig.Mode := 1;
                    Trig.Modify(true);
                    Result := 'modified';
                end;
            4:
                begin
                    Trig.Get(11);
                    Trig.Delete(true);
                    Result := 'deleted';
                end;
            5:
                begin
                    Sub.Id := 2;
                    Sub.Insert(true);
                    Result := 'inserted';
                end;
            6:
                begin
                    OpenPage.OpenView();
                    Result := 'opened';
                    OpenPage.Close();
                end;
            7:
                begin
                    ActPage.OpenView();
                    ActPage.RunIt.Invoke();
                    Result := 'invoked';
                    ActPage.Close();
                end;
        end;
        Error('LT Y84 ok %1', Result);
    end;

    local procedure StartMock() WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
