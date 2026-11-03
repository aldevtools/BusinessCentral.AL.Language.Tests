// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74863, codeunit 74864
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent) against GetLastErrorText(false) and GetLastErrorCode when FindFirst, FindLast, FindSet, FindSet(true) and Find('-'), Find('+'), Find('=') are used as statements on an empty table, and when FindFirst, FindLast, FindSet find nothing in a filter of a table that has rows. The empty-table test is guarded with BC28PLUS (pinned only from BC 28: errors/lt-error-handling/ErTRuntimeErrors.al); the lead decides what BC 27 observes.
// BC versions: 29 (empty-table test: 28 and later)

table 74863 "LT FND Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74864 "LT FND Find Flag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFindFirst(var Row: Record "LT FND Row")
    begin
        Row.FindFirst();
    end;

    [TryFunction]
    local procedure TryFindLast(var Row: Record "LT FND Row")
    begin
        Row.FindLast();
    end;

    [TryFunction]
    local procedure TryFindSet(var Row: Record "LT FND Row")
    begin
        Row.FindSet();
    end;

    [TryFunction]
    local procedure TryFindSetForUpdate(var Row: Record "LT FND Row")
    begin
        Row.FindSet(true);
    end;

    [TryFunction]
    local procedure TryFindMinus(var Row: Record "LT FND Row")
    begin
        Row.Find('-');
    end;

    [TryFunction]
    local procedure TryFindPlus(var Row: Record "LT FND Row")
    begin
        Row.Find('+');
    end;

    [TryFunction]
    local procedure TryFindEqual(var Row: Record "LT FND Row")
    begin
        Row.Find('=');
    end;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

#if BC28PLUS
    [Test]
    procedure FindOnEmptyTable_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FND Row";
    begin
        Row.DeleteAll();
        Observer.Observe('first', Format(TryFindFirst(Row)));
        Forms('first', Observer);
        Observer.Observe('last', Format(TryFindLast(Row)));
        Forms('last', Observer);
        Observer.Observe('set', Format(TryFindSet(Row)));
        Forms('set', Observer);
        Observer.Observe('setupd', Format(TryFindSetForUpdate(Row)));
        Forms('setupd', Observer);
        Observer.Observe('minus', Format(TryFindMinus(Row)));
        Forms('minus', Observer);
        Observer.Observe('plus', Format(TryFindPlus(Row)));
        Forms('plus', Observer);
        Observer.Observe('equal', Format(TryFindEqual(Row)));
        Forms('equal', Observer);
        Observer.Expect('first', 'No');
        Observer.Expect('first_true', 'The LT FND Row table is empty.');
        Observer.Expect('first_false', 'The LT FND Row table is empty.');
        Observer.Expect('first_code', 'DB:TableIsEmpty');
        Observer.Expect('last', 'No');
        Observer.Expect('last_true', 'The LT FND Row table is empty.');
        Observer.Expect('last_false', 'The LT FND Row table is empty.');
        Observer.Expect('last_code', 'DB:TableIsEmpty');
        Observer.Expect('set', 'No');
        Observer.Expect('set_true', 'The LT FND Row table is empty.');
        Observer.Expect('set_false', 'The LT FND Row table is empty.');
        Observer.Expect('set_code', 'DB:TableIsEmpty');
        Observer.Expect('setupd', 'No');
        Observer.Expect('setupd_true', 'The LT FND Row table is empty.');
        Observer.Expect('setupd_false', 'The LT FND Row table is empty.');
        Observer.Expect('setupd_code', 'DB:TableIsEmpty');
        Observer.Expect('minus', 'No');
        Observer.Expect('minus_true', 'The LT FND Row table is empty.');
        Observer.Expect('minus_false', 'The LT FND Row table is empty.');
        Observer.Expect('minus_code', 'DB:TableIsEmpty');
        Observer.Expect('plus', 'No');
        Observer.Expect('plus_true', 'The LT FND Row table is empty.');
        Observer.Expect('plus_false', 'The LT FND Row table is empty.');
        Observer.Expect('plus_code', 'DB:TableIsEmpty');
        Observer.Expect('equal', 'No');
        Observer.Expect('equal_true', 'The LT FND Row does not exist. Identification fields and values: <redacted>');
        Observer.Expect('equal_false', 'The LT FND Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('equal_code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure FindNothingInFilter_NonEmptyTable_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FND Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.SetRange(Id, 99);
        Observer.Observe('first', Format(TryFindFirst(Row)));
        Forms('first', Observer);
        Observer.Observe('last', Format(TryFindLast(Row)));
        Forms('last', Observer);
        Observer.Observe('set', Format(TryFindSet(Row)));
        Forms('set', Observer);
        Observer.Expect('first', 'No');
        Observer.Expect('first_true', 'There is no LT FND Row within the filter.\\Filters: <redacted>');
        Observer.Expect('first_false', 'There is no LT FND Row within the filter.\\Filters: Id: 99');
        Observer.Expect('first_code', 'DB:NothingInsideFilter');
        Observer.Expect('last', 'No');
        Observer.Expect('last_true', 'There is no LT FND Row within the filter.\\Filters: <redacted>');
        Observer.Expect('last_false', 'There is no LT FND Row within the filter.\\Filters: Id: 99');
        Observer.Expect('last_code', 'DB:NothingInsideFilter');
        Observer.Expect('set', 'No');
        Observer.Expect('set_true', 'There is no LT FND Row within the filter.\\Filters: <redacted>');
        Observer.Expect('set_false', 'There is no LT FND Row within the filter.\\Filters: Id: 99');
        Observer.Expect('set_code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;
}
