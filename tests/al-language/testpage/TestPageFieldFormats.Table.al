// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope
// Fixtures used: (none -- backing table for the TestPage field-format suite)

table 69932 "TPF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Num; Integer) {}
        field(3; Big; BigInteger) {}
        field(4; Dec2; Decimal) {}
        field(5; Dec1; Decimal) {}
        field(6; Dec5; Decimal) {}
        field(7; DecDef; Decimal) {}
        field(8; DecRng; Decimal) {}
        field(9; DecBZ; Decimal) {}
        field(10; DecBZT; Decimal) { BlankZero = true; }
        field(11; DecBNP; Decimal) {}
        field(12; DecBNN; Decimal) {}
        field(13; DecAF; Decimal) {}
        field(14; NumBZ; Integer) {}
        field(15; Flag; Boolean) {}
        field(16; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'Eins,Zwei,Drei'; }
        field(17; Enm; Enum "TPF Enum") {}
        field(18; Dt; Date) {}
        field(19; Tm; Time) {}
        field(20; DtTm; DateTime) {}
        field(21; Cd; Code[20]) {}
        field(22; Txt; Text[50]) {}
        field(23; Gd; Guid) {}
        field(24; Dur; Duration) {}
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
