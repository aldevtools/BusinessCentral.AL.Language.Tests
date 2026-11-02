// Cross-app fixture A: package data (NavApp.LoadPackageData) of writer Y85, al-runner issue 6649. The files TAB<id>.navxdata in this folder are the
// table data files that the install codeunit 94449 loads (all but 94447 and 94448) with NavApp.LoadPackageData. Their layout, confirmed by what the platform reads back:
//   u32 0xDA7A, u32 1, u32 table id, u32 field count, the field names (BinaryWriter strings; the names are ignored), then per row 0x01, the values of
//   the primary key fields in key order and then of the other stored fields in declaration order (FlowFields, FlowFilters and disabled fields are
//   not stored; fields of table extensions follow), then the 16 bytes of the SystemId; the file ends with 0x00. Values: Code and Text are
//   BinaryWriter strings; Integer, Option and Enum int32; BigInteger and Duration (milliseconds) int64; Boolean one byte; Decimal the 16 bytes of
//   System.Decimal; Guid 16 bytes; Date, Time and DateTime int64 DateTime.ToBinary (Time on 1753-01-01); DateFormula a string; a BLOB with
//   Compressed = false an int64 length and the bytes. The tests are in tests/al-language/install/lt-y85-package-data/Y85PackageData.al.
// Code values are stored as written (a Code key in the file must be upper case to be found by Get); reading shows Code upper case.
// Install code must never fail: each table is loaded only while it is empty.

table 50100 "LT Y85 Pkg Company"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    // NavApp.LoadPackageData runs no table trigger: the rows keep the Description of the file.
    trigger OnInsert()
    begin
        Description := 'TRIGGER';
    end;
}

table 94440 "LT Y85 Pkg Database"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
        field(3; Amount; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

enum 94445 "LT Y85 Pkg Enum"
{
    value(0; Zero) { }
    value(5; Five) { }
    value(7; "Seven Up") { }
}

table 94441 "LT Y85 Pkg Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Cde; Code[10]) { }
        field(4; Int; Integer) { }
        field(5; Big; BigInteger) { }
        field(6; Dec; Decimal) { }
        field(7; Bool; Boolean) { }
        field(8; Dat; Date) { }
        field(9; Tim; Time) { }
        field(10; Dtm; DateTime) { }
        field(11; Dur; Duration) { }
        field(12; Gid; Guid) { }
        field(13; Opt; Option) { OptionMembers = Zero,One,Two; }
        field(14; Enm; Enum "LT Y85 Pkg Enum") { }
        field(15; Dfm; DateFormula) { }
        field(16; Blb; Blob) { Compressed = false; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// The file lists the values as B, A (the primary key), then C, "No." (declaration order), then Ext (the table extension): Fl is a FlowField and Dis is
// disabled, so neither is in the file.
table 94442 "LT Y85 Pkg Order"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(4; C; Code[10]) { }
        field(1; "No."; Code[20]) { }
        field(5; Fl; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y85 Pkg Database");
        }
        field(2; A; Code[10]) { }
        field(6; Dis; Integer) { Enabled = false; }
        field(3; B; Code[10]) { }
    }
    keys
    {
        key(PK; B, A) { Clustered = true; }
    }
}

tableextension 94444 "LT Y85 Pkg Order Ext" extends "LT Y85 Pkg Order"
{
    fields
    {
        field(94446; Ext; Integer) { }
    }
}

table 94443 "LT Y85 Pkg Auto"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Tables 94447 (per company) and 94448 (DataPerCompany = false) have a data file that the install code never loads: the tests call LoadPackageData for them.
table 94447 "LT Y85 Pkg Late"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94448 "LT Y85 Pkg Late Database"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 94449 "LT Y85 Pkg Install"

{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Company: Record "LT Y85 Pkg Company";
        Types: Record "LT Y85 Pkg Types";
        Order: Record "LT Y85 Pkg Order";
        Auto: Record "LT Y85 Pkg Auto";
    begin
        if Company.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Company");
        if Types.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Types");
        if Order.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Order");
        if Auto.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Auto");
    end;

    trigger OnInstallAppPerDatabase()
    var
        Db: Record "LT Y85 Pkg Database";
    begin
        if Db.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Database");
    end;
}
