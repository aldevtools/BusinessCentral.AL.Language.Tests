// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures for the probes of corpus issue 642 (TestPage behavior, part 3): table 79600, log codeunit 79601 (used by test codeunit 79650 only),
// pages 79610-79620. The tests are in ApTestPageTests.al (79650).
// Log tokens: O OnOpenPage, R<code> OnAfterGetRecord, C<code> OnAfterGetCurrRecord, W OnNewRecord, I<code>/<name> OnInsertRecord,
// M<code> OnModifyRecord, Q OnQueryClosePage, X OnClosePage.

table 79600 "LT AP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Decimal) { }
        field(4; Flag; Boolean) { }
        field(5; Rt; Decimal) { }
        field(6; Txt; Text[30]) { }
        field(7; Cd; Code[20]) { }
        field(8; TxtNB; Text[30]) { NotBlank = true; }
        field(9; CdNB; Code[20]) { NotBlank = true; }
        field(10; Grp; Code[10]) { }
        field(11; Val; Text[30])
        {
            trigger OnValidate()
            begin
                if Val = 'BAD' then
                    Error('LT AP bad value %1', Val);
            end;
        }
        field(12; Sec; Text[30]) { }
        field(13; Num; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 79601 "LT AP Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 79610 "LT AP Part Grp"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

    layout
    {
        area(Content)
        {
            group("Page")
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    procedure Proc()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('PG' + Rec."Code");
    end;
}

page 79611 "LT AP Part Fld"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Page"; Rec.Name) { ApplicationArea = All; }
                field(Val; Rec.Val) { ApplicationArea = All; }
            }
        }
    }

    procedure Proc()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('PF' + Rec."Code");
    end;
}

page 79612 "LT AP Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            part(PartG; "LT AP Part Grp")
            {
                ApplicationArea = All;
                SubPageLink = "Code" = field("Code");
            }
            part(PartF; "LT AP Part Fld")
            {
                ApplicationArea = All;
                SubPageLink = "Code" = field("Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallG)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.PartG.Page.Proc();
                end;
            }
            action(CallF)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.PartF.Page.Proc();
                end;
            }
        }
    }
}

page 79613 "LT AP List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Flag; Rec.Flag) { ApplicationArea = All; }
                field(Val; Rec.Val) { ApplicationArea = All; }
                field(NameNB; Rec.Txt)
                {
                    ApplicationArea = All;
                    NotBlank = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertViaRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT AP Log";
                begin
                    Rec.Init();
                    Rec."Code" := 'NEW1';
                    Rec.Name := 'Created';
                    Rec.Insert();
                    Log.Add('ins');
                end;
            }
            action(SelFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT AP Row";
                    Log: Codeunit "LT AP Log";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    Log.Add('S n=' + Format(Sel.Count()) + ' f=[' + Sel.GetFilters() + '] cf=[' + Sel.GetFilter("Code") + ']');
                end;
            }
            action(SelMarks)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    SelWithMarks(false);
                end;
            }
            action(SelMarksOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    SelWithMarks(true);
                end;
            }
        }
    }

    local procedure Marked(var Sel: Record "LT AP Row"): Text
    var
        Result: Text;
    begin
        if Sel.FindSet() then
            repeat
                if Sel.Mark() then
                    Result += Sel."Code";
            until Sel.Next() = 0;
        exit(Result);
    end;

    local procedure SelWithMarks(OnlyMarked: Boolean)
    var
        Sel: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        Shown: Text;
    begin
        Sel.Get('A');
        Sel.Mark(true);
        Sel.Get('B');
        Sel.Mark(true);
        Log.Add('before=' + Marked(Sel));
        if OnlyMarked then
            Sel.MarkedOnly(true);
        CurrPage.SetSelectionFilter(Sel);
        Log.Add('n=' + Format(Sel.Count()) + ' f=[' + Sel.GetFilters() + '] mo=' + Format(Sel.MarkedOnly()));
        if Sel.FindSet() then
            repeat
                Shown += Sel."Code";
                if Sel.Mark() then
                    Shown += '*';
            until Sel.Next() = 0;
        Log.Add('rows=' + Shown);
        Sel.MarkedOnly(false);
        Sel.SetRange("Code");
        Log.Add('after=' + Marked(Sel));
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('O');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('R' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('C' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('W');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('I' + Rec."Code" + '/' + Rec.Name);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('M' + Rec."Code");
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('Q');
        exit(true);
    end;
}

page 79614 "LT AP Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
                field(Cd; Rec.Cd) { ApplicationArea = All; }
                field(TxtNB; Rec.TxtNB) { ApplicationArea = All; }
                field(CdNB; Rec.CdNB) { ApplicationArea = All; }
                field(VarTxt; VarTxt) { ApplicationArea = All; }
                field(VarCd; VarCd) { ApplicationArea = All; }
                field(RtF; Rec.Rt)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Ratio;
                }
                field(RtPlain; Rec.Rt) { ApplicationArea = All; }
                field(Val; Rec.Val) { ApplicationArea = All; }
                field(SecF; Rec.Sec)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(NumF; Rec.Num)
                {
                    ApplicationArea = All;
                    Numeric = true;
                }
                field(NBF; Rec.Grp)
                {
                    ApplicationArea = All;
                    NotBlank = true;
                }
            }
            group(GrpOff)
            {
                Enabled = false;
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveUpd)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT AP Log";
                begin
                    CurrPage.SaveRecord();
                    Log.Add('saved');
                    CurrPage.Update();
                    Log.Add('updated');
                end;
            }
            action(SaveUpdF)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT AP Log";
                begin
                    CurrPage.SaveRecord();
                    Log.Add('saved');
                    CurrPage.Update(false);
                    Log.Add('updated');
                end;
            }
        }
    }

    var
        VarTxt: Text[30];
        VarCd: Code[20];

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('O');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('R' + Rec."Code");
    end;
}

page 79615 "LT AP NoModify Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";
    ModifyAllowed = false;

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
}

page 79616 "LT AP Cancel Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

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

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('C' + Rec."Code");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('Q' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('X');
    end;
}

page 79617 "LT AP Cancel List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('C' + Rec."Code");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('Q' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT AP Log";
    begin
        Log.Add('X');
    end;
}

page 79618 "LT AP Caption DE"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AP Row";
    CaptionML = DEU = 'Deutsche Seite';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    CaptionML = DEU = 'Deutscher Name';
                }
            }
        }
    }
}

page 79619 "LT AP NoSource"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(VarNB; VarNB)
                {
                    ApplicationArea = All;
                    NotBlank = true;
                }
            }
        }
    }

    var
        VarNB: Text[30];
}
