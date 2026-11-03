// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-return-values
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71160, codeunit 71161
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): a field read off a procedure result
// Facts: GetRec(Code).Field when the row does not exist, a record that was Init'ed inside the procedure (InitValue), nested in expressions, with a quoted field name, from a var-less temporary record, chained twice
// BC versions: 29 (27 and 28 by CI)

table 71160 "LT P69 Ret Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Quoted Name"; Text[30]) { }
        field(3; Qty; Decimal) { InitValue = 7; }
        field(4; Flag; Boolean) { InitValue = true; }
        field(5; Kind; Option) { OptionMembers = Zero,One,Two; InitValue = Two; }
        field(6; "Posted On"; Date) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

// Corpus #664 item 35: a procedure returning a complex type. The holder returns its own global variables; the test changes the returned
// value and reads the global back, which shows whether the returned value is a copy or the same instance.
interface "LT BM IRet Counter"
{
    procedure Bump();
    procedure Value(): Integer;
}

codeunit 81951 "LT BM Ret Counter" implements "LT BM IRet Counter"
{
    var
        N: Integer;

    procedure Bump()
    begin
        N += 1;
    end;

    procedure Value(): Integer
    begin
        exit(N);
    end;
}

codeunit 81952 "LT BM Ret Holder"
{
    var
        Json: JsonObject;
        Tb: TextBuilder;
        Dict: Dictionary of [Text, Integer];
        Lst: List of [Integer];
        Counter: Codeunit "LT BM Ret Counter";
        Row: Record "LT P69 Ret Row";
        TempRow: Record "LT P69 Ret Row" temporary;

    procedure GetJson(): JsonObject
    begin
        exit(Json);
    end;

    procedure JsonText(): Text
    var
        T: Text;
    begin
        Json.WriteTo(T);
        exit(T);
    end;

    procedure GetTb(): TextBuilder
    begin
        exit(Tb);
    end;

    procedure TbText(): Text
    begin
        exit(Tb.ToText());
    end;

    procedure GetDict(): Dictionary of [Text, Integer]
    begin
        exit(Dict);
    end;

    procedure DictCount(): Integer
    begin
        exit(Dict.Count());
    end;

    procedure GetList(): List of [Integer]
    begin
        exit(Lst);
    end;

    procedure ListCount(): Integer
    begin
        exit(Lst.Count());
    end;

    procedure GetCounter(): Codeunit "LT BM Ret Counter"
    begin
        exit(Counter);
    end;

    procedure GetCounterInterface(): Interface "LT BM IRet Counter"
    var
        I: Interface "LT BM IRet Counter";
    begin
        I := Counter;
        exit(I);
    end;

    procedure CounterValue(): Integer
    begin
        exit(Counter.Value());
    end;

    procedure GetFilteredRow(): Record "LT P69 Ret Row"
    begin
        Row.SetRange(Code, 'A');
        Row.SetFilter(Qty, '>1');
        exit(Row);
    end;

    procedure RowFilters(): Text
    begin
        exit(Row.GetFilters());
    end;

    procedure GetTempRow(): Record "LT P69 Ret Row" temporary
    begin
        TempRow.Code := 'H1';
        if TempRow.Insert() then;
        exit(TempRow);
    end;

    procedure TempRowCount(): Integer
    begin
        exit(TempRow.Count());
    end;
}

