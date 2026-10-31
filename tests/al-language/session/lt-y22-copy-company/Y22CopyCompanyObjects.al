// Objects of the Database.CopyCompany probes (Y22CopyCompany.al, al-runner issue 6507).
// "LT Y22 Row" is per company; its OnInsert trigger writes to "LT Y22 Log", which, like "LT Y22 Shared", is one table for all companies.
table 92170 "LT Y22 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "By Trigger"; Boolean) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Record "LT Y22 Log";
    begin
        "By Trigger" := true;
        Log.Add('trigger ' + Format(No));
    end;
}

table 92171 "LT Y22 Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Entry No"; Integer) { AutoIncrement = true; }
        field(2; What; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No") { Clustered = true; }
    }

    procedure Add(Value: Text)
    var
        Log: Record "LT Y22 Log";
    begin
        Log.Init();
        Log.What := CopyStr(Value, 1, MaxStrLen(Log.What));
        Log.Insert();
    end;

    // The entries after FromEntry, joined with ';'.
    procedure After(FromEntry: Integer) Result: Text
    var
        Log: Record "LT Y22 Log";
    begin
        Log.SetFilter("Entry No", '>%1', FromEntry);
        if Log.FindSet() then
            repeat
                Result += Log.What + ';';
            until Log.Next() = 0;
    end;

    procedure Last(): Integer
    var
        Log: Record "LT Y22 Log";
    begin
        if Log.FindLast() then
            exit(Log."Entry No");
    end;
}

table 92172 "LT Y22 Shared"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; No; Integer) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

codeunit 92174 "LT Y22 Copy Runner"
{
    var
        SourceName: Text;
        DestinationName: Text;

    procedure Setup(Source: Text; Destination: Text)
    begin
        SourceName := Source;
        DestinationName := Destination;
    end;

    trigger OnRun()
    begin
        Database.CopyCompany(SourceName, DestinationName);
    end;
}

// Bound only around the copy (manual): logs the table events, the database triggers of "LT Y22 Row" and the inserts of Company rows.
codeunit 92175 "LT Y22 Copy Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT Y22 Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure RowAfterInsert(var Rec: Record "LT Y22 Row"; RunTrigger: Boolean)
    var
        Log: Record "LT Y22 Log";
    begin
        Log.Add('event ' + Format(Rec.No) + ' ' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterInsertEvent', '', false, false)]
    local procedure CompanyAfterInsert(var Rec: Record Company; RunTrigger: Boolean)
    var
        Log: Record "LT Y22 Log";
    begin
        Log.Add('company insert ' + Rec.Name);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure TriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId <> Database::"LT Y22 Row" then
            exit;
        OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure DatabaseInsert(RecRef: RecordRef)
    var
        Log: Record "LT Y22 Log";
    begin
        if RecRef.Number <> Database::"LT Y22 Row" then
            exit;
        Log.Add('database insert ' + Format(RecRef.Field(1).Value));
    end;
}
