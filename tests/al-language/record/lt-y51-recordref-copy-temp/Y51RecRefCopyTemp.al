// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-copy-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 92982, test codeunit 92983 (writer Y51, gap cycle 5 spec G5-15)
// Probe: RecordRef.Copy with a Record (or RecordRef) source into a RecordRef opened as temporary, then Insert, in a loop over the source:
//        a filtered non-temporary Record, a temporary Record with marks and MarkedOnly, Copy without the ShareTable argument, ShareTable
//        true with a non-temporary and a temporary source, and a filtered RecordRef source with Insert(false). Observed: IsTemporary, Count,
//        GetFilters, GetView and the ids FindSet visits (State), the field value right after Copy, the row count of the real table.
//        Copy runs in a TryFunction (no write inside it); Insert runs outside.
//        Already pinned nearby: misc/lt-probes-needed-6/PnF27RecordRefCopy.al (Record into a non-temporary RecordRef),
//        types/PWMisc.al (temporary RecordRef into a temporary RecordRef), record/TestCopyOntoTemporaryRecord.al (Record.Copy onto a temporary Record).
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
//         SetView and RecordRef.Copy values (not the FilterPageHandler test) also match the SaaS sandbox BC 29.
// BC versions: 27, 28, 29

table 92982 "LT Y51 RC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Id) { }
    }
}

