// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, codeunit 72625
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own tables (Item, Line, Loc) and the seed codeunit for the P71 query outer join probes
// BC versions: 29 (27 and 28 by CI)

table 72622 "LT P71 Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Grp; Code[10]) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

table 72623 "LT P71 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemNo; Code[20]) { }
        field(3; LocCode; Code[10]) { }
        field(4; Qty; Decimal) { }
        field(5; Note; Text[30]) { }
        field(6; Posted; Boolean) { }
        field(7; DueDate; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72624 "LT P71 Loc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; ItemNo; Code[20]) { }
        field(3; Name; Text[30]) { }
        field(4; Rank; Integer) { }
        field(5; Cost; Decimal) { }
        field(6; Since; Date) { }
        field(7; Active; Boolean) { }
        field(8; Zone; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// Seed: items A, B, C, D (D has no line and no location); locations L1, L2 (item A), L3 (item B), L4 (item X: no such item), L5 (item C);
// lines 1 and 2 (item A, locations L1, L2), 3 and 4 (item B, locations L3 and L9: no such location), 5 (item C, blank location).
codeunit 72625 "LT P71 Seed"
{
    procedure Seed()
    var
        Item: Record "LT P71 Item";
        Line: Record "LT P71 Line";
        Loc: Record "LT P71 Loc";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Loc.DeleteAll();
        AddItem('A', 'Alpha', 'G1');
        AddItem('B', 'Beta', 'G1');
        AddItem('C', 'Gamma', 'G2');
        AddItem('D', 'Delta', 'G2');
        AddLoc('L1', 'A', 'Main', 1, 10.5, 20200101D, true, 'N');
        AddLoc('L2', 'A', 'Side', 2, 20.25, 20210202D, false, 'S');
        AddLoc('L3', 'B', 'Dock', 3, 30, 0D, true, 'N');
        AddLoc('L4', 'X', 'Lost', 4, 40, 20220303D, true, '');
        AddLoc('L5', 'C', 'Yard', 5, 0, 0D, false, 'N');
        AddLine(1, 'A', 'L1', 5, 'first', true, 20200105D);
        AddLine(2, 'A', 'L2', 7, 'second', false, 0D);
        AddLine(3, 'B', 'L3', 2, 'third', true, 20200301D);
        AddLine(4, 'B', 'L9', 3, 'fourth', false, 0D);
        AddLine(5, 'C', '', 4, '', false, 0D);
    end;

    local procedure AddItem(No: Code[20]; Name: Text[30]; Grp: Code[10])
    var
        Item: Record "LT P71 Item";
    begin
        Item.Init();
        Item.No := No;
        Item.Name := Name;
        Item.Grp := Grp;
        Item.Insert();
    end;

    local procedure AddLoc(Code: Code[10]; ItemNo: Code[20]; Name: Text[30]; Rank: Integer; Cost: Decimal; Since: Date; Active: Boolean; Zone: Code[10])
    var
        Loc: Record "LT P71 Loc";
    begin
        Loc.Init();
        Loc."Code" := Code;
        Loc.ItemNo := ItemNo;
        Loc.Name := Name;
        Loc.Rank := Rank;
        Loc.Cost := Cost;
        Loc.Since := Since;
        Loc.Active := Active;
        Loc.Zone := Zone;
        Loc.Insert();
    end;

    local procedure AddLine(Id: Integer; ItemNo: Code[20]; LocCode: Code[10]; Qty: Decimal; Note: Text[30]; Posted: Boolean; DueDate: Date)
    var
        Line: Record "LT P71 Line";
    begin
        Line.Init();
        Line.Id := Id;
        Line.ItemNo := ItemNo;
        Line.LocCode := LocCode;
        Line.Qty := Qty;
        Line.Note := Note;
        Line.Posted := Posted;
        Line.DueDate := DueDate;
        Line.Insert();
    end;
}
