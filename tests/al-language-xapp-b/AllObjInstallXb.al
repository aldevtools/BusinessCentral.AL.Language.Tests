// Probe of what AllObj and AllObjWithCaption show during the install of another app (al-runner issues 8954 and 6924): the install code of B runs
// the probe of fixture A's hub 94693, per database and per company (see tests/al-language-xapp-a/AllObjInstallXa.al). The table below is the
// object the install code of A and D looks up in AllObj. Install code must never fail: the hub reads in TryFunctions and writes only
// `if Insert() then;` into a DataPerCompany = false table.
// local object: the test asserts whether AllObj shows this table of B during the install of another app.

table 61386 "INS AllObj Inst XB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 61385 "INS AllObj Inst XB Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Hub: Codeunit "INS AllObj Inst Hub";
    begin
        Hub.Probe('B', 'db');
    end;

    trigger OnInstallAppPerCompany()
    var
        Hub: Codeunit "INS AllObj Inst Hub";
    begin
        Hub.Probe('B', 'co');
    end;
}
