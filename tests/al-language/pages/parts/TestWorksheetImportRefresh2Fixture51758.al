// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51758 "PAG Refresh 2 Worksheet"
{
    PageType = Worksheet;
    SourceTable = "PAG Refresh 2 Row";
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
                field(ReadId; ReadId) { ApplicationArea = All; }
                field(CurrentId; CurrentId) { ApplicationArea = All; }
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
                    Row: Record "PAG Refresh 2 Row";
                begin
                    Row.Id := 'SEVEN';
                    Row.Batch := 'SELECTED';
                    Row.VisibleKind := true;
                    Row.Insert();
                    CurrPage.Update(false);
                end;
            }
            action(CheckImportedSelection)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Selected: Record "PAG Refresh 2 Row";
                begin
                    CurrPage.SetSelectionFilter(Selected);
                    if (Selected.Count() <> 1) or (Selected.GetRangeMin(Id) <> 'SEVEN') then
                        Error('Expected one selected import, got %1|%2', Selected.Count(), Selected.GetView(false));
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Batch := 'SELECTED';
        Rec.VisibleKind := true;
    end;

    trigger OnAfterGetRecord()
    begin
        ReadId := Rec.Id;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrentId := Rec.Id;
    end;

    var
        ReadId: Code[10];
        CurrentId: Code[10];

}
