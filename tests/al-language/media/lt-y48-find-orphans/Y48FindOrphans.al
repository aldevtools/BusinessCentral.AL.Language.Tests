// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-findorphans-method
// Scope: in-scope (Tenant Media and Tenant Media Set are Scope = Cloud)
// Fixtures used: Probe Observer (69160); self-contained objects 92929 - 92931
// Probe: gap cycle 5, spec G5-05 part B (writer Y48). Which media Media.FindOrphans() and MediaSet.FindOrphans() list: a Tenant Media row
//        inserted by AL code that no field holds, Tenant Media Set rows inserted by AL code, held media (a field of an inserted row, a
//        MediaSet item), a media imported into a record that is never inserted or not modified after the import, a cleared field, a
//        media held only by a temporary record. Microsoft's Media Cleanup inserts such detached rows the same way.
//        FindOrphans reads the whole database, which can hold other media: only Contains(<own id>) is observed, never the list or its size.
//        Every write runs in a codeunit of its own (Codeunit.Run). P102MediaOrphans.al pins the attached and the deleted-with-its-record case.
//        Not done: the spec's T6 (a committed detached row seen by a later test): the main suite rolls back per codeunit, not per test.
// BC versions: 27, 28, 29

table 92929 "LT Y48 FO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92930 "LT Y48 FO Step"
{
    var
        Step: Text;
        RowId: Integer;
        MediaGuid: Guid;
        Result: Text;

    procedure SetStep(NewStep: Text; NewRowId: Integer; NewMediaGuid: Guid)
    begin
        Step := NewStep;
        RowId := NewRowId;
        MediaGuid := NewMediaGuid;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    procedure GetMediaGuid(): Guid
    begin
        exit(MediaGuid);
    end;

    local procedure TextStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('orphan probe');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    trigger OnRun()
    var
        TM: Record "Tenant Media";
        TMS: Record "Tenant Media Set";
        Row: Record "LT Y48 FO Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
    begin
        case Step of
            'tm insert':
                begin
                    TM.Init();
                    TM.ID := MediaGuid;
                    TM.Content.CreateOutStream(OutS);
                    OutS.WriteText('orphan probe');
                    Result := Format(TM.Insert());
                end;
            'tm delete':
                begin
                    TM.Get(MediaGuid);
                    Result := Format(TM.Delete());
                end;
            // MediaGuid = the set id; inserts one item, MediaGuid becomes the item's media id
            'tms insert':
                begin
                    TMS.Init();
                    TMS.ID := MediaGuid;
                    TextStream(TempBlob, InS);
                    TMS."Media ID".ImportStream(InS, '');
                    Result := Format(TMS.Insert());
                    MediaGuid := TMS."Media ID".MediaId();
                end;
            'tms delete set':
                begin
                    TMS.SetRange(ID, MediaGuid);
                    TMS.DeleteAll();
                    Result := 'done';
                end;
            'row pic':
                begin
                    Row.Init();
                    Row.Id := RowId;
                    Row.Insert();
                    TextStream(TempBlob, InS);
                    Row.Pic.ImportStream(InS, 'd');
                    Row.Modify();
                    MediaGuid := Row.Pic.MediaId();
                    Result := 'ok';
                end;
            'row pics':
                begin
                    Row.Init();
                    Row.Id := RowId;
                    Row.Insert();
                    TextStream(TempBlob, InS);
                    Row.Pics.ImportStream(InS, 'a');
                    Row.Modify();
                    MediaGuid := Row.Pics.MediaId();
                    Result := 'ok';
                end;
            // import into a record that is never inserted
            'pic no insert':
                begin
                    Row.Init();
                    Row.Id := RowId;
                    TextStream(TempBlob, InS);
                    Row.Pic.ImportStream(InS, 'd');
                    MediaGuid := Row.Pic.MediaId();
                    Result := 'ok';
                end;
            // import into an inserted record, no Modify after it
            'pic no modify':
                begin
                    Row.Init();
                    Row.Id := RowId;
                    Row.Insert();
                    TextStream(TempBlob, InS);
                    Row.Pic.ImportStream(InS, 'd');
                    MediaGuid := Row.Pic.MediaId();
                    Result := 'ok';
                end;
            'clear pic':
                begin
                    Row.Get(RowId);
                    Clear(Row.Pic);
                    Result := Format(Row.Modify());
                end;
            'clear pics':
                begin
                    Row.Get(RowId);
                    Clear(Row.Pics);
                    Result := Format(Row.Modify());
                end;
            'temporary pic':
                begin
                    Row.Reset();
                    TextStream(TempBlob, InS);
                    MediaGuid := TemporaryImport(RowId, InS);
                    Result := 'ok';
                end;
        end;
    end;

    local procedure TemporaryImport(Id: Integer; var InS: InStream): Guid
    var
        TempRow: Record "LT Y48 FO Row" temporary;
    begin
        TempRow.Init();
        TempRow.Id := Id;
        TempRow.Pic.ImportStream(InS, 'd');
        TempRow.Insert();
        exit(TempRow.Pic.MediaId());
    end;
}

