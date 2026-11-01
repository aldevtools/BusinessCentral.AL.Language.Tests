// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 92980, test codeunit 92981 (writer Y51, gap cycle 5 spec G5-14)
// Probe: SetView texts the Retention Policy code of the System Application builds: a lowercase field<n> form with a space after
//        SORTING (`sorting (field2) where(field2=1(<>''))` on a Date field with no key), an empty value in `1()` / FILTER() / CONST()
//        on Text, Date and Integer fields, Field0 and a Field<n> with no such field, an empty value set inside a filter group, and an
//        empty value set by a FilterPageHandler on a FilterPageBuilder record. Per view: ok or the error text and code, GetView(false),
//        GetView(true), GetFilters, Count and the ids FindSet visits.
//        Already pinned nearby: types/lt-evaluate-format-lasterror-setview/P86SetView.al (unknown names, CONST() on an Integer),
//        record/lt-setview-caption-form/SetViewCaptionForm.al (unknown name in WHERE ignored).
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
//         SetView and RecordRef.Copy values (not the FilterPageHandler test) also match the SaaS sandbox BC 29.
// BC versions: 27, 28, 29

table 92980 "LT Y51 SV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Date Field"; Date) { }
        field(4; Description; Text[100]) { }
        field(5; "Description 2"; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 92981 "LT Y51 SetView Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerView: Text;
        HandlerResult: Text;

    local procedure Seed()
    var
        Row: Record "LT Y51 SV Row";
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row."Date Field" := DMY2Date(1, 1, 2024);
        Row.Description := 'A';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row."Description 2" := 'D';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 3;
        Row."Date Field" := DMY2Date(1, 3, 2024);
        Row.Description := 'B';
        Row."Description 2" := 'E';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TrySetView(var RR: RecordRef; View: Text)
    begin
        RR.SetView(View);
    end;

    [TryFunction]
    local procedure TrySetViewRec(var Row: Record "LT Y51 SV Row"; View: Text)
    begin
        Row.SetView(View);
    end;

    local procedure State(var RR: RecordRef): Text
    var
        Ids: Text;
    begin
        if RR.FindSet() then
            repeat
                Ids += Format(RR.Field(1).Value) + ',';
            until RR.Next() = 0;
        exit(RR.GetView(false) + '|' + RR.GetView(true) + '|' + RR.GetFilters() + '|' + Format(RR.Count()) + '|' + Ids);
    end;

    local procedure SV(View: Text): Text
    var
        RR: RecordRef;
    begin
        RR.Open(Database::"LT Y51 SV Row");
        ClearLastError();
        if TrySetView(RR, View) then
            exit('ok|' + State(RR));
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + RR.GetView(false));
    end;

    local procedure SVRec(View: Text): Text
    var
        Row: Record "LT Y51 SV Row";
        Ids: Text;
    begin
        ClearLastError();
        if not TrySetViewRec(Row, View) then
            exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Row.GetView(false));
        if Row.FindSet() then
            repeat
                Ids += Format(Row."Entry No.") + ',';
            until Row.Next() = 0;
        exit('ok|' + Row.GetView(false) + '|' + Row.GetView(true) + '|' + Row.GetFilters() + '|' + Format(Row.Count()) + '|' + Ids);
    end;

    [Test]
    procedure SetView_LowercaseFieldN()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('ms_text', SV('sorting (field2) where(field2=1(<>''''))'));
        Observer.Observe('ms_text_rec', SVRec('sorting (field2) where(field2=1(<>''''))'));
        Observer.Observe('sorting_field2', SV('sorting(field2)'));
        Observer.Observe('where_field4', SV('where(field4=1(A))'));
        Observer.Observe('where_fIeLd4', SV('WHERE(fIeLd4=1(A))'));
        Observer.Observe('sorting_space_Field2', SV('SORTING (Field2)'));
        Observer.Observe('Field2_ne_blank', SV('WHERE(Field2=1(<>''''))'));
        Observer.Expect('ms_text', 'ok|VERSION(1) SORTING(Field2) WHERE(Field2=1(<>''''))|VERSION(1) SORTING(Date Field) WHERE(Date Field=FILTER(<>''''))|Date Field: <>''''|2|1,3,');
        Observer.Expect('ms_text_rec', 'ok|VERSION(1) SORTING(Field2) WHERE(Field2=1(<>''''))|VERSION(1) SORTING(Date Field) WHERE(Date Field=FILTER(<>''''))|Date Field: <>''''|2|1,3,');
        Observer.Expect('sorting_field2', 'ok|VERSION(1) SORTING(Field2)|VERSION(1) SORTING(Date Field)||3|2,1,3,');
        Observer.Expect('where_field4', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(A))|VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(A))|Description: A|1|1,');
        Observer.Expect('where_fIeLd4', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(A))|VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(A))|Description: A|1|1,');
        Observer.Expect('sorting_space_Field2', 'ok|VERSION(1) SORTING(Field2)|VERSION(1) SORTING(Date Field)||3|2,1,3,');
        Observer.Expect('Field2_ne_blank', 'ok|VERSION(1) SORTING(Field1) WHERE(Field2=1(<>''''))|VERSION(1) SORTING(Entry No.) WHERE(Date Field=FILTER(<>''''))|Date Field: <>''''|2|1,3,');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_EmptyFilterValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('text_1', SV('WHERE(Field4=1())'));
        Observer.Observe('text_1_rec', SVRec('WHERE(Field4=1())'));
        Observer.Observe('text_filter', SV('WHERE(Field4=FILTER())'));
        Observer.Observe('text_const', SV('WHERE(Field4=CONST())'));
        Observer.Observe('date_1', SV('WHERE(Field2=1())'));
        Observer.Observe('int_1', SV('WHERE(Field1=1())'));
        Observer.Observe('text5_1', SV('WHERE(Field5=1())'));
        Observer.Expect('text_1', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(==))|VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(==))|Description: ==|3|1,2,3,');
        Observer.Expect('text_1_rec', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(==))|VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(==))|Description: ==|3|1,2,3,');
        Observer.Expect('text_filter', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(==))|VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(==))|Description: ==|3|1,2,3,');
        Observer.Expect('text_const', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(''''))|VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(''''))|Description: ''''|1|2,');
        Observer.Expect('date_1', 'ok|VERSION(1) SORTING(Field1) WHERE(Field2=1(==))|VERSION(1) SORTING(Entry No.) WHERE(Date Field=FILTER(==))|Date Field: ==|3|1,2,3,');
        Observer.Expect('int_1', 'ok|VERSION(1) SORTING(Field1) WHERE(Field1=1(==))|VERSION(1) SORTING(Entry No.) WHERE(Entry No.=FILTER(==))|Entry No.: ==|3|1,2,3,');
        Observer.Expect('text5_1', 'ok|VERSION(1) SORTING(Field1) WHERE(Field5=1(==))|VERSION(1) SORTING(Entry No.) WHERE(Description 2=FILTER(==))|Description 2: ==|3|1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_FieldZeroAndMissingId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('field0_empty', SV('WHERE(Field0=1())'));
        Observer.Observe('field0_x', SV('WHERE(Field0=1(x))'));
        Observer.Observe('field99_x', SV('WHERE(Field99=1(x))'));
        Observer.Observe('sorting_field99', SV('SORTING(Field99)'));
        Observer.Observe('field0_rec', SVRec('WHERE(Field0=1())'));
        Observer.Expect('field0_empty', 'ok|VERSION(1) SORTING(Field1) WHERE(Field0=1(==))|VERSION(1) SORTING(Entry No.) WHERE(timestamp=FILTER(==))|timestamp: ==|3|1,2,3,');
        Observer.Expect('field0_x', 'err|The value "x" can''t be evaluated into type BigInteger.|InvalidFilterExpression:Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('field99_x', 'ok|VERSION(1) SORTING(Field1)|VERSION(1) SORTING(Entry No.)||3|1,2,3,');
        Observer.Expect('sorting_field99', 'ok|VERSION(1) SORTING(Field1)|VERSION(1) SORTING(Entry No.)||3|1,2,3,');
        Observer.Expect('field0_rec', 'ok|VERSION(1) SORTING(Field1) WHERE(Field0=1(==))|VERSION(1) SORTING(Entry No.) WHERE(timestamp=FILTER(==))|timestamp: ==|3|1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_EmptyValue_InFilterGroup()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(Database::"LT Y51 SV Row");
        RR.FilterGroup := 10;
        ClearLastError();
        Observer.Observe('setview_ok', Format(TrySetView(RR, 'WHERE(Field4=1())')));
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('group10_view', RR.GetView(false));
        Observer.Observe('group10_filters', RR.GetFilters());
        Observer.Observe('group10_count', Format(RR.Count()));
        RR.FilterGroup := 0;
        Observer.Observe('group0_view', RR.GetView(false));
        Observer.Observe('group0_filters', RR.GetFilters());
        Observer.Observe('group0_state', State(RR));
        Observer.Expect('setview_ok', 'Yes');
        Observer.Expect('error', '|');
        Observer.Expect('group10_view', 'VERSION(1) SORTING(Field1) WHERE(Field4=1(==))');
        Observer.Expect('group10_filters', 'Description: ==');
        Observer.Expect('group10_count', '3');
        Observer.Expect('group0_view', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('group0_filters', '');
        Observer.Expect('group0_state', 'VERSION(1) SORTING(Field1)|VERSION(1) SORTING(Entry No.)||3|1,2,3,');
        Observer.Verify();
    end;

    [FilterPageHandler]
    procedure EmptyValueHandler(var RR: RecordRef): Boolean
    begin
        HandlerView := RR.GetView(false);
        ClearLastError();
        if TrySetView(RR, 'WHERE(Field4=1())') then
            HandlerResult := 'ok|' + RR.GetView(false)
        else
            HandlerResult := 'err|' + GetLastErrorText() + '|' + GetLastErrorCode();
        exit(true);
    end;

    [Test]
    [HandlerFunctions('EmptyValueHandler')]
    procedure SetView_EmptyValue_FilterPageHandler()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        RR: RecordRef;
        Answer: Boolean;
    begin
        Seed();
        RR.Open(Database::"LT Y51 SV Row");
        FPB.AddRecordRef('Rows', RR);
        Answer := FPB.RunModal();
        Observer.Observe('runmodal', Format(Answer));
        Observer.Observe('handler_view_before', HandlerView);
        Observer.Observe('handler_result', HandlerResult);
        Observer.Observe('fpb_view_false', FPB.GetView('Rows', false));
        Observer.Observe('fpb_view_true', FPB.GetView('Rows', true));
        Observer.Expect('runmodal', 'Yes');
        Observer.Expect('handler_view_before', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('handler_result', 'ok|VERSION(1) SORTING(Field1) WHERE(Field4=1(==))');
        Observer.Expect('fpb_view_false', 'VERSION(1) SORTING(Field1) WHERE(Field4=1(==))');
        Observer.Expect('fpb_view_true', 'VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(==))');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetFilterDescription(var Row: Record "LT Y51 SV Row"; Filter: Text)
    begin
        Row.SetFilter(Description, Filter);
    end;

    local procedure SF(Filter: Text): Text
    var
        Row: Record "LT Y51 SV Row";
    begin
        ClearLastError();
        if TrySetFilterDescription(Row, Filter) then
            exit('ok|' + Row.GetFilter(Description) + '|' + Row.GetView(false) + '|' + Format(Row.Count()));
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Writer Y57: a view that already holds the empty value as GetView writes it (`1(==)`), set again with SetView (the Retention Policy
    // apply code reads back the view its FilterPageBuilder stored).
    [Test]
    procedure SetView_DoubleEqualsValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('text_1', SV('WHERE(Field4=1(==))'));
        Observer.Observe('text_full', SV('VERSION(1) SORTING(Field1) WHERE(Field4=1(==))'));
        Observer.Observe('text_full_rec', SVRec('VERSION(1) SORTING(Field1) WHERE(Field4=1(==))'));
        Observer.Observe('text_filter_name', SV('VERSION(1) SORTING(Entry No.) WHERE(Description=FILTER(==))'));
        Observer.Observe('text5_1', SV('WHERE(Field5=1(==))'));
        Observer.Observe('date_1', SV('WHERE(Field2=1(==))'));
        Observer.Observe('int_1', SV('WHERE(Field1=1(==))'));
        Observer.Observe('text_const', SV('WHERE(Field4=CONST(==))'));
        Observer.Observe('text_single_eq', SV('WHERE(Field4=1(=))'));
        Observer.Observe('text_eq_A', SV('WHERE(Field4=1(=A))'));
        Observer.Finish();
    end;

    [Test]
    procedure SetView_DoubleEquals_TwoFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('two_fields', SV('VERSION(1) SORTING(Field1) WHERE(Field2=1(..2024-02-01),Field4=1(==))'));
        Observer.Observe('two_fields_first', SV('VERSION(1) SORTING(Field1) WHERE(Field4=1(==),Field5=1(E))'));
        Observer.Finish();
    end;

    [Test]
    procedure SetView_DoubleEquals_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y51 SV Row";
        RR: RecordRef;
        RR2: RecordRef;
        RR3: RecordRef;
        View: Text;
    begin
        Seed();
        RR.Open(Database::"LT Y51 SV Row");
        RR.SetView('WHERE(Field4=1())');
        View := RR.GetView(false);
        Observer.Observe('stored_view', View);
        RR2.Open(Database::"LT Y51 SV Row");
        ClearLastError();
        if TrySetView(RR2, View) then
            Observer.Observe('set_again', 'ok|' + State(RR2))
        else
            Observer.Observe('set_again', 'err|' + GetLastErrorText() + '|' + GetLastErrorCode());
        RR3.Open(Database::"LT Y51 SV Row");
        RR3.FilterGroup := 10;
        ClearLastError();
        if TrySetView(RR3, View) then
            Observer.Observe('group10_set', 'ok|' + RR3.GetView(false) + '|' + RR3.GetFilters() + '|' + Format(RR3.Count()))
        else
            Observer.Observe('group10_set', 'err|' + GetLastErrorText() + '|' + GetLastErrorCode());
        RR3.FilterGroup := 0;
        Observer.Observe('group0_view', RR3.GetView(false));
        RR3.FilterGroup := 10;
        RR3.SetView('');
        Observer.Observe('group10_cleared', RR3.GetView(false) + '|' + Format(RR3.Count()));
        Observer.Observe('setfilter_eqeq', SF('=='));
        Observer.Observe('setfilter_eq', SF('='));
        Observer.Observe('setfilter_quotes', SF(''''''));
        Row.SetRange(Description, '');
        Observer.Observe('setrange_blank', Row.GetFilter(Description) + '|' + Row.GetView(false) + '|' + Format(Row.Count()));
        Observer.Finish();
    end;
}
