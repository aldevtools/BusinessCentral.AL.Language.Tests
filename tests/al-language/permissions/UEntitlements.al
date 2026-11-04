// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entitlement-object
// Scope: in-scope
// Fixtures used: permission set "LT P116 Ent Perm Set" (70477)
// Probe (issue 601.19): entitlement objects with Id, RoleType and GroupName. Compile-only, like misc/lt-permissions-mock-indirect/RiskyEntitlement.al: AL code cannot read an entitlement
// at run time. The invalid combinations are must-not-compile cases (AL0674, AL0223, AL0169). RISKY: the platform has to accept the objects when the app is published.

entitlement "LT U Ent Concurrent"
{
    Type = ConcurrentUserServicePlan;
    Id = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5fb';
    GroupName = 'LT U Group';
    ObjectEntitlements = "LT P116 Ent Perm Set";
}

entitlement "LT U Ent Per User"
{
    Type = PerUserServicePlan;
    Id = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5fc';
    ObjectEntitlements = "LT P116 Ent Perm Set";
}

entitlement "LT U Ent Role Local"
{
    Type = Role;
    Id = 'D365 BUS FULL ACCESS';
    RoleType = Local;
    ObjectEntitlements = "LT P116 Ent Perm Set";
}

entitlement "LT U Ent Role Delegated"
{
    Type = Role;
    Id = 'D365 BASIC';
    RoleType = Delegated;
    ObjectEntitlements = "LT P116 Ent Perm Set";
}
