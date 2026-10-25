// @expect AL0305 | The length of the application object identifier 'MNC Test Codeunit Name Length31' cannot exceed 30 characters.
// A test codeunit whose name has 31 characters, one over the limit (al-runner issue 5845). Case 0055 has a 37-character
// name. A 30-character test codeunit name compiles: tests/al-language/codeunit/TestScopeIsolationContracts.al
// ("Test Scope Isolation Contracts", codeunit 60170).
codeunit 50000 "MNC Test Codeunit Name Length31"
{
    Subtype = Test;

    [Test]
    procedure DoublesTheValue()
    begin
        if 21 * 2 <> 42 then
            Error('21 * 2 is not 42.');
    end;
}
