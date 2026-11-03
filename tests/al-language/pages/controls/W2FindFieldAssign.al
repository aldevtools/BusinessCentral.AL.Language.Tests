// Probe: FindFirstField / FindNextField / FindPreviousField misses, a bare control name next to a local variable of the same name, and TestPage field .Value assignment.
// Settles: md:403 (miss with the result unused), md:473 (which wins: local variable or control), md:472 (.Value := compared with SetValue).

table 68668 "W2 Find Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68667 "W2 Find List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Find Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 68669 "W2 Find Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "W2 Find Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'Alpha');
        AddRow(2, 'Beta');
        AddRow(3, 'Gamma');
    end;

    local procedure AddRow(Id: Integer; Name: Text[30])
    var
        Row: Record "W2 Find Row";
    begin
        Row.Id := Id;
        Row.Name := Name;
        Row.Insert();
    end;

    // md:403 The result is used: a miss answers false, the cursor stays.
    [Test]
    procedure FindField_MissWithResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Found: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Found := Pg.FindFirstField(Name, 'Nope');
        Observer.Observe('first|found', Format(Found));
        Observer.Observe('first|row', Pg.Id.Value());
        Found := Pg.FindNextField(Name, 'Nope');
        Observer.Observe('next|found', Format(Found));
        Observer.Observe('next|row', Pg.Id.Value());
        Found := Pg.FindPreviousField(Name, 'Nope');
        Observer.Observe('previous|found', Format(Found));
        Observer.Observe('previous|row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('first|found', 'No');
        Observer.Expect('first|row', '1');
        Observer.Expect('next|found', 'No');
        Observer.Expect('next|row', '1');
        Observer.Expect('previous|found', 'No');
        Observer.Expect('previous|row', '1');
        Observer.Verify();
    end;

    // md:403 A hit with the result used.
    [Test]
    procedure FindField_HitWithResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Found: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Found := Pg.FindFirstField(Name, 'Gamma');
        Observer.Observe('first|found', Format(Found));
        Observer.Observe('first|row', Pg.Id.Value());
        Found := Pg.FindPreviousField(Name, 'Alpha');
        Observer.Observe('previous|found', Format(Found));
        Observer.Observe('previous|row', Pg.Id.Value());
        Found := Pg.FindNextField(Name, 'Beta');
        Observer.Observe('next|found', Format(Found));
        Observer.Observe('next|row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('first|found', 'Yes');
        Observer.Expect('first|row', '3');
        Observer.Expect('previous|found', 'Yes');
        Observer.Expect('previous|row', '1');
        Observer.Expect('next|found', 'Yes');
        Observer.Expect('next|row', '2');
        Observer.Verify();
    end;

    // md:403 Misses with the result unused: raise or not, per method. Each in its own TryFunction.
    [Test]
    procedure FindFirstField_MissWithResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Ok := MissFirst(Pg);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('first');
        Observer.Observe('row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('first|text', 'The row does not exist on the TestPage.');
        Observer.Expect('first|code', 'TestRowNotFound');
        Observer.Expect('row', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FindNextField_MissWithResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Ok := MissNext(Pg);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('next');
        Observer.Observe('row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('next|text', 'The row does not exist on the TestPage.');
        Observer.Expect('next|code', 'TestRowNotFound');
        Observer.Expect('row', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FindPreviousField_MissWithResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.Last();
        Ok := MissPrevious(Pg);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('previous');
        Observer.Observe('row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('previous|text', 'The row does not exist on the TestPage.');
        Observer.Expect('previous|code', 'TestRowNotFound');
        Observer.Expect('row', '3');
        Observer.Verify();
    end;

    // md:473 A local variable named like the control. The bare name in the field position: which one is used?
    // The call sits in a TryFunction (its own local variable Name = 'Id'), so a refusal is observed.
    [Test]
    procedure FindFirstField_LocalVariableNamedLikeTheControl()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Found: Boolean;
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Ok := TryFirstByName(Pg, Found);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('first');
        Observer.Observe('found', Format(Found));
        Observer.Observe('row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('ok', 'Yes');
        Observer.Expect('found', 'Yes');
        Observer.Expect('row', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FindNextField_LocalVariableNamedLikeTheControl()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Found: Boolean;
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Ok := TryNextByName(Pg, Found);
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('next');
        Observer.Observe('found', Format(Found));
        Observer.Observe('row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('ok', 'Yes');
        Observer.Expect('found', 'Yes');
        Observer.Expect('row', '3');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFirstByName(var Pg: TestPage "W2 Find List"; var Found: Boolean)
    var
        Name: Text;
    begin
        Name := 'Id';
        Found := Pg.FindFirstField(Name, 'Beta');
    end;

    [TryFunction]
    local procedure TryNextByName(var Pg: TestPage "W2 Find List"; var Found: Boolean)
    var
        Name: Text;
    begin
        Name := 'Id';
        Found := Pg.FindNextField(Name, 'Gamma');
    end;

    // md:473 Same names, the control reached with the qualified form for contrast.
    [Test]
    procedure FindFirstField_QualifiedControlWithLocalVariableOfTheSameName()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Find List";
        Name: Text;
        Found: Boolean;
    begin
        Seed();
        Name := 'Id';
        Pg.OpenView();
        Pg.First();
        Found := Pg.FindFirstField(Pg.Name, 'Beta');
        Observer.Observe('found', Format(Found));
        Observer.Observe('row', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('found', 'Yes');
        Observer.Expect('row', '2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure MissFirst(var Pg: TestPage "W2 Find List")
    begin
        Pg.FindFirstField(Name, 'Nope');
    end;

    [TryFunction]
    local procedure MissNext(var Pg: TestPage "W2 Find List")
    begin
        Pg.FindNextField(Name, 'Nope');
    end;

    [TryFunction]
    local procedure MissPrevious(var Pg: TestPage "W2 Find List")
    begin
        Pg.FindPreviousField(Name, 'Nope');
    end;
}

// md:472: Pg.Field.Value := 'x' compared with Pg.Field.SetValue('x'): OnValidate, read-back, non-editable field.
codeunit 68671 "W2 Assign Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 68672 "W2 Assign Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Find Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(EditableCtl; EditableText)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Assign Log";
                begin
                    Log.Add('EditableCtl.OnValidate(' + EditableText + ')');
                end;
            }
            field(FixedCtl; FixedText)
            {
                ApplicationArea = All;
                Editable = false;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Assign Log";
                begin
                    Log.Add('FixedCtl.OnValidate(' + FixedText + ')');
                end;
            }
            field(NumberCtl; NumberVar)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Assign Log";
                begin
                    Log.Add('NumberCtl.OnValidate(' + Format(NumberVar) + ')');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        FixedText := 'initial';
    end;

    var
        EditableText: Text;
        FixedText: Text;
        NumberVar: Integer;
}

codeunit 68670 "W2 Assign Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ValueAssign_EditableControl_VersusSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Assign Log";
        Pg: TestPage "W2 Assign Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Log.Take();
        Ok := AssignEditable(Pg, 'by-value');
        Observer.Observe('assign|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('assign');
        Observer.Observe('assign|log', Log.Take());
        Observer.Observe('assign|read', Pg.EditableCtl.Value());
        Ok := SetEditable(Pg, 'by-set');
        Observer.Observe('set|ok', Format(Ok));
        Observer.Observe('set|log', Log.Take());
        Observer.Observe('set|read', Pg.EditableCtl.Value());
        Pg.Close();
        Observer.Expect('assign|ok', 'Yes');
        Observer.Expect('assign|log', 'EditableCtl.OnValidate(by-value);');
        Observer.Expect('assign|read', 'by-value');
        Observer.Expect('set|ok', 'Yes');
        Observer.Expect('set|log', 'EditableCtl.OnValidate(by-set);');
        Observer.Expect('set|read', 'by-set');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAssign_NotEditableControl_VersusSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Assign Log";
        Pg: TestPage "W2 Assign Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Log.Take();
        Ok := AssignFixed(Pg, 'by-value');
        Observer.Observe('assign|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('assign');
        Observer.Observe('assign|log', Log.Take());
        Observer.Observe('assign|read', Pg.FixedCtl.Value());
        Ok := SetFixed(Pg, 'by-set');
        Observer.Observe('set|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('set');
        Observer.Observe('set|log', Log.Take());
        Observer.Observe('set|read', Pg.FixedCtl.Value());
        Pg.Close();
        Observer.Expect('assign|ok', 'Yes');
        Observer.Expect('assign|log', 'FixedCtl.OnValidate(by-value);');
        Observer.Expect('assign|read', 'by-value');
        Observer.Expect('set|ok', 'Yes');
        Observer.Expect('set|log', 'FixedCtl.OnValidate(by-set);');
        Observer.Expect('set|read', 'by-set');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAssign_IntegerControl_TextAndNonNumber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Assign Log";
        Pg: TestPage "W2 Assign Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Log.Take();
        Ok := AssignNumber(Pg, '42');
        Observer.Observe('number|ok', Format(Ok));
        Observer.Observe('number|log', Log.Take());
        Observer.Observe('number|read', Pg.NumberCtl.Value());
        Ok := AssignNumber(Pg, 'abc');
        Observer.Observe('text|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('text');
        Observer.Observe('text|log', Log.Take());
        Observer.Observe('text|read', Pg.NumberCtl.Value());
        Ok := SetNumber(Pg, 'abc');
        Observer.Observe('set_text|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('set_text');
        Pg.Close();
        Observer.Expect('number|ok', 'Yes');
        Observer.Expect('number|log', 'NumberCtl.OnValidate(42);');
        Observer.Expect('number|read', '42');
        Observer.Expect('text|ok', 'No');
        Observer.Expect('text|text', 'Validation error for Field: NumberCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''NumberCtl''. The value "abc" can''t be evaluated into type Integer.''');
        Observer.Expect('text|code', 'TestValidation');
        Observer.Expect('text|log', '');
        Observer.Expect('text|read', '42');
        Observer.Expect('set_text|ok', 'No');
        Observer.Expect('set_text|text', 'Validation error for Field: NumberCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''NumberCtl''. The value "abc" can''t be evaluated into type Integer.''');
        Observer.Expect('set_text|code', 'TestValidation');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure AssignEditable(var Pg: TestPage "W2 Assign Card"; Input: Text)
    begin
        Pg.EditableCtl.Value := Input;
    end;

    [TryFunction]
    local procedure SetEditable(var Pg: TestPage "W2 Assign Card"; Input: Text)
    begin
        Pg.EditableCtl.SetValue(Input);
    end;

    [TryFunction]
    local procedure AssignFixed(var Pg: TestPage "W2 Assign Card"; Input: Text)
    begin
        Pg.FixedCtl.Value := Input;
    end;

    [TryFunction]
    local procedure SetFixed(var Pg: TestPage "W2 Assign Card"; Input: Text)
    begin
        Pg.FixedCtl.SetValue(Input);
    end;

    [TryFunction]
    local procedure AssignNumber(var Pg: TestPage "W2 Assign Card"; Input: Text)
    begin
        Pg.NumberCtl.Value := Input;
    end;

    [TryFunction]
    local procedure SetNumber(var Pg: TestPage "W2 Assign Card"; Input: Text)
    begin
        Pg.NumberCtl.SetValue(Input);
    end;
}
