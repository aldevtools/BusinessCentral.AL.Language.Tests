// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Base Application table "Sales Comment Line" and page
//                "Sales Comment Sheet" (both ship in Base Application, which this app depends on);
//                the tableextension, pageextension and test codeunit below (ids 67480, 67481, 67482).
//
// Probe (AL Runner issue aldevtools/BusinessCentral.AL.Runner#8906): a TestPage on a MICROSOFT page that a
// pageextension of this app extends, in the shapes the reporter used:
//   - Visible() of a pageextension control whose Visible property is an extension variable: never assigned,
//     and assigned true in the extension's OnOpenPage; opened with OpenEdit, OpenView and trapped.
//   - read and write of a pageextension control bound to the base field (Rec.Comment) and of one bound to a
//     Boolean field a tableextension adds to "Sales Comment Line"; Close, then Get reads the stored row.
//   - a page opened by AL through a Page variable (SetTableView + Run) and trapped by the TestPage: write the
//     page's own Comment control and the tableextension Boolean control, Close, Get.
//   - GetField with an id no control declares on that trapped page: the error text.
// The page is Microsoft's on purpose: the reporter's failures were specific to a page that ships in a
// dependency (it is compiled before this app); TestPageExtensionControlTrapped_Page.al and
// TestPageExtensionControlBinding_Page.al cover the same controls on a page of this app.
// Rows: every test deletes the "Sales Comment Line" rows whose "No." starts with PXSC- and writes only those.
// The facts are the Expect lines of each test; written against BC 27.5, measured by corpus CI on 27.5, 28.5, 29.0.

tableextension 67480 "PXSC Comment Line Ext" extends "Sales Comment Line"
{
    fields
    {
        field(67480; "PXSC Flag"; Boolean) { DataClassification = CustomerContent; }
    }
}

pageextension 67481 "PXSC Comment Sheet Ext" extends "Sales Comment Sheet"
{
    layout
    {
        addafter(Comment)
        {
            field(PXSCCopy; Rec.Comment) { ApplicationArea = All; }
            field(PXSCFlag; Rec."PXSC Flag") { ApplicationArea = All; }
            // Visible is an extension variable nobody assigns.
            field(PXSCHiddenUnset; Rec.Comment) { ApplicationArea = All; Visible = PXSCNeverSet; }
            // Visible is an extension variable the extension's OnOpenPage sets to true.
            field(PXSCShownOnOpen; Rec.Comment) { ApplicationArea = All; Visible = PXSCSetOnOpen; }
        }
    }

    trigger OnOpenPage()
    begin
        PXSCSetOnOpen := true;
    end;

    var
        PXSCNeverSet: Boolean;
        PXSCSetOnOpen: Boolean;
}

