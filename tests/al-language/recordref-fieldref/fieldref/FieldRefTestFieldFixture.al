// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own table with one field per value type and a seeding helper for the FieldRef.TestField typed-overload probes (issue 190)
// BC versions: 29 (27 and 28 by CI)

table 71717 "LT FRTF Row"
{
    DataClassification = SystemMetadata;
    Caption = 'FRTF Row Caption';

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code Cap'; }
        field(2; Txt; Text[20]) { Caption = 'Txt Cap'; }
        field(3; Num; Integer) { Caption = 'Num Cap'; }
        field(4; Opt; Option) { Caption = 'Opt Cap'; OptionMembers = Alpha,Beta,Gamma; }
        field(5; Tm; Time) { Caption = 'Tm Cap'; }
        field(6; Cd; Code[10]) { Caption = 'Cd Cap'; }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 71718 "LT FRTF Helper"
{
    procedure Seed()
    var
        Row: Record "LT FRTF Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'K1';
        Row.Txt := 'Hello';
        Row.Num := 5;
        Row.Opt := Row.Opt::Beta;
        Row.Tm := 120000T;
        Row.Cd := 'ABC';
        Row.Insert();
    end;
}
