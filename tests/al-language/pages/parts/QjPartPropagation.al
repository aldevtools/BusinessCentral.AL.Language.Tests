// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-updatepropagation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QJ *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: (1) a Document card over table H with a ListPart over table L (SubPageLink), the part control with UpdatePropagation = Both,
//   SubPart and not set. A part field's OnValidate modifies the H row (Get + Modify, another field) and calls CurrPage.Update(false); then a
//   host action runs Rec.Validate of a third H field and CurrPage.SaveRecord(). Observed: the host and part triggers with their Rec/xRec
//   values, the host controls, the stored H row after each step, and whether 'changed by another user' is raised. Also with an unsaved
//   host edit typed before the part edit.
//   (2) a subform field's OnValidate that calls CurrPage.SaveRecord() and reads Rec and xRec of the same field before and after the call,
//   for a new typed row and for an edited stored row, each edited twice (Microsoft's DeltaUpdateTotals adds Rec minus xRec).
// Results (BC 29.0): with Both, SubPart and not set alike the host re-reads its row after the part's Update(false) (H.AGR/H.AGCR with the
//   part's Total; with Both the host's triggers run before the part's re-read, otherwise after it), no 'changed by another user' is raised,
//   the host's later save keeps the part's change, and the part's own typed Qty is not saved (Update(false) re-reads the line). An unsaved
//   host edit is saved (H.MODR) before the part's OnValidate runs. In a subform OnValidate, CurrPage.SaveRecord() changes neither Rec nor
//   xRec; for a new row Rec gets the AutoSplitKey line number and xRec stays the blank new row.
// Settles al-runtime-rs docs/probes-needed.md assumption part-update-propagation-both-refreshes-host (Tests-ERM 134344 and about 160 more).
// Facts (writer QT, QT_* tests, objects QtPartObjects.al): Last() on an EMPTY part whose key field has an OnValidate answers No, validates the
//   SubPageLink field, runs OnNewRecord and OnAfterGetCurrRecord (twice), stores nothing; typing after it inserts (AutoSplitKey + DelayedInsert
//   at Close, plain at once). A failing key OnValidate is not surfaced at open; SetValue after Last then raises 'The row does not exist on the
//   TestPage.'. Card / ListPlus / Document hosts with a part: the read order at OpenEdit, GoToKey and Next (QT_Host*), and an empty part after
//   OpenNew (QT_EmptyPart_*): OpenNew alone inserts no head, part Last() or New inserts the blank head.
// BC versions: 29 (27 and 28 by CI)

table 86880 "LT QJ Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Total; Decimal) { }
        field(3; Descr; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT QJ Log";
            begin
                Log.Add('T.H.Descr.V(' + Descr + ' x=' + xRec.Descr + ' t=' + Format(Total) + ' x.t=' + Format(xRec.Total) + ')');
            end;
        }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT QJ Log";
    begin
        Log.Add('T.H.MOD(t=' + Format(Total) + ' d=' + Descr + ' n=' + Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

table 86881 "LT QJ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Decimal) { }
        field(4; Amt; Decimal) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

codeunit 86882 "LT QJ Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Take(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' ';
            Result += Line;
        end;
        Clear(Lines);
        exit(Result);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;
}

