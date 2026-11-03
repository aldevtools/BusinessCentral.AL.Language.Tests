// Fixtures for TestReportOnInitReportTiming.al (codeunit 60006).
//
// "OIR Log" is SingleInstance, so what a report's triggers write into it outlives the report
// instance: NavReportHandle.Run drops its instance when the run returns, so a report global
// read AFTER Run() belongs to a new instance and says nothing about the run.

codeunit 60005 "OIR Log"
{
    SingleInstance = true;

    var
        InitCount: Integer;
        BodyCount: Integer;
        BodySaw: Text;

    procedure Reset()
    begin
        InitCount := 0;
        BodyCount := 0;
        BodySaw := '';
    end;

    procedure NoteInit()
    begin
        InitCount += 1;
    end;

    procedure NoteBody(Seen: Text)
    begin
        BodyCount += 1;
        BodySaw := Seen;
    end;

    procedure GetInitCount(): Integer
    begin
        exit(InitCount);
    end;

    procedure GetBodyCount(): Integer
    begin
        exit(BodyCount);
    end;

    procedure GetBodySaw(): Text
    begin
        exit(BodySaw);
    end;
}

// OnInitReport counts itself and seeds Setting; the one-row body records what Setting holds
// when it runs. SetSetting is how a caller writes Setting before Run().
report 60005 "OIR Init Probe"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(I; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                Log.NoteBody(Setting);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Log.NoteInit();
        Setting := 'from-oninitreport';
    end;

    procedure SetSetting(NewSetting: Text)
    begin
        Setting := NewSetting;
    end;

    var
        Log: Codeunit "OIR Log";
        Setting: Text;
}

// OnInitReport quits. Nothing after it may run.
report 60006 "OIR Quit Probe"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(I; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                Log.NoteBody('body-ran');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Log.NoteInit();
        CurrReport.Quit();
    end;

    trigger OnPreReport()
    begin
        Log.NoteBody('onprereport-ran');
    end;

    var
        Log: Codeunit "OIR Log";
}
