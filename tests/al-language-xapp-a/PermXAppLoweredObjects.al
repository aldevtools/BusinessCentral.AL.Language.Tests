// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none.
// Objects in another app for the permission probe of al-runner issues 8066, 8092 and 8093
// (tests/al-language/permissions/testpermissions/PermXAppLowered.al): the writer codeunit, the extended table with its
// table extension and the permission sets live in this app, the test in the main test app, as in the reporters' repros.
// Object ids 95834-95839 (per object type), table extensions 61106-61107, permission sets 94686, 94687, 94689, 94694-94696.

// local object: the reporter's shape (a table with no properties) is what the test checks.
table 95834 "PERM XA Log"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Message; Text[100]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// 8066: the writer has Permissions = rimd on the table; the routine that writes carries a lower-case InherentPermissions letter.
codeunit 95834 "PERM XA Logger"
{
    Permissions = tabledata "PERM XA Log" = rimd;

    procedure Log(EntryNo: Integer)
    begin
        InsertEntry(EntryNo);
    end;

    procedure Bump(EntryNo: Integer)
    begin
        ModifyEntry(EntryNo);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PERM XA Log", 'i')]
    local procedure InsertEntry(EntryNo: Integer)
    var
        LogRow: Record "PERM XA Log";
    begin
        LogRow."Entry No." := EntryNo;
        LogRow.Insert();
    end;

    // The No. Series shape: a read, then a Modify covered by 'm'.
    [InherentPermissions(PermissionObjectType::TableData, Database::"PERM XA Log", 'm')]
    local procedure ModifyEntry(EntryNo: Integer)
    var
        LogRow: Record "PERM XA Log";
    begin
        LogRow.Get(EntryNo);
        LogRow.Message := 'bumped';
        LogRow.Modify();
    end;
}

// 8093: an extended table with no properties (the reporter's shape) and one with DataClassification only.
table 95835 "PERM XA Doc"
{
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 95836 "PERM XA Doc DC"
{
    DataClassification = CustomerContent;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 95837 "PERM XA Audit"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Document Code"; Code[10]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

tableextension 61106 "PERM XA Doc Ext" extends "PERM XA Doc"
{
    fields { field(95834; "PERM Flag"; Boolean) { DataClassification = SystemMetadata; } }

    trigger OnInsert()
    var
        Audit: Record "PERM XA Audit";
    begin
        Audit."Document Code" := Rec.Code;
        Audit.Insert();
    end;
}

tableextension 61107 "PERM XA Doc DC Ext" extends "PERM XA Doc DC"
{
    trigger OnInsert()
    var
        Audit: Record "PERM XA Audit";
    begin
        Audit."Document Code" := Rec.Code;
        Audit.Insert();
    end;
}

// 8092: the reporter's two composition shapes, and the reduced variant from the issue thread.
table 95838 "PERM XA Item A"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 95839 "PERM XA Item B"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

permissionset 95834 "PERM XA Doc Insert"
{
    Assignable = true;
    Permissions = tabledata "PERM XA Doc" = RIMD, tabledata "PERM XA Doc DC" = RIMD;
}

permissionset 95835 "PERM XA Read Log"
{
    Assignable = true;
    Permissions = tabledata "PERM XA Log" = R;
}

permissionset 95836 "PERM XA Other"
{
    Assignable = true;
    Permissions = tabledata "PERM XA Item A" = R;
}

permissionset 95837 "PERM XA Base"
{
    Assignable = false;
    Permissions = tabledata "PERM XA Item A" = RIMD, tabledata "PERM XA Item B" = RIMD;
}

permissionset 95838 "PERM XA Narrow"
{
    Assignable = false;
    ExcludedPermissionSets = "PERM XA Excluded";
    IncludedPermissionSets = "PERM XA Base";
}

permissionset 95839 "PERM XA Excluded"
{
    Assignable = false;
    Permissions = tabledata "PERM XA Item B" = RIMD;
}

permissionset 94686 "PERM XA Inc Narrow"
{
    Assignable = true;
    IncludedPermissionSets = "PERM XA Narrow";
}

permissionset 94687 "PERM XA Grants B"
{
    Assignable = true;
    Permissions = tabledata "PERM XA Item B" = RIMD;
}

permissionset 94689 "PERM XA Excludes B"
{
    Assignable = true;
    ExcludedPermissionSets = "PERM XA Grants B";
    Permissions = tabledata "PERM XA Item A" = RIMD;
}

permissionset 94694 "PERM XA Narrow2"
{
    Assignable = false;
    ExcludedPermissionSets = "PERM XA Excluded";
    Permissions = tabledata "PERM XA Item A" = RIMD;
}

permissionset 94695 "PERM XA Same B"
{
    Assignable = false;
    Permissions = tabledata "PERM XA Item B" = RIMD;
}

permissionset 94696 "PERM XA Inc Two"
{
    Assignable = true;
    IncludedPermissionSets = "PERM XA Narrow2", "PERM XA Same B";
}
