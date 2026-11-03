// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-usersecurityid-method
// Scope: in-scope
// Fixtures used: none -- both tables are platform tables (User 2000000120, User
//                Personalization 2000000073) and the only value asserted about is the
//                session's own identity.
//
// CLAIM: the security id UserSecurityId() hands AL is a ROW in the User table, not just a
// value carried in session state. So a field whose TableRelation points at
// User."User Security ID" accepts UserSecurityId() -- and still refuses a security id that
// belongs to no user, which is what makes the first half a statement about the row existing
// rather than about validation being off.
//
// This is asserted here, against a real service tier, because nothing about it is specific to
// any one host: the platform creates the user account before AL runs, and every AL surface
// that stores "who did this" -- User Personalization."User SID", User Setup, Access Control,
// and about 150 further Base Application fields carrying a relation to User."User Security ID"
// -- depends on the session's own id resolving through it.
//
// "User Personalization" is the relating table on purpose: its "User SID" carries
// TableRelation = User."User Security ID" with validation left on (its TestTableRelation line
// is commented out in the shipped platform source), and it is a Cloud-scope table, so a
// Cloud-target app can name it. Validate() is used rather than Insert() so the test asserts
// the relation check and writes nothing to a tenant table.
codeunit 60991 "Test User Table Session User"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        UnknownUserSecurityIdTok: Label '{6D0A9C41-1B27-4C36-9F8E-0E2A5B7D3C11}', Locked = true;

    [Test]
    procedure UserTable_SessionUser_IsARowKeyedByItsOwnSecurityId()
    // CLAIM: Get(UserSecurityId()) finds a row, and that row's primary key is the very id
    // UserSecurityId() returned. Get(), not FindFirst(), so the row is reached by key and a
    // table that merely happens to hold some other user cannot satisfy this.
    var
        UserRec: Record User;
    begin
        Assert.IsTrue(
            UserRec.Get(UserSecurityId()),
            'the session user must be a row in the User table, keyed by UserSecurityId()');

        Assert.AreEqual(
            UserSecurityId(), UserRec."User Security ID",
            'the row found must be keyed by the session security id itself');
        Assert.AreNotEqual(
            '', UserRec."User Name",
            'the session user row must carry a user name');
    end;

    [Test]
    procedure UserTable_SessionUserRow_CarriesTheNameUserIdReturns()
    // CLAIM: the two identity surfaces agree. UserId() is the session user's name and the
    // User row reached by UserSecurityId() carries that same name, so the id-keyed and
    // name-keyed views of "who am I" cannot point at different users.
    var
        UserRec: Record User;
    begin
        UserRec.Get(UserSecurityId());

        Assert.AreEqual(
            UserId(), UserRec."User Name",
            'User."User Name" of the session user row must be what UserId() returns');
    end;

    [Test]
    procedure UserTable_RelationToUserSecurityId_AcceptsTheSessionUser()
    // CLAIM: validating a field related to User."User Security ID" with UserSecurityId()
    // is accepted and keeps the value. This is the half that fails when the session's user
    // is not a row: the platform hands AL an id its own referential check cannot resolve.
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Init();
        UserPersonalization.Validate("User SID", UserSecurityId());

        Assert.AreEqual(
            UserSecurityId(), UserPersonalization."User SID",
            'Validate must accept the session security id and keep it');
    end;

    [Test]
    procedure UserTable_RelationToUserSecurityId_RefusesAnIdBelongingToNoUser()
    // CLAIM: the negative direction. A security id no User row carries is refused by the
    // relation check. Without this, the test above would pass equally on a platform that
    // simply did not check the relation, which says nothing about the row existing.
    var
        UserPersonalization: Record "User Personalization";
        UnknownUserSecurityId: Guid;
    begin
        UnknownUserSecurityId := UnknownUserSecurityIdTok;
        UserPersonalization.Init();

        asserterror UserPersonalization.Validate("User SID", UnknownUserSecurityId);
        Assert.ExpectedError('cannot be found in the related table');
    end;
}
