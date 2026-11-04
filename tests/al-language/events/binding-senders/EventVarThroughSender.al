// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 74360 (publisher), 74361 (reader subscriber), 74362 (assigning subscriber), 74363 (assign-first subscriber), 74364 (tests); writer RO: 88443 (nested subscriber), 88444/88445 (InternalEvent repro)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a codeunit passes its GLOBAL Boolean, Integer and Text variables as var arguments to an [IntegrationEvent(true, false)] event. A subscriber with var Sender calls a procedure
//   of the sender that sets those globals. What the globals hold after the event, what the subscriber's own parameters hold right after the sender call, and which value wins when
//   the subscriber also assigns a parameter (after the sender call, or before it). Corpus issue 571 (event-var-alias-through-sender).
// BC versions: 29 (27 and 28 by CI)

codeunit 74360 "LT EvVar Pub"
{
    var
        LineCreated: Boolean;
        Counter: Integer;
        Note: Text;

    procedure Start()
    begin
        LineCreated := false;
        Counter := 1;
        Note := 'initial';
    end;

    procedure RaiseWithGlobals()
    begin
        OnWork(LineCreated, Counter, Note);
    end;

    procedure RaiseWithLocals(var LocalCreated: Boolean; var LocalCounter: Integer; var LocalNote: Text)
    begin
        OnWork(LocalCreated, LocalCounter, LocalNote);
    end;

    procedure SetFromSender()
    begin
        LineCreated := true;
        Counter := 5;
        Note := 'set by sender';
    end;

    procedure GetCreated(): Boolean
    begin
        exit(LineCreated);
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure GetNote(): Text
    begin
        exit(Note);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWork(var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
    end;
}

// Calls the sender's procedure and does not assign its own parameters.
codeunit 74361 "LT EvVar Reader Sub"
{
    EventSubscriberInstance = Manual;

    var
        BeforeCreated: Boolean;
        BeforeCount: Integer;
        BeforeText: Text;
        AfterCreated: Boolean;
        AfterCount: Integer;
        AfterText: Text;
        EndCreated: Boolean;
        EndCount: Integer;
        EndText: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        BeforeCreated := Created;
        BeforeCount := Count;
        BeforeText := Txt;
        Sender.SetFromSender();
        AfterCreated := Created;
        AfterCount := Count;
        AfterText := Txt;
        EndCreated := Created;
        EndCount := Count;
        EndText := Txt;
    end;

    procedure Seen(Which: Text): Text
    begin
        case Which of
            'before':
                exit(Format(BeforeCreated) + '/' + Format(BeforeCount) + '/' + BeforeText);
            'after':
                exit(Format(AfterCreated) + '/' + Format(AfterCount) + '/' + AfterText);
        end;
    end;
}

// Calls the sender's procedure, then assigns Count and Txt (not Created).
codeunit 74362 "LT EvVar Assign Sub"
{
    EventSubscriberInstance = Manual;

    var
        AfterSenderCount: Integer;
        AfterSenderText: Text;
        AfterAssignCount: Integer;
        AfterAssignText: Text;
        SenderCounterAfterAssign: Integer;
        SenderNoteAfterAssign: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        Sender.SetFromSender();
        AfterSenderCount := Count;
        AfterSenderText := Txt;
        Count := 99;
        Txt := 'set by subscriber';
        AfterAssignCount := Count;
        AfterAssignText := Txt;
        SenderCounterAfterAssign := Sender.GetCounter();
        SenderNoteAfterAssign := Sender.GetNote();
    end;

    procedure Seen(): Text
    begin
        exit(Format(AfterSenderCount) + '/' + AfterSenderText + '/' + Format(AfterAssignCount) + '/' + AfterAssignText + '/' + Format(SenderCounterAfterAssign) + '/' + SenderNoteAfterAssign);
    end;
}

// Assigns Count and Txt first, then calls the sender's procedure.
codeunit 74363 "LT EvVar AssignFirst Sub"
{
    EventSubscriberInstance = Manual;

    var
        AfterSenderCount: Integer;
        AfterSenderText: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        Count := 77;
        Txt := 'assigned first';
        Sender.SetFromSender();
        AfterSenderCount := Count;
        AfterSenderText := Txt;
    end;

    procedure Seen(): Text
    begin
        exit(Format(AfterSenderCount) + '/' + AfterSenderText);
    end;
}

codeunit 74364 "LT EvVar Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EventVar_GlobalsPassedAsVar_SenderSetsThem_NoAssignInSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar Reader Sub";
    begin
        Pub.Start();
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('globalNote', Pub.GetNote());
        Observer.Observe('paramsBeforeSenderCall', Sub.Seen('before'));
        Observer.Observe('paramsAfterSenderCall', Sub.Seen('after'));
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '5');
        Observer.Expect('globalNote', 'set by sender');
        Observer.Expect('paramsBeforeSenderCall', 'No/1/initial');
        Observer.Expect('paramsAfterSenderCall', 'Yes/5/set by sender');
        Observer.Verify();
    end;

    [Test]
    procedure EventVar_GlobalsPassedAsVar_SubscriberAssignsAfterSenderCall()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar Assign Sub";
    begin
        Pub.Start();
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('globalNote', Pub.GetNote());
        Observer.Observe('subscriberSeen', Sub.Seen());
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '99');
        Observer.Expect('globalNote', 'set by subscriber');
        Observer.Expect('subscriberSeen', '5/set by sender/99/set by subscriber/99/set by subscriber');
        Observer.Verify();
    end;

    [Test]
    procedure EventVar_GlobalsPassedAsVar_SubscriberAssignsBeforeSenderCall()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar AssignFirst Sub";
    begin
        Pub.Start();
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('globalNote', Pub.GetNote());
        Observer.Observe('subscriberSeen', Sub.Seen());
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '5');
        Observer.Expect('globalNote', 'set by sender');
        Observer.Expect('subscriberSeen', '5/set by sender');
        Observer.Verify();
    end;

    [Test]
    procedure EventVar_LocalsPassedAsVar_SenderSetsGlobals_LocalsKeepTheirOwnValue()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar Reader Sub";
        LocalCreated: Boolean;
        LocalCounter: Integer;
        LocalNote: Text;
    begin
        // Control: the arguments are caller-owned variables that are not the sender's globals.
        Pub.Start();
        LocalCounter := 10;
        LocalNote := 'local';
        BindSubscription(Sub);
        Pub.RaiseWithLocals(LocalCreated, LocalCounter, LocalNote);
        UnbindSubscription(Sub);
        Observer.Observe('localCreated', Format(LocalCreated));
        Observer.Observe('localCounter', Format(LocalCounter));
        Observer.Observe('localNote', LocalNote);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('paramsAfterSenderCall', Sub.Seen('after'));
        Observer.Expect('localCreated', 'No');
        Observer.Expect('localCounter', '10');
        Observer.Expect('localNote', 'local');
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '5');
        Observer.Expect('paramsAfterSenderCall', 'No/10/local');
        Observer.Verify();
    end;

    // Writer RO (al-runner issue 5754): the subscriber hands its var parameters and Sender on to procedures of its own, which set the
    // parameters and then call back through Sender (codeunit 88443 "LT RO EvVar Nested Sub", modes below); and the reporter's shape
    // with an [InternalEvent(true)] whose publisher passes one global Boolean (codeunits 88444, 88445).
    local procedure RoNested(Mode: Integer): Text
    var
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT RO EvVar Nested Sub";
    begin
        Pub.Start();
        Sub.SetMode(Mode);
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        exit(Sub.Seen() + 'globals:' + Format(Pub.GetCreated()) + '/' + Format(Pub.GetCounter()) + '/' + Pub.GetNote());
    end;

    [Test]
    procedure RO_EventVar_NestedProcedure_SetsParams_ReadsThroughSender()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1 subscriber sets, reads sender', RoNested(1));
        Observer.Observe('2 nested var sender', RoNested(2));
        Observer.Observe('3 nested sender by value', RoNested(3));
        Observer.Observe('4 two levels', RoNested(4));
        Observer.Observe('5 nested, sender sets, nested reads params', RoNested(5));
        Observer.Observe('6 nested, params by value', RoNested(6));
        Observer.Observe('7 nested sets, subscriber reads sender after return', RoNested(7));
        Observer.Expect('1 subscriber sets, reads sender', 'sender:Yes/42/set by subscriber;params at end:Yes/42/set by subscriber;globals:Yes/42/set by subscriber');
        Observer.Expect('2 nested var sender', 'sender:Yes/42/set by nested;params at end:Yes/42/set by nested;globals:Yes/42/set by nested');
        Observer.Expect('3 nested sender by value', 'value sender:Yes/42/set by nested;params at end:Yes/42/set by nested;globals:Yes/42/set by nested');
        Observer.Expect('4 two levels', 'sender:Yes/42/set by nested;sender in outer:Yes/42/set by nested;params at end:Yes/42/set by nested;globals:Yes/42/set by nested');
        Observer.Expect('5 nested, sender sets, nested reads params', 'nested params:Yes/5/set by sender;params at end:Yes/5/set by sender;globals:Yes/5/set by sender');
        Observer.Expect('6 nested, params by value', 'sender:No/1/initial;params at end:No/1/initial;globals:No/1/initial');
        Observer.Expect('7 nested sets, subscriber reads sender after return', 'sender after return:Yes/42/set by nested;params at end:Yes/42/set by nested;globals:Yes/42/set by nested');
        Observer.Verify();
    end;

    [Test]
    procedure RO_EventVar_InternalEvent_Repro()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT RO EvVar Flag Holder";
        Setter: Codeunit "LT RO EvVar Flag Setter";
        Result: Boolean;
    begin
        BindSubscription(Setter);
        Result := Holder.Go(false);
        Observer.Observe('direct: sender saw', Format(Setter.GetFlagSeenBySender()));
        Observer.Observe('direct: after event', Format(Result));
        Result := Holder.Go(true);
        Observer.Observe('nested: sender saw', Format(Setter.GetFlagSeenBySender()));
        Observer.Observe('nested: after event', Format(Result));
        UnbindSubscription(Setter);
        Observer.Expect('direct: sender saw', 'Yes');
        Observer.Expect('direct: after event', 'Yes');
        Observer.Expect('nested: sender saw', 'Yes');
        Observer.Expect('nested: after event', 'Yes');
        Observer.Verify();
    end;
}

