// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: none beyond this file — Base Application report 5707 "Batch Post Transfer Orders"
//                and its integration event OnCodeOnBeforePostTransferOrder
//
// A request page that declares SaveValues = true shows, on its next run, the values the user
// confirmed with OK on the previous one. A request page that does not declare it opens on its
// own defaults every time. This holds for a report compiled from this app's source and for one
// that ships precompiled in Base Application.
//
// Each test runs a report twice in one test. The first run's handler sets a request-page field
// and presses OK; the second run's handler reads the same field and presses Cancel.
//
// Report 5707 declares SaveValues = true on its request page, and its OnPostDataItem raises
//     OnCodeOnBeforePostTransferOrder(TransferHeader, TransferOrderPost, IsHandled)
// before posting anything. The probe subscriber records the option the report ran with and sets
// IsHandled, so nothing is posted. The Transfer Header filter matches no row.
codeunit 67540 "RPSV Probe"
{
    SingleInstance = true;

    var
        SeenOption: Enum "Transfer Order Post";
        Calls: Integer;
        LastRemembered: Text[30];

    procedure Reset()
    begin
        SeenOption := SeenOption::Ship;
        Calls := 0;
        LastRemembered := '';
    end;

    procedure GetSeenOption(): Enum "Transfer Order Post"
    begin
        exit(SeenOption);
    end;

    procedure GetCalls(): Integer
    begin
        exit(Calls);
    end;

    procedure RecordRemembered(Value: Text[30])
    begin
        Calls += 1;
        LastRemembered := Value;
    end;

    procedure GetRemembered(): Text[30]
    begin
        exit(LastRemembered);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Batch Post Transfer Orders", 'OnCodeOnBeforePostTransferOrder', '', false, false)]
    local procedure SkipPosting(var TransferHeader: Record "Transfer Header"; var TransferOrderPost: Enum "Transfer Order Post"; var IsHandled: Boolean)
    begin
        Calls += 1;
        SeenOption := TransferOrderPost;
        IsHandled := true;
    end;
}

report 67540 "RPSV Saved Options"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
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
    }

    trigger OnPreReport()
    var
        Probe: Codeunit "RPSV Probe";
    begin
        Probe.RecordRemembered(RememberedTxt);
    end;

    var
        RememberedTxt: Text[30];
}

report 67541 "RPSV Unsaved Options"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
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
    }

    trigger OnPreReport()
    var
        Probe: Codeunit "RPSV Probe";
    begin
        Probe.RecordRemembered(RememberedTxt);
    end;

    var
        RememberedTxt: Text[30];
}

// Its own report, so no value another test saved on 67540 can be what the second run shows.
report 67542 "RPSV Parameters Options"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
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
    }

    trigger OnPreReport()
    var
        Probe: Codeunit "RPSV Probe";
    begin
        Probe.RecordRemembered(RememberedTxt);
    end;

    var
        RememberedTxt: Text[30];
}

