// @expect AL0264 | An application object of type 'PermissionSetExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'PermissionSetExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two permission set extensions with the same id.
permissionset 50000 "MNC SH PS"
{
    Assignable = true;
}

permissionsetextension 50001 "MNC SH PSX A" extends "MNC SH PS"
{
}

permissionsetextension 50001 "MNC SH PSX B" extends "MNC SH PS"
{
}
