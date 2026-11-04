// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Host (60565), TRL Card (60566)
//
// Card over "TRL Host". ALL THREE controls are bare -- none declares trigger OnLookup(var Text:
// Text): Boolean -- because the suite's subject is what a lookup does when the ONLY thing
// available is the source table field's TableRelation. A control trigger on either field
// would take precedence and the suite would be measuring that instead.

page 60566 "TRL Card"
{
    PageType = Card;
    SourceTable = "TRL Host";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field("Related Code"; Rec."Related Code") { ApplicationArea = All; }
            field("Plain Code"; Rec."Plain Code") { ApplicationArea = All; }
            field("Pageless Code"; Rec."Pageless Code") { ApplicationArea = All; }
        }
    }
}
