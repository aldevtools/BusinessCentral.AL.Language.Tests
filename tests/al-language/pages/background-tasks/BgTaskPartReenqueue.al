// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/developer-page-background-tasks
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 97920, log codeunit 97921, worker 97922, pages 97923-97924, test codeunit 97925
// Probe: al-runner issue 7576. A FactBox part that enqueues a page background task in its OnAfterGetCurrRecord, on a list host that a test opens
//   with OpenView and then moves with GoToRecord (the reported pages). session-system/isolated-storage/IsolatedStorageInBackgroundTask.al
//   (codeunits 75108 and 75114) saw one task outcome for OpenView followed by GoToRecord of the same row. This probe logs, per scenario, every
//   OnAfterGetCurrRecord of the part (with its row), every task the part enqueues, and every OnPageBackgroundTaskCompleted (with the row the task got):
//     GoToRecord of the row OpenView already shows; GoToRecord of another row; OpenView and Close only; Next; and GoToRecord of the same row twice.
//   The log is a SingleInstance codeunit of the test session (the Completed trigger runs in the test session: PbtChildSession.al).
// BC versions: 27 - 29

// local object: the rows the host and its part show
table 97920 "LT BPR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// local object: a log of the test session that the part's triggers write
codeunit 97921 "LT BPR Log"
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

// local object: the worker hands back the row it was given
codeunit 97922 "LT BPR Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        Params := Page.GetBackgroundParameters();
        Results.Add('Id', Params.Get('Id'));
        Page.SetBackgroundTaskResult(Results);
    end;
}

// local object: the part whose OnAfterGetCurrRecord enqueues the task is the subject
page 97923 "LT BPR Part"
{
    PageType = CardPart;
    SourceTable = "LT BPR Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    var
        TaskId: Integer;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT BPR Log";
        Parameters: Dictionary of [Text, Text];
    begin
        Log.Add('agcr ' + Format(Rec.Id));
        if Rec.Id = 0 then
            exit;
        Parameters.Add('Id', Format(Rec.Id));
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT BPR Worker", Parameters);
        Log.Add('enqueued ' + Format(Rec.Id));
    end;

    trigger OnPageBackgroundTaskCompleted(CompletedTaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "LT BPR Log";
    begin
        Log.Add('done ' + Results.Get('Id'));
    end;

    trigger OnPageBackgroundTaskError(ErrorTaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "LT BPR Log";
    begin
        Log.Add('error ' + ErrorCode);
        IsHandled := true;
    end;
}

// local object: the list host of the part (the reported page shape)
page 97924 "LT BPR Host"
{
    PageType = List;
    SourceTable = "LT BPR Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT BPR Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

codeunit 97925 "LT BPR Part Reenqueue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup(var RowA: Record "LT BPR Row"; var RowB: Record "LT BPR Row")
    var
        Log: Codeunit "LT BPR Log";
    begin
        RowA.DeleteAll();
        RowA.Init();
        RowA.Id := 1;
        RowA.Insert();
        RowB.Init();
        RowB.Id := 2;
        RowB.Insert();
        Commit();
        Log.Take();
    end;

    [Test]
    procedure GoToRecord_TheRowOpenViewShows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BPR Log";
        RowA: Record "LT BPR Row";
        RowB: Record "LT BPR Row";
        Host: TestPage "LT BPR Host";
    begin
        Setup(RowA, RowB);
        Host.OpenView();
        Observer.Observe('after OpenView', Log.Take());
        Host.GoToRecord(RowA);
        Observer.Observe('after GoToRecord', Log.Take());
        Host.Close();
        Observer.Observe('after Close', Log.Take());
        Observer.Expect('after OpenView', 'agcr 1;enqueued 1;done 1;');
        Observer.Expect('after GoToRecord', '');
        Observer.Expect('after Close', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToRecord_AnotherRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BPR Log";
        RowA: Record "LT BPR Row";
        RowB: Record "LT BPR Row";
        Host: TestPage "LT BPR Host";
    begin
        Setup(RowA, RowB);
        Host.OpenView();
        Observer.Observe('after OpenView', Log.Take());
        Host.GoToRecord(RowB);
        Observer.Observe('after GoToRecord', Log.Take());
        Host.Close();
        Observer.Observe('after Close', Log.Take());
        Observer.Expect('after OpenView', 'agcr 1;enqueued 1;done 1;');
        Observer.Expect('after GoToRecord', 'agcr 2;enqueued 2;done 2;');
        Observer.Expect('after Close', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BPR Log";
        RowA: Record "LT BPR Row";
        RowB: Record "LT BPR Row";
        Host: TestPage "LT BPR Host";
    begin
        Setup(RowA, RowB);
        Host.OpenView();
        Observer.Observe('after OpenView', Log.Take());
        Host.Close();
        Observer.Observe('after Close', Log.Take());
        Observer.Expect('after OpenView', 'agcr 1;enqueued 1;done 1;');
        Observer.Expect('after Close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Next_ToTheSecondRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BPR Log";
        RowA: Record "LT BPR Row";
        RowB: Record "LT BPR Row";
        Host: TestPage "LT BPR Host";
    begin
        Setup(RowA, RowB);
        Host.OpenView();
        Observer.Observe('after OpenView', Log.Take());
        Observer.Observe('Next', Format(Host.Next()));
        Observer.Observe('after Next', Log.Take());
        Host.Close();
        Observer.Observe('after Close', Log.Take());
        Observer.Expect('after OpenView', 'agcr 1;enqueued 1;done 1;');
        Observer.Expect('Next', 'Yes');
        Observer.Expect('after Next', 'agcr 2;enqueued 2;done 2;');
        Observer.Expect('after Close', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToRecord_TheSameRowTwice()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BPR Log";
        RowA: Record "LT BPR Row";
        RowB: Record "LT BPR Row";
        Host: TestPage "LT BPR Host";
    begin
        Setup(RowA, RowB);
        Host.OpenView();
        Host.GoToRecord(RowB);
        Observer.Observe('after OpenView and GoToRecord', Log.Take());
        Host.GoToRecord(RowB);
        Observer.Observe('after the second GoToRecord', Log.Take());
        Host.Close();
        Observer.Observe('after Close', Log.Take());
        Observer.Expect('after OpenView and GoToRecord', 'agcr 1;enqueued 1;done 1;agcr 2;enqueued 2;done 2;');
        Observer.Expect('after the second GoToRecord', '');
        Observer.Expect('after Close', '');
        Observer.Verify();
    end;
}
