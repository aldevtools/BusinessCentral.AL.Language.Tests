codeunit 90431 "LT UM Mu Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Mu', 'OnInstallAppPerCompany');
    end;
    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Mu', 'OnInstallAppPerDatabase');
    end;
}
