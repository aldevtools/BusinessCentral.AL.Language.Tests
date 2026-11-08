// Fixtures of al-runner issue 7288 (2026-11-08) for LT PnG Refresh (codeunit 70177): a list of thirty rows of ALT Shape 15 (Id 1 to 30, Grp R1 to R30) (more than the twenty rows
// of the client's first window) with OnAfterGetRecord and OnAfterGetCurrRecord and without OnFindRecord or OnNextRecord, whose actions
// put another stored row into Rec with Rec.Get and do not call CurrPage.Update. Logs go to LT PnG Log (table backed).

// local object: its own triggers (OnAfterGetRecord, OnAfterGetCurrRecord) and actions are under test.
page 86991 "LT BW List"
{
    PageType = List;
    SourceTable = "ALT Shape 15";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoF; Rec.Grp) { ApplicationArea = All; Editable = false; }
                field(CellF; CellText) { ApplicationArea = All; Caption = 'Cell'; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetRow2)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Get(2);
                    Log.Add('A:' + Rec.Grp + '/x=' + xRec.Grp);
                end;
            }
            action(GetRow24)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Get(24);
                    Log.Add('A:' + Rec.Grp + '/x=' + xRec.Grp);
                end;
            }
            action(GetRow28)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Get(28);
                    Log.Add('A:' + Rec.Grp + '/x=' + xRec.Grp);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";
        CellText: Text;

    trigger OnAfterGetRecord()
    begin
        CellText := 'cell of ' + Rec.Grp;
        Log.Add('G:' + Rec.Grp);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Grp + '/x=' + xRec.Grp);
    end;
}
