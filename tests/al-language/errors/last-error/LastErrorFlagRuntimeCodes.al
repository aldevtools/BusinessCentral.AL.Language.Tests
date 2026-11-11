// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Universal (table 60000)
// Probe: measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43072734044); the values are the same on all three.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent), GetLastErrorText(false) and GetLastErrorCode after runtime errors of
//   codes the corpus did not pin for the flag: DB:NothingInsideFilter on an empty table, on a temporary record and with Find('-') /
//   Find('+'); ArgumentOutOfRange (List.Get, Text.Substring, Text.PadLeft); IndexOutOfBounds (an array index, JsonArray.RemoveAt);
//   KeyNotFound (Dictionary.Get); a duplicate Dictionary.Add; TypeConversion:Format (a Variant holding a text into an Integer);
//   OutsidePermittedRange (DMY2Date); InvalidGuidFormat (Evaluate into a Guid); Evaluate into an Integer; a List changed in its
//   own foreach. The first statement of each test is the reporter's repro of aldevtools/BusinessCentral.AL.Runner#7759.
// BC versions: 27.5, 28.5, 29.0

codeunit 77100 "ERR LastErr Codes Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryFind(var Row: Record "ALT Universal"; Which: Text)
    begin
        case Which of
            'first':
                Row.FindFirst();
            'last':
                Row.FindLast();
            'set':
                Row.FindSet();
            'minus':
                Row.Find('-');
            'plus':
                Row.Find('+');
        end;
    end;

    [Test]
    procedure NothingInsideFilter_EmptyTable_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
    begin
        Row.DeleteAll();
        Row.SetRange("Entry No.", 42);
        Observer.Observe('first', Format(TryFind(Row, 'first')));
        Forms('first', Observer);
        Observer.Observe('last', Format(TryFind(Row, 'last')));
        Forms('last', Observer);
        Observer.Observe('set', Format(TryFind(Row, 'set')));
        Forms('set', Observer);
        Observer.Observe('minus', Format(TryFind(Row, 'minus')));
        Forms('minus', Observer);
        Observer.Observe('plus', Format(TryFind(Row, 'plus')));
        Forms('plus', Observer);
        Observer.Expect('first', 'No');
        Observer.Expect('first_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('first_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 42');
        Observer.Expect('first_code', 'DB:NothingInsideFilter');
        Observer.Expect('last', 'No');
        Observer.Expect('last_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('last_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 42');
        Observer.Expect('last_code', 'DB:NothingInsideFilter');
        Observer.Expect('set', 'No');
        Observer.Expect('set_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('set_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 42');
        Observer.Expect('set_code', 'DB:NothingInsideFilter');
        Observer.Expect('minus', 'No');
        Observer.Expect('minus_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('minus_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 42');
        Observer.Expect('minus_code', 'DB:NothingInsideFilter');
        Observer.Expect('plus', 'No');
        Observer.Expect('plus_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('plus_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 42');
        Observer.Expect('plus_code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure NothingInsideFilter_FindMinusPlus_TableWithRows_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row."Text Field" := 'customer text';
        Row.Insert();
        Row.SetRange("Entry No.", 99);
        Observer.Observe('minus', Format(TryFind(Row, 'minus')));
        Forms('minus', Observer);
        Observer.Observe('plus', Format(TryFind(Row, 'plus')));
        Forms('plus', Observer);
        Row.Reset();
        Row.SetFilter("Text Field", 'secret*');
        Observer.Observe('textfilter', Format(TryFind(Row, 'first')));
        Forms('textfilter', Observer);
        Observer.Expect('minus', 'No');
        Observer.Expect('minus_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('minus_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 99');
        Observer.Expect('minus_code', 'DB:NothingInsideFilter');
        Observer.Expect('plus', 'No');
        Observer.Expect('plus_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('plus_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 99');
        Observer.Expect('plus_code', 'DB:NothingInsideFilter');
        Observer.Expect('textfilter', 'No');
        Observer.Expect('textfilter_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('textfilter_false', 'There is no ALT Universal within the filter.\\Filters: Text Field: secret*');
        Observer.Expect('textfilter_code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure NothingInsideFilter_TemporaryRecord_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal" temporary;
    begin
        Row."Entry No." := 1;
        Row.Insert();
        Row.SetRange("Entry No.", 99);
        Observer.Observe('withrows', Format(TryFind(Row, 'first')));
        Forms('withrows', Observer);
        Row.Reset();
        Row.DeleteAll();
        Row.SetRange("Entry No.", 99);
        Observer.Observe('emptyfiltered', Format(TryFind(Row, 'first')));
        Forms('emptyfiltered', Observer);
        Row.Reset();
        Observer.Observe('empty', Format(TryFind(Row, 'first')));
        Forms('empty', Observer);
        Observer.Expect('withrows', 'No');
        Observer.Expect('withrows_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('withrows_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 99');
        Observer.Expect('withrows_code', 'DB:NothingInsideFilter');
        Observer.Expect('emptyfiltered', 'No');
        Observer.Expect('emptyfiltered_true', 'There is no ALT Universal within the filter.\\Filters: <redacted>');
        Observer.Expect('emptyfiltered_false', 'There is no ALT Universal within the filter.\\Filters: Entry No.: 99');
        Observer.Expect('emptyfiltered_code', 'DB:NothingInsideFilter');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty_true', 'The ALT Universal table is empty.');
        Observer.Expect('empty_false', 'The ALT Universal table is empty.');
        Observer.Expect('empty_code', 'DB:TableIsEmpty');
        Observer.Verify();
    end;

    [Test]
    procedure ArgumentOutOfRange_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        I: Integer;
        T: Text;
        R: Text;
    begin
        asserterror I := L.Get(3);
        Forms('listget', Observer);
        T := 'abc';
        asserterror R := T.Substring(9);
        Forms('substring', Observer);
        asserterror R := T.PadLeft(-1);
        Forms('padleft', Observer);
        Observer.Expect('listget_true', 'Message not shown because the NavBaseException constructor was used without privacy classification');
        Observer.Expect('listget_false', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('listget_code', 'ArgumentOutOfRange');
        Observer.Expect('substring_true', 'Message not shown because the NavBaseException constructor was used without privacy classification');
        Observer.Expect('substring_false', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('substring_code', 'ArgumentOutOfRange');
        Observer.Expect('padleft_true', 'Message not shown because the NavBaseException constructor was used without privacy classification');
        Observer.Expect('padleft_false', 'totalWidth (''-1'') must be a non-negative value. (Parameter ''totalWidth'')\Actual value was -1.');
        Observer.Expect('padleft_code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure IndexOutOfBounds_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3] of Integer;
        JA: JsonArray;
        I: Integer;
    begin
        I := 4;
        asserterror A[I] := 1;
        Forms('array', Observer);
        JA.Add(1);
        asserterror JA.RemoveAt(5);
        Forms('jsonremoveat', Observer);
        Observer.Expect('array_true', 'Index out of bounds.');
        Observer.Expect('array_false', 'Index out of bounds.');
        Observer.Expect('array_code', 'IndexOutOfBounds');
        Observer.Expect('jsonremoveat_true', 'Index out of bounds.');
        Observer.Expect('jsonremoveat_false', 'Index out of bounds.');
        Observer.Expect('jsonremoveat_code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure Dictionary_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        I: Integer;
    begin
        asserterror I := D.Get('missing key');
        Forms('get', Observer);
        D.Add('k', 1);
        asserterror D.Add('k', 2);
        Forms('addtwice', Observer);
        Observer.Expect('get_true', 'Message not shown because the NavBaseException constructor was used without privacy classification');
        Observer.Expect('get_false', 'The given key was not present in the dictionary.');
        Observer.Expect('get_code', 'KeyNotFound');
        Observer.Expect('addtwice_true', 'An item with the same key has already been added.');
        Observer.Expect('addtwice_false', 'An item with the same key has already been added.');
        Observer.Expect('addtwice_code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Conversions_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        I: Integer;
        D: Date;
        G: Guid;
    begin
        V := 'abc';
        asserterror I := V;
        Forms('variantint', Observer);
        asserterror D := DMY2Date(40, 13, 2020);
        Forms('dmy2date', Observer);
        asserterror Evaluate(G, 'not a guid');
        Forms('evalguid', Observer);
        asserterror Evaluate(I, 'secret 12');
        Forms('evalint', Observer);
        Observer.Expect('variantint_true', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('variantint_false', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('variantint_code', 'TypeConversion:Format');
        Observer.Expect('dmy2date_true', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: <redacted>. The permitted range is: from 1 to 12.');
        Observer.Expect('dmy2date_false', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 13. The permitted range is: from 1 to 12.');
        Observer.Expect('dmy2date_code', 'OutsidePermittedRange');
        Observer.Expect('evalguid_true', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('evalguid_false', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('evalguid_code', 'InvalidGuidFormat');
        Observer.Expect('evalint_true', 'The value "<redacted>" can''t be evaluated into type Integer.');
        Observer.Expect('evalint_false', 'The value "secret 12" can''t be evaluated into type Integer.');
        Observer.Expect('evalint_code', 'Evaluate');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryChangeListInForeach(var L: List of [Integer])
    var
        X: Integer;
    begin
        foreach X in L do
            L.Add(X + 10);
    end;

    [Test]
    procedure ListChangedInForeach_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
    begin
        L.Add(1);
        L.Add(2);
        Observer.Observe('ok', Format(TryChangeListInForeach(L)));
        Forms('foreach', Observer);
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('ok', 'No');
        Observer.Expect('foreach_true', 'Collection was modified; enumeration operation may not execute.');
        Observer.Expect('foreach_false', 'Collection was modified; enumeration operation may not execute.');
        Observer.Expect('foreach_code', 'AL:InvalidOperation');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;
}
