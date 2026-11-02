// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y84PermObjects.al (94380-94421); Y24PermObjects.al (guard targets); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 stage 3, writer Y84, runtime issue "AccessByPermission shapes the runtime refuses": AccessByPermission with every
//   letter (R, I, M, D, IM, RIMD, lower case r and rimd) on page fields, page actions and page parts; with every object kind (codeunit, query,
//   xmlport, report, page, table, system, lower case x); on a table field; on the page object and on the report object; on request page fields;
//   under sets that grant the guard table in each letter (direct and indirect) and under exact sets that grant objects; the other methods of a
//   hidden control; the Page Control Field rows of a page with hidden controls; a FlowField control over a guard table without rows.
//   AccessByPermission on a group does not compile (AL0124, tests/must-not-compile/cases/2785).
// Key legend of the observations: Y = control visible, F = Visible returned false, N = the TestPage has no such control (error).
// BC versions: 27, 28, 29

codeunit 94392 "LT Y84 Perm Abp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Errors: List of [Text];
        RequestSeen: Text;

    [Test]
    procedure Y84_Abp_LettersA()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        ObserveSet('LT Y84 C R', 'tabledata', 'r');
        ObserveSet('LT Y84 C I', 'tabledata', 'i');
        ObserveSet('LT Y84 C M', 'tabledata', 'm');
        ObserveSet('LT Y84 C D', 'tabledata', 'd');
        ObserveSet('LT Y84 C IM', 'tabledata', 'im');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Abp_LettersB()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        ObserveSet('LT Y84 C RIMD', 'tabledata', 'rimd');
        ObserveSet('LT Y84 C Ind R', 'tabledata', 'indr');
        ObserveSet('LT Y84 C Ind I', 'tabledata', 'indi');
        ObserveSet('LT Y84 C Ind RIMD', 'tabledata', 'indrimd');
        ObserveSet('LT Y84 C None', 'tabledata', 'none');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Abp_ObjectKinds()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        ObserveExact('LT Y84 X Some', 'some');
        ObserveExact('LT Y84 X Other', 'other');
        ObserveExact('LT Y84 X Ind', 'ind');
        ObserveExact('LT Y84 X None', 'none');
        Mock.Set('LT Y84 C None');
        ObserveKeys('set none', 'objects');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Abp_HiddenMethods()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Seed(true);
        Mock.Set('LT Y84 C None');
        ObserveMethods('hidden');
        Mock.Set('LT Y84 C RIMD');
        ObserveMethods('visible');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Abp_PageControlFieldRows()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Seed(true);
        Mock.Set('LT Y84 C None');
        ObserveRows('hidden');
        Mock.Set('LT Y84 C RIMD');
        ObserveRows('visible');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Abp_FlowFieldControl()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Seed(false);
        Mock.Set('LT Y84 C None');
        ObserveFlow('empty, no read');
        Mock.Set('LT Y84 C R');
        ObserveFlow('empty, read');
        Mock.ClearAssignments();
        Seed(true);
        Mock.Set('LT Y84 C None');
        ObserveFlow('rows, no read');
        Mock.Set('LT Y84 C R');
        ObserveFlow('rows, read');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Abp_PageAndReportLevel()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Seed(true);
        Mock.Set('LT Y84 C None');
        ObservePageLevel('no read');
        ObserveReportLevel('no read');
        Mock.Set('LT Y84 C R');
        ObservePageLevel('read');
        ObserveReportLevel('read');
        Mock.Set('LT Y84 C I');
        ObservePageLevel('insert');
        ObserveReportLevel('insert');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y84RequestHandler')]
    procedure Y84_Abp_RequestPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Seed(true);
        Commit();
        Mock.Set('LT Y84 C None');
        RunRequest('none');
        Mock.Set('LT Y84 C R');
        RunRequest('r');
        Mock.Set('LT Y84 C I');
        RunRequest('i');
        Mock.Set('LT Y84 C M');
        RunRequest('m');
        Mock.Set('LT Y84 C D');
        RunRequest('d');
        Mock.Set('LT Y84 C Ind R');
        RunRequest('ind r');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    local procedure Seed(WithGuardRow: Boolean)
    var
        Row: Record "LT Y84 Row";
        Guard: Record "LT Y84 Guard";
    begin
        Mock.ClearAssignments();
        Row.DeleteAll();
        Guard.DeleteAll();
        Row.Id := 1;
        Row.Value := 10;
        Row.Name := 'a';
        Row.TfGuard := 7;
        Row.Insert();
        if WithGuardRow then begin
            Guard.Id := 1;
            Guard.Insert();
        end;
    end;

    local procedure ObserveSet(SetName: Code[20]; Kind: Text; Tag: Text)
    begin
        Seed(true);
        Mock.Set(SetName);
        ObserveKeys(Tag, Kind);
    end;

    local procedure ObserveExact(SetName: Code[20]; Tag: Text)
    begin
        Seed(true);
        Mock.SetExactPermissionSet(SetName);
        ObserveKeys(Tag, 'objects');
    end;

    // Tag names the set; Kind picks the controls ('tabledata' guards or 'objects' guards).
    local procedure ObserveKeys(Tag: Text; Kind: Text)
    var
        Facts: TestPage "LT Y84 ABP Card";
        Keys: List of [Text];
        FieldKeys: Text;
        KeyName: Text;
        Line: Text;
    begin
        Clear(Errors);
        if not TryOpen(Facts) then begin
            Observer.Observe(Tag + '|open', 'error: ' + GetLastErrorText());
            Observer.Observe(Tag + '|open code', GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        if Kind = 'tabledata' then
            FieldKeys := 'PL,TF,FLOW,R,I,M,D,IM,RIMD,lR,lRIMD,PP,GP,PA,aR,aI,aM,aD,aRIMD'
        else
            FieldKeys := 'Cu,Qry,Xp,Rep,Pg,Tbl,Sys,lCu,GOP,aCu,aQry,aXp,aRep,aPg,aTbl,aSys';
        Keys.AddRange(FieldKeys.Split(','));
        foreach KeyName in Keys do
            Line += KeyName + '=' + Vis(Facts, KeyName) + ' ';
        Observer.Observe(Tag, Line.TrimEnd());
        ObserveErrors(Tag);
        Facts.Close();
    end;

    local procedure ObserveErrors(Tag: Text)
    var
        Distinct: List of [Text];
        Note: Text;
        Line: Text;
    begin
        foreach Note in Errors do
            if not Distinct.Contains(Note) then begin
                Distinct.Add(Note);
                Line += Note + ' | ';
            end;
        if Line <> '' then
            Observer.Observe(Tag + '|errors', Line);
    end;

    local procedure Vis(var Facts: TestPage "LT Y84 ABP Card"; KeyName: Text): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if TryVis(Facts, KeyName, Result) then begin
            if Result then
                exit('Y');
            exit('F');
        end;
        Errors.Add(GetLastErrorText());
        ClearLastError();
        exit('N');
    end;

    [TryFunction]
    local procedure TryOpen(var Facts: TestPage "LT Y84 ABP Card")
    begin
        Facts.OpenView();
        Facts.First();
    end;

    [TryFunction]
    local procedure TryVis(var Facts: TestPage "LT Y84 ABP Card"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'PL':
                Result := Facts.PlainCtl.Visible();
            'TF':
                Result := Facts.TfCtl.Visible();
            'FLOW':
                Result := Facts.FlowCtl.Visible();
            'R':
                Result := Facts.GR.Visible();
            'I':
                Result := Facts.GI.Visible();
            'M':
                Result := Facts.GM.Visible();
            'D':
                Result := Facts.GD.Visible();
            'IM':
                Result := Facts.GIM.Visible();
            'RIMD':
                Result := Facts.GRIMD.Visible();
            'lR':
                Result := Facts.GLowR.Visible();
            'lRIMD':
                Result := Facts.GLowRIMD.Visible();
            'PP':
                Result := Facts.PlainPart.IdCol.Visible();
            'GP':
                Result := Facts.GuardPart.IdCol.Visible();
            'Cu':
                Result := Facts.ObjCu.Visible();
            'Qry':
                Result := Facts.ObjQry.Visible();
            'Xp':
                Result := Facts.ObjXp.Visible();
            'Rep':
                Result := Facts.ObjRep.Visible();
            'Pg':
                Result := Facts.ObjPg.Visible();
            'Tbl':
                Result := Facts.ObjTbl.Visible();
            'Sys':
                Result := Facts.ObjSys.Visible();
            'lCu':
                Result := Facts.ObjCuLow.Visible();
            'GOP':
                Result := Facts.GuardObjPart.IdCol.Visible();
            'PA':
                Result := Facts.PlainAct.Visible();
            'aR':
                Result := Facts.ActR.Visible();
            'aI':
                Result := Facts.ActI.Visible();
            'aM':
                Result := Facts.ActM.Visible();
            'aD':
                Result := Facts.ActD.Visible();
            'aRIMD':
                Result := Facts.ActRIMD.Visible();
            'aCu':
                Result := Facts.ActCu.Visible();
            'aQry':
                Result := Facts.ActQry.Visible();
            'aXp':
                Result := Facts.ActXp.Visible();
            'aRep':
                Result := Facts.ActRep.Visible();
            'aPg':
                Result := Facts.ActPg.Visible();
            'aTbl':
                Result := Facts.ActTbl.Visible();
            'aSys':
                Result := Facts.ActSys.Visible();
        end;
    end;

    local procedure ObserveMethods(Tag: Text)
    var
        Facts: TestPage "LT Y84 ABP Card";
        Methods: List of [Text];
        Method: Text;
    begin
        if not TryOpen(Facts) then begin
            Observer.Observe(Tag + '|open', 'error: ' + GetLastErrorText());
            ClearLastError();
            exit;
        end;
        Methods.AddRange('GR.Value,GR.Editable,GR.Caption,GR.Enabled,GR.SetValue,GR.Lookup,GR.AssertEquals,GR.Activate,ActR.Enabled,ActR.Invoke,GuardPart.Value'.Split(','));
        foreach Method in Methods do
            Observer.Observe(Tag + '|' + Method, MethodOutcome(Facts, Method));
        Facts.Close();
    end;

    local procedure MethodOutcome(var Facts: TestPage "LT Y84 ABP Card"; Method: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryMethod(Facts, Method, Result) then
            exit(Result);
        Result := 'error: ' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryMethod(var Facts: TestPage "LT Y84 ABP Card"; Method: Text; var Result: Text)
    begin
        case Method of
            'GR.Value':
                Result := Facts.GR.Value();
            'GR.Editable':
                Result := Format(Facts.GR.Editable());
            'GR.Caption':
                Result := Facts.GR.Caption();
            'GR.Enabled':
                Result := Format(Facts.GR.Enabled());
            'GR.SetValue':
                begin
                    Facts.GR.SetValue(5);
                    Result := 'set';
                end;
            'GR.Lookup':
                begin
                    Facts.GR.Lookup();
                    Result := 'looked up';
                end;
            'GR.AssertEquals':
                begin
                    Facts.GR.AssertEquals(10);
                    Result := 'equal';
                end;
            'GR.Activate':
                begin
                    Facts.GR.Activate();
                    Result := 'activated';
                end;
            'ActR.Enabled':
                Result := Format(Facts.ActR.Enabled());
            'ActR.Invoke':
                begin
                    Facts.ActR.Invoke();
                    Result := 'invoked';
                end;
            'GuardPart.Value':
                Result := Facts.GuardPart.IdCol.Value();
        end;
    end;

    // The Page Control Field rows (virtual table) of the page, whatever the page shows.
    local procedure ObserveRows(Tag: Text)
    var
        Names: Text;
        Count: Integer;
    begin
        ClearLastError();
        if not TryRows(Names, Count) then begin
            Observer.Observe(Tag + '|rows', 'error: ' + GetLastErrorText());
            ClearLastError();
            exit;
        end;
        Observer.Observe(Tag + '|count', Format(Count));
        Observer.Observe(Tag + '|names', Listed(Names));
    end;

    // Which of the page's controls have a row, in a fixed order (the rows come back in no stable order).
    local procedure Listed(Names: Text): Text
    var
        All: List of [Text];
        Name: Text;
        Result: Text;
    begin
        All.AddRange('PlainCtl,TfCtl,FlowCtl,GR,GI,GM,GD,GIM,GRIMD,GLowR,GLowRIMD,ObjCu,ObjQry,ObjXp,ObjRep,ObjPg,ObjTbl,ObjSys,ObjCuLow,PlainPart,GuardPart,GuardObjPart,PlainAct,ActR,ActCu'.Split(','));
        foreach Name in All do
            if Names.Contains(',' + Name + ',') then
                Result += Name + '=Y '
            else
                Result += Name + '=N ';
        exit(Result.TrimEnd());
    end;

    [TryFunction]
    local procedure TryRows(var Names: Text; var Count: Integer)
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, Page::"LT Y84 ABP Card");
        if PageControlField.FindSet() then
            repeat
                Count += 1;
                Names += ',' + PageControlField.ControlName;
            until PageControlField.Next() = 0;
        Names += ',';
    end;

    local procedure ObserveFlow(Tag: Text)
    var
        Facts: TestPage "LT Y84 ABP Card";
        Value: Text;
        VisibleText: Text;
    begin
        ClearLastError();
        if not TryOpen(Facts) then begin
            Observer.Observe(Tag + '|open', 'error: ' + GetLastErrorText());
            ClearLastError();
            exit;
        end;
        VisibleText := Vis(Facts, 'FLOW');
        if TryFlowValue(Facts, Value) then
            Observer.Observe(Tag, 'visible ' + VisibleText + ' value ' + Value)
        else begin
            Observer.Observe(Tag, 'visible ' + VisibleText + ' value error: ' + GetLastErrorText());
            ClearLastError();
        end;
        Facts.Close();
    end;

    [TryFunction]
    local procedure TryFlowValue(var Facts: TestPage "LT Y84 ABP Card"; var Value: Text)
    begin
        Value := Facts.FlowCtl.Value();
    end;

    local procedure ObservePageLevel(Tag: Text)
    var
        Facts: TestPage "LT Y84 ABP Page Level";
    begin
        ClearLastError();
        if TryOpenLevel(Facts) then
            Observer.Observe('page level ' + Tag, 'opened')
        else begin
            Observer.Observe('page level ' + Tag, 'error: ' + GetLastErrorText());
            Observer.Observe('page level ' + Tag + ' code', GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [TryFunction]
    local procedure TryOpenLevel(var Facts: TestPage "LT Y84 ABP Page Level")
    begin
        Facts.OpenView();
        Facts.Close();
    end;

    local procedure ObserveReportLevel(Tag: Text)
    begin
        ClearLastError();
        if TryRunLevel() then
            Observer.Observe('report level ' + Tag, 'ran')
        else begin
            Observer.Observe('report level ' + Tag, 'error: ' + GetLastErrorText());
            Observer.Observe('report level ' + Tag + ' code', GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [TryFunction]
    local procedure TryRunLevel()
    var
        Rep: Report "LT Y84 ABP Rep Level";
    begin
        Rep.UseRequestPage(false);
        Rep.RunModal();
    end;

    local procedure RunRequest(Tag: Text)
    var
        Rep: Report "LT Y84 ABP Rep";
    begin
        RequestSeen := '';
        ClearLastError();
        Rep.UseRequestPage(true);
        if TryRunRequest(Rep) then
            Observer.Observe('request ' + Tag + '|run', 'ran')
        else begin
            Observer.Observe('request ' + Tag + '|run', 'error: ' + GetLastErrorText());
            ClearLastError();
        end;
        Observer.Observe('request ' + Tag, RequestSeen);
    end;

    [TryFunction]
    local procedure TryRunRequest(var Rep: Report "LT Y84 ABP Rep")
    begin
        Rep.RunModal();
    end;

    [RequestPageHandler]
    procedure Y84RequestHandler(var RequestPage: TestRequestPage "LT Y84 ABP Rep")
    begin
        RequestSeen := 'plain ' + ReqVis(RequestPage, 'plain') + ' R ' + ReqVis(RequestPage, 'R') + ' I ' + ReqVis(RequestPage, 'I') + ' M ' + ReqVis(RequestPage, 'M') +
            ' D ' + ReqVis(RequestPage, 'D') + ' RIMD ' + ReqVis(RequestPage, 'RIMD') + ' Cu ' + ReqVis(RequestPage, 'Cu');
        RequestPage.OK().Invoke();
    end;

    local procedure ReqVis(var RequestPage: TestRequestPage "LT Y84 ABP Rep"; KeyName: Text): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if TryReqVis(RequestPage, KeyName, Result) then begin
            if Result then
                exit('Y');
            exit('F');
        end;
        ClearLastError();
        exit('N');
    end;

    [TryFunction]
    local procedure TryReqVis(var RequestPage: TestRequestPage "LT Y84 ABP Rep"; KeyName: Text; var Result: Boolean)
    begin
        case KeyName of
            'plain':
                Result := RequestPage.PlainOpt.Visible();
            'R':
                Result := RequestPage.ROpt.Visible();
            'I':
                Result := RequestPage.IOpt.Visible();
            'M':
                Result := RequestPage.MOpt.Visible();
            'D':
                Result := RequestPage.DOpt.Visible();
            'RIMD':
                Result := RequestPage.RIMDOpt.Visible();
            'Cu':
                Result := RequestPage.CuOpt.Visible();
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
