// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/users-user-groups-permissions
// Scope: in-scope
// Fixtures used: none -- Access Control (2000000053) and User (2000000120) are platform
//                tables, and the only user asserted about is the session's own.
//
// CLAIM: a user's SUPER status is BACKED BY A ROW. "User Permissions".IsSuper(UserSecurityId())
// answering true and Access Control holding a SUPER row for that same security id are two
// views of one fact, not two independent facts -- so a host that reports the session user as
// SUPER must also be able to show you the assignment that makes it so.
//
// This is read-only on purpose. It writes nothing to Access Control and creates no user: the
// claim is about the relationship between the permission answer and the table, and both halves
// are observable without changing either.
//
// WHY IT IS WORTH ASSERTING AGAINST A REAL TIER
// AL code that manages users reads Access Control directly (the "User Permissions" page does
// exactly this) while AL code that GUARDS operations asks IsSuper -- Base Application codeunit
// 9002's User/OnBeforeModifyEvent subscriber reaches "User Permissions".CanManageUsersOnTenant,
// which is IsSuper, before it will let one user modify another's row. If those two could
// disagree, a session could be refused an operation the permission table says it may perform,
// or shown an empty permission list while holding SUPER. Nothing in the AL surface says they
// cannot disagree; only a service tier can settle it.
//
// The second test is what stops the first from being satisfiable by "the tier answers true to
// every IsSuper question": a security id belonging to no user at all must NOT be SUPER.
codeunit 60889 "Test Access Control IsSuper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SuperTok: Label 'SUPER', Locked = true;
        UnknownUserSecurityIdTok: Label '{4E1D7A83-52C6-4B90-A7F1-9C3E60B8D274}', Locked = true;

    [Test]
    procedure SessionUserIsSuper_AndAccessControlHoldsTheRowThatSaysSo()
    // CLAIM: the permission answer and the permission table agree about the session user. The
    // Access Control lookup is filtered on the session's own security id and on SUPER, so a
    // table that merely holds somebody else's SUPER assignment cannot satisfy it.
    var
        UserPermissions: Codeunit "User Permissions";
        AccessControl: Record "Access Control";
        UserRec: Record User;
    begin
        // Precondition, asserted rather than assumed: codeunit 153's IsSuper opens with
        // `if User.IsEmpty() then exit(true)` -- the "no users provisioned yet" bootstrap. On an
        // empty User table the first assertion below would hold without the platform consulting
        // any permission set at all, and the test would prove nothing.
        Assert.IsFalse(
            UserRec.IsEmpty(),
            'the User table must not be empty, or IsSuper answers true from its bootstrap branch');

        Assert.IsTrue(
            UserPermissions.IsSuper(UserSecurityId()),
            'the session user must be SUPER');

        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", SuperTok);
        Assert.IsFalse(
            AccessControl.IsEmpty(),
            'a session user reported as SUPER must hold a SUPER row in Access Control');
    end;

    [Test]
    procedure ASecurityIdBelongingToNoUser_IsNotSuper()
    // The negative control. Without it, a tier answering true to every IsSuper question would
    // pass the test above, and the claim would be about nothing.
    var
        UserPermissions: Codeunit "User Permissions";
        UserRec: Record User;
        UnknownSid: Guid;
    begin
        UnknownSid := UnknownUserSecurityIdTok;
        Assert.IsFalse(
            UserRec.Get(UnknownSid),
            'precondition: this security id must belong to no user');

        Assert.IsFalse(
            UserPermissions.IsSuper(UnknownSid),
            'a security id belonging to no user must not be SUPER');
    end;
}
