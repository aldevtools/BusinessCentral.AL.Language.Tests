// @expect AL0720 | An application object 'Table 18' could not be found in the current extension
// InherentPermissions on a procedure may name only table data of the extension that declares the procedure; Customer belongs to Base Application.
codeunit 50000 "MNC Y90 Inherent Base Table"
{
    [InherentPermissions(PermissionObjectType::TableData, Database::Customer, 'R')]
    procedure P()
    begin
    end;
}
