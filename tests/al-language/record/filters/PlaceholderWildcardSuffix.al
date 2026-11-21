// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74072 and test codeunit 74073
// local object: the rows hold codes with a dash, a star and a question mark, and the test asserts which of them a filter keeps.
// Probe (al-runner issue 8642: `SetFilter(Code, '<>%1', 'XYZ-*')` after `SetRange(Enabled, true)`, then IsEmpty and ModifyAll):
//   is the star in a %1 value a wildcard or a plain character?
// Area: a %1 argument that ends in a star after a dash, on a Code[20] and a Text[30] field, through Record.SetFilter and
//   FieldRef.SetFilter. Argument values: XYZ-* (the reporter's), xyz-*, XYZ-?, XYZ-**, XYZ*, *XYZ*, *-1, *, a blank before or after
//   the star, a value longer than the Code field. Filter forms: <>%1, %1, =%1, <>%1&<>%2, and the same text written in the filter.
//   Each cell records GetFilter and the ids of the rows the filter keeps, or the error text and code. The reporter's sequence also
//   records IsEmpty, Count and the rows ModifyAll changed.
// Existing pins: record/filters/PlaceholderWildcardValue.al (A*B, A*, *B with <>%1 on Text[50] and Code[50]), WildcardGetFilter.al.
// Facts: see the Expect lines; the values were observed on BC and converted, never typed by hand.
// BC versions: 27.5, 28.5, 29.0

