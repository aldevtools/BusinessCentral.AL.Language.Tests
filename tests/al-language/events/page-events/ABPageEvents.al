// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), ABPageEventFixtures.al
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: what the page trigger events do around the page's own triggers: order against the trigger, the arguments (Rec, xRec, BelowxRec),
// the allow flag a subscriber can clear (insert, modify, close), the order of several subscribers, and that a TestPage raises them.
