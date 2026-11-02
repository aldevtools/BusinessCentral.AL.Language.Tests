// Install-order probe of cross-app fixture A (writer Y8, al-runtime-rs docs/probes-needed.md install-order leftovers).
// Each of the fixtures A, D and B logs, from its OnInstallAppPerDatabase trigger, which rows of table 61180 it sees, and then writes its own row
// with Insert(true). Fixture B's table extension of 61180 (Y8XbInstallOrder.al) appends '+BX' to Note in OnBeforeInsert, so a row's Note shows
// whether B's extension trigger ran when that row was written. D does not depend on B and B does not depend on D (no dependency path).
// The test "LT Y8 Install Order Tests" (91420, tests/al-language/install/lt-y8-install-order/) reads the rows back.
// Install code must never fail (check-install-triggers.py): every write is `if Insert(..) then;` into a DataPerCompany = false table, and the only
// trigger that runs on these inserts (B's OnBeforeInsert) only appends text.

table 61180 "LT Y8 XA Data"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61181 "LT Y8 XA Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; App; Text[10]) { }
        field(3; Seen; Text[250]) { }
    }

    keys { key(PK; Seq) { Clustered = true; } }
}

codeunit 61182 "LT Y8 XA Install Helper"
{
    procedure SeenRows(): Text
    var
        Data: Record "LT Y8 XA Data";
        Result: Text;
    begin
        if Data.FindSet() then
            repeat
                Result += Format(Data."No.") + '=' + Data.Note + ';';
            until Data.Next() = 0;
        exit(Result);
    end;

    procedure LogAndWrite(App: Text; RowNo: Integer)
    var
        Log: Record "LT Y8 XA Install Log";
        Data: Record "LT Y8 XA Data";
    begin
        Log.Init();
        Log.App := CopyStr(App, 1, MaxStrLen(Log.App));
        Log.Seen := CopyStr(SeenRows(), 1, MaxStrLen(Log.Seen));
        if Log.Insert() then;
        Data.Init();
        Data."No." := RowNo;
        Data.Note := CopyStr(App, 1, 10);
        if Data.Insert(true) then;
    end;
}

codeunit 61183 "LT Y8 XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Helper: Codeunit "LT Y8 XA Install Helper";
    begin
        Helper.LogAndWrite('A', 1);
    end;
}
