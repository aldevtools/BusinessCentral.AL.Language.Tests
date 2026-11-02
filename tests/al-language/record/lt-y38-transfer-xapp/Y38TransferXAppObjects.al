// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures: tables 92570-92578 here and table 61105 "LT Y38 XA Target" of tests/al-language-xapp-a (Y38XaTarget.al).
// Writer Y38 (gap cycle 3, C3-16). Source table 92570 has, for the field numbers it shares with the target tables, the types Boolean (33),
// Integer (40), Code[10] (41), Option (42), Text[30] (43), Date (44) and Decimal (45). 61105 (another app) and 92571 (this app) have
// Decimal, Decimal, Text[5], Integer, Code[30], DateTime and Boolean there; 92572-92578 (this app) each have one of those fields only.

table 92570 "LT Y38 TF Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(5; Name; Text[100]) { }
        field(33; Flag; Boolean) { }
        field(40; Qty; Integer) { }
        field(41; Cod; Code[10]) { }
        field(42; Opt; Option) { OptionMembers = A,B,C; }
        field(43; Txt; Text[30]) { }
        field(44; Dt; Date) { }
        field(45; Amt; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92571 "LT Y38 TF Same Target"
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

table 92572 "LT Y38 TF Pair 33"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(33; Factor; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92573 "LT Y38 TF Pair 40"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(40; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92574 "LT Y38 TF Pair 41"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(41; Cod; Text[5]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92575 "LT Y38 TF Pair 42"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(42; Opt; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92576 "LT Y38 TF Pair 43"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(43; Txt; Code[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92577 "LT Y38 TF Pair 44"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(44; Dt; DateTime) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92578 "LT Y38 TF Pair 45"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CustNo; Code[20]) { }
        field(45; Amt; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
