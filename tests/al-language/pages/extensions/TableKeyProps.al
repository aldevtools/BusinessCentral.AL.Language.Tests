// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72277, codeunit 72278
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72277 "LT P123 TKey"
{
    DataClassification = SystemMetadata;
    Caption = 'P123 table caption', Locked = true;

    fields
    {
        field(1; Id; Integer) { Caption = 'Id field', Locked = true; }
        field(2; Name; Text[30]) { Caption = 'Name field'; }
        field(3; Amount; Decimal) { Caption = 'Amount field', Locked = true; }
        field(4; Code10; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Name) { IncludedFields = Amount; MaintainSQLIndex = false; }
        key(K3; Amount) { IncludedFields = Name, Code10; }
    }
}

codeunit 72278 "LT P123 Table Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        T: Record "LT P123 TKey";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.Name := 'Charlie'; T.Amount := 30; T.Code10 := 'C'; T.Insert();
        T.Init(); T.Id := 2; T.Name := 'Alpha'; T.Amount := 20; T.Code10 := 'A'; T.Insert();
        T.Init(); T.Id := 3; T.Name := 'Bravo'; T.Amount := 10; T.Code10 := 'B'; T.Insert();
    end;

    [Test]
    procedure P123_TableCaptionsLocked()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 TKey";
    begin
        Seed();
        Observer.Observe('tablecaption', T.TableCaption());
        Observer.Observe('cap id', T.FieldCaption(Id));
        Observer.Observe('cap name', T.FieldCaption(Name));
        Observer.Observe('cap amount', T.FieldCaption(Amount));
        Observer.Observe('cap code10', T.FieldCaption(Code10));
        Observer.Expect('tablecaption', 'P123 table caption');
        Observer.Expect('cap id', 'Id field');
        Observer.Expect('cap name', 'Name field');
        Observer.Expect('cap amount', 'Amount field');
        Observer.Expect('cap code10', 'Code10');
        Observer.Verify();
    end;

    [Test]
    procedure P123_KeyOrderWithIncludedFieldsAndNoSqlIndex()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 TKey";
        Names: Text;
    begin
        Seed();
        T.SetCurrentKey(Name);
        T.FindSet();
        repeat
            Names += T.Name + ',';
        until T.Next() = 0;
        Observer.Observe('order by K2 (MaintainSQLIndex false)', Names);
        Observer.Observe('current key K2', T.CurrentKey());
        Names := '';
        T.Reset();
        T.SetCurrentKey(Amount);
        T.FindSet();
        repeat
            Names += T.Name + ',';
        until T.Next() = 0;
        Observer.Observe('order by K3 (IncludedFields)', Names);
        Observer.Observe('current key K3', T.CurrentKey());
        T.Reset();
        T.SetCurrentKey(Name);
        T.SetRange(Name, 'Bravo');
        T.FindFirst();
        Observer.Observe('filter K2 included amount', Format(T.Amount));
        T.Reset();
        T.SetCurrentKey(Amount);
        T.SetFilter(Amount, '>=20');
        Observer.Observe('count K3 amount>=20', Format(T.Count()));
        T.SetRange(Amount, 10);
        T.FindFirst();
        Observer.Observe('K3 included code10', T.Code10);
        Observer.Expect('order by K2 (MaintainSQLIndex false)', 'Alpha,Bravo,Charlie,');
        Observer.Expect('current key K2', 'Name field');
        Observer.Expect('order by K3 (IncludedFields)', 'Bravo,Alpha,Charlie,');
        Observer.Expect('current key K3', 'Amount field');
        Observer.Expect('filter K2 included amount', '10');
        Observer.Expect('count K3 amount>=20', '2');
        Observer.Expect('K3 included code10', 'B');
        Observer.Verify();
    end;
}
