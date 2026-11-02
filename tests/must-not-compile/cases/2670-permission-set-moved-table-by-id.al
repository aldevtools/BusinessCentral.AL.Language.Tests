// @expect AL0653 | Ids are not supported as object reference.
// @expect AL0653 | Ids are not supported as object reference.
// A permission set names a table by id: not allowed for any table, also not for tables that BC 29 ships twice under one id (Reason Code 231 and
// Source Code 230 are declared in the Base Application with ObsoleteState = Moved and in Business Foundation). The name form compiles
// (tests/al-language/permissions/lt-y69-moved-system/Y69PermSets.al).
permissionset 59670 "MNC Y69 PS 2670"
{
    Assignable = true;
    Permissions = tabledata 230 = RIMD,
                  table 242 = X;
}
