// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 73780, table extension 73780 and helper codeunit 73780 of BlobInsertUnloaded.al; own
//   test codeunit 73783
// Probe (AL Runner issue 9286, the shapes named in the review of AL Runner pull request 9301): follow-up of BlobInsertUnloaded.al.
//   The same table and seed (SRC with 'hello', 'hello-raw', 'hello-ext'; OTHER with 'other', ...; EMPTY with no Blob).
//   Read origin (C := the source, Blobs not loaded, new key NEW, Insert): the source read with FindLast, Find('-'), Find('='),
//   Find('+'), Next (the second row of a FindSet loop, OTHER), and a RecordRef opened with Open, read with FindFirst, field 1 set
//   and RecordRef.Insert.
//   Modify forms onto the stored row OTHER: Modify(true), RecordRef.Modify, a by-value copy modified in the callee, and a Modify
//   after ChangeCompany into the other company's row SRC.
//   A temporary row written with a stream (not stored by CalcFields), then Rename, then a new key and Insert, or Modify.
//   A failed Insert onto an existing key: guarded and followed by Modify, guarded alone on the source's own key, and under
//   asserterror; each ends with CalcFields.
//   The scope of I4 (CalcFields on the inserting record right after its Insert): after a Modify, after another variable wrote 'x'
//   and modified the row, after Commit, after Delete, after Get, and after a second Insert under another key.
//   Readings as in BlobInsertUnloaded.al: own = the record's own Blobs (after the CalcFields where the cell names one), before and
//   stored = a fresh record's Get of the stored row, HasValue before and the Blobs after CalcFields.
//   Observe round: every test ends with Observer.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
// BC versions: 27, 28, 29 by CI
codeunit 73783 "LT BIU Origin Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertCopy(var Observer: Codeunit "Probe Observer"; var Src: Record "LT BIU Row")
    var
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
    begin
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
    end;

    // O1-O4: the source read with FindLast and Find('-' | '=' | '+') on a filter to SRC.
    [Test]
    procedure O1_FindLast()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetRange("No.", 'SRC');
        Src.FindLast();
        InsertCopy(Observer, Src);
        Observer.Finish();
    end;

    [Test]
    procedure O2_FindMinus()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetRange("No.", 'SRC');
        Src.Find('-');
        InsertCopy(Observer, Src);
        Observer.Finish();
    end;

    [Test]
    procedure O3_FindEquals()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src."No." := 'SRC';
        Src.Find('=');
        InsertCopy(Observer, Src);
        Observer.Finish();
    end;

    [Test]
    procedure O4_FindPlus()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetRange("No.", 'SRC');
        Src.Find('+');
        InsertCopy(Observer, Src);
        Observer.Finish();
    end;

    // O5: the second row of a FindSet loop (EMPTY, then OTHER), copied and inserted.
    [Test]
    procedure O5_NextInFindSet()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.FindSet();
        Src.Next();
        Observer.Observe('row', Src."No.");
        InsertCopy(Observer, Src);
        Observer.Finish();
    end;

    // O6: RecordRef.Open, a filter to SRC, FindFirst, field 1 set to NEW, RecordRef.Insert.
    [Test]
    procedure O6_RecordRefOpenFindFirstInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Probe.Seed();
        RR.Open(Database::"LT BIU Row");
        FR := RR.Field(1);
        FR.SetRange('SRC');
        RR.FindFirst();
        FR.SetRange();
        FR.Value := 'NEW';
        RR.Insert();
        Probe.Stored(Observer, 'NEW');
        Observer.Finish();
    end;

    // M4: C := Src under the key OTHER, Modify(true).
    [Test]
    procedure M4_ModifyTrueOntoOther()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'OTHER';
        C.Modify(true);
        Probe.Stored(Observer, 'OTHER');
        Observer.Finish();
    end;

    // M5: RecordRef.GetTable(Src), field 1 set to OTHER, RecordRef.Modify.
    [Test]
    procedure M5_RecordRefModifyOntoOther()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Probe.Seed();
        Src.Get('SRC');
        RR.GetTable(Src);
        FR := RR.Field(1);
        FR.Value := 'OTHER';
        RR.Modify();
        Probe.Stored(Observer, 'OTHER');
        Observer.Finish();
    end;

    local procedure ModifyByValue(C: Record "LT BIU Row")
    begin
        C."No." := 'OTHER';
        C.Modify();
    end;

    // M6: a by-value copy of Src, modified in the callee under the key OTHER.
    [Test]
    procedure M6_ByValueModifyOntoOther()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        ModifyByValue(Src);
        Probe.Stored(Observer, 'OTHER');
        Observer.Finish();
    end;

    // M7: C := Src (this company), C.ChangeCompany(<other>), Modify of the other company's row SRC (holding 'there', ...), under
    // asserterror: the Modify raises (see the header).
    [Test]
    procedure M7_ChangeCompanyModify()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Company: Record Company;
        Src: Record "LT BIU Row";
        Other: Record "LT BIU Row";
        C: Record "LT BIU Row";
        OtherName: Text;
    begin
        Probe.Seed();
        Company.SetFilter(Name, '<>%1', CompanyName());
        if Company.FindFirst() then
            OtherName := Company.Name;
        Observer.Observe('other_company_found', Format(OtherName <> ''));
        if OtherName <> '' then begin
            Other.ChangeCompany(OtherName);
            Other.DeleteAll();
            Other.Init();
            Other."No." := 'SRC';
            Probe.Write(Other, 'there', 'there-raw', 'there-ext');
            Other.Insert();
            Src.Get('SRC');
            C := Src;
            C.ChangeCompany(OtherName);
            C.Note := 'modified';
            // asserterror rolls the test's writes back (the seed rows and the other company's row included), so nothing is read after it.
            asserterror C.Modify();
            Observer.ObserveError('modify');
        end;
        Observer.Finish();
    end;

    // T1: a temporary row written with a stream and inserted (T1), read with Get, Rename('T2'), then the new key T3 and Insert.
    [Test]
    procedure T1_TempRenameThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        T: Record "LT BIU Row" temporary;
    begin
        T.Init();
        T."No." := 'T1';
        Probe.Write(T, 'mem', 'mem-raw', 'mem-ext');
        T.Insert();
        T.Get('T1');
        T.Rename('T2');
        T."No." := 'T3';
        T.Insert();
        Probe.Own(Observer, T);
        Probe.StoredTemp(Observer, T, 'T3');
        Observer.Finish();
    end;

    // T2: the same Rename, then Note changed and Modify of the renamed row T2.
    [Test]
    procedure T2_TempRenameThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        T: Record "LT BIU Row" temporary;
    begin
        T.Init();
        T."No." := 'T1';
        Probe.Write(T, 'mem', 'mem-raw', 'mem-ext');
        T.Insert();
        T.Get('T1');
        T.Rename('T2');
        T.Note := 'modified';
        T.Modify();
        Probe.Own(Observer, T);
        Probe.StoredTemp(Observer, T, 'T2');
        Observer.Finish();
    end;

    // F1: C := Src under the key OTHER, a guarded Insert (fails: OTHER exists), then Modify and C.CalcFields.
    [Test]
    procedure F1_GuardedInsertThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'OTHER';
        Observer.Observe('insert', Format(C.Insert()));
        C.Modify();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'OTHER');
        Observer.Finish();
    end;

    // F2: a guarded Insert of the source itself on its own key (fails), then Src.CalcFields.
    [Test]
    procedure F2_GuardedInsertOwnKey()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Observer.Observe('insert', Format(Src.Insert()));
        Src.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, Src);
        Probe.Stored(Observer, 'SRC');
        Observer.Finish();
    end;

    // F3: C := Src under the key OTHER, asserterror C.Insert(), then C.CalcFields.
    [Test]
    procedure F3_AssertErrorInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'OTHER';
        asserterror C.Insert();
        Observer.Observe('insert_error', GetLastErrorCode());
        ClearLastError();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    local procedure CopyInsert(var C: Record "LT BIU Row")
    var
        Src: Record "LT BIU Row";
    begin
        Src.Get('SRC');
        C := Src;
        C."No." := 'NEW';
        C.Insert();
    end;

    // S1: C01's Insert, then Modify of C, then C.CalcFields.
    [Test]
    procedure S1_InsertModifyCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        CopyInsert(C);
        C.Note := 'modified';
        C.Modify();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    // S2: C01's Insert, then a second variable writes 'x' into NEW's Body and modifies the row, then C.CalcFields.
    [Test]
    procedure S2_InsertOtherWriteCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
        Second: Record "LT BIU Row";
    begin
        Probe.Seed();
        CopyInsert(C);
        Second.Get('NEW');
        Probe.Write(Second, 'x', '', '');
        Second.Modify();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    // S3: C01's Insert, then Commit, then C.CalcFields.
    [Test]
    procedure S3_InsertCommitCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        CopyInsert(C);
        Commit();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    // S4: C01's Insert, then C.Delete, then C.CalcFields.
    [Test]
    procedure S4_InsertDeleteCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        CopyInsert(C);
        C.Delete();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    // S5: C01's Insert, then C.Get('NEW'), then C.CalcFields.
    [Test]
    procedure S5_InsertGetCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        CopyInsert(C);
        C.Get('NEW');
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    // S6: C01's Insert, then the key NEW2 and a second Insert, then C.CalcFields; and what NEW2 stores.
    [Test]
    procedure S6_InsertSecondInsertCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        CopyInsert(C);
        C."No." := 'NEW2';
        C.Insert();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW2');
        Observer.Finish();
    end;
}
