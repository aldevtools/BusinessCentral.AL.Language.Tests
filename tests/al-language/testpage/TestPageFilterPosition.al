// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefiltertestpagefilter-setfilter-method
// Scope: in-scope
// Fixtures used: Test Page Filter Position Row (60692)
//
// Backing table for the TestPage filter/cursor-position suite.

table 60692 "Test Page Filter Position Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
