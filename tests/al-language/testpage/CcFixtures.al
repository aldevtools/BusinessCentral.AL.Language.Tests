// Fixtures for CcPageLeads.al (test codeunit 84275 "LT CC Page Leads"): tables 84220-84223, pages 84230-84248, worker codeunit 84271.
// The log codeunit "LT CC Log" (84270) is SingleInstance and used only by test codeunit 84275.

table 84220 "LT CC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Grp; Integer) { }
        field(4; Flag; Boolean) { }
        field(5; D; Date) { }
        field(6; Big; BigInteger) { }
        field(7; FlowShown; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CC Line".Amt where(Id = field(Id)));
        }
        field(8; FlowHidden; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CC Line".Amt where(Id = field(Id)));
        }
        field(9; FlowAbsent; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CC Line".Amt where(Id = field(Id)));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 84221 "LT CC Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Amt; Decimal) { }
    }

    keys { key(PK; Id, LineNo) { Clustered = true; } }
}

table 84222 "LT CC Cfn Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT CC Log";
            begin
                Log.Add('Name.OnValidate cur=' + Format(CurrFieldNo));
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('OnInsert cur=' + Format(CurrFieldNo));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('OnModify cur=' + Format(CurrFieldNo));
    end;
}

tableextension 84223 "LT CC Cfn Ext" extends "LT CC Cfn Row"
{
    fields
    {
        modify(Name)
        {
            trigger OnAfterValidate()
            var
                Log: Codeunit "LT CC Log";
            begin
                Log.Add('ext Name.OnAfterValidate cur=' + Format(CurrFieldNo));
            end;
        }
    }

    trigger OnBeforeInsert()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('ext OnBeforeInsert cur=' + Format(CurrFieldNo));
    end;

    trigger OnAfterInsert()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('ext OnAfterInsert cur=' + Format(CurrFieldNo));
    end;

    trigger OnAfterModify()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('ext OnAfterModify cur=' + Format(CurrFieldNo));
    end;
}

// ---- OnQueryClosePage without exit (Card, StandardDialog, extension-only trigger) ----

page 84230 "LT CC QC Card"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('card OnQueryClosePage ' + Format(CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('card OnClosePage');
    end;
}

page 84231 "LT CC QC Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoteCtl; Note) { ApplicationArea = All; Caption = 'Note'; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('dialog OnQueryClosePage ' + Format(CloseAction));
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('dialog OnClosePage');
    end;

    var
        Note: Text[30];
}

page 84232 "LT CC QC Plain"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnClosePage()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('plain OnClosePage');
    end;
}

pageextension 84233 "LT CC QC Ext" extends "LT CC QC Plain"
{
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('ext OnQueryClosePage ' + Format(CloseAction));
    end;
}

// ---- OnModifyRecord: empty body, or mode driven (exit(false), assign another record, exit(true)) ----

page 84234 "LT CC Mod Empty"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
    end;
}

page 84235 "LT CC Mod Mode"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT CC Log";
        Other: Record "LT CC Row";
    begin
        Log.Add('OnModifyRecord mode=' + Format(Log.GetMode()) + ' name=' + Rec.Name);
        case Log.GetMode() of
            1:
                exit(false);
            2:
                begin
                    Other.Get(2);
                    Rec := Other;
                end;
            3:
                exit(true);
        end;
    end;
}

// ---- Page background task enqueued per row, completion trigger calls CurrPage.Update ----

page 84236 "LT CC Bg List"
{
    PageType = List;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT CC Log";
        Args: Dictionary of [Text, Text];
        TaskId: Integer;
    begin
        Args.Add('id', Format(Rec.Id));
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT CC Bg Worker", Args, 10000);
        Log.Add('enqueue ' + Format(Rec.Id));
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "LT CC Log";
        Id: Text;
    begin
        Results.Get('id', Id);
        Log.Add('done ' + Id);
        if Log.GetMode() = 1 then begin
            CurrPage.Update(false);
            Log.Add('updated ' + Id);
        end;
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('task error ' + ErrorText);
    end;
}

// ---- Errors raised in page triggers: which trigger fails is chosen through the log codeunit ----

