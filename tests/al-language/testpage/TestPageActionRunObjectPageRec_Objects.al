// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpageonrec-property
// Scope: in-scope
// Fixtures used: TPARPR Row (67350), TPARPR Probe (67350), TPARPR Host (67350),
//                TPARPR Target (67351), TPARPR Calc Host (67352)
//
// Fixtures for what a page action with RunObject = Page and RunPageOnRec = true shares with the
// page it was invoked from. Codeunit 60606 answers the same questions for a RunObject codeunit:
//
//   1. does the target's Rec carry the host page's current row and its filters, and
//   2. when the target moves or modifies its Rec, what does the host page show afterwards?
//
// ONE target page serves every arm. The probe's mode, set by the test before the invoke, picks
// what the target's OnOpenPage does, so the arms differ only in that mode.
//
// Written by agent stma-auto2-2, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4634.

table 67350 "TPARPR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
        field(3; Grp; Code[10]) { }
        // Never written by a test; only "TPARPR Calc Host"'s OnAfterGetRecord fills it.
        field(4; Calc; Text[60]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    // Records the before- and after-image of every modify, so an arm can read which xRec a
    // page's save carried.
    trigger OnModify()
    var
        Probe: Codeunit "TPARPR Probe";
    begin
        Probe.RecordModify(xRec.Descr + '>' + Rec.Descr);
    end;
}

codeunit 67350 "TPARPR Probe"
{
    SingleInstance = true;

    var
        Mode: Text[20];
        Opened: Boolean;
        RecSeen: Text[50];
        RowsSeen: Text[250];
        CountSeen: Integer;
        MovedTo: Text[50];
        LastModify: Text[110];

    procedure Reset(NewMode: Text[20])
    begin
        Mode := NewMode;
        Opened := false;
        RecSeen := '';
        RowsSeen := '';
        CountSeen := -1;
        MovedTo := '';
        LastModify := '';
    end;

    procedure RecordModify(Images: Text[110])
    begin
        LastModify := Images;
    end;

    procedure GetLastModify(): Text[110]
    begin
        exit(LastModify);
    end;

    procedure GetMode(): Text[20]
    begin
        exit(Mode);
    end;

    procedure RecordSeen(Descr: Text[50]; Rows: Text[250]; RowCount: Integer)
    begin
        Opened := true;
        RecSeen := Descr;
        RowsSeen := Rows;
        CountSeen := RowCount;
    end;

    procedure RecordMovedTo(Descr: Text[50])
    begin
        MovedTo := Descr;
    end;

    procedure GetOpened(): Boolean
    begin
        exit(Opened);
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

page 67350 "TPARPR Host"
{
    PageType = List;
    SourceTable = "TPARPR Row";
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
                RunObject = Page "TPARPR Target";
                RunPageOnRec = true;
            }
        }
    }
}

// A second host whose OnAfterGetRecord derives Calc from the row it just read, with one action
// of each kind: a plain RunObject and a RunPageOnRec one. Calc lives only in the page's Rec (no
// test stores it), so after an action the host shows 'CALC:<Descr>' only if OnAfterGetRecord
// ran for the row it shows, and the Descr inside it says which read of the row that was.
page 67352 "TPARPR Calc Host"
{
    PageType = List;
    SourceTable = "TPARPR Row";
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
                field(Calc; Rec.Calc)
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
            action(RunPlain)
            {
                ApplicationArea = All;
                Caption = 'Run Target (plain)';
                RunObject = Page "TPARPR Target";
            }
            action(RunOnRec)
            {
                ApplicationArea = All;
                Caption = 'Run Target (on rec)';
                RunObject = Page "TPARPR Target";
                RunPageOnRec = true;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.Calc := 'CALC:' + Rec.Descr;
    end;
}

page 67351 "TPARPR Target"
{
    PageType = Card;
    SourceTable = "TPARPR Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
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

    trigger OnOpenPage()
    var
        Probe: Codeunit "TPARPR Probe";
        Other: Record "TPARPR Row";
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

        if Probe.GetMode() = 'MOVE' then begin
            // Leave the host's filters and row behind entirely.
            Rec.Reset();
            Rec.SetRange("No.", 'E');
            Rec.FindFirst();
            Probe.RecordMovedTo(Rec.Descr);
        end;
    end;
}
