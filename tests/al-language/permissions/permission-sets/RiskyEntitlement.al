// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY, compile-only: entitlement objects (Id, Type, ObjectEntitlements) have no runtime
// observable in a test; the declared objects are reached statically, the test only proves the app compiled and ran.

permissionset 70477 "LT P116 Ent Perm Set"
{
    Assignable = true;
    Permissions = tabledata "LT P116 Ent Table" = R;
}

table 70478 "LT P116 Ent Table"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

entitlement "LT P116 Implicit Ent"
{
    Type = Implicit;
    ObjectEntitlements = "LT P116 Ent Perm Set";
}

codeunit 70479 "LT P116 Entitlement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P116_EntitlementDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P116 Ent Table";
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row.Insert();
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('count', '1');
        Observer.Verify();
    end;
}
