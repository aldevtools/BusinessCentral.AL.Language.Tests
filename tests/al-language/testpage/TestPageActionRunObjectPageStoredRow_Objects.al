// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpageonrec-property
// Scope: in-scope
// Fixtures used: TPARPS Row (67360), TPARPS Probe (67360), TPARPS Host (67360),
//                TPARPS Target (67361)
//
// Fixtures for one question about a page action with RunObject = Page and RunPageOnRec = true:
// when the host page's OnAfterGetRecord writes a value into a TABLE field of Rec that is never
// saved, does the target page see that in-memory value, show it, and store it when the target
// saves its own edit of the row? Or does the target read the row as it is in the table?
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4752.

table 67360 "TPARPS Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
        // Stored as 'G1'/'G2'; the host's OnAfterGetRecord overwrites it in memory with 'CALC'.
        field(3; Grp; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    // Records the before- and after-image of Grp for every modify.
    trigger OnModify()
    var
        Probe: Codeunit "TPARPS Probe";
    begin
        Probe.RecordModify(xRec.Grp + '>' + Rec.Grp);
    end;
}

codeunit 67360 "TPARPS Probe"
{
    SingleInstance = true;

    var
        OpenSeen: Text[50];
        ShownGrp: Text[50];
        LastModify: Text[30];

    procedure Reset()
    begin
        OpenSeen := '';
        ShownGrp := '';
        LastModify := '';
    end;

    procedure RecordOpen(Seen: Text[50])
    begin
        OpenSeen := Seen;
    end;

    procedure GetOpenSeen(): Text[50]
    begin
        exit(OpenSeen);
    end;

    procedure RecordShownGrp(Grp: Text[50])
    begin
        ShownGrp := Grp;
    end;

    procedure GetShownGrp(): Text[50]
    begin
        exit(ShownGrp);
    end;

    procedure RecordModify(Images: Text[30])
    begin
        LastModify := Images;
    end;

    procedure GetLastModify(): Text[30]
    begin
        exit(LastModify);
    end;
}

page 67360 "TPARPS Host"
{
    PageType = List;
    SourceTable = "TPARPS Row";
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
                RunObject = Page "TPARPS Target";
                RunPageOnRec = true;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.Grp := 'CALC';
    end;
}

page 67361 "TPARPS Target"
{
    PageType = Card;
    SourceTable = "TPARPS Row";
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
        Probe: Codeunit "TPARPS Probe";
    begin
        Probe.RecordOpen(Rec."No." + ':' + Rec.Grp);
    end;
}
