// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/keyref/keyref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 91550 "LT Y12 KeyRef Row" (own, self-contained)
// Probe (al-runner issue 6437, writer Y12): the text Format gives for a KeyRef, for a key of one field and of several fields, with the
// standard format and with format numbers 1, 2 and 9. Object ids 91550 - 91551.

table 91550 "LT Y12 KeyRef Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document Type"; Option) { OptionMembers = Quote,Order; }
        field(3; "No."; Code[20]) { }
        field(5; Description; Text[50]) { }
        field(7; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Document Type", "No.") { Clustered = true; }
        key(ByDescription; Description) { }
        key(ByAmount; Amount, "No.", Description) { }
    }
}

codeunit 91551 "LT Y12 KeyRef Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y12_Format_KeyRef_StandardFormat()
    var
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"LT Y12 KeyRef Row");
        Observer.Observe('pk', Format(RecRef.KeyIndex(1)));
        Observer.Observe('one_field', Format(RecRef.KeyIndex(2)));
        Observer.Observe('three_fields', Format(RecRef.KeyIndex(3)));
        Observer.Expect('pk', 'Field1,Field3');
        Observer.Expect('one_field', 'Field5');
        Observer.Expect('three_fields', 'Field7,Field3,Field5');
        Observer.Verify();
    end;

    [Test]
    procedure Y12_Format_KeyRef_FormatNumbers()
    var
        RecRef: RecordRef;
        KeyR: KeyRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"LT Y12 KeyRef Row");
        KeyR := RecRef.KeyIndex(1);
        Observer.Observe('f0', Format(KeyR, 0, 0));
        Observer.Observe('f1', Format(KeyR, 0, 1));
        Observer.Observe('f2', Format(KeyR, 0, 2));
        Observer.Observe('f9', Format(KeyR, 0, 9));
        Observer.Observe('len5', Format(KeyR, 5));
        Observer.Expect('f0', 'Field1,Field3');
        Observer.Expect('f1', 'Field1,Field3');
        Observer.Expect('f2', 'Field1,Field3');
        Observer.Expect('f9', 'Field1,Field3');
        Observer.Expect('len5', 'Field');
        Observer.Verify();
    end;

    [Test]
    procedure Y12_Format_KeyRef_FromGetTableAndTemporary()
    var
        Row: Record "LT Y12 KeyRef Row";
        TempRow: Record "LT Y12 KeyRef Row" temporary;
        RecRef: RecordRef;
        TempRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.GetTable(Row);
        Observer.Observe('gettable_pk', Format(RecRef.KeyIndex(1)));
        TempRef.GetTable(TempRow);
        Observer.Observe('temporary_pk', Format(TempRef.KeyIndex(3)));
        Observer.Expect('gettable_pk', 'Field1,Field3');
        Observer.Expect('temporary_pk', 'Field7,Field3,Field5');
        Observer.Verify();
    end;

    [Test]
    procedure Y12_Format_KeyRef_SystemTable()
    var
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::Integer);
        Observer.Observe('integer_pk', Format(RecRef.KeyIndex(1)));
        RecRef.Close();
        RecRef.Open(Database::"NAV App Installed App");
        Observer.Observe('installed_app_pk', Format(RecRef.KeyIndex(1)));
        Observer.Expect('integer_pk', 'Field1');
        Observer.Expect('installed_app_pk', 'Field1');
        Observer.Verify();
    end;
}
