// @expect AL0393 | Application object "Tools, Security, Roles" is already referenced
// @expect AL0393 | Application object "Tools, Security, Roles" is already referenced
// The same system object twice in one permission set (also with X and a lower case x): both entries are reported.
permissionset 59675 "MNC Y69 PS 2673"
{
    Assignable = true;
    Permissions = system "Tools, Security, Roles" = X,
                  system "Tools, Security, Roles" = x;
}
