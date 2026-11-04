// A table's unqualified TableRelation or CalcFormula table name is resolved by the compiler in
// the scope of the file that wrote it: its own namespace first, then its using directives.
// ALTRelationNameCollisionTables.al declares "Shipping Agent" (60990) and "Config. Package
// Table" (60991) in ALLanguage.Coverage.RelationNameCollision, shadowing Base Application tables
// 291 and 8613 by name. TestRelationTargetNameCollision covers the other direction, a Base
// Application table's relation staying on Base Application.
//
// - 69200 and 69202 are declared in that same namespace: their names mean the local tables.
// - 69201 and 69203 are declared in another namespace that imports the Base Application
//   namespaces and not the local one: their names mean Base Application's tables.
// - 69202 and 69203 are each extended by a tableextension whose modify(...) changes the
//   relation field; 69200 and 69201 are not. Same names, same expected answers.
// - A tableextension field writes its names in the extension's file, not the base table's:
//   69207 sits in the same file as table 69203 (Base Application's table); 69206 is added to
//   69203 by an extension declared in the local namespace (ALTRelationScopeExtension.al), so it
//   means the local table; the FlowField it adds counts the local "Config. Package Table".
// - 69214 and 69215 (plain, and modify twin 69216 extension) are declared in a third namespace
//   that imports the namespace of the same-named local tables and no Base Application one: the
//   names mean the local tables, reached through a using within the app.
//
// Each test asserts a concrete id or count. The Validate tests also assert the OTHER table is
// refused, and each FlowField test fills both tables with different row counts.

codeunit 69210 "Test Relation Target NS Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RelationScope_SameNamespace_RelationAnswersTheLocalTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69200);

        Assert.AreEqual(60990, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69200 relates to the same-namespace table 60990');
    end;

    [Test]
    procedure RelationScope_SameNamespace_Validate_AcceptsLocalRefusesBase()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69200);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-namespace table 60990 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationScope_SameNamespace_FlowField_CountsTheLocalTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69200');

        RecRef.Open(69200);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69200';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69200 counts the same-namespace "Config. Package Table" (2 rows), not the Base Application one (1 row)');
    end;

    [Test]
    procedure RelationScope_SameNamespaceModified_RelationAnswersTheLocalTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69202);

        Assert.AreEqual(60990, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69202 relates to the same-namespace table 60990');
    end;

    [Test]
    procedure RelationScope_SameNamespaceModified_Validate_AcceptsLocalRefusesBase()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69202);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-namespace table 60990 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationScope_SameNamespaceModified_FlowField_CountsTheLocalTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69202');

        RecRef.Open(69202);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69202';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69202 counts the same-namespace "Config. Package Table" (2 rows), not the Base Application one (1 row)');
    end;

    [Test]
    procedure RelationScope_Usings_RelationAnswersTheImportedTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69201);

        Assert.AreEqual(291, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69201 relates to Base Application table 291');
    end;

    [Test]
    procedure RelationScope_Usings_Validate_AcceptsBaseRefusesLocal()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69201);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(2).Value),
            'a value present only in Base Application table 291 validates');

        asserterror RecRef.Field(2).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationScope_Usings_FlowField_CountsTheImportedTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69201');

        RecRef.Open(69201);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69201';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(1, RecRef.Field(3).Value,
            'the FlowField in table 69201 counts the Base Application "Config. Package Table" (1 row), not the same-named table 60991 (2 rows)');
    end;

    [Test]
    procedure RelationScope_UsingsModified_RelationAnswersTheImportedTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69203);

        Assert.AreEqual(291, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69203 relates to Base Application table 291');
    end;

    [Test]
    procedure RelationScope_UsingsModified_Validate_AcceptsBaseRefusesLocal()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69203);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(2).Value),
            'a value present only in Base Application table 291 validates');

        asserterror RecRef.Field(2).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationScope_UsingsModified_FlowField_CountsTheImportedTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69203');

        RecRef.Open(69203);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69203';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(1, RecRef.Field(3).Value,
            'the FlowField in table 69203 counts the Base Application "Config. Package Table" (1 row), not the same-named table 60991 (2 rows)');
    end;

    [Test]
    procedure RelationScope_UsingsModified_ExtensionFieldInTheSameFile_RelationAnswersTheImportedTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69203);

        Assert.AreEqual(291, RecRef.Field(69207).Relation(),
            'the extension field "Ext Agent Code" is written under using Microsoft.Foundation.Shipping and relates to Base Application table 291');
    end;

    [Test]
    procedure RelationScope_UsingsModified_ExtensionFieldInAnotherNamespace_RelationFollowsTheExtension()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69203);

        Assert.AreEqual(60990, RecRef.Field(69206).Relation(),
            'the extension field is written in the namespace that declares table 60990, so its "Shipping Agent" is that table, although table 69203 itself is written under using Microsoft.Foundation.Shipping');
    end;

    [Test]
    procedure RelationScope_Third_RelationAnswersTheLocalTableThroughUsing()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69214);

        Assert.AreEqual(60990, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69214 relates to 60990, which using ALLanguage.Coverage.RelationNameCollision brings in');
    end;

    [Test]
    procedure RelationScope_Third_Validate_AcceptsLocalRefusesBase()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69214);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-app table 60990 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationScope_Third_FlowField_CountsTheLocalTableThroughUsing()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69214');

        RecRef.Open(69214);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69214';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69214 counts the local "Config. Package Table" (2 rows) that the using brings in, not Base Application''s (1 row)');
    end;

    [Test]
    procedure RelationScope_ThirdModified_RelationAnswersTheLocalTableThroughUsing()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69215);

        Assert.AreEqual(60990, RecRef.Field(2).Relation(),
            'the unqualified "Shipping Agent" in table 69215 relates to 60990, which using ALLanguage.Coverage.RelationNameCollision brings in');
    end;

    [Test]
    procedure RelationScope_ThirdModified_Validate_AcceptsLocalRefusesBase()
    var
        RecRef: RecordRef;
    begin
        InsertAgents();

        RecRef.Open(69215);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-app table 60990 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationScope_ThirdModified_FlowField_CountsTheLocalTableThroughUsing()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKG69215');

        RecRef.Open(69215);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKG69215';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69215 counts the local "Config. Package Table" (2 rows) that the using brings in, not Base Application''s (1 row)');
    end;

    [Test]
    procedure RelationScope_UsingsModified_ExtensionFieldInAnotherNamespace_FlowFieldCountsTheExtensionsTable()
    var
        RecRef: RecordRef;
    begin
        InsertPackageTables('ALTPKGEXT');

        RecRef.Open(69203);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTPKGEXT';
        RecRef.Field(69208).CalcField();

        Assert.AreEqual(2, RecRef.Field(69208).Value,
            'the extension FlowField is written in the namespace that declares table 60991, so it counts that table (2 rows), not the Base Application "Config. Package Table" (1 row) that table 69203 itself imports');
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
    // same-named local table gets two.
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
