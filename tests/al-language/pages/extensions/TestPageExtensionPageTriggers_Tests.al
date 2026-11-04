// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXT Row (60654), PXT Log (60655), PXT List (60656), PXT List Ext (60657), Assert (60021)
//
// What a pageextension's page triggers do when the extended page is opened as a TestPage.
// The base page declares none of them, so every entry PXT Log holds came from the extension.

codeunit 60658 "PXT Page Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "PXT Row";
        LogRec: Record "PXT Log";
    begin
        Row.DeleteAll();
        LogRec.DeleteAll();

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    local procedure CountOf(TriggerName: Text): Integer
    var
        LogRec: Record "PXT Log";
    begin
        LogRec.SetRange("Trigger Name", TriggerName);
        exit(LogRec.Count());
    end;

    // Positive: the extension's OnOpenPage runs, exactly once, on a page that declares none.
    [Test]
    procedure PageextensionOnOpenPageRunsOnceWhenTheExtendedPageOpens()
    var
        PxtList: TestPage "PXT List";
    begin
        Initialize();

        PxtList.OpenView();
        PxtList.Close();

        Assert.AreEqual(1, CountOf('OnOpenPage'),
          'the pageextension''s OnOpenPage must run exactly once for one open of the extended page');
    end;

    // Positive: the extension's OnAfterGetRecord runs, and runs in the PAGE's context — it
    // reads Rec, and what it read is the row the page is positioned on.
    [Test]
    procedure PageextensionOnAfterGetRecordRunsAgainstThePagesCurrentRow()
    var
        LogRec: Record "PXT Log";
        PxtList: TestPage "PXT List";
    begin
        Initialize();

        PxtList.OpenView();
        PxtList.First();
        PxtList.Close();

        LogRec.SetRange("Trigger Name", 'OnAfterGetRecord');
        LogRec.SetRange("Row No.", 'A');
        Assert.IsFalse(LogRec.IsEmpty(),
          'the pageextension''s OnAfterGetRecord must have run with Rec on the page''s first row');
    end;

    // Positive: it is raised PER ROW, not once per page - stepping to the second row records
    // that row too. Without this arm a one-shot implementation passes the arm above.
    [Test]
    procedure PageextensionOnAfterGetRecordRunsForEachRowTheTestPageVisits()
    var
        LogRec: Record "PXT Log";
        PxtList: TestPage "PXT List";
    begin
        Initialize();

        PxtList.OpenView();
        PxtList.First();
        PxtList.Next();
        PxtList.Close();

        LogRec.SetRange("Trigger Name", 'OnAfterGetRecord');
        LogRec.SetRange("Row No.", 'B');
        Assert.IsFalse(LogRec.IsEmpty(),
          'the pageextension''s OnAfterGetRecord must have run for the second row as well');
    end;

    // Negative on ORDER, the half a "fires at some point" assertion cannot see: OnOpenPage
    // is raised BEFORE the page's first row is fetched, so entry 1 is OnOpenPage and no
    // OnAfterGetRecord precedes it.
    [Test]
    procedure PageextensionOnOpenPageIsRaisedBeforeTheFirstOnAfterGetRecord()
    var
        LogRec: Record "PXT Log";
        PxtList: TestPage "PXT List";
    begin
        Initialize();

        PxtList.OpenView();
        PxtList.First();
        PxtList.Close();

        LogRec.FindFirst();
        Assert.AreEqual(1, LogRec."Entry No.", 'the first logged raise must be entry 1');
        Assert.AreEqual('OnOpenPage', LogRec."Trigger Name",
          'OnOpenPage must be raised before any OnAfterGetRecord');
    end;
}
