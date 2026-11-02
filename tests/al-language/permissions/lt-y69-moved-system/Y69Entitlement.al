// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entitlement-object
// Scope: in-scope
// Probe (writer Y69, al-runner issue 6716): an entitlement over a permission set that names tables BC 29 ships twice under one id (see Y69PermSets.al).
//   Kept in its own file: on the SaaS sandbox an app with an entitlement licenses only the objects of the entitled permission sets, so a slice
//   of the corpus that holds this file cannot run its test codeunits there.

// Compile-only: an entitlement over a set that names moved tables (entitlements have no runtime observable in a test).
entitlement "LT Y69 MV Ent"
{
    Type = Implicit;
    ObjectEntitlements = "LT Y69 MV All";
}
