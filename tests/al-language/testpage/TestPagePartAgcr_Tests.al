// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-onaftergetcurrrecord-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Test Page Part Agcr Row (60812), Test Page Part Agcr Part (60813),
//                Test Page Part Agcr Host (60814), Test Page Part Agcr Trace (60811),
//                Assert (60021)
//
// A subpage PART bound via SubPageLink to the host's current row -- the FactBox/summary
// shape -- gets its own row and fires OnOpenPage/OnAfterGetRecord/OnAfterGetCurrRecord the
// same way a top-level page does. What is NOT obvious, and what OBS probes measured rather
// than assumed (AL Runner issue 2677), is WHEN: whether a TestPage-driven host fires the
// part's triggers eagerly as part of opening (the part is declared in the layout; nothing in
// the host's own AL ever references CurrPage.AgcrPart), or only once something touches the
// part.
//
// MEASURED (BC 27.0, 27.3, 27.5, 28.0, 28.1, 28.2, 28.3, 28.4 via this repo's own CI, and
// independently confirmed against a local BC 28.4 onprem container): opening the host ALONE
// -- nothing ever touches CurrPage.AgcrPart or TestPage.AgcrPart -- already produces
// HostOpen;PartOpen;HostAGCR:X;PartAGCR:X. The part's OnOpenPage runs right after the host's
// own, and its OnAfterGetRecord/OnAfterGetCurrRecord runs right after the host's own, for
// the row the host landed on -- entirely unprompted. A later touch adds nothing further (the
// value read back matches what PartAGCR already computed).
//
// GoToRecord on the host to a DIFFERENT row re-fires the part's trigger for the NEW row and
// does NOT re-fire it for the row just left -- but the corpus CI legs measured
// HostAGCR:X;HostAGCR:Y;PartAGCR:Y after a Reset() immediately before GoToRecord, i.e. the
// HOST's own OnAfterGetCurrRecord fires TWICE around a GoToRecord to a new row (once
// apparently for the row being left, once for the row arrived at) -- general TestPage
// GoToRecord navigation behaviour, not something specific to subpage parts, and out of this
// file's scope to characterise further. What THIS file asserts about GoToRecord is narrower
// and unaffected by that: the part's OWN trigger fires exactly once, for the NEW row, not
// for the old one.
//
// NOT PINNED: the exact repeat count of PartAGCR:X on the no-touch/with-touch probes. The
// corpus CI's 8 BC legs (linux, via StefanMaron/MsDyn365Bc.On.Linux) measured it firing
// TWICE; an independently run local BC 28.4 onprem-on-Windows container measured it firing
// ONCE. Same AL, same measured ORDER, different repeat count between two real BC hosting
// environments -- an artifact of test-runner/hosting plumbing this file has no way to
// characterise further, so only presence and relative order are asserted, never a count.
codeunit 60815 "Test Page Part Agcr Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Part Agcr Row";
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Row.DeleteAll();
        Trace.Reset();
    end;

    local procedure SeedRow(No: Code[20]; Name: Text[50])
    var
        Row: Record "Test Page Part Agcr Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Name;
        Row.Insert();
    end;

    // Positive: the part's OnOpenPage and OnAfterGetRecord/OnAfterGetCurrRecord both run as
    // part of the host simply opening -- nothing here ever references CurrPage.AgcrPart or
    // Host.AgcrPart -- in the order HostOpen < PartOpen < HostAGCR < PartAGCR.
    [Test]
    procedure PartFiresOnHostOpen_NoTouch()
    var
        Host: TestPage "Test Page Part Agcr Host";
        Trace: Codeunit "Test Page Part Agcr Trace";
        Order: Text;
    begin
        Initialize();
        SeedRow('X', 'Alpha');

        Host.OpenView();
        Host.Close();

        Order := Trace.GetTrace();
        Assert.IsTrue(StrPos(Order, 'PartAGCR:X') > 0, 'the part''s OnAfterGetCurrRecord must have fired with nothing ever touching the part');
        Assert.IsTrue(StrPos(Order, 'HostOpen') < StrPos(Order, 'PartOpen'), 'the part''s own OnOpenPage must run after the host''s');
        Assert.IsTrue(StrPos(Order, 'PartOpen') < StrPos(Order, 'HostAGCR:X'), 'the part''s OnOpenPage must run before the host''s first OnAfterGetCurrRecord');
        Assert.IsTrue(StrPos(Order, 'HostAGCR:X') < StrPos(Order, 'PartAGCR:X'), 'the host''s own OnAfterGetCurrRecord must run before the part''s');
    end;

    // Positive: reading a control on the part after OpenView returns the value the part's
    // OWN (already-run) OnAfterGetCurrRecord established -- the touch does not compute
    // anything new, it reads what eager materialisation already produced.
    [Test]
    procedure PartValueMatchesEagerRow_WithTouch()
    var
        Host: TestPage "Test Page Part Agcr Host";
        PartNo: Code[20];
    begin
        Initialize();
        SeedRow('X', 'Alpha');

        Host.OpenView();
        PartNo := Host.AgcrPart."No.".Value();
        Host.Close();

        Assert.AreEqual('X', PartNo, 'the part''s control must already reflect the host''s current row without any explicit refresh');
    end;

    // Positive: GoToRecord to a DIFFERENT row re-fires the part's OWN trigger for the NEW
    // row, and does not leave a stale fire for the row just left.
    [Test]
    procedure PartRefires_OnGoToRecord()
    var
        Row2: Record "Test Page Part Agcr Row";
        Host: TestPage "Test Page Part Agcr Host";
        Trace: Codeunit "Test Page Part Agcr Trace";
        PartNo: Code[20];
        Order: Text;
    begin
        Initialize();
        SeedRow('X', 'Alpha');
        SeedRow('Y', 'Bravo');
        Row2.Get('Y');

        Host.OpenView();
        PartNo := Host.AgcrPart."No.".Value(); // establish the part once, on row X
        Trace.Reset(); // isolate what GoToRecord alone does
        Assert.IsTrue(Host.GoToRecord(Row2), 'GoToRecord must find the seeded row Y');
        PartNo := Host.AgcrPart."No.".Value();
        Host.Close();

        Order := Trace.GetTrace();
        Assert.AreEqual('Y', PartNo, 'the part''s control must reflect the NEW row after GoToRecord');
        Assert.IsTrue(StrPos(Order, 'PartAGCR:Y') > 0, 'the part''s OnAfterGetCurrRecord must re-fire for the new row');
        Assert.IsTrue(StrPos(Order, 'HostAGCR:Y') < StrPos(Order, 'PartAGCR:Y'), 'the host''s OnAfterGetCurrRecord for the new row must run before the part''s');
        Assert.AreEqual(0, StrPos(Order, 'PartAGCR:X'), 'the part must NOT re-fire for the row just left');
    end;
}
