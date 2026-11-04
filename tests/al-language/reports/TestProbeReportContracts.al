// Observe-only probes (writer A). Rows: AllowScheduling, trigger order of a run, report variable reuse,
// UseRequestPage getter/setter, RunRequestPage parameters text and OK/Cancel, writes inside a request page handler,
// DataItemLink filters after the run, Skip/Break/Quit, UseTemporary data items.
table 69809 "PA Rpt Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

report 69800 "PA Rpt Scheduling True"
{
    ProcessingOnly = true;
    AllowScheduling = true;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Row; "PA Rpt Row") { }
    }
    trigger OnPreReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add('scheduling-true OnPreReport');
    end;
}

report 69801 "PA Rpt Scheduling False"
{
    ProcessingOnly = true;
    AllowScheduling = false;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Row; "PA Rpt Row") { }
    }
    trigger OnPreReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add('scheduling-false OnPreReport');
    end;
}

report 69802 "PA Rpt Order"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Parent; "PA Rpt Row")
        {
            DataItemTableView = sorting(Id) where(Grp = const(0));
            dataitem(Child; "PA Rpt Row")
            {
                DataItemLink = Grp = field(Id);
                trigger OnPreDataItem()
                begin
                    Log('Child OnPreDataItem count=' + Format(Child.Count()) + ' filters=' + Child.GetFilters());
                end;

                trigger OnAfterGetRecord()
                begin
                    Log('Child OnAfterGetRecord id=' + Format(Child.Id));
                end;

                trigger OnPostDataItem()
                begin
                    Log('Child OnPostDataItem');
                end;
            }
            trigger OnPreDataItem()
            begin
                Log('Parent OnPreDataItem count=' + Format(Parent.Count()));
            end;

            trigger OnAfterGetRecord()
            begin
                Log('Parent OnAfterGetRecord id=' + Format(Parent.Id));
            end;

            trigger OnPostDataItem()
            begin
                Log('Parent OnPostDataItem');
            end;

        }
        dataitem(Second; "PA Rpt Row")
        {
            DataItemTableView = sorting(Id) where(Id = const(1));
            trigger OnAfterGetRecord()
            begin
                Log('Second OnAfterGetRecord id=' + Format(Second.Id));
            end;
        }
    }

    trigger OnInitReport()
    begin
        Log('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        Log('OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log('OnPostReport child filters=[' + Child.GetFilters() + '] parent filters=[' + Parent.GetFilters() + ']');
    end;

    local procedure Log(T: Text)
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add(T);
    end;
}

report 69803 "PA Rpt Skip Break Quit"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Item; "PA Rpt Row")
        {
            DataItemTableView = sorting(Id) where(Grp = const(0));
            dataitem(Nested; "PA Rpt Row")
            {
                DataItemLink = Grp = field(Id);
                trigger OnAfterGetRecord()
                begin
                    Log('Nested id=' + Format(Nested.Id));
                end;
            }
            trigger OnAfterGetRecord()
            begin
                Log('Item id=' + Format(Item.Id));
                case ModeValue of
                    1:
                        if Item.Id = 2 then
                            CurrReport.Skip();
                    2:
                        if Item.Id = 2 then
                            CurrReport.Break();
                    3:
                        if Item.Id = 2 then
                            CurrReport.Quit();
                end;
            end;

            trigger OnPostDataItem()
            begin
                Log('Item OnPostDataItem');
            end;

        }
    }

    var
        ModeValue: Integer;

    procedure SetMode(M: Integer)
    begin
        ModeValue := M;
    end;

    trigger OnPostReport()
    begin
        Log('OnPostReport');
    end;

    local procedure Log(T: Text)
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add(T);
    end;
}

report 69804 "PA Rpt Quit In Pre"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Item; "PA Rpt Row")
        {
            trigger OnAfterGetRecord()
            var
                L: Codeunit "PA Rpt Log";
            begin
                L.Add('Item should not run');
            end;
        }
    }
    trigger OnPreReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add('OnPreReport before quit');
        CurrReport.Quit();
    end;

    trigger OnPostReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add('OnPostReport after quit');
    end;
}

