// Probe (observe only): the writing members of a FieldRef that no RecordRef.Field call filled (the reading members are pinned by types/PSUnassignedFieldRef.al).
// Settles the open part of docs/probes-needed.md row 675 (Value(x), then SetRange / SetFilter / CalcField / Validate) (batch 4). Object id 68078.

codeunit 68078 "W4 FieldRef Setter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetValue(var FR: FieldRef)
    begin
        FR.Value := 5;
    end;

    [TryFunction]
    local procedure TrySetRange(var FR: FieldRef)
    begin
        FR.SetRange(1, 2);
    end;

    [TryFunction]
    local procedure TrySetFilter(var FR: FieldRef)
    begin
        FR.SetFilter('>1');
    end;

    [TryFunction]
    local procedure TryCalcField(var FR: FieldRef)
    begin
        FR.CalcField();
    end;

    [TryFunction]
    local procedure TryGetFilter(var FR: FieldRef; var Result: Text)
    begin
        Result := FR.GetFilter();
    end;

    [TryFunction]
    local procedure TryValidate(var FR: FieldRef)
    begin
        FR.Validate(5);
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:[' + Value + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure UnassignedFieldRef_WritingMembers()
    var
        FR: FieldRef;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value_assign', Outcome(TrySetValue(FR), ''));
        ClearLastError();
        Observer.Observe('setrange', Outcome(TrySetRange(FR), ''));
        ClearLastError();
        Observer.Observe('setfilter', Outcome(TrySetFilter(FR), ''));
        ClearLastError();
        Observer.Observe('calcfield', Outcome(TryCalcField(FR), ''));
        ClearLastError();
        Observer.Observe('getfilter', Outcome(TryGetFilter(FR, Result), Result));
        ClearLastError();
        Observer.Observe('validate', Outcome(TryValidate(FR), ''));
        ClearLastError();
        Observer.Expect('value_assign', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('setrange', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('setfilter', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('calcfield', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('getfilter', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('validate', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Verify();
    end;
}
