// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own table, log and two list pages with SourceTableView (a where on Grp with sorting(Qty); sorting(Grp,Qty) order(descending) with a where on Qty) for Page.Run(Page, Rec) probes: filters per filter group as seen from OnOpenPage, current key, direction, rows
// BC versions: 29 (final facts are added after the measurement)

table 74920 "LT P145 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Grp; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(K2; Qty) { }
        key(K3; Grp, Qty) { }
    }
}

table 74921 "LT P145 Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[250]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74922 "LT P145 Log Mgt"
{
    procedure Clear()
    var
        Log: Record "LT P145 Log";
    begin
        Log.DeleteAll();
    end;

    procedure Add(Value: Text)
    var
        Log: Record "LT P145 Log";
        NextId: Integer;
    begin
        if Log.FindLast() then
            NextId := Log.Id;
        Log.Init();
        Log.Id := NextId + 1;
        Log.Txt := CopyStr(Value, 1, MaxStrLen(Log.Txt));
        Log.Insert();
    end;

    procedure Dump(): Text
    var
        Log: Record "LT P145 Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                Result += Log.Txt + ' | ';
            until Log.Next() = 0;
        exit(Result);
    end;

    procedure Snapshot(Name: Text; var Row: Record "LT P145 Row")
    var
        Old: Integer;
        G0: Text;
        G1: Text;
        G2: Text;
        G3: Text;
    begin
        Old := Row.FilterGroup();
        Row.FilterGroup(0);
        G0 := Row.GetFilters();
        Row.FilterGroup(1);
        G1 := Row.GetFilters();
        Row.FilterGroup(2);
        G2 := Row.GetFilters();
        Row.FilterGroup(3);
        G3 := Row.GetFilters();
        Row.FilterGroup(Old);
        Add(Name + ' open: group-at-open=' + Format(Old) + ' g0=[' + G0 + '] g1=[' + G1 + '] g2=[' + G2 + '] g3=[' + G3 + ']');
        Add(Name + ' key=' + Row.CurrentKey() + ' asc=' + Format(Row.Ascending()) + ' view=[' + Row.GetView() + ']');
    end;
}

page 74923 "LT P145 List A"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P145 Row";
    SourceTableView = sorting(Qty) where(Grp = filter('A|B'));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(GrpCtl; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(QtyCtl; Rec.Qty)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P145 Log Mgt";
    begin
        Log.Snapshot('A', Rec);
    end;
}

page 74924 "LT P145 List B"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P145 Row";
    SourceTableView = sorting(Grp, Qty) order(descending) where(Qty = filter('>=2'));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(GrpCtl; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(QtyCtl; Rec.Qty)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P145 Log Mgt";
    begin
        Log.Snapshot('B', Rec);
    end;
}

// Writer SF: a list whose view names order(ascending) explicitly.
page 89065 "LT SF P145 List C"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P145 Row";
    SourceTableView = sorting(Qty) order(ascending) where(Grp = filter('A|B'));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(GrpCtl; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(QtyCtl; Rec.Qty)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P145 Log Mgt";
    begin
        Log.Snapshot('C', Rec);
    end;
}
