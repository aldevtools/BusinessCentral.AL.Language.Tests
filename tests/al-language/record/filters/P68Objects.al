// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: own tables 70701-70712, enum 70713, codeunit 70714 (helper, no tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: shared own tables of the P68 probes (record filters, keys, finds, table relations, stale modify, TransferFields)
// BC versions: 29 (27 and 28 by CI)

enum 70713 "LT P68 Kind"
{
    Extensible = true;

    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
    value(3; D) { }
    value(4; E) { }
    value(100; Far) { }
}

table 70701 "LT P68 Flt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cod; Code[20]) { }
        field(4; Int; Integer) { }
        field(5; Dt; Date) { }
        field(6; Dec; Decimal) { }
        field(7; Flag; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Alt; Txt) { }
    }
}

table 70702 "LT P68 Keyed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Val; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 70703 "LT P68 Comp"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Integer) { }
        field(2; Sub; Integer) { }
        field(3; Val; Text[30]) { }
    }

    keys
    {
        key(PK; Grp, Sub) { Clustered = true; }
        key(ValKey; Val) { }
    }
}

table 70704 "LT P68 Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70706 "LT P68 T1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 70707 "LT P68 T2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 70708 "LT P68 T3"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 70705 "LT P68 Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT P68 Kind") { }
        field(3; Num; Integer) { }
        field(4; Grp; Code[10]) { }
        field(5; RefKind; Code[20])
        {
            TableRelation = if (Kind = const(A)) "LT P68 T1"
            else if (Kind = filter(B | C)) "LT P68 T2"
            else if (Kind = filter(C | D)) "LT P68 T3";
        }
        field(6; RefNum; Code[20])
        {
            TableRelation = if (Num = filter(1 .. 3)) "LT P68 T1"
            else if (Num = filter(>= 3)) "LT P68 T2"
            else "LT P68 T3";
        }
        field(7; RefGrp; Code[20])
        {
            TableRelation = if (Grp = const('')) "LT P68 T1"
            else if (Grp = filter('X*')) "LT P68 T2"
            else "LT P68 T3";
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70709 "LT P68 Stale"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Val; Integer) { }
        field(3; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 70710 "LT P68 X1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(10; Opt; Enum "LT P68 Kind") { }
        field(11; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70711 "LT P68 X2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(10; Opt; Option)
        {
            OptionMembers = O0,O1,O2,O3,O4,O5,O6;
        }
        field(11; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Runs a Modify of the record it is given (TableNo), so a test can see whether the Modify raises without asserterror.
codeunit 70714 "LT P68 Modify Run"
{
    TableNo = "LT P68 Stale";

    trigger OnRun()
    begin
        Rec.Modify();
    end;
}
