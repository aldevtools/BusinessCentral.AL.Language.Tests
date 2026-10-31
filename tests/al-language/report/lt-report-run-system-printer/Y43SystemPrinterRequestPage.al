// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 92854, reports 92855-92856 and SingleInstance log 92853 (used only by test codeunit 92857)
// Probe (writer Y43, gap cycle 4, G4-11): Report.Run / Report.RunModal(Id, RequestWindow, SystemPrinter = true, Rec) with a request page
//   shown (a processing-only report: OK, Cancel; a report with an RDLC layout: OK) and without one (a layout report with a ReportHandler and
//   with no handler). Each call runs after Commit() inside a TryFunction; observed: the outcome (ok, or the error text and code), which
//   triggers ran, the data item filters the request page set, the request page field, and the same call with SystemPrinter false.
//   Neighbours: ReportRunSystemPrinter.al (processing-only, no request page), misc/lt-y13-triage/Y13ReportSystemPrinter.al (UseSystemPrinter).
//   The SaveAsXml shape (needs files) is in tests/al-language-onprem/report/lt-y43-sp-saveasxml/.
// Probe: the SaaS route runs no UI handlers, so the values come from the corpus CI containers; other BC versions by the CI matrix.

codeunit 92853 "LT Y43 SP Log"
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

table 92854 "LT Y43 SP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

report 92855 "LT Y43 SP Proc"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(D; "LT Y43 SP Row")
        {
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            begin
                Log.Add('pre-di ' + D.GetFilters());
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + D."No.");
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FlagField; Flag) { ApplicationArea = All; Caption = 'Flag'; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('pre');
        Log.Add('flag ' + Format(Flag));
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT Y43 SP Log";
        Flag: Boolean;
}

report 92856 "LT Y43 SP Layout"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(D; "LT Y43 SP Row")
        {
            RequestFilterFields = "No.";
            column(NoCol; "No.") { }
            column(AmountCol; Amount) { }

            trigger OnPreDataItem()
            begin
                Log.Add('pre-di ' + D.GetFilters());
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + D."No.");
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FlagField; Flag) { ApplicationArea = All; Caption = 'Flag'; }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './LtY43SpLayout.rdl';
            Caption = 'Y43 SP layout';
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('pre');
        Log.Add('flag ' + Format(Flag));
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT Y43 SP Log";
        Flag: Boolean;
}

codeunit 92857 "LT Y43 SP Request Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y43 SP Log";

    local procedure Seed()
    var
        Row: Record "LT Y43 SP Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Amount := 1;
        Row.Insert();
        Row."No." := 'B';
        Row.Amount := 2;
        Row.Insert();
        Row."No." := 'C';
        Row.Amount := 3;
        Row.Insert();
        Commit();
        Log.Take();
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer; Modal: Boolean; RequestWindow: Boolean; SystemPrinter: Boolean)
    var
        Row: Record "LT Y43 SP Row";
    begin
        if Modal then
            Report.RunModal(ReportId, RequestWindow, SystemPrinter, Row)
        else
            Report.Run(ReportId, RequestWindow, SystemPrinter, Row);
    end;

    local procedure Outcome(ReportId: Integer; Modal: Boolean; RequestWindow: Boolean; SystemPrinter: Boolean): Text
    var
        Result: Text;
    begin
        Log.Take();
        ClearLastError();
        if TryRun(ReportId, Modal, RequestWindow, SystemPrinter) then
            Result := 'ok'
        else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        exit(Result + ' / ' + Log.Take());
    end;

    [RequestPageHandler]
    procedure RpOk(var Request: TestRequestPage "LT Y43 SP Proc")
    begin
        Log.Add('rp');
        Request.D.SetFilter("No.", 'A|B');
        Request.FlagField.SetValue(true);
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RpCancel(var Request: TestRequestPage "LT Y43 SP Proc")
    begin
        Log.Add('rp');
        Request.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure RlOk(var Request: TestRequestPage "LT Y43 SP Layout")
    begin
        Log.Add('rp');
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RlPrint(var Request: TestRequestPage "LT Y43 SP Layout")
    begin
        Log.Add('rp');
        Request.Print().Invoke();
    end;

    [RequestPageHandler]
    procedure RlPreview(var Request: TestRequestPage "LT Y43 SP Layout")
    begin
        Log.Add('rp');
        Request.Preview().Invoke();
    end;

    [ReportHandler]
    procedure RlReport(var R: Report "LT Y43 SP Layout")
    begin
        Log.Add('handler');
    end;

    [Test]
    [HandlerFunctions('RpOk')]
    procedure Y43_G411_ProcOnly_RunModal_ReqTrue_Sp_Ok()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Proc", true, true, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Proc", true, true, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RpOk')]
    procedure Y43_G411_ProcOnly_Run_ReqTrue_Sp_Ok()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Proc", false, true, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Proc", false, true, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RpCancel')]
    procedure Y43_G411_ProcOnly_RunModal_ReqTrue_Sp_Cancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Proc", true, true, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Proc", true, true, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RlOk')]
    procedure Y43_G411_Layout_Run_ReqTrue_Sp_Ok()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Layout", false, true, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Layout", false, true, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RlReport')]
    procedure Y43_G411_Layout_Run_ReqFalse_Sp_ReportHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Layout", false, false, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Layout", false, false, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G411_Layout_Run_ReqFalse_Sp_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Layout", false, false, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Layout", false, false, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RlPrint')]
    procedure Y43_G411_Layout_Run_ReqTrue_Sp_Print()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Layout", false, true, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Layout", false, true, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RlPreview')]
    procedure Y43_G411_Layout_Run_ReqTrue_Sp_Preview()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('systemPrinterTrue', Outcome(Report::"LT Y43 SP Layout", false, true, true));
        Observer.Observe('systemPrinterFalse', Outcome(Report::"LT Y43 SP Layout", false, true, false));
        Observer.Finish();
    end;
}
