// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpRequestMessage SetCookie(Cookie) and GetCookie with Cookie objects: name, value, uninitialised cookie, overwrite
// BC versions: 29 (27 and 28 by CI)

codeunit 74814 "LT P97 Req CookieObj"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SetName(var C: Cookie; V: Text)
    var
        R: Text;
    begin
        R := C.Name(V);
    end;

    local procedure SetValue(var C: Cookie; V: Text)
    var
        R: Text;
    begin
        R := C.Value(V);
    end;

    [TryFunction]
    local procedure TrySetObj(var Req: HttpRequestMessage; var C: Cookie; var Result: Boolean)
    begin
        Result := Req.SetCookie(C);
    end;

    [TryFunction]
    local procedure TryGet(var Req: HttpRequestMessage; Name: Text; var Result: Text)
    var
        C: Cookie;
        Found: Boolean;
    begin
        Found := Req.GetCookie(Name, C);
        Result := Format(Found);
        if Found then
            Result += '|' + C.Name() + '|' + C.Value() + '|' + C.Domain() + '|' + C.Path() + '|' + Format(C.Secure()) + '|' + Format(C.HttpOnly());
    end;

    local procedure SetObs(var Observer: Codeunit "Probe Observer"; Name: Text; var Req: HttpRequestMessage; var C: Cookie; GetName: Text)
    var
        R: Boolean;
        G: Text;
    begin
        if TrySetObj(Req, C, R) then begin
            Observer.Observe(Name, Format(R));
            if TryGet(Req, GetName, G) then
                Observer.Observe(Name + '_get', G)
            else
                Observer.ObserveError(Name + '_get');
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SetCookie_Object()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: Cookie;
    begin
        Req.SetRequestUri('https://example.invalid/path');
        SetName(C, 'obj');
        SetValue(C, 'v1');
        SetObs(Observer, 'object', Req, C, 'obj');
        SetValue(C, 'v2');
        SetObs(Observer, 'changed_value', Req, C, 'obj');
        Observer.Expect('object', 'Yes');
        Observer.Expect('object_get', 'Yes|obj|v1||/|No|No');
        Observer.Expect('changed_value', 'Yes');
        Observer.Expect('changed_value_get', 'Yes|obj|v2||/|No|No');
        Observer.Verify();
    end;

    [Test]
    procedure SetCookie_Object_NoUri()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: Cookie;
    begin
        SetName(C, 'obj');
        SetValue(C, 'v1');
        SetObs(Observer, 'object', Req, C, 'obj');
        Observer.Expect('object', 'Yes');
        Observer.Expect('object_get', 'Yes|obj|v1||/|No|No');
        Observer.Verify();
    end;

    [Test]
    procedure SetCookie_Object_Uninitialised()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: Cookie;
        Named: Cookie;
    begin
        Req.SetRequestUri('https://example.invalid/');
        SetObs(Observer, 'uninit', Req, C, '');
        SetName(Named, 'only');
        SetObs(Observer, 'name_only', Req, Named, 'only');
        Observer.Expect('uninit', 'No');
        Observer.Expect('uninit_get', 'No');
        Observer.Expect('name_only', 'Yes');
        Observer.Expect('name_only_get', 'Yes|only|||/|No|No');
        Observer.Verify();
    end;

    [Test]
    procedure GetCookie_Cookie_IsCopy()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: Cookie;
        Back: Cookie;
        G: Text;
    begin
        Req.SetRequestUri('https://example.invalid/');
        SetName(C, 'copy');
        SetValue(C, 'orig');
        Req.SetCookie(C);
        SetValue(C, 'changed');
        if TryGet(Req, 'copy', G) then
            Observer.Observe('after_change_local', G)
        else
            Observer.ObserveError('after_change_local');
        Req.GetCookie('copy', Back);
        SetValue(Back, 'changed_back');
        if TryGet(Req, 'copy', G) then
            Observer.Observe('after_change_back', G)
        else
            Observer.ObserveError('after_change_back');
        Observer.Expect('after_change_local', 'Yes|copy|orig||/|No|No');
        Observer.Expect('after_change_back', 'Yes|copy|orig||/|No|No');
        Observer.Verify();
    end;

    [Test]
    procedure SetCookie_Object_Overwrites_NameValue()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: Cookie;
        G: Text;
    begin
        Req.SetRequestUri('https://example.invalid/');
        Req.SetCookie('same', 'text');
        SetName(C, 'same');
        SetValue(C, 'object');
        Req.SetCookie(C);
        if TryGet(Req, 'same', G) then
            Observer.Observe('after_object', G)
        else
            Observer.ObserveError('after_object');
        Req.SetCookie('same', 'text2');
        if TryGet(Req, 'same', G) then
            Observer.Observe('after_text', G)
        else
            Observer.ObserveError('after_text');
        Observer.Expect('after_object', 'Yes|same|object||/|No|No');
        Observer.Expect('after_text', 'Yes|same|text2||/|No|No');
        Observer.Verify();
    end;
}
