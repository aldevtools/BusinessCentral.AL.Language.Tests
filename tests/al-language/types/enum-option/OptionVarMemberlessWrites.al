// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75250, 75251, 75255 (OVN Row, OVN Lib, OVN Memberless Writes Tests)
// local object: an Option variable handed to a var parameter declared without members is what is under test.
// Probe (al-runner issues 7994 and 8291, follow-up of OptionVarMemberLists.al): what a var Value: Option parameter without
//   members shows after the callee wrote to it, and what the caller shows after the call.
// FACTS: to be filled from the observation.
table 75250 "OVN Row"
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

    // Hands the record's own fields to a memberless var Option parameter of another codeunit.
    procedure FieldsViaLib(): Text
    var
        Lib: Codeunit "OVN Lib";
        Seen: Text;
    begin
        Seen := Lib.FormatInside(Opt) + '#' + Lib.FormatInside(OptCap) + '#' + Lib.FormatInside(Rec.OptCap);
        Opt := Opt::First;
        OptCap := OptCap::Third;
        Lib.Assign1(Opt);
        Lib.Assign1(OptCap);
        Seen += '#' + Format(Opt) + '#' + Format(OptCap);
        exit(Seen);
    end;

    // Hands the record's own fields to a memberless var Option parameter of the table itself.
    procedure FieldsViaOwnProcedure(): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideOwn(Opt) + '#' + FormatInsideOwn(OptCap) + '#' + FormatInsideOwn(Rec.OptCap);
        Opt := Opt::First;
        OptCap := OptCap::Third;
        Assign1Own(Opt);
        Assign1Own(OptCap);
        Seen += '#' + Format(Opt) + '#' + Format(OptCap);
        exit(Seen);
    end;

    local procedure FormatInsideOwn(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure Assign1Own(var Value: Option)
    begin
        Value := 1;
    end;
}

