// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), publisher 71063, static subscribers 71064 and 71065, log 71062 (used by exactly one test codeunit, 71066)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: BusinessEvent / IntegrationEvent with static [EventSubscriber]: order through a log, IsHandled, var parameters, errors in subscribers
// BC versions: 29 (27 and 28 by CI)

codeunit 71062 "LT OjT Event Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        exit(Lines.Get(Index));
    end;
}

codeunit 71063 "LT OjT Event Pub"
{
    procedure RaiseBusiness(var Value: Integer; Name: Text)
    begin
        OnBusiness(Value, Name);
    end;

    procedure RaiseIntegration(var Value: Integer)
    begin
        OnIntegration(Value);
    end;

    procedure RaiseNoSubscriber(): Text
    begin
        OnNoSubscriber();
        exit('done');
    end;

    procedure RaiseOrder()
    begin
        OnOrder();
    end;

    procedure DoWork(var Result: Text): Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeWork(Result, IsHandled);
        if IsHandled then
            exit(true);
        Result := Result + '|default';
        exit(false);
    end;

    procedure RaiseFailing()
    begin
        OnFailing();
    end;

    procedure RaiseTwiceInLoop()
    var
        i: Integer;
        V: Integer;
    begin
        for i := 1 to 2 do begin
            V := i;
            OnIntegration(V);
        end;
    end;

    [BusinessEvent(false)]
    local procedure OnBusiness(var Value: Integer; Name: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIntegration(var Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNoSubscriber()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOrder()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWork(var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFailing()
    begin
    end;
}

codeunit 71064 "LT OjT Subs A"
{
    var
        Log: Codeunit "LT OjT Event Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnBusiness', '', false, false)]
    local procedure BusinessA(var Value: Integer; Name: Text)
    begin
        Log.Add('A.business ' + Name + ' ' + Format(Value));
        Value += 10;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnIntegration', '', false, false)]
    local procedure IntegrationA(var Value: Integer)
    begin
        Log.Add('A.integration ' + Format(Value));
        Value := Value * 2;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnOrder', '', false, false)]
    local procedure OrderA()
    begin
        Log.Add('A.order');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnBeforeWork', '', false, false)]
    local procedure BeforeWorkA(var Result: Text; var IsHandled: Boolean)
    begin
        Log.Add('A.beforeWork ' + Result + ' handled=' + Format(IsHandled));
        if Result = 'handleA' then begin
            Result := 'handledByA';
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnFailing', '', false, false)]
    local procedure FailingA()
    begin
        Log.Add('A.failing');
        Error('subscriber A failed');
    end;
}

codeunit 71065 "LT OjT Subs B"
{
    var
        Log: Codeunit "LT OjT Event Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnBusiness', '', false, false)]
    local procedure BusinessB(var Value: Integer; Name: Text)
    begin
        Log.Add('B.business ' + Name + ' ' + Format(Value));
        Value += 100;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnIntegration', '', false, false)]
    local procedure IntegrationB(var Value: Integer)
    begin
        Log.Add('B.integration ' + Format(Value));
        Value += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnOrder', '', false, false)]
    local procedure OrderB()
    begin
        Log.Add('B.order');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnBeforeWork', '', false, false)]
    local procedure BeforeWorkB(var Result: Text; var IsHandled: Boolean)
    begin
        Log.Add('B.beforeWork ' + Result + ' handled=' + Format(IsHandled));
        if Result.StartsWith('handleB') then begin
            Result := 'handledByB';
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Event Pub", 'OnFailing', '', false, false)]
    local procedure FailingB()
    begin
        Log.Add('B.failing');
    end;
}

codeunit 71066 "LT OjT Events Static"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT OjT Event Log";

    local procedure Dump(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('logCount', Format(Log.Count()));
        for i := 1 to Log.Count() do begin
            Observer.Observe('log' + Format(i), Log.Get(i));
        end;
    end;

    [Test]
    procedure Business_VarParameterAndOrder()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
        V: Integer;
    begin
        Log.Reset();
        V := 1;
        Pub.RaiseBusiness(V, 'n');
        Observer.Observe('value', Format(V));
        Dump(Observer);
        Observer.Expect('value', '111');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'A.business n 1');
        Observer.Expect('log2', 'B.business n 11');
        Observer.Verify();
    end;

    [Test]
    procedure Integration_VarParameterAndOrder()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
        V: Integer;
    begin
        Log.Reset();
        V := 5;
        Pub.RaiseIntegration(V);
        Observer.Observe('value', Format(V));
        Dump(Observer);
        Observer.Expect('value', '11');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'A.integration 5');
        Observer.Expect('log2', 'B.integration 10');
        Observer.Verify();
    end;

    [Test]
    procedure Integration_RaisedTwice()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
    begin
        Log.Reset();
        Pub.RaiseTwiceInLoop();
        Dump(Observer);
        Observer.Expect('logCount', '4');
        Observer.Expect('log1', 'A.integration 1');
        Observer.Expect('log2', 'B.integration 2');
        Observer.Expect('log3', 'A.integration 2');
        Observer.Expect('log4', 'B.integration 4');
        Observer.Verify();
    end;

    [Test]
    procedure Order_NoParameters()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
    begin
        Log.Reset();
        Pub.RaiseOrder();
        Dump(Observer);
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'A.order');
        Observer.Expect('log2', 'B.order');
        Observer.Verify();
    end;

    [Test]
    procedure NoSubscriber_Runs()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
    begin
        Log.Reset();
        Observer.Observe('result', Pub.RaiseNoSubscriber());
        Observer.Observe('logCount', Format(Log.Count()));
        Observer.Expect('result', 'done');
        Observer.Expect('logCount', '0');
        Observer.Verify();
    end;

    [Test]
    procedure IsHandled_NotHandled()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
        R: Text;
    begin
        Log.Reset();
        R := 'plain';
        Observer.Observe('handled', Format(Pub.DoWork(R)));
        Observer.Observe('result', R);
        Dump(Observer);
        Observer.Expect('handled', 'No');
        Observer.Expect('result', 'plain|default');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'A.beforeWork plain handled=No');
        Observer.Expect('log2', 'B.beforeWork plain handled=No');
        Observer.Verify();
    end;

    [Test]
    procedure IsHandled_HandledByFirst()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
        R: Text;
    begin
        Log.Reset();
        R := 'handleA';
        Observer.Observe('handled', Format(Pub.DoWork(R)));
        Observer.Observe('result', R);
        Dump(Observer);
        Observer.Expect('handled', 'Yes');
        Observer.Expect('result', 'handledByA');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'A.beforeWork handleA handled=No');
        Observer.Expect('log2', 'B.beforeWork handledByA handled=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure IsHandled_HandledBySecond()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
        R: Text;
    begin
        Log.Reset();
        R := 'handleB';
        Observer.Observe('handled', Format(Pub.DoWork(R)));
        Observer.Observe('result', R);
        Dump(Observer);
        Observer.Expect('handled', 'Yes');
        Observer.Expect('result', 'handledByB');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'A.beforeWork handleB handled=No');
        Observer.Expect('log2', 'B.beforeWork handleB handled=No');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_RaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Event Pub";
    begin
        Log.Reset();
        asserterror Pub.RaiseFailing();
        Observer.ObserveError('failing');
        Dump(Observer);
        Observer.Expect('failing|text', 'subscriber A failed');
        Observer.Expect('failing|code', 'Dialog');
        Observer.Expect('logCount', '1');
        Observer.Expect('log1', 'A.failing');
        Observer.Verify();
    end;
}