report 69805 "PA Rpt Globals"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Row; "PA Rpt Row") { }
    }
    var
        Counter: Integer;
        InitCount: Integer;

    trigger OnInitReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        InitCount += 1;
        L.Add('OnInitReport initcount=' + Format(InitCount) + ' counter=' + Format(Counter));
    end;

    trigger OnPreReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        Counter += 1;
        L.Add('OnPreReport counter=' + Format(Counter) + ' initcount=' + Format(InitCount));
    end;
}

report 69806 "PA Rpt Request"
{
    ProcessingOnly = true;
    UsageCategory = None;
    dataset
    {
        dataitem(Row; "PA Rpt Row")
        {
            RequestFilterFields = Id, Grp;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OptName; NameValue) { ApplicationArea = All; Caption = 'Name option'; }
                field(OptNum; NumValue) { ApplicationArea = All; Caption = 'Number option'; }
                field(OptFlag; FlagValue) { ApplicationArea = All; Caption = 'Flag option'; }
                field(OptDate; DateValue) { ApplicationArea = All; Caption = 'Date option'; }
            }
        }
        trigger OnOpenPage()
        var
            L: Codeunit "PA Rpt Log";
        begin
            L.Add('request OnOpenPage name=' + NameValue);
        end;
    }
    var
        NameValue: Text[30];
        NumValue: Decimal;
        FlagValue: Boolean;
        DateValue: Date;

    trigger OnPreReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add('OnPreReport name=' + NameValue + ' num=' + Format(NumValue) + ' flag=' + Format(FlagValue) + ' rowfilters=' + Row.GetFilters());
    end;
}

report 69807 "PA Rpt Temp Item"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    dataset
    {
        dataitem(Tmp; "PA Rpt Row")
        {
            UseTemporary = true;
            trigger OnAfterGetRecord()
            var
                L: Codeunit "PA Rpt Log";
            begin
                L.Add('Tmp id=' + Format(Tmp.Id));
            end;
        }
    }
    trigger OnPreReport()
    var
        L: Codeunit "PA Rpt Log";
    begin
        L.Add('OnPreReport tmp count=' + Format(Tmp.Count()) + ' istemporary=' + Format(Tmp.IsTemporary()));
        Tmp.Id := 11;
        Tmp.Insert();
        Tmp.Id := 12;
        Tmp.Insert();
    end;
}

report 69808 "PA Rpt Request ShowFilter"
{
    ProcessingOnly = true;
    UsageCategory = None;
    dataset
    {
        dataitem(Row; "PA Rpt Row")
        {
            RequestFilterFields = Id;
        }
    }
    requestpage
    {
        ShowFilter = false;
        layout
        {
            area(Content)
            {
                field(OptName; NameValue) { ApplicationArea = All; }
            }
        }
    }
    var
        NameValue: Text[30];
}

