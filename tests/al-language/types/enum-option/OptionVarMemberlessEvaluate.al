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
// Facts: Evaluate into a var Value: Option parameter without members uses the member list of the variable handed in. Member
//   names match without regard to case and with leading and trailing blanks ignored; '1' gives Second; '7' succeeds and stores
//   ordinal 7 (Format shows 7). 'Nope' and '' fail: with the result used, Evaluate returns false, the value stays, and
//   GetLastErrorText is empty; as a statement it raises "'Nope' is not an option. The existing options are: First,Second,Third"
//   (code InvalidOptionString). For a caller Option " ",First, '' gives the blank member. A memberless caller has no members:
//   'Second' fails ("The existing options are: " with an empty list), '1' works. A by-value memberless parameter has no members
//   either, and the caller is unchanged. A record field with OptionCaption accepts both the caption (Two) and the name (Second).
//   Format number 9, Format inside the callee, globals, another codeunit, two hops, events, var array elements and an Option ""
//   parameter behave like the local caller.
// BC versions: identical on 27.5, 28.5 and 29.0 (Linux, corpus CI) and on a local Windows BC 29.0 tier.

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
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Verify();
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
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Verify();
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
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Verify();
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
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Verify();
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
        Observer.Expect('Format', '7');
        Observer.Expect('Format 0 2', '7');
        Observer.Verify();
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
        Observer.Expect('error|text', '''Nope'' is not an option. The existing options are: First,Second,Third');
        Observer.Expect('error|code', 'InvalidOptionString');
        Observer.Expect('Format', 'Third');
        Observer.Expect('Format 0 2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EvaluateStatement_Empty()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Third;
        asserterror EvalStatement(V, '');
        Observer.ObserveError('error');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Expect('error|text', ''''' is not an option. The existing options are: First,Second,Third');
        Observer.Expect('error|code', 'InvalidOptionString');
        Observer.Expect('Format', 'Third');
        Observer.Expect('Format 0 2', '2');
        Observer.Verify();
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
        Observer.Expect('Second result', 'Yes');
        Observer.Expect('Second Format', 'Second');
        Observer.Expect('Second Format 0 2', '1');
        Observer.Expect('Second error', '');
        Observer.Expect('second result', 'Yes');
        Observer.Expect('second Format', 'Second');
        Observer.Expect('second Format 0 2', '1');
        Observer.Expect('second error', '');
        Observer.Expect('blanks result', 'Yes');
        Observer.Expect('blanks Format', 'Second');
        Observer.Expect('blanks Format 0 2', '1');
        Observer.Expect('blanks error', '');
        Observer.Expect('First result', 'Yes');
        Observer.Expect('First Format', 'First');
        Observer.Expect('First Format 0 2', '0');
        Observer.Expect('First error', '');
        Observer.Verify();
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
        Observer.Expect('1 result', 'Yes');
        Observer.Expect('1 Format', 'Second');
        Observer.Expect('1 Format 0 2', '1');
        Observer.Expect('1 error', '');
        Observer.Expect('7 result', 'Yes');
        Observer.Expect('7 Format', '7');
        Observer.Expect('7 Format 0 2', '7');
        Observer.Expect('7 error', '');
        Observer.Expect('Nope result', 'No');
        Observer.Expect('Nope Format', 'Third');
        Observer.Expect('Nope Format 0 2', '2');
        Observer.Expect('Nope error', '');
        Observer.Expect('empty result', 'No');
        Observer.Expect('empty Format', 'Third');
        Observer.Expect('empty Format 0 2', '2');
        Observer.Expect('empty error', '');
        Observer.Verify();
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
        Observer.Expect('inside Second', 'Yes|Second|Second|1');
        Observer.Expect('after Second', 'Second');
        Observer.Expect('inside 1', 'Yes|Second|Second|1');
        Observer.Expect('after 1', 'Second');
        Observer.Verify();
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
        Observer.Expect('result Second', 'Yes');
        Observer.Expect('Format Second', 'Second');
        Observer.Expect('error Second', '');
        Observer.Expect('result 1', 'Yes');
        Observer.Expect('Format 1', 'Second');
        Observer.Expect('error 1', '');
        Observer.Verify();
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
        Observer.Expect('result', 'Yes');
        Observer.Expect('Format', ' ');
        Observer.Expect('Format 0 2', '0');
        Observer.Expect('error', '');
        Observer.Expect('result First', 'Yes');
        Observer.Expect('Format First', 'First');
        Observer.Expect('error First', '');
        Observer.Verify();
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
        Observer.Expect('Format', ' ');
        Observer.Expect('Format 0 2', '0');
        Observer.Verify();
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
        Observer.Expect('result Second', 'No');
        Observer.Expect('Format Second', '0');
        Observer.Expect('error Second', '');
        Observer.Expect('result 1', 'Yes');
        Observer.Expect('Format 1', '1');
        Observer.Expect('error 1', '');
        Observer.Verify();
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
        Observer.Expect('Format', '1');
        Observer.Verify();
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
        Observer.Expect('error|text', '''Second'' is not an option. The existing options are: ');
        Observer.Expect('error|code', 'InvalidOptionString');
        Observer.Expect('Format', '0');
        Observer.Verify();
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
        Observer.Expect('field result Second', 'Yes');
        Observer.Expect('field Format', 'Second');
        Observer.Expect('field error', '');
        Observer.Expect('caption field result Two', 'Yes');
        Observer.Expect('caption field Format Two', 'Two');
        Observer.Expect('caption field error Two', '');
        Observer.Expect('caption field result Second', 'Yes');
        Observer.Expect('caption field Format Second', 'Two');
        Observer.Expect('caption field error Second', '');
        Observer.Verify();
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
        Observer.Expect('field Format', 'Second');
        Observer.Verify();
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
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Verify();
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
        Observer.Expect('result', 'Yes');
        Observer.Expect('Format', 'Second');
        Observer.Expect('error', '');
        Observer.Verify();
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
        Observer.Expect('inside Second', 'No|2|2');
        Observer.Expect('error Second', '');
        Observer.Expect('inside 1', 'Yes|1|1');
        Observer.Expect('error 1', '');
        Observer.Expect('after', 'Third');
        Observer.Verify();
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
        Observer.Expect('error|text', '''Second'' is not an option. The existing options are: ');
        Observer.Expect('error|code', 'InvalidOptionString');
        Observer.Expect('after', 'Third');
        Observer.Verify();
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
        Observer.Expect('result Second', 'Yes');
        Observer.Expect('subscriber Second', 'Second|1');
        Observer.Expect('after Second', 'Second');
        Observer.Expect('result 1', 'Yes');
        Observer.Expect('after 1', 'Second');
        Observer.Verify();
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
        Observer.Expect('result Second', 'Yes');
        Observer.Expect('subscriber Second', 'Second|1');
        Observer.Expect('after Second', 'Second');
        Observer.Expect('result 1', 'Yes');
        Observer.Expect('after 1', 'Second');
        Observer.Verify();
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
        Observer.Expect('inside', 'Yes|Second|1');
        Observer.Expect('after', 'Second');
        Observer.Expect('error', '');
        Observer.Verify();
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
        Observer.Expect('global result', 'Yes');
        Observer.Expect('global Format', 'Second');
        Observer.Expect('global error', '');
        Observer.Expect('other codeunit result', 'Yes');
        Observer.Expect('other codeunit Format', 'Second');
        Observer.Expect('other codeunit error', '');
        Observer.Verify();
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
        Observer.Expect('inside Second', 'Yes|Second|1');
        Observer.Expect('after Second', 'Second');
        Observer.Expect('error Second', '');
        Observer.Expect('inside 1', 'Yes|Second|1');
        Observer.Expect('after 1', 'Second');
        Observer.Expect('error 1', '');
        Observer.Verify();
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
