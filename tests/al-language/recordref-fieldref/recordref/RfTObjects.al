// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: self-contained (tables 73000-73003, enum 73000); used by the RfT test codeunits
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

enum 73000 "LT RfT Color"
{
    Extensible = true;
    value(0; Red) { Caption = 'Red'; }
    value(1; Green) { Caption = 'Green'; }
    value(5; Blue) { Caption = 'Blue Caption'; }
}

table 73000 "LT RfT Parent"
{
    DataClassification = SystemMetadata;
    Caption = 'RfT Parent Caption';

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No. Caption'; }
        field(2; Description; Text[50]) { Caption = 'Descr Caption'; }
        field(3; Qty; Integer) { }
        field(4; Amount; Decimal) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 73001 "LT RfT Data"
{
    DataClassification = SystemMetadata;
    Caption = 'RfT Data Caption';

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code Caption'; NotBlank = true; }
        field(2; Txt; Text[30]) { Caption = 'Txt Caption'; }
        field(3; Int; Integer) { MinValue = -100; MaxValue = 1000; }
        field(4; Dec; Decimal) { DecimalPlaces = 0 : 3; }
        field(5; Bool; Boolean) { }
        field(6; Dt; Date) { }
        field(7; Tm; Time) { }
        field(8; DtTm; DateTime) { }
        field(9; Opt; Option)
        {
            OptionMembers = First,Second,Third;
            OptionCaption = 'Erste,Zweite,Dritte';
        }
        field(10; Col; Enum "LT RfT Color") { }
        field(11; Big; BigInteger) { }
        field(12; Gd; Guid) { }
        field(13; Bl; Blob) { }
        field(14; Dur; Duration) { }
        field(15; DF; DateFormula) { }
        field(16; Cd50; Code[50]) { }
        field(17; Rel; Code[20]) { TableRelation = "LT RfT Parent"; }
        field(18; Valid; Integer)
        {
            trigger OnValidate()
            begin
                Txt := 'validated ' + Format(Valid);
            end;
        }
        field(19; Rid; RecordId) { }
        field(20; Txt250; Text[250]) { }
        field(22; Bin; Blob) { Subtype = Memo; }
        field(30; SumFF; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RfT Parent".Amount where("No." = field(Code))); Editable = false; }
        field(31; CntFF; Integer) { FieldClass = FlowField; CalcFormula = count("LT RfT Parent" where("No." = field(Code))); Editable = false; }
        field(32; FilterFF; Integer) { FieldClass = FlowFilter; }
        field(33; LookFF; Text[50]) { FieldClass = FlowField; CalcFormula = lookup("LT RfT Parent".Description where("No." = field(Code))); Editable = false; }
        field(34; Dis; Integer) { Enabled = false; }
        field(35; ObsF; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(K2; Int, Txt) { }
        key(K3; Dec) { }
    }
}
