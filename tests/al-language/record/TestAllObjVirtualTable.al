// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: ALT Relation Parent (60028), ALT Relation Parent B (60030),
//                ALT Event Mutation Control (codeunit 60030), ALT Captioned (60830),
//                ALT Card Page (60017), ALT List Page (60016),
//                ALT Profile RC SameApp (page 60904), Install Seeder (codeunit 60618),
//                Not An Installer (codeunit 60619), ALT CRM Entity (60291),
//                ALT Temp Only (60025), ALT Simple Report (60018),
//                ALT Triggered Order Ext (tableextension 60024 over ALT Triggered 60002),
//                ALT Keyed Ext (tableextension 60330 over ALT Keyed 60006),
//                TPX List Ext (pageextension 60723 over TPX List 60722),
//                EEM Status Ext (enumextension 60881 over EEM Status 60880),
//                TP CurrFieldNo Job Ext (tableextension 60390 over Job),
//                Spaced Action Base Ext (pageextension 60245 over Item Attribute Values),
//                TP Precompiled Capture Ext (pageextension 60735 over Item Attribute),
//                ALT Separator Captioned (60026), ALT Global Trigger Sub (codeunit 60025),
//                ALT Event Mutation Sub (codeunit 60031)
// BC versions: 27.5+
//
// Pins the built-in "AllObj" (2000000038) and "AllObjWithCaption" (2000000058) system
// virtual tables: one row per compiled object, keyed on (Object Type, Object ID) and
// computed from the object's own metadata. Microsoft's own test libraries look table
// captions up through AllObjWithCaption, and this corpus's slim Assert carries a comment
// saying the lookup was dropped because the table "is a virtual platform table not visible
// to AL Runner v2's resolved dep set" -- a claim about a downstream consumer that nothing
// here adjudicated, because nothing here read either table at all.
//
// The discriminating test is AllObj_Get_SameObjectIdDifferentType_ReturnsDifferentObject:
// object id 60030 is BOTH a table and a codeunit in this app, with different names, so a
// provider keyed on the id alone -- or one answering a fixed row -- fails exactly one of
// the two halves.
//
// The AllObjWithCaption_..._ObjectSubtype... tests pin the "Object Subtype" column
// (field 30, AllObjWithCaption only -- AllObj has no such column). Its value is
// per-object-kind: a page reports its PageType, a codeunit its Subtype, a table its
// TableType, and a kind with no subtype concept reports the empty string. Each of those
// is asserted against at least two fixtures with DIFFERENT declared values, so an
// implementation answering one constant -- including the empty string every kind would
// otherwise take -- fails at least one half.
//
// The AllObjWithCaption_..._Extension_... tests pin the same column for the *extension
// object kinds, where the rule is different in kind rather than in value: BC reports the
// ID OF THE OBJECT THE EXTENSION EXTENDS, as a decimal string, instead of a type name.
// Three of the five kinds the option set carries are covered (TableExtension,
// PageExtension, EnumExtension); this app declares no permissionsetextension and no
// reportextension, so those two are unasserted rather than asserted empty.
//
// Three properties are pinned separately, because an implementation can get the simple
// case right and each of these wrong: the target may live in ANOTHER app (an extension
// over Base Application's Job / Item Attribute reports that object's id, not nothing);
// the id is resolved in the TARGET KIND's own namespace; and two extensions over one
// target both report it, so the value identifies the target rather than the extension.

// The codeunit case carries two things worth pinning. First the asymmetry: a codeunit
// whose subtype is Normal reports the EMPTY string, while a table whose TableType is
// Normal reports the word 'Normal'. Second, a Subtype = Install codeunit ALSO reports the
// empty string -- not because Install is blanked, but because the AL compiler never writes
// Install into object metadata in the first place, so this column sees Normal. The
// sibling column asserts that same fact from the other side
// (Record_CodeunitMetadata_Get_InstallCodeunit_ReportsSubtypeNormal).

// The AllObjWithCaption_..._App... tests pin the three owning-app columns of
// AllObjWithCaption: "App Package ID" (60), "App Runtime Package ID" (61) and "App ID" (62).
// 60 and 61 must equal AllObj's own columns for the same (Object Type, Object ID) -- the two
// tables describe one object. "App ID" is the owning app's MANIFEST id (NavApp module id),
// not a package id: this app's objects report this module's id, a Base Application table
// reports Base Application's. And "App ID" is filled per object kind: an enum reports the
// empty guid even when its package columns are filled.

