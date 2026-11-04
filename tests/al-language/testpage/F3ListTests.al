// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Row / Log Mgt / Nav List / Delete List / List (F3Fixtures.al)
// Probe: (1) how the client reads a list through OnFindRecord(Which) and OnNextRecord(Steps): open, Last, Previous, First, Next, GoToKey, and CurrPage.Update after the view changed.
//        (2) Format of a TestPage control and of its members.
//        (3) a list whose only row an action deletes, without and with CurrPage.Update: current row, OnAfterGetCurrRecord calls.
//        (4) CurrPage.SetSelectionFilter on a page with no current row.
// Object ids 67095 - 67096.

codeunit 67095 "LT F3 List Cursor"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Observer.Observe(Name, Log.Dump());
        Log.Clear();
    end;

    [Test]
    procedure Nav_TwelveRows_OpenLastPreviousFirstNext()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 Nav List";
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Step(Observer, 'open');
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('last_no', P.NoCtl.Value());
        Step(Observer, 'after_last');
        Observer.Observe('prev1', Format(P.Previous()));
        Observer.Observe('prev2', Format(P.Previous()));
        Observer.Observe('prev3', Format(P.Previous()));
        Observer.Observe('prev_no', P.NoCtl.Value());
        Step(Observer, 'after_previous3');
        Observer.Observe('first', Format(P.First()));
        Step(Observer, 'after_first');
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next_no', P.NoCtl.Value());
        Step(Observer, 'after_next2');
        Observer.Observe('goto', Format(P.GoToKey('R1009')));
        Step(Observer, 'after_goto');
        P.Close();
        Observer.Expect('open', 'Find(=><)=Yes | AGR(R1001) | Next(1)=1 | AGR(R1002) | Next(1)=1 | AGR(R1003) | Next(1)=1 | AGR(R1004) | Next(1)=1 | AGR(R1005) | Next(1)=1 | AGR(R1006) | Next(1)=1 | AGR(R1007) | Next(1)=1 | AGR(R1008) | Next(1)=1 | AGR(R1009) | Next(1)=1 | AGR(R1010) | Next(1)=1 | AGR(R1011) | Next(1)=1 | AGR(R1012) | Next(1)=0 | AGR(R1001) | Next(-1)=0 | ');
        Observer.Expect('last', 'Yes');
        Observer.Expect('last_no', 'R1012');
        Observer.Expect('after_last', '');
        Observer.Expect('prev1', 'Yes');
        Observer.Expect('prev2', 'Yes');
        Observer.Expect('prev3', 'Yes');
        Observer.Expect('prev_no', 'R1009');
        Observer.Expect('after_previous3', '');
        Observer.Expect('first', 'Yes');
        Observer.Expect('after_first', '');
        Observer.Expect('next1', 'Yes');
        Observer.Expect('next2', 'Yes');
        Observer.Expect('next_no', 'R1003');
        Observer.Expect('after_next2', '');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_goto', '');
        Observer.Verify();
    end;

    [Test]
    procedure Nav_ActionChangesViewThenUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 Nav List";
        Rows: Text;
    begin
        Log.Seed(12);
        Log.Clear();
        P.OpenView();
        Observer.Observe('goto', Format(P.GoToKey('R1003')));
        Log.Clear();
        P.OnlyBig.Invoke();
        Observer.Observe('current_no', P.NoCtl.Value());
        Step(Observer, 'after_update');
        if P.First() then
            repeat
                Rows += P.NoCtl.Value() + ',';
            until not P.Next();
        Observer.Observe('rows', Rows);
        Step(Observer, 'after_walk');
        P.Close();
        Observer.Expect('goto', 'Yes');
        Observer.Expect('current_no', 'R1008');
        Observer.Expect('after_update', 'AGR(R1003) | AGR(R1003) | OnlyBig done | Next(1)=1 | AGR(R1008) | Find(=>)=Yes | AGR(R1008) | Next(1)=1 | AGR(R1009) | Next(1)=1 | AGR(R1010) | Next(1)=1 | AGR(R1011) | Next(1)=1 | AGR(R1012) | Next(1)=0 | AGR(R1008) | Next(-1)=0 | ');
        Observer.Expect('rows', 'R1008,R1009,R1010,R1011,R1012,');
        Observer.Expect('after_walk', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFormat(var P: TestPage "LT F3 List"; Which: Integer; var Result: Text)
    begin
        case Which of
            1:
                Result := Format(P.NoCtl);
            2:
                Result := Format(P.QtyCtl);
            3:
                Result := Format(P.NoCtl.Value());
            4:
                Result := Format(P.QtyCtl.AsInteger());
            5:
                Result := Format(P.QtyCtl.Visible());
            6:
                Result := Format(P.NoCtl.Editable());
            7:
                Result := Format(P);
        end;
    end;

    [Test]
    procedure TestPage_FormatOfControl()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 List";
        Result: Text;
        Which: Integer;
        Ok: Boolean;
    begin
        Log.Seed(3);
        P.OpenView();
        P.GoToKey('R1002');
        for Which := 1 to 7 do begin
            Clear(Result);
            ClearLastError();
            Ok := TryFormat(P, Which, Result);
            Observer.Observe('f' + Format(Which) + '_ok', Format(Ok));
            Observer.Observe('f' + Format(Which) + '_result', Result);
            if not Ok then begin
                Observer.Observe('f' + Format(Which) + '_error', GetLastErrorText());
                Observer.Observe('f' + Format(Which) + '_code', GetLastErrorCode());
            end;
        end;
        P.Close();
        Observer.Expect('f1_ok', 'Yes');
        Observer.Expect('f1_result', 'R1002');
        Observer.Expect('f2_ok', 'Yes');
        Observer.Expect('f2_result', '2');
        Observer.Expect('f3_ok', 'Yes');
        Observer.Expect('f3_result', 'R1002');
        Observer.Expect('f4_ok', 'Yes');
        Observer.Expect('f4_result', '2');
        Observer.Expect('f5_ok', 'Yes');
        Observer.Expect('f5_result', 'Yes');
        Observer.Expect('f6_ok', 'Yes');
        Observer.Expect('f6_result', 'No');
        Observer.Expect('f7_ok', 'Yes');
        Observer.Expect('f7_result', 'TestPage 67078');
        Observer.Verify();
    end;
}

