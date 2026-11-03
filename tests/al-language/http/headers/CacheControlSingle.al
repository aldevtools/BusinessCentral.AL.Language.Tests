// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Cache-Control directives added alone: GetValues result, Keys, order within one Add call, case and invalid values (request headers)
// BC versions: 29 (27 and 28 by CI)

codeunit 72963 "LT Hdr198 Cache Single"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Hdr198 Helper";

    local procedure One(Value: Text): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(1, H);
        Res := 'add=' + Helper.DoAdd(H, 'Cache-Control', Value);
        Res += ';get=' + Helper.DoGet(H, 'Cache-Control');
        Res += ';keys=' + Helper.Keys(H);
        exit(Res);
    end;

    [Test]
    procedure P198_EachDirectiveAlone()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        D: Text;
    begin
        Helper.Directives(L);
        foreach D in L do
            Observer.Observe(D, One(D));
        Observer.Expect('no-store', 'add=ok;get=Yes/no-store;keys=1:Cache-Control,');
        Observer.Expect('no-transform', 'add=ok;get=Yes/no-transform;keys=1:Cache-Control,');
        Observer.Expect('only-if-cached', 'add=ok;get=Yes/only-if-cached;keys=1:Cache-Control,');
        Observer.Expect('public', 'add=ok;get=Yes/public;keys=1:Cache-Control,');
        Observer.Expect('no-cache', 'add=ok;get=Yes/no-cache;keys=1:Cache-Control,');
        Observer.Expect('max-age=60', 'add=ok;get=Yes/max-age=60;keys=1:Cache-Control,');
        Observer.Expect('max-stale=30', 'add=ok;get=Yes/max-stale=30;keys=1:Cache-Control,');
        Observer.Expect('min-fresh=10', 'add=ok;get=Yes/min-fresh=10;keys=1:Cache-Control,');
        Observer.Expect('private', 'add=ok;get=Yes/private;keys=1:Cache-Control,');
        Observer.Expect('must-revalidate', 'add=ok;get=Yes/must-revalidate;keys=1:Cache-Control,');
        Observer.Expect('proxy-revalidate', 'add=ok;get=Yes/proxy-revalidate;keys=1:Cache-Control,');
        Observer.Expect('s-maxage=5', 'add=ok;get=Yes/s-maxage=5;keys=1:Cache-Control,');
        Observer.Expect('x-test=1', 'add=ok;get=Yes/x-test=1;keys=1:Cache-Control,');
        Observer.Verify();
    end;

    [Test]
    procedure P198_LowerCaseHeaderName()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
        L: List of [Text];
        D: Text;
    begin
        Helper.Directives(L);
        foreach D in L do begin
            Clear(H);
            Helper.GetH(1, H);
            Helper.DoAdd(H, 'cache-control', D);
            Observer.Observe(D, Helper.Keys(H) + Helper.DoGet(H, 'CACHE-CONTROL'));
        end;
        Observer.Expect('no-store', '1:Cache-Control,Yes/no-store');
        Observer.Expect('no-transform', '1:Cache-Control,Yes/no-transform');
        Observer.Expect('only-if-cached', '1:Cache-Control,Yes/only-if-cached');
        Observer.Expect('public', '1:Cache-Control,Yes/public');
        Observer.Expect('no-cache', '1:Cache-Control,Yes/no-cache');
        Observer.Expect('max-age=60', '1:Cache-Control,Yes/max-age=60');
        Observer.Expect('max-stale=30', '1:Cache-Control,Yes/max-stale=30');
        Observer.Expect('min-fresh=10', '1:Cache-Control,Yes/min-fresh=10');
        Observer.Expect('private', '1:Cache-Control,Yes/private');
        Observer.Expect('must-revalidate', '1:Cache-Control,Yes/must-revalidate');
        Observer.Expect('proxy-revalidate', '1:Cache-Control,Yes/proxy-revalidate');
        Observer.Expect('s-maxage=5', '1:Cache-Control,Yes/s-maxage=5');
        Observer.Expect('x-test=1', '1:Cache-Control,Yes/x-test=1');
        Observer.Verify();
    end;

    [Test]
    procedure P198_DirectiveCaseAsWritten()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('NO-CACHE', One('NO-CACHE'));
        Observer.Observe('No-Store', One('No-Store'));
        Observer.Observe('MAX-AGE=60', One('MAX-AGE=60'));
        Observer.Observe('Public', One('Public'));
        Observer.Observe('X-Test=1', One('X-Test=1'));
        Observer.Observe('maxAgeSpaces', One('max-age = 60'));
        Observer.Observe('maxAgeZero', One('max-age=0'));
        Observer.Observe('maxAgeBig', One('max-age=99999999999'));
        Observer.Observe('noCacheField', One('no-cache="Set-Cookie"'));
        Observer.Observe('privateField', One('private="Authorization"'));
        Observer.Observe('extNoValue', One('x-test'));
        Observer.Observe('extQuoted', One('x-test="a b"'));
        Observer.Observe('extToken', One('x-test=a'));
        Observer.Expect('NO-CACHE', 'add=ok;get=Yes/no-cache;keys=1:Cache-Control,');
        Observer.Expect('No-Store', 'add=ok;get=Yes/no-store;keys=1:Cache-Control,');
        Observer.Expect('MAX-AGE=60', 'add=ok;get=Yes/max-age=60;keys=1:Cache-Control,');
        Observer.Expect('Public', 'add=ok;get=Yes/public;keys=1:Cache-Control,');
        Observer.Expect('X-Test=1', 'add=ok;get=Yes/X-Test=1;keys=1:Cache-Control,');
        Observer.Expect('maxAgeSpaces', 'add=ok;get=Yes/max-age=60;keys=1:Cache-Control,');
        Observer.Expect('maxAgeZero', 'add=ok;get=Yes/max-age=0;keys=1:Cache-Control,');
        Observer.Expect('maxAgeBig', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('noCacheField', 'add=ok;get=Yes/no-cache="Set-Cookie";keys=1:Cache-Control,');
        Observer.Expect('privateField', 'add=ok;get=Yes/private="Authorization";keys=1:Cache-Control,');
        Observer.Expect('extNoValue', 'add=ok;get=Yes/x-test;keys=1:Cache-Control,');
        Observer.Expect('extQuoted', 'add=ok;get=Yes/x-test="a b";keys=1:Cache-Control,');
        Observer.Expect('extToken', 'add=ok;get=Yes/x-test=a;keys=1:Cache-Control,');
        Observer.Verify();
    end;

    [Test]
    procedure P198_InvalidAndEmptyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', One(''));
        Observer.Observe('space', One(' '));
        Observer.Observe('maxAgeText', One('max-age=abc'));
        Observer.Observe('maxAgeNegative', One('max-age=-1'));
        Observer.Observe('maxAgeEmpty', One('max-age='));
        Observer.Observe('comma', One(','));
        Observer.Observe('trailingComma', One('no-cache,'));
        Observer.Observe('twoCommaTight', One('no-cache,no-store'));
        Observer.Observe('twoSpaces', One('no-cache  no-store'));
        Observer.Observe('twoSemicolon', One('no-cache;no-store'));
        Observer.Observe('slash', One('no/cache'));
        Observer.Observe('unicode', One('x-ü=1'));
        Observer.Expect('empty', 'add=ok;get=No/;keys=0:');
        Observer.Expect('space', 'add=ok;get=No/;keys=0:');
        Observer.Expect('maxAgeText', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('maxAgeNegative', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('maxAgeEmpty', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('comma', 'add=ok;get=No/;keys=0:');
        Observer.Expect('trailingComma', 'add=ok;get=Yes/no-cache;keys=1:Cache-Control,');
        Observer.Expect('twoCommaTight', 'add=ok;get=Yes/no-store, no-cache;keys=1:Cache-Control,');
        Observer.Expect('twoSpaces', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('twoSemicolon', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('slash', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Expect('unicode', 'add=E[Invalid HTTP header. Please, make sure t];get=No/;keys=0:');
        Observer.Verify();
    end;

    [Test]
    procedure P198_SameDirectiveTwice()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
        L: List of [Text];
        D: Text;
        Res: Text;
    begin
        Helper.Directives(L);
        foreach D in L do begin
            Clear(H);
            Helper.GetH(1, H);
            Res := Helper.DoAdd(H, 'Cache-Control', D);
            Res += '/' + Helper.DoAdd(H, 'Cache-Control', D);
            Observer.Observe(D, Res + '/' + Helper.DoGet(H, 'Cache-Control'));
        end;
        Observer.Expect('no-store', 'ok/ok/Yes/no-store');
        Observer.Expect('no-transform', 'ok/ok/Yes/no-transform');
        Observer.Expect('only-if-cached', 'ok/ok/Yes/only-if-cached');
        Observer.Expect('public', 'ok/ok/Yes/public');
        Observer.Expect('no-cache', 'ok/ok/Yes/no-cache');
        Observer.Expect('max-age=60', 'ok/ok/Yes/max-age=60');
        Observer.Expect('max-stale=30', 'ok/ok/Yes/max-stale=30');
        Observer.Expect('min-fresh=10', 'ok/ok/Yes/min-fresh=10');
        Observer.Expect('private', 'ok/ok/Yes/private');
        Observer.Expect('must-revalidate', 'ok/ok/Yes/must-revalidate');
        Observer.Expect('proxy-revalidate', 'ok/ok/Yes/proxy-revalidate');
        Observer.Expect('s-maxage=5', 'ok/ok/Yes/s-maxage=5');
        Observer.Expect('x-test=1', 'ok/ok/Yes/x-test=1, x-test=1');
        Observer.Verify();
    end;
}
