// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Spaced Action Row (60242), Spaced Action List (60243)
//
// A list page whose actions differ only in whether the action NAME contains spaces.
// SpacedStamp and "Spaced Stamp" deliberately coexist: a dispatcher that normalized
// names (e.g. stripped spaces) would collide them, so each writes a distinct stamp.
// The pageextensions contribute spaced-name actions to this page and to a precompiled
// Base App page, mirroring TestPageExtensionActionInvoke for the spaced case.

page 60243 "Spaced Action List"
{
    PageType = List;
    SourceTable = "Spaced Action Row";
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
            action(SpacedStamp)
            {
                ApplicationArea = All;
                Caption = 'Spaced Stamp (unspaced name)';

                trigger OnAction()
                var
                    Stamp: Record "Spaced Action Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'UNSPACED';
                    Stamp.Descr := Rec."No.";
                    Stamp.Insert();
                end;
            }

            action("Spaced Stamp")
            {
                ApplicationArea = All;
                Caption = 'Spaced Stamp';

                trigger OnAction()
                var
                    Stamp: Record "Spaced Action Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'SPACED';
                    Stamp.Descr := Rec."No.";
                    Stamp.Insert();
                end;
            }

            action("Always Fails Spaced")
            {
                ApplicationArea = All;
                Caption = 'Always Fails Spaced';

                trigger OnAction()
                begin
                    Error('Spaced Action List action refused deliberately');
                end;
            }
        }
    }
}

pageextension 60244 "Spaced Action List Ext" extends "Spaced Action List"
{
    actions
    {
        addlast(Processing)
        {
            action("Ext Spaced Stamp")
            {
                ApplicationArea = All;
                Caption = 'Ext Spaced Stamp';

                trigger OnAction()
                var
                    Stamp: Record "Spaced Action Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'EXTSPACED';
                    Stamp.Descr := Rec."No.";
                    Stamp.Insert();
                end;
            }
        }
    }
}

pageextension 60245 "Spaced Action Base Ext" extends "Item Attribute Values"
{
    actions
    {
        addlast(Processing)
        {
            action("Base Spaced Stamp")
            {
                ApplicationArea = All;
                Caption = 'Base Spaced Stamp';

                trigger OnAction()
                var
                    Stamp: Record "Spaced Action Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'BASESPACED';
                    Stamp.Descr := 'base app page';
                    Stamp.Insert();
                end;
            }
        }
    }
}
