// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y19 Perm Helper (91935, record/Y19PermObjects.al); Permissions Mock (131006) from the dependency.
// Probe (al-runner issues 8092, 8093, 7854): ADR-062 cells that no corpus test measures yet.
//   A (8092) set composition: an assigned set that includes a set with ExcludedPermissionSets (does the exclusion take from the
//     included set only, or from the whole assigned set); two assigned sets where one excludes the other (both orders of Set
//     and Assign). Insert and read of the table, and "User Permissions".GetEffectivePermission of it (Helper.Rights).
//   B (8093) code of extension objects: a write to another table from a tableextension trigger, a tableextension procedure and a
//     pageextension trigger; the extended object with and without Permissions = tabledata B = imd, the extension with and
//     without its own Permissions; a user with imd on B and with nothing on B.
//   C (7854) reads with a filter that matches no row of a table that has rows, read not granted: FindSet, FindLast, Find('-'),
//     Count, IsEmpty (FindFirst is the measured control); Delete(true) and Delete() under a set that grants only the table.
//   D (7854) "Expanded Permission" rows of a tenant set that grants a Page, Report, Codeunit, Query, XMLport and System object:
//     every permission column of each row.
// Note: an extension cannot carry its own Permissions property (AL0246 on tableextension and pageextension), so the
//   'extension with its own Permissions' cell is a must-not-compile fact and is not measured here.
// Shape: each case clears the assignment, seeds, assigns, runs ONE op inside asserterror that ends with the own error
//   'LT PC ok', observes text and code, clears the assignment (as Y19PermWrites.al).
// Expected values: filled in from the local observation run of each major (BC 27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

table 97330 "LT PC T"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnDelete()
    begin
    end;
}

table 97331 "LT PC B" { DataClassification = SystemMetadata; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }

// ---- A: composition (8092) -------------------------------------------------------------------------------------------------

permissionset 97332 "LT PC Grant T" { Assignable = false; Permissions = tabledata "LT PC T" = RIMD; }
permissionset 97333 "LT PC Grant T Again" { Assignable = false; Permissions = tabledata "LT PC T" = RIMD; }

// Included by the assigned set; it excludes "LT PC Grant T".
permissionset 97334 "LT PC Narrow"
{
    Assignable = false;
    Permissions = tabledata "LT PC B" = R;
    ExcludedPermissionSets = "LT PC Grant T";
}

// A1: includes the narrow set and a second set that grants T: does the narrow set's exclusion take T from the whole set?
permissionset 97335 "LT PC Inc Narrow"
{
    Assignable = true;
    IncludedPermissionSets = "LT PC Narrow", "LT PC Grant T Again";
}

// A2: includes the narrow set and the very set it excludes.
permissionset 97336 "LT PC Inc Both"
{
    Assignable = true;
    IncludedPermissionSets = "LT PC Narrow", "LT PC Grant T";
}

// A3/A4: X grants T; Y excludes X.
permissionset 97337 "LT PC X" { Assignable = true; Permissions = tabledata "LT PC T" = RIMD; }
permissionset 97338 "LT PC Y"
{
    Assignable = true;
    Permissions = tabledata "LT PC B" = R;
    ExcludedPermissionSets = "LT PC X";
}

// ---- B: extension objects (8093) -------------------------------------------------------------------------------------------

table 97339 "LT PC E Plain" { DataClassification = SystemMetadata; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
table 97340 "LT PC E ExtPerm" { DataClassification = SystemMetadata; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
table 97341 "LT PC E TabPerm"
{
    DataClassification = SystemMetadata;
    Permissions = tabledata "LT PC B" = imd;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
table 97342 "LT PC E BothPerm"
{
    DataClassification = SystemMetadata;
    Permissions = tabledata "LT PC B" = imd;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 97330 "LT PC X Plain" extends "LT PC E Plain"
{
    trigger OnInsert()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 100;
        B.Insert();
    end;

    procedure WriteB()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 200;
        B.Insert();
    end;
}

tableextension 97331 "LT PC X ExtPerm" extends "LT PC E ExtPerm"
{

    trigger OnInsert()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 100;
        B.Insert();
    end;

    procedure WriteB()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 200;
        B.Insert();
    end;
}

tableextension 97332 "LT PC X TabPerm" extends "LT PC E TabPerm"
{
    trigger OnInsert()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 100;
        B.Insert();
    end;

    procedure WriteB()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 200;
        B.Insert();
    end;
}

tableextension 97333 "LT PC X BothPerm" extends "LT PC E BothPerm"
{

    trigger OnInsert()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 100;
        B.Insert();
    end;

    procedure WriteB()
    var
        B: Record "LT PC B";
    begin
        B.Id := Rec.Id + 200;
        B.Insert();
    end;
}

page 97343 "LT PC Page Plain"
{
    PageType = Card;
    SourceTable = "LT PC E Plain";
    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; } } }
}

page 97344 "LT PC Page Perm"
{
    PageType = Card;
    SourceTable = "LT PC E Plain";
    Permissions = tabledata "LT PC B" = imd;
    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; } } }
}

