codeunit 90435 "LT UM Zz Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Zz', 'OnInstallAppPerCompany');
    end;
    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Zz', 'OnInstallAppPerDatabase');
    end;
}
