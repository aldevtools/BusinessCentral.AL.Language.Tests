// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: none (self-contained publisher/subscriber pair)
// Note: regression proof that a codeunit IntegrationEvent carrying an Option
// argument is marshalled to a subscriber whose parameter is Option-typed.
// BC versions: 24+

codeunit 60215 "Test Codeunit Event OptArg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CodeunitEventOptionArg_MarshalsSecond()
    var
        Publisher: Codeunit "Opt Publisher CEO";
    begin
        Initialize();
        // [WHEN] the publisher fires OnDoChoice(Second) — option ordinal 1
        asserterror Publisher.Fire(1);

        // [THEN] the subscriber fired and received the Option value, ordinal 1
        Assert.AreEqual('RECEIVED:Second', GetLastErrorText(),
            'Subscriber must receive the correct Option ordinal (Second = 1)');
    end;

    [Test]
    procedure CodeunitEventOptionArg_MarshalsThird()
    var
        Publisher: Codeunit "Opt Publisher CEO";
    begin
        Initialize();
        // [WHEN] firing with ordinal 2 (Third)
        asserterror Publisher.Fire(2);

        Assert.AreEqual('RECEIVED:Third', GetLastErrorText(),
            'Subscriber must receive the correct Option ordinal (Third = 2)');
    end;

    [Test]
    procedure CodeunitEventOptionArg_MarshalsFirst()
    var
        Publisher: Codeunit "Opt Publisher CEO";
    begin
        Initialize();
        // Negative-direction guard: ordinal 0 must NOT be masked as a default.
        // The subscriber error must carry RECEIVED:First (the real ordinal),
        // proving the marshalled value is genuinely passed through, and must
        // NOT equal the other ordinals.
        asserterror Publisher.Fire(0);

        Assert.AreEqual('RECEIVED:First', GetLastErrorText(),
            'Subscriber must receive ordinal 0 (First) — not a masked default');
    end;

    local procedure Initialize()
    begin
    end;
}
