// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-editable-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68910, page 68911, codeunit 68912
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins Editable on a Page variable (not CurrPage):
//  - read before the page runs it answers true; "P.Editable := false" and "P.Editable(false)" are accepted before
//    RunModal and before Run (no error), and the variable then reads false;
//  - the page opens and runs; a TestPage handler reports Editable() false for the page and for its
//    fields; with Editable(true) both report true;
//  - the TestPage does not enforce it: SetValue on a field of the non-editable page works and the field shows the new
//    value;
//  - RunModal answers OK when the handler closes the page the default way.
// BC versions: 27.5

table 68910 "Probe PE Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68911 "Probe PE Page"
{
    PageType = List;
    SourceTable = "Probe PE Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 68912 "Probe Page Variable Editable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenEditable: Boolean;
        SeenFieldEditable: Boolean;
        SeenAfterSet: Text;

    local procedure Seed()
    var
        PeRec: Record "Probe PE Table";
    begin
        PeRec.DeleteAll();
        PeRec.Id := 1;
        PeRec.Txt := 'a';
        PeRec.Insert();
        Commit();
    end;

    [ModalPageHandler]
    procedure ReadHandler(var PePage: TestPage "Probe PE Page")
    begin
        SeenEditable := PePage.Editable();
        SeenFieldEditable := PePage.Txt.Editable();
        PePage.Txt.SetValue('zz');
        SeenAfterSet := PePage.Txt.Value();
    end;

    [PageHandler]
    procedure RunHandler(var PePage: TestPage "Probe PE Page")
    begin
        SeenEditable := PePage.Editable();
        SeenFieldEditable := PePage.Txt.Editable();
        PePage.Close();
    end;

    [Test]
    procedure EditableBeforeRun_IsTrue_AndAssignmentIsAccepted()
    var
        PePage: Page "Probe PE Page";
    begin
        Assert.IsTrue(PePage.Editable(), 'before anything');

        PePage.Editable := false;
        Assert.IsFalse(PePage.Editable(), 'after the assignment');

        PePage.Editable(true);
        Assert.IsTrue(PePage.Editable(), 'after Editable(true)');
        PePage.Editable(false);
        Assert.IsFalse(PePage.Editable(), 'after Editable(false)');
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RunModal_AfterEditableFalse_OpensANonEditablePage()
    var
        PePage: Page "Probe PE Page";
        Result: Action;
    begin
        Seed();
        SeenEditable := true;
        SeenFieldEditable := true;

        PePage.Editable(false);
        Result := PePage.RunModal();

        Assert.AreEqual(Action::OK, Result, 'result');
        Assert.IsFalse(SeenEditable, 'TestPage.Editable()');
        Assert.IsFalse(SeenFieldEditable, 'field Editable()');
        Assert.AreEqual('zz', SeenAfterSet, 'SetValue is not refused by the TestPage');
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure RunModal_AfterAssigningEditableTrue_OpensAnEditablePage()
    var
        PePage: Page "Probe PE Page";
    begin
        Seed();
        SeenEditable := false;
        SeenFieldEditable := false;

        PePage.Editable := true;
        PePage.RunModal();

        Assert.IsTrue(SeenEditable, 'TestPage.Editable()');
        Assert.IsTrue(SeenFieldEditable, 'field Editable()');
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure Run_AfterEditableFalse_OpensANonEditablePage()
    var
        PePage: Page "Probe PE Page";
    begin
        Seed();
        SeenEditable := true;
        SeenFieldEditable := true;

        PePage.Editable := false;
        PePage.Run();

        Assert.IsFalse(SeenEditable, 'TestPage.Editable()');
        Assert.IsFalse(SeenFieldEditable, 'field Editable()');
    end;
}
