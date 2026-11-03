// Scope: in-scope
// Fixtures for codeunit 85060 "LT CQ Odd Leads" (corpus issue 672, items 32 to 46).
// Table 85061 has a BigInteger key; table 85062 reads it through FlowFields whose CalcFormula converts BigInteger to Integer or to an enum.
// The AL 30 compiler reports warning AL0662 (BigInteger to Integer) for LookupInt and Cnt2 and warning AL0663 (BigInteger to Enum) for CntEnum; the app still compiles.
// SumInt (sum of a BigInteger field into an Integer FlowField) gets no warning; BC 27.5 and 28.5 publish it but refuse CalcFields on it. BC 27.5 and 28.5 refuse to publish LookupInt (AL0427),
// Cnt2 and CntEnum (AL0204), so those fields exist only from BC 29.

enum 85063 "LT CQ E"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}

table 85061 "LT CQ Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; BigInteger) { }
        field(2; Other; Integer) { }
        field(3; En; Enum "LT CQ E") { }
        field(4; Int; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 85062 "LT CQ Flow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
#if BC29PLUS
        field(3; LookupInt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT CQ Src".Id where(Other = field(Id)));
        }
#endif
        field(4; SumInt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CQ Src".Id where(Other = field(Id)));
        }
#if BC29PLUS
        field(5; Cnt2; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CQ Src" where(Int = field(Big)));
        }
        field(6; CntEnum; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CQ Src" where(En = field(Big)));
        }
#endif
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 85064 "LT CQ Dec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D2; Decimal) { DecimalPlaces = 0 : 2; }
        field(3; D20; Decimal) { DecimalPlaces = 0 : 20; }
        field(4; D25; Decimal) { DecimalPlaces = 2 : 5; }
        field(5; D3040; Decimal) { DecimalPlaces = 30 : 40; }
        field(6; Description; Text[100]) { }
        field(7; No; Code[20]) { }
        field(8; Short; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
