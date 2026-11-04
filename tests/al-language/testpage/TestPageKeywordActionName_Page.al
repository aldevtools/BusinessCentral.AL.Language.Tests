// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Keyword Action Row (60267), Keyword Action List (60268)
//
// A list page whose actions are named with words that are RESERVED KEYWORDS in C#
// (New, Delegate, Override, Finalize) next to words that merely look like one (Delete,
// Setup). AL does not care - an action name is an identifier - and TestPage dispatch must
// be identical for all of them. The pairing is the point: a test harness that emits AL to
// another language may have to rename New but not Delete, and the AL-observable contract
// is that the caller never sees the difference. New_Promoted covers the promoted-actionref
// route to a keyword-named target, mirroring TestPageSpacedActionName for the spaced case.

table 60267 "Keyword Action Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; Descr; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

page 60268 "Keyword Action List"
{
    PageType = List;
    SourceTable = "Keyword Action Row";
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
            action(New)
            {
                ApplicationArea = All;
                Caption = 'New (C# keyword)';

                trigger OnAction()
                begin
                    Stamp('NEW');
                end;
            }

            action(Delegate)
            {
                ApplicationArea = All;
                Caption = 'Delegate (C# keyword)';

                trigger OnAction()
                begin
                    Stamp('DELEGATE');
                end;
            }

            action(Finalize)
            {
                ApplicationArea = All;
                Caption = 'Finalize (reserved member name)';

                trigger OnAction()
                begin
                    Stamp('FINALIZE');
                end;
            }

            action(Delete)
            {
                ApplicationArea = All;
                Caption = 'Delete (not a C# keyword)';

                trigger OnAction()
                begin
                    Stamp('DELETE');
                end;
            }

            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Setup (not a C# keyword)';

                trigger OnAction()
                begin
                    Stamp('SETUP');
                end;
            }

            action(Override)
            {
                ApplicationArea = All;
                Caption = 'Override (C# keyword, always fails)';

                trigger OnAction()
                begin
                    Error('Keyword Action List action refused deliberately');
                end;
            }
        }
        area(Promoted)
        {
            actionref(New_Promoted; New)
            {
            }
        }
    }

    local procedure Stamp(No: Code[20])
    var
        Row: Record "Keyword Action Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Descr := Rec."No.";
        Row.Insert();
    end;
}
