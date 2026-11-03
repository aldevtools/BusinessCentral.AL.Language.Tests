// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: none (objects for the PX_* tests of codeunit 81959 "LT BM FlowField Conversions")
// Writer PX (runtime probes-needed, PR 331): a Lookup FlowField Code[5] over a Code[30] source, and Min/Max FlowFields Text[5]/Code[5]
// over a Text[30]/Code[30] source, when the source value is longer than the FlowField.
// BC versions: 27-29
table 86235 "LT PX FF Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Cd; Code[30]) { }
        field(4; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 86236 "LT PX FF Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Code Lookup"; Code[5])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT PX FF Src".Cd where(Id = field(Id)));
        }
        field(3; "Text Min"; Text[5])
        {
            FieldClass = FlowField;
            CalcFormula = min("LT PX FF Src".Txt where(Grp = field(Id)));
        }
        field(4; "Text Max"; Text[5])
        {
            FieldClass = FlowField;
            CalcFormula = max("LT PX FF Src".Txt where(Grp = field(Id)));
        }
        field(5; "Code Min"; Code[5])
        {
            FieldClass = FlowField;
            CalcFormula = min("LT PX FF Src".Cd where(Grp = field(Id)));
        }
        field(6; "Code Max"; Code[5])
        {
            FieldClass = FlowField;
            CalcFormula = max("LT PX FF Src".Cd where(Grp = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
