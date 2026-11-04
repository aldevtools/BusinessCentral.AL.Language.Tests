// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Dec Line (60926), ASK Dec Lines (60927)
//
// The Decimal twin of "ASK Lines" (60918): AutoSplitKey = true and no numbering AL of its
// own. "Line No." is deliberately NOT a control, so any value it carries was assigned by
// the platform.

page 60927 "ASK Dec Lines"
{
    PageType = ListPart;
    SourceTable = "ASK Dec Line";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
