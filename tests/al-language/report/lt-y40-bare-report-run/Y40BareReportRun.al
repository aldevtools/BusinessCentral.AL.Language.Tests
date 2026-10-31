// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); SingleInstance log 92721 is used only by test codeunit 92725
// Writer Y40 (2026-10-31): Report methods that RUN the report, called bare (no CurrReport., no variable) in the report's own
// procedure and trigger: a procedure that does UseRequestPage(false); RunModal(); exit(Found) (a processing-only report that runs
// itself to look for rows), bare Run(), a second call on the same variable, the bare RunModal() with the request page (handler typed
// on the report), a bare RunModal() inside OnPreReport while the report runs, and the bare RequestOptionsPage.Caption (get and set)
// on a variable never run and inside OnPreReport (CurrReport.RequestOptionsPage gives AL0161: must-not-compile case 2514). The getters and setters of the bare form
// (UseRequestPage, SetTableView, ObjectId, ...) are report/lt-y36-bare-report-member/Y36BareReportMember.al (writer Y36).
// BC versions: 27 - 29
table 92720 "LT Y40 BRR Row"
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

codeunit 92721 "LT Y40 BRR Log"
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

report 92722 "LT Y40 BRR Finder"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT Y40 BRR Row")
        {
            trigger OnPreDataItem()
            begin
                Log.Add('pre-item count=' + Format(Row.Count()) + ' note=' + Note);
            end;

            trigger OnAfterGetRecord()
            begin
                Found := true;
                Visited += 1;
            end;
        }
    }

    requestpage
    {
        Caption = 'LT Y40 Finder Options';

        layout
        {
            area(Content)
            {
                field(NoteCtl; Note)
                {
                    Caption = 'Note';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('rp-open');
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre caption=' + OptionsCaptionText());
        if RunInsidePreReport then begin
            RunInsidePreReport := false;
            if TryBareRunModal() then
                Log.Add('inner-ok')
            else
                Log.Add('inner-error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
    end;

    trigger OnPostReport()
    begin
        Log.Add('post visited=' + Format(Visited));
    end;

    var
        Log: Codeunit "LT Y40 BRR Log";
        Found: Boolean;
        Visited: Integer;
        Note: Text[30];
        RunInsidePreReport: Boolean;

    procedure FindRowsModal(): Boolean
    begin
        UseRequestPage(false);
        RunModal();
        exit(Found);
    end;

    procedure FindRowsRun(): Boolean
    begin
        UseRequestPage(false);
        Run();
        exit(Found);
    end;

    procedure RunModalWithPage()
    begin
        RunModal();
    end;

    procedure RunModalInsidePreReport()
    begin
        RunInsidePreReport := true;
        UseRequestPage(false);
        RunModal();
    end;

    procedure State(): Text
    begin
        exit('found=' + Format(Found) + ' visited=' + Format(Visited) + ' note=' + Note + ' userp=' + Format(UseRequestPage()));
    end;

    // Bare RequestOptionsPage (CurrReport.RequestOptionsPage does not compile: must-not-compile case 2514).
    procedure OptionsCaptionText(): Text
    begin
        exit(RequestOptionsPage.Caption);
    end;

    procedure SetOptionsCaption(NewCaption: Text)
    begin
        RequestOptionsPage.Caption := NewCaption;
    end;

    [TryFunction]
    local procedure TryBareRunModal()
    begin
        RunModal();
    end;
}

codeunit 92725 "LT Y40 BRR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y40 BRR Log";

    local procedure Seed(Count: Integer)
    var
        R: Record "LT Y40 BRR Row";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to Count do begin
            R.Id := I;
            R.Insert();
        end;
        Log.Take();
    end;

    [TryFunction]
    local procedure TryFindModal(var Rep: Report "LT Y40 BRR Finder"; var Found: Boolean)
    begin
        Found := Rep.FindRowsModal();
    end;

    local procedure FindModal(var Rep: Report "LT Y40 BRR Finder"): Text
    var
        Found: Boolean;
    begin
        ClearLastError();
        if TryFindModal(Rep, Found) then
            exit('ok found=' + Format(Found));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y40_BareRunModal_InProcedure_RowsExist()
    var
        Rep: Report "LT Y40 BRR Finder";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Observer.Observe('call', FindModal(Rep));
        Observer.Observe('log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [Test]
    procedure Y40_BareRunModal_InProcedure_NoRows()
    var
        Rep: Report "LT Y40 BRR Finder";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(0);
        Observer.Observe('call', FindModal(Rep));
        Observer.Observe('log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [Test]
    procedure Y40_BareRunModal_SecondCallOnSameVariable()
    var
        Rep: Report "LT Y40 BRR Finder";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Observer.Observe('first', FindModal(Rep));
        Observer.Observe('first_log', Log.Take());
        Observer.Observe('second', FindModal(Rep));
        Observer.Observe('second_log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [Test]
    procedure Y40_BareRun_InProcedure()
    var
        Rep: Report "LT Y40 BRR Finder";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Observer.Observe('found', Format(Rep.FindRowsRun()));
        Observer.Observe('log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [Test]
    procedure Y40_BareRunModal_AfterVariableSetTableView()
    var
        Rep: Report "LT Y40 BRR Finder";
        R: Record "LT Y40 BRR Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        R.SetRange(Id, 2);
        Rep.SetTableView(R);
        Observer.Observe('call', FindModal(Rep));
        Observer.Observe('log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('Y40FinderRequestPage')]
    procedure Y40_BareRunModal_WithRequestPage()
    var
        Rep: Report "LT Y40 BRR Finder";
        Observer: Codeunit "Probe Observer";
    begin
        // No write before the run: an uncommitted write before a run with a request page ends the run in an error before the page
        // opens (Y36BareReportMember.al, Y36_BareGetter_InsideRun_RequestWindow). The rows of the earlier tests of this codeunit stay.
        Log.Take();
        Rep.RunModalWithPage();
        Observer.Observe('log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOptionsCaption(var Rep: Report "LT Y40 BRR Finder"; var Caption: Text)
    begin
        Caption := Rep.OptionsCaptionText();
    end;

    [TryFunction]
    local procedure TrySetOptionsCaption(var Rep: Report "LT Y40 BRR Finder"; NewCaption: Text)
    begin
        Rep.SetOptionsCaption(NewCaption);
    end;

    [Test]
    procedure Y40_BareRequestOptionsPage_Caption()
    var
        Rep: Report "LT Y40 BRR Finder";
        Caption: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(1);
        ClearLastError();
        if TryOptionsCaption(Rep, Caption) then
            Observer.Observe('unrun_get', 'ok ' + Caption)
        else
            Observer.Observe('unrun_get', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TrySetOptionsCaption(Rep, 'Changed') then
            Observer.Observe('unrun_set', 'ok')
        else
            Observer.Observe('unrun_set', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryOptionsCaption(Rep, Caption) then
            Observer.Observe('unrun_get_after_set', 'ok ' + Caption)
        else
            Observer.Observe('unrun_get_after_set', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('run', FindModal(Rep));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y40_BareRunModal_InsidePreReport()
    var
        Rep: Report "LT Y40 BRR Finder";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(1);
        Rep.RunModalInsidePreReport();
        Observer.Observe('log', Log.Take());
        Observer.Observe('state', Rep.State());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure Y40FinderRequestPage(var RP: TestRequestPage "LT Y40 BRR Finder")
    begin
        Log.Add('handler note=' + RP.NoteCtl.Value());
        RP.NoteCtl.SetValue('from handler');
        RP.OK().Invoke();
    end;
}