codeunit 92931 "LT Y48 Find Orphans"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LastGuid: Guid;

    local procedure Run(Name: Text; Step: Text; RowId: Integer; MediaGuid: Guid)
    var
        StepCu: Codeunit "LT Y48 FO Step";
    begin
        StepCu.SetStep(Step, RowId, MediaGuid);
        ClearLastError();
        if StepCu.Run() then
            Observer.Observe(Name, 'ok:' + StepCu.GetResult())
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        LastGuid := StepCu.GetMediaGuid();
    end;

    local procedure InMedia(Id: Guid): Text
    begin
        exit(Format(Media.FindOrphans().Contains(Id)));
    end;

    local procedure InSet(Id: Guid): Text
    begin
        exit(Format(MediaSet.FindOrphans().Contains(Id)));
    end;

    local procedure TmExists(Id: Guid): Text
    var
        TM: Record "Tenant Media";
    begin
        exit(Format(TM.Get(Id)));
    end;

    [Test]
    procedure FO_DetachedTenantMediaRow()
    var
        Id: Guid;
    begin
        Clear(Observer);
        Id := CreateGuid();
        Observer.Observe('before insert: in media orphans', InMedia(Id));
        Run('insert', 'tm insert', 0, Id);
        Observer.Observe('in media orphans', InMedia(Id));
        Observer.Observe('in mediaset orphans', InSet(Id));
        Run('delete', 'tm delete', 0, Id);
        Observer.Observe('after delete: in media orphans', InMedia(Id));
        Observer.Finish();
    end;

    [Test]
    procedure FO_DetachedTenantMediaSetRows()
    var
        SetId: Guid;
        Item1: Guid;
        Item2: Guid;
    begin
        Clear(Observer);
        SetId := CreateGuid();
        Run('insert item 1', 'tms insert', 0, SetId);
        Item1 := LastGuid;
        Run('insert item 2', 'tms insert', 0, SetId);
        Item2 := LastGuid;
        Observer.Observe('set in mediaset orphans', InSet(SetId));
        Observer.Observe('set in media orphans', InMedia(SetId));
        Observer.Observe('item 1 in media orphans', InMedia(Item1));
        Observer.Observe('item 2 in media orphans', InMedia(Item2));
        Observer.Observe('item 1 tenant media row', TmExists(Item1));
        Run('delete set rows', 'tms delete set', 0, SetId);
        Observer.Observe('after delete: set in mediaset orphans', InSet(SetId));
        Observer.Observe('after delete: item 1 in media orphans', InMedia(Item1));
        Observer.Observe('after delete: item 1 tenant media row', TmExists(Item1));
        Observer.Finish();
    end;

    [Test]
    procedure FO_HeldNotOrphans_FieldVariants()
    var
        Row: Record "LT Y48 FO Row";
        NullGuid: Guid;
        SetId: Guid;
    begin
        Clear(Observer);
        Run('row pic', 'row pic', 1, NullGuid);
        Observer.Observe('held pic in media orphans', InMedia(LastGuid));
        Run('row pics', 'row pics', 2, NullGuid);
        SetId := LastGuid;
        Row.Get(2);
        Observer.Observe('held set in mediaset orphans', InSet(SetId));
        Observer.Observe('held set item in media orphans', InMedia(Row.Pics.Item(1)));
        Run('pic no insert', 'pic no insert', 3, NullGuid);
        Observer.Observe('not inserted: tenant media row', TmExists(LastGuid));
        Observer.Observe('not inserted: in media orphans', InMedia(LastGuid));
        Run('pic no modify', 'pic no modify', 4, NullGuid);
        Observer.Observe('not modified: tenant media row', TmExists(LastGuid));
        Observer.Observe('not modified: in media orphans', InMedia(LastGuid));
        Row.Get(4);
        Observer.Observe('not modified: row pic hasvalue', Format(Row.Pic.HasValue()));
        Observer.Finish();
    end;

    [Test]
    procedure FO_ClearedField()
    var
        Row: Record "LT Y48 FO Row";
        NullGuid: Guid;
        OldId: Guid;
        OldSet: Guid;
        OldItem: Guid;
    begin
        Clear(Observer);
        Run('row pic', 'row pic', 11, NullGuid);
        OldId := LastGuid;
        Run('clear pic', 'clear pic', 11, NullGuid);
        Observer.Observe('cleared pic in media orphans', InMedia(OldId));
        Observer.Observe('cleared pic tenant media row', TmExists(OldId));
        Run('row pics', 'row pics', 12, NullGuid);
        OldSet := LastGuid;
        Row.Get(12);
        OldItem := Row.Pics.Item(1);
        Run('clear pics', 'clear pics', 12, NullGuid);
        Observer.Observe('cleared set in mediaset orphans', InSet(OldSet));
        Observer.Observe('cleared set item in media orphans', InMedia(OldItem));
        Observer.Observe('cleared set item tenant media row', TmExists(OldItem));
        Observer.Finish();
    end;

    [Test]
    procedure FO_TemporaryHolder()
    var
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('temporary pic', 'temporary pic', 21, NullGuid);
        Observer.Observe('temporary: tenant media row', TmExists(LastGuid));
        Observer.Observe('temporary: in media orphans', InMedia(LastGuid));
        Observer.Finish();
    end;
}
