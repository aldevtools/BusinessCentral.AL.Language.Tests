// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: self-contained (tables 72200-72202, codeunit 72209); used by the P92 test codeunits
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: own tables and a seeding helper for the RecordRef / FieldRef probes of issue #92
// BC versions: 29 (27 and 28 by CI)

table 72200 "LT P92 Item"
{
    DataClassification = SystemMetadata;
    Caption = 'P92 Item Caption';

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code Cap'; }
        field(2; Name; Text[50]) { Caption = 'Name Cap'; }
        field(3; Qty; Integer) { }
        field(4; Amt; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; Dt; Date) { }
        field(7; Kind; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(8; Note; Text[100]) { }
        field(9; Pic; Blob) { }
        field(10; Cd; Code[10]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(K2; Qty, Name) { }
        key(K3; Amt) { }
    }
}

table 72201 "LT P92 Pair"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; Seq; Integer) { }
        field(3; Txt; Text[30]) { }
        field(4; Num; Integer) { }
    }
    keys
    {
        key(PK; Grp, Seq) { Clustered = true; }
        key(K2; Num) { }
    }
}

table 72202 "LT P92 Trig"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            begin
                Name := 'v' + Format(Val);
            end;
        }
        field(3; Name; Text[30]) { }
        field(4; Other; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72209 "LT P92 Helper"
{
    procedure SeedItems()
    var
        Item: Record "LT P92 Item";
    begin
        Item.DeleteAll();
        Add(Item, 'A1', 'Alpha', 10, 1.5);
        Add(Item, 'A2', 'Beta', 20, 2.5);
        Add(Item, 'A3', 'Gamma', 30, 3.5);
        Add(Item, 'B1', '', 0, 0);
    end;

    local procedure Add(var Item: Record "LT P92 Item"; Code: Code[20]; Name: Text[50]; Qty: Integer; Amt: Decimal)
    begin
        Item.Init();
        Item.Code := Code;
        Item.Name := Name;
        Item.Qty := Qty;
        Item.Amt := Amt;
        Item.Insert();
    end;

    procedure SeedPairs()
    var
        Pair: Record "LT P92 Pair";
    begin
        Pair.DeleteAll();
        AddPair(Pair, 'G1', 1, 'one');
        AddPair(Pair, 'G1', 2, 'two');
        AddPair(Pair, 'G2', 1, 'three');
        AddPair(Pair, 'A,B', 3, 'comma');
        AddPair(Pair, 'X(1)', 4, 'paren');
        AddPair(Pair, 'Q''T', 5, 'quote');
    end;

    local procedure AddPair(var Pair: Record "LT P92 Pair"; Grp: Code[10]; Seq: Integer; Txt: Text[30])
    begin
        Pair.Init();
        Pair.Grp := Grp;
        Pair.Seq := Seq;
        Pair.Txt := Txt;
        Pair.Num := Seq * 10;
        Pair.Insert();
    end;
}
