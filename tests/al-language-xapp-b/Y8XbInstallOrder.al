// Install-order probe of cross-app fixture B (writer Y8): a table extension of fixture A's table 61180 whose OnBeforeInsert appends '+BX' to Note,
// and an install codeunit that logs which rows of 61180 it sees during its own install, then writes row 20 with Insert(true).
// See tests/al-language-xapp-a/Y8XaInstallOrder.al. Install code must never fail: the helper writes only `if Insert(..) then;` into
// DataPerCompany = false tables, and the trigger below only appends text (Note is Text[50], the longest value is 'B+BX').

tableextension 61185 "LT Y8 XB Data Ext" extends "LT Y8 XA Data"
{
    fields
    {
        field(61185; "Y8 XB Mark"; Text[10])
        {
            DataClassification = SystemMetadata;
            InitValue = 'B init';
        }
    }

    trigger OnBeforeInsert()
    begin
        Rec.Note := CopyStr(Rec.Note + '+BX', 1, MaxStrLen(Rec.Note));
    end;
}

codeunit 61186 "LT Y8 XB Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Helper: Codeunit "LT Y8 XA Install Helper";
    begin
        Helper.LogAndWrite('B', 20);
    end;
}

// Writer Y64 (al-runner issue 6644): install code of B arms fixture A's hub 61351, raises its event and logs telemetry (Probe), as D's install
// does (tests/al-language-xapp-d/Y8XdInstallOrder.al). Install code must never fail: the only write is `if Insert() then;` into the
// DataPerCompany = false table 61354.
codeunit 61356 "LT Y64 XB Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        Hub.Probe('B', 'db');
    end;

    trigger OnInstallAppPerCompany()
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        Hub.Probe('B', 'co');
    end;
}
