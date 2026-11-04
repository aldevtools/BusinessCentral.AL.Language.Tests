// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfieldvalidationerrorcount-method
// Scope: in-scope
// Fixtures used: TestPage SubErr Row (60823), TP SubErr Guard (60824),
//                TestPage SubErr Page (60825), Assert (60021)
//
// WHERE the refusal a TestPage control write hits is allowed to come from.
//
// Three codeunits already pin that `asserterror TestPage.<field>.SetValue(x)` traps a refusal
// and that the control keeps a ledger of it: 60836 (Rec-bound control, source-compiled page),
// 60820 (Rec-bound control, PRECOMPILED page), 60808 (page-global control, source-compiled
// page). Every one of them raises the error in the control's OWN `trigger OnValidate()` body.
//
// This one does not. The control's OnValidate calls `Delete(true)` and nothing else; the Error
// comes from a subscriber to the table's `OnBeforeDeleteEvent`, which the platform's event
// dispatch invokes underneath the delete. The page has no idea the subscriber exists.
//
// That distance is the whole claim, and it is not academic. It is how Microsoft's own
// Tests-SINGLESERVER `Codeunit134614.TestRemoveSUPERPermissionsByUserAll` asserts a refusal:
// page 9816 "Permission Set by User"'s AllUsersHavePermission control (a page GLOBAL, not a
// Rec-bound field) deletes an "Access Control" row, and the System Application's
// `"User Permissions Impl."(153).CheckSuperPermissionsBeforeDeleteAccessControl` subscriber
// raises `There should be at least one enabled 'SUPER' user.` four frames below the control
// write. A platform — or a runner — that dropped an error crossing that boundary would leave all
// three codeunits above green and break Microsoft's shape silently. AL Runner issue #3105
// reported exactly that symptom, and this file is what makes a return of it visible here.
//
// The claims, one per [Test]:
//   1. the subscriber's Error reaches the caller of SetValue, so `asserterror` traps it, and it
//      carries the subscriber's own message;
//   2. the delete it refused did not happen;
//   3. the control records exactly one validation error for it, readable AFTER the asserterror,
//      as the bare message — page-global, so no " (Select Refresh to discard errors)" suffix,
//      which run 34016443056 measured for this binding shape (codeunit 60808);
//   4. a row the subscriber does NOT refuse is deleted and records nothing.
//
// Claim 4 is what stops an implementation that refuses every write from satisfying 1-3, and
// claims 1-3 stop one that swallows the subscriber's error from satisfying 4. Both directions
// are needed: dropping either arm leaves the file passing against a wrong implementation.
//
// The seed commits on purpose. `asserterror` unwinds to the last commit, so without the Commit()
// the row claim 2 is about would be gone for a reason that has nothing to do with the refusal,
// and claim 2 would pass against an implementation that deleted the row and then rolled back.
codeunit 60826 "TP SubErr Refusal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Guard: Codeunit "TP SubErr Guard";
        GuardedNoTok: Label 'GUARDED', Locked = true;
        OpenNoTok: Label 'OPEN', Locked = true;

    local procedure Seed(No: Code[20]; Guarded: Boolean)
    var
        Row: Record "TestPage SubErr Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := No;
        Row.Guarded := Guarded;
        Row.Insert();
        Commit();
    end;

    // CLAIMS 1 AND 2. The subscriber's Error travels back up through Delete(true), through the
    // control's OnValidate, out of the page-global control write, and into the caller's
    // asserterror — and the row it refused to delete is still there.
    [Test]
    procedure SubscriberRefusal_ReachesTheAssertErrorAroundSetValue()
    var
        Pg: TestPage "TestPage SubErr Page";
        Row: Record "TestPage SubErr Row";
    begin
        Seed(GuardedNoTok, true);

        Pg.OpenEdit();
        asserterror Pg.PurgeAll.SetValue(true);

        // BC wraps the recorded text in "Validation error for Field: …"; the subscriber's own
        // message is inside that wrapper, which is what ExpectedError checks for.
        Assert.ExpectedError(Guard.ExpectedMessage(GuardedNoTok));

        Assert.AreEqual(1, Row.Count(),
            'the row whose delete the subscriber refused must still be there');

        Pg.Close();
    end;

    // CLAIM 3. The ledger, read AFTER the asserterror swallowed the exception.
    [Test]
    procedure SubscriberRefusal_RecordsExactlyOneValidationError()
    var
        Pg: TestPage "TestPage SubErr Page";
    begin
        Seed(GuardedNoTok, true);

        Pg.OpenEdit();
        asserterror Pg.PurgeAll.SetValue(true);

        Assert.AreEqual(1, Pg.PurgeAll.ValidationErrorCount(),
            'a refusal raised below the control write must be recorded once on the control');
        Assert.AreEqual(Guard.ExpectedMessage(GuardedNoTok), Pg.PurgeAll.GetValidationError(1),
            'a page-global control stages no row edit, so the stored text is the bare message');

        Pg.Close();
    end;

    // CLAIM 4, THE MIRROR. A row the subscriber does not refuse goes through: the delete
    // happens, nothing is recorded, and the value is readable back.
    [Test]
    procedure UnguardedRow_IsDeletedAndRecordsNoValidationError()
    var
        Pg: TestPage "TestPage SubErr Page";
        Row: Record "TestPage SubErr Row";
    begin
        Seed(OpenNoTok, false);

        Pg.OpenEdit();
        Pg.PurgeAll.SetValue(true);

        Assert.AreEqual(0, Pg.PurgeAll.ValidationErrorCount(),
            'an accepted write must record no validation error');
        Assert.AreEqual('Yes', Pg.PurgeAll.Value(),
            'the accepted value must be readable back from the page-global control');
        Assert.AreEqual(0, Row.Count(),
            'the accepted write must have performed the delete the control asked for');

        Pg.Close();
    end;
}
