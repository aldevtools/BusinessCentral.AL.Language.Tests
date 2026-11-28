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
//   and modified the row, after Delete, after Get, and after a second Insert under another key. Not probed: I4 after Commit (a
//   Commit in a test keeps the rows past the test and the run, so later cells would read another state).
//   Readings as in BlobInsertUnloaded.al: own = the record's own Blobs (after the CalcFields where the cell names one), before and
//   stored = a fresh record's Get of the stored row, HasValue before and the Blobs after CalcFields.
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session) on 2026-11-28 with an invented app holding
//   these objects (AL 18.0.43.1464, run by al runtests of AL tool 18.1.43.24897); the values are those readings, turned into
//   Expect and Verify by convert.py verbatim, asserted on BC 28 and later (#if BC28PLUS). On BC 27.5 (#else) every test is an
//   observe round, red on purpose: it ends with Finish(); one following commit asserts the 27.5 readings.
//   Facts (BC 29.0.54011.57673), the same for the three Blob fields:
//   - Every read origin (FindLast, Find('-'), Find('='), Find('+'), the second row of a FindSet loop, a RecordRef FindFirst and
//     RecordRef.Insert) stores no Blob, as Get, FindFirst and FindSet do; the inserting record answers HasValue Yes, empty.
//   - Modify(true), RecordRef.Modify and a by-value Modify onto OTHER leave OTHER's Blobs as they were.
//   - A Modify after ChangeCompany onto the other company's row raises 'The changes to the LT BIU Row record cannot be saved
//     because some information on the page is not up-to-date. ...' (DB:RecordChanged).
//   - A temporary row written with a stream, read with Get and renamed: after a new key and Insert, or after Modify, the row answers
//     HasValue Yes before CalcFields and No (empty) after it; the record reads empty.
//   - A guarded Insert onto an existing key returns No and leaves no mark: after Modify, CalcFields reads OTHER's Blobs; on the
//     source's own key CalcFields reads 'hello'. Under asserterror (DB:RecordExists, which rolls the test's writes back; the seed is written again), CalcFields reads OTHER's
//     Blobs too.
//   - The I4 state (HasValue Yes, empty) outlives a Modify and a second Insert under another key (which stores no Blob
//     either); after another variable wrote 'x' into Body and modified the row, CalcFields reads 'x' for Body and Raw and Ext stay
//     HasValue Yes, empty; after Delete or Get, CalcFields answers HasValue No.
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('row', 'OTHER');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[other]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[other]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[other]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('other_company_found', 'Yes');
        Observer.Expect('modify|text', 'The changes to the LT BIU Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''SRC''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('insert', 'No');
        Observer.Expect('own_body', 'hasValue=Yes text=[other]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[other]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('insert', 'No');
        Observer.Expect('own_body', 'hasValue=Yes text=[hello]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[hello-raw]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[hello-ext]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[hello]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[hello-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[hello-ext]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
        // asserterror rolled the seed back; seed again so OTHER holds 'other' when C (key OTHER) calculates its Blobs.
        Probe.Seed();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
#if BC28PLUS
        Observer.Expect('insert_error', 'DB:RecordExists');
        Observer.Expect('own_body', 'hasValue=Yes text=[other]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[x]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=No text=[]');
        Observer.Expect('own_raw', 'hasValue=No text=[]');
        Observer.Expect('own_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=No text=[]');
        Observer.Expect('own_raw', 'hasValue=No text=[]');
        Observer.Expect('own_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
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
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;
}
