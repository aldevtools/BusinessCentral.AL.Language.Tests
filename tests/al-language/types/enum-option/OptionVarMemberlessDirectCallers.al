// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); OVN Publisher, OVN Subscriber, OVN Formatter and OVN Formatter Impl
//   (OptionVarMemberlessCallers.al); own objects 75257..75261 and the interface OVN Array Formatter (OVN Direct Publisher,
//   OVN Direct Subscriber, OVN Direct Row, OVN Array Formatter Impl, OVN Direct Callers Tests)
// local object: an Option value handed to a var parameter declared without members, by a direct event publisher call, an
//   interface method or a procedure, is what is under test.
// Probe (al-runner issues 7994 and 8291, review of al-runner PR 8299; follow-up of OptionVarMemberlessCallers.al):
//   Cells: an event publisher with public integration events raised directly (no var parameter in between), once without
//   members and once with the caller's members (First,Second,Third), each with a memberless subscriber, from a local, a global,
//   a local record field, a global record field, a local and a global array element, a field with OptionCaption One,Two,Three,
//   a field whose OptionCaption equals its members, a memberless local, a by-value parameter, a named return value, a field of
//   a var record and of a by-value record, Rec's own field, a by-value array element, a var parameter with the members and a
//   memberless var parameter. Through OVN Publisher.RaiseWithMembers (a var parameter with the members): a global record field,
//   a global record caption field, the field whose caption equals its members, a memberless local, and a caption field through
//   two var parameters with members. Interface method with a memberless var Option parameter: a by-value parameter, a named
//   return value, a field of a var record, of a by-value record and of Rec, a local and a by-value array element, the field
//   whose caption equals its members, a memberless var parameter. Interface method with a memberless var Option array
//   parameter: a local, a global, a var and a by-value array. Procedure with a memberless var Option parameter: a global array
//   element, the field whose caption equals its members. A memberless var parameter (caller with members) handed to a var
//   parameter with members A,B,C.
// Facts: Values are Format|ordinal. Direct publisher calls: the memberless subscriber sees Second|1 (caption field Two|1) under
//   both publishers, the caller still shows Second|1 after, and the subscriber's Value := 2 gives the caller Third|2 (caption
//   field Three|2). By-value callers (parameter, record, array element) keep their own value: their caller shows Second|1
//   after; var callers (var record, Rec, var parameters with or without members) show Third|2 after; a named return value
//   returns Third|2. A memberless local (value 1): under the memberless publisher the subscriber sees 1|1 and the write gives
//   2|2; under the publisher with members the subscriber sees Second|1, the local shows 1|1 after and 2|2 after the write.
//   Through RaiseWithMembers: the same, Second|1 or Two|1, then Third|2 or Three|2; the memberless local shows Second|1 in the
//   subscriber and 1|1, 2|2 in the caller. The field whose OptionCaption equals its members behaves like a field without
//   caption. Interface methods and procedures: inside Second|Second|1, Assign1 gives Second|1, Evaluate('Third') gives
//   Yes|Third|2. Interface with a memberless var array parameter: A[1] Second|1, A[2] Third|2, after A[1] := 2 Third|2,
//   Evaluate(A[2], 'First') Yes|First|0; a local, global or var array caller then shows Third|2 and First|0; a by-value array
//   parameter shows them too, and its caller stays Second|1 and Third|2. A memberless var parameter handed on to a var
//   parameter with members A,B,C shows Second there (not B); Value := Value::C gives Third|2 in the memberless parameter and in
//   the caller.
// BC versions: measured on 29.0 (local Windows BC tier). The local 27.5 and 28.5 legs did not run (host lock timeout on 28.5,
//   service unavailable on 27.5); the corpus CI run of the pull request measures them.
// A publisher whose integration events are public, so callers raise them directly (no var parameter in between).
codeunit 75257 "OVN Direct Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnMemberless(var Value: Option; Write: Boolean; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnWithMembers(var Value: Option First,Second,Third; Write: Boolean; var Seen: Text)
    begin
    end;
}

