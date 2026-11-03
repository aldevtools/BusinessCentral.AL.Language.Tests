// Cross-app fixture A: package data probes of writer Y88 (follow-up of Y85, same file layout, see Y85XaPackageData.al). The files TAB<id>.navxdata
// in this folder are loaded by the install codeunit 94682 (Y8XaInstallOrder.al) with NavApp.LoadPackageData, each inside a TryFunction. The error
// of a load is written to the log table 94681; the tests are in tests/al-language/install/lt-y88-package-data/Y88PackageData.al.
//   94680 events: two rows; subscribers log every table event of the table.
//   94683 option: file ordinal 1, 7 (the option has 0..2), 2.   94684 enum: ordinals 5, 9 (undefined), 7, -1 (undefined), 0.
//   94686 date 1752-12-31 (before the first valid date); 94687 DateTime.ToBinary 0 (0001-01-01); 94688 date 9999-12-31.
//   94689 decimal 79228162514264337593543950335 (System.Decimal maximum); 94690 decimal 1E-28 (scale 28).

table 94681 "LT Y88 Pkg Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Kind; Text[20]) { }
        field(3; Subject; Text[50]) { }
        field(4; Detail; Text[250]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 94680 "LT Y88 Pkg Events"
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

codeunit 94691 "LT Y88 Pkg Event Log"
{
    local procedure Add(What: Text; Rec: Record "LT Y88 Pkg Events")
    var
        Log: Record "LT Y88 Pkg Log";
    begin
        Log.Kind := 'event';
        Log.Subject := CopyStr(What, 1, 50);
        Log.Detail := CopyStr(Rec."No." + '=' + Rec.Description, 1, 250);
        if Log.Insert() then;
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y88 Pkg Events", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "LT Y88 Pkg Events"; RunTrigger: Boolean)
    begin
        Add('before insert ' + Format(RunTrigger), Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y88 Pkg Events", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "LT Y88 Pkg Events"; RunTrigger: Boolean)
    begin
        Add('after insert ' + Format(RunTrigger), Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y88 Pkg Events", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "LT Y88 Pkg Events"; var xRec: Record "LT Y88 Pkg Events"; RunTrigger: Boolean)
    begin
        Add('before modify ' + Format(RunTrigger), Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y88 Pkg Events", 'OnBeforeValidateEvent', 'Description', false, false)]
    local procedure BeforeValidate(var Rec: Record "LT Y88 Pkg Events"; var xRec: Record "LT Y88 Pkg Events"; CurrFieldNo: Integer)
    begin
        Add('before validate', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y88 Pkg Events", 'OnAfterValidateEvent', 'Description', false, false)]
    local procedure AfterValidate(var Rec: Record "LT Y88 Pkg Events"; var xRec: Record "LT Y88 Pkg Events"; CurrFieldNo: Integer)
    begin
        Add('after validate', Rec);
    end;
}

table 94683 "LT Y88 Pkg Option"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Opt; Option) { OptionMembers = Zero,One,Two; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

enum 94685 "LT Y88 Pkg Enum"
{
    value(0; Zero) { }
    value(5; Five) { }
    value(7; "Seven Up") { }
}

table 94684 "LT Y88 Pkg Enum Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Enm; Enum "LT Y88 Pkg Enum") { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94686 "LT Y88 Pkg Date Low"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Dat; Date) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94687 "LT Y88 Pkg Date Zero"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Dat; Date) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94688 "LT Y88 Pkg Date High"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Dat; Date) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94689 "LT Y88 Pkg Dec Huge"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Dec; Decimal) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94690 "LT Y88 Pkg Dec Tiny"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Dec; Decimal) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
