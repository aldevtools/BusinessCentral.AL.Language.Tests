// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 77610-77643 (DKT Entry, DKT Log, DKT Mgt, DKT Mgt SI, 29 DKT pages, DKT Tests)
// Probe: draft, facts filled in after observation.

table 77610 "DKT Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc Name"; Text[50]) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 77611 "DKT Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        Rows: Integer;

    procedure Wipe(NewRows: Integer)
    begin
        Clear(Lines);
        Rows := NewRows;
    end;

    procedure RowsWanted(): Integer
    begin
        exit(Rows);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit(Result);
    end;
}

codeunit 77612 "DKT Mgt"
{
    var
        CaptionText: Text;

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionText := NewCaption;
    end;

    procedure GetCaption(): Text
    begin
        exit(CaptionText);
    end;

    procedure GetCaptionLogged(): Text
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('DC=' + CaptionText);
        exit(CaptionText);
    end;
}

codeunit 77613 "DKT Mgt SI"
{
    SingleInstance = true;

    var
        CaptionText: Text;

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionText := NewCaption;
    end;

    procedure GetCaption(): Text
    begin
        exit(CaptionText);
    end;

    procedure GetCaptionLogged(): Text
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('DC=' + CaptionText);
        exit(CaptionText);
    end;
}

page 77614 "DKT N Init Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Init Pure';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    local procedure GetCaptionText(): Text
    begin
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77615 "DKT N Init Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Init Logged';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    local procedure GetCaptionText(): Text
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('DC=' + Rec."Doc Name");
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77616 "DKT N Init Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Init Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;
}

page 77617 "DKT N Close Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Close Pure';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;

    local procedure GetCaptionText(): Text
    begin
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77618 "DKT N Close Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Close Logged';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;

    local procedure GetCaptionText(): Text
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('DC=' + Rec."Doc Name");
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77619 "DKT N Close Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Close Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77620 "DKT N Both Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Both Pure';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;

    local procedure GetCaptionText(): Text
    begin
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77621 "DKT N Both Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Both Logged';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;

    local procedure GetCaptionText(): Text
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('DC=' + Rec."Doc Name");
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77622 "DKT N Both Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N Both Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77623 "DKT N NoOpen Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N NoOpen Pure';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;

    local procedure GetCaptionText(): Text
    begin
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77624 "DKT N NoOpen Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N NoOpen Logged';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;

    local procedure GetCaptionText(): Text
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('DC=' + Rec."Doc Name");
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77625 "DKT N NoOpen Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT N NoOpen Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        DocNo: Code[20];
        ActEnabled: Boolean;

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit doc=' + DocNo);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77626 "DKT L Init Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Init Pure';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77627 "DKT L Init Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Init Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77628 "DKT L Init Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Init Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77629 "DKT L Close Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Close Pure';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77630 "DKT L Close Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Close Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77631 "DKT L Close Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Close Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77632 "DKT L Both Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Both Pure';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77633 "DKT L Both Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Both Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77634 "DKT L Both Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Both Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77635 "DKT L NoOpen Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L NoOpen Pure';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77636 "DKT L NoOpen Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L NoOpen Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77637 "DKT L NoOpen Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L NoOpen Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;
                Enabled = ActEnabled;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";
        ActEnabled: Boolean;

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnInit()
    var
        Log: Codeunit "DKT Log";
    begin
        ActEnabled := true;
        Log.Add('OnInit');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnClosePage rows=' + Format(Rec.Count()));
    end;
}

