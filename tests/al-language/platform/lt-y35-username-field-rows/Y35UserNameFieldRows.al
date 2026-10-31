// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 92356; Base Application table 18 Customer (read only)
// Probe (gap cycle 3, C3-05): every column of the Field rows of the user-name system fields SystemCreatedByUserName,
//   SystemCreatedByFullName, SystemModifiedByUserName and SystemModifiedByFullName (No. 2000000005-2000000008 on BC 29), for an own table
//   and a Base Application table, and how filtered scans of Field (Class, Enabled, Type, ObsoleteState) see them. Already pinned:
//   No., FieldName, Type, Len, Class (system-fields/W6SystemFieldStamps.al:239-246), the field names (metadata/W6FieldKeyRows.al:268),
//   Copy of the rows (platform/lt-wc/WcFieldRowCopy.al:53). App Package ID and App Runtime Package ID change with every publish: they are
//   compared with the ones of field 1 of the same table, not shown.
// BC versions: 27.5, 28.5, 29.0 (the four rows exist on BC 29)

table 92356 "LT Y35 UN Table"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 92357 "LT Y35 UN Field Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RowText(var F: Record Field): Text
    var
        First: Record Field;
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        RR.GetTable(F);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if not (FR.Name in ['App Package ID', 'App Runtime Package ID']) then
                Result += FR.Name + '=' + Format(FR.Value, 0, 9) + ';';
        end;
        if First.Get(F.TableNo, 1) then
            Result += 'packages as field 1=' + Format((F."App Package ID" = First."App Package ID") and (F."App Runtime Package ID" = First."App Runtime Package ID")) + ';';
        exit(Result);
    end;

    local procedure ObserveRows(TableNo: Integer)
    var
        F: Record Field;
        No: Integer;
    begin
        for No := 2000000005 to 2000000008 do
            if F.Get(TableNo, No) then
                Observer.Observe(Format(No), RowText(F))
            else
                Observer.Observe(Format(No), 'not found');
    end;

    local procedure SystemNos(var F: Record Field): Text
    var
        Result: Text;
    begin
        F.SetFilter("No.", '>=%1', 2000000000);
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + ',';
            until F.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure C305_UserNameFieldRows_OwnTable()
    begin
        ObserveRows(Database::"LT Y35 UN Table");
        Observer.Finish();
    end;

    [Test]
    procedure C305_UserNameFieldRows_Customer()
    begin
        ObserveRows(Database::Customer);
        Observer.Finish();
    end;

    [Test]
    procedure C305_UserNameFieldRows_FilteredScans()
    var
        F: Record Field;
    begin
        F.SetRange(TableNo, Database::"LT Y35 UN Table");
        Observer.Observe('all', SystemNos(F));
        F.SetRange(Class, F.Class::Normal);
        Observer.Observe('class_normal', SystemNos(F));
        F.SetRange(Class, F.Class::FlowField);
        Observer.Observe('class_flowfield', SystemNos(F));
        F.SetRange(Class);
        F.SetRange(Enabled, true);
        Observer.Observe('enabled', SystemNos(F));
        F.SetRange(Enabled);
        F.SetRange(Type, F.Type::Text);
        Observer.Observe('type_text', SystemNos(F));
        F.SetRange(Type);
        F.SetRange(ObsoleteState, F.ObsoleteState::No);
        Observer.Observe('obsolete_no', SystemNos(F));
        F.SetRange(ObsoleteState);
        F.SetRange(DataClassification, F.DataClassification::EndUserIdentifiableInformation);
        Observer.Observe('dataclass_euii', SystemNos(F));
        F.SetRange(DataClassification);
        F.SetRange(IsPartOfPrimaryKey, false);
        Observer.Observe('not_pk', SystemNos(F));
        Observer.Finish();
    end;
}
