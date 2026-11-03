// @expect AL0122 | Cannot implicitly convert type 'None' to 'Integer'. Use an explicit conversion or change the type.
// NavApp.LoadPackageData returns nothing.
codeunit 50000 "MNC Y85 LoadPackageData"
{
    procedure P()
    var
        Cust: Record Customer;
        Id: Integer;
    begin
        Id := NavApp.LoadPackageData(18);
    end;
}
