// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); OVN Row (table 75250, OptionVarMemberlessWrites.al); own objects 75252..75254,
//   75256 and the interface OVN Formatter (OVN Publisher, OVN Subscriber, OVN Formatter Impl, OVN Memberless Callers Tests)
// local object: an Option value handed to a var parameter declared without members, from callers other than a local, is
//   what is under test.
// Probe (al-runner issues 7994 and 8291, follow-up of OptionVarMemberLists.al): by-value callers, event subscribers and
//   interface methods with a memberless var Option parameter.
//   Cells: a by-value parameter handed to a memberless var parameter, to a var parameter with other members, to a memberless
//   publisher and to a publisher with members; a by-value array element and a by-value array to a memberless var array; a named
//   return value; fields of a by-value record; a by-value memberless parameter handed to a var parameter with members. Event
//   subscribers without members under a memberless publisher and under a publisher with the caller's members, for a global, a
//   caption field, a local record field, a global record field, a local array element and a var parameter with members.
//   Interface methods with a memberless var Option parameter for a local, a local field, a caption field, a global, a global
//   record field and caption field, a global array element and a var parameter with members.
// Facts: every caller kind here behaves like a local caller. The memberless var parameter shows the caller's member name
//   (Second), or the caption (Two, Three) for a field with OptionCaption. A write (Value := 1 or 2) goes back to the caller and
//   shows the caller's names; Evaluate('Third') succeeds. A by-value parameter with members handed on keeps its members in the
//   callee and in the by-value parameter, and the original caller is unchanged; the same for a by-value array, a by-value array
//   element, a named return value and fields of a by-value record. A by-value parameter handed to a var parameter with members
//   A,B,C shows B; Value := Value::C gives Third. A by-value memberless parameter shows 1; handed to a var parameter with the
//   members First,Second,Third it shows Second there and 1 again after. Events: a memberless subscriber sees Second/1 (caption
//   field Two/1) both under a memberless publisher and under a publisher with the caller's members; its Value := 2 gives the
//   caller Third (caption field Three). Interfaces: inside Second|Second|1 (caption field Two|Two|1), Assign1 gives Second
//   (Two), Evaluate('Third') gives Third (Three).
// BC versions: identical on 28.5 and 29.0 (local Windows BC tiers). 27.5: the local leg did not run (infrastructure); the
//   corpus CI run of the pull request measures it.
// Raises the events: one with a memberless var Option parameter, one whose parameter has the caller's members.
codeunit 75252 "OVN Publisher"
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

