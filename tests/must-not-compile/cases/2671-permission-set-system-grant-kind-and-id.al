// @expect AL0195 | Invalid permission kind. Expected: 'X'
// @expect AL0195 | Invalid permission kind. Expected: 'X'
// @expect AL0653 | Ids are not supported as object reference.
// A system grant takes only X (RIMD and the lower case read kind r are refused) and names the system object (the id is refused). With
// the valid forms (`system "Tools, Security, Roles" = X` and `= x`) the set compiles (tests/al-language/permissions/lt-y69-moved-system/Y69PermSets.al).
permissionset 59671 "MNC Y69 PS 2671 A"
{
    Assignable = true;
    Permissions = system "Tools, Security, Roles" = RIMD;
}

permissionset 59672 "MNC Y69 PS 2671 B"
{
    Assignable = true;
    Permissions = system "Tools, Security, Roles" = r;
}

permissionset 59673 "MNC Y69 PS 2671 C"
{
    Assignable = true;
    Permissions = system 5810 = X;
}
