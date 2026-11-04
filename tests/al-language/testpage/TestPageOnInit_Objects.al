// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-oninit-page-trigger
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: POI Row (60486), POI Wizard (60487), POI Refusing Page (60489)
//
// Fixtures for the page OnInit suite (codeunit 60488).
//
// A wizard-shaped NavigatePage with no source table, modelled on Base Application page
// "Time Sheet Setup Wizard": OnInit sets the step and computes the page globals the footer
// actions' Enabled is bound to. Nothing else sets them, so every value the tests read is one
// only OnInit (or an action that ran) could have produced.
//
//   Trace      'I' appended by OnInit, 'S' by SetStep, 'O' by OnOpenPage -- how often, and in
//              what order, each ran
//   NextAction Enabled = NextEnabled   OnInit sets it TRUE  (Step 0 of 0..2)
//   BackAction Enabled = BackEnabled   OnInit sets it FALSE (Step 0 of 0..2)
//
// Next advances Step and recomputes both globals, Back steps back, and both stamp a row of
// POI Row, so "the trigger ran" is observable without a handler.

table 60486 "POI Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Hits; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 60487 "POI Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'POI Wizard';

    layout
    {
        area(Content)
        {
            field(TraceText; Trace)
            {
                ApplicationArea = All;
                Caption = 'Trace';
                Editable = false;
            }
            field(StepNo; Step)
            {
                ApplicationArea = All;
                Caption = 'Step';
                Editable = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BackAction)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Stamp('BACK');
                    Step -= 1;
                    UpdateControls();
                end;
            }

            action(NextAction)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Stamp('NEXT');
                    Step += 1;
                    UpdateControls();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Trace += 'I';
        Step := 0;
        UpdateControls();
    end;

    trigger OnOpenPage()
    begin
        Trace += 'O';
    end;

    // Called by AL on the page VARIABLE before it is run. BC constructs the instance -- and
    // runs OnInit -- the first time the variable is used, so this always runs after OnInit.
    procedure SetStep(NewStep: Integer)
    begin
        Trace += 'S';
        Step := NewStep;
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        NextEnabled := Step < 2;
        BackEnabled := Step > 0;
    end;

    local procedure Stamp(No: Code[20])
    var
        Row: Record "POI Row";
    begin
        if not Row.Get(No) then begin
            Row.Init();
            Row."No." := No;
            Row.Insert();
        end;
        Row.Hits += 1;
        Row.Modify();
    end;

    var
        Trace: Text[10];
        Step: Integer;
        NextEnabled: Boolean;
        BackEnabled: Boolean;
}

// OnInit refuses. Nothing else in the page runs, so the only error a caller can see is this one.
page 60489 "POI Refusing Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'POI Refusing Page';

    trigger OnInit()
    begin
        Error('POI OnInit refused to open the page');
    end;
}
