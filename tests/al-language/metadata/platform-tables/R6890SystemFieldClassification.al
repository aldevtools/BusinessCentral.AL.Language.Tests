// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 92356 (LT Y35 UN Table, CustomerContent), 95020, 95021
// BC versions: 27.5, 28.5, 29.0
// Measured (Windows 27.5 and 28.5 identical; 29.0 see commit): SystemId (2000000000), SystemCreatedBy and SystemModifiedBy carry
//   DataClassification EndUserPseudonymousIdentifiers (4); SystemCreatedAt and SystemModifiedAt carry SystemMetadata (6), whatever the table
//   declares (CustomerContent, ToBeClassified or nothing); Class Normal, Enabled, ObsoleteState 0; field 0 has no row.
// Probe (al-runner issue 6890): the Field rows of SystemId and the audit fields (No. 2000000000-2000000004): what DataClassification, Class,
//   Type, FieldName, Enabled and ObsoleteState they carry in a table that declares CustomerContent, ToBeClassified or no DataClassification, by
//   Field.Get and in a SetRange(TableNo) walk. The user-name rows 2000000005-2000000008 are pinned in Y35UserNameFieldRows.al.

table 95020 "LT R6890 No Class Table"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95021 "LT R6890 ToBeClass Table"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 95022 "LT R6890 System Field Class"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RowText(var F: Record Field): Text
    begin
        exit(F.FieldName + ': DataClassification=' + Format(F.DataClassification, 0, 9) + '; Class=' + Format(F.Class, 0, 9) + '; Type=' + Format(F.Type, 0, 9) +
            '; Enabled=' + Format(F.Enabled) + '; ObsoleteState=' + Format(F.ObsoleteState, 0, 9));
    end;

    local procedure ObserveRows(Prefix: Text; TableNo: Integer)
    var
        F: Record Field;
        No: Integer;
    begin
        for No := 0 to 2000000004 do begin
            if No = 5 then
                No := 2000000000;
            if F.Get(TableNo, No) then
                Observer.Observe(Prefix + ' get ' + Format(No), RowText(F))
            else
                Observer.Observe(Prefix + ' get ' + Format(No), 'not found');
        end;
    end;

    local procedure Walk(Prefix: Text; TableNo: Integer)
    var
        F: Record Field;
        Result: Text;
    begin
        F.SetRange(TableNo, TableNo);
        F.SetFilter("No.", '>=%1&<=%2', 2000000000, 2000000004);
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + '=' + Format(F.DataClassification, 0, 9) + ',';
            until F.Next() = 0;
        Observer.Observe(Prefix + ' walk', Result);
        F.SetRange(DataClassification, F.DataClassification::SystemMetadata);
        Result := '';
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + ',';
            until F.Next() = 0;
        Observer.Observe(Prefix + ' walk SystemMetadata', Result);
        F.SetRange(DataClassification, F.DataClassification::EndUserPseudonymousIdentifiers);
        Result := '';
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + ',';
            until F.Next() = 0;
        Observer.Observe(Prefix + ' walk EndUserPseudonymousIdentifiers', Result);
    end;

    [Test]
    procedure R6890_SystemFieldRows_CustomerContentTable()
    begin
        ObserveRows('cc', Database::"LT Y35 UN Table");
        Walk('cc', Database::"LT Y35 UN Table");
        Observer.Expect('cc get 0', 'not found');
        Observer.Expect('cc get 1', 'No.: DataClassification=0; Class=0; Type=31489; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc get 2', 'Description: DataClassification=0; Class=0; Type=31488; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc get 3', 'not found');
        Observer.Expect('cc get 4', 'not found');
        Observer.Expect('cc get 2000000000', '$systemId: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc get 2000000001', 'SystemCreatedAt: DataClassification=6; Class=0; Type=37375; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc get 2000000002', 'SystemCreatedBy: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc get 2000000003', 'SystemModifiedAt: DataClassification=6; Class=0; Type=37375; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc get 2000000004', 'SystemModifiedBy: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('cc walk', '2000000000=4,2000000001=6,2000000002=4,2000000003=6,2000000004=4,');
        Observer.Expect('cc walk SystemMetadata', '2000000001,2000000003,');
        Observer.Expect('cc walk EndUserPseudonymousIdentifiers', '2000000000,2000000002,2000000004,');
        Observer.Verify();
    end;

    [Test]
    procedure R6890_SystemFieldRows_NoClassificationTable()
    begin
        ObserveRows('none', Database::"LT R6890 No Class Table");
        Walk('none', Database::"LT R6890 No Class Table");
        Observer.Expect('none get 0', 'not found');
        Observer.Expect('none get 1', 'No.: DataClassification=0; Class=0; Type=31489; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('none get 2', 'not found');
        Observer.Expect('none get 3', 'not found');
        Observer.Expect('none get 4', 'not found');
        Observer.Expect('none get 2000000000', '$systemId: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('none get 2000000001', 'SystemCreatedAt: DataClassification=6; Class=0; Type=37375; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('none get 2000000002', 'SystemCreatedBy: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('none get 2000000003', 'SystemModifiedAt: DataClassification=6; Class=0; Type=37375; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('none get 2000000004', 'SystemModifiedBy: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('none walk', '2000000000=4,2000000001=6,2000000002=4,2000000003=6,2000000004=4,');
        Observer.Expect('none walk SystemMetadata', '2000000001,2000000003,');
        Observer.Expect('none walk EndUserPseudonymousIdentifiers', '2000000000,2000000002,2000000004,');
        Observer.Verify();
    end;

    [Test]
    procedure R6890_SystemFieldRows_ToBeClassifiedTable()
    begin
        ObserveRows('tbc', Database::"LT R6890 ToBeClass Table");
        Walk('tbc', Database::"LT R6890 ToBeClass Table");
        Observer.Expect('tbc get 0', 'not found');
        Observer.Expect('tbc get 1', 'No.: DataClassification=1; Class=0; Type=31489; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('tbc get 2', 'not found');
        Observer.Expect('tbc get 3', 'not found');
        Observer.Expect('tbc get 4', 'not found');
        Observer.Expect('tbc get 2000000000', '$systemId: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('tbc get 2000000001', 'SystemCreatedAt: DataClassification=6; Class=0; Type=37375; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('tbc get 2000000002', 'SystemCreatedBy: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('tbc get 2000000003', 'SystemModifiedAt: DataClassification=6; Class=0; Type=37375; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('tbc get 2000000004', 'SystemModifiedBy: DataClassification=4; Class=0; Type=37119; Enabled=Yes; ObsoleteState=0');
        Observer.Expect('tbc walk', '2000000000=4,2000000001=6,2000000002=4,2000000003=6,2000000004=4,');
        Observer.Expect('tbc walk SystemMetadata', '2000000001,2000000003,');
        Observer.Expect('tbc walk EndUserPseudonymousIdentifiers', '2000000000,2000000002,2000000004,');
        Observer.Verify();
    end;
}
