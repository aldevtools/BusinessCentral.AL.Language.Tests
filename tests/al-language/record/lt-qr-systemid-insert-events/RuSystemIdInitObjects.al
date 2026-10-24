// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope
// Fixtures used: own objects 88660 - 88662 (writer RU); tests in QrSystemIdTests.al (codeunit 87289, the RU_* tests)
// Objects (AL Runner issue 5803): a table whose OnInsert trigger calls Init(), or Clear(SystemId), when the state codeunit's mode asks for it,
//   and notes Rec.SystemId and Rec.Note before and after; a manual subscriber codeunit that calls Rec.Init() in OnBeforeInsertEvent or
//   OnAfterInsertEvent. Mode 0 does nothing.
// BC versions: 27, 28, 29

table 88660 "LT RU Init Row"
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
        State: Codeunit "LT RU Init State";
    begin
        case State.Mode() of
            1:
                begin
                    State.NoteBefore(SystemId, Note);
                    Init();
                    State.NoteAfter(SystemId, Note);
                end;
            2:
                begin
                    State.NoteBefore(SystemId, Note);
                    Clear(SystemId);
                    State.NoteAfter(SystemId, Note);
                end;
        end;
    end;
}

codeunit 88661 "LT RU Init Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT RU Init Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "LT RU Init Row"; RunTrigger: Boolean)
    var
        State: Codeunit "LT RU Init State";
    begin
        if State.Mode() <> 3 then
            exit;
        State.NoteBefore(Rec.SystemId, Rec.Note);
        Rec.Init();
        State.NoteAfter(Rec.SystemId, Rec.Note);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT RU Init Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "LT RU Init Row"; RunTrigger: Boolean)
    var
        State: Codeunit "LT RU Init State";
    begin
        if State.Mode() <> 4 then
            exit;
        State.NoteBefore(Rec.SystemId, Rec.Note);
        Rec.Init();
        State.NoteAfter(Rec.SystemId, Rec.Note);
    end;
}

codeunit 88662 "LT RU Init State"
{
    SingleInstance = true;

    var
        CurrentMode: Integer;
        IdBefore: Guid;
        IdAfter: Guid;
        NoteBeforeText: Text;
        NoteAfterText: Text;

    procedure Arm(NewMode: Integer)
    var
        Empty: Guid;
    begin
        CurrentMode := NewMode;
        IdBefore := Empty;
        IdAfter := Empty;
        NoteBeforeText := '<not run>';
        NoteAfterText := '<not run>';
    end;

    procedure Disarm()
    begin
        CurrentMode := 0;
    end;

    procedure Mode(): Integer
    begin
        exit(CurrentMode);
    end;

    procedure NoteBefore(Id: Guid; NoteValue: Text)
    begin
        IdBefore := Id;
        NoteBeforeText := NoteValue;
    end;

    procedure NoteAfter(Id: Guid; NoteValue: Text)
    begin
        IdAfter := Id;
        NoteAfterText := NoteValue;
    end;

    procedure GetIdBefore(): Guid
    begin
        exit(IdBefore);
    end;

    procedure GetIdAfter(): Guid
    begin
        exit(IdAfter);
    end;

    procedure GetNoteBefore(): Text
    begin
        exit(NoteBeforeText);
    end;

    procedure GetNoteAfter(): Text
    begin
        exit(NoteAfterText);
    end;
}
