// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Cache-Control: every ordered pair of directives, each added with two Add calls; one observation per first directive joins the GetValues results of all second directives
// BC versions: 29 (27 and 28 by CI)

codeunit 72964 "LT Hdr198 Cache Pairs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Hdr198 Helper";

    local procedure PairResult(First: Text; Second: Text; OneCall: Boolean): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(1, H);
        if OneCall then
            Res := Helper.DoAdd(H, 'Cache-Control', First + ', ' + Second)
        else begin
            Res := Helper.DoAdd(H, 'Cache-Control', First);
            if Res = 'ok' then
                Res := Helper.DoAdd(H, 'Cache-Control', Second);
        end;
        if Res = 'ok' then
            exit(Helper.DoGet(H, 'Cache-Control'));
        exit(Res);
    end;

    local procedure ForFirst(First: Text; OneCall: Boolean): Text
    var
        L: List of [Text];
        Second: Text;
        Res: Text;
    begin
        Helper.Directives(L);
        foreach Second in L do
            if Second <> First then
                Res += PairResult(First, Second, OneCall) + ';';
        exit(Res);
    end;

    local procedure Chunk(var Observer: Codeunit "Probe Observer"; From: Integer; UpTo: Integer; OneCall: Boolean)
    var
        L: List of [Text];
        i: Integer;
    begin
        Helper.Directives(L);
        for i := From to UpTo do
            Observer.Observe(L.Get(i), ForFirst(L.Get(i), OneCall));
    end;

    [Test]
    procedure P198_TwoAdds_First_1_To_7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, 1, 7, false);
        Observer.Expect('no-store', 'Yes/no-store, no-transform;Yes/no-store, only-if-cached;Yes/no-store, public;Yes/no-store, no-cache;Yes/no-store, max-age=60;Yes/no-store, max-stale=30;Yes/no-store, min-fresh=10;Yes/no-store, private;Yes/no-store, must-revalidate;Yes/no-store, proxy-revalidate;Yes/no-store, s-maxage=5;Yes/no-store, x-test=1;');
        Observer.Expect('no-transform', 'Yes/no-store, no-transform;Yes/no-transform, only-if-cached;Yes/no-transform, public;Yes/no-transform, no-cache;Yes/no-transform, max-age=60;Yes/no-transform, max-stale=30;Yes/no-transform, min-fresh=10;Yes/no-transform, private;Yes/no-transform, must-revalidate;Yes/no-transform, proxy-revalidate;Yes/no-transform, s-maxage=5;Yes/no-transform, x-test=1;');
        Observer.Expect('only-if-cached', 'Yes/no-store, only-if-cached;Yes/no-transform, only-if-cached;Yes/only-if-cached, public;Yes/only-if-cached, no-cache;Yes/only-if-cached, max-age=60;Yes/only-if-cached, max-stale=30;Yes/only-if-cached, min-fresh=10;Yes/only-if-cached, private;Yes/only-if-cached, must-revalidate;Yes/only-if-cached, proxy-revalidate;Yes/only-if-cached, s-maxage=5;Yes/only-if-cached, x-test=1;');
        Observer.Expect('public', 'Yes/no-store, public;Yes/no-transform, public;Yes/only-if-cached, public;Yes/public, no-cache;Yes/public, max-age=60;Yes/public, max-stale=30;Yes/public, min-fresh=10;Yes/public, private;Yes/public, must-revalidate;Yes/public, proxy-revalidate;Yes/public, s-maxage=5;Yes/public, x-test=1;');
        Observer.Expect('no-cache', 'Yes/no-store, no-cache;Yes/no-transform, no-cache;Yes/only-if-cached, no-cache;Yes/public, no-cache;Yes/no-cache, max-age=60;Yes/no-cache, max-stale=30;Yes/no-cache, min-fresh=10;Yes/no-cache, private;Yes/must-revalidate, no-cache;Yes/proxy-revalidate, no-cache;Yes/no-cache, s-maxage=5;Yes/no-cache, x-test=1;');
        Observer.Expect('max-age=60', 'Yes/no-store, max-age=60;Yes/no-transform, max-age=60;Yes/only-if-cached, max-age=60;Yes/public, max-age=60;Yes/no-cache, max-age=60;Yes/max-age=60, max-stale=30;Yes/max-age=60, min-fresh=10;Yes/max-age=60, private;Yes/must-revalidate, max-age=60;Yes/proxy-revalidate, max-age=60;Yes/max-age=60, s-maxage=5;Yes/max-age=60, x-test=1;');
        Observer.Expect('max-stale=30', 'Yes/no-store, max-stale=30;Yes/no-transform, max-stale=30;Yes/only-if-cached, max-stale=30;Yes/public, max-stale=30;Yes/no-cache, max-stale=30;Yes/max-age=60, max-stale=30;Yes/max-stale=30, min-fresh=10;Yes/max-stale=30, private;Yes/must-revalidate, max-stale=30;Yes/proxy-revalidate, max-stale=30;Yes/s-maxage=5, max-stale=30;Yes/max-stale=30, x-test=1;');
        Observer.Verify();
    end;





    [Test]
    procedure P198_TwoAdds_First_8_To_13()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, 8, 13, false);
        Observer.Expect('min-fresh=10', 'Yes/no-store, min-fresh=10;Yes/no-transform, min-fresh=10;Yes/only-if-cached, min-fresh=10;Yes/public, min-fresh=10;Yes/no-cache, min-fresh=10;Yes/max-age=60, min-fresh=10;Yes/max-stale=30, min-fresh=10;Yes/min-fresh=10, private;Yes/must-revalidate, min-fresh=10;Yes/proxy-revalidate, min-fresh=10;Yes/s-maxage=5, min-fresh=10;Yes/min-fresh=10, x-test=1;');
        Observer.Expect('private', 'Yes/no-store, private;Yes/no-transform, private;Yes/only-if-cached, private;Yes/public, private;Yes/no-cache, private;Yes/max-age=60, private;Yes/max-stale=30, private;Yes/min-fresh=10, private;Yes/must-revalidate, private;Yes/proxy-revalidate, private;Yes/s-maxage=5, private;Yes/private, x-test=1;');
        Observer.Expect('must-revalidate', 'Yes/no-store, must-revalidate;Yes/no-transform, must-revalidate;Yes/only-if-cached, must-revalidate;Yes/public, must-revalidate;Yes/must-revalidate, no-cache;Yes/must-revalidate, max-age=60;Yes/must-revalidate, max-stale=30;Yes/must-revalidate, min-fresh=10;Yes/must-revalidate, private;Yes/must-revalidate, proxy-revalidate;Yes/must-revalidate, s-maxage=5;Yes/must-revalidate, x-test=1;');
        Observer.Expect('proxy-revalidate', 'Yes/no-store, proxy-revalidate;Yes/no-transform, proxy-revalidate;Yes/only-if-cached, proxy-revalidate;Yes/public, proxy-revalidate;Yes/proxy-revalidate, no-cache;Yes/proxy-revalidate, max-age=60;Yes/proxy-revalidate, max-stale=30;Yes/proxy-revalidate, min-fresh=10;Yes/proxy-revalidate, private;Yes/must-revalidate, proxy-revalidate;Yes/proxy-revalidate, s-maxage=5;Yes/proxy-revalidate, x-test=1;');
        Observer.Expect('s-maxage=5', 'Yes/no-store, s-maxage=5;Yes/no-transform, s-maxage=5;Yes/only-if-cached, s-maxage=5;Yes/public, s-maxage=5;Yes/no-cache, s-maxage=5;Yes/max-age=60, s-maxage=5;Yes/s-maxage=5, max-stale=30;Yes/s-maxage=5, min-fresh=10;Yes/s-maxage=5, private;Yes/must-revalidate, s-maxage=5;Yes/proxy-revalidate, s-maxage=5;Yes/s-maxage=5, x-test=1;');
        Observer.Expect('x-test=1', 'Yes/no-store, x-test=1;Yes/no-transform, x-test=1;Yes/only-if-cached, x-test=1;Yes/public, x-test=1;Yes/no-cache, x-test=1;Yes/max-age=60, x-test=1;Yes/max-stale=30, x-test=1;Yes/min-fresh=10, x-test=1;Yes/private, x-test=1;Yes/must-revalidate, x-test=1;Yes/proxy-revalidate, x-test=1;Yes/s-maxage=5, x-test=1;');
        Observer.Verify();
    end;





    [Test]
    procedure P198_OneAddWithComma_First_1_To_7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, 1, 7, true);
        Observer.Expect('no-store', 'Yes/no-store, no-transform;Yes/no-store, only-if-cached;Yes/no-store, public;Yes/no-store, no-cache;Yes/no-store, max-age=60;Yes/no-store, max-stale=30;Yes/no-store, min-fresh=10;Yes/no-store, private;Yes/no-store, must-revalidate;Yes/no-store, proxy-revalidate;Yes/no-store, s-maxage=5;Yes/no-store, x-test=1;');
        Observer.Expect('no-transform', 'Yes/no-store, no-transform;Yes/no-transform, only-if-cached;Yes/no-transform, public;Yes/no-transform, no-cache;Yes/no-transform, max-age=60;Yes/no-transform, max-stale=30;Yes/no-transform, min-fresh=10;Yes/no-transform, private;Yes/no-transform, must-revalidate;Yes/no-transform, proxy-revalidate;Yes/no-transform, s-maxage=5;Yes/no-transform, x-test=1;');
        Observer.Expect('only-if-cached', 'Yes/no-store, only-if-cached;Yes/no-transform, only-if-cached;Yes/only-if-cached, public;Yes/only-if-cached, no-cache;Yes/only-if-cached, max-age=60;Yes/only-if-cached, max-stale=30;Yes/only-if-cached, min-fresh=10;Yes/only-if-cached, private;Yes/only-if-cached, must-revalidate;Yes/only-if-cached, proxy-revalidate;Yes/only-if-cached, s-maxage=5;Yes/only-if-cached, x-test=1;');
        Observer.Expect('public', 'Yes/no-store, public;Yes/no-transform, public;Yes/only-if-cached, public;Yes/public, no-cache;Yes/public, max-age=60;Yes/public, max-stale=30;Yes/public, min-fresh=10;Yes/public, private;Yes/public, must-revalidate;Yes/public, proxy-revalidate;Yes/public, s-maxage=5;Yes/public, x-test=1;');
        Observer.Expect('no-cache', 'Yes/no-store, no-cache;Yes/no-transform, no-cache;Yes/only-if-cached, no-cache;Yes/public, no-cache;Yes/no-cache, max-age=60;Yes/no-cache, max-stale=30;Yes/no-cache, min-fresh=10;Yes/no-cache, private;Yes/must-revalidate, no-cache;Yes/proxy-revalidate, no-cache;Yes/no-cache, s-maxage=5;Yes/no-cache, x-test=1;');
        Observer.Expect('max-age=60', 'Yes/no-store, max-age=60;Yes/no-transform, max-age=60;Yes/only-if-cached, max-age=60;Yes/public, max-age=60;Yes/no-cache, max-age=60;Yes/max-age=60, max-stale=30;Yes/max-age=60, min-fresh=10;Yes/max-age=60, private;Yes/must-revalidate, max-age=60;Yes/proxy-revalidate, max-age=60;Yes/max-age=60, s-maxage=5;Yes/max-age=60, x-test=1;');
        Observer.Expect('max-stale=30', 'Yes/no-store, max-stale=30;Yes/no-transform, max-stale=30;Yes/only-if-cached, max-stale=30;Yes/public, max-stale=30;Yes/no-cache, max-stale=30;Yes/max-age=60, max-stale=30;Yes/max-stale=30, min-fresh=10;Yes/max-stale=30, private;Yes/must-revalidate, max-stale=30;Yes/proxy-revalidate, max-stale=30;Yes/s-maxage=5, max-stale=30;Yes/max-stale=30, x-test=1;');
        Observer.Verify();
    end;





    [Test]
    procedure P198_OneAddWithComma_First_8_To_13()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, 8, 13, true);
        Observer.Expect('min-fresh=10', 'Yes/no-store, min-fresh=10;Yes/no-transform, min-fresh=10;Yes/only-if-cached, min-fresh=10;Yes/public, min-fresh=10;Yes/no-cache, min-fresh=10;Yes/max-age=60, min-fresh=10;Yes/max-stale=30, min-fresh=10;Yes/min-fresh=10, private;Yes/must-revalidate, min-fresh=10;Yes/proxy-revalidate, min-fresh=10;Yes/s-maxage=5, min-fresh=10;Yes/min-fresh=10, x-test=1;');
        Observer.Expect('private', 'Yes/no-store, private;Yes/no-transform, private;Yes/only-if-cached, private;Yes/public, private;Yes/no-cache, private;Yes/max-age=60, private;Yes/max-stale=30, private;Yes/min-fresh=10, private;Yes/must-revalidate, private;Yes/proxy-revalidate, private;Yes/s-maxage=5, private;Yes/private, x-test=1;');
        Observer.Expect('must-revalidate', 'Yes/no-store, must-revalidate;Yes/no-transform, must-revalidate;Yes/only-if-cached, must-revalidate;Yes/public, must-revalidate;Yes/must-revalidate, no-cache;Yes/must-revalidate, max-age=60;Yes/must-revalidate, max-stale=30;Yes/must-revalidate, min-fresh=10;Yes/must-revalidate, private;Yes/must-revalidate, proxy-revalidate;Yes/must-revalidate, s-maxage=5;Yes/must-revalidate, x-test=1;');
        Observer.Expect('proxy-revalidate', 'Yes/no-store, proxy-revalidate;Yes/no-transform, proxy-revalidate;Yes/only-if-cached, proxy-revalidate;Yes/public, proxy-revalidate;Yes/proxy-revalidate, no-cache;Yes/proxy-revalidate, max-age=60;Yes/proxy-revalidate, max-stale=30;Yes/proxy-revalidate, min-fresh=10;Yes/proxy-revalidate, private;Yes/must-revalidate, proxy-revalidate;Yes/proxy-revalidate, s-maxage=5;Yes/proxy-revalidate, x-test=1;');
        Observer.Expect('s-maxage=5', 'Yes/no-store, s-maxage=5;Yes/no-transform, s-maxage=5;Yes/only-if-cached, s-maxage=5;Yes/public, s-maxage=5;Yes/no-cache, s-maxage=5;Yes/max-age=60, s-maxage=5;Yes/s-maxage=5, max-stale=30;Yes/s-maxage=5, min-fresh=10;Yes/s-maxage=5, private;Yes/must-revalidate, s-maxage=5;Yes/proxy-revalidate, s-maxage=5;Yes/s-maxage=5, x-test=1;');
        Observer.Expect('x-test=1', 'Yes/no-store, x-test=1;Yes/no-transform, x-test=1;Yes/only-if-cached, x-test=1;Yes/public, x-test=1;Yes/no-cache, x-test=1;Yes/max-age=60, x-test=1;Yes/max-stale=30, x-test=1;Yes/min-fresh=10, x-test=1;Yes/private, x-test=1;Yes/must-revalidate, x-test=1;Yes/proxy-revalidate, x-test=1;Yes/s-maxage=5, x-test=1;');
        Observer.Verify();
    end;




}
