// Cross-app fixture A (al-runner issue 8696, login without a dependency): a SingleInstance codeunit with globals, like
// Microsoft's Backup Management (codeunit 130011), whose own subscribers of GlobalTriggerManagement change them. XApp E's
// OnAfterLogin subscriber (tests/al-language-xapp-e/SirNdLoginSubs.al) reads table 98032 and reads and writes table 98033;
// XApp E does not depend on this app. It sets the insert and modify flags for table 98033 only and leaves every other table's
// flags as it got them. The globals are read by one test codeunit only: tests/al-language/codeunits/SirLoginNoDep.al.
codeunit 98496 "SIR ND XA Trigger State"
{
    SingleInstance = true;

    var
        ReadSetups: Integer;
        WriteSetups: Integer;
        Writes: Integer;
        Txt: Text;
        Names: List of [Text];
        SawWrite: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        case TableId of
            98032:
                begin
                    ReadSetups += 1;
                    Txt += 'R';
                    Names.Add('r');
                end;
            98033:
                begin
                    WriteSetups += 1;
                    Txt += 'S';
                    Names.Add('s');
                    OnDatabaseInsert := true;
                    OnDatabaseModify := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        if RecRef.Number = 98033 then
            CountWrite();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure AfterModify(RecRef: RecordRef)
    begin
        if RecRef.Number = 98033 then
            CountWrite();
    end;

    local procedure CountWrite()
    begin
        Writes += 1;
        Txt += 'W';
        SawWrite := true;
    end;

    procedure GetReadSetups(): Integer
    begin
        exit(ReadSetups);
    end;

    procedure GetWriteSetups(): Integer
    begin
        exit(WriteSetups);
    end;

    procedure GetWrites(): Integer
    begin
        exit(Writes);
    end;

    procedure SetWrites(NewWrites: Integer)
    begin
        Writes := NewWrites;
    end;

    procedure GetTxt(): Text
    begin
        exit(Txt);
    end;

    procedure SetTxt(NewTxt: Text)
    begin
        Txt := NewTxt;
    end;

    procedure GetNames(): List of [Text]
    begin
        exit(Names);
    end;

    procedure AddName(Name: Text)
    begin
        Names.Add(Name);
    end;

    procedure NameCount(): Integer
    begin
        exit(Names.Count());
    end;

    procedure GetSawWrite(): Boolean
    begin
        exit(SawWrite);
    end;

    procedure SetSawWrite(NewSawWrite: Boolean)
    begin
        SawWrite := NewSawWrite;
    end;
}
