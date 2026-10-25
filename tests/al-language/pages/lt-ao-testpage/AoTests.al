// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (69160); AoFixtures.al (79500-79518); LT AO Dep Card (61051) in the internals fixture app
// Probe: corpus issue 641 (TestPage behavior the runtime decides without a pin, part 2), writer AO. Every literal is what the corpus CI tier produced.
// Writer SF (al-runtime-rs assumptions subpagelink-empty-term-selects-blank, testfilter-setfilter-empty-clears): SF_ tests, pages 89066-89067 in AoFixtures.al.
// BC versions: 27, 28, 29

codeunit 79590 "LT AO TestPage Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ReqMode: Text;

    local procedure Clean()
    var
        Row: Record "LT AO Row";
        Hdr: Record "LT AO Hdr";
        Line: Record "LT AO Line";
        Dep: Record "LT AO Dep Row";
        Log: Codeunit "LT AO Log";
    begin
        Row.DeleteAll();
        Hdr.DeleteAll();
        Line.DeleteAll();
        Dep.DeleteAll();
        Log.Take();
    end;

    local procedure AddRow(Id: Integer; F: Code[10]; Op: Text[30])
    var
        Row: Record "LT AO Row";
    begin
        Row.Id := Id;
        Row.F := F;
        Row.Name := 'r' + Format(Id);
        Row.Op := Op;
        Row.Insert();
    end;

    local procedure ListIds(var TP: TestPage "LT AO Row List"): Text
    var
        S: Text;
    begin
        if not TP.First() then
            exit('<none>');
        repeat
            S += TP.Id.Value() + ',';
        until not TP.Next();
        exit(S);
    end;

    // ---- item 1: page background task worker does Commit, Codeunit.Run unguarded or Modify ----

    local procedure BgRun(var Observer: Codeunit "Probe Observer"; Op: Text[30])
    var
        Row: Record "LT AO Row";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Bg Card";
    begin
        Clean();
        AddRow(1, '', Op);
        AddRow(2, '', '');
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Observe('rows', Format(Row.Count()));
        Row.Get(1);
        Observer.Observe('r1', Row.Name);
        Row.Get(2);
        Observer.Observe('r2', Row.Name);
        Observer.Observe('wtx', Format(Database.IsInWriteTransaction()));
    end;

    [Test]
    procedure Bg_Commit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'commit');
        Observer.Expect('log', 'done commit ok;');
        Observer.Expect('rows', '2');
        Observer.Expect('r1', 'r1');
        Observer.Expect('r2', 'r2');
        Observer.Expect('wtx', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Bg_RunOkUnguarded()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'runok');
        Observer.Expect('log', 'done runok ok;');
        Observer.Expect('rows', '2');
        Observer.Expect('r1', 'r1');
        Observer.Expect('r2', 'r2');
        Observer.Expect('wtx', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Bg_RunFailUnguarded()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'runfail');
        Observer.Expect('log', 'error code=Dialog text=LT AO inner failure;');
        Observer.Expect('rows', '2');
        Observer.Expect('r1', 'r1');
        Observer.Expect('r2', 'r2');
        Observer.Expect('wtx', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Bg_ModifyShownRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'modify');
        Observer.Expect('log', 'error code=DB:ReadOnlySession text=Sorry, the current permissions prevented the action. (TableData 79502 LT AO Row Modify: AL Language Coverage Tests);');
        Observer.Expect('rows', '2');
        Observer.Expect('r1', 'r1');
        Observer.Expect('r2', 'r2');
        Observer.Expect('wtx', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Bg_ModifyOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BgRun(Observer, 'modifypend');
        Observer.Expect('log', 'error code=DB:ReadOnlySession text=Sorry, the current permissions prevented the action. (TableData 79502 LT AO Row Modify: AL Language Coverage Tests);');
        Observer.Expect('rows', '2');
        Observer.Expect('r1', 'r1');
        Observer.Expect('r2', 'r2');
        Observer.Expect('wtx', 'Yes');
        Observer.Verify();
    end;

    // ---- item 2: SetValue on an invisible control ----

    [Test]
    procedure Invisible_DependencyAppPage()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AO Dep Card";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('ok', Format(TrySetHiddenDep(TP)));
        Observer.ObserveError('set');
        TP.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('set|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('set|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Invisible_SameAppPage()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AO Vis Card";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('ok', Format(TrySetHiddenSame(TP)));
        Observer.ObserveError('set');
        TP.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('set|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('set|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetHiddenDep(var TP: TestPage "LT AO Dep Card")
    begin
        TP.Hidden.SetValue('x');
    end;

    [TryFunction]
    local procedure TrySetHiddenSame(var TP: TestPage "LT AO Vis Card")
    begin
        TP.Hidden.SetValue('x');
    end;

    [TryFunction]
    local procedure TryCallIt(var TP: TestPage "LT AO Addin Card")
    begin
        TP.CallIt.Invoke();
    end;

    // ---- item 3: a local variable named like the record field, passed bare to Record.TestField ----

    [TryFunction]
    local procedure TryTestFieldName(var Row: Record "LT AO Row")
    var
        Name: Text;
    begin
        Name := 'local';
        Row.TestField(Name);
    end;

    [Test]
    procedure TestField_LocalVariableNamedLikeField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
    begin
        Row.Id := 3;
        Row.Name := '';
        Observer.Observe('blank', Format(TryTestFieldName(Row)));
        Observer.ObserveError('blank');
        Row.Name := 'x';
        Observer.Observe('set', Format(TryTestFieldName(Row)));
        Observer.Expect('blank', 'No');
        Observer.Expect('blank|text', 'Name must have a value in LT AO Row: Id=3. It cannot be zero or empty.');
        Observer.Expect('blank|code', 'TestField');
        Observer.Expect('set', 'Yes');
        Observer.Verify();
    end;

    // ---- item 4: header SetValue, part line modifies the header, then a card action ----

    [TryFunction]
    local procedure TryActLog(var Card: TestPage "LT AO Hdr Card")
    begin
        Card.ActLog.Invoke();
    end;

    [TryFunction]
    local procedure TryActModify(var Card: TestPage "LT AO Hdr Card")
    begin
        Card.ActModify.Invoke();
    end;

    local procedure HeaderChanged(var Observer: Codeunit "Probe Observer"; Modify: Boolean)
    var
        Hdr: Record "LT AO Hdr";
        Log: Codeunit "LT AO Log";
        Card: TestPage "LT AO Hdr Card";
        Ok: Boolean;
    begin
        Clean();
        Hdr."No." := 'H4';
        Hdr.Name := 'a';
        Hdr.Insert();
        Card.OpenEdit();
        Card.Name.SetValue('b');
        Card.Lines.New();
        Card.Lines.Descr.SetValue('l1');
        Hdr.Get('H4');
        Observer.Observe('db1', Hdr.Name + '/' + Format(Hdr.Total));
        if Modify then
            Ok := TryActModify(Card)
        else
            Ok := TryActLog(Card);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('act');
        Observer.Observe('log', Log.Take());
        Hdr.Get('H4');
        Observer.Observe('db2', Hdr.Name + '/' + Format(Hdr.Total));
    end;

    [Test]
    procedure HeaderChangedByLine_ActionLogs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeaderChanged(Observer, false);
        Observer.Expect('db1', 'b/0');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'act name=b total=1;');
        Observer.Expect('db2', 'b/1');
        Observer.Verify();
    end;

    [Test]
    procedure HeaderChangedByLine_ActionModifies()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeaderChanged(Observer, true);
        Observer.Expect('db1', 'b/0');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'act modified total=1;');
        Observer.Expect('db2', 'act/1');
        Observer.Verify();
    end;

    // ---- item 7: SetValue of numbers on Text[30] / Code[30] controls ----

    [Test]
    procedure NumberIntoTextField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.Txt.SetValue(14);
        Observer.Observe('i', TP.Txt.Value());
        TP.Txt.SetValue(14.0);
        Observer.Observe('d', TP.Txt.Value());
        TP.Txt.SetValue(1234);
        Observer.Observe('k', TP.Txt.Value());
        TP.Txt.SetValue(-3);
        Observer.Observe('n', TP.Txt.Value());
        TP.Close();
        Row.Get(1);
        Observer.Observe('db', Row.Txt);
        Observer.Expect('i', '14');
        Observer.Expect('d', '14');
        Observer.Expect('k', '1234');
        Observer.Expect('n', '-3');
        Observer.Expect('db', '-3');
        Observer.Verify();
    end;

    [Test]
    procedure NumberIntoCodeField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.Cd.SetValue(14);
        Observer.Observe('i', TP.Cd.Value());
        TP.Cd.SetValue(14.0);
        Observer.Observe('d', TP.Cd.Value());
        TP.Cd.SetValue(1234);
        Observer.Observe('k', TP.Cd.Value());
        TP.Cd.SetValue(-3);
        Observer.Observe('n', TP.Cd.Value());
        TP.Close();
        Row.Get(1);
        Observer.Observe('db', Row.Cd);
        Observer.Expect('i', '14');
        Observer.Expect('d', '14');
        Observer.Expect('k', '1234');
        Observer.Expect('n', '-3');
        Observer.Expect('db', '-3');
        Observer.Verify();
    end;

    [Test]
    procedure NumberIntoTextVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.VTxt.SetValue(14);
        TP.VTxt.SetValue(14.0);
        TP.VTxt.SetValue(1234);
        TP.VTxt.SetValue(-3);
        Observer.Observe('log', Log.Take());
        Observer.Observe('v', TP.VTxt.Value());
        TP.Close();
        Observer.Expect('log', '[14];[14];[1234];[-3];');
        Observer.Expect('v', '-3');
        Observer.Verify();
    end;

    [Test]
    procedure NumberIntoCodeVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Text Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        TP.VCd.SetValue(14);
        TP.VCd.SetValue(14.0);
        TP.VCd.SetValue(1234);
        TP.VCd.SetValue(-3);
        Observer.Observe('log', Log.Take());
        Observer.Observe('v', TP.VCd.Value());
        TP.Close();
        Observer.Expect('log', '[14];[14];[1234];[-3];');
        Observer.Expect('v', '-3');
        Observer.Verify();
    end;

    // ---- item 9: Page.Run on a record with SetRange(F, 'A') in filter group 0 or 2, then a new row ----

    [TryFunction]
    local procedure TryNew(var TP: TestPage "LT AO Row List")
    begin
        TP.New();
    end;

    [TryFunction]
    local procedure TrySetId(var TP: TestPage "LT AO Row List")
    begin
        TP.Id.SetValue(9);
    end;

    [TryFunction]
    local procedure TrySetName(var TP: TestPage "LT AO Row List")
    begin
        TP.Name.SetValue('n');
    end;

    [TryFunction]
    local procedure TryClose(var TP: TestPage "LT AO Row List")
    begin
        TP.Close();
    end;

    local procedure FilteredNewRow(var Observer: Codeunit "Probe Observer"; Group: Integer)
    var
        Row: Record "LT AO Row";
        Stored: Record "LT AO Row";
        TP: TestPage "LT AO Row List";
        Ok: Boolean;
    begin
        Clean();
        AddRow(1, 'A', '');
        AddRow(2, 'B', '');
        Row.FilterGroup(Group);
        Row.SetRange(F, 'A');
        Row.FilterGroup(0);
        TP.Trap();
        Page.Run(Page::"LT AO Row List", Row);
        Observer.Observe('flt', '[' + TP.Filter.GetFilter(F) + ']');
        Observer.Observe('first', Format(TP.First()) + TP.Id.Value());
        Ok := TryNew(TP);
        Observer.Observe('new', Format(Ok));
        if not Ok then
            Observer.ObserveError('new');
        Observer.Observe('newF', '[' + TP.F.Value() + ']');
        Ok := TrySetId(TP);
        Observer.Observe('id', Format(Ok));
        if not Ok then
            Observer.ObserveError('id');
        Observer.Observe('idF', '[' + TP.F.Value() + ']');
        Ok := TrySetName(TP);
        Observer.Observe('nm', Format(Ok));
        if not Ok then
            Observer.ObserveError('nm');
        Ok := TryClose(TP);
        Observer.Observe('cl', Format(Ok));
        if not Ok then
            Observer.ObserveError('cl');
        Observer.Observe('stored', Format(Stored.Get(9)));
        Observer.Observe('F', '[' + Stored.F + ']');
    end;

    [Test]
    procedure FilterGroup0_NewRowField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredNewRow(Observer, 0);
        Observer.Expect('flt', '[A]');
        Observer.Expect('first', 'Yes1');
        Observer.Expect('new', 'Yes');
        Observer.Expect('newF', '[]');
        Observer.Expect('id', 'Yes');
        Observer.Expect('idF', '[]');
        Observer.Expect('nm', 'No');
        Observer.Expect('nm|text', 'Validation error for Field: ,  Message = ''The view is filtered, and the entry is outside the filter. Some actions may not work.''');
        Observer.Expect('nm|code', 'TestValidation');
        Observer.Expect('cl', 'Yes');
        Observer.Expect('stored', 'Yes');
        Observer.Expect('F', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup2_NewRowField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredNewRow(Observer, 2);
        Observer.Expect('flt', '[A]');
        Observer.Expect('first', 'Yes1');
        Observer.Expect('new', 'Yes');
        Observer.Expect('newF', '[]');
        Observer.Expect('id', 'Yes');
        Observer.Expect('idF', '[]');
        Observer.Expect('nm', 'No');
        Observer.Expect('nm|text', 'Validation error for Field: ,  Message = ''The view is filtered, and the entry is outside the filter. Some actions may not work.''');
        Observer.Expect('nm|code', 'TestValidation');
        Observer.Expect('cl', 'Yes');
        Observer.Expect('stored', 'Yes');
        Observer.Expect('F', '[]');
        Observer.Verify();
    end;

    // ---- item 11: RunPageLink F = const('') and F = filter('') ----

    local procedure RunLinked(var Observer: Codeunit "Probe Observer"; UseConst: Boolean)
    var
        Card: TestPage "LT AO Text Card";
        TP: TestPage "LT AO Row List";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        Card.OpenView();
        TP.Trap();
        if UseConst then
            Card.RunConst.Invoke()
        else
            Card.RunFilter.Invoke();
        Observer.Observe('rows', ListIds(TP));
        Observer.Observe('flt', '[' + TP.Filter.GetFilter(F) + ']');
        TP.Close();
        Card.Close();
    end;

    [Test]
    procedure RunPageLink_ConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunLinked(Observer, true);
        Observer.Expect('rows', '1,0,');
        Observer.Expect('flt', '['''']');
        Observer.Verify();
    end;

    [Test]
    procedure RunPageLink_FilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunLinked(Observer, false);
        Observer.Expect('rows', '1,0,');
        Observer.Expect('flt', '['''']');
        Observer.Verify();
    end;

    // ---- item 12: OpenNew on pages with OnFindRecord, table empty or not; xRec in OnNewRecord ----

    [Test]
    procedure FindList_OpenNew_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find List";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Expect('log', 'new below=Yes x=0/ rec=0;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_OpenNew_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find List";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, '', '');
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Expect('log', 'new below=Yes x=2/r2 rec=0;');
        Observer.Verify();
    end;

    [Test]
    procedure FindCard_OpenNew_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find Card";
    begin
        Clean();
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Expect('log', 'new below=Yes x=0/ rec=0;');
        Observer.Verify();
    end;

    [Test]
    procedure FindCard_OpenNew_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Find Card";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, '', '');
        TP.OpenNew();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Expect('log', 'new below=Yes x=2/r2 rec=0;');
        Observer.Verify();
    end;

    // ---- item 13: OpenNew on a card with a part linked on the card key ----

    [Test]
    procedure PartDraftLine_LinkFieldAfterKey()
    var
        Observer: Codeunit "Probe Observer";
        Hdr: Record "LT AO Hdr";
        Line: Record "LT AO Line";
        Card: TestPage "LT AO Hdr Card";
    begin
        Clean();
        Card.OpenNew();
        Observer.Observe('d0', '[' + Card.Lines."Doc No.".Value() + ']');
        Card."No.".SetValue('H13');
        Observer.Observe('d1', '[' + Card.Lines."Doc No.".Value() + ']');
        Observer.Observe('h1', Format(Hdr.Get('H13')));
        Card.Name.SetValue('nm');
        Observer.Observe('d2', '[' + Card.Lines."Doc No.".Value() + ']');
        Observer.Observe('h2', Format(Hdr.Get('H13')));
        Observer.Observe('lines', Format(Line.Count()));
        Card.Close();
        Observer.Expect('d0', '[]');
        Observer.Expect('d1', '[]');
        Observer.Expect('h1', 'No');
        Observer.Expect('d2', '[]');
        Observer.Expect('h2', 'No');
        Observer.Expect('lines', '0');
        Observer.Verify();
    end;

    // ---- item 15: TestFilter SetFilter(F, ' ') and SetFilter(F, '') after a filter; the same on a request page ----

    local procedure ListFilterReset(var Observer: Codeunit "Probe Observer"; Reset: Text)
    var
        TP: TestPage "LT AO Row List";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        TP.OpenView();
        TP.Filter.SetFilter(F, 'A');
        Observer.Observe('a', ListIds(TP));
        TP.Filter.SetFilter(F, Reset);
        Observer.Observe('flt', '[' + TP.Filter.GetFilter(F) + ']');
        Observer.Observe('rows', ListIds(TP));
        TP.Close();
    end;

    [Test]
    procedure TestFilter_SetFilterSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilterReset(Observer, ' ');
        Observer.Expect('a', '2,');
        Observer.Expect('flt', '[]');
        Observer.Expect('rows', '1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure TestFilter_SetFilterEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilterReset(Observer, '');
        Observer.Expect('a', '2,');
        Observer.Expect('flt', '[]');
        Observer.Expect('rows', '1,2,3,');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RptHandler(var RP: TestRequestPage "LT AO Rpt")
    var
        Log: Codeunit "LT AO Log";
    begin
        RP.RowDI.SetFilter(F, 'A');
        RP.RowDI.SetFilter(F, ReqMode);
        Log.Add('rp=[' + RP.RowDI.GetFilter(F) + ']');
        RP.OK().Invoke();
    end;

    local procedure ReqFilterReset(var Observer: Codeunit "Probe Observer"; Reset: Text)
    var
        Log: Codeunit "LT AO Log";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        Commit();
        ReqMode := Reset;
        Report.Run(Report::"LT AO Rpt");
        Observer.Observe('log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('RptHandler')]
    procedure RequestPage_SetFilterSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReqFilterReset(Observer, ' ');
        Observer.Expect('log', 'rp=[A];pre filter= count=3;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RptHandler')]
    procedure RequestPage_SetFilterEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReqFilterReset(Observer, '');
        Observer.Expect('log', 'rp=[];pre filter= count=3;');
        Observer.Verify();
    end;

    // ---- item 17: a list action deletes the only row without CurrPage.Update ----

    [Test]
    procedure DeleteOnlyRow_NoUpdate_Trace()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AO Row";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Del List";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        Observer.Observe('open', Log.Take());
        TP.DelOnly.Invoke();
        Observer.Observe('act', Log.Take());
        Observer.Observe('id', '[' + TP.Id.Value() + ']');
        Observer.Observe('read', Log.Take());
        TP.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Expect('open', 'agr 1;agr 1;agcr 1;');
        Observer.Expect('act', 'agr 1;del 1;deleted;agcr 0;agcr 0;agcr 0;');
        Observer.Expect('id', '[0]');
        Observer.Expect('read', '');
        Observer.Expect('close', '');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    // ---- item 18: an action calls a control add-in procedure on a TestPage ----

    [Test]
    procedure AddinProcedureFromAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
        TP: TestPage "LT AO Addin Card";
    begin
        Clean();
        AddRow(1, '', '');
        TP.OpenEdit();
        Observer.Observe('ok', Format(TryCallIt(TP)));
        Observer.ObserveError('call');
        Observer.Observe('log', Log.Take());
        Observer.Expect('ok', 'No');
#if BC28PLUS
        // Windows BC 28.5 (Windows check 2026-10-20) and 27.5/29.0 in a client session (Windows check 3). Before the bc-linux #133 fix the
        // Linux image gave 'A call to Say failed with this message: Object reference not set to an instance of an object.' (TestWrapped:DotNetInvoke).
        Observer.Expect('call|text', 'The control add-in on control Ctl on page LT AO Addin Card has not been instantiated.');
        Observer.Expect('call|code', 'TestWrapped:DotNetControlAddInNotCreated');
#else
        // BC 27.5 depends on the test runner: through the TestRunnerHub (Windows check 2026-10-20) the call fails earlier with
        // 'Microsoft Dynamics 365 Business Central Data Services attempted to issue a client callback to get a DotNet object Page 79511
        // LT AO Addin Card. ...' (TestWrapped:CallbackNotAllowed); a client session gives the 28.5 text.
        Observer.Ignore('call|text');
        Observer.Ignore('call|code');
#endif
        Observer.Expect('log', 'before;');
        Observer.Verify();
    end;

    // ---- writer SF (al-runtime-rs assumption subpagelink-empty-term-selects-blank): parts with SubPageLink F = const('') and
    //      F = filter('') over rows with blank and non-blank F. (The same terms of a RunPageLink: item 11 above.) ----

    local procedure SfPartIds(var Host: TestPage "LT SF AO Link Host"; UseConst: Boolean): Text
    var
        S: Text;
        More: Boolean;
    begin
        if UseConst then
            More := Host.PartConst.First()
        else
            More := Host.PartFilter.First();
        if not More then
            exit('<none>');
        while More do
            if UseConst then begin
                S += Host.PartConst.Id.Value() + ',';
                More := Host.PartConst.Next();
            end else begin
                S += Host.PartFilter.Id.Value() + ',';
                More := Host.PartFilter.Next();
            end;
        exit(S);
    end;

    local procedure SfSeedLink()
    var
        Hdr: Record "LT AO Hdr";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        AddRow(4, '', '');
        Hdr."No." := 'H1';
        Hdr.Insert();
    end;

    [Test]
    procedure SF_SubPageLink_ConstBlank()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT SF AO Link Host";
    begin
        SfSeedLink();
        Host.OpenView();
        Observer.Observe('rows', SfPartIds(Host, true));
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SF_SubPageLink_FilterBlank()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT SF AO Link Host";
    begin
        SfSeedLink();
        Host.OpenView();
        Observer.Observe('rows', SfPartIds(Host, false));
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SF_SubPageLink_ConstBlank_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT SF AO Link Host";
    begin
        SfSeedLink();
        Host.OpenEdit();
        Observer.Observe('rows', SfPartIds(Host, true));
        Observer.Observe('rows_filter', SfPartIds(Host, false));
        Host.Close();
        Observer.Finish();
    end;

    // ---- writer SF (assumption testfilter-setfilter-empty-clears, request page): the filter 'A' alone, to compare with item 15 ----

    [RequestPageHandler]
    procedure SfRptHandlerOnlyA(var RP: TestRequestPage "LT AO Rpt")
    var
        Log: Codeunit "LT AO Log";
    begin
        RP.RowDI.SetFilter(F, 'A');
        Log.Add('rp=[' + RP.RowDI.GetFilter(F) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SfRptHandlerOnlyA')]
    procedure SF_RequestPage_SetFilterOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AO Log";
    begin
        Clean();
        AddRow(1, '', '');
        AddRow(2, 'A', '');
        AddRow(3, 'B', '');
        Commit();
        Report.Run(Report::"LT AO Rpt");
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // The space form of item 15 with a second space: '  '.
    [Test]
    [HandlerFunctions('RptHandler')]
    procedure SF_RequestPage_SetFilterTwoSpaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReqFilterReset(Observer, '  ');
        Observer.Finish();
    end;

    [Test]
    procedure SF_TestFilter_SetFilterTwoSpaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilterReset(Observer, '  ');
        Observer.Finish();
    end;
}
