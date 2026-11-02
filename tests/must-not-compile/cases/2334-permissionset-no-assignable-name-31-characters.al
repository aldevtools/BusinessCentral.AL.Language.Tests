// @expect AL0305 | The length of the application object identifier 'MNC Y12 No Assignable Prop 31ch' cannot exceed 30 characters.
// A permission set with no Assignable property whose name has 31 characters: the limit is 30, not the 20 of Assignable = true (case 2131).
// 21 to 30 characters compile: tests/al-language/permissions/lt-y12-permset-name-length/Y12PermSetNames.al. al-runner issue 6445, writer Y12.
// Recorded with AL 30.0.42.60748.
permissionset 50000 "MNC Y12 No Assignable Prop 31ch"
{
}