table 74072 "REC PhWildSfx Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[20]) { }
        field(3; Txt; Text[30]) { }
        field(4; Enabled; Boolean) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74073 "REC PhWildSfx Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        R: Record "REC PhWildSfx Row";
    begin
        R.DeleteAll();
        Add(1, 'XYZ-1', true);
        Add(2, 'XYZ-2', true);
        Add(3, 'XYZ-', true);
        Add(4, 'XYZ', true);
        Add(5, 'XYZ-*', true);
        Add(6, 'ABC-1', true);
        Add(7, 'ABC-2', false);
        Add(8, 'XYZ-3', false);
        Add(9, 'AXYZ-1', true);
        Add(10, 'XYZ-10', true);
        Add(11, 'xyz-1', true);
        Add(12, 'XYZ-?', true);
        Add(13, '', true);
        Add(14, 'XYZ_1', true);
        Add(15, 'XYZ 1', true);
    end;

    local procedure Add(Id: Integer; Value: Text[30]; IsEnabled: Boolean)
    var
        R: Record "REC PhWildSfx Row";
    begin
        R.Init();
        R.Id := Id;
        R.Cd := CopyStr(Value, 1, 20);
        R.Txt := Value;
        R.Enabled := IsEnabled;
        R.Insert();
    end;

    local procedure Ids(var R: Record "REC PhWildSfx Row") Result: Text
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ' ';
            until R.Next() = 0;
    end;

    local procedure RefIds(var Ref: RecordRef) Result: Text
    begin
        if Ref.FindSet() then
            repeat
                Result += Format(Ref.Field(1).Value()) + ' ';
            until Ref.Next() = 0;
    end;

    local procedure EnabledIds() Result: Text
    var
        R: Record "REC PhWildSfx Row";
    begin
        R.SetRange(Enabled, true);
        exit(Ids(R));
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "REC PhWildSfx Row"; OnCode: Boolean; FilterText: Text; Args: Integer; V1: Text; V2: Text)
    begin
        case true of
            OnCode and (Args = 0):
                R.SetFilter(Cd, FilterText);
            OnCode and (Args = 1):
                R.SetFilter(Cd, FilterText, V1);
            OnCode and (Args = 2):
                R.SetFilter(Cd, FilterText, V1, V2);
            Args = 0:
                R.SetFilter(Txt, FilterText);
            Args = 1:
                R.SetFilter(Txt, FilterText, V1);
            Args = 2:
                R.SetFilter(Txt, FilterText, V1, V2);
        end;
    end;

    [TryFunction]
    local procedure TryRead(var R: Record "REC PhWildSfx Row"; var Result: Text)
    begin
        Result := Ids(R);
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; OnCode: Boolean; FilterText: Text; Args: Integer; V1: Text; V2: Text)
    var
        R: Record "REC PhWildSfx Row";
        Kept: Text;
    begin
        ClearLastError();
        if not TrySet(R, OnCode, FilterText, Args, V1, V2) then begin
            Observer.ObserveError(Name + ' set');
            exit;
        end;
        if OnCode then
            Observer.Observe(Name + ' getfilter', R.GetFilter(Cd))
        else
            Observer.Observe(Name + ' getfilter', R.GetFilter(Txt));
        if TryRead(R, Kept) then
            Observer.Observe(Name + ' rows', Kept)
        else
            Observer.ObserveError(Name + ' read');
    end;

    local procedure Values(var Observer: Codeunit "Probe Observer"; OnCode: Boolean)
    begin
        Cell(Observer, 'ne XYZ-*', OnCode, '<>%1', 1, 'XYZ-*', '');
        Cell(Observer, 'ne xyz-*', OnCode, '<>%1', 1, 'xyz-*', '');
        Cell(Observer, 'ne XYZ-?', OnCode, '<>%1', 1, 'XYZ-?', '');
        Cell(Observer, 'ne XYZ-**', OnCode, '<>%1', 1, 'XYZ-**', '');
        Cell(Observer, 'ne XYZ*', OnCode, '<>%1', 1, 'XYZ*', '');
        Cell(Observer, 'ne *XYZ*', OnCode, '<>%1', 1, '*XYZ*', '');
        Cell(Observer, 'ne *-1', OnCode, '<>%1', 1, '*-1', '');
        Cell(Observer, 'ne star', OnCode, '<>%1', 1, '*', '');
        Cell(Observer, 'ne XYZ-* blank after', OnCode, '<>%1', 1, 'XYZ-* ', '');
        Cell(Observer, 'ne XYZ-* blank before', OnCode, '<>%1', 1, ' XYZ-*', '');
        Cell(Observer, 'ne XYZ- *', OnCode, '<>%1', 1, 'XYZ- *', '');
    end;

    local procedure Forms(var Observer: Codeunit "Probe Observer"; OnCode: Boolean)
    begin
        Cell(Observer, 'eq XYZ-*', OnCode, '%1', 1, 'XYZ-*', '');
        Cell(Observer, 'eqsign XYZ-*', OnCode, '=%1', 1, 'XYZ-*', '');
        Cell(Observer, 'ne XYZ-* and ne ABC-*', OnCode, '<>%1&<>%2', 2, 'XYZ-*', 'ABC-*');
        Cell(Observer, 'ne XYZ-* or ne ABC-*', OnCode, '<>%1|<>%2', 2, 'XYZ-*', 'ABC-*');
        Cell(Observer, 'written ne XYZ-*', OnCode, '<>XYZ-*', 0, '', '');
        Cell(Observer, 'written ne quoted XYZ-*', OnCode, '<>''XYZ-*''', 0, '', '');
        Cell(Observer, 'ne long 25', OnCode, '<>%1', 1, 'XYZ-ABCDEFGHIJKLMNOPQRST*', '');
        Cell(Observer, 'ne long 21', OnCode, '<>%1', 1, 'XYZ-ABCDEFGHIJKLMNOP*', '');
        Cell(Observer, 'ne long 35', OnCode, '<>%1', 1, 'XYZ-ABCDEFGHIJKLMNOPQRSTUVWXYZ1234*', '');
    end;

    [Test]
    procedure Code_NotEqualPlaceholder_StarSuffixValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Values(Observer, true);
        Observer.Finish();
    end;

    [Test]
    procedure Text_NotEqualPlaceholder_StarSuffixValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Values(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure Code_OtherForms_StarSuffixValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Forms(Observer, true);
        Observer.Finish();
    end;

    [Test]
    procedure Text_OtherForms_StarSuffixValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Forms(Observer, false);
        Observer.Finish();
    end;

    [Test]
    procedure Code_ReporterSequence_IsEmptyModifyAll()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC PhWildSfx Row";
    begin
        Initialize();
        R.SetRange(Enabled, true);
        R.SetFilter(Cd, '<>%1', 'XYZ-*');
        Observer.Observe('getfilters', R.GetFilters());
        Observer.Observe('isempty', Format(R.IsEmpty()));
        Observer.Observe('count', Format(R.Count()));
        if not R.IsEmpty() then
            R.ModifyAll(Enabled, false);
        Observer.Observe('enabled after', EnabledIds());
        Observer.Finish();
    end;

    [Test]
    procedure Code_ReporterSequence_NothingLeft()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC PhWildSfx Row";
    begin
        // Only rows that the pattern matches are enabled: the filter keeps none of them.
        R.DeleteAll();
        Add(1, 'XYZ-1', true);
        Add(2, 'XYZ-*', true);
        Add(3, 'ABC-1', false);
        R.SetRange(Enabled, true);
        R.SetFilter(Cd, '<>%1', 'XYZ-*');
        Observer.Observe('isempty', Format(R.IsEmpty()));
        Observer.Observe('count', Format(R.Count()));
        if not R.IsEmpty() then
            R.ModifyAll(Enabled, false);
        Observer.Observe('enabled after', EnabledIds());
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_ReporterValue_StarSuffix()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        Initialize();
        Ref.Open(Database::"REC PhWildSfx Row");
        Ref.Field(4).SetRange(true);
        Fld := Ref.Field(2);
        Fld.SetFilter('<>%1', 'XYZ-*');
        Observer.Observe('code getfilter', Fld.GetFilter());
        Observer.Observe('code rows', RefIds(Ref));
        Observer.Observe('code isempty', Format(Ref.IsEmpty()));
        Fld.SetRange();
        Fld := Ref.Field(3);
        Fld.SetFilter('<>%1', 'XYZ-*');
        Observer.Observe('text getfilter', Fld.GetFilter());
        Observer.Observe('text rows', RefIds(Ref));
        Ref.Close();
        Observer.Finish();
    end;
}
