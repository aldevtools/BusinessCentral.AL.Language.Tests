// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 66350 and 66351, test codeunit 66352
// local object: the CalcFormula definitions are what the tests measure.
// Probe (al-runner issue 7433: `count("My Doc" where("Type Code" = field("Type Filter"), "Date" = field(filter("Date Filter"))))` with a
//   Date FlowFilter set by SetFilter("Date Filter", Format(WorkDate()))): observation form, the values are read from the corpus CI matrix.
// Area: a Date FlowFilter read by a CalcFormula through field(filter(F)) and through field(F), in count, sum, exist, min and lookup
//   formulas, alone and next to a Code FlowFilter condition. Forms of the filter on the FlowFilter: not set, one date (SetRange, SetFilter
//   with %1, SetFilter with the text of the date), a closed range, open ranges, two dates, not equal, the blank date, greater than, and a
//   range together with the Code FlowFilter. Also field(filter(F)) over a normal Date field (its value) and over a normal Text field that
//   holds a date filter text. Each state records every FlowField and GetFilter of the FlowFilter, or the CalcFields error text and code.
// Existing pins: record/flowfields/FfmCountExist.al, FfmSumAverage.al, FfmMinMax.al and FfmLookup.al pin field(filter(DateF)) for a
//   FlowFilter that is not set and one that holds a closed range (SetRange with two dates).
// BC versions: 27, 28, 29 by CI

table 66350 "REC FfDate Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Type Code"; Code[10]) { }
        field(3; Day; Date) { }
        field(4; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 66351 "REC FfDate Cue"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[20]) { }
        field(2; "Date Value"; Date) { }
        field(3; "Date Text"; Text[30]) { }
        field(20; "Type Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(50; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(30; CntTypeAndFf; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("REC FfDate Doc" where("Type Code" = field("Type Filter"), Day = field(filter("Date Filter"))));
        }
        field(31; CntTypeAndF; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("REC FfDate Doc" where("Type Code" = field("Type Filter"), Day = field("Date Filter")));
        }
        field(32; CntFf; Integer) { FieldClass = FlowField; CalcFormula = count("REC FfDate Doc" where(Day = field(filter("Date Filter")))); }
        field(33; CntF; Integer) { FieldClass = FlowField; CalcFormula = count("REC FfDate Doc" where(Day = field("Date Filter"))); }
        field(34; SumFf; Decimal) { FieldClass = FlowField; CalcFormula = sum("REC FfDate Doc".Amount where(Day = field(filter("Date Filter")))); }
        field(35; ExistFf; Boolean) { FieldClass = FlowField; CalcFormula = exist("REC FfDate Doc" where(Day = field(filter("Date Filter")))); }
        field(36; MinFf; Date) { FieldClass = FlowField; CalcFormula = min("REC FfDate Doc".Day where(Day = field(filter("Date Filter")))); }
        field(37; LookupFf; Integer) { FieldClass = FlowField; CalcFormula = lookup("REC FfDate Doc".Id where(Day = field(filter("Date Filter")))); }
        field(40; CntValueFf; Integer) { FieldClass = FlowField; CalcFormula = count("REC FfDate Doc" where(Day = field(filter("Date Value")))); }
        field(41; CntValueF; Integer) { FieldClass = FlowField; CalcFormula = count("REC FfDate Doc" where(Day = field("Date Value"))); }
        field(42; CntTextFf; Integer) { FieldClass = FlowField; CalcFormula = count("REC FfDate Doc" where(Day = field(filter("Date Text")))); }
    }

    keys { key(PK; "Primary Key") { Clustered = true; } }
}

