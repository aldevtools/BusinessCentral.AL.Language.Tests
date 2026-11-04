// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 71770, SingleInstance log 71771 (used only by test codeunit 71775), subscribers 71772, pages 71773 and 71774, codeunit 71776
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a subscriber to OnBeforeActionEvent or OnAfterActionEvent of a page action that raises an error, when a TestPage invokes the action: does OnAction run, does the other event fire, what error does
// Invoke report (text and code), and can the action be invoked again. The same for an action with RunObject = Page and RunObject = Codeunit: do both events fire, and in what order relative to the opened page or codeunit.
// The no-error order of a plain action is in P114PageActionEvents.al.
// Measured: an error in the before subscriber of a plain action stops the action (OnAction and the after event do not run); an error in the after subscriber comes after OnAction ran; Invoke reports the
// subscriber's text with code TestWrapped:Dialog; with both failing only the before error is reported; the action can be invoked again. For an action with RunObject = Page neither event fires (the target
// opens and closes, the failing mode makes no difference). For RunObject = Codeunit only OnAfterActionEvent fires, after the codeunit ran, and an error in it reaches Invoke; the before event does not fire.
// BC versions: 27.0 to 29.0

table 71770 "LT PAS Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 71771 "LT PAS Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        FailMode: Text;

    procedure Reset(NewFailMode: Text)
    begin
        Clear(Lines);
        FailMode := NewFailMode;
    end;

    procedure SetFailMode(NewFailMode: Text)
    begin
        FailMode := NewFailMode;
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Fails(When: Text): Boolean
    begin
        exit((FailMode = When) or (FailMode = 'both'));
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

codeunit 71772 "LT PAS Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PAS Card", 'OnBeforeActionEvent', 'Act', false, false)]
    local procedure BeforeAct()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('before-Act');
        if Log.Fails('before') then
            Error('PS before-Act failed');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAS Card", 'OnAfterActionEvent', 'Act', false, false)]
    local procedure AfterAct()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('after-Act');
        if Log.Fails('after') then
            Error('PS after-Act failed');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAS Card", 'OnBeforeActionEvent', 'RunPg', false, false)]
    local procedure BeforeRunPg()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('before-RunPg');
        if Log.Fails('before') then
            Error('PS before-RunPg failed');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAS Card", 'OnAfterActionEvent', 'RunPg', false, false)]
    local procedure AfterRunPg()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('after-RunPg');
        if Log.Fails('after') then
            Error('PS after-RunPg failed');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAS Card", 'OnBeforeActionEvent', 'RunCu', false, false)]
    local procedure BeforeRunCu()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('before-RunCu');
        if Log.Fails('before') then
            Error('PS before-RunCu failed');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAS Card", 'OnAfterActionEvent', 'RunCu', false, false)]
    local procedure AfterRunCu()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('after-RunCu');
        if Log.Fails('after') then
            Error('PS after-RunCu failed');
    end;
}

codeunit 71776 "LT PAS Run"
{
    trigger OnRun()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('codeunit-OnRun');
    end;
}

page 71774 "LT PAS Target"
{
    PageType = Card;
    SourceTable = "LT PAS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('target-OnOpenPage');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('target-OnClosePage');
    end;
}

page 71773 "LT PAS Card"
{
    PageType = Card;
    SourceTable = "LT PAS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PAS Log";
                begin
                    Log.Add('OnAction-Act');
                end;
            }
            action(RunPg)
            {
                ApplicationArea = All;
                RunObject = Page "LT PAS Target";
            }
            action(RunCu)
            {
                ApplicationArea = All;
                RunObject = Codeunit "LT PAS Run";
            }
        }
    }
}

codeunit 71775 "LT Page Action Sub Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(FailMode: Text)
    var
        Row: Record "LT PAS Row";
        Log: Codeunit "LT PAS Log";
    begin
        Row.DeleteAll(false);
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Log.Reset(FailMode);
    end;

    [PageHandler]
    procedure TargetHandler(var Target: TestPage "LT PAS Target")
    var
        Log: Codeunit "LT PAS Log";
    begin
        Log.Add('handler');
    end;

    [Test]
    procedure Act_BeforeSubscriberRaises()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('before');
        Card.OpenEdit();
        Card.First();
        Log.Reset('before');
        asserterror Card.Act.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Dump());
        Log.Reset('');
        Card.Act.Invoke();
        Observer.Observe('log_second_invoke', Log.Dump());
        Observer.Expect('invoke|text', 'PS before-Act failed');
        Observer.Expect('invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('log', '[before-Act]');
        Observer.Expect('log_second_invoke', '[before-Act | OnAction-Act | after-Act]');
        Observer.Verify();
    end;

    [Test]
    procedure Act_AfterSubscriberRaises()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('after');
        Card.OpenEdit();
        Card.First();
        Log.Reset('after');
        asserterror Card.Act.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Dump());
        Log.Reset('');
        Card.Act.Invoke();
        Observer.Observe('log_second_invoke', Log.Dump());
        Observer.Expect('invoke|text', 'PS after-Act failed');
        Observer.Expect('invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('log', '[before-Act | OnAction-Act | after-Act]');
        Observer.Expect('log_second_invoke', '[before-Act | OnAction-Act | after-Act]');
        Observer.Verify();
    end;

    [Test]
    procedure Act_BothSubscribersRaise()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('both');
        Card.OpenEdit();
        Card.First();
        Log.Reset('both');
        asserterror Card.Act.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Dump());
        Observer.Expect('invoke|text', 'PS before-Act failed');
        Observer.Expect('invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('log', '[before-Act]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure RunPage_EventOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('');
        Card.OpenEdit();
        Card.First();
        Log.Reset('');
        Card.RunPg.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('log', '[target-OnOpenPage | handler | target-OnClosePage]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure RunPage_AfterSubscriberConfiguredToRaise()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('after');
        Card.OpenEdit();
        Card.First();
        Log.Reset('after');
        Card.RunPg.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', '[target-OnOpenPage | handler | target-OnClosePage]');
        Observer.Verify();
    end;

    [Test]
    procedure RunCodeunit_EventOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('');
        Card.OpenEdit();
        Card.First();
        Log.Reset('');
        Card.RunCu.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('log', '[codeunit-OnRun | after-RunCu]');
        Observer.Verify();
    end;

    [Test]
    procedure RunCodeunit_BeforeSubscriberConfiguredToRaise()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('before');
        Card.OpenEdit();
        Card.First();
        Log.Reset('before');
        Card.RunCu.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', '[codeunit-OnRun | after-RunCu]');
        Observer.Verify();
    end;

    [Test]
    procedure RunCodeunit_AfterSubscriberRaises()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAS Log";
        Card: TestPage "LT PAS Card";
    begin
        Seed('after');
        Card.OpenEdit();
        Card.First();
        Log.Reset('after');
        asserterror Card.RunCu.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Dump());
        Observer.Expect('invoke|text', 'PS after-RunCu failed');
        Observer.Expect('invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('log', '[codeunit-OnRun | after-RunCu]');
        Observer.Verify();
    end;
}
