// @expect AL0264 | An application object of type 'PermissionSet' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'PermissionSet' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two permission sets with the same id.
permissionset 50001 "MNC SH PS A"
{
    Assignable = true;
}

permissionset 50001 "MNC SH PS B"
{
    Assignable = true;
}
