// Fixtures of writer QL (2026-10-21) for LT PnG Refresh (codeunit 70177): a list action that puts another row into Rec
// (Rec := Other with changed fields), and a journal-like list filtered in filter group 2 to one template and batch that loses its only row
// to an action. Logs go to LT PnG Log (table backed). Asked by al-runtime-rs PR 387 (Tests-ERM 134918/134022 Apply Customer Entries
// Post Application `Rec := TempApplyingCustLedgEntry`; 134002/134024 General Journal blank line after the only row is posted).

table 86974 "LT QL Act Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('T.INS(' + "No." + ',' + Name + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('T.MOD(' + "No." + ',' + Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('T.REN(' + "No." + ',' + Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;
}

page 86975 "LT QL Act List"
{
    PageType = List;
    SourceTable = "LT QL Act Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
                field(QtyF; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakeOtherChanged)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherChangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherChangedUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    CurrPage.Update(false);
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeTempChanged)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                    TempRow: Record "LT QL Act Row" temporary;
                begin
                    Other.Get('B');
                    TempRow := Other;
                    TempRow.Name := 'temp B';
                    TempRow.Insert();
                    Rec := TempRow;
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherUnchanged)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Rec := Other;
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(ChangeOwnRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Name := 'own changed';
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec."No." + ',' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MODR(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INSR(' + Rec."No." + ',' + Rec.Name + ')');
    end;
}

table 86976 "LT QL Jnl Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Template; Code[10])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT PnG Log";
            begin
                Log.Add('T.Template.V(' + Template + ')');
            end;
        }
        field(2; Batch; Code[10])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT PnG Log";
            begin
                Log.Add('T.Batch.V(' + Batch + ')');
            end;
        }
        field(3; "Line No."; Integer) { }
        field(4; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Template, Batch, "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('T.INS(' + Template + '/' + Batch + '/' + Format("Line No.") + ',' + Descr + ')');
    end;
}

page 86977 "LT QL Jnl Sheet FG2"
{
    PageType = Worksheet;
    SourceTable = "LT QL Jnl Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TemplateF; Rec.Template) { ApplicationArea = All; }
                field(BatchF; Rec.Batch) { ApplicationArea = All; }
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
            action(DeleteWithUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Template, 'T1');
        Rec.SetRange(Batch, 'B1');
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ' x=' + xRec.Template + '/' + xRec.Batch + '/' + Format(xRec."Line No.") + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ' x=' + xRec.Template + '/' + xRec.Batch + '/' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INSR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ',' + Rec.Descr + ')');
    end;
}

page 86978 "LT QL Jnl List FG2"
{
    PageType = List;
    SourceTable = "LT QL Jnl Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TemplateF; Rec.Template) { ApplicationArea = All; }
                field(BatchF; Rec.Batch) { ApplicationArea = All; }
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
            action(DeleteWithUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Template, 'T1');
        Rec.SetRange(Batch, 'B1');
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ' x=' + xRec.Template + '/' + xRec.Batch + '/' + Format(xRec."Line No.") + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ' x=' + xRec.Template + '/' + xRec.Batch + '/' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INSR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ',' + Rec.Descr + ')');
    end;
}

page 86979 "LT QL Jnl Sheet FG0"
{
    PageType = Worksheet;
    SourceTable = "LT QL Jnl Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TemplateF; Rec.Template) { ApplicationArea = All; }
                field(BatchF; Rec.Batch) { ApplicationArea = All; }
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
            action(DeleteWithUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";

    trigger OnOpenPage()
    begin
        Rec.SetRange(Template, 'T1');
        Rec.SetRange(Batch, 'B1');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ' x=' + xRec.Template + '/' + xRec.Batch + '/' + Format(xRec."Line No.") + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ' x=' + xRec.Template + '/' + xRec.Batch + '/' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec) + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INSR(' + Rec.Template + '/' + Rec.Batch + '/' + Format(Rec."Line No.") + ',' + Rec.Descr + ')');
    end;
}

// ---- Writer QN (2026-10-21): the same list actions with CurrPage.Close() on pages that declare OnQueryClosePage and OnClosePage
// (Worksheet and List), asked by al-runtime-rs PR 5594 (Apply Customer Entries page 232, Post Application). ----

page 87036 "LT QN Close Sheet"
{
    PageType = Worksheet;
    SourceTable = "LT QL Act Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
                field(QtyF; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakeOtherChangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherUnchangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Rec := Other;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeTempChangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                    TempRow: Record "LT QL Act Row" temporary;
                begin
                    Other.Get('B');
                    TempRow := Other;
                    TempRow.Name := 'temp B';
                    TempRow.Insert();
                    Rec := TempRow;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(ChangeOwnRowClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Name := 'own changed';
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(CloseOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherChanged)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec."No." + ',' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MODR(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INSR(' + Rec."No." + ',' + Rec.Name + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('P.QCP(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ' a=' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('P.CP(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;
}

page 87037 "LT QN Close List"
{
    PageType = List;
    SourceTable = "LT QL Act Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
                field(QtyF; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakeOtherChangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherUnchangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Rec := Other;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeTempChangedClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                    TempRow: Record "LT QL Act Row" temporary;
                begin
                    Other.Get('B');
                    TempRow := Other;
                    TempRow.Name := 'temp B';
                    TempRow.Insert();
                    Rec := TempRow;
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(ChangeOwnRowClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Name := 'own changed';
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(CloseOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Close();
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
            action(TakeOtherChanged)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT QL Act Row";
                begin
                    Other.Get('B');
                    Other.Name := 'changed B';
                    Rec := Other;
                    Log.Add('ACT.end(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT PnG Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec."No." + ',' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MODR(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INSR(' + Rec."No." + ',' + Rec.Name + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('P.QCP(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ' a=' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('P.CP(' + Rec."No." + ',' + Rec.Name + ' x=' + xRec."No." + ',' + xRec.Name + ')');
    end;
}
