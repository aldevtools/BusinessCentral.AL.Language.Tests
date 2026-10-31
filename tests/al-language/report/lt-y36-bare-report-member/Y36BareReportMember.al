// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-userequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SingleInstance log 92379 is used only by test codeunit 92381
// Writer Y36 (gap cycle 3, C3-07): a Report method called bare (no CurrReport., no variable) inside the report's own procedures and
// triggers, and inside a report extension: UseRequestPage() getter and setter, ObjectId, IsReadOnly, Language, FormatRegion,
// PrintOnlyIfDetail, SetTableView. Called on a report variable that is never run, and during a run.
// Compile (alc 18.1 runtime 16.0, alc 30 runtime 18.0, same result): bare UseRequestPage(), UseRequestPage(false), ObjectId(false),
//   IsReadOnly(), Language(), FormatRegion(), PrintOnlyIfDetail(), SetTableView(Rec), Run(), RunModal(), Execute(''), RunRequestPage()
//   compile in a report and in a report extension. Bare Preview(), Skip(), Quit(), PageNo(), TotalsCausedBy(), ShowOutput(), NewPage(),
//   CreateTotals() give AL0161 "is inaccessible due to its protection level" (must-not-compile cases 2505 to 2509); Break() is the
//   loop statement, so `Break();` is a syntax error.
// BC versions: 29 (27 and 28 by CI)
table 92376 "LT Y36 BRM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92379 "LT Y36 BRM Log"
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

report 92377 "LT Y36 BRM A"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT Y36 BRM Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FlagCtl; Flag)
                {
                    ApplicationArea = All;
                    Caption = 'Flag';
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        LogBare('pre');
        L.Add('pre other ' + OtherBare());
    end;

    var
        Flag: Boolean;
        L: Codeunit "LT Y36 BRM Log";

    procedure GetUseRp(): Boolean
    begin
        exit(UseRequestPage());
    end;

    procedure SetUseRpFalse()
    begin
        UseRequestPage(false);
    end;

    procedure LogBare(Where: Text)
    begin
        L.Add(Where + ' bare=' + Format(UseRequestPage()) + ' curr=' + Format(CurrReport.UseRequestPage()));
    end;

    procedure OtherBare(): Text
    begin
        exit('objectid=' + Format(ObjectId(false) = CurrReport.ObjectId(false)) + ' ' + ObjectId(false) +
            ' readonly=' + Format(IsReadOnly()) + '/' + Format(CurrReport.IsReadOnly()) +
            ' language=' + Format(Language() = CurrReport.Language()) +
            ' region=' + Format(FormatRegion() = CurrReport.FormatRegion()) +
            ' onlyifdetail=' + Format(PrintOnlyIfDetail()) + '/' + Format(CurrReport.PrintOnlyIfDetail()));
    end;

    procedure SetViewBare(var R: Record "LT Y36 BRM Row")
    begin
        SetTableView(R);
    end;
}

report 92378 "LT Y36 BRM B"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT Y36 BRM Row")
        {
        }
    }

    trigger OnPreReport()
    begin
        L.Add('B pre bare=' + Format(UseRequestPage()) + ' curr=' + Format(CurrReport.UseRequestPage()));
    end;

    var
        L: Codeunit "LT Y36 BRM Log";

    procedure GetUseRp(): Boolean
    begin
        exit(UseRequestPage());
    end;
}

reportextension 92380 "LT Y36 BRM A Ext" extends "LT Y36 BRM A"
{
    procedure ExtGetUseRp(): Boolean
    begin
        exit(UseRequestPage());
    end;

    procedure ExtSetUseRpFalse()
    begin
        UseRequestPage(false);
    end;

    procedure ExtCurrUseRp(): Boolean
    begin
        exit(CurrReport.UseRequestPage());
    end;
}

