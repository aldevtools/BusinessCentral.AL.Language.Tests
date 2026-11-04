// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y94AbpObjects.al (95100-95139); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21, stage 4 gate (591 lines of the shadow run: a control states a guard over a table field that states one too).
//   CtlOnlyA: guard A on the control, none on its table field. FldOnlyA, FldOnlyB: no guard on the control, guard A / B on the table field.
//   CtlConflict: guard A on the control, guard B on the table field. CtlSame: guard B on both. Sets: none, A read, B read, both.
//   Legend: Y visible, F Visible false, N no such control on the TestPage.
//   Observed text: one letter per control, in this order: Plain, CtlOnlyA, FldOnlyA, FldOnlyB, CtlConflict, CtlSame.
// BC versions: 27, 28, 29

codeunit 95123 "LT Y94 Abp Conflict"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y94_Conflict_GrantsA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveOne('noset');
        ObserveExact('LT Y94 Conf none', 'none');
        ObserveExact('LT Y94 Conf ar', 'ar');
        ObserveExact('LT Y94 Conf br', 'br');
        ObserveExact('LT Y94 Conf abr', 'abr');
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
        Facts: TestPage "LT Y94 Conflict";
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
        Keys.AddRange('Plain,CtlOnlyA,FldOnlyA,FldOnlyB,CtlConflict,CtlSame'.Split(','));
        foreach KeyName in Keys do
            Line += Vis(Facts, KeyName);
        Facts.Close();
        Observer.Observe(Tag, Line);
    end;

    local procedure Vis(var Facts: TestPage "LT Y94 Conflict"; KeyName: Text): Text
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
    local procedure TryOpen(var Facts: TestPage "LT Y94 Conflict")
    begin
        Facts.OpenView();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y94 Conflict"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'Plain':
                Result := Facts.Plain.Visible();
            'CtlOnlyA':
                Result := Facts.CtlOnlyA.Visible();
            'FldOnlyA':
                Result := Facts.FldOnlyA.Visible();
            'FldOnlyB':
                Result := Facts.FldOnlyB.Visible();
            'CtlConflict':
                Result := Facts.CtlConflict.Visible();
            'CtlSame':
                Result := Facts.CtlSame.Visible();
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
