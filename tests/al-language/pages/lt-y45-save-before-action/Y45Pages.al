// Pages of pages/lt-y45-save-before-action. The facts are in Y45SaveBeforeAction.al.

page 92880 "LT Y45 Head Card"
{
    PageType = Card;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y45 Head Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadAct)
            {
                ApplicationArea = All;
                Caption = 'Read';

                trigger OnAction()
                begin
                    Log.Act('act', Rec);
                end;
            }
            action(RunCu)
            {
                ApplicationArea = All;
                Caption = 'Run codeunit';
                RunObject = codeunit "LT Y45 RunObj";
            }
            action(RunPg)
            {
                ApplicationArea = All;
                Caption = 'Run page';
                RunObject = page "LT Y45 Peek";
                RunPageLink = "Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R ' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C ' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('pN');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('pI ' + Rec."Code" + ' ' + Rec.Name);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('pM ' + Rec.Name + '/' + xRec.Name + ' db=' + Log.HeadDb(Rec."Code"));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('pQC ' + Format(CloseAction) + ' db=' + Log.HeadDb(Rec."Code"));
    end;

    trigger OnClosePage()
    begin
        Log.Add('pClose');
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

page 92881 "LT Y45 Head List"
{
    PageType = List;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y45 Head List';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadAct)
            {
                ApplicationArea = All;
                Caption = 'Read';

                trigger OnAction()
                begin
                    Log.Act('act', Rec);
                end;
            }
            action(RunCu)
            {
                ApplicationArea = All;
                Caption = 'Run codeunit';
                RunObject = codeunit "LT Y45 RunObj";
            }
            action(RunPg)
            {
                ApplicationArea = All;
                Caption = 'Run page';
                RunObject = page "LT Y45 Peek";
                RunPageLink = "Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R ' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C ' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('pN');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('pI ' + Rec."Code" + ' ' + Rec.Name);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('pM ' + Rec.Name + '/' + xRec.Name + ' db=' + Log.HeadDb(Rec."Code"));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('pQC ' + Format(CloseAction) + ' db=' + Log.HeadDb(Rec."Code"));
    end;

    trigger OnClosePage()
    begin
        Log.Add('pClose');
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

page 92883 "LT Y45 Doc"
{
    PageType = Document;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y45 Doc';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
            part(Lines; "LT Y45 Lines")
            {
                ApplicationArea = All;
                SubPageLink = Doc = field("Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadAct)
            {
                ApplicationArea = All;
                Caption = 'Read';

                trigger OnAction()
                begin
                    Log.Act('act', Rec);
                end;
            }
            action(RunCu)
            {
                ApplicationArea = All;
                Caption = 'Run codeunit';
                RunObject = codeunit "LT Y45 RunObj";
            }
            action(RunPg)
            {
                ApplicationArea = All;
                Caption = 'Run page';
                RunObject = page "LT Y45 Peek";
                RunPageLink = "Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R ' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C ' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('pN');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('pI ' + Rec."Code" + ' ' + Rec.Name);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('pM ' + Rec.Name + '/' + xRec.Name + ' db=' + Log.HeadDb(Rec."Code"));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('pQC ' + Format(CloseAction) + ' db=' + Log.HeadDb(Rec."Code"));
    end;

    trigger OnClosePage()
    begin
        Log.Add('pClose');
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

page 92884 "LT Y45 Card Part"
{
    PageType = Card;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y45 Card Part';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
            part(Lines; "LT Y45 Lines")
            {
                ApplicationArea = All;
                SubPageLink = Doc = field("Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadAct)
            {
                ApplicationArea = All;
                Caption = 'Read';

                trigger OnAction()
                begin
                    Log.Act('act', Rec);
                end;
            }
            action(RunCu)
            {
                ApplicationArea = All;
                Caption = 'Run codeunit';
                RunObject = codeunit "LT Y45 RunObj";
            }
            action(RunPg)
            {
                ApplicationArea = All;
                Caption = 'Run page';
                RunObject = page "LT Y45 Peek";
                RunPageLink = "Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R ' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C ' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('pN');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('pI ' + Rec."Code" + ' ' + Rec.Name);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('pM ' + Rec.Name + '/' + xRec.Name + ' db=' + Log.HeadDb(Rec."Code"));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('pQC ' + Format(CloseAction) + ' db=' + Log.HeadDb(Rec."Code"));
    end;

    trigger OnClosePage()
    begin
        Log.Add('pClose');
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

page 92882 "LT Y45 Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y45 Line";
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'LT Y45 Lines';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Desc; Rec.Desc) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LineAct)
            {
                ApplicationArea = All;
                Caption = 'Read line';

                trigger OnAction()
                begin
                    Log.LineAct('lact', Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('lC ' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('lpN');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('lpI ' + Format(Rec."Line No.") + ' ' + Rec.Desc);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('lpM ' + Format(Rec."Line No.") + ' ' + Rec.Desc + '/' + xRec.Desc + ' db=' + Log.LineDb(Rec.Doc, Rec."Line No."));
        exit(true);
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

page 92885 "LT Y45 Peek"
{
    PageType = Card;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'LT Y45 Peek';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('peek open f=' + Rec.GetFilter("Code") + ' db=' + Log.HeadDb(CopyStr(Rec.GetFilter("Code"), 1, 20)));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('peek C ' + Rec.Name);
    end;

    var
        Log: Codeunit "LT Y45 Log";
}
