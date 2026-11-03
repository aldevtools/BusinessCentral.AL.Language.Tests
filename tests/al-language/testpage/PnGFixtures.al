// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: this file declares the shared fixtures of the PnG probes (tables 70130-70132 and 70300, log codeunit 70133, pages 70134-70149)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 70130 "LT PnG Item"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT PnG Log";
            begin
                Log.Add('TblVal(' + "No." + ',' + Name + ')');
            end;
        }
        field(3; Qty; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; Grp; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByQty; Qty) { }
        key(ByNameQty; Name, Qty) { }
    }
}

table 70131 "LT PnG Head"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 70132 "LT PnG Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Head Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
        field(4; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }
}

table 70300 "LT PnG Log Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Kind; Integer) { }
        field(3; Name; Text[100]) { }
        field(4; Value; Text[2000]) { }
        field(5; Flag; Boolean) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// Table backed so that several test codeunits can share it: Kind 0 = log entry, Kind 1 = flag.
codeunit 70133 "LT PnG Log"
{
    procedure Reset()
    var
        Row: Record "LT PnG Log Row";
    begin
        Row.DeleteAll();
    end;

    local procedure NextNo(): Integer
    var
        Row: Record "LT PnG Log Row";
    begin
        if Row.FindLast() then
            exit(Row."Entry No." + 1);
        exit(1);
    end;

    procedure Add(Entry: Text)
    var
        Row: Record "LT PnG Log Row";
    begin
        Row."Entry No." := NextNo();
        Row.Kind := 0;
        Row.Value := CopyStr(Entry, 1, MaxStrLen(Row.Value));
        Row.Insert();
    end;

    procedure Count(): Integer
    var
        Row: Record "LT PnG Log Row";
    begin
        Row.SetRange(Kind, 0);
        exit(Row.Count());
    end;

    procedure Dump(): Text
    var
        Row: Record "LT PnG Log Row";
        Result: Text;
    begin
        Row.SetRange(Kind, 0);
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Row.Value;
            until Row.Next() = 0;
        exit(Result);
    end;

    procedure SetFlag(FlagName: Text; FlagValue: Boolean)
    var
        Row: Record "LT PnG Log Row";
    begin
        Row.SetRange(Kind, 1);
        Row.SetRange(Name, CopyStr(FlagName, 1, MaxStrLen(Row.Name)));
        if Row.FindFirst() then begin
            Row.Flag := FlagValue;
            Row.Modify();
            exit;
        end;
        Row.Reset();
        Row."Entry No." := NextNo();
        Row.Kind := 1;
        Row.Name := CopyStr(FlagName, 1, MaxStrLen(Row.Name));
        Row.Flag := FlagValue;
        Row.Insert();
    end;

    procedure GetFlag(FlagName: Text): Boolean
    var
        Row: Record "LT PnG Log Row";
    begin
        Row.SetRange(Kind, 1);
        Row.SetRange(Name, CopyStr(FlagName, 1, MaxStrLen(Row.Name)));
        if Row.FindFirst() then
            exit(Row.Flag);
        exit(false);
    end;
}

