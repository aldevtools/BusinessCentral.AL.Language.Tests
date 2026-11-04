// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfieldgetvalidationerror-method
// Scope: in-scope
// Fixtures used: Test Page Variable Control Row (60714), Test Page Variable Control (60715),
//                Assert (60021)
//
// Does the validation error a PAGE-GLOBAL control records carry the client's
// " (Select Refresh to discard errors)" suffix, the way a REC-BOUND control's does?
//
// This asks one question, and it is asked because two pieces of evidence point opposite ways.
//
//   * Run 34002487601 (PR #182, codeunit 60836) measured a REC-BOUND control on all reporting
//     legs. Its OnValidate raised `Error('Deliberate OnValidate failure for VAL-1')` and
//     GetValidationError(1) answered
//     `Deliberate OnValidate failure for VAL-1 (Select Refresh to discard errors)`.
//
//   * Microsoft's Tests-SINGLESERVER `Codeunit134614.TestRemoveSUPERPermissionsByUserAll`
//     asserts the opposite for its own control, with EXACT equality and no suffix:
//     `Assert.AreEqual('There should be at least one enabled ''SUPER'' user.',
//         PermissionSetByUser.AllUsersHavePermission.GetValidationError(1), ...)`.
//
// Those are not the same shape. `AllUsersHavePermission` on page 9816 "Permission Set by User"
// (an earlier version of this comment said 9807, which is "User Card") binds to a page GLOBAL,
// not to a field of "Aggregate Permission Set" — checked mechanically against the page's own
// control-binding map, not inferred from the name. A page-global control stages no row edit, so
// there is nothing for "Refresh to discard" to discard, which is a plausible reason the suffix
// would be absent.
//
// Plausible is not measured, and that is the whole point of this file. AL Runner currently
// implements the split — suffix on a Rec-bound control, none on a page-global one — on exactly
// this evidence, so if the tier says the suffix is there for both, the runner is wrong and
// Microsoft's own assertion cannot be passing either. Both outcomes are worth knowing; neither
// is knowable by reading `Ncl.dll`, which is how the two claims PR #182 had to correct got
// wrong in the first place.
//
// The expected value below is Microsoft's shape, asserted with exact equality so the answer is
// unambiguous in either direction.

codeunit 60808 "TP PageVar Validation Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RefuseTok: Label 'REFUSE', Locked = true;
        GuardRefusedTok: Label 'Guard control refused the value', Locked = true;
        RefreshSuffixTok: Label ' (Select Refresh to discard errors)', Locked = true;

    local procedure Initialize()
    var
        Row: Record "Test Page Variable Control Row";
    begin
        Row.DeleteAll();
        Commit();
    end;

    // THE QUESTION. A page-global control refuses the value; what does it store?
    [Test]
    procedure PageVariableControl_GetValidationError_HasNoRefreshSuffix()
    var
        VarPage: TestPage "Test Page Variable Control";
    begin
        Initialize();

        VarPage.OpenEdit();
        asserterror VarPage.GuardField.SetValue(RefuseTok);

        Assert.AreEqual(1, VarPage.GuardField.ValidationErrorCount(),
            'A refused write on a page-global control must record exactly one validation error');
        Assert.AreEqual(GuardRefusedTok, VarPage.GuardField.GetValidationError(1),
            'A page-global control stages no row edit, so the stored text should be the bare '
            + 'AL message with no refresh suffix');

        VarPage.Close();
    end;

    // The same question read from the other side, so a failure says WHICH way it went rather
    // than only that the strings differed. If the suffix is present after all, this arm names
    // it explicitly instead of leaving it to be inferred from a diff of two long strings.
    [Test]
    procedure PageVariableControl_GetValidationError_SuffixPresenceIsStated()
    var
        VarPage: TestPage "Test Page Variable Control";
        Stored: Text;
    begin
        Initialize();

        VarPage.OpenEdit();
        asserterror VarPage.GuardField.SetValue(RefuseTok);
        Stored := VarPage.GuardField.GetValidationError(1);

        Assert.AreEqual(0, StrPos(Stored, RefreshSuffixTok),
            'The refresh suffix must not appear in a page-global control''s stored validation error');

        VarPage.Close();
    end;

    // The negative direction: a value the guard does NOT refuse records nothing, so neither arm
    // above can pass against an implementation that refuses every write.
    [Test]
    procedure PageVariableControl_AcceptedWrite_RecordsNoValidationError()
    var
        VarPage: TestPage "Test Page Variable Control";
    begin
        Initialize();

        VarPage.OpenEdit();
        VarPage.GuardField.SetValue('ALLOWED');

        Assert.AreEqual(0, VarPage.GuardField.ValidationErrorCount(),
            'An accepted write on a page-global control must record no validation error');
        Assert.AreEqual('ALLOWED', VarPage.GuardField.Value(),
            'The accepted value must be readable back from the control');

        VarPage.Close();
    end;
}
