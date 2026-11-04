// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Related (60563), TRL Related List (60564)
//
// The page "TRL Related".LookupPageId names. A TestPage lookup on a TRL Host field whose
// TableRelation points at "TRL Related" must open THIS page, and the suite's
// [ModalPageHandler] is declared for it.

page 60564 "TRL Related List"
{
    PageType = List;
    SourceTable = "TRL Related";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
