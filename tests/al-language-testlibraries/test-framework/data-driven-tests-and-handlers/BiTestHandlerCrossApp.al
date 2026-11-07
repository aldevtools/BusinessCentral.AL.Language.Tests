// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods#add-lifecycle-handlers-to-test-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XH Log (97830) of tests/al-language-xhandler-lib; the default handlers XH Handler A (97835, app XHandler A, a dependency of this app),
//   XH Handler C (97840, app XHandler C) and XH Handler D (97845, app XHandler D) (both published, neither depends on this app and this app depends on neither);
//   LT BI DH Default (81693) and LT BI DH Own (81694) from BiTestHandlerDefault.al
// Corpus issue (al-runner 7181, runtime 18): a DefaultTestHandler extension declared in another app than the test codeunit.
// Probe: written against BC 29.0 (CI run of the batcher). Pinned: the handler apps are ordered HD (XH Handler D), HC, HA, then this app's default handler (D) and TestHandlers handler (O).
// BC versions: 29
#if BC29PLUS
// Test codeunit without TestHandlers. The default handlers of apps A (a dependency of this app), C and D (unrelated apps, no tests) and this app's own (LT BI DH Default)
// are all installed. The entries tagged HA, HC, HD show which of them ran.
codeunit 81646 "LT BI XH Plain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BiXh_A_First()
    var
        Log: Codeunit "XH Log";
    begin
        Log.Add(81646, 'body A');
    end;

    [Test]
    procedure BiXh_B_Second()
    var
        Log: Codeunit "XH Log";
    begin
        Log.Add(81646, 'body B');
    end;

    [Test]
    procedure BiXh_Z_Observe()
    var
        Log: Codeunit "XH Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take(81646));
        Observer.Expect('log', 'HD.bCU(||n=1);HC.bCU(||n=1);HA.bCU(||n=1);D.bCU(||n=1);HD.bP(BiXh_A_First||n=2);HC.bP(BiXh_A_First||n=2);HA.bP(BiXh_A_First||n=2);D.bP(BiXh_A_First||n=2);body A;HD.aP(BiXh_A_First||n=3|Yes);HC.aP(BiXh_A_First||n=3|Yes);HA.aP(BiXh_A_First||n=3|Yes);D.aP(BiXh_A_First||n=3|Yes);HD.bP(BiXh_B_Second||n=4);HC.bP(BiXh_B_Second||n=4);HA.bP(BiXh_B_Second||n=4);D.bP(BiXh_B_Second||n=4);body B;HD.aP(BiXh_B_Second||n=5|Yes);HC.aP(BiXh_B_Second||n=5|Yes);HA.aP(BiXh_B_Second||n=5|Yes);D.aP(BiXh_B_Second||n=5|Yes);HD.bP(BiXh_Z_Observe||n=6);HC.bP(BiXh_Z_Observe||n=6);HA.bP(BiXh_Z_Observe||n=6);D.bP(BiXh_Z_Observe||n=6);');
        Observer.Verify();
    end;
}

// Test codeunit with TestHandlers: this app's handler LT BI DH Own, plus every default handler.
codeunit 81647 "LT BI XH Own"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI DH Own";

    [Test]
    procedure BiXh_A_Plain()
    var
        Log: Codeunit "XH Log";
    begin
        Log.Add(81647, 'body A');
    end;

    [Test]
    procedure BiXh_Z_Observe()
    var
        Log: Codeunit "XH Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take(81647));
        Observer.Expect('log', 'HD.bCU(||n=1);HC.bCU(||n=1);HA.bCU(||n=1);D.bCU(||n=1);O.bCU(||n=1);HD.bP(BiXh_A_Plain||n=2);HC.bP(BiXh_A_Plain||n=2);HA.bP(BiXh_A_Plain||n=2);D.bP(BiXh_A_Plain||n=2);O.bP(BiXh_A_Plain||n=2);body A;HD.aP(BiXh_A_Plain||n=3|Yes);HC.aP(BiXh_A_Plain||n=3|Yes);HA.aP(BiXh_A_Plain||n=3|Yes);D.aP(BiXh_A_Plain||n=3|Yes);O.aP(BiXh_A_Plain||n=3|Yes);HD.bP(BiXh_Z_Observe||n=4);HC.bP(BiXh_Z_Observe||n=4);HA.bP(BiXh_Z_Observe||n=4);D.bP(BiXh_Z_Observe||n=4);O.bP(BiXh_Z_Observe||n=4);');
        Observer.Verify();
    end;
}

