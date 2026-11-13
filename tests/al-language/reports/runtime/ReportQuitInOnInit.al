// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-quit-method
// Scope: in-scope. CurrReport.Quit() in OnInitReport of a processing-only report that has a request page (al-runner issue 7964, item 3),
//   followed by every way a caller can start the report: RunRequestPage on the variable and the static one (return value), Run and
//   RunModal with and without UseRequestPage(false), the static Report.Run with and without a request page, SaveAs (variable and static)
//   and Execute, and a second Run on the same variable. TestReportOnInitReportTiming.al already pins Run on a report without a request page.
// Fixtures used: Probe Observer (69160); self-contained table 71901, report 71900, codeunits 71899 (log, SingleInstance), 71902 (runs one
//   form through Codeunit.Run, so that an error is caught) and 71903 (the tests).
// Probe: written for al-runner issue 7964, observed on BC 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: run is the return value of Codeunit.Run of the form; error|text and error|code are GetLastErrorText and GetLastErrorCode after
//   a false run; result is what the form returned (the parameters text of RunRequestPage, the Boolean of SaveAs, the length of the
//   SaveAs output); log lists the report triggers that ran, in order.
// BC versions: 27, 28, 29

table 71901 "LT RqI Blob"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 71900 "LT RqI Quit Proc"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(I; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnPreDataItem()
            begin
                Log.Add('OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('OnAfterGetRecord');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OptionField; OptionValue)
                {
                    ApplicationArea = All;
                    Caption = 'Option value';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('RequestPage.OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('RequestPage.OnQueryClosePage');
            exit(true);
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('OnInitReport');
        CurrReport.Quit();
        Log.Add('after Quit');
    end;

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('OnPostReport');
    end;

    var
        Log: Codeunit "LT RqI Log";
        OptionValue: Text[30];
}

codeunit 71899 "LT RqI Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

codeunit 71902 "LT RqI Runner"
{
    var
        Mode: Integer;
        Result: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    trigger OnRun()
    var
        Rep: Report "LT RqI Quit Proc";
        Buf: Record "LT RqI Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        case Mode of
            1:
                Result := Rep.RunRequestPage();
            2:
                Result := Report.RunRequestPage(Report::"LT RqI Quit Proc");
            3:
                begin
                    Rep.UseRequestPage(false);
                    Rep.Run();
                end;
            4:
                Rep.Run();
            5:
                Report.Run(Report::"LT RqI Quit Proc");
            6:
                Report.Run(Report::"LT RqI Quit Proc", false);
            7:
                begin
                    Rep.UseRequestPage(false);
                    Rep.RunModal();
                end;
            8:
                Rep.RunModal();
            9:
                begin
                    Buf.Id := 1;
                    Buf.Insert();
                    Buf.Data.CreateOutStream(OutS);
                    Ok := Rep.SaveAs('', ReportFormat::Xml, OutS);
                    Buf.Modify();
                    Buf.CalcFields(Data);
                    Result := 'ok=' + Format(Ok) + ' length=' + Format(Buf.Data.Length());
                end;
            10:
                begin
                    Buf.Id := 1;
                    Buf.Insert();
                    Buf.Data.CreateOutStream(OutS);
                    Ok := Report.SaveAs(Report::"LT RqI Quit Proc", '', ReportFormat::Xml, OutS);
                    Buf.Modify();
                    Buf.CalcFields(Data);
                    Result := 'ok=' + Format(Ok) + ' length=' + Format(Buf.Data.Length());
                end;
            11:
                Report.Execute(Report::"LT RqI Quit Proc", '');
            12:
                begin
                    Rep.UseRequestPage(false);
                    Rep.Run();
                    Rep.Run();
                end;
            13:
                Result := Report.RunRequestPage(Report::"LT RqI Quit Proc", '');
        end;
    end;
}

codeunit 71903 "LT RqI Quit OnInit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RunForm(Mode: Integer)
    var
        Log: Codeunit "LT RqI Log";
        Runner: Codeunit "LT RqI Runner";
        Ok: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Runner.SetMode(Mode);
        Ok := Runner.Run();
        Observer.Observe('run', Format(Ok));
        if not Ok then
            Observer.ObserveError('error');
        Observer.Observe('result', Runner.GetResult());
        Observer.Observe('log', Log.Get());
    end;

    [Test]
    procedure Quit_ThenVarRunRequestPage()
    begin
        RunForm(1);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenStaticRunRequestPage()
    begin
        RunForm(2);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenStaticRunRequestPageWithParameters()
    begin
        RunForm(13);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenUseRequestPageFalseRun()
    begin
        RunForm(3);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenVarRunWithRequestPage()
    begin
        RunForm(4);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenStaticRunWithRequestPage()
    begin
        RunForm(5);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenStaticRunWithoutRequestPage()
    begin
        RunForm(6);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenUseRequestPageFalseRunModal()
    begin
        RunForm(7);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenVarRunModalWithRequestPage()
    begin
        RunForm(8);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenVarSaveAs()
    begin
        RunForm(9);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenStaticSaveAs()
    begin
        RunForm(10);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenStaticExecute()
    begin
        RunForm(11);
        Observer.Finish();
    end;

    [Test]
    procedure Quit_ThenRunTwiceOnOneVariable()
    begin
        RunForm(12);
        Observer.Finish();
    end;
}
