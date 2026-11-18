// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-joker-string-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); OVM Row (table 75242, OptionVarMemberLists.al); own objects 75247..75249
//   (OVM Eval Lib, OVM Eval Subscriber, OVM Memberless Eval Tests)
// local object: Evaluate into a var Option parameter without members is what is under test.
// Probe (al-runner issue 7994): Evaluate(Value, Text) where Value is a var Value: Option parameter (no members) and the caller
//   hands an Option with members. Cells: member names (exact, other case, with blanks), ordinals in and past the members, an
//   unknown text and the empty text, in statement form and with the result used; Evaluate with format number 9; Format inside
//   the callee after Evaluate; the caller an Option " ",First, a memberless Option, a record field (with and without
//   OptionCaption, by name and by caption), a global; a callee in another codeunit; two hops; a by-value memberless parameter;
//   integration event subscribers (memberless publisher, publisher with members); a var array of memberless Option.
// Facts: (observation form, filled after the run)

// Callees in another codeunit, and the events whose subscribers evaluate into a memberless var Option parameter.
codeunit 75247 "OVM Eval Lib"
{
    procedure EvalResult(var Value: Option; T: Text): Boolean
    begin
        exit(Evaluate(Value, T));
    end;

    procedure RaiseMemberless(var Value: Option; T: Text; var Ok: Boolean; var Seen: Text)
    begin
        OnEvalMemberless(Value, T, Ok, Seen);
    end;

    procedure RaiseWithMembers(var Value: Option First,Second,Third; T: Text; var Ok: Boolean; var Seen: Text)
    begin
        OnEvalWithMembers(Value, T, Ok, Seen);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEvalMemberless(var Value: Option; T: Text; var Ok: Boolean; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEvalWithMembers(var Value: Option First,Second,Third; T: Text; var Ok: Boolean; var Seen: Text)
    begin
    end;
}

codeunit 75248 "OVM Eval Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVM Eval Lib", 'OnEvalMemberless', '', false, false)]
    local procedure HandleMemberless(var Value: Option; T: Text; var Ok: Boolean; var Seen: Text)
    begin
        Ok := Evaluate(Value, T);
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVM Eval Lib", 'OnEvalWithMembers', '', false, false)]
    local procedure HandleWithMembers(var Value: Option; T: Text; var Ok: Boolean; var Seen: Text)
    begin
        Ok := Evaluate(Value, T);
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;
}

