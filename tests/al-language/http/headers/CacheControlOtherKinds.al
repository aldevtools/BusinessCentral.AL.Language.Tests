// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Cache-Control on content headers and response headers (content headers probably reject it; the error is observed): each directive alone and ordered pairs of a few directives
// BC versions: 29 (27 and 28 by CI)

codeunit 72966 "LT Hdr198 Cache Other Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Hdr198 Helper";

    local procedure Pair(Kind: Integer; A: Text; B: Text): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(Kind, H);
        Res := Helper.DoAdd(H, 'Cache-Control', A);
        Res += '/' + Helper.DoAdd(H, 'Cache-Control', B);
        exit(Res + '/' + Helper.DoGet(H, 'Cache-Control'));
    end;

    local procedure Singles(var Observer: Codeunit "Probe Observer"; Kind: Integer)
    var
        L: List of [Text];
        D: Text;
        H: HttpHeaders;
    begin
        Helper.Directives(L);
        foreach D in L do begin
            Clear(H);
            Helper.GetH(Kind, H);
            Observer.Observe(D, Helper.DoAdd(H, 'Cache-Control', D) + '/' + Helper.DoGet(H, 'Cache-Control'));
        end;
    end;

    [Test]
    procedure P198_Response_EachDirectiveAlone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Singles(Observer, 3);
        Observer.Expect('no-store', 'ok/Yes/no-store');
        Observer.Expect('no-transform', 'ok/Yes/no-transform');
        Observer.Expect('only-if-cached', 'ok/Yes/only-if-cached');
        Observer.Expect('public', 'ok/Yes/public');
        Observer.Expect('no-cache', 'ok/Yes/no-cache');
        Observer.Expect('max-age=60', 'ok/Yes/max-age=60');
        Observer.Expect('max-stale=30', 'ok/Yes/max-stale=30');
        Observer.Expect('min-fresh=10', 'ok/Yes/min-fresh=10');
        Observer.Expect('private', 'ok/Yes/private');
        Observer.Expect('must-revalidate', 'ok/Yes/must-revalidate');
        Observer.Expect('proxy-revalidate', 'ok/Yes/proxy-revalidate');
        Observer.Expect('s-maxage=5', 'ok/Yes/s-maxage=5');
        Observer.Expect('x-test=1', 'ok/Yes/x-test=1');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Content_EachDirectiveAlone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Singles(Observer, 2);
        Observer.Expect('no-store', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('no-transform', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('only-if-cached', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('public', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('no-cache', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('max-age=60', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('max-stale=30', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('min-fresh=10', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('private', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('must-revalidate', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('proxy-revalidate', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('s-maxage=5', 'E[The requested operation cannot be perfor]/No/');
        Observer.Expect('x-test=1', 'E[The requested operation cannot be perfor]/No/');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Response_Pairs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('noCache_noStore', Pair(3, 'no-cache', 'no-store'));
        Observer.Observe('noStore_noCache', Pair(3, 'no-store', 'no-cache'));
        Observer.Observe('public_maxAge', Pair(3, 'public', 'max-age=60'));
        Observer.Observe('maxAge_public', Pair(3, 'max-age=60', 'public'));
        Observer.Observe('private_mustRevalidate', Pair(3, 'private', 'must-revalidate'));
        Observer.Observe('mustRevalidate_private', Pair(3, 'must-revalidate', 'private'));
        Observer.Observe('sMaxAge_proxyRevalidate', Pair(3, 's-maxage=5', 'proxy-revalidate'));
        Observer.Observe('proxyRevalidate_sMaxAge', Pair(3, 'proxy-revalidate', 's-maxage=5'));
        Observer.Observe('ext_noTransform', Pair(3, 'x-test=1', 'no-transform'));
        Observer.Observe('noTransform_ext', Pair(3, 'no-transform', 'x-test=1'));
        Observer.Expect('noCache_noStore', 'ok/ok/Yes/no-store, no-cache');
        Observer.Expect('noStore_noCache', 'ok/ok/Yes/no-store, no-cache');
        Observer.Expect('public_maxAge', 'ok/ok/Yes/public, max-age=60');
        Observer.Expect('maxAge_public', 'ok/ok/Yes/public, max-age=60');
        Observer.Expect('private_mustRevalidate', 'ok/ok/Yes/must-revalidate, private');
        Observer.Expect('mustRevalidate_private', 'ok/ok/Yes/must-revalidate, private');
        Observer.Expect('sMaxAge_proxyRevalidate', 'ok/ok/Yes/proxy-revalidate, s-maxage=5');
        Observer.Expect('proxyRevalidate_sMaxAge', 'ok/ok/Yes/proxy-revalidate, s-maxage=5');
        Observer.Expect('ext_noTransform', 'ok/ok/Yes/no-transform, x-test=1');
        Observer.Expect('noTransform_ext', 'ok/ok/Yes/no-transform, x-test=1');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Content_Pairs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('noCache_noStore', Pair(2, 'no-cache', 'no-store'));
        Observer.Observe('noStore_noCache', Pair(2, 'no-store', 'no-cache'));
        Observer.Observe('public_maxAge', Pair(2, 'public', 'max-age=60'));
        Observer.Expect('noCache_noStore', 'E[The requested operation cannot be perfor]/E[The requested operation cannot be perfor]/No/');
        Observer.Expect('noStore_noCache', 'E[The requested operation cannot be perfor]/E[The requested operation cannot be perfor]/No/');
        Observer.Expect('public_maxAge', 'E[The requested operation cannot be perfor]/E[The requested operation cannot be perfor]/No/');
        Observer.Verify();
    end;
}
