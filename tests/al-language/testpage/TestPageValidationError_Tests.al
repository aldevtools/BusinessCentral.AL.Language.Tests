// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfieldvalidationerrorcount-method
// Scope: in-scope
// Fixtures used: TestPage ErrTeardown Row (60796), TestPage ErrTeardown Card (60797), Assert (60021)
// Adds no fixture and no object: the page-level arms reuse card 60797, whose NameCtl OnValidate
// already raises when the row says so.
//
// What a REFUSED TestPage control write leaves behind on the control.
//
// `asserterror TestPage.<field>.SetValue(x)` is how a BC test asserts that a page refuses a
// value. The refusal is not only an exception: the control keeps a ledger of it, and
// `ValidationErrorCount()` / `GetValidationError(Index)` read that ledger AFTER the
// asserterror has already swallowed the exception. Microsoft's own tests rely on both halves
// — Tests-SINGLESERVER `Codeunit134614.TestRemoveSUPERPermissionsByUserAll` asserts
// `ValidationErrorCount() = 1` and compares `GetValidationError(1)` against the bare error
// text, and `UserRoleTest` asserts the trapped error text contains 'Validation error for
// Field' — but nothing in this corpus pinned either, so this codeunit does.
//
// The claims, one per [Test]:
//   1. a refused write records exactly one validation error on that control;
//   2. `GetValidationError(1)` answers the error text BC stores, which is the AL message plus
//      the client's " (Select Refresh to discard errors)" — but NOT the wrapper;
//   3. the exception the asserterror traps carries the wrapper around that same stored text;
//   4. an ACCEPTED write records nothing and stores the value;
//   5. the index `ValidationErrorCount()` reports is readable — i.e. the ledger is 1-based.
//
// Claims 6-9 ask the same four questions of the PAGE-level pair — `TestPage.ValidationErrorCount()`
// and `TestPage.GetValidationError(Index)`, read on the page variable itself rather than on a
// control. That is a different ledger reached through different BC methods; see the block above
// those tests for why it is not an alias of the control pair, and why its out-of-range arm is
// observable from AL where the control one is not.
//
// TWO OF THESE WERE WRONG IN THE FIRST DRAFT, AND THIS RUN IS WHY THEY ARE RIGHT NOW.
// Run 34002487601 answered both, identically on every leg that reported:
//
//   * Claim 2 asserted the BARE AL text. Real BC stores
//     `Deliberate OnValidate failure for VAL-1 (Select Refresh to discard errors)` — the
//     client appends its offer to discard the staged row edit before storing. Corrected to the
//     measured string, still an exact-equality assertion.
//
//   * Claim 5 asserted that reading PAST the end raises a trappable AL error, reasoning that
//     `NavTestField.ALGetValidationError(Index)` carries a `catch (IndexOutOfRangeException)`
//     and would not carry a catch for something unreachable. The catch IS unreachable: BC's
//     client does `System.Linq.Enumerable.ElementAt`, which raises
//     `ArgumentOutOfRangeException`, the catch does not match, and it escapes as
//     `Unexpected CLR exception thrown.` — which AL `asserterror` does NOT trap. So there is
//     no way to assert that behaviour from a PASSING AL test at all. The arm therefore stops
//     at the boundary instead of crossing it, and asserts the part that IS observable: the
//     index the count names is readable, which is a 1-based ledger. The measured
//     out-of-range behaviour is recorded here rather than lost.
//
// Both corrections were measurements replacing readings of decompiled `Ncl.dll`, which is the
// whole reason the claim goes upstream before the runner ships it.
//
// Reuses the ErrTeardown fixtures rather than adding new ones: page 60797's NameCtl control
// already declares an OnValidate that raises when the row says so, which is exactly the
// refusal these claims need.

