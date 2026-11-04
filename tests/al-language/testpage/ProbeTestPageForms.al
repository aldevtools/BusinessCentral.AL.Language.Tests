// Probe: TestPage Value assignment, SetValue of the held value, FindFirstField misses, validation error index,
// BelowxRec in OnInsertRecord.
codeunit 69523 "Probe Tp Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 69524 "PB Tp List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Probe Pf Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Txt; Rec.Txt)
                {
                    trigger OnValidate()
                    var
                        Log: Codeunit "Probe Tp Log";
                    begin
                        Log.Add('OnValidate(' + Rec.Txt + ')');
                    end;
                }
                field(ReadOnlyTxt; Rec.Txt)
                {
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "Probe Tp Log";
    begin
        Log.Add('OnInsertRecord(below=' + Format(BelowxRec) + ')');
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "Probe Tp Log";
    begin
        Log.Add('OnNewRecord(below=' + Format(BelowxRec) + ')');
    end;
}

page 69525 "Probe Tp Validation"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Probe Pf Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                MinValue = 1;
                MaxValue = 10;
            }
        }
    }
}

codeunit 69526 "Probe Test Page Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "Probe Pf Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Id := i;
            Row.Txt := 'row' + Format(i);
            Row.Insert();
        end;
    end;

    [Test]
    procedure Value_AssignOnEditableField_VersusSetValue()
    var
        Pg: TestPage "PB Tp List";
        Log: Codeunit "Probe Tp Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Log.Take();
        Pg.Txt.Value := 'assigned';
        Observer.Observe('afterValueAssign_log', Log.Take());
        Observer.Observe('afterValueAssign_value', Pg.Txt.Value());
        Pg.Txt.SetValue('viaSetValue');
        Observer.Observe('afterSetValue_log', Log.Take());
        Observer.Observe('afterSetValue_value', Pg.Txt.Value());
        Pg.Close();
        Observer.Expect('afterValueAssign_log', 'OnValidate(assigned);');
        Observer.Expect('afterValueAssign_value', 'assigned');
        Observer.Expect('afterSetValue_log', 'OnValidate(viaSetValue);');
        Observer.Expect('afterSetValue_value', 'viaSetValue');
        Observer.Verify();
    end;

    [Test]
    procedure Value_AssignOnNonEditableField_ErrorText()
    var
        Pg: TestPage "PB Tp List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Pg.ReadOnlyTxt.Value := 'x';
        Observer.Observe('valueAssignNonEditable', 'no error');
        Pg.ReadOnlyTxt.SetValue('x');
        Observer.Observe('setValueNonEditable', 'no error');
        Observer.Expect('valueAssignNonEditable', 'no error');
        Observer.Expect('setValueNonEditable', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_SameValueAsHeld_RunsOnValidate()
    var
        Pg: TestPage "PB Tp List";
        Log: Codeunit "Probe Tp Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(2);
        Log.Take();
        Pg.Txt.SetValue(Pg.Txt.Value());
        Observer.Observe('sameValue_log', Log.Take());
        Pg.Txt.SetValue('row2');
        Observer.Observe('sameLiteral_log', Log.Take());
        Pg.Txt.SetValue('other');
        Pg.Txt.SetValue('other');
        Observer.Observe('twiceOther_log', Log.Take());
        Pg.Close();
        Observer.Expect('sameValue_log', 'OnValidate(row2);');
        Observer.Expect('sameLiteral_log', 'OnValidate(row2);');
        Observer.Expect('twiceOther_log', 'OnValidate(other);OnValidate(other);');
        Observer.Verify();
    end;

    [Test]
    procedure FindFirstField_Miss_ResultUnused_AndUsed()
    var
        Pg: TestPage "PB Tp List";
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Found := Pg.GoToKey(1);
        Found := Pg.FindFirstField(Txt, 'nomatch');
        Observer.Observe('findFirstUsed', Format(Found));
        Found := Pg.FindNextField(Txt, 'nomatch');
        Observer.Observe('findNextUsed', Format(Found));
        Found := Pg.FindPreviousField(Txt, 'nomatch');
        Observer.Observe('findPreviousUsed', Format(Found));
        Pg.Close();
        Observer.Expect('findFirstUsed', 'No');
        Observer.Expect('findNextUsed', 'No');
        Observer.Expect('findPreviousUsed', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetValidationError_IndexPastLast()
    var
        Pg: TestPage "Probe Tp Validation";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Pg.Id.SetValue(11);
        Observer.Observe('setValueOutOfRange', 'no error');
        asserterror Observer.Observe('error0', Pg.GetValidationError(0));
        Observer.ObserveError('error0');
        asserterror Observer.Observe('error1', Pg.GetValidationError(1));
        Observer.ObserveError('indexOnePastLast');
        asserterror Observer.Observe('error5', Pg.GetValidationError(5));
        Observer.ObserveError('indexFivePastLast');
        Observer.Expect('setValueOutOfRange', 'no error');
        Observer.Expect('error0|text', 'Index out of bounds.');
        Observer.Expect('error0|code', 'IndexOutOfBounds');
        Observer.Expect('indexOnePastLast|text', 'Index out of bounds.');
        Observer.Expect('indexOnePastLast|code', 'IndexOutOfBounds');
        Observer.Expect('indexFivePastLast|text', 'Index out of bounds.');
        Observer.Expect('indexFivePastLast|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure OnInsertRecord_BelowxRec_NewAtEnd_AndInMiddle()
    var
        Pg: TestPage "PB Tp List";
        Log: Codeunit "Probe Tp Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Last();
        Log.Take();
        Pg.New();
        Pg.Id.SetValue(10);
        Pg.Txt.SetValue('atEnd');
        Pg.Next();
        Observer.Observe('newAtEnd_log', Log.Take());
        Pg.GoToKey(2);
        Log.Take();
        Pg.New();
        Pg.Id.SetValue(20);
        Pg.Txt.SetValue('inMiddle');
        Pg.Next();
        Observer.Observe('newInMiddle_log', Log.Take());
        Pg.Close();
        Observer.Expect('newAtEnd_log', 'OnNewRecord(below=Yes);OnInsertRecord(below=Yes);OnValidate(atEnd);OnNewRecord(below=Yes);');
        Observer.Expect('newInMiddle_log', 'OnNewRecord(below=Yes);OnInsertRecord(below=Yes);OnValidate(inMiddle);');
        Observer.Verify();
    end;
}
