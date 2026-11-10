// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 66300 and test codeunit 66301
// local object: the rows hold texts with filter characters, and the test asserts which of them a filter keeps.
// Probe (al-runner issue 7460: `SetFilter(F, '<>%1', Value)` where Value holds `*` and `?`): observation form, the values are read from the
//   corpus CI matrix.
// Area: a %1 argument that holds filter characters, on a Text[50] and a Code[50] field, through Record.SetFilter and FieldRef.SetFilter.
//   Argument values: A*B, A?B, A*, *B, ?, A*B? and the reporter's 8+LI^IBY*]#8?~A^;ZCB (wildcard characters), A&B, A|B, A..B, (A), <A, >A,
//   =A, A'B (operator characters). Filter forms: <>%1, %1, =%1, >%1, <=%1, %1|%2, <>%1&<>%2, %1..%2, and the same text written in the filter
//   itself. The rows are chosen so that a value read as a wildcard pattern keeps other rows than the same value read as a plain text:
//   AXB and AXXB match A*B, AXB matches A?B, and row 8 matches the reporter's value as a pattern.
//   Each cell records GetFilter and the ids of the rows the filter keeps, or the error text and code.
// Existing pins: record/filters/WildcardGetFilter.al Placeholders (`<>%1` with `*` alone, `%1` with A*), PlaceholderAtSignValue.al (a value
//   that starts with @), recordref-fieldref/fieldref/FieldRefFilterMatrix.al pnestar.* (`<>%1` with a*b?, but no row tells a pattern from a text).
// BC versions: 27, 28, 29 by CI

