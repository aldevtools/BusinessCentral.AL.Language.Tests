// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-enabled-property
// Scope: in-scope
// Fixtures used: (none — the table below is the card page's SourceTable)
//
// Backing objects for the SOURCE-TABLE-FIELD half of the Enabled / Editable client-expression
// grammar, on an ACTION and on a CONTROL.
//
// Codeunit 60755 ("TPCF Tests") already settles one neighbouring surface: a CONTROL's Visible
// bound to a source-table field reads as if the field held its type default, on every row and on
// every reopen. This suite deliberately does NOT re-measure Visible. It asks a different
// question about a different property, because the answer is not derivable from that one: does
// an ACTION's Enabled — the property the testability layer consults before it dispatches
// OnAction — follow the current row, and do a control's Enabled and Editable?
//
// Every control under test binds to its OWN field, distinct from the field its property
// expression reads and from the other test control's field, so a failure is never ambiguous
// about which control it is about (the discipline codeunit 60265's header describes).

table 60434 "TPAE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Flag; Boolean) { }
        field(3; Value; Text[30]) { }
        field(4; LineType; Option) { OptionMembers = Zero,One,Two; }
        field(5; Spare; Text[30]) { }
        field(6; Spare2; Text[30]) { }
    }

    keys { key(K; PK) { Clustered = true; } }
}

table 60437 "TPAE Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Message; Text[100]) { }
    }

    keys { key(K; "Entry No.") { Clustered = true; } }

    procedure Stamp(Msg: Text[100])
    var
        Log: Record "TPAE Log";
        Last: Integer;
    begin
        if Log.FindLast() then
            Last := Log."Entry No.";
        Log.Init();
        Log."Entry No." := Last + 1;
        Log.Message := Msg;
        Log.Insert();
    end;

    procedure Stamped(Msg: Text[100]): Boolean
    var
        Log: Record "TPAE Log";
    begin
        Log.SetRange(Message, Msg);
        exit(not Log.IsEmpty());
    end;
}

page 60435 "TPAE Card"
{
    PageType = Card;
    SourceTable = "TPAE Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPAE Card';

    layout
    {
        area(Content)
        {
            // Plain, no property override — lets a test read back which row it is on.
            field(ValueCtl; Rec.Value) { ApplicationArea = All; }

            // The two CONTROL shapes under test. Each binds to a field neither the other test
            // control nor its own property expression touches.
            field(EnabledCtl; Rec.Spare) { ApplicationArea = All; Enabled = Rec.Flag; }
            field(EditableCtl; Rec.Spare2) { ApplicationArea = All; Editable = Rec.Flag; }
        }
    }

    actions
    {
        area(Processing)
        {
            // The three ACTION shapes: a Boolean field read directly, a text comparison, and an
            // Option compared against two of its members. Each stamps its own marker, so a test
            // can tell whether OnAction ran without reading Enabled first.
            action(ABoolField)
            {
                ApplicationArea = All;
                Enabled = Rec.Flag;
                trigger OnAction()
                var
                    Log: Record "TPAE Log";
                begin
                    Log.Stamp('BOOL-FIELD');
                end;
            }
            action(ATextCompare)
            {
                ApplicationArea = All;
                Enabled = Rec.Value <> '';
                trigger OnAction()
                var
                    Log: Record "TPAE Log";
                begin
                    Log.Stamp('TEXT-COMPARE');
                end;
            }
            action(AOptionCompare)
            {
                ApplicationArea = All;
                Enabled = (Rec.LineType = Rec.LineType::One) or (Rec.LineType = Rec.LineType::Two);
                trigger OnAction()
                var
                    Log: Record "TPAE Log";
                begin
                    Log.Stamp('OPTION-COMPARE');
                end;
            }
        }
    }
}
