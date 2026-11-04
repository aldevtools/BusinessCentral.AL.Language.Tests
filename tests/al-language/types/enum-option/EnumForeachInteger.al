// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-foreach-statement
// Scope: in-scope
// Fixtures used: Probe Observer (69160); enum 67070 (EnumFromIntegerVariant.al)
// Probe: foreach over a List of [Integer] with an Enum variable as the loop variable: the values the variable takes (known and unknown ordinals), and foreach over a List of [Enum] into an Integer variable.
// Object id 67123.

codeunit 67123 "LT F3 Enum Foreach"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Foreach_ListOfInteger_IntoEnumVariable()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: List of [Integer];
        Color: Enum "LT FI Color";
        Seen: Text;
    begin
        Numbers.Add(0);
        Numbers.Add(5);
        Numbers.Add(1);
        Numbers.Add(7);
        foreach Color in Numbers do
            Seen += Format(Color) + '/' + Format(Color.AsInteger()) + ';';
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'Red/0;Blue/5;Green/1;7/7;');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_ListOfEnum_IntoIntegerVariable()
    var
        Observer: Codeunit "Probe Observer";
        Colors: List of [Enum "LT FI Color"];
        Value: Integer;
        Seen: Text;
    begin
        Colors.Add(Enum::"LT FI Color"::Blue);
        Colors.Add(Enum::"LT FI Color"::Green);
        foreach Value in Colors do
            Seen += Format(Value) + ';';
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', '5;1;');
        Observer.Verify();
    end;
}
