// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75280..75283 (OVH Row, OVH Publisher, OVH Subscribers,
//   OVH Heard Callers Tests)
// local object: an Option variable handed to a var parameter of an event publisher that a subscriber hears is what is
//   under test.
// Probe (al-runner issue 8384, follow-up of OptionVarMemberlessUnheard.al): an Option variable handed directly to an event
//   publisher's var parameter with members P,Q,R, which a subscriber hears. Base Application's shape: codeunit 5407
//   "Prod. Order Status Management".TransProdOrderLine hands its memberless NewStatusOption to OnAfterToProdOrderLineModify.
//   Subscribers: one that does not take the parameter, one that reads it, one that stores P,Q,R's R, one that stores the
//   Integer 0, one that stores R and then raises an error, and two subscribers on one event (one ignores the parameter, the
//   other stores R).
//   Callers: a memberless local (holding 1, and 7, past the publisher's members), a local First,Second,Third, a global with
//   members and a memberless one, a parameter passed by value (with members and memberless), a var parameter with members
//   First,Second,Third, a memberless var parameter (holding its caller's members, and a memberless 1), a named return value,
//   a field of a local record (without captions and with OptionCaption One,Two,Three), of a global record and of a var record
//   parameter, an element of a local array with members, of a global array and of a local memberless array.
// Facts: values are Format|ordinal. The subscriber reads the publisher's member for the ordinal (Q|1), also for a caller
//   without members, a global, a parameter passed by value, a named return value, a field (also one with captions) and an
//   element; an ordinal past the publisher's members reads as the number (7|7). After the call the caller's variable has
//   its own members and the ordinal the subscriber left: unchanged after a subscriber that ignores or reads the parameter
//   (Second|1, a memberless 1|1, a caption field Two|1), R gives Third|2 (memberless 2|2, caption field Three|2), the Integer
//   0 gives First|0 (memberless 0|0), also with two subscribers. A var parameter of the running routine handed on shows the
//   subscriber the members of the value its own caller handed (Second|1, a memberless 1|1), not the publisher's. An error
//   the subscriber raises after it stores R leaves R's ordinal in the caller's variable (Third|2, memberless 2|2).
// BC versions: measured on 29.1 (local Windows BC tier). The local 27.5 and 28.5 legs were not run; the corpus CI run of the
//   pull request measures them.
table 75280 "OVH Row"
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

// Raises the events. OVH Subscribers hears each of them.
codeunit 75281 "OVH Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnHeardIgnored(var Value: Option P,Q,R)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnHeardRead(var Value: Option P,Q,R; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnHeardWritten(var Value: Option P,Q,R; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnHeardWrittenInteger(var Value: Option P,Q,R; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnHeardTwice(var Value: Option P,Q,R; var Seen: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnHeardWrittenThenError(var Value: Option P,Q,R)
    begin
    end;
}

