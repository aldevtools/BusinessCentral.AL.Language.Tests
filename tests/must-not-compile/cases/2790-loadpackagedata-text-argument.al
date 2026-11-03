// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// NavApp.LoadPackageData takes the table number as an Integer.
codeunit 50000 "MNC Y85 LoadPackageData"
{
    procedure P()
    var
        Cust: Record Customer;
        Id: Integer;
    begin
        NavApp.LoadPackageData('abc');
    end;
}
