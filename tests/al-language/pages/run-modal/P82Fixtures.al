// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares the shared P82 fixtures (tables 71184, 71185, 71192, log codeunit 71186, pages 71187-71191, 71193)
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: fixtures only (a card, a list, a tree list, a list part, a host card with a part, a lookup list); the log is a plain table backed codeunit, not SingleInstance
// BC versions: 29

table 71184 "LT P82 Item"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P82 List";
    DrillDownPageId = "LT P82 List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; DateF; Date) { }
        field(7; DT; DateTime) { }
        field(8; Grp; Code[10]) { TableRelation = "LT P82 Group".Code; }
        field(9; Indent; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByQty; Qty) { }
    }
}

table 71185 "LT P82 Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Entry; Text[250]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 71192 "LT P82 Group"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P82 Group List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 71186 "LT P82 Log"
{
    procedure Reset()
    var
        Row: Record "LT P82 Log";
    begin
        Row.DeleteAll();
    end;

    procedure Add(Text: Text)
    var
        Row: Record "LT P82 Log";
    begin
        if Row.FindLast() then
            Row."Entry No." += 1
        else
            Row."Entry No." := 1;
        Row.Entry := CopyStr(Text, 1, MaxStrLen(Row.Entry));
        Row.Insert();
    end;

    procedure Count(): Integer
    var
        Row: Record "LT P82 Log";
    begin
        exit(Row.Count());
    end;

    procedure Dump(): Text
    var
        Row: Record "LT P82 Log";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Row.Entry;
            until Row.Next() = 0;
        exit(Result);
    end;
}

page 71193 "LT P82 Group List"
{
    PageType = List;
    SourceTable = "LT P82 Group";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT P82 Group List Caption';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 71187 "LT P82 Card"
{
    PageType = Card;
    SourceTable = "LT P82 Item";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT P82 Card Caption';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; ShowMandatory = true; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; HideValue = HideFlag; }
                field(AmtCtl; Rec.Amount) { ApplicationArea = All; }
                field(FlagCtl; Rec.Flag) { ApplicationArea = All; }
                field(DateCtl; Rec.DateF) { ApplicationArea = All; }
                field(DtCtl; Rec.DT) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(RoCtl; RoText) { ApplicationArea = All; Editable = false; }
                field(EnOffCtl; EnText) { ApplicationArea = All; Enabled = false; }
                field(HidStaticCtl; HidText) { ApplicationArea = All; Visible = false; }
                field(VisDynCtl; VisText) { ApplicationArea = All; Visible = VisFlag; }
                field(MandDynCtl; MandText) { ApplicationArea = All; ShowMandatory = MandFlag; }
                field(LookupCtl; LookupText)
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Log: Codeunit "LT P82 Log";
                    begin
                        Log.Add('OnLookup(' + Text + ')');
                        Text := 'looked';
                        exit(true);
                    end;
                }
                field(DrillCtl; DrillText)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        Log: Codeunit "LT P82 Log";
                    begin
                        Log.Add('OnDrillDown');
                    end;
                }
                field(AssistCtl; AssistText)
                {
                    ApplicationArea = All;

                    trigger OnAssistEdit()
                    var
                        Log: Codeunit "LT P82 Log";
                    begin
                        Log.Add('OnAssistEdit');
                        AssistText := 'assisted';
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(ActUpdateSave)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
            action(ActUpdateDefault)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update();
                end;
            }
            action(ActClose)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(ActEditF)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Editable(false);
                end;
            }
            action(ActEditT)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Editable(true);
                end;
            }
            action(ActEditRead)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P82 Log";
                begin
                    Log.Add('Editable=' + Format(CurrPage.Editable()));
                end;
            }
            action(ActSave)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P82 Log";
                begin
                    CurrPage.SaveRecord();
                    Log.Add('saved');
                end;
            }
            action(ActObjId)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P82 Log";
                begin
                    Log.Add('id1=' + CurrPage.ObjectId(true));
                    Log.Add('id0=' + CurrPage.ObjectId(false));
                end;
            }
            action(ActCaption)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P82 Log";
                begin
                    Log.Add('caption=' + CurrPage.Caption);
                end;
            }
            action(ActSetCaption)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P82 Log";
                begin
                    CurrPage.Caption := 'Changed caption';
                    Log.Add('caption=' + CurrPage.Caption);
                end;
            }
            action(ActHide)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    HideFlag := not HideFlag;
                end;
            }
            action(ActVis)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    VisFlag := not VisFlag;
                end;
            }
            action(ActMand)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    MandFlag := not MandFlag;
                end;
            }
            action(ActErr)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Error('P82 action error %1', Rec."No.");
                end;
            }
        }
    }

    var
        HideFlag: Boolean;
        VisFlag: Boolean;
        MandFlag: Boolean;
        RoText: Text[30];
        EnText: Text[30];
        HidText: Text[30];
        VisText: Text[30];
        MandText: Text[30];
        LookupText: Text[30];
        DrillText: Text[30];
        AssistText: Text[30];

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('OnAfterGetRecord(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('OnClosePage');
    end;
}

page 71188 "LT P82 List"
{
    PageType = List;
    SourceTable = "LT P82 Item";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT P82 List Caption';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(AmtCtl; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActSelFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P82 Item";
                    Log: Codeunit "LT P82 Log";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    Log.Add('sel=' + Format(Sel.Count()) + ' filter=' + Sel.GetFilter("No."));
                end;
            }
            action(ActUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(ActClose)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(ActLookupMode)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P82 Log";
                begin
                    Log.Add('LookupMode=' + Format(CurrPage.LookupMode()));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('List OnOpenPage filter=' + Rec.GetFilters());
    end;
}

page 71189 "LT P82 Tree"
{
    PageType = List;
    SourceTable = "LT P82 Item";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = sorting("No.");

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                ShowAsTree = true;

                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 71190 "LT P82 Sub"
{
    PageType = ListPart;
    SourceTable = "LT P82 Item";
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

page 71191 "LT P82 Host"
{
    PageType = Card;
    SourceTable = "LT P82 Group";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            part(SubPart; "LT P82 Sub")
            {
                ApplicationArea = All;
                SubPageLink = Grp = field(Code);
            }
            part(HiddenPart; "LT P82 Sub")
            {
                ApplicationArea = All;
                Visible = false;
            }
            part(DisabledPart; "LT P82 Sub")
            {
                ApplicationArea = All;
                Enabled = false;
            }
        }
    }
}
