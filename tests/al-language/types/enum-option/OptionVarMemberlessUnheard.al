// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75270..75276 and the interface OVU Formatter (OVU Row,
//   OVU Publisher, OVU Subscriber, OVU Formatter Impl, OVU Unheard Callers Tests, OVU Unheard Hand On Tests,
//   OVU Unheard Elem Store Tests)
// local object: an Option variable handed to a var parameter of an event publisher that no subscriber hears is what is
//   under test.
// Probe (al-runner PR 8299, follow-up of OptionVarMemberlessWrites.al): FACTS TO BE FILLED AFTER OBSERVATION.
table 75270 "OVU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = First,Second,Third; }
        field(3; OptCap; Option) { OptionMembers = First,Second,Third; OptionCaption = 'One,Two,Three'; }
        field(4; OptPQR; Option) { OptionMembers = P,Q,R; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Raises the events. No subscriber in the app hears OnUnheardMembers, OnUnheardMemberless, OnUnheardSame and
// OnUnheardArr; OVU Subscriber hears OnHeardMemberless.
codeunit 75271 "OVU Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnUnheardMembers(var Value: Option P,Q,R)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUnheardMemberless(var Value: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUnheardSame(var Value: Option First,Second,Third)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUnheardArr(var A: array[2] of Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnHeardMemberless(var Value: Option; var Seen: Text)
    begin
    end;
}

codeunit 75272 "OVU Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVU Publisher", 'OnHeardMemberless', '', false, false)]
    local procedure HandleHeardMemberless(var Value: Option; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;
}

interface "OVU Formatter"
{
    procedure FormatInside(var Value: Option): Text;
}

