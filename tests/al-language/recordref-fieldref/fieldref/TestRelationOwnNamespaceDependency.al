// A table's unqualified TableRelation or CalcFormula table name is resolved by the compiler in
// the scope of the file that wrote it: its own namespace first, then its using directives. This
// file pins the case where the name is found in BOTH the file's own namespace and an imported
// one, and one of the two is a Base Application table while the other is declared in this app.
//
// ALTRelationNameCollisionTables.al declares "Shipping Agent" (60990) and "Config. Package
// Table" (60991) in ALLanguage.Coverage.RelationNameCollision. Base Application declares tables
// of the same names, 291 in Microsoft.Foundation.Shipping and 8613 in System.IO. The sibling
// codeunit 69210 pins the shapes where only ONE of the two is in scope.
//
// - 69222 and 69223 are written in Microsoft.Foundation.Shipping and import the app's namespace:
//   the own-namespace table is Base Application's, so "Shipping Agent" means 291 and the app's
//   60990 never takes over. 69229 and 69230 are the CalcFormula half, written in System.IO:
//   "Config. Package Table" means 8613, not 60991.
// - 69226 and 69227 are written in the app's namespace and import both Base Application
//   namespaces: the own-namespace tables are the app's, so the names mean 60990 and 60991. The
//   other direction of the same rule.
// - Each shape has a twin whose table a tableextension touches with modify(...): 69223, 69230
//   and 69227; 69222, 69229 and 69226 are not touched. Same names, same expected answers.
//   Table extension 69224 also adds a field, "Ext Agent Code", written in the same file as
//   table 69223.
//
// Each test asserts a concrete id or count. The Validate tests also assert the OTHER table is
// refused, and each FlowField test fills the two tables with different row counts.

codeunit 69217 "Test Relation Own NS Dep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RelationOwnNS_OwnDep_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69222);

        Assert.AreEqual(291, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69222 relates to Base Application table 291 (the own-namespace table), not the imported 60990');
    end;

    [Test]
    procedure RelationOwnNS_OwnDep_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69222);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(2).Value),
            'a value present only in Base Application table 291 validates');

        asserterror RecRef.Field(2).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepModified_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69223);

        Assert.AreEqual(291, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69223 relates to Base Application table 291 (the own-namespace table), not the imported 60990');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepModified_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69223);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(2).Value),
            'a value present only in Base Application table 291 validates');

        asserterror RecRef.Field(2).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepModified_ExtensionField_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69223);

        Assert.AreEqual(291, RecRef.Field(69225).Relation(),
            'the extension field is written in the file of table 69223, where "Shipping Agent" means Base Application table 291, not the imported 60990');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepModified_ExtensionField_Validate_AcceptsBaseRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69223);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(69225).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(69225).Value),
            'a value present only in Base Application table 291 validates');

        asserterror RecRef.Field(69225).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnDep_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69229');

        RecRef.Open(69229);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69229';
        RecRef.Field(2).CalcField();

        Assert.AreEqual(1, RecRef.Field(2).Value,
            'the FlowField in table 69229 counts Base Application "Config. Package Table" (1 row), not the imported 60991 (2 rows)');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepModified_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69230');

        RecRef.Open(69230);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69230';
        RecRef.Field(2).CalcField();

        Assert.AreEqual(1, RecRef.Field(2).Value,
            'the FlowField in table 69230 counts Base Application "Config. Package Table" (1 row), not the imported 60991 (2 rows)');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundle_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69226);

        Assert.AreEqual(60990, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69226 relates to the same-namespace table 60990, not Base Application table 291 that the using brings in');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundle_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69226);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-namespace table 60990 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundle_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69226');

        RecRef.Open(69226);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69226';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69226 counts the same-namespace "Config. Package Table" 60991 (2 rows), not the imported Base Application one (1 row)');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundleModified_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69227);

        Assert.AreEqual(60990, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69227 relates to the same-namespace table 60990, not Base Application table 291 that the using brings in');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundleModified_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69227);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-namespace table 60990 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundleModified_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69227');

        RecRef.Open(69227);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69227';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69227 counts the same-namespace "Config. Package Table" 60991 (2 rows), not the imported Base Application one (1 row)');
    end;

    local procedure InsertAgents()
    var
        BaseAgent: Record Microsoft.Foundation.Shipping."Shipping Agent";
        LocalAgent: Record ALLanguage.Coverage.RelationNameCollision."Shipping Agent";
    begin
        if not BaseAgent.Get('ALTBASE') then begin
            BaseAgent.Init();
            BaseAgent.Code := 'ALTBASE';
            BaseAgent.Insert(false);
        end;
        if not LocalAgent.Get('ALTLOCAL') then begin
            LocalAgent.Init();
            LocalAgent.Code := 'ALTLOCAL';
            LocalAgent.Insert(false);
        end;
    end;

    // Base Application's "Config. Package Table" gets one row for the package code, the
    // same-named app table gets two.
    local procedure InsertPackageTables(PackageCode: Code[20])
    var
        BaseTable: Record System.IO."Config. Package Table";
        LocalTable: Record ALLanguage.Coverage.RelationNameCollision."Config. Package Table";
    begin
        BaseTable.Init();
        BaseTable."Package Code" := PackageCode;
        BaseTable."Table ID" := 18;
        BaseTable.Insert(false);

        LocalTable.Init();
        LocalTable."Package Code" := PackageCode;
        LocalTable."Table ID" := 18;
        LocalTable.Insert(false);
        LocalTable.Init();
        LocalTable."Package Code" := PackageCode;
        LocalTable."Table ID" := 27;
        LocalTable.Insert(false);
    end;
}
