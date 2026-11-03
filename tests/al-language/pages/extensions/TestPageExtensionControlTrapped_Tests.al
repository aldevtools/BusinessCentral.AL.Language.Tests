// Tests for the fixture in TestPageExtensionControlTrapped_Page.al.
//
// CLAIM: a TestPage that TRAPS a page AL opened -- with Page.Run(Id, Rec), or through a Page
// variable's SetRecord + Run -- reaches the controls a pageextension adds to that page, whether
// the control is bound to an expression over Rec or to a global the extension assigns in its
// OnOpenPage. Each reads its value for the row the page was opened on.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4738. Nothing here predicts
// the runner's answer; these arms record what BC does.

codeunit 67470 "PXR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(var Second: Record "PXR Row")
    var
        Row: Record "PXR Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row."Rec Text" := 'FIRST';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row."Rec Text" := 'SECOND';
        Row.Insert();
        Second.Get(2);
    end;

    [Test]
    procedure TrappedPageRun_BaseControl_ReadsTheRowItWasOpenedOn()
    // The baseline. If this fails, the arms below fail for a reason that has nothing to do with
    // pageextensions.
    var
        Row: Record "PXR Row";
        List: TestPage "PXR List";
    begin
        Initialize(Row);

        List.Trap();
        Page.Run(Page::"PXR List", Row);
        Assert.AreEqual('SECOND', List."Rec Text".Value(),
            'The trapped page''s own control must read the row Page.Run opened it on.');
        List.Close();
    end;

    [Test]
    procedure TrappedPageRun_ExtExpressionControl_ReadsTheCurrentRow()
    // The shape AL Runner #4738 reports: an extension control bound to an expression over Rec.
    var
        Row: Record "PXR Row";
        List: TestPage "PXR List";
    begin
        Initialize(Row);

        List.Trap();
        Page.Run(Page::"PXR List", Row);
        Assert.AreEqual('2:SECOND', List.ExtExpression.Value(),
            'A pageextension control bound to an expression must evaluate it for the row the page is on.');
        List.First();
        Assert.AreEqual('1:FIRST', List.ExtExpression.Value(),
            'The expression must follow the TestPage onto another row.');
        List.Close();
    end;

    [Test]
    procedure TrappedPageRun_ExtGlobalControl_ReadsTheValueItsOnOpenPageAssigned()
    // A found control that reads blank would mean the extension's OnOpenPage never ran on the
    // trapped page, which is a different failure from not finding the control at all.
    var
        Row: Record "PXR Row";
        List: TestPage "PXR List";
    begin
        Initialize(Row);

        List.Trap();
        Page.Run(Page::"PXR List", Row);
        Assert.AreEqual('EXTOPENED', List.ExtGlobalField.Value(),
            'A pageextension control bound to an extension global must read the value its OnOpenPage assigned.');
        List.Close();
    end;

    [Test]
    procedure TrappedPageRun_ExtControlOnValidate_UpdatesTheGlobalTheControlShows()
    // One extension instance per page: the control's OnValidate must run on the same instance
    // whose global the control reads, so the write reads back the trigger's rewrite of it.
    var
        Row: Record "PXR Row";
        List: TestPage "PXR List";
    begin
        Initialize(Row);

        List.Trap();
        Page.Run(Page::"PXR List", Row);
        List.ExtGlobalField.SetValue('typed');
        Assert.AreEqual('TYPED!', List.ExtGlobalField.Value(),
            'The extension control''s OnValidate must rewrite the global the control is bound to.');
        List.Close();
    end;

    [Test]
    procedure TrappedPageVariableRun_ExtControls_AreFound()
    // The same claim through a Page VARIABLE, which is a different construction path from the
    // static Page.Run(Id, Rec).
    var
        Row: Record "PXR Row";
        ListPage: Page "PXR List";
        List: TestPage "PXR List";
    begin
        Initialize(Row);

        List.Trap();
        ListPage.SetRecord(Row);
        ListPage.Run();
        Assert.AreEqual('2:SECOND', List.ExtExpression.Value(),
            'A pageextension expression control must be found on a page run through a Page variable.');
        Assert.AreEqual('EXTOPENED', List.ExtGlobalField.Value(),
            'A pageextension global control must read its OnOpenPage value on a page run through a Page variable.');
        List.Close();
    end;

    [Test]
    procedure TrappedPageRun_UndeclaredControlId_IsNotFound()
    // The negative: the trapped page still refuses an id no control declares, so a found
    // extension control above is found because the extension declares it.
    var
        Row: Record "PXR Row";
        List: TestPage "PXR List";
        Value: Text;
    begin
        Initialize(Row);

        List.Trap();
        Page.Run(Page::"PXR List", Row);
        asserterror Value := List.GetField(12345).Value();
        Assert.ExpectedError('The field with ID = 12345 is not found on the page.');
        List.Close();
    end;
}
