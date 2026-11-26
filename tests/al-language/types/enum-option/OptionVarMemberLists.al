// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75242..75246 (OVM Row, OVM Lib, OVM Publisher, OVM Subscriber,
//   OVM Member Lists Tests)
// local object: an Option variable handed to a var parameter whose Option member list differs is what is under test.
// Probe (al-runner issue 7994 and its follow-up): what a caller's Option variable shows after it was handed to a var parameter
//   with another member list, and what the callee shows of it. Cells: a var Value: Option parameter (no members) with an empty
//   body, with Value := 1, with Format inside; the caller a local, a global, a record field (with and without OptionCaption), an
//   array element; a callee in another codeunit; two hops; a parameter with other members (A,B,C), with the same members, with
//   the member " "; a memberless caller handed to a parameter with members; var arrays of memberless Option; integration
//   events (memberless publisher; publisher with members and a memberless subscriber); a TryFunction callee; a callee that
//   raises after the assignment; by-value memberless parameters as the control. After the call: Format, Format 0 2, Format 0 9,
//   StrSubstNo, concatenation, compare, case, Evaluate(V, 'Third'), a Variant copy, Error('%1', V).
// Facts: a var Value: Option parameter without members uses the member list of the variable handed in. Inside the callee,
//   Format and StrSubstNo show the caller's member name (Second), or its caption for a record field with OptionCaption (Two);
//   Format 0 2 shows the ordinal. After an empty body the caller is unchanged; Value := 1 in the callee shows Second in the caller.
//   A by-value memberless parameter shows the ordinal (1) and does not change the caller. A parameter with other members (A,B,C)
//   shows its own name (B); Value := Value::C gives the caller Third. A parameter Option " " shows the ordinal (1); a parameter
//   Option "" shows the caller's name. A memberless caller handed to a parameter with members: the callee shows Second, the
//   caller still shows 1. Globals, record fields, array elements, another codeunit, two hops, var arrays, integration event
//   subscribers, a TryFunction callee and a callee that raises after the assignment all behave like the local caller.
// BC versions: identical on 27.5, 28.5 and 29.0 (Linux, corpus CI) and on a local Windows BC 29.0 tier.
table 75242 "OVM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = First,Second,Third; }
        field(3; OptCap; Option) { OptionMembers = First,Second,Third; OptionCaption = 'One,Two,Three'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// A callee in another codeunit than the caller.
codeunit 75243 "OVM Lib"
{
    procedure Nop(var Value: Option)
    begin
    end;

    procedure Assign1(var Value: Option)
    begin
        Value := 1;
    end;
}

// Raises the events: one with a memberless var Option parameter, one whose parameter has the caller's members.
codeunit 75244 "OVM Publisher"
{
    procedure RaiseMemberless(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        OnMemberless(Value, Write, Seen);
    end;

    procedure RaiseWithMembers(var Value: Option First,Second,Third; Write: Boolean; var Seen: Text)
    begin
        OnWithMembers(Value, Write, Seen);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMemberless(var Value: Option; Write: Boolean; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWithMembers(var Value: Option First,Second,Third; Write: Boolean; var Seen: Text)
    begin
    end;
}

codeunit 75245 "OVM Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVM Publisher", 'OnMemberless', '', false, false)]
    local procedure HandleMemberless(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        Seen := Format(Value) + '/' + Format(Value, 0, 2);
        if Write then
            Value := 2;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVM Publisher", 'OnWithMembers', '', false, false)]
    local procedure HandleWithMembers(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        Seen := Format(Value) + '/' + Format(Value, 0, 2);
        if Write then
            Value := 2;
    end;
}

codeunit 75246 "OVM Member Lists Tests"
{
    Subtype = Test;

    var
        GlobalV: Option First,Second,Third;

    [Test]
    procedure MemberlessVar_EmptyBody_CallerFormat()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Nop(V);
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Observe('Format 0 9', Format(V, 0, 9));
        Observer.Observe('StrSubstNo', StrSubstNo('%1', V));
        Observer.Observe('Concat', 'x' + Format(V) + 'y');
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Expect('Format 0 9', '1');
        Observer.Expect('StrSubstNo', 'Second');
        Observer.Expect('Concat', 'xSecondy');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_CallerCompareCase()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        T: Text;
    begin
        V := V::Second;
        Nop(V);
        Observer.Observe('V = V::Second', Format(V = V::Second));
        case V of
            V::First:
                T := 'First';
            V::Second:
                T := 'Second';
            else
                T := 'else';
        end;
        Observer.Observe('case', T);
        Observer.Expect('V = V::Second', 'Yes');
        Observer.Expect('case', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_CallerEvaluateThird()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Nop(V);
        Evaluate(V, 'Third');
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Expect('Format', 'Third');
        Observer.Expect('Format 0 2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_CallerEvaluateThirdResult()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        Ok: Boolean;
    begin
        V := V::Second;
        Nop(V);
        ClearLastError();
        Ok := Evaluate(V, 'Third');
        Observer.Observe('result', Format(Ok));
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Observe('last error', GetLastErrorText());
        Observer.Expect('result', 'Yes');
        Observer.Expect('Format', 'Third');
        Observer.Expect('Format 0 2', '2');
        Observer.Expect('last error', '');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_CallerVariantAndError()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        X: Variant;
        Copy: Option First,Second,Third;
    begin
        V := V::Second;
        Nop(V);
        X := V;
        Observer.Observe('Variant Format', Format(X));
        Copy := V;
        Observer.Observe('copy Format', Format(Copy));
        asserterror Error('%1', V);
        Observer.ObserveError('Error %1');
        Observer.Expect('Variant Format', 'Second');
        Observer.Expect('copy Format', 'Second');
        Observer.Expect('Error %1|text', 'Second');
        Observer.Expect('Error %1|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_CallerReassign()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Nop(V);
        V := V::Third;
        Observer.Observe('Format', Format(V));
        Observer.Expect('Format', 'Third');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_Assign1_CallerFormat()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Assign1(V);
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Observe('StrSubstNo', StrSubstNo('%1', V));
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Expect('StrSubstNo', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_CalleeFormat_CallerLocal()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', FormatInsideVar(V));
        Observer.Observe('after', Format(V));
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessByValue_CalleeFormat_CallerLocal()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', FormatInsideByValue(V));
        Observer.Observe('after', Format(V));
        Observer.Expect('inside', '1|1|1');
        Observer.Expect('after', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessByValue_CalleeAssign_CallerLocal()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', AssignByValue(V));
        Observer.Observe('after', Format(V));
        Observer.Expect('inside', '2');
        Observer.Expect('after', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_CalleeFormat_RecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVM Row";
    begin
        Row.Opt := Row.Opt::Second;
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('var field', FormatInsideVar(Row.Opt));
        Observer.Observe('var caption field', FormatInsideVar(Row.OptCap));
        Observer.Observe('by value field', FormatInsideByValue(Row.Opt));
        Observer.Observe('by value caption field', FormatInsideByValue(Row.OptCap));
        Observer.Observe('after field', Format(Row.Opt));
        Observer.Observe('after caption field', Format(Row.OptCap));
        Observer.Expect('var field', 'Second|Second|1');
        Observer.Expect('var caption field', 'Two|Two|1');
        Observer.Expect('by value field', '1|1|1');
        Observer.Expect('by value caption field', '1|1|1');
        Observer.Expect('after field', 'Second');
        Observer.Expect('after caption field', 'Two');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_RecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVM Row";
    begin
        Row.Opt := Row.Opt::Second;
        Row.OptCap := Row.OptCap::Second;
        Nop(Row.Opt);
        Nop(Row.OptCap);
        Observer.Observe('field', Format(Row.Opt));
        Observer.Observe('caption field', Format(Row.OptCap));
        Assign1(Row.Opt);
        Row.OptCap := Row.OptCap::Third;
        Assign1(Row.OptCap);
        Observer.Observe('field after Assign1', Format(Row.Opt));
        Observer.Observe('caption field after Assign1', Format(Row.OptCap));
        Observer.Expect('field', 'Second');
        Observer.Expect('caption field', 'Two');
        Observer.Expect('field after Assign1', 'Second');
        Observer.Expect('caption field after Assign1', 'Two');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_EmptyBody_Global()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalV := GlobalV::Second;
        Nop(GlobalV);
        Observer.Observe('Format', Format(GlobalV));
        GlobalV := GlobalV::First;
        Assign1(GlobalV);
        Observer.Observe('Format after Assign1', Format(GlobalV));
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format after Assign1', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_OtherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Lib: Codeunit "OVM Lib";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Lib.Nop(V);
        Observer.Observe('Format after Nop', Format(V));
        V := V::First;
        Lib.Assign1(V);
        Observer.Observe('Format after Assign1', Format(V));
        Observer.Expect('Format after Nop', 'Second');
        Observer.Expect('Format after Assign1', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_TwoHops()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        HopNop(V);
        Observer.Observe('Format after HopNop', Format(V));
        V := V::First;
        HopAssign1(V);
        Observer.Observe('Format after HopAssign1', Format(V));
        Observer.Expect('Format after HopNop', 'Second');
        Observer.Expect('Format after HopAssign1', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure OtherMembersVar_EmptyBody()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        OtherMembersNop(V);
        Observer.Observe('Format', Format(V));
        Observer.Observe('Format 0 2', Format(V, 0, 2));
        Observer.Observe('StrSubstNo', StrSubstNo('%1', V));
        Observer.Expect('Format', 'Second');
        Observer.Expect('Format 0 2', '1');
        Observer.Expect('StrSubstNo', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure OtherMembersVar_CalleeFormatAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', OtherMembersFormat(V));
        Observer.Observe('after', Format(V));
        OtherMembersAssignC(V);
        Observer.Observe('after Value::C', Format(V));
        Observer.Observe('after Value::C 0 2', Format(V, 0, 2));
        Observer.Expect('inside', 'B|B|1');
        Observer.Expect('after', 'Second');
        Observer.Expect('after Value::C', 'Third');
        Observer.Expect('after Value::C 0 2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SameMembersVar_EmptyBody()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        SameMembersNop(V);
        Observer.Observe('Format', Format(V));
        Observer.Observe('inside', SameMembersFormat(V));
        Observer.Expect('Format', 'Second');
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessCaller_MembersVar()
    var
        Observer: Codeunit "Probe Observer";
        V0: Option;
    begin
        V0 := 1;
        Observer.Observe('Format before', Format(V0));
        Observer.Observe('inside', SameMembersFormat(V0));
        Observer.Observe('Format after', Format(V0));
        SameMembersNop(V0);
        Observer.Observe('Format after empty body', Format(V0));
        Observer.Observe('StrSubstNo after empty body', StrSubstNo('%1', V0));
        Observer.Expect('Format before', '1');
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('Format after', '1');
        Observer.Expect('Format after empty body', '1');
        Observer.Expect('StrSubstNo after empty body', '1');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessCaller_MemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V0: Option;
    begin
        V0 := 1;
        Nop(V0);
        Observer.Observe('Format', Format(V0));
        Observer.Observe('inside', FormatInsideVar(V0));
        Observer.Expect('Format', '1');
        Observer.Expect('inside', '1|1|1');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVarArray_Callee()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        ArrayNop(Arr);
        Observer.Observe('after empty body', Format(Arr[1]));
        Observer.Observe('inside', ArrayFormat(Arr));
        Observer.Observe('after inside', Format(Arr[1]));
        Arr[1] := Arr[1]::First;
        ArrayAssign1(Arr);
        Observer.Observe('after A[1] := 1', Format(Arr[1]));
        Observer.Observe('after A[1] := 1 0 2', Format(Arr[1], 0, 2));
        Observer.Expect('after empty body', 'Second');
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after inside', 'Second');
        Observer.Expect('after A[1] := 1', 'Second');
        Observer.Expect('after A[1] := 1 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_ArrayElementCaller()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Nop(Arr[1]);
        Observer.Observe('after empty body', Format(Arr[1]));
        Observer.Observe('inside', FormatInsideVar(Arr[1]));
        Arr[2] := Arr[2]::First;
        Assign1(Arr[2]);
        Observer.Observe('after Assign1', Format(Arr[2]));
        Observer.Expect('after empty body', 'Second');
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after Assign1', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure Event_MemberlessPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVM Publisher";
        V: Option First,Second,Third;
        Seen: Text;
    begin
        V := V::Second;
        Publisher.RaiseMemberless(V, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(V));
        V := V::First;
        Publisher.RaiseMemberless(V, true, Seen);
        Observer.Observe('after write 2', Format(V));
        Observer.Expect('subscriber saw', 'Second/1');
        Observer.Expect('after', 'Second');
        Observer.Expect('after write 2', 'Third');
        Observer.Verify();
    end;

    [Test]
    procedure Event_MembersPublisher_MemberlessSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVM Publisher";
        V: Option First,Second,Third;
        Seen: Text;
    begin
        V := V::Second;
        Publisher.RaiseWithMembers(V, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(V));
        V := V::First;
        Publisher.RaiseWithMembers(V, true, Seen);
        Observer.Observe('after write 2', Format(V));
        Observer.Expect('subscriber saw', 'Second/1');
        Observer.Expect('after', 'Second');
        Observer.Expect('after write 2', 'Third');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_TryFunctionAssign()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('try result', Format(TryAssign1(V)));
        Observer.Observe('Format', Format(V));
        Observer.Expect('try result', 'Yes');
        Observer.Expect('Format', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVar_AssignThenError()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        asserterror Assign1ThenError(V);
        Observer.ObserveError('error');
        Observer.Observe('Format', Format(V));
        Observer.Expect('error|text', 'stop after the assignment');
        Observer.Expect('error|code', 'Dialog');
        Observer.Expect('Format', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure BlankMemberVar_EmptyBody()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        BlankMemberNop(V);
        Observer.Observe('Format', Format(V));
        Observer.Observe('inside', BlankMemberFormat(V));
        Observer.Expect('Format', 'Second');
        Observer.Expect('inside', '1|1');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyNameMemberVar_EmptyBody()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        EmptyNameMemberNop(V);
        Observer.Observe('Format', Format(V));
        Observer.Observe('inside', EmptyNameMemberFormat(V));
        Observer.Expect('Format', 'Second');
        Observer.Expect('inside', 'Second|1');
        Observer.Verify();
    end;

    local procedure Nop(var Value: Option)
    begin
    end;

    local procedure EmptyNameMemberNop(var Value: Option "")
    begin
    end;

    local procedure EmptyNameMemberFormat(var Value: Option ""): Text
    begin
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure Assign1(var Value: Option)
    begin
        Value := 1;
    end;

    local procedure FormatInsideVar(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure FormatInsideByValue(Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure AssignByValue(Value: Option): Text
    begin
        Value := 2;
        exit(Format(Value));
    end;

    local procedure HopNop(var Value: Option)
    begin
        Nop(Value);
    end;

    local procedure HopAssign1(var Value: Option)
    begin
        Assign1(Value);
    end;

    local procedure OtherMembersNop(var Value: Option A,B,C)
    begin
    end;

    local procedure OtherMembersFormat(var Value: Option A,B,C): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure OtherMembersAssignC(var Value: Option A,B,C)
    begin
        Value := Value::C;
    end;

    local procedure SameMembersNop(var Value: Option First,Second,Third)
    begin
    end;

    local procedure SameMembersFormat(var Value: Option First,Second,Third): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure ArrayNop(var A: array[2] of Option)
    begin
    end;

    local procedure ArrayFormat(var A: array[2] of Option): Text
    begin
        exit(Format(A[1]) + '|' + StrSubstNo('%1', A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ArrayAssign1(var A: array[2] of Option)
    begin
        A[1] := 1;
    end;

    [TryFunction]
    local procedure TryAssign1(var Value: Option)
    begin
        Value := 1;
    end;

    local procedure Assign1ThenError(var Value: Option)
    begin
        Value := 1;
        Error('stop after the assignment');
    end;

    local procedure BlankMemberNop(var Value: Option " ")
    begin
    end;

    local procedure BlankMemberFormat(var Value: Option " "): Text
    begin
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;
}
