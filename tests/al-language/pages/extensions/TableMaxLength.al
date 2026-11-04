// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72287, codeunit 72288
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72287 "LT P123 MaxLen"
{
    DataClassification = SystemMetadata;
    Caption = 'Max length caption', MaxLength = 40;

    fields
    {
        field(1; Id; Integer) { Caption = 'Id caption', MaxLength = 20; }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72288 "LT P123 MaxLen Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_MaxLengthCaptions()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 MaxLen";
    begin
        Observer.Observe('table caption', T.TableCaption());
        Observer.Observe('id caption', T.FieldCaption(Id));
        Observer.Expect('table caption', 'Max length caption');
        Observer.Expect('id caption', 'Id caption');
        Observer.Verify();
    end;
}
