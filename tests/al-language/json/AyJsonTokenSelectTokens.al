// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-selecttokens-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80505
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: JsonToken.SelectTokens(Path, var List of [JsonToken]) on an object token, an array token and a value token: several matches (wildcard, recursive
// descent, filter), no match, a pre-filled list, and invalid paths: the Boolean, the tokens returned, GetLastErrorText and GetLastErrorCode.
// The method needs app runtime 17: on BC 27 (runtime 16.1) the compiler refuses it (must-not-compile case 1200), so the tests are BC28PLUS.
// BC versions: 28, 29 (corpus CI)

// The whole codeunit is BC 28+ (JsonToken.SelectTokens needs runtime 17): on BC 27 a Subtype = Test codeunit without test methods
// reports no result and fails the leg (bump 28 staging run 39285388937).
#if BC28PLUS
codeunit 80505 "LT AY JsonToken SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySelect(T: JsonToken; Path: Text; var L: List of [JsonToken]; var Ret: Boolean)
    begin
        Ret := T.SelectTokens(Path, L);
    end;

    local procedure Q(var Observer: Codeunit "Probe Observer"; T: JsonToken; ObsKey: Text; Path: Text; PreFill: Boolean)
    var
        L: List of [JsonToken];
        X: JsonToken;
        Ret: Boolean;
        Out: Text;
    begin
        if PreFill then begin
            X.ReadFrom('"old"');
            L.Add(X);
        end;
        ClearLastError();
        if TrySelect(T, Path, L, Ret) then begin
            Out := Format(Ret) + ' n=' + Format(L.Count()) + ':';
            foreach X in L do
                Out += Format(X) + '@' + X.Path() + ';';
            if GetLastErrorText() <> '' then
                Out += ' last=' + GetLastErrorText() + '|' + GetLastErrorCode();
            Observer.Observe(ObsKey, Out);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure Doc(): JsonToken
    var
        T: JsonToken;
    begin
        T.ReadFrom('{"a":[{"n":1,"p":5},{"n":2,"p":15},{"n":3}],"b":{"n":4}}');
        exit(T);
    end;

    [Test]
    procedure SelectTokens_ObjectToken_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'wildcard', '$.a[*].n', false);
        Q(Observer, Doc(), 'recursive', '$..n', false);
        Q(Observer, Doc(), 'filter', '$.a[?(@.p > 10)].n', false);
        Observer.Expect('wildcard', 'Yes n=3:1@a[0].n;2@a[1].n;3@a[2].n;');
        Observer.Expect('recursive', 'Yes n=4:1@a[0].n;2@a[1].n;3@a[2].n;4@b.n;');
        Observer.Expect('filter', 'Yes n=1:2@a[1].n;');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_ObjectToken_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'single', '$.b.n', false);
        Q(Observer, Doc(), 'no_dollar', 'a[0].n', false);
        Q(Observer, Doc(), 'no_match', '$.zz', false);
        Observer.Expect('single', 'Yes n=1:4@b.n;');
        Observer.Expect('no_dollar', 'Yes n=1:1@a[0].n;');
        Observer.Expect('no_match', 'Yes n=0:');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_ObjectToken_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'no_match_prefilled', '$.zz', true);
        Q(Observer, Doc(), 'match_prefilled', '$.a[*].n', true);
        Observer.Expect('no_match_prefilled', 'Yes n=0:');
        Observer.Expect('match_prefilled', 'Yes n=3:1@a[0].n;2@a[1].n;3@a[2].n;');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_ArrayAndValueToken_1()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonToken;
        V: JsonToken;
    begin
        A.ReadFrom('[1,[2,3],{"x":4}]');
        V.ReadFrom('7');
        Q(Observer, A, 'array_all', '$[*]', false);
        Q(Observer, A, 'array_slice', '$[0:2]', false);
        Q(Observer, A, 'array_recursive', '$..x', false);
        Observer.Expect('array_all', 'Yes n=3:1@[0];[2,3]@[1];{"x":4}@[2];');
        Observer.Expect('array_slice', 'Yes n=2:1@[0];[2,3]@[1];');
        Observer.Expect('array_recursive', 'Yes n=1:4@[2].x;');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_ArrayAndValueToken_2()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonToken;
        V: JsonToken;
    begin
        A.ReadFrom('[1,[2,3],{"x":4}]');
        V.ReadFrom('7');
        Q(Observer, V, 'value_root', '$', false);
        Q(Observer, V, 'value_child', '$.a', false);
        Observer.Expect('value_root', 'Yes n=1:7@;');
        Observer.Expect('value_child', 'Yes n=0:');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_InvalidPath_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'unclosed_bracket', '$.a[', false);
        Q(Observer, Doc(), 'bad_filter', '$.a[?(@.p >)]', false);
        Q(Observer, Doc(), 'empty', '', false);
        Observer.Expect('unclosed_bracket', 'No n=0: last=The requested operation cannot be performed in this context.|InvalidOperation');
        Observer.Expect('bad_filter', 'No n=0: last=The requested operation cannot be performed in this context.|InvalidOperation');
        Observer.Expect('empty', 'Yes n=1:{"a":[{"n":1,"p":5},{"n":2,"p":15},{"n":3}],"b":{"n":4}}@;');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_InvalidPath_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Q(Observer, Doc(), 'unclosed_prefilled', '$.a[', true);
        Observer.Expect('unclosed_prefilled', 'No n=1:"old"@; last=The requested operation cannot be performed in this context.|InvalidOperation');
        Observer.Verify();
    end;
}
#endif
