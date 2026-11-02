// @expect AL0305 | The length of the application object identifier 'MNC Y12 Not Assignable 31 chars' cannot exceed 30 characters.
// A permission set with Assignable = false whose name has 31 characters. With Assignable = false the limit is 30 (21 to 30 compile:
// tests/al-language/permissions/lt-y12-permset-name-length/Y12PermSetNames.al); with Assignable = true it is 20 (case 2131).
// al-runner issue 6445, writer Y12. Recorded with AL 30.0.42.60748.
permissionset 50000 "MNC Y12 Not Assignable 31 chars"
{
    Assignable = false;
}
