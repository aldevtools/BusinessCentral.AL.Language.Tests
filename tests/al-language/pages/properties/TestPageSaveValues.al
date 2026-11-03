// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: none beyond this file
//
// A page (not a request page) that declares SaveValues = true, driven by a test handler.
// Each test opens a page twice in one test. The first handler sets a field bound to a page
// global; the second reads the same field. What decides the second read is how the first
// open was closed:
//   - modal, closed with OK, SaveValues:     the second open shows the value
//   - modal, closed with OK, no SaveValues:  the second open shows the default
//   - modal, closed with Cancel, SaveValues: the second open shows the default
//   - non-modal Page.Run with a [PageHandler], SaveValues
//   - opened by the test itself (TestPage.OpenEdit) and closed with TestPage.Close(), SaveValues
// Every arm uses its own page, so no value another test saved can be what a second open shows.

page 67545 "PSV Saved Dialog"
{
    PageType = StandardDialog;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedTxt)
            {
                ApplicationArea = All;
                Caption = 'Remembered';
            }
        }
    }

    var
        RememberedTxt: Text[30];
}

page 67546 "PSV Unsaved Dialog"
{
    PageType = StandardDialog;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedTxt)
            {
                ApplicationArea = All;
                Caption = 'Remembered';
            }
        }
    }

    var
        RememberedTxt: Text[30];
}

page 67547 "PSV Cancelled Dialog"
{
    PageType = StandardDialog;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedTxt)
            {
                ApplicationArea = All;
                Caption = 'Remembered';
            }
        }
    }

    var
        RememberedTxt: Text[30];
}

page 67548 "PSV Saved Card"
{
    PageType = Card;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedTxt)
            {
                ApplicationArea = All;
                Caption = 'Remembered';
            }
        }
    }

    var
        RememberedTxt: Text[30];
}

page 67549 "PSV Test Opened Card"
{
    PageType = Card;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(Remembered; RememberedTxt)
            {
                ApplicationArea = All;
                Caption = 'Remembered';
            }
        }
    }

    var
        RememberedTxt: Text[30];
}

codeunit 67545 "Page SaveValues Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        SetValueTxt: Text;
        ReadValueTxt: Text;
        HandlerCalls: Integer;
        SetOnThisRun: Boolean;

    [Test]
    [HandlerFunctions('SavedDialogHandler')]
    procedure Modal_SaveValues_ClosedWithOK_NextOpenShowsTheValue()
    begin
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'psv-saved-67545';
        Page.RunModal(Page::"PSV Saved Dialog");

        SetOnThisRun := false;
        ReadValueTxt := '';
        Page.RunModal(Page::"PSV Saved Dialog");

        Assert.AreEqual(2, HandlerCalls, 'the [ModalPageHandler] should run once per open');
        Assert.AreEqual('psv-saved-67545', ReadValueTxt,
            'a SaveValues page closed with OK should reopen on the value it was closed with');
    end;

    [Test]
    [HandlerFunctions('UnsavedDialogHandler')]
    procedure Modal_NoSaveValues_ClosedWithOK_NextOpenShowsTheDefault()
    begin
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'psv-unsaved-67546';
        Page.RunModal(Page::"PSV Unsaved Dialog");

        SetOnThisRun := false;
        ReadValueTxt := 'not read';
        Page.RunModal(Page::"PSV Unsaved Dialog");

        Assert.AreEqual(2, HandlerCalls, 'the [ModalPageHandler] should run once per open');
        Assert.AreEqual('', ReadValueTxt,
            'a page without SaveValues should reopen on its default');
    end;

    [Test]
    [HandlerFunctions('CancelledDialogHandler')]
    procedure Modal_SaveValues_ClosedWithCancel_NextOpenShowsTheDefault()
    begin
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'psv-cancelled-67547';
        Page.RunModal(Page::"PSV Cancelled Dialog");

        SetOnThisRun := false;
        ReadValueTxt := 'not read';
        Page.RunModal(Page::"PSV Cancelled Dialog");

        Assert.AreEqual(2, HandlerCalls, 'the [ModalPageHandler] should run once per open');
        Assert.AreEqual('', ReadValueTxt,
            'a SaveValues page closed with Cancel should not save the value it was closed with');
    end;

    [Test]
    [HandlerFunctions('SavedCardHandler')]
    procedure NonModal_SaveValues_PageHandler_NextOpenShowsTheValue()
    begin
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'psv-card-67548';
        Page.Run(Page::"PSV Saved Card");

        SetOnThisRun := false;
        ReadValueTxt := '';
        Page.Run(Page::"PSV Saved Card");

        Assert.AreEqual(2, HandlerCalls, 'the [PageHandler] should run once per open');
        Assert.AreEqual('psv-card-67548', ReadValueTxt,
            'a SaveValues page run through a [PageHandler] should reopen on the value it was closed with');
    end;

    [Test]
    procedure TestOpened_SaveValues_ClosedWithClose_NextOpenShowsTheValue()
    var
        Card: TestPage "PSV Test Opened Card";
    begin
        // No handler: the test opens the page itself and closes it with TestPage.Close().
        Card.OpenEdit();
        Card.Remembered.SetValue('psv-test-opened-67549');
        Card.Close();

        Card.OpenEdit();
        ReadValueTxt := Card.Remembered.Value();
        Card.Close();

        Assert.AreEqual('psv-test-opened-67549', ReadValueTxt,
            'a SaveValues page the test opened and closed should reopen on the value it was closed with');
    end;

    [ModalPageHandler]
    procedure SavedDialogHandler(var Dialog: TestPage "PSV Saved Dialog")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            Dialog.Remembered.SetValue(SetValueTxt);
            Dialog.OK().Invoke();
        end else begin
            ReadValueTxt := Dialog.Remembered.Value();
            Dialog.Cancel().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure UnsavedDialogHandler(var Dialog: TestPage "PSV Unsaved Dialog")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            Dialog.Remembered.SetValue(SetValueTxt);
            Dialog.OK().Invoke();
        end else begin
            ReadValueTxt := Dialog.Remembered.Value();
            Dialog.Cancel().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure CancelledDialogHandler(var Dialog: TestPage "PSV Cancelled Dialog")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            Dialog.Remembered.SetValue(SetValueTxt);
            Dialog.Cancel().Invoke();
        end else begin
            ReadValueTxt := Dialog.Remembered.Value();
            Dialog.Cancel().Invoke();
        end;
    end;

    [PageHandler]
    procedure SavedCardHandler(var Card: TestPage "PSV Saved Card")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then
            Card.Remembered.SetValue(SetValueTxt)
        else
            ReadValueTxt := Card.Remembered.Value();
    end;
}
