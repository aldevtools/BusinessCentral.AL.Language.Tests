codeunit 90434 "LT UM Ay Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Ay', 'OnInstallAppPerCompany');
    end;
    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Ay', 'OnInstallAppPerDatabase');
    end;
}
