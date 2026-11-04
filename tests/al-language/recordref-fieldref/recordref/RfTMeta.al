// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: tables 73000, 73001 (RfTObjects.al), codeunit 73010 (RfTHelpers.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

// Field/FieldIndex/FieldCount/FieldExist, KeyIndex/KeyCount/CurrentKeyIndex, KeyRef members.

codeunit 73021 "LT RfT Meta"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Field_ByNumber_Properties()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Num: Integer;
        NumTxt: Text;
    begin
        RecRef.Open(73001);
        foreach NumTxt in '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,22,30,31,32,33'.Split(',') do begin
            Evaluate(Num, NumTxt);
            Fld := RecRef.Field(Num);
            Observer.Observe('f' + Format(Num), Fld.Name() + '|' + Fld.Caption() + '|' + Format(Fld.Number()) + '|' + Format(Fld.Type()) + '|' + Format(Fld.Length()) + '|' + Format(Fld.Class()));
        end;
        Observer.Expect('f1', 'Code|Code Caption|1|Code|20|Normal');
        Observer.Expect('f2', 'Txt|Txt Caption|2|Text|30|Normal');
        Observer.Expect('f3', 'Int|Int|3|Integer|4|Normal');
        Observer.Expect('f4', 'Dec|Dec|4|Decimal|12|Normal');
        Observer.Expect('f5', 'Bool|Bool|5|Boolean|4|Normal');
        Observer.Expect('f6', 'Dt|Dt|6|Date|4|Normal');
        Observer.Expect('f7', 'Tm|Tm|7|Time|4|Normal');
        Observer.Expect('f8', 'DtTm|DtTm|8|DateTime|8|Normal');
        Observer.Expect('f9', 'Opt|Opt|9|Option|4|Normal');
        Observer.Expect('f10', 'Col|Col|10|Option|4|Normal');
        Observer.Expect('f11', 'Big|Big|11|BigInteger|8|Normal');
        Observer.Expect('f12', 'Gd|Gd|12|GUID|16|Normal');
        Observer.Expect('f13', 'Bl|Bl|13|BLOB|8|Normal');
        Observer.Expect('f14', 'Dur|Dur|14|Duration|8|Normal');
        Observer.Expect('f15', 'DF|DF|15|DateFormula|32|Normal');
        Observer.Expect('f16', 'Cd50|Cd50|16|Code|50|Normal');
        Observer.Expect('f17', 'Rel|Rel|17|Code|20|Normal');
        Observer.Expect('f18', 'Valid|Valid|18|Integer|4|Normal');
        Observer.Expect('f19', 'Rid|Rid|19|RecordID|448|Normal');
        Observer.Expect('f20', 'Txt250|Txt250|20|Text|250|Normal');
        Observer.Expect('f22', 'Bin|Bin|22|BLOB|8|Normal');
        Observer.Expect('f30', 'SumFF|SumFF|30|Decimal|12|FlowField');
        Observer.Expect('f31', 'CntFF|CntFF|31|Integer|4|FlowField');
        Observer.Expect('f32', 'FilterFF|FilterFF|32|Integer|4|FlowFilter');
        Observer.Expect('f33', 'LookFF|LookFF|33|Text|50|FlowField');
        Observer.Verify();
    end;

    [Test]
    procedure Field_Active_Flags()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Num: Integer;
        NumTxt: Text;
    begin
        RecRef.Open(73001);
        foreach NumTxt in '1,2,9,10,13,30,33,34,35'.Split(',') do begin
            Evaluate(Num, NumTxt);
            Fld := RecRef.Field(Num);
            Observer.Observe('active' + Format(Num), Format(Fld.Active()));
        end;
        Observer.Observe('isenum_col', Format(RecRef.Field(10).IsEnum()));
        Observer.Observe('isenum_opt', Format(RecRef.Field(9).IsEnum()));
        Observer.Observe('isenum_int', Format(RecRef.Field(3).IsEnum()));
        Observer.Expect('active1', 'Yes');
        Observer.Expect('active2', 'Yes');
        Observer.Expect('active9', 'Yes');
        Observer.Expect('active10', 'Yes');
        Observer.Expect('active13', 'Yes');
        Observer.Expect('active30', 'Yes');
        Observer.Expect('active33', 'Yes');
        Observer.Expect('active34', 'No');
        Observer.Expect('active35', 'Yes');
        Observer.Expect('isenum_col', 'Yes');
        Observer.Expect('isenum_opt', 'No');
        Observer.Expect('isenum_int', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Field_Invalid_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        RecRef.Open(73001);
        Fld := RecRef.Field(0);
        Observer.Observe('zero', 'no error');
        asserterror Fld := RecRef.Field(-1);
        Observer.ObserveError('negative');
        asserterror Fld := RecRef.Field(23);
        Observer.ObserveError('gap');
        asserterror Fld := RecRef.Field(99999);
        Observer.ObserveError('big');
        asserterror Fld := RecRef.Field(2147483647);
        Observer.ObserveError('maxint');
        asserterror Fld := RecRef.Field(10000);
        Observer.ObserveError('system_range');
        Fld := RecRef.Field(2000000000);
        Observer.Observe('systemid_field', Fld.Name());
        Fld := RecRef.Field(2000000001);
        Observer.Observe('systemcreatedat', Fld.Name());
        Observer.Expect('zero', 'no error');
        Observer.Expect('negative|text', 'The supplied field number ''-1'' cannot be found in the ''RfT Data Caption'' table.');
        Observer.Expect('negative|code', 'FieldNotFound');
        Observer.Expect('gap|text', 'The supplied field number ''23'' cannot be found in the ''RfT Data Caption'' table.');
        Observer.Expect('gap|code', 'FieldNotFound');
        Observer.Expect('big|text', 'The supplied field number ''99999'' cannot be found in the ''RfT Data Caption'' table.');
        Observer.Expect('big|code', 'FieldNotFound');
        Observer.Expect('maxint|text', 'The supplied field number ''2147483647'' cannot be found in the ''RfT Data Caption'' table.');
        Observer.Expect('maxint|code', 'FieldNotFound');
        Observer.Expect('system_range|text', 'The supplied field number ''10000'' cannot be found in the ''RfT Data Caption'' table.');
        Observer.Expect('system_range|code', 'FieldNotFound');
        Observer.Expect('systemid_field', '$systemId');
        Observer.Expect('systemcreatedat', 'SystemCreatedAt');
        Observer.Verify();
    end;

    [Test]
    procedure FieldExist_Cases()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73001);
        Observer.Observe('exist_1', Format(RecRef.FieldExist(1)));
        Observer.Observe('exist_22', Format(RecRef.FieldExist(22)));
        Observer.Observe('exist_23', Format(RecRef.FieldExist(23)));
        Observer.Observe('exist_0', Format(RecRef.FieldExist(0)));
        Observer.Observe('exist_neg', Format(RecRef.FieldExist(-5)));
        Observer.Observe('exist_30', Format(RecRef.FieldExist(30)));
        Observer.Observe('exist_34', Format(RecRef.FieldExist(34)));
        Observer.Observe('exist_systemid', Format(RecRef.FieldExist(2000000000)));
        Observer.Observe('exist_maxint', Format(RecRef.FieldExist(2147483647)));
        Observer.Expect('exist_1', 'Yes');
        Observer.Expect('exist_22', 'Yes');
        Observer.Expect('exist_23', 'No');
        Observer.Expect('exist_0', 'No');
        Observer.Expect('exist_neg', 'No');
        Observer.Expect('exist_30', 'Yes');
        Observer.Expect('exist_34', 'No');
        Observer.Expect('exist_systemid', 'Yes');
        Observer.Expect('exist_maxint', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Keys_Basics()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        KeyR: KeyRef;
        i: Integer;
        j: Integer;
        Seq: Text;
    begin
        RecRef.Open(73001);
        Observer.Observe('keycount', Format(RecRef.KeyCount()));
        Observer.Observe('currentkeyindex', Format(RecRef.CurrentKeyIndex()));
        for i := 1 to RecRef.KeyCount() do begin
            KeyR := RecRef.KeyIndex(i);
            Seq := '';
            for j := 1 to KeyR.FieldCount() do
                Seq += Format(KeyR.FieldIndex(j).Number()) + ',';
            Observer.Observe('key' + Format(i), Format(KeyR.FieldCount()) + '|' + Seq + '|' + Format(KeyR.Active()));
        end;
        Observer.Expect('keycount', '4');
        Observer.Expect('currentkeyindex', '1');
        Observer.Expect('key1', '1|1,|Yes');
        Observer.Expect('key2', '2|3,2,|Yes');
        Observer.Expect('key3', '1|4,|Yes');
        Observer.Expect('key4', '1|2000000000,|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Keys_Errors()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        KeyR: KeyRef;
        Fld: FieldRef;
    begin
        RecRef.Open(73001);
        asserterror KeyR := RecRef.KeyIndex(0);
        Observer.ObserveError('keyindex0');
        asserterror KeyR := RecRef.KeyIndex(99);
        Observer.ObserveError('keyindex99');
        asserterror KeyR := RecRef.KeyIndex(-1);
        Observer.ObserveError('keyindexneg');
        KeyR := RecRef.KeyIndex(2);
        asserterror Fld := KeyR.FieldIndex(0);
        Observer.ObserveError('keyfield0');
        asserterror Fld := KeyR.FieldIndex(3);
        Observer.ObserveError('keyfield_over');
        Observer.Expect('keyindex0|text', 'Index out of bounds.');
        Observer.Expect('keyindex0|code', 'IndexOutOfBounds');
        Observer.Expect('keyindex99|text', 'Index out of bounds.');
        Observer.Expect('keyindex99|code', 'IndexOutOfBounds');
        Observer.Expect('keyindexneg|text', 'Index out of bounds.');
        Observer.Expect('keyindexneg|code', 'IndexOutOfBounds');
        Observer.Expect('keyfield0|text', 'Index out of bounds.');
        Observer.Expect('keyfield0|code', 'IndexOutOfBounds');
        Observer.Expect('keyfield_over|text', 'Index out of bounds.');
        Observer.Expect('keyfield_over|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure Keys_Active_And_CurrentKeyIndex()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Seq: Text;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Observer.Observe('active_k1_initial', Format(RecRef.KeyIndex(1).Active()));
        Observer.Observe('active_k2_initial', Format(RecRef.KeyIndex(2).Active()));
        RecRef.CurrentKeyIndex(2);
        Observer.Observe('currentkeyindex_k2', Format(RecRef.CurrentKeyIndex()));
        Observer.Observe('active_k1', Format(RecRef.KeyIndex(1).Active()));
        Observer.Observe('active_k2', Format(RecRef.KeyIndex(2).Active()));
        RecRef.CurrentKeyIndex(3);
        Observer.Observe('currentkeyindex_k3', Format(RecRef.CurrentKeyIndex()));
        RecRef.Ascending(false);
        Observer.Observe('ascending', Format(RecRef.Ascending()));
        Fld := RecRef.Field(1);
        if RecRef.FindSet() then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('descending_by_dec', Seq);
        RecRef.Ascending(true);
        Observer.Observe('ascending_again', Format(RecRef.Ascending()));
        asserterror RecRef.CurrentKeyIndex(0);
        Observer.ObserveError('index0');
        RecRef.CurrentKeyIndex(4);
        Observer.Observe('index4', 'no error');
        asserterror RecRef.CurrentKeyIndex(-1);
        Observer.ObserveError('indexneg');
        Observer.Observe('after_errors', Format(RecRef.CurrentKeyIndex()));
        RecRef.Reset();
        Observer.Observe('after_reset', Format(RecRef.CurrentKeyIndex()));
        Observer.Expect('active_k1_initial', 'Yes');
        Observer.Expect('active_k2_initial', 'Yes');
        Observer.Expect('currentkeyindex_k2', '2');
        Observer.Expect('active_k1', 'Yes');
        Observer.Expect('active_k2', 'Yes');
        Observer.Expect('currentkeyindex_k3', '3');
        Observer.Expect('ascending', 'No');
        Observer.Expect('descending_by_dec', 'D5;D4;D3;D2;D1;');
        Observer.Expect('ascending_again', 'Yes');
        Observer.Expect('index0|text', 'The RfT Data Caption table does not have an active key at index 0.');
        Observer.Expect('index0|code', 'DB:KeyNotFound');
        Observer.Expect('index4', 'no error');
        Observer.Expect('indexneg|text', 'The RfT Data Caption table does not have an active key at index -1.');
        Observer.Expect('indexneg|code', 'DB:KeyNotFound');
        Observer.Expect('after_errors', '4');
        Observer.Expect('after_reset', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Keys_Order_Of_Iteration()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Seq: Text;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(3).Value := 0;
        RecRef.CurrentKeyIndex(2);
        Fld := RecRef.Field(3);
        if RecRef.FindSet() then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('by_int', Seq);
        Observer.Expect('by_int', '10;20;30;40;50;');
        Observer.Verify();
    end;

    [Test]
    procedure KeyRef_Record()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        KeyR: KeyRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        KeyR := RecRef.KeyIndex(1);
        RecRef2 := KeyR.Record();
        Observer.Observe('record_name', RecRef2.Name());
        Observer.Observe('record_count', Format(RecRef2.Count()));
        Observer.Expect('record_name', 'LT RfT Data');
        Observer.Expect('record_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Names_Captions_Parent()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73000);
        Observer.Observe('name', RecRef.Name());
        Observer.Observe('caption', RecRef.Caption());
        Observer.Observe('number', Format(RecRef.Number()));
        Observer.Observe('f1_caption', RecRef.Field(1).Caption());
        Observer.Observe('f2_caption', RecRef.Field(2).Caption());
        Observer.Observe('f3_caption', RecRef.Field(3).Caption());
        Observer.Observe('f3_name', RecRef.Field(3).Name());
        Observer.Expect('name', 'LT RfT Parent');
        Observer.Expect('caption', 'RfT Parent Caption');
        Observer.Expect('number', '73000');
        Observer.Expect('f1_caption', 'No. Caption');
        Observer.Expect('f2_caption', 'Descr Caption');
        Observer.Expect('f3_caption', 'Qty');
        Observer.Expect('f3_name', 'Qty');
        Observer.Verify();
    end;
}
