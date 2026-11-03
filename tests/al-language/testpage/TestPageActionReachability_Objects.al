// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testaction/testaction-invoke-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: TPAR Row (60581), TPAR Host (60582)
//
// Fixtures for the TestAction reachability suite (codeunit 60583).
//
// The page declares six actions that differ ONLY in how Visible/Enabled is written, so the
// suite can tell four things apart that a page with one action cannot:
//
//   Plain            no Visible/Enabled at all      -- the positive control
//   HiddenLiteral    Visible = false                -- a compile-time literal
//   InHiddenGroup    inside a group Visible = false -- inherited from an ancestor
//   HiddenByVar      Visible = <page variable>      -- an expression that is false right now
//   DisabledLiteral  Enabled = false                -- a compile-time literal
//   DisabledByVar    Enabled = <page variable>      -- an expression that is false right now
//
// Every OnAction stamps a row of TPAR Row under its own key, so "the trigger ran" is
// observable from the test without a handler and without reading page state.

table 60581 "TPAR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 60582 "TPAR Host"
{
    PageType = List;
    SourceTable = "TPAR Row";
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
            action(Plain)
            {
                ApplicationArea = All;
                Caption = 'Plain';

                trigger OnAction()
                begin
                    Stamp('PLAIN');
                end;
            }

            action(HiddenLiteral)
            {
                ApplicationArea = All;
                Caption = 'Hidden Literal';
                Visible = false;

                trigger OnAction()
                begin
                    Stamp('HIDDENLIT');
                end;
            }

            action(HiddenByVar)
            {
                ApplicationArea = All;
                Caption = 'Hidden By Var';
                Visible = ShowIt;

                trigger OnAction()
                begin
                    Stamp('HIDDENVAR');
                end;
            }

            action(DisabledLiteral)
            {
                ApplicationArea = All;
                Caption = 'Disabled Literal';
                Enabled = false;

                trigger OnAction()
                begin
                    Stamp('DISABLEDLIT');
                end;
            }

            action(DisabledByVar)
            {
                ApplicationArea = All;
                Caption = 'Disabled By Var';
                Enabled = EnableIt;

                trigger OnAction()
                begin
                    Stamp('DISABLEDVAR');
                end;
            }

            group(HiddenGroup)
            {
                Caption = 'Hidden Group';
                Visible = false;

                action(InHiddenGroup)
                {
                    ApplicationArea = All;
                    Caption = 'In Hidden Group';

                    trigger OnAction()
                    begin
                        Stamp('INGROUP');
                    end;
                }
            }
        }
    }

    var
        // Never assigned, so both are false for the whole life of the page. They exist so an
        // action can carry a Visible/Enabled that is an EXPRESSION rather than a literal --
        // the distinction the suite is about.
        ShowIt: Boolean;
        EnableIt: Boolean;

    local procedure Stamp(StampKey: Code[20])
    var
        Row: Record "TPAR Row";
    begin
        if Row.Get(StampKey) then
            exit;
        Row.Init();
        Row."No." := StampKey;
        Row.Descr := 'ran';
        Row.Insert();
    end;
}
