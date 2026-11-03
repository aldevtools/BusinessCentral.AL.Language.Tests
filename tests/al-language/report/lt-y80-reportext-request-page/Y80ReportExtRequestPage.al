// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT Y80 Row" (pages/lt-y80-gone-rows/Y80GoneRows.al); own objects 94293 - 94296
// Probe (writer Y80, from the runtime lane rt-pages-1102c): TestRequestPage in a RequestPageHandler of a report whose request page has a source table, with
//   a reportextension that adds a control and the page triggers (OnAfterGetRecord and the others). report/lt-ab-request-page-triggers and
//   pages/lt-ab-tests/ABTests.al:1192-1295 pin the triggers when the handler sets one value and presses OK or Cancel. Here the handler reads the controls
//   (base and extension), sets the control of the extension, moves (Next, Previous, First, Last, GoToKey, New) and sets a value twice; the log shows
//   which triggers (base, extension, report) ran, in order. Report.Run with the handler, and SaveAsXml with the handler's xml.
// BC versions: 27, 28, 29

report 94293 "LT Y80 RX Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "LT Y80 Row")
        {
            trigger OnPreDataItem()
            var
                Log: Codeunit "LT Y80 RX Log";
            begin
                Log.Add('report predata');
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT Y80 RX Log";
            begin
                Log.Add('report agr ' + Format(T.Id) + '|' + T.Txt + '|' + Format(T.Num));
            end;
        }
    }

    requestpage
    {
        SourceTable = "LT Y80 Row";

        layout
        {
            area(Content)
            {
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base open ' + Format(Rec.Count));
        end;

        trigger OnAfterGetRecord()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base agr ' + Format(Rec.Id));
        end;

        trigger OnAfterGetCurrRecord()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base agcr ' + Format(Rec.Id));
        end;

        trigger OnNewRecord(BelowxRec: Boolean)
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base new');
        end;

        trigger OnModifyRecord(): Boolean
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base modify ' + Rec.Txt);
            exit(true);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base query ' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('base close');
        end;
    }

    trigger OnPreReport()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Log.Add('report prereport');
    end;
}

reportextension 94294 "LT Y80 RX Ext" extends "LT Y80 RX Report"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(NumCtl; ExtNum) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext open ' + '0');
        end;

        trigger OnAfterGetRecord()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext agr ' + '0');
        end;

        trigger OnAfterGetCurrRecord()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext agcr ' + '0');
        end;

        trigger OnNewRecord(BelowxRec: Boolean)
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext new');
        end;

        trigger OnModifyRecord(): Boolean
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext modify ' + '-');
            exit(true);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext query ' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        var
            Log: Codeunit "LT Y80 RX Log";
        begin
            Log.Add('ext close');
        end;

        var
            ExtNum: Integer;
    }
}

codeunit 94296 "LT Y80 RX Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    var
        Entries: Text;
}

