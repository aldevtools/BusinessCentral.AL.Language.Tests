// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90397 - 90401, 90404 (writer UJ)
// Probe: the OnPageBackgroundTaskCompleted and OnPageBackgroundTaskError triggers of a page extension in a TestPage session. Modes (chosen in
//   the log codeunit): 0 only the base page enqueues a task; 1 base and extension both enqueue; 2 only the extension enqueues; 3 the base page
//   enqueues a task whose worker raises an error; 4 only the extension enqueues a failing task. Per mode the log lists enqueue calls, the
//   completed triggers (base, then extension, in the order they run) with the task's result and whether the task id is set, and the error
//   triggers with the error text and the value of IsHandled each trigger sees; and whether OpenView has returned when they ran.
// Source: al-runner issue 6182 (Microsoft's page extension "User Card Perf. Factboxes" on User Card; TestPage "User Card" is refused).
// BC versions: 27, 28, 29

table 90397 "LT UJ Bg Row"
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

codeunit 90398 "LT UJ Bg Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Who: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('who', Who);
        if Who.EndsWith('-fail') then
            Error('worker failed for %1', Who);
        Results.Add('who', Who);
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 90399 "LT UJ Bg Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentMode: Integer;

    procedure Start(NewMode: Integer)
    begin
        Entries := '';
        CurrentMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(CurrentMode);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 90400 "LT UJ Bg Base"
{
    PageType = Card;
    SourceTable = "LT UJ Bg Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT UJ Bg Log";
        Args: Dictionary of [Text, Text];
        TaskId: Integer;
    begin
        if Log.Mode() in [0, 1, 3] then begin
            if Log.Mode() = 3 then
                Args.Add('who', 'base-fail')
            else
                Args.Add('who', 'base');
            CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT UJ Bg Worker", Args, 10000);
            Log.Add('base enqueue');
        end;
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "LT UJ Bg Log";
        Who: Text;
    begin
        Results.Get('who', Who);
        Log.Add('base completed ' + Who + ' id set=' + Format(TaskId <> 0));
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "LT UJ Bg Log";
    begin
        Log.Add('base error [' + ErrorText + '] handled=' + Format(IsHandled));
    end;
}

pageextension 90401 "LT UJ Bg Ext" extends "LT UJ Bg Base"
{
    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT UJ Bg Log";
        Args: Dictionary of [Text, Text];
        TaskId: Integer;
    begin
        if Log.Mode() in [1, 2, 4] then begin
            if Log.Mode() = 4 then
                Args.Add('who', 'ext-fail')
            else
                Args.Add('who', 'ext');
            CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT UJ Bg Worker", Args, 10000);
            Log.Add('ext enqueue');
        end;
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "LT UJ Bg Log";
        Who: Text;
    begin
        Results.Get('who', Who);
        Log.Add('ext completed ' + Who + ' id set=' + Format(TaskId <> 0));
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "LT UJ Bg Log";
    begin
        Log.Add('ext error [' + ErrorText + '] handled=' + Format(IsHandled));
    end;
}

codeunit 90404 "LT UJ Page Ext Bg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RunMode(Mode: Integer; Name: Text)
    var
        Row: Record "LT UJ Bg Row";
        Log: Codeunit "LT UJ Bg Log";
        Card: TestPage "LT UJ Bg Base";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Start(Mode);
        Card.OpenView();
        Log.Add('opened');
        Observer.Observe(Name, Log.Take());
        Card.Close();
        Log.Take();
    end;

    [Test]
    procedure UJ_PageExt_BgTask_Completed()
    begin
        RunMode(0, 'mode 0 base enqueues');
        RunMode(1, 'mode 1 both enqueue');
        RunMode(2, 'mode 2 extension enqueues');
        Observer.Finish();
    end;

    [Test]
    procedure UJ_PageExt_BgTask_Error()
    begin
        RunMode(3, 'mode 3 base enqueues failing task');
        RunMode(4, 'mode 4 extension enqueues failing task');
        Observer.Finish();
    end;
}
