//sub:report
// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: the parameters text Report.RunRequestPage returns for request page fields bound to something other than a plain global
// variable, and what Report.Execute and Report.RunRequestPage(Id, Parameters) do with that text. Also a RequestPageHandler that does
// nothing, one that only reads, and one that only presses OK or Cancel, on Report.RunRequestPage and on Report.Run.
// Fixtures used: "Probe Observer" (_fixtures/ProbeObserver.Codeunit.al).
// Probe: written against al-runner issues 6960 (a field bound to Arr[1].Name, an element of an array of records) and 6996 (an empty
// RequestPageHandler for Report.RunRequestPage). Not covered elsewhere: reports/extensions/W3RpExtRequestPage.al pins report
// extension controls on variables; reports/TestReportRequestPageSourceTableCompiledContracts.al pins that a SourceTable field is not
// in the text; reports/request-page/Y42RequestLeftOpen.al pins a handler that reads, or sets and returns, on other report shapes.
// Bindings on the request page of "R6960 Bind": a plain Code variable, a field of a global record variable, a field of the first
// and second element of an array of records, an element of a plain Text array, and a field of the data item's record.
// Facts (BC 29.0, CI): every one of these fields is in the Options of the parameters text, in control order, named by its
// source expression as written (`Buf.Name`, `BufArr[1].Name`, `TxtArr[2]`, `D.Name`), an empty value as `<Field name="..." />`.
// Report.Execute and Report.RunRequestPage(Id, Parameters) with that text set each of them again. A handler that does nothing,
// or only reads, closes the page with Cancel (OnQueryClosePage(Cancel), OnClosePage): RunRequestPage returns '' and Report.Run
// does not run the report; Report.Execute with that '' runs the report on the defaults without opening the request page.

table 95540 "R6960 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95541 "R6960 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 95542 "R6960 Bind"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(D; "R6960 Row")
        {
            DataItemTableView = where(Id = const(1));

            trigger OnPreDataItem()
            begin
                Log.Add('pre plain=' + PlainVal + ' rec=' + Buf.Name + ' arr1=' + BufArr[1].Name + ' arr2=' + BufArr[2].Name +
                    ' txt2=' + TxtArr[2] + ' item=' + D.Name);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Main)
                {
                    field(PlainCtl; PlainVal) { ApplicationArea = All; }
                    field(RecCtl; Buf.Name) { ApplicationArea = All; }
                    field(Arr1Ctl; BufArr[1].Name) { ApplicationArea = All; }
                    field(Arr2Ctl; BufArr[2].Name) { ApplicationArea = All; }
                    field(TxtCtl; TxtArr[2]) { ApplicationArea = All; }
                    field(ItemCtl; D.Name) { ApplicationArea = All; }
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('qc ' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            Log.Add('close');
        end;
    }

    var
        Log: Codeunit "R6960 Log";
        Buf: Record "R6960 Row";
        BufArr: array[2] of Record "R6960 Row";
        PlainVal: Code[10];
        TxtArr: array[3] of Text[20];
}

// Runs one report call inside Codeunit.Run, so an error ends here and the test observes it.
codeunit 95543 "R6960 Runner"
{
    var
        Kind: Integer;
        Params: Text;
        Result: Text;

    procedure Prepare(NewKind: Integer; NewParams: Text)
    begin
        Kind := NewKind;
        Params := NewParams;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    trigger OnRun()
    begin
        case Kind of
            0:
                Result := Report.RunRequestPage(Report::"R6960 Bind");
            1:
                Result := Report.RunRequestPage(Report::"R6960 Bind", Params);
            2:
                Report.Execute(Report::"R6960 Bind", Params);
            3:
                Report.Run(Report::"R6960 Bind");
        end;
    end;
}

