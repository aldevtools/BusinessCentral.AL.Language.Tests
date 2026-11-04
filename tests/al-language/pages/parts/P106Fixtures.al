// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares tables 72400-72402, log codeunit 72400, pages 72400-72404
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: fixtures only (a card, a list, a group lookup list, a list part, a host card with a part); the log is a plain table backed codeunit
// BC versions: 29 (27 and 28 by CI)

table 72400 "LT P106 Item"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P106 List";
    DrillDownPageId = "LT P106 List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
        field(4; DT; DateTime) { }
        field(5; Grp; Code[10]) { TableRelation = "LT P106 Group".Code; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByQty; Qty) { }
    }
}

table 72401 "LT P106 Group"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P106 Group List";

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

table 72402 "LT P106 Log"
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

codeunit 72400 "LT P106 Log"
{
    procedure Reset()
    var
        Row: Record "LT P106 Log";
    begin
        Row.DeleteAll();
    end;

    procedure Add(Text: Text)
    var
        Row: Record "LT P106 Log";
    begin
        if Row.FindLast() then
            Row."Entry No." += 1
        else
            Row."Entry No." := 1;
        Row.Entry := CopyStr(Text, 1, MaxStrLen(Row.Entry));
        Row.Insert();
    end;

    procedure Dump(): Text
    var
        Row: Record "LT P106 Log";
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

    procedure Seed()
    var
        Item: Record "LT P106 Item";
        Grp: Record "LT P106 Group";
    begin
        Item.DeleteAll();
        Grp.DeleteAll();
        Reset();
        Grp.Code := 'G1';
        Grp.Descr := 'One';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Two';
        Grp.Insert();
        Grp.Code := 'G3';
        Grp.Descr := 'Three';
        Grp.Insert();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Qty := 1;
        Item.Grp := 'G1';
        Item.DT := CreateDateTime(DMY2Date(2, 3, 2020), 101500T);
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Qty := 2;
        Item.Grp := 'G1';
        Item.DT := CreateDateTime(DMY2Date(5, 6, 2021), 235959T);
        Item.Insert();
        Item.Init();
        Item."No." := 'C';
        Item.Name := 'Gamma';
        Item.Qty := 3;
        Item.Grp := 'G2';
        Item.Insert();
        Item.Init();
        Item."No." := 'D';
        Item.Name := 'Delta';
        Item.Qty := 3;
        Item.Insert();
    end;
}

page 72402 "LT P106 Group List"
{
    PageType = List;
    SourceTable = "LT P106 Group";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT P106 Group List Caption';

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

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('Group OnOpenPage filter=' + Rec.GetFilters());
    end;
}

page 72400 "LT P106 Card"
{
    PageType = Card;
    SourceTable = "LT P106 Item";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT P106 Card Caption';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(DtCtl; Rec.DT) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(LookupCtl; LookupText)
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Log: Codeunit "LT P106 Log";
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
                        Log: Codeunit "LT P106 Log";
                    begin
                        Log.Add('OnDrillDown');
                    end;
                }
                field(AssistCtl; AssistText)
                {
                    ApplicationArea = All;

                    trigger OnAssistEdit()
                    var
                        Log: Codeunit "LT P106 Log";
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
                    Log: Codeunit "LT P106 Log";
                begin
                    Log.Add('LookupMode=' + Format(CurrPage.LookupMode()));
                end;
            }
        }
    }

    var
        LookupText: Text[30];
        DrillText: Text[30];
        AssistText: Text[30];

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('OnAfterGetRecord(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('OnClosePage');
    end;
}

page 72401 "LT P106 List"
{
    PageType = List;
    SourceTable = "LT P106 Item";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT P106 List Caption';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(DtCtl; Rec.DT) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
                    Log: Codeunit "LT P106 Log";
                begin
                    Log.Add('LookupMode=' + Format(CurrPage.LookupMode()));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('List OnOpenPage filter=' + Rec.GetFilters());
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P106 Log";
    begin
        Log.Add('List OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;
}

page 72403 "LT P106 Sub"
{
    PageType = ListPart;
    SourceTable = "LT P106 Item";
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

page 72404 "LT P106 Host"
{
    PageType = Card;
    SourceTable = "LT P106 Group";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            part(SubPart; "LT P106 Sub")
            {
                ApplicationArea = All;
                SubPageLink = Grp = field(Code);
            }
        }
    }
}