codeunit 67541 "Rpt RequestPage SaveValues"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Probe: Codeunit "RPSV Probe";
        SetValueTxt: Text;
        ReadValueTxt: Text;
        HandlerCalls: Integer;
        SetOnThisRun: Boolean;

    [Test]
    [HandlerFunctions('TransferOrdersRequestPage')]
    procedure PrecompiledReport_SaveValues_NextRunShowsTheConfirmedValue()
    var
        TransferHeader: Record "Transfer Header";
    begin
        Probe.Reset();
        HandlerCalls := 0;
        TransferHeader.SetRange("No.", 'RPSV-NO-SUCH-ORDER');

        // [WHEN] the first run confirms "Receive" (the enum default is "Ship")
        SetOnThisRun := true;
        SetValueTxt := Format("Transfer Order Post"::Receive);
        Report.RunModal(Report::"Batch Post Transfer Orders", true, false, TransferHeader);

        Assert.AreEqual(1, Probe.GetCalls(), 'the first run should reach OnCodeOnBeforePostTransferOrder once');
        Assert.AreEqual("Transfer Order Post"::Receive, Probe.GetSeenOption(), 'the first run should run with the value its handler set');

        // [THEN] the second run's request page opens on "Receive"
        SetOnThisRun := false;
        ReadValueTxt := '';
        Report.RunModal(Report::"Batch Post Transfer Orders", true, false, TransferHeader);

        Assert.AreEqual(2, HandlerCalls, 'the [RequestPageHandler] should run once per run');
        Assert.AreEqual(Format("Transfer Order Post"::Receive), ReadValueTxt,
            'a SaveValues request page should reopen on the value confirmed in the previous run');
    end;

    [Test]
    [HandlerFunctions('SavedOptionsRequestPage')]
    procedure SourceReport_SaveValues_NextRunShowsTheConfirmedValue()
    begin
        Probe.Reset();
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'rpsv-saved-67540';
        Report.RunModal(Report::"RPSV Saved Options", true, false);
        Assert.AreEqual('rpsv-saved-67540', Probe.GetRemembered(), 'the first run should run with the value its handler set');

        SetOnThisRun := false;
        ReadValueTxt := '';
        Report.RunModal(Report::"RPSV Saved Options", true, false);

        Assert.AreEqual(2, HandlerCalls, 'the [RequestPageHandler] should run once per run');
        Assert.AreEqual('rpsv-saved-67540', ReadValueTxt,
            'a SaveValues request page should reopen on the value confirmed in the previous run');
    end;

    [Test]
    [HandlerFunctions('UnsavedOptionsRequestPage')]
    procedure SourceReport_NoSaveValues_NextRunShowsTheDefault()
    begin
        Probe.Reset();
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'rpsv-unsaved-67541';
        Report.RunModal(Report::"RPSV Unsaved Options", true, false);
        Assert.AreEqual('rpsv-unsaved-67541', Probe.GetRemembered(), 'the first run should run with the value its handler set');

        SetOnThisRun := false;
        ReadValueTxt := 'not read';
        Report.RunModal(Report::"RPSV Unsaved Options", true, false);

        Assert.AreEqual(2, HandlerCalls, 'the [RequestPageHandler] should run once per run');
        Assert.AreEqual('', ReadValueTxt,
            'a request page without SaveValues should reopen on its default, not on the previous run''s value');
    end;

    [Test]
    [HandlerFunctions('SavedOptionsRequestPage')]
    procedure SourceReport_SaveValues_ReportVariable_NextRunShowsTheConfirmedValue()
    var
        FirstRun: Report "RPSV Saved Options";
        SecondRun: Report "RPSV Saved Options";
    begin
        // The same round trip as the by-id test above, through a report variable instead of
        // Report.RunModal(id).
        Probe.Reset();
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'rpsv-variable-67540';
        FirstRun.RunModal();
        Assert.AreEqual('rpsv-variable-67540', Probe.GetRemembered(), 'the first run should run with the value its handler set');

        SetOnThisRun := false;
        ReadValueTxt := '';
        SecondRun.RunModal();

        Assert.AreEqual(2, HandlerCalls, 'the [RequestPageHandler] should run once per run');
        Assert.AreEqual('rpsv-variable-67540', ReadValueTxt,
            'a SaveValues request page opened through a report variable should reopen on the value confirmed in the previous run');
    end;

    [Test]
    [HandlerFunctions('ParametersOptionsRequestPage')]
    procedure SourceReport_SaveValues_RunRequestPageReturnsTheValueWithoutSavingIt()
    var
        Parameters: Text;
    begin
        // Report.RunRequestPage hands back the request page's values, but confirming it is not a
        // run: the next run of the report still opens on the default.
        Probe.Reset();
        HandlerCalls := 0;

        SetOnThisRun := true;
        SetValueTxt := 'rpsv-parameters-67540';
        Parameters := Report.RunRequestPage(Report::"RPSV Parameters Options");
        Assert.IsTrue(Parameters.Contains('rpsv-parameters-67540'),
            'RunRequestPage should return the value its handler set, got: ' + Parameters);
        Assert.AreEqual(0, Probe.GetCalls(), 'RunRequestPage should not run the report');

        SetOnThisRun := false;
        ReadValueTxt := 'not read';
        Report.RunModal(Report::"RPSV Parameters Options", true, false);

        Assert.AreEqual(2, HandlerCalls, 'the [RequestPageHandler] should run once per call');
        Assert.AreEqual('', ReadValueTxt,
            'confirming Report.RunRequestPage should not save the value for the next run');
    end;

    [RequestPageHandler]
    procedure TransferOrdersRequestPage(var RequestPage: TestRequestPage "Batch Post Transfer Orders")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            RequestPage.TransferOption.SetValue(SetValueTxt);
            RequestPage.OK().Invoke();
        end else begin
            ReadValueTxt := RequestPage.TransferOption.Value();
            RequestPage.Cancel().Invoke();
        end;
    end;

    [RequestPageHandler]
    procedure SavedOptionsRequestPage(var RequestPage: TestRequestPage "RPSV Saved Options")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            RequestPage.Remembered.SetValue(SetValueTxt);
            RequestPage.OK().Invoke();
        end else begin
            ReadValueTxt := RequestPage.Remembered.Value();
            RequestPage.Cancel().Invoke();
        end;
    end;

    [RequestPageHandler]
    procedure ParametersOptionsRequestPage(var RequestPage: TestRequestPage "RPSV Parameters Options")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            RequestPage.Remembered.SetValue(SetValueTxt);
            RequestPage.OK().Invoke();
        end else begin
            ReadValueTxt := RequestPage.Remembered.Value();
            RequestPage.Cancel().Invoke();
        end;
    end;

    [RequestPageHandler]
    procedure UnsavedOptionsRequestPage(var RequestPage: TestRequestPage "RPSV Unsaved Options")
    begin
        HandlerCalls += 1;
        if SetOnThisRun then begin
            RequestPage.Remembered.SetValue(SetValueTxt);
            RequestPage.OK().Invoke();
        end else begin
            ReadValueTxt := RequestPage.Remembered.Value();
            RequestPage.Cancel().Invoke();
        end;
    end;
}
