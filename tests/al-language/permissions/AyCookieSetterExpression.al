// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/cookie/cookie-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80506
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: the setter forms Cookie.Name(Text) and Cookie.Value(Text) (the only Cookie members with a setter) used as an expression: Format of the value
// they return, on a fresh cookie, on a cookie that held other values and with an empty text, and the getter afterwards.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80506 "LT AY Cookie Setter Expression"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CookieSetter_AsExpression_FreshCookie()
    var
        Observer: Codeunit "Probe Observer";
        C: Cookie;
    begin
        Observer.Observe('name', '[' + Format(C.Name('n')) + '] get=' + C.Name());
        Observer.Observe('value', '[' + Format(C.Value('v')) + '] get=' + C.Value());
        Observer.Expect('name', '[n] get=n');
        Observer.Expect('value', '[v] get=v');
        Observer.Verify();
    end;

    [Test]
    procedure CookieSetter_AsExpression_OtherValues()
    var
        Observer: Codeunit "Probe Observer";
        C: Cookie;
        Ignored: Text;
    begin
        // The statement form C.Name('old-name'); compiles with the AL 30 compiler but the BC 27.5/28.5/29.0 server
        // rejects it at publish with AL0192 "The return value must be used for the method 'Name'" (corpus CI, 2026-10-19).
        Ignored := C.Name('old-name');
        Ignored := C.Value('old-value');
        Observer.Observe('name', '[' + Format(C.Name('n')) + '] get=' + C.Name());
        Observer.Observe('value', '[' + Format(C.Value('v')) + '] get=' + C.Value());
        Observer.Expect('name', '[n] get=n');
        Observer.Expect('value', '[v] get=v');
        Observer.Verify();
    end;

    // Corpus CI 2026-10-19: Name('') raises "The 'Name'='' part of the cookie is invalid." on 27.5, 28.5 and 29.0.
    [Test]
    procedure CookieSetter_EmptyName()
    var
        Observer: Codeunit "Probe Observer";
        C: Cookie;
        Ignored: Text;
    begin
        Ignored := C.Name('old-name');
        asserterror Ignored := C.Name('');
        Observer.ObserveError('name_empty');
        Observer.Observe('name_after', C.Name());
        Observer.Expect('name_empty|text', 'The ''Name''='''' part of the cookie is invalid.');
        Observer.Expect('name_empty|code', 'AL:Cookie');
        Observer.Expect('name_after', 'old-name');
        Observer.Verify();
    end;

    [Test]
    procedure CookieSetter_EmptyValue()
    var
        Observer: Codeunit "Probe Observer";
        C: Cookie;
        Ignored: Text;
    begin
        Ignored := C.Name('old-name');
        Ignored := C.Value('old-value');
        Observer.Observe('value_empty', '[' + Format(C.Value('')) + '] get=' + C.Value());
        Observer.Expect('value_empty', '[] get=');
        Observer.Verify();
    end;
}