codeunit 60836 "TestPage ValidationError Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // What the page's OnValidate raises.
        ValidateErrTok: Label 'Deliberate OnValidate failure for VAL-1', Locked = true;
        // What BC actually STORES for it on a Rec-bound control: the message above plus the
        // client's offer to discard the staged row edit. Measured, run 34002487601.
        RefreshSuffixTok: Label ' (Select Refresh to discard errors)', Locked = true;

    local procedure Initialize()
    var
        Row: Record "TestPage ErrTeardown Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed(No: Code[20]; FailOnValidate: Boolean)
    var
        Row: Record "TestPage ErrTeardown Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := 'Init';
        Row.FailOnGet := false;
        Row.FailOnValidate := FailOnValidate;
        Row.Insert();
    end;

    // Claim 1. A refused write records exactly one validation error on the control it was made
    // through — readable after the asserterror, which is the whole point of the ledger.
    // Asserting 1 rather than "> 0" is deliberate: one refused write is one error, and a count
    // that grew per retry would be a different behavior.
    [Test]
    procedure TestPage_SetValue_RefusedByOnValidate_RecordsOneValidationError()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        Assert.AreEqual(1, Card.NameCtl.ValidationErrorCount(),
            'A refused SetValue must leave exactly one validation error on the control');

        Card.Close();
    end;

    // Claim 2. GetValidationError(1) answers the text BC STORES: the AL message plus the
    // client's " (Select Refresh to discard errors)", and NOT the "Validation error for
    // Field: ..." wrapper the exception carries. Comparing for equality, not containment, is
    // what pins that the stored text and the wrapped text are different strings — and it is
    // what caught the first draft's wrong expectation instead of quietly tolerating it.
    [Test]
    procedure TestPage_GetValidationError_RefusedByOnValidate_IsTheStoredErrorText()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        Assert.AreEqual(ValidateErrTok + RefreshSuffixTok, Card.NameCtl.GetValidationError(1),
            'GetValidationError(1) must answer the OnValidate text with the refresh suffix BC appends');

        Card.Close();
    end;

    // Claim 3. The exception the asserterror traps is BC's validation wrapper around that same
    // STORED text — all three parts asserted, so a change to any is visible. The suffix
    // assertion is what would catch an implementation that appended it twice, once when
    // recording and once when wrapping.
    [Test]
    procedure TestPage_SetValue_RefusedByOnValidate_RaisesTheValidationWrapper()
    var
        Card: TestPage "TestPage ErrTeardown Card";
        Trapped: Text;
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');
        Trapped := GetLastErrorText();

        Assert.IsSubstring(Trapped, 'Validation error for Field');
        Assert.IsSubstring(Trapped, ValidateErrTok);
        Assert.IsSubstring(Trapped, RefreshSuffixTok);

        Card.Close();
    end;

    // Claim 4, the negative direction: a write the page ACCEPTS records nothing, and the value
    // reaches the table. Without the second assertion this would pass against an implementation
    // that refused every write and simply never counted.
    [Test]
    procedure TestPage_SetValue_Accepted_RecordsNoValidationErrorAndStoresTheValue()
    var
        Row: Record "TestPage ErrTeardown Row";
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-OK', false);

        Card.OpenView();
        Card.GoToKey('VAL-OK');
        Card.NameCtl.SetValue('Accepted Name');

        Assert.AreEqual(0, Card.NameCtl.ValidationErrorCount(),
            'An accepted SetValue must leave no validation error on the control');

        Card.Close();

        Row.Get('VAL-OK');
        Assert.AreEqual('Accepted Name', Row.Name,
            'The accepted value must reach the backing table');
    end;

    // Claim 5. The ledger is 1-based: the index ValidationErrorCount() reports is itself
    // readable, so the last valid index EQUALS the count rather than count - 1. Reading through
    // the count rather than through a literal is the point — a 0-based ledger answers the
    // second element (or nothing) for GetValidationError(1) and fails here.
    //
    // This arm deliberately stops AT the boundary and does not cross it. Going one past is not
    // an AL-observable error: BC's client reaches System.Linq.Enumerable.ElementAt, which raises
    // ArgumentOutOfRangeException; NavTestField.ALGetValidationError's catch is for
    // IndexOutOfRangeException and does not match; the exception escapes as "Unexpected CLR
    // exception thrown." and `asserterror` does not trap it. Measured on run 34002487601 — see
    // the header. There is therefore no passing AL test that can state it, which is a fact
    // about the surface, not a gap in this suite.
    [Test]
    procedure TestPage_GetValidationError_AtTheReportedCount_IsReadable()
    var
        Card: TestPage "TestPage ErrTeardown Card";
        LastIndex: Integer;
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        LastIndex := Card.NameCtl.ValidationErrorCount();
        Assert.AreEqual(1, LastIndex, 'One refused write must report a count of one');
        Assert.AreEqual(ValidateErrTok + RefreshSuffixTok, Card.NameCtl.GetValidationError(LastIndex),
            'The index ValidationErrorCount() reports must itself be readable');

        Card.Close();
    end;
    // ── The PAGE-level pair, as opposed to the control-level pair above ────────────────
    //
    // Everything above reads `Card.NameCtl.ValidationErrorCount()` — the ledger of the CONTROL
    // the write went through. AL also exposes the same two names on the TestPage ITSELF:
    // `Card.ValidationErrorCount()` and `Card.GetValidationError(Index)`. They are a different
    // ledger reached through a different BC method, and nothing in this corpus pinned them on a
    // full page.
    //
    // Ncl.dll shows they are genuinely distinct rather than an alias. The control pair goes
    // through `NavTestField.ALValidationErrorCount` / `ALGetValidationError`; the page pair goes
    // through `NavTestPageBase.ALValidationErrorCount()`, which is
    // `CheckPageOpened(); return TestPage.ValidationErrorCount;`, and
    // `NavTestPageBase.ALGetValidationError(index)`, which is
    // `TestPage.GetValidationError(checked(index - 1))` wrapped in a translation of
    // ArgumentOutOfRangeException into NavNCLIndexOutOfBoundsException. `NavTestField.CheckError`
    // — the method wrapping every control write — reads BOTH, and raises a PAGE-named validation
    // exception when the page count grew by more than the control's own did.
    //
    // Codeunit 60346 "Test TestPart" pins these four claims on a TestPart (`Host.Lines`). A part
    // is not a page: it is reached through ITestPart and its host owns the form. These arms ask
    // the same four questions of a full TestPage, which is the shape Microsoft's own tests hold
    // a TestPage in and the one nothing had measured.
    //
    // The claims, one per [Test]:
    //   6. a clean page reports zero — the arm that rules out "always report one";
    //   7. a refused control write is counted on the PAGE as well as on the control;
    //   8. the page's GetValidationError(1) is 1-based and carries the stored text;
    //   9. index 0 is below the range and raises a catchable error.
    //
    // Claim 9 is worth stating separately from its control-level sibling, which CANNOT be
    // written as a passing AL test at all (see the header: the control boundary catches
    // IndexOutOfRangeException, which Enumerable.ElementAt never raises, so an out-of-range
    // control read escapes untrappable). The PAGE boundary catches ArgumentOutOfRangeException,
    // which it does raise — so on the page the same shape IS observable from AL. That asymmetry
    // is exactly the kind of thing a service tier should settle rather than a reader of Ncl.

    // Claim 6. A page nothing has refused reports zero. Without this arm, claims 7-9 would all
    // pass against an implementation that reported a constant 1.
    [Test]
    procedure TestPage_PageLevel_ValidationErrorCount_IsZeroOnACleanPage()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', false);

        Card.OpenView();
        Card.GoToKey('VAL-1');

        Assert.AreEqual(0, Card.ValidationErrorCount(),
            'A page with no refused write must report zero validation errors');

        Card.Close();
    end;

    // Claim 7. The refusal is counted on the PAGE too, not only on the control it was made
    // through. Asserted as exact equality with 1 rather than "> 0": one refused write is one
    // error, and a page ledger that also counted the control's copy would read 2 here.
    [Test]
    procedure TestPage_PageLevel_ValidationErrorCount_CountsARefusedControlWrite()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        Assert.AreEqual(1, Card.ValidationErrorCount(),
            'A refused control write must be counted on the page as well as on the control');

        Card.Close();
    end;

    // Claim 8. The page ledger is 1-based and stores the same text the control's does —
    // asserted by exact equality against the measured stored string, so it cannot pass on an
    // arbitrary non-empty value or on BC's "Validation error for Field:" wrapper.
    [Test]
    procedure TestPage_PageLevel_GetValidationError_IsOneBasedAndCarriesTheStoredText()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        Assert.AreEqual(ValidateErrTok + RefreshSuffixTok, Card.GetValidationError(1),
            'The page GetValidationError(1) must carry the same stored text the control does');

        Card.Close();
    end;

    // Claim 9. Index 0 is below the 1-based range and raises a CATCHABLE error rather than
    // answering the first error or the empty string. Unlike the control-level sibling this is
    // observable from AL, because the page boundary catches the exception LINQ actually raises.
    [Test]
    procedure TestPage_PageLevel_GetValidationError_ErrorsOnIndexZero()
    var
        Card: TestPage "TestPage ErrTeardown Card";
        ErrText: Text;
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        asserterror ErrText := Card.GetValidationError(0);

        Assert.IsTrue(GetLastErrorText() <> '',
            'The page GetValidationError(0) must raise a catchable error, because the index is 1-based');

        Card.Close();
    end;
}
