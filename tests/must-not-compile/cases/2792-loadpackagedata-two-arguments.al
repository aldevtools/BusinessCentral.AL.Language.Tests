// @expect AL0126 | No overload for method 'LoadPackageData' takes 2 arguments. Candidates: built-in method 'LoadPackageData(Integer)'
// NavApp.LoadPackageData takes exactly one argument.
codeunit 50000 "MNC Y85 LoadPackageData"
{
    procedure P()
    var
        Cust: Record Customer;
        Id: Integer;
    begin
        NavApp.LoadPackageData(Database::Customer, true);
    end;
}
