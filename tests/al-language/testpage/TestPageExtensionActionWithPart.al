// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: TPXP Row (60725)
//
// Backing table for the TestPage pageextension-action-with-part suite (companion to
// TestPageExtensionActionInvoke, which covers a pageextension-contributed action on a page
// with no part()). The two suites use SEPARATE tables/pages so this one's discriminator —
// the SAME pageextension also adding a part() to the page's layout — cannot be confused
// with the earlier, narrower #1923/#1966 fixture.

table 60725 "TPXP Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
