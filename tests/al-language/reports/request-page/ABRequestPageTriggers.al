// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); reports 77070-77073 (ABRequestPageFixtures.al, ABRequestPageExt.al); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), codeunit "LT AB Log" (77050)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: which request page triggers fire when a report runs with a request page handler (OK, Cancel, a veto in OnQueryClosePage), in which order against the
// base page, the extension and the report triggers; and what Report.Run does when no request page handler exists.
