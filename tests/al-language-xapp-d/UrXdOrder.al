// Subscriber order across 65536-wide object id blocks (writer UR; al-runner NP Retail install order, ADR-046 probe Q1 follow-up).
// Eight subscriber codeunits of this app subscribe to the two "Extension Triggers" install events and to one ordinary event of this app
// ("LT UR XD Publisher".OnUrOrder). Their ids lie in five blocks of 65536 ids (block = id div 65536), so that each candidate rule predicts
// another order (ids, tag = id):
//   id       block  id mod 65536  name          declared here
//   61163    0      61163         LT UR XD S5   3rd
//   61167    0      61167         LT UR XD S2   6th
//   120000   1      54464         LT UR XD S7   1st
//   150100   2      19028         LT UR XD S1   8th
//   196000   2      64928         LT UR XD S8   7th
//   1000000  15     16960         LT UR XD S4   4th
//   6014438  91     50662         LT UR XD S6   5th
//   6059909  92     30597         LT UR XD S3   2nd
// Install code must never fail: every write is `if Insert() then;` into a DataPerCompany = false table.
// Tests: tests/al-language/install/lt-ur-block-order/UrBlockOrderTests.al (they read the log through RecordRef: the main app does not
// depend on this app directly).

table 61164 "LT UR XD Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Routine; Text[250]) { }
        field(3; Part; Text[30]) { }
        field(4; Company; Text[60]) { }
        field(5; "Session Id"; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Add(RoutineText: Text; PartName: Text)
    var
        Row: Record "LT UR XD Log";
    begin
        Row.Init();
        Row.Routine := CopyStr(RoutineText, 1, MaxStrLen(Row.Routine));
        Row.Part := CopyStr(PartName, 1, MaxStrLen(Row.Part));
        Row.Company := CopyStr(CompanyName(), 1, MaxStrLen(Row.Company));
        Row."Session Id" := SessionId();
        if Row.Insert() then;
    end;
}

// Codeunit.Run raises OnUrOrder twice and writes both orders as one row (Part 'event').
codeunit 61165 "LT UR XD Publisher"
{
    trigger OnRun()
    var
        Log: Record "LT UR XD Log";
        First: Text;
        Second: Text;
    begin
        OnUrOrder(First);
        OnUrOrder(Second);
        Log.Add(First + '|' + Second, 'event');
    end;

    [IntegrationEvent(false, false)]
    procedure OnUrOrder(var Log: Text)
    begin
    end;
}

codeunit 120000 "LT UR XD S7"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('120000', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('120000', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '120000;';
    end;
}

codeunit 6059909 "LT UR XD S3"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('6059909', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('6059909', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '6059909;';
    end;
}

codeunit 61163 "LT UR XD S5"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('61163', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('61163', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '61163;';
    end;
}

codeunit 1000000 "LT UR XD S4"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('1000000', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('1000000', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '1000000;';
    end;
}

codeunit 6014438 "LT UR XD S6"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('6014438', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('6014438', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '6014438;';
    end;
}

codeunit 61167 "LT UR XD S2"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('61167', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('61167', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '61167;';
    end;
}

codeunit 196000 "LT UR XD S8"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('196000', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('196000', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '196000;';
    end;
}

codeunit 150100 "LT UR XD S1"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure OnInstallAppPerCompany()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('150100', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure OnInstallAppPerDatabase()
    var
        Log: Record "LT UR XD Log";
    begin
        Log.Add('150100', 'database');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT UR XD Publisher", 'OnUrOrder', '', false, false)]
    local procedure OnUrOrder(var Log: Text)
    begin
        Log += '150100;';
    end;
}