codeunit 60802 "Test AllObj Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AllObj_Get_TableObject_ReturnsMatchingRow()
    // CLAIM: AllObj has a row for a compiled table, keyed on (Object Type::Table, id).
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, Database::"ALT Relation Parent"),
            'AllObj has no Table row for ALT Relation Parent.');

        Assert.AreEqual(
            'ALT Relation Parent', AllObj."Object Name",
            'Unexpected Object Name for the AllObj Table row of ALT Relation Parent.');
        Assert.AreEqual(
            Database::"ALT Relation Parent", AllObj."Object ID",
            'Unexpected Object ID for the AllObj Table row of ALT Relation Parent.');
        Assert.AreEqual(
            AllObj."Object Type"::Table, AllObj."Object Type",
            'The row fetched with Object Type::Table must report Object Type::Table.');
    end;

    [Test]
    procedure AllObj_Get_PageObject_ReturnsMatchingRow()
    // CLAIM: the same lookup works for a non-table object type.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Page, Page::"ALT Card Page"),
            'AllObj has no Page row for ALT Card Page.');

        Assert.AreEqual(
            'ALT Card Page', AllObj."Object Name",
            'Unexpected Object Name for the AllObj Page row of ALT Card Page.');
        Assert.AreEqual(
            AllObj."Object Type"::Page, AllObj."Object Type",
            'The row fetched with Object Type::Page must report Object Type::Page.');
    end;

    [Test]
    procedure AllObj_Get_SameObjectIdDifferentType_ReturnsDifferentObject()
    // CLAIM: the key is (Object Type, Object ID) -- the same id under two object types
    // resolves to two different objects.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // 60030 is table "ALT Relation Parent B"...
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, 60030),
            'AllObj has no Table row for object id 60030.');
        Assert.AreEqual(
            'ALT Relation Parent B', AllObj."Object Name",
            'Object id 60030 as a Table is ALT Relation Parent B.');

        // ...and 60030 is ALSO codeunit "ALT Event Mutation Control". Same id, different
        // object type, different name: an implementation that ignored Object Type, or that
        // answered a constant row, cannot satisfy both halves of this test.
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Codeunit, 60030),
            'AllObj has no Codeunit row for object id 60030.');
        Assert.AreEqual(
            'ALT Event Mutation Control', AllObj."Object Name",
            'Object id 60030 as a Codeunit is ALT Event Mutation Control.');
    end;

    [Test]
    procedure AllObj_Get_ObjectTypeThatDoesNotUseTheId_ReturnsFalse()
    // CLAIM: an id that exists under one object type is absent under another.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // 60028 is a table in this app, and no codeunit anywhere uses that id -- 50000..99999
        // is the partner range, so Microsoft ships nothing there either.
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, 60028),
            'AllObj has no Table row for object id 60028.');
        Assert.IsFalse(
            AllObj.Get(AllObj."Object Type"::Codeunit, 60028),
            'No codeunit uses object id 60028, so AllObj must have no Codeunit row for it.');
    end;

    [Test]
    procedure AllObj_Get_UnknownObjectId_ReturnsFalse()
    // CLAIM: Get returns false for an id no object uses.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // Negative control for every positive test above: a provider answering every Get
        // with true would pass them all and fail here.
        Assert.IsFalse(
            AllObj.Get(AllObj."Object Type"::Table, 99999999),
            'AllObj must not have a row for an id no object uses.');
    end;

    [Test]
    procedure AllObj_SetRange_OnObjectTypeAndIdRange_SelectsOnlyMatchingRows()
    // CLAIM: filtering on Object Type and an Object ID range selects exactly the objects in
    // that range of that type.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // Tables 60028, 60029 and 60030 are three consecutive fixture tables, so the count is
        // a concrete number rather than "more than zero". The name filter lists the objects the
        // counts are about, so an object that another file adds in 60028..60030 does not change
        // them (CONTRIBUTING.md, standing rule 10). It also lists, per object type, one object
        // below and one above the range: tables ALT Separator Captioned (60026) and ALT Captioned
        // (60830), codeunits ALT Global Trigger Sub (60025) and ALT Event Mutation Sub (60031).
        // The counts 3 and 1 hold only when the range excludes those rows on both sides.
        AllObj.SetFilter(
            "Object Name", '%1|%2|%3|%4|%5|%6|%7|%8',
            'ALT Relation Parent', 'ALT Relation Child', 'ALT Relation Parent B', 'ALT Event Mutation Control',
            'ALT Separator Captioned', 'ALT Captioned', 'ALT Global Trigger Sub', 'ALT Event Mutation Sub');
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", 60028, 60030);
        Assert.AreEqual(3, AllObj.Count(), 'The Table rows for object ids 60028..60030 are exactly three.');

        // The same id range under Object Type::Codeunit selects only 60030: the listed codeunits
        // 60025 and 60031 lie outside the range -- and the Object Type half of the filter is doing work.
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        Assert.AreEqual(1, AllObj.Count(), 'Exactly one codeunit is declared in the id range 60028..60030.');
        Assert.IsTrue(AllObj.FindFirst(), 'FindFirst must succeed for the one codeunit in the range.');
        Assert.AreEqual(
            'ALT Event Mutation Control', AllObj."Object Name",
            'The one codeunit in the id range 60028..60030 is ALT Event Mutation Control.');

        // And a range no object of that type occupies selects nothing. No app may declare an id
        // there, so this range needs no name filter.
        AllObj.SetRange("Object Name");
        AllObj.SetRange("Object ID", 99999998, 99999999);
        Assert.AreEqual(0, AllObj.Count(), 'A range no object occupies must select no rows.');
        Assert.IsTrue(AllObj.IsEmpty(), 'IsEmpty must be true for a range no object occupies.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_CaptionedTable_ReportsDeclaredCaption()
    // CLAIM: AllObjWithCaption carries the object's caption alongside its name, and the two
    // are different strings when the object declares a Caption.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Captioned"),
            'AllObjWithCaption has no Table row for ALT Captioned.');

        // ALT Captioned exists precisely because its Caption and its Name differ, so a
        // provider echoing the name into the caption column cannot pass both assertions.
        Assert.AreEqual(
            'ALT Captioned', AllObjWithCaption."Object Name",
            'Object Name must read the object name of ALT Captioned.');
        Assert.AreEqual(
            'Captioned Fixture Table', AllObjWithCaption."Object Caption",
            'Object Caption must read the declared Caption of ALT Captioned, not its object name.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_SecondTable_ReportsItsOwnNameAndId()
    // CLAIM: AllObjWithCaption's columns vary per row rather than being constants.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Relation Parent B"),
            'AllObjWithCaption has no Table row for ALT Relation Parent B.');

        // A different row than the test above, read the same way.
        Assert.AreEqual(
            'ALT Relation Parent B', AllObjWithCaption."Object Name",
            'Unexpected Object Name for ALT Relation Parent B.');
        Assert.AreEqual(
            60030, AllObjWithCaption."Object ID",
            'ALT Relation Parent B is declared as table 60030.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_UnknownObjectId_ReturnsFalse()
    // CLAIM: Get returns false for an id no object uses.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsFalse(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, 99999999),
            'AllObjWithCaption must not have a row for an id no object uses.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Page_ObjectSubtypeIsThePageType()
    // CLAIM: for a Page row, Object Subtype carries the page's declared PageType, spelled
    // exactly as the AL PageType property is spelled.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // ALT Card Page declares PageType = Card.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Page::"ALT Card Page"),
            'AllObjWithCaption has no Page row for ALT Card Page.');
        Assert.AreEqual(
            'Card', AllObjWithCaption."Object Subtype",
            'Object Subtype of a PageType = Card page must be ''Card''.');

        // ALT List Page declares PageType = List. Two pages with DIFFERENT declared page
        // types, read the same way: an implementation answering one constant -- including
        // the empty string, or AL's default 'Card' for every page -- fails one of them.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Page::"ALT List Page"),
            'AllObjWithCaption has no Page row for ALT List Page.');
        Assert.AreEqual(
            'List', AllObjWithCaption."Object Subtype",
            'Object Subtype of a PageType = List page must be ''List''.');
    end;

    [Test]
    procedure AllObjWithCaption_SetRange_ObjectSubtypeRoleCenter_FindsTheRoleCenterPage()
    // CLAIM: Object Subtype is a filterable column -- filtering Page rows to
    // Object Subtype = 'RoleCenter' selects role-center pages and excludes others. This
    // is the shape Base Application's own Role Center picker uses.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // Positive: the one RoleCenter page this app declares is reachable through the
        // filter, by name.
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');
        AllObjWithCaption.SetRange("Object ID", Page::"ALT Profile RC SameApp");
        Assert.IsTrue(
            AllObjWithCaption.FindFirst(),
            'Filtering Page rows to Object Subtype ''RoleCenter'' must find ALT Profile RC SameApp.');
        Assert.AreEqual(
            'ALT Profile RC SameApp', AllObjWithCaption."Object Name",
            'The RoleCenter-filtered row for that id is ALT Profile RC SameApp.');
        Assert.AreEqual(
            'RoleCenter', AllObjWithCaption."Object Subtype",
            'A row selected by Object Subtype = ''RoleCenter'' must report that subtype.');

        // Negative: the SAME filter over a Card page's id selects nothing, so the subtype
        // half of the filter is doing work rather than being ignored.
        AllObjWithCaption.SetRange("Object ID", Page::"ALT Card Page");
        Assert.IsTrue(
            AllObjWithCaption.IsEmpty(),
            'A PageType = Card page must not be selected by Object Subtype = ''RoleCenter''.');

        // ...and that same Card page IS selected once the subtype filter matches it, so the
        // emptiness above is the subtype filter and not a missing row.
        AllObjWithCaption.SetRange("Object Subtype", 'Card');
        Assert.IsTrue(
            AllObjWithCaption.FindFirst(),
            'ALT Card Page must be selected by Object Subtype = ''Card''.');
        Assert.AreEqual(
            'ALT Card Page', AllObjWithCaption."Object Name",
            'The Card-filtered row for that id is ALT Card Page.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Codeunit_ObjectSubtypeIsTheSubtypeAndEmptyForNormal()
    // CLAIM: for a Codeunit row, Object Subtype carries the subtype the AL COMPILER wrote
    // into object metadata -- and is the EMPTY string when that is Normal, rather than the
    // word 'Normal'.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // This very codeunit declares Subtype = Test, so it reads its own row. Subtype = Test
        // is carried into object metadata, unlike Install -- see the next test.
        Assert.IsTrue(
            AllObjWithCaption.Get(
                AllObjWithCaption."Object Type"::Codeunit, Codeunit::"Test AllObj Virtual Table"),
            'AllObjWithCaption has no Codeunit row for Test AllObj Virtual Table.');
        Assert.AreEqual(
            'Test', AllObjWithCaption."Object Subtype",
            'Object Subtype of a Subtype = Test codeunit must be ''Test''.');

        // Not An Installer declares no Subtype at all, so its subtype is Normal -- and BC
        // reports Normal as the empty string, not as 'Normal'. The pair is what makes this
        // discriminating: an implementation writing the subtype name unconditionally passes
        // the first half and fails here.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Codeunit::"Not An Installer"),
            'AllObjWithCaption has no Codeunit row for Not An Installer.');
        Assert.AreEqual(
            '', AllObjWithCaption."Object Subtype",
            'Object Subtype of a codeunit whose subtype is Normal must be the empty string.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_InstallCodeunit_ObjectSubtypeIsEmpty()
    // CLAIM: a Subtype = Install codeunit reports the EMPTY string here, not 'Install'.
    //
    // This is not the Normal-is-blanked rule reaching a second case -- it is a fact about
    // the AL COMPILER, one level upstream of this table. The compiler does not carry
    // Install into object metadata: NCLMetaCodeunit.Subtype reads the codeunit's
    // NavCodeunitOptionsAttribute, i.e. what the compiler wrote, and for an Install
    // codeunit that is Normal. AllObjWithCaption then blanks Normal, so the value lands on
    // the empty string by two steps rather than one.
    //
    // The sibling column asserts the same fact from the other side: CodeUnit Metadata
    // (2000000137) reports Subtype::Normal for an Install codeunit
    // (Record_CodeunitMetadata_Get_InstallCodeunit_ReportsSubtypeNormal). This test is why
    // an implementation cannot satisfy the Subtype = Test case above by simply echoing the
    // declared property.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Codeunit::"Install Seeder"),
            'AllObjWithCaption has no Codeunit row for Install Seeder.');
        Assert.AreEqual(
            '', AllObjWithCaption."Object Subtype",
            'A Subtype = Install codeunit reports the empty string: the compiler writes Normal.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Table_ObjectSubtypeIsTheTableType()
    // CLAIM: for a Table row, Object Subtype carries the declared TableType.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // ALT CRM Entity declares TableType = CRM.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT CRM Entity"),
            'AllObjWithCaption has no Table row for ALT CRM Entity.');
        Assert.AreEqual(
            'CRM', AllObjWithCaption."Object Subtype",
            'Object Subtype of a TableType = CRM table must be ''CRM''.');

        // ALT Temp Only declares TableType = Temporary -- a different value, so the column
        // is read off the table rather than being a constant.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Temp Only"),
            'AllObjWithCaption has no Table row for ALT Temp Only.');
        Assert.AreEqual(
            'Temporary', AllObjWithCaption."Object Subtype",
            'Object Subtype of a TableType = Temporary table must be ''Temporary''.');

        // ALT Captioned declares no TableType, so its table type is Normal. Unlike a
        // codeunit's Normal subtype, a table's TableType is reported by NAME -- BC only
        // special-cases Normal for codeunits.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Captioned"),
            'AllObjWithCaption has no Table row for ALT Captioned.');
        Assert.AreEqual(
            'Normal', AllObjWithCaption."Object Subtype",
            'Object Subtype of a table declaring no TableType must be ''Normal''.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Report_ObjectSubtypeIsEmpty()
    // CLAIM: object kinds that have no subtype concept report the EMPTY string, not some
    // placeholder. This is the negative control for every positive case above: an
    // implementation inventing a subtype for every kind fails here.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, Report::"ALT Simple Report"),
            'AllObjWithCaption has no Report row for ALT Simple Report.');
        Assert.AreEqual(
            '', AllObjWithCaption."Object Subtype",
            'A Report has no subtype, so Object Subtype must be the empty string.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_TableExtension_ObjectSubtypeIsTheTargetTableId()
    // CLAIM: for a TableExtension row, Object Subtype is the ID OF THE TABLE IT EXTENDS,
    // rendered as a decimal string -- not a type name, unlike every other object kind on
    // this table, and not the empty string.
    //
    // The two extensions below target DIFFERENT tables, so an implementation answering one
    // constant -- including the empty string, or the extension's own id -- fails at least
    // one half. The second pair (an extension id and its target id that are far apart)
    // additionally rules out "the id minus a fixed offset".
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // tableextension 60024 "ALT Triggered Order Ext" extends table 60002 "ALT Triggered".
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::TableExtension, 60024),
            'AllObjWithCaption has no TableExtension row for ALT Triggered Order Ext.');
        Assert.AreEqual(
            'ALT Triggered Order Ext', AllObjWithCaption."Object Name",
            'Unexpected Object Name for the TableExtension row 60024.');
        Assert.AreEqual(
            '60002', AllObjWithCaption."Object Subtype",
            'Object Subtype of a tableextension must be the id of the table it extends.');

        // tableextension 60330 "ALT Keyed Ext" extends table 60006 "ALT Keyed" -- a
        // different target, read the same way.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::TableExtension, 60330),
            'AllObjWithCaption has no TableExtension row for ALT Keyed Ext.');
        Assert.AreEqual(
            'ALT Keyed Ext', AllObjWithCaption."Object Name",
            'Unexpected Object Name for the TableExtension row 60330.');
        Assert.AreEqual(
            '60006', AllObjWithCaption."Object Subtype",
            'Object Subtype of ALT Keyed Ext must be 60006, the id of ALT Keyed.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_PageExtension_ObjectSubtypeIsTheTargetPageId()
    // CLAIM: the same rule holds for a PageExtension, and the id it reports is resolved in
    // the PAGE id namespace -- AL gives every object kind its own, so a tableextension and
    // a pageextension naming the same number extend two different objects.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // pageextension 60723 "TPX List Ext" extends page 60722 "TPX List".
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::PageExtension, 60723),
            'AllObjWithCaption has no PageExtension row for TPX List Ext.');
        Assert.AreEqual(
            'TPX List Ext', AllObjWithCaption."Object Name",
            'Unexpected Object Name for the PageExtension row 60723.');
        Assert.AreEqual(
            '60722', AllObjWithCaption."Object Subtype",
            'Object Subtype of a pageextension must be the id of the page it extends.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_EnumExtension_ObjectSubtypeIsTheTargetEnumId()
    // CLAIM: and for an EnumExtension -- a third kind, so the rule is per-extension-kind
    // rather than a property of tables and pages.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // enumextension 60881 "EEM Status Ext" extends enum 60880 "EEM Status".
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::EnumExtension, 60881),
            'AllObjWithCaption has no EnumExtension row for EEM Status Ext.');
        Assert.AreEqual(
            'EEM Status Ext', AllObjWithCaption."Object Name",
            'Unexpected Object Name for the EnumExtension row 60881.');
        Assert.AreEqual(
            '60880', AllObjWithCaption."Object Subtype",
            'Object Subtype of an enumextension must be the id of the enum it extends.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_ExtensionOfPrecompiledObject_ObjectSubtypeIsTheTargetId()
    // CLAIM: the target does not have to live in this app. "TP CurrFieldNo Job Ext"
    // extends Job (table 167), which ships in the Base Application -- so the column
    // reports an id from ANOTHER app rather than only ids this app declares.
    //
    // This is the second of the three sub-questions the runner-side issue asks: whether an
    // extension whose target is in another app reports that target's id, or nothing.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // tableextension 60390 "TP CurrFieldNo Job Ext" extends Job.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::TableExtension, 60390),
            'AllObjWithCaption has no TableExtension row for TP CurrFieldNo Job Ext.');
        Assert.AreEqual(
            Format(Database::Job), AllObjWithCaption."Object Subtype",
            'Object Subtype of an extension over a Base Application table must be that table''s id.');
    end;

    [Test]
    procedure AllObjWithCaption_SetRange_ObjectSubtypeOfTwoExtensionsOverOneTarget_SelectsBoth()
    // CLAIM: two extensions over the SAME target both report that target's id -- the value
    // identifies the target, not the extension, so it is not unique across rows.
    //
    // This is the third sub-question the runner-side issue asks. "Spaced Action Base Ext"
    // (60245) and "TP Precompiled Capture Ext" (60735) are two pageextensions over two
    // DIFFERENT Base Application pages, which is the control: if the column were a
    // constant, or the extension's own id, the two filters below could not separate them.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // pageextension 60245 "Spaced Action Base Ext" extends "Item Attribute Values".
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::PageExtension, 60245),
            'AllObjWithCaption has no PageExtension row for Spaced Action Base Ext.');
        Assert.AreEqual(
            Format(Page::"Item Attribute Values"), AllObjWithCaption."Object Subtype",
            'Spaced Action Base Ext extends Item Attribute Values, so it reports that page''s id.');

        // pageextension 60735 "TP Precompiled Capture Ext" extends "Item Attribute" -- a
        // DIFFERENT Base Application page, so the two rows carry different subtypes.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::PageExtension, 60735),
            'AllObjWithCaption has no PageExtension row for TP Precompiled Capture Ext.');
        Assert.AreEqual(
            Format(Page::"Item Attribute"), AllObjWithCaption."Object Subtype",
            'TP Precompiled Capture Ext extends Item Attribute, so it reports that page''s id.');

        // And the column is filterable in this shape too: filtering PageExtension rows to
        // the target's id selects the extension over that target and not the other one.
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
        AllObjWithCaption.SetRange("Object Subtype", Format(Page::"Item Attribute"));
        AllObjWithCaption.SetRange("Object ID", 60245);
        Assert.IsTrue(
            AllObjWithCaption.IsEmpty(),
            'Spaced Action Base Ext does not extend Item Attribute, so that filter must not select it.');

        AllObjWithCaption.SetRange("Object ID", 60735);
        Assert.IsTrue(
            AllObjWithCaption.FindFirst(),
            'TP Precompiled Capture Ext extends Item Attribute, so that filter must select it.');
        Assert.AreEqual(
            'TP Precompiled Capture Ext', AllObjWithCaption."Object Name",
            'The row selected by the Item Attribute subtype filter is TP Precompiled Capture Ext.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_OwnObjects_AppIdIsThisModulesId()
    // CLAIM: "App ID" on a row for an object this app declares is this app's module id --
    // for a table, a page and a codeunit alike.
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ThisModule: ModuleInfo;
        EmptyId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Assert.AreNotEqual(EmptyId, ThisModule.Id(), 'The current module must have an id.');

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Relation Parent"),
            'AllObjWithCaption has no Table row for ALT Relation Parent.');
        Assert.AreEqual(
            ThisModule.Id(), AllObjWithCaption."App ID",
            'App ID of a table this app declares must be this app''s id.');

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Page::"ALT Card Page"),
            'AllObjWithCaption has no Page row for ALT Card Page.');
        Assert.AreEqual(
            ThisModule.Id(), AllObjWithCaption."App ID",
            'App ID of a page this app declares must be this app''s id.');

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Codeunit::"ALT Event Mutation Control"),
            'AllObjWithCaption has no Codeunit row for ALT Event Mutation Control.');
        Assert.AreEqual(
            ThisModule.Id(), AllObjWithCaption."App ID",
            'App ID of a codeunit this app declares must be this app''s id.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_OwnTable_PackageIdsEqualAllObj()
    // CLAIM: "App Package ID" and "App Runtime Package ID" are the same values AllObj reports
    // for the same object, and for an object this app declares they are not empty. And "App
    // ID" is NOT one of them: it is the manifest id, a different guid.
    var
        AllObj: Record AllObj;
        AllObjWithCaption: Record AllObjWithCaption;
        EmptyId: Guid;
    begin
        Initialize();

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, Database::"ALT Relation Parent"),
            'AllObj has no Table row for ALT Relation Parent.');
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Relation Parent"),
            'AllObjWithCaption has no Table row for ALT Relation Parent.');

        Assert.AreNotEqual(
            EmptyId, AllObjWithCaption."App Runtime Package ID",
            'App Runtime Package ID of a table this app declares must not be empty.');
        Assert.AreEqual(
            AllObj."App Runtime Package ID", AllObjWithCaption."App Runtime Package ID",
            'AllObjWithCaption and AllObj must report the same App Runtime Package ID for one table.');
        Assert.AreEqual(
            AllObj."App Package ID", AllObjWithCaption."App Package ID",
            'AllObjWithCaption and AllObj must report the same App Package ID for one table.');
        Assert.AreNotEqual(
            AllObjWithCaption."App Runtime Package ID", AllObjWithCaption."App ID",
            'App ID is the app''s manifest id, not its runtime package id.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_BaseApplicationTable_AppIdIsBaseApplication()
    // CLAIM: a table from ANOTHER app reports THAT app's id -- Base Application's for
    // Customer -- and its package columns still equal AllObj's. The control against an
    // implementation stamping the current module's id on every row.
    var
        AllObj: Record AllObj;
        AllObjWithCaption: Record AllObjWithCaption;
        ThisModule: ModuleInfo;
        BaseApplicationId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Evaluate(BaseApplicationId, '437dbf0e-84ff-417a-965d-ed2bb9650972');

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::Customer),
            'AllObjWithCaption has no Table row for Customer.');
        Assert.AreEqual(
            BaseApplicationId, AllObjWithCaption."App ID",
            'App ID of Customer must be Base Application''s id.');
        Assert.AreNotEqual(
            ThisModule.Id(), AllObjWithCaption."App ID",
            'App ID of Customer must not be the calling app''s id.');

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, Database::Customer),
            'AllObj has no Table row for Customer.');
        Assert.AreEqual(
            AllObj."App Runtime Package ID", AllObjWithCaption."App Runtime Package ID",
            'AllObjWithCaption and AllObj must report the same App Runtime Package ID for Customer.');
        Assert.AreEqual(
            AllObj."App Package ID", AllObjWithCaption."App Package ID",
            'AllObjWithCaption and AllObj must report the same App Package ID for Customer.');
    end;

    [Test]
    procedure AllObjWithCaption_FindEnum_BaseApplicationEnum_AppIdIsEmpty()
    // CLAIM: "App ID" is filled per object kind, and an Enum is not one of the kinds that get
    // it: a Base Application enum reports the empty App ID, while its package columns still
    // equal AllObj's. The control against an implementation copying the owner onto every kind.
    var
        AllObj: Record AllObj;
        AllObjWithCaption: Record AllObjWithCaption;
        EmptyId: Guid;
    begin
        Initialize();

        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Enum);
        AllObjWithCaption.SetRange("Object Name", 'Sales Document Type');
        Assert.IsTrue(
            AllObjWithCaption.FindFirst(),
            'AllObjWithCaption has no Enum row for Sales Document Type.');
        Assert.AreEqual(
            EmptyId, AllObjWithCaption."App ID",
            'App ID of an enum must be the empty guid.');

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Enum, AllObjWithCaption."Object ID"),
            'AllObj has no Enum row for Sales Document Type.');
        Assert.AreEqual(
            AllObj."App Runtime Package ID", AllObjWithCaption."App Runtime Package ID",
            'AllObjWithCaption and AllObj must report the same App Runtime Package ID for an enum.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_ReportExtension_ObjectSubtypeIsTheTargetReportId()
    // CLAIM: for a ReportExtension row, Object Subtype is the ID OF THE REPORT IT EXTENDS,
    // rendered as a decimal string -- the same rule the tableextension, pageextension and
    // enumextension tests above pin, extended to the fourth *extension kind.
    //
    // Worth its own assertion rather than resting on the other three: a reportextension
    // carries its target under a different manifest spelling from the kinds already covered,
    // so it is the kind where a wrong reading yields an empty subtype -- indistinguishable
    // from "this kind has no subtype concept", which is the answer every non-extension kind
    // legitimately gives. See AL Runner issue #3566.
    //
    // The two extensions target reports 394 apart, so one constant -- the empty string, the
    // extension's own id, or a fixed offset -- fails at least one half.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // reportextension 60011 "ALT Simple Report Ext" extends report 60018.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::ReportExtension, 60011),
            'AllObjWithCaption has no ReportExtension row for ALT Simple Report Ext.');
        Assert.AreEqual(
            '60018', AllObjWithCaption."Object Subtype",
            'Object Subtype of a reportextension must be the id of the report it extends.');

        // reportextension 60012 "ALT Tx None Rep Ext" extends report 60412.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::ReportExtension, 60012),
            'AllObjWithCaption has no ReportExtension row for ALT Tx None Rep Ext.');
        Assert.AreEqual(
            '60412', AllObjWithCaption."Object Subtype",
            'A second reportextension must report ITS target, not the first one''s.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_PermissionSetExtension_ObjectSubtypeIsTheTargetSetId()
    // CLAIM: for a PermissionSetExtension row, Object Subtype is the ID OF THE PERMISSION SET
    // IT EXTENDS, rendered as a decimal string -- the fifth and last *extension kind.
    //
    // The two extensions target permission sets 907 apart. See AL Runner issue #3566.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // permissionsetextension 60019 "ALT NonAssignable Ext" extends permissionset 60023.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::PermissionSetExtension, 60019),
            'AllObjWithCaption has no PermissionSetExtension row for ALT NonAssignable Ext.');
        Assert.AreEqual(
            '60023', AllObjWithCaption."Object Subtype",
            'Object Subtype of a permissionsetextension must be the id of the set it extends.');

        // permissionsetextension 60021 "ALT Agg Perm Set Ext" extends permissionset 60930.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::PermissionSetExtension, 60021),
            'AllObjWithCaption has no PermissionSetExtension row for ALT Agg Perm Set Ext.');
        Assert.AreEqual(
            '60930', AllObjWithCaption."Object Subtype",
            'A second permissionsetextension must report ITS target, not the first one''s.');
    end;

    // Writer BP2 (corpus issue 664, microsoft/AL issue 3019): how BC registers codeunit 82557 "LT BP Lower Subtype", whose Subtype is
    // written in lower case (`Subtype = test;`), next to a codeunit with `Subtype = Test;` and a normal codeunit.
    [Test]
    procedure AllObj_LowerCaseSubtypeCodeunit_ObjectSubtype_BP()
    var
        Observer: Codeunit "Probe Observer";
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, 82557);
        Observer.Observe('lower case test', AllObj."Object Subtype");
        AllObj.Get(AllObj."Object Type"::Codeunit, Codeunit::"Test AllObj Virtual Table");
        Observer.Observe('Subtype = Test', AllObj."Object Subtype");
        AllObj.Get(AllObj."Object Type"::Codeunit, Codeunit::"LT BP DataScope Holder");
        Observer.Observe('normal codeunit', AllObj."Object Subtype");
        Observer.Expect('lower case test', 'Test');
        Observer.Expect('Subtype = Test', 'Test');
        Observer.Expect('normal codeunit', '');
        Observer.Verify();
    end;

    local procedure Initialize()
    begin
        // AllObj and AllObjWithCaption are read-only system virtual tables -- nothing to
        // DeleteAll.
    end;
}

// Writer BP (corpus issue 664, microsoft/AL issue 3019): a codeunit whose Subtype is written in lower case (`Subtype = test;`). It
// compiles, the runner finds its [Test] procedure, and AllObjWithCaption shows its Object Subtype.
codeunit 82557 "LT BP Lower Subtype"
{
    Subtype = test;
    TestPermissions = Disabled;

    [Test]
    procedure BP_LowerCaseSubtype_TestRuns()
    var
        Observer: Codeunit "Probe Observer";
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, Codeunit::"LT BP Lower Subtype");
        Observer.Observe('own subtype', AllObj."Object Subtype");
        AllObj.Get(AllObj."Object Type"::Codeunit, Codeunit::"Test AllObj Virtual Table");
        Observer.Observe('Subtype = Test codeunit', AllObj."Object Subtype");
        AllObj.Get(AllObj."Object Type"::Codeunit, Codeunit::"LT BP DataScope Holder");
        Observer.Observe('normal codeunit', AllObj."Object Subtype");
        Observer.Finish();
    end;
}
