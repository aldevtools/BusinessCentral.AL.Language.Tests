// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: TPX Row (60721), TPX List (60722), TPX List Ext (60723)
//
// A list page with ONE action declared directly on it, plus a pageextension adding TWO
// more. StampRow/StampExt write what the page's CURRENT row is, so a test can tell "the
// trigger ran" apart from "the trigger ran in the page's context" for BOTH an own-page
// action and a pageextension-contributed one.

page 60722 "TPX List"
{
    PageType = List;
    SourceTable = "TPX Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StampRow)
            {
                ApplicationArea = All;
                Caption = 'Stamp Row';

                trigger OnAction()
                var
                    Stamp: Record "TPX Row";
                begin
                    if not Stamp.Get('STAMP') then begin
                        Stamp.Init();
                        Stamp."No." := 'STAMP';
                        Stamp.Insert();
                    end;
                end;
            }
        }
    }
}

pageextension 60723 "TPX List Ext" extends "TPX List"
{
    actions
    {
        addlast(Processing)
        {
            action(StampExt)
            {
                ApplicationArea = All;
                Caption = 'Stamp Ext';

                trigger OnAction()
                var
                    Stamp: Record "TPX Row";
                begin
                    if not Stamp.Get('STAMPEXT') then begin
                        Stamp.Init();
                        Stamp."No." := 'STAMPEXT';
                        Stamp.Descr := Rec."No.";
                        Stamp.Insert();
                    end else begin
                        Stamp.Descr := Rec."No.";
                        Stamp.Modify();
                    end;
                end;
            }

            action(StampExtFails)
            {
                ApplicationArea = All;
                Caption = 'Stamp Ext Fails';

                trigger OnAction()
                begin
                    Error('TPX List Ext action refused deliberately');
                end;
            }
        }
    }
}
