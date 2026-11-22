// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-integer-record-fieldref-method
// Scope: in-scope. Page.Run and Page.RunModal with a Variant that holds no value (and one that holds an Integer) as the record, with page id 0 and with the id of a card page (no PageHandler: the run with a handler raised an uninitialized-variable error of the test host and was not measured).
// Fixtures used: Probe Observer (codeunit 69160); own table 77811 (FC Dots Row, from record/filters/FilterDotsOnlyTypes.al); own objects 77814-77815 (Page Run Unassigned Variant, FC Dots Card)
// Probe: from al-runner issue 8213, part 3 (Page.Run with an unassigned Variant). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: Page.Run and Page.RunModal with a Variant that holds no value raise the error NotInitialized, with page id 0 and with the id of a card page, and a Variant that holds an Integer raises Conversion; error texts as asserted.
// BC versions: 27, 28, 29

page 77815 "FC Dots Card"
{
    PageType = Card;
    SourceTable = "FC Dots Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
        }
    }
}

codeunit 77814 "Page Run Unassigned Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageRun_Zero_UnassignedVariant()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        asserterror Page.Run(0, V);
        Observer.ObserveError('run');
        Observer.Expect('run|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('run|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure PageRunModal_Zero_UnassignedVariant()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        asserterror Page.RunModal(0, V);
        Observer.ObserveError('runModal');
        Observer.Expect('runModal|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('runModal|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure PageRun_Zero_IntegerVariant()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := 5;
        asserterror Page.Run(0, V);
        Observer.ObserveError('run');
        Observer.Expect('run|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.');
        Observer.Expect('run|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure PageRun_Card_UnassignedVariant_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        asserterror Page.Run(Page::"FC Dots Card", V);
        Observer.ObserveError('run');
        Observer.Expect('run|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('run|code', 'NotInitialized');
        Observer.Verify();
    end;
}
