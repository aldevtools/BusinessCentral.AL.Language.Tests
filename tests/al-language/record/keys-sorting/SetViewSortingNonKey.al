// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70872 and codeunit 70873
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetView('SORTING(Description) WHERE(...)') where no key starts with Description: success or error text and code, the FindSet order, GetView text (with and without field names), CurrentKey, Ascending, and the same for a two-field list, a key prefix plus a non-key field, ORDER(Descending), and SetCurrentKey with the same fields for comparison.
// BC versions: 29 (27 and 28 by CI)

table 70872 "LT SVS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Description; Text[30]) { }
        field(3; Amount; Integer) { }
        field(4; Category; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByAmount; Amount) { }
    }
}

codeunit 70873 "LT SetView Sorting NonKey"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT SVS Row";
    begin
        Row.DeleteAll();
        Add(1, 'delta', 30, 'X');
        Add(2, 'alpha', 10, 'X');
        Add(3, 'charlie', 20, 'Y');
        Add(4, 'bravo', 10, 'Y');
        Add(5, 'alpha', 5, 'X');
    end;

    local procedure Add(Id: Integer; Descr: Text[30]; Amount: Integer; Cat: Code[10])
    var
        Row: Record "LT SVS Row";
    begin
        Row.Id := Id;
        Row.Description := Descr;
        Row.Amount := Amount;
        Row.Category := Cat;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TrySetView(var Row: Record "LT SVS Row"; View: Text)
    begin
        Row.SetView(View);
    end;

    local procedure Order(var Row: Record "LT SVS Row"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Probe(Name: Text; View: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT SVS Row";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TrySetView(Row, View);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_err', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_view', Row.GetView());
        Observer.Observe(Name + '_viewnames', Row.GetView(false));
        Observer.Observe(Name + '_key', Row.CurrentKey());
        Observer.Observe(Name + '_asc', Format(Row.Ascending()));
        Observer.Observe(Name + '_order', Order(Row));
        Observer.Observe(Name + '_count', Format(Row.Count()));
    end;

    [Test]
    procedure SetView_SortingNonKeyField_WithWhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('desc_where', 'SORTING(Description) WHERE(Category=FILTER(X))', Observer);
        Probe('desc_only', 'SORTING(Description)', Observer);
        Observer.Expect('desc_where_ok', 'Yes');
        Observer.Expect('desc_where_err', '');
        Observer.Expect('desc_where_code', '');
        Observer.Expect('desc_where_view', 'VERSION(1) SORTING(Description) WHERE(Category=FILTER(X))');
        Observer.Expect('desc_where_viewnames', 'VERSION(1) SORTING(Field2) WHERE(Field4=1(X))');
        Observer.Expect('desc_where_key', 'Description');
        Observer.Expect('desc_where_asc', 'Yes');
        Observer.Expect('desc_where_order', '2,5,1,');
        Observer.Expect('desc_where_count', '3');
        Observer.Expect('desc_only_ok', 'Yes');
        Observer.Expect('desc_only_err', '');
        Observer.Expect('desc_only_code', '');
        Observer.Expect('desc_only_view', 'VERSION(1) SORTING(Description)');
        Observer.Expect('desc_only_viewnames', 'VERSION(1) SORTING(Field2)');
        Observer.Expect('desc_only_key', 'Description');
        Observer.Expect('desc_only_asc', 'Yes');
        Observer.Expect('desc_only_order', '2,5,4,3,1,');
        Observer.Expect('desc_only_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_SortingNonKeyField_Descending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('desc_down', 'SORTING(Description) ORDER(Descending)', Observer);
        Probe('desc_down_where', 'SORTING(Description) ORDER(Descending) WHERE(Amount=FILTER(>=10))', Observer);
        Observer.Expect('desc_down_ok', 'Yes');
        Observer.Expect('desc_down_err', '');
        Observer.Expect('desc_down_code', '');
        Observer.Expect('desc_down_view', 'VERSION(1) SORTING(Description) ORDER(Descending)');
        Observer.Expect('desc_down_viewnames', 'VERSION(1) SORTING(Field2) ORDER(1)');
        Observer.Expect('desc_down_key', 'Description');
        Observer.Expect('desc_down_asc', 'No');
        Observer.Expect('desc_down_order', '1,3,4,5,2,');
        Observer.Expect('desc_down_count', '5');
        Observer.Expect('desc_down_where_ok', 'Yes');
        Observer.Expect('desc_down_where_err', '');
        Observer.Expect('desc_down_where_code', '');
        Observer.Expect('desc_down_where_view', 'VERSION(1) SORTING(Description) ORDER(Descending) WHERE(Amount=FILTER(>=10))');
        Observer.Expect('desc_down_where_viewnames', 'VERSION(1) SORTING(Field2) ORDER(1) WHERE(Field3=1(>=10))');
        Observer.Expect('desc_down_where_key', 'Description');
        Observer.Expect('desc_down_where_asc', 'No');
        Observer.Expect('desc_down_where_order', '1,3,4,2,');
        Observer.Expect('desc_down_where_count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_SortingFieldLists()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('two_fields', 'SORTING(Description,Amount)', Observer);
        Probe('key_prefix_plus', 'SORTING(Amount,Description)', Observer);
        Probe('category_first', 'SORTING(Category,Id)', Observer);
        Probe('pk_field', 'SORTING(Id)', Observer);
        Observer.Expect('two_fields_ok', 'Yes');
        Observer.Expect('two_fields_err', '');
        Observer.Expect('two_fields_code', '');
        Observer.Expect('two_fields_view', 'VERSION(1) SORTING(Description,Amount)');
        Observer.Expect('two_fields_viewnames', 'VERSION(1) SORTING(Field2,Field3)');
        Observer.Expect('two_fields_key', 'Description,Amount');
        Observer.Expect('two_fields_asc', 'Yes');
        Observer.Expect('two_fields_order', '5,2,4,3,1,');
        Observer.Expect('two_fields_count', '5');
        Observer.Expect('key_prefix_plus_ok', 'Yes');
        Observer.Expect('key_prefix_plus_err', '');
        Observer.Expect('key_prefix_plus_code', '');
        Observer.Expect('key_prefix_plus_view', 'VERSION(1) SORTING(Amount,Description)');
        Observer.Expect('key_prefix_plus_viewnames', 'VERSION(1) SORTING(Field3,Field2)');
        Observer.Expect('key_prefix_plus_key', 'Amount,Description');
        Observer.Expect('key_prefix_plus_asc', 'Yes');
        Observer.Expect('key_prefix_plus_order', '5,2,4,3,1,');
        Observer.Expect('key_prefix_plus_count', '5');
        Observer.Expect('category_first_ok', 'Yes');
        Observer.Expect('category_first_err', '');
        Observer.Expect('category_first_code', '');
        Observer.Expect('category_first_view', 'VERSION(1) SORTING(Category,Id)');
        Observer.Expect('category_first_viewnames', 'VERSION(1) SORTING(Field4,Field1)');
        Observer.Expect('category_first_key', 'Category,Id');
        Observer.Expect('category_first_asc', 'Yes');
        Observer.Expect('category_first_order', '1,2,5,3,4,');
        Observer.Expect('category_first_count', '5');
        Observer.Expect('pk_field_ok', 'Yes');
        Observer.Expect('pk_field_err', '');
        Observer.Expect('pk_field_code', '');
        Observer.Expect('pk_field_view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('pk_field_viewnames', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('pk_field_key', 'Id');
        Observer.Expect('pk_field_asc', 'Yes');
        Observer.Expect('pk_field_order', '1,2,3,4,5,');
        Observer.Expect('pk_field_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_SortingWithFieldNumbersAndErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('by_number', 'SORTING(Field2)', Observer);
        Probe('unknown_field', 'SORTING(NoSuchField)', Observer);
        Probe('empty_sorting', 'SORTING()', Observer);
        Observer.Expect('by_number_ok', 'Yes');
        Observer.Expect('by_number_err', '');
        Observer.Expect('by_number_code', '');
        Observer.Expect('by_number_view', 'VERSION(1) SORTING(Description)');
        Observer.Expect('by_number_viewnames', 'VERSION(1) SORTING(Field2)');
        Observer.Expect('by_number_key', 'Description');
        Observer.Expect('by_number_asc', 'Yes');
        Observer.Expect('by_number_order', '2,5,4,3,1,');
        Observer.Expect('by_number_count', '5');
        Observer.Expect('unknown_field_ok', 'Yes');
        Observer.Expect('unknown_field_err', '');
        Observer.Expect('unknown_field_code', '');
        Observer.Expect('unknown_field_view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('unknown_field_viewnames', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('unknown_field_key', 'Id');
        Observer.Expect('unknown_field_asc', 'Yes');
        Observer.Expect('unknown_field_order', '1,2,3,4,5,');
        Observer.Expect('unknown_field_count', '5');
        Observer.Expect('empty_sorting_ok', 'No');
        Observer.Expect('empty_sorting_err', 'Invalid expression of type: table view.\SORTING()');
        Observer.Expect('empty_sorting_code', 'DB:Ok');
        Observer.Expect('empty_sorting_view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('empty_sorting_viewnames', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('empty_sorting_key', 'Id');
        Observer.Expect('empty_sorting_asc', 'Yes');
        Observer.Expect('empty_sorting_order', '1,2,3,4,5,');
        Observer.Expect('empty_sorting_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_NonKeyField_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SVS Row";
    begin
        Seed();
        Row.SetCurrentKey(Description);
        Observer.Observe('key', Row.CurrentKey());
        Observer.Observe('view', Row.GetView());
        Observer.Observe('order', Order(Row));
        Row.SetCurrentKey(Description, Amount);
        Observer.Observe('key2', Row.CurrentKey());
        Observer.Observe('view2', Row.GetView());
        Observer.Observe('order2', Order(Row));
        Observer.Expect('key', 'Description');
        Observer.Expect('view', 'VERSION(1) SORTING(Description)');
        Observer.Expect('order', '2,5,4,3,1,');
        Observer.Expect('key2', 'Description,Amount');
        Observer.Expect('view2', 'VERSION(1) SORTING(Description,Amount)');
        Observer.Expect('order2', '5,2,4,3,1,');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_ThenResetAndGetView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SVS Row";
    begin
        Seed();
        Row.SetView('SORTING(Description) WHERE(Category=FILTER(X))');
        Row.Reset();
        Observer.Observe('after_reset_view', Row.GetView());
        Observer.Observe('after_reset_key', Row.CurrentKey());
        Observer.Observe('after_reset_order', Order(Row));
        Row.SetView('SORTING(Description) WHERE(Category=FILTER(X))');
        Row.SetRange(Category, 'Y');
        Observer.Observe('then_setrange_view', Row.GetView());
        Observer.Observe('then_setrange_order', Order(Row));
        Observer.Observe('findlast', Format(Row.FindLast()) + ':' + Format(Row.Id));
        Observer.Observe('findfirst', Format(Row.FindFirst()) + ':' + Format(Row.Id));
        Observer.Expect('after_reset_view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after_reset_key', 'Id');
        Observer.Expect('after_reset_order', '1,2,3,4,5,');
        Observer.Expect('then_setrange_view', 'VERSION(1) SORTING(Description) WHERE(Category=FILTER(Y))');
        Observer.Expect('then_setrange_order', '4,3,');
        Observer.Expect('findlast', 'Yes:3');
        Observer.Expect('findfirst', 'Yes:4');
        Observer.Verify();
    end;
}
