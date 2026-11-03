// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: TPRTR Row (67362), TPRTR Child (67363), TPRTR Probe (67362), TPRTR Card (67362)
//
// Fixtures for one question about Page.Run(Id, Rec) when Rec is a TEMPORARY record: codeunit
// 67361 measured that a page opened on a caller's database row shows the row as the table holds
// it, not the caller's unsaved in-memory values. Here the caller's row lives in a temporary
// table, and the database holds a different row under the same key. Which one does the page
// show, and does it calculate a FlowField on it?
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4762.

table 67362 "TPRTR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Grp; Code[10]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("TPRTR Child" where(Parent = field("No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 67363 "TPRTR Child"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Parent; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 67362 "TPRTR Probe"
{
    SingleInstance = true;

    var
        OpenSeen: Text[100];
        Shown: Text[100];

    procedure Reset()
    begin
        OpenSeen := '';
        Shown := '';
    end;

    procedure RecordOpen(Seen: Text[100])
    begin
        OpenSeen := Seen;
    end;

    procedure GetOpenSeen(): Text[100]
    begin
        exit(OpenSeen);
    end;

    procedure RecordShown(Value: Text[100])
    begin
        Shown := Value;
    end;

    procedure GetShown(): Text[100]
    begin
        exit(Shown);
    end;
}

page 67362 "TPRTR Card"
{
    PageType = Card;
    SourceTable = "TPRTR Row";
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
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(Cnt; Rec.Cnt)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Probe: Codeunit "TPRTR Probe";
    begin
        Probe.RecordOpen(Rec."No." + ':' + Rec.Grp + ':' + Format(Rec.IsTemporary()));
    end;
}
