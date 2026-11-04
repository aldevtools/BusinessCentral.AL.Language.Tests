// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: own objects 87285 - 87288 (writer QR); tests in QrSystemIdTests.al (codeunit 87289)
// Objects: a table whose OnInsert, and a table extension whose OnBeforeInsert, OnInsert and OnAfterInsert triggers, set SystemId to the
//   value the state codeunit holds when its mode asks for it; a manual subscriber codeunit that does the same in OnBeforeInsertEvent and
//   OnAfterInsertEvent. Mode 0 sets nothing.
// BC versions: 27, 28, 29

table 87285 "LT QR Sys Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        State: Codeunit "LT QR Sys State";
    begin
        if State.Mode() = 5 then
            SystemId := State.Wanted();
    end;
}

tableextension 87286 "LT QR Sys Row Ext" extends "LT QR Sys Row"
{
    trigger OnBeforeInsert()
    var
        State: Codeunit "LT QR Sys State";
    begin
        if State.Mode() = 1 then
            Rec.SystemId := State.Wanted();
    end;

    trigger OnInsert()
    var
        State: Codeunit "LT QR Sys State";
    begin
        if State.Mode() = 2 then
            Rec.SystemId := State.Wanted();
    end;

    trigger OnAfterInsert()
    var
        State: Codeunit "LT QR Sys State";
    begin
        if State.Mode() = 3 then
            Rec.SystemId := State.Wanted();
    end;
}

codeunit 87287 "LT QR Sys Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT QR Sys Row", OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "LT QR Sys Row"; RunTrigger: Boolean)
    var
        State: Codeunit "LT QR Sys State";
    begin
        if State.Mode() = 6 then
            Rec.SystemId := State.Wanted();
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT QR Sys Row", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "LT QR Sys Row"; RunTrigger: Boolean)
    var
        State: Codeunit "LT QR Sys State";
    begin
        if State.Mode() = 4 then
            Rec.SystemId := State.Wanted();
    end;
}

codeunit 87288 "LT QR Sys State"
{
    SingleInstance = true;

    var
        CurrentMode: Integer;
        WantedId: Guid;

    procedure Arm(NewMode: Integer; NewWanted: Guid)
    begin
        CurrentMode := NewMode;
        WantedId := NewWanted;
    end;

    procedure Mode(): Integer
    begin
        exit(CurrentMode);
    end;

    procedure Wanted(): Guid
    begin
        exit(WantedId);
    end;
}
