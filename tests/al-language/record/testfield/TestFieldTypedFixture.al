// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: fixture only: table 70955 and enum 70954 for the typed TestField tests
// BC versions: 29 (27 and 28 by CI)

enum 70954 "LT TFT Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
    value(2; Two) { }
}

table 70955 "LT TFT Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[50]) { }
        field(3; Cod; Code[20]) { }
        field(4; Dec; Decimal) { }
        field(5; Int; Integer) { }
        field(6; Big; BigInteger) { }
        field(7; Bool; Boolean) { }
        field(8; Dt; Date) { }
        field(9; DtTm; DateTime) { }
        field(10; Gd; Guid) { }
        field(11; Knd; Enum "LT TFT Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
