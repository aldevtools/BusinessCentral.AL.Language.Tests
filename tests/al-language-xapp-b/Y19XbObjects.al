// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none.
// Writer Y19, ADR-062 probes P5 and P9 (tests/al-language/permissions/lt-y19-perm-probes/Y19PermCrossApp.al): xapp-b code without a
// Permissions property that reads and inserts a table of xapp-a and inserts its own table; a permission set "LT Y19 Dup" whose role id
// xapp-d declares too (xapp-b and xapp-d do not depend on each other).

table 61188 "LT Y19 XB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 61187 "LT Y19 XB Access"
{
    procedure CountXa(): Integer
    var
        Row: Record "LT Y19 XA Row";
    begin
        exit(Row.Count());
    end;

    procedure InsertXa(NewId: Integer)
    var
        Row: Record "LT Y19 XA Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;

    procedure InsertOwn(NewId: Integer)
    var
        Row: Record "LT Y19 XB Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;
}

// Read only on the xapp-a table; xapp-d's set of the same name grants read and insert.
permissionset 61189 "LT Y19 Dup"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 XA Row" = R;
}