page 84237 "LT CC Err Card"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnInit()
    begin
        MaybeFail('OnInit');
    end;

    trigger OnOpenPage()
    begin
        MaybeFail('OnOpenPage');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        MaybeFail('OnFindRecord');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        MaybeFail('OnNextRecord');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        MaybeFail('OnAfterGetRecord');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        MaybeFail('OnAfterGetCurrRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        MaybeFail('OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        MaybeFail('OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        MaybeFail('OnModifyRecord');
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        MaybeFail('OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        MaybeFail('OnClosePage');
    end;

    local procedure MaybeFail(TriggerName: Text)
    var
        Log: Codeunit "LT CC Log";
    begin
        if Log.GetFailAt() = TriggerName then begin
            Log.Add('hit ' + TriggerName);
            Error('LT CC failure in %1', TriggerName);
        end;
    end;
}

// ---- CurrFieldNo when a TestPage writes the field ----

page 84238 "LT CC Cfn Card"
{
    PageType = Card;
    SourceTable = "LT CC Cfn Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

// ---- FlowFields: one visible, one Visible = false, one not on the page ----

page 84239 "LT CC Flow Card"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(FlowShown; Rec.FlowShown) { ApplicationArea = All; }
            field(FlowHidden; Rec.FlowHidden) { ApplicationArea = All; Visible = false; }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT CC Log";
    begin
        Log.Add('shown=' + Format(Rec.FlowShown) + ' hidden=' + Format(Rec.FlowHidden) + ' absent=' + Format(Rec.FlowAbsent));
    end;
}

// ---- Control expressions BC compiles at run time ----

page 84240 "LT CC Expr RecFn"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
                Editable = GetRow().Flag;
            }
        }
    }

    procedure GetRow(): Record "LT CC Row"
    begin
        exit(Rec);
    end;
}

page 84241 "LT CC Expr BigInt"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Big; Rec.Big) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DoIt)
            {
                ApplicationArea = All;
                Caption = 'Do it';
                Enabled = 0L <> Rec.Big;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 84242 "LT CC Expr Date"
{
    PageType = List;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(D; Rec.D) { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = Rec.D = 0D;
                }
            }
        }
    }
}

page 84243 "LT CC Expr Global"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DoIt)
            {
                ApplicationArea = All;
                Caption = 'Do it';
                Enabled = GlobalRow.Grp = 2;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GlobalRow := Rec;
    end;

    var
        GlobalRow: Record "LT CC Row";
}

// ---- A ToolTip of 1100 characters ----

page 84244 "LT CC Long ToolTip"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
                ToolTip = '0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 ';
            }
        }
    }
}

// ---- Rec.Reset plus CurrPage.Update(false) on a page with SourceTableView ----

page 84245 "LT CC View List"
{
    PageType = List;
    SourceTable = "LT CC Row";
    SourceTableView = where(Grp = const(1));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetUpdate)
            {
                ApplicationArea = All;
                Caption = 'Reset and update';

                trigger OnAction()
                var
                    Log: Codeunit "LT CC Log";
                begin
                    Rec.Reset();
                    Log.Add('after reset filters=[' + Rec.GetFilters() + ']');
                    CurrPage.Update(false);
                    Log.Add('after update filters=[' + Rec.GetFilters() + ']');
                end;
            }
        }
    }
}

// ---- A FactBox field that has only an OnLookup trigger ----

page 84246 "LT CC Fact Host"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Fact; "LT CC Fact Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

page 84247 "LT CC Fact Part"
{
    PageType = CardPart;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Log: Codeunit "LT CC Log";
                begin
                    Log.Add('fact Name OnLookup');
                end;
            }
        }
    }
}

// ---- CurrPage.Editable(false) in OnOpenPage, then an action calls CurrPage.Editable(true) ----

page 84248 "LT CC Lock Card"
{
    PageType = Card;
    SourceTable = "LT CC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetEditableTrue)
            {
                ApplicationArea = All;
                Caption = 'Set editable true';

                trigger OnAction()
                begin
                    CurrPage.Editable(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable(false);
    end;
}

codeunit 84271 "LT CC Bg Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Id: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('id', Id);
        Results.Add('id', Id);
        Page.SetBackgroundTaskResult(Results);
    end;
}
