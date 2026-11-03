// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-caption-method
// Scope: in-scope
// Fixtures used: TP Caption Row (60992)
//
// Backing table for the TestPage.Caption() suite: a static Caption property vs. a
// CurrPage.Caption assigned at runtime from OnOpenPage.

table 60992 "TP Caption Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
