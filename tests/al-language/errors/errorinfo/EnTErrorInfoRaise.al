// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-error-errorinfo-method
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//
// Error(ErrorInfo), GetLastErrorText/Code/Object, AddAction / AddNavigationAction, collected errors.
// Fixtures used: Probe Observer (69160); self-contained codeunits 73027, 73028
// BC versions: 29 (27 and 28 by CI)

codeunit 73027 "LT EnT ErrorInfo Actions"
{
    procedure DoAction(ErrInfo: ErrorInfo)
    begin
    end;

    procedure Other(ErrInfo: ErrorInfo)
    begin
    end;
}

codeunit 73028 "LT EnT ErrorInfo Raise"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Error_ErrorInfo_Text()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := 'boom';
        asserterror Error(ErrInfo);
        Observer.ObserveError('plain');
        Observer.Observe('lasterrortext after clear', GetLastErrorText());
        ErrInfo := ErrorInfo.Create('created');
        asserterror Error(ErrInfo);
        Observer.ObserveError('created');
        ErrInfo.Message := 'with detail';
        ErrInfo.DetailedMessage := 'the detail';
        ErrInfo.Title := 'the title';
        asserterror Error(ErrInfo);
        Observer.ObserveError('detail');
        Observer.Expect('plain|text', 'boom');
        Observer.Expect('plain|code', 'Dialog');
        Observer.Expect('lasterrortext after clear', '');
        Observer.Expect('created|text', 'created');
        Observer.Expect('created|code', 'Dialog');
        Observer.Expect('detail|text', 'with detail');
        Observer.Expect('detail|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Error_ErrorInfo_Empty()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        asserterror Error(ErrInfo);
        Observer.ObserveError('default errorinfo');
        ErrInfo.Message := '';
        asserterror Error(ErrInfo);
        Observer.ObserveError('empty message');
        asserterror Error(ErrorInfo.Create());
        Observer.ObserveError('create no args');
        Observer.Expect('default errorinfo|text', '');
        Observer.Expect('default errorinfo|code', 'Dialog');
        Observer.Expect('empty message|text', '');
        Observer.Expect('empty message|code', 'Dialog');
        Observer.Expect('create no args|text', '');
        Observer.Expect('create no args|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Error_ErrorInfo_Collectible_NotCollecting()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create('collectible but not collecting', true);
        asserterror Error(ErrInfo);
        Observer.ObserveError('collectible');
        Observer.Observe('has collected', Format(HasCollectedErrors()));
        Observer.Expect('collectible|text', 'collectible but not collecting');
        Observer.Expect('collectible|code', 'Dialog');
        Observer.Expect('has collected', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LastError_Object_Related()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create('x');
        ErrInfo.CustomDimensions.Add('k', 'v');
        asserterror Error(ErrInfo);
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('has callstack', Format(GetLastErrorCallStack() <> ''));
        ClearLastError();
        Observer.Observe('after clear text', GetLastErrorText());
        Observer.Observe('after clear code', GetLastErrorCode());
        Observer.Expect('text', 'x');
        Observer.Expect('code', 'Dialog');
        Observer.Expect('has callstack', 'Yes');
        Observer.Expect('after clear text', '');
        Observer.Expect('after clear code', '');
        Observer.Verify();
    end;

    [Test]
    procedure AddAction_Variants()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create('with actions');
        ErrInfo.AddAction('Do it', Codeunit::"LT EnT ErrorInfo Actions", 'DoAction');
        Observer.Observe('one action', 'ok');
        ErrInfo.AddAction('Do other', Codeunit::"LT EnT ErrorInfo Actions", 'Other', 'A description');
        Observer.Observe('with description', 'ok');
        ErrInfo.AddAction('', Codeunit::"LT EnT ErrorInfo Actions", 'DoAction');
        Observer.Observe('empty caption', 'ok');
        ErrInfo.AddAction('Same', Codeunit::"LT EnT ErrorInfo Actions", 'DoAction');
        ErrInfo.AddAction('Same', Codeunit::"LT EnT ErrorInfo Actions", 'DoAction');
        Observer.Observe('duplicate', 'ok');
        asserterror Error(ErrInfo);
        Observer.ObserveError('raise');
        Observer.Expect('one action', 'ok');
        Observer.Expect('with description', 'ok');
        Observer.Expect('empty caption', 'ok');
        Observer.Expect('duplicate', 'ok');
        Observer.Expect('raise|text', 'with actions');
        Observer.Expect('raise|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure AddAction_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create('bad actions');
        ErrInfo.AddAction('x', 0, 'DoAction');
        Observer.Observe('codeunit zero', 'no error');
        ErrInfo.AddAction('x', 99999999, 'DoAction');
        Observer.Observe('codeunit missing', 'no error');
        ErrInfo.AddAction('x', Codeunit::"LT EnT ErrorInfo Actions", 'NoSuchMethod');
        Observer.Observe('method missing', 'no error');
        ErrInfo.AddAction('x', Codeunit::"LT EnT ErrorInfo Actions", '');
        Observer.Observe('method empty', 'no error');
        Observer.Expect('codeunit zero', 'no error');
        Observer.Expect('codeunit missing', 'no error');
        Observer.Expect('method missing', 'no error');
        Observer.Expect('method empty', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure AddNavigationAction_Variants()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Rec: Record "LT EnT Info Rec";
    begin
        ErrInfo := ErrorInfo.Create('nav');
        ErrInfo.AddNavigationAction('Open');
        Observer.Observe('no target', 'no error');
        ErrInfo.PageNo := 0;
        ErrInfo.TableId := Database::"LT EnT Info Rec";
        ErrInfo.AddNavigationAction('Open', 'Description');
        Observer.Observe('table only with description', 'no error');
        Observer.Expect('no target', 'no error');
        Observer.Expect('table only with description', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Collect_Basic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        CollectTwo(Observer);
        Observer.Observe('after has', Format(HasCollectedErrors()));
        Observer.Expect('has before', 'No');
        Observer.Expect('continued after first', 'yes');
        Observer.Expect('has after', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('msg 1', 'first');
        Observer.Expect('det 1', '');
        Observer.Expect('title 1', '');
        Observer.Expect('collectible 1', 'Yes');
        Observer.Expect('msg 2', 'second');
        Observer.Expect('det 2', 'det2');
        Observer.Expect('title 2', 'tit2');
        Observer.Expect('collectible 2', 'Yes');
        Observer.Expect('lasterror text', '');
        Observer.Expect('has cleared', 'No');
        Observer.Expect('count cleared', '0');
        Observer.Expect('after has', 'Yes');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTwo(var Observer: Codeunit "Probe Observer")
    var
        ErrInfo: ErrorInfo;
        List: List of [ErrorInfo];
        E: ErrorInfo;
        i: Integer;
    begin
        Observer.Observe('has before', Format(HasCollectedErrors()));
        ErrInfo := ErrorInfo.Create('first', true);
        Error(ErrInfo);
        Observer.Observe('continued after first', 'yes');
        ErrInfo := ErrorInfo.Create('second', true);
        ErrInfo.DetailedMessage := 'det2';
        ErrInfo.Title := 'tit2';
        Error(ErrInfo);
        Observer.Observe('has after', Format(HasCollectedErrors()));
        List := GetCollectedErrors();
        Observer.Observe('count', Format(List.Count()));
        for i := 1 to List.Count() do begin
            E := List.Get(i);
            Observer.Observe('msg ' + Format(i), E.Message);
            Observer.Observe('det ' + Format(i), E.DetailedMessage);
            Observer.Observe('title ' + Format(i), E.Title);
            Observer.Observe('collectible ' + Format(i), Format(E.Collectible));
        end;
        Observer.Observe('lasterror text', GetLastErrorText());
        ClearCollectedErrors();
        Observer.Observe('has cleared', Format(HasCollectedErrors()));
        Observer.Observe('count cleared', Format(GetCollectedErrors().Count()));
    end;

    [Test]
    procedure Collect_NotCleared_RaisesAtEnd()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        asserterror CollectLeftover();
        Observer.ObserveError('leftover');
        Observer.Observe('has after', Format(HasCollectedErrors()));
        ClearCollectedErrors();
        Observer.Expect('leftover|text', 'left over');
        Observer.Expect('leftover|code', 'Dialog');
        Observer.Expect('has after', 'Yes');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectLeftover()
    begin
        Error(ErrorInfo.Create('left over', true));
    end;

    [Test]
    procedure Collect_NonCollectible_Raises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        asserterror CollectNonCollectible();
        Observer.ObserveError('noncollectible');
        Observer.Observe('has', Format(HasCollectedErrors()));
        ClearCollectedErrors();
        Observer.Expect('noncollectible|text', 'plain');
        Observer.Expect('noncollectible|code', 'Dialog');
        Observer.Expect('has', 'Yes');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectNonCollectible()
    begin
        Error(ErrorInfo.Create('plain'));
    end;

    [Test]
    procedure Collect_PlainTextError_Raises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        asserterror CollectTextError();
        Observer.ObserveError('text error');
        Observer.Observe('has', Format(HasCollectedErrors()));
        ClearCollectedErrors();
        Observer.Expect('text error|text', 'plain text');
        Observer.Expect('text error|code', 'Dialog');
        Observer.Expect('has', 'Yes');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTextError()
    begin
        Error('plain text');
    end;

    [Test]
    procedure Collect_Outside_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        Observer.Observe('has', Format(HasCollectedErrors()));
        Observer.Observe('count', Format(GetCollectedErrors().Count()));
        Observer.Expect('has', 'Yes');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Collect_Callee_Inherits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearCollectedErrors();
        CollectViaCallee(Observer);
        Observer.Expect('after callee', '1');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectViaCallee(var Observer: Codeunit "Probe Observer")
    begin
        Raiser();
        Observer.Observe('after callee', Format(GetCollectedErrors().Count()));
        ClearCollectedErrors();
    end;

    local procedure Raiser()
    begin
        Error(ErrorInfo.Create('from callee', true));
    end;
}
