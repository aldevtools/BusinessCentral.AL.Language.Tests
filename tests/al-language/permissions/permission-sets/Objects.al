// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none (own objects only; Permissions Mock from the dependency).

table 70415 "LT P116 Open"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70418 "LT P116 Target"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70419 "LT P116 Trig Src"
{
    Permissions = tabledata "LT P116 Target" = i;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Target: Record "LT P116 Target";
    begin
        Target."Entry No." := "Entry No.";
        Target.Insert();
    end;
}

table 70420 "LT P116 Trig NoPerm"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Target: Record "LT P116 Target";
    begin
        Target."Entry No." := "Entry No.";
        Target.Insert();
    end;
}

permissionset 70421 "LT P116 Set A"
{
    Assignable = true;
    Permissions =
        tabledata "LT P116 Open" = RIMD,
        tabledata "LT P116 Trig Src" = RIMD,
        tabledata "LT P116 Trig NoPerm" = RIMD,
        codeunit "LT P116 Writer" = X,
        codeunit "LT P116 Writer NoPerm" = X;
}

permissionset 70422 "LT P116 Set B"
{
    Assignable = true;
    Permissions =
        tabledata "LT P116 Open" = R;
}

permissionset 70423 "LT P116 Set C"
{
    Assignable = true;
    Permissions =
        tabledata "LT P116 Target" = RI;
}

codeunit 70424 "LT P116 Writer"
{
    Permissions = tabledata "LT P116 Target" = i;

    procedure Write(EntryNo: Integer)
    var
        Target: Record "LT P116 Target";
    begin
        Target."Entry No." := EntryNo;
        Target.Insert();
    end;
}

codeunit 70425 "LT P116 Writer NoPerm"
{
    procedure Write(EntryNo: Integer)
    var
        Target: Record "LT P116 Target";
    begin
        Target."Entry No." := EntryNo;
        Target.Insert();
    end;
}
