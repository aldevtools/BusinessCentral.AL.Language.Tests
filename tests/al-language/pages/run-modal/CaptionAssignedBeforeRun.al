// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own page 72460, log 72461, tests 72462
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Caption assigned through a page procedure on the Page variable before RunModal is read in OnOpenPage and in the handler; second run of the same variable with and without a new assignment.
// BC versions: 29 (27 and 28 by CI)

codeunit 72461 "LT CapOpen Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Wipe()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        if (Index < 1) or (Index > Lines.Count()) then
            exit('<none>');
        exit(Lines.Get(Index));
    end;
}

page 72460 "LT CapOpen Page"
{
    PageType = Card;
    Caption = 'LT Static Open Caption';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Dummy; DummyText) { ApplicationArea = All; }
            }
        }
    }

    var
        DummyText: Text;
        LTCapLog: Codeunit "LT CapOpen Log";

    procedure SetPageCaption(NewCaption: Text)
    begin
        CurrPage.Caption := NewCaption;
    end;

    trigger OnOpenPage()
    begin
        LTCapLog.Add('OnOpenPage [' + CurrPage.Caption + ']');
    end;
}

codeunit 72462 "LT CapOpen Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerCaptions: List of [Text];

    [ModalPageHandler]
    procedure CapHandler(var TP: TestPage "LT CapOpen Page")
    begin
        HandlerCaptions.Add(TP.Caption());
    end;

    local procedure Dump(var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT CapOpen Log";
        i: Integer;
    begin
        Observer.Observe('log-count', Format(Log.Count()));
        for i := 1 to Log.Count() do
            Observer.Observe('log-' + Format(i), Log.Get(i));
        Observer.Observe('handler-count', Format(HandlerCaptions.Count()));
        for i := 1 to HandlerCaptions.Count() do
            Observer.Observe('handler-' + Format(i), '[' + HandlerCaptions.Get(i) + ']');
    end;

    local procedure Reset()
    var
        Log: Codeunit "LT CapOpen Log";
    begin
        Log.Wipe();
        Clear(HandlerCaptions);
    end;

    [Test]
    [HandlerFunctions('CapHandler')]
    procedure P187_NoAssign_OpenPageAndHandler()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapOpen Page";
    begin
        Reset();
        Pg.RunModal();
        Dump(Observer);
        Observer.Expect('log-count', '1');
        Observer.Expect('log-1', 'OnOpenPage [LT Static Open Caption]');
        Observer.Expect('handler-count', '1');
        Observer.Expect('handler-1', '[LT Static Open Caption]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CapHandler')]
    procedure P187_AssignBeforeRun_OpenPageAndHandler()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapOpen Page";
    begin
        Reset();
        Pg.SetPageCaption('Assigned One');
        Pg.RunModal();
        Dump(Observer);
        Observer.Expect('log-count', '1');
        Observer.Expect('log-1', 'OnOpenPage [Assigned One]');
        Observer.Expect('handler-count', '1');
        Observer.Expect('handler-1', '[Assigned One]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CapHandler')]
    procedure P187_SecondRun_NoReassign()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapOpen Page";
    begin
        Reset();
        Pg.SetPageCaption('Assigned One');
        Pg.RunModal();
        Pg.RunModal();
        Dump(Observer);
        Observer.Expect('log-count', '2');
        Observer.Expect('log-1', 'OnOpenPage [Assigned One]');
        Observer.Expect('log-2', 'OnOpenPage [Assigned One]');
        Observer.Expect('handler-count', '2');
        Observer.Expect('handler-1', '[Assigned One]');
        Observer.Expect('handler-2', '[Assigned One]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CapHandler')]
    procedure P187_SecondRun_Reassigned()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapOpen Page";
    begin
        Reset();
        Pg.SetPageCaption('Assigned One');
        Pg.RunModal();
        Pg.SetPageCaption('Assigned Two');
        Pg.RunModal();
        Dump(Observer);
        Observer.Expect('log-count', '2');
        Observer.Expect('log-1', 'OnOpenPage [Assigned One]');
        Observer.Expect('log-2', 'OnOpenPage [Assigned Two]');
        Observer.Expect('handler-count', '2');
        Observer.Expect('handler-1', '[Assigned One]');
        Observer.Expect('handler-2', '[Assigned Two]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CapHandler')]
    procedure P187_AssignEmpty_BeforeRun()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT CapOpen Page";
    begin
        Reset();
        Pg.SetPageCaption('');
        Pg.RunModal();
        Dump(Observer);
        Observer.Expect('log-count', '1');
        Observer.Expect('log-1', 'OnOpenPage []');
        Observer.Expect('handler-count', '1');
        Observer.Expect('handler-1', '[]');
        Observer.Verify();
    end;
}
