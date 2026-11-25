// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 75670, test codeunit 75671
// Probe (al-runner issue 8649): enum values and option members after `::` whose names are words of the AL language.
// Facts:
//   - The enum values and option members named Exit, If and This work through the quoted name after `::` (V::"Exit", O::"If");
//     Local and Key work unquoted (V::Local, O::Key); Format gives the name and the ordinal is the declared one.
//   - Not compiling (must-not-compile 3460 to 3496): one of 32 words unquoted after `::` (And, AssertError, Begin, Case, Div, Do,
//     DownTo, Else, End, Event, Exit, False, For, ForEach, If, In, Mod, Not, Of, Or, Procedure, Repeat, Then, This, To, Trigger,
//     True, Until, Var, While, With, Xor), with AL0107 at the name first: an enum value through a variable or the enum type, an
//     option field's or option variable's member, a case label, and Database:: before a table named so.
// local object: the value names are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

enum 75670 "TYP Keyword Scope Value"
{
    value(0; "Exit") { }
    value(1; "If") { }
    value(2; "This") { }
    value(3; Local) { }
    value(4; "Key") { }
}

codeunit 75671 "TYP Keyword Scope Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordScopeNames_Enum_QuotedAndPlainNames()
    var
        Observer: Codeunit "Probe Observer";
        Value: Enum "TYP Keyword Scope Value";
    begin
        Initialize();
        Value := Value::"Exit";
        Observer.Observe('Exit', Format(Value) + '/' + Format(Value.AsInteger()));
        Value := Value::"If";
        Observer.Observe('If', Format(Value) + '/' + Format(Value.AsInteger()));
        Value := "TYP Keyword Scope Value"::"This";
        Observer.Observe('This', Format(Value) + '/' + Format(Value.AsInteger()));
        Value := Value::Local;
        Observer.Observe('Local', Format(Value) + '/' + Format(Value.AsInteger()));
        Value := Value::Key;
        Observer.Observe('Key', Format(Value) + '/' + Format(Value.AsInteger()));
        Observer.Expect('Exit', 'Exit/0');
        Observer.Expect('If', 'If/1');
        Observer.Expect('This', 'This/2');
        Observer.Expect('Local', 'Local/3');
        Observer.Expect('Key', 'Key/4');
        Observer.Verify();
    end;

    [Test]
    procedure KeywordScopeNames_Option_QuotedAndPlainMembers()
    var
        Observer: Codeunit "Probe Observer";
        Option: Option Zero,"If",Local,"Key";
    begin
        Initialize();
        Option := Option::"If";
        Observer.Observe('If', Format(Option) + '/' + Format(Option, 0, 9));
        Option := Option::Local;
        Observer.Observe('Local', Format(Option) + '/' + Format(Option, 0, 9));
        Option := Option::Key;
        Observer.Observe('Key', Format(Option) + '/' + Format(Option, 0, 9));
        Observer.Expect('If', 'If/1');
        Observer.Expect('Local', 'Local/2');
        Observer.Expect('Key', 'Key/3');
        Observer.Verify();
    end;

    local procedure Initialize()
    begin
    end;
}
