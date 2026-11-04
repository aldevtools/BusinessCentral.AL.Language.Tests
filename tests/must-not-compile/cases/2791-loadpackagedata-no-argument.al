// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'TableNo' of 'LoadPackageData(Integer)'
// NavApp.LoadPackageData needs the table number.
codeunit 50000 "MNC Y85 LoadPackageData"
{
    procedure P()
    var
        Cust: Record Customer;
        Id: Integer;
    begin
        NavApp.LoadPackageData();
    end;
}
