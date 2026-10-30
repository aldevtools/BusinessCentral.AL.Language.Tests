// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained worker codeunit 91360, test codeunit 91361
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: whether two call stack texts compare equal with = : ErrorInfo.Callstack() read twice from one collected error, two collected errors raised by the same
//   statement reached from the same call site and from two call sites, two errors raised by different statements, a Text copy and a CopyStr of the text, and
//   GetLastErrorCallStack() of two failed TryFunction calls from one call site. Also StrLen equality and whether the text holds the character U+FDD0.
//   The call stack text itself is not asserted (it names apps and lines).
// BC versions: 27, 28, 29

codeunit 91360 "LT Y7 Callstack Worker"
{
    procedure RaiseCollectible(Msg: Text)
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create(Msg);
        ErrInfo.Collectible := true;
        Error(ErrInfo);
    end;

    procedure RaiseCollectibleOther(Msg: Text)
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create(Msg);
        ErrInfo.Collectible := true;
        Error(ErrInfo);
    end;

    [TryFunction]
    procedure TryFail()
    begin
        Error('boom');
    end;
}

codeunit 91361 "LT Y7 Callstack Equality"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Mark(): Text
    var
        C: Text[1];
    begin
        C[1] := 64976;
        exit(C);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Y7_Callstack_Collected_Equality()
    var
        Observer: Codeunit "Probe Observer";
        Worker: Codeunit "LT Y7 Callstack Worker";
        Collected: List of [ErrorInfo];
        E1: ErrorInfo;
        E2: ErrorInfo;
        E3: ErrorInfo;
        E4: ErrorInfo;
        CS1: Text;
        CS1Again: Text;
        CS2: Text;
        CS3: Text;
        CS4: Text;
        Copy: Text;
        I: Integer;
    begin
        for I := 1 to 2 do
            Worker.RaiseCollectible('same site');
        Worker.RaiseCollectible('other site');
        Worker.RaiseCollectibleOther('other statement');
        Collected := GetCollectedErrors(true);
        Observer.Observe('collected count', Format(Collected.Count()));
        Collected.Get(1, E1);
        Collected.Get(2, E2);
        Collected.Get(3, E3);
        Collected.Get(4, E4);
        CS1 := E1.Callstack();
        CS1Again := E1.Callstack();
        CS2 := E2.Callstack();
        CS3 := E3.Callstack();
        CS4 := E4.Callstack();
        Copy := CS1;
        Observer.Observe('empty', Format(CS1 = ''));
        Observer.Observe('read twice equal', Format(CS1 = CS1Again));
        Observer.Observe('call twice inline equal', Format(E1.Callstack() = E1.Callstack()));
        Observer.Observe('copy equal', Format(Copy = CS1));
        Observer.Observe('copystr equal', Format(CopyStr(CS1, 1) = CS1));
        Observer.Observe('same statement same call site equal', Format(CS1 = CS2));
        Observer.Observe('same statement same call site length equal', Format(StrLen(CS1) = StrLen(CS2)));
        Observer.Observe('same statement other call site equal', Format(CS1 = CS3));
        Observer.Observe('other statement equal', Format(CS1 = CS4));
        Observer.Observe('not equal operator same site', Format(CS1 <> CS2));
        Observer.Observe('holds U+FDD0', Format(CS1.Contains(Mark())));
        Observer.Finish();
    end;

    [Test]
    procedure Y7_Callstack_LastError_TwoTryCalls_Equality()
    var
        Observer: Codeunit "Probe Observer";
        Worker: Codeunit "LT Y7 Callstack Worker";
        CS: array[2] of Text;
        I: Integer;
    begin
        for I := 1 to 2 do begin
            Observer.Observe('try ' + Format(I), Format(Worker.TryFail()));
            CS[I] := GetLastErrorCallStack();
            ClearLastError();
        end;
        Observer.Observe('empty', Format(CS[1] = ''));
        Observer.Observe('two calls equal', Format(CS[1] = CS[2]));
        Observer.Observe('holds U+FDD0', Format(CS[1].Contains(Mark())));
        Observer.Finish();
    end;
}
