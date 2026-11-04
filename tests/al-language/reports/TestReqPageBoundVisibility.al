// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: RPVB Flags (60009), RPVB Report (60008), RPVB Subscribers (60010),
//                Base Application reports 20 "Calc. and Post VAT Settlement",
//                296 "Batch Post Sales Orders" and 91 "Export Consolidation"
//
// TestRequestPage.<control>.Visible() and .Editable() answer the value of the REPORT GLOBAL
// the control's property is bound to, as the request page's triggers left it — in both
// directions. A runtime that answers the AL default (true) for a property it cannot evaluate
// passes every "is visible" assertion for the wrong reason, so each claim is pinned with the
// global false as well as true.
//
// Two shapes of report:
//   * report 60008, compiled with this app: a field bound directly, and a field whose
//     enclosing GROUP is bound;
//   * Base Application reports, which reach the test precompiled: report 20's VATDt field
//     (Visible = IsVATDateEnabled, set in OnInitReport) and report 296's VATDate field
//     (Visible = Editable = VATDateEnabled, set in the request page's OnOpenPage), and
//     report 91's "F&O Legal Entity ID", whose enclosing GROUP is Visible =
//     FOLegalEntityIDVisible, which OnInit and OnOpenPage leave false for the default file
//     format. Only the false direction is pinned there: reaching true needs the file-format
//     option set by caption, which is a separate surface.

codeunit 60008 "Req Page Bound Visibility"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenVisible: Boolean;
        SeenEditable: Boolean;
        HandlerRan: Boolean;

    local procedure Initialize()
    begin
        SeenVisible := false;
        SeenEditable := false;
        HandlerRan := false;
    end;

    [Test]
    [HandlerFunctions('BoundFieldHandler')]
    procedure OwnReport_VisibleBoundToFalseGlobal_IsHidden()
    var
        Flags: Codeunit "RPVB Flags";
    begin
        Initialize();
        Flags.Set(false, true, true);

        Report.Run(Report::"RPVB Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsFalse(SeenVisible, 'Visible bound to a false report global must answer false');
    end;

    [Test]
    [HandlerFunctions('BoundFieldHandler')]
    procedure OwnReport_EditableBoundToFalseGlobal_IsReadOnly()
    var
        Flags: Codeunit "RPVB Flags";
    begin
        Initialize();
        Flags.Set(true, false, true);

        Report.Run(Report::"RPVB Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsTrue(SeenVisible, 'Visible bound to a true report global must answer true');
        Assert.IsFalse(SeenEditable, 'Editable bound to a false report global must answer false');
    end;

    [Test]
    [HandlerFunctions('BoundFieldHandler')]
    procedure OwnReport_BothBoundToTrueGlobals_VisibleAndEditable()
    var
        Flags: Codeunit "RPVB Flags";
    begin
        Initialize();
        Flags.Set(true, true, true);

        Report.Run(Report::"RPVB Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsTrue(SeenVisible, 'Visible bound to a true report global must answer true');
        Assert.IsTrue(SeenEditable, 'Editable bound to a true report global must answer true');
    end;

    [Test]
    [HandlerFunctions('InGroupFieldHandler')]
    procedure OwnReport_GroupBoundToFalseGlobal_HidesItsField()
    var
        Flags: Codeunit "RPVB Flags";
    begin
        Initialize();
        Flags.Set(true, true, false);

        Report.Run(Report::"RPVB Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsFalse(SeenVisible, 'a field inside a group whose Visible is a false report global must answer false');
    end;

    [Test]
    [HandlerFunctions('InGroupFieldHandler')]
    procedure OwnReport_GroupBoundToTrueGlobal_ShowsItsField()
    var
        Flags: Codeunit "RPVB Flags";
    begin
        Initialize();
        Flags.Set(true, true, true);

        Report.Run(Report::"RPVB Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsTrue(SeenVisible, 'a field inside a group whose Visible is a true report global must answer true');
    end;

    [Test]
    [HandlerFunctions('VATSettlementHandler')]
    procedure BaseAppReport20_VATDateDisabled_VATDtIsHidden()
    var
        Subscribers: Codeunit "RPVB Subscribers";
    begin
        Initialize();
        Subscribers.SetVATDateEnabled(false);
        BindSubscription(Subscribers);

        Report.Run(Report::"Calc. and Post VAT Settlement");

        UnbindSubscription(Subscribers);
        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsFalse(SeenVisible, 'VATDt is bound to IsVATDateEnabled, which OnInitReport set to false');
    end;

    [Test]
    [HandlerFunctions('VATSettlementHandler')]
    procedure BaseAppReport20_VATDateEnabled_VATDtIsVisible()
    var
        Subscribers: Codeunit "RPVB Subscribers";
    begin
        Initialize();
        Subscribers.SetVATDateEnabled(true);
        BindSubscription(Subscribers);

        Report.Run(Report::"Calc. and Post VAT Settlement");

        UnbindSubscription(Subscribers);
        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsTrue(SeenVisible, 'VATDt is bound to IsVATDateEnabled, which OnInitReport set to true');
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrdersHandler')]
    procedure BaseAppReport296_VATDateEnabledLeftFalse_VATDateIsHiddenAndReadOnly()
    var
        Subscribers: Codeunit "RPVB Subscribers";
    begin
        Initialize();
        BindSubscription(Subscribers);

        Report.Run(Report::"Batch Post Sales Orders");

        UnbindSubscription(Subscribers);
        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsFalse(SeenVisible, 'VATDate.Visible is bound to VATDateEnabled, which OnOpenPage left false');
        Assert.IsFalse(SeenEditable, 'VATDate.Editable is bound to VATDateEnabled, which OnOpenPage left false');
    end;

    [Test]
    [HandlerFunctions('ExportConsolidationHandler')]
    procedure BaseAppReport91_GroupBoundToFalseGlobal_HidesItsField()
    begin
        Initialize();

        Report.Run(Report::"Export Consolidation");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsFalse(SeenVisible, '"F&O Legal Entity ID" sits in a group whose Visible is FOLegalEntityIDVisible, false for the default file format');
    end;

    [RequestPageHandler]
    procedure ExportConsolidationHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        HandlerRan := true;
        SeenVisible := RequestPage."F&O Legal Entity ID".Visible();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure BoundFieldHandler(var RequestPage: TestRequestPage "RPVB Report")
    begin
        HandlerRan := true;
        SeenVisible := RequestPage.BoundField.Visible();
        SeenEditable := RequestPage.BoundField.Editable();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InGroupFieldHandler(var RequestPage: TestRequestPage "RPVB Report")
    begin
        HandlerRan := true;
        SeenVisible := RequestPage.InGroupField.Visible();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure VATSettlementHandler(var RequestPage: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        HandlerRan := true;
        SeenVisible := RequestPage.VATDt.Visible();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure BatchPostSalesOrdersHandler(var RequestPage: TestRequestPage "Batch Post Sales Orders")
    begin
        HandlerRan := true;
        SeenVisible := RequestPage.VATDate.Visible();
        SeenEditable := RequestPage.VATDate.Editable();
        RequestPage.Cancel().Invoke();
    end;
}
