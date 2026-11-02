// @expect AL0720 | An application object 'Table 231' could not be found in the current extension. Only application objects that belong to the current extensions can be used in this context.
// @expect AL0720 | An application object 'Table 18' could not be found in the current extension. Only application objects that belong to the current extensions can be used in this context.
// InherentPermissions names a table of another app: refused, for a moved table (Reason Code 231, Base Application and Business Foundation) and for any other
// (Customer 18). A permission set or the Permissions property can name them (tests/al-language/permissions/lt-y69-moved-system/Y69PermSets.al).
codeunit 59676 "MNC Y69 CU 2674"
{
    [InherentPermissions(PermissionObjectType::TableData, Database::"Reason Code", 'R')]
    procedure A()
    begin
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::Customer, 'R')]
    procedure B()
    begin
    end;
}
