// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Big Line (60923), ASK Big Lines (60924)
//
// The BigInteger twin of "ASK Lines" (60918): AutoSplitKey = true and no numbering AL of
// its own. "Line No." is deliberately NOT a control, so any value it carries was assigned
// by the platform.

page 60924 "ASK Big Lines"
{
    PageType = ListPart;
    SourceTable = "ASK Big Line";
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
