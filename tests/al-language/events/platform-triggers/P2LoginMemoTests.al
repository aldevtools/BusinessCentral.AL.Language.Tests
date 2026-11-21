// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/P2XaLoginMemos.al (memos 98490-98494, OnAfterLogin subscriber 98495);
//   XApp B tests/al-language-xapp-b/P2XbLoginMemos.al (OnAfterLogin subscriber 98500); table 97930 below.
// Probe (al-runner issue 8239, probe P2): what the test session finds in the globals of a dependency app's memo (a SingleInstance codeunit that fills
//   its globals on first use) after the OnAfterLogin subscribers of the partner dependency apps filled or changed it. Cells:
//   - memo of the subscriber's own app vs memo of another app (XApp B's subscriber fills an XApp A memo, the stand-in for "Server Setting Impl.");
//   - one subscriber vs two subscribers (XApp A and XApp B) changing the same memo;
//   - Boolean globals vs Text, Integer and List of [Text] globals;
//   - the real "Server Setting Impl." and "Environment Information Impl." memos, filled by EnvironmentInformation.IsSaaS() in the XApp A subscriber
//     (only the values are observable: the test compares what it reads with what the login saw, never the host's own values);
//   - (a) a test that reads the memo, (b) a test that writes a row whose OnInsert reads it, (c) a test that reads nothing;
//   - a memo changed again by a test, read by the next test of the same codeunit and by a second test codeunit.
// BC result (measured on BC 27.5, 28.5 and 29.0, the same on all three): the OnAfterLogin subscribers of both dependency apps ran once, in the
//   test session, before the first test. Every memo keeps what the login left, whatever app it lives in and whatever app's subscriber changed it:
//   the Boolean memos are filled once (Initialized Yes, Value Yes, one fill; reading them again does not refill), the Text/Integer/List memo
//   holds L, 10 and one name, the memo two subscribers changed holds both changes (2 calls). The real "Server Setting Impl." and
//   "Environment Information Impl." memos give the test and the OnInsert trigger the same IsSaaS(), IsSandbox() and
//   GetEnableMembershipEntitlement() values the login saw. A row insert whose OnInsert reads a memo works and reads the same state. A test that
//   reads nothing runs. A change made by a test (Value := false, Text += 'T', Integer += 1, List.Add, one more call) stays: the next test,
//   the next OnInsert and a second test codeunit see it, and the login does not run again.
// BC versions: 27 - 29
using System.Environment;
using System.Environment.Configuration;

table 97930 "LT P2 Memo Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Kind; Integer) { }
        field(3; BoolValue; Boolean) { }
        field(4; MixedTxt; Text[50]) { }
        field(5; MixedNum; Integer) { }
        field(6; MixedNames; Text[100]) { }
        field(7; TwoSubsCalls; Integer) { }
        field(8; EnvSaaS; Boolean) { }
        field(9; EnvSandbox; Boolean) { }
        field(10; EnvEntitlement; Boolean) { }
        field(11; InsertRan; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
        Mixed: Codeunit "LT P2 XA Mixed Memo";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
    begin
        InsertRan := true;
        case Kind of
            1:
                BoolValue := BoolMemo.IsOn();
            2:
                BoolValue := BoolMemoOther.IsOn();
            3:
                begin
                    MixedTxt := CopyStr(Mixed.RawTxt(), 1, MaxStrLen(MixedTxt));
                    MixedNum := Mixed.RawNum();
                    MixedNames := CopyStr(Mixed.RawNames(), 1, MaxStrLen(MixedNames));
                end;
            4:
                TwoSubsCalls := TwoSubs.RawCalls();
            5:
                begin
                    EnvSaaS := EnvironmentInformation.IsSaaS();
                    EnvSandbox := EnvironmentInformation.IsSandbox();
                    EnvEntitlement := ServerSetting.GetEnableMembershipEntitlement();
                end;
        end;
    end;
}

