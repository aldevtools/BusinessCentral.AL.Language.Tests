// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73851, codeunit 73851
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "GetLastErrorText(ExcludeCustomerContent)" (GetLastErrorText flag, SaveValues with page extensions, ... issue 35)
// Facts: GetLastErrorText(true), GetLastErrorText(false) and GetLastErrorText() for Error with an argument, TestField and a failed Get; the flag after no error
// BC versions: 29 (27 and 28 by CI)

table 73851 "LT PnF Flag Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73851 "LT PnF LastErr Flag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryErrorArg()
    begin
        Error('x %1', 'secret');
    end;

    [TryFunction]
    local procedure TryErrorPlain()
    begin
        Error('plain text');
    end;

    [TryFunction]
    local procedure TryTestFieldBlank()
    var
        Row: Record "LT PnF Flag Row";
    begin
        Row.Id := 7;
        Row.TestField(Name);
    end;

    [TryFunction]
    local procedure TryTestFieldValue()
    var
        Row: Record "LT PnF Flag Row";
    begin
        Row.Id := 7;
        Row.Name := 'actual';
        Row.TestField(Name, 'expected');
    end;

    [TryFunction]
    local procedure TryGetMissing()
    var
        Row: Record "LT PnF Flag Row";
    begin
        Row.Get(12345);
    end;

    local procedure ObserveForms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '|true', GetLastErrorText(true));
        Observer.Observe(Name + '|false', GetLastErrorText(false));
        Observer.Observe(Name + '|default', GetLastErrorText());
        Observer.Observe(Name + '|code', GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure Flag_ErrorWithArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if not TryErrorArg() then
            ObserveForms('error_arg', Observer);
        asserterror Error('x %1', 'secret');
        Observer.ObserveError('error_arg_asserterror');
        Observer.Expect('error_arg|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('error_arg|false', 'x secret');
        Observer.Expect('error_arg|default', 'x secret');
        Observer.Expect('error_arg|code', 'Dialog');
        Observer.Expect('error_arg_asserterror|text', 'x secret');
        Observer.Expect('error_arg_asserterror|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_ErrorPlain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if not TryErrorPlain() then
            ObserveForms('error_plain', Observer);
        asserterror Error('plain text');
        Observer.ObserveError('error_plain_asserterror');
        Observer.Expect('error_plain|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('error_plain|false', 'plain text');
        Observer.Expect('error_plain|default', 'plain text');
        Observer.Expect('error_plain|code', 'Dialog');
        Observer.Expect('error_plain_asserterror|text', 'plain text');
        Observer.Expect('error_plain_asserterror|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_TestField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if not TryTestFieldBlank() then
            ObserveForms('testfield_blank', Observer);
        if not TryTestFieldValue() then
            ObserveForms('testfield_value', Observer);
        Observer.Expect('testfield_blank|true', 'Name must have a value in LT PnF Flag Row: <redacted>. It cannot be zero or empty.');
        Observer.Expect('testfield_blank|false', 'Name must have a value in LT PnF Flag Row: Id=7. It cannot be zero or empty.');
        Observer.Expect('testfield_blank|default', 'Name must have a value in LT PnF Flag Row: Id=7. It cannot be zero or empty.');
        Observer.Expect('testfield_blank|code', 'TestField');
        Observer.Expect('testfield_value|true', 'Name must be equal to ''<redacted>''  in LT PnF Flag Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('testfield_value|false', 'Name must be equal to ''expected''  in LT PnF Flag Row: Id=7. Current value is ''actual''.');
        Observer.Expect('testfield_value|default', 'Name must be equal to ''expected''  in LT PnF Flag Row: Id=7. Current value is ''actual''.');
        Observer.Expect('testfield_value|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_GetMissing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Flag Row";
    begin
        Row.DeleteAll();
        if not TryGetMissing() then
            ObserveForms('get_missing', Observer);
        asserterror Row.Get(12345);
        Observer.ObserveError('get_missing_asserterror');
        Observer.Expect('get_missing|true', 'The LT PnF Flag Row does not exist. Identification fields and values: <redacted>');
        Observer.Expect('get_missing|false', 'The LT PnF Flag Row does not exist. Identification fields and values: Id=''12345''');
        Observer.Expect('get_missing|default', 'The LT PnF Flag Row does not exist. Identification fields and values: Id=''12345''');
        Observer.Expect('get_missing|code', 'DB:RecordNotFound');
        Observer.Expect('get_missing_asserterror|text', 'The LT PnF Flag Row does not exist. Identification fields and values: Id=''12345''');
        Observer.Expect('get_missing_asserterror|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_AfterNoError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('true', GetLastErrorText(true));
        Observer.Observe('false', GetLastErrorText(false));
        Observer.Observe('default', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('true', '');
        Observer.Expect('false', '');
        Observer.Expect('default', '');
        Observer.Expect('code', '');
        Observer.Verify();
    end;
}
