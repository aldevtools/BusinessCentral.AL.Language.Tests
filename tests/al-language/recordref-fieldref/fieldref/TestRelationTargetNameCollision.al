// A Base Application field's TableRelation and CalcFormula point at Base Application tables by
// object id, fixed when Base Application compiled. An app that depends on Base Application and
// declares a table with the SAME NAME in its own namespace cannot change that: Base
// Application never saw the dependent app. ALTRelationNameCollisionTables.al supplies the two
// same-named tables.
//
// Each test asserts a concrete id or count, and each has a counterpart that only passes when
// the dependent app's table is NOT the one consulted: the Validate with a value present only
// in the same-named table must be refused, and the FlowField must count the row in the Base
// Application table.

codeunit 60988 "Test Relation Name Collision"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RelationNameCollision_BaseAppRelation_AnswersBaseAppTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::Microsoft.Sales.Customer.Customer);
        FldRef := RecRef.Field(31);

        Assert.AreEqual(291, FldRef.Relation(),
            'Customer."Shipping Agent Code" relates to Base Application table 291, not to a same-named table 60990 in a dependent app');
    end;

    [Test]
    procedure RelationNameCollision_Validate_AcceptsValueInBaseAppTable()
    var
        Agent: Record Microsoft.Foundation.Shipping."Shipping Agent";
        Customer: Record Microsoft.Sales.Customer.Customer;
    begin
        Agent.Init();
        Agent.Code := 'ALTBASE';
        Agent.Insert(false);

        Customer.Init();
        Customer.Validate("Shipping Agent Code", 'ALTBASE');

        Assert.AreEqual('ALTBASE', Customer."Shipping Agent Code",
            'a value present in Base Application "Shipping Agent" must validate');
    end;

    [Test]
    procedure RelationNameCollision_Validate_RefusesValueOnlyInSameNamedTable()
    var
        LocalAgent: Record ALLanguage.Coverage.RelationNameCollision."Shipping Agent";
        Customer: Record Microsoft.Sales.Customer.Customer;
    begin
        LocalAgent.Init();
        LocalAgent.Code := 'ALTLOCAL';
        LocalAgent.Insert(false);

        Customer.Init();
        asserterror Customer.Validate("Shipping Agent Code", 'ALTLOCAL');

        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationNameCollision_BaseAppFlowField_CountsBaseAppTable()
    var
        Package: Record System.IO."Config. Package";
        PackageTable: Record System.IO."Config. Package Table";
        LocalPackageTable: Record ALLanguage.Coverage.RelationNameCollision."Config. Package Table";
    begin
        Package.Init();
        Package.Code := 'ALTPKG';
        Package.Insert(false);

        PackageTable.Init();
        PackageTable."Package Code" := 'ALTPKG';
        PackageTable."Table ID" := 18;
        PackageTable.Insert(false);

        LocalPackageTable.Init();
        LocalPackageTable."Package Code" := 'ALTPKG';
        LocalPackageTable."Table ID" := 18;
        LocalPackageTable.Insert(false);
        LocalPackageTable.Init();
        LocalPackageTable."Package Code" := 'ALTPKG';
        LocalPackageTable."Table ID" := 27;
        LocalPackageTable.Insert(false);

        Package.CalcFields("No. of Tables");

        Assert.AreEqual(1, Package."No. of Tables",
            '"Config. Package"."No. of Tables" counts Base Application "Config. Package Table" (1 row), not the same-named table 60991 (2 rows)');
    end;
}