codeunit 75282 "OVH Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardIgnored', '', false, false)]
    local procedure HandleIgnored()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardRead', '', false, false)]
    local procedure HandleRead(var Value: Option P,Q,R; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardWritten', '', false, false)]
    local procedure HandleWritten(var Value: Option P,Q,R; var Seen: Text)
    begin
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
        Value := Value::R;
        Seen += '~' + Format(Value) + '|' + Format(Value, 0, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardWrittenInteger', '', false, false)]
    local procedure HandleWrittenInteger(var Value: Option P,Q,R; var Seen: Text)
    begin
        Value := 0;
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardTwice', '', false, false)]
    local procedure HandleTwiceIgnored()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardTwice', '', false, false)]
    local procedure HandleTwiceWritten(var Value: Option P,Q,R; var Seen: Text)
    begin
        Value := Value::R;
        Seen := Format(Value) + '|' + Format(Value, 0, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVH Publisher", 'OnHeardWrittenThenError', '', false, false)]
    local procedure HandleWrittenThenError(var Value: Option P,Q,R)
    begin
        Value := Value::R;
        Error('OVH subscriber error');
    end;
}

// Caller kinds handed directly to the heard publishers. Values are Format|ordinal; 'seen>after' is what the subscriber
// saw, then the caller's variable after the call.
codeunit 75283 "OVH Heard Callers Tests"
{
    Subtype = Test;

    var
        Pub: Codeunit "OVH Publisher";
        GlobalV: Option First,Second,Third;
        GlobalV0: Option;
        GlobalRow: Record "OVH Row";
        GlobalArr: array[2] of Option First,Second,Third;

    [Test]
    procedure MemberlessLocal_HeardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V1: Option;
        V2: Option;
        V3: Option;
        V4: Option;
        V5: Option;
        V6: Option;
        V7: Option;
        Seen: Text;
    begin
        V1 := 1;
        Pub.OnHeardIgnored(V1);
        Observer.Observe('ignored: after', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := 1;
        Pub.OnHeardRead(V2, Seen);
        Observer.Observe('read: seen>after', Seen + '>' + Format(V2) + '|' + Format(V2, 0, 2));
        V3 := 1;
        Pub.OnHeardWritten(V3, Seen);
        Observer.Observe('written R: seen>after', Seen + '>' + Format(V3) + '|' + Format(V3, 0, 2));
        V4 := 1;
        Pub.OnHeardWrittenInteger(V4, Seen);
        Observer.Observe('written 0: seen>after', Seen + '>' + Format(V4) + '|' + Format(V4, 0, 2));
        V5 := 1;
        Pub.OnHeardTwice(V5, Seen);
        Observer.Observe('two subscribers: seen>after', Seen + '>' + Format(V5) + '|' + Format(V5, 0, 2));
        V6 := 7;
        Pub.OnHeardIgnored(V6);
        Observer.Observe('7, ignored: after', Format(V6) + '|' + Format(V6, 0, 2));
        V7 := 7;
        Pub.OnHeardRead(V7, Seen);
        Observer.Observe('7, read: seen>after', Seen + '>' + Format(V7) + '|' + Format(V7, 0, 2));
        Observer.Expect('ignored: after', '1|1');
        Observer.Expect('read: seen>after', 'Q|1>1|1');
        Observer.Expect('written R: seen>after', 'Q|1~R|2>2|2');
        Observer.Expect('written 0: seen>after', 'P|0>0|0');
        Observer.Expect('two subscribers: seen>after', 'R|2>2|2');
        Observer.Expect('7, ignored: after', '7|7');
        Observer.Expect('7, read: seen>after', '7|7>7|7');
        Observer.Verify();
    end;

    [Test]
    procedure LocalWithMembers_HeardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V1: Option First,Second,Third;
        V2: Option First,Second,Third;
        V3: Option First,Second,Third;
        V4: Option First,Second,Third;
        V5: Option First,Second,Third;
        V6: Option First,Second,Third;
        Seen: Text;
    begin
        V1 := V1::Second;
        Pub.OnHeardIgnored(V1);
        Observer.Observe('ignored: after', Format(V1) + '|' + Format(V1, 0, 2));
        V2 := V2::Second;
        Pub.OnHeardRead(V2, Seen);
        Observer.Observe('read: seen>after', Seen + '>' + Format(V2) + '|' + Format(V2, 0, 2));
        V3 := V3::Second;
        Pub.OnHeardWritten(V3, Seen);
        Observer.Observe('written R: seen>after', Seen + '>' + Format(V3) + '|' + Format(V3, 0, 2));
        V4 := V4::Second;
        Pub.OnHeardWrittenInteger(V4, Seen);
        Observer.Observe('written 0: seen>after', Seen + '>' + Format(V4) + '|' + Format(V4, 0, 2));
        V5 := V5::Second;
        Pub.OnHeardTwice(V5, Seen);
        Observer.Observe('two subscribers: seen>after', Seen + '>' + Format(V5) + '|' + Format(V5, 0, 2));
        V6 := V6::Second;
        Pub.OnHeardWritten(V6, Seen);
        V6 := V6::First;
        Observer.Observe('written R, then V := V::First', Format(V6) + '|' + Format(V6, 0, 2));
        Observer.Expect('ignored: after', 'Second|1');
        Observer.Expect('read: seen>after', 'Q|1>Second|1');
        Observer.Expect('written R: seen>after', 'Q|1~R|2>Third|2');
        Observer.Expect('written 0: seen>after', 'P|0>First|0');
        Observer.Expect('two subscribers: seen>after', 'R|2>Third|2');
        Observer.Expect('written R, then V := V::First', 'First|0');
        Observer.Verify();
    end;

    [Test]
    procedure Globals_HeardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Seen: Text;
    begin
        GlobalV := GlobalV::Second;
        Pub.OnHeardRead(GlobalV, Seen);
        Observer.Observe('with members, read: seen>after', Seen + '>' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::Second;
        Pub.OnHeardWritten(GlobalV, Seen);
        Observer.Observe('with members, written R: seen>after', Seen + '>' + Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV := GlobalV::Second;
        Pub.OnHeardIgnored(GlobalV);
        Observer.Observe('with members, ignored: after', Format(GlobalV) + '|' + Format(GlobalV, 0, 2));
        GlobalV0 := 1;
        Pub.OnHeardRead(GlobalV0, Seen);
        Observer.Observe('memberless, read: seen>after', Seen + '>' + Format(GlobalV0) + '|' + Format(GlobalV0, 0, 2));
        GlobalV0 := 1;
        Pub.OnHeardWritten(GlobalV0, Seen);
        Observer.Observe('memberless, written R: seen>after', Seen + '>' + Format(GlobalV0) + '|' + Format(GlobalV0, 0, 2));
        Observer.Expect('with members, read: seen>after', 'Q|1>Second|1');
        Observer.Expect('with members, written R: seen>after', 'Q|1~R|2>Third|2');
        Observer.Expect('with members, ignored: after', 'Second|1');
        Observer.Expect('memberless, read: seen>after', 'Q|1>1|1');
        Observer.Expect('memberless, written R: seen>after', 'Q|1~R|2>2|2');
        Observer.Verify();
    end;

    [Test]
    procedure Parameters_HeardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        V0: Option;
        T: Text;
    begin
        V := V::Second;
        Observer.Observe('by-value with members: read>written', ByValueRaise(V));
        Observer.Observe('by-value with members: caller after', Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        Observer.Observe('by-value memberless: read>written', ByValueMemberlessRaise(V0));
        V := V::Second;
        T := VarWithMembersRaise(V);
        Observer.Observe('var with members: read>written>caller after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V := V::Second;
        T := VarMemberlessRaise(V);
        Observer.Observe('memberless var holding Second: read>written>caller after', T + '>' + Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        T := VarMemberlessRaise(V0);
        Observer.Observe('memberless var holding 1: read>written>caller after', T + '>' + Format(V0) + '|' + Format(V0, 0, 2));
        V := NamedReturnRaise(T);
        Observer.Observe('named return value: read>written', T);
        Observer.Observe('named return value: caller after', Format(V) + '|' + Format(V, 0, 2));
        Observer.Expect('by-value with members: read>written', 'Q|1>Second|1>Q|1~R|2>Third|2');
        Observer.Expect('by-value with members: caller after', 'Second|1');
        Observer.Expect('by-value memberless: read>written', 'Q|1>1|1>Q|1~R|2>2|2');
        Observer.Expect('var with members: read>written>caller after', 'Second|1>Second|1>Second|1~Third|2>Third|2>Third|2');
        Observer.Expect('memberless var holding Second: read>written>caller after', 'Second|1>Second|1>Second|1~Third|2>Third|2>Third|2');
        Observer.Expect('memberless var holding 1: read>written>caller after', '1|1>1|1>1|1~2|2>2|2>2|2');
        Observer.Expect('named return value: read>written', 'Q|1>Second|1>Q|1~R|2>Third|2');
        Observer.Expect('named return value: caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Fields_HeardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "OVH Row";
        Seen: Text;
    begin
        Row.Opt := Row.Opt::Second;
        Pub.OnHeardRead(Row.Opt, Seen);
        Observer.Observe('local record: read: seen>after', Seen + '>' + Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::Second;
        Pub.OnHeardWritten(Row.Opt, Seen);
        Observer.Observe('local record: written R: seen>after', Seen + '>' + Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.Opt := Row.Opt::Second;
        Pub.OnHeardIgnored(Row.Opt);
        Observer.Observe('local record: ignored: after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Row.OptCap := Row.OptCap::Second;
        Pub.OnHeardRead(Row.OptCap, Seen);
        Observer.Observe('caption field: read: seen>after', Seen + '>' + Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        Row.OptCap := Row.OptCap::Second;
        Pub.OnHeardWritten(Row.OptCap, Seen);
        Observer.Observe('caption field: written R: seen>after', Seen + '>' + Format(Row.OptCap) + '|' + Format(Row.OptCap, 0, 2));
        GlobalRow.Opt := GlobalRow.Opt::Second;
        Pub.OnHeardWritten(GlobalRow.Opt, Seen);
        Observer.Observe('global record: written R: seen>after', Seen + '>' + Format(GlobalRow.Opt) + '|' + Format(GlobalRow.Opt, 0, 2));
        Row.Opt := Row.Opt::Second;
        Observer.Observe('var record parameter: read>written', VarRecordRaise(Row));
        Observer.Observe('var record parameter: caller after', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        Observer.Expect('local record: read: seen>after', 'Q|1>Second|1');
        Observer.Expect('local record: written R: seen>after', 'Q|1~R|2>Third|2');
        Observer.Expect('local record: ignored: after', 'Second|1');
        Observer.Expect('caption field: read: seen>after', 'Q|1>Two|1');
        Observer.Expect('caption field: written R: seen>after', 'Q|1~R|2>Three|2');
        Observer.Expect('global record: written R: seen>after', 'Q|1~R|2>Third|2');
        Observer.Expect('var record parameter: read>written', 'Q|1>Second|1>Q|1~R|2>Third|2');
        Observer.Expect('var record parameter: caller after', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure Elements_HeardPublishers()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
        Arr0: array[2] of Option;
        Seen: Text;
    begin
        Arr[1] := Arr[1]::Second;
        Pub.OnHeardRead(Arr[1], Seen);
        Observer.Observe('local array: read: seen>after', Seen + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2));
        Arr[1] := Arr[1]::Second;
        Pub.OnHeardWritten(Arr[1], Seen);
        Observer.Observe('local array: written R: seen>after', Seen + '>' + Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '/' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        GlobalArr[1] := GlobalArr[1]::Second;
        Pub.OnHeardWritten(GlobalArr[1], Seen);
        Observer.Observe('global array: written R: seen>after', Seen + '>' + Format(GlobalArr[1]) + '|' + Format(GlobalArr[1], 0, 2));
        Arr0[1] := 1;
        Pub.OnHeardRead(Arr0[1], Seen);
        Observer.Observe('local memberless array: read: seen>after', Seen + '>' + Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2));
        Arr0[1] := 1;
        Pub.OnHeardWritten(Arr0[1], Seen);
        Observer.Observe('local memberless array: written R: seen>after', Seen + '>' + Format(Arr0[1]) + '|' + Format(Arr0[1], 0, 2));
        Observer.Expect('local array: read: seen>after', 'Q|1>Second|1');
        Observer.Expect('local array: written R: seen>after', 'Q|1~R|2>Third|2/First|0');
        Observer.Expect('global array: written R: seen>after', 'Q|1~R|2>Third|2');
        Observer.Expect('local memberless array: read: seen>after', 'Q|1>1|1');
        Observer.Expect('local memberless array: written R: seen>after', 'Q|1~R|2>2|2');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorAfterWrite_HeardPublisher()
    var
        Observer: Codeunit "Probe Observer";
        V: Option First,Second,Third;
        V0: Option;
    begin
        V := V::Second;
        asserterror Pub.OnHeardWrittenThenError(V);
        Observer.Observe('with members: error>after', GetLastErrorText() + '>' + Format(V) + '|' + Format(V, 0, 2));
        V0 := 1;
        asserterror Pub.OnHeardWrittenThenError(V0);
        Observer.Observe('memberless: error>after', GetLastErrorText() + '>' + Format(V0) + '|' + Format(V0, 0, 2));
        Observer.Expect('with members: error>after', 'OVH subscriber error>Third|2');
        Observer.Expect('memberless: error>after', 'OVH subscriber error>2|2');
        Observer.Verify();
    end;

    local procedure ByValueRaise(V: Option First,Second,Third): Text
    var
        Seen: Text;
        T: Text;
    begin
        Pub.OnHeardRead(V, Seen);
        T := Seen + '>' + Format(V) + '|' + Format(V, 0, 2);
        Pub.OnHeardWritten(V, Seen);
        exit(T + '>' + Seen + '>' + Format(V) + '|' + Format(V, 0, 2));
    end;

    local procedure ByValueMemberlessRaise(V: Option): Text
    var
        Seen: Text;
        T: Text;
    begin
        Pub.OnHeardRead(V, Seen);
        T := Seen + '>' + Format(V) + '|' + Format(V, 0, 2);
        Pub.OnHeardWritten(V, Seen);
        exit(T + '>' + Seen + '>' + Format(V) + '|' + Format(V, 0, 2));
    end;

    local procedure VarWithMembersRaise(var V: Option First,Second,Third): Text
    var
        Seen: Text;
        T: Text;
    begin
        Pub.OnHeardRead(V, Seen);
        T := Seen + '>' + Format(V) + '|' + Format(V, 0, 2);
        Pub.OnHeardWritten(V, Seen);
        exit(T + '>' + Seen + '>' + Format(V) + '|' + Format(V, 0, 2));
    end;

    local procedure VarMemberlessRaise(var V: Option): Text
    var
        Seen: Text;
        T: Text;
    begin
        Pub.OnHeardRead(V, Seen);
        T := Seen + '>' + Format(V) + '|' + Format(V, 0, 2);
        Pub.OnHeardWritten(V, Seen);
        exit(T + '>' + Seen + '>' + Format(V) + '|' + Format(V, 0, 2));
    end;

    local procedure NamedReturnRaise(var T: Text) V: Option First,Second,Third
    var
        Seen: Text;
    begin
        V := V::Second;
        Pub.OnHeardRead(V, Seen);
        T := Seen + '>' + Format(V) + '|' + Format(V, 0, 2);
        Pub.OnHeardWritten(V, Seen);
        T += '>' + Seen + '>' + Format(V) + '|' + Format(V, 0, 2);
    end;

    local procedure VarRecordRaise(var Row: Record "OVH Row"): Text
    var
        Seen: Text;
        T: Text;
    begin
        Pub.OnHeardRead(Row.Opt, Seen);
        T := Seen + '>' + Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2);
        Pub.OnHeardWritten(Row.Opt, Seen);
        exit(T + '>' + Seen + '>' + Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
    end;
}