codeunit 92983 "LT Y51 RecRef Copy Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y51 RC Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 5 do begin
            Row.Init();
            Row.Id := I;
            Row.Grp := (I + 1) div 2;
            Row.Name := 'n' + Format(I);
            Row.Insert();
        end;
    end;

    local procedure State(var RR: RecordRef): Text
    var
        Ids: Text;
    begin
        if RR.FindSet() then
            repeat
                Ids += Format(RR.Field(1).Value) + ',';
            until RR.Next() = 0;
        exit(Format(RR.IsTemporary()) + '|' + Format(RR.Count()) + '|' + RR.GetFilters() + '|' + RR.GetView(false) + '|' + Ids);
    end;

    local procedure DbCount(): Integer
    var
        Real: Record "LT Y51 RC Row";
    begin
        exit(Real.Count());
    end;

    [TryFunction]
    local procedure TryCopy(var RR: RecordRef; var Row: Record "LT Y51 RC Row"; Share: Boolean)
    begin
        RR.Copy(Row, Share);
    end;

    [TryFunction]
    local procedure TryCopyNoArg(var RR: RecordRef; var Row: Record "LT Y51 RC Row")
    begin
        RR.Copy(Row);
    end;

    [TryFunction]
    local procedure TryCopyRef(var RR: RecordRef; var Src: RecordRef; Share: Boolean)
    begin
        RR.Copy(Src, Share);
    end;

    local procedure Err(): Text
    var
        Result: Text;
    begin
        Result := GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure RecRefCopy_RecordIntoTemporary_LoopInsert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y51 RC Row";
        RR: RecordRef;
        First: Boolean;
        Copies: Text;
    begin
        Seed();
        Row.SetRange(Grp, 1, 2);
        Row.FindSet();
        RR.Open(Database::"LT Y51 RC Row", true);
        Observer.Observe('after_open', State(RR));
        First := true;
        repeat
            if not TryCopy(RR, Row, false) then
                Copies += 'err ' + Err() + ';'
            else
                Copies += 'ok;';
            if First then begin
                Observer.Observe('first_copy_field1', Format(RR.Field(1).Value));
                Observer.Observe('first_copy_field3', Format(RR.Field(3).Value));
                Observer.Observe('after_first_copy', State(RR));
                TryCopy(RR, Row, false);
                First := false;
            end;
            RR.Insert();
        until Row.Next() = 0;
        Observer.Observe('copies', Copies);
        Observer.Observe('after_loop', State(RR));
        RR.Reset();
        Observer.Observe('after_reset', State(RR));
        Observer.Observe('db_count', Format(DbCount()));
        Observer.Expect('after_open', 'Yes|0||VERSION(1) SORTING(Field1)|');
        Observer.Expect('first_copy_field1', '1');
        Observer.Expect('first_copy_field3', 'n1');
        Observer.Expect('after_first_copy', 'Yes|0|Grp: 1..2|VERSION(1) SORTING(Field1) WHERE(Field2=1(1..2))|');
        Observer.Expect('copies', 'ok;ok;ok;ok;');
        Observer.Expect('after_loop', 'Yes|4|Grp: 1..2|VERSION(1) SORTING(Field1) WHERE(Field2=1(1..2))|1,2,3,4,');
        Observer.Expect('after_reset', 'Yes|4||VERSION(1) SORTING(Field1)|1,2,3,4,');
        Observer.Expect('db_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure RecRefCopy_MarkedTemporaryRecordIntoTemporary()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT Y51 RC Row" temporary;
        RR: RecordRef;
        I: Integer;
        Copies: Text;
    begin
        Seed();
        for I := 10 to 12 do begin
            TempRow.Init();
            TempRow.Id := I;
            TempRow.Grp := 7;
            TempRow.Insert();
            if I <> 11 then
                TempRow.Mark(true);
        end;
        TempRow.MarkedOnly(true);
        RR.Open(Database::"LT Y51 RC Row", true);
        if TempRow.FindSet() then
            repeat
                if not TryCopy(RR, TempRow, false) then
                    Copies += 'err ' + Err() + ';'
                else
                    Copies += 'ok;';
                RR.Insert();
            until TempRow.Next() = 0;
        Observer.Observe('copies', Copies);
        Observer.Observe('markedonly_after_loop', Format(RR.MarkedOnly()));
        Observer.Observe('after_loop', State(RR));
        RR.Reset();
        Observer.Observe('markedonly_after_reset', Format(RR.MarkedOnly()));
        Observer.Observe('after_reset', State(RR));
        Observer.Observe('temprow_count', Format(TempRow.Count()));
        TempRow.MarkedOnly(false);
        Observer.Observe('temprow_count_all', Format(TempRow.Count()));
        Observer.Observe('db_count', Format(DbCount()));
        Observer.Expect('copies', 'ok;ok;');
        Observer.Expect('markedonly_after_loop', 'Yes');
        Observer.Expect('after_loop', 'Yes|2|Marked: Yes|VERSION(1) SORTING(Field1)|10,12,');
        Observer.Expect('markedonly_after_reset', 'No');
        Observer.Expect('after_reset', 'Yes|2||VERSION(1) SORTING(Field1)|10,12,');
        Observer.Expect('temprow_count', '2');
        Observer.Expect('temprow_count_all', '3');
        Observer.Expect('db_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure RecRefCopy_RecordIntoTemporary_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y51 RC Row";
        RR: RecordRef;
    begin
        Seed();
        Row.SetRange(Grp, 1, 2);
        Row.FindFirst();
        RR.Open(Database::"LT Y51 RC Row", true);
        if TryCopyNoArg(RR, Row) then
            Observer.Observe('copy', 'ok')
        else
            Observer.Observe('copy', 'err ' + Err());
        Observer.Observe('field1', Format(RR.Field(1).Value));
        RR.Insert();
        Observer.Observe('after_insert', State(RR));
        RR.Reset();
        Observer.Observe('after_reset', State(RR));
        Observer.Observe('db_count', Format(DbCount()));
        Observer.Expect('copy', 'ok');
        Observer.Expect('field1', '1');
        Observer.Expect('after_insert', 'Yes|1|Grp: 1..2|VERSION(1) SORTING(Field1) WHERE(Field2=1(1..2))|1,');
        Observer.Expect('after_reset', 'Yes|1||VERSION(1) SORTING(Field1)|1,');
        Observer.Expect('db_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure RecRefCopy_RecordIntoTemporary_ShareTableTrue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y51 RC Row";
        TempRow: Record "LT Y51 RC Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Seed();
        Row.FindFirst();
        RR.Open(Database::"LT Y51 RC Row", true);
        if TryCopy(RR, Row, true) then
            Observer.Observe('share_nontemp', 'ok')
        else
            Observer.Observe('share_nontemp', 'err ' + Err());
        Observer.Observe('share_nontemp_state', State(RR));

        TempRow.Id := 20;
        TempRow.Insert();
        TempRow.Id := 21;
        TempRow.Insert();
        RR2.Open(Database::"LT Y51 RC Row", true);
        if TryCopy(RR2, TempRow, true) then
            Observer.Observe('share_temp', 'ok')
        else
            Observer.Observe('share_temp', 'err ' + Err());
        RR2.Field(1).Value := 99;
        RR2.Field(2).Value := 9;
        RR2.Insert();
        Observer.Observe('share_temp_state', State(RR2));
        TempRow.Reset();
        Observer.Observe('share_temp_temprow_count', Format(TempRow.Count()));
        Observer.Observe('db_count', Format(DbCount()));
        Observer.Expect('share_nontemp', 'err The COPY function can only be used with the shareTable argument set to true if both records are temporary.|Argument');
        Observer.Expect('share_nontemp_state', 'Yes|0||VERSION(1) SORTING(Field1)|');
        Observer.Expect('share_temp', 'ok');
        Observer.Expect('share_temp_state', 'Yes|3||VERSION(1) SORTING(Field1)|20,21,99,');
        Observer.Expect('share_temp_temprow_count', '3');
        Observer.Expect('db_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure RecRefCopy_RecordRefIntoTemporary_InsertFalse()
    var
        Observer: Codeunit "Probe Observer";
        Src: RecordRef;
        RR: RecordRef;
        Copies: Text;
    begin
        Seed();
        Src.Open(Database::"LT Y51 RC Row");
        Src.Field(2).SetRange(1, 2);
        Src.FindSet();
        RR.Open(Src.Number(), true);
        repeat
            if not TryCopyRef(RR, Src, false) then
                Copies += 'err ' + Err() + ';'
            else
                Copies += 'ok;';
            RR.Insert(false);
        until Src.Next() = 0;
        Observer.Observe('copies', Copies);
        Observer.Observe('after_loop', State(RR));
        RR.Reset();
        Observer.Observe('after_reset', State(RR));
        Observer.Observe('db_count', Format(DbCount()));
        Observer.Expect('copies', 'ok;ok;ok;ok;');
        Observer.Expect('after_loop', 'Yes|4|Grp: 1..2|VERSION(1) SORTING(Field1) WHERE(Field2=1(1..2))|1,2,3,4,');
        Observer.Expect('after_reset', 'Yes|4||VERSION(1) SORTING(Field1)|1,2,3,4,');
        Observer.Expect('db_count', '5');
        Observer.Verify();
    end;
}
