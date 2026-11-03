// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
//
// The rowset both list pages in this suite are built over. Two fields is all the suite needs:
// a Code primary key so a descending SourceTableView has something to order by, and a text
// column a manual filter can narrow the set on.

table 60671 "ALT Page Find Record Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; Description; Text[30]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
