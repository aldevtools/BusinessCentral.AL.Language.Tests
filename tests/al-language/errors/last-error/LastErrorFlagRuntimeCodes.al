// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Universal (table 60000)
// Probe: observe form, measured by the corpus CI matrix (BC 27.5, 28.5, 29.0).
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