codeunit 94295 "LT Y80 RX Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mode: Text;

    local procedure Seed()
    var
        Row: Record "LT Y80 Row";
        Log: Codeunit "LT Y80 RX Log";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I * 10;
            Row.Txt := 'r' + Format(I * 10);
            Row.Num := I;
            Row.Insert();
        end;
        Log.Take();
        Commit();
    end;

    local procedure RowsDump(): Text
    var
        Row: Record "LT Y80 Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += '[' + Format(Row.Id) + '|' + Row.Txt + '|' + Format(Row.Num) + ']';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryStep(var P: TestRequestPage "LT Y80 RX Report"; Which: Text; var Result: Text)
    begin
        case Which of
            'next':
                Result := Format(P.Next(), 0, 9);
            'previous':
                Result := Format(P.Previous(), 0, 9);
            'first':
                Result := Format(P.First(), 0, 9);
            'last':
                Result := Format(P.Last(), 0, 9);
            'goto20':
                Result := Format(P.GoToKey(20), 0, 9);
            'new':
                begin
                    P.New();
                    Result := 'new';
                end;
            'settxt':
                begin
                    P.TxtCtl.SetValue('typed');
                    Result := 'set';
                end;
            'settxt2':
                begin
                    P.TxtCtl.SetValue('typed2');
                    Result := 'set';
                end;
            'setnum':
                begin
                    P.NumCtl.SetValue(55);
                    Result := 'set';
                end;
        end;
        Result += '|' + P.TxtCtl.Value() + '|' + P.NumCtl.Value();
    end;

    local procedure Step(var P: TestRequestPage "LT Y80 RX Report"; Which: Text)
    var
        Log: Codeunit "LT Y80 RX Log";
        Result: Text;
    begin
        if TryStep(P, Which, Result) then
            Observer.Observe(Which, Result)
        else begin
            Observer.Observe(Which, 'err|' + GetLastErrorCode() + '|' + GetLastErrorText());
            ClearLastError();
        end;
        Observer.Observe(Which + ' log', Log.Take());
    end;


    [RequestPageHandler]
    procedure H_ReadOnly_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Observer.Observe('read', P.TxtCtl.Value() + '|' + P.NumCtl.Value());
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_ReadOnly_OK')]
    procedure Y80_RX_ReadOnly_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('read', 'r10|0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_ReadOnly_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Observer.Observe('read', P.TxtCtl.Value() + '|' + P.NumCtl.Value());
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_ReadOnly_Cancel')]
    procedure Y80_RX_ReadOnly_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('read', 'r10|0');
        Observer.Expect('after run log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetNum_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'setnum');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetNum_OK')]
    procedure Y80_RX_SetNum_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('setnum', 'set|r10|55');
        Observer.Expect('setnum log', '');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetNum_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'setnum');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetNum_Cancel')]
    procedure Y80_RX_SetNum_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('setnum', 'set|r10|55');
        Observer.Expect('setnum log', '');
        Observer.Expect('after run log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetTxt_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'settxt');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetTxt_OK')]
    procedure Y80_RX_SetTxt_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('after run log', 'base modify typed | ext modify - | base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|typed|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|typed|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetTxt_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'settxt');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetTxt_Cancel')]
    procedure Y80_RX_SetTxt_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('after run log', 'base modify typed | ext modify - | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|typed|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetTwice_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'settxt');
        Step(P, 'settxt2');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetTwice_OK')]
    procedure Y80_RX_SetTwice_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('settxt2', 'set|typed2|0');
        Observer.Expect('settxt2 log', '');
        Observer.Expect('after run log', 'base modify typed2 | ext modify - | base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|typed2|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|typed2|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetTwice_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'settxt');
        Step(P, 'settxt2');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetTwice_Cancel')]
    procedure Y80_RX_SetTwice_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('settxt2', 'set|typed2|0');
        Observer.Expect('settxt2 log', '');
        Observer.Expect('after run log', 'base modify typed2 | ext modify - | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|typed2|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetBoth_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'settxt');
        Step(P, 'setnum');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetBoth_OK')]
    procedure Y80_RX_SetBoth_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('setnum', 'set|typed|55');
        Observer.Expect('setnum log', '');
        Observer.Expect('after run log', 'base modify typed | ext modify - | base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|typed|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|typed|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_SetBoth_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'settxt');
        Step(P, 'setnum');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_SetBoth_Cancel')]
    procedure Y80_RX_SetBoth_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('setnum', 'set|typed|55');
        Observer.Expect('setnum log', '');
        Observer.Expect('after run log', 'base modify typed | ext modify - | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|typed|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_Next_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'next');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_Next_OK')]
    procedure Y80_RX_Next_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('next', 'true|r20|0');
        Observer.Expect('next log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_Next_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'next');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_Next_Cancel')]
    procedure Y80_RX_Next_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('next', 'true|r20|0');
        Observer.Expect('next log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('after run log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_NextNext_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'next');
        Step(P, 'next');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_NextNext_OK')]
    procedure Y80_RX_NextNext_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('next', 'true|r20|0');
        Observer.Expect('next log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('next', 'true|r30|0');
        Observer.Expect('next log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_NextNext_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'next');
        Step(P, 'next');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_NextNext_Cancel')]
    procedure Y80_RX_NextNext_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('next', 'true|r20|0');
        Observer.Expect('next log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('next', 'true|r30|0');
        Observer.Expect('next log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0');
        Observer.Expect('after run log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_Last_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'last');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_Last_OK')]
    procedure Y80_RX_Last_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('last', 'true|r30|0');
        Observer.Expect('last log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_Last_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'last');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_Last_Cancel')]
    procedure Y80_RX_Last_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('last', 'true|r30|0');
        Observer.Expect('last log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0');
        Observer.Expect('after run log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_LastPrevious_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'last');
        Step(P, 'previous');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_LastPrevious_OK')]
    procedure Y80_RX_LastPrevious_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('last', 'true|r30|0');
        Observer.Expect('last log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0');
        Observer.Expect('previous', 'true|r20|0');
        Observer.Expect('previous log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_LastPrevious_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'last');
        Step(P, 'previous');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_LastPrevious_Cancel')]
    procedure Y80_RX_LastPrevious_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('last', 'true|r30|0');
        Observer.Expect('last log', 'base agr 30 | ext agr 0 | base agcr 30 | ext agcr 0');
        Observer.Expect('previous', 'true|r20|0');
        Observer.Expect('previous log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('after run log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_First_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'first');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_First_OK')]
    procedure Y80_RX_First_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('first', 'true|r10|0');
        Observer.Expect('first log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_First_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'first');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_First_Cancel')]
    procedure Y80_RX_First_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('first', 'true|r10|0');
        Observer.Expect('first log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('after run log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_GoToKey_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'goto20');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_GoToKey_OK')]
    procedure Y80_RX_GoToKey_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('goto20', 'true|r20|0');
        Observer.Expect('goto20 log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_GoToKey_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'goto20');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_GoToKey_Cancel')]
    procedure Y80_RX_GoToKey_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('goto20', 'true|r20|0');
        Observer.Expect('goto20 log', 'base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0 | base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('after run log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_New_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'new');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_New_OK')]
    procedure Y80_RX_New_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('new', 'new||0');
        Observer.Expect('new log', 'base agcr 0 | ext agcr 0');
        Observer.Expect('after run log', 'base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|r20|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_New_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'new');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_New_Cancel')]
    procedure Y80_RX_New_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('new', 'new||0');
        Observer.Expect('new log', 'base agcr 0 | ext agcr 0');
        Observer.Expect('after run log', 'base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|r20|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_NextSet_OK(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'next');
        Step(P, 'settxt');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_NextSet_OK')]
    procedure Y80_RX_NextSet_OK()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('next', 'true|r20|0');
        Observer.Expect('next log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('after run log', 'base modify typed | ext modify - | base query OK | ext query OK | base close | ext close | report prereport | report predata | report agr 10|r10|1 | report agr 20|typed|2 | report agr 30|r30|3');
        Observer.Expect('rows', '[10|r10|1][20|typed|2][30|r30|3]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure H_NextSet_Cancel(var P: TestRequestPage "LT Y80 RX Report")
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Observer.Observe('handler start', Log.Take());
        Step(P, 'next');
        Step(P, 'settxt');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('H_NextSet_Cancel')]
    procedure Y80_RX_NextSet_Cancel()
    var
        Log: Codeunit "LT Y80 RX Log";
    begin
        Seed();
        Report.Run(Report::"LT Y80 RX Report");
        Observer.Observe('after run log', Log.Take());
        Observer.Observe('rows', RowsDump());
        Observer.Expect('handler start', 'base open 3 | ext open 0 | base agr 10 | ext agr 0 | base agcr 10 | ext agcr 0');
        Observer.Expect('next', 'true|r20|0');
        Observer.Expect('next log', 'base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0');
        Observer.Expect('settxt', 'set|typed|0');
        Observer.Expect('settxt log', '');
        Observer.Expect('after run log', 'base modify typed | ext modify - | base agr 20 | ext agr 0 | base agcr 20 | ext agcr 0 | base query Cancel | ext query Cancel | base close | ext close');
        Observer.Expect('rows', '[10|r10|1][20|typed|2][30|r30|3]');
        Observer.Verify();
    end;
}