page 77638 "DKT L Base Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Base Pure';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77639 "DKT L Base Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Base Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77640 "DKT L Base Plain"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Base Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77641 "DKT L Base SI Pure"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Base SI Pure';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt SI";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77642 "DKT L Base SI Logged"
{
    PageType = Worksheet;
    SourceTable = "DKT Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKT L Base SI Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKT Mgt SI";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKT Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

codeunit 77643 "DKT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "DKT Log";
        Reads: Text;

    local procedure NavReads(DocCtl: Text; Filter: Text; HasFirst: Boolean; Name: Text; HasNext: Boolean): Text
    begin
        exit(StrSubstNo('doc=%1 filter=%2 first=%3 name=%4 next=%5', DocCtl, Filter, HasFirst, Name, HasNext));
    end;

    [Test]
    procedure NInit_Pure_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Init Pure";
        P: TestPage "DKT N Init Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NInit_Pure_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Init Pure";
        P: TestPage "DKT N Init Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NInit_Plain_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Init Plain";
        P: TestPage "DKT N Init Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NInit_Plain_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Init Plain";
        P: TestPage "DKT N Init Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NInit_Logged_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Init Logged";
        P: TestPage "DKT N Init Logged";
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NInit_Logged_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Init Logged";
        P: TestPage "DKT N Init Logged";
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NClose_Pure_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Close Pure";
        P: TestPage "DKT N Close Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NClose_Pure_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Close Pure";
        P: TestPage "DKT N Close Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NClose_Plain_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Close Plain";
        P: TestPage "DKT N Close Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NClose_Plain_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Close Plain";
        P: TestPage "DKT N Close Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NClose_Logged_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Close Logged";
        P: TestPage "DKT N Close Logged";
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NClose_Logged_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Close Logged";
        P: TestPage "DKT N Close Logged";
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NBoth_Pure_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Both Pure";
        P: TestPage "DKT N Both Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NBoth_Pure_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Both Pure";
        P: TestPage "DKT N Both Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NBoth_Plain_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Both Plain";
        P: TestPage "DKT N Both Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NBoth_Plain_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Both Plain";
        P: TestPage "DKT N Both Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NBoth_Logged_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Both Logged";
        P: TestPage "DKT N Both Logged";
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NBoth_Logged_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N Both Logged";
        P: TestPage "DKT N Both Logged";
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NNoOpen_Pure_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N NoOpen Pure";
        P: TestPage "DKT N NoOpen Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NNoOpen_Plain_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N NoOpen Plain";
        P: TestPage "DKT N NoOpen Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('enabled', Format(P.Show.Enabled()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure NNoOpen_Logged_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKT N NoOpen Logged";
        P: TestPage "DKT N NoOpen Logged";
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Observe('log after close', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HInitPure')]
    procedure LInit_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Init Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HInitPure')]
    procedure LInit_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Init Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HInitPlain')]
    procedure LInit_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Init Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HInitPlain')]
    procedure LInit_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Init Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HInitLogged')]
    procedure LInit_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Init Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HInitLogged')]
    procedure LInit_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Init Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HClosePure')]
    procedure LClose_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Close Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HClosePure')]
    procedure LClose_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Close Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HClosePlain')]
    procedure LClose_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Close Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HClosePlain')]
    procedure LClose_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Close Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HCloseLogged')]
    procedure LClose_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Close Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HCloseLogged')]
    procedure LClose_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Close Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBothPure')]
    procedure LBoth_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Both Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBothPure')]
    procedure LBoth_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Both Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBothPlain')]
    procedure LBoth_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Both Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBothPlain')]
    procedure LBoth_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Both Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBothLogged')]
    procedure LBoth_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Both Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBothLogged')]
    procedure LBoth_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Both Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HNoOpenPure')]
    procedure LNoOpen_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L NoOpen Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HNoOpenPlain')]
    procedure LNoOpen_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L NoOpen Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HNoOpenLogged')]
    procedure LNoOpen_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L NoOpen Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W0Pinned_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W0Pinned_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W0Pinned_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W0Pinned_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W0Pinned_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W0Pinned_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W1ResultUsed_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry" temporary;
        Result: Action;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        Result := LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W1ResultUsed_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry" temporary;
        Result: Action;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        Result := LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W1ResultUsed_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry" temporary;
        Result: Action;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        Result := LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W1ResultUsed_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry" temporary;
        Result: Action;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        Result := LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W1ResultUsed_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry" temporary;
        Result: Action;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        Result := LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W1ResultUsed_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry" temporary;
        Result: Action;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        Result := LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W2StoredView_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry";
    begin
        Log.Wipe(0);
        Reads := '';
        View.DeleteAll();
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W2StoredView_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry";
    begin
        Log.Wipe(1);
        Reads := '';
        View.DeleteAll();
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W2StoredView_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry";
    begin
        Log.Wipe(0);
        Reads := '';
        View.DeleteAll();
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W2StoredView_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry";
    begin
        Log.Wipe(1);
        Reads := '';
        View.DeleteAll();
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W2StoredView_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry";
    begin
        Log.Wipe(0);
        Reads := '';
        View.DeleteAll();
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W2StoredView_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry";
    begin
        Log.Wipe(1);
        Reads := '';
        View.DeleteAll();
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W4NonKeyFilter_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange(Qty, 3);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePure')]
    procedure W4NonKeyFilter_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange(Qty, 3);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W4NonKeyFilter_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange(Qty, 3);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBasePlain')]
    procedure W4NonKeyFilter_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Plain";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange(Qty, 3);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W4NonKeyFilter_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange(Qty, 3);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseLogged')]
    procedure W4NonKeyFilter_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange(Qty, 3);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseSIPure')]
    procedure W3SingleInstance_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base SI Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseSIPure')]
    procedure W3SingleInstance_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base SI Pure";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseSILogged')]
    procedure W3SingleInstance_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base SI Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(0);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HBaseSILogged')]
    procedure W3SingleInstance_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        LinesPage: Page "DKT L Base SI Logged";
        View: Record "DKT Entry" temporary;
    begin
        Log.Wipe(1);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure HInitPure(var P: TestPage "DKT L Init Pure")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5 cap=%6', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled, P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HInitLogged(var P: TestPage "DKT L Init Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HInitPlain(var P: TestPage "DKT L Init Plain")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled);
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HClosePure(var P: TestPage "DKT L Close Pure")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5 cap=%6', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled, P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HCloseLogged(var P: TestPage "DKT L Close Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HClosePlain(var P: TestPage "DKT L Close Plain")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled);
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBothPure(var P: TestPage "DKT L Both Pure")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5 cap=%6', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled, P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBothLogged(var P: TestPage "DKT L Both Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBothPlain(var P: TestPage "DKT L Both Plain")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled);
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HNoOpenPure(var P: TestPage "DKT L NoOpen Pure")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5 cap=%6', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled, P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HNoOpenLogged(var P: TestPage "DKT L NoOpen Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HNoOpenPlain(var P: TestPage "DKT L NoOpen Plain")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled);
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBasePure(var P: TestPage "DKT L Base Pure")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5 cap=%6', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled, P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBaseLogged(var P: TestPage "DKT L Base Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBasePlain(var P: TestPage "DKT L Base Plain")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled);
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBaseSIPure(var P: TestPage "DKT L Base SI Pure")
    var
        HasFirst: Boolean;
        Enabled: Boolean;
    begin
        Log.Add('H0');
        Enabled := P.Calc.Enabled();
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 qtyfilter=%4 enabled=%5 cap=%6', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Filter.GetFilter(Qty), Enabled, P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure HBaseSILogged(var P: TestPage "DKT L Base SI Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;
}