// Reads the logs of the two codeunits above after they finished: the After callbacks of their last procedure and of the codeunit itself.
// Test codeunits run in id order, so this one runs after 81646 and 81647.
codeunit 81648 "LT BI XH Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BiXh_Plain_Final()
    var
        Log: Codeunit "XH Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take(81646));
        Observer.Expect('log', 'HD.bCU(||n=1);HC.bCU(||n=1);HA.bCU(||n=1);D.bCU(||n=1);HD.bP(BiXh_A_First||n=2);HC.bP(BiXh_A_First||n=2);HA.bP(BiXh_A_First||n=2);D.bP(BiXh_A_First||n=2);body A;HD.aP(BiXh_A_First||n=3|Yes);HC.aP(BiXh_A_First||n=3|Yes);HA.aP(BiXh_A_First||n=3|Yes);D.aP(BiXh_A_First||n=3|Yes);HD.bP(BiXh_B_Second||n=4);HC.bP(BiXh_B_Second||n=4);HA.bP(BiXh_B_Second||n=4);D.bP(BiXh_B_Second||n=4);body B;HD.aP(BiXh_B_Second||n=5|Yes);HC.aP(BiXh_B_Second||n=5|Yes);HA.aP(BiXh_B_Second||n=5|Yes);D.aP(BiXh_B_Second||n=5|Yes);HD.bP(BiXh_Z_Observe||n=6);HC.bP(BiXh_Z_Observe||n=6);HA.bP(BiXh_Z_Observe||n=6);D.bP(BiXh_Z_Observe||n=6);HD.aP(BiXh_Z_Observe||n=7|Yes);HC.aP(BiXh_Z_Observe||n=7|Yes);HA.aP(BiXh_Z_Observe||n=7|Yes);D.aP(BiXh_Z_Observe||n=7|Yes);HD.aCU(||n=8|Yes);HC.aCU(||n=8|Yes);HA.aCU(||n=8|Yes);D.aCU(||n=8|Yes);');
        Observer.Verify();
    end;

    [Test]
    procedure BiXh_Own_Final()
    var
        Log: Codeunit "XH Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take(81647));
        Observer.Expect('log', 'HD.bCU(||n=1);HC.bCU(||n=1);HA.bCU(||n=1);D.bCU(||n=1);O.bCU(||n=1);HD.bP(BiXh_A_Plain||n=2);HC.bP(BiXh_A_Plain||n=2);HA.bP(BiXh_A_Plain||n=2);D.bP(BiXh_A_Plain||n=2);O.bP(BiXh_A_Plain||n=2);body A;HD.aP(BiXh_A_Plain||n=3|Yes);HC.aP(BiXh_A_Plain||n=3|Yes);HA.aP(BiXh_A_Plain||n=3|Yes);D.aP(BiXh_A_Plain||n=3|Yes);O.aP(BiXh_A_Plain||n=3|Yes);HD.bP(BiXh_Z_Observe||n=4);HC.bP(BiXh_Z_Observe||n=4);HA.bP(BiXh_Z_Observe||n=4);D.bP(BiXh_Z_Observe||n=4);O.bP(BiXh_Z_Observe||n=4);HD.aP(BiXh_Z_Observe||n=5|Yes);HC.aP(BiXh_Z_Observe||n=5|Yes);HA.aP(BiXh_Z_Observe||n=5|Yes);D.aP(BiXh_Z_Observe||n=5|Yes);O.aP(BiXh_Z_Observe||n=5|Yes);HD.aCU(||n=6|Yes);HC.aCU(||n=6|Yes);HA.aCU(||n=6|Yes);D.aCU(||n=6|Yes);O.aCU(||n=6|Yes);');
        Observer.Verify();
    end;
}
#endif
