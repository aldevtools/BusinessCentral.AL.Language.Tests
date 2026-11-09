// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 74982, test codeunit 74983
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.SetRange with an empty (never assigned) DateFormula and with an empty RecordId: the text FieldRef.GetFilter and
//   RecordRef.GetFilters return, the rows a FindSet returns, and what SetFilter with '<>' plus that text does on the same field and
//   on another field. FieldRef.SetFilter on a Blob field with '' (empty), two single quotes, '<>' plus two single quotes and a
//   range of the two: whether it raises, GetFilter and the rows returned.
//   Asked by al-runner issues 7437 (empty DateFormula and RecordId) and 7426 (empty quotes on a Blob field).
// BC versions: 27, 28, 29 by CI

table 74982 "LT FRF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Due; DateFormula) { }
        field(3; Rid; RecordId) { }
        field(4; Data; Blob) { }
        field(5; Due2; DateFormula) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 74983 "LT FRF Filter Empty Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed()
    var
        R: Record "LT FRF Row";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R.Code := 'NONE1';
        R.Insert();
        R.Code := 'NONE2';
        R.Insert();
        R.Code := 'DAY';
        Evaluate(R.Due, '<1D>');
        Evaluate(R.Due2, '<1D>');
        R.Rid := R.RecordId();
        R.Data.CreateOutStream(OutS);
        OutS.WriteText('abc');
        R.Insert();
        R.Code := 'MONTH';
        Evaluate(R.Due, '<1M>');
        Clear(R.Due2);
        R.Rid := R.RecordId();
        Clear(R.Data);
        R.Insert();
        Obs.Observe('total', Format(R.Count()));
    end;

    local procedure Rows(var RecRef: RecordRef): Text
    var
        Result: Text;
    begin
        if RecRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(RecRef.Field(1).Value());
            until RecRef.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryFilter(var FldRef: FieldRef; Expr: Text)
    begin
        FldRef.SetFilter(Expr);
    end;

    [TryFunction]
    local procedure TryRangeDf(var FldRef: FieldRef)
    var
        Empty: DateFormula;
    begin
        FldRef.SetRange(Empty);
    end;

    [TryFunction]
    local procedure TryRangeRid(var FldRef: FieldRef)
    var
        Empty: RecordId;
    begin
        FldRef.SetRange(Empty);
    end;

    [TryFunction]
    local procedure TryRangeBlob(var FldRef: FieldRef; Lo: Text; Hi: Text)
    begin
        FldRef.SetRange(Lo, Hi);
    end;

    local procedure Report(Name: Text; var RecRef: RecordRef; var FldRef: FieldRef; Ok: Boolean)
    begin
        if not Ok then begin
            Obs.ObserveError(Name);
            exit;
        end;
        Obs.Observe(Name + '.filter', FldRef.GetFilter());
        Obs.Observe(Name + '.filters', RecRef.GetFilters());
        Obs.Observe(Name + '.rows', Rows(RecRef));
    end;

    local procedure OpenRef(var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"LT FRF Row");
    end;

    [Test]
    procedure FieldRef_SetRange_EmptyDateFormula_GetFilterText()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Text1: Text;
    begin
        Seed();
        OpenRef(RecRef);
        FldRef := RecRef.Field(2);
        Report('range_empty', RecRef, FldRef, TryRangeDf(FldRef));
        Text1 := FldRef.GetFilter();
        Obs.Observe('text_length', Format(StrLen(Text1)));
        RecRef.Reset();
        FldRef := RecRef.Field(2);
        Report('neq_text_same_field', RecRef, FldRef, TryFilter(FldRef, '<>' + Text1));
        RecRef.Reset();
        FldRef := RecRef.Field(5);
        Report('neq_text_other_field', RecRef, FldRef, TryFilter(FldRef, '<>' + Text1));
        RecRef.Reset();
        FldRef := RecRef.Field(5);
        Report('eq_text_other_field', RecRef, FldRef, TryFilter(FldRef, Text1));
        RecRef.Close();
        Obs.Expect('total', '4');
        Obs.Expect('range_empty.filter', '''''');
        Obs.Expect('range_empty.filters', 'Due: ''''');
        Obs.Expect('range_empty.rows', 'NONE1,NONE2');
        Obs.Expect('text_length', '2');
        Obs.Expect('neq_text_same_field.filter', '<>''''');
        Obs.Expect('neq_text_same_field.filters', 'Due: <>''''');
        Obs.Expect('neq_text_same_field.rows', 'DAY,MONTH');
        Obs.Expect('neq_text_other_field.filter', '<>''''');
        Obs.Expect('neq_text_other_field.filters', 'Due2: <>''''');
        Obs.Expect('neq_text_other_field.rows', 'DAY');
        Obs.Expect('eq_text_other_field.filter', '''''');
        Obs.Expect('eq_text_other_field.filters', 'Due2: ''''');
        Obs.Expect('eq_text_other_field.rows', 'MONTH,NONE1,NONE2');
        Obs.Verify();
    end;

    [Test]
    procedure FieldRef_SetRange_EmptyRecordId_GetFilterText()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Text1: Text;
    begin
        Seed();
        OpenRef(RecRef);
        FldRef := RecRef.Field(3);
        Report('range_empty', RecRef, FldRef, TryRangeRid(FldRef));
        Text1 := FldRef.GetFilter();
        Obs.Observe('text_length', Format(StrLen(Text1)));
        RecRef.Reset();
        FldRef := RecRef.Field(3);
        Report('neq_text_same_field', RecRef, FldRef, TryFilter(FldRef, '<>' + Text1));
        RecRef.Reset();
        FldRef := RecRef.Field(3);
        Report('eq_text_same_field', RecRef, FldRef, TryFilter(FldRef, Text1));
        RecRef.Close();
        Obs.Expect('total', '4');
        Obs.Expect('range_empty.filter', '''''');
        Obs.Expect('range_empty.filters', 'Rid: ''''');
        Obs.Expect('range_empty.rows', 'NONE1,NONE2');
        Obs.Expect('text_length', '2');
        Obs.Expect('neq_text_same_field.filter', '<>''''');
        Obs.Expect('neq_text_same_field.filters', 'Rid: <>''''');
        Obs.Expect('neq_text_same_field.rows', 'DAY,MONTH');
        Obs.Expect('eq_text_same_field.filter', '''''');
        Obs.Expect('eq_text_same_field.filters', 'Rid: ''''');
        Obs.Expect('eq_text_same_field.rows', 'NONE1,NONE2');
        Obs.Verify();
    end;

    [Test]
    procedure FieldRef_SetFilter_EmptyQuotesOnBlob()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Seed();
        OpenRef(RecRef);
        FldRef := RecRef.Field(4);
        Report('empty', RecRef, FldRef, TryFilter(FldRef, ''));
        RecRef.Reset();
        FldRef := RecRef.Field(4);
        Report('quotes', RecRef, FldRef, TryFilter(FldRef, ''''''));
        RecRef.Reset();
        FldRef := RecRef.Field(4);
        Report('neq_quotes', RecRef, FldRef, TryFilter(FldRef, '<>'''''));
        RecRef.Reset();
        FldRef := RecRef.Field(4);
        Report('neq_bare', RecRef, FldRef, TryFilter(FldRef, '<>'));
        RecRef.Reset();
        FldRef := RecRef.Field(4);
        Report('text_value', RecRef, FldRef, TryFilter(FldRef, 'abc'));
        RecRef.Reset();
        FldRef := RecRef.Field(4);
        Report('range_quotes', RecRef, FldRef, TryRangeBlob(FldRef, '', ''));
        RecRef.Close();
        Obs.Expect('total', '4');
        Obs.Expect('empty.filter', '');
        Obs.Expect('empty.filters', '');
        Obs.Expect('empty.rows', 'DAY,MONTH,NONE1,NONE2');
        Obs.Expect('quotes.filter', ''' ''');
        Obs.Expect('quotes.filters', 'Data: '' ''');
        Obs.Expect('quotes.rows', 'MONTH,NONE1,NONE2');
        Obs.Expect('neq_quotes.filter', '<>'' ''');
        Obs.Expect('neq_quotes.filters', 'Data: <>'' ''');
        Obs.Expect('neq_quotes.rows', 'DAY');
        Obs.Expect('neq_bare|text', 'The filter "<>" is not valid for the Data field on the LT FRF Row table. A value is expected after the ''<>''.');
        Obs.Expect('neq_bare|code', 'Filter:CSide');
        Obs.Expect('text_value|text', 'The filter "abc" is not valid for the Data field on the LT FRF Row table. The value "abc" can''t be evaluated into type BLOB.');
        Obs.Expect('text_value|code', 'Filter:CSide');
        // The error of the range on a Blob field differs: BC 28.5 and 29.0 raise the Evaluate error, BC 27.5 an invalid conversion
        // (CI subset runs 42625890377, 42625924631, 42625958537).
#if BC28PLUS
        Obs.Expect('range_quotes|text', 'The value "" can''t be evaluated into type BLOB.');
        Obs.Expect('range_quotes|code', 'Evaluate:Argument');
#else
        Obs.Expect('range_quotes|text', 'Invalid Conversion. Source: NavText, Destination: NavBLOB.');
        Obs.Expect('range_quotes|code', 'Argument');
#endif
        Obs.Verify();
    end;
}
