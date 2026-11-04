// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none (own objects; Permissions Mock from the dependency).
// Objects for CpPermLeads.al (corpus issue 669, items 76 to 89): tables, permission sets with direct and indirect grants, codeunits with and
// without a Permissions property, an event subscriber with a Permissions property, and methods with the InherentPermissions attribute.
// Object ids 85000-85016; tests in 85018-85023.

table 85000 "LT CP Ledger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Amount; Decimal) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 85001 "LT CP Flow Host"
{
    DataClassification = SystemMetadata;
    InherentPermissions = RIMD;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Ledger Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CP Ledger");
        }
        field(3; "Ledger Sum"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CP Ledger".Amount);
        }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 85002 "LT CP Item"
{
    DataClassification = SystemMetadata;
    InherentPermissions = RIMD;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Mode; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 85003 "LT CP Ext"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 85004 "LT CP Secret"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// Indirect grants only: read, insert and modify on the ledger, read on the extension table.
permissionset 85005 "LT CP Indirect"
{
    Assignable = true;
    Permissions =
        tabledata "LT CP Ledger" = rim,
        tabledata "LT CP Ext" = r;
}

// Grants nothing on the ledger, the extension table or the secret table.
permissionset 85006 "LT CP Empty"
{
    Assignable = true;
    Permissions = tabledata "LT CP Item" = R;
}

permissionset 85007 "LT CP Full"
{
    Assignable = true;
    Permissions = tabledata "LT CP Ledger" = RIMD;
}

permissionset 85008 "LT CP Ledger R"
{
    Assignable = true;
    Permissions = tabledata "LT CP Ledger" = R;
}

// Includes RIMD on the ledger and excludes the set that grants R on it.
permissionset 85009 "LT CP Excl"
{
    Assignable = true;
    IncludedPermissionSets = "LT CP Full";
    ExcludedPermissionSets = "LT CP Ledger R";
}

codeunit 85010 "LT CP Writer"
{
    Permissions = tabledata "LT CP Ledger" = rim;

    procedure InsertRow(EntryNo: Integer)
    var
        Ledger: Record "LT CP Ledger";
    begin
        Ledger."Entry No." := EntryNo;
        Ledger.Amount := 1;
        Ledger.Insert();
    end;

    procedure ModifyRow(EntryNo: Integer; NewAmount: Decimal)
    var
        Ledger: Record "LT CP Ledger";
    begin
        Ledger.Get(EntryNo);
        Ledger.Amount := NewAmount;
        Ledger.Modify();
    end;

    procedure CountRows(): Integer
    var
        Ledger: Record "LT CP Ledger";
    begin
        exit(Ledger.Count());
    end;
}

codeunit 85011 "LT CP Writer Read Only"
{
    Permissions = tabledata "LT CP Ledger" = r;

    procedure InsertRow(EntryNo: Integer)
    var
        Ledger: Record "LT CP Ledger";
    begin
        Ledger."Entry No." := EntryNo;
        Ledger.Insert();
    end;
}

codeunit 85012 "LT CP Subscriber"
{
    Permissions = tabledata "LT CP Ext" = r;

    [EventSubscriber(ObjectType::Table, Database::"LT CP Item", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyItem(var Rec: Record "LT CP Item"; var xRec: Record "LT CP Item"; RunTrigger: Boolean)
    var
        Ext: Record "LT CP Ext";
        Reader: Codeunit "LT CP Reader";
        ReaderPerm: Codeunit "LT CP Reader Perm";
        Inherent: Codeunit "LT CP Inherent";
    begin
        case Rec.Mode of
            1:
                if not Ext.Get(1) then
                    Error('LT CP ext row 1 not found');
            2:
                Reader.ReadExt();
            3:
                ReaderPerm.ReadExt();
            4:
                Inherent.ReadExtInherent();
        end;
    end;
}

codeunit 85013 "LT CP Reader"
{
    procedure ReadExt()
    var
        Ext: Record "LT CP Ext";
    begin
        if not Ext.Get(1) then
            Error('LT CP ext row 1 not found');
    end;
}

codeunit 85014 "LT CP Reader Perm"
{
    Permissions = tabledata "LT CP Ext" = r;

    procedure ReadExt()
    var
        Ext: Record "LT CP Ext";
    begin
        if not Ext.Get(1) then
            Error('LT CP ext row 1 not found');
    end;
}

codeunit 85015 "LT CP Inherent"
{
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT CP Secret", 'R')]
    procedure CountInherent(): Integer
    var
        Secret: Record "LT CP Secret";
    begin
        exit(Secret.Count());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT CP Secret", 'R')]
    procedure CountNested(): Integer
    begin
        exit(CountPlain());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT CP Secret", 'R')]
    procedure CountViaOther(): Integer
    var
        Other: Codeunit "LT CP Secret Reader";
    begin
        exit(Other.CountSecret());
    end;

    procedure CountPlain(): Integer
    var
        Secret: Record "LT CP Secret";
    begin
        exit(Secret.Count());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT CP Ext", 'R')]
    procedure ReadExtInherent()
    var
        Ext: Record "LT CP Ext";
    begin
        if not Ext.Get(1) then
            Error('LT CP ext row 1 not found');
    end;
}

codeunit 85016 "LT CP Secret Reader"
{
    procedure CountSecret(): Integer
    var
        Secret: Record "LT CP Secret";
    begin
        exit(Secret.Count());
    end;
}
