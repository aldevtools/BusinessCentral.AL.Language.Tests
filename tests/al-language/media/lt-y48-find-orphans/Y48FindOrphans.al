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
//        Asserted values: the CI containers BC 27.5, 28.5 and 29.0, all the same (a SaaS sandbox BC 29 agrees where its license allows the writes;
//        it refuses Insert into Tenant Media and Tenant Media Set).
// Writer Y57 (corpus issue 996), FO_ReplacedPic .. FO_TemporarySetHolder: a second import into a held Media field deletes the old Tenant
//        Media row (not an orphan); deleting the holder row deletes its Media and MediaSet rows (no orphans); a media shared by two rows
//        keeps its row until the last holder is deleted; a set item removed with MediaSet.Remove keeps its Tenant Media row and becomes a
//        Media orphan (the set is not an orphan); a MediaSet imported into a temporary record is a MediaSet orphan, its item is not a
//        Media orphan. Measured: SaaS sandbox BC 29 and the Linux CI containers BC 27.5, 28.5, 29.0, all the same.
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
        CopyRow: Record "LT Y48 FO Row";
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
            // Writer Y57 steps.
            // a second import into the field of an inserted row, then Modify; MediaGuid becomes the new media id
            'replace pic':
                begin
                    Row.Get(RowId);
                    TextStream(TempBlob, InS);
                    Row.Pic.ImportStream(InS, 'second');
                    Row.Modify();
                    MediaGuid := Row.Pic.MediaId();
                    Result := 'ok';
                end;
            'delete row':
                begin
                    Row.Get(RowId);
                    Result := Format(Row.Delete());
                end;
            // a new row RowId whose Pic is assigned from row RowId - 1; MediaGuid becomes its media id
            'copy pic':
                begin
                    Row.Get(RowId - 1);
                    CopyRow.Init();
                    CopyRow.Id := RowId;
                    CopyRow.Pic := Row.Pic;
                    CopyRow.Insert();
                    MediaGuid := CopyRow.Pic.MediaId();
                    Result := 'ok';
                end;
            // a second item imported into the set of row RowId; MediaGuid becomes that item's media id
            'add set item':
                begin
                    Row.Get(RowId);
                    TextStream(TempBlob, InS);
                    Row.Pics.ImportStream(InS, 'b');
                    Row.Modify();
                    MediaGuid := Row.Pics.Item(Row.Pics.Count());
                    Result := Format(Row.Pics.Count());
                end;
            // MediaGuid = the item to remove from the set of row RowId
            'remove set item':
                begin
                    Row.Get(RowId);
                    Result := Format(Row.Pics.Remove(MediaGuid));
                    Row.Modify();
                    Result += '|' + Format(Row.Pics.Count());
                end;
            // MediaGuid becomes the set id of a temporary record's MediaSet import
            'temporary pics':
                begin
                    TextStream(TempBlob, InS);
                    MediaGuid := TemporarySetImport(RowId, InS);
                    Result := 'ok';
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

    local procedure TemporarySetImport(Id: Integer; var InS: InStream): Guid
    var
        TempRow: Record "LT Y48 FO Row" temporary;
    begin
        TempRow.Init();
        TempRow.Id := Id;
        TempRow.Pics.ImportStream(InS, 'a');
        TempRow.Insert();
        exit(TempRow.Pics.MediaId());
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

    // Error texts can carry a media id or a session id: both change per run.
    local procedure ScrubIds(Value: Text): Text
    begin
        Value := Between(Value, 'ID=''', '''');
        Value := Between(Value, 'session ID: ''', '''');
        exit(Value);
    end;

    local procedure Between(Value: Text; StartText: Text; EndText: Text): Text
    var
        StartPos: Integer;
        Rest: Text;
        EndPos: Integer;
    begin
        StartPos := StrPos(Value, StartText);
        if StartPos = 0 then
            exit(Value);
        Rest := CopyStr(Value, StartPos + StrLen(StartText));
        EndPos := StrPos(Rest, EndText);
        if EndPos = 0 then
            exit(Value);
        exit(CopyStr(Value, 1, StartPos + StrLen(StartText) - 1) + 'x' + CopyStr(Rest, EndPos));
    end;

    local procedure Run(Name: Text; Step: Text; RowId: Integer; MediaGuid: Guid)
    var
        StepCu: Codeunit "LT Y48 FO Step";
    begin
        StepCu.SetStep(Step, RowId, MediaGuid);
        ClearLastError();
        if StepCu.Run() then
            Observer.Observe(Name, 'ok:' + StepCu.GetResult())
        else
            Observer.Observe(Name, 'error:' + ScrubIds(GetLastErrorText()) + '|' + GetLastErrorCode());
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
        Observer.Expect('before insert: in media orphans', 'No');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('in media orphans', 'Yes');
        Observer.Expect('in mediaset orphans', 'No');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('after delete: in media orphans', 'No');
        Observer.Verify();
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
        Observer.Expect('insert item 1', 'ok:Yes');
        Observer.Expect('insert item 2', 'ok:Yes');
        Observer.Expect('set in mediaset orphans', 'Yes');
        Observer.Expect('set in media orphans', 'No');
        Observer.Expect('item 1 in media orphans', 'No');
        Observer.Expect('item 2 in media orphans', 'No');
        Observer.Expect('item 1 tenant media row', 'Yes');
        Observer.Expect('delete set rows', 'ok:done');
        Observer.Expect('after delete: set in mediaset orphans', 'No');
        Observer.Expect('after delete: item 1 in media orphans', 'Yes');
        Observer.Expect('after delete: item 1 tenant media row', 'Yes');
        Observer.Verify();
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
        Observer.Expect('row pic', 'ok:ok');
        Observer.Expect('held pic in media orphans', 'No');
        Observer.Expect('row pics', 'ok:ok');
        Observer.Expect('held set in mediaset orphans', 'No');
        Observer.Expect('held set item in media orphans', 'No');
        Observer.Expect('pic no insert', 'ok:ok');
        Observer.Expect('not inserted: tenant media row', 'Yes');
        Observer.Expect('not inserted: in media orphans', 'Yes');
        Observer.Expect('pic no modify', 'ok:ok');
        Observer.Expect('not modified: tenant media row', 'Yes');
        Observer.Expect('not modified: in media orphans', 'Yes');
        Observer.Expect('not modified: row pic hasvalue', 'No');
        Observer.Verify();
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
        Observer.Expect('row pic', 'ok:ok');
        Observer.Expect('clear pic', 'ok:Yes');
        Observer.Expect('cleared pic in media orphans', 'No');
        Observer.Expect('cleared pic tenant media row', 'No');
        Observer.Expect('row pics', 'ok:ok');
        Observer.Expect('clear pics', 'ok:Yes');
        Observer.Expect('cleared set in mediaset orphans', 'No');
        Observer.Expect('cleared set item in media orphans', 'No');
        Observer.Expect('cleared set item tenant media row', 'No');
        Observer.Verify();
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
        Observer.Expect('temporary pic', 'ok:ok');
        Observer.Expect('temporary: tenant media row', 'Yes');
        Observer.Expect('temporary: in media orphans', 'Yes');
        Observer.Verify();
    end;

    // Writer Y57: a replaced media, a deleted holder row (Media and MediaSet), a media shared by two rows, a set item removed from its set,
    // and a MediaSet imported into a temporary record.
    [Test]
    procedure FO_ReplacedPic()
    var
        NullGuid: Guid;
        OldId: Guid;
    begin
        Clear(Observer);
        Run('row pic', 'row pic', 51, NullGuid);
        OldId := LastGuid;
        Run('replace pic', 'replace pic', 51, NullGuid);
        Observer.Observe('new id differs', Format(LastGuid <> OldId));
        Observer.Observe('old: tenant media row', TmExists(OldId));
        Observer.Observe('old: in media orphans', InMedia(OldId));
        Observer.Observe('new: in media orphans', InMedia(LastGuid));
        Observer.Expect('row pic', 'ok:ok');
        Observer.Expect('replace pic', 'ok:ok');
        Observer.Expect('new id differs', 'Yes');
        Observer.Expect('old: tenant media row', 'No');
        Observer.Expect('old: in media orphans', 'No');
        Observer.Expect('new: in media orphans', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FO_DeletedHolderRow()
    var
        Row: Record "LT Y48 FO Row";
        NullGuid: Guid;
        PicId: Guid;
        SetId: Guid;
        ItemId: Guid;
    begin
        Clear(Observer);
        Run('row pic', 'row pic', 52, NullGuid);
        PicId := LastGuid;
        Run('delete pic row', 'delete row', 52, NullGuid);
        Observer.Observe('pic: tenant media row', TmExists(PicId));
        Observer.Observe('pic: in media orphans', InMedia(PicId));
        Run('row pics', 'row pics', 53, NullGuid);
        SetId := LastGuid;
        Row.Get(53);
        ItemId := Row.Pics.Item(1);
        Run('delete pics row', 'delete row', 53, NullGuid);
        Observer.Observe('set: in mediaset orphans', InSet(SetId));
        Observer.Observe('item: tenant media row', TmExists(ItemId));
        Observer.Observe('item: in media orphans', InMedia(ItemId));
        Observer.Expect('row pic', 'ok:ok');
        Observer.Expect('delete pic row', 'ok:Yes');
        Observer.Expect('pic: tenant media row', 'No');
        Observer.Expect('pic: in media orphans', 'No');
        Observer.Expect('row pics', 'ok:ok');
        Observer.Expect('delete pics row', 'ok:Yes');
        Observer.Expect('set: in mediaset orphans', 'No');
        Observer.Expect('item: tenant media row', 'No');
        Observer.Expect('item: in media orphans', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FO_SharedPic()
    var
        NullGuid: Guid;
        FirstId: Guid;
    begin
        Clear(Observer);
        Run('row pic', 'row pic', 54, NullGuid);
        FirstId := LastGuid;
        Run('copy pic', 'copy pic', 55, NullGuid);
        Observer.Observe('same id', Format(LastGuid = FirstId));
        Run('delete first row', 'delete row', 54, NullGuid);
        Observer.Observe('after delete: tenant media row', TmExists(FirstId));
        Observer.Observe('after delete: in media orphans', InMedia(FirstId));
        Run('delete second row', 'delete row', 55, NullGuid);
        Observer.Observe('after both: tenant media row', TmExists(FirstId));
        Observer.Observe('after both: in media orphans', InMedia(FirstId));
        Observer.Expect('row pic', 'ok:ok');
        Observer.Expect('copy pic', 'ok:ok');
        Observer.Expect('same id', 'Yes');
        Observer.Expect('delete first row', 'ok:Yes');
        Observer.Expect('after delete: tenant media row', 'Yes');
        Observer.Expect('after delete: in media orphans', 'No');
        Observer.Expect('delete second row', 'ok:Yes');
        Observer.Expect('after both: tenant media row', 'No');
        Observer.Expect('after both: in media orphans', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FO_RemovedSetItem()
    var
        Row: Record "LT Y48 FO Row";
        NullGuid: Guid;
        SetId: Guid;
        Item1: Guid;
        Item2: Guid;
    begin
        Clear(Observer);
        Run('row pics', 'row pics', 56, NullGuid);
        SetId := LastGuid;
        Row.Get(56);
        Item1 := Row.Pics.Item(1);
        Run('add set item', 'add set item', 56, NullGuid);
        Item2 := LastGuid;
        Run('remove item 1', 'remove set item', 56, Item1);
        Row.Get(56);
        Observer.Observe('set id kept', Format(Row.Pics.MediaId() = SetId));
        Observer.Observe('item 2 still item 1', Format(Row.Pics.Item(1) = Item2));
        Observer.Observe('removed: tenant media row', TmExists(Item1));
        Observer.Observe('removed: in media orphans', InMedia(Item1));
        Observer.Observe('kept: in media orphans', InMedia(Item2));
        Observer.Observe('set: in mediaset orphans', InSet(SetId));
        Observer.Expect('row pics', 'ok:ok');
        Observer.Expect('add set item', 'ok:2');
        Observer.Expect('remove item 1', 'ok:Yes|1');
        Observer.Expect('set id kept', 'Yes');
        Observer.Expect('item 2 still item 1', 'Yes');
        Observer.Expect('removed: tenant media row', 'Yes');
        Observer.Expect('removed: in media orphans', 'Yes');
        Observer.Expect('kept: in media orphans', 'No');
        Observer.Expect('set: in mediaset orphans', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FO_TemporarySetHolder()
    var
        TMS: Record "Tenant Media Set";
        NullGuid: Guid;
        ItemId: Guid;
    begin
        Clear(Observer);
        Run('temporary pics', 'temporary pics', 57, NullGuid);
        TMS.SetRange(ID, LastGuid);
        Observer.Observe('temporary: set rows', Format(TMS.Count()));
        if TMS.FindFirst() then begin
            ItemId := TMS."Media ID".MediaId();
            Observer.Observe('temporary: item tenant media row', TmExists(ItemId));
            Observer.Observe('temporary: item in media orphans', InMedia(ItemId));
        end;
        Observer.Observe('temporary: set in mediaset orphans', InSet(LastGuid));
        Observer.Expect('temporary pics', 'ok:ok');
        Observer.Expect('temporary: set rows', '1');
        Observer.Expect('temporary: item tenant media row', 'Yes');
        Observer.Expect('temporary: item in media orphans', 'No');
        Observer.Expect('temporary: set in mediaset orphans', 'Yes');
        Observer.Verify();
    end;
}
