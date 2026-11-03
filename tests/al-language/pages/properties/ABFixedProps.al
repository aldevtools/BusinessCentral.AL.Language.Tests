// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), page "LT AB Fixed Props" (77012), page "LT AB Fixed Tree List" (77015), ABGroupFixtures.al
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: Editable, Enabled and Visible of a fixed (true, false, an expression) as a TestPage sees them on the field inside; input on a non-editable field;
// ShowAsTree and FileUploadAction on a fixed (compile, and a TestPage still lists every row).
// The other repeater-only properties are refused on a fixed: must-not-compile cases in 0920 to 0946.
