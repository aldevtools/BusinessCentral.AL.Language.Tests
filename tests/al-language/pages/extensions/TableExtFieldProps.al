// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own tables 72296 and 72297, tableextension 72298, codeunit 72299
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72296 "LT P123 ExtBase"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72297 "LT P123 Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code10; Code[10]) { }
    }

    keys
    {
        key(PK; Code10) { Clustered = true; }
    }
}

tableextension 72298 "LT P123 ExtBase Ext" extends "LT P123 ExtBase"
{
    fields
    {
        field(72300; OptExt; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = ,Red,Green,Blue;
            OptionCaption = ',Rot,Gruen,Blau';
        }
        field(72301; RelNoValidate; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = "LT P123 Rel";
            ValidateTableRelation = false;
        }
        field(72302; RelValidate; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = "LT P123 Rel";
        }
    }
}

codeunit 72299 "LT P123 TableExt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ExtOptionMembers()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 ExtBase";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1;
        Observer.Observe('default', Format(T.OptExt));
        T.OptExt := T.OptExt::Green;
        Observer.Observe('green', Format(T.OptExt));
        Observer.Observe('green int', Format(T.OptExt, 0, 2));
        T.Validate(OptExt, 3);
        Observer.Observe('blue', Format(T.OptExt));
        Evaluate(T.OptExt, 'Red');
        Observer.Observe('evaluate Red', Format(T.OptExt));
        Observer.Observe('evaluate caption Rot', Format(Evaluate(T.OptExt, 'Rot')));
        T.Validate(OptExt, 4);
        Observer.Observe('out of range', 'no error');
        T.Insert();
        T.SetRange(OptExt, T.OptExt::Red);
        Observer.Observe('filter red count', Format(T.Count()));
        Observer.Expect('default', '0');
        Observer.Expect('green', 'Gruen');
        Observer.Expect('green int', '2');
        Observer.Expect('blue', 'Blau');
        Observer.Expect('evaluate Red', 'Rot');
        Observer.Expect('evaluate caption Rot', 'Yes');
        Observer.Expect('out of range', 'no error');
        Observer.Expect('filter red count', '0');
        Observer.Verify();
    end;
}
