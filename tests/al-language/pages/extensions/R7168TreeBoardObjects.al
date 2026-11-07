// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-showastree-property
// Scope: in-scope
// Fixtures used: Y28CollapsedTreeObjects.al (log codeunit 92271); tests in Y28CollapsedTreeTests.al (92279, procedures R7168_*)
// Probe: al-runner issue 7168 (FBakkensen). A Worksheet page over a temporary table, filled in OnOpenPage, with a tree repeater
//   (ShowAsTree, TreeInitialState = CollapseAll, IndentationColumn) and both row triggers. Two actions leave Rec on a child row the
//   collapsed page does not show (Rec.Get(2)): one ends with CurrPage.Update(false), the other does not.
// Rows: 1 WC1 (0), 2 MC1 (1), 3 MC2 (1), 4 WC2 (0), 5 MC3 (1).
// BC versions: 27, 28, 29

table 96070 "LT R7168 Tree Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Row ID"; Integer) { }
        field(2; "No."; Code[20]) { }
        field(3; Indentation; Integer) { }
    }

    keys
    {
        key(PK; "Row ID") { Clustered = true; }
    }
}

codeunit 96072 "LT R7168 Tree Fill"
{
    procedure Fill(var Row: Record "LT R7168 Tree Row" temporary)
    begin
        Row.DeleteAll();
        Add(Row, 1, 'WC1', 0);
        Add(Row, 2, 'MC1', 1);
        Add(Row, 3, 'MC2', 1);
        Add(Row, 4, 'WC2', 0);
        Add(Row, 5, 'MC3', 1);
    end;

    local procedure Add(var Row: Record "LT R7168 Tree Row" temporary; RowID: Integer; No: Code[20]; Indentation: Integer)
    begin
        Row.Init();
        Row."Row ID" := RowID;
        Row."No." := No;
        Row.Indentation := Indentation;
        Row.Insert();
    end;
}

page 96071 "LT R7168 Tree Board"
{
    PageType = Worksheet;
    SourceTable = "LT R7168 Tree Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                TreeInitialState = CollapseAll;
                IndentationColumn = Rec.Indentation;

                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(CellCtl; CellText) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetChild)
            {
                ApplicationArea = All;
                Caption = 'Get Child';

                trigger OnAction()
                begin
                    Log.Add('act-get=' + Format(Rec.Get(2)));
                end;
            }
            action(GetChildAndRefresh)
            {
                ApplicationArea = All;
                Caption = 'Get Child And Refresh';

                trigger OnAction()
                begin
                    Log.Add('act-get=' + Format(Rec.Get(2)));
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Fill: Codeunit "LT R7168 Tree Fill";
    begin
        Fill.Fill(Rec);
        if Rec.FindFirst() then;
        Log.Add('open n=' + Format(Rec.Count()) + ' cur=' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    begin
        CellText := 'cell of ' + Rec."No.";
        Log.Add('agr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsWorkCenterRow := Rec.Indentation = 0;
        Log.Add('agcr' + Rec."No.");
    end;

    var
        Log: Codeunit "LT Y28 Tree Log";
        CellText: Text;
        IsWorkCenterRow: Boolean;
}
