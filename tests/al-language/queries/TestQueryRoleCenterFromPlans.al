// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: none — exercises real System Application objects: Query 777 "Role Center from
//   Plans", Table 9004 Plan, Table 9005 "User Plan" (all Access = Internal, so a caller may
//   never declare a local variable of those table types — see below). Seeded through
//   Microsoft's own Codeunit 132916 "Azure AD Plan Test Library" (ships in the System
//   Application Test Library app since BC 27.0): its CreatePlan(Guid, Text, Integer, Guid) and
//   AssignUserToPlan(Guid, Guid) take only Guid/Text/Integer parameters, so calling them never
//   requires a local `Record Plan` / `Record "User Plan"` declaration.
//
// Query 777 filters "User Plan" by "User Security ID" (a filter(...) column, never itself
// projected) and inner-joins "Plan" on "Plan ID" to project "Role Center ID". This proves BC's
// own precompiled query executes that join end to end against real rows: a seeded plan
// assignment comes back with the expected projected value, and an unassigned user reads back
// zero rows.
codeunit 60896 "Test Query RoleCenter Plans"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";

    [Test]
    procedure MatchingPlan_InnerJoinsPlan_ReturnsProjectedRoleCenterId()
    var
        RoleCenterFromPlans: Query "Role Center from Plans";
        PlanId: Guid;
        RowCount: Integer;
    begin
        // [GIVEN] The current user starts with no plan assignments, then is assigned a freshly
        // created plan with a known Role Center ID.
        AzureADPlanTestLibrary.DeleteAllUserPlan();
        PlanId := CreateGuid();
        AzureADPlanTestLibrary.CreatePlan(PlanId, 'ALT Role Center Plan', 50100, CreateGuid());
        AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanId);

        // [WHEN] Query 777 is opened filtered to the current user.
        RoleCenterFromPlans.SetRange(User_Security_ID, UserSecurityId());
        RoleCenterFromPlans.Open();

        // [THEN] The InnerJoin to Plan returns exactly the seeded Role Center ID, proving the
        // projected column actually comes from the joined Plan row, not an unrelated column or
        // a default value.
        RowCount := 0;
        Assert.IsTrue(RoleCenterFromPlans.Read(), 'Query 777 must return the joined row for a user with an assigned plan.');
        RowCount += 1;
        Assert.AreEqual(50100, RoleCenterFromPlans.Role_Center_ID,
            'Query 777 must project the joined Plan''s Role Center ID.');

        while RoleCenterFromPlans.Read() do
            RowCount += 1;
        Assert.AreEqual(1, RowCount, 'Query 777 must return exactly one row for one assigned plan.');
        RoleCenterFromPlans.Close();
    end;

    [Test]
    procedure NoMatchingPlan_ReturnsNoRows()
    var
        RoleCenterFromPlans: Query "Role Center from Plans";
    begin
        // [GIVEN] No plan assignment exists for this freshly generated, guaranteed-unused user
        // security ID.
        // [WHEN] Query 777 is opened filtered to that user.
        RoleCenterFromPlans.SetRange(User_Security_ID, CreateGuid());
        RoleCenterFromPlans.Open();

        // [THEN] The InnerJoin yields zero rows.
        Assert.IsFalse(RoleCenterFromPlans.Read(), 'Query 777 must return zero rows when no plan is assigned to the filtered user.');
        RoleCenterFromPlans.Close();
    end;
}
