// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setrange-method
// Scope: in-scope
// Fixtures used: tables 73000, 73001, enum 73000 (RfTObjects.al), codeunit 73010 (RfTHelpers.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// FieldRef SetRange/SetFilter/GetFilter/GetRangeMin/GetRangeMax, OptionMembers/OptionCaption, enum members, Relation, CalcField/CalcSum.
// BC versions: 29 (27 and 28 by CI)

codeunit 73025 "LT RfT Field Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetRange_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(3);
        Fld.SetRange(20);
        Observer.Observe('single', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange(20, 40);
        Observer.Observe('range', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange(40, 20);
        Observer.Observe('reversed', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange();
        Observer.Observe('cleared', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange(20, 20);
        Observer.Observe('same', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange(10, 30);
        Fld.SetRange(50);
        Observer.Observe('replaced', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Observer.Expect('single', '20|1');
        Observer.Expect('range', '20..40|3');
        Observer.Expect('reversed', '40..20|0');
        Observer.Expect('cleared', '|5');
        Observer.Expect('same', '20|1');
        Observer.Expect('replaced', '50|1');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Text_And_Code()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(1);
        Fld.SetRange('D2', 'D4');
        Observer.Observe('code_range', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange('d2');
        Observer.Observe('code_lower', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange('');
        Observer.Observe('code_blank', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld := RecRef.Field(2);
        Fld.SetRange('Text 1');
        Observer.Observe('text_eq', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange('text 1');
        Observer.Observe('text_case', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetRange('Text*');
        Observer.Observe('text_wild_literal', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Observer.Expect('code_range', 'D2..D4|3');
        Observer.Expect('code_lower', 'D2|1');
        Observer.Expect('code_blank', '''''|0');
        Observer.Expect('text_eq', 'Text 1|0');
        Observer.Expect('text_case', 'text 1|0');
        Observer.Expect('text_wild_literal', '=''Text*''|0');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(3);
        Fld.SetFilter('>20');
        Observer.Observe('gt', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('<=20|>=40');
        Observer.Observe('or', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('10..30');
        Observer.Observe('dots', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('<>20&<>30');
        Observer.Observe('and', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('%1', 30);
        Observer.Observe('param', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('%1..%2', 20, 40);
        Observer.Observe('param_range', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('');
        Observer.Observe('empty', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('<>%1', 20);
        Observer.Observe('param_neq', Fld.GetFilter() + '|' + Format(RecRef.Count()));
        Fld.SetFilter('');
        Observer.Expect('gt', '>20|3');
        Observer.Expect('or', '<=20|>=40|4');
        Observer.Expect('dots', '10..30|3');
        Observer.Expect('and', '<>20&<>30|3');
        Observer.Expect('param', '30|1');
        Observer.Expect('param_range', '20..40|3');
        Observer.Expect('empty', '|5');
        Observer.Expect('param_neq', '<>20|4');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure SetFilter_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(3);
        asserterror Fld.SetFilter('abc');
        Observer.ObserveError('int_text');
        Fld.SetFilter('1..');
        Observer.Observe('int_open', 'no error');
        asserterror Fld.SetFilter('%1');
        Observer.ObserveError('missing_param');
        asserterror Fld.SetFilter('>>5');
        Observer.ObserveError('double_op');
        asserterror Fld.SetFilter('(1');
        Observer.ObserveError('paren');
        Fld := RecRef.Field(6);
        asserterror Fld.SetFilter('notadate');
        Observer.ObserveError('date');
        Fld := RecRef.Field(5);
        asserterror Fld.SetFilter('maybe');
        Observer.ObserveError('bool');
        Fld := RecRef.Field(9);
        asserterror Fld.SetFilter('Nope');
        Observer.ObserveError('option');
        Fld := RecRef.Field(10);
        asserterror Fld.SetFilter('Purple');
        Observer.ObserveError('enum');
        Fld := RecRef.Field(3);
        asserterror Fld.SetRange('abc');
        Observer.Observe('setrange_text|raised', Format(GetLastErrorText() <> ''));
        ClearLastError();
        asserterror Fld.SetRange(1, 'x');
        Observer.Observe('setrange_mixed|raised', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Observer.Expect('int_text|text', 'The filter "abc" is not valid for the Int field on the RfT Data Caption table. The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('int_text|code', 'Filter:CSide');
        Observer.Expect('int_open', 'no error');
        Observer.Expect('missing_param|text', 'The filter "%1" is not valid for the Int field on the RfT Data Caption table. The variable "%1" was not understood.');
        Observer.Expect('missing_param|code', 'Filter:CSide');
        Observer.Expect('double_op|text', 'The filter ">>5" is not valid for the Int field on the RfT Data Caption table. A value is expected after the ''>''.');
        Observer.Expect('double_op|code', 'Filter:CSide');
        Observer.Expect('paren|text', 'The filter "(1" is not valid for the Int field on the RfT Data Caption table. A '')'' is missing.');
        Observer.Expect('paren|code', 'Filter:CSide');
        Observer.Expect('date|text', 'The filter "notadate" is not valid for the Dt field on the RfT Data Caption table. The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('date|code', 'Filter:CSide');
        Observer.Expect('bool|text', 'The filter "maybe" is not valid for the Bool field on the RfT Data Caption table. The value "maybe" can''t be evaluated into type Boolean.');
        Observer.Expect('bool|code', 'Filter:CSide');
        Observer.Expect('option|text', 'The filter "Nope" is not valid for the Opt field on the RfT Data Caption table. ''Nope'' is not an option. The existing options are: Erste,Zweite,Dritte');
        Observer.Expect('option|code', 'Filter:CSide');
        Observer.Expect('enum|text', 'The filter "Purple" is not valid for the Col field on the RfT Data Caption table. ''Purple'' is not an option. The existing options are: Red,Green,Blue Caption');
        Observer.Expect('enum|code', 'Filter:CSide');
        Observer.Expect('setrange_text|raised', 'Yes');
        Observer.Expect('setrange_mixed|raised', 'Yes');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure GetRangeMinMax()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(3);
        Fld.SetRange(20, 40);
        Observer.Observe('min', Format(Fld.GetRangeMin()));
        Observer.Observe('max', Format(Fld.GetRangeMax()));
        Fld.SetRange(25);
        Observer.Observe('single_min', Format(Fld.GetRangeMin()));
        Observer.Observe('single_max', Format(Fld.GetRangeMax()));
        Fld.SetFilter('10..20|40..50');
        asserterror Observer.Observe('multi_min', Format(Fld.GetRangeMin()));
        Observer.ObserveError('multi_min');
        asserterror Observer.Observe('multi_max', Format(Fld.GetRangeMax()));
        Observer.ObserveError('multi_max');
        Fld.SetRange();
        asserterror Observer.Observe('none_min', Format(Fld.GetRangeMin()));
        Observer.ObserveError('none_min');
        Fld.SetFilter('>20');
        Observer.Observe('gt_min', Format(Fld.GetRangeMin()));
        Observer.Observe('gt_min', 'no error');
        Fld := RecRef.Field(1);
        Fld.SetRange('A', 'C');
        Observer.Observe('code_min', Format(Fld.GetRangeMin()));
        Observer.Observe('code_max', Format(Fld.GetRangeMax()));
        Observer.Expect('min', '20');
        Observer.Expect('max', '40');
        Observer.Expect('single_min', '25');
        Observer.Expect('single_max', '25');
        Observer.Expect('multi_min|text', 'The filter expression "10..20|40..50" applied to the field Int in the RfT Data Caption table results in more than one range.');
        Observer.Expect('multi_min|code', 'DB:NotIntervalFilter');
        Observer.Expect('multi_max|text', 'The filter expression "10..20|40..50" applied to the field Int in the RfT Data Caption table results in more than one range.');
        Observer.Expect('multi_max|code', 'DB:NotIntervalFilter');
        Observer.Expect('none_min|text', 'Specify a filter for the Int field in the RfT Data Caption table.');
        Observer.Expect('none_min|code', 'DB:NoFilter');
        Observer.Expect('gt_min', '20');
        Observer.Expect('gt_min', 'no error');
        Observer.Expect('code_min', 'A');
        Observer.Expect('code_max', 'C');
        Observer.Verify();
    end;

    [Test]
    procedure GetFilter_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(3);
        Observer.Observe('none', Fld.GetFilter());
        Fld.SetFilter('<10|>40');
        Observer.Observe('or', Fld.GetFilter());
        Fld := RecRef.Field(6);
        Fld.SetRange(DMY2Date(1, 1, 2020), DMY2Date(3, 1, 2020));
        Observer.Observe('date', Fld.GetFilter());
        Observer.Observe('date_count', Format(RecRef.Count()));
        Fld := RecRef.Field(9);
        Fld.SetRange(1);
        Observer.Observe('option', Fld.GetFilter());
        Observer.Observe('option_count', Format(RecRef.Count()));
        Fld.SetFilter('Second|Third');
        Observer.Observe('option_names', Fld.GetFilter());
        Observer.Observe('option_names_count', Format(RecRef.Count()));
        Fld := RecRef.Field(5);
        Fld.SetRange(true);
        Observer.Observe('bool', Fld.GetFilter());
        Observer.Observe('bool_count', Format(RecRef.Count()));
        Fld := RecRef.Field(10);
        Fld.SetRange(Enum::"LT RfT Color"::Red);
        Observer.Observe('enum', Fld.GetFilter());
        Observer.Observe('enum_count', Format(RecRef.Count()));
        Fld.SetFilter('Green|Blue');
        Observer.Observe('enum_names', Fld.GetFilter());
        Observer.Expect('none', '');
        Observer.Expect('or', '<10|>40');
        Observer.Expect('date', '01/01/20..01/03/20');
        Observer.Expect('date_count', '0');
        Observer.Expect('option', 'Zweite');
        Observer.Expect('option_count', '0');
        Observer.Expect('option_names', 'Zweite|Dritte');
        Observer.Expect('option_names_count', '0');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('bool_count', '0');
        Observer.Expect('enum', 'Red');
        Observer.Expect('enum_count', '0');
        Observer.Expect('enum_names', 'Green|Blue Caption');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_Values()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Num: Integer;
    begin
        RecRef.Open(73001);
        Fld := RecRef.Field(17);
        Observer.Observe('relation_field', Format(Fld.Relation()));
        Fld := RecRef.Field(3);
        Observer.Observe('relation_none', Format(Fld.Relation()));
        Fld := RecRef.Field(1);
        Observer.Observe('relation_pk', Format(Fld.Relation()));
        Fld := RecRef.Field(10);
        Observer.Observe('relation_enum', Format(Fld.Relation()));
        Fld := RecRef.Field(30);
        Observer.Observe('relation_flowfield', Format(Fld.Relation()));
        Observer.Expect('relation_field', '73000');
        Observer.Expect('relation_none', '0');
        Observer.Expect('relation_pk', '0');
        Observer.Expect('relation_enum', '0');
        Observer.Expect('relation_flowfield', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CalcField_FlowFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(1).Value := 'P2';
        RecRef.Insert();
        Fld := RecRef.Field(30);
        Observer.Observe('class', Format(Fld.Class()));
        Observer.Observe('sum_before', Format(Fld.Value));
        Fld.CalcField();
        Observer.Observe('sum_after_D2', Format(Fld.Value));
        RecRef.Get(Rec_Id('D2'));
        Fld.CalcField();
        Observer.Observe('sum_first', Format(Fld.Value));
        Fld := RecRef.Field(31);
        Fld.CalcField();
        Observer.Observe('count', Format(Fld.Value));
        Fld := RecRef.Field(33);
        Fld.CalcField();
        Observer.Observe('lookup', Format(Fld.Value));
        RecRef.Close();
        Observer.Expect('class', 'FlowField');
        Observer.Expect('sum_before', '0');
        Observer.Expect('sum_after_D2', '21');
        Observer.Expect('sum_first', '0');
        Observer.Expect('count', '0');
        Observer.Expect('lookup', '');
        Observer.Verify();
    end;

    [Test]
    procedure CalcField_Errors_NonFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.FindFirst();
        Fld := RecRef.Field(3);
        asserterror Fld.CalcField();
        Observer.ObserveError('calcfield_normal');
        Fld.CalcSum();
        Observer.Observe('calcsum_normal', 'no error');
        Fld := RecRef.Field(32);
        asserterror Fld.CalcField();
        Observer.ObserveError('calcfield_flowfilter');
        Fld := RecRef.Field(13);
        Fld.CalcField();
        Observer.Observe('calcfield_blob', 'ok');
        Observer.Expect('calcfield_normal|text', 'The Int field in the RfT Data Caption table must be a FlowField.');
        Observer.Expect('calcfield_normal|code', 'DB:Ok');
        Observer.Expect('calcsum_normal', 'no error');
        Observer.Expect('calcfield_flowfilter|text', 'The FilterFF field in the RfT Data Caption table must be a FlowField.');
        Observer.Expect('calcfield_flowfilter|code', 'DB:Ok');
        Observer.Expect('calcfield_blob', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSum_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.FindFirst();
        Fld := RecRef.Field(30);
        asserterror Observer.Observe('calcsum_result', Format(Fld.CalcSum()));
        Observer.ObserveError('af379');
        Observer.Observe('value_after', Format(Fld.Value));
        Fld := RecRef.Field(31);
        asserterror Observer.Observe('calcsum_count', Format(Fld.CalcSum()));
        Observer.ObserveError('calcsum_count');
        Observer.Expect('af379|text', 'Cannot calculate a sum of the values in the SumFF field in the RfT Data Caption table because one or more values are not normal numeric fields.');
        Observer.Expect('af379|code', 'DB:Ok');
        Observer.Expect('value_after', '0');
        Observer.Expect('calcsum_count|text', 'Cannot calculate a sum of the values in the CntFF field in the RfT Data Caption table because one or more values are not normal numeric fields.');
        Observer.Expect('calcsum_count|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure CalcField_Errors_Via_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
    begin
        Helper.Seed();
        Rec.Code := 'P3';
        Rec.Insert();
        RecRef.GetTable(Rec);
        RecRef.Field(30).CalcField();
        Observer.Observe('sum', Format(RecRef.Field(30).Value));
        RecRef.Field(31).CalcField();
        Observer.Observe('cnt', Format(RecRef.Field(31).Value));
        RecRef.Field(33).CalcField();
        Observer.Observe('lookup', Format(RecRef.Field(33).Value));
        RecRef.SetTable(Rec);
        Observer.Observe('record_sees_sum', Format(Rec.SumFF));
        Observer.Observe('record_sees_cnt', Format(Rec.CntFF));
        Observer.Expect('sum', '31.5');
        Observer.Expect('cnt', '1');
        Observer.Expect('lookup', 'Parent 3');
        Observer.Expect('record_sees_sum', '31.5');
        Observer.Expect('record_sees_cnt', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_FlowFilter_Via_FieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(32);
        Fld.SetRange(5);
        Observer.Observe('flowfilter_get', Fld.GetFilter());
        Observer.Observe('flowfilter_class', Format(Fld.Class()));
        Observer.Observe('count_unaffected', Format(RecRef.Count()));
        Observer.Expect('flowfilter_get', '5');
        Observer.Expect('flowfilter_class', 'FlowFilter');
        Observer.Expect('count_unaffected', '5');
        Observer.Verify();
    end;

    local procedure Rec_Id(CodeValue: Code[20]): RecordId
    var
        Rec: Record "LT RfT Data";
    begin
        Rec.Code := CodeValue;
        exit(Rec.RecordId());
    end;
}
