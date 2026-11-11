// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-method-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 96640, queries 96641-96642, codeunit 96643.
// Probe: from the code-sweep issue al-runner 7637. Observation form: every test ends in Observer.Finish(), so its failure message holds
//   BC's values.
// Area:
//   - Min and Max over no rows for Decimal, BigInteger and Duration columns, without and with grouping columns (the Integer form is
//     pinned: queries/TestQueryRuntimeContracts.al:357-372; other column types do not compile, AL0347);
//   - SetRange after a Read with a value that does not convert to the column's type (a Text that is no date, through a Variant): the error,
//     and whether the next Read still answers from the open query.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

table 96640 "LT QMN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Dec; Decimal) { }
        field(4; Dt; Date) { }
        field(5; Tm; Time) { }
        field(6; DtTm; DateTime) { }
        field(7; Txt; Text[30]) { }
        field(8; Cd; Code[20]) { }
        field(9; Big; BigInteger) { }
        field(10; Dur; Duration) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 96641 "LT QMN Scalar"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT QMN Row")
        {
            column(MinDec; Dec) { Method = Min; }
            column(MaxDec; Dec) { Method = Max; }
            column(MinBig; Big) { Method = Min; }
            column(MaxBig; Big) { Method = Max; }
            column(MinDur; Dur) { Method = Min; }
            column(MaxDur; Dur) { Method = Max; }
        }
    }
}

query 96642 "LT QMN Grouped"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT QMN Row")
        {
            column(Grp; Grp) { }
            column(Dt; Dt) { }
            column(MinDec; Dec) { Method = Min; }
            column(MaxBig; Big) { Method = Max; }
        }
    }
}

codeunit 96643 "LT QMN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ScalarText(var Q: Query "LT QMN Scalar"): Text
    begin
        exit('dec=[' + Format(Q.MinDec) + '|' + Format(Q.MaxDec) + '] big=[' + Format(Q.MinBig) + '|' + Format(Q.MaxBig) +
            '] dur=[' + Format(Q.MinDur) + '|' + Format(Q.MaxDur) + ']');
    end;

    [Test]
    procedure QMN_MinMax_NoRows_Scalar()
    var
        Row: Record "LT QMN Row";
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QMN Scalar";
        Rows: Integer;
    begin
        Row.DeleteAll();
        Q.Open();
        while Q.Read() do begin
            Rows += 1;
            Observer.Observe('row ' + Format(Rows), ScalarText(Q));
        end;
        Q.Close();
        Observer.Observe('rows', Format(Rows));
        Row.Id := 1;
        Row.Grp := 'G';
        Row.Insert();
        Q.SetRange(MinDec, 5);
        Q.Open();
        Rows := 0;
        while Q.Read() do begin
            Rows += 1;
            Observer.Observe('filtered row ' + Format(Rows), ScalarText(Q));
        end;
        Observer.Observe('filtered rows', Format(Rows));
        Observer.Finish();
    end;

    [Test]
    procedure QMN_MinMax_NoRows_Grouped()
    var
        Row: Record "LT QMN Row";
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QMN Grouped";
        Rows: Integer;
    begin
        Row.DeleteAll();
        Q.Open();
        while Q.Read() do
            Rows += 1;
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('after', 'grp=[' + Q.Grp + '] dt=[' + Format(Q.Dt, 0, 9) + '] dec=[' + Format(Q.MinDec) + '] big=[' + Format(Q.MaxBig) + ']');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetRangeDt(var Q: Query "LT QMN Grouped"; Value: Variant)
    begin
        Q.SetRange(Dt, Value);
    end;

    [TryFunction]
    local procedure TryRead(var Q: Query "LT QMN Grouped"; var Got: Boolean)
    begin
        Got := Q.Read();
    end;

    [Test]
    procedure QMN_SetRangeAfterRead_ValueThatDoesNotConvert()
    var
        Row: Record "LT QMN Row";
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QMN Grouped";
        Bad: Variant;
        Got: Boolean;
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Grp := 'G' + Format(I);
            Row.Dt := DMY2Date(I, 1, 2026);
            Row.Insert();
        end;
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()) + ' ' + Q.Grp);
        Bad := 'not a date';
        ClearLastError();
        Observer.Observe('setrange', Format(TrySetRangeDt(Q, Bad)));
        Observer.ObserveError('setrange');
        ClearLastError();
        Observer.Observe('read 2', Format(TryRead(Q, Got)) + ' ' + Format(Got) + ' ' + Q.Grp);
        Observer.ObserveError('read 2');
        Observer.Observe('read 3', Format(TryRead(Q, Got)) + ' ' + Format(Got) + ' ' + Q.Grp);
        Observer.ObserveError('read 3');
        Observer.Observe('getfilters', Q.GetFilters());
        Observer.Finish();
    end;
}
