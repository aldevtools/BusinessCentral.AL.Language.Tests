// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51773 "Refresh Probe Worksheet"
{
    PageType = Worksheet;
    SourceTable = "Refresh Probe Row";
    SourceTableView = where(VisibleKind = const(true));
    DelayedInsert = true;
    SaveValues = true;
    InsertAllowed = false;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "Refresh Probe Row";
                begin
                    Row.Id := 'SEVEN';
                    Row.Batch := 'SELECTED';
                    Row.VisibleKind := true;
                    Row.Insert();
                    CurrPage.Update(false);
                end;
            }
            action(CheckSelection)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Selected: Record "Refresh Probe Row";
                begin
                    CurrPage.SetSelectionFilter(Selected);
                    if (Selected.Count() <> 0) or (Selected.GetRangeMin(Id) <> '') then
                        Error('Unexpected selection: %1|%2', Selected.Count(), Selected.GetView(false));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Batch, 'SELECTED');
        Rec.FilterGroup(0);
        if Rec.FindFirst() then;
    end;
}
