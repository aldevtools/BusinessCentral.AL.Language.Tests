// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-key-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 83860, codeunit 83871
// Probe: corpus #664 item 48 (microsoft/AL issue 2159): a secondary key of 17 fields that does not name the primary key field F1 (the platform appends it). The compiler (AL 30) accepts it; kept in its own file so it can be dropped if the
//   app does not publish.
// Facts: the app publishes; Insert, SetCurrentKey on the long key, FindFirst/FindLast order and the key's field list through KeyRef
// BC versions: 27, 28, 29

table 83860 "LT BN3 Key17"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; F1; Integer) { }
        field(2; F2; Integer) { }
        field(3; F3; Integer) { }
        field(4; F4; Integer) { }
        field(5; F5; Integer) { }
        field(6; F6; Integer) { }
        field(7; F7; Integer) { }
        field(8; F8; Integer) { }
        field(9; F9; Integer) { }
        field(10; F10; Integer) { }
        field(11; F11; Integer) { }
        field(12; F12; Integer) { }
        field(13; F13; Integer) { }
        field(14; F14; Integer) { }
        field(15; F15; Integer) { }
        field(16; F16; Integer) { }
        field(17; F17; Integer) { }
        field(18; F18; Integer) { }
    }

    keys
    {
        key(PK; F1) { Clustered = true; }
        key(SK; F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18) { }
    }
}

codeunit 83871 "LT BN3 Key17 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BN3_KeyOf17Fields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN3 Key17";
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.F1 := 1;
        Row.F2 := 20;
        Row.Insert();
        Row.Init();
        Row.F1 := 2;
        Row.F2 := 10;
        Row.Insert();
        Row.SetCurrentKey(F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18);
        Row.FindFirst();
        Observer.Observe('first', Format(Row.F1));
        Row.FindLast();
        Observer.Observe('last', Format(Row.F1));
        Observer.Observe('current key', Row.CurrentKey());
        RecRef.Open(Database::"LT BN3 Key17");
        Observer.Observe('key count', Format(RecRef.KeyCount()));
        KRef := RecRef.KeyIndex(2);
        Observer.Observe('second key field count', Format(KRef.FieldCount()));
        Observer.Expect('first', '2');
        Observer.Expect('last', '1');
        Observer.Expect('current key', 'F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18');
        Observer.Expect('key count', '3');
        Observer.Expect('second key field count', '17');
        Observer.Verify();
    end;
}
