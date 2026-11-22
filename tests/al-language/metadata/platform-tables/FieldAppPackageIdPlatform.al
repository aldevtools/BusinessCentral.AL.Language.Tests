// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope. The App Package ID and App Runtime Package ID of Field rows: of platform tables (Object, Field, Table Metadata, AllObj), of a Base Application table and of this app's own table; a SetRange on App Package ID without a TableNo filter.
// Fixtures used: Probe Observer (codeunit 69160); own table 77800 (FC Coll Row, from FilterCollationNordic.al); own codeunit 77804 (Field App Package Id Platform)
// Probe: from al-runner issue 8089 (Field."App Package ID" SetRange without TableNo). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

codeunit 77804 "Field App Package Id Platform"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(TableId: Integer): Text
    var
        FieldRec: Record Field;
        Info: ModuleInfo;
        Result: Text;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        FieldRec.SetRange(TableNo, TableId);
        if not FieldRec.FindFirst() then
            exit('no field rows');
        Result := 'packageNull=' + Format(IsNullGuid(FieldRec."App Package ID"));
        Result += ' runtimeNull=' + Format(IsNullGuid(FieldRec."App Runtime Package ID"));
        Result += ' packageIsThisApp=' + Format(FieldRec."App Package ID" = Info.PackageId());
        Result += ' runtimeEqualsPackage=' + Format(FieldRec."App Runtime Package ID" = FieldRec."App Package ID");
        exit(Result);
    end;

    local procedure AllRowsShare(TableId: Integer): Text
    var
        FieldRec: Record Field;
        First: Guid;
        Total: Integer;
    begin
        FieldRec.SetRange(TableNo, TableId);
        if not FieldRec.FindFirst() then
            exit('no field rows');
        First := FieldRec."App Package ID";
        Total := FieldRec.Count();
        FieldRec.SetRange("App Package ID", First);
        exit(Format(FieldRec.Count() = Total));
    end;

    [Test]
    procedure FieldRows_PackageIds_PerTableKind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('object', Describe(2000000001));
        Observer.Observe('field', Describe(2000000041));
        Observer.Observe('tableMetadata', Describe(2000000136));
        Observer.Observe('allObj', Describe(2000000038));
        // 291 is the Base Application table "Shipping Agent"; the corpus has its own table of that name (AL0275 by name).
        Observer.Observe('baseAppShippingAgent', Describe(291));
        Observer.Observe('ownTable', Describe(Database::"FC Coll Row"));
        Observer.Observe('objectAllRowsShare', AllRowsShare(2000000001));
        Observer.Observe('ownAllRowsShare', AllRowsShare(Database::"FC Coll Row"));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRows_NullPackageFilter_PlatformTable()
    var
        FieldRec: Record Field;
        Observer: Codeunit "Probe Observer";
        NullId: Guid;
        Total: Integer;
    begin
        FieldRec.SetRange(TableNo, 2000000001);
        Total := FieldRec.Count();
        FieldRec.SetRange("App Package ID", NullId);
        Observer.Observe('objectRowsWithNullPackage', Format(FieldRec.Count() = Total));
        FieldRec.SetRange("App Package ID");
        FieldRec.SetRange("App Runtime Package ID", NullId);
        Observer.Observe('objectRowsWithNullRuntime', Format(FieldRec.Count() = Total));
        Observer.Finish();
    end;

    [Test]
    procedure SetRange_PackageId_NoTableNo_FindSet()
    var
        FieldRec: Record Field;
        Info: ModuleInfo;
        Observer: Codeunit "Probe Observer";
        SawOwnName: Boolean;
        SawPlatform: Boolean;
        SawOtherPackage: Boolean;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        FieldRec.SetRange("App Package ID", Info.PackageId());
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        if FieldRec.FindSet() then
            repeat
                if (FieldRec.TableNo = Database::"FC Coll Row") and (FieldRec."No." = 2) then
                    SawOwnName := true;
                if FieldRec.TableNo >= 2000000000 then
                    SawPlatform := true;
                if FieldRec."App Package ID" <> Info.PackageId() then
                    SawOtherPackage := true;
            until FieldRec.Next() = 0;
        Observer.Observe('foundOwnField', Format(SawOwnName));
        Observer.Observe('foundPlatformRow', Format(SawPlatform));
        Observer.Observe('foundOtherPackage', Format(SawOtherPackage));
        FieldRec.SetRange(TableNo, 2000000001);
        Observer.Observe('objectRowsWithThisPackageEmpty', Format(FieldRec.IsEmpty()));
        Observer.Finish();
    end;
}
