// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXQ Log (69400), Shipping Agent Services (69403), PXQ Plain (69404),
//   PXQ Table (69412), Assert (60021) -- and Base Application page "Shipping Agent Services"
//
// A pageextension's `extends` clause can name its base page with the namespace written out, or
// leave it to the file's own namespace and `using`s. Each extension logs one row when its
// OnOpenPage runs, so the log says exactly which extensions ran for the page that was opened.
// This app's "Shipping Agent Services" and Base Application's page of that name are two pages:
// an extension of one must not run for the other, however it spells the name.

codeunit 69415 "PXQ Qualified Extends Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        LogRec: Record ALLanguage.Coverage.PxqShared."PXQ Log";
    begin
        LogRec.DeleteAll();
    end;

    local procedure CountOf(TriggerName: Text): Integer
    var
        LogRec: Record ALLanguage.Coverage.PxqShared."PXQ Log";
    begin
        LogRec.SetRange("Trigger Name", TriggerName);
        exit(LogRec.Count());
    end;

    // Positive: both extensions of this app's page run once, whether they write the namespace or
    // are declared inside it. Negative: the extension of Base Application's page does not.
    [Test]
    procedure ExtensionsOfTheLocalPageRunAndTheBasePagesDoesNot()
    var
        Card: TestPage ALLanguage.Coverage.PxqLocal."Shipping Agent Services";
    begin
        Initialize();

        Card.OpenView();
        Card.Close();

        Assert.AreEqual(1, CountOf('local-qualified'), 'the extension qualifying the local page must run once when it opens');
        Assert.AreEqual(1, CountOf('local-own'), 'the extension declared in the local namespace must run once');
        Assert.AreEqual(0, CountOf('base-qualified'), 'an extension of Base Application''s page must not run for the local page');
    end;

    // The mirror image: opening Base Application's page runs only the extension that names it.
    [Test]
    procedure ExtensionOfTheBasePageRunsAndTheLocalPagesDoNot()
    var
        Card: TestPage Microsoft.Foundation.Shipping."Shipping Agent Services";
    begin
        Initialize();

        Card.OpenView();
        Card.Close();

        Assert.AreEqual(1, CountOf('base-qualified'), 'the extension qualifying Base Application''s page must run once when it opens');
        Assert.AreEqual(0, CountOf('local-qualified'), 'an extension of the local page must not run for Base Application''s page');
        Assert.AreEqual(0, CountOf('local-own'), 'an extension declared in the local namespace must not run for Base Application''s page');
    end;

    // Positive control on a page whose name is unique: the extension reaching it through a using
    // and the one writing the namespace out both run, once each.
    [Test]
    procedure ImportedAndQualifiedExtendsBothRunForAUniquelyNamedPage()
    var
        Plain: TestPage ALLanguage.Coverage.PxqLocal."PXQ Plain";
    begin
        Initialize();

        Plain.OpenView();
        Plain.Close();

        Assert.AreEqual(1, CountOf('plain-imported'), 'the extension reaching "PXQ Plain" through a using must run once');
        Assert.AreEqual(1, CountOf('plain-qualified'), 'the extension qualifying "PXQ Plain" must run once');
        Assert.AreEqual(0, CountOf('local-qualified'), 'no extension of another page runs for "PXQ Plain"');
    end;

    // A tableextension whose clause writes the namespace attaches to its table: its OnInsert runs.
    [Test]
    procedure QualifiedTableExtensionTriggerRunsOnInsert()
    var
        Row: Record ALLanguage.Coverage.PxqLocal."PXQ Table";
    begin
        Initialize();
        Row.DeleteAll();

        Row."No." := 'A';
        Row."PXQ Added" := 7;
        Row.Insert(true);

        Assert.AreEqual(1, CountOf('table-qualified'), 'the qualified tableextension''s OnInsert must run once');
        Row.Get('A');
        Assert.AreEqual(7, Row."PXQ Added", 'the field the qualified tableextension adds must be stored');
    end;
}
