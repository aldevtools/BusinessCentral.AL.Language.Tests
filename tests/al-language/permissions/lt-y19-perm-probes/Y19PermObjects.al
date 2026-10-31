// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none (own objects; Permissions Mock from the dependency).
// Objects for the al-runtime-rs ADR-062 permission probes P0-P13 (writer Y19): own tables, permission sets, a permission set
// extension of an own set and of D365 BASIC, codeunits with and without a Permissions property, an interface.
// Object ids 91900-91949; tests in 91950-91999. Cross-app objects: tests/al-language-xapp-a/Y19XaObjects.al,
// tests/al-language-xapp-b/Y19XbObjects.al, tests/al-language-xapp-d/Y19XdObjects.al.

table 91900 "LT Y19 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    // P7: a table procedure that inserts a row of its own table.
    procedure InsertSelf(NewId: Integer)
    begin
        Rec.Init();
        Rec.Id := NewId;
        Rec.Insert();
    end;
}

// P3: triggers write "LT Y19 Trig B"; no Permissions property.
table 91901 "LT Y19 Trig A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        B: Record "LT Y19 Trig B";
    begin
        B.Id := Id;
        B.Insert();
    end;

    trigger OnModify()
    var
        B: Record "LT Y19 Trig B";
    begin
        B.Id := Id;
        B.Value := Value;
        B.Modify();
    end;

    trigger OnDelete()
    var
        B: Record "LT Y19 Trig B";
    begin
        B.Id := Id;
        B.Delete();
    end;
}

// P3: the same triggers, with Permissions = tabledata "LT Y19 Trig B" = imd.
table 91902 "LT Y19 Trig A Perm"
{
    DataClassification = SystemMetadata;
    Permissions = tabledata "LT Y19 Trig B" = imd;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        B: Record "LT Y19 Trig B";
    begin
        B.Id := Id;
        B.Insert();
    end;

    trigger OnModify()
    var
        B: Record "LT Y19 Trig B";
    begin
        B.Id := Id;
        B.Value := Value;
        B.Modify();
    end;

    trigger OnDelete()
    var
        B: Record "LT Y19 Trig B";
    begin
        B.Id := Id;
        B.Delete();
    end;
}

table 91903 "LT Y19 Trig B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// P6: a table whose TableType is Temporary.
table 91904 "LT Y19 Temp Table"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// P10: the table the D365 BASIC extension grants.
table 91905 "LT Y19 Ext Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// P4: Permissions = d on the row table.
codeunit 91906 "LT Y19 Deleter"
{
    Permissions = tabledata "LT Y19 Row" = d;

    procedure DeleteRow(RowId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := RowId;
        Row.Delete();
    end;
}

// P4: Permissions = m on the row table.
codeunit 91907 "LT Y19 Modifier"
{
    Permissions = tabledata "LT Y19 Row" = m;

    procedure ModifyRow(RowId: Integer; NewValue: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := RowId;
        Row.Value := NewValue;
        Row.Modify();
    end;
}

interface "LT Y19 Inserter"
{
    procedure InsertRow(NewId: Integer);
}

// P7 and P12: Permissions = ri on the row table; inserts in its own procedure, in a local procedure, through an interface
// implemented by a codeunit without the property, and through a table procedure.
codeunit 91908 "LT Y19 Frame Writer"
{
    Permissions = tabledata "LT Y19 Row" = ri;

    procedure InsertDirect(NewId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;

    procedure InsertViaLocal(NewId: Integer)
    begin
        LocalInsert(NewId);
    end;

    procedure InsertViaInterface(NewId: Integer)
    var
        Impl: Codeunit "LT Y19 Frame Impl";
        Inserter: Interface "LT Y19 Inserter";
    begin
        Inserter := Impl;
        Inserter.InsertRow(NewId);
    end;

    procedure InsertViaTableProc(NewId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.InsertSelf(NewId);
    end;

    procedure CountRows(): Integer
    var
        Row: Record "LT Y19 Row";
    begin
        exit(Row.Count());
    end;

    local procedure LocalInsert(NewId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;
}

// P7: implements the interface, no Permissions property.
codeunit 91909 "LT Y19 Frame Impl" implements "LT Y19 Inserter"
{
    procedure InsertRow(NewId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := NewId;
        Row.Insert();
    end;
}

// ---- permission sets ----

// Grants nothing on the row table (P4, P6, P13 and the cross-app probes).
permissionset 91910 "LT Y19 None"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Trig B" = R;
}

permissionset 91911 "LT Y19 R"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = R;
}

permissionset 91912 "LT Y19 RI"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = RI;
}

permissionset 91913 "LT Y19 RIM"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = RIM;
}

permissionset 91914 "LT Y19 RIMD"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = RIMD;
}

// P3: RIMD on both A tables, indirect insert, modify and delete on B.
permissionset 91915 "LT Y19 Trig Imd B"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y19 Trig A" = RIMD,
        tabledata "LT Y19 Trig A Perm" = RIMD,
        tabledata "LT Y19 Trig B" = imd;
}

// P3: RIMD on both A tables, nothing on B.
permissionset 91916 "LT Y19 Trig No B"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y19 Trig A" = RIMD,
        tabledata "LT Y19 Trig A Perm" = RIMD;
}