// Memberless var Option parameters in another codeunit than the caller.
codeunit 75251 "OVN Lib"
{
    procedure FormatInside(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    procedure Assign1(var Value: Option)
    begin
        Value := 1;
    end;
}

codeunit 75255 "OVN Memberless Writes Tests"
{
    Subtype = Test;

    var
        GlobalV: Option First,Second,Third;

    [Test]
    procedure MemberlessVar_AssignThenFormat_Inside()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('inside', Assign1ThenFormat(V));
        Observer.Observe('after', Format(V));
        Observer.Observe('after 0 2', Format(V, 0, 2));
        Observer.Observe('after StrSubstNo', StrSubstNo('%1', V));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_AssignThenEvaluate_Result()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('Third inside', Assign1ThenEvalResult(V, 'Third'));
        Observer.Observe('Third after', Format(V));
        V := V::First;
        Observer.Observe('third inside', Assign1ThenEvalResult(V, 'third'));
        Observer.Observe('third after', Format(V));
        V := V::First;
        Observer.Observe('2 inside', Assign1ThenEvalResult(V, '2'));
        Observer.Observe('2 after', Format(V));
        V := V::First;
        ClearLastError();
        Observer.Observe('Nope inside', Assign1ThenEvalResult(V, 'Nope'));
        Observer.Observe('Nope after', Format(V));
        Observer.Observe('Nope last error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_AssignThenEvaluate_TryStatement()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        Seen: Text;
        Ok: Boolean;
    begin
        V := V::First;
        ClearLastError();
        Ok := TryAssign1ThenEval(V, 'Third', Seen);
        Observer.Observe('Third try', Format(Ok));
        Observer.Observe('Third inside', Seen);
        Observer.Observe('Third last error', GetLastErrorText());
        Observer.Observe('Third last code', GetLastErrorCode());
        Observer.Observe('Third after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        ClearLastError();
        Ok := TryAssign1ThenEval(V, 'Nope', Seen);
        Observer.Observe('Nope try', Format(Ok));
        Observer.Observe('Nope inside', Seen);
        Observer.Observe('Nope last error', GetLastErrorText());
        Observer.Observe('Nope last code', GetLastErrorCode());
        Observer.Observe('Nope after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        ClearLastError();
        Ok := TryAssign1ThenEval(V, '', Seen);
        Observer.Observe('empty try', Format(Ok));
        Observer.Observe('empty inside', Seen);
        Observer.Observe('empty last error', GetLastErrorText());
        Observer.Observe('empty last code', GetLastErrorCode());
        Observer.Observe('empty after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_AssignThenEvaluate_Statement()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('inside', Assign1ThenEvalStatement(V, 'Third'));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_Clear_Inside()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('assign then clear inside', AssignThenClear(V));
        Observer.Observe('assign then clear after', Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Observer.Observe('clear only inside', ClearOnly(V));
        Observer.Observe('clear only after', Format(V) + '|' + Format(V, 0, 2));
        V := V::Third;
        Observer.Observe('clear then assign inside', ClearThenAssign1(V));
        Observer.Observe('clear then assign after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_AssignThenHop_Inside()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('hop format', Assign1ThenHopFormat(V));
        Observer.Observe('hop format after', Format(V));
        V := V::First;
        Observer.Observe('hop evaluate', Assign1ThenHopEval(V));
        Observer.Observe('hop evaluate after', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_StoreOtherOption_Inside()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('other members inside', StoreOtherMembers(V));
        Observer.Observe('other members after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('memberless local inside', StoreMemberlessLocal(V));
        Observer.Observe('memberless local after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('same members inside', StoreSameMembers(V));
        Observer.Observe('same members after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_Global_ReadDuringCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalV := GlobalV::Second;
        Observer.Observe('read only', ReadGlobalInside(GlobalV));
        GlobalV := GlobalV::First;
        Observer.Observe('assign then read', Assign1ReadGlobalInside(GlobalV));
        Observer.Observe('after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessVar_Assign1_CallerReaders()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        Row: Record "OVN Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        X: Variant;
    begin
        V := V::First;
        Assign1(V);
        Observer.Observe('Format 0 1', Format(V, 0, 1));
        Observer.Observe('Format 0 0', Format(V, 0, 0));
        X := V;
        Observer.Observe('Variant', Format(X));
        Row.SetRange(Opt, V);
        Observer.Observe('SetRange GetFilter', Row.GetFilter(Opt));
        Row.SetFilter(Opt, '%1', V);
        Observer.Observe('SetFilter GetFilter', Row.GetFilter(Opt));
        Row.Opt := V;
        Observer.Observe('field assign', Format(Row.Opt));
        Row.Validate(OptCap, V);
        Observer.Observe('Validate caption field', Format(Row.OptCap));
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(2);
        FldRef.Value := V;
        Observer.Observe('FieldRef Value', Format(FldRef.Value));
        FldRef.SetRange(V);
        Observer.Observe('FieldRef SetRange', FldRef.GetFilter());
        FldRef.SetFilter('%1', V);
        Observer.Observe('FieldRef SetFilter', FldRef.GetFilter());
        Observer.Finish();
    end;

    [Test]
    procedure MembersVar_HandOnToMemberless_SameMembers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('level 1', Level1SameMembers(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('level 1 evaluate', Level1SameMembersEval(V));
        Observer.Observe('after evaluate', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MembersVar_HandOnToMemberless_OtherMembers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('level 1', Level1OtherMembers(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MembersVar_HandOnToMemberless_OtherMembersEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('evaluate C', Level1OtherMembersEval(V, 'C'));
        Observer.Observe('after C', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('evaluate Third', Level1OtherMembersEval(V, 'Third'));
        Observer.Observe('after Third', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('evaluate 2', Level1OtherMembersEval(V, '2'));
        Observer.Observe('after 2', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarRecordParam_FieldToMemberless()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Row";
    begin
        Row.Opt := Row.Opt::Second;
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('inside', VarRecordFields(Row));
        Observer.Observe('after field', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Observe('after caption field', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarRecordParam_CaptionFieldEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Row";
    begin
        Row.OptCap := Row.OptCap::First;
        Observer.Observe('caption Three', VarRecordCaptionEval(Row, 'Three'));
        Observer.Observe('after Three', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Observer.Observe('name Second', VarRecordCaptionEval(Row, 'Second'));
        Observer.Observe('after Second', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure RecField_OwnTableProcedure_ToMemberless()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Row";
    begin
        Row.Opt := Row.Opt::Second;
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('via other codeunit', Row.FieldsViaLib());
        Observer.Observe('after lib field', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Observe('after lib caption field', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.Opt := Row.Opt::Second;
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('via table procedure', Row.FieldsViaOwnProcedure());
        Observer.Observe('after own field', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Observe('after own caption field', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarArray_StoreOtherOption()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::First;
        Observer.Observe('other members inside', ArrayStoreOtherMembers(Arr));
        Observer.Observe('other members after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Arr[1] := Arr[1]::First;
        Observer.Observe('memberless local inside', ArrayStoreMemberlessLocal(Arr));
        Observer.Observe('memberless local after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Arr[1] := Arr[1]::First;
        Observer.Observe('same members inside', ArrayStoreSameMembers(Arr));
        Observer.Observe('same members after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarArray_ClearArray()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('inside', ArrayClearAll(Arr));
        Observer.Observe('after 1', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Observe('after 2', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarArray_ClearElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('inside', ArrayClearElement(Arr));
        Observer.Observe('after 1', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Observe('after 2', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarArray_CopyArray()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('copy out', ArrayCopyOut(Arr));
        Observer.Observe('after copy out', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Observe('copy in', ArrayCopyIn(Arr));
        Observer.Observe('after copy in 1', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Observe('after copy in 2', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure LocalArray_CopyToMemberless()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        Arr1: array[2] of Option;
    begin
        Arr[1] := Arr[1]::Second;
        CopyArray(Arr1, Arr, 1);
        Observer.Observe('CopyArray read', Format(Arr1[1]) + '|' + Format(Arr1[1], 0, 2));
        Arr1[1] := 1;
        Observer.Observe('CopyArray store', Format(Arr1[1]) + '|' + Format(Arr1[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure ByValueArray_Memberless()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Observer.Observe('inside', ByValueArrayStore(Arr));
        Observer.Observe('after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    local procedure FormatInsideVar(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure EvalResultInside(var Value: Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure Assign1(var Value: Option)
    begin
        Value := 1;
    end;

    local procedure Assign1ThenFormat(var Value: Option): Text
    begin
        Value := 1;
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure Assign1ThenEvalResult(var Value: Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Value := 1;
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;

    [TryFunction]
    local procedure TryAssign1ThenEval(var Value: Option; T: Text; var Seen: Text)
    begin
        Seen := 'not reached';
        Value := 1;
        Evaluate(Value, T);
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;

    local procedure Assign1ThenEvalStatement(var Value: Option; T: Text): Text
    begin
        Value := 1;
        Evaluate(Value, T);
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure AssignThenClear(var Value: Option): Text
    begin
        Value := 1;
        Clear(Value);
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure ClearOnly(var Value: Option): Text
    begin
        Clear(Value);
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure ClearThenAssign1(var Value: Option): Text
    begin
        Clear(Value);
        Value := 1;
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure Assign1ThenHopFormat(var Value: Option): Text
    begin
        Value := 1;
        exit(FormatInsideVar(Value));
    end;

    local procedure Assign1ThenHopEval(var Value: Option): Text
    begin
        Value := 1;
        exit(EvalResultInside(Value, 'Third'));
    end;

    local procedure StoreOtherMembers(var Value: Option): Text
    var
        Other: Option P,Q,R;
    begin
        Other := Other::R;
        Value := Other;
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure StoreMemberlessLocal(var Value: Option): Text
    var
        M: Option;
    begin
        M := 2;
        Value := M;
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure StoreSameMembers(var Value: Option): Text
    var
        Same: Option First,Second,Third;
    begin
        Same := Same::Third;
        Value := Same;
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure ReadGlobalInside(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
    end;

    local procedure Assign1ReadGlobalInside(var Value: Option): Text
    begin
        Value := 1;
        exit(Format(Value) + '|' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
    end;

    local procedure Level1SameMembers(var Value: Option First,Second,Third): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideVar(Value) + '#' + Format(Value);
        Value := Value::First;
        Assign1(Value);
        Seen += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Seen += '#' + Assign1ThenFormat(Value) + '#' + Format(Value);
        exit(Seen);
    end;

    local procedure Level1SameMembersEval(var Value: Option First,Second,Third): Text
    begin
        exit(EvalResultInside(Value, 'Third') + '#' + Format(Value));
    end;

    local procedure Level1OtherMembers(var Value: Option A,B,C): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideVar(Value) + '#' + Format(Value);
        Value := Value::A;
        Assign1(Value);
        Seen += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::A;
        Seen += '#' + Assign1ThenFormat(Value) + '#' + Format(Value);
        exit(Seen);
    end;

    local procedure Level1OtherMembersEval(var Value: Option A,B,C; T: Text): Text
    begin
        exit(EvalResultInside(Value, T) + '#' + Format(Value));
    end;

    local procedure VarRecordFields(var R: Record "OVN Row"): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideVar(R.Opt) + '#' + FormatInsideVar(R.OptCap);
        R.Opt := R.Opt::First;
        R.OptCap := R.OptCap::Third;
        Assign1(R.Opt);
        Assign1(R.OptCap);
        Seen += '#' + Format(R.Opt) + '#' + Format(R.OptCap);
        R.Opt := R.Opt::First;
        R.OptCap := R.OptCap::First;
        Seen += '#' + Assign1ThenFormat(R.Opt) + '#' + Assign1ThenFormat(R.OptCap);
        exit(Seen);
    end;

    local procedure VarRecordCaptionEval(var R: Record "OVN Row"; T: Text): Text
    begin
        exit(EvalResultInside(R.OptCap, T) + '#' + Format(R.OptCap));
    end;

    local procedure ArrayStoreOtherMembers(var A: array[2] of Option): Text
    var
        Other: Option P,Q,R;
    begin
        Other := Other::R;
        A[1] := Other;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ArrayStoreMemberlessLocal(var A: array[2] of Option): Text
    var
        M: Option;
    begin
        M := 2;
        A[1] := M;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ArrayStoreSameMembers(var A: array[2] of Option): Text
    var
        Same: Option First,Second,Third;
    begin
        Same := Same::Third;
        A[1] := Same;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ArrayClearAll(var A: array[2] of Option): Text
    var
        Seen: Text;
    begin
        Clear(A);
        Seen := Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[1] := 1;
        Seen += '#' + Format(A[1]) + '|' + Format(A[1], 0, 2);
        exit(Seen);
    end;

    local procedure ArrayClearElement(var A: array[2] of Option): Text
    var
        Seen: Text;
    begin
        Clear(A[1]);
        Seen := Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[1] := 1;
        Seen += '#' + Format(A[1]) + '|' + Format(A[1], 0, 2);
        exit(Seen);
    end;

    local procedure ArrayCopyOut(var A: array[2] of Option): Text
    var
        B: array[2] of Option;
        Seen: Text;
    begin
        CopyArray(B, A, 1);
        Seen := Format(B[1]) + '|' + Format(B[1], 0, 2);
        B[1] := 1;
        Seen += '#' + Format(B[1]) + '|' + Format(B[1], 0, 2);
        exit(Seen);
    end;

    local procedure ArrayCopyIn(var A: array[2] of Option): Text
    var
        Src: array[2] of Option;
    begin
        Src[1] := 2;
        Src[2] := 1;
        CopyArray(A, Src, 1);
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2));
    end;

    local procedure ByValueArrayStore(A: array[2] of Option): Text
    var
        Seen: Text;
    begin
        Seen := Format(A[1]) + '|' + Format(A[1], 0, 2);
        A[1] := 2;
        Seen += '#' + Format(A[1]) + '|' + Format(A[1], 0, 2);
        exit(Seen);
    end;
}
