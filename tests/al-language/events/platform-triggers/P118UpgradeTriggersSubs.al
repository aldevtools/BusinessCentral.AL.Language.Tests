// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: self-contained (71219-71221)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// P118 subscribers (ordinary codeunit, not Subtype Upgrade) to Codeunit "Upgrade Triggers" events; nothing raises them in a test.
// BC versions: 29 (27 and 28 by CI)

codeunit 71219 "LT P118 Upgr Log"
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

codeunit 71220 "LT P118 Upgr Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnCheckPreconditionsPerCompany', '', false, false)]
    local procedure PerCompany()
    var
        Log: Codeunit "LT P118 Upgr Log";
    begin
        Log.Add('PerCompany');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnCheckPreconditionsPerDatabase', '', false, false)]
    local procedure PerDatabase()
    var
        Log: Codeunit "LT P118 Upgr Log";
    begin
        Log.Add('PerDatabase');
    end;
}

codeunit 71221 "LT P118 Upgr Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P118_UpgradePreconditions_NotRaised()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 Upgr Log";
    begin
        Log.Reset();
        Observer.Observe('percompany', Format(Log.CountOf('PerCompany')));
        Observer.Observe('perdatabase', Format(Log.CountOf('PerDatabase')));
        Observer.Expect('percompany', '0');
        Observer.Expect('perdatabase', '0');
        Observer.Verify();
    end;
}
