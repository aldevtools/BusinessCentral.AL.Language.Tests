// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); page 74899, test codeunits 74899 (A) and 74898 (B)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a SaveValues = true page whose control-bound global and whose unbound global are set in a test of codeunit A. Is the value still there
//   (1) when the next test of the same codeunit opens the page, (2) after an asserterror in the same test, (3) when a test of codeunit B (declared and run
//   after A) opens the page, for a modal page closed with OK and with Cancel, and for a TestPage opened by the test.
//   Codeunit B only has the facts of the preceding codeunit A in a run that executes both (the order of the test codeunits is by id, A before B in that run).
// BC versions: all (CI)

page 74899 "LT SVX Dialog"
{
    PageType = StandardDialog;
    UsageCategory = None;
    ApplicationArea = All;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Bound; BoundTxt)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        BoundTxt: Text[30];
        UnboundTxt: Text[30];

    procedure SetUnbound(NewValue: Text)
    begin
        UnboundTxt := NewValue;
    end;

    procedure GetUnbound(): Text
    begin
        exit(UnboundTxt);
    end;

    procedure GetBound(): Text
    begin
        exit(BoundTxt);
    end;
}

codeunit 74899 "LT SVX A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CloseWithOk: Boolean;
        Mode: Text;
        SeenBound: Text;
        SeenUnbound: Text;

    [ModalPageHandler]
    procedure DialogHandler(var P: Page "LT SVX Dialog"; var Response: Action)
    begin
        SeenBound := P.GetBound();
        SeenUnbound := P.GetUnbound();
        if Mode = 'set' then
            P.SetUnbound('A-unbound');
        if CloseWithOk then
            Response := Action::OK
        else
            Response := Action::Cancel;
    end;

    [ModalPageHandler]
    procedure DialogTestPageHandler(var P: TestPage "LT SVX Dialog")
    begin
        SeenBound := P.Bound.Value();
        if Mode = 'set' then
            P.Bound.SetValue('A-bound');
        if CloseWithOk then
            P.OK().Invoke()
        else
            P.Cancel().Invoke();
    end;

    local procedure Open(NewMode: Text; Ok: Boolean)
    begin
        Mode := NewMode;
        CloseWithOk := Ok;
        SeenBound := '<not run>';
        SeenUnbound := '<not run>';
        Page.RunModal(Page::"LT SVX Dialog");
    end;

    [Test]
    [HandlerFunctions('DialogTestPageHandler')]
    procedure Dialog_SetBoundControlAndClose_Ok()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Open('read', true);
        Observer.Observe('firstOpen', SeenBound);
        Open('set', true);
        Open('read', true);
        Observer.Observe('reopenInSameTest', SeenBound);
        Observer.Expect('firstOpen', '');
        Observer.Expect('reopenInSameTest', 'A-bound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogTestPageHandler')]
    procedure Dialog_NextTestOfSameCodeunit_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Open('read', true);
        Observer.Observe('nextTest', SeenBound);
        Observer.Expect('nextTest', 'A-bound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogTestPageHandler')]
    procedure Dialog_AfterAsserterror_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Open('set', true);
        asserterror Error('rolled back');
        Open('read', true);
        Observer.Observe('afterRollback', SeenBound);
        Observer.Expect('afterRollback', 'A-bound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_UnboundGlobal_SetInHandler_Ok()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Open('read', true);
        Observer.Observe('unboundFirst', SeenUnbound);
        Open('set', true);
        Open('read', true);
        Observer.Observe('unboundReopen', SeenUnbound);
        Observer.Expect('unboundFirst', '');
        Observer.Expect('unboundReopen', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_UnboundGlobal_NextTest_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Open('read', true);
        Observer.Observe('unboundNextTest', SeenUnbound);
        Observer.Expect('unboundNextTest', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogTestPageHandler')]
    procedure Dialog_SetBoundControl_Cancel_NextOpenReads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Open('set', false);
        Open('read', false);
        Observer.Observe('afterCancel', SeenBound);
        Observer.Expect('afterCancel', 'A-bound');
        Observer.Verify();
    end;
}

codeunit 74898 "LT SVX B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Text;
        SeenBound: Text;
        SeenUnbound: Text;

    [ModalPageHandler]
    procedure DialogHandler(var P: Page "LT SVX Dialog"; var Response: Action)
    begin
        SeenBound := P.GetBound();
        SeenUnbound := P.GetUnbound();
        Response := Action::Cancel;
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure OtherCodeunit_Reads_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Page.RunModal(Page::"LT SVX Dialog");
        Observer.Observe('otherCodeunitBound', SeenBound);
        Observer.Observe('otherCodeunitUnbound', SeenUnbound);
        Observer.Expect('otherCodeunitBound', '');
        Observer.Expect('otherCodeunitUnbound', '');
        Observer.Verify();
    end;
}
