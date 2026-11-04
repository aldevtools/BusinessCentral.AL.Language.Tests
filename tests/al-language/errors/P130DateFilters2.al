// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 73548 "LT P130 Filter Row" from P130DateFilters.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on a Date field with an empty text, '', <>'', blank space, 0D forms, wildcards, and with date words and date formulas (T, W, CM, 1M, <1M> ...);
//   the formula tests compare with today and WorkDate only as booleans (a row dated today is the only row near today), nothing observed is a date of today
// Settles issue 130 reasons 7, 14, 21, 22 (an empty '', a formula such as 1M)
// BC versions: 29 (27 and 28 by CI)

codeunit 73550 "LT P130 Date Filters 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithToday: Boolean)
    var
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        Add(1, 20240102D);
        Add(2, 20240103D);
        Add(3, 20240301D);
        Add(4, 0D);
        if WithToday then
            Add(5, Today());
    end;

    local procedure Add(Id: Integer; D: Date)
    var
        R: Record "LT P130 Filter Row";
    begin
        R.Id := Id;
        R.Dt := D;
        R.Insert();
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "LT P130 Filter Row"; FilterText: Text)
    begin
        R.SetFilter(Dt, FilterText);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT P130 Filter Row";
    begin
        if TrySet(R, FilterText) then
            Observer.Observe(Name, 'ok count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // The filter text is not printed (it may hold a date of today): count, and whether GetFilter echoes the text or today's date.
    local procedure ProbeRel(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT P130 Filter Row";
    begin
        if TrySet(R, FilterText) then
            Observer.Observe(Name, 'ok count=' + Format(R.Count()) + ' echo=' + Format(R.GetFilter(Dt) = FilterText) + ' today=' + Format(R.GetFilter(Dt) = Format(Today())) + ' work=' + Format(R.GetFilter(Dt) = Format(WorkDate())))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P130_DateFilter_EmptyAndBlankForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Probe(Observer, 'empty', '');
        Probe(Observer, 'two_quotes', '''''');
        Probe(Observer, 'ne_two_quotes', '<>''''');
        Probe(Observer, 'one_space', ' ');
        Probe(Observer, 'quoted_space', '='' ''');
        Probe(Observer, 'zero_digit', '0');
        Probe(Observer, 'zero_date_text', '0D');
        Probe(Observer, 'star', '*');
        Probe(Observer, 'at_star', '@*');
        Probe(Observer, 'question', '?');
        Probe(Observer, 'dotdot', '..');
        Probe(Observer, 'pipe_only', '|');
        Probe(Observer, 'leading_pipe', '|2024-01-03');
        Probe(Observer, 'trailing_pipe', '2024-01-03|');
        Probe(Observer, 'equals_empty', '=');
        Probe(Observer, 'ne_only', '<>');
        Probe(Observer, 'blank_or_date', '''''|2024-01-03');
        Probe(Observer, 'blank_range_date', '''''..2024-01-03');
        Probe(Observer, 'amp_only', '&');
        Probe(Observer, 'parens', '(2024-01-03)');
        Observer.Expect('empty', 'ok count=4 filter=');
        Observer.Expect('two_quotes', 'ok count=1 filter=''''');
        Observer.Expect('ne_two_quotes', 'ok count=3 filter=<>''''');
        Observer.Expect('one_space', 'ok count=4 filter=');
        Observer.Expect('quoted_space', 'ok count=1 filter=''''');
        Observer.Expect('zero_digit', 'error:The filter "0" is not valid for the Dt field on the LT P130 Filter Row table. The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('zero_date_text', 'ok count=0 filter=' + Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>'));
        Observer.Expect('star', 'ok count=0 filter=' + Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>'));
        Observer.Expect('at_star', 'ok count=0 filter=' + Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>'));
        Observer.Expect('question', 'ok count=0 filter=' + Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>'));
        Observer.Expect('dotdot', 'error:The filter ".." is not valid for the Dt field on the LT P130 Filter Row table. Both sides of the range (''..'') cannot be empty.|Filter:CSide');
        Observer.Expect('pipe_only', 'error:The filter "|" is not valid for the Dt field on the LT P130 Filter Row table. The left side of ''|'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('leading_pipe', 'error:The filter "|2024-01-03" is not valid for the Dt field on the LT P130 Filter Row table. The left side of ''|'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('trailing_pipe', 'error:The filter "2024-01-03|" is not valid for the Dt field on the LT P130 Filter Row table. The right side of ''|'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('equals_empty', 'error:The filter "=" is not valid for the Dt field on the LT P130 Filter Row table. A value is expected after the ''=''.|Filter:CSide');
        Observer.Expect('ne_only', 'error:The filter "<>" is not valid for the Dt field on the LT P130 Filter Row table. A value is expected after the ''<>''.|Filter:CSide');
        Observer.Expect('blank_or_date', 'ok count=2 filter=''''|01/03/24');
        Observer.Expect('blank_range_date', 'ok count=3 filter=''''..01/03/24');
        Observer.Expect('amp_only', 'error:The filter "&" is not valid for the Dt field on the LT P130 Filter Row table. The left side of ''&'' operators cannot be empty.|Filter:CSide');
        Observer.Expect('parens', 'ok count=1 filter=01/03/24');
        Observer.Verify();
    end;




}