codeunit 97931 "LT P2 Login Memo A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P2A_01_ReadsNothing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ran', 'yes');
        Observer.Expect('ran', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_02_BoolSameApp_Read()
    var
        Observer: Codeunit "Probe Observer";
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
    begin
        Observer.Observe('raw initialized', Format(BoolMemo.RawInitialized()));
        Observer.Observe('raw value', Format(BoolMemo.RawValue()));
        Observer.Observe('raw fills', Format(BoolMemo.RawFills()));
        Observer.Observe('is on', Format(BoolMemo.IsOn()));
        Observer.Observe('fills after is on', Format(BoolMemo.RawFills()));
        Observer.Expect('raw initialized', 'Yes');
        Observer.Expect('raw value', 'Yes');
        Observer.Expect('raw fills', '1');
        Observer.Expect('is on', 'Yes');
        Observer.Expect('fills after is on', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_03_BoolOtherApp_Read()
    var
        Observer: Codeunit "Probe Observer";
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
    begin
        Observer.Observe('raw initialized', Format(BoolMemoOther.RawInitialized()));
        Observer.Observe('raw value', Format(BoolMemoOther.RawValue()));
        Observer.Observe('raw fills', Format(BoolMemoOther.RawFills()));
        Observer.Observe('is on', Format(BoolMemoOther.IsOn()));
        Observer.Observe('fills after is on', Format(BoolMemoOther.RawFills()));
        Observer.Expect('raw initialized', 'Yes');
        Observer.Expect('raw value', 'Yes');
        Observer.Expect('raw fills', '1');
        Observer.Expect('is on', 'Yes');
        Observer.Expect('fills after is on', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_04_MixedOtherApp_Read()
    var
        Observer: Codeunit "Probe Observer";
        Mixed: Codeunit "LT P2 XA Mixed Memo";
    begin
        Observer.Observe('txt', Mixed.RawTxt());
        Observer.Observe('num', Format(Mixed.RawNum()));
        Observer.Observe('names', Mixed.RawNames());
        Observer.Expect('txt', 'L');
        Observer.Expect('num', '10');
        Observer.Expect('names', '1:login;');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_05_TwoSubs_Read()
    var
        Observer: Codeunit "Probe Observer";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
    begin
        Observer.Observe('calls', Format(TwoSubs.RawCalls()));
        Observer.Observe('from a', Format(TwoSubs.RawFromA()));
        Observer.Observe('from b', Format(TwoSubs.RawFromB()));
        Observer.Expect('calls', '2');
        Observer.Expect('from a', 'Yes');
        Observer.Expect('from b', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_06_ServerSettingMemo_Read()
    var
        Observer: Codeunit "Probe Observer";
        EnvSeen: Codeunit "LT P2 XA Env Seen";
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
    begin
        Observer.Observe('login calls', Format(EnvSeen.RawCalls()));
        Observer.Observe('saas equals login', Format(EnvironmentInformation.IsSaaS() = EnvSeen.RawSaaS()));
        Observer.Observe('sandbox equals login', Format(EnvironmentInformation.IsSandbox() = EnvSeen.RawSandbox()));
        Observer.Observe('entitlement equals login', Format(ServerSetting.GetEnableMembershipEntitlement() = EnvSeen.RawEntitlement()));
        Observer.Expect('login calls', '1');
        Observer.Expect('saas equals login', 'Yes');
        Observer.Expect('sandbox equals login', 'Yes');
        Observer.Expect('entitlement equals login', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_07_BoolSameApp_InsertReads()
    var
        Observer: Codeunit "Probe Observer";
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
    begin
        InsertKind(1, 1, Observer);
        Observer.Observe('fills', Format(BoolMemo.RawFills()));
        Observer.Expect('1 insert ran', 'Yes');
        Observer.Expect('1 bool value', 'Yes');
        Observer.Expect('fills', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_08_BoolOtherApp_InsertReads()
    var
        Observer: Codeunit "Probe Observer";
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
    begin
        InsertKind(2, 2, Observer);
        Observer.Observe('fills', Format(BoolMemoOther.RawFills()));
        Observer.Expect('2 insert ran', 'Yes');
        Observer.Expect('2 bool value', 'Yes');
        Observer.Expect('fills', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_09_MixedOtherApp_InsertReads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertKind(3, 3, Observer);
        Observer.Expect('3 insert ran', 'Yes');
        Observer.Expect('3 mixed txt', 'L');
        Observer.Expect('3 mixed num', '10');
        Observer.Expect('3 mixed names', '1:login;');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_10_TwoSubs_InsertReads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertKind(4, 4, Observer);
        Observer.Expect('4 insert ran', 'Yes');
        Observer.Expect('4 two subs calls', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_11_ServerSettingMemo_InsertReads()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P2 Memo Row";
        EnvSeen: Codeunit "LT P2 XA Env Seen";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 5;
        Row.Kind := 5;
        Row.Insert(true);
        Row.Get(5);
        Observer.Observe('insert ran', Format(Row.InsertRan));
        Observer.Observe('row saas equals login', Format(Row.EnvSaaS = EnvSeen.RawSaaS()));
        Observer.Observe('row sandbox equals login', Format(Row.EnvSandbox = EnvSeen.RawSandbox()));
        Observer.Observe('row entitlement equals login', Format(Row.EnvEntitlement = EnvSeen.RawEntitlement()));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('insert ran', 'Yes');
        Observer.Expect('row saas equals login', 'Yes');
        Observer.Expect('row sandbox equals login', 'Yes');
        Observer.Expect('row entitlement equals login', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_12_ChangedByTest_ThenRead()
    var
        Observer: Codeunit "Probe Observer";
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
        Mixed: Codeunit "LT P2 XA Mixed Memo";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
    begin
        BoolMemo.SetValue(false);
        BoolMemoOther.SetValue(false);
        Mixed.ChangeFromTest();
        TwoSubs.AddFrom('T');
        ObserveAll(Observer);
        Observer.Expect('same initialized', 'Yes');
        Observer.Expect('same value', 'No');
        Observer.Expect('same fills', '1');
        Observer.Expect('other initialized', 'Yes');
        Observer.Expect('other value', 'No');
        Observer.Expect('other fills', '1');
        Observer.Expect('mixed txt', 'LT');
        Observer.Expect('mixed num', '11');
        Observer.Expect('mixed names', '2:login;test;');
        Observer.Expect('two subs calls', '3');
        Observer.Expect('two subs from a', 'Yes');
        Observer.Expect('two subs from b', 'Yes');
        Observer.Expect('env login calls', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_13_AfterChange_NextTestReads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer);
        Observer.Expect('same initialized', 'Yes');
        Observer.Expect('same value', 'No');
        Observer.Expect('same fills', '1');
        Observer.Expect('other initialized', 'Yes');
        Observer.Expect('other value', 'No');
        Observer.Expect('other fills', '1');
        Observer.Expect('mixed txt', 'LT');
        Observer.Expect('mixed num', '11');
        Observer.Expect('mixed names', '2:login;test;');
        Observer.Expect('two subs calls', '3');
        Observer.Expect('two subs from a', 'Yes');
        Observer.Expect('two subs from b', 'Yes');
        Observer.Expect('env login calls', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P2A_14_AfterChange_InsertReads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertKind(21, 1, Observer);
        InsertKind(22, 2, Observer);
        Observer.Expect('21 insert ran', 'Yes');
        Observer.Expect('21 bool value', 'No');
        Observer.Expect('22 insert ran', 'Yes');
        Observer.Expect('22 bool value', 'No');
        Observer.Verify();
    end;

    local procedure InsertKind(No: Integer; Kind: Integer; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT P2 Memo Row";
        Prefix: Text;
    begin
        Prefix := Format(No) + ' ';
        Row.SetRange("No.", No);
        Row.DeleteAll();
        Row.Reset();
        Row.Init();
        Row."No." := No;
        Row.Kind := Kind;
        Row.Insert(true);
        Row.Get(No);
        Observer.Observe(Prefix + 'insert ran', Format(Row.InsertRan));
        case Kind of
            1, 2:
                Observer.Observe(Prefix + 'bool value', Format(Row.BoolValue));
            3:
                begin
                    Observer.Observe(Prefix + 'mixed txt', Row.MixedTxt);
                    Observer.Observe(Prefix + 'mixed num', Format(Row.MixedNum));
                    Observer.Observe(Prefix + 'mixed names', Row.MixedNames);
                end;
            4:
                Observer.Observe(Prefix + 'two subs calls', Format(Row.TwoSubsCalls));
        end;
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer")
    var
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
        Mixed: Codeunit "LT P2 XA Mixed Memo";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
        EnvSeen: Codeunit "LT P2 XA Env Seen";
    begin
        Observer.Observe('same initialized', Format(BoolMemo.RawInitialized()));
        Observer.Observe('same value', Format(BoolMemo.RawValue()));
        Observer.Observe('same fills', Format(BoolMemo.RawFills()));
        Observer.Observe('other initialized', Format(BoolMemoOther.RawInitialized()));
        Observer.Observe('other value', Format(BoolMemoOther.RawValue()));
        Observer.Observe('other fills', Format(BoolMemoOther.RawFills()));
        Observer.Observe('mixed txt', Mixed.RawTxt());
        Observer.Observe('mixed num', Format(Mixed.RawNum()));
        Observer.Observe('mixed names', Mixed.RawNames());
        Observer.Observe('two subs calls', Format(TwoSubs.RawCalls()));
        Observer.Observe('two subs from a', Format(TwoSubs.RawFromA()));
        Observer.Observe('two subs from b', Format(TwoSubs.RawFromB()));
        Observer.Observe('env login calls', Format(EnvSeen.RawCalls()));
    end;
}

codeunit 97932 "LT P2 Login Memo B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P2B_01_SecondCodeunit_Read()
    var
        Observer: Codeunit "Probe Observer";
        BoolMemo: Codeunit "LT P2 XA Bool Memo";
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
        Mixed: Codeunit "LT P2 XA Mixed Memo";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
        EnvSeen: Codeunit "LT P2 XA Env Seen";
    begin
        Observer.Observe('same initialized', Format(BoolMemo.RawInitialized()));
        Observer.Observe('same value', Format(BoolMemo.RawValue()));
        Observer.Observe('same fills', Format(BoolMemo.RawFills()));
        Observer.Observe('other initialized', Format(BoolMemoOther.RawInitialized()));
        Observer.Observe('other value', Format(BoolMemoOther.RawValue()));
        Observer.Observe('other fills', Format(BoolMemoOther.RawFills()));
        Observer.Observe('mixed txt', Mixed.RawTxt());
        Observer.Observe('mixed num', Format(Mixed.RawNum()));
        Observer.Observe('mixed names', Mixed.RawNames());
        Observer.Observe('two subs calls', Format(TwoSubs.RawCalls()));
        Observer.Observe('two subs from a', Format(TwoSubs.RawFromA()));
        Observer.Observe('two subs from b', Format(TwoSubs.RawFromB()));
        Observer.Observe('env login calls', Format(EnvSeen.RawCalls()));
        Observer.Expect('same initialized', 'Yes');
        Observer.Expect('same value', 'No');
        Observer.Expect('same fills', '1');
        Observer.Expect('other initialized', 'Yes');
        Observer.Expect('other value', 'No');
        Observer.Expect('other fills', '1');
        Observer.Expect('mixed txt', 'LT');
        Observer.Expect('mixed num', '11');
        Observer.Expect('mixed names', '2:login;test;');
        Observer.Expect('two subs calls', '3');
        Observer.Expect('two subs from a', 'Yes');
        Observer.Expect('two subs from b', 'Yes');
        Observer.Expect('env login calls', '1');
        Observer.Verify();
    end;
}