// Writer RO: a subscriber of OnWork that passes its var parameters and Sender to its own procedures (al-runner issue 5754).
//   1 sets the parameters itself, then reads through Sender (control);
//   2 a procedure with var parameters and var Sender sets them, then reads through Sender;
//   3 the same with Sender passed by value;
//   4 two procedures deep (var all the way), the inner one sets and reads through Sender;
//   5 a procedure with var parameters calls Sender.SetFromSender, then reads its own parameters;
//   6 a procedure that takes the parameters by value sets its copies, then reads through Sender;
//   7 a procedure sets the parameters; the subscriber reads through Sender after it returns.
codeunit 88443 "LT RO EvVar Nested Sub"
{
    EventSubscriberInstance = Manual;

    var
        Mode: Integer;
        Trace: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        Trace := '';
    end;

    procedure Seen(): Text
    begin
        exit(Trace);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        case Mode of
            1:
                begin
                    Created := true;
                    Count := 42;
                    Txt := 'set by subscriber';
                    ReadSender('sender', Sender);
                end;
            2:
                SetThenReadVarSender(Created, Count, Txt, Sender);
            3:
                SetThenReadValueSender(Created, Count, Txt, Sender);
            4:
                Outer(Created, Count, Txt, Sender);
            5:
                SenderSetsThenReadParams(Created, Count, Txt, Sender);
            6:
                SetCopiesThenReadSender(Created, Count, Txt, Sender);
            7:
                begin
                    SetOnly(Created, Count, Txt);
                    ReadSender('sender after return', Sender);
                end;
        end;
        Trace += 'params at end:' + Format(Created) + '/' + Format(Count) + '/' + Txt + ';';
    end;

    local procedure ReadSender(Name: Text; var Sender: Codeunit "LT EvVar Pub")
    begin
        Trace += Name + ':' + Format(Sender.GetCreated()) + '/' + Format(Sender.GetCounter()) + '/' + Sender.GetNote() + ';';
    end;

    local procedure SetOnly(var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        Created := true;
        Count := 42;
        Txt := 'set by nested';
    end;

    local procedure SetThenReadVarSender(var Created: Boolean; var Count: Integer; var Txt: Text; var Sender: Codeunit "LT EvVar Pub")
    begin
        SetOnly(Created, Count, Txt);
        ReadSender('sender', Sender);
    end;

    local procedure SetThenReadValueSender(var Created: Boolean; var Count: Integer; var Txt: Text; Sender: Codeunit "LT EvVar Pub")
    begin
        Created := true;
        Count := 42;
        Txt := 'set by nested';
        Trace += 'value sender:' + Format(Sender.GetCreated()) + '/' + Format(Sender.GetCounter()) + '/' + Sender.GetNote() + ';';
    end;

    local procedure Outer(var Created: Boolean; var Count: Integer; var Txt: Text; var Sender: Codeunit "LT EvVar Pub")
    begin
        SetThenReadVarSender(Created, Count, Txt, Sender);
        ReadSender('sender in outer', Sender);
    end;

    local procedure SenderSetsThenReadParams(var Created: Boolean; var Count: Integer; var Txt: Text; var Sender: Codeunit "LT EvVar Pub")
    begin
        Sender.SetFromSender();
        Trace += 'nested params:' + Format(Created) + '/' + Format(Count) + '/' + Txt + ';';
    end;

    local procedure SetCopiesThenReadSender(Created: Boolean; Count: Integer; Txt: Text; var Sender: Codeunit "LT EvVar Pub")
    begin
        Created := true;
        Count := 42;
        Txt := 'set by nested copy';
        ReadSender('sender', Sender);
    end;
}

// Writer RO: the reporter's shape of al-runner issue 5754 (codeunit 22 "Item Jnl.-Post Line" passes its global LastOperation by var
// to the InternalEvent OnPostOutput; the subscriber hands it with Sender to PostOutput, which sets it and calls back through Sender).
codeunit 88444 "LT RO EvVar Flag Holder"
{
    var
        Flag: Boolean;
        Nested: Boolean;

    procedure Go(SetInNestedProcedure: Boolean): Boolean
    begin
        Nested := SetInNestedProcedure;
        Flag := false;
        OnSetFlag(Flag);
        exit(Flag);
    end;

    procedure IsNested(): Boolean
    begin
        exit(Nested);
    end;

    procedure ReadFlag(): Boolean
    begin
        exit(Flag);
    end;

    [InternalEvent(true)]
    local procedure OnSetFlag(var NewFlag: Boolean)
    begin
    end;
}

codeunit 88445 "LT RO EvVar Flag Setter"
{
    EventSubscriberInstance = Manual;

    var
        FlagSeenBySender: Boolean;

    procedure GetFlagSeenBySender(): Boolean
    begin
        exit(FlagSeenBySender);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT RO EvVar Flag Holder", 'OnSetFlag', '', false, false)]
    local procedure OnSetFlag(var NewFlag: Boolean; var sender: Codeunit "LT RO EvVar Flag Holder")
    begin
        FlagSeenBySender := false;
        if sender.IsNested() then begin
            SetFlagThenReadItBack(NewFlag, sender);
            exit;
        end;

        NewFlag := true;
        FlagSeenBySender := sender.ReadFlag();
    end;

    local procedure SetFlagThenReadItBack(var NewFlag: Boolean; var sender: Codeunit "LT RO EvVar Flag Holder")
    begin
        NewFlag := true;
        FlagSeenBySender := sender.ReadFlag();
    end;
}
