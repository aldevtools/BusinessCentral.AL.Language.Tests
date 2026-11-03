// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Event Publisher (60014), ALT Manual Event Sub (60033), ALT Manual Sub Passer (67371),
//   ALT SI Manual Event Sub (67372)
// BC versions: 27.5+
//
// Companion to TestEventManualBinding's Contract 10 (codeunit 60240): a LOCAL codeunit
// variable's manual binding ends when its procedure returns, because nothing references the
// instance any more. This file pins the other side of that boundary: the binding ends only
// when the LAST reference to the instance goes away. A bound instance handed to another
// procedure BY VALUE, or assigned out to the caller before the local goes out of scope, is
// still referenced when the callee returns, so it stays bound.
//
// The by-value shape is how Base Application's "Error Message Management".PushContext keeps
// its "Error Context Element" bound after handing it to "Last Error Context Element".Set
// (AL Runner issue #4737).

codeunit 67370 "Test Manual Bind By Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure BoundInstance_PassedByValueToAnotherCodeunit_StillFires()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
        ManualSub: Codeunit "ALT Manual Event Sub";
    begin
        Assert.IsTrue(BindSubscription(ManualSub), 'BindSubscription on an unbound manual subscriber must return true');
        Assert.AreEqual(0, Passer.ReadFireCountByValue(ManualSub), 'The by-value callee must see the same, not yet fired, instance');
        Assert.IsTrue(Publisher.TriggerBeforeAndReturnHandled(3), 'A bound instance passed by value must stay bound after the callee returns');
        Assert.AreEqual(1, ManualSub.GetFireCount(), 'The bound instance itself must have received the event');
        Assert.AreEqual(1, Passer.ReadFireCountByValue(ManualSub), 'The by-value parameter must share the caller''s instance');
        UnbindSubscription(ManualSub);
    end;

    [Test]
    procedure BoundInstance_PassedByValueToLocalProcedure_StillFires()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
    begin
        Assert.IsTrue(BindSubscription(ManualSub), 'BindSubscription on an unbound manual subscriber must return true');
        Assert.AreEqual(0, ReadFireCountByValue(ManualSub), 'The by-value callee must see the same, not yet fired, instance');
        Assert.IsTrue(Publisher.TriggerBeforeAndReturnHandled(4), 'A bound instance passed by value must stay bound after a local callee returns');
        Assert.AreEqual(4, ManualSub.GetLastEntryNo(), 'The bound instance itself must have seen the published EntryNo');
        UnbindSubscription(ManualSub);
    end;

    [Test]
    procedure LocalBoundInCallee_NotReferencedAfterReturn_DoesNotFire()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
    begin
        Assert.IsTrue(Passer.BindLocalAndReturn(), 'BindSubscription inside the callee must return true');
        Assert.IsFalse(Publisher.TriggerBeforeAndReturnHandled(5), 'A binding held only by the callee''s local must end when the callee returns');
    end;

    [Test]
    procedure TwoLocalsSharingOneInstanceInCallee_DoNotFireAfterReturn()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
    begin
        Assert.IsTrue(Passer.BindTwoSharingLocalsAndReturn(), 'BindSubscription inside the callee must return true');
        Assert.IsFalse(Publisher.TriggerBeforeAndReturnHandled(7), 'An instance referenced only by the callee''s two locals must lose its binding when the callee returns');
    end;

    [Test]
    procedure LocalPassedByValueInCallee_OwnerReturns_DoesNotFire()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
    begin
        Assert.AreEqual(0, Passer.BindPassByValueAndReturn(), 'The by-value callee must see the bound, not yet fired, instance');
        Assert.IsFalse(Publisher.TriggerBeforeAndReturnHandled(8), 'Once the by-value callee and then the owner have returned, nothing references the instance, so its binding must end');
    end;

    [Test]
    procedure LocalCopiedToSiblingViaCallee_OwnerReturns_DoesNotFire()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
    begin
        Assert.IsTrue(Passer.BindCopyToSiblingViaCalleeAndReturn(), 'BindSubscription inside the callee must return true');
        Assert.IsFalse(Publisher.TriggerBeforeAndReturnHandled(9), 'An instance referenced only by the returned procedure''s two locals must lose its binding when it returns');
    end;

    [Test]
    procedure SingleInstanceLocalBoundInCallee_StillFiresAfterReturn()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
        SingleInstanceSub: Codeunit "ALT SI Manual Event Sub";
        Handled: Boolean;
    begin
        Assert.IsTrue(Passer.BindSingleInstanceLocalAndReturn(), 'BindSubscription inside the callee must return true');
        Handled := Publisher.TriggerBeforeAndReturnHandled(10);
        UnbindSubscription(SingleInstanceSub);
        Assert.IsTrue(Handled, 'A SingleInstance codeunit outlives the callee''s local, so its binding must survive the return');
        Assert.IsFalse(Publisher.TriggerBeforeAndReturnHandled(11), 'Unbinding through another variable of the same SingleInstance codeunit must end the binding');
    end;

    [Test]
    procedure LocalBoundInCallee_AssignedToCallerVariable_StillFires()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Passer: Codeunit "ALT Manual Sub Passer";
        ManualSub: Codeunit "ALT Manual Event Sub";
    begin
        Assert.IsTrue(Passer.BindLocalIntoCallerVariable(ManualSub), 'BindSubscription inside the callee must return true');
        Assert.IsTrue(Publisher.TriggerBeforeAndReturnHandled(6), 'An instance the caller still references must stay bound after the callee returns');
        Assert.AreEqual(1, ManualSub.GetFireCount(), 'The caller''s variable must hold the bound instance');
        UnbindSubscription(ManualSub);
    end;

    local procedure ReadFireCountByValue(ManualSub: Codeunit "ALT Manual Event Sub"): Integer
    begin
        exit(ManualSub.GetFireCount());
    end;
}