codeunit 75273 "OVU Formatter Impl" implements "OVU Formatter"
{
    procedure FormatInside(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;
}

// Facts: see the header of the file.
codeunit 75274 "OVU Unheard Callers Tests"
{
    Subtype = Test;

    var
        Pub: Codeunit "OVU Publisher";
        GlobalV: Option First,Second,Third;
        GlobalArr: array[2] of Option First,Second,Third;

    [Test]
    procedure Local_UnheardPublishers_CallerAfter()
    var
        Observer: Codeunit "Probe Observer";
        V1: Option First,Second,Third;
        V2: Option First,Second,Third;
        V3: Option First,Second,Third;
        V4: Option First,Second,Third;
        V5: Option First,Second,Third;
        V6: Option First,Second,Third;
        V7: Option First,Second,Third;
        V8: Option First,Second,Third;
        V9: Option First,Second,Third;
        Ok: Boolean;
    begin
        V1 := V1::Second;
        Pub.OnUnheardMembers(V1);
        Observer.Observe('members P,Q,R', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := V2::Second;
        Pub.OnUnheardMemberless(V2);
        Observer.Observe('memberless', Format(V2) + '|' + Format(V2, 0, 2));
        V3 := V3::Second;
        Pub.OnUnheardSame(V3);
        Observer.Observe('same members', Format(V3) + '|' + Format(V3, 0, 2));
        V4 := V4::Second;
        Pub.OnUnheardMemberless(V4);
        Observer.Observe('memberless, then', Format(V4) + '|' + Format(V4, 0, 2));
        Pub.OnUnheardMembers(V4);
        Observer.Observe('then members P,Q,R', Format(V4) + '|' + Format(V4, 0, 2));
        V5 := V5::Second;
        Pub.OnUnheardMembers(V5);
        V5 := 2;
        Observer.Observe('members P,Q,R then V := 2', Format(V5) + '|' + Format(V5, 0, 2));
        V6 := V6::Second;
        Pub.OnUnheardMembers(V6);
        V6 := V6::Third;
        Observer.Observe('members P,Q,R then V := V::Third', Format(V6) + '|' + Format(V6, 0, 2));
        V7 := V7::Second;
        Pub.OnUnheardMembers(V7);
        Ok := Evaluate(V7, 'Third');
        Observer.Observe('members P,Q,R then Evaluate Third', Format(Ok) + '|' + Format(V7) + '|' + Format(V7, 0, 2));
        V8 := V8::Second;
        Pub.OnUnheardMembers(V8);
        Ok := Evaluate(V8, 'R');
        Observer.Observe('members P,Q,R then Evaluate R', Format(Ok) + '|' + Format(V8) + '|' + Format(V8, 0, 2));
        V9 := V9::First;
        Pub.OnUnheardMembers(V9);
        Observer.Observe('members P,Q,R from First', Format(V9) + '|' + Format(V9, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure Global_UnheardPublishers_CallerAfter()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        GlobalV := GlobalV::Second;
        Pub.OnUnheardMemberless(GlobalV);
        T := Format(GlobalV) + '|' + Format(GlobalV, 0, 2);
        Pub.OnUnheardMembers(GlobalV);
        T += '>' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2);
        Observer.Observe('memberless then members P,Q,R', T);
        GlobalV := GlobalV::Second;
        Pub.OnUnheardMembers(GlobalV);
        T := Format(GlobalV) + '|' + Format(GlobalV, 0, 2);
        Observer.Observe('members P,Q,R', T);
        GlobalV := GlobalV::Second;
        Pub.OnUnheardMembers(GlobalV);
        GlobalV := 2;
        Observer.Observe('members P,Q,R then V := 2', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure ByValueParameter_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::First;
        Observer.Observe('memberless then members P,Q,R', ByValueTShape(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure Fields_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVU Row";
        T: Text;
    begin
        Row.Opt := Row.Opt::Second;
        Pub.OnUnheardMemberless(Row.Opt);
        T := Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2);
        Pub.OnUnheardMembers(Row.Opt);
        T += '>' + Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2);
        Observer.Observe('field memberless then members P,Q,R', T);
        Row.OptCap := Row.OptCap::Second;
        Pub.OnUnheardMemberless(Row.OptCap);
        T := Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2);
        Pub.OnUnheardMembers(Row.OptCap);
        T += '>' + Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2);
        Observer.Observe('caption field memberless then members P,Q,R', T);
        Row.OptPQR := Row.OptPQR::Q;
        Pub.OnUnheardSame(Row.OptPQR);
        Observer.Observe('field P,Q,R to publisher First,Second,Third', Format(Row.OptPQR) + '|' + Format(Row.OptPQR, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure ArrayElements_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        Arr0: array[2] of Option;
        T: Text;
    begin
        Arr[1] := Arr[1]::Second;
        Pub.OnUnheardMemberless(Arr[1]);
        T := Format(Arr[1]) + '|' + Format(Arr[1], 0, 2);
        Pub.OnUnheardMembers(Arr[1]);
        T += '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2);
        Observer.Observe('local element memberless then members P,Q,R', T);
        GlobalArr[1] := GlobalArr[1]::Second;
        Pub.OnUnheardMemberless(GlobalArr[1]);
        T := Format(GlobalArr[1]) + '|' + Format(GlobalArr[1], 0, 2);
        Pub.OnUnheardMembers(GlobalArr[1]);
        T += '>' + Format(GlobalArr[1]) + '|' + Format(GlobalArr[1], 0, 2);
        Observer.Observe('global element memberless then members P,Q,R', T);
        Arr[1] := Arr[1]::Second;
        CopyArray(Arr0, Arr, 1);
        Pub.OnUnheardMemberless(Arr0[1]);
        T := Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2);
        Pub.OnUnheardMembers(Arr0[1]);
        T += '>' + Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2);
        Observer.Observe('CopyArray filled memberless element', T);
        Arr[1] := Arr[1]::Second;
        Pub.OnUnheardArr(Arr);
        Observer.Observe('whole array to memberless array publisher', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure ArrayParameters_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Observer.Observe('var memberless array element, inside', VarArrayElementTShape(Arr));
        Observer.Observe('var memberless array element, caller after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        Observer.Observe('by-value memberless array element, inside', ByValueArrayElementTShape(Arr));
        Observer.Observe('by-value memberless array element, caller after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        Observer.Observe('whole var memberless array, inside', VarArrayWhole(Arr));
        Observer.Observe('whole var memberless array, caller after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        Observer.Observe('var memberless array, A[1] unheard then A[2] := 2, inside', VarArrayMixed(Arr));
        Observer.Observe('var memberless array, A[1] unheard then A[2] := 2, caller after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarRecordField_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVU Row";
    begin
        Row.OptPQR := Row.OptPQR::Q;
        Observer.Observe('var record field P,Q,R, inside', VarRecordField(Row));
        Observer.Observe('var record field P,Q,R, caller after', Format(Row.OptPQR) + '|' + Format(Row.OptPQR, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessLocal_UnheardPublisher()
    var
        Observer: Codeunit "Probe Observer";
        V0: Option;
        W0: Option;
        Ok: Boolean;
    begin
        V0 := 1;
        Pub.OnUnheardMembers(V0);
        Observer.Observe('memberless local 1 to members P,Q,R', Format(V0) + '|' + Format(V0, 0, 2));
        W0 := 1;
        Pub.OnUnheardMembers(W0);
        Ok := Evaluate(W0, 'R');
        Observer.Observe('then Evaluate R', Format(Ok) + '|' + Format(W0) + '|' + Format(W0, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure VarParameters_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        V0: Option;
    begin
        V := V::Second;
        Observer.Observe('var parameter First,Second,Third, inside', VarParamMembersTShape(V));
        Observer.Observe('var parameter First,Second,Third, caller after', Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Observer.Observe('memberless var parameter holding Second, inside', VarParamMemberlessTShape(V));
        Observer.Observe('memberless var parameter holding Second, caller after', Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        Observer.Observe('memberless var parameter holding memberless 1, inside', VarParamMemberlessMembers(V0));
        Observer.Observe('memberless var parameter holding memberless 1, caller after', Format(V0) + '|' + Format(V0, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure NamedReturn_UnheardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        T: Text;
    begin
        V := NamedReturnTShape(T);
        Observer.Observe('named return value, inside', T);
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure OtherMembersParameter_HandsOnToUnheard()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        V0: Option;
        T: Text;
    begin
        V := V::Second;
        T := OtherParamMembers(V);
        Observer.Observe('X,Y,Z parameter to members P,Q,R', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        T := OtherParamMemberless(V);
        Observer.Observe('X,Y,Z parameter to memberless', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        T := OtherParamMembers(V0);
        Observer.Observe('memberless caller, X,Y,Z parameter to members P,Q,R', T + '>' + Format(V0) + '|' + Format(V0, 0, 2));
        Observer.Observe('by-value caller, X,Y,Z parameter to members P,Q,R', ByValueOuter(V));
        V := V::Second;
        T := OtherParamSame(V);
        Observer.Observe('X,Y,Z parameter to members First,Second,Third', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        T := OtherParamNoPublisher(V);
        Observer.Observe('X,Y,Z parameter, no publisher', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        T := OtherParamMembersThenZ(V);
        Observer.Observe('X,Y,Z parameter to members P,Q,R then P := P::Z', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        GlobalV := GlobalV::Second;
        T := OtherParamMembers(GlobalV);
        Observer.Observe('global caller, X,Y,Z parameter to members P,Q,R', T + '>' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Finish();
    end;

    local procedure ByValueTShape(P: Option First,Second,Third) T: Text
    begin
        P := P::Second;
        Pub.OnUnheardMemberless(P);
        T := Format(P) + '|' + Format(P, 0, 2);
        Pub.OnUnheardMembers(P);
        T += '>' + Format(P) + '|' + Format(P, 0, 2);
    end;

    local procedure VarArrayElementTShape(var A: array[2] of Option) T: Text
    begin
        Pub.OnUnheardMemberless(A[1]);
        T := Format(A[1]) + '|' + Format(A[1], 0, 2);
        Pub.OnUnheardMembers(A[1]);
        T += '>' + Format(A[1]) + '|' + Format(A[1], 0, 2);
    end;

    local procedure ByValueArrayElementTShape(A: array[2] of Option) T: Text
    begin
        Pub.OnUnheardMemberless(A[1]);
        T := Format(A[1]) + '|' + Format(A[1], 0, 2);
        Pub.OnUnheardMembers(A[1]);
        T += '>' + Format(A[1]) + '|' + Format(A[1], 0, 2);
    end;

    local procedure VarArrayWhole(var A: array[2] of Option): Text
    begin
        Pub.OnUnheardArr(A);
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure VarArrayMixed(var A: array[2] of Option): Text
    begin
        Pub.OnUnheardMembers(A[1]);
        A[2] := 2;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2));
    end;

    local procedure VarRecordField(var Row: Record "OVU Row") T: Text
    begin
        Pub.OnUnheardMemberless(Row.OptPQR);
        T := Format(Row.OptPQR) + '|' + Format(Row.OptPQR, 0, 2);
        Pub.OnUnheardSame(Row.OptPQR);
        T += '>' + Format(Row.OptPQR) + '|' + Format(Row.OptPQR, 0, 2);
    end;

    local procedure VarParamMembersTShape(var P: Option First,Second,Third) T: Text
    begin
        Pub.OnUnheardMemberless(P);
        T := Format(P) + '|' + Format(P, 0, 2);
        Pub.OnUnheardMembers(P);
        T += '>' + Format(P) + '|' + Format(P, 0, 2);
    end;

    local procedure VarParamMemberlessTShape(var P: Option) T: Text
    begin
        Pub.OnUnheardMemberless(P);
        T := Format(P) + '|' + Format(P, 0, 2);
        Pub.OnUnheardMembers(P);
        T += '>' + Format(P) + '|' + Format(P, 0, 2);
    end;

    local procedure VarParamMemberlessMembers(var P: Option): Text
    begin
        Pub.OnUnheardMembers(P);
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure NamedReturnTShape(var T: Text) R: Option First,Second,Third
    begin
        R := R::Second;
        Pub.OnUnheardMemberless(R);
        T := Format(R) + '|' + Format(R, 0, 2);
        Pub.OnUnheardMembers(R);
        T += '>' + Format(R) + '|' + Format(R, 0, 2);
    end;

    local procedure OtherParamMembers(var P: Option X,Y,Z): Text
    begin
        Pub.OnUnheardMembers(P);
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure OtherParamMemberless(var P: Option X,Y,Z): Text
    begin
        Pub.OnUnheardMemberless(P);
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure OtherParamSame(var P: Option X,Y,Z): Text
    begin
        Pub.OnUnheardSame(P);
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure OtherParamNoPublisher(var P: Option X,Y,Z): Text
    begin
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure OtherParamMembersThenZ(var P: Option X,Y,Z): Text
    begin
        Pub.OnUnheardMembers(P);
        P := P::Z;
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure ByValueOuter(BV: Option First,Second,Third): Text
    var
        T: Text;
    begin
        BV := BV::Second;
        T := OtherParamMembers(BV);
        exit(T + '>' + Format(BV) + '|' + Format(BV, 0, 2));
    end;
}

codeunit 75275 "OVU Unheard Hand On Tests"
{
    Subtype = Test;

    var
        Pub: Codeunit "OVU Publisher";
        GlobalV: Option First,Second,Third;
        Inside: Text;

    [Test]
    procedure Local_AfterUnheard_ToMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        V0: Option;
        Formatter: Interface "OVU Formatter";
        Impl: Codeunit "OVU Formatter Impl";
        T: Text;
    begin
        V := V::Second;
        T := FormatInside(V);
        Observer.Observe('no publisher (control): inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := Format(V) + '|' + Format(V, 0, 2);
        T += '>' + FormatInside(V);
        Observer.Observe('members P,Q,R: before>inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMemberless(V);
        T := Format(V) + '|' + Format(V, 0, 2);
        T += '>' + FormatInside(V);
        Observer.Observe('memberless: before>inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        Pub.OnUnheardMembers(V0);
        T := Format(V0) + '|' + Format(V0, 0, 2);
        T += '>' + FormatInside(V0);
        Observer.Observe('memberless local, members P,Q,R: before>inside>after', T + '>' + Format(V0) + '|' + Format(V0, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := OtherMembersInside(V);
        Observer.Observe('members P,Q,R, then X,Y,Z parameter: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        Formatter := Impl;
        T := Formatter.FormatInside(V);
        Observer.Observe('members P,Q,R, then interface method: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        GlobalV := GlobalV::Second;
        Pub.OnUnheardMembers(GlobalV);
        T := FormatInside(GlobalV);
        Observer.Observe('global, members P,Q,R: inside>after', T + '>' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := RaiseHeard(V);
        Observer.Observe('members P,Q,R, then heard memberless publisher: subscriber>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure Local_AfterUnheard_StoresInMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        T: Text;
    begin
        V := V::Second;
        T := Store2(V);
        Observer.Observe('no publisher (control), Value := 2: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := Store2(V);
        Observer.Observe('members P,Q,R, Value := 2: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMemberless(V);
        T := Store2(V);
        Observer.Observe('memberless, Value := 2: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure Local_AfterUnheard_EvaluateInMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        T: Text;
    begin
        V := V::Second;
        T := EvaluateUsed(V, 'Third');
        Observer.Observe('no publisher (control), Evaluate Third result used: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        T := EvaluateUsed(V, 'Q');
        Observer.Observe('no publisher (control), Evaluate Q result used: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := EvaluateUsed(V, 'Third');
        Observer.Observe('members P,Q,R, Evaluate Third result used: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := EvaluateUsed(V, 'Q');
        Observer.Observe('members P,Q,R, Evaluate Q result used: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := EvaluateUsed(V, 'R');
        Observer.Observe('members P,Q,R, Evaluate R result used: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMemberless(V);
        T := EvaluateUsed(V, 'Third');
        Observer.Observe('memberless, Evaluate Third result used: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure Local_AfterUnheard_EvaluateStatementInMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        T: Text;
    begin
        V := V::Second;
        T := EvaluateStatementOutcome(V, 'Third');
        Observer.Observe('no publisher (control), Evaluate Third statement: outcome>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        T := EvaluateStatementOutcome(V, 'Q');
        Observer.Observe('no publisher (control), Evaluate Q statement: outcome>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := EvaluateStatementOutcome(V, 'Third');
        Observer.Observe('members P,Q,R, Evaluate Third statement: outcome>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Pub.OnUnheardMembers(V);
        T := EvaluateStatementOutcome(V, 'Q');
        Observer.Observe('members P,Q,R, Evaluate Q statement: outcome>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessParameter_AfterUnheard_HandsOn()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        V0: Option;
        T: Text;
    begin
        V := V::Second;
        T := MemberlessParamUnheardThenHandOn(V);
        Observer.Observe('memberless var parameter holding Second: inside~handed on>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        T := MemberlessParamUnheardThenHandOn(V0);
        Observer.Observe('memberless var parameter holding memberless 1: inside~handed on>after', T + '>' + Format(V0) + '|' + Format(V0, 0, 2));
        V := V::Second;
        T := MemberlessParamUnheardThenStore2(V);
        Observer.Observe('memberless var parameter holding Second, then Value := 2: inside>after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('by-value parameter First,Second,Third: inside~handed on', ByValueUnheardThenHandOn(V));
        V := NamedReturnUnheardThenHandOn(T);
        Observer.Observe('named return value First,Second,Third: inside~handed on', T);
        Observer.Observe('named return value, caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Finish();
    end;

    local procedure FormatInside(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure OtherMembersInside(var Value: Option X,Y,Z): Text
    begin
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure RaiseHeard(var Value: Option): Text
    var
        Seen: Text;
    begin
        Pub.OnHeardMemberless(Value, Seen);
        exit(Seen);
    end;

    local procedure Store2(var Value: Option): Text
    begin
        Value := 2;
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure EvaluateUsed(var Value: Option; Input: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, Input);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure EvaluateStatementOutcome(var Value: Option; Input: Text): Text
    begin
        Inside := 'not reached';
        ClearLastError();
        if TryEvaluateStatement(Value, Input) then
            exit('no error|' + Inside);
        exit('error ' + GetLastErrorText() + '|' + Inside);
    end;

    [TryFunction]
    local procedure TryEvaluateStatement(var Value: Option; Input: Text)
    begin
        Inside := 'before';
        Evaluate(Value, Input);
        Inside := Format(Value) + '|' + Format(Value, 0, 2);
    end;

    local procedure MemberlessParamUnheardThenHandOn(var P: Option): Text
    begin
        Pub.OnUnheardMembers(P);
        exit(Format(P) + '|' + Format(P, 0, 2) + '~' + FormatInside(P));
    end;

    local procedure MemberlessParamUnheardThenStore2(var P: Option): Text
    begin
        Pub.OnUnheardMembers(P);
        P := 2;
        exit(Format(P) + '|' + Format(P, 0, 2));
    end;

    local procedure ByValueUnheardThenHandOn(BV: Option First,Second,Third): Text
    begin
        BV := BV::Second;
        Pub.OnUnheardMembers(BV);
        exit(Format(BV) + '|' + Format(BV, 0, 2) + '~' + FormatInside(BV));
    end;

    local procedure NamedReturnUnheardThenHandOn(var T: Text) R: Option First,Second,Third
    begin
        R := R::Second;
        Pub.OnUnheardMembers(R);
        T := Format(R) + '|' + Format(R, 0, 2) + '~' + FormatInside(R);
    end;
}

codeunit 75276 "OVU Unheard Elem Store Tests"
{
    Subtype = Test;

    var
        Pub: Codeunit "OVU Publisher";
        GlobalPQR: Option P,Q,R;
        GlobalMemberless: Option;

    [Test]
    procedure ByValueParameter_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := ByValuePQR(Arr);
        Observer.Observe('by-value parameter PQR: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := ByValueMemberless(Arr);
        Observer.Observe('by-value parameter Memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := ByValueSame(Arr);
        Observer.Observe('by-value parameter Same: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure NamedReturn_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := NamedReturnPQR(Arr);
        Observer.Observe('named return value PQR: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := NamedReturnMemberless(Arr);
        Observer.Observe('named return value Memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := NamedReturnSame(Arr);
        Observer.Observe('named return value Same: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure FunctionResult_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := FunctionResultPQR(Arr);
        Observer.Observe('function result PQR: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := FunctionResultMemberless(Arr);
        Observer.Observe('function result Memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := FunctionResultSame(Arr);
        Observer.Observe('function result Same: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure LocalArrayElement_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := LocalArrayElementPQR(Arr);
        Observer.Observe('local array element PQR: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := LocalArrayElementMemberless(Arr);
        Observer.Observe('local array element Memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := LocalArrayElementSame(Arr);
        Observer.Observe('local array element Same: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure OptionConstant_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := ConstantPQR(Arr);
        Observer.Observe('constant L::R of Option P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := ConstantSame(Arr);
        Observer.Observe('constant L::Third of Option First,Second,Third: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure OtherSources_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := GlobalPQRSource(Arr);
        Observer.Observe('global P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := GlobalMemberlessSource(Arr);
        Observer.Observe('global memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := FieldPQRSource(Arr);
        Observer.Observe('record field P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := VarParamPQRSource(Arr);
        Observer.Observe('var parameter P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := ParenLocalSource(Arr);
        Observer.Observe('parenthesized local P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure LocalAfterUnheard_ToVarMemberlessElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        T: Text;
    begin
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := MemberlessLocalUnheardPQR(Arr);
        Observer.Observe('memberless local 2, unheard members P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := MemberlessLocalUnheardSame(Arr);
        Observer.Observe('memberless local 2, unheard members First,Second,Third: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := MemberlessLocalUnheardMemberless(Arr);
        Observer.Observe('memberless local 2, unheard memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := MemberlessLocalNoPublisher(Arr);
        Observer.Observe('memberless local 2, no publisher (control): inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := SameLocalUnheardPQR(Arr);
        Observer.Observe('local First,Second,Third Third, unheard members P,Q,R: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := SameLocalNoPublisher(Arr);
        Observer.Observe('local First,Second,Third Third, no publisher (control): inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := PQRLocalUnheardMemberless(Arr);
        Observer.Observe('local P,Q,R R, unheard memberless: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := PQRLocalUnheardSame(Arr);
        Observer.Observe('local P,Q,R R, unheard members First,Second,Third: inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Clear(Arr);
        Arr[1] := Arr[1]::Second;
        T := PQRLocalNoPublisher(Arr);
        Observer.Observe('local P,Q,R R, no publisher (control): inside>caller after', T + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure MemberlessLocalArray_FromOptionsWithMembers()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        Arr0: array[2] of Option;
        O: Option P,Q,R;
    begin
        O := O::R;
        Arr0[1] := O;
        Observer.Observe('local P,Q,R into local memberless array', Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2));
        GlobalPQR := GlobalPQR::R;
        Arr0[1] := GlobalPQR;
        Observer.Observe('global P,Q,R into local memberless array', Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2));
        Arr[2] := Arr[2]::Third;
        Arr0[1] := Arr[2];
        Observer.Observe('element First,Second,Third into local memberless array', Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2));
        Observer.Finish();
    end;

    local procedure ByValuePQR(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        exit(ByValuePQRStore(A, L));
    end;

    local procedure ByValuePQRStore(var A: array[2] of Option; BV: Option P,Q,R): Text
    begin
        A[1] := BV;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure NamedReturnPQR(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := NamedReturnPQRStore(A);
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure NamedReturnPQRStore(var A: array[2] of Option) Ret: Option P,Q,R
    begin
        Ret := Ret::R;
        A[1] := Ret;
    end;

    local procedure FunctionResultPQR(var A: array[2] of Option): Text
    begin
        A[1] := MakePQR();
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MakePQR(): Option P,Q,R
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        exit(L);
    end;

    local procedure LocalArrayElementPQR(var A: array[2] of Option): Text
    var
        LA: array[2] of Option P,Q,R;
    begin
        LA[2] := LA[2]::R;
        A[1] := LA[2];
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ByValueMemberless(var A: array[2] of Option): Text
    var
        L: Option;
    begin
        L := 2;
        exit(ByValueMemberlessStore(A, L));
    end;

    local procedure ByValueMemberlessStore(var A: array[2] of Option; BV: Option): Text
    begin
        A[1] := BV;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure NamedReturnMemberless(var A: array[2] of Option): Text
    var
        L: Option;
    begin
        L := NamedReturnMemberlessStore(A);
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure NamedReturnMemberlessStore(var A: array[2] of Option) Ret: Option
    begin
        Ret := 2;
        A[1] := Ret;
    end;

    local procedure FunctionResultMemberless(var A: array[2] of Option): Text
    begin
        A[1] := MakeMemberless();
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MakeMemberless(): Option
    var
        L: Option;
    begin
        L := 2;
        exit(L);
    end;

    local procedure LocalArrayElementMemberless(var A: array[2] of Option): Text
    var
        LA: array[2] of Option;
    begin
        LA[2] := 2;
        A[1] := LA[2];
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ByValueSame(var A: array[2] of Option): Text
    var
        L: Option First,Second,Third;
    begin
        L := L::Third;
        exit(ByValueSameStore(A, L));
    end;

    local procedure ByValueSameStore(var A: array[2] of Option; BV: Option First,Second,Third): Text
    begin
        A[1] := BV;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure NamedReturnSame(var A: array[2] of Option): Text
    var
        L: Option First,Second,Third;
    begin
        L := NamedReturnSameStore(A);
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure NamedReturnSameStore(var A: array[2] of Option) Ret: Option First,Second,Third
    begin
        Ret := Ret::Third;
        A[1] := Ret;
    end;

    local procedure FunctionResultSame(var A: array[2] of Option): Text
    begin
        A[1] := MakeSame();
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MakeSame(): Option First,Second,Third
    var
        L: Option First,Second,Third;
    begin
        L := L::Third;
        exit(L);
    end;

    local procedure LocalArrayElementSame(var A: array[2] of Option): Text
    var
        LA: array[2] of Option First,Second,Third;
    begin
        LA[2] := LA[2]::Third;
        A[1] := LA[2];
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ConstantPQR(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        A[1] := L::R;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ConstantSame(var A: array[2] of Option): Text
    var
        L: Option First,Second,Third;
    begin
        A[1] := L::Third;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure GlobalPQRSource(var A: array[2] of Option): Text
    begin
        GlobalPQR := GlobalPQR::R;
        A[1] := GlobalPQR;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure GlobalMemberlessSource(var A: array[2] of Option): Text
    begin
        GlobalMemberless := 2;
        A[1] := GlobalMemberless;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure FieldPQRSource(var A: array[2] of Option): Text
    var
        Row: Record "OVU Row";
    begin
        Row.OptPQR := Row.OptPQR::R;
        A[1] := Row.OptPQR;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure VarParamPQRSource(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        exit(VarParamPQRStore(A, L));
    end;

    local procedure VarParamPQRStore(var A: array[2] of Option; var VP: Option P,Q,R): Text
    begin
        A[1] := VP;
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ParenLocalSource(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        A[1] := (L);
        exit(Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MemberlessLocalUnheardPQR(var A: array[2] of Option): Text
    var
        L: Option;
    begin
        L := 2;
        Pub.OnUnheardMembers(L);
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MemberlessLocalUnheardSame(var A: array[2] of Option): Text
    var
        L: Option;
    begin
        L := 2;
        Pub.OnUnheardSame(L);
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MemberlessLocalUnheardMemberless(var A: array[2] of Option): Text
    var
        L: Option;
    begin
        L := 2;
        Pub.OnUnheardMemberless(L);
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure MemberlessLocalNoPublisher(var A: array[2] of Option): Text
    var
        L: Option;
    begin
        L := 2;
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure SameLocalUnheardPQR(var A: array[2] of Option): Text
    var
        L: Option First,Second,Third;
    begin
        L := L::Third;
        Pub.OnUnheardMembers(L);
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure SameLocalNoPublisher(var A: array[2] of Option): Text
    var
        L: Option First,Second,Third;
    begin
        L := L::Third;
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure PQRLocalUnheardMemberless(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        Pub.OnUnheardMemberless(L);
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure PQRLocalUnheardSame(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        Pub.OnUnheardSame(L);
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure PQRLocalNoPublisher(var A: array[2] of Option): Text
    var
        L: Option P,Q,R;
    begin
        L := L::R;
        A[1] := L;
        exit(Format(L) + '|' + Format(L, 0, 2) + '~' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;
}
