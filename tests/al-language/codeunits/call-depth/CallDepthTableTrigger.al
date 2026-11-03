// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72889, codeunits 72890 and 72891
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the depth reached when OnInsert inserts the next row from inside itself until the ceiling, error text and code. Risky: own file.
// BC versions: 29 (27 and 28 by CI)

codeunit 72890 "LT CallDepth TrigCounter"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Reset()
    begin
        Counter := 0;
    end;

    procedure Next(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

table 72889 "LT CallDepth Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        C: Codeunit "LT CallDepth TrigCounter";
        Next: Record "LT CallDepth Row";
    begin
        Next.Id := C.Next();
        Next.Insert(true);
    end;
}