page 70134 "LT PnG Card"
{
    PageType = Card;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
            field(FlagCtl; Rec.Flag) { ApplicationArea = All; }
            field(HiddenCtl; Rec.Grp)
            {
                ApplicationArea = All;
                Visible = false;
            }
            group(HiddenGroup)
            {
                Visible = false;
                field(InHiddenGroupCtl; Rec.Grp) { ApplicationArea = All; }
            }
            field(MandatoryCtl; Rec.Grp)
            {
                ApplicationArea = All;
                ShowMandatory = true;
            }
            field(HideValueCtl; Rec.Qty)
            {
                ApplicationArea = All;
                HideValue = true;
            }
            field(PlainGrpCtl; Rec.Grp) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadTableRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PnG Log";
                    Stored: Record "LT PnG Item";
                begin
                    Log.Add('ReadTable(' + Format(Stored.Get(Rec."No.")) + ')');
                end;
            }
            action(UpdateOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(UpdateAndSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
            action(SetEditableFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Editable(false);
                end;
            }
            action(SetEditableTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Editable(true);
                end;
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.OnOpenPage');
        if Log.GetFlag('CardUpdateInOpen') then
            CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.OnNewRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.AGR(' + Rec."No." + ',' + Rec.Name + ')');
        if Log.GetFlag('CardBufferEdit') then
            Rec.Name := 'Buf-' + Rec."No.";
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.AGCR(' + Rec."No." + ',' + Rec.Name + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Card.OnClosePage');
    end;
}

page 70135 "LT PnG List"
{
    PageType = List;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
                field(FlagCtl; Rec.Flag) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadTableRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PnG Log";
                    Stored: Record "LT PnG Item";
                begin
                    Log.Add('ReadTable(' + Rec."No." + ',' + Format(Stored.Get(Rec."No.")) + ')');
                end;
            }
            action(ModifyNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Name := 'Changed';
                    Rec.Modify();
                end;
            }
            action(ModifyWithUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Name := 'Changed';
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(UpdateOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
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
            action(InsertViaRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Init();
                    Rec."No." := 'NEW1';
                    Rec.Name := 'Created';
                    Rec.Insert();
                end;
            }
            action(InsertViaOtherVar)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT PnG Item";
                begin
                    Other."No." := 'NEW2';
                    Other.Name := 'Created';
                    Other.Insert();
                end;
            }
            action(InsertViaRecAndUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Init();
                    Rec."No." := 'NEW3';
                    Rec.Name := 'Created';
                    Rec.Insert();
                    CurrPage.Update(false);
                end;
            }
            action(PositionOnStoredRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Other: Record "LT PnG Item";
                begin
                    Other.FindFirst();
                    Rec := Other;
                end;
            }
            action(SetEditableFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Editable(false);
                end;
            }
            action(SetEditableTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Editable(true);
                end;
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('List.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('List.OnOpenPage');
        if Log.GetFlag('ListUpdateInOpen') then
            CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('List.OnNewRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('List.AGR(' + Rec."No." + ',' + Rec.Name + ')');
        if Log.GetFlag('ListBufferEdit') then
            Rec.Name := 'Buf-' + Rec."No.";
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('List.AGCR(' + Rec."No." + ',' + xRec."No." + ')');
    end;
}

page 70136 "LT PnG Part"
{
    PageType = ListPart;
    SourceTable = "LT PnG Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadCtl; Rec."Head Code") { ApplicationArea = All; }
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadTableRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PnG Log";
                    Stored: Record "LT PnG Line";
                begin
                    Log.Add('PartReadTable(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ',' + Format(Stored.Get(Rec."Head Code", Rec."Line No.")) + ')');
                end;
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Part.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Part.OnOpenPage(' + Rec.GetFilter("Head Code") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Part.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 70137 "LT PnG Doc"
{
    PageType = Document;
    SourceTable = "LT PnG Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "LT PnG Part")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Doc.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Doc.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Doc.AGR(' + Rec."Code" + ')');
    end;
}

page 70138 "LT PnG Doc Parts"
{
    PageType = Document;
    SourceTable = "LT PnG Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PlainLines; "LT PnG Part")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
            }
            part(ReadOnlyLines; "LT PnG Part")
            {
                ApplicationArea = All;
                Editable = false;
                SubPageLink = "Head Code" = field("Code");
            }
            part(DisabledLines; "LT PnG Part")
            {
                ApplicationArea = All;
                Enabled = false;
                SubPageLink = "Head Code" = field("Code");
            }
            part(HiddenLines; "LT PnG Part")
            {
                ApplicationArea = All;
                Visible = HideThem;
                SubPageLink = "Head Code" = field("Code");
            }
            part(ViewFilteredLines; "LT PnG Part")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = filter('>10'));
                SubPageLink = "Head Code" = field("Code");
            }
            part(SameFieldViewLines; "LT PnG Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = const('ZZZ'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    var
        HideThem: Boolean;

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('DocParts.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('DocParts.OnOpenPage');
    end;
}

page 70139 "LT PnG Part Close"
{
    PageType = ListPart;
    SourceTable = "LT PnG Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PartClose.OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('PartClose.OnClosePage');
    end;
}

page 70140 "LT PnG Doc Close"
{
    PageType = Document;
    SourceTable = "LT PnG Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT PnG Part Close")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnClosePage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('DocClose.OnClosePage');
    end;
}

page 70141 "LT PnG Temp Ctl"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TmpNameA; TempBuf.Name) { ApplicationArea = All; }
            field(TmpNameB; TempBuf.Name) { ApplicationArea = All; }
            field(TmpQty; TempBuf.Qty) { ApplicationArea = All; }
            field(TmpFlag; TempBuf.Flag) { ApplicationArea = All; }
            field(TmpAmount; TempBuf.Amount) { ApplicationArea = All; }
        }
    }

    var
        TempBuf: Record "LT PnG Item" temporary;

    trigger OnOpenPage()
    begin
        TempBuf."No." := 'T1';
        TempBuf.Name := 'Start';
        TempBuf.Qty := 5;
        TempBuf.Insert();
    end;
}

page 70142 "LT PnG Controls"
{
    PageType = Card;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            label(PlainLabel)
            {
                ApplicationArea = All;
                Caption = 'A label caption';
            }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            group(GridHost)
            {
                grid(TheGrid)
                {
                    GridLayout = Rows;
                    group(GridRow)
                    {
                        field(GridQty; Rec.Qty) { ApplicationArea = All; }
                    }
                }
            }
            group(FixedHost)
            {
                fixed(TheFixed)
                {
                    group(FixedCol)
                    {
                        field(FixedQty; Rec.Amount) { ApplicationArea = All; }
                    }
                }
            }
        }
    }
}

