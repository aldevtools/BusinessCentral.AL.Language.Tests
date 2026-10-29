codeunit 90433 "LT UM Cu Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Cu', 'OnInstallAppPerCompany');
    end;
    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Cu', 'OnInstallAppPerDatabase');
    end;
}
