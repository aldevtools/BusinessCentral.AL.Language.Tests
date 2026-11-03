// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-setdata-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: Notification.SetData with a Guid (and other non-text values) as the value, then GetData and HasData; the read-back text compared with Format(Guid)
// and with Format(Guid, 0, 4). Settles: guid-as-text-argument. Object id 67183.

codeunit 67183 "LT Notification Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetData_Guid_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
        G: Guid;
    begin
        G := '{12345678-1234-1234-1234-123456789ABC}';
        N.SetData('k', G);
        Observer.Observe('has_data', Format(N.HasData('k')));
        Observer.Observe('get_data', N.GetData('k'));
        Observer.Observe('equals_format_default', Format(N.GetData('k') = Format(G)));
        Observer.Observe('equals_format_braces_off', Format(N.GetData('k') = Format(G, 0, 4)));
        Observer.Observe('length', Format(StrLen(N.GetData('k'))));
        Observer.Expect('has_data', 'Yes');
        Observer.Expect('get_data', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('equals_format_default', 'Yes');
        Observer.Expect('equals_format_braces_off', 'No');
        Observer.Expect('length', '38');
        Observer.Verify();
    end;

    [Test]
    procedure SetData_NonTextValues_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
        Blank: Guid;
    begin
        N.SetData('blank_guid', Blank);
        Observer.Observe('blank_guid', N.GetData('blank_guid'));
        Observer.Observe('blank_guid_has_data', Format(N.HasData('blank_guid')));
        N.SetData('int', Format(42));
        Observer.Observe('int_text', N.GetData('int'));
        Observer.Observe('missing_has_data', Format(N.HasData('missing')));
        Observer.Observe('missing_get_data', '[' + N.GetData('missing') + ']');
        Observer.Expect('blank_guid', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('blank_guid_has_data', 'Yes');
        Observer.Expect('int_text', '42');
        Observer.Expect('missing_has_data', 'No');
        Observer.Expect('missing_get_data', '[]');
        Observer.Verify();
    end;
}
