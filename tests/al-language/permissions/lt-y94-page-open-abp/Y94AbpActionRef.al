// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y94AbpObjects.al (95100-95139); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P21, stage 4 gate (1339 lines of the shadow run over Microsoft's tests: a page with AccessByPermission on an action that the
//   page lists with actionref). Y90PermActionRef.al pins the R, RIMD, indirect r and codeunit guards. This file adds the other guard kinds (tabledata I,
//   page, report, query, xmlport, table object, a second table), an action added by a page extension together with its actionref, a field, and the
//   TestPage methods of a hidden promoted action (Enabled, Invoke). Exact sets: the page and its source table plus one grant (set names LT Y94 Ref <grant>).
//   Legend: Y = control visible, F = Visible returned false, N = the TestPage has no such control.
//   Observed text: one letter per control, in this order: PlainAct, TblRAct, TblIAct, TblRimdAct, PgAct, RepAct, QryAct, XmlAct, TblObjAct, CuAct, BAct, NoRefAct, ExtAct, ExtPlainAct, FldA, FldExt.
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
        ObserveExact('LT Y94 Ref abr', 'abr');
        ObserveExact('LT Y94 Ref cu', 'cu');
        ObserveExact('LT Y94 Ref pg', 'pg');
        ObserveExact('LT Y94 Ref rep', 'rep');
        ObserveExact('LT Y94 Ref qry', 'qry');
        ObserveExact('LT Y94 Ref xml', 'xml');
        ObserveExact('LT Y94 Ref tbl', 'tbl');
        RestoreMock(WasStarted);
        Observer.Expect('noset',
            'YYYYYYYYYYYYYYYY');
        Observer.Expect('none',
            'YNNNNNNNNNNNNYNN');
        Observer.Expect('ar',
            'YYNYNNNNNNNYYYYY');
        Observer.Expect('ai',
            'YNYYNNNNNNNNNYNN');
        Observer.Expect('arimd',
            'YYYYNNNNNNNYYYYY');
        Observer.Expect('indr',
            'YNNNNNNNNNNNNYNN');
        Observer.Expect('br',
            'YNNNNNNNNNYNNYNN');
        Observer.Expect('abr',
            'YYNYNNNNNNYYYYYY');
        Observer.Expect('cu',
            'YNNNNNNNNYNNNYNN');
        Observer.Expect('pg',
            'YNNNYNNNNNNNNYNN');
        Observer.Expect('rep',
            'YNNNNYNNNNNNNYNN');
        Observer.Expect('qry',
            'YNNNNNYNNNNNNYNN');
        Observer.Expect('xml',
            'YNNNNNNYNNNNNYNN');
        Observer.Expect('tbl',
            'YNNNNNNNYNNNNYNN');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_GrantsB()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        ObserveExact('LT Y94 Ref wtdr', 'wtdr');
        ObserveExact('LT Y94 Ref wtdi', 'wtdi');
        ObserveExact('LT Y94 Ref wcu', 'wcu');
        ObserveExact('LT Y94 Ref wpg', 'wpg');
        ObserveExact('LT Y94 Ref wrep', 'wrep');
        ObserveExact('LT Y94 Ref wqry', 'wqry');
        ObserveExact('LT Y94 Ref wxml', 'wxml');
        ObserveExact('LT Y94 Ref wtbl', 'wtbl');
        ObserveExact('LT Y94 Ref wsys', 'wsys');
        Mock.ClearAssignments();
        Mock.Set('D365 BASIC');
        ObserveOne('set d365 basic');
        ObserveExact('D365 BASIC', 'exact d365 basic');
        ObserveExact('D365 FULL ACCESS', 'exact d365 full access');
        RestoreMock(WasStarted);
        Observer.Expect('wtdr',
            'YYNYNNNNNNYYYYYY');
        Observer.Expect('wtdi',
            'YNYYNNNNNNNNNYNN');
        Observer.Expect('wcu',
            'YNNNNNNNNYNNNYNN');
        Observer.Expect('wpg',
            'YNNNYNNNNNNNNYNN');
        Observer.Expect('wrep',
            'YNNNNYNNNNNNNYNN');
        Observer.Expect('wqry',
            'YNNNNNYNNNNNNYNN');
        Observer.Expect('wxml',
            'YNNNNNNYNNNNNYNN');
        Observer.Expect('wtbl',
            'YNNNNNNNYNNNNYNN');
        Observer.Expect('wsys',
            'YNNNNNNNNNNNNYNN');
        Observer.Expect('set d365 basic',
            'YNNNYYYYYYNNNYNN');
        Observer.Expect('exact d365 basic',
            'YNNNYYYYYYNNNYNN');
        Observer.Expect('exact d365 full access',
            'YNNNYYYYYYNNNYNN');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_Methods_none_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref none');
        ObserveMethods('TblRAct.Enabled,TblRAct.Invoke,CuAct.Invoke');
        RestoreMock(WasStarted);
        Observer.Expect('TblRAct.Enabled',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('TblRAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('CuAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_Methods_none_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref none');
        ObserveMethods('ExtAct.Invoke,NoRefAct.Invoke,FldA.Value');
        RestoreMock(WasStarted);
        Observer.Expect('ExtAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('NoRefAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('FldA.Value',
            'The field with ID = n is not found on the page. | TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_Methods_ar_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref ar');
        ObserveMethods('TblRAct.Enabled,TblRAct.Invoke,CuAct.Invoke');
        RestoreMock(WasStarted);
        Observer.Expect('TblRAct.Enabled',
            'Yes');
        Observer.Expect('TblRAct.Invoke',
            'ok');
        Observer.Expect('CuAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_Methods_ar_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref ar');
        ObserveMethods('ExtAct.Invoke,NoRefAct.Invoke,FldA.Value');
        RestoreMock(WasStarted);
        Observer.Expect('ExtAct.Invoke',
            'ok');
        Observer.Expect('NoRefAct.Invoke',
            'ok');
        Observer.Expect('FldA.Value',
            '');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_Methods_cu_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref cu');
        ObserveMethods('TblRAct.Enabled,TblRAct.Invoke,CuAct.Invoke');
        RestoreMock(WasStarted);
        Observer.Expect('TblRAct.Enabled',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('TblRAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('CuAct.Invoke',
            'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_Methods_cu_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref cu');
        ObserveMethods('ExtAct.Invoke,NoRefAct.Invoke,FldA.Value');
        RestoreMock(WasStarted);
        Observer.Expect('ExtAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('NoRefAct.Invoke',
            'The action with ID = n is not found on the page. | TestActionNotFound');
        Observer.Expect('FldA.Value',
            'The field with ID = n is not found on the page. | TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y94_Ref_OpenModes()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref none');
        ObserveMode('edit', 'none edit');
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref none');
        ObserveMode('new', 'none new');
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref ar');
        ObserveMode('edit', 'ar edit');
        Mock.ClearAssignments();
        Mock.SetExactPermissionSet('LT Y94 Ref ar');
        ObserveMode('new', 'ar new');
        RestoreMock(WasStarted);
        Observer.Expect('none edit',
            'YNNNNNNNNNNNNYNN');
        Observer.Expect('none new',
            'YNNNNNNNNNNNNYNN');
        Observer.Expect('ar edit',
            'YYNYNNNNNNNYYYYY');
        Observer.Expect('ar new',
            'YYNYNNNNNNNYYYYY');
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
            Line += Vis(Facts, KeyName);
        Facts.Close();
        Observer.Observe(Tag, Line);
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

    local procedure ObserveMethods(Methods: Text)
    var
        Facts: TestPage "LT Y94 Ref Card";
        Method: Text;
        Outcome: Text;
    begin
        Facts.OpenView();
        foreach Method in Methods.Split(',') do begin
            ClearLastError();
            Outcome := '';
            if TryMethod(Facts, Method, Outcome) then
                Observer.Observe(Method, Outcome)
            else begin
                Observer.Observe(Method, GetLastErrorText() + ' | ' + GetLastErrorCode());
                ClearLastError();
            end;
        end;
        Facts.Close();
    end;

    local procedure ObserveMode(Mode: Text; Tag: Text)
    var
        Facts: TestPage "LT Y94 Ref Card";
        Line: Text;
        Keys: List of [Text];
        KeyName: Text;
    begin
        ClearLastError();
        if not TryOpenMode(Facts, Mode) then begin
            Observer.Observe(Tag, 'open error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Keys.AddRange('PlainAct,TblRAct,TblIAct,TblRimdAct,PgAct,RepAct,QryAct,XmlAct,TblObjAct,CuAct,BAct,NoRefAct,ExtAct,ExtPlainAct,FldA,FldExt'.Split(','));
        foreach KeyName in Keys do
            Line += Vis(Facts, KeyName);
        Facts.Close();
        Observer.Observe(Tag, Line);
    end;

    [TryFunction]
    local procedure TryOpenMode(var Facts: TestPage "LT Y94 Ref Card"; Mode: Text)
    begin
        if Mode = 'edit' then
            Facts.OpenEdit()
        else
            Facts.OpenNew();
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
