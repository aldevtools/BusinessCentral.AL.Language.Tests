// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getcollectederrors-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects codeunit 72044, table 72045
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Builtins refused until a probe pins them: Record.FieldError(Field, ErrorInfo) and FieldRef.FieldError(ErrorInfo) - Probe wanted: GetCollectedErrors(true) followed by HasCollectedErrors
// Facts: HasCollectedErrors and the list size around GetCollectedErrors(true) and GetCollectedErrors(false) and ClearCollectedErrors in an ErrorBehavior::Collect scope, with Error(ErrorInfo) and Record.FieldError(ErrorInfo) as sources; what the scope does with errors still collected at its end
// BC versions: 29 (27 and 28 by CI)

table 72045 "LT PnD Collect Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72044 "LT PnD Collected Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Collectible(Msg: Text): ErrorInfo
    begin
        exit(ErrorInfo.Create(Msg, true));
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    [TryFunction]
    local procedure ScopeGetTrueThenHas(var Log: Text)
    var
        Errs: List of [ErrorInfo];
    begin
        Log += 'start has=' + Format(HasCollectedErrors()) + ';';
        Error(Collectible('first'));
        Error(Collectible('second'));
        Log += 'after2 has=' + Format(HasCollectedErrors()) + ';';
        Errs := GetCollectedErrors(true);
        Log += 'got count=' + Format(Errs.Count()) + ';';
        Log += 'afterGetTrue has=' + Format(HasCollectedErrors()) + ';';
        Errs := GetCollectedErrors(false);
        Log += 'again count=' + Format(Errs.Count()) + ';';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    [TryFunction]
    local procedure ScopeGetFalseThenHas(var Log: Text)
    var
        Errs: List of [ErrorInfo];
    begin
        Error(Collectible('first'));
        Errs := GetCollectedErrors(false);
        Log += 'getFalse count=' + Format(Errs.Count()) + ';';
        Log += 'afterGetFalse has=' + Format(HasCollectedErrors()) + ';';
        Errs := GetCollectedErrors(true);
        Log += 'getTrue count=' + Format(Errs.Count()) + ';';
        Log += 'afterGetTrue has=' + Format(HasCollectedErrors()) + ';';
        Errs := GetCollectedErrors(true);
        Log += 'getTrueAgain count=' + Format(Errs.Count()) + ';';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    [TryFunction]
    local procedure ScopeClear(var Log: Text)
    begin
        Error(Collectible('first'));
        Log += 'before has=' + Format(HasCollectedErrors()) + ';';
        ClearCollectedErrors();
        Log += 'afterClear has=' + Format(HasCollectedErrors()) + ';';
        Error(Collectible('second'));
        Log += 'afterNew has=' + Format(HasCollectedErrors()) + ';';
        ClearCollectedErrors();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    [TryFunction]
    local procedure ScopeLeftUncleared(var Log: Text)
    begin
        Error(Collectible('left over'));
        Log += 'raised;';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    [TryFunction]
    local procedure ScopeNonCollectible(var Log: Text)
    begin
        Log += 'start;';
        Error('plain error');
        Log += 'not reached;';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    [TryFunction]
    local procedure ScopeFieldError(var Log: Text)
    var
        Row: Record "LT PnD Collect Row";
        Errs: List of [ErrorInfo];
        Info: ErrorInfo;
    begin
        Row.Id := 1;
        Row.Name := 'abc';
        Info := Collectible('field problem');
        Row.FieldError(Name, Info);
        Log += 'afterFieldError has=' + Format(HasCollectedErrors()) + ';';
        Errs := GetCollectedErrors(true);
        Log += 'count=' + Format(Errs.Count()) + ';';
        Log += 'afterGetTrue has=' + Format(HasCollectedErrors()) + ';';
    end;

    local procedure Result(Ok: Boolean; Log: Text): Text
    begin
        if Ok then
            exit('ok ' + Log);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' ' + Log);
    end;

    [Test]
    procedure GetCollectedErrors_True_ThenHas()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Observer.Observe('scope', Result(ScopeGetTrueThenHas(Log), Log));
        Observer.Observe('outsideHas', Format(HasCollectedErrors()));
        Observer.Expect('scope', 'ok start has=No;after2 has=Yes;got count=2;afterGetTrue has=No;again count=0;');
        Observer.Expect('outsideHas', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetCollectedErrors_False_ThenTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Observer.Observe('scope', Result(ScopeGetFalseThenHas(Log), Log));
        Observer.Observe('outsideHas', Format(HasCollectedErrors()));
        Observer.Expect('scope', 'ok getFalse count=1;afterGetFalse has=Yes;getTrue count=1;afterGetTrue has=No;getTrueAgain count=0;');
        Observer.Expect('outsideHas', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ClearCollectedErrors_ThenHas()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Observer.Observe('scope', Result(ScopeClear(Log), Log));
        Observer.Observe('outsideHas', Format(HasCollectedErrors()));
        Observer.Expect('scope', 'ok before has=Yes;afterClear has=No;afterNew has=Yes;');
        Observer.Expect('outsideHas', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ScopeEnd_WithErrorsLeftCollected()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Observer.Observe('scope', Result(ScopeLeftUncleared(Log), Log));
        Observer.Observe('outsideHas', Format(HasCollectedErrors()));
        Observer.Expect('scope', 'error:left over|Dialog raised;');
        Observer.Expect('outsideHas', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NonCollectibleError_InCollectScope()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Observer.Observe('scope', Result(ScopeNonCollectible(Log), Log));
        Observer.Observe('outsideHas', Format(HasCollectedErrors()));
        Observer.Expect('scope', 'error:plain error|Dialog start;');
        Observer.Expect('outsideHas', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_WithErrorInfo_GetCollectedTrue_ThenHas()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Observer.Observe('scope', Result(ScopeFieldError(Log), Log));
        Observer.Observe('outsideHas', Format(HasCollectedErrors()));
        Observer.Expect('scope', 'ok afterFieldError has=Yes;count=1;afterGetTrue has=No;');
        Observer.Expect('outsideHas', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure OutsideAnyScope()
    var
        Observer: Codeunit "Probe Observer";
        Errs: List of [ErrorInfo];
    begin
        Observer.Observe('has', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('countTrue', Format(Errs.Count()));
        Errs := GetCollectedErrors(false);
        Observer.Observe('countFalse', Format(Errs.Count()));
        ClearCollectedErrors();
        Observer.Observe('hasAfterClear', Format(HasCollectedErrors()));
        Observer.Expect('has', 'Yes');
        Observer.Expect('countTrue', '0');
        Observer.Expect('countFalse', '0');
        Observer.Expect('hasAfterClear', 'Yes');
        Observer.Verify();
    end;
}
