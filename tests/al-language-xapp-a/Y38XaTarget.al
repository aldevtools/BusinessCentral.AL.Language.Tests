// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: none.
// Writer Y38 (gap cycle 3, C3-16): the target table of TransferFields from another app's table. The source table, a same-app copy of
// this table and the tests are in tests/al-language/record/lt-y38-transfer-xapp/Y38TransferXApp.al. Each field number shared with the
// source has another type there (field 2 and the key have the same type); field 5 has another name on purpose.

table 61105 "LT Y38 XA Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(5; OtherName; Text[100]) { }
        field(33; Factor; Decimal) { }
        field(40; Qty; Decimal) { }
        field(41; Cod; Text[5]) { }
        field(42; Opt; Integer) { }
        field(43; Txt; Code[30]) { }
        field(44; Dt; DateTime) { }
        field(45; Amt; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
