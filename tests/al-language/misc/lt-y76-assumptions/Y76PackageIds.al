// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/admin-how-to-import-and-apply-configuration-packages
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own using System.IO;

codeunit 94077
// Probe (writer Y76, al-runtime-rs assumption package-auto-increment-from-one): a Dimension Value whose AutoIncrement field "Dimension Value ID" is not
// in the package that creates it. A configuration package (Config. Package, one table Dimension Value, the field "Dimension Value ID" excluded) is
// built in AL and applied with Config. Package Management.ApplyPackage; the ids the rows get, in the order of the package rows, and the id of a row
// inserted afterwards. The absolute numbers depend on how many Dimension Value rows the database numbered before; the test asserts the differences.
// BC versions: 27, 28, 29

codeunit 94077 "LT Y76 Package Ids"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddPackageRow(PackageCode: Code[20]; No: Integer; DimCode: Code[20]; ValueCode: Code[20])
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        DimValue: Record "Dimension Value";
    begin
        ConfigPackageRecord.Init();
        ConfigPackageRecord."Package Code" := PackageCode;
        ConfigPackageRecord."Table ID" := Database::"Dimension Value";
        ConfigPackageRecord."No." := No;
        ConfigPackageRecord.Insert();
        ConfigPackageMgt.InsertPackageData(ConfigPackageData, PackageCode, Database::"Dimension Value", No, DimValue.FieldNo("Dimension Code"), DimCode, false);
        ConfigPackageMgt.InsertPackageData(ConfigPackageData, PackageCode, Database::"Dimension Value", No, DimValue.FieldNo(Code), ValueCode, false);
        ConfigPackageMgt.InsertPackageData(ConfigPackageData, PackageCode, Database::"Dimension Value", No, DimValue.FieldNo(Name), 'Name ' + ValueCode, false);
    end;

    [Test]
    procedure Y76_Package_AutoIncrementField_NotInPackage()
    var
        Observer: Codeunit "Probe Observer";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record System.IO."Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        Errors: Integer;
        Ids: Text;
    begin
        Dimension.Init();
        Dimension.Code := 'LTY76DIM';
        Dimension.Insert();
        ConfigPackageMgt.InsertPackage(ConfigPackage, 'LTY76', 'LT Y76', false);
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, 'LTY76', Database::"Dimension Value");
        ConfigPackageField.SetRange("Package Code", 'LTY76');
        ConfigPackageField.SetRange("Table ID", Database::"Dimension Value");
        if ConfigPackageField.FindSet() then
            repeat
                ConfigPackageField."Include Field" := ConfigPackageField."Field ID" in [DimValue.FieldNo("Dimension Code"), DimValue.FieldNo(Code), DimValue.FieldNo(Name)];
                ConfigPackageField.Modify();
            until ConfigPackageField.Next() = 0;
        AddPackageRow('LTY76', 1, 'LTY76DIM', 'V1');
        AddPackageRow('LTY76', 2, 'LTY76DIM', 'V2');
        AddPackageRow('LTY76', 3, 'LTY76DIM', 'V3');
        Errors := ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, false);
        Observer.Observe('apply errors', Format(Errors));
        DimValue.SetRange("Dimension Code", 'LTY76DIM');
        Observer.Observe('rows', Format(DimValue.Count()));
        if DimValue.FindSet() then
            repeat
                Ids += DimValue.Code + '=' + Format(DimValue."Dimension Value ID") + ' ';
            until DimValue.Next() = 0;
        Observer.Observe('ids', Ids);
        DimValue.Init();
        DimValue."Dimension Code" := 'LTY76DIM';
        DimValue.Code := 'V4';
        DimValue.Insert();
        Observer.Observe('next plain insert id', Format(DimValue."Dimension Value ID"));
        Observer.Finish();
    end;
}
