// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: TPXP Row (60725), TPXP List (60726), TPXP FactBox (60727), TPXP List Ext (60728)
//
// A list page with one action of its own AND an (empty) FactBoxes area, a CardPart page for
// a factbox, and a pageextension that adds BOTH a part() (via addfirst(FactBoxes)) AND two
// actions — the exact combination the pageextension-action-with-part suite pins: does adding
// a part() to a pageextension's layout change whether that SAME pageextension's actions
// still dispatch?

page 60726 "TPXP List"
{
    PageType = List;
    SourceTable = "TPXP Row";
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
        area(FactBoxes)
        {
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
                    Stamp: Record "TPXP Row";
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

page 60727 "TPXP FactBox"
{
    PageType = CardPart;
    SourceTable = "TPXP Row";
    Caption = 'TPXP FactBox';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 60728 "TPXP List Ext" extends "TPXP List"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part(TpxpFactBox; "TPXP FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(StampExtWithPart)
            {
                ApplicationArea = All;
                Caption = 'Stamp Ext With Part';

                trigger OnAction()
                var
                    Stamp: Record "TPXP Row";
                begin
                    if not Stamp.Get('STAMPEXTPART') then begin
                        Stamp.Init();
                        Stamp."No." := 'STAMPEXTPART';
                        Stamp.Descr := Rec."No.";
                        Stamp.Insert();
                    end else begin
                        Stamp.Descr := Rec."No.";
                        Stamp.Modify();
                    end;
                end;
            }

            action("Stamp Ext With Part Spaced")
            {
                ApplicationArea = All;
                Caption = 'Stamp Ext With Part Spaced';

                trigger OnAction()
                var
                    Stamp: Record "TPXP Row";
                begin
                    if not Stamp.Get('STAMPEXTPARTSPACED') then begin
                        Stamp.Init();
                        Stamp."No." := 'STAMPEXTPARTSPACED';
                        Stamp.Insert();
                    end;
                end;
            }
        }
    }
}
