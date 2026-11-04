// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-cancelbackgroundtask-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68800, codeunits 68801 (worker), 68802 (log), page
//                68803, codeunit 68804 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins CurrPage.CancelBackgroundTask under a TestPage (where a background task runs at once, see
// TestPageBgTask_Tests.al): the completion trigger has already run when EnqueueBackgroundTask returns, so a cancel
// right after it cannot stop it; CancelBackgroundTask answers true for the id of a task that was enqueued
// (also after it completed, and again on a second call), false for an id nobody enqueued (9999, or 0 before
// any enqueue); it raises no error.
// BC versions: 27.5

table 68800 "Probe Cancel Table"
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

codeunit 68801 "Probe Cancel Worker"
{
    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        Results.Add('R', 'done');
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 68802 "Probe Cancel Log"
{
    SingleInstance = true;

    var
        Mode: Integer;
        Log: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure CurrentMode(): Integer
    begin
        exit(Mode);
    end;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 68803 "Probe Cancel Page"
{
    PageType = Card;
    SourceTable = "Probe Cancel Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CancelAgain)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    CancelLog: Codeunit "Probe Cancel Log";
                begin
                    CancelLog.Add('cancel from the action=' + Format(CurrPage.CancelBackgroundTask(TaskId)));
                end;
            }
        }
    }

    var
        TaskId: Integer;

    trigger OnOpenPage()
    var
        CancelLog: Codeunit "Probe Cancel Log";
        Args: Dictionary of [Text, Text];
    begin
        case CancelLog.CurrentMode() of
            1:
                begin
                    CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"Probe Cancel Worker", Args, 5000);
                    CancelLog.Add('cancel right after enqueue=' + Format(CurrPage.CancelBackgroundTask(TaskId)));
                end;
            2:
                CancelLog.Add('cancel unknown id=' + Format(CurrPage.CancelBackgroundTask(9999)));
        end;
    end;

    trigger OnPageBackgroundTaskCompleted(CompletedTaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CancelLog: Codeunit "Probe Cancel Log";
    begin
        CancelLog.Add('completed');
    end;
}

codeunit 68804 "Probe Page Cancel Task"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CancelLog: Codeunit "Probe Cancel Log";

    local procedure Open(Mode: Integer; RunAction: Boolean): Text
    var
        CancelRec: Record "Probe Cancel Table";
        CancelPage: TestPage "Probe Cancel Page";
    begin
        CancelRec.DeleteAll();
        CancelRec.Id := 1;
        CancelRec.Insert();
        Commit();
        CancelLog.Take();
        CancelLog.SetMode(Mode);

        CancelPage.OpenView();
        if RunAction then
            CancelPage.CancelAgain.Invoke();
        CancelPage.Close();
        exit(CancelLog.Take());
    end;

    [Test]
    procedure Cancel_RightAfterEnqueue_ReturnsTrue_ButTheTaskHasCompleted()
    begin
        Assert.AreEqual('completed;cancel right after enqueue=Yes;', Open(1, false), 'log');
    end;

    [Test]
    procedure Cancel_AfterCompletion_ReturnsTrueAgain()
    begin
        Assert.AreEqual('completed;cancel right after enqueue=Yes;cancel from the action=Yes;', Open(1, true), 'log');
    end;

    [Test]
    procedure Cancel_OfAnIdNobodyEnqueued_ReturnsFalse()
    begin
        Assert.AreEqual('cancel unknown id=No;', Open(2, false), 'unknown id');
        Assert.AreEqual('cancel from the action=No;', Open(0, true), 'id 0 before any enqueue');
    end;
}