pageextension 97330 "LT PC PX Plain" extends "LT PC Page Plain"
{
    trigger OnOpenPage()
    var
        B: Record "LT PC B";
    begin
        B.Id := 300;
        B.Insert();
    end;
}

pageextension 97331 "LT PC PX Own" extends "LT PC Page Plain"
{
}

pageextension 97332 "LT PC PX OnPerm" extends "LT PC Page Perm"
{
    trigger OnOpenPage()
    var
        B: Record "LT PC B";
    begin
        B.Id := 301;
        B.Insert();
    end;
}

// The user has RIMD on the extended tables and on T; imd on B, or nothing on B.
permissionset 97345 "LT PC Ext Imd B"
{
    Assignable = true;
    Permissions = tabledata "LT PC E Plain" = RIMD, tabledata "LT PC E ExtPerm" = RIMD, tabledata "LT PC E TabPerm" = RIMD,
        tabledata "LT PC E BothPerm" = RIMD, tabledata "LT PC B" = imd;
}

permissionset 97346 "LT PC Ext No B"
{
    Assignable = true;
    Permissions = tabledata "LT PC E Plain" = RIMD, tabledata "LT PC E ExtPerm" = RIMD, tabledata "LT PC E TabPerm" = RIMD,
        tabledata "LT PC E BothPerm" = RIMD;
}

// ---- C: reads with no match, Delete(true) (7854) ----------------------------------------------------------------------------

permissionset 97347 "LT PC Only B" { Assignable = true; Permissions = tabledata "LT PC B" = R; }
permissionset 97348 "LT PC Only T" { Assignable = true; Permissions = tabledata "LT PC T" = RIMD; }

// ---- D: objects a tenant set grants (7854) ----------------------------------------------------------------------------------

report 97350 "LT PC Report"
{
    ProcessingOnly = true;
    dataset { dataitem(T; "LT PC T") { } }
}

query 97351 "LT PC Query"
{
    elements { dataitem(T; "LT PC T") { column(Id; Id) { } } }
}

xmlport 97352 "LT PC XmlPort"
{
    schema { textelement(Root) { tableelement(T; "LT PC T") { fieldelement(Id; T.Id) { } } } }
}

