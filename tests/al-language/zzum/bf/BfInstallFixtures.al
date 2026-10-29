codeunit 90432 "LT UM b Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('b', 'OnInstallAppPerCompany');
    end;
    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('b', 'OnInstallAppPerDatabase');
    end;
}
