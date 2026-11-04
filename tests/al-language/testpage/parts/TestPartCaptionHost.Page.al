// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-caption-method
// Scope: in-scope
// Fixtures used: ALT TestPart Lines (60342)
//
// A second host whose part control OVERRIDES the caption, hosting the SAME part page the
// default host hosts without one.
//
// This exists to settle where TestPart.Caption() reads from, which the default host alone
// cannot answer: there, the control has no caption, so control-sourced and page-sourced
// implementations agree. Here they must disagree -- the control says 'Control Level Caption'
// and the part page says 'Part Lines Caption' -- so the assertion picks exactly one.
//
// Ncl.dll settles the expected direction in advance: NavTestPageBase.ALCaption is
// `{ CheckPageOpened(); return TestPage.Caption; }`, reading the underlying page object and
// never the hosting control. The test pins that, and the pairing with the default host is
// what makes it a measurement rather than a restatement.

page 60345 "ALT TestPart Caption Host"
{
    PageType = Worksheet;
    Caption = 'Caption Host Page';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            part(Lines; "ALT TestPart Lines")
            {
                ApplicationArea = All;
                Caption = 'Control Level Caption';
            }
        }
    }
}
