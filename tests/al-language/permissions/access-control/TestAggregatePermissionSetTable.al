// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/table-user-permission
// Scope: in-scope
// Fixtures used: ALT Agg Perm Set (permissionset, 60930), ALT PermissionSet
//                (permissionset, 60022, declares no Caption)
//
// CLAIM: the "Aggregate Permission Set" system table (2000000167) answers with one row per
// permission set every published app declares (Scope::System, keyed by the declaring app's
// id and the permission set's own name as its Role ID) UNIONED with one row per
// "Tenant Permission Set" (2000000165) row (Scope::Tenant) -- and Get() on an undeclared
// role id fails rather than silently succeeding.
//
// The System-scope rows are asserted against THIS app's own permission set fixtures, not
// against Base Application content, so the expected values are declared a few lines away
// and cannot drift with a demo dataset.
codeunit 60931 "Test Aggregate Permission Set"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AggregatePermissionSet_ThisAppsDeclaredPermissionSet_IsPresentWithItsDeclaredMetadata()
    // CLAIM: a permission set this app declares is a System-scope row of "Aggregate
    // Permission Set", keyed by this app's id and the permission set's own name -- and its
    // Name and App Name columns come back exactly as declared.
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        Assert.IsTrue(
            AggregatePermissionSet.Get(
                AggregatePermissionSet.Scope::System, ThisModule.Id(), 'ALT Agg Perm Set'),
            'Get() must find a permission set this app declares');

        Assert.AreEqual(
            'ALT Agg Perm Set Fixture', AggregatePermissionSet.Name,
            'Name must be the permission set''s declared Caption');
        Assert.AreEqual(
            ThisModule.Name(), AggregatePermissionSet."App Name",
            'App Name must be the declaring app''s name');
    end;

    [Test]
    procedure AggregatePermissionSet_PermissionSetDeclaringNoCaption_NameFallsBackToRoleId()
    // CLAIM: a permission set declaring no Caption ("ALT PermissionSet", used only for this
    // assertion) still gets a Name -- it falls back to the Role ID, not an empty string.
    // Measured against a live BC container (both matrix legs): a no-Caption permission
    // set's row Name equals its own Role ID, not ''.
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        Assert.IsTrue(
            AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, ThisModule.Id(), 'ALTPermissionSet'),
            'Get() must find the permission set');
        Assert.AreNotEqual(
            '', AggregatePermissionSet.Name,
            'A permission set declaring no Caption still has a non-empty row Name');
        Assert.AreEqual(
            AggregatePermissionSet."Role ID", AggregatePermissionSet.Name,
            'A permission set declaring no Caption falls back to its own Role ID for Name');
    end;

    [Test]
    procedure AggregatePermissionSet_GetOnUndeclaredRoleId_Fails()
    // CLAIM: Get() on a role id no published app declares does not silently succeed.
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Assert.IsFalse(
            AggregatePermissionSet.Get(
                AggregatePermissionSet.Scope::System, ThisModule.Id(), 'ALT NO SUCH PERM SET'),
            'Get() must return false for a role id no app declares');
    end;

    [Test]
    procedure AggregatePermissionSet_TenantScopeDeclaration_IsPresent()
    // CLAIM: a row inserted directly into "Tenant Permission Set" is a Tenant-scope row of
    // "Aggregate Permission Set" -- the union covers both scopes, not only System.
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        EmptyGuid: Guid;
        RoleIdTok: Label 'ALT TENANT PERM SET', Locked = true;
    begin
        if TenantPermissionSet.Get(EmptyGuid, RoleIdTok) then
            TenantPermissionSet.Delete();

        Clear(TenantPermissionSet);
        TenantPermissionSet."App ID" := EmptyGuid;
        TenantPermissionSet."Role ID" := RoleIdTok;
        TenantPermissionSet.Name := 'ALT tenant perm set fixture';
        TenantPermissionSet.Assignable := true;
        TenantPermissionSet.Insert();

        Assert.IsTrue(
            AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, EmptyGuid, RoleIdTok),
            'Get() must find a Tenant Permission Set row through the Tenant scope');
        Assert.AreEqual(
            'ALT tenant perm set fixture', AggregatePermissionSet.Name,
            'Name must be the Tenant Permission Set row''s declared Name');

        TenantPermissionSet.Delete();
    end;

    [Test]
    procedure AggregatePermissionSet_TenantRowInsertedAfterEarlierTouch_IsVisible()
    // CLAIM: "Aggregate Permission Set" answers a Get()/FindSet() against the CURRENT state
    // of "Tenant Permission Set", not a snapshot taken the first time anything touched the
    // table -- a row inserted into Tenant Permission Set AFTER an earlier, unrelated touch of
    // Aggregate Permission Set must still be visible, and a row later deleted must not remain
    // a ghost row.
    var
        AggregatePermissionSetFirstTouch: Record "Aggregate Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AggregatePermissionSetAfterDelete: Record "Aggregate Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ThisModule: ModuleInfo;
        EmptyGuid: Guid;
        RoleIdTok: Label 'ALT TENANT AFTER', Locked = true;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);

        // An EARLIER, unrelated touch of Aggregate Permission Set, through a separate record
        // variable -- this is the moment a "populate once at first touch" implementation
        // would freeze its answer.
        if AggregatePermissionSetFirstTouch.Get(
            AggregatePermissionSetFirstTouch.Scope::System, ThisModule.Id(), 'ALT Agg Perm Set')
        then;

        if TenantPermissionSet.Get(EmptyGuid, RoleIdTok) then
            TenantPermissionSet.Delete();

        Clear(TenantPermissionSet);
        TenantPermissionSet."App ID" := EmptyGuid;
        TenantPermissionSet."Role ID" := RoleIdTok;
        TenantPermissionSet.Name := 'ALT tenant role post touch';
        TenantPermissionSet.Assignable := true;
        TenantPermissionSet.Insert();

        Assert.IsTrue(
            AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, EmptyGuid, RoleIdTok),
            'a Tenant Permission Set row inserted AFTER an earlier touch of Aggregate Permission Set must be visible on a later touch');
        Assert.AreEqual(
            'ALT tenant role post touch', AggregatePermissionSet.Name,
            'Name must round-trip from the newly-inserted Tenant Permission Set row');

        TenantPermissionSet.Delete();
        Assert.IsFalse(
            AggregatePermissionSetAfterDelete.Get(AggregatePermissionSetAfterDelete.Scope::Tenant, EmptyGuid, RoleIdTok),
            'a Tenant Permission Set row deleted after being visible must not remain a ghost row in Aggregate Permission Set');
    end;
}