codeunit 69817 "PA Report Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HLog: Text;

    local procedure Start(var L: Codeunit "PA Rpt Log")
    var
        R: Record "PA Rpt Row";
    begin
        R.DeleteAll();
        L.Reset();
        HLog := '';
    end;

    local procedure Seed(Id: Integer; Grp: Integer)
    var
        R: Record "PA Rpt Row";
    begin
        R.Id := Id;
        R.Grp := Grp;
        R.Insert();
    end;

    [Test]
    procedure AllowScheduling_TrueAndFalse_Run()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
    begin
        Start(L);
        Seed(1, 0);
        O.Observe('true_run', TryRun(69800));
        O.Observe('false_run', TryRun(69801));
        O.Observe('log', L.Text());
        O.Expect('true_run', 'ok');
        O.Expect('false_run', 'ok');
        O.Expect('log', 'scheduling-true OnPreReport ; scheduling-false OnPreReport ; ');
        O.Verify();
    end;

    local procedure TryRun(Id: Integer): Text
    begin
        if TryRunF(Id) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRunF(Id: Integer)
    begin
        Report.Run(Id);
    end;

    [Test]
    procedure TriggerOrder_NestedAndSecondItem()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
    begin
        Start(L);
        Seed(1, 0);
        Seed(2, 0);
        Seed(10, 1);
        Seed(11, 1);
        Seed(20, 2);
        Report.Run(69802);
        O.Observe('log', L.Text());
        O.Expect('log', 'OnInitReport ; OnPreReport ; Parent OnPreDataItem count=2 ; Parent OnAfterGetRecord id=1 ; Child OnPreDataItem count=2 filters= ; Child OnAfterGetRecord id=10 ; Child OnAfterGetRecord id=11 ; Child OnPostDataItem ; Parent OnAfterGetRecord id=2 ; Child OnPreDataItem count=1 filters= ; Child OnAfterGetRecord id=20 ; Child OnPostDataItem ; Parent OnPostDataItem ; Second OnAfterGetRecord id=1 ; OnPostReport child filters=[] parent filters=[] ; ');
        O.Verify();
    end;

    [Test]
    procedure SkipBreakQuit_InAfterGetRecord()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Skip Break Quit";
    begin
        Start(L);
        Seed(1, 0);
        Seed(2, 0);
        Seed(3, 0);
        Seed(10, 1);
        Seed(20, 2);
        Seed(30, 3);
        Rpt.SetMode(1);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        O.Observe('skip', L.Text());
        L.Reset();
        Clear(Rpt);
        Rpt.SetMode(2);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        O.Observe('break', L.Text());
        L.Reset();
        Clear(Rpt);
        Rpt.SetMode(3);
        Rpt.UseRequestPage(false);
        O.Observe('quit_run', TryRunVar(Rpt));
        O.Observe('quit', L.Text());
        O.Expect('skip', 'Item id=1 ; Nested id=10 ; Item id=2 ; Item id=3 ; Nested id=30 ; Item OnPostDataItem ; OnPostReport ; ');
        O.Expect('break', 'Item id=1 ; Nested id=10 ; Item id=2 ; Item OnPostDataItem ; OnPostReport ; ');
        O.Expect('quit_run', 'ok');
        O.Expect('quit', 'Item id=1 ; Nested id=10 ; Item id=2 ; ');
        O.Verify();
    end;

    local procedure TryRunVar(var Rpt: Report "PA Rpt Skip Break Quit"): Text
    begin
        if TryRunVarF(Rpt) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRunVarF(var Rpt: Report "PA Rpt Skip Break Quit")
    begin
        Rpt.Run();
    end;

    [Test]
    procedure Quit_InOnPreReport()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
    begin
        Start(L);
        Seed(1, 0);
        Report.Run(69804);
        O.Observe('log', L.Text());
        O.Expect('log', 'OnPreReport before quit ; ');
        O.Verify();
    end;

    [Test]
    procedure ReportVariable_RunTwice_GlobalsReset()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Globals";
    begin
        Start(L);
        Seed(1, 0);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        O.Observe('first_run', L.Text());
        L.Reset();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        O.Observe('second_run_same_variable', L.Text());
        L.Reset();
        Rpt.RunModal();
        O.Observe('third_runmodal_same_variable', L.Text());
        O.Expect('first_run', 'OnInitReport initcount=1 counter=0 ; OnPreReport counter=1 initcount=1 ; ');
        O.Expect('second_run_same_variable', 'OnInitReport initcount=1 counter=0 ; OnPreReport counter=1 initcount=1 ; ');
        O.Expect('third_runmodal_same_variable', 'OnInitReport initcount=1 counter=0 ; OnPreReport counter=1 initcount=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure UseRequestPage_GetterAndSetter()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Globals";
        RptReq: Report "PA Rpt Request";
    begin
        Start(L);
        O.Observe('declared_false_getter', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(true);
        O.Observe('declared_false_after_set_true_getter', Format(Rpt.UseRequestPage()));
        O.Observe('declared_true_getter', Format(RptReq.UseRequestPage()));
        RptReq.UseRequestPage(false);
        O.Observe('declared_true_after_set_false', Format(RptReq.UseRequestPage()));
        Seed(1, 0);
        O.Observe('run_declared_false_set_true_no_handler', TryRunGlobals(Rpt));
        O.Observe('log', L.Text());
        L.Reset();
        O.Observe('run_declared_true_set_false', TryRunRequest(RptReq));
        O.Observe('log_request', L.Text());
        O.Expect('declared_false_getter', 'No');
        O.Expect('declared_false_after_set_true_getter', 'Yes');
        O.Expect('declared_true_getter', 'Yes');
        O.Expect('declared_true_after_set_false', 'No');
        O.Expect('run_declared_false_set_true_no_handler', 'ERR:An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance./DB:Ok');
        O.Expect('log', 'OnInitReport initcount=1 counter=0 ; ');
        O.Expect('run_declared_true_set_false', 'ok');
        O.Expect('log_request', 'OnPreReport name= num=0 flag=No rowfilters= ; ');
        O.Verify();
    end;

    local procedure TryRunGlobals(var Rpt: Report "PA Rpt Globals"): Text
    begin
        if TryRunGlobalsF(Rpt) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRunGlobalsF(var Rpt: Report "PA Rpt Globals")
    begin
        Rpt.Run();
    end;

    local procedure TryRunRequest(var Rpt: Report "PA Rpt Request"): Text
    begin
        if TryRunRequestF(Rpt) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRunRequestF(var Rpt: Report "PA Rpt Request")
    begin
        Rpt.Run();
    end;

    [Test]
    procedure RequestWindowFalse_StaticRun()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
    begin
        Start(L);
        Seed(1, 0);
        Report.Run(69806, false);
        O.Observe('static_run_request_window_false', L.Text());
        L.Reset();
        O.Observe('static_run_request_window_true_no_handler', TryRunStatic(69806));
        O.Observe('log', L.Text());
        O.Expect('static_run_request_window_false', 'OnPreReport name= num=0 flag=No rowfilters= ; ');
        O.Expect('static_run_request_window_true_no_handler', 'ERR:An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance./DB:Ok');
        O.Expect('log', '');
        O.Verify();
    end;

    local procedure TryRunStatic(Id: Integer): Text
    begin
        if TryRunStaticF(Id) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRunStaticF(Id: Integer)
    begin
        Report.Run(Id, true);
    end;

    [Test]
    [HandlerFunctions('RequestOK')]
    procedure RunRequestPage_ParametersText()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Request";
        Params: Text;
        Lf: Text;
    begin
        Start(L);
        Lf[1] := 10;
        Seed(1, 0);
        Commit();
        Params := Rpt.RunRequestPage();
        O.Observe('parameters', Params.Replace(Lf, '<LF>'));
        O.Observe('log', L.Text());
        O.Expect('parameters', '<?xml version="1.0" standalone="yes"?><ReportParameters name="PA Rpt Request" id="69806"><Options><Field name="NameValue">typed</Field><Field name="NumValue">12.5</Field><Field name="FlagValue">true</Field><Field name="DateValue">2024-03-05</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(1..5))</DataItem></DataItems></ReportParameters>');
        O.Expect('log', 'request OnOpenPage name= ; ');
        O.Verify();
    end;

    [RequestPageHandler]
    procedure RequestOK(var RP: TestRequestPage "PA Rpt Request")
    begin
        RP.OptName.SetValue('typed');
        RP.OptNum.SetValue(12.5);
        RP.OptFlag.SetValue(true);
        RP.OptDate.SetValue(DMY2Date(5, 3, 2024));
        RP.Row.SetFilter(Id, '1..5');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestCancel')]
    procedure RunRequestPage_Cancel_ParametersText()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Request";
        Params: Text;
    begin
        Start(L);
        Commit();
        Params := Rpt.RunRequestPage();
        O.Observe('parameters_after_cancel', '[' + Params + ']');
        O.Expect('parameters_after_cancel', '[]');
        O.Verify();
    end;

    [RequestPageHandler]
    procedure RequestCancel(var RP: TestRequestPage "PA Rpt Request")
    begin
        RP.OptName.SetValue('typed');
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestInvokeUnknown')]
    procedure RequestPage_InvokeActionNotFound()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Request";
        Params: Text;
    begin
        Start(L);
        Commit();
        Params := Rpt.RunRequestPage();
        O.Observe('handler_log', HLog);
        O.Expect('handler_log', 'ok-visible=ok');
        O.Verify();
    end;

    [RequestPageHandler]
    procedure RequestInvokeUnknown(var RP: TestRequestPage "PA Rpt Request")
    begin
        HLog := 'ok-visible=' + TryActions(RP);
        RP.OK().Invoke();
    end;

    local procedure TryActions(var RP: TestRequestPage "PA Rpt Request"): Text
    begin
        if TryActionsF(RP) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryActionsF(var RP: TestRequestPage "PA Rpt Request")
    var
        B: Boolean;
    begin
        B := RP.OK().Visible();
        B := RP.Cancel().Visible();
    end;

    [Test]
    [HandlerFunctions('RequestWriteInside')]
    procedure RequestPage_TableWriteInsideHandler()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Request";
        Params: Text;
        R: Record "PA Rpt Row";
    begin
        Start(L);
        Commit();
        Params := Rpt.RunRequestPage();
        O.Observe('handler_log', HLog);
        O.Observe('row_count_after', Format(R.Count()));
        O.Expect('handler_log', 'insert error=A transaction must be started before changes can be made to the database. code=DB:BWTMissing');
        O.Expect('row_count_after', '0');
        O.Verify();
    end;

    [RequestPageHandler]
    procedure RequestWriteInside(var RP: TestRequestPage "PA Rpt Request")
    var
        R: Record "PA Rpt Row";
    begin
        R.Id := 500;
        asserterror R.Insert();
        HLog := 'insert error=' + GetLastErrorText() + ' code=' + GetLastErrorCode();
        RP.OK().Invoke();
    end;

    [Test]
    procedure UseTemporary_DataItem()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
    begin
        Start(L);
        Seed(1, 0);
        Report.Run(69807);
        O.Observe('log', L.Text());
        O.Expect('log', 'OnPreReport tmp count=0 istemporary=Yes ; Tmp id=11 ; Tmp id=12 ; ');
        O.Verify();
    end;

    [Test]
    [HandlerFunctions('ShowFilterOK')]
    procedure RequestPage_ShowFilterFalse()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Rpt Log";
        Rpt: Report "PA Rpt Request ShowFilter";
        Params: Text;
        Lf: Text;
    begin
        Start(L);
        Lf[1] := 10;
        Commit();
        Params := Rpt.RunRequestPage();
        O.Observe('parameters', Params.Replace(Lf, '<LF>'));
        O.Observe('handler_log', HLog);
        O.Expect('parameters', '<?xml version="1.0" standalone="yes"?><ReportParameters name="PA Rpt Request ShowFilter" id="69808"><Options><Field name="NameValue">x</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        O.Expect('handler_log', '');
        O.Verify();
    end;

    [RequestPageHandler]
    procedure ShowFilterOK(var RP: TestRequestPage "PA Rpt Request ShowFilter")
    begin
        RP.OptName.SetValue('x');
        RP.OK().Invoke();
    end;
}

codeunit 69823 "PA Rpt Log"
{
    SingleInstance = true;
    var
        Lines: List of [Text];

    procedure Add(T: Text)
    begin
        Lines.Add(T);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Text(): Text
    var
        L: Text;
        R: Text;
    begin
        foreach L in Lines do
            R += L + ' ; ';
        exit(R);
    end;
}
