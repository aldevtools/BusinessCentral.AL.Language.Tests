// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/business-events-overview
// Scope: in-scope
// Fixtures used: EBE Event Category (68610), EBE Publisher (68610), EBE Run Target (68612),
//                shared Assert (60021)
// Note: raising a procedure marked [ExternalBusinessEvent] when no subscription exists
// returns to the caller, and the AL after it runs. Delivery to a subscriber is out of
// process and after commit, so nothing about it is observable here; what these tests pin
// is that the raise itself completes, and that it does not hide an error raised around
// it. AL Runner issue #5149.
// BC versions: 27+

codeunit 68611 "Test External Business Event"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ExternalBusinessEvent_RaiseWithNoSubscription_RunsTheNextStatement()
    var
        Publisher: Codeunit "EBE Publisher";
    begin
        Publisher.RaiseBetweenSteps();

        Assert.AreEqual(2, Publisher.Steps(), 'The statement after the external business event must run.');
    end;

    [Test]
    procedure ExternalBusinessEvent_RaiseWithPayload_RunsTheNextStatement()
    var
        Publisher: Codeunit "EBE Publisher";
    begin
        Publisher.RaiseWithPayload();

        Assert.AreEqual(2, Publisher.Steps(), 'The statement after an external business event with a payload must run.');
    end;

    [Test]
    procedure ExternalBusinessEvent_RaiseThenCommit_Completes()
    var
        Publisher: Codeunit "EBE Publisher";
    begin
        Publisher.RaiseBetweenSteps();
        Publisher.RaiseBetweenSteps();
        Commit();

        Assert.AreEqual(4, Publisher.Steps(), 'Two raises and a commit must all complete.');
    end;

    [Test]
    procedure ExternalBusinessEvent_RaiseInsideCodeunitRun_ReturnsTrue()
    var
        Succeeded: Boolean;
    begin
        ClearLastError();

        Succeeded := Codeunit.Run(Codeunit::"EBE Run Target");

        Assert.IsTrue(Succeeded, 'Codeunit.Run around an external business event must return true; last error: ' + GetLastErrorText());
        Assert.AreEqual('', GetLastErrorText(), 'A successful Codeunit.Run must leave no last error.');
    end;

    [Test]
    procedure ExternalBusinessEvent_ErrorAfterTheRaise_StillPropagates()
    var
        Publisher: Codeunit "EBE Publisher";
    begin
        asserterror Publisher.RaiseThenFail();

        Assert.ExpectedError('EBE unrelated failure after the raise');
        Assert.AreEqual(2, Publisher.Steps(), 'The raise must complete before the later error.');
    end;
}