codeunit 66352 "REC FfDate Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        D: Record "REC FfDate Doc";
        C: Record "REC FfDate Cue";
    begin
        D.DeleteAll();
        C.DeleteAll();
        Add(1, 'A', 20260110D, 1);
        Add(2, 'A', 20260115D, 2);
        Add(3, 'B', 20260115D, 4);
        Add(4, 'A', 20260120D, 8);
        Add(5, 'A', 0D, 16);
        Add(6, 'B', 20260201D, 32);
        C."Primary Key" := 'CUE';
        C.Insert();
    end;

    local procedure Add(Id: Integer; TypeCode: Code[10]; Day: Date; Amount: Decimal)
    var
        D: Record "REC FfDate Doc";
    begin
        D.Id := Id;
        D."Type Code" := TypeCode;
        D.Day := Day;
        D.Amount := Amount;
        D.Insert();
    end;

    [TryFunction]
    local procedure TryCalcFlowFilterFields(var C: Record "REC FfDate Cue")
    begin
        C.CalcFields(CntTypeAndFf, CntTypeAndF, CntFf, CntF, SumFf, ExistFf, MinFf, LookupFf);
    end;

    [TryFunction]
    local procedure TryCalcValueFields(var C: Record "REC FfDate Cue")
    begin
        C.CalcFields(CntValueFf, CntValueF);
    end;

    [TryFunction]
    local procedure TryCalcTextField(var C: Record "REC FfDate Cue")
    begin
        C.CalcFields(CntTextFf);
    end;

    local procedure State(var Observer: Codeunit "Probe Observer"; Name: Text; var C: Record "REC FfDate Cue")
    begin
        if not TryCalcFlowFilterFields(C) then begin
            Observer.Observe(Name, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
            exit;
        end;
        Observer.Observe(Name, StrSubstNo('typeff=%1 typef=%2 ff=%3 f=%4 sum=%5 exist=%6 min=%7 lookup=%8', C.CntTypeAndFf, C.CntTypeAndF, C.CntFf, C.CntF,
            Format(C.SumFf, 0, 9), Format(C.ExistFf, 0, 9), Format(C.MinFf, 0, 9), C.LookupFf));
    end;

    [TryFunction]
    local procedure TrySetFilterText(var C: Record "REC FfDate Cue"; FilterText: Text)
    begin
        C.SetFilter("Date Filter", FilterText);
    end;

    local procedure Fresh(var C: Record "REC FfDate Cue")
    begin
        C.Reset();
        C.Get('CUE');
    end;

    [Test]
    procedure DateFlowFilter_NotSet_AndOneDate()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "REC FfDate Cue";
    begin
        Initialize();
        Fresh(C);
        State(Observer, 'not set', C);
        Fresh(C);
        C.SetRange("Date Filter", 20260115D);
        State(Observer, 'SetRange one date', C);
        Fresh(C);
        C.SetFilter("Date Filter", '%1', 20260115D);
        State(Observer, 'SetFilter %1 one date', C);
        Fresh(C);
        C.SetFilter("Date Filter", Format(20260115D));
        Observer.Observe('text of the date is the filter text', Format(C.GetFilter("Date Filter") = Format(20260115D)));
        State(Observer, 'SetFilter text of the date', C);
        Fresh(C);
        C.SetFilter("Date Filter", '=%1', 20260115D);
        State(Observer, 'SetFilter =%1', C);
        Fresh(C);
        C.SetRange("Date Filter", 20260116D);
        State(Observer, 'one date without rows', C);
        Observer.Finish();
    end;

    [Test]
    procedure DateFlowFilter_Ranges()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "REC FfDate Cue";
    begin
        Initialize();
        Fresh(C);
        C.SetRange("Date Filter", 20260110D, 20260115D);
        State(Observer, 'closed range', C);
        Fresh(C);
        C.SetFilter("Date Filter", '%1..', 20260115D);
        State(Observer, 'from', C);
        Fresh(C);
        C.SetFilter("Date Filter", '..%1', 20260115D);
        State(Observer, 'up to', C);
        Fresh(C);
        C.SetFilter("Date Filter", '>%1', 20260115D);
        State(Observer, 'greater', C);
        Fresh(C);
        C.SetFilter("Date Filter", '<%1', 20260115D);
        State(Observer, 'less', C);
        Fresh(C);
        C.SetFilter("Date Filter", '%1..%2', 20260120D, 20260110D);
        State(Observer, 'reversed range', C);
        Observer.Finish();
    end;

    [Test]
    procedure DateFlowFilter_ListsNotEqualAndBlank()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "REC FfDate Cue";
    begin
        Initialize();
        Fresh(C);
        C.SetFilter("Date Filter", '%1|%2', 20260110D, 20260201D);
        State(Observer, 'two dates', C);
        Fresh(C);
        C.SetFilter("Date Filter", '<>%1', 20260115D);
        State(Observer, 'not equal', C);
        Fresh(C);
        C.SetRange("Date Filter", 0D);
        Observer.Observe('GetFilter after SetRange 0D', C.GetFilter("Date Filter"));
        State(Observer, 'SetRange blank date', C);
        Fresh(C);
        C.SetFilter("Date Filter", '<>%1', 0D);
        Observer.Observe('GetFilter after <>%1 0D', C.GetFilter("Date Filter"));
        State(Observer, 'not blank date', C);
        Fresh(C);
        if TrySetFilterText(C, '''''') then begin
            Observer.Observe('GetFilter after two quotes', C.GetFilter("Date Filter"));
            State(Observer, 'two quotes', C);
        end else
            Observer.ObserveError('two quotes');
        Fresh(C);
        C.SetFilter("Date Filter", '%1..%2|%3', 20260110D, 20260115D, 20260201D);
        State(Observer, 'range or date', C);
        Observer.Finish();
    end;

    [Test]
    procedure DateFlowFilter_WithCodeFlowFilter()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "REC FfDate Cue";
    begin
        Initialize();
        Fresh(C);
        C.SetFilter("Type Filter", 'A');
        State(Observer, 'type A, date not set', C);
        C.SetFilter("Date Filter", Format(20260115D));
        State(Observer, 'type A, one date as text', C);
        C.SetRange("Date Filter", 20260110D, 20260120D);
        State(Observer, 'type A, closed range', C);
        C.SetFilter("Type Filter", 'B');
        State(Observer, 'type B, closed range', C);
        C.SetFilter("Type Filter", 'A|B');
        State(Observer, 'type A or B, closed range', C);
        C.SetFilter("Type Filter", 'Z');
        State(Observer, 'type Z, closed range', C);
        C.SetRange("Date Filter");
        State(Observer, 'type Z, date cleared', C);
        Observer.Finish();
    end;

    [Test]
    procedure FieldFilterOverNormalDateField_ReadsTheValue()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "REC FfDate Cue";
    begin
        Initialize();
        Fresh(C);
        if TryCalcValueFields(C) then
            Observer.Observe('value blank', StrSubstNo('ff=%1 f=%2', C.CntValueFf, C.CntValueF))
        else
            Observer.ObserveError('value blank');
        C."Date Value" := 20260115D;
        if TryCalcValueFields(C) then
            Observer.Observe('value 15 Jan, not saved', StrSubstNo('ff=%1 f=%2', C.CntValueFf, C.CntValueF))
        else
            Observer.ObserveError('value 15 Jan, not saved');
        C.Modify();
        if TryCalcValueFields(C) then
            Observer.Observe('value 15 Jan, saved', StrSubstNo('ff=%1 f=%2', C.CntValueFf, C.CntValueF))
        else
            Observer.ObserveError('value 15 Jan, saved');
        C."Date Value" := 20260116D;
        C.Modify();
        if TryCalcValueFields(C) then
            Observer.Observe('value 16 Jan, saved', StrSubstNo('ff=%1 f=%2', C.CntValueFf, C.CntValueF))
        else
            Observer.ObserveError('value 16 Jan, saved');
        Observer.Finish();
    end;

    local procedure TextState(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text[30])
    var
        C: Record "REC FfDate Cue";
    begin
        C.Get('CUE');
        C."Date Text" := Value;
        C.Modify();
        if TryCalcTextField(C) then
            Observer.Observe(Name, Format(C.CntTextFf))
        else begin
            Observer.Observe(Name, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
    end;

    [Test]
    procedure FieldFilterOverNormalTextField_DateFilterText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        TextState(Observer, 'blank text', '');
        TextState(Observer, 'one date', CopyStr(Format(20260115D), 1, 30));
        TextState(Observer, 'range', CopyStr(Format(20260110D) + '..' + Format(20260115D), 1, 30));
        TextState(Observer, 'from', CopyStr(Format(20260115D) + '..', 1, 30));
        TextState(Observer, 'two quotes', '''''');
        TextState(Observer, 'not a date', 'abc');
        Observer.Finish();
    end;
}
