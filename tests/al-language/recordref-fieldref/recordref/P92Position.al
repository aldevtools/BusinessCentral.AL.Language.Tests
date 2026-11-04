// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-getposition-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: RecordRef.GetPosition / SetPosition with and without field names, escaping, round trip, composite keys, other tables
// BC versions: 29 (27 and 28 by CI)

codeunit 72212 "LT P92 Position"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetPos(var RecRef: RecordRef; Pos: Text)
    begin
        RecRef.SetPosition(Pos);
    end;

    local procedure SetPosOutcome(var RecRef: RecordRef; Pos: Text): Text
    begin
        if TrySetPos(RecRef, Pos) then
            exit('ok');
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetPosition_NamesAndDefault()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(1).SetRange('A2');
        RecRef.FindFirst();
        Observer.Observe('default', RecRef.GetPosition());
        Observer.Observe('names', RecRef.GetPosition(true));
        Observer.Observe('nonames', RecRef.GetPosition(false));
        Observer.Observe('default_equals_names', Format(RecRef.GetPosition() = RecRef.GetPosition(true)));
        RecRef.Close();
        Observer.Expect('default', 'Code Cap=CONST(A2)');
        Observer.Expect('names', 'Code Cap=CONST(A2)');
        Observer.Expect('nonames', 'Field1=0(A2)');
        Observer.Expect('default_equals_names', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetPosition_CompositeKey()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        RecRef.FindFirst();
        Observer.Observe('first_names', RecRef.GetPosition(true));
        Observer.Observe('first_nonames', RecRef.GetPosition(false));
        RecRef.FindLast();
        Observer.Observe('last_names', RecRef.GetPosition(true));
        Observer.Observe('last_nonames', RecRef.GetPosition(false));
        RecRef.Close();
        Observer.Expect('first_names', 'Grp=CONST(A,B),Seq=CONST(3)');
        Observer.Expect('first_nonames', 'Field1=0(A,B),Field2=0(3)');
        Observer.Expect('last_names', 'Grp=CONST("X(1)"),Seq=CONST(4)');
        Observer.Expect('last_nonames', 'Field1=0("X(1)"),Field2=0(4)');
        Observer.Verify();
    end;

    [Test]
    procedure GetPosition_SpecialCharactersInKey()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        RecRef.Field(4).SetRange(30);
        RecRef.FindFirst();
        Observer.Observe('comma_names', RecRef.GetPosition(true));
        Observer.Observe('comma_nonames', RecRef.GetPosition(false));
        RecRef.Field(4).SetRange(40);
        RecRef.FindFirst();
        Observer.Observe('paren_names', RecRef.GetPosition(true));
        Observer.Observe('paren_nonames', RecRef.GetPosition(false));
        RecRef.Field(4).SetRange(50);
        RecRef.FindFirst();
        Observer.Observe('quote_names', RecRef.GetPosition(true));
        Observer.Observe('quote_nonames', RecRef.GetPosition(false));
        RecRef.Close();
        Observer.Expect('comma_names', 'Grp=CONST(A,B),Seq=CONST(3)');
        Observer.Expect('comma_nonames', 'Field1=0(A,B),Field2=0(3)');
        Observer.Expect('paren_names', 'Grp=CONST("X(1)"),Seq=CONST(4)');
        Observer.Expect('paren_nonames', 'Field1=0("X(1)"),Field2=0(4)');
        Observer.Expect('quote_names', 'Grp=CONST(Q''T),Seq=CONST(5)');
        Observer.Expect('quote_nonames', 'Field1=0(Q''T),Field2=0(5)');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_SpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Back: RecordRef;
        Pos: Text;
        i: Integer;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        Back.Open(72201);
        for i := 1 to 5 do begin
            RecRef.Reset();
            RecRef.Field(4).SetRange(i * 10);
            RecRef.FindFirst();
            Pos := RecRef.GetPosition(true);
            Back.Init();
            Back.SetPosition(Pos);
            Observer.Observe('names_find_' + Format(i), Format(Back.Find('=')));
            Observer.Observe('names_txt_' + Format(i), Format(Back.Field(3).Value));
        end;
        RecRef.Close();
        Back.Close();
        Observer.Expect('names_find_1', 'Yes');
        Observer.Expect('names_txt_1', 'one');
        Observer.Expect('names_find_2', 'Yes');
        Observer.Expect('names_txt_2', 'two');
        Observer.Expect('names_find_3', 'Yes');
        Observer.Expect('names_txt_3', 'comma');
        Observer.Expect('names_find_4', 'Yes');
        Observer.Expect('names_txt_4', 'paren');
        Observer.Expect('names_find_5', 'Yes');
        Observer.Expect('names_txt_5', 'quote');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_WithoutNames()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Back: RecordRef;
        Pos: Text;
        i: Integer;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        Back.Open(72201);
        for i := 1 to 5 do begin
            RecRef.Reset();
            RecRef.Field(4).SetRange(i * 10);
            RecRef.FindFirst();
            Pos := RecRef.GetPosition(false);
            Back.Init();
            Back.SetPosition(Pos);
            Observer.Observe('nonames_find_' + Format(i), Format(Back.Find('=')));
            Observer.Observe('nonames_txt_' + Format(i), Format(Back.Field(3).Value));
        end;
        RecRef.Close();
        Back.Close();
        Observer.Expect('nonames_find_1', 'Yes');
        Observer.Expect('nonames_txt_1', 'one');
        Observer.Expect('nonames_find_2', 'Yes');
        Observer.Expect('nonames_txt_2', 'two');
        Observer.Expect('nonames_find_3', 'Yes');
        Observer.Expect('nonames_txt_3', 'comma');
        Observer.Expect('nonames_find_4', 'Yes');
        Observer.Expect('nonames_txt_4', 'paren');
        Observer.Expect('nonames_find_5', 'Yes');
        Observer.Expect('nonames_txt_5', 'quote');
        Observer.Verify();
    end;

    [Test]
    procedure SetPosition_SetsKeyFieldsOnly()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Pos: Text;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        RecRef.Field(4).SetRange(20);
        RecRef.FindFirst();
        Pos := RecRef.GetPosition();
        RecRef.Init();
        Observer.Observe('after_init_grp', Format(RecRef.Field(1).Value));
        RecRef.SetPosition(Pos);
        Observer.Observe('grp', Format(RecRef.Field(1).Value));
        Observer.Observe('seq', Format(RecRef.Field(2).Value));
        Observer.Observe('txt_not_loaded', Format(RecRef.Field(3).Value));
        Observer.Observe('num_not_loaded', Format(RecRef.Field(4).Value));
        Observer.Observe('find_exact', Format(RecRef.Find('=')));
        Observer.Observe('txt_after_find', Format(RecRef.Field(3).Value));
        RecRef.Close();
        Observer.Expect('after_init_grp', 'G1');
        Observer.Expect('grp', 'G1');
        Observer.Expect('seq', '2');
        Observer.Expect('txt_not_loaded', '');
        Observer.Expect('num_not_loaded', '0');
        Observer.Expect('find_exact', 'Yes');
        Observer.Expect('txt_after_find', 'two');
        Observer.Verify();
    end;

    [Test]
    procedure SetPosition_Malformed()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72201);
        Observer.Observe('empty', SetPosOutcome(RecRef, ''));
        Observer.Observe('garbage', SetPosOutcome(RecRef, 'garbage'));
        Observer.Observe('unknown_field', SetPosOutcome(RecRef, 'Nope=CONST(1)'));
        Observer.Observe('unclosed', SetPosOutcome(RecRef, 'Grp=CONST(G1'));
        Observer.Observe('wrong_type', SetPosOutcome(RecRef, 'Grp=CONST(G1),Seq=CONST(abc)'));
        Observer.Observe('only_first_key_field', SetPosOutcome(RecRef, 'Grp=CONST(G1)'));
        Observer.Observe('too_many_values', SetPosOutcome(RecRef, 'G1,1,extra'));
        Observer.Observe('one_value_nonames', SetPosOutcome(RecRef, 'G1'));
        Observer.Observe('too_long_code', SetPosOutcome(RecRef, 'Grp=CONST(ABCDEFGHIJKLMNOP),Seq=CONST(1)'));
        RecRef.Close();
        Observer.Expect('empty', 'error|'''' is not a valid position specification for the LT P92 Pair table. The position must contain all the primary key fields, in order, and only primary key fields.|DB:Ok');
        Observer.Expect('garbage', 'error|Invalid expression of type: position.\garbage|DB:Ok');
        Observer.Expect('unknown_field', 'error|''Nope=CONST(1)'' is not a valid position specification for the LT P92 Pair table. The position must contain all the primary key fields, in order, and only primary key fields.|DB:Ok');
        Observer.Expect('unclosed', 'error|Invalid expression of type: position.\Grp=CONST(G1|DB:Ok');
        Observer.Expect('wrong_type', 'error|The value "abc" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('only_first_key_field', 'error|''Grp=CONST(G1)'' is not a valid position specification for the LT P92 Pair table. The position must contain all the primary key fields, in order, and only primary key fields.|DB:Ok');
        Observer.Expect('too_many_values', 'error|Invalid expression of type: position.\G1,1,extra|DB:Ok');
        Observer.Expect('one_value_nonames', 'error|Invalid expression of type: position.\G1|DB:Ok');
        Observer.Expect('too_long_code', 'error|The length of the string is 16, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJKLMNOP|StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure SetPosition_FromOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        ItemRef: RecordRef;
        PairRef: RecordRef;
        Pos: Text;
    begin
        Helper.SeedItems();
        Helper.SeedPairs();
        ItemRef.Open(72200);
        PairRef.Open(72201);
        ItemRef.Field(1).SetRange('A1');
        ItemRef.FindFirst();
        Pos := ItemRef.GetPosition();
        Observer.Observe('item_pos', Pos);
        Observer.Observe('into_pair', SetPosOutcomeOther(PairRef, Pos));
        PairRef.FindFirst();
        Pos := PairRef.GetPosition();
        Observer.Observe('into_item', SetPosOutcomeOther(ItemRef, Pos));
        ItemRef.Close();
        PairRef.Close();
        Observer.Expect('item_pos', 'Code Cap=CONST(A1)');
        Observer.Expect('into_pair', 'error|''Code Cap=CONST(A1)'' is not a valid position specification for the LT P92 Pair table. The position must contain all the primary key fields, in order, and only primary key fields.|DB:Ok');
        Observer.Expect('into_item', 'error|''Grp=CONST(A,B),Seq=CONST(3)'' is not a valid position specification for the P92 Item Caption table. The position must contain all the primary key fields, in order, and only primary key fields.|DB:Ok');
        Observer.Verify();
    end;

    local procedure SetPosOutcomeOther(var RecRef: RecordRef; Pos: Text): Text
    begin
        exit(SetPosOutcome(RecRef, Pos));
    end;

    [Test]
    procedure GetPosition_UnopenedAndNotFound()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Pos: Text;
    begin
        asserterror Pos := RecRef.GetPosition();
        Observer.ObserveError('unopened_get');
        asserterror RecRef.SetPosition('A1');
        Observer.ObserveError('unopened_set');
        Helper.SeedItems();
        RecRef.Open(72200);
        Observer.Observe('fresh_names', RecRef.GetPosition(true));
        Observer.Observe('fresh_nonames', RecRef.GetPosition(false));
        RecRef.Field(1).SetRange('NOPE');
        Observer.Observe('find_missing', Format(RecRef.FindFirst()));
        Observer.Observe('after_missing_find', RecRef.GetPosition(true));
        RecRef.Init();
        RecRef.Field(1).Value := 'NEW';
        Observer.Observe('init_with_key', RecRef.GetPosition(true));
        RecRef.Close();
        Observer.Expect('unopened_get|text', 'The record is not open.');
        Observer.Expect('unopened_get|code', 'RecordNotOpened');
        Observer.Expect('unopened_set|text', 'The record is not open.');
        Observer.Expect('unopened_set|code', 'RecordNotOpened');
        Observer.Expect('fresh_names', 'Code Cap=CONST()');
        Observer.Expect('fresh_nonames', 'Field1=0()');
        Observer.Expect('find_missing', 'No');
        Observer.Expect('after_missing_find', 'Code Cap=CONST()');
        Observer.Expect('init_with_key', 'Code Cap=CONST(NEW)');
        Observer.Verify();
    end;

    [Test]
    procedure GetPosition_IgnoresCurrentKeyAndTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Temp: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(1).SetRange('A3');
        RecRef.FindFirst();
        Observer.Observe('k2_pos', RecRef.GetPosition());
        RecRef.Close();
        Temp.Open(72200, true);
        Temp.Field(1).Value := 'TMP';
        Temp.Insert();
        Temp.Field(1).SetRange('TMP');
        Temp.FindFirst();
        Observer.Observe('temp_pos', Temp.GetPosition());
        Temp.Close();
        Observer.Expect('k2_pos', 'Code Cap=CONST(A3)');
        Observer.Expect('temp_pos', 'Code Cap=CONST(TMP)');
        Observer.Verify();
    end;
}
