// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermObjects.al (94780-94829); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21 (1339 lines of the shadow run over Microsoft's tests): AccessByPermission on page actions that the page also lists
//   in its Promoted area with actionref. What a session without the guard sees: does the page open, and is the action still on the TestPage, for actions in the
//   Processing, Creation, Navigation and Reporting areas, in a group, guarded by table data R, RIMD and by a codeunit. Sets: none of the guard, R, RIMD,
//   indirect r, Execute on the guard codeunit, and no assignment. Legend: Y = action visible, F = Visible returned false, N = the TestPage has no such action.
// BC versions: 27, 28, 29

codeunit 94807 "LT Y90 Perm ActionRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y90_ActionRef_NoSetAndNone()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveOne('noset');
        ObserveExact('LT Y90 A None', 'none');
        ObserveExact('LT Y90 A R', 'r');
        RestoreMock(WasStarted);
        Observer.Expect('noset',
            'PlainAct=Y GuardAct=Y GuardActRimd=Y CuAct=Y InGrpAct=Y CreateAct=Y NavAct=Y RepAct=Y');
        Observer.Expect('none',
            'PlainAct=Y GuardAct=N GuardActRimd=N CuAct=N InGrpAct=N CreateAct=N NavAct=N RepAct=N');
        Observer.Expect('r',
            'PlainAct=Y GuardAct=Y GuardActRimd=Y CuAct=N InGrpAct=Y CreateAct=Y NavAct=Y RepAct=Y');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_ActionRef_RimdIndirectCodeunit()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        ObserveExact('LT Y90 A RIMD', 'rimd');
        ObserveExact('LT Y90 A Ind R', 'indr');
        ObserveExact('LT Y90 A Cu', 'cu');
        RestoreMock(WasStarted);
        Observer.Expect('rimd',
            'PlainAct=Y GuardAct=Y GuardActRimd=Y CuAct=N InGrpAct=Y CreateAct=Y NavAct=Y RepAct=Y');
        Observer.Expect('indr',
            'PlainAct=Y GuardAct=N GuardActRimd=N CuAct=N InGrpAct=N CreateAct=N NavAct=N RepAct=N');
        Observer.Expect('cu',
            'PlainAct=Y GuardAct=N GuardActRimd=N CuAct=Y InGrpAct=N CreateAct=N NavAct=N RepAct=N');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_ActionRef_NotExact()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.Set('LT Y90 A None');
        ObserveOne('set none');
        Mock.Set('LT Y90 A R');
        ObserveOne('set r');
        RestoreMock(WasStarted);
        Observer.Expect('set none',
            'PlainAct=Y GuardAct=N GuardActRimd=N CuAct=Y InGrpAct=N CreateAct=N NavAct=N RepAct=N');
        Observer.Expect('set r',
            'PlainAct=Y GuardAct=Y GuardActRimd=Y CuAct=Y InGrpAct=Y CreateAct=Y NavAct=Y RepAct=Y');
        Observer.Verify();
    end;

    local procedure ObserveExact(SetName: Code[20]; Tag: Text)
    begin
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet(SetName);
        ObserveOne(Tag);
    end;

    local procedure ObserveOne(Tag: Text)
    var
        Facts: TestPage "LT Y90 Ref Card";
        Line: Text;
        Keys: List of [Text];
        KeyName: Text;
    begin
        ClearLastError();
        if not TryOpen(Facts) then begin
            Observer.Observe(Tag, 'open error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Keys.AddRange('PlainAct,GuardAct,GuardActRimd,CuAct,InGrpAct,CreateAct,NavAct,RepAct'.Split(','));
        foreach KeyName in Keys do
            Line += KeyName + '=' + Vis(Facts, KeyName) + ' ';
        Facts.Close();
        Observer.Observe(Tag, Line.TrimEnd());
    end;

    local procedure Vis(var Facts: TestPage "LT Y90 Ref Card"; KeyName: Text): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if TryVis(Facts, KeyName, Result) then begin
            if Result then
                exit('Y');
            exit('F');
        end;
        ClearLastError();
        exit('N');
    end;

    [TryFunction]
    local procedure TryOpen(var Facts: TestPage "LT Y90 Ref Card")
    begin
        Facts.OpenView();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y90 Ref Card"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'PlainAct':
                Result := Facts.PlainAct.Visible();
            'GuardAct':
                Result := Facts.GuardAct.Visible();
            'GuardActRimd':
                Result := Facts.GuardActRimd.Visible();
            'CuAct':
                Result := Facts.CuAct.Visible();
            'InGrpAct':
                Result := Facts.InGrpAct.Visible();
            'CreateAct':
                Result := Facts.CreateAct.Visible();
            'NavAct':
                Result := Facts.NavAct.Visible();
            'RepAct':
                Result := Facts.RepAct.Visible();
        end;
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
