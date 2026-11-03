// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermObjects.al (94780-94829); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P23: a card with a part that has no AccessByPermission, opened under an exact set that grants the card (and the table data)
//   but not the part page (A), one that also grants the part page (B), and one that grants every page with page * = X (C). Y84 pinned the guarded part
//   (it needs Execute on its page); this file pins the unguarded one. Observed: whether the card opens and, if it does, whether a control of the part is
//   visible. Set-assigned (not exact) is observed for the same cards.
// BC versions: 27, 28, 29

codeunit 94809 "LT Y90 Perm Parts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y90_Part_ExactA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('a_parent_only', 'LT Y90 P Pages', 1, true);
        Run('a_cu_star', 'LT Y90 P PagesCuStar', 1, true);
        RestoreMock(WasStarted);
        Observer.Expect('a_parent_only',
            'The part with ID = n was not found on the page. | TestPartNotFound');
        Observer.Expect('a_cu_star',
            'The part with ID = n was not found on the page. | TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Part_ExactB()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('b_part_granted', 'LT Y90 P Parts', 2, true);
        Run('b_all_wildcards', 'LT Y90 P Parts2', 2, true);
        Run('b_table_x', 'LT Y90 P Parts3', 2, true);
        RestoreMock(WasStarted);
        Observer.Expect('b_part_granted',
            'The part with ID = n was not found on the page. | TestPartNotFound');
        Observer.Expect('b_all_wildcards',
            'LT Y90 ok part visible | Dialog');
        Observer.Expect('b_table_x',
            'The part with ID = n was not found on the page. | TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Part_ExactC()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('c_page_star', 'LT Y90 P PagesStar', 3, true);
        Run('c_star_star', 'LT Y90 P StarStar', 3, true);
        RestoreMock(WasStarted);
        Observer.Expect('c_page_star',
            'The part with ID = n was not found on the page. | TestPartNotFound');
        Observer.Expect('c_star_star',
            'The part with ID = n was not found on the page. | TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Part_Set()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('set_a_parent_only', 'LT Y90 P Pages', 1, false);
        RestoreMock(WasStarted);
        Observer.Expect('set_a_parent_only',
            'LT Y90 ok part visible | Dialog');
        Observer.Verify();
    end;

    local procedure Run(Tag: Text; SetName: Code[20]; Which: Integer; Exact: Boolean)
    var
        Trig: Record "LT Y90 Row";
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        Trig.DeleteAll();
        Trig.Id := 1;
        Trig.Insert();
        if Exact then
            Mock.SetExactPermissionSet(SetName)
        else
            Mock.Set(SetName);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        Observer.Observe(Tag, ErrorText + ' | ' + ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        A: TestPage "LT Y90 Card A";
        B: TestPage "LT Y90 Card B";
        C: TestPage "LT Y90 Card C";
        Result: Text;
    begin
        case Which of
            1:
                begin
                    A.OpenView();
                    Result := PartState(A.PartCtl.IdCol.Visible());
                    A.Close();
                end;
            2:
                begin
                    B.OpenView();
                    Result := PartState(B.PartCtl.IdCol.Visible());
                    B.Close();
                end;
            3:
                begin
                    C.OpenView();
                    Result := PartState(C.PartCtl.IdCol.Visible());
                    C.Close();
                end;
        end;
        Error('LT Y90 ok %1', Result);
    end;

    local procedure PartState(Visible: Boolean): Text
    begin
        if Visible then
            exit('part visible');
        exit('part hidden');
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
