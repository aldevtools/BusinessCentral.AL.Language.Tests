// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 70701, 70702, 70703, 70704
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.Get(RecordId) for the same table, another table, a missing row, a blank RecordId, and with filters set
// BC versions: 29 (27 and 28 by CI)

codeunit 70724 "LT P68 Get RecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGetFlt(var R: Record "LT P68 Flt"; Rid: RecordId)
    begin
        R.Get(Rid);
    end;

    [TryFunction]
    local procedure TryGetKeyed(var R: Record "LT P68 Keyed"; Rid: RecordId)
    begin
        R.Get(Rid);
    end;

    [TryFunction]
    local procedure TryGetComp(var R: Record "LT P68 Comp"; Rid: RecordId)
    begin
        R.Get(Rid);
    end;

    [TryFunction]
    local procedure TryGetOther(var R: Record "LT P68 Other"; Rid: RecordId)
    begin
        R.Get(Rid);
    end;

    [TryFunction]
    local procedure TryRRGet(var RR: RecordRef; Rid: RecordId)
    begin
        RR.Get(Rid);
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Seed()
    var
        F: Record "LT P68 Flt";
        K: Record "LT P68 Keyed";
        C: Record "LT P68 Comp";
        O: Record "LT P68 Other";
    begin
        F.DeleteAll();
        K.DeleteAll();
        C.DeleteAll();
        O.DeleteAll();
        F."No." := 1;
        F.Txt := 'F1';
        F.Int := 10;
        F.Insert();
        F."No." := 2;
        F.Txt := 'F2';
        F.Int := 20;
        F.Insert();
        K.Code := 'K1';
        K.Val := 100;
        K.Insert();
        C.Grp := 1;
        C.Sub := 2;
        C.Val := 'C12';
        C.Insert();
        O.Id := 1;
        O.Txt := 'O1';
        O.Insert();
    end;

    [Test]
    procedure Get_RecordId_Same_Table()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        R2: Record "LT P68 Flt";
        Rid: RecordId;
    begin
        Seed();
        R.Get(2);
        Rid := R.RecordId;
        Observer.Observe('rid', Format(Rid));
        Observer.Observe('get', Outcome(TryGetFlt(R2, Rid)));
        Observer.Observe('txt', R2.Txt);
        Observer.Observe('int', Format(R2.Int));
        R2.Init();
        R2.Get(R.RecordId);
        Observer.Observe('after-init-txt', R2.Txt);
        Observer.Expect('rid', 'LT P68 Flt: 2');
        Observer.Expect('get', 'ok');
        Observer.Expect('txt', 'F2');
        Observer.Expect('int', '20');
        Observer.Expect('after-init-txt', 'F2');
        Observer.Verify();
    end;

    [Test]
    procedure Get_RecordId_Composite_And_Keyed()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT P68 Comp";
        C2: Record "LT P68 Comp";
        K: Record "LT P68 Keyed";
        K2: Record "LT P68 Keyed";
    begin
        Seed();
        C.Get(1, 2);
        Observer.Observe('comp-rid', Format(C.RecordId));
        Observer.Observe('comp-get', Outcome(TryGetComp(C2, C.RecordId)));
        Observer.Observe('comp-val', C2.Val);
        K.Get('K1');
        Observer.Observe('keyed-rid', Format(K.RecordId));
        Observer.Observe('keyed-get', Outcome(TryGetKeyed(K2, K.RecordId)));
        Observer.Observe('keyed-val', Format(K2.Val));
        Observer.Expect('comp-rid', 'LT P68 Comp: 1,2');
        Observer.Expect('comp-get', 'ok');
        Observer.Expect('comp-val', 'C12');
        Observer.Expect('keyed-rid', 'LT P68 Keyed: K1');
        Observer.Expect('keyed-get', 'ok');
        Observer.Expect('keyed-val', '100');
        Observer.Verify();
    end;

    [Test]
    procedure Get_RecordId_Other_Table()
    var
        Observer: Codeunit "Probe Observer";
        F: Record "LT P68 Flt";
        K: Record "LT P68 Keyed";
        C: Record "LT P68 Comp";
        O: Record "LT P68 Other";
        Rid: RecordId;
    begin
        Seed();
        F.Get(1);
        Rid := F.RecordId;
        Observer.Observe('flt-to-keyed', Outcome(TryGetKeyed(K, Rid)));
        Observer.Observe('flt-to-comp', Outcome(TryGetComp(C, Rid)));
        Observer.Observe('flt-to-other', Outcome(TryGetOther(O, Rid)));
        Observer.Observe('other-same-key-shape', Format(O.Id) + '|' + O.Txt);
        K.Get('K1');
        Observer.Observe('keyed-to-flt', Outcome(TryGetFlt(F, K.RecordId)));
        Observer.Expect('flt-to-keyed', 'A RecordID from table ''LT P68 Flt'' cannot be used with a record from table ''LT P68 Keyed''.|DB:Ok');
        Observer.Expect('flt-to-comp', 'A RecordID from table ''LT P68 Flt'' cannot be used with a record from table ''LT P68 Comp''.|DB:Ok');
        Observer.Expect('flt-to-other', 'A RecordID from table ''LT P68 Flt'' cannot be used with a record from table ''LT P68 Other''.|DB:Ok');
        Observer.Expect('other-same-key-shape', '0|');
        Observer.Expect('keyed-to-flt', 'A RecordID from table ''LT P68 Keyed'' cannot be used with a record from table ''LT P68 Flt''.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Get_RecordId_Missing_Row_And_Blank()
    var
        Observer: Codeunit "Probe Observer";
        F: Record "LT P68 Flt";
        F2: Record "LT P68 Flt";
        Blank: RecordId;
        Rid: RecordId;
    begin
        Seed();
        F.Get(2);
        Rid := F.RecordId;
        F.Delete();
        Observer.Observe('deleted-row', Outcome(TryGetFlt(F2, Rid)));
        Observer.Observe('blank-rid-format', Format(Blank));
        Observer.Observe('blank-rid', Outcome(TryGetFlt(F2, Blank)));
        Observer.Expect('deleted-row', 'The LT P68 Flt does not exist. Identification fields and values: No.=''2''|DB:RecordNotFound');
        Observer.Expect('blank-rid-format', '');
        Observer.Expect('blank-rid', 'A RecordID from table '''' cannot be used with a record from table ''LT P68 Flt''.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Get_RecordId_With_Filters()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        Rid: RecordId;
    begin
        Seed();
        R.Get(1);
        Rid := R.RecordId;
        R.Reset();
        R.SetRange(Int, 99);
        Observer.Observe('filtered-get', Outcome(TryGetFlt(R, Rid)));
        Observer.Observe('filtered-txt', R.Txt);
        Observer.Observe('filter-kept', R.GetFilter(Int));
        R.SetRange("No.", 2);
        Observer.Observe('pk-filter-get', Outcome(TryGetFlt(R, Rid)));
        Observer.Observe('pk-filter-no', Format(R."No."));
        Observer.Expect('filtered-get', 'ok');
        Observer.Expect('filtered-txt', 'F1');
        Observer.Expect('filter-kept', '99');
        Observer.Expect('pk-filter-get', 'ok');
        Observer.Expect('pk-filter-no', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Get_RecordId_Via_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        K: Record "LT P68 Keyed";
        RR: RecordRef;
        RR2: RecordRef;
        Rid: RecordId;
    begin
        Seed();
        R.Get(2);
        RR.GetTable(R);
        Rid := RR.RecordId;
        Observer.Observe('rr-rid-equals', Format(Rid = R.RecordId));
        Clear(R);
        Observer.Observe('get-from-rr-rid', Format(R.Get(Rid)));
        Observer.Observe('txt', R.Txt);
        RR2.Open(Database::"LT P68 Keyed");
        Observer.Observe('rr2-get', Format(RR2.Get(K.RecordId)));
        K.Get('K1');
        Observer.Observe('rr2-get-keyed', Format(RR2.Get(K.RecordId)));
        Observer.Observe('rr2-val', Format(RR2.Field(2).Value));
        Observer.Observe('rr2-get-other-table', Outcome(TryRRGet(RR2, Rid)));
        Observer.Expect('rr-rid-equals', 'Yes');
        Observer.Expect('get-from-rr-rid', 'Yes');
        Observer.Expect('txt', 'F2');
        Observer.Expect('rr2-get', 'No');
        Observer.Expect('rr2-get-keyed', 'Yes');
        Observer.Expect('rr2-val', '100');
        Observer.Expect('rr2-get-other-table', 'ok');
        Observer.Verify();
    end;
}
