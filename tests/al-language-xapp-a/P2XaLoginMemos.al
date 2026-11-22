// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8239, probe P2; tests: tests/al-language/events/platform-triggers/P2LoginMemoTests.al): memos (SingleInstance codeunits
//   that fill their globals on first use) of a dependency app (XApp A, not the app under test, not Microsoft), filled or changed by the
//   "System Initialization".OnAfterLogin subscribers of XApp A (this file) and of XApp B (tests/al-language-xapp-b/P2XbLoginMemos.al).
//   - "LT P2 XA Bool Memo": two Booleans (Initialized, Value), filled by the XApp A subscriber (same app as the memo, one subscriber).
//   - "LT P2 XA Bool Memo Other": the same shape, filled by the XApp B subscriber (another app than the memo, one subscriber). This is the
//     DotNet-free stand-in for "Server Setting Impl." (System Application), which a partner subscriber fills through EnvironmentInformation.IsSaaS().
//   - "LT P2 XA Mixed Memo": a Text, an Integer and a List of [Text], set by the XApp B subscriber (another app, one subscriber).
//   - "LT P2 XA Two Subs Memo": an Integer counter and two Booleans, changed by both subscribers (XApp A and XApp B).
//   - "LT P2 XA Env Seen": what EnvironmentInformation.IsSaaS(), IsSandbox() and "Server Setting".GetEnableMembershipEntitlement() returned in the
//     XApp A subscriber. IsSaaS() fills the memos of "Environment Information Impl." and "Server Setting Impl." in the login session.
//   The subscribers never fail. The Raw procedures read a global without filling it.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29
using System.Environment;
using System.Environment.Configuration;

// singleinstance-shared-on-purpose: the probe is what a SingleInstance codeunit of a dependency app carries from the login into the test session
// and from one test codeunit to the next (two test codeunits read the same instances).
codeunit 98490 "LT P2 XA Bool Memo"
{
    SingleInstance = true;

    var
        Initialized: Boolean;
        Value: Boolean;
        Fills: Integer;

    local procedure Initialize()
    begin
        if Initialized then
            exit;
        Value := true;
        Initialized := true;
        Fills += 1;
    end;

    procedure IsOn(): Boolean
    begin
        Initialize();
        exit(Value);
    end;

    procedure SetValue(NewValue: Boolean)
    begin
        Value := NewValue;
    end;

    procedure RawInitialized(): Boolean
    begin
        exit(Initialized);
    end;

    procedure RawValue(): Boolean
    begin
        exit(Value);
    end;

    procedure RawFills(): Integer
    begin
        exit(Fills);
    end;
}

codeunit 98491 "LT P2 XA Bool Memo Other"
{
    SingleInstance = true;

    var
        Initialized: Boolean;
        Value: Boolean;
        Fills: Integer;

    local procedure Initialize()
    begin
        if Initialized then
            exit;
        Value := true;
        Initialized := true;
        Fills += 1;
    end;

    procedure IsOn(): Boolean
    begin
        Initialize();
        exit(Value);
    end;

    procedure SetValue(NewValue: Boolean)
    begin
        Value := NewValue;
    end;

    procedure RawInitialized(): Boolean
    begin
        exit(Initialized);
    end;

    procedure RawValue(): Boolean
    begin
        exit(Value);
    end;

    procedure RawFills(): Integer
    begin
        exit(Fills);
    end;
}

codeunit 98492 "LT P2 XA Mixed Memo"
{
    SingleInstance = true;

    var
        Txt: Text;
        Num: Integer;
        Names: List of [Text];

    procedure SetFromLogin()
    begin
        Txt += 'L';
        Num += 10;
        Names.Add('login');
    end;

    procedure ChangeFromTest()
    begin
        Txt += 'T';
        Num += 1;
        Names.Add('test');
    end;

    procedure RawTxt(): Text
    begin
        exit(Txt);
    end;

    procedure RawNum(): Integer
    begin
        exit(Num);
    end;

    procedure RawNames(): Text
    var
        Name: Text;
        Joined: Text;
    begin
        foreach Name in Names do
            Joined += Name + ';';
        exit(Format(Names.Count()) + ':' + Joined);
    end;
}

codeunit 98493 "LT P2 XA Two Subs Memo"
{
    SingleInstance = true;

    var
        Calls: Integer;
        FromA: Boolean;
        FromB: Boolean;

    procedure AddFrom(Who: Text)
    begin
        Calls += 1;
        case Who of
            'A':
                FromA := true;
            'B':
                FromB := true;
        end;
    end;

    procedure RawCalls(): Integer
    begin
        exit(Calls);
    end;

    procedure RawFromA(): Boolean
    begin
        exit(FromA);
    end;

    procedure RawFromB(): Boolean
    begin
        exit(FromB);
    end;
}

codeunit 98494 "LT P2 XA Env Seen"
{
    SingleInstance = true;

    var
        Calls: Integer;
        SawSaaS: Boolean;
        SawSandbox: Boolean;
        SawEntitlement: Boolean;

    procedure Record()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
    begin
        Calls += 1;
        SawSaaS := EnvironmentInformation.IsSaaS();
        SawSandbox := EnvironmentInformation.IsSandbox();
        SawEntitlement := ServerSetting.GetEnableMembershipEntitlement();
    end;

    procedure RawCalls(): Integer
    begin
        exit(Calls);
    end;

    procedure RawSaaS(): Boolean
    begin
        exit(SawSaaS);
    end;

    procedure RawSandbox(): Boolean
    begin
        exit(SawSandbox);
    end;

    procedure RawEntitlement(): Boolean
    begin
        exit(SawEntitlement);
    end;
}

codeunit 98495 "LT P2 XA Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
        EnvSeen: Codeunit "LT P2 XA Env Seen";
    begin
        if BoolMemo.IsOn() then;
        TwoSubs.AddFrom('A');
        EnvSeen.Record();
    end;
}
