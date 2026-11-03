// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Facts: a part page's OnOpenPage calls Confirm and no ConfirmHandler answers it: the host TestPage's OpenView fails with the
// unhandled-UI error of that Confirm (text and code below). The direct call is pinned in misc/lt-probes-needed-3/PnC09UnhandledUi.al.
// Measured: on Linux BC 27.5 (2026-10-19) OpenView fails with exactly the text and code asserted below. The Windows BC 28.4 container
// (CI run 36368565794) also failed OpenView with an "Unhandled UI: Confirm" error (that run checked only this prefix).
// Linux suspect: on the Linux BC 28.5 and 29.0 legs (2026-10-19) the host opens and nothing is raised ("An error was expected inside
// an ASSERTERROR statement."), which disagrees with Windows BC 28.4. Kept as source, not compiled, until the Windows nightly settles it.
// BC versions: 27.0 and later

#if LT_BH_LINUX_SUSPECT
table 81450 "LT BH Confirm Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 81450 "LT BH Confirm Part"
{
    PageType = CardPart;
    SourceTable = "LT BH Confirm Row";

    layout
    {
        area(Content)
        {
            field(PartCode; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        if Confirm('LT BH part asks') then;
    end;
}

page 81451 "LT BH Confirm Host"
{
    PageType = Card;
    SourceTable = "LT BH Confirm Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(HostCode; Rec."Code") { ApplicationArea = All; }
            part(ConfirmPart; "LT BH Confirm Part") { ApplicationArea = All; }
        }
    }
}

codeunit 81452 "LT BH Part Confirm Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure HostWithUnhandledConfirmInPart_OpenView_Fails()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT BH Confirm Host";
    begin
        asserterror Host.OpenView();
        Observer.ObserveError('openView');
        Observer.Expect('openView|text', 'Unhandled UI: Confirm LT BH part asks');
        Observer.Expect('openView|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}
#endif