// Both subscribers declare the parameter without members.
codeunit 75258 "OVN Direct Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVN Direct Publisher", 'OnMemberless', '', false, false)]
    local procedure HandleMemberless(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
        if Write then
            Value := 2;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVN Direct Publisher", 'OnWithMembers', '', false, false)]
    local procedure HandleWithMembers(var Value: Option; Write: Boolean; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
        if Write then
            Value := 2;
    end;
}

table 75259 "OVN Direct Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = First,Second,Third; }
        field(3; OptCap; Option) { OptionMembers = First,Second,Third; OptionCaption = 'One,Two,Three'; }
        field(4; OptSame; Option) { OptionMembers = First,Second,Third; OptionCaption = 'First,Second,Third'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    // Rec's own field raised directly to both publishers.
    procedure OptToPublishers(): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        Opt := Opt::Second;
        Publisher.OnMemberless(Opt, false, Seen);
        Result := Seen + '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        Opt := Opt::First;
        Publisher.OnMemberless(Opt, true, Seen);
        Result += '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        Opt := Opt::Second;
        Publisher.OnWithMembers(Opt, false, Seen);
        Result += '#' + Seen + '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        Opt := Opt::First;
        Publisher.OnWithMembers(Opt, true, Seen);
        Result += '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        exit(Result);
    end;

    // Rec's own field handed to an interface method with a memberless var Option parameter.
    procedure OptToInterface(Formatter: Interface "OVN Formatter"): Text
    var
        Result: Text;
    begin
        Opt := Opt::Second;
        Result := Formatter.FormatInside(Opt) + '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        Opt := Opt::First;
        Formatter.Assign1(Opt);
        Result += '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        Opt := Opt::First;
        Result += '#' + Formatter.EvalResult(Opt, 'Third') + '#' + Format(Opt) + '|' + Format(Opt, 0, 2);
        exit(Result);
    end;
}

// An interface method with a memberless var Option array parameter.
interface "OVN Array Formatter"
{
    procedure StoreAndFormat(var A: array[2] of Option): Text;
}

codeunit 75260 "OVN Array Formatter Impl" implements "OVN Array Formatter"
{
    procedure StoreAndFormat(var A: array[2] of Option): Text
    var
        Seen: Text;
        Ok: Boolean;
    begin
        Seen := Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[1] := 2;
        Seen += '#' + Format(A[1]) + '|' + Format(A[1], 0, 2);
        Ok := Evaluate(A[2], 'First');
        Seen += '#' + Format(Ok) + '|' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        exit(Seen);
    end;
}

codeunit 75261 "OVN Direct Callers Tests"
{
    Subtype = Test;

    var
        GlobalV: Option First,Second,Third;
        GlobalRow: Record "OVN Direct Row";
        GlobalArr: array[2] of Option First,Second,Third;
        GSeen: Text;

    [Test]
    procedure Direct_Local_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Publisher.OnMemberless(V, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Publisher.OnMemberless(V, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        Publisher.OnWithMembers(V, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(V) + '|' + Format(V, 0, 2));
        V := V::First;
        Publisher.OnWithMembers(V, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_Global_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
    begin
        GlobalV := GlobalV::Second;
        Publisher.OnMemberless(GlobalV, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Publisher.OnMemberless(GlobalV, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::Second;
        Publisher.OnWithMembers(GlobalV, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::First;
        Publisher.OnWithMembers(GlobalV, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_LocalField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Row: Record "OVN Direct Row";
    begin
        Row.Opt := Row.Opt::Second;
        Publisher.OnMemberless(Row.Opt, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::First;
        Publisher.OnMemberless(Row.Opt, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::Second;
        Publisher.OnWithMembers(Row.Opt, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::First;
        Publisher.OnWithMembers(Row.Opt, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_GlobalRecordField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
    begin
        Clear(GlobalRow);
        GlobalRow.Opt := GlobalRow.Opt::Second;
        Publisher.OnMemberless(GlobalRow.Opt, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        Publisher.OnMemberless(GlobalRow.Opt, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::Second;
        Publisher.OnWithMembers(GlobalRow.Opt, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        Publisher.OnWithMembers(GlobalRow.Opt, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_LocalArrayElement_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[2] := Arr[2]::Second;
        Publisher.OnMemberless(Arr[2], false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Arr[2] := Arr[2]::First;
        Publisher.OnMemberless(Arr[2], true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Arr[2] := Arr[2]::Second;
        Publisher.OnWithMembers(Arr[2], false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Arr[2] := Arr[2]::First;
        Publisher.OnWithMembers(Arr[2], true, Seen);
        Observer.Observe('publisher with members after write 2', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_GlobalArrayElement_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
    begin
        Clear(GlobalArr);
        GlobalArr[2] := GlobalArr[2]::Second;
        Publisher.OnMemberless(GlobalArr[2], false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        GlobalArr[2] := GlobalArr[2]::First;
        Publisher.OnMemberless(GlobalArr[2], true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        GlobalArr[2] := GlobalArr[2]::Second;
        Publisher.OnWithMembers(GlobalArr[2], false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        GlobalArr[2] := GlobalArr[2]::First;
        Publisher.OnWithMembers(GlobalArr[2], true, Seen);
        Observer.Observe('publisher with members after write 2', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_CaptionField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Row: Record "OVN Direct Row";
    begin
        Row.OptCap := Row.OptCap::Second;
        Publisher.OnMemberless(Row.OptCap, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Publisher.OnMemberless(Row.OptCap, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::Second;
        Publisher.OnWithMembers(Row.OptCap, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::First;
        Publisher.OnWithMembers(Row.OptCap, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('memberless publisher saw', 'Two|1');
        Observer.Expect('memberless publisher after', 'Two|1');
        Observer.Expect('memberless publisher after write 2', 'Three|2');
        Observer.Expect('publisher with members saw', 'Two|1');
        Observer.Expect('publisher with members after', 'Two|1');
        Observer.Expect('publisher with members after write 2', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_SameCaptionField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Row: Record "OVN Direct Row";
    begin
        Row.OptSame := Row.OptSame::Second;
        Publisher.OnMemberless(Row.OptSame, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Row.OptSame := Row.OptSame::First;
        Publisher.OnMemberless(Row.OptSame, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Row.OptSame := Row.OptSame::Second;
        Publisher.OnWithMembers(Row.OptSame, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Row.OptSame := Row.OptSame::First;
        Publisher.OnWithMembers(Row.OptSame, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Observer.Expect('memberless publisher saw', 'Second|1');
        Observer.Expect('memberless publisher after', 'Second|1');
        Observer.Expect('memberless publisher after write 2', 'Third|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', 'Second|1');
        Observer.Expect('publisher with members after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_MemberlessLocal_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        M: Option;
    begin
        M := 1;
        Publisher.OnMemberless(M, false, Seen);
        Observer.Observe('memberless publisher saw', Seen);
        Observer.Observe('memberless publisher after', Format(M) + '|' + Format(M, 0, 2));
        M := 0;
        Publisher.OnMemberless(M, true, Seen);
        Observer.Observe('memberless publisher after write 2', Format(M) + '|' + Format(M, 0, 2));
        M := 1;
        Publisher.OnWithMembers(M, false, Seen);
        Observer.Observe('publisher with members saw', Seen);
        Observer.Observe('publisher with members after', Format(M) + '|' + Format(M, 0, 2));
        M := 0;
        Publisher.OnWithMembers(M, true, Seen);
        Observer.Observe('publisher with members after write 2', Format(M) + '|' + Format(M, 0, 2));
        Observer.Expect('memberless publisher saw', '1|1');
        Observer.Expect('memberless publisher after', '1|1');
        Observer.Expect('memberless publisher after write 2', '2|2');
        Observer.Expect('publisher with members saw', 'Second|1');
        Observer.Expect('publisher with members after', '1|1');
        Observer.Expect('publisher with members after write 2', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_ByValueParam_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', ByValueToPublishers(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_NamedReturn_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        GSeen := '';
        V := ReturnNamedToPublishers();
        Observer.Observe('inside', GSeen);
        Observer.Observe('returned', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('returned', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_VarRecordField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Observer.Observe('inside', VarRecordToPublishers(Row));
        Observer.Observe('caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_ByValueRecordField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Row.Opt := Row.Opt::Second;
        Observer.Observe('inside', ByValueRecordToPublishers(Row));
        Observer.Observe('caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_RecField_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Observer.Observe('inside', Row.OptToPublishers());
        Observer.Observe('caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_ByValueArrayElement_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[2] := Arr[2]::Second;
        Observer.Observe('inside', ByValueArrayElementToPublishers(Arr));
        Observer.Observe('caller after', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_MembersVarParam_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        Observer.Observe('inside', MembersVarToPublishers(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Direct_MemberlessVarParam_BothPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', MemberlessVarToPublishers(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|1#Second|1#Third|2#Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Hop_GlobalRecordField_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        HopPublisher: Codeunit "OVN Publisher";
        Seen: Text;
    begin
        Clear(GlobalRow);
        GlobalRow.Opt := GlobalRow.Opt::Second;
        HopPublisher.RaiseWithMembers(GlobalRow.Opt, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::First;
        HopPublisher.RaiseWithMembers(GlobalRow.Opt, true, Seen);
        Observer.Observe('after write 2', Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Hop_GlobalCaptionField_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        HopPublisher: Codeunit "OVN Publisher";
        Seen: Text;
    begin
        Clear(GlobalRow);
        GlobalRow.OptCap := GlobalRow.OptCap::Second;
        HopPublisher.RaiseWithMembers(GlobalRow.OptCap, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(GlobalRow.OptCap) + '|' + Format(GlobalRow.OptCap, 0, 2));
        GlobalRow.OptCap := GlobalRow.OptCap::First;
        HopPublisher.RaiseWithMembers(GlobalRow.OptCap, true, Seen);
        Observer.Observe('after write 2', Format(GlobalRow.OptCap) + '|' + Format(GlobalRow.OptCap, 0, 2));
        Observer.Expect('subscriber saw', 'Two|1');
        Observer.Expect('after', 'Two|1');
        Observer.Expect('after write 2', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Hop_SameCaptionField_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        HopPublisher: Codeunit "OVN Publisher";
        Seen: Text;
        Row: Record "OVN Direct Row";
    begin
        Row.OptSame := Row.OptSame::Second;
        HopPublisher.RaiseWithMembers(Row.OptSame, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Row.OptSame := Row.OptSame::First;
        HopPublisher.RaiseWithMembers(Row.OptSame, true, Seen);
        Observer.Observe('after write 2', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', 'Second|1');
        Observer.Expect('after write 2', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Hop_MemberlessLocal_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        HopPublisher: Codeunit "OVN Publisher";
        Seen: Text;
        M: Option;
    begin
        M := 1;
        HopPublisher.RaiseWithMembers(M, false, Seen);
        Observer.Observe('subscriber saw', Seen);
        Observer.Observe('after', Format(M) + '|' + Format(M, 0, 2));
        M := 0;
        HopPublisher.RaiseWithMembers(M, true, Seen);
        Observer.Observe('after write 2', Format(M) + '|' + Format(M, 0, 2));
        Observer.Expect('subscriber saw', 'Second|1');
        Observer.Expect('after', '1|1');
        Observer.Expect('after write 2', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Hop_CaptionField_TwoHops_MembersPublisher()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Row.OptCap := Row.OptCap::Second;
        Observer.Observe('inside', TwoHopsToMembersPublisher(Row.OptCap));
        Observer.Observe('caller after', Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Observer.Expect('inside', 'Two|1#Two|1#Three|2');
        Observer.Expect('caller after', 'Three|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_ByValueParam()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', ByValueToInterface(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_NamedReturn()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        GSeen := '';
        V := ReturnNamedToInterface();
        Observer.Observe('inside', GSeen);
        Observer.Observe('returned', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('returned', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_VarRecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Observer.Observe('inside', VarRecordToInterface(Row));
        Observer.Observe('caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_ByValueRecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Row.Opt := Row.Opt::Second;
        Observer.Observe('inside', ByValueRecordToInterface(Row));
        Observer.Observe('caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_RecField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
    begin
        Formatter := Impl;
        Observer.Observe('inside', Row.OptToInterface(Formatter));
        Observer.Observe('caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_LocalArrayElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('inside', LocalArrayElementToInterface());
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_ByValueArrayElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[2] := Arr[2]::Second;
        Observer.Observe('inside', ByValueArrayElementToInterface(Arr));
        Observer.Observe('caller after', Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Second|1');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_SameCaptionField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Observer.Observe('inside', SameCaptionFieldToInterface(Row));
        Observer.Observe('caller after', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_MemberlessVarParam()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', MemberlessVarToInterface(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure InterfaceArray_LocalAndGlobalArray()
    var
        Observer: Codeunit "Probe Observer";
        ArrayFormatter: Interface "OVN Array Formatter";
        ArrayImpl: Codeunit "OVN Array Formatter Impl";
        Arr: array[2] of Option First,Second,Third;
    begin
        ArrayFormatter := ArrayImpl;
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('local inside', ArrayFormatter.StoreAndFormat(Arr));
        Observer.Observe('local after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Clear(GlobalArr);
        GlobalArr[1] := GlobalArr[1]::Second;
        GlobalArr[2] := GlobalArr[2]::Third;
        Observer.Observe('global inside', ArrayFormatter.StoreAndFormat(GlobalArr));
        Observer.Observe('global after', Format(GlobalArr[1]) + '|' + Format(GlobalArr[1], 0, 2) + '#' + Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        Observer.Expect('local inside', 'Second|1#Third|2#Third|2#Yes|First|0');
        Observer.Expect('local after', 'Third|2#First|0');
        Observer.Expect('global inside', 'Second|1#Third|2#Third|2#Yes|First|0');
        Observer.Expect('global after', 'Third|2#First|0');
        Observer.Verify();
    end;

    [Test]
    procedure InterfaceArray_VarAndByValueArrayParam()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('var parameter inside', VarArrayToInterface(Arr));
        Observer.Observe('var parameter after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('by-value parameter inside', ByValueArrayToInterface(Arr));
        Observer.Observe('by-value parameter after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('var parameter inside', 'Second|1#Third|2#Third|2#Yes|First|0#Third|2#First|0');
        Observer.Expect('var parameter after', 'Third|2#First|0');
        Observer.Expect('by-value parameter inside', 'Second|1#Third|2#Third|2#Yes|First|0#Third|2#First|0');
        Observer.Expect('by-value parameter after', 'Second|1#Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Procedure_GlobalArrayElement()
    var
        Observer: Codeunit "Probe Observer";

    begin
        Clear(GlobalArr);
        Observer.Observe('inside', GlobalArrayElementToProcedure());
        Observer.Observe('caller after', Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Procedure_SameCaptionField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVN Direct Row";
    begin
        Observer.Observe('inside', SameCaptionFieldToProcedure(Row));
        Observer.Observe('caller after', Format(Row.OptSame) + '|' + Format(Row.OptSame, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Second|1#Yes|Third|2#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure MemberlessVarParam_ToOtherMembersVar()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
    begin
        V := V::Second;
        Observer.Observe('inside', MemberlessVarToOtherMembers(V));
        Observer.Observe('caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('inside', 'Second|Second|1#Second|1#Third|2');
        Observer.Expect('caller after', 'Third|2');
        Observer.Verify();
    end;

    local procedure ByValueToPublishers(Value: Option First,Second,Third): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        Value := Value::Second;
        Publisher.OnMemberless(Value, false, Seen);
        Result := Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Publisher.OnMemberless(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::Second;
        Publisher.OnWithMembers(Value, false, Seen);
        Result += '#' + Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Publisher.OnWithMembers(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure ReturnNamedToPublishers() R: Option First,Second,Third
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        R := R::Second;
        Publisher.OnMemberless(R, false, Seen);
        Result := Seen + '#' + Format(R) + '|' + Format(R, 0, 2);
        R := R::First;
        Publisher.OnMemberless(R, true, Seen);
        Result += '#' + Format(R) + '|' + Format(R, 0, 2);
        R := R::Second;
        Publisher.OnWithMembers(R, false, Seen);
        Result += '#' + Seen + '#' + Format(R) + '|' + Format(R, 0, 2);
        R := R::First;
        Publisher.OnWithMembers(R, true, Seen);
        Result += '#' + Format(R) + '|' + Format(R, 0, 2);
        GSeen := Result;
    end;

    local procedure VarRecordToPublishers(var R: Record "OVN Direct Row"): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        R.Opt := R.Opt::Second;
        Publisher.OnMemberless(R.Opt, false, Seen);
        Result := Seen + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Publisher.OnMemberless(R.Opt, true, Seen);
        Result += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::Second;
        Publisher.OnWithMembers(R.Opt, false, Seen);
        Result += '#' + Seen + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Publisher.OnWithMembers(R.Opt, true, Seen);
        Result += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        exit(Result);
    end;

    local procedure ByValueRecordToPublishers(R: Record "OVN Direct Row"): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        R.Opt := R.Opt::Second;
        Publisher.OnMemberless(R.Opt, false, Seen);
        Result := Seen + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Publisher.OnMemberless(R.Opt, true, Seen);
        Result += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::Second;
        Publisher.OnWithMembers(R.Opt, false, Seen);
        Result += '#' + Seen + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Publisher.OnWithMembers(R.Opt, true, Seen);
        Result += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        exit(Result);
    end;

    local procedure ByValueArrayElementToPublishers(A: array[2] of Option First,Second,Third): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        A[2] := A[2]::Second;
        Publisher.OnMemberless(A[2], false, Seen);
        Result := Seen + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[2] := A[2]::First;
        Publisher.OnMemberless(A[2], true, Seen);
        Result += '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[2] := A[2]::Second;
        Publisher.OnWithMembers(A[2], false, Seen);
        Result += '#' + Seen + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[2] := A[2]::First;
        Publisher.OnWithMembers(A[2], true, Seen);
        Result += '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        exit(Result);
    end;

    local procedure MembersVarToPublishers(var Value: Option First,Second,Third): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        Value := Value::Second;
        Publisher.OnMemberless(Value, false, Seen);
        Result := Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Publisher.OnMemberless(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::Second;
        Publisher.OnWithMembers(Value, false, Seen);
        Result += '#' + Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Publisher.OnWithMembers(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure MemberlessVarToPublishers(var Value: Option): Text
    var
        Publisher: Codeunit "OVN Direct Publisher";
        Seen: Text;
        Result: Text;
    begin
        Value := 1;
        Publisher.OnMemberless(Value, false, Seen);
        Result := Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := 0;
        Publisher.OnMemberless(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := 1;
        Publisher.OnWithMembers(Value, false, Seen);
        Result += '#' + Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := 0;
        Publisher.OnWithMembers(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure TwoHopsToMembersPublisher(var Value: Option First,Second,Third): Text
    var
        HopPublisher: Codeunit "OVN Publisher";
        Seen: Text;
        Result: Text;
    begin
        HopPublisher.RaiseWithMembers(Value, false, Seen);
        Result := Seen + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        HopPublisher.RaiseWithMembers(Value, true, Seen);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure ByValueToInterface(Value: Option First,Second,Third): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        Value := Value::Second;
        Result := Formatter.FormatInside(Value) + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Formatter.Assign1(Value);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::First;
        Result += '#' + Formatter.EvalResult(Value, 'Third') + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure ReturnNamedToInterface() R: Option First,Second,Third
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        R := R::Second;
        Result := Formatter.FormatInside(R) + '#' + Format(R) + '|' + Format(R, 0, 2);
        R := R::First;
        Formatter.Assign1(R);
        Result += '#' + Format(R) + '|' + Format(R, 0, 2);
        R := R::First;
        Result += '#' + Formatter.EvalResult(R, 'Third') + '#' + Format(R) + '|' + Format(R, 0, 2);
        GSeen := Result;
    end;

    local procedure VarRecordToInterface(var R: Record "OVN Direct Row"): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        R.Opt := R.Opt::Second;
        Result := Formatter.FormatInside(R.Opt) + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Formatter.Assign1(R.Opt);
        Result += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Result += '#' + Formatter.EvalResult(R.Opt, 'Third') + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        exit(Result);
    end;

    local procedure ByValueRecordToInterface(R: Record "OVN Direct Row"): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        R.Opt := R.Opt::Second;
        Result := Formatter.FormatInside(R.Opt) + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Formatter.Assign1(R.Opt);
        Result += '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        R.Opt := R.Opt::First;
        Result += '#' + Formatter.EvalResult(R.Opt, 'Third') + '#' + Format(R.Opt) + '|' + Format(R.Opt, 0, 2);
        exit(Result);
    end;

    local procedure LocalArrayElementToInterface(): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Arr: array[2] of Option First,Second,Third;
        Result: Text;
    begin
        Formatter := Impl;
        Arr[2] := Arr[2]::Second;
        Result := Formatter.FormatInside(Arr[2]) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2);
        Arr[2] := Arr[2]::First;
        Formatter.Assign1(Arr[2]);
        Result += '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2);
        Arr[2] := Arr[2]::First;
        Result += '#' + Formatter.EvalResult(Arr[2], 'Third') + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2);
        exit(Result);
    end;

    local procedure ByValueArrayElementToInterface(A: array[2] of Option First,Second,Third): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        A[2] := A[2]::Second;
        Result := Formatter.FormatInside(A[2]) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[2] := A[2]::First;
        Formatter.Assign1(A[2]);
        Result += '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        A[2] := A[2]::First;
        Result += '#' + Formatter.EvalResult(A[2], 'Third') + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2);
        exit(Result);
    end;

    local procedure SameCaptionFieldToInterface(var R: Record "OVN Direct Row"): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        R.OptSame := R.OptSame::Second;
        Result := Formatter.FormatInside(R.OptSame) + '#' + Format(R.OptSame) + '|' + Format(R.OptSame, 0, 2);
        R.OptSame := R.OptSame::First;
        Formatter.Assign1(R.OptSame);
        Result += '#' + Format(R.OptSame) + '|' + Format(R.OptSame, 0, 2);
        R.OptSame := R.OptSame::First;
        Result += '#' + Formatter.EvalResult(R.OptSame, 'Third') + '#' + Format(R.OptSame) + '|' + Format(R.OptSame, 0, 2);
        exit(Result);
    end;

    local procedure MemberlessVarToInterface(var Value: Option): Text
    var
        Formatter: Interface "OVN Formatter";
        Impl: Codeunit "OVN Formatter Impl";
        Result: Text;
    begin
        Formatter := Impl;
        Result := Formatter.FormatInside(Value) + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := 0;
        Formatter.Assign1(Value);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        Value := 0;
        Result += '#' + Formatter.EvalResult(Value, 'Third') + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
    end;

    local procedure VarArrayToInterface(var A: array[2] of Option First,Second,Third): Text
    var
        ArrayFormatter: Interface "OVN Array Formatter";
        ArrayImpl: Codeunit "OVN Array Formatter Impl";
        Result: Text;
    begin
        ArrayFormatter := ArrayImpl;
        Result := ArrayFormatter.StoreAndFormat(A);
        exit(Result + '#' + Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2));
    end;

    local procedure ByValueArrayToInterface(A: array[2] of Option First,Second,Third): Text
    var
        ArrayFormatter: Interface "OVN Array Formatter";
        ArrayImpl: Codeunit "OVN Array Formatter Impl";
        Result: Text;
    begin
        ArrayFormatter := ArrayImpl;
        Result := ArrayFormatter.StoreAndFormat(A);
        exit(Result + '#' + Format(A[1]) + '|' + Format(A[1], 0, 2) + '#' + Format(A[2]) + '|' + Format(A[2], 0, 2));
    end;

    local procedure GlobalArrayElementToProcedure(): Text
    var
        Result: Text;
    begin
        GlobalArr[2] := GlobalArr[2]::Second;
        Result := FormatInsideVar(GlobalArr[2]) + '#' + Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2);
        GlobalArr[2] := GlobalArr[2]::First;
        Assign1(GlobalArr[2]);
        Result += '#' + Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2);
        GlobalArr[2] := GlobalArr[2]::First;
        Result += '#' + EvalResultInside(GlobalArr[2], 'Third') + '#' + Format(GlobalArr[2]) + '|' + Format(GlobalArr[2], 0, 2);
        exit(Result);
    end;

    local procedure SameCaptionFieldToProcedure(var R: Record "OVN Direct Row"): Text
    var
        Result: Text;
    begin
        R.OptSame := R.OptSame::Second;
        Result := FormatInsideVar(R.OptSame) + '#' + Format(R.OptSame) + '|' + Format(R.OptSame, 0, 2);
        R.OptSame := R.OptSame::First;
        Assign1(R.OptSame);
        Result += '#' + Format(R.OptSame) + '|' + Format(R.OptSame, 0, 2);
        R.OptSame := R.OptSame::First;
        Result += '#' + EvalResultInside(R.OptSame, 'Third') + '#' + Format(R.OptSame) + '|' + Format(R.OptSame, 0, 2);
        exit(Result);
    end;

    local procedure MemberlessVarToOtherMembers(var Value: Option): Text
    var
        Result: Text;
    begin
        Result := OtherMembersFormat(Value) + '#' + Format(Value) + '|' + Format(Value, 0, 2);
        OtherMembersAssignC(Value);
        Result += '#' + Format(Value) + '|' + Format(Value, 0, 2);
        exit(Result);
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
}
