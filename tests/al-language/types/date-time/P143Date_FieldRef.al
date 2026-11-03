// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74662 "LT P143 FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetFilter(FieldNo: Integer; FilterText: Text; var Result: Text; var Cnt: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"LT P143 Row");
        FldRef := RecRef.Field(FieldNo);
        FldRef.SetFilter(FilterText);
        Result := FldRef.GetFilter();
        Cnt := RecRef.Count();
    end;

    [TryFunction]
    local procedure TrySetRangeText(FromText: Text; ToText: Text; var Result: Text; var Cnt: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"LT P143 Row");
        FldRef := RecRef.Field(2);
        FldRef.SetRange(FromText, ToText);
        Result := FldRef.GetFilter();
        Cnt := RecRef.Count();
    end;

    local procedure ProbeFilter(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; FilterText: Text)
    var
        Result: Text;
        Cnt: Integer;
    begin
        if TrySetFilter(FieldNo, FilterText, Result, Cnt) then begin
            Observer.Observe(Name + '_filter', Result);
            Observer.Observe(Name + '_count', Format(Cnt));
        end else
            Observer.ObserveError(Name + '_err');
    end;

    [Test]
    procedure P143_FieldRefGuid()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
    begin
        Helper.Seed();
        ProbeFilter(Observer, 'guid_braced', 3, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        ProbeFilter(Observer, 'guid_unbraced_lower', 3, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
        ProbeFilter(Observer, 'guid_empty_text', 3, '');
        ProbeFilter(Observer, 'guid_zero', 3, '{00000000-0000-0000-0000-000000000000}');
        ProbeFilter(Observer, 'guid_invalid', 3, 'abc');
        Observer.Expect('guid_braced_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid_braced_count', '1');
        Observer.Expect('guid_unbraced_lower_filter', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid_unbraced_lower_count', '1');
        Observer.Expect('guid_empty_text_filter', '');
        Observer.Expect('guid_empty_text_count', '10');
        Observer.Expect('guid_zero_filter', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('guid_zero_count', '7');
        Observer.Expect('guid_invalid_err|text', 'The filter "abc" is not valid for the G field on the LT P143 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid_invalid_err|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure P143_EvaluateRelations()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P143 Helper";
        D: Date;
        Cnt: Integer;
        FilterText: Text;
        Ok: Boolean;
    begin
        Helper.Seed();
        Ok := Evaluate(D, '01/17/27');
        Observer.Observe('eval_0117_27_ok', Format(Ok));
        Observer.Observe('eval_0117_27_count_on', Format(Helper.CountOn(D)));
        Ok := Evaluate(D, 'C10/18/26');
        Observer.Observe('eval_closing_ok', Format(Ok));
        Observer.Observe('eval_closing_count_on', Format(Helper.CountOn(D)));
        Ok := Evaluate(D, '12/31/9999');
        Observer.Observe('eval_max_ok', Format(Ok));
        Observer.Observe('eval_max_count_on', Format(Helper.CountOn(D)));
        Ok := Evaluate(D, '1/1/2027');
        Observer.Observe('eval_1_1_2027_ok', Format(Ok));
        Observer.Observe('eval_1_1_2027_count_on', Format(Helper.CountOn(D)));
        Ok := Evaluate(D, '');
        Observer.Observe('eval_empty_ok', Format(Ok));
        Observer.Observe('eval_empty_count_on', Format(Helper.CountOn(D)));
        Ok := Evaluate(D, 'CD');
        Observer.Observe('eval_cd_ok', Format(Ok));
        Observer.Observe('eval_cd_equals_today', Format(D = Today()));
        Ok := Evaluate(D, 'T');
        Observer.Observe('eval_t_ok', Format(Ok));
        Observer.Observe('eval_t_equals_today', Format(D = Today()));
        Ok := Evaluate(D, 'W');
        Observer.Observe('eval_w_ok', Format(Ok));
        Observer.Observe('eval_w_equals_workdate', Format(D = WorkDate()));
        Observer.Expect('eval_0117_27_ok', 'Yes');
        Observer.Expect('eval_0117_27_count_on', '1');
        Observer.Expect('eval_closing_ok', 'Yes');
        Observer.Expect('eval_closing_count_on', '1');
        Observer.Expect('eval_max_ok', 'Yes');
        Observer.Expect('eval_max_count_on', '1');
        Observer.Expect('eval_1_1_2027_ok', 'Yes');
        Observer.Expect('eval_1_1_2027_count_on', '1');
        Observer.Expect('eval_empty_ok', 'Yes');
        Observer.Expect('eval_empty_count_on', '1');
        Observer.Expect('eval_cd_ok', 'Yes');
        Observer.Expect('eval_cd_equals_today', 'No');
        Observer.Expect('eval_t_ok', 'Yes');
        Observer.Expect('eval_t_equals_today', 'Yes');
        Observer.Expect('eval_w_ok', 'Yes');
        Observer.Expect('eval_w_equals_workdate', 'Yes');
        Observer.Verify();
    end;
}