codeunit 97349 "LT PC Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";
        TenantRoleTok: Label 'LT PC TENANT', Locked = true;

    // A: 1 Set(Inc Narrow) insert T; 2 Set(Inc Narrow) read T; 3 Set(Inc Both) insert T; 4 Set(X), Assign(Y) insert T;
    // 5 Set(Y), Assign(X) insert T; 6 Set(X), Assign(Y) read T. Rights of T observed after each Set/Assign as `<case>|rights`.
    [Test]
    procedure PC_A_Composition()
    var
        WasStarted: Boolean;
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        for Which := 1 to 6 do
            RunCase('a' + Format(Which), Which);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure PC_A_Composition_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_A_Composition_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_A_Composition_More3()
    begin
        Observer.More();
    end;

    // B: 11-14 Insert(true) of E Plain, E ExtPerm, E TabPerm, E BothPerm (tableextension OnInsert writes B), user imd on B;
    // 15-18 the same, nothing on B; 21-24 WriteB() of each, imd on B; 25-28 nothing on B;
    // 31 open page Plain (pageextension OnOpenPage writes B, a second pageextension has Permissions), imd on B; 32 nothing on B;
    // 33 open page Perm (the page has Permissions, its extension's OnOpenPage writes B), imd on B; 34 nothing on B.
    [Test]
    procedure PC_B_ExtensionCode()
    var
        WasStarted: Boolean;
        Ops: List of [Integer];
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        Ops.AddRange(11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26, 27, 28, 31, 32, 33, 34);
        foreach Which in Ops do
            RunCase('b' + Format(Which), Which);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure PC_B_ExtensionCode_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_B_ExtensionCode_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_B_ExtensionCode_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_B_ExtensionCode_More4()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_B_ExtensionCode_More5()
    begin
        Observer.More();
    end;

    // C: T holds rows 1 and 2; the set grants R on B only. SetRange(Id, 100) then 41 FindFirst (control), 42 FindSet,
    // 43 FindLast, 44 Find('-'), 45 Count, 46 IsEmpty; unfiltered 47 FindSet. Set "LT PC Only T": 48 Delete(true) of row 1,
    // 49 Delete() of row 1.
    [Test]
    procedure PC_C_NoMatchReadsAndDelete()
    var
        WasStarted: Boolean;
        Which: Integer;
    begin
        WasStarted := Helper.StartMock(Mock);
        for Which := 41 to 49 do
            RunCase('c' + Format(Which), Which);
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure PC_C_NoMatchReadsAndDelete_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_C_NoMatchReadsAndDelete_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PC_C_NoMatchReadsAndDelete_More3()
    begin
        Observer.More();
    end;

    // D: a tenant set with one row each for Page, Report, Codeunit, Query and XMLport objects of this file, System object 1350
    // and Table "LT PC T", every permission column left at its InitValue Yes: the rows "Expanded Permission" lists.
    [Test]
    procedure PC_D_ExpandedPermissionOfTenantObjectGrants()
    var
        ExpandedPermission: Record "Expanded Permission";
        NullGuid: Guid;
        Rows: Text;
    begin
        SeedTenantSet();
        ExpandedPermission.SetRange("App ID", NullGuid);
        ExpandedPermission.SetRange("Role ID", TenantRoleTok);
        if ExpandedPermission.FindSet() then
            repeat
                Rows += '[' + Format(ExpandedPermission."Object Type") + ' ' + Format(ExpandedPermission."Object ID") + ' ' +
                    Format(ExpandedPermission."Read Permission") + ',' + Format(ExpandedPermission."Insert Permission") + ',' +
                    Format(ExpandedPermission."Modify Permission") + ',' + Format(ExpandedPermission."Delete Permission") + ',' +
                    Format(ExpandedPermission."Execute Permission") + ']';
            until ExpandedPermission.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Observe('count', Format(ExpandedPermission.Count()));
        Observer.Finish();
    end;

    local procedure SeedTenantSet()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        NullGuid: Guid;
    begin
        TenantPermission.SetRange("Role ID", TenantRoleTok);
        TenantPermission.DeleteAll();
        if TenantPermissionSet.Get(NullGuid, TenantRoleTok) then
            TenantPermissionSet.Delete();
        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := TenantRoleTok;
        TenantPermissionSet.Name := 'LT PC Tenant';
        TenantPermissionSet.Insert();
        // Every permission column's InitValue is Yes (TestMetadataExpandedPermission.al:165); the rows keep it.
        AddGrant(TenantPermission."Object Type"::Page, Page::"LT PC Page Plain");
        AddGrant(TenantPermission."Object Type"::Report, Report::"LT PC Report");
        AddGrant(TenantPermission."Object Type"::Codeunit, Codeunit::"LT PC Probes");
        AddGrant(TenantPermission."Object Type"::Query, Query::"LT PC Query");
        AddGrant(TenantPermission."Object Type"::XMLport, XmlPort::"LT PC XmlPort");
        AddGrant(TenantPermission."Object Type"::System, 1350);
        AddGrant(TenantPermission."Object Type"::"Table", Database::"LT PC T");
    end;

    local procedure AddGrant(ObjectType: Integer; ObjectId: Integer)
    var
        TenantPermission: Record "Tenant Permission";
        NullGuid: Guid;
    begin
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := TenantRoleTok;
        TenantPermission."Object Type" := ObjectType;
        TenantPermission."Object ID" := ObjectId;
        TenantPermission.Insert();
    end;

    local procedure RunCase(Name: Text; Which: Integer)
    begin
        Mock.ClearAssignments();
        Seed();
        Assign(Name, Which);
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure Assign(Name: Text; Which: Integer)
    begin
        case Which of
            1, 2:
                Mock.Set('LT PC Inc Narrow');
            3:
                Mock.Set('LT PC Inc Both');
            4, 6:
                begin
                    Mock.Set('LT PC X');
                    Mock.Assign('LT PC Y');
                end;
            5:
                begin
                    Mock.Set('LT PC Y');
                    Mock.Assign('LT PC X');
                end;
            11 .. 14, 21 .. 24, 31, 33:
                Mock.Set('LT PC Ext Imd B');
            15 .. 18, 25 .. 28, 32, 34:
                Mock.Set('LT PC Ext No B');
            41 .. 47:
                Mock.Set('LT PC Only B');
            48, 49:
                Mock.Set('LT PC Only T');
        end;
        if Which <= 6 then
            Observer.Observe(Name + '|rights', Helper.Rights(0, Database::"LT PC T"));
    end;

    local procedure Seed()
    var
        T: Record "LT PC T";
        B: Record "LT PC B";
        EPlain: Record "LT PC E Plain";
        EExtPerm: Record "LT PC E ExtPerm";
        ETabPerm: Record "LT PC E TabPerm";
        EBothPerm: Record "LT PC E BothPerm";
    begin
        T.DeleteAll();
        B.DeleteAll();
        EPlain.DeleteAll();
        EExtPerm.DeleteAll();
        ETabPerm.DeleteAll();
        EBothPerm.DeleteAll();
        T.Id := 1;
        T.Insert();
        T.Id := 2;
        T.Insert();
        // Rows for WriteB() (inserted without triggers, so B stays empty).
        EPlain.Id := 1;
        EPlain.Insert();
        EExtPerm.Id := 1;
        EExtPerm.Insert();
        ETabPerm.Id := 1;
        ETabPerm.Insert();
        EBothPerm.Id := 1;
        EBothPerm.Insert();
    end;

    local procedure Op(Which: Integer)
    var
        T: Record "LT PC T";
        EPlain: Record "LT PC E Plain";
        EExtPerm: Record "LT PC E ExtPerm";
        ETabPerm: Record "LT PC E TabPerm";
        EBothPerm: Record "LT PC E BothPerm";
        PagePlain: TestPage "LT PC Page Plain";
        PagePerm: TestPage "LT PC Page Perm";
    begin
        case Which of
            1, 3, 4, 5:
                begin
                    T.Id := 5;
                    T.Insert();
                end;
            2, 6:
                T.FindFirst();
            11, 15:
                begin
                    EPlain.Id := 2;
                    EPlain.Insert(true);
                end;
            12, 16:
                begin
                    EExtPerm.Id := 2;
                    EExtPerm.Insert(true);
                end;
            13, 17:
                begin
                    ETabPerm.Id := 2;
                    ETabPerm.Insert(true);
                end;
            14, 18:
                begin
                    EBothPerm.Id := 2;
                    EBothPerm.Insert(true);
                end;
            21, 25:
                begin
                    EPlain.Get(1);
                    EPlain.WriteB();
                end;
            22, 26:
                begin
                    EExtPerm.Get(1);
                    EExtPerm.WriteB();
                end;
            23, 27:
                begin
                    ETabPerm.Get(1);
                    ETabPerm.WriteB();
                end;
            24, 28:
                begin
                    EBothPerm.Get(1);
                    EBothPerm.WriteB();
                end;
            31, 32:
                begin
                    PagePlain.OpenView();
                    PagePlain.Close();
                end;
            33, 34:
                begin
                    PagePerm.OpenView();
                    PagePerm.Close();
                end;
            41 .. 46:
                begin
                    T.SetRange(Id, 100);
                    case Which of
                        41:
                            T.FindFirst();
                        42:
                            T.FindSet();
                        43:
                            T.FindLast();
                        44:
                            T.Find('-');
                        45:
                            Error('LT PC ok count %1', T.Count());
                        46:
                            Error('LT PC ok isempty %1', T.IsEmpty());
                    end;
                end;
            47:
                T.FindSet();
            48:
                begin
                    T.Get(1);
                    T.Delete(true);
                end;
            49:
                begin
                    T.Get(1);
                    T.Delete();
                end;
        end;
        Error('LT PC ok');
    end;
}
