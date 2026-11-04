// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y94AbpObjects.al (95100-95139); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21, stage 4 gate (1339 lines of the shadow run over Microsoft's tests: a page with AccessByPermission on an action that the
//   page lists with actionref). Y90PermActionRef.al pins the R, RIMD, indirect r and codeunit guards. This file adds the other guard kinds (tabledata I,
//   page, report, query, xmlport, table object, a second table), an action added by a page extension together with its actionref, a field, and the
//   TestPage methods of a hidden promoted action (Enabled, Invoke). Exact sets: the page and its source table plus one grant (set names LT Y94 Ref <grant>).
//   Legend: Y = control visible, F = Visible returned false, N = the TestPage has no such control.
// BC versions: 27, 28, 29

codeunit 95120 "LT Y94 Abp Action Ref"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y94_Ref_GrantsA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveOne('noset');
        ObserveExact('LT Y94 Ref none', 'none');
        ObserveExact('LT Y94 Ref ar', 'ar');
        ObserveExact('LT Y94 Ref ai', 'ai');
        ObserveExact('LT Y94 Ref arimd', 'arimd');
        ObserveExact('LT Y94 Ref indr', 'indr');
        ObserveExact('LT Y94 Ref br', 'br');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y94_Ref_GrantsB()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        ObserveExact('LT Y94 Ref abr', 'abr');
        ObserveExact('LT Y94 Ref cu', 'cu');
        ObserveExact('LT Y94 Ref pg', 'pg');
        ObserveExact('LT Y94 Ref rep', 'rep');
        ObserveExact('LT Y94 Ref qry', 'qry');
        ObserveExact('LT Y94 Ref xml', 'xml');
        ObserveExact('LT Y94 Ref tbl', 'tbl');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y94_Ref_Methods()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref none');
        ObserveMethods('none');
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref ar');
        ObserveMethods('ar');
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref cu');
        ObserveMethods('cu');
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
        Facts: TestPage "LT Y94 Ref Card";
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
        Keys.AddRange('PlainAct,TblRAct,TblIAct,TblRimdAct,PgAct,RepAct,QryAct,XmlAct,TblObjAct,CuAct,BAct,NoRefAct,ExtAct,ExtPlainAct,FldA,FldExt'.Split(','));
        foreach KeyName in Keys do
            Line += KeyName + '=' + Vis(Facts, KeyName) + ' ';
        Facts.Close();
        Observer.Observe(Tag, Line.TrimEnd());
    end;

    local procedure Vis(var Facts: TestPage "LT Y94 Ref Card"; KeyName: Text): Text
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
    local procedure TryOpen(var Facts: TestPage "LT Y94 Ref Card")
    begin
        Facts.OpenView();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y94 Ref Card"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'PlainAct':
                Result := Facts.PlainAct.Visible();
            'TblRAct':
                Result := Facts.TblRAct.Visible();
            'TblIAct':
                Result := Facts.TblIAct.Visible();
            'TblRimdAct':
                Result := Facts.TblRimdAct.Visible();
            'PgAct':
                Result := Facts.PgAct.Visible();
            'RepAct':
                Result := Facts.RepAct.Visible();
            'QryAct':
                Result := Facts.QryAct.Visible();
            'XmlAct':
                Result := Facts.XmlAct.Visible();
            'TblObjAct':
                Result := Facts.TblObjAct.Visible();
            'CuAct':
                Result := Facts.CuAct.Visible();
            'BAct':
                Result := Facts.BAct.Visible();
            'NoRefAct':
                Result := Facts.NoRefAct.Visible();
            'ExtAct':
                Result := Facts.ExtAct.Visible();
            'ExtPlainAct':
                Result := Facts.ExtPlainAct.Visible();
            'FldA':
                Result := Facts.FldA.Visible();
            'FldExt':
                Result := Facts.FldExt.Visible();
        end;
    end;

    local procedure ObserveMethods(Tag: Text)
    var
        Facts: TestPage "LT Y94 Ref Card";
        Method: Text;
        Outcome: Text;
    begin
        Facts.OpenView();
        foreach Method in 'TblRAct.Enabled,TblRAct.Invoke,CuAct.Invoke,ExtAct.Invoke,NoRefAct.Invoke,FldA.Value'.Split(',') do begin
            ClearLastError();
            Outcome := '';
            if TryMethod(Facts, Method, Outcome) then
                Observer.Observe(Tag + '|' + Method, Outcome)
            else begin
                Observer.Observe(Tag + '|' + Method, GetLastErrorText() + ' | ' + GetLastErrorCode());
                ClearLastError();
            end;
        end;
        Facts.Close();
    end;

    [TryFunction]
    local procedure TryMethod(var Facts: TestPage "LT Y94 Ref Card"; Method: Text; var Outcome: Text)
    begin
        case Method of
            'TblRAct.Enabled':
                Outcome := Format(Facts.TblRAct.Enabled());
            'TblRAct.Invoke':
                begin
                    Facts.TblRAct.Invoke();
                    Outcome := 'ok';
                end;
            'CuAct.Invoke':
                begin
                    Facts.CuAct.Invoke();
                    Outcome := 'ok';
                end;
            'ExtAct.Invoke':
                begin
                    Facts.ExtAct.Invoke();
                    Outcome := 'ok';
                end;
            'NoRefAct.Invoke':
                begin
                    Facts.NoRefAct.Invoke();
                    Outcome := 'ok';
                end;
            'FldA.Value':
                Outcome := Format(Facts.FldA.Value());
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
