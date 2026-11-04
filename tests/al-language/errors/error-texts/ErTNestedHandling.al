// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), none
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: nested try and asserterror, ErrorBehavior Collect
// BC versions: 29 (27 and 28 by CI)

codeunit 70075 "LT ErT Nested Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRaise(Txt: Text)
    begin
        Error(Txt);
    end;

    local procedure RaiseAfterTry()
    begin
        if not TryRaise('inner') then
            Error('wrapped: %1', GetLastErrorText());
    end;

    local procedure SwallowThenSucceed(): Text
    begin
        if not TryRaise('swallowed') then
            exit(GetLastErrorText());
        exit('no error');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTwo()
    var
        E1: ErrorInfo;
        E2: ErrorInfo;
    begin
        E1.Message := 'first collected';
        E1.Collectible := true;
        Error(E1);
        E2.Message := 'second collected';
        E2.Collectible := true;
        Error(E2);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectNone()
    begin
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectNonCollectible()
    begin
        Error('not collectible');
    end;

    [Test]
    procedure AsserterrorAroundTry()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror RaiseAfterTry();
        Observer.ObserveError('wrapped');
        Observer.Observe('swallow', SwallowThenSucceed());
        Observer.Expect('wrapped|text', 'wrapped: inner');
        Observer.Expect('wrapped|code', 'Dialog');
        Observer.Expect('swallow', 'swallowed');
        Observer.Verify();
    end;

    [Test]
    procedure TryAroundAsserterrorState()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('outer');
        Observer.Observe('beforeTry', GetLastErrorText());
        Observer.Observe('try', Format(TryRaise('inner')));
        Observer.Observe('afterTry', GetLastErrorText());
        Observer.Expect('beforeTry', 'outer');
        Observer.Expect('try', 'No');
        Observer.Expect('afterTry', 'inner');
        Observer.Verify();
    end;

    [Test]
    procedure CollectErrorsBasics()
    var
        Observer: Codeunit "Probe Observer";
        Errs: List of [ErrorInfo];
        E: ErrorInfo;
        i: Integer;
    begin
        ClearCollectedErrors();
        Observer.Observe('hasBefore', Format(HasCollectedErrors()));
        asserterror CollectTwo();
        Observer.ObserveError('af90');
        Observer.Observe('hasAfter', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(false);
        Observer.Observe('count', Format(Errs.Count()));
        for i := 1 to Errs.Count() do begin
            E := Errs.Get(i);
            Observer.Observe('msg' + Format(i), E.Message);
        end;
        ClearCollectedErrors();
        Observer.Observe('hasCleared', Format(HasCollectedErrors()));
        CollectNone();
        Observer.Observe('hasAfterNone', Format(HasCollectedErrors()));
        Observer.Expect('hasBefore', 'Yes');
        Observer.Expect('af90|text', 'Multiple errors occurred during the operation the first of which is: first collected. All errors can be found under ''Detailed Information''.');
        Observer.Expect('af90|code', 'Dialog');
        Observer.Expect('hasAfter', 'Yes');
        Observer.Expect('count', '0');
        Observer.Expect('hasCleared', 'Yes');
        Observer.Expect('hasAfterNone', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CollectNonCollectibleStillRaises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        asserterror CollectNonCollectible();
        Observer.ObserveError('nonCollectible');
        Observer.Observe('hasCollected', Format(HasCollectedErrors()));
        ClearCollectedErrors();
        Observer.Expect('nonCollectible|text', 'not collectible');
        Observer.Expect('nonCollectible|code', 'Dialog');
        Observer.Expect('hasCollected', 'Yes');
        Observer.Verify();
    end;
}