// P4: read and indirect delete.
permissionset 91917 "LT Y19 R Ind D"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = Rd;
}

// P4: read and direct modify.
permissionset 91918 "LT Y19 R M"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = RM;
}

// P7 and P11: indirect read and insert only.
permissionset 91919 "LT Y19 Ind RI"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = ri;
}

// P9: not assignable.
permissionset 91920 "LT Y19 Not Assign"
{
    Assignable = false;
    Permissions = tabledata "LT Y19 Row" = RIMD;
}

// P9: a role id in mixed case.
permissionset 91921 "LT Y19 Mixed Case"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = RI;
}

// P10: base set extended below.
permissionset 91922 "LT Y19 Ext Base"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = R;
}

permissionsetextension 91923 "LT Y19 Ext Base Ext" extends "LT Y19 Ext Base"
{
    Permissions = tabledata "LT Y19 Row" = RIMD;
}

permissionsetextension 91924 "LT Y19 D365 Basic Ext" extends "D365 BASIC"
{
    Permissions = tabledata "LT Y19 Ext Row" = RIMD;
}

// P11: an excluded set that itself includes a set.
permissionset 91925 "LT Y19 Leaf R"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = R;
}

permissionset 91926 "LT Y19 Mid Incl Leaf"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y19 Leaf R";
    Permissions = tabledata "LT Y19 Trig B" = R;
}

permissionset 91927 "LT Y19 Excl Nested"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y19 Row" = RIMD,
        tabledata "LT Y19 Trig B" = RIMD;
    ExcludedPermissionSets = "LT Y19 Mid Incl Leaf";
}

// P11: RIMD excluding rimd.
permissionset 91928 "LT Y19 Ind RIMD"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = rimd;
}

permissionset 91929 "LT Y19 Excl Indirect"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = RIMD;
    ExcludedPermissionSets = "LT Y19 Ind RIMD";
}

// P11: one included set with R and another with r on the same table.
permissionset 91930 "LT Y19 Ind R"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Row" = r;
}

permissionset 91931 "LT Y19 R And Ind R"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y19 R", "LT Y19 Ind R";
}

// P12: wildcard table data grants.
permissionset 91932 "LT Y19 Wild R"
{
    Assignable = true;
    Permissions = tabledata * = R;
}

permissionset 91933 "LT Y19 Wild Ind R"
{
    Assignable = true;
    Permissions = tabledata * = r;
}

permissionset 91934 "LT Y19 Wild RIMD"
{
    Assignable = true;
    Permissions = tabledata * = RIMD;
}

// Helpers shared by the Y19 test codeunits (not SingleInstance, no state).
codeunit 91935 "LT Y19 Perm Helper"
{
    procedure StartMock(var Mock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    procedure RestoreMock(var Mock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;

    // Read, insert, modify, delete and execute of "User Permissions".GetEffectivePermission, comma separated.
    procedure Rights(ObjectType: Option "Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query","System",,,,,,,,,; ObjectId: Integer): Text
    var
        UserPermissions: Codeunit "User Permissions";
        Expanded: Record "Expanded Permission" temporary;
    begin
        Expanded := UserPermissions.GetEffectivePermission(ObjectType, ObjectId);
        exit(Format(Expanded."Read Permission") + ',' + Format(Expanded."Insert Permission") + ',' + Format(Expanded."Modify Permission") + ',' +
            Format(Expanded."Delete Permission") + ',' + Format(Expanded."Execute Permission"));
    end;

    // Rows 1 (value 10) and 2 (value 20) in "LT Y19 Row"; the other own tables empty.
    procedure Seed()
    var
        Row: Record "LT Y19 Row";
        A: Record "LT Y19 Trig A";
        APerm: Record "LT Y19 Trig A Perm";
        B: Record "LT Y19 Trig B";
        ExtRow: Record "LT Y19 Ext Row";
    begin
        Row.DeleteAll();
        A.DeleteAll();
        APerm.DeleteAll();
        B.DeleteAll();
        ExtRow.DeleteAll();
        Row.Id := 1;
        Row.Value := 10;
        Row.Insert();
        Row.Id := 2;
        Row.Value := 20;
        Row.Insert();
    end;

    // P3 seed: row 1 in both A tables (inserted without triggers) and row 1 in B.
    procedure SeedTriggers()
    var
        A: Record "LT Y19 Trig A";
        APerm: Record "LT Y19 Trig A Perm";
        B: Record "LT Y19 Trig B";
    begin
        Seed();
        A.Id := 1;
        A.Insert();
        APerm.Id := 1;
        APerm.Insert();
        B.Id := 1;
        B.Insert();
    end;

    // The rows of "LT Y19 Row" as "id=value;..." (the inherent read works under any mocked set).
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT Y19 Row", 'R')]
    procedure DescribeRows(): Text
    var
        Row: Record "LT Y19 Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '=' + Format(Row.Value) + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT Y19 Trig B", 'R')]
    procedure DescribeB(): Text
    var
        B: Record "LT Y19 Trig B";
        Result: Text;
    begin
        if B.FindSet() then
            repeat
                Result += Format(B.Id) + '=' + Format(B.Value) + ';';
            until B.Next() = 0;
        exit(Result);
    end;
}
