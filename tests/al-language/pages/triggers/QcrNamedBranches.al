// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained pages, log codeunit and test codeunit below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Modal card page whose named Result is assigned true on one branch only: 'if Flag then Result := true' and 'if not Flag then Result := true', each run with the flag true and false (both orders); RunModal answer, trace, error text and code, OK handler (and Cancel for one).
// BC versions: 29 (27 and 28 by CI)

page 71350 "LT QCR Named TrueIfFlag"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCR Named TrueIfFlag';

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
        Log: Codeunit "LT QCR Log C";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        if Log.Flag() then
            Result := true;
        Log.Add('flag=' + Format(Log.Flag()));
    end;

    trigger OnClosePage()
    begin
        Log.Add('C');
    end;
}

page 71351 "LT QCR Named TrueIfNot"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCR Named TrueIfNot';

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
        Log: Codeunit "LT QCR Log C";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action) Result: Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        if not Log.Flag() then
            Result := true;
        Log.Add('flag=' + Format(Log.Flag()));
    end;

    trigger OnClosePage()
    begin
        Log.Add('C');
    end;
}

codeunit 71352 "LT QCR Log C"
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

codeunit 71353 "LT QCR Branch Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QCR Log C";
        LookupFlag: Boolean;

    [TryFunction]
    local procedure TryLTQCRNamedTrueIfFlag(var Answer: Text)
    var
        Modal: Page "LT QCR Named TrueIfFlag";
    begin
        Modal.LookupMode(LookupFlag);
        Answer := Format(Modal.RunModal());
    end;

    [TryFunction]
    local procedure TryLTQCRNamedTrueIfNot(var Answer: Text)
    var
        Modal: Page "LT QCR Named TrueIfNot";
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
    [HandlerFunctions('LTQCRNamedTrueIfFlagOKHandler')]
    procedure OnQueryClosePage_NamedTrueIfFlagFlagTrueHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(true);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedTrueIfFlag(Answer);
        LookupFlag := false;
        Report('trueifflag_flagtrue', Ok, Answer, Observer);
        Observer.Expect('trueifflag_flagtrue_tryok', 'Yes');
        Observer.Expect('trueifflag_flagtrue_answer', 'OK');
        Observer.Expect('trueifflag_flagtrue_err', '');
        Observer.Expect('trueifflag_flagtrue_code', '');
        Observer.Expect('trueifflag_flagtrue_trace', 'Q:OK;flag=Yes;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedTrueIfFlagOKHandler')]
    procedure OnQueryClosePage_NamedTrueIfFlagFlagFalseHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedTrueIfFlag(Answer);
        LookupFlag := false;
        Report('trueifflag_flagfalse', Ok, Answer, Observer);
        Observer.Expect('trueifflag_flagfalse_tryok', 'Yes');
        Observer.Expect('trueifflag_flagfalse_answer', 'OK');
        Observer.Expect('trueifflag_flagfalse_err', '');
        Observer.Expect('trueifflag_flagfalse_code', '');
        Observer.Expect('trueifflag_flagfalse_trace', 'Q:OK;flag=No;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedTrueIfFlagCancelHandler')]
    procedure OnQueryClosePage_NamedTrueIfFlagFlagFalseHandlerCancel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := true;
        ClearLastError();
        Ok := TryLTQCRNamedTrueIfFlag(Answer);
        LookupFlag := false;
        Report('trueifflag_flagfalse_cancel', Ok, Answer, Observer);
        Observer.Expect('trueifflag_flagfalse_cancel_tryok', 'Yes');
        Observer.Expect('trueifflag_flagfalse_cancel_answer', 'LookupCancel');
        Observer.Expect('trueifflag_flagfalse_cancel_err', '');
        Observer.Expect('trueifflag_flagfalse_cancel_code', '');
        Observer.Expect('trueifflag_flagfalse_cancel_trace', 'Q:LookupCancel;flag=No;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedTrueIfNotOKHandler')]
    procedure OnQueryClosePage_NamedTrueIfNotFlagTrueHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(true);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedTrueIfNot(Answer);
        LookupFlag := false;
        Report('trueifnot_flagtrue', Ok, Answer, Observer);
        Observer.Expect('trueifnot_flagtrue_tryok', 'Yes');
        Observer.Expect('trueifnot_flagtrue_answer', 'OK');
        Observer.Expect('trueifnot_flagtrue_err', '');
        Observer.Expect('trueifnot_flagtrue_code', '');
        Observer.Expect('trueifnot_flagtrue_trace', 'Q:OK;flag=Yes;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedTrueIfNotOKHandler')]
    procedure OnQueryClosePage_NamedTrueIfNotFlagFalseHandlerOk_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := false;
        ClearLastError();
        Ok := TryLTQCRNamedTrueIfNot(Answer);
        LookupFlag := false;
        Report('trueifnot_flagfalse', Ok, Answer, Observer);
        Observer.Expect('trueifnot_flagfalse_tryok', 'Yes');
        Observer.Expect('trueifnot_flagfalse_answer', 'OK');
        Observer.Expect('trueifnot_flagfalse_err', '');
        Observer.Expect('trueifnot_flagfalse_code', '');
        Observer.Expect('trueifnot_flagfalse_trace', 'Q:OK;flag=No;C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LTQCRNamedTrueIfNotCancelHandler')]
    procedure OnQueryClosePage_NamedTrueIfNotFlagTrueHandlerCancel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(true);
        LookupFlag := true;
        ClearLastError();
        Ok := TryLTQCRNamedTrueIfNot(Answer);
        LookupFlag := false;
        Report('trueifnot_flagtrue_cancel', Ok, Answer, Observer);
        Observer.Expect('trueifnot_flagtrue_cancel_tryok', 'Yes');
        Observer.Expect('trueifnot_flagtrue_cancel_answer', 'LookupCancel');
        Observer.Expect('trueifnot_flagtrue_cancel_err', '');
        Observer.Expect('trueifnot_flagtrue_cancel_code', '');
        Observer.Expect('trueifnot_flagtrue_cancel_trace', 'Q:LookupCancel;flag=Yes;C;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedTrueIfFlagCancelHandler(var Modal: TestPage "LT QCR Named TrueIfFlag")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedTrueIfFlagOKHandler(var Modal: TestPage "LT QCR Named TrueIfFlag")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedTrueIfNotCancelHandler(var Modal: TestPage "LT QCR Named TrueIfNot")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRNamedTrueIfNotOKHandler(var Modal: TestPage "LT QCR Named TrueIfNot")
    begin
        Modal.OK().Invoke();
    end;
}
