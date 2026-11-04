// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group/Log tables, LT P106 Log codeunit, pages LT P106 Card / List / Group List / Sub / Host from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField.AsDateTime on DateTime controls (filled, blank, after SetValue) and on a control of another type
// BC versions: 29 (27 and 28 by CI)

codeunit 72417 "LT P106 TestField AsDateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";

    [Test]
    procedure P106_AsDateTime_Values()
    var
        Observer: Codeunit "Probe Observer";
        L: TestPage "LT P106 List";
    begin
        Log.Seed();
        L.OpenEdit();
        Observer.Observe('goto_a', Format(L.GoToKey('A')));
        Observer.Observe('a', Format(L.DtCtl.AsDateTime(), 0, 9));
        Observer.Observe('a_text', L.DtCtl.Value());
        Observer.Observe('goto_b', Format(L.GoToKey('B')));
        Observer.Observe('b', Format(L.DtCtl.AsDateTime(), 0, 9));
        Observer.Observe('goto_d', Format(L.GoToKey('D')));
        Observer.Observe('blank', Format(L.DtCtl.AsDateTime(), 0, 9));
        Observer.Observe('blank_is_zero', Format(L.DtCtl.AsDateTime() = 0DT));
        L.DtCtl.SetValue(CreateDateTime(DMY2Date(7, 8, 2022), 080910T));
        Observer.Observe('after_set', Format(L.DtCtl.AsDateTime(), 0, 9));
        L.Close();
        Observer.Expect('goto_a', 'Yes');
        Observer.Expect('a', '2020-03-02T10:15:00Z');
        Observer.Expect('a_text', '3/2/2020 10:15 AM');
        Observer.Expect('goto_b', 'Yes');
        Observer.Expect('b', '2021-06-05T23:59:59Z');
        Observer.Expect('goto_d', 'Yes');
        Observer.Expect('blank', '');
        Observer.Expect('blank_is_zero', 'Yes');
        Observer.Expect('after_set', '2022-08-07T08:09:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure P106_AsDateTime_Card()
    var
        Observer: Codeunit "Probe Observer";
        C: TestPage "LT P106 Card";
    begin
        Log.Seed();
        C.OpenEdit();
        Observer.Observe('card', Format(C.DtCtl.AsDateTime(), 0, 9));
        asserterror C.DtCtl.SetValue('2023-01-02T03:04:05');
        Observer.ObserveError('af47');
        Observer.Observe('set_text', Format(C.DtCtl.AsDateTime(), 0, 9));
        C.Close();
        Observer.Expect('card', '2020-03-02T10:15:00Z');
        Observer.Expect('af47|text', 'Validation error for Field: DtCtl,  Message = ''Your entry of ''2023-01-02T03:04:05'' is not an acceptable value for ''DT''. The date is not valid. (Select Refresh to discard errors)''');
        Observer.Expect('af47|code', 'TestValidation');
        Observer.Expect('set_text', '2020-03-02T10:15:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure P106_AsDateTime_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        C: TestPage "LT P106 Card";
    begin
        Log.Seed();
        C.OpenEdit();
        C.Close();
        Observer.Verify();
    end;
}