codeunit 95544 "R6960 Param Bindings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "R6960 Log";
        // 0: type a value into every control, then OK; 1: log every control's value, then OK; 2: OK only; 3: Cancel only;
        // 4: read one value and return.
        HMode: Integer;

    local procedure Seed()
    var
        Row: Record "R6960 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'ROW1';
        Row.Insert();
        Commit();
        Log.Take();
    end;

    local procedure Exec(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer; Params: Text): Text
    var
        Runner: Codeunit "R6960 Runner";
        Ok: Boolean;
    begin
        ClearLastError();
        Runner.Prepare(Kind, Params);
        Ok := Runner.Run();
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.Observe(Name + ' error|text', GetLastErrorText());
        Observer.Observe(Name + ' error|code', GetLastErrorCode());
        Observer.Observe(Name + ' log', Log.Take());
        exit(Runner.GetResult());
    end;

    [Test]
    [HandlerFunctions('BindHandler')]
    procedure Rrp_TypedValues_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        Observer.Observe('rrp result', Exec(Observer, 'rrp', 0, ''));
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc OK;close;');
        Observer.Expect('rrp result', '<?xml version="1.0" standalone="yes"?><ReportParameters name="R6960 Bind" id="95542"><Options><Field name="PlainVal">P1</Field><Field name="Buf.Name">R1</Field><Field name="BufArr[1].Name">A1</Field><Field name="BufArr[2].Name">A2</Field><Field name="TxtArr[2]">T2</Field><Field name="D.Name">I1</Field></Options><DataItems><DataItem name="D">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BindHandler')]
    procedure Rrp_Defaults_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 2;
        Observer.Observe('rrp result', Exec(Observer, 'rrp', 0, ''));
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc OK;close;');
        Observer.Expect('rrp result', '<?xml version="1.0" standalone="yes"?><ReportParameters name="R6960 Bind" id="95542"><Options><Field name="PlainVal" /><Field name="Buf.Name" /><Field name="BufArr[1].Name" /><Field name="BufArr[2].Name" /><Field name="TxtArr[2]" /><Field name="D.Name" /></Options><DataItems><DataItem name="D">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BindHandler')]
    procedure Rrp_TypedValues_ThenExecute()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        HMode := 0;
        Params := Exec(Observer, 'rrp', 0, '');
        Exec(Observer, 'execute', 2, Params);
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc OK;close;');
        Observer.Expect('execute ok', 'Yes');
        Observer.Expect('execute error|text', '');
        Observer.Expect('execute error|code', '');
        Observer.Expect('execute log', 'open;close;pre plain=P1 rec=R1 arr1=A1 arr2=A2 txt2=T2 item=I1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BindHandler')]
    procedure Rrp_TypedValues_ThenSeededRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        HMode := 0;
        Params := Exec(Observer, 'rrp', 0, '');
        HMode := 1;
        Exec(Observer, 'seeded', 1, Params);
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc OK;close;');
        Observer.Expect('seeded ok', 'Yes');
        Observer.Expect('seeded error|text', '');
        Observer.Expect('seeded error|code', '');
        Observer.Expect('seeded log', 'open;h plain=P1 rec=R1 arr1=A1 arr2=A2 txt2=T2 item=I1;qc OK;close;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BindHandler')]
    procedure Rrp_CancelOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 3;
        Observer.Observe('rrp result', Exec(Observer, 'rrp', 0, ''));
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc Cancel;close;');
        Observer.Expect('rrp result', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BindHandler')]
    procedure Rrp_ReadOnlyHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 4;
        Observer.Observe('rrp result', Exec(Observer, 'rrp', 0, ''));
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;h plain=;qc Cancel;close;');
        Observer.Expect('rrp result', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EmptyHandler')]
    procedure Rrp_EmptyHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('rrp result', Exec(Observer, 'rrp', 0, ''));
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc Cancel;close;');
        Observer.Expect('rrp result', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EmptyHandler')]
    procedure Rrp_EmptyHandler_ThenExecuteWithItsText()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Exec(Observer, 'rrp', 0, '');
        Exec(Observer, 'execute', 2, Params);
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'open;qc Cancel;close;');
        Observer.Expect('execute ok', 'Yes');
        Observer.Expect('execute error|text', '');
        Observer.Expect('execute error|code', '');
        Observer.Expect('execute log', 'pre plain= rec= arr1= arr2= txt2= item=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EmptyHandler')]
    procedure Run_EmptyHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Exec(Observer, 'run', 3, '');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run error|text', '');
        Observer.Expect('run error|code', '');
        Observer.Expect('run log', 'open;qc Cancel;close;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BindHandler(var RP: TestRequestPage "R6960 Bind")
    begin
        case HMode of
            0:
                begin
                    RP.PlainCtl.SetValue('P1');
                    RP.RecCtl.SetValue('R1');
                    RP.Arr1Ctl.SetValue('A1');
                    RP.Arr2Ctl.SetValue('A2');
                    RP.TxtCtl.SetValue('T2');
                    RP.ItemCtl.SetValue('I1');
                    RP.OK().Invoke();
                end;
            1:
                begin
                    Log.Add('h plain=' + RP.PlainCtl.Value() + ' rec=' + RP.RecCtl.Value() + ' arr1=' + RP.Arr1Ctl.Value() +
                        ' arr2=' + RP.Arr2Ctl.Value() + ' txt2=' + RP.TxtCtl.Value() + ' item=' + RP.ItemCtl.Value());
                    RP.OK().Invoke();
                end;
            2:
                RP.OK().Invoke();
            3:
                RP.Cancel().Invoke();
            4:
                Log.Add('h plain=' + RP.PlainCtl.Value());
        end;
    end;

    [RequestPageHandler]
    procedure EmptyHandler(var RP: TestRequestPage "R6960 Bind")
    begin
    end;
}
