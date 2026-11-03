// Scope: in-scope. Fixtures used: none. Probe: BC 29, GitHub issue 143. Own table with a Date and a Guid field, seeded rows, and the filter helper. BC versions: 29
table 74647 "LT P143 Row"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; D; Date)
        {
        }
        field(3; G; Guid)
        {
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}

codeunit 74648 "LT P143 Helper"
{
    // rows: 1 = 17 Jan 2027, 2 = 18 Oct 2026, 3 = 31 Dec 9999, 4 = 1 Jan 2027, 5 = 31 Jan 2027, 6 = no date,
    // 7 = Today, 8 = WorkDate, 9 = ClosingDate(18 Oct 2026), 10 = ClosingDate(1 Jan 2027).
    // Guids: row 1 = AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE, row 2 = 11111111-2222-3333-4444-555555555555, row 3 = 0A0B0C0D-0000-1111-2222-333333333333, others empty.
    procedure Seed()
    var
        Row: Record "LT P143 Row";
    begin
        Row.DeleteAll();
        Add(1, 20270117D, 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE');
        Add(2, 20261018D, '11111111-2222-3333-4444-555555555555');
        Add(3, 99991231D, '0A0B0C0D-0000-1111-2222-333333333333');
        Add(4, 20270101D, '');
        Add(5, 20270131D, '');
        Add(6, 0D, '');
        Add(7, Today(), '');
        Add(8, WorkDate(), '');
        Add(9, ClosingDate(20261018D), '');
        Add(10, ClosingDate(20270101D), '');
    end;

    local procedure Add(Id: Integer; D: Date; GuidText: Text)
    var
        Row: Record "LT P143 Row";
    begin
        Row.Id := Id;
        Row.D := D;
        if GuidText <> '' then
            Evaluate(Row.G, '{' + GuidText + '}');
        Row.Insert();
    end;

    [TryFunction]
    procedure TryDate(Text: Text; var FilterText: Text; var Cnt: Integer)
    var
        Row: Record "LT P143 Row";
    begin
        Row.SetFilter(D, Text);
        FilterText := Row.GetFilter(D);
        Cnt := Row.Count();
    end;

    [TryFunction]
    procedure TryGuid(Text: Text; var FilterText: Text; var Cnt: Integer)
    var
        Row: Record "LT P143 Row";
    begin
        Row.SetFilter(G, Text);
        FilterText := Row.GetFilter(G);
        Cnt := Row.Count();
    end;

    procedure ProbeDate(var Observer: Codeunit "Probe Observer"; Name: Text; Text: Text)
    var
        FilterText: Text;
        Cnt: Integer;
    begin
        if TryDate(Text, FilterText, Cnt) then begin
            Observer.Observe(Name + '_filter', FilterText);
            Observer.Observe(Name + '_count', Format(Cnt));
        end else
            Observer.ObserveError(Name + '_err');
    end;

    procedure ProbeGuid(var Observer: Codeunit "Probe Observer"; Name: Text; Text: Text)
    var
        FilterText: Text;
        Cnt: Integer;
    begin
        if TryGuid(Text, FilterText, Cnt) then begin
            Observer.Observe(Name + '_filter', FilterText);
            Observer.Observe(Name + '_count', Format(Cnt));
        end else
            Observer.ObserveError(Name + '_err');
    end;

    // How many of the two run-date rows (7 = Today, 8 = WorkDate) fall inside From..To. The
    // expectations add this to the count of the fixed rows, so they hold on any run date.
    procedure InRows(FromDate: Date; ToDate: Date): Integer
    var
        Result: Integer;
    begin
        if (Today() >= FromDate) and (Today() <= ToDate) then
            Result += 1;
        if (WorkDate() >= FromDate) and (WorkDate() <= ToDate) then
            Result += 1;
        exit(Result);
    end;

    // count of rows whose D equals Value (the relation target of the date formulas)
    procedure CountOn(Value: Date): Integer
    var
        Row: Record "LT P143 Row";
    begin
        Row.SetRange(D, Value);
        exit(Row.Count());
    end;

    // relations for a date formula: count equals count on Expected, filter text is the formula, filter text is the formatted Expected
    procedure ProbeFormula(var Observer: Codeunit "Probe Observer"; Name: Text; Text: Text; Expected: Date)
    var
        FilterText: Text;
        Cnt: Integer;
    begin
        if TryDate(Text, FilterText, Cnt) then begin
            Observer.Observe(Name + '_count_eq_on_expected', Format(Cnt = CountOn(Expected)));
            Observer.Observe(Name + '_filter_is_text', Format(FilterText = Text));
            Observer.Observe(Name + '_filter_is_expected_date', Format(FilterText = Format(Expected)));
        end else
            Observer.ObserveError(Name + '_err');
    end;
}
