// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: none (own tables and a dump helper for the PnC probes)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles: fixtures only, used by the other PnC files (tag PnC, ids 71071-71499)
// BC versions: 29 (27 and 28 by CI)

table 71080 "LT PnC Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Code Value"; Code[20]) { }
        field(4; Amount; Decimal) { }
        field(5; Other; Integer) { }
        field(6; "Child Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PnC Child" where("Parent No." = field("No.")));
        }
        field(7; "Flow Flt"; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(8; Note; Blob) { }
        field(9; "Table Flt"; TableFilter) { }
        field(10; Status; Option)
        {
            OptionMembers = Open,Released,Closed;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(K2; Name) { }
        key(K3; "Code Value", Amount) { }
    }
}

table 71081 "LT PnC Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Parent No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 71082 "LT PnC Media"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Pic; Media) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 71095 "LT PnC Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 71089 "LT PnC Dump"
{
    // Observes every field of the current row of a RecordRef as Prefix.<field name> (Guid, DateTime, Blob and Media columns left out).
    procedure DumpRow(var RR: RecordRef; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if not (FR.Type in [FieldType::Guid, FieldType::DateTime, FieldType::Blob, FieldType::Media, FieldType::MediaSet]) then
                Observer.Observe(Prefix + '.' + FR.Name, Format(FR.Value));
        end;
    end;
}