table 66300 "REC PhWild Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[50]) { }
        field(3; Cd; Code[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 66301 "REC PhWild Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        R: Record "REC PhWild Row";
    begin
        R.DeleteAll();
        Add(1, 'A*B');
        Add(2, 'AXB');
        Add(3, 'AB');
        Add(4, 'A?B');
        Add(5, 'AXXB');
        Add(6, '');
        Add(7, '8+LI^IBY*]#8?~A^;ZCB');
        Add(8, '8+LI^IBYQQ]#8X~A^;ZCB');
        Add(9, '*');
        Add(10, '?');
        Add(11, 'A&B');
        Add(12, 'A|B');
        Add(13, 'A..B');
        Add(14, '(A)');
        Add(15, '<A');
        Add(16, 'A''B');
        Add(17, 'A');
        Add(18, 'B');
        Add(19, '>A');
        Add(20, '=A');
    end;

    local procedure Add(Id: Integer; Value: Text[50])
    var
        R: Record "REC PhWild Row";
    begin
        R.Init();
        R.Id := Id;
        R.Txt := Value;
        R.Cd := CopyStr(Value, 1, 50);
        R.Insert();
    end;

    local procedure Ids(var R: Record "REC PhWild Row") Result: Text
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

    [TryFunction]
    local procedure TrySet(var R: Record "REC PhWild Row"; OnCode: Boolean; FilterText: Text; Args: Integer; V1: Text; V2: Text)
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
    local procedure TrySetRef(var Fld: FieldRef; FilterText: Text; Args: Integer; V1: Text; V2: Text)
    begin
        case Args of
            0:
                Fld.SetFilter(FilterText);
            1:
                Fld.SetFilter(FilterText, V1);
            2:
                Fld.SetFilter(FilterText, V1, V2);
        end;
    end;

    [TryFunction]
    local procedure TryRange(var R: Record "REC PhWild Row"; OnCode: Boolean; V1: Text)
    begin
        if OnCode then
            R.SetRange(Cd, V1)
        else
            R.SetRange(Txt, V1);
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; OnCode: Boolean; FilterText: Text; Args: Integer; V1: Text; V2: Text)
    var
        R: Record "REC PhWild Row";
    begin
        if not TrySet(R, OnCode, FilterText, Args, V1, V2) then begin
            Observer.Observe(Name, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
            exit;
        end;
        if OnCode then
            Observer.Observe(Name, R.GetFilter(Cd) + ' | ' + Ids(R))
        else
            Observer.Observe(Name, R.GetFilter(Txt) + ' | ' + Ids(R));
    end;

    local procedure RefCell(var Observer: Codeunit "Probe Observer"; Name: Text; OnCode: Boolean; FilterText: Text; Args: Integer; V1: Text; V2: Text)
    var
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        Ref.Open(Database::"REC PhWild Row");
        if OnCode then
            Fld := Ref.Field(3)
        else
            Fld := Ref.Field(2);
        if not TrySetRef(Fld, FilterText, Args, V1, V2) then begin
            Observer.Observe(Name, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
        end else
            Observer.Observe(Name, Fld.GetFilter() + ' | ' + RefIds(Ref));
        Ref.Close();
    end;

    local procedure RangeCell(var Observer: Codeunit "Probe Observer"; Name: Text; OnCode: Boolean; V1: Text)
    var
        R: Record "REC PhWild Row";
    begin
        if not TryRange(R, OnCode, V1) then begin
            Observer.Observe(Name, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
            exit;
        end;
        if OnCode then
            Observer.Observe(Name, R.GetFilter(Cd) + ' | ' + Ids(R))
        else
            Observer.Observe(Name, R.GetFilter(Txt) + ' | ' + Ids(R));
    end;

    local procedure WildValues(var Observer: Codeunit "Probe Observer"; OnCode: Boolean; FilterText: Text)
    begin
        Cell(Observer, 'A*B', OnCode, FilterText, 1, 'A*B', '');
        Cell(Observer, 'A?B', OnCode, FilterText, 1, 'A?B', '');
        Cell(Observer, 'A*', OnCode, FilterText, 1, 'A*', '');
        Cell(Observer, '*B', OnCode, FilterText, 1, '*B', '');
        Cell(Observer, '?', OnCode, FilterText, 1, '?', '');
        Cell(Observer, 'A*B?', OnCode, FilterText, 1, 'A*B?', '');
        Cell(Observer, 'reported', OnCode, FilterText, 1, '8+LI^IBY*]#8?~A^;ZCB', '');
    end;

    local procedure OperatorValues(var Observer: Codeunit "Probe Observer"; OnCode: Boolean; FilterText: Text)
    begin
        Cell(Observer, 'A&B', OnCode, FilterText, 1, 'A&B', '');
        Cell(Observer, 'A|B', OnCode, FilterText, 1, 'A|B', '');
        Cell(Observer, 'A..B', OnCode, FilterText, 1, 'A..B', '');
        Cell(Observer, '(A)', OnCode, FilterText, 1, '(A)', '');
        Cell(Observer, '<A', OnCode, FilterText, 1, '<A', '');
        Cell(Observer, '>A', OnCode, FilterText, 1, '>A', '');
        Cell(Observer, '=A', OnCode, FilterText, 1, '=A', '');
        Cell(Observer, 'A''B', OnCode, FilterText, 1, 'A''B', '');
    end;

    local procedure LiteralValues(var Observer: Codeunit "Probe Observer"; OnCode: Boolean; Prefix: Text)
    begin
        Cell(Observer, 'A*B', OnCode, Prefix + 'A*B', 0, '', '');
        Cell(Observer, 'A?B', OnCode, Prefix + 'A?B', 0, '', '');
        Cell(Observer, 'A*', OnCode, Prefix + 'A*', 0, '', '');
        Cell(Observer, '*B', OnCode, Prefix + '*B', 0, '', '');
        Cell(Observer, '?', OnCode, Prefix + '?', 0, '', '');
        Cell(Observer, 'A*B?', OnCode, Prefix + 'A*B?', 0, '', '');
        Cell(Observer, 'reported', OnCode, Prefix + '8+LI^IBY*]#8?~A^;ZCB', 0, '', '');
        Cell(Observer, 'quoted A*B', OnCode, Prefix + '''A*B''', 0, '', '');
        Cell(Observer, 'quoted A?B', OnCode, Prefix + '''A?B''', 0, '', '');
    end;

    [Test]
    procedure Text_NotEqualPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, false, '<>%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_PlainPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, false, '%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_EqualSignPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, false, '=%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_GreaterPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, false, '>%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_LessOrEqualPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, false, '<=%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_TwoPlaceholders_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Cell(Observer, 'or A*B AB', false, '%1|%2', 2, 'A*B', 'AB');
        Cell(Observer, 'or AB A?B', false, '%1|%2', 2, 'AB', 'A?B');
        Cell(Observer, 'ne A*B and ne AB', false, '<>%1&<>%2', 2, 'A*B', 'AB');
        Cell(Observer, 'ne AB and ne A?B', false, '<>%1&<>%2', 2, 'AB', 'A?B');
        Cell(Observer, 'ne A*B and ne A?B', false, '<>%1&<>%2', 2, 'A*B', 'A?B');
        Cell(Observer, 'range A*B AXB', false, '%1..%2', 2, 'A*B', 'AXB');
        Cell(Observer, 'range A A?B', false, '%1..%2', 2, 'A', 'A?B');
        Cell(Observer, 'A*B and ne AXB', false, '%1&<>%2', 2, 'A*B', 'AXB');
        Cell(Observer, 'ne reported and ne A', false, '<>%1&<>%2', 2, '8+LI^IBY*]#8?~A^;ZCB', 'A');
        Observer.Finish();
    end;

    [Test]
    procedure Text_NotEqualPlaceholder_OperatorValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OperatorValues(Observer, false, '<>%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_PlainPlaceholder_OperatorValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OperatorValues(Observer, false, '%1');
        Observer.Finish();
    end;

    [Test]
    procedure Text_NotEqualWrittenInFilter_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        LiteralValues(Observer, false, '<>');
        Observer.Finish();
    end;

    [Test]
    procedure Text_WrittenInFilter_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        LiteralValues(Observer, false, '');
        Observer.Finish();
    end;

    [Test]
    procedure Text_SetRange_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RangeCell(Observer, 'A*B', false, 'A*B');
        RangeCell(Observer, 'A?B', false, 'A?B');
        RangeCell(Observer, 'A*', false, 'A*');
        RangeCell(Observer, '?', false, '?');
        RangeCell(Observer, 'reported', false, '8+LI^IBY*]#8?~A^;ZCB');
        RangeCell(Observer, 'A|B', false, 'A|B');
        RangeCell(Observer, 'A..B', false, 'A..B');
        Observer.Finish();
    end;

    [Test]
    procedure Code_NotEqualPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, true, '<>%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_PlainPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, true, '%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_EqualSignPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, true, '=%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_GreaterPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, true, '>%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_LessOrEqualPlaceholder_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        WildValues(Observer, true, '<=%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_TwoPlaceholders_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Cell(Observer, 'or A*B AB', true, '%1|%2', 2, 'A*B', 'AB');
        Cell(Observer, 'or AB A?B', true, '%1|%2', 2, 'AB', 'A?B');
        Cell(Observer, 'ne A*B and ne AB', true, '<>%1&<>%2', 2, 'A*B', 'AB');
        Cell(Observer, 'ne AB and ne A?B', true, '<>%1&<>%2', 2, 'AB', 'A?B');
        Cell(Observer, 'ne A*B and ne A?B', true, '<>%1&<>%2', 2, 'A*B', 'A?B');
        Cell(Observer, 'range A*B AXB', true, '%1..%2', 2, 'A*B', 'AXB');
        Cell(Observer, 'range A A?B', true, '%1..%2', 2, 'A', 'A?B');
        Cell(Observer, 'A*B and ne AXB', true, '%1&<>%2', 2, 'A*B', 'AXB');
        Cell(Observer, 'ne reported and ne A', true, '<>%1&<>%2', 2, '8+LI^IBY*]#8?~A^;ZCB', 'A');
        Observer.Finish();
    end;

    [Test]
    procedure Code_NotEqualPlaceholder_OperatorValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OperatorValues(Observer, true, '<>%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_PlainPlaceholder_OperatorValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        OperatorValues(Observer, true, '%1');
        Observer.Finish();
    end;

    [Test]
    procedure Code_NotEqualWrittenInFilter_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        LiteralValues(Observer, true, '<>');
        Observer.Finish();
    end;

    [Test]
    procedure Code_WrittenInFilter_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        LiteralValues(Observer, true, '');
        Observer.Finish();
    end;

    [Test]
    procedure Code_SetRange_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RangeCell(Observer, 'A*B', true, 'A*B');
        RangeCell(Observer, 'A?B', true, 'A?B');
        RangeCell(Observer, 'A*', true, 'A*');
        RangeCell(Observer, '?', true, '?');
        RangeCell(Observer, 'reported', true, '8+LI^IBY*]#8?~A^;ZCB');
        RangeCell(Observer, 'A|B', true, 'A|B');
        RangeCell(Observer, 'A..B', true, 'A..B');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_Text_Placeholders_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RefCell(Observer, 'ne A*B', false, '<>%1', 1, 'A*B', '');
        RefCell(Observer, 'ne A?B', false, '<>%1', 1, 'A?B', '');
        RefCell(Observer, 'ne ?', false, '<>%1', 1, '?', '');
        RefCell(Observer, 'ne reported', false, '<>%1', 1, '8+LI^IBY*]#8?~A^;ZCB', '');
        RefCell(Observer, 'eq A*B', false, '%1', 1, 'A*B', '');
        RefCell(Observer, 'eq A?B', false, '%1', 1, 'A?B', '');
        RefCell(Observer, 'eq reported', false, '%1', 1, '8+LI^IBY*]#8?~A^;ZCB', '');
        RefCell(Observer, 'eqsign A*B', false, '=%1', 1, 'A*B', '');
        RefCell(Observer, 'ne A*B and ne AB', false, '<>%1&<>%2', 2, 'A*B', 'AB');
        RefCell(Observer, 'written ne A*B', false, '<>A*B', 0, '', '');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_Code_Placeholders_WildcardValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RefCell(Observer, 'ne A*B', true, '<>%1', 1, 'A*B', '');
        RefCell(Observer, 'ne A?B', true, '<>%1', 1, 'A?B', '');
        RefCell(Observer, 'ne ?', true, '<>%1', 1, '?', '');
        RefCell(Observer, 'ne reported', true, '<>%1', 1, '8+LI^IBY*]#8?~A^;ZCB', '');
        RefCell(Observer, 'eq A*B', true, '%1', 1, 'A*B', '');
        RefCell(Observer, 'eq A?B', true, '%1', 1, 'A?B', '');
        RefCell(Observer, 'eq reported', true, '%1', 1, '8+LI^IBY*]#8?~A^;ZCB', '');
        RefCell(Observer, 'eqsign A*B', true, '=%1', 1, 'A*B', '');
        RefCell(Observer, 'ne A*B and ne AB', true, '<>%1&<>%2', 2, 'A*B', 'AB');
        RefCell(Observer, 'written ne A*B', true, '<>A*B', 0, '', '');
        Observer.Finish();
    end;
}
