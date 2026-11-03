// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72282, codeunit 72283
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72282 "LT P123 SqlIdx"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Name, Amount) { SqlIndex = Amount, Name; }
    }
}

codeunit 72283 "LT P123 SqlIndex Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_SqlIndexDeclared()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 SqlIdx";
        Names: Text;
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.Name := 'B'; T.Amount := 1; T.Insert();
        T.Init(); T.Id := 2; T.Name := 'A'; T.Amount := 2; T.Insert();
        T.Init(); T.Id := 3; T.Name := 'A'; T.Amount := 1; T.Insert();
        T.SetCurrentKey(Name, Amount);
        T.FindSet();
        repeat
            Names += Format(T.Id) + ',';
        until T.Next() = 0;
        Observer.Observe('order by K2', Names);
        Observer.Expect('order by K2', '3,2,1,');
        Observer.Verify();
    end;
}
