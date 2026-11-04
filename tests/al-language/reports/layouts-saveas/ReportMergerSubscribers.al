// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Helper (70835), LT RptMrg Sub One (70833), LT RptMrg Sub Two (70834), LT RptMrg Order Log (70832, used by this codeunit only),
// LT RptMrg Capture (70831), Report Layout ByName Capture (60532, always bound, handles every call with 'RLB-RENDERED'), report 70883
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// order (bind order, reverse bind order), does a later one see IsHandled already true, what ends up in the output stream, and after UnbindSubscription.
// Item 4 (no subscriber, or none that handles) cannot be isolated here: the static subscriber 60532 of the same app handles every call, so a test only sees its result.
// Whether 60532 ran is observed through its captured template (cleared first).
// BC versions: 29 (the final facts get added later)

codeunit 70844 "LT RptMrg Subscribers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Save(var Observer: Codeunit "Probe Observer")
    var
        Helper: Codeunit "LT RptMrg Helper";
        ByName: Codeunit "Report Layout ByName Capture";
        Log: Codeunit "LT RptMrg Order Log";
        Output: Text;
        Saved: Boolean;
        Completed: Boolean;
    begin
        ClearLastError();
        ByName.ClearCapture();
        Completed := Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved);
        Observer.Observe('try completed', Format(Completed));
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 200));
        Observer.Observe('output', Output);
        Observer.Observe('log calls', Format(Log.Calls()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('static 60532 template', ByName.CapturedTemplate());
    end;

    local procedure Start()
    var
        Helper: Codeunit "LT RptMrg Helper";
        Log: Codeunit "LT RptMrg Order Log";
    begin
        Helper.SeedRows(1);
        Log.Reset();
    end;

    [Test]
    procedure TwoSubscribers_NeitherHandles_BindOneThenTwo()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
        Two: Codeunit "LT RptMrg Sub Two";
    begin
        Start();
        BindSubscription(One);
        BindSubscription(Two);
        Save(Observer);
        UnbindSubscription(One);
        UnbindSubscription(Two);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDERED');
        Observer.Expect('log calls', '2');
        Observer.Expect('log', 'One call 1 entry IsHandled=Yes ; Two call 2 entry IsHandled=Yes');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_NeitherHandles_BindTwoThenOne()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
        Two: Codeunit "LT RptMrg Sub Two";
    begin
        Start();
        BindSubscription(Two);
        BindSubscription(One);
        Save(Observer);
        UnbindSubscription(One);
        UnbindSubscription(Two);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDERED');
        Observer.Expect('log calls', '2');
        Observer.Expect('log', 'One call 1 entry IsHandled=Yes ; Two call 2 entry IsHandled=Yes');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_FirstBoundHandles_SecondStillCalled()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
        Two: Codeunit "LT RptMrg Sub Two";
    begin
        Start();
        One.SetHandle(true);
        BindSubscription(One);
        BindSubscription(Two);
        Save(Observer);
        UnbindSubscription(One);
        UnbindSubscription(Two);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDOUT-ONE');
        Observer.Expect('log calls', '2');
        Observer.Expect('log', 'One call 1 entry IsHandled=Yes ; Two call 2 entry IsHandled=Yes');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_SecondBoundHandles_FirstSeesIsHandled()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
        Two: Codeunit "LT RptMrg Sub Two";
    begin
        Start();
        Two.SetHandle(true);
        BindSubscription(One);
        BindSubscription(Two);
        Save(Observer);
        UnbindSubscription(One);
        UnbindSubscription(Two);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDOUT-TWO');
        Observer.Expect('log calls', '2');
        Observer.Expect('log', 'One call 1 entry IsHandled=Yes ; Two call 2 entry IsHandled=Yes');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_BothHandle_OutputStream()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
        Two: Codeunit "LT RptMrg Sub Two";
    begin
        Start();
        One.SetHandle(true);
        Two.SetHandle(true);
        BindSubscription(One);
        BindSubscription(Two);
        Save(Observer);
        UnbindSubscription(One);
        UnbindSubscription(Two);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDOUT-ONEOUT-TWO');
        Observer.Expect('log calls', '2');
        Observer.Expect('log', 'One call 1 entry IsHandled=Yes ; Two call 2 entry IsHandled=Yes');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure OneSubscriber_LeavesIsHandledFalse_OutputStream()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
    begin
        Start();
        BindSubscription(One);
        Save(Observer);
        UnbindSubscription(One);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDERED');
        Observer.Expect('log calls', '1');
        Observer.Expect('log', 'One call 1 entry IsHandled=Yes');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure OneSubscriber_Unbound_NotCalled()
    var
        Observer: Codeunit "Probe Observer";
        One: Codeunit "LT RptMrg Sub One";
    begin
        Start();
        BindSubscription(One);
        UnbindSubscription(One);
        Save(Observer);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDERED');
        Observer.Expect('log calls', '0');
        Observer.Expect('log', '');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure NoManualSubscriber_OnlyStaticOne_OutputStream()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Save(Observer);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDERED');
        Observer.Expect('log calls', '0');
        Observer.Expect('log', '');
        Observer.Expect('static 60532 template', 'LMC-LAYOUT-A-BODY');
        Observer.Verify();
    end;

    [Test]
    procedure CaptureAndSubscriber_CaptureBoundFirst_SeesEntryState()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Two: Codeunit "LT RptMrg Sub Two";
        Log: Codeunit "LT RptMrg Order Log";
        Output: Text;
        Saved: Boolean;
    begin
        Start();
        BindSubscription(Cap);
        BindSubscription(Two);
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        UnbindSubscription(Cap);
        UnbindSubscription(Two);
        Observer.Observe('output', Output);
        Observer.Observe('capture calls', Format(Cap.CallCount()));
        Observer.Observe('capture entry IsHandled', Cap.Item('entry handled', 1));
        Observer.Observe('log', Log.Joined());
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('capture calls', '1');
        Observer.Expect('capture entry IsHandled', 'Yes');
        Observer.Expect('log', 'Two call 1 entry IsHandled=Yes');
        Observer.Verify();
    end;
}
