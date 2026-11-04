// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test Page GoToRecord Row (60695)
//
// Backing table for the TestPage under test. Deliberately trivial: a Code[20] primary key plus
// one text field, so GoToRecord's primary-key lookup has an unambiguous single-field key to
// match on.

table 60695 "Test Page GoToRecord Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; Descr; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
