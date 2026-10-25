// @expect AL0305 | The length of the application object identifier 'MNC SH Name Length Pr' cannot exceed 20 characters.
// A permission set whose name has 21 characters: the limit for permission sets is 20 (20 compiles).
permissionset 50001 "MNC SH Name Length Pr"
{
    Assignable = true;
}
