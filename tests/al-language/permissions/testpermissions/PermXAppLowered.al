// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y19 Perm Helper (91935, record/Y19PermObjects.al); LT IA With Perms (97323,
//   permissions/testpermissions/Y19InherentAttrIndirect.al); xapp-a PermXAppLoweredObjects.al (95834-95839, 94686-94696);
//   Permissions Mock (131006) and D365 BASIC from the dependencies.
// Probe (al-runner issues 8066, 8092, 8093): the reporters' shapes, which Y19InherentAttrIndirect.al and Y19PermExtAndCompose.al
//   do not cover: the set D365 BASIC (alone or with a second set), the writer, the extended table and the permission sets in
//   another app (xapp-a), and the test method calling the writer directly (one test frame, no asserterror).
// Shape: each test starts the mock if needed, clears the assignment, seeds, assigns, makes ONE call, clears the assignment and
//   then reads the rows the call wrote.
// BC versions: 27, 28, 29

codeunit 91001 "PERM XApp Lowered"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    // 8066 reporter shape: D365 BASIC, the test calls the public writer of another app, lower-case i on the local insert routine.
    [Test]
    procedure IA_D365Basic_XAppWriter_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        Logger.Log(1);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8066 reporter variant: a set of the other app that grants only another table.
    [Test]
    procedure IA_XAppSet_XAppWriter_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Other');
        Logger.Log(1);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8066 No. Series shape without R: D365 BASIC, read then Modify covered by lower-case m.
    [Test]
    procedure IA_D365Basic_XAppWriter_ModifyM()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        SeedLog();
        Mock.Set('D365 BASIC');
        Logger.Bump(1);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8066 No. Series shape: D365 BASIC plus a set that grants R on the table, Modify covered by lower-case m.
    [Test]
    procedure IA_D365BasicReadLog_XAppWriter_ModifyM()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        SeedLog();
        Mock.Set('D365 BASIC');
        Mock.Assign('PERM XA Read Log');
        Logger.Bump(1);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8066: only a set that grants R on the table, Modify covered by lower-case m.
    [Test]
    procedure IA_ReadLog_XAppWriter_ModifyM()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        SeedLog();
        Mock.Set('PERM XA Read Log');
        Logger.Bump(1);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8066: D365 BASIC with the writer of this app (Y19InherentAttrIndirect.al objects), called directly by the test.
    [Test]
    procedure IA_D365Basic_SameAppWriter_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        WithPerms.InsertOnWriter();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8066: D365 BASIC with the writer of this app, Modify covered by lower-case m.
    [Test]
    procedure IA_D365Basic_SameAppWriter_ModifyM()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        WithPerms.ModifyOnWriter();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8093 reporter shape: D365 BASIC plus a set that grants the extended table; the table extension OnInsert of another app inserts into a third table; the base table declares no property.
    [Test]
    procedure Ext_D365BasicDocInsert_NoPropertyBase()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        Mock.Assign('PERM XA Doc Insert');
        Doc.Code := 'D1';
        Doc.Insert(true);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8093: only the set that grants the extended table; the base table declares no property.
    [Test]
    procedure Ext_DocInsert_NoPropertyBase()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Doc Insert');
        Doc.Code := 'D2';
        Doc.Insert(true);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8093: D365 BASIC plus the set; the base table declares DataClassification only.
    [Test]
    procedure Ext_D365BasicDocInsert_DataClassificationBase()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        Mock.Assign('PERM XA Doc Insert');
        DocDC.Code := 'D3';
        DocDC.Insert(true);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8093: only the set; the base table declares DataClassification only.
    [Test]
    procedure Ext_DocInsert_DataClassificationBase()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Doc Insert');
        DocDC.Code := 'D4';
        DocDC.Insert(true);
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8092 reporter shape 1: the assigned set includes a set that includes a set and excludes the set that grants B.
    [Test]
    procedure Comp_IncNarrow_InsertB()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Inc Narrow');
        ItemB.Code := 'B1';
        ItemB.Insert();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8092 shape 1, the table the excluded set does not grant.
    [Test]
    procedure Comp_IncNarrow_InsertA()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Inc Narrow');
        ItemA.Code := 'A1';
        ItemA.Insert();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8092 reporter shape 2: Set the set that grants B, Assign the set that excludes it.
    [Test]
    procedure Comp_GrantsBExcludesB_InsertB()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Grants B');
        Mock.Assign('PERM XA Excludes B');
        ItemB.Code := 'B2';
        ItemB.Insert();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8092 shape 1 with D365 BASIC.
    [Test]
    procedure Comp_D365BasicIncNarrow_InsertB()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        Mock.Assign('PERM XA Inc Narrow');
        ItemB.Code := 'B3';
        ItemB.Insert();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8092 shape 2 with D365 BASIC.
    [Test]
    procedure Comp_D365BasicGrantsBExcludesB_InsertB()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('D365 BASIC');
        Mock.Assign('PERM XA Grants B');
        Mock.Assign('PERM XA Excludes B');
        ItemB.Code := 'B4';
        ItemB.Insert();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    // 8092 reduced variant: one set includes a set that excludes the B set and grants only A, and a sibling that grants B.
    [Test]
    procedure Comp_IncTwo_InsertB()
    var
        Observer: Codeunit "Probe Observer";
        Logger: Codeunit "PERM XA Logger";
        WithPerms: Codeunit "LT IA With Perms";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
        WasStarted: Boolean;
    begin
        WasStarted := Initialize();
        Mock.Set('PERM XA Inc Two');
        ItemB.Code := 'B5';
        ItemB.Insert();
        Mock.ClearAssignments();
        Helper.RestoreMock(Mock, WasStarted);
        Observer.Observe('log', LogRows());
        Observer.Observe('ia_row', IaRows());
        Observer.Observe('audit', AuditRows());
        Observer.Observe('item_b', ItemBRows());
        Observer.Finish();
    end;

    local procedure Initialize() WasStarted: Boolean
    var
        LogRow: Record "PERM XA Log";
        IaRow: Record "LT IA Row";
        Audit: Record "PERM XA Audit";
        Doc: Record "PERM XA Doc";
        DocDC: Record "PERM XA Doc DC";
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
    begin
        WasStarted := Helper.StartMock(Mock);
        Mock.ClearAssignments();
        LogRow.DeleteAll();
        IaRow.DeleteAll();
        Audit.DeleteAll();
        Doc.DeleteAll();
        DocDC.DeleteAll();
        ItemA.DeleteAll();
        ItemB.DeleteAll();
        IaRow.Id := 1;
        IaRow.Value := 10;
        IaRow.Insert();
    end;

    local procedure SeedLog()
    var
        LogRow: Record "PERM XA Log";
    begin
        LogRow."Entry No." := 1;
        LogRow.Message := 'seed';
        LogRow.Insert();
    end;

    local procedure LogRows() Result: Text
    var
        LogRow: Record "PERM XA Log";
    begin
        if LogRow.FindSet() then
            repeat
                Result += Format(LogRow."Entry No.") + ':' + LogRow.Message + ';';
            until LogRow.Next() = 0;
    end;

    local procedure IaRows() Result: Text
    var
        IaRow: Record "LT IA Row";
    begin
        if IaRow.FindSet() then
            repeat
                Result += Format(IaRow.Id) + ':' + Format(IaRow.Value) + ';';
            until IaRow.Next() = 0;
    end;

    local procedure AuditRows() Result: Text
    var
        Audit: Record "PERM XA Audit";
    begin
        if Audit.FindSet() then
            repeat
                Result += Audit."Document Code" + ';';
            until Audit.Next() = 0;
    end;

    local procedure ItemBRows() Result: Text
    var
        ItemA: Record "PERM XA Item A";
        ItemB: Record "PERM XA Item B";
    begin
        if ItemA.FindSet() then
            repeat
                Result += 'A ' + ItemA.Code + ';';
            until ItemA.Next() = 0;
        if ItemB.FindSet() then
            repeat
                Result += 'B ' + ItemB.Code + ';';
            until ItemB.Next() = 0;
    end;
}
