// @expect AL0133 | Argument 1: cannot convert from 'Record Customer' to 'Integer'
// NavApp.LoadPackageData takes the table number, not a record variable.
codeunit 50000 "MNC Y85 LoadPackageData"
{
    procedure P()
    var
        Cust: Record Customer;
        Id: Integer;
    begin
        NavApp.LoadPackageData(Cust);
    end;
}
