// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARCR Row (60585), TPARCR Probe (60586), TPARCR Target (60595),
//                TPARCR Host (60596)
//
// Fixtures for two properties of a page action whose RunObject names a codeunit, next to what
// codeunit 60559 already pins (the codeunit runs, on the host's current row):
//
//   1. does the codeunit's Rec carry the host page's filters, and
//   2. when the codeunit moves, re-filters or modifies its Rec, what does the host page show?
//
// ONE target codeunit serves every arm. The probe's mode, set by the test before the invoke,
// picks what the target does, so each arm differs from the others only in that mode and not in
// which object the action names.
//
// Written by agent stma-auto2-12, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4589.

table 60585 "TPARCR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
        field(3; Grp; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 60586 "TPARCR Probe"
{
    SingleInstance = true;

    var
        Mode: Text[20];
        Ran: Boolean;
        RecSeen: Text[50];
        RowsSeen: Text[250];
        CountSeen: Integer;
        MovedTo: Text[50];

    procedure Reset(NewMode: Text[20])
    begin
        Mode := NewMode;
        Ran := false;
        RecSeen := '';
        RowsSeen := '';
        CountSeen := -1;
        MovedTo := '';
    end;

    procedure GetMode(): Text[20]
    begin
        exit(Mode);
    end;

    procedure RecordSeen(Descr: Text[50]; Rows: Text[250]; RowCount: Integer)
    begin
        Ran := true;
        RecSeen := Descr;
        RowsSeen := Rows;
        CountSeen := RowCount;
    end;

    procedure RecordMovedTo(Descr: Text[50])
    begin
        MovedTo := Descr;
    end;

    procedure GetRan(): Boolean
    begin
        exit(Ran);
    end;

    procedure GetRecSeen(): Text[50]
    begin
        exit(RecSeen);
    end;

    procedure GetRowsSeen(): Text[250]
    begin
        exit(RowsSeen);
    end;

    procedure GetCountSeen(): Integer
    begin
        exit(CountSeen);
    end;

    procedure GetMovedTo(): Text[50]
    begin
        exit(MovedTo);
    end;
}

codeunit 60595 "TPARCR Target"
{
    TableNo = "TPARCR Row";

    trigger OnRun()
    var
        Probe: Codeunit "TPARCR Probe";
        Other: Record "TPARCR Row";
        Rows: Text[250];
    begin
        // Read what Rec carries BEFORE touching it. The row set is walked on a Copy, which takes
        // Rec's filters in every filter group, so the walk cannot itself move Rec.
        Other.Copy(Rec);
        if Other.FindSet() then
            repeat
                Rows += Other."No.";
            until Other.Next() = 0;
        Probe.RecordSeen(Rec.Descr, Rows, Rec.Count());

        case Probe.GetMode() of
            'MOVE':
                begin
                    // Leave the host's filters and row behind entirely.
                    Rec.Reset();
                    Rec.SetRange("No.", 'E');
                    Rec.FindFirst();
                    Probe.RecordMovedTo(Rec.Descr);
                end;
            'WRITE':
                begin
                    Rec.Descr := 'Written';
                    Rec.Modify();
                end;
        end;
    end;
}

page 60596 "TPARCR Host"
{
    PageType = List;
    SourceTable = "TPARCR Row";
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
                field(Grp; Rec.Grp)
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
            action(RunTarget)
            {
                ApplicationArea = All;
                Caption = 'Run Target';
                RunObject = Codeunit "TPARCR Target";
            }
        }
    }
}
