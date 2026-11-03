// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Test Page Action Row (60682), Test Page Action List (60683)
//
// A list page with page actions. StampRow writes what the page's CURRENT row is, so a
// test can tell "the trigger ran" apart from "the trigger ran in the page's context".

page 60683 "Test Page Action List"
{
    PageType = List;
    SourceTable = "Test Page Action Row";
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
                    Stamp: Record "Test Page Action Row";
                begin
                    if not Stamp.Get('STAMP') then begin
                        Stamp.Init();
                        Stamp."No." := 'STAMP';
                        Stamp.Descr := Rec."No.";
                        Stamp.Insert();
                    end else begin
                        Stamp.Descr := Rec."No.";
                        Stamp.Modify();
                    end;
                end;
            }

            action(StampOther)
            {
                ApplicationArea = All;
                Caption = 'Stamp Other';

                trigger OnAction()
                var
                    Stamp: Record "Test Page Action Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'OTHER';
                    Stamp.Descr := 'other ran';
                    Stamp.Insert();
                end;
            }

            action(AlwaysFails)
            {
                ApplicationArea = All;
                Caption = 'Always Fails';

                trigger OnAction()
                begin
                    Error('Test Page Action action refused deliberately');
                end;
            }
        }
    }
}