page 86883 "LT QJ Lines"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
                field(QtyF; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Head: Record "LT QJ Head";
                    begin
                        Log.Add('L.Qty.V(' + Format(Rec.Qty) + ' x=' + Format(xRec.Qty) + ')');
                        Head.Get(Rec."Doc No.");
                        Head.Total := Head.Total + Rec.Qty - xRec.Qty;
                        Head.Modify();
                        CurrPage.Update(false);
                        Log.Add('L.Qty.V.end');
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('L.AGR(' + Format(Rec."Line No.") + ' q=' + Format(Rec.Qty) + ' x.q=' + Format(xRec.Qty) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('L.AGCR(' + Format(Rec."Line No.") + ' q=' + Format(Rec.Qty) + ' x.q=' + Format(xRec.Qty) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('L.MODR(' + Format(Rec."Line No.") + ' q=' + Format(Rec.Qty) + ' x.q=' + Format(xRec.Qty) + ')');
    end;
}

page 86884 "LT QJ Host Both"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('H.ACT(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                    Rec.Validate(Descr, 'by action');
                    CurrPage.SaveRecord();
                    Log.Add('H.ACT.end(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

page 86885 "LT QJ Host SubPart"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = SubPart;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('H.ACT(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                    Rec.Validate(Descr, 'by action');
                    CurrPage.SaveRecord();
                    Log.Add('H.ACT.end(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

page 86886 "LT QJ Host Default"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('H.ACT(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                    Rec.Validate(Descr, 'by action');
                    CurrPage.SaveRecord();
                    Log.Add('H.ACT.end(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

page 86887 "LT QJ Save Lines"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
                field(AmtF; Rec.Amt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('S.V.before(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
                        CurrPage.SaveRecord();
                        Log.Add('S.V.after(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' delta=' + Format(Rec.Amt - xRec.Amt) + ')');
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('S.AGCR(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('S.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('S.INSR(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('S.MODR(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ')');
    end;
}

page 86888 "LT QJ Save Host"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Save Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

// ---- Writer QL additions (2026-10-21): a part edit that does not change the host row, a new part row, GoToKey and New counts ----

page 86970 "LT QL Note Lines"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
                field(AmtF; Rec.Amt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('N.Amt.V(' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ')');
                        CurrPage.Update(false);
                        Log.Add('N.Amt.V.end');
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('N.AGR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x.a=' + Format(xRec.Amt) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('N.AGCR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x.a=' + Format(xRec.Amt) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('N.MODR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x.a=' + Format(xRec.Amt) + ')');
    end;
}

page 86971 "LT QL Note Host Both"
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
                UpdatePropagation = Both;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 86972 "LT QL Note Host SubPart"
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
                UpdatePropagation = SubPart;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 86973 "LT QL Note Host Default"
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

// ---- Writer QN additions (2026-10-21): hosts that are not Document pages for the LT QL Note Lines part; parts with other trigger and
// insert shapes (AutoSplitKey, DelayedInsert, OnAfterGetRecord, OnAfterGetCurrRecord) and a plain Document host for each ----

page 87020 "LT QN Note Host Card"
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87021 "LT QN Note Host Card Both"
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87022 "LT QN Note Host ListPlus"
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87023 "LT QN Note Host ListPlus Both"
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 87024 "LT QN Lines NoAGCR"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
        Log.Add('A.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' b=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('A.AGR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('A.INSR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;
}

page 87025 "LT QN Lines AGR"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
        Log.Add('B.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' b=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('B.AGR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('B.AGCR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('B.INSR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;
}

page 87026 "LT QN Lines NewOnly"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
        Log.Add('C.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' b=' + Format(BelowxRec) + ')');
    end;
}

page 87027 "LT QN Lines DelayedOnly"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
        Log.Add('D.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' b=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('D.AGCR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('D.INSR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;
}

page 87028 "LT QN Lines SplitOnly"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
    ApplicationArea = All;
    AutoSplitKey = true;

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
        Log.Add('E.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' b=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('E.AGCR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('E.INSR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;
}

page 87029 "LT QN Lines Plain"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
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
        Log.Add('F.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' b=' + Format(BelowxRec) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('F.AGCR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('F.INSR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;
}

page 87030 "LT QN Host NoAGCR"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QN Lines NoAGCR")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87031 "LT QN Host AGR"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QN Lines AGR")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87032 "LT QN Host NewOnly"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QN Lines NewOnly")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87033 "LT QN Host DelayedOnly"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QN Lines DelayedOnly")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87034 "LT QN Host SplitOnly"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QN Lines SplitOnly")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 87035 "LT QN Host Plain"
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
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QN Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

codeunit 86889 "LT QJ Part Propagation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QJ Log";

    local procedure Seed()
    var
        Head: Record "LT QJ Head";
        Line: Record "LT QJ Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'H1';
        Head.Total := 1;
        Head.Descr := 'orig';
        Head.Note := 'orig';
        Head.Insert();
        Line."Doc No." := 'H1';
        Line."Line No." := 10000;
        Line.Qty := 1;
        Line.Amt := 1;
        Line.Insert();
        Log.Reset();
    end;

    local procedure Stored(): Text
    var
        Head: Record "LT QJ Head";
    begin
        if not Head.Get('H1') then
            exit('<no header>');
        exit('t=' + Format(Head.Total) + ' d=' + Head.Descr + ' n=' + Head.Note);
    end;

    local procedure StoredLines(): Text
    var
        Line: Record "LT QJ Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", 'H1');
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Format(Line."Line No.") + ':q=' + Format(Line.Qty) + ',a=' + Format(Line.Amt);
            until Line.Next() = 0;
        exit(Result);
    end;

    // ---- (1) part OnValidate modifies the host row, then the host action validates and saves ----

    [Test]
    procedure QJ_Both_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('host-descr-after-action', TP.DescrF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=1) L.Qty.V.end H.AGR(t=5 d=orig n=orig x.t=1) H.AGCR(t=5 d=orig n=orig x.t=1) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=5 d=orig n=orig');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=orig x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=orig x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=orig x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=orig x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('host-descr-after-action', 'by action');
        Observer.Expect('stored-after-action', 't=5 d=by action n=orig');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QJ_SubPart_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('host-descr-after-action', TP.DescrF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=orig x.t=1) H.AGCR(t=5 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=5 d=orig n=orig');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=orig x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=orig x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=orig x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=orig x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('host-descr-after-action', 'by action');
        Observer.Expect('stored-after-action', 't=5 d=by action n=orig');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QJ_Default_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('host-descr-after-action', TP.DescrF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=orig x.t=1) H.AGCR(t=5 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=5 d=orig n=orig');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=orig x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=orig x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=orig x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=orig x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('host-descr-after-action', 'by action');
        Observer.Expect('stored-after-action', 't=5 d=by action n=orig');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    // The host holds an unsaved edit (Note typed) when the part edit modifies the host row.

    [Test]
    procedure QJ_Both_HostEdited_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.NoteF.SetValue('typed');
        Observer.Observe('log-open-and-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('host-note-after-part', TP.NoteF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('log-open-and-host-edit', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=1 d=orig n=typed x.t=1 x.d=orig) T.H.MOD(t=1 d=orig n=typed x.t=1 x.d=orig) L.Qty.V(5 x=1) L.Qty.V.end H.AGR(t=5 d=orig n=typed x.t=1) H.AGCR(t=5 d=orig n=typed x.t=1) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('host-note-after-part', 'typed');
        Observer.Expect('stored-after-part', 't=5 d=orig n=typed');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=typed x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=typed x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=typed x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=typed x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('stored-after-action', 't=5 d=by action n=typed');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=typed');
        Observer.Verify();
    end;

    [Test]
    procedure QJ_SubPart_HostEdited_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.NoteF.SetValue('typed');
        Observer.Observe('log-open-and-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('host-note-after-part', TP.NoteF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('log-open-and-host-edit', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=1 d=orig n=typed x.t=1 x.d=orig) T.H.MOD(t=1 d=orig n=typed x.t=1 x.d=orig) L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=typed x.t=1) H.AGCR(t=5 d=orig n=typed x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('host-note-after-part', 'typed');
        Observer.Expect('stored-after-part', 't=5 d=orig n=typed');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=typed x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=typed x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=typed x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=typed x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('stored-after-action', 't=5 d=by action n=typed');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=typed');
        Observer.Verify();
    end;

    [Test]
    procedure QJ_Default_HostEdited_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.NoteF.SetValue('typed');
        Observer.Observe('log-open-and-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('host-note-after-part', TP.NoteF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('log-open-and-host-edit', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=1 d=orig n=typed x.t=1 x.d=orig) T.H.MOD(t=1 d=orig n=typed x.t=1 x.d=orig) L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=typed x.t=1) H.AGCR(t=5 d=orig n=typed x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('host-note-after-part', 'typed');
        Observer.Expect('stored-after-part', 't=5 d=orig n=typed');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=typed x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=typed x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=typed x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=typed x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('stored-after-action', 't=5 d=by action n=typed');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=typed');
        Observer.Verify();
    end;

    // ---- (2) subform OnValidate: CurrPage.SaveRecord() and Rec/xRec of the same field before and after ----

    [Test]
    procedure QJ_SubformSaveRecord_StoredRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-first-edit', Log.Take());
        Observer.Observe('lines-after-first-edit', StoredLines());
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-second-edit', Log.Take());
        Observer.Observe('lines-after-second-edit', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0)');
        Observer.Expect('log-first-edit', 'S.V.before(10000 r=5 x=1 x.ln=10000) S.MODR(10000 r=5 x=1) S.V.after(10000 r=5 x=1 x.ln=10000 delta=4)');
        Observer.Expect('lines-after-first-edit', '10000:q=1,a=5');
        Observer.Expect('log-second-edit', 'S.V.before(10000 r=7 x=5 x.ln=10000) S.MODR(10000 r=7 x=5) S.V.after(10000 r=7 x=5 x.ln=10000 delta=2)');
        Observer.Expect('lines-after-second-edit', '10000:q=1,a=7');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=7');
        Observer.Verify();
    end;

    [Test]
    procedure QJ_SubformSaveRecord_NewRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-open-and-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-first-edit', Log.Take());
        Observer.Observe('lines-after-first-edit', StoredLines());
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-second-edit', Log.Take());
        Observer.Observe('lines-after-second-edit', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open-and-new', 'S.AGCR(10000 r=1 x=0) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.AGCR(10000 r=1 x=1) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-first-edit', 'S.V.before(0 r=5 x=0 x.ln=0) S.INSR(20000 r=5 x=0 x.ln=0) S.V.after(20000 r=5 x=0 x.ln=0 delta=5)');
        Observer.Expect('lines-after-first-edit', '10000:q=1,a=1 20000:q=0,a=5');
        Observer.Expect('log-second-edit', 'S.V.before(20000 r=7 x=5 x.ln=20000) S.MODR(20000 r=7 x=5) S.V.after(20000 r=7 x=5 x.ln=20000 delta=2)');
        Observer.Expect('lines-after-second-edit', '10000:q=1,a=1 20000:q=0,a=7');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1 20000:q=0,a=7');
        Observer.Verify();
    end;

    // ---- Writer QL (2026-10-21): (3) a new part row (DelayedInsert) whose OnValidate modifies the host row and calls CurrPage.Update(false);
    // a part edit whose code does not change the host row; (4) OpenEdit + GoToKey on a Document host and New on the part: trigger counts ----
    // Probed by corpus CI on BC 27.5, 28.5 and 29.0 (batch runs 39559542435, 39559572012, 39559599293; the same values on all three).
    // Results: (3) on a new part row, with Both the host reads its row again and the part keeps its typed row (inserted at Close); with
    // SubPart and not set the part reads its rows again first, drops the typed new row (never inserted), then the host reads its row again.
    // A part Update(false) that did not change the host row: with Both the host reads its row again before the part, with SubPart and not
    // set the host is not read again. (4) GoToKey on a Document host walks the host rows from the first one (the part reads its rows for
    // each host row it passes whose lines it does not already show); on a part with rows Last() runs OnNewRecord once and comes back to the last
    // row, each New() runs it once more (xRec is the last row, also after First()); a part with no rows runs it on each host move and twice
    // on Last().

    local procedure SeedQl()
    var
        Head: Record "LT QJ Head";
        Line: Record "LT QJ Line";
    begin
        Seed();
        Head."No." := 'H2';
        Head.Total := 2;
        Head.Descr := 'two';
        Head.Note := 'two';
        Head.Insert();
        Head."No." := 'H3';
        Head.Total := 3;
        Head.Descr := 'three';
        Head.Note := 'three';
        Head.Insert();
        Line."Doc No." := 'H2';
        Line."Line No." := 30000;
        Line.Qty := 3;
        Line.Amt := 3;
        Line.Insert();
        Line."Line No." := 40000;
        Line.Qty := 4;
        Line.Amt := 4;
        Line.Insert();
        Log.Reset();
    end;

    [Test]
    procedure QL_Both_NewPartRow_PartModifiesHost()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-qty-after-part', TP.Lines.QtyF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'L.AGCR(0 q=0 x.q=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1) L.AGCR(0 q=0 x.q=0)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=0) L.Qty.V.end H.AGR(t=6 d=orig n=orig x.t=1) H.AGCR(t=6 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '6.00');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-qty-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=6 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=6 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1 20000:q=5,a=0');
        Observer.Verify();
    end;

    [Test]
    procedure QL_SubPart_NewPartRow_PartModifiesHost()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-qty-after-part', TP.Lines.QtyF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'L.AGCR(0 q=0 x.q=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1) L.AGCR(0 q=0 x.q=0)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=0) L.Qty.V.end L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1) L.AGCR(0 q=0 x.q=0) H.AGR(t=6 d=orig n=orig x.t=1) H.AGCR(t=6 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '6.00');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-qty-after-part', '0.00');
        Observer.Expect('stored-after-part', 't=6 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=6 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Default_NewPartRow_PartModifiesHost()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-qty-after-part', TP.Lines.QtyF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'L.AGCR(0 q=0 x.q=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1) L.AGCR(0 q=0 x.q=0)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=0) L.Qty.V.end L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1) L.AGCR(0 q=0 x.q=0) H.AGR(t=6 d=orig n=orig x.t=1) H.AGCR(t=6 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '6.00');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-qty-after-part', '0.00');
        Observer.Expect('stored-after-part', 't=6 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=6 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Both_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=1 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QL_SubPart_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=1 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Default_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=1 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Both_GoToKey_Counts()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2-again', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey-h1', Log.Take());
        Observer.Observe('part-line-at-h1', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0)');
        Observer.Expect('log-gotokey-h2', 'H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1) H.AGR(t=2 d=two n=two x.t=1) H.AGCR(t=2 d=two n=two x.t=1) L.AGR(30000 q=3 x.q=1) L.AGR(40000 q=4 x.q=3) L.AGR(30000 q=3 x.q=4) L.AGR(30000 q=3 x.q=3) L.AGCR(30000 q=3 x.q=1)');
        Observer.Expect('log-gotokey-h2-again', 'H.AGR(t=1 d=orig n=orig x.t=2) H.AGCR(t=1 d=orig n=orig x.t=2) L.AGR(10000 q=1 x.q=3) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=3) H.AGR(t=2 d=two n=two x.t=1) H.AGCR(t=2 d=two n=two x.t=1) L.AGR(30000 q=3 x.q=1) L.AGR(40000 q=4 x.q=3) L.AGR(30000 q=3 x.q=4) L.AGR(30000 q=3 x.q=3) L.AGCR(30000 q=3 x.q=1)');
        Observer.Expect('log-gotokey-h1', 'H.AGR(t=1 d=orig n=orig x.t=2) H.AGCR(t=1 d=orig n=orig x.t=2) L.AGR(10000 q=1 x.q=3) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=3)');
        Observer.Expect('part-line-at-h1', '10000');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Default_GoToKey_Counts()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2-again', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey-h1', Log.Take());
        Observer.Observe('part-line-at-h1', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0)');
        Observer.Expect('log-gotokey-h2', 'H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1) H.AGR(t=2 d=two n=two x.t=1) H.AGCR(t=2 d=two n=two x.t=1) L.AGR(30000 q=3 x.q=1) L.AGR(40000 q=4 x.q=3) L.AGR(30000 q=3 x.q=4) L.AGR(30000 q=3 x.q=3) L.AGCR(30000 q=3 x.q=1)');
        Observer.Expect('log-gotokey-h2-again', 'H.AGR(t=1 d=orig n=orig x.t=2) H.AGCR(t=1 d=orig n=orig x.t=2) L.AGR(10000 q=1 x.q=3) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=3) H.AGR(t=2 d=two n=two x.t=1) H.AGCR(t=2 d=two n=two x.t=1) L.AGR(30000 q=3 x.q=1) L.AGR(40000 q=4 x.q=3) L.AGR(30000 q=3 x.q=4) L.AGR(30000 q=3 x.q=3) L.AGCR(30000 q=3 x.q=1)');
        Observer.Expect('log-gotokey-h1', 'H.AGR(t=1 d=orig n=orig x.t=2) H.AGCR(t=1 d=orig n=orig x.t=2) L.AGR(10000 q=1 x.q=3) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=3)');
        Observer.Expect('part-line-at-h1', '10000');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QL_OpenView_GoToKey_Counts()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        SeedQl();
        TP.OpenView();
        Observer.Observe('log-open', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey-h1', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0)');
        Observer.Expect('log-gotokey-h2', 'H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1) H.AGR(t=2 d=two n=two x.t=1) H.AGCR(t=2 d=two n=two x.t=1) L.AGR(30000 q=3 x.q=1) L.AGR(40000 q=4 x.q=3) L.AGR(30000 q=3 x.q=4) L.AGR(30000 q=3 x.q=3) L.AGCR(30000 q=3 x.q=1)');
        Observer.Expect('log-gotokey-h1', 'H.AGR(t=1 d=orig n=orig x.t=2) H.AGCR(t=1 d=orig n=orig x.t=2) L.AGR(10000 q=1 x.q=3) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=3)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QL_PartNew_WithoutLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-1-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H1'));
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0)');
        Observer.Expect('log-1-new', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QL_PartLastNew_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-1-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0) S.AGCR(30000 r=3 x=1)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-1-last', 'S.NEW(x=4 x.ln=40000) S.AGCR(0 r=0 x=0) S.AGCR(40000 r=4 x=3)');
        Observer.Expect('log-2-new', 'S.NEW(x=4 x.ln=40000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QL_PartFirstNew_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('first-result', Format(TP.Lines.First()));
        Observer.Observe('log-1-first', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0) S.AGCR(30000 r=3 x=1)');
        Observer.Expect('first-result', 'Yes');
        Observer.Expect('log-1-first', '');
        Observer.Expect('log-2-new', 'S.NEW(x=4 x.ln=40000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QL_PartLastNew_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H3');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-1-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H3'));
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0) S.AGCR(30000 r=3 x=1) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-1-last', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-2-new', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QL_PartLastNewNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-1-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-3-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H1'));
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-1-last', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.AGCR(10000 r=1 x=1)');
        Observer.Expect('log-2-new', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-3-new', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    local procedure StoredLinesOf(DocNo: Code[20]): Text
    var
        Line: Record "LT QJ Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", DocNo);
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Format(Line."Line No.") + ':q=' + Format(Line.Qty) + ',a=' + Format(Line.Amt);
            until Line.Next() = 0;
        exit(Result);
    end;

    // ---- Writer QN (2026-10-21), al-runtime-rs PR 5595 refusals: (2) a part's CurrPage.Update(false) when the host row did not change, on a
    // new part row, on Card and ListPlus hosts and while the host holds an unsaved edit; (3) the xRec an empty part's OnNewRecord sees after
    // host moves other than GoToKey (Next, Previous, First, Last, OpenNew, OpenEdit); (4) Last() and First() on parts without
    // OnAfterGetCurrRecord or with OnAfterGetRecord; (5) New() on parts that are not AutoSplitKey + DelayedInsert or have OnAfterGetRecord. ----
    // Probed by corpus CI on BC 29.0 (batch run 39595069689); 27.5 and 28.5 by the final check.
    // Results: (2) on a NEW part row the part's Update(false) behaves as when the part changed the host row: with Both (Document or ListPlus)
    // the host reads its row again and the part keeps the typed row (inserted at Close as 20000); with SubPart, not set, or a Card host the part
    // reads its rows again and drops the typed row. On a stored row: Card and ListPlus hosts behave like the Document host (Both reads the
    // host first; not set does not read the host; the typed value is dropped). An unsaved host edit is saved (H.MODR + OnModify) before the
    // part's OnValidate runs; then the same as without it. (3) an empty part runs OnNewRecord three times on each host move (Next, Previous,
    // First, Last, as with GoToKey): the first and third see the last part row the page showed before as xRec, the second a blank one; on
    // OpenNew and on OpenEdit onto an empty first host all three are blank. (4) Last() on a part without OnAfterGetCurrRecord runs OnNewRecord
    // once and lands on the last row; First() on the first row reads nothing; with OnAfterGetRecord, First() from another row reads the row
    // twice. (5) every part shape tried (DelayedInsert only, AutoSplitKey only, neither, with OnAfterGetRecord) gives OnNewRecord the LAST row
    // of the part as xRec (BelowxRec Yes), from any current row; a typed new row from the first row gets 35000 with AutoSplitKey, 0 without.

    local procedure SeedQn(WithEmptyFirst: Boolean; WithLastLines: Boolean)
    var
        Head: Record "LT QJ Head";
        Line: Record "LT QJ Line";
    begin
        SeedQl();
        if WithEmptyFirst then begin
            Head."No." := 'H0';
            Head.Total := 0;
            Head.Descr := 'zero';
            Head.Note := 'zero';
            Head.Insert();
        end;
        if WithLastLines then begin
            Head."No." := 'H4';
            Head.Total := 4;
            Head.Descr := 'four';
            Head.Note := 'four';
            Head.Insert();
            Line."Doc No." := 'H4';
            Line."Line No." := 50000;
            Line.Qty := 5;
            Line.Amt := 5;
            Line.Insert();
        end;
        Log.Reset();
    end;

    local procedure StoredHeads(): Text
    var
        Head: Record "LT QJ Head";
        Result: Text;
    begin
        if Head.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += '[' + Head."No." + ']';
            until Head.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure QN_Both_NewPartRow_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'N.AGCR(0 a=0 x.a=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=0) N.Amt.V.end H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-amt-after-part', '5.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1 20000:q=0,a=5');
        Observer.Verify();
    end;

    [Test]
    procedure QN_SubPart_NewPartRow_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'N.AGCR(0 a=0 x.a=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=0) N.Amt.V.end N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-amt-after-part', '0.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_Default_NewPartRow_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'N.AGCR(0 a=0 x.a=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=0) N.Amt.V.end N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-amt-after-part', '0.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_Card_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CardBoth_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host Card Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_ListPlus_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host ListPlus";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_ListPlusBoth_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host ListPlus Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-open', 'H.AGR(t=1 x.t=0) H.AGCR(t=1 x.t=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0) H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_Card_NewPartRow_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'N.AGCR(0 a=0 x.a=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=0) N.Amt.V.end N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-amt-after-part', '0.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_ListPlusBoth_NewPartRow_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host ListPlus Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-new', 'N.AGCR(0 a=0 x.a=0) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=1) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=0) N.Amt.V.end H.AGR(t=1 x.t=1) H.AGCR(t=1 x.t=1)');
        Observer.Expect('part-line-after-part', '0');
        Observer.Expect('part-amt-after-part', '5.00');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1 20000:q=0,a=5');
        Observer.Verify();
    end;

    [Test]
    procedure QN_Both_HostEdited_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.TotalF.SetValue(9);
        Observer.Observe('log-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-host-edit', '');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=9 x.t=1) T.H.MOD(t=9 d=orig n=orig x.t=1 x.d=orig) N.Amt.V(5 x=1) N.Amt.V.end H.AGR(t=9 x.t=9) H.AGCR(t=9 x.t=9) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '9.00');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_SubPart_HostEdited_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.TotalF.SetValue(9);
        Observer.Observe('log-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-host-edit', '');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=9 x.t=1) T.H.MOD(t=9 d=orig n=orig x.t=1 x.d=orig) N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '9.00');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_Default_HostEdited_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.TotalF.SetValue(9);
        Observer.Observe('log-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-host-edit', '');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=9 x.t=1) T.H.MOD(t=9 d=orig n=orig x.t=1 x.d=orig) N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '9.00');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_Card_HostEdited_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Note Host Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.TotalF.SetValue(9);
        Observer.Observe('log-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-host-edit', '');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=9 x.t=1) T.H.MOD(t=9 d=orig n=orig x.t=1 x.d=orig) N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('host-total-after-part', '9.00');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('stored-after-part', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-part', '10000:q=1,a=1');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=9 d=orig n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_OpenEdit_FirstHostEmpty()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(true, false);
        TP.OpenEdit();
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('host-no', 'H0');
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_HostNext()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenEdit();
        TP.Next();
        Log.Take();
        Observer.Observe('next-result', Format(TP.Next()));
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-move', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('host-no', 'H3');
        Observer.Expect('log-move', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_HostPrevious()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, true);
        TP.OpenEdit();
        TP.Last();
        Log.Take();
        Observer.Observe('previous-result', Format(TP.Previous()));
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-move', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('previous-result', 'Yes');
        Observer.Expect('host-no', 'H3');
        Observer.Expect('log-move', 'S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0) S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_HostFirst()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(true, false);
        TP.OpenEdit();
        TP.Next();
        Log.Take();
        Observer.Observe('first-result', Format(TP.First()));
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-move', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('first-result', 'Yes');
        Observer.Expect('host-no', 'H0');
        Observer.Expect('log-move', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_HostLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenEdit();
        Log.Take();
        Observer.Observe('last-host-result', Format(TP.Last()));
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-move', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('last-host-result', 'Yes');
        Observer.Expect('host-no', 'H3');
        Observer.Expect('log-move', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_HostOpenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenNew();
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('heads-after-close', StoredHeads());
        Observer.Expect('host-no', '');
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('heads-after-close', '[] [H1] [H2] [H3]');
        Observer.Verify();
    end;

    [Test]
    procedure QN_EmptyPart_HostNext_ThenNextAgain()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, true);
        TP.OpenEdit();
        TP.Next();
        TP.Next();
        Log.Take();
        Observer.Observe('next-result', Format(TP.Next()));
        Observer.Observe('host-no', TP.NoF.Value());
        Observer.Observe('log-move', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('host-no', 'H4');
        Observer.Expect('log-move', 'S.AGCR(50000 r=5 x=3)');
        Observer.Expect('log-new', 'S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0)');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_Last_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line-after-new', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'A.AGR(10000 a=1 x=0 x.ln=0) A.AGR(30000 a=3 x=1 x.ln=10000) A.AGR(40000 a=4 x=3 x.ln=30000) A.AGR(30000 a=3 x=4 x.ln=40000)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('part-line-after-new', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_Last_OneLine()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line-after-new', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H1'));
        Observer.Expect('log-open', 'A.AGR(10000 a=1 x=0 x.ln=0)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'A.NEW(x=1 x.ln=10000 b=Yes)');
        Observer.Expect('part-line', '10000');
        Observer.Expect('log-new', 'A.NEW(x=1 x.ln=10000 b=Yes)');
        Observer.Expect('part-line-after-new', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_Last_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H3');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line-after-new', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H3'));
        Observer.Expect('log-open', 'A.AGR(10000 a=1 x=0 x.ln=0) A.AGR(30000 a=3 x=1 x.ln=10000) A.AGR(40000 a=4 x=3 x.ln=30000) A.AGR(30000 a=3 x=4 x.ln=40000) A.NEW(x=3 x.ln=30000 b=Yes) A.NEW(x=0 x.ln=0 b=Yes) A.NEW(x=3 x.ln=30000 b=Yes)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'A.NEW(x=3 x.ln=30000 b=Yes) A.NEW(x=3 x.ln=30000 b=Yes)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new', 'A.NEW(x=3 x.ln=30000 b=Yes)');
        Observer.Expect('part-line-after-new', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNewOnly_Last_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NewOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line-after-new', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', '');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'C.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'C.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('part-line-after-new', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNewOnly_Last_OneLine()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NewOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line-after-new', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H1'));
        Observer.Expect('log-open', '');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'C.NEW(x=1 x.ln=10000 b=Yes)');
        Observer.Expect('part-line', '10000');
        Observer.Expect('log-new', 'C.NEW(x=1 x.ln=10000 b=Yes)');
        Observer.Expect('part-line-after-new', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNewOnly_Last_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NewOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H3');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line-after-new', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H3'));
        Observer.Expect('log-open', 'C.NEW(x=3 x.ln=30000 b=Yes) C.NEW(x=0 x.ln=0 b=Yes) C.NEW(x=3 x.ln=30000 b=Yes)');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'C.NEW(x=3 x.ln=30000 b=Yes) C.NEW(x=3 x.ln=30000 b=Yes)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new', 'C.NEW(x=3 x.ln=30000 b=Yes)');
        Observer.Expect('part-line-after-new', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartAGR_First_OnFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host AGR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('first-result', Format(TP.Lines.First()));
        Observer.Observe('log-first', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        Observer.Observe('first-again-result', Format(TP.Lines.First()));
        Observer.Observe('log-first-again', Log.Take());
        Observer.Observe('part-line-after-first-again', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'B.AGR(10000 a=1 x=0 x.ln=0) B.AGR(10000 a=1 x=1 x.ln=10000) B.AGCR(10000 a=1 x=0 x.ln=0) B.AGR(30000 a=3 x=1 x.ln=10000) B.AGR(40000 a=4 x=3 x.ln=30000) B.AGR(30000 a=3 x=4 x.ln=40000) B.AGR(30000 a=3 x=3 x.ln=30000) B.AGCR(30000 a=3 x=1 x.ln=10000)');
        Observer.Expect('first-result', 'Yes');
        Observer.Expect('log-first', '');
        Observer.Expect('part-line', '30000');
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', 'B.AGR(40000 a=4 x=3 x.ln=30000) B.AGR(40000 a=4 x=4 x.ln=40000) B.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('first-again-result', 'Yes');
        Observer.Expect('log-first-again', 'B.AGR(30000 a=3 x=4 x.ln=40000) B.AGR(30000 a=3 x=3 x.ln=30000) B.AGCR(30000 a=3 x=4 x.ln=40000)');
        Observer.Expect('part-line-after-first-again', '30000');
        Observer.Expect('log-new', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_First_OnFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('first-result', Format(TP.Lines.First()));
        Observer.Observe('log-first', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        Observer.Observe('first-again-result', Format(TP.Lines.First()));
        Observer.Observe('log-first-again', Log.Take());
        Observer.Observe('part-line-after-first-again', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'A.AGR(10000 a=1 x=0 x.ln=0) A.AGR(30000 a=3 x=1 x.ln=10000) A.AGR(40000 a=4 x=3 x.ln=30000) A.AGR(30000 a=3 x=4 x.ln=40000)');
        Observer.Expect('first-result', 'Yes');
        Observer.Expect('log-first', '');
        Observer.Expect('part-line', '30000');
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', '');
        Observer.Expect('first-again-result', 'Yes');
        Observer.Expect('log-first-again', '');
        Observer.Expect('part-line-after-first-again', '30000');
        Observer.Expect('log-new', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartAGR_Last_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host AGR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0) B.AGR(40000 a=4 x=0 x.ln=0) B.AGR(40000 a=4 x=4 x.ln=40000) B.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartDelayedOnly_New_FromFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host DelayedOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'D.AGCR(10000 a=1 x=0 x.ln=0) D.AGCR(30000 a=3 x=1 x.ln=10000)');
        Observer.Expect('log-new', 'D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new-again', 'D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartDelayedOnly_NextNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host DelayedOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', 'D.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('log-new', 'D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartDelayedOnly_LastNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host DelayedOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0) D.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartDelayedOnly_NewTyped_ThenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host DelayedOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        TP.Lines.New();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-new-typed', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        Observer.Observe('lines-after-second-new', StoredLinesOf('H2'));
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-new-typed', 'D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-new-again', 'D.INSR(0 a=7 x=3 x.ln=30000) D.NEW(x=4 x.ln=40000 b=Yes) D.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('lines-after-second-new', '0:q=0,a=7 30000:q=3,a=3 40000:q=4,a=4');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '0:q=0,a=7 30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartSplitOnly_New_FromFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host SplitOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'E.AGCR(10000 a=1 x=0 x.ln=0) E.AGCR(30000 a=3 x=1 x.ln=10000)');
        Observer.Expect('log-new', 'E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new-again', 'E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartSplitOnly_NextNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host SplitOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', 'E.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('log-new', 'E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartSplitOnly_LastNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host SplitOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0) E.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartSplitOnly_NewTyped_ThenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host SplitOnly";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        TP.Lines.New();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-new-typed', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        Observer.Observe('lines-after-second-new', StoredLinesOf('H2'));
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-new-typed', 'E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-new-again', 'E.INSR(35000 a=7 x=3 x.ln=30000) E.NEW(x=4 x.ln=40000 b=Yes) E.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('lines-after-second-new', '30000:q=3,a=3 35000:q=0,a=7 40000:q=4,a=4');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 35000:q=0,a=7 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartPlain_New_FromFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host Plain";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'F.AGCR(10000 a=1 x=0 x.ln=0) F.AGCR(30000 a=3 x=1 x.ln=10000)');
        Observer.Expect('log-new', 'F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new-again', 'F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartPlain_NextNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host Plain";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', 'F.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('log-new', 'F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartPlain_LastNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host Plain";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0) F.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartPlain_NewTyped_ThenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host Plain";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        TP.Lines.New();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-new-typed', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        Observer.Observe('lines-after-second-new', StoredLinesOf('H2'));
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-new-typed', 'F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-new-again', 'F.INSR(0 a=7 x=3 x.ln=30000) F.NEW(x=4 x.ln=40000 b=Yes) F.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('lines-after-second-new', '0:q=0,a=7 30000:q=3,a=3 40000:q=4,a=4');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '0:q=0,a=7 30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartAGR_New_FromFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host AGR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'B.AGR(10000 a=1 x=0 x.ln=0) B.AGR(10000 a=1 x=1 x.ln=10000) B.AGCR(10000 a=1 x=0 x.ln=0) B.AGR(30000 a=3 x=1 x.ln=10000) B.AGR(40000 a=4 x=3 x.ln=30000) B.AGR(30000 a=3 x=4 x.ln=40000) B.AGR(30000 a=3 x=3 x.ln=30000) B.AGCR(30000 a=3 x=1 x.ln=10000)');
        Observer.Expect('log-new', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new-again', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartAGR_NextNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host AGR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', 'B.AGR(40000 a=4 x=3 x.ln=30000) B.AGR(40000 a=4 x=4 x.ln=40000) B.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('log-new', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartAGR_LastNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host AGR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0) B.AGR(40000 a=4 x=0 x.ln=0) B.AGR(40000 a=4 x=4 x.ln=40000) B.AGCR(40000 a=4 x=3 x.ln=30000)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartAGR_NewTyped_ThenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host AGR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        TP.Lines.New();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-new-typed', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        Observer.Observe('lines-after-second-new', StoredLinesOf('H2'));
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-new-typed', 'B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('log-new-again', 'B.INSR(35000 a=7 x=3 x.ln=30000) B.NEW(x=4 x.ln=40000 b=Yes) B.AGCR(0 a=0 x=0 x.ln=0)');
        Observer.Expect('lines-after-second-new', '30000:q=3,a=3 35000:q=0,a=7 40000:q=4,a=4');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 35000:q=0,a=7 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_New_FromFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-open', 'A.AGR(10000 a=1 x=0 x.ln=0) A.AGR(30000 a=3 x=1 x.ln=10000) A.AGR(40000 a=4 x=3 x.ln=30000) A.AGR(30000 a=3 x=4 x.ln=40000)');
        Observer.Expect('log-new', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-new-again', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_NextNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('next-result', Format(TP.Lines.Next()));
        Observer.Observe('log-next', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('next-result', 'Yes');
        Observer.Expect('log-next', '');
        Observer.Expect('log-new', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_LastNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('part-line', '40000');
        Observer.Expect('log-new', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 40000:q=4,a=4');
        Observer.Verify();
    end;

    [Test]
    procedure QN_PartNoAGCR_NewTyped_ThenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QN Host NoAGCR";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Log.Take();
        TP.Lines.New();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-new-typed', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new-again', Log.Take());
        Observer.Observe('lines-after-second-new', StoredLinesOf('H2'));
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Expect('log-new-typed', 'A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('log-new-again', 'A.INSR(35000 a=7 x=3 x.ln=30000) A.NEW(x=4 x.ln=40000 b=Yes)');
        Observer.Expect('lines-after-second-new', '30000:q=3,a=3 35000:q=0,a=7 40000:q=4,a=4');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '30000:q=3,a=3 35000:q=0,a=7 40000:q=4,a=4');
        Observer.Verify();
    end;

    // ---- Writer QT (2026-10-22): (a) al-runtime-rs bump 44 pin PR 5620: Last() (and First, Next, New) on an EMPTY part whose table has an
    // OnValidate on its key fields ("LT QT Val Line"), for AutoSplitKey + DelayedInsert, DelayedInsert only and neither; with the key
    // OnValidate raising an error; and a part with two lines as the control. (b) the host's reads at open, in order, for Card, Card Both,
    // ListPlus, ListPlus Both and Document hosts with part "LT QL Note Lines" (OpenEdit, then GoToKey, then a part Update(false); OpenView;
    // three heads with GoToKey + Next). (c) QN_EmptyPart_HostOpenNew and QN_EmptyPart_HostNext_ThenNextAgain step by step. Objects in
    // QtPartObjects.al. ----

    local procedure SeedQtVal(Fail: Boolean; WithLines: Boolean)
    var
        Head: Record "LT QJ Head";
        Line: Record "LT QT Val Line";
    begin
        Seed();
        Line.DeleteAll();
        if Fail then begin
            Head.Get('H1');
            Head.Note := 'fail';
            Head.Modify();
        end;
        if WithLines then begin
            Line."Doc No." := 'H1';
            Line."Line No." := 10000;
            Line.Amt := 1;
            Line.Insert();
            Line."Line No." := 20000;
            Line.Amt := 2;
            Line.Insert();
        end;
        Log.Reset();
    end;

    local procedure StoredValLines(): Text
    var
        Line: Record "LT QT Val Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Line."Doc No." + ':' + Format(Line."Line No.") + ':a=' + Format(Line.Amt);
            until Line.Next() = 0;
        exit('[' + Result + ']');
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_Last()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-last', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-openedit', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('log-gotokey', '');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('part-amt', '0.00');
        Observer.Expect('lines-after-last', '[]');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_Last_ThenType()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.Last();
        Log.Take();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-type', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('lines-after-type', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-type', '');
        Observer.Expect('part-line', '0');
        Observer.Expect('lines-after-type', '[]');
        Observer.Expect('log-close', 'V.INSR(H1 10000 a=7 below=Yes) T.INS(H1 10000 a=7)');
        Observer.Expect('lines-after-close', '[H1:10000:a=7]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartSplit_TwoLines_Last()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, true);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-open', 'V.AGR(H1 10000 a=1) V.AGR(H1 20000 a=2) V.AGR(H1 10000 a=1) V.AGR(H1 10000 a=1) V.AGCR(H1 10000 a=1 x=H1 0)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'T.Doc.V(H1 x=H1 ln=0) V.NEW(H1 0 x=H1 20000 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) V.AGR(H1 20000 a=2) V.AGR(H1 20000 a=2) V.AGCR(H1 20000 a=2 x=H1 10000)');
        Observer.Expect('part-line', '20000');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[H1:10000:a=1 H1:20000:a=2]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartDelayed_Empty_Last()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Delayed";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-last', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-openedit', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('log-gotokey', '');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('part-amt', '0.00');
        Observer.Expect('lines-after-last', '[]');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartDelayed_Empty_Last_ThenType()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Delayed";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.Last();
        Log.Take();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-type', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('lines-after-type', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-type', '');
        Observer.Expect('part-line', '0');
        Observer.Expect('lines-after-type', '[]');
        Observer.Expect('log-close', 'V.INSR(H1 0 a=7 below=Yes) T.INS(H1 0 a=7)');
        Observer.Expect('lines-after-close', '[H1:0:a=7]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartDelayed_TwoLines_Last()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Delayed";
    begin
        SeedQtVal(false, true);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-open', 'V.AGR(H1 10000 a=1) V.AGR(H1 20000 a=2) V.AGR(H1 10000 a=1) V.AGR(H1 10000 a=1) V.AGCR(H1 10000 a=1 x=H1 0)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'T.Doc.V(H1 x=H1 ln=0) V.NEW(H1 0 x=H1 20000 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) V.AGR(H1 20000 a=2) V.AGR(H1 20000 a=2) V.AGCR(H1 20000 a=2 x=H1 10000)');
        Observer.Expect('part-line', '20000');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[H1:10000:a=1 H1:20000:a=2]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartPlain_Empty_Last()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Plain";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('part-amt', TP.Lines.AmtF.Value());
        Observer.Observe('lines-after-last', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-openedit', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('log-gotokey', '');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('part-amt', '0.00');
        Observer.Expect('lines-after-last', '[]');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartPlain_Empty_Last_ThenType()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Plain";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.Last();
        Log.Take();
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-type', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        Observer.Observe('lines-after-type', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-type', 'V.INSR(H1 0 a=0 below=Yes) T.INS(H1 0 a=0)');
        Observer.Expect('part-line', '0');
        Observer.Expect('lines-after-type', '[H1:0:a=0]');
        Observer.Expect('log-close', 'V.MODR(H1 0 a=7)');
        Observer.Expect('lines-after-close', '[H1:0:a=7]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartPlain_TwoLines_Last()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Plain";
    begin
        SeedQtVal(false, true);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-open', 'V.AGR(H1 10000 a=1) V.AGR(H1 20000 a=2) V.AGR(H1 10000 a=1) V.AGR(H1 10000 a=1) V.AGCR(H1 10000 a=1 x=H1 0)');
        Observer.Expect('last-result', 'Yes');
        Observer.Expect('log-last', 'T.Doc.V(H1 x=H1 ln=0) V.NEW(H1 0 x=H1 20000 below=Yes) V.AGCR(H1 0 a=0 x=H1 0) V.AGR(H1 20000 a=2) V.AGR(H1 20000 a=2) V.AGCR(H1 20000 a=2 x=H1 10000)');
        Observer.Expect('part-line', '20000');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[H1:10000:a=1 H1:20000:a=2]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure QtTryOpenSplit(var TP: TestPage "LT QT Val Host Split")
    begin
        TP.OpenEdit();
        TP.GoToKey('H1');
    end;

    [TryFunction]
    local procedure QtTryLastSplit(var TP: TestPage "LT QT Val Host Split"; var Result: Boolean)
    begin
        Result := TP.Lines.Last();
    end;

    [TryFunction]
    local procedure QtTryTypeSplit(var TP: TestPage "LT QT Val Host Split")
    begin
        TP.Lines.AmtF.SetValue(7);
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_Last_KeyValidateErrors()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
        Result: Boolean;
    begin
        SeedQtVal(true, false);
        if QtTryOpenSplit(TP) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if QtTryLastSplit(TP, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if QtTryTypeSplit(TP) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        Observer.Observe('lines-after-type', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('open', 'ok');
        Observer.Expect('log-open', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('last', 'ok No');
        Observer.Expect('log-last', '');
        Observer.Expect('type|text', 'The row does not exist on the TestPage.');
        Observer.Expect('type|code', 'TestRowNotFound');
        Observer.Expect('log-type', '');
        Observer.Expect('lines-after-type', '[]');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure QtTryOpenPlain(var TP: TestPage "LT QT Val Host Plain")
    begin
        TP.OpenEdit();
        TP.GoToKey('H1');
    end;

    [TryFunction]
    local procedure QtTryLastPlain(var TP: TestPage "LT QT Val Host Plain"; var Result: Boolean)
    begin
        Result := TP.Lines.Last();
    end;

    [TryFunction]
    local procedure QtTryTypePlain(var TP: TestPage "LT QT Val Host Plain")
    begin
        TP.Lines.AmtF.SetValue(7);
    end;

    [Test]
    procedure QT_ValPartPlain_Empty_Last_KeyValidateErrors()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Plain";
        Result: Boolean;
    begin
        SeedQtVal(true, false);
        if QtTryOpenPlain(TP) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if QtTryLastPlain(TP, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if QtTryTypePlain(TP) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        Observer.Observe('lines-after-type', StoredValLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('open', 'ok');
        Observer.Expect('log-open', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('last', 'ok No');
        Observer.Expect('log-last', '');
        Observer.Expect('type|text', 'The row does not exist on the TestPage.');
        Observer.Expect('type|code', 'TestRowNotFound');
        Observer.Expect('log-type', '');
        Observer.Expect('lines-after-type', '[]');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_First()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        Observer.Observe('result', Format(TP.Lines.First()));
        Observer.Observe('log', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('result', 'No');
        Observer.Expect('log', '');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        Observer.Observe('result', Format(TP.Lines.Next()));
        Observer.Observe('log', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('result', 'No');
        Observer.Expect('log', '');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_Previous()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        Observer.Observe('result', Format(TP.Lines.Previous()));
        Observer.Observe('log', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('result', 'No');
        Observer.Expect('log', '');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_ValPartSplit_Empty_New_ThenType()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Val Host Split";
    begin
        SeedQtVal(false, false);
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-type', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredValLines());
        Observer.Expect('log-new', 'T.Doc.V(H1 x= ln=0) V.NEW(H1 0 x= 0 below=Yes) V.AGCR(H1 0 a=0 x=H1 0)');
        Observer.Expect('log-type', '');
        Observer.Expect('part-line', '0');
        Observer.Expect('log-close', 'V.INSR(H1 20000 a=7 below=Yes) T.INS(H1 20000 a=7)');
        Observer.Expect('lines-after-close', '[H1:20000:a=7]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCard_OpenEdit_GoToKey_PartUpdate()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCard_OpenEdit_PartUpdate_NoGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCard_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('log-openview', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openview', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCard_ThreeHeads_GoToKeyH2_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('next', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) H.AGR(H2 t=2 x=H1) H.AGCR(H2 t=2 x=H1) N.AGR(30000 a=3 x.a=1) N.AGR(40000 a=4 x.a=3) N.AGR(30000 a=3 x.a=4) N.AGR(30000 a=3 x.a=3) N.AGCR(30000 a=3 x.a=1)');
        Observer.Expect('next', 'Yes|H3');
        Observer.Expect('log-next', 'H.AGR(H3 t=3 x=H2) H.AGCR(H3 t=3 x=H2) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCardBoth_OpenEdit_GoToKey_PartUpdate()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host Both";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCardBoth_OpenEdit_PartUpdate_NoGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host Both";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCardBoth_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host Both";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('log-openview', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openview', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostCardBoth_ThreeHeads_GoToKeyH2_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Card Host Both";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('next', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) H.AGR(H2 t=2 x=H1) H.AGCR(H2 t=2 x=H1) N.AGR(30000 a=3 x.a=1) N.AGR(40000 a=4 x.a=3) N.AGR(30000 a=3 x.a=4) N.AGR(30000 a=3 x.a=3) N.AGCR(30000 a=3 x.a=1)');
        Observer.Expect('next', 'Yes|H3');
        Observer.Expect('log-next', 'H.AGR(H3 t=3 x=H2) H.AGCR(H3 t=3 x=H2) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlus_OpenEdit_GoToKey_PartUpdate()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlus_OpenEdit_PartUpdate_NoGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlus_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('log-openview', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openview', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlus_ThreeHeads_GoToKeyH2_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('next', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) H.AGR(H2 t=2 x=H1) H.AGCR(H2 t=2 x=H1) N.AGR(30000 a=3 x.a=1) N.AGR(40000 a=4 x.a=3) N.AGR(30000 a=3 x.a=4) N.AGR(30000 a=3 x.a=3) N.AGCR(30000 a=3 x.a=1)');
        Observer.Expect('next', 'Yes|H3');
        Observer.Expect('log-next', 'H.AGR(H3 t=3 x=H2) H.AGCR(H3 t=3 x=H2) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlusBoth_OpenEdit_GoToKey_PartUpdate()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host Both";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlusBoth_OpenEdit_PartUpdate_NoGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host Both";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlusBoth_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host Both";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('log-openview', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openview', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostListPlusBoth_ThreeHeads_GoToKeyH2_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT ListPlus Host Both";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('next', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) H.AGR(H2 t=2 x=H1) H.AGCR(H2 t=2 x=H1) N.AGR(30000 a=3 x.a=1) N.AGR(40000 a=4 x.a=3) N.AGR(30000 a=3 x.a=4) N.AGR(30000 a=3 x.a=3) N.AGCR(30000 a=3 x.a=1)');
        Observer.Expect('next', 'Yes|H3');
        Observer.Expect('log-next', 'H.AGR(H3 t=3 x=H2) H.AGCR(H3 t=3 x=H2) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostDoc_OpenEdit_GoToKey_PartUpdate()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Doc Host";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('part-amt-after-part', TP.Lines.AmtF.Value());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('part-amt-after-part', '1.00');
        Observer.Expect('host-total-after-part', '1.00');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostDoc_OpenEdit_PartUpdate_NoGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Doc Host";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-part-edit', 'N.Amt.V(5 x=1) N.Amt.V.end N.AGR(10000 a=1 x.a=1) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=5)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostDoc_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Doc Host";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('log-openview', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openview', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_HostDoc_ThreeHeads_GoToKeyH2_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QT Doc Host";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-openedit', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey', Log.Take());
        Observer.Observe('next', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-openedit', 'H.OPEN() H.AGR(H1 t=1 x=) H.AGCR(H1 t=1 x=) N.AGR(10000 a=1 x.a=0) N.AGR(10000 a=1 x.a=1) N.AGCR(10000 a=1 x.a=0)');
        Observer.Expect('log-gotokey', 'H.AGR(H1 t=1 x=H1) H.AGCR(H1 t=1 x=H1) H.AGR(H2 t=2 x=H1) H.AGCR(H2 t=2 x=H1) N.AGR(30000 a=3 x.a=1) N.AGR(40000 a=4 x.a=3) N.AGR(30000 a=3 x.a=4) N.AGR(30000 a=3 x.a=3) N.AGCR(30000 a=3 x.a=1)');
        Observer.Expect('next', 'Yes|H3');
        Observer.Expect('log-next', 'H.AGR(H3 t=3 x=H2) H.AGCR(H3 t=3 x=H2) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0) N.AGCR(0 a=0 x.a=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostOpenNew_CloseOnly()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenNew();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('heads-after-open', StoredHeads());
        Observer.Observe('heads-before-close', StoredHeads());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('heads-after-close', StoredHeads());
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-after-open', '[H1] [H2] [H3]');
        Observer.Expect('heads-before-close', '[H1] [H2] [H3]');
        Observer.Expect('log-close', '');
        Observer.Expect('heads-after-close', '[H1] [H2] [H3]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostOpenNew_LastOnly()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenNew();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('heads-after-open', StoredHeads());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        Observer.Observe('heads-before-close', StoredHeads());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('heads-after-close', StoredHeads());
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-after-open', '[H1] [H2] [H3]');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-before-close', '[] [H1] [H2] [H3]');
        Observer.Expect('log-close', '');
        Observer.Expect('heads-after-close', '[] [H1] [H2] [H3]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostOpenNew_NewOnly()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenNew();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('heads-after-open', StoredHeads());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('heads-before-close', StoredHeads());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('heads-after-close', StoredHeads());
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-after-open', '[H1] [H2] [H3]');
        Observer.Expect('log-new', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-before-close', '[] [H1] [H2] [H3]');
        Observer.Expect('log-close', '');
        Observer.Expect('heads-after-close', '[] [H1] [H2] [H3]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostOpenNew_LastThenNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenNew();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('heads-after-open', StoredHeads());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        Observer.Observe('heads-before-close', StoredHeads());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('heads-after-close', StoredHeads());
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-after-open', '[H1] [H2] [H3]');
        Observer.Expect('last-result', 'No');
        Observer.Expect('log-last', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-new', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-before-close', '[] [H1] [H2] [H3]');
        Observer.Expect('log-close', '');
        Observer.Expect('heads-after-close', '[] [H1] [H2] [H3]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostOpenNew_ReadHostOnly()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, false);
        TP.OpenNew();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('heads-after-open', StoredHeads());
        Observer.Observe('host-descr', TP.DescrF.Value());
        Observer.Observe('log-read', Log.Take());
        Observer.Observe('heads-before-close', StoredHeads());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('heads-after-close', StoredHeads());
        Observer.Expect('log-open', 'S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0)');
        Observer.Expect('heads-after-open', '[H1] [H2] [H3]');
        Observer.Expect('host-descr', '');
        Observer.Expect('log-read', '');
        Observer.Expect('heads-before-close', '[H1] [H2] [H3]');
        Observer.Expect('log-close', '');
        Observer.Expect('heads-after-close', '[H1] [H2] [H3]');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostNext_Steps()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, true);
        TP.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('next-1', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next-1', Log.Take());
        Observer.Observe('next-2', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next-2', Log.Take());
        Observer.Observe('next-3', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next-3', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0)');
        Observer.Expect('next-1', 'Yes|H2');
        Observer.Expect('log-next-1', 'S.AGCR(30000 r=3 x=1)');
        Observer.Expect('next-2', 'Yes|H3');
        Observer.Expect('log-next-2', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('next-3', 'Yes|H4');
        Observer.Expect('log-next-3', 'S.AGCR(50000 r=5 x=3)');
        Observer.Expect('log-new', 'S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_EmptyPart_HostNext_Steps_ReadPartLine()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQn(false, true);
        TP.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('next-1', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next-1', Log.Take());
        Observer.Observe('part-line-1', TP.Lines.LineNoF.Value());
        Observer.Observe('log-read-1', Log.Take());
        Observer.Observe('next-2', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next-2', Log.Take());
        Observer.Observe('part-line-2', TP.Lines.LineNoF.Value());
        Observer.Observe('log-read-2', Log.Take());
        Observer.Observe('next-3', Format(TP.Next()) + '|' + TP.NoF.Value());
        Observer.Observe('log-next-3', Log.Take());
        Observer.Observe('part-line-3', TP.Lines.LineNoF.Value());
        Observer.Observe('log-read-3', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0)');
        Observer.Expect('next-1', 'Yes|H2');
        Observer.Expect('log-next-1', 'S.AGCR(30000 r=3 x=1)');
        Observer.Expect('part-line-1', '30000');
        Observer.Expect('log-read-1', '');
        Observer.Expect('next-2', 'Yes|H3');
        Observer.Expect('log-next-2', 'S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0) S.NEW(x=0 x.ln=0) S.AGCR(0 r=0 x=0) S.NEW(x=3 x.ln=30000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('part-line-2', '0');
        Observer.Expect('log-read-2', '');
        Observer.Expect('next-3', 'Yes|H4');
        Observer.Expect('log-next-3', 'S.AGCR(50000 r=5 x=3)');
        Observer.Expect('part-line-3', '50000');
        Observer.Expect('log-read-3', '');
        Observer.Expect('log-new', 'S.NEW(x=5 x.ln=50000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-close', '');
        Observer.Verify();
    end;

    // Writer RP (al-runner issue 5765): a main Card, a ListPart (Sub A) and a FactBox CardPart, each with a control bound to
    // State.GetValue() of ONE codeunit instance ("LT RP State", not SingleInstance) handed to all three pages. Pins when each
    // page shows a changed state: after a FactBox action (with and without CurrPage.Update(false) in it), after a main-page
    // action (with and without CurrPage.Update(false)), after test code changes the state, after navigating the main page
    // or a part. Sub A declares an empty OnAfterGetCurrRecord (the reporter's shape), Sub B declares no trigger. RpObserve walks Sub A to its
    // first row before it reads (the reporter's shape); RpRead does not navigate.
    local procedure RpOpenMain(var MainTestPage: TestPage "LT RP State Main"; var State: Codeunit "LT RP State")
    var
        TempParam: Record "LT RP Param" temporary;
        MainPage: Page "LT RP State Main";
        i: Integer;
    begin
        for i := 1 to 3 do begin
            TempParam.Init();
            TempParam."Code" := CopyStr('ABC', i, 1);
            TempParam.Insert();
        end;
        MainPage.SetParam(TempParam);
        MainPage.SetState(State);
        MainTestPage.Trap();
        MainPage.Run();
    end;

    local procedure RpObserve(var MainTestPage: TestPage "LT RP State Main"; var State: Codeunit "LT RP State"): Text
    begin
        MainTestPage.SubA.First();
        exit(StrSubstNo('test=%1;main=%2;subA=%3;subB=%4;factbox=%5', State.GetValue(), MainTestPage.StateValue.Value(), MainTestPage.SubA.StateValue.Value(), MainTestPage.SubB.StateValue.Value(), MainTestPage.Factbox.StateValue.Value()));
    end;

    local procedure RpRead(var MainTestPage: TestPage "LT RP State Main"; var State: Codeunit "LT RP State"): Text
    begin
        exit(StrSubstNo('test=%1;main=%2;subA=%3;subB=%4;factbox=%5', State.GetValue(), MainTestPage.StateValue.Value(), MainTestPage.SubA.StateValue.Value(), MainTestPage.SubB.StateValue.Value(), MainTestPage.Factbox.StateValue.Value()));
    end;

    [Test]
    procedure RP_SharedState_FactBoxAction()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT RP State";
        MainTestPage: TestPage "LT RP State Main";
    begin
        RpOpenMain(MainTestPage, State);
        Observer.Observe('opened', RpRead(MainTestPage, State));
        MainTestPage.Factbox.SetState42.Invoke();
        Observer.Observe('after_factbox_action_read', RpRead(MainTestPage, State));
        Observer.Observe('after_factbox_action', RpObserve(MainTestPage, State));
        MainTestPage.UpdatePage.Invoke();
        Observer.Observe('after_main_update', RpObserve(MainTestPage, State));
        MainTestPage.Close();
        Observer.Expect('opened', 'test=0;main=0;subA=0;subB=0;factbox=0');
        Observer.Expect('after_factbox_action_read', 'test=42;main=0;subA=0;subB=0;factbox=42');
        Observer.Expect('after_factbox_action', 'test=42;main=0;subA=42;subB=0;factbox=42');
        Observer.Expect('after_main_update', 'test=42;main=42;subA=42;subB=42;factbox=42');
        Observer.Verify();
    end;

    [Test]
    procedure RP_SharedState_FactBoxActionWithUpdate()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT RP State";
        MainTestPage: TestPage "LT RP State Main";
    begin
        RpOpenMain(MainTestPage, State);
        MainTestPage.Factbox.SetState42AndUpdate.Invoke();
        Observer.Observe('main_factbox', StrSubstNo('main=%1;factbox=%2', MainTestPage.StateValue.Value(), MainTestPage.Factbox.StateValue.Value()));
        Observer.Observe('after_factbox_update', RpRead(MainTestPage, State));
        MainTestPage.Close();
        Observer.Expect('main_factbox', 'main=0;factbox=42');
        Observer.Expect('after_factbox_update', 'test=42;main=0;subA=0;subB=0;factbox=42');
        Observer.Verify();
    end;

    [Test]
    procedure RP_SharedState_TestCodeChangesState()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT RP State";
        MainTestPage: TestPage "LT RP State Main";
    begin
        RpOpenMain(MainTestPage, State);
        State.SetValue(7);
        Observer.Observe('after_set_read', RpRead(MainTestPage, State));
        Observer.Observe('after_set', RpObserve(MainTestPage, State));
        MainTestPage.SubA.Next();
        Observer.Observe('after_sub_next', RpRead(MainTestPage, State));
        MainTestPage.Next();
        Observer.Observe('after_main_next', RpRead(MainTestPage, State));
        State.SetValue(9);
        MainTestPage.UpdatePage.Invoke();
        Observer.Observe('after_main_update', RpRead(MainTestPage, State));
        MainTestPage.Close();
        Observer.Expect('after_set_read', 'test=7;main=0;subA=0;subB=0;factbox=0');
        Observer.Expect('after_set', 'test=7;main=0;subA=7;subB=0;factbox=0');
        Observer.Expect('after_sub_next', 'test=7;main=0;subA=7;subB=0;factbox=0');
        Observer.Expect('after_main_next', 'test=7;main=0;subA=7;subB=0;factbox=0');
        Observer.Expect('after_main_update', 'test=9;main=9;subA=9;subB=9;factbox=9');
        Observer.Verify();
    end;

    [Test]
    procedure RP_SharedState_MainAction()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT RP State";
        MainTestPage: TestPage "LT RP State Main";
    begin
        RpOpenMain(MainTestPage, State);
        MainTestPage.SetState5.Invoke();
        Observer.Observe('after_main_action', RpRead(MainTestPage, State));
        MainTestPage.SetState6AndUpdate.Invoke();
        Observer.Observe('after_main_action_update', RpRead(MainTestPage, State));
        MainTestPage.Close();
        Observer.Expect('after_main_action', 'test=5;main=5;subA=5;subB=5;factbox=5');
        Observer.Expect('after_main_action_update', 'test=6;main=6;subA=6;subB=6;factbox=6');
        Observer.Verify();
    end;
}

// Writer RP (al-runner issue 5765): one state codeunit instance shared by a main page, a ListPart and a FactBox.
codeunit 88399 "LT RP State"
{
    var
        Value: Integer;

    procedure SetValue(NewValue: Integer)
    begin
        Value := NewValue;
    end;

    procedure GetValue(): Integer
    begin
        exit(Value);
    end;
}

table 88400 "LT RP Param"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 88401 "LT RP State Main"
{
    PageType = Card;
    SourceTable = "LT RP Param";
    SourceTableTemporary = true;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { }
                field(StateValue; State.GetValue()) { }
            }
            part(SubA; "LT RP State Sub") { }
            part(SubB; "LT RP State Sub Plain") { }
        }
        area(FactBoxes)
        {
            part(Factbox; "LT RP State Factbox") { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdatePage)
            {
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(SetState5)
            {
                trigger OnAction()
                begin
                    State.SetValue(5);
                end;
            }
            action(SetState6AndUpdate)
            {
                trigger OnAction()
                begin
                    State.SetValue(6);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Copy(TempParamSource, true);
        CurrPage.SubA.Page.SetSource(Rec);
        CurrPage.SubA.Page.SetState(State);
        CurrPage.SubB.Page.SetSource(Rec);
        CurrPage.SubB.Page.SetState(State);
        CurrPage.Factbox.Page.SetSource(Rec);
        CurrPage.Factbox.Page.SetState(State);
    end;

    var
        TempParamSource: Record "LT RP Param" temporary;
        State: Codeunit "LT RP State";

    procedure SetParam(var TempParam: Record "LT RP Param" temporary)
    begin
        TempParamSource.Copy(TempParam, true);
    end;

    procedure SetState(NewState: Codeunit "LT RP State")
    begin
        State := NewState;
    end;
}

page 88402 "LT RP State Sub"
{
    PageType = ListPart;
    SourceTable = "LT RP Param";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { }
                field(StateValue; State.GetValue()) { }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        State: Codeunit "LT RP State";

    procedure SetSource(var TempParam: Record "LT RP Param" temporary)
    begin
        Rec.Copy(TempParam, true);
    end;

    procedure SetState(NewState: Codeunit "LT RP State")
    begin
        State := NewState;
    end;
}

page 88404 "LT RP State Sub Plain"
{
    PageType = ListPart;
    SourceTable = "LT RP Param";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { }
                field(StateValue; State.GetValue()) { }
            }
        }
    }

    var
        State: Codeunit "LT RP State";

    procedure SetSource(var TempParam: Record "LT RP Param" temporary)
    begin
        Rec.Copy(TempParam, true);
    end;

    procedure SetState(NewState: Codeunit "LT RP State")
    begin
        State := NewState;
    end;
}

page 88403 "LT RP State Factbox"
{
    PageType = CardPart;
    SourceTable = "LT RP Param";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(StateValue; State.GetValue()) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetState42)
            {
                trigger OnAction()
                begin
                    State.SetValue(42);
                end;
            }
            action(SetState42AndUpdate)
            {
                trigger OnAction()
                begin
                    State.SetValue(42);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        State: Codeunit "LT RP State";

    procedure SetSource(var TempParam: Record "LT RP Param" temporary)
    begin
        Rec.Copy(TempParam, true);
    end;

    procedure SetState(NewState: Codeunit "LT RP State")
    begin
        State := NewState;
    end;
}

