// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y94AbpObjects.al (95100-95139); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21, stage 4 gate: a page that carries AccessByPermission itself (tabledata A = R), together with a guarded field (B) and a
//   promoted guarded action (A). Y84PermAbp.al Y84_Abp_PageAndReportLevel pins the page alone (opens whatever the sets are). Legend: Y visible, F Visible false, N no such control.
//   Observed text: one letter per control, in this order: IdCtl, LvlGuardB, LvlPlainAct, LvlGuardAct.
// BC versions: 27, 28, 29

codeunit 95124 "LT Y94 Abp Page Level"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y94_PageLevel_GrantsA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveOne('noset');
        ObserveExact('LT Y94 Lvl none', 'none');
        ObserveExact('LT Y94 Lvl ar', 'ar');
        ObserveExact('LT Y94 Lvl br', 'br');
        RestoreMock(WasStarted);
        Observer.Expect('noset',
            'YYYY');
        Observer.Expect('none',
            'YNYN');
        Observer.Expect('ar',
            'YNYY');
        Observer.Expect('br',
            'YYYN');
        Observer.Verify();
    end;

    local procedure ObserveExact(SetName: Code[30]; Tag: Text)
    begin
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet(SetName);
        ObserveOne(Tag);
    end;

    local procedure ObserveOne(Tag: Text)
    var
        Facts: TestPage "LT Y94 Page Level";
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
        Keys.AddRange('IdCtl,LvlGuardB,LvlPlainAct,LvlGuardAct'.Split(','));
        foreach KeyName in Keys do
            Line += Vis(Facts, KeyName);
        Facts.Close();
        Observer.Observe(Tag, Line);
    end;

    local procedure Vis(var Facts: TestPage "LT Y94 Page Level"; KeyName: Text): Text
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
    local procedure TryOpen(var Facts: TestPage "LT Y94 Page Level")
    begin
        Facts.OpenView();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y94 Page Level"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'IdCtl':
                Result := Facts.IdCtl.Visible();
            'LvlGuardB':
                Result := Facts.LvlGuardB.Visible();
            'LvlPlainAct':
                Result := Facts.LvlPlainAct.Visible();
            'LvlGuardAct':
                Result := Facts.LvlGuardAct.Visible();
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
