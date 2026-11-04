// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: self-contained: tables 72694-72695, codeunit 72696 (this file), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own tables and seeding helper for the P107 open-overload probes (issue #107)
// BC versions: 29 (27 and 28 by CI)

table 72694 "LT P107 Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code Cap'; }
        field(2; Name; Text[50]) { Caption = 'Name Cap'; }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 72695 "LT P107 Dest"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 72696 "LT P107 Helper"
{
    procedure Seed()
    var
        Rec: Record "LT P107 Rec";
        Dest: Record "LT P107 Dest";
    begin
        Rec.DeleteAll();
        Dest.DeleteAll();
        Add('A', 'Alpha', 1);
        Add('B', 'Beta', 5);
        Add('C', 'Gamma', 10);
    end;

    local procedure Add(Code: Code[20]; Name: Text[50]; Qty: Integer)
    var
        Rec: Record "LT P107 Rec";
    begin
        Rec.Init();
        Rec.Code := Code;
        Rec.Name := Name;
        Rec.Qty := Qty;
        Rec.Insert();
    end;
}
