// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page New Row Flt Child (60708), Test Page New Row Filters List (60709)

page 60709 "Test Page New Row Filters List"
{
    PageType = List;
    SourceTable = "Test Page New Row Flt Child";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ParentCode; Rec.ParentCode) { ApplicationArea = All; }
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
                field(Derived; Rec.Derived) { ApplicationArea = All; }
                field(Category; Rec.Category) { ApplicationArea = All; }
            }
        }
    }
}
