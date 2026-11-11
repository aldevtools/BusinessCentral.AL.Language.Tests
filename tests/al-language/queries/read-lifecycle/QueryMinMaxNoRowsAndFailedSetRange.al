// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-method-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 96640, queries 96641-96642, codeunit 96643.
// Probe: from the code-sweep issue al-runner 7637. The expected values are what the corpus CI legs (BC 27.5, 28.5, 29.0) returned.
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
        Observer.Expect('row 1', 'dec=[0|0] big=[0|0] dur=[|]');
        Observer.Expect('rows', '1');
        Observer.Expect('filtered rows', '0');
        Observer.Verify();
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
        // A first measurement failed here (the read of Grp after the last Read raised an error): each column is read on its own now.
        ReadColumn(Observer, Q, 'grp');
        ReadColumn(Observer, Q, 'dt');
        ReadColumn(Observer, Q, 'dec');
        ReadColumn(Observer, Q, 'big');
        Observer.Expect('rows', '0');
        Observer.Expect('grp', 'error');
        Observer.Expect('grp|text', 'You have not yet retrieved a data row for this query. The value for column ''Grp'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('grp|code', 'QueryNoDataSet');
        Observer.Expect('dt', 'error');
        Observer.Expect('dt|text', 'You have not yet retrieved a data row for this query. The value for column ''Dt'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('dt|code', 'QueryNoDataSet');
        Observer.Expect('dec', 'error');
        Observer.Expect('dec|text', 'You have not yet retrieved a data row for this query. The value for column ''MinDec'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('dec|code', 'QueryNoDataSet');
        Observer.Expect('big', 'error');
        Observer.Expect('big|text', 'You have not yet retrieved a data row for this query. The value for column ''MaxBig'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('big|code', 'QueryNoDataSet');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryColumn(var Q: Query "LT QMN Grouped"; Which: Text; var Result: Text)
    begin
        case Which of
            'grp':
                Result := Q.Grp;
            'dt':
                Result := Format(Q.Dt, 0, 9);
            'dec':
                Result := Format(Q.MinDec);
            'big':
                Result := Format(Q.MaxBig);
        end;
    end;

    local procedure ReadColumn(var Observer: Codeunit "Probe Observer"; var Q: Query "LT QMN Grouped"; Which: Text)
    var
        Result: Text;
    begin
        if TryColumn(Q, Which, Result) then
            Observer.Observe(Which, Result)
        else begin
            Observer.Observe(Which, 'error');
            Observer.ObserveError(Which);
        end;
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
        Observer.Expect('read 1', 'Yes G1');
        Observer.Expect('setrange', 'No');
#if BC28PLUS
        Observer.Expect('setrange|text', 'The format of the Date ''not a date'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('setrange|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('setrange|code', 'Evaluate:Conversion');
#else
        Observer.Expect('setrange|code', 'Conversion');
#endif
        Observer.Expect('read 2', 'Yes Yes G2');
        Observer.Expect('read 2|text', '');
        Observer.Expect('read 2|code', '');
        Observer.Expect('read 3', 'Yes Yes G3');
        Observer.Expect('read 3|text', '');
        Observer.Expect('read 3|code', '');
        Observer.Expect('getfilters', '');
        Observer.Verify();
    end;
}
