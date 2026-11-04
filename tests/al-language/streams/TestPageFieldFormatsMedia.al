// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope
// Fixtures used: TPF Media Row (69933), TPF Media Card (69933)

table 69933 "TPF Media Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Pic; MediaSet) { }
        field(3; One; Media) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}

page 69933 "TPF Media Card"
{
    PageType = Card;
    SourceTable = "TPF Media Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPF Media Card';

    layout
    {
        area(Content)
        {
            field(PK; Rec.PK) { ApplicationArea = All; }
            field(Pic; Rec.Pic) { ApplicationArea = All; }
            field(One; Rec.One) { ApplicationArea = All; }
        }
    }
}
