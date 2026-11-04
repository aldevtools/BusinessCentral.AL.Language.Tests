// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-importstream-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-insert-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-mediaid-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Media (60980), LT BR MediaSet Copy (82969); writer QV: MediaSet.Insert tests (QV_*)
// BC versions: 27.5+
//
// Companion of StefanMaron/BusinessCentral.AL.Runner#1773, which reports that AL Runner's
// MediaSet.ImportStream returns a non-null MediaId whose membership is then invisible to
// Count()/Item() after Modify()+Get() — while the single-value Media field (used here as
// the control, MediaSetPersistence_Media_ImportStream_ModifyThenGet_HasValueTrue) already
// round-trips correctly. These tests pin the correct (real BC) behavior of both field types
// across a write/re-read cycle, including the differential between MediaSet's returned
// import id (the set's own container id, same value MediaId() returns) and the per-item id
// Item() returns.
codeunit 60951 "Test MediaSet Persistence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Control: Media (single) ─────────────────────────────────────────────────────

    [Test]
    procedure Media_ImportStream_ModifyThenGet_HasValueTrue()
    // CLAIM: a Media field's ImportStream()'d content survives Modify()+Get() — the
    // control case MediaSet is compared against.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'M1';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('picture-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Picture.ImportStream(InStr, 'a picture');
        Rec.Modify();

        Assert.IsFalse(IsNullGuid(MediaId), 'Media.ImportStream must return a non-empty MediaId');

        Rec.Get('M1');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Media field must have a value after Modify()+Get()');
    end;

    // ── Core regression: MediaSet.ImportStream ──────────────────────────────────────

    [Test]
    procedure MediaSet_Count_NeverTouched_ReturnsZero()
    // CLAIM: Count() is 0 for a MediaSet field nothing has ever been added to.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Code := 'C1';
        Rec.Insert();

        Assert.AreEqual(0, Rec.Images.Count(), 'Count() must be 0 for an untouched MediaSet field');
    end;

    [Test]
    procedure MediaSet_ImportStream_ModifyThenGet_CountIsOne()
    // CLAIM: MediaSet.ImportStream()'s membership survives Modify()+Get() through the SAME
    // record variable. This is the literal AL Runner#1773 repro.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS1';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('sample-image-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Images.ImportStream(InStr, 'sample image');
        Rec.Modify();

        Assert.IsFalse(IsNullGuid(MediaId), 'MediaSet.ImportStream must return a non-empty id');

        Rec.Get('MS1');
        Assert.AreEqual(1, Rec.Images.Count(), 'Count() must be 1 after Modify()+Get()');
    end;

    [Test]
    procedure MediaSet_ImportStream_ModifyThenGetSecondVariable_CountIsOne()
    // CLAIM: same claim as above, but the re-read happens through a SEPARATE AL record
    // variable of the same row, not just the one that performed the import.
    var
        Rec1: Record "ALT Media";
        Rec2: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec1.Code := 'MS2';
        Rec1.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('second-variable-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec1.Images.ImportStream(InStr, 'second variable');
        Rec1.Modify();

        Rec2.Get('MS2');
        Assert.AreEqual(1, Rec2.Images.Count(), 'Count() must be 1 via a second record variable pointed at the same row');
        Assert.AreEqual(MediaId, Rec2.Images.MediaId(), 'MediaId() via the second record variable must equal ImportStream()''s returned id');
    end;

    [Test]
    procedure MediaSet_ImportStream_MediaId_EqualsReturnedId()
    // CLAIM: MediaSet.MediaId() returns the SAME value ImportStream() returned — both read
    // the field's own container id.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS3';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('id-check-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Images.ImportStream(InStr, 'id check');
        Rec.Modify();

        Rec.Get('MS3');
        Assert.AreEqual(MediaId, Rec.Images.MediaId(), 'MediaId() must equal the id ImportStream() returned');
    end;

    [Test]
    procedure MediaSet_ImportStream_Item_DiffersFromMediaId()
    // CLAIM: Item(1) — the individual imported media object's own id — is a DIFFERENT guid
    // from MediaId()/ImportStream()'s return value, which identifies the set container, not
    // any one item in it.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        ReturnedId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS4';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('item-vs-set-bytes');
        TempBlob.CreateInStream(InStr);
        ReturnedId := Rec.Images.ImportStream(InStr, 'item vs set');
        Rec.Modify();

        Rec.Get('MS4');
        Assert.AreEqual(1, Rec.Images.Count(), 'Count() must be 1');
        Assert.AreNotEqual(ReturnedId, Rec.Images.Item(1), 'Item(1) (the media object id) must differ from ImportStream()''s returned set id');
        Assert.IsFalse(IsNullGuid(Rec.Images.Item(1)), 'Item(1) must be a real, non-empty id');
    end;

    [Test]
    procedure MediaSet_ImportStream_Content_RoundTripsThroughTenantMedia()
    // CLAIM: the bytes passed to ImportStream() are retrievable afterwards by looking up
    // Item(1)'s id in the "Tenant Media" system table — the documented way to read a
    // MediaSet member's content back out.
    var
        Rec: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        Content: Text;
    begin
        Initialize();

        Rec.Code := 'MS5';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('round-trip-bytes');
        TempBlob.CreateInStream(InStr);
        Rec.Images.ImportStream(InStr, 'round trip');
        Rec.Modify();

        Rec.Get('MS5');
        Assert.IsTrue(TenantMedia.Get(Rec.Images.Item(1)), 'Tenant Media row for the imported item must exist');
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(InStr);
        InStr.ReadText(Content);
        Assert.AreEqual('round-trip-bytes', Content, 'Content read back from Tenant Media must match what was imported');
    end;

    [Test]
    procedure MediaSet_Remove_ModifyThenGet_CountIsZero()
    // CLAIM: Remove()'s effect on Count() survives Modify()+Get(), same as Insert()'s does.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS6';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('to-be-removed-bytes');
        TempBlob.CreateInStream(InStr);
        Rec.Images.ImportStream(InStr, 'to be removed');
        Rec.Modify();

        Rec.Get('MS6');
        MediaId := Rec.Images.Item(1);
        Assert.IsTrue(Rec.Images.Remove(MediaId), 'Remove() must return true for an id that is really in the set');
        Rec.Modify();

        Rec.Get('MS6');
        Assert.AreEqual(0, Rec.Images.Count(), 'Count() must be 0 after Remove()+Modify()+Get()');
    end;

    [Test]
    procedure MediaSet_Remove_NeverInserted_ReturnsFalse()
    // CLAIM: Remove() returns false (negative case) for an id that was never added.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Code := 'MS7';
        Rec.Insert();

        Assert.IsFalse(Rec.Images.Remove(CreateGuid()), 'Remove() must return false for an id never inserted');
    end;

    // ── Temporary record variant ─────────────────────────────────────────────────────

    [Test]
    procedure MediaSet_Temporary_ImportStream_Get_CountIsOne()
    // CLAIM: MediaSet membership on a `temporary` record survives its own Modify()+Get()
    // cycle against the record's private in-memory buffer, same as a database-backed row.
    var
        Rec: Record "ALT Media" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'TMP1';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('temp-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Images.ImportStream(InStr, 'temp record');
        Rec.Modify();

        Assert.IsFalse(IsNullGuid(MediaId), 'MediaSet.ImportStream must return a non-empty id on a temporary record');

        Rec.Get('TMP1');
        Assert.AreEqual(1, Rec.Images.Count(), 'Count() must be 1 after Modify()+Get() on a temporary record');
    end;

    // Corpus issue 668 item 73 (writer br): Item() renumbers after Remove of the first item; a MediaSet field copied by assignment to the
    // same field of another row, to a field with the same id in another table, and to a field with another id.
    local procedure BrImport(var Rec: Record "ALT Media"; Payload: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(Payload);
        TempBlob.CreateInStream(InStr);
        Rec.Images.ImportStream(InStr, Payload);
    end;

    [Test]
    procedure MediaSet_RemoveFirstItem_ItemsRenumber()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "ALT Media";
        I1: Guid;
        I2: Guid;
        I3: Guid;
    begin
        Initialize();
        Rec.Code := 'BR1';
        Rec.Insert();
        BrImport(Rec, 'first-bytes');
        BrImport(Rec, 'second-bytes');
        BrImport(Rec, 'third-bytes');
        Rec.Modify();
        Rec.Get('BR1');
        Observer.Observe('count', Format(Rec.Images.Count()));
        I1 := Rec.Images.Item(1);
        I2 := Rec.Images.Item(2);
        I3 := Rec.Images.Item(3);
        Observer.Observe('distinct', Format((I1 <> I2) and (I2 <> I3) and (I1 <> I3)));
        Observer.Observe('remove first', Format(Rec.Images.Remove(I1)));
        Observer.Observe('count after remove', Format(Rec.Images.Count()));
        Observer.Observe('item1 is old item2', Format(Rec.Images.Item(1) = I2));
        Observer.Observe('item2 is old item3', Format(Rec.Images.Item(2) = I3));
        Rec.Modify();
        Rec.Get('BR1');
        Observer.Observe('after modify get', Format(Rec.Images.Count()) + '|' + Format(Rec.Images.Item(1) = I2) + '|' + Format(Rec.Images.Item(2) = I3));
        Observer.Expect('count', '3');
        Observer.Expect('distinct', 'Yes');
        Observer.Expect('remove first', 'Yes');
        Observer.Expect('count after remove', '2');
        Observer.Expect('item1 is old item2', 'Yes');
        Observer.Expect('item2 is old item3', 'Yes');
        Observer.Expect('after modify get', '2|Yes|Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BrTryAssign(var Target: Record "LT BR MediaSet Copy"; var Source: Record "ALT Media"; SameId: Boolean)
    begin
        if SameId then
            Target.Images := Source.Images
        else
            Target.Other := Source.Images;
    end;

    [Test]
    procedure MediaSet_CopyToSameFieldOfAnotherRow()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "ALT Media";
    begin
        Initialize();
        Source.Code := 'BR2';
        Source.Insert();
        BrImport(Source, 'copy-bytes');
        Source.Modify();
        Target.Code := 'BR3';
        Target.Insert();
        Target.Images := Source.Images;
        Observer.Observe('assigned count', Format(Target.Images.Count()));
        Target.Modify();
        Target.Get('BR3');
        Observer.Observe('stored', Format(Target.Images.Count()) + '|' + Format(Target.Images.Item(1) = Source.Images.Item(1)) + '|' + Format(Target.Images.MediaId() = Source.Images.MediaId()));
        Observer.Expect('assigned count', '1');
        Observer.Expect('stored', '1|Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_CopyToSameFieldIdOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "LT BR MediaSet Copy";
    begin
        Initialize();
        Target.DeleteAll();
        Source.Code := 'BR4';
        Source.Insert();
        BrImport(Source, 'copy-bytes');
        Source.Modify();
        Target.Code := 'BR4';
        Target.Insert();
        ClearLastError();
        if BrTryAssign(Target, Source, true) then
            Observer.Observe('assign', 'ok|' + Format(Target.Images.Count()))
        else
            Observer.Observe('assign', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Target.Modify();
        Target.Get('BR4');
        Observer.Observe('stored', Format(Target.Images.Count()));
        Observer.Expect('assign', 'ok|1');
        Observer.Expect('stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_CopyToOtherFieldIdOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "LT BR MediaSet Copy";
    begin
        Initialize();
        Target.DeleteAll();
        Source.Code := 'BR5';
        Source.Insert();
        BrImport(Source, 'copy-bytes');
        Source.Modify();
        Target.Code := 'BR5';
        Target.Insert();
        ClearLastError();
        if BrTryAssign(Target, Source, false) then
            Observer.Observe('assign', 'ok|' + Format(Target.Other.Count()))
        else
            Observer.Observe('assign', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Target.Modify();
        Target.Get('BR5');
        Observer.Observe('stored', Format(Target.Other.Count()));
        Observer.Expect('assign', 'ok|1');
        Observer.Expect('stored', '1');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5683): MediaSet.Insert with the id of a media of another record's MediaSet (Item(n) of that set).
    [Test]
    procedure QV_MediaSet_Insert_ItemOfAnotherRow()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "ALT Media";
        Item1: Guid;
    begin
        Initialize();
        Source.Code := 'QV1';
        Source.Insert();
        BrImport(Source, 'qv-source-bytes');
        Source.Modify();
        Item1 := Source.Images.Item(1);
        Target.Code := 'QV2';
        Target.Insert();
        Observer.Observe('target set id empty before', Format(IsNullGuid(Target.Images.MediaId())));
        Observer.Observe('insert', Format(Target.Images.Insert(Item1)));
        Observer.Observe('target count before modify', Format(Target.Images.Count()));
        Observer.Observe('target item1 before modify', Format(Target.Images.Item(1) = Item1));
        Observer.Observe('target set id empty after insert', Format(IsNullGuid(Target.Images.MediaId())));
        Target.Modify();
        Target.Get('QV2');
        Source.Get('QV1');
        Observer.Observe('target stored', Format(Target.Images.Count()) + '|' + Format(Target.Images.Item(1) = Item1));
        Observer.Observe('set ids differ', Format(Target.Images.MediaId() <> Source.Images.MediaId()));
        Observer.Observe('source stored', Format(Source.Images.Count()) + '|' + Format(Source.Images.Item(1) = Item1));
        Observer.Expect('target set id empty before', 'Yes');
        Observer.Expect('insert', 'Yes');
        Observer.Expect('target count before modify', '1');
        Observer.Expect('target item1 before modify', 'Yes');
        Observer.Expect('target set id empty after insert', 'No');
        Observer.Expect('target stored', '1|Yes');
        Observer.Expect('set ids differ', 'Yes');
        Observer.Expect('source stored', '1|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QV_MediaSet_Insert_SameIdTwice()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "ALT Media";
        Item1: Guid;
    begin
        Initialize();
        Source.Code := 'QV3';
        Source.Insert();
        BrImport(Source, 'qv-twice-bytes');
        Source.Modify();
        Item1 := Source.Images.Item(1);
        Target.Code := 'QV4';
        Target.Insert();
        Observer.Observe('first insert', Format(Target.Images.Insert(Item1)));
        ClearLastError();
        Observer.Observe('second insert', Format(Target.Images.Insert(Item1)));
        Observer.ObserveError('second insert error');
        Observer.Observe('count', Format(Target.Images.Count()));
        Target.Modify();
        Target.Get('QV4');
        Observer.Observe('stored count', Format(Target.Images.Count()));
        // The id that the source set already holds, inserted into the source set itself.
        Observer.Observe('insert into own set', Format(Source.Images.Insert(Item1)));
        Observer.Observe('own set count', Format(Source.Images.Count()));
        Observer.Expect('first insert', 'Yes');
        Observer.Expect('second insert', 'No');
        Observer.Expect('second insert error|text', '');
        Observer.Expect('second insert error|code', '');
        Observer.Expect('count', '1');
        Observer.Expect('stored count', '1');
        Observer.Expect('insert into own set', 'No');
        Observer.Expect('own set count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure QV_MediaSet_Insert_RecordNotInserted()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "ALT Media";
        Item1: Guid;
    begin
        Initialize();
        Source.Code := 'QV5';
        Source.Insert();
        BrImport(Source, 'qv-new-row-bytes');
        Source.Modify();
        Item1 := Source.Images.Item(1);
        Target.Init();
        Target.Code := 'QV6';
        ClearLastError();
        Observer.Observe('insert', Format(Target.Images.Insert(Item1)));
        Observer.ObserveError('insert error');
        Observer.Observe('count', Format(Target.Images.Count()));
        Target.Insert();
        Target.Get('QV6');
        Observer.Observe('stored', Format(Target.Images.Count()) + '|' + Format(Target.Images.Count() = 1));
        if Target.Images.Count() = 1 then
            Observer.Observe('stored item', Format(Target.Images.Item(1) = Item1));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('insert error|text', '');
        Observer.Expect('insert error|code', '');
        Observer.Expect('count', '1');
        Observer.Expect('stored', '1|Yes');
        Observer.Expect('stored item', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QV_MediaSet_Insert_UnknownAndNullId()
    var
        Observer: Codeunit "Probe Observer";
        Target: Record "ALT Media";
        NullId: Guid;
    begin
        Initialize();
        Target.Code := 'QV7';
        Target.Insert();
        ClearLastError();
        Observer.Observe('unknown id', Format(Target.Images.Insert(CreateGuid())));
        Observer.ObserveError('unknown id error');
        Observer.Observe('count after unknown', Format(Target.Images.Count()));
        ClearLastError();
        Observer.Observe('null id', Format(Target.Images.Insert(NullId)));
        Observer.ObserveError('null id error');
        Observer.Observe('count after null', Format(Target.Images.Count()));
        Observer.Expect('unknown id', 'No');
        Observer.Expect('unknown id error|text', '');
        Observer.Expect('unknown id error|code', '');
        Observer.Expect('count after unknown', '0');
        Observer.Expect('null id', 'No');
        Observer.Expect('null id error|text', '');
        Observer.Expect('null id error|code', '');
        Observer.Expect('count after null', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QV_MediaSet_Insert_SourceRemovesAfterwards()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "ALT Media";
        Target: Record "LT BR MediaSet Copy";
        Item1: Guid;
    begin
        Initialize();
        Target.DeleteAll();
        Source.Code := 'QV8';
        Source.Insert();
        BrImport(Source, 'qv-other-table-bytes');
        Source.Modify();
        Item1 := Source.Images.Item(1);
        Target.Code := 'QV8';
        Target.Insert();
        Observer.Observe('insert other table', Format(Target.Images.Insert(Item1)));
        Observer.Observe('insert other field', Format(Target.Other.Insert(Item1)));
        Target.Modify();
        Observer.Observe('source remove', Format(Source.Images.Remove(Item1)));
        Source.Modify();
        Source.Get('QV8');
        Target.Get('QV8');
        Observer.Observe('source count', Format(Source.Images.Count()));
        Observer.Observe('target images', Format(Target.Images.Count()) + '|' + Format(Target.Images.Count() = 1));
        Observer.Observe('target other', Format(Target.Other.Count()));
        if Target.Images.Count() = 1 then
            Observer.Observe('target item', Format(Target.Images.Item(1) = Item1));
        Observer.Expect('insert other table', 'Yes');
        Observer.Expect('insert other field', 'Yes');
        Observer.Expect('source remove', 'Yes');
        Observer.Expect('source count', '0');
        Observer.Expect('target images', '1|Yes');
        Observer.Expect('target other', '1');
        Observer.Expect('target item', 'Yes');
        Observer.Verify();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}

table 82969 "LT BR MediaSet Copy"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(4; Images; MediaSet) { }
        field(5; Other; MediaSet) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}