codeunit 67482 "PXSC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize(var Comment: Record "Sales Comment Line"; No: Code[20])
    var
        Existing: Record "Sales Comment Line";
    begin
        Existing.SetFilter("No.", 'PXSC-*');
        Existing.DeleteAll();
        Comment.Init();
        Comment."Document Type" := Comment."Document Type"::Order;
        Comment."No." := No;
        Comment."Document Line No." := 0;
        Comment."Line No." := 10000;
        Comment.Comment := 'Allocation comment';
        Comment."PXSC Flag" := false;
        Comment.Insert(false);
    end;

    local procedure Stored(var Comment: Record "Sales Comment Line")
    begin
        Comment.Get(Comment."Document Type", Comment."No.", Comment."Document Line No.", Comment."Line No.");
    end;

    [Test]
    procedure OpenEdit_ExtVisibleVariable_UnsetAndSetOnOpen()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-VIS-EDIT');
        Sheet.OpenEdit();
        Sheet.GoToRecord(Comment);
        Observer.Observe('unset visible', Format(Sheet.PXSCHiddenUnset.Visible()));
        Observer.Observe('set on open visible', Format(Sheet.PXSCShownOnOpen.Visible()));
        Observer.Observe('copy visible', Format(Sheet.PXSCCopy.Visible()));
        Observer.Observe('unset value', Sheet.PXSCHiddenUnset.Value());
        Sheet.Close();
        Observer.Expect('unset visible', 'No');
        Observer.Expect('set on open visible', 'Yes');
        Observer.Expect('copy visible', 'Yes');
        Observer.Expect('unset value', 'Allocation comment');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ExtVisibleVariable_UnsetAndSetOnOpen()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-VIS-VIEW');
        Sheet.OpenView();
        Sheet.GoToRecord(Comment);
        Observer.Observe('unset visible', Format(Sheet.PXSCHiddenUnset.Visible()));
        Observer.Observe('set on open visible', Format(Sheet.PXSCShownOnOpen.Visible()));
        Sheet.Close();
        Observer.Expect('unset visible', 'No');
        Observer.Expect('set on open visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_ExtVisibleVariable_UnsetAndSetOnOpen()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        PageInstance: Page "Sales Comment Sheet";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-VIS-TRAP');
        Comment.SetRange("Document Type", Comment."Document Type");
        Comment.SetRange("No.", Comment."No.");
        PageInstance.SetTableView(Comment);
        Sheet.Trap();
        PageInstance.Run();
        Sheet.GoToRecord(Comment);
        Observer.Observe('unset visible', Format(Sheet.PXSCHiddenUnset.Visible()));
        Observer.Observe('set on open visible', Format(Sheet.PXSCShownOnOpen.Visible()));
        Sheet.Close();
        Observer.Expect('unset visible', 'No');
        Observer.Expect('set on open visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_ExtControlOnBaseField_ReadWritePersists()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-COPY');
        Sheet.OpenEdit();
        Sheet.GoToRecord(Comment);
        Observer.Observe('base control before', Sheet.Comment.Value());
        Observer.Observe('ext copy before', Sheet.PXSCCopy.Value());
        Sheet.PXSCCopy.SetValue('Changed through extension');
        Observer.Observe('ext copy after set', Sheet.PXSCCopy.Value());
        Observer.Observe('base control after set', Sheet.Comment.Value());
        Sheet.Close();
        Stored(Comment);
        Observer.Observe('stored comment', Comment.Comment);
        Observer.Expect('base control before', 'Allocation comment');
        Observer.Expect('ext copy before', 'Allocation comment');
        Observer.Expect('ext copy after set', 'Changed through extension');
        Observer.Expect('base control after set', 'Changed through extension');
        Observer.Expect('stored comment', 'Changed through extension');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_ExtControlOnTableExtBoolean_ReadWritePersists()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-FLAG');
        Sheet.OpenEdit();
        Sheet.GoToRecord(Comment);
        Observer.Observe('flag before', Format(Sheet.PXSCFlag.AsBoolean()));
        Sheet.PXSCFlag.SetValue(true);
        Observer.Observe('flag after set', Format(Sheet.PXSCFlag.AsBoolean()));
        Observer.Observe('flag value text', Sheet.PXSCFlag.Value());
        Sheet.Close();
        Stored(Comment);
        Observer.Observe('stored flag', Format(Comment."PXSC Flag"));
        Observer.Expect('flag before', 'No');
        Observer.Expect('flag after set', 'Yes');
        Observer.Expect('flag value text', 'Yes');
        Observer.Expect('stored flag', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_BaseCommentControl_EditPersistsAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        PageInstance: Page "Sales Comment Sheet";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-TRAP-BASE');
        Comment.SetRange("Document Type", Comment."Document Type");
        Comment.SetRange("No.", Comment."No.");
        PageInstance.SetTableView(Comment);
        Sheet.Trap();
        PageInstance.Run();
        Sheet.GoToRecord(Comment);
        Sheet.Comment.SetValue('Changed through trap');
        Observer.Observe('base control after set', Sheet.Comment.Value());
        Observer.Observe('ext copy after set', Sheet.PXSCCopy.Value());
        Sheet.Close();
        Stored(Comment);
        Observer.Observe('stored comment', Comment.Comment);
        Observer.Expect('base control after set', 'Changed through trap');
        Observer.Expect('ext copy after set', 'Changed through trap');
        Observer.Expect('stored comment', 'Changed through trap');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_ExtControlOnTableExtBoolean_EditPersistsAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        PageInstance: Page "Sales Comment Sheet";
        Sheet: TestPage "Sales Comment Sheet";
    begin
        Initialize(Comment, 'PXSC-TRAP-FLAG');
        Comment.SetRange("Document Type", Comment."Document Type");
        Comment.SetRange("No.", Comment."No.");
        PageInstance.SetTableView(Comment);
        Sheet.Trap();
        PageInstance.Run();
        Sheet.GoToRecord(Comment);
        Sheet.PXSCFlag.SetValue(true);
        Observer.Observe('flag after set', Format(Sheet.PXSCFlag.AsBoolean()));
        Sheet.Close();
        Stored(Comment);
        Observer.Observe('stored flag', Format(Comment."PXSC Flag"));
        Observer.Expect('flag after set', 'Yes');
        Observer.Expect('stored flag', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_UndeclaredControlId_IsNotFound()
    var
        Observer: Codeunit "Probe Observer";
        Comment: Record "Sales Comment Line";
        PageInstance: Page "Sales Comment Sheet";
        Sheet: TestPage "Sales Comment Sheet";
        Value: Text;
    begin
        Initialize(Comment, 'PXSC-TRAP-NF');
        Comment.SetRange("Document Type", Comment."Document Type");
        Comment.SetRange("No.", Comment."No.");
        PageInstance.SetTableView(Comment);
        Sheet.Trap();
        PageInstance.Run();
        Sheet.GoToRecord(Comment);
        asserterror Value := Sheet.GetField(12345).Value();
        Observer.ObserveError('get field 12345');
        Sheet.Close();
        Observer.Expect('get field 12345|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('get field 12345|code', 'TestFieldNotFound');
        Observer.Verify();
    end;
}