codeunit 75249 "OVM Memberless Eval Tests"
{
    Subtype = Test;

    var
        GlobalV: Option First,Second,Third;

    [Test]
    procedure MemberlessVar_EvaluateStatement_Name()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        EvalStatement(V, 'Second');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_NameLowerCase()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        EvalStatement(V, 'second');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_NameBlanks()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        EvalStatement(V, ' Second ');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_Ordinal1()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        EvalStatement(V, '1');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_Ordinal7()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        EvalStatement(V, '7');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_Unknown()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        asserterror EvalStatement(V, 'Nope');
        Observer.ObserveError('error');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_Empty()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        EvalStatement(V, '');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateResult_Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveResult(Observer, 'Second', 'Second');
        ObserveResult(Observer, 'second', 'second');
        ObserveResult(Observer, 'blanks', ' Second ');
        ObserveResult(Observer, 'First', 'First');
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateResult_Others()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveResult(Observer, '1', '1');
        ObserveResult(Observer, '7', '7');
        ObserveResult(Observer, 'Nope', 'Nope');
        ObserveResult(Observer, 'empty', '');
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateThenCalleeFormat()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        Observer.Observe('inside Second', EvalThenFormat(V, 'Second'));
        Observer.Observe('after Second', Format(V));
        V := V::Third;
        Observer.Observe('inside 1', EvalThenFormat(V, '1'));
        Observer.Observe('after 1', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateFormatNumber9()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        ClearLastError();
        Observer.Observe('result Second', Format(EvalResult9(V, 'Second')));
        Observer.Observe('Format Second', Format(V));
        Observer.Observe('error Second', GetLastErrorText());
        V := V::Third;
        ClearLastError();
        Observer.Observe('result 1', Format(EvalResult9(V, '1')));
        Observer.Observe('Format 1', Format(V));
        Observer.Observe('error 1', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateResult_BlankFirstMember()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",First;
    begin
        V := V::First;
        ClearLastError();
        Observer.Observe('result', Format(EvalResult(V, '')));
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Observe('error', GetLastErrorText());
        V := V::" ";
        ClearLastError();
        Observer.Observe('result First', Format(EvalResult(V, 'First')));
        Observer.Observe('Format First', Format(V));
        Observer.Observe('error First', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_BlankFirstMember()
    var
        Observer: Codeunit "Probe Observer";
        V: Option " ",First;
    begin
        V := V::First;
        EvalStatement(V, '');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessCaller_EvaluateResult()
    var
        Observer: Codeunit "Probe Observer";
        V0: Option;
    begin
        V0 := 0;
        ClearLastError();
        Observer.Observe('result Second', Format(EvalResult(V0, 'Second')));
        Observer.Observe('Format Second', Format(V0));
        Observer.Observe('error Second', GetLastErrorText());
        V0 := 0;
        ClearLastError();
        Observer.Observe('result 1', Format(EvalResult(V0, '1')));
        Observer.Observe('Format 1', Format(V0));
        Observer.Observe('error 1', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessCaller_EvaluateStatement_Ordinal1()
    var
        Observer: Codeunit "Probe Observer";
        V0: Option;
    begin
        V0 := 0;
        EvalStatement(V0, '1');
        Observer.Observe('Format', Format(V0));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessCaller_EvaluateStatement_Name()
    var
        Observer: Codeunit "Probe Observer";
        V0: Option;
    begin
        V0 := 0;
        asserterror EvalStatement(V0, 'Second');
        Observer.ObserveError('error');
        Observer.Observe('Format', Format(V0));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateResult_RecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVM Row";
    begin
        Row.Opt := Row.Opt::Third;
        ClearLastError();
        Observer.Observe('field result Second', Format(EvalResult(Row.Opt, 'Second')));
        Observer.Observe('field Format', Format(Row.Opt));
        Observer.Observe('field error', GetLastErrorText());
        Row.OptCap := Row.OptCap::Third;
        ClearLastError();
        Observer.Observe('caption field result Two', Format(EvalResult(Row.OptCap, 'Two')));
        Observer.Observe('caption field Format Two', Format(Row.OptCap));
        Observer.Observe('caption field error Two', GetLastErrorText());
        Row.OptCap := Row.OptCap::Third;
        ClearLastError();
        Observer.Observe('caption field result Second', Format(EvalResult(Row.OptCap, 'Second')));
        Observer.Observe('caption field Format Second', Format(Row.OptCap));
        Observer.Observe('caption field error Second', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_RecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVM Row";
    begin
        Row.Opt := Row.Opt::Third;
        EvalStatement(Row.Opt, 'Second');
        Observer.Observe('field Format', Format(Row.Opt));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_TwoHops()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        HopEvalStatement(V, 'Second');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateResult_TwoHops()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        ClearLastError();
        Observer.Observe('result', Format(HopEvalResult(V, 'Second')));
        Observer.Observe('Format', Format(V));
        Observer.Observe('error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessByValue_EvaluateResult()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        ClearLastError();
        Observer.Observe('inside Second', EvalByValueResult(V, 'Second'));
        Observer.Observe('error Second', GetLastErrorText());
        ClearLastError();
        Observer.Observe('inside 1', EvalByValueResult(V, '1'));
        Observer.Observe('error 1', GetLastErrorText());
        Observer.Observe('after', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessByValue_EvaluateStatement_Name()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        asserterror EvalByValueStatement(V, 'Second');
        Observer.ObserveError('error');
        Observer.Observe('after', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure Event_MemberlessPublisher_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        Lib: Codeunit "OVM Eval Lib";
        V: Option First,Second,Third;
        Ok: Boolean;
        Seen: Text;
    begin
        V := V::Third;
        Lib.RaiseMemberless(V, 'Second', Ok, Seen);
        Observer.Observe('result Second', Format(Ok));
        Observer.Observe('subscriber Second', Seen);
        Observer.Observe('after Second', Format(V));
        V := V::Third;
        Lib.RaiseMemberless(V, '1', Ok, Seen);
        Observer.Observe('result 1', Format(Ok));
        Observer.Observe('after 1', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure Event_MembersPublisher_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        Lib: Codeunit "OVM Eval Lib";
        V: Option First,Second,Third;
        Ok: Boolean;
        Seen: Text;
    begin
        V := V::Third;
        Lib.RaiseWithMembers(V, 'Second', Ok, Seen);
        Observer.Observe('result Second', Format(Ok));
        Observer.Observe('subscriber Second', Seen);
        Observer.Observe('after Second', Format(V));
        V := V::Third;
        Lib.RaiseWithMembers(V, '1', Ok, Seen);
        Observer.Observe('result 1', Format(Ok));
        Observer.Observe('after 1', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVarArray_EvaluateResult()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Third;
        ClearLastError();
        Observer.Observe('inside', ArrayEvalResult(Arr, 'Second'));
        Observer.Observe('after', Format(Arr[1]));
        Observer.Observe('error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_EvaluateResult_GlobalAndOtherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Lib: Codeunit "OVM Eval Lib";
        V: Option First,Second,Third;
    begin
        GlobalV := GlobalV::Third;
        ClearLastError();
        Observer.Observe('global result', Format(EvalResult(GlobalV, 'Second')));
        Observer.Observe('global Format', Format(GlobalV));
        Observer.Observe('global error', GetLastErrorText());
        V := V::Third;
        ClearLastError();
        Observer.Observe('other codeunit result', Format(Lib.EvalResult(V, 'Second')));
        Observer.Observe('other codeunit Format', Format(V));
        Observer.Observe('other codeunit error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure EmptyNameMemberVar_EvaluateResult()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        ClearLastError();
        Observer.Observe('inside Second', EmptyNameEvalResult(V, 'Second'));
        Observer.Observe('after Second', Format(V));
        Observer.Observe('error Second', GetLastErrorText());
        V := V::Third;
        ClearLastError();
        Observer.Observe('inside 1', EmptyNameEvalResult(V, '1'));
        Observer.Observe('after 1', Format(V));
        Observer.Observe('error 1', GetLastErrorText());
        Observer.Finish();
    end;

    local procedure ObserveResult(var Observer: Codeunit "Probe Observer"; Name: Text; T: Text)
    var
        V: Option First,Second,Third;
    begin
        V := V::Third;
        ClearLastError();
        Observer.Observe(Name + ' result', Format(EvalResult(V, T)));
        Observer.Observe(Name + ' Format', Format(V));
        Observer.Observe(Name + ' Format 0 2', Format(V, 0, 2));
        Observer.Observe(Name + ' error', GetLastErrorText());
    end;

    local procedure EmptyNameEvalResult(var Value: Option ""; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure EvalStatement(var Value: Option; T: Text)
    begin
        Evaluate(Value, T);
    end;

    local procedure EvalResult(var Value: Option; T: Text): Boolean
    begin
        exit(Evaluate(Value, T));
    end;

    local procedure EvalResult9(var Value: Option; T: Text): Boolean
    begin
        exit(Evaluate(Value, T, 9));
    end;

    local procedure EvalThenFormat(var Value: Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure HopEvalStatement(var Value: Option; T: Text)
    begin
        EvalStatement(Value, T);
    end;

    local procedure HopEvalResult(var Value: Option; T: Text): Boolean
    begin
        exit(EvalResult(Value, T));
    end;

    local procedure EvalByValueResult(Value: Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure EvalByValueStatement(Value: Option; T: Text)
    begin
        Evaluate(Value, T);
    end;

    local procedure ArrayEvalResult(var A: array[2] of Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(A[1], T);
        exit(Format(Ok) + '|' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;
}
