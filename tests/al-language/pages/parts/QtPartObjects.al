// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-last-method
// Scope: in-scope
// Fixtures used: own objects 87384 - 87395 (writer QT); table "LT QJ Head" (86880), part "LT QL Note Lines" (86970) and log "LT QJ Log" (86882)
//   from QjPartPropagation.al; tests in QjPartPropagation.al (codeunit 86889, QT_* tests)
// Objects: (a) table "LT QT Val Line" whose key fields "Doc No." and "Line No." have an OnValidate (logged; "Doc No." raises an error when the
//   header's Note is 'fail'), with three ListParts over it (AutoSplitKey + DelayedInsert, DelayedInsert only, neither) and a Document host for
//   each (al-runtime-rs bump 44 pin PR 5620: Last() on an EMPTY part whose table validates a key field). (b) Card, Card with
//   UpdatePropagation = Both, ListPlus, ListPlus with Both and Document hosts over "LT QJ Head" with part "LT QL Note Lines", whose triggers log
//   the row No. (the host's reads at open, in order).
// BC versions: 27, 28, 29

table 87384 "LT QT Val Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20])
        {
            trigger OnValidate()
            var
                Head: Record "LT QJ Head";
                Log: Codeunit "LT QJ Log";
            begin
                Log.Add('T.Doc.V(' + "Doc No." + ' x=' + xRec."Doc No." + ' ln=' + Format("Line No.") + ')');
                if Head.Get("Doc No.") then
                    if Head.Note = 'fail' then
                        Error('LT QT Doc No. %1 may not be validated.', "Doc No.");
            end;
        }
        field(2; "Line No."; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT QJ Log";
            begin
                Log.Add('T.Ln.V(' + Format("Line No.") + ' x=' + Format(xRec."Line No.") + ' doc=' + "Doc No." + ')');
            end;
        }
        field(3; Amt; Decimal) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT QJ Log";
    begin
        Log.Add('T.INS(' + "Doc No." + ' ' + Format("Line No.") + ' a=' + Format(Amt) + ')');
    end;
}

page 87385 "LT QT Val Lines Split"
{
    PageType = ListPart;
    SourceTable = "LT QT Val Line";
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(AmtF; Rec.Amt) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('V.NEW(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' x=' + xRec."Doc No." + ' ' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('V.AGR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('V.AGCR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + xRec."Doc No." + ' ' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('V.INSR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('V.MODR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ')');
    end;
}

page 87386 "LT QT Val Lines Delayed"
{
    PageType = ListPart;
    SourceTable = "LT QT Val Line";
    ApplicationArea = All;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(AmtF; Rec.Amt) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('V.NEW(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' x=' + xRec."Doc No." + ' ' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('V.AGR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('V.AGCR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + xRec."Doc No." + ' ' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('V.INSR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('V.MODR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ')');
    end;
}

page 87387 "LT QT Val Lines Plain"
{
    PageType = ListPart;
    SourceTable = "LT QT Val Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(AmtF; Rec.Amt) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('V.NEW(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' x=' + xRec."Doc No." + ' ' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('V.AGR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('V.AGCR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + xRec."Doc No." + ' ' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('V.INSR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('V.MODR(' + Rec."Doc No." + ' ' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ')');
    end;
}

page 87388 "LT QT Val Host Split"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QT Val Lines Split")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87389 "LT QT Val Host Delayed"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QT Val Lines Delayed")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87390 "LT QT Val Host Plain"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QT Val Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87391 "LT QT Card Host"
{
    PageType = Card;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('H.OPEN(' + Rec."No." + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87392 "LT QT Card Host Both"
{
    PageType = Card;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('H.OPEN(' + Rec."No." + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87393 "LT QT ListPlus Host"
{
    PageType = ListPlus;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('H.OPEN(' + Rec."No." + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87394 "LT QT ListPlus Host Both"
{
    PageType = ListPlus;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('H.OPEN(' + Rec."No." + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87395 "LT QT Doc Host"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('H.OPEN(' + Rec."No." + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x=' + xRec."No." + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(' + Rec."No." + ' t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}
