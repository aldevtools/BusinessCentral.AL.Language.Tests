// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y19PermObjects.al; xapp-a Y19XaObjects.al (61184), xapp-b Y19XbObjects.al (61187-61188); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 stage 1 probes, writer Y19:
//   P5 the app name in the permission error when code of one app touches the table of another: xapp-b code (no Permissions property)
//      reads and inserts a table of xapp-a, and inserts its own table, called from this app's test under a set that grants nothing there;
//      this app's own code on the xapp-a table for comparison;
//   Not here (P9, a role id declared by two apps): BC does not publish the second app. With permissionset "LT Y19 Dup" in xapp-d and in
//   xapp-b (the two do not depend on each other; both compile), publishing xapp-b fails with HTTP 422 "Publishing failed due to 'The object
//   name 'LT Y19 DUP' can only appear once for the type 'PermissionSet'. The same object exists in both extension (...)" (BC 29.0, CI run
//   41188729109). So two apps in one database never declare the same role id.
// Facts (BC 27.5, 28.5, 29.0): the app name in the error is the app whose code makes the access: xapp-b code on an xapp-a table gives
//   ': AL Language XApp B'; this app's code on xapp-a or xapp-b tables gives ': AL Language Coverage Tests'.
// BC versions: 27, 28, 29

codeunit 91953 "LT Y19 Perm Cross App"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y19_P5_AppNameAcrossApps()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Helper.StartMock(Mock);
        RunCase(Observer, 'xb_reads_xa', 'LT Y19 None', 1);
        RunCase(Observer, 'xb_inserts_xa', 'LT Y19 None', 2);
        RunCase(Observer, 'xb_inserts_own', 'LT Y19 None', 3);
        RunCase(Observer, 'test_reads_xa', 'LT Y19 None', 4);
        RunCase(Observer, 'test_inserts_xa', 'LT Y19 None', 5);
        RunCase(Observer, 'test_inserts_xb', 'LT Y19 None', 6);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('xb_reads_xa|text', 'Sorry, the current permissions prevented the action. (TableData 61184 LT Y19 XA Row Read: AL Language XApp B)');
        Observer.Expect('xb_reads_xa|code', 'DB:ClientReadDenied');
        Observer.Expect('xb_inserts_xa|text', 'Sorry, the current permissions prevented the action. (TableData 61184 LT Y19 XA Row Insert: AL Language XApp B)');
        Observer.Expect('xb_inserts_xa|code', 'DB:ClientInsertDenied');
        Observer.Expect('xb_inserts_own|text', 'Sorry, the current permissions prevented the action. (TableData 61188 LT Y19 XB Row Insert: AL Language XApp B)');
        Observer.Expect('xb_inserts_own|code', 'DB:ClientInsertDenied');
        Observer.Expect('test_reads_xa|text', 'Sorry, the current permissions prevented the action. (TableData 61184 LT Y19 XA Row Read: AL Language Coverage Tests)');
        Observer.Expect('test_reads_xa|code', 'DB:ClientReadDenied');
        Observer.Expect('test_inserts_xa|text', 'Sorry, the current permissions prevented the action. (TableData 61184 LT Y19 XA Row Insert: AL Language Coverage Tests)');
        Observer.Expect('test_inserts_xa|code', 'DB:ClientInsertDenied');
        Observer.Expect('test_inserts_xb|text', 'Sorry, the current permissions prevented the action. (TableData 61188 LT Y19 XB Row Insert: AL Language Coverage Tests)');
        Observer.Expect('test_inserts_xb|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Which: Integer)
    begin
        Mock.ClearAssignments();
        Seed();
        ClearLastError();
        if not TrySet(SetName) then begin
            Observer.Observe(Name + '|set', 'failed: ' + GetLastErrorText());
            Observer.Observe(Name + '|set_code', GetLastErrorCode());
            ClearLastError();
            Mock.ClearAssignments();
            exit;
        end;
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    [TryFunction]
    local procedure TrySet(SetName: Code[20])
    begin
        Mock.Set(SetName);
    end;

    local procedure Seed()
    var
        XaRow: Record "LT Y19 XA Row";
        XbRow: Record "LT Y19 XB Row";
    begin
        XaRow.DeleteAll();
        XbRow.DeleteAll();
        XaRow.Id := 1;
        XaRow.Insert();
        XbRow.Id := 1;
        XbRow.Insert();
    end;

    local procedure Op(Which: Integer)
    var
        XaRow: Record "LT Y19 XA Row";
        XbRow: Record "LT Y19 XB Row";
        Access: Codeunit "LT Y19 XB Access";
        Result: Text;
    begin
        case Which of
            1:
                Result := Format(Access.CountXa());
            2:
                Access.InsertXa(5);
            3:
                Access.InsertOwn(5);
            4:
                Result := Format(XaRow.Count());
            5:
                begin
                    XaRow.Id := 5;
                    XaRow.Insert();
                end;
            6:
                begin
                    XbRow.Id := 5;
                    XbRow.Insert();
                end;
        end;
        Error('LT Y19 ok %1', Result);
    end;
}
