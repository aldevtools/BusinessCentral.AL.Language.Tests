// Source table of CalcFormulaNamespace.al: a table in the namespace LTCalcNs.Source (one namespace per file).

namespace LTCalcNs.Source;

table 67184 "LT CN Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc No."; Code[10]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
