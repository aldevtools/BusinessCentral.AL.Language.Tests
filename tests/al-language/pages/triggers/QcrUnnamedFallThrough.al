// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained pages, log codeunit and test codeunit below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Modal card page whose unnamed ': Boolean' OnQueryClosePage logs and ends without exit: RunModal answer, whether the page closes (OnClosePage ran), error text and code, for a handler pressing OK and Cancel (LookupMode).
// BC versions: 29 (27 and 28 by CI)

page 71335 "LT QCR Unnamed"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCR Unnamed';

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
        Log: Codeunit "LT QCR Log A";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        // no exit: falls through
    end;

    trigger OnClosePage()
    begin
        Log.Add('C');
    end;
}

codeunit 71336 "LT QCR Log A"
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

codeunit 71337 "LT QCR Unnamed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QCR Log A";
        LookupFlag: Boolean;

    [TryFunction]
    local procedure TryLTQCRUnnamed(var Answer: Text)
    var
        Modal: Page "LT QCR Unnamed";
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
    [HandlerFunctions('LTQCRUnnamedCancelHandler')]
    procedure OnQueryClosePage_UnnamedFallThroughHandlerCancel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Text;
        Ok: Boolean;
    begin
        Log.Reset(false);
        LookupFlag := true;
        ClearLastError();
        Ok := TryLTQCRUnnamed(Answer);
        LookupFlag := false;
        Report('cancel', Ok, Answer, Observer);
        Observer.Expect('cancel_tryok', 'Yes');
        Observer.Expect('cancel_answer', 'LookupCancel');
        Observer.Expect('cancel_err', '');
        Observer.Expect('cancel_code', '');
        Observer.Expect('cancel_trace', 'Q:LookupCancel;C;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LTQCRUnnamedCancelHandler(var Modal: TestPage "LT QCR Unnamed")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LTQCRUnnamedOKHandler(var Modal: TestPage "LT QCR Unnamed")
    begin
        Modal.OK().Invoke();
    end;
}
