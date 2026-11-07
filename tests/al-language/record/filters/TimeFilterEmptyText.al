// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); ALT Universal (60000): "Time Field", "Date Field", "DateTime Field"
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on a Time field with a quoted empty text ('') as the value: alone, after =, <>, <, >, <=, >=, as a range end, in an
//   OR list with 0T given as %1, after <> with 0T as %1, the operator alone, and SetRange with 0T. Rows: one with 10:00:00 and two
//   without a time. Each filter: whether it raises, GetFilter and Count. The same filters on a Date and a DateTime field for contrast.
//   Asked by al-runner issue 6900 (a partner app filters "not empty" on a Time field with '<>''''').
// BC versions: 27, 28, 29 by CI

codeunit 95810 "REC Time Filter Empty Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Row: Record "ALT Universal";

    local procedure Initialize()
    begin
        Row.Reset();
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row."Time Field" := 100000T;
        Row."Date Field" := 20240305D;
        Row."DateTime Field" := CreateDateTime(20240305D, 100000T);
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row."Time Field" := 0T;
        Row."Date Field" := 0D;
        Row."DateTime Field" := 0DT;
        Row.Insert();
        Row.Init();
        Row."Entry No." := 3;
        Row.Insert();
        Row.Reset();
    end;

    [TryFunction]
    local procedure TryFilter(FieldNo: Integer; Filter: Text; var Result: Text)
    begin
        case FieldNo of
            9:
                Row.SetFilter("Time Field", Filter);
            8:
                Row.SetFilter("Date Field", Filter);
            10:
                Row.SetFilter("DateTime Field", Filter);
        end;
        Result := Format(Row.Count()) + ' | ' + Row.GetFilters();
    end;

    [TryFunction]
    local procedure TryFilterArg(FieldNo: Integer; Filter: Text; var Result: Text)
    begin
        case FieldNo of
            9:
                Row.SetFilter("Time Field", Filter, 0T);
            8:
                Row.SetFilter("Date Field", Filter, 0D);
            10:
                Row.SetFilter("DateTime Field", Filter, 0DT);
        end;
        Result := Format(Row.Count()) + ' | ' + Row.GetFilters();
    end;

    local procedure Probe(FieldNo: Integer; Filter: Text; WithArg: Boolean): Text
    var
        Result: Text;
        Ok: Boolean;
    begin
        Row.Reset();
        ClearLastError();
        if WithArg then
            Ok := TryFilterArg(FieldNo, Filter, Result)
        else
            Ok := TryFilter(FieldNo, Filter, Result);
        Row.Reset();
        if Ok then
            exit('[' + Result + ']');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    local procedure ObserveAll(FieldNo: Integer; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('ne empty', Probe(FieldNo, '<>''''', false));
        Observer.Observe('empty', Probe(FieldNo, '''''', false));
        Observer.Observe('eq empty', Probe(FieldNo, '=''''', false));
        Observer.Observe('lt empty', Probe(FieldNo, '<''''', false));
        Observer.Observe('gt empty', Probe(FieldNo, '>''''', false));
        Observer.Observe('le empty', Probe(FieldNo, '<=''''', false));
        Observer.Observe('ge empty', Probe(FieldNo, '>=''''', false));
        Observer.Observe('range from empty', Probe(FieldNo, '''''..', false));
        Observer.Observe('range to empty', Probe(FieldNo, '..''''', false));
        Observer.Observe('empty or arg', Probe(FieldNo, '''''|%1', true));
        Observer.Observe('ne arg', Probe(FieldNo, '<>%1', true));
        Observer.Observe('ne alone', Probe(FieldNo, '<>', false));
        Observer.Observe('ne empty and ne arg', Probe(FieldNo, '<>''''&<>%1', true));
    end;

    [Test]
    procedure SetFilter_TimeField_QuotedEmptyText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ObserveAll(9, Observer);
        Row.SetRange("Time Field", 0T);
        Observer.Observe('setrange 0T', Format(Row.Count()) + ' | ' + Row.GetFilters());
        Row.Reset();
        Observer.Expect('ne empty', '[1 | Time Field: <>'''']');
        Observer.Expect('empty', '[2 | Time Field: '''']');
        Observer.Expect('eq empty', '[2 | Time Field: '''']');
        Observer.Expect('lt empty', '[0 | Time Field: <'''']');
        Observer.Expect('gt empty', '[1 | Time Field: >'''']');
        Observer.Expect('le empty', '[2 | Time Field: <='''']');
        Observer.Expect('ge empty', '[3 | Time Field: >='''']');
        Observer.Expect('range from empty', '[3 | Time Field: ''''..]');
        Observer.Expect('range to empty', '[2 | Time Field: ..'''']');
        Observer.Expect('empty or arg', '[2 | Time Field: ''''|'''']');
        Observer.Expect('ne arg', '[1 | Time Field: <>'''']');
        Observer.Expect('ne alone', 'error: The filter "<>" is not valid for the Time Field field on the ALT Universal table. A value is expected after the ''<>''. | Filter:CSide');
        Observer.Expect('ne empty and ne arg', '[1 | Time Field: <>''''&<>'''']');
        Observer.Expect('setrange 0T', '2 | Time Field: ''''');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_DateField_QuotedEmptyText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ObserveAll(8, Observer);
        Observer.Expect('ne empty', '[1 | Date Field: <>'''']');
        Observer.Expect('empty', '[2 | Date Field: '''']');
        Observer.Expect('eq empty', '[2 | Date Field: '''']');
        Observer.Expect('lt empty', '[0 | Date Field: <'''']');
        Observer.Expect('gt empty', '[1 | Date Field: >'''']');
        Observer.Expect('le empty', '[2 | Date Field: <='''']');
        Observer.Expect('ge empty', '[3 | Date Field: >='''']');
        Observer.Expect('range from empty', '[3 | Date Field: ''''..]');
        Observer.Expect('range to empty', '[2 | Date Field: ..'''']');
        Observer.Expect('empty or arg', '[2 | Date Field: ''''|'''']');
        Observer.Expect('ne arg', '[1 | Date Field: <>'''']');
        Observer.Expect('ne alone', 'error: The filter "<>" is not valid for the Date Field field on the ALT Universal table. A value is expected after the ''<>''. | Filter:CSide');
        Observer.Expect('ne empty and ne arg', '[1 | Date Field: <>''''&<>'''']');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_DateTimeField_QuotedEmptyText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ObserveAll(10, Observer);
        Observer.Expect('ne empty', '[1 | DateTime Field: <>'''']');
        Observer.Expect('empty', '[2 | DateTime Field: ''''..'''']');
        Observer.Expect('eq empty', '[2 | DateTime Field: '''']');
        Observer.Expect('lt empty', '[0 | DateTime Field: <'''']');
        Observer.Expect('gt empty', '[1 | DateTime Field: >'''']');
        Observer.Expect('le empty', '[2 | DateTime Field: <='''']');
        Observer.Expect('ge empty', '[3 | DateTime Field: >='''']');
        Observer.Expect('range from empty', '[3 | DateTime Field: ''''..]');
        Observer.Expect('range to empty', '[2 | DateTime Field: ..'''']');
        Observer.Expect('empty or arg', '[2 | DateTime Field: ''''..''''|'''']');
        Observer.Expect('ne arg', '[1 | DateTime Field: <>'''']');
        Observer.Expect('ne alone', 'error: The filter "<>" is not valid for the DateTime Field field on the ALT Universal table. A value is expected after the ''<>''. | Filter:CSide');
        Observer.Expect('ne empty and ne arg', '[1 | DateTime Field: <>''''&<>'''']');
        Observer.Verify();
    end;
}
