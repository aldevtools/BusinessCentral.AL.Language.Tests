// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: self-contained (71216-71218)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: publisher GetAgentTaskMessagePageId has Scope = OnPrem: may give AL0296 in the Cloud app
// BC versions: 29 (27 and 28 by CI)

codeunit 71216 "LT P118 AgentPage Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure CountOf(Entry: Text): Integer
    var
        E: Text;
        N: Integer;
    begin
        foreach E in Entries do
            if E = Entry then
                N += 1;
        exit(N);
    end;

    procedure Total(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;
}

codeunit 71217 "LT P118 AgentPage Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetAgentTaskMessagePageId', '', false, false)]
    local procedure GetAgentTaskMessagePageIdSub(var PageId: Integer)
    var
        Log: Codeunit "LT P118 AgentPage Log";
    begin
        Log.Add('GetAgentTaskMessagePageId');
    end;
}

codeunit 71218 "LT P118 AgentPage Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P118_AgentPage_NotRaisedByTest()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 AgentPage Log";
    begin
        Log.Reset();
        Observer.Observe('count', Format(Log.CountOf('GetAgentTaskMessagePageId')));
        Observer.Observe('total', Format(Log.Total()));
        Observer.Expect('count', '0');
        Observer.Expect('total', '0');
        Observer.Verify();
    end;
}
