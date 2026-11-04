// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-editable-method
// Scope: in-scope
// Fixtures used: none (both pages are source-table-less cards)
//
// Two cards that differ ONLY in their declared Editable, for the page-level TestPage.Editable()
// suite. Neither declares a SourceTable: the claim is about the PAGE's editability, and a
// rowset would only add a second thing that could explain a wrong answer.

page 60745 "Test Page Hdlr Editable RO"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Note; NoteValue) { ApplicationArea = All; }
        }
    }

    var
        NoteValue: Text[50];
}

// The control arm: identical but for the absent Editable property, which defaults to true.
page 60746 "Test Page Hdlr Editable RW"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            field(Note; NoteValue) { ApplicationArea = All; }
        }
    }

    var
        NoteValue: Text[50];
}
