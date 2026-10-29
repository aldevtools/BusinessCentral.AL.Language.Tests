// Fixtures of the id block order probe (writer UR; tests: UrBlockOrderTests.al). Four subscriber codeunits of this app subscribe to the
// two "Extension Triggers" install events and to one ordinary event of this app ("LT UR Publisher".OnUrOrder). Two of them lie in id
// block 0 (ids below 65536), two in block 1. Names and declaration order are mixed so that name order and file order differ from id order:
//   id     block  id mod 65536  name                declared here
//   50300  0      50300         LT UR M Sub Zeta    4th
//   50301  0      50301         LT UR M Sub Alpha   2nd
//   90511  1      24975         LT UR M Sub Mid     3rd
//   90512  1      24976         LT UR M Sub Beta    1st
// Two install codeunits of this app also log: "LT UR Install Low" 50302 (_fixtures/ALTInstallProbe.al) and "LT UR Install High" 90515
// (types/TestBlankEnumInitInstaller.Codeunit.al), appended to files check-install-triggers.py allows.
// Install code must never fail: every write is `if Insert() then;` into a DataPerCompany = false table.

table 90513 "LT UR Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Routine; Text[30]) { }
        field(3; Part; Text[30]) { }
        field(4; Company; Text[60]) { }
        field(5; "Session Id"; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Add(RoutineText: Text; PartName: Text)
    var
        Row: Record "LT UR Install Log";
    begin
        Row.Init();
        Row.Routine := CopyStr(RoutineText, 1, MaxStrLen(Row.Routine));
        Row.Part := CopyStr(PartName, 1, MaxStrLen(Row.Part));
        Row.Company := CopyStr(CompanyName(), 1, MaxStrLen(Row.Company));
        Row."Session Id" := SessionId();
        if Row.Insert() then;
    end;
}

codeunit 90514 "LT UR Publisher"
{
    procedure Raise(): Text
    var
        Log: Text;
    begin
        OnUrOrder(Log);
        exit(Log);
    end;

    [IntegrationEvent(false, false)]
    procedure OnUrOrder(var Log: Text)
    begin
    end;
}

codeunit 90512 "LT UR M Sub Beta"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S90512', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S90512', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '90512;';
    end;
}

codeunit 50301 "LT UR M Sub Alpha"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S50301', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S50301', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '50301;';
    end;
}

codeunit 90511 "LT UR M Sub Mid"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S90511', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S90511', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '90511;';
    end;
}

codeunit 50300 "LT UR M Sub Zeta"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S50300', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('S50300', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '50300;';
    end;
}