codeunit 67096 "LT F3 List Delete Select"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [PageHandler]
    procedure EmptyViewHandler(var P: TestPage "LT F3 Delete List")
    begin
        Observer.Observe('h_first', Format(P.First()));
        P.SelectionFilter.Invoke();
    end;

    [PageHandler]
    procedure RowViewHandler(var P: TestPage "LT F3 Delete List")
    begin
        Observer.Observe('h_goto', Format(P.GoToKey('R1002')));
        P.SelectionFilter.Invoke();
    end;

    [Test]
    procedure DeleteOnlyRow_WithoutUpdate()
    var
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
        P: TestPage "LT F3 Delete List";
    begin
        Log.Seed(1);
        P.OpenEdit();
        Log.Clear();
        P.DeleteRow.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('name', P.NameCtl.Value());
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('log_after_first', Log.Dump());
        P.Close();
        Observer.Expect('log', 'AGCR() | AGCR() | AGCR() | ');
        Observer.Expect('no', '');
        Observer.Expect('name', '');
        Observer.Expect('db_count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('log_after_first', 'AGCR() | AGCR() | AGCR() | ');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteOnlyRow_WithUpdate()
    var
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
        P: TestPage "LT F3 Delete List";
    begin
        Log.Seed(1);
        P.OpenEdit();
        Log.Clear();
        P.DeleteRowUpdate.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('name', P.NameCtl.Value());
        Observer.Observe('db_count', Format(Row.Count()));
        Observer.Observe('first', Format(P.First()));
        P.Close();
        Observer.Expect('log', 'AGCR() | AGCR() | AGCR() | ');
        Observer.Expect('no', '');
        Observer.Expect('name', '');
        Observer.Expect('db_count', '0');
        Observer.Expect('first', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteLastOfTwoRows_WithoutUpdate()
    var
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 Delete List";
    begin
        Log.Seed(2);
        P.OpenEdit();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Log.Clear();
        P.DeleteRow.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'AGCR(R1001) | AGCR(R1001) | ');
        Observer.Expect('no', 'R1001');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('next', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EmptyViewHandler')]
    procedure SelectionFilter_NoCurrentRow_TableHasRows()
    var
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
    begin
        Log.Seed(3);
        Log.Clear();
        Row.SetRange(Qty, 99);
        Page.Run(Page::"LT F3 Delete List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('h_first', 'No');
        Observer.Expect('log', 'AGCR() | AGCR() | Selection count=0 filter=[No.: ''''] | AGCR() | AGCR() | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowViewHandler')]
    procedure SelectionFilter_CurrentRow()
    var
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
    begin
        Log.Seed(3);
        Log.Clear();
        Page.Run(Page::"LT F3 Delete List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('h_goto', 'Yes');
        Observer.Expect('log', 'AGCR(R1001) | AGCR(R1002) | Selection count=1 filter=[No.: R1002] | AGCR(R1002) | ');
        Observer.Verify();
    end;
}