codeunit 75253 "OVN Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVN Publisher", 'OnMemberless', '', false, false)]
    local procedure HandleMemberless(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
        if Write then
            Value := 2;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVN Publisher", 'OnWithMembers', '', false, false)]
    local procedure HandleWithMembers(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
        if Write then
            Value := 2;
    end;
}

interface "OVN Formatter"
{
    procedure FormatInside(var Value: Option): Text;
    procedure Assign1(var Value: Option);
    procedure Assign1ThenFormat(var Value: Option): Text;
    procedure EvalResult(var Value: Option; T: Text): Text;
}

codeunit 75254 "OVN Formatter Impl" implements "OVN Formatter"
{
    procedure FormatInside(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    procedure Assign1(var Value: Option)
    begin
        Value := 1;
    end;

    procedure Assign1ThenFormat(var Value: Option): Text
    begin
        Value := 1;
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    procedure EvalResult(var Value: Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;
}

codeunit 75256 "OVN Memberless Callers Tests"
{
    Subtype = Test;

    var
        GlobalV: Option First,Second,Third;
        GlobalRow: Record "OVN Row";
        GlobalArr: array[2] of Option First,Second,Third;
        GSeen: Text;

    [Test]
    procedure ByValueParam_ToMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', ByValueToMemberless(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second#Second|1#Yes|Third|2#Third');
        Observer.Expect('after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueParam_ToOtherMembersVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', ByValueToOtherMembers(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'B|B|1#Second#Third|2');
        Observer.Expect('after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueArrayElement_ToMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Observer.Observe('element', ByValueArrayElementToMemberless(Arr));
        Observer.Observe('after element', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Arr[1] := Arr[1]::Second;
        Observer.Observe('whole array', ByValueArrayToMemberlessArray(Arr));
        Observer.Observe('after whole array', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Observer.Expect('element', 'Second|Second|1#Second#Second|1');
        Observer.Expect('after element', 'Second|1');
        Observer.Expect('whole array', 'Second|Second|1#Third|2#Third|2');
        Observer.Expect('after whole array', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure NamedReturnValue_ToMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        GSeen := '';
        V := ReturnNamed();
        Observer.Observe('inside', GSeen);
        Observer.Observe('returned', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second#Second|1');
        Observer.Expect('returned', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueRecordField_ToMemberlessVar()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Row";
    begin
        Row.Opt := Row.Opt::Second;
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('inside', ByValueRecordFields(Row));
        Observer.Observe('after field', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Observe('after caption field', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Two|Two|1#Second|1#Two|1');
        Observer.Expect('after field', 'Second|1');
        Observer.Expect('after caption field', 'Two|1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueParam_ToPublisher()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('memberless publisher', ByValueToMemberlessPublisher(V));
        Observer.Observe('after memberless publisher', Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Observer.Observe('publisher with members', ByValueToMembersPublisher(V));
        Observer.Observe('after publisher with members', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('memberless publisher', 'Second|1#Second#Third|2');
        Observer.Expect('after memberless publisher', 'Second|1');
        Observer.Expect('publisher with members', 'Second|1#Second#Third|2');
        Observer.Expect('after publisher with members', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueMemberless_ToMembersVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', ByValueMemberlessToMembers(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', '1#Second|Second|1#1');
        Observer.Expect('after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Event_Global_MemberlessPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
    begin
        GlobalV := GlobalV::Second;
        Publisher.RaiseMemberless(GlobalV, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Publisher.RaiseMemberless(GlobalV, true, Seen);
        Observer.Observe('after write 2', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_Global_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
    begin
        GlobalV := GlobalV::Second;
        Publisher.RaiseWithMembers(GlobalV, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Publisher.RaiseWithMembers(GlobalV, true, Seen);
        Observer.Observe('after write 2', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_CaptionField_MemberlessPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Row: Record "OVN Row";
    begin
        Row.OptCap := Row.OptCap::Second;
        Publisher.RaiseMemberless(Row.OptCap, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Publisher.RaiseMemberless(Row.OptCap, true, Seen);
        Observer.Observe('after write 2', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('subscriber saw', 'Two|1');
        Observer.Expect('after', 'Two|1');
        Observer.Expect('after write 2', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_CaptionField_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Row: Record "OVN Row";
    begin
        Row.OptCap := Row.OptCap::Second;
        Publisher.RaiseWithMembers(Row.OptCap, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Publisher.RaiseWithMembers(Row.OptCap, true, Seen);
        Observer.Observe('after write 2', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('subscriber saw', 'Two|1');
        Observer.Expect('after', 'Two|1');
        Observer.Expect('after write 2', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_LocalField_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Row: Record "OVN Row";
    begin
        Row.Opt := Row.Opt::Second;
        Publisher.RaiseWithMembers(Row.Opt, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::First;
        Publisher.RaiseWithMembers(Row.Opt, true, Seen);
        Observer.Observe('after write 2', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_GlobalRecordField_MemberlessPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
    begin
        Clear(GlobalRow);
        GlobalRow.Opt := GlobalRow.Opt::Second;
        Publisher.RaiseMemberless(GlobalRow.Opt, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        Publisher.RaiseMemberless(GlobalRow.Opt, true, Seen);
        Observer.Observe('after write 2', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_LocalArrayElement_MemberlessPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[2] := Arr[2]::Second;
        Publisher.RaiseMemberless(Arr[2], false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Arr[2] := Arr[2]::First;
        Publisher.RaiseMemberless(Arr[2], true, Seen);
        Observer.Observe('after write 2', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Event_MembersVarParam_MemberlessPublisher()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('level 1', Level1ToMemberlessPublisher(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('level 1', 'Second|1#Second#Third|2');
        Observer.Expect('after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_Local()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        V: Option First,Second,Third;
    begin
        Formatter := Impl;
        V := V::Second;
        Observer.Observe('inside', Formatter.FormatInside(V));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Formatter.Assign1(V);
        Observer.Observe('after Assign1', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(V));
        Observer.Observe('after Assign1 then Format', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(V, 'Third'));
        Observer.Observe('after evaluate Third', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after Assign1', 'Second|1');
        Observer.Expect('Assign1 then Format', 'Second|Second|1');
        Observer.Expect('after Assign1 then Format', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('after evaluate Third', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_LocalField()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Row: Record "OVN Row";
    begin
        Formatter := Impl;
        Row.Opt := Row.Opt::Second;
        Observer.Observe('inside', Formatter.FormatInside(Row.Opt));
        Observer.Observe('after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::First;
        Formatter.Assign1(Row.Opt);
        Observer.Observe('after Assign1', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(Row.Opt));
        Observer.Observe('after Assign1 then Format', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(Row.Opt, 'Third'));
        Observer.Observe('after evaluate Third', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after Assign1', 'Second|1');
        Observer.Expect('Assign1 then Format', 'Second|Second|1');
        Observer.Expect('after Assign1 then Format', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('after evaluate Third', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_CaptionField()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Row: Record "OVN Row";
    begin
        Formatter := Impl;
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('inside', Formatter.FormatInside(Row.OptCap));
        Observer.Observe('after', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Formatter.Assign1(Row.OptCap);
        Observer.Observe('after Assign1', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(Row.OptCap));
        Observer.Observe('after Assign1 then Format', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(Row.OptCap, 'Third'));
        Observer.Observe('after evaluate Third', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('inside', 'Two|Two|1');
        Observer.Expect('after', 'Two|1');
        Observer.Expect('after Assign1', 'Two|1');
        Observer.Expect('Assign1 then Format', 'Two|Two|1');
        Observer.Expect('after Assign1 then Format', 'Two|1');
        Observer.Expect('evaluate Third', 'Yes|Three|2');
        Observer.Expect('after evaluate Third', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_Global()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
    begin
        Formatter := Impl;
        GlobalV := GlobalV::Second;
        Observer.Observe('inside', Formatter.FormatInside(GlobalV));
        Observer.Observe('after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Formatter.Assign1(GlobalV);
        Observer.Observe('after Assign1', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(GlobalV));
        Observer.Observe('after Assign1 then Format', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(GlobalV, 'Third'));
        Observer.Observe('after evaluate Third', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after Assign1', 'Second|1');
        Observer.Expect('Assign1 then Format', 'Second|Second|1');
        Observer.Expect('after Assign1 then Format', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('after evaluate Third', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_GlobalRecordField()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
    begin
        Formatter := Impl;
        Clear(GlobalRow);
        GlobalRow.Opt := GlobalRow.Opt::Second;
        Observer.Observe('inside', Formatter.FormatInside(GlobalRow.Opt));
        Observer.Observe('after', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        Formatter.Assign1(GlobalRow.Opt);
        Observer.Observe('after Assign1', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(GlobalRow.Opt));
        Observer.Observe('after Assign1 then Format', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(GlobalRow.Opt, 'Third'));
        Observer.Observe('after evaluate Third', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after Assign1', 'Second|1');
        Observer.Expect('Assign1 then Format', 'Second|Second|1');
        Observer.Expect('after Assign1 then Format', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('after evaluate Third', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_GlobalRecordCaptionField()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
    begin
        Formatter := Impl;
        Clear(GlobalRow);
        GlobalRow.OptCap := GlobalRow.OptCap::Second;
        Observer.Observe('inside', Formatter.FormatInside(GlobalRow.OptCap));
        Observer.Observe('after', Format(GlobalRow.OptCap) + '|' + Format(GlobalRow.OptCap, 0, 2));
        GlobalRow.OptCap := GlobalRow.OptCap::First;
        Formatter.Assign1(GlobalRow.OptCap);
        Observer.Observe('after Assign1', Format(GlobalRow.OptCap) + '|' + Format(GlobalRow.OptCap, 0, 2));
        GlobalRow.OptCap := GlobalRow.OptCap::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(GlobalRow.OptCap));
        Observer.Observe('after Assign1 then Format', Format(GlobalRow.OptCap) + '|' + Format(GlobalRow.OptCap, 0, 2));
        GlobalRow.OptCap := GlobalRow.OptCap::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(GlobalRow.OptCap, 'Third'));
        Observer.Observe('after evaluate Third', Format(GlobalRow.OptCap) + '|' + Format(GlobalRow.OptCap, 0, 2));
        Observer.Expect('inside', 'Two|Two|1');
        Observer.Expect('after', 'Two|1');
        Observer.Expect('after Assign1', 'Two|1');
        Observer.Expect('Assign1 then Format', 'Two|Two|1');
        Observer.Expect('after Assign1 then Format', 'Two|1');
        Observer.Expect('evaluate Third', 'Yes|Three|2');
        Observer.Expect('after evaluate Third', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_GlobalArrayElement()
    var
        Observer: Codeunit "Probe Observer";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
    begin
        Formatter := Impl;
        Clear(GlobalArr);
        GlobalArr[2] := GlobalArr[2]::Second;
        Observer.Observe('inside', Formatter.FormatInside(GlobalArr[2]));
        Observer.Observe('after', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        GlobalArr[2] := GlobalArr[2]::First;
        Formatter.Assign1(GlobalArr[2]);
        Observer.Observe('after Assign1', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        GlobalArr[2] := GlobalArr[2]::First;
        Observer.Observe('Assign1 then Format', Formatter.Assign1ThenFormat(GlobalArr[2]));
        Observer.Observe('after Assign1 then Format', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        GlobalArr[2] := GlobalArr[2]::First;
        Observer.Observe('evaluate Third', Formatter.EvalResult(GlobalArr[2], 'Third'));
        Observer.Observe('after evaluate Third', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        Observer.Expect('inside', 'Second|Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after Assign1', 'Second|1');
        Observer.Expect('Assign1 then Format', 'Second|Second|1');
        Observer.Expect('after Assign1 then Format', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('after evaluate Third', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_MembersVarParam()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
    begin
        Formatter := Impl;
        V := V::Second;
        Observer.Observe('level 1', Level1ToInterface(V, Formatter));
        Observer.Observe('after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('level 1', 'Second|Second|1#Second#Second|1#Yes|Third|2#Third');
        Observer.Expect('after', 'Third|2');
        Observer.Verify();
    end;

    local procedure FormatInsideVar(var Value: Option): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure Assign1(var Value: Option)
    begin
        Value := 1;
    end;

    local procedure EvalResultInside(var Value: Option; T: Text): Text
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(Value, T);
        exit(Format(Ok) + '|' + Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure OtherMembersFormat(var Value: Option A,B,C): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure OtherMembersAssignC(var Value: Option A,B,C)
    begin
        Value := Value::C;
    end;

    local procedure SameMembersFormat(var Value: Option First,Second,Third): Text
    begin
        exit(Format(Value) + '|' + StrSubstNo('%1', Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure MemberlessArrayFormat(var A: array[2] of Option): Text
    var
        Seen: Text;
    begin
        Seen := Format(A[1]) + '|' + StrSubstNo('%1', A[1]) + '|' + Format(A[1], 0, 2);
        A[1] := 2;
        Seen += '#' + Format(A[1]) + '|' + Format(A[1], 0, 2);
        exit(Seen);
    end;

    local procedure ByValueToMemberless(Value: Option First,Second,Third): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideVar(Value) + '#' + Format(Value);
        Value := Value::First;
        Assign1(Value);
        Seen += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Seen += '#' + EvalResultInside(Value, 'Third') + '#' + Format(Value);
        exit(Seen);
    end;

    local procedure ByValueToOtherMembers(Value: Option First,Second,Third): Text
    var
        Seen: Text;
    begin
        Seen := OtherMembersFormat(Value) + '#' + Format(Value);
        OtherMembersAssignC(Value);
        Seen += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Seen);
    end;

    local procedure ByValueArrayElementToMemberless(A: array[2] of Option First,Second,Third): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideVar(A[1]) + '#' + Format(A[1]);
        A[1] := A[1]::First;
        Assign1(A[1]);
        Seen += '#' + Format(A[1]) + '|' + Format(A[1], 0, 2);
        exit(Seen);
    end;

    local procedure ByValueArrayToMemberlessArray(A: array[2] of Option First,Second,Third): Text
    begin
        exit(MemberlessArrayFormat(A) + '#' + Format(A[1]) + '|' + Format(A[1], 0, 2));
    end;

    local procedure ReturnNamed() R: Option First,Second,Third
    begin
        R := R::Second;
        GSeen := FormatInsideVar(R) + '#' + Format(R);
        R := R::First;
        Assign1(R);
        GSeen += '#' + Format(R) + '|' + Format(R, 0, 2);
    end;

    local procedure ByValueRecordFields(R: Record "OVN Row"): Text
    var
        Seen: Text;
    begin
        Seen := FormatInsideVar(R.Opt) + '#' + FormatInsideVar(R.OptCap);
        R.Opt := R.Opt::First;
        R.OptCap := R.OptCap::Third;
        Assign1(R.Opt);
        Assign1(R.OptCap);
        Seen += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2) + '#' + Format(R.OptCap) + '|' + Format(R.OptCap, 0, 2);
        exit(Seen);
    end;

    local procedure ByValueToMemberlessPublisher(Value: Option First,Second,Third): Text
    var
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Result: Text;
    begin
        Publisher.RaiseMemberless(Value, false, Seen);
        Result := Seen + '#' + Format(Value);
        Value := Value::First;
        Publisher.RaiseMemberless(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure ByValueToMembersPublisher(Value: Option First,Second,Third): Text
    var
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Result: Text;
    begin
        Publisher.RaiseWithMembers(Value, false, Seen);
        Result := Seen + '#' + Format(Value);
        Value := Value::First;
        Publisher.RaiseWithMembers(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure ByValueMemberlessToMembers(Value: Option): Text
    begin
        exit(Format(Value) + '#' + SameMembersFormat(Value) + '#' + Format(Value));
    end;

    local procedure Level1ToMemberlessPublisher(var Value: Option First,Second,Third): Text
    var
        Publisher: Codeunit "OVN Publisher";
        Seen: Text;
        Result: Text;
    begin
        Publisher.RaiseMemberless(Value, false, Seen);
        Result := Seen + '#' + Format(Value);
        Value := Value::First;
        Publisher.RaiseMemberless(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure Level1ToInterface(var Value: Option First,Second,Third; Formatter: Interface "OVN Formatter"): Text
    var
        Seen: Text;
    begin
        Seen := Formatter.FormatInside(Value) + '#' + Format(Value);
        Value := Value::First;
        Formatter.Assign1(Value);
        Seen += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Seen += '#' + Formatter.EvalResult(Value, 'Third') + '#' + Format(Value);
        exit(Seen);
    end;
}
