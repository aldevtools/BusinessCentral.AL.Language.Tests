// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Cache-Control: three directives in all six orders, longer sequences, interleaving with another header, Remove and re-add
// BC versions: 29 (27 and 28 by CI)

codeunit 72965 "LT Hdr198 Cache Triples"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Hdr198 Helper";

    local procedure Seq(A: Text; B: Text; C: Text): Text
    var
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Helper.DoAdd(H, 'Cache-Control', A);
        Helper.DoAdd(H, 'Cache-Control', B);
        Helper.DoAdd(H, 'Cache-Control', C);
        exit(Helper.DoGet(H, 'Cache-Control'));
    end;

    local procedure AllOrders(var Observer: Codeunit "Probe Observer"; A: Text; B: Text; C: Text)
    begin
        Observer.Observe('abc', Seq(A, B, C));
        Observer.Observe('acb', Seq(A, C, B));
        Observer.Observe('bac', Seq(B, A, C));
        Observer.Observe('bca', Seq(B, C, A));
        Observer.Observe('cab', Seq(C, A, B));
        Observer.Observe('cba', Seq(C, B, A));
    end;

    [Test]
    procedure P198_Triple_NoCache_NoStore_Public()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AllOrders(Observer, 'no-cache', 'no-store', 'public');
        Observer.Expect('abc', 'Yes/no-store, public, no-cache');
        Observer.Expect('acb', 'Yes/no-store, public, no-cache');
        Observer.Expect('bac', 'Yes/no-store, public, no-cache');
        Observer.Expect('bca', 'Yes/no-store, public, no-cache');
        Observer.Expect('cab', 'Yes/no-store, public, no-cache');
        Observer.Expect('cba', 'Yes/no-store, public, no-cache');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Triple_MaxAge_Private_Extension()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AllOrders(Observer, 'max-age=60', 'private', 'x-test=1');
        Observer.Expect('abc', 'Yes/max-age=60, private, x-test=1');
        Observer.Expect('acb', 'Yes/max-age=60, private, x-test=1');
        Observer.Expect('bac', 'Yes/max-age=60, private, x-test=1');
        Observer.Expect('bca', 'Yes/max-age=60, private, x-test=1');
        Observer.Expect('cab', 'Yes/max-age=60, private, x-test=1');
        Observer.Expect('cba', 'Yes/max-age=60, private, x-test=1');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Triple_MaxStale_MinFresh_SMaxAge()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AllOrders(Observer, 'max-stale=30', 'min-fresh=10', 's-maxage=5');
        Observer.Expect('abc', 'Yes/s-maxage=5, max-stale=30, min-fresh=10');
        Observer.Expect('acb', 'Yes/s-maxage=5, max-stale=30, min-fresh=10');
        Observer.Expect('bac', 'Yes/s-maxage=5, max-stale=30, min-fresh=10');
        Observer.Expect('bca', 'Yes/s-maxage=5, max-stale=30, min-fresh=10');
        Observer.Expect('cab', 'Yes/s-maxage=5, max-stale=30, min-fresh=10');
        Observer.Expect('cba', 'Yes/s-maxage=5, max-stale=30, min-fresh=10');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Triple_Revalidate_Transform_OnlyIfCached()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AllOrders(Observer, 'must-revalidate', 'proxy-revalidate', 'only-if-cached');
        Observer.Expect('abc', 'Yes/only-if-cached, must-revalidate, proxy-revalidate');
        Observer.Expect('acb', 'Yes/only-if-cached, must-revalidate, proxy-revalidate');
        Observer.Expect('bac', 'Yes/only-if-cached, must-revalidate, proxy-revalidate');
        Observer.Expect('bca', 'Yes/only-if-cached, must-revalidate, proxy-revalidate');
        Observer.Expect('cab', 'Yes/only-if-cached, must-revalidate, proxy-revalidate');
        Observer.Expect('cba', 'Yes/only-if-cached, must-revalidate, proxy-revalidate');
        Observer.Verify();
    end;

    [Test]
    procedure P198_AllDirectivesInListOrderAndReverse()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
        L: List of [Text];
        i: Integer;
    begin
        Helper.Directives(L);
        Helper.GetH(1, H);
        for i := 1 to L.Count() do
            Helper.DoAdd(H, 'Cache-Control', L.Get(i));
        Observer.Observe('forward', Helper.DoGet(H, 'Cache-Control'));
        Clear(H);
        Helper.GetH(1, H);
        for i := L.Count() downto 1 do
            Helper.DoAdd(H, 'Cache-Control', L.Get(i));
        Observer.Observe('reverse', Helper.DoGet(H, 'Cache-Control'));
        Observer.Expect('forward', 'Yes/no-store, no-transform, only-if-cached, public, must-revalidate, proxy-revalidate, no-cache, max-age=60, s-maxage=5, max-stale=30, min-fresh=10, private, x-test=1');
        Observer.Expect('reverse', 'Yes/no-store, no-transform, only-if-cached, public, must-revalidate, proxy-revalidate, no-cache, max-age=60, s-maxage=5, max-stale=30, min-fresh=10, private, x-test=1');
        Observer.Verify();
    end;

    [Test]
    procedure P198_InterleavedAndRemoved()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Helper.DoAdd(H, 'Cache-Control', 'no-cache');
        Helper.DoAdd(H, 'Accept', 'text/html');
        Helper.DoAdd(H, 'Cache-Control', 'no-store');
        Helper.DoAdd(H, 'Pragma', 'no-cache');
        Helper.DoAdd(H, 'Cache-Control', 'max-age=60');
        Observer.Observe('get', Helper.DoGet(H, 'Cache-Control'));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('remove', Helper.DoRemove(H, 'cache-control'));
        Observer.Observe('getAfter', Helper.DoGet(H, 'Cache-Control'));
        Observer.Observe('keysAfter', Helper.Keys(H));
        Helper.DoAdd(H, 'Cache-Control', 'no-store');
        Helper.DoAdd(H, 'Cache-Control', 'no-cache');
        Observer.Observe('readded', Helper.DoGet(H, 'Cache-Control'));
        Observer.Observe('keysReadded', Helper.Keys(H));
        Observer.Expect('get', 'Yes/no-store, no-cache, max-age=60');
        Observer.Expect('keys', '3:Cache-Control,Accept,Pragma,');
        Observer.Expect('remove', 'Yes');
        Observer.Expect('getAfter', 'No/');
        Observer.Expect('keysAfter', '2:Accept,Pragma,');
        Observer.Expect('readded', 'Yes/no-store, no-cache');
        Observer.Expect('keysReadded', '3:Accept,Pragma,Cache-Control,');
        Observer.Verify();
    end;

    [Test]
    procedure P198_RawAddWithoutValidation()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Observer.Observe('raw1', Helper.DoRaw(H, 'Cache-Control', 'no-cache'));
        Observer.Observe('raw2', Helper.DoRaw(H, 'Cache-Control', 'no-store'));
        Observer.Observe('raw3', Helper.DoRaw(H, 'Cache-Control', 'max-age=60'));
        Observer.Observe('get', Helper.DoGet(H, 'Cache-Control'));
        Observer.Observe('rawInvalid', Helper.DoRaw(H, 'Cache-Control', 'max-age=abc'));
        Observer.Observe('getAfterInvalid', Helper.DoGet(H, 'Cache-Control'));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Expect('raw1', 'ok');
        Observer.Expect('raw2', 'ok');
        Observer.Expect('raw3', 'ok');
        Observer.Expect('get', 'Yes/no-store, no-cache, max-age=60');
        Observer.Expect('rawInvalid', 'ok');
        Observer.Expect('getAfterInvalid', 'Yes/no-store, no-cache, max-age=60|max-age=abc');
        Observer.Expect('keys', '1:Cache-Control,');
        Observer.Verify();
    end;
}
