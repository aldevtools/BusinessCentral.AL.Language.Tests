// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/codeunit/system.text.json-management
// Scope: public JSON Management API; no copied Microsoft implementation or customer schema.
// BC versions: 27.5, 28.5, 29.0. Verified by the real BC matrix, not by AL Runner.
codeunit 69025 "JSN JSON Property Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure JSONManagement_TextProperty_ReturnsNonDefaultValue()
    var
        JSONMgt: Codeunit "JSON Management";
        Value: Variant;
    begin
        Initialize();
        JSONMgt.InitializeFromString('{"sample":"value-42"}');
        if not JSONMgt.GetPropertyValueByName('sample', Value) then
            Error('Expected sample property to exist.');
        if Format(Value) <> 'value-42' then
            Error('Expected value-42, got %1.', Format(Value));
    end;
    [Test]
    procedure JSONManagement_NumberProperty_ReturnsNonZeroValue()
    var
        JSONMgt: Codeunit "JSON Management";
        Value: Variant;
    begin
        Initialize();
        JSONMgt.InitializeFromString('{"amount":42}');
        if not JSONMgt.GetPropertyValueByName('amount', Value) then
            Error('Expected amount property to exist.');
        if Format(Value) <> '42' then
            Error('Expected 42, got %1.', Format(Value));
    end;
    local procedure Initialize()
    begin
        FixtureCleanup.Initialize();
        // This example uses no persistent records.
    end;
}
