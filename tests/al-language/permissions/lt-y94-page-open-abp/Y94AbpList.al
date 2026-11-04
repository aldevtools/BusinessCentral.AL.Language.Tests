// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y94AbpObjects.al (95100-95139); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21, stage 4 gate: a list page. Guarded fields in a repeater and in a group, guarded actions promoted by actionref
//   directly under Promoted and in a group, and in a group of the Processing area. Legend: Y visible, F Visible false, N no such control on the TestPage.
//   Observed text: one letter per control, in this order: RPlain, RGuardA, RGuardB, GPlain, GGuardA, LPlainAct, LGuardAAct, LGuardBAct, LInnerAct.
// BC versions: 27, 28, 29

codeunit 95121 "LT Y94 Abp List"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y94_List_GrantsA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveOne('noset');
        ObserveExact('LT Y94 List none', 'none');
        ObserveExact('LT Y94 List ar', 'ar');
        ObserveExact('LT Y94 List br', 'br');
        ObserveExact('LT Y94 List abr', 'abr');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    local procedure ObserveExact(SetName: Code[30]; Tag: Text)
    begin
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet(SetName);
        ObserveOne(Tag);
    end;

    local procedure ObserveOne(Tag: Text)
    var
        Facts: TestPage "LT Y94 List";
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
        Keys.AddRange('RPlain,RGuardA,RGuardB,GPlain,GGuardA,LPlainAct,LGuardAAct,LGuardBAct,LInnerAct'.Split(','));
        foreach KeyName in Keys do
            Line += Vis(Facts, KeyName);
        Facts.Close();
        Observer.Observe(Tag, Line);
    end;

    local procedure Vis(var Facts: TestPage "LT Y94 List"; KeyName: Text): Text
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
    local procedure TryOpen(var Facts: TestPage "LT Y94 List")
    begin
        Facts.OpenView();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y94 List"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'RPlain':
                Result := Facts.RPlain.Visible();
            'RGuardA':
                Result := Facts.RGuardA.Visible();
            'RGuardB':
                Result := Facts.RGuardB.Visible();
            'GPlain':
                Result := Facts.GPlain.Visible();
            'GGuardA':
                Result := Facts.GGuardA.Visible();
            'LPlainAct':
                Result := Facts.LPlainAct.Visible();
            'LGuardAAct':
                Result := Facts.LGuardAAct.Visible();
            'LGuardBAct':
                Result := Facts.LGuardBAct.Visible();
            'LInnerAct':
                Result := Facts.LInnerAct.Visible();
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
