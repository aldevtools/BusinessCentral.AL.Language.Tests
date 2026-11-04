// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Notification.Id assigned a Guid text (plain, braces, uppercase, not a Guid, empty); the Id is also read back after Message-less use (assumption notification-id-from-guid-text). Risky: assigning a Text to Notification.Id may not compile; each form is in its own codeunit-free procedure via Evaluate fallback.
// BC versions: 29 (27 and 28 by CI)

codeunit 70658 "LT NotifId From Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAssignId(var N: Notification; Value: Text)
    begin
        N.Id := Value;
    end;

    local procedure Attempt(Value: Text): Text
    var
        N: Notification;
    begin
        ClearLastError();
        if TryAssignId(N, Value) then
            exit('ok:' + Format(N.Id));
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure Id_FromGuidText_Result()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.Id := '9a3203a3-35a5-4598-941b-2d6c9f1a2b3c';
        Observer.Observe('literal_plain', Format(N.Id));
        Observer.Observe('func_plain', Attempt('9a3203a3-35a5-4598-941b-2d6c9f1a2b3c'));
        Observer.Observe('func_braces', Attempt('{9a3203a3-35a5-4598-941b-2d6c9f1a2b3c}'));
        Observer.Observe('func_upper', Attempt('9A3203A3-35A5-4598-941B-2D6C9F1A2B3C'));
        Observer.Observe('func_no_dashes', Attempt('9a3203a335a54598941b2d6c9f1a2b3c'));
        Observer.Expect('literal_plain', '{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Expect('func_plain', 'ok:{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Expect('func_braces', 'ok:{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Expect('func_upper', 'ok:{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Expect('func_no_dashes', 'ok:{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Verify();
    end;

    [Test]
    procedure Id_FromInvalidText_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('not_a_guid', Attempt('not a guid'));
        Observer.Observe('too_short', Attempt('9a3203a3-35a5-4598-941b'));
        Observer.Observe('too_long', Attempt('9a3203a3-35a5-4598-941b-2d6c9f1a2b3c-00'));
        Observer.Observe('empty', Attempt(''));
        Observer.Observe('spaces', Attempt('   '));
        Observer.Expect('not_a_guid', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('too_short', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('too_long', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('empty', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('spaces', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Verify();
    end;

    [Test]
    procedure Id_RoundTripThroughGuid_Result()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
        N2: Notification;
        G: Guid;
    begin
        Evaluate(G, '9a3203a3-35a5-4598-941b-2d6c9f1a2b3c');
        N.Id := G;
        Observer.Observe('guid_assigned', Format(N.Id));
        N2.Id := Format(G);
        Observer.Observe('text_assigned', Format(N2.Id));
        Observer.Observe('same_id', Format(N.Id = N2.Id));
        Observer.Expect('guid_assigned', '{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Expect('text_assigned', '{9A3203A3-35A5-4598-941B-2D6C9F1A2B3C}');
        Observer.Expect('same_id', 'Yes');
        Observer.Verify();
    end;
}
