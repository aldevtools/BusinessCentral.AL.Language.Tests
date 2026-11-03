// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-usersecurityid-method
// Scope: in-scope, but ONLY for a Target = OnPrem app - see the header note below
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP AND NOT THE CLOUD ONE
//   Microsoft declares "User Property" (2000000121) Scope = OnPrem in System.app, while
//   "User" (2000000120) is Scope = Cloud. A Target = Cloud app cannot name the record type:
//
//     error AL0296: The application object or method 'User Property' has scope 'OnPrem'
//                   and cannot be used for 'Cloud' development
//
//   The User half of this claim is already pinned from the Cloud app by
//   "Test User Table Session User" (60991); this file adds the companion table, which only
//   an OnPrem app can read.
//
// CLAIM: the session user is not only a row in User, it also has the "User Property" row the
// platform keeps alongside every user, keyed by the same security id. Both tests are read-only,
// so nothing is written to a tenant table.
//
// Every positive read is paired with a negative one: a Get that answered true for any key would
// satisfy a bare "row exists" assertion, so the second test asks the same table for a security id
// that belongs to no user and requires it to find nothing.
codeunit 61203 "Test User Property Session Usr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        UnknownUserSecurityIdTok: Label '{3B8E6F20-7C41-4D95-A2E8-91D0C4F5B736}', Locked = true;

    [Test]
    procedure UserProperty_SessionUser_HasACompanionRowKeyedByItsSecurityId()
    // CLAIM: Get(UserSecurityId()) on "User Property" finds a row, and that row's key is the
    // session security id itself. The User row is read first, in the same session, as the
    // control arm: it is what makes the companion row a statement about THIS user.
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
    begin
        Assert.IsTrue(
            UserRec.Get(UserSecurityId()),
            'control arm: the session user must be a row in the User table');

        Assert.IsTrue(
            UserProperty.Get(UserSecurityId()),
            'the session user must have a User Property row, keyed by UserSecurityId()');
        Assert.AreEqual(
            UserRec."User Security ID", UserProperty."User Security ID",
            'the User Property row must be keyed by the same security id as the User row');
    end;

    [Test]
    procedure UserProperty_Get_IdBelongingToNoUser_FindsNothing()
    // CLAIM: the negative direction. For a security id no User row carries, "User Property"
    // has no row either. Without this, the test above would pass equally against a table
    // that answered every key.
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
        UnknownUserSecurityId: Guid;
    begin
        UnknownUserSecurityId := UnknownUserSecurityIdTok;

        Assert.IsFalse(
            UserRec.Get(UnknownUserSecurityId),
            'control arm: the unknown security id must belong to no User row');
        Assert.IsFalse(
            UserProperty.Get(UnknownUserSecurityId),
            'User Property must have no row for a security id that belongs to no user');
    end;
}
