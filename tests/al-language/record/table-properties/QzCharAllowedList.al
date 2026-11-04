// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-charallowed-property
// Scope: in-scope
// Fixture for the QZ_* test in codeunit "LT X Table Props Tests" (XTablePropsTests.al): page 87708 (an editable List over table "LT X Props").
// Facts: TestPage SetValue on a field with CharAllowed on a LIST page (the Card form is CharAllowed_TestPage_AllowedAndDisallowed).

page 87708 "LT QZ X Props List"
{
    PageType = List;
    SourceTable = "LT X Props";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Digits; Rec.Digits) { ApplicationArea = All; }
                field(Picky; Rec.Picky) { ApplicationArea = All; }
            }
        }
    }
}
