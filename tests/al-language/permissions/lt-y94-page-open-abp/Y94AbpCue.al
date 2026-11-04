// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y94AbpObjects.al (95100-95139); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21, stage 4 gate: a cue part (CardPart) opened directly. Cue fields and an action of the cuegroup carry the property.
//   Legend: Y visible, F Visible false, N no such control on the TestPage.
//   Observed text: one letter per control, in this order: CuePlain, CueGuardA, CueGuardB, CueAct, CuePlainAct.
// BC versions: 27, 28, 29

codeunit 95122 "LT Y94 Abp Cue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y94_Cue_GrantsA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveOne('noset');
        ObserveExact('LT Y94 Cue none', 'none');
        ObserveExact('LT Y94 Cue ar', 'ar');
        ObserveExact('LT Y94 Cue br', 'br');
        ObserveExact('LT Y94 Cue abr', 'abr');
        RestoreMock(WasStarted);
        Observer.Expect('noset',
            'YYYYY');
        Observer.Expect('none',
            'YNNNY');
        Observer.Expect('ar',
            'YYNYY');
        Observer.Expect('br',
            'YNYNY');
        Observer.Expect('abr',
            'YYYYY');
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
        Facts: TestPage "LT Y94 Cue Part";
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
        Keys.AddRange('CuePlain,CueGuardA,CueGuardB,CueAct,CuePlainAct'.Split(','));
        foreach KeyName in Keys do
            Line += Vis(Facts, KeyName);
        Facts.Close();
        Observer.Observe(Tag, Line);
    end;

    local procedure Vis(var Facts: TestPage "LT Y94 Cue Part"; KeyName: Text): Text
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
    local procedure TryOpen(var Facts: TestPage "LT Y94 Cue Part")
    begin
        Facts.OpenView();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y94 Cue Part"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'CuePlain':
                Result := Facts.CuePlain.Visible();
            'CueGuardA':
                Result := Facts.CueGuardA.Visible();
            'CueGuardB':
                Result := Facts.CueGuardB.Visible();
            'CueAct':
                Result := Facts.CueAct.Visible();
            'CuePlainAct':
                Result := Facts.CuePlainAct.Visible();
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
