// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 81875
// Probe: corpus issue 673 item 5 (al-runtime-rs #296). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts: SetFilter on a Decimal field with text that is not a number ('NOT-A-NUMBER', '1..x', '1|abc', '>abc', '<>abc', '1;5', '1,5', '1e3', ...): the error text and code, or GetFilter; the filter on the field after the error; the same text on BigInteger, Duration, Date, Time and Guid fields; a temporary and a non-temporary record. A Text placeholder value for a Decimal field does not compile (must-not-compile case 1361).
// BC versions: 27+

table 81875 "LT BL Bad Filter Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Amount; Decimal) { }
        field(3; Big; BigInteger) { }
        field(4; Dur; Duration) { }
        field(5; Dt; Date) { }
        field(6; Tm; Time) { }
        field(7; Gd; Guid) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 81876 "LT BL Invalid Decimal Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySet(var Row: Record "LT BL Bad Filter Row" temporary; FieldNo: Integer; Filter: Text)
    begin
        case FieldNo of
            2:
                Row.SetFilter(Amount, Filter);
            3:
                Row.SetFilter(Big, Filter);
            4:
                Row.SetFilter(Dur, Filter);
            5:
                Row.SetFilter(Dt, Filter);
            6:
                Row.SetFilter(Tm, Filter);
            7:
                Row.SetFilter(Gd, Filter);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Filter: Text)
    var
        Row: Record "LT BL Bad Filter Row" temporary;
    begin
        ClearLastError();
        if TrySet(Row, FieldNo, Filter) then
            Observer.Observe(Format(FieldNo) + ' ' + Filter, 'ok [' + Row.GetFilters() + ']')
        else
            Observer.Observe(Format(FieldNo) + ' ' + Filter, 'error [' + GetLastErrorText() + '] [' + GetLastErrorCode() + ']');
    end;

    // The al-runtime-rs #296 repro.
    [Test]
    procedure Repro_InvalidDecimalFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Bad Filter Row" temporary;
    begin
        asserterror Row.SetFilter(Amount, 'NOT-A-NUMBER');
        Observer.ObserveError('not-a-number');
        Observer.Expect('not-a-number|text', 'The filter "NOT-A-NUMBER" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "NOT-A-NUMBER" can''t be evaluated into type Decimal.');
        Observer.Expect('not-a-number|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure Repro_NonTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Bad Filter Row";
    begin
        asserterror Row.SetFilter(Amount, 'NOT-A-NUMBER');
        Observer.ObserveError('not-a-number');
        Observer.Expect('not-a-number|text', 'The filter "NOT-A-NUMBER" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "NOT-A-NUMBER" can''t be evaluated into type Decimal.');
        Observer.Expect('not-a-number|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 2, 'abc');
        Probe(Observer, 2, '1..x');
        Probe(Observer, 2, 'x..1');
        Probe(Observer, 2, '1|abc');
        Probe(Observer, 2, '>abc');
        Probe(Observer, 2, '<>abc');
        Probe(Observer, 2, '1;5');
        Probe(Observer, 2, '1,5');
        Probe(Observer, 2, '1e3');
        Probe(Observer, 2, '1.2.3');
        Probe(Observer, 2, '1..');
        Probe(Observer, 2, '..1');
        Probe(Observer, 2, '''abc''');
        Probe(Observer, 2, '*');
        Probe(Observer, 2, '-');
        Observer.Expect('2 abc', 'error [The filter "abc" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "abc" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 1..x', 'error [The filter "1..x" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "x" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 x..1', 'error [The filter "x..1" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "x" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 1|abc', 'error [The filter "1|abc" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "abc" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 >abc', 'error [The filter ">abc" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "abc" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 <>abc', 'error [The filter "<>abc" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "abc" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 1;5', 'error [The filter "1;5" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "1;5" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 1,5', 'ok [Amount: 15]');
        Observer.Expect('2 1e3', 'ok [Amount: 1,000]');
        Observer.Expect('2 1.2.3', 'error [The filter "1.2.3" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "1.2.3" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 1..', 'ok [Amount: 1..]');
        Observer.Expect('2 ..1', 'ok [Amount: ..1]');
        Observer.Expect('2 ''abc''', 'error [The filter "''abc''" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "abc" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 *', 'error [The filter "*" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "*" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Expect('2 -', 'error [The filter "-" is not valid for the Amount field on the LT BL Bad Filter Row table. The value "-" can''t be evaluated into type Decimal.] [Filter:CSide]');
        Observer.Verify();
    end;

    [Test]
    procedure Other_Types()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 3, 'NOT-A-NUMBER');
        Probe(Observer, 4, 'NOT-A-NUMBER');
        Probe(Observer, 5, 'NOT-A-NUMBER');
        Probe(Observer, 6, 'NOT-A-NUMBER');
        Probe(Observer, 7, 'NOT-A-NUMBER');
        Observer.Expect('3 NOT-A-NUMBER', 'error [The filter "NOT-A-NUMBER" is not valid for the Big field on the LT BL Bad Filter Row table. The value "NOT-A-NUMBER" can''t be evaluated into type BigInteger.] [Filter:CSide]');
        Observer.Expect('4 NOT-A-NUMBER', 'error [The filter "NOT-A-NUMBER" is not valid for the Dur field on the LT BL Bad Filter Row table. The value "NOT-A-NUMBER" can''t be evaluated into type Duration.] [Filter:CSide]');
        Observer.Expect('5 NOT-A-NUMBER', 'error [The filter "NOT-A-NUMBER" is not valid for the Dt field on the LT BL Bad Filter Row table. The format of the Date ''NOT-A-NUMBER'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.] [Filter:CSide]');
        Observer.Expect('6 NOT-A-NUMBER', 'error [The filter "NOT-A-NUMBER" is not valid for the Tm field on the LT BL Bad Filter Row table. The value "NOT-A-NUMBER" can''t be evaluated into type Time.] [Filter:CSide]');
        Observer.Expect('7 NOT-A-NUMBER', 'error [The filter "NOT-A-NUMBER" is not valid for the Gd field on the LT BL Bad Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.] [Filter:CSide]');
        Observer.Verify();
    end;

    [Test]
    procedure FilterKept_AfterError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Bad Filter Row" temporary;
    begin
        Row."No." := 1;
        Row.Amount := 5;
        Row.Insert();
        Row."No." := 2;
        Row.Amount := 7;
        Row.Insert();
        Row.SetFilter(Amount, '5');
        if TrySet(Row, 2, 'NOT-A-NUMBER') then
            Observer.Observe('second setfilter', 'ok')
        else
            Observer.Observe('second setfilter', 'error');
        Observer.Observe('getfilter after', Row.GetFilter(Amount));
        Observer.Observe('count after', Format(Row.Count()));
        Observer.Expect('second setfilter', 'error');
        Observer.Expect('getfilter after', '5');
        Observer.Expect('count after', '1');
        Observer.Verify();
    end;
}
