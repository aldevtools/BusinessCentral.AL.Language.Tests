// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained pages, log codeunit and test codeunit below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Modal card page whose named 'Result: Boolean' OnQueryClosePage (2) never assigns Result, (3) reads Result before any assignment (value read, then an if on it), (4) assigns Result := false and falls through: RunModal answer, trace of the trigger and OnClosePage, error text and code, for OK and Cancel handlers.
// BC versions: 29 (27 and 28 by CI)

page 71340 "LT QCR Named NoAssign"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCR Named NoAssign';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Log: Codeunit "LT QCR Log B";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        // Result is never assigned
    end;

    trigger OnClosePage()
    begin
        Log.Add('C');
    end;
}

page 71341 "LT QCR Named ReadFirst"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCR Named ReadFirst';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Log: Codeunit "LT QCR Log B";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        Log.Add('read=' + Format(Result));
        if Result then
            Log.Add('branch=true')
        else
            Log.Add('branch=false');
    end;

    trigger OnClosePage()
    begin
        Log.Add('C');
    end;
}

page 71342 "LT QCR Named FalseFall"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCR Named FalseFall';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Log: Codeunit "LT QCR Log B";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        Result := false;
        Log.Add('assigned=false');
    end;

    trigger OnClosePage()
    begin
        Log.Add('C');
    end;
}

codeunit 71343 "LT QCR Log B"
{
    SingleInstance = true;

    var
        Entries: Text;
        FlagValue: Boolean;

    procedure Reset(NewFlag: Boolean)
    begin
        Entries := '';
        FlagValue := NewFlag;
    end;

    procedure Flag(): Boolean
    begin
        exit(FlagValue);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Trace(): Text
    begin
        exit(Entries);
    end;
}

codeunit 71344 "LT QCR Named Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QCR Log B";
        LookupFlag: Boolean;

    [TryFunction]
    local procedure TryLTQCRNamedFalseFall(var Answer: Text)
    var
        Modal: Page "LT QCR Named FalseFall";
    begin
        Modal.LookupMode(LookupFlag);
        Answer := Format(Modal.RunModal());
    end;

    [TryFunction]
    local procedure TryLTQCRNamedNoAssign(var Answer: Text)
    var
        Modal: Page "LT QCR Named NoAssign";
    begin
        Modal.LookupMode(LookupFlag);
        Answer := Format(Modal.RunModal());
    end;

    [TryFunction]
    local procedure TryLTQCRNamedReadFirst(var Answer: Text)
    var
        Modal: Page "LT QCR Named ReadFirst";
    begin
        Modal.LookupMode(LookupFlag);
        Answer := Format(Modal.RunModal());
    end;

    local procedure Report(Name: Text; Ok: Boolean; Answer: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_tryok', Format(Ok));
        Observer.Observe(Name + '_answer', Answer);
        Observer.Observe(Name + '_err', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_trace', Log.Trace());
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedNoAssignOKHandler')]
    procedure OnQueryClosePage_NamedNeverAssignedHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedNoAssign(Answer);
        LookupFlag := false;
        Report('noassign_ok', Ok, Answer, Observer);
        Observer.Expect('noassign_ok_tryok', 'Yes');
        Observer.Expect('noassign_ok_answer', 'OK');
        Observer.Expect('noassign_ok_err', '');
        Observer.Expect('noassign_ok_code', '');
        Observer.Expect('noassign_ok_trace', 'Q:OK;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedNoAssignCancelHandler')]
    procedure OnQueryClosePage_NamedNeverAssignedHandlerCancel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := true;
        ClearLastError();
        Ok := TryLTQCRNamedNoAssign(Answer);
        LookupFlag := false;
        Report('noassign_cancel', Ok, Answer, Observer);
        Observer.Expect('noassign_cancel_tryok', 'Yes');
        Observer.Expect('noassign_cancel_answer', 'LookupCancel');
        Observer.Expect('noassign_cancel_err', '');
        Observer.Expect('noassign_cancel_code', '');
        Observer.Expect('noassign_cancel_trace', 'Q:LookupCancel;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedReadFirstOKHandler')]
    procedure OnQueryClosePage_NamedReadsResultFirstHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedReadFirst(Answer);
        LookupFlag := false;
        Report('readfirst_ok', Ok, Answer, Observer);
        Observer.Expect('readfirst_ok_tryok', 'Yes');
        Observer.Expect('readfirst_ok_answer', 'OK');
        Observer.Expect('readfirst_ok_err', '');
        Observer.Expect('readfirst_ok_code', '');
        Observer.Expect('readfirst_ok_trace', 'Q:OK;read=Yes;branch=true;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedReadFirstCancelHandler')]
    procedure OnQueryClosePage_NamedReadsResultFirstHandlerCancel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := true;
        ClearLastError();
        Ok := TryLTQCRNamedReadFirst(Answer);
        LookupFlag := false;
        Report('readfirst_cancel', Ok, Answer, Observer);
        Observer.Expect('readfirst_cancel_tryok', 'Yes');
        Observer.Expect('readfirst_cancel_answer', 'LookupCancel');
        Observer.Expect('readfirst_cancel_err', '');
        Observer.Expect('readfirst_cancel_code', '');
        Observer.Expect('readfirst_cancel_trace', 'Q:LookupCancel;read=Yes;branch=true;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedFalseFallOKHandler')]
    procedure OnQueryClosePage_NamedFalseThenFallThroughHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedFalseFall(Answer);
        LookupFlag := false;
        Report('false_ok', Ok, Answer, Observer);
        Observer.Expect('false_ok_tryok', 'Yes');
        Observer.Expect('false_ok_answer', 'None');
        Observer.Expect('false_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('false_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('false_ok_trace', 'Q:OK;assigned=false;Q:OK;assigned=false;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedFalseFallCancelHandler')]
    procedure OnQueryClosePage_NamedFalseThenFallThroughHandlerCancel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := true;
        ClearLastError();
        Ok := TryLTQCRNamedFalseFall(Answer);
        LookupFlag := false;
        Report('false_cancel', Ok, Answer, Observer);
        Observer.Expect('false_cancel_tryok', 'Yes');
        Observer.Expect('false_cancel_answer', 'None');
        Observer.Expect('false_cancel_err', 'The page cannot be closed at this time.');
        Observer.Expect('false_cancel_code', 'FormCloseNotAllowed');
        Observer.Expect('false_cancel_trace', 'Q:LookupCancel;assigned=false;Q:LookupCancel;assigned=false;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedFalseFallCancelHandler(var Modal: TestPage "LT QCR Named FalseFall")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedFalseFallOKHandler(var Modal: TestPage "LT QCR Named FalseFall")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedNoAssignCancelHandler(var Modal: TestPage "LT QCR Named NoAssign")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedNoAssignOKHandler(var Modal: TestPage "LT QCR Named NoAssign")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedReadFirstCancelHandler(var Modal: TestPage "LT QCR Named ReadFirst")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedReadFirstOKHandler(var Modal: TestPage "LT QCR Named ReadFirst")
    begin
        Modal.OK().Invoke();
    end;
}