codeunit 71161 "LT P69 Proc Result Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure GetRow(CodeValue: Code[10]): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        if not Row.Get(CodeValue) then
            Row.Init();
        exit(Row);
    end;

    local procedure InitOnly(): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.Init();
        exit(Row);
    end;

    local procedure InitWithKey(CodeValue: Code[10]): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.Init();
        Row.Code := CodeValue;
        exit(Row);
    end;

    local procedure Temp(): Record "LT P69 Ret Row" temporary
    var
        Row: Record "LT P69 Ret Row" temporary;
    begin
        Row.Code := 'TMP';
        Row."Quoted Name" := 'temporary';
        Row.Insert();
        exit(Row);
    end;

    local procedure Seed()
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row."Quoted Name" := 'alpha';
        Row.Qty := 2.5;
        Row.Flag := false;
        Row.Kind := Row.Kind::One;
        Row."Posted On" := DMY2Date(5, 6, 2021);
        Row.Insert();
    end;

    [Test]
    procedure ProcResult_ExistingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', GetRow('A').Code);
        Observer.Observe('quoted', GetRow('A')."Quoted Name");
        Observer.Observe('qty', Format(GetRow('A').Qty));
        Observer.Observe('flag', Format(GetRow('A').Flag));
        Observer.Observe('kind', Format(GetRow('A').Kind));
        Observer.Observe('date', Format(GetRow('A')."Posted On", 0, 9));
        Observer.Observe('qty_expr', Format(GetRow('A').Qty * 2 + 1));
        Observer.Observe('text_expr', GetRow('A')."Quoted Name" + '-' + GetRow('A').Code);
        Observer.Observe('compare', Format(GetRow('A').Qty > 2));
        Observer.Observe('date_expr', Format(GetRow('A')."Posted On" + 1, 0, 9));
        Observer.Observe('strlen', Format(StrLen(GetRow('A')."Quoted Name")));
        Observer.Expect('code', 'A');
        Observer.Expect('quoted', 'alpha');
        Observer.Expect('qty', '2.5');
        Observer.Expect('flag', 'No');
        Observer.Expect('kind', 'One');
        Observer.Expect('date', '2021-06-05');
        Observer.Expect('qty_expr', '6');
        Observer.Expect('text_expr', 'alpha-A');
        Observer.Expect('compare', 'Yes');
        Observer.Expect('date_expr', '2021-06-06');
        Observer.Expect('strlen', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_MissingRowInit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', GetRow('NONE').Code);
        Observer.Observe('quoted', GetRow('NONE')."Quoted Name");
        Observer.Observe('qty_initvalue', Format(GetRow('NONE').Qty));
        Observer.Observe('flag_initvalue', Format(GetRow('NONE').Flag));
        Observer.Observe('kind_initvalue', Format(GetRow('NONE').Kind));
        Observer.Observe('date', Format(GetRow('NONE')."Posted On", 0, 9));
        Observer.Observe('qty_expr', Format(GetRow('NONE').Qty * 2));
        Observer.Observe('text_len', Format(StrLen(GetRow('NONE')."Quoted Name")));
        Observer.Expect('code', '');
        Observer.Expect('quoted', '');
        Observer.Expect('qty_initvalue', '7');
        Observer.Expect('flag_initvalue', 'Yes');
        Observer.Expect('kind_initvalue', 'Two');
        Observer.Expect('date', '');
        Observer.Expect('qty_expr', '14');
        Observer.Expect('text_len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_InitOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code', InitOnly().Code);
        Observer.Observe('qty', Format(InitOnly().Qty));
        Observer.Observe('flag', Format(InitOnly().Flag));
        Observer.Observe('kind', Format(InitOnly().Kind));
        Observer.Observe('kind_ordinal', Format(InitOnly().Kind, 0, 2));
        Observer.Observe('with_key_code', InitWithKey('KEY').Code);
        Observer.Observe('with_key_qty', Format(InitWithKey('KEY').Qty));
        Observer.Observe('with_key_name', InitWithKey('KEY')."Quoted Name");
        Observer.Expect('code', '');
        Observer.Expect('qty', '7');
        Observer.Expect('flag', 'Yes');
        Observer.Expect('kind', 'Two');
        Observer.Expect('kind_ordinal', '2');
        Observer.Expect('with_key_code', 'KEY');
        Observer.Expect('with_key_qty', '7');
        Observer.Expect('with_key_name', '');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Ret Row";
    begin
        Seed();
        Observer.Observe('code', Temp().Code);
        Observer.Observe('name', Temp()."Quoted Name");
        Observer.Observe('qty', Format(Temp().Qty));
        Observer.Observe('stored_rows', Format(Row.Count()));
        Observer.Observe('is_temporary', Format(Temp().IsTemporary()));
        Observer.Expect('code', 'TMP');
        Observer.Expect('name', 'temporary');
        Observer.Expect('qty', '7');
        Observer.Expect('stored_rows', '1');
        Observer.Expect('is_temporary', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ProcResult_MethodOnResult()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tablename', GetRow('A').TableName());
        Observer.Observe('count', Format(GetRow('A').Count()));
        Observer.Observe('fieldno', Format(GetRow('A').FieldNo(Qty)));
        Observer.Observe('getfilters', GetRow('A').GetFilters());
        Observer.Observe('rowcount_missing', Format(GetRow('NONE').Count()));
        Observer.Expect('tablename', 'LT P69 Ret Row');
        Observer.Expect('count', '1');
        Observer.Expect('fieldno', '3');
        Observer.Expect('getfilters', '');
        Observer.Expect('rowcount_missing', '1');
        Observer.Verify();
    end;

    // Corpus #664 item 35 (see the holder codeunit above): copy or same instance for each returned type.
    [Test]
    procedure BM_ProcResult_ComplexTypes_CopyOrShared()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT BM Ret Holder";
        J: JsonObject;
        T: TextBuilder;
        D: Dictionary of [Text, Integer];
        L: List of [Integer];
        C: Codeunit "LT BM Ret Counter";
        I: Interface "LT BM IRet Counter";
        R: Record "LT P69 Ret Row";
        TR: Record "LT P69 Ret Row" temporary;
    begin
        Seed();
        J := Holder.GetJson();
        J.Add('k', 1);
        Observer.Observe('json_holder_after_add', Holder.JsonText());
        T := Holder.GetTb();
        T.Append('x');
        Observer.Observe('textbuilder_holder_after_append', '[' + Holder.TbText() + ']');
        D := Holder.GetDict();
        D.Add('a', 1);
        Observer.Observe('dictionary_holder_count', Format(Holder.DictCount()));
        L := Holder.GetList();
        L.Add(1);
        Observer.Observe('list_holder_count', Format(Holder.ListCount()));
        C := Holder.GetCounter();
        C.Bump();
        Observer.Observe('codeunit_holder_after_bump', Format(Holder.CounterValue()));
        I := Holder.GetCounterInterface();
        I.Bump();
        Observer.Observe('interface_holder_after_bump', Format(Holder.CounterValue()));
        Observer.Observe('interface_value', Format(I.Value()));
        R := Holder.GetFilteredRow();
        Observer.Observe('record_filters', R.GetFilters());
        Observer.Observe('record_count', Format(R.Count()));
        R.SetRange(Code);
        Observer.Observe('holder_filters_after_caller_reset', Holder.RowFilters());
        TR := Holder.GetTempRow();
        Observer.Observe('temp_is_temporary', Format(TR.IsTemporary()));
        Observer.Observe('temp_count', Format(TR.Count()));
        TR.Code := 'C1';
        TR.Insert();
        Observer.Observe('temp_caller_count', Format(TR.Count()));
        Observer.Observe('temp_holder_count', Format(Holder.TempRowCount()));
        Observer.Expect('json_holder_after_add', '{"k":1}');
        Observer.Expect('textbuilder_holder_after_append', '[x]');
        Observer.Expect('dictionary_holder_count', '1');
        Observer.Expect('list_holder_count', '1');
        Observer.Expect('codeunit_holder_after_bump', '1');
        Observer.Expect('interface_holder_after_bump', '2');
        Observer.Expect('interface_value', '2');
        Observer.Expect('record_filters', '');
        Observer.Expect('record_count', '1');
        Observer.Expect('holder_filters_after_caller_reset', 'Code: A, Qty: >1');
        Observer.Expect('temp_is_temporary', 'Yes');
        Observer.Expect('temp_count', '0');
        Observer.Expect('temp_caller_count', '1');
        Observer.Expect('temp_holder_count', '1');
        Observer.Verify();
    end;

    // Writer RN (al-runner issue 5757): a procedure that returns a Record and leaves by a bare `exit;` (unnamed and named return
    // value) or by falling off its end: the field values (the table has InitValue fields), Get on the blank key, the receiving
    // variable's earlier values and filters.
    // Measured (BC 29.0; 27.5 and 28.5 by CI): a bare exit or no exit returns a record with the InitValue values (Qty 7, Flag Yes,
    // Kind Two) and blank fields elsewhere; a named return value keeps what was assigned to it; the receiving variable keeps its filters;
    // Get on the blank key finds nothing.
    local procedure RnBareExit(CodeValue: Code[10]): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        if CodeValue = '' then
            exit;
        Row.Get(CodeValue);
        exit(Row);
    end;

    local procedure RnNamedBareExit(CodeValue: Code[10]) Result: Record "LT P69 Ret Row"
    begin
        Result."Quoted Name" := 'named';
        if CodeValue = '' then
            exit;
        Result.Get(CodeValue);
    end;

    local procedure RnNoExit(): Record "LT P69 Ret Row"
    var
        Row: Record "LT P69 Ret Row";
    begin
        Row.Get('A');
    end;

    local procedure RnDescribe(var Row: Record "LT P69 Ret Row"): Text
    begin
        exit('code=' + Row.Code + ';name=' + Row."Quoted Name" + ';qty=' + Format(Row.Qty) + ';flag=' + Format(Row.Flag) +
            ';kind=' + Format(Row.Kind) + ';date=' + Format(Row."Posted On", 0, 9));
    end;

    [Test]
    procedure RN_BareExit_ReturnsRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Ret Row";
    begin
        Seed();
        Row.Get('A');
        Row.SetRange(Code, 'A');
        Row := RnBareExit('');
        Observer.Observe('assigned', RnDescribe(Row));
        Observer.Observe('assigned_filters', Row.GetFilters());
        Observer.Observe('get_blank', Format(Row.Get(Row.Code)));
        Observer.Observe('direct_code', '[' + RnBareExit('').Code + ']');
        Observer.Observe('direct_qty', Format(RnBareExit('').Qty));
        Observer.Observe('direct_flag', Format(RnBareExit('').Flag));
        Observer.Observe('direct_kind', Format(RnBareExit('').Kind));
        Row := RnBareExit('A');
        Observer.Observe('found', RnDescribe(Row));
        Observer.Expect('assigned', 'code=;name=;qty=7;flag=Yes;kind=Two;date=');
        Observer.Expect('assigned_filters', 'Code: A');
        Observer.Expect('get_blank', 'No');
        Observer.Expect('direct_code', '[]');
        Observer.Expect('direct_qty', '7');
        Observer.Expect('direct_flag', 'Yes');
        Observer.Expect('direct_kind', 'Two');
        Observer.Expect('found', 'code=A;name=alpha;qty=2.5;flag=No;kind=One;date=2021-06-05');
        Observer.Verify();
    end;

    [Test]
    procedure RN_NamedBareExit_And_NoExit_ReturnRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Ret Row";
    begin
        Seed();
        Row := RnNamedBareExit('');
        Observer.Observe('named_blank', RnDescribe(Row));
        Row := RnNamedBareExit('A');
        Observer.Observe('named_found', RnDescribe(Row));
        Row.Get('A');
        Row := RnNoExit();
        Observer.Observe('no_exit', RnDescribe(Row));
        Observer.Expect('named_blank', 'code=;name=named;qty=7;flag=Yes;kind=Two;date=');
        Observer.Expect('named_found', 'code=A;name=alpha;qty=2.5;flag=No;kind=One;date=2021-06-05');
        Observer.Expect('no_exit', 'code=;name=;qty=7;flag=Yes;kind=Two;date=');
        Observer.Verify();
    end;
}
