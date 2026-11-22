// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 66993 "LT UH Pic" (UhUntouchedStreams.al) and 66990 "LT UH Row" (UhUnopenedRecordRef.al)
// Probe: written against BC 27.5, 28.5 and 29.0 (corpus PR 1411 CI run). All three versions gave the same result, so no version guard.
// Facts: what a record holds after Media.ImportStream and MediaSet.ImportStream from an InStream that was never created: HasValue,
//   MediaId and MediaSet Count right after the import; the same after Insert and Get; the import into a record already inserted
//   (then Modify and Get) and into a temporary record. Neighbors of UhUntouchedStreams.al (corpus PR 1408); al-runner PR 8120
//   refuses these shapes until they are measured.
// BC versions: 27.5, 28.5, 29.0

codeunit 66995 "LT UH Streams After Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Step(Name: Text): Text
    var
        Pic: Record "LT UH Pic";
        Got: Record "LT UH Pic";
        TempPic: Record "LT UH Pic" temporary;
        InS: InStream;
        G: Guid;
        Result: Text;
    begin
        Pic.DeleteAll();
        case Name of
            'media_fresh':
                begin
                    Pic.Code := 'A';
                    G := Pic.Icon.ImportStream(InS, 'icon');
                    Result := Format(G) + '|' + Format(Pic.Icon.HasValue()) + '|' + Format(Pic.Icon.MediaId());
                end;
            'media_fresh_insert_get':
                begin
                    Pic.Code := 'A';
                    G := Pic.Icon.ImportStream(InS, 'icon');
                    Pic.Insert();
                    Got.Get('A');
                    Result := Format(Got.Icon.HasValue()) + '|' + Format(Got.Icon.MediaId());
                end;
            'mediaset_fresh':
                begin
                    Pic.Code := 'A';
                    G := Pic.Icons.ImportStream(InS, 'icon');
                    Result := Format(G) + '|' + Format(Pic.Icons.Count()) + '|' + Format(Pic.Icons.MediaId());
                end;
            'mediaset_fresh_insert_get':
                begin
                    Pic.Code := 'A';
                    G := Pic.Icons.ImportStream(InS, 'icon');
                    Pic.Insert();
                    Got.Get('A');
                    Result := Format(Got.Icons.Count()) + '|' + Format(Got.Icons.MediaId());
                end;
            'media_inserted':
                begin
                    Pic.Code := 'A';
                    Pic.Insert();
                    G := Pic.Icon.ImportStream(InS, 'icon');
                    Result := Format(G) + '|' + Format(Pic.Icon.HasValue()) + '|' + Format(Pic.Icon.MediaId());
                end;
            'media_inserted_modify_get':
                begin
                    Pic.Code := 'A';
                    Pic.Insert();
                    G := Pic.Icon.ImportStream(InS, 'icon');
                    Pic.Modify();
                    Got.Get('A');
                    Result := Format(Got.Icon.HasValue()) + '|' + Format(Got.Icon.MediaId());
                end;
            'mediaset_inserted':
                begin
                    Pic.Code := 'A';
                    Pic.Insert();
                    G := Pic.Icons.ImportStream(InS, 'icon');
                    Result := Format(G) + '|' + Format(Pic.Icons.Count());
                end;
            'media_temporary':
                begin
                    TempPic.Code := 'A';
                    G := TempPic.Icon.ImportStream(InS, 'icon');
                    Result := Format(G) + '|' + Format(TempPic.Icon.HasValue()) + '|' + Format(TempPic.Icon.MediaId());
                end;
            'mediaset_temporary':
                begin
                    TempPic.Code := 'A';
                    G := TempPic.Icons.ImportStream(InS, 'icon');
                    Result := Format(G) + '|' + Format(TempPic.Icons.Count());
                end;
        end;
        exit(Result);
    end;

    // The steps write rows, which a TryFunction may not do: a step that raises fails its test (observe form).
    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe('result', Step(Name));
    end;

    [Test]
    procedure AfterImport_Media_Fresh()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_fresh');
        Observer.Expect('result', '{00000000-0000-0000-0000-000000000000}|No|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_Media_Fresh_InsertThenGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_fresh_insert_get');
        Observer.Expect('result', 'No|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_MediaSet_Fresh()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'mediaset_fresh');
        Observer.Expect('result', '{00000000-0000-0000-0000-000000000000}|0|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_MediaSet_Fresh_InsertThenGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'mediaset_fresh_insert_get');
        Observer.Expect('result', '0|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_Media_Inserted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_inserted');
        Observer.Expect('result', '{00000000-0000-0000-0000-000000000000}|No|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_Media_Inserted_ModifyThenGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_inserted_modify_get');
        Observer.Expect('result', 'No|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_MediaSet_Inserted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'mediaset_inserted');
        Observer.Expect('result', '{00000000-0000-0000-0000-000000000000}|0');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_Media_Temporary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_temporary');
        Observer.Expect('result', '{00000000-0000-0000-0000-000000000000}|No|{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure AfterImport_MediaSet_Temporary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'mediaset_temporary');
        Observer.Expect('result', '{00000000-0000-0000-0000-000000000000}|0');
        Observer.Verify();
    end;
}

// What a RecordRef answers after a call that left it not open, where UhUnopenedRecordRef.al measured a new variable only, and
// CopyLinks sources that probe did not pass. al-runner PR 8120 refuses these shapes until they are measured.
codeunit 66996 "LT UH RecordRef After Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try(Setup: Text; Member: Text; var Result: Text)
    var
        Rec: Record "LT UH Row";
        RR: RecordRef;
        Src: RecordRef;
        KR: KeyRef;
        FR: FieldRef;
        V: Variant;
        RecId: RecordId;
        B: Boolean;
    begin
        case Setup of
            'failed_open':
                if not TryOpen(RR) then;
            'missed_get':
                begin
                    Rec.Id := 7;
                    RecId := Rec.RecordId();
                    B := RR.Get(RecId);
                end;
            'open_zero':
                RR.Open(0);
            'open_clear':
                begin
                    RR.Open(66990);
                    Clear(RR);
                end;
        end;
        case Member of
            'findlast':
                Result := Format(RR.FindLast());
            'getfilters':
                Result := RR.GetFilters();
            'next':
                Result := Format(RR.Next());
            'keyindex':
                begin
                    KR := RR.KeyIndex(1);
                    Result := 'done';
                end;
            'setrecfilter':
                begin
                    RR.SetRecFilter();
                    Result := 'done';
                end;
            'setloadfields':
                begin
                    RR.SetLoadFields(1);
                    Result := 'done';
                end;
            'copylinks_variant':
                begin
                    V := Rec;
                    RR.CopyLinks(V);
                    Result := 'done';
                end;
            'copylinks_filtered':
                begin
                    Rec.SetRange(Id, 1);
                    RR.CopyLinks(Rec);
                    Result := 'done';
                end;
            'copylinks_positioned':
                begin
                    Rec.Get(1); // inserted by the test
                    RR.CopyLinks(Rec);
                    Result := 'done';
                end;
            'copylinks_ref_filtered':
                begin
                    Src.Open(66990);
                    FR := Src.Field(1);
                    FR.SetRange(1);
                    RR.CopyLinks(Src);
                    Result := 'done';
                end;
        end;
    end;

    [TryFunction]
    local procedure TryOpen(var RR: RecordRef)
    begin
        RR.Open(99999999);
    end;

    [TryFunction]
    local procedure TryKeyRef(Step: Text; var Result: Text)
    var
        RR: RecordRef;
        KR: KeyRef;
    begin
        RR.Open(66990);
        KR := RR.KeyIndex(1);
        Clear(KR);
        case Step of
            'fieldcount':
                Result := Format(KR.FieldCount());
            'active':
                Result := Format(KR.Active());
        end;
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Setup: Text; Member: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if Try(Setup, Member, Result) then
            Observer.Observe(Setup + '|' + Member, 'ok:' + Result)
        else
            Observer.Observe(Setup + '|' + Member, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RunAll(var Observer: Codeunit "Probe Observer"; Setup: Text)
    begin
        Run(Observer, Setup, 'findlast');
        Run(Observer, Setup, 'getfilters');
        Run(Observer, Setup, 'next');
        Run(Observer, Setup, 'keyindex');
        Run(Observer, Setup, 'setrecfilter');
        Run(Observer, Setup, 'setloadfields');
    end;

    [Test]
    procedure AfterFailedOpen_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAll(Observer, 'failed_open');
        Observer.Expect('failed_open|findlast', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('failed_open|getfilters', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('failed_open|next', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('failed_open|keyindex', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('failed_open|setrecfilter', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('failed_open|setloadfields', 'error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure AfterMissedGet_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAll(Observer, 'missed_get');
        Observer.Expect('missed_get|findlast', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('missed_get|getfilters', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('missed_get|next', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('missed_get|keyindex', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('missed_get|setrecfilter', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('missed_get|setloadfields', 'error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure AfterOpenZero_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAll(Observer, 'open_zero');
        Observer.Expect('open_zero|findlast', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_zero|getfilters', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_zero|next', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_zero|keyindex', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_zero|setrecfilter', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_zero|setloadfields', 'error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure AfterOpenClear_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAll(Observer, 'open_clear');
        Observer.Expect('open_clear|findlast', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_clear|getfilters', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_clear|next', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_clear|keyindex', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_clear|setrecfilter', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('open_clear|setloadfields', 'error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure CopyLinks_Sources()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT UH Row";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Run(Observer, 'new', 'copylinks_variant');
        Run(Observer, 'new', 'copylinks_filtered');
        Run(Observer, 'new', 'copylinks_positioned');
        Run(Observer, 'new', 'copylinks_ref_filtered');
        Observer.Expect('new|copylinks_variant', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('new|copylinks_filtered', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('new|copylinks_positioned', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('new|copylinks_ref_filtered', 'error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure KeyRef_AfterClear_Members()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        ClearLastError();
        if TryKeyRef('fieldcount', Result) then
            Observer.Observe('fieldcount', 'ok:' + Result)
        else
            Observer.Observe('fieldcount', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryKeyRef('active', Result) then
            Observer.Observe('active', 'ok:' + Result)
        else
            Observer.Observe('active', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('active', 'error:Microsoft.Dynamics.Nav.Runtime.NavKeyRef variable not initialized.|NotInitialized');
        Observer.Ignore('fieldcount'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;
}
