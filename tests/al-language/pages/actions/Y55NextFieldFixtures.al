// Fixtures of the Y55 tests in pages/lt-y45-save-before-action/Y45SaveBeforeAction.al (codeunit 92890): does BC save the row edited
// through a TestPage before the OnValidate of the NEXT field runs. Pages over "LT Y45 Head" with a page-variable field (Activate) whose
// OnValidate reads the stored row, a Qty control whose page OnValidate reads it too, and a part over the own line table "LT Y55 Line".
// Log 92880 "LT Y45 Log" (SingleInstance, used only by codeunit 92890). The facts are in Y45SaveBeforeAction.al.
table 93000 "LT Y55 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Doc; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Desc; Text[50])
        {
            trigger OnValidate()
            begin
                Log.Add('vDesc ' + Rec.Desc + '/' + xRec.Desc + ' db=' + StoredDesc());
            end;
        }
        field(4; Qty; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('vLQty ' + Format(Rec.Qty) + ' db=' + StoredDesc());
            end;
        }
    }

    keys
    {
        key(PK; Doc, "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('lI ' + Format(Rec."Line No.") + ' ' + Rec.Desc + ' db=' + StoredDesc());
    end;

    trigger OnModify()
    begin
        Log.Add('lM ' + Rec.Desc + '/' + xRec.Desc + ' db=' + StoredDesc());
    end;

    procedure StoredDesc(): Text
    var
        Line: Record "LT Y55 Line";
    begin
        if Line.Get(Rec.Doc, Rec."Line No.") then
            exit(Line.Desc + '/' + Format(Line.Qty));
        exit('none');
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

page 93000 "LT Y55 Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y55 Worksheet';
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvQty ' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvAct rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
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

    var
        Log: Codeunit "LT Y45 Log";
        Activate: Boolean;
}

page 93001 "LT Y55 Worksheet Ins"
{
    PageType = Worksheet;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y55 Worksheet Ins';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvQty ' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvAct rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
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

    var
        Log: Codeunit "LT Y45 Log";
        Activate: Boolean;
}

page 93002 "LT Y55 Card"
{
    PageType = Card;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y55 Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvQty ' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvAct rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
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

    var
        Log: Codeunit "LT Y45 Log";
        Activate: Boolean;
}

page 93003 "LT Y55 List"
{
    PageType = List;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y55 List';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvQty ' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvAct rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
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

    var
        Log: Codeunit "LT Y45 Log";
        Activate: Boolean;
}

page 93005 "LT Y55 Doc"
{
    PageType = Document;
    SourceTable = "LT Y45 Head";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y55 Doc';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvQty ' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
                field(Activate; Activate)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('pvAct rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' db=' + Log.HeadDb(Rec."Code"));
                    end;
                }
            }
            part(Lines; "LT Y55 Lines")
            {
                ApplicationArea = All;
                SubPageLink = Doc = field("Code");
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

    var
        Log: Codeunit "LT Y45 Log";
        Activate: Boolean;
}

page 93004 "LT Y55 Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y55 Line";
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'LT Y55 Lines';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Desc; Rec.Desc) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('lpvQty ' + Format(Rec.Qty) + ' db=' + Rec.StoredDesc());
                    end;
                }
                field(LAct; LAct)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('lpvAct rec=' + Rec.Desc + '/' + Format(Rec.Qty) + ' db=' + Rec.StoredDesc() + ' head=' + Log.HeadDb(Rec.Doc));
                    end;
                }
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
        Log.Add('lpM ' + Rec.Desc + '/' + xRec.Desc + ' db=' + Rec.StoredDesc());
        exit(true);
    end;

    var
        Log: Codeunit "LT Y45 Log";
        LAct: Boolean;
}