codeunit 92381 "LT Y36 BRM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT Y36 BRM Log";

    local procedure Start()
    var
        R: Record "LT Y36 BRM Row";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 3 do begin
            R.Init();
            R.Id := I;
            R.Insert();
        end;
        L.Take();
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryRunA(var Rpt: Report "LT Y36 BRM A")
    begin
        Rpt.Run();
    end;

    [TryFunction]
    local procedure TryStaticRunA(RequestWindow: Boolean)
    begin
        Report.Run(Report::"LT Y36 BRM A", RequestWindow);
    end;

    [Test]
    procedure Y36_BareGetter_OnUnrunVariable()
    var
        Observer: Codeunit "Probe Observer";
        RptA: Report "LT Y36 BRM A";
        RptB: Report "LT Y36 BRM B";
    begin
        Start();
        Clear(RptA);
        Observer.Observe('bare_getter_unrun_A', Format(RptA.GetUseRp()));
        Observer.Observe('variable_getter_unrun_A', Format(RptA.UseRequestPage()));
        Clear(RptB);
        Observer.Observe('bare_getter_unrun_B', Format(RptB.GetUseRp()));
        Observer.Observe('variable_getter_unrun_B', Format(RptB.UseRequestPage()));
        Observer.Observe('ext_bare_getter_unrun_A', Format(RptA.ExtGetUseRp()));
        Observer.Observe('ext_curr_getter_unrun_A', Format(RptA.ExtCurrUseRp()));
        RptA.LogBare('unrun');
        Observer.Observe('log_unrun_A', L.Take());
        Observer.Observe('other_bare_unrun_A', RptA.OtherBare());
        Observer.Finish();
    end;

    [Test]
    procedure Y36_BareGetter_InsideRun_NoRequestWindow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('static_run_false', Format(TryStaticRunA(false)));
        Observer.Observe('static_run_false_error', GetLastErrorText());
        Observer.Observe('log_static_run_false', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y36RequestPageA')]
    procedure Y36_BareGetter_InsideRun_RequestWindow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT Y36 BRM A", true);
        Observer.Observe('log_static_run_true', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y36_BareSetter_ThenRun()
    var
        Observer: Codeunit "Probe Observer";
        RptA: Report "LT Y36 BRM A";
    begin
        Start();
        RptA.SetUseRpFalse();
        Observer.Observe('variable_getter_after_bare_setter', Format(RptA.UseRequestPage()));
        Observer.Observe('bare_getter_after_bare_setter', Format(RptA.GetUseRp()));
        Observer.Observe('run_after_bare_setter', Format(TryRunA(RptA)));
        Observer.Observe('run_after_bare_setter_error', GetLastErrorText());
        Observer.Observe('log_run_after_bare_setter', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y36_ExtBareSetter_ThenRun()
    var
        Observer: Codeunit "Probe Observer";
        RptA: Report "LT Y36 BRM A";
    begin
        Start();
        RptA.ExtSetUseRpFalse();
        Observer.Observe('variable_getter_after_ext_setter', Format(RptA.UseRequestPage()));
        Observer.Observe('ext_getter_after_ext_setter', Format(RptA.ExtGetUseRp()));
        Observer.Observe('run_after_ext_setter', Format(TryRunA(RptA)));
        Observer.Observe('run_after_ext_setter_error', GetLastErrorText());
        Observer.Observe('log_run_after_ext_setter', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y36_BareGetter_AfterVariableSetter()
    var
        Observer: Codeunit "Probe Observer";
        RptA: Report "LT Y36 BRM A";
        RptB: Report "LT Y36 BRM B";
    begin
        Start();
        RptA.UseRequestPage(false);
        Observer.Observe('A_bare_getter_after_variable_false', Format(RptA.GetUseRp()));
        RptA.UseRequestPage(true);
        Observer.Observe('A_bare_getter_after_variable_true', Format(RptA.GetUseRp()));
        RptB.UseRequestPage(true);
        Observer.Observe('B_bare_getter_after_variable_true', Format(RptB.GetUseRp()));
        RptB.UseRequestPage(false);
        Observer.Observe('B_bare_getter_after_variable_false', Format(RptB.GetUseRp()));
        Observer.Finish();
    end;

    [Test]
    procedure Y36_BareSetTableView_ThenRun()
    var
        Observer: Codeunit "Probe Observer";
        RptA: Report "LT Y36 BRM A";
        R: Record "LT Y36 BRM Row";
    begin
        Start();
        R.SetRange(Id, 2);
        RptA.SetViewBare(R);
        RptA.UseRequestPage(false);
        Observer.Observe('run_after_bare_settableview', Format(TryRunA(RptA)));
        Observer.Observe('log_run_after_bare_settableview', L.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure Y36RequestPageA(var RP: TestRequestPage "LT Y36 BRM A")
    begin
        L.Add('rp');
        RP.OK().Invoke();
    end;
}