page 70143 "LT PnG Cue Card"
{
    PageType = CardPart;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            cuegroup(TheCues)
            {
                field(CueQty; Rec.Qty) { ApplicationArea = All; }
                field(CueAmount; Rec.Amount) { ApplicationArea = All; }
            }
            field(PlainName; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 70144 "LT PnG Save Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
            field(IntCtl; IntVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];
        IntVar: Integer;

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveCard.OnInit(' + TxtVar + '|' + Format(IntVar) + ')');
        if Log.GetFlag('SaveCardOnInitSets') then
            TxtVar := 'FromOnInit';
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveCard.OnOpenPage(' + TxtVar + '|' + Format(IntVar) + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveCard.OnQueryClosePage(' + Format(CloseAction) + ',' + TxtVar + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveCard.OnClosePage(' + TxtVar + ')');
    end;
}

page 70145 "LT PnG Save Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];

    trigger OnInit()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveDlg.OnInit(' + TxtVar + ')');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveDlg.OnOpenPage(' + TxtVar + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveDlg.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('SaveDlg.OnClosePage');
    end;
}

page 70146 "LT PnG Boom List"
{
    PageType = List;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Name = 'BOOM' then
            Error('LT PnG boom on %1', Rec."No.");
    end;
}

page 70147 "LT PnG Temp Source"
{
    PageType = List;
    SourceTable = "LT PnG Item";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CountRows)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PnG Log";
                begin
                    Log.Add('TempCount(' + Format(Rec.Count()) + ')');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."No." := 'A';
        Rec.Name := 'First';
        Rec.Qty := 1;
        Rec.Insert();
        Rec."No." := 'B';
        Rec.Name := 'Second';
        Rec.Qty := 2;
        Rec.Insert();
        if Rec.FindFirst() then;
    end;
}

page 70148 "LT PnG View List"
{
    PageType = List;
    SourceTable = "LT PnG Item";
    SourceTableView = where(Qty = filter('>=2'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 70149 "LT PnG Tree List"
{
    PageType = List;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
