// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68420, page 68421, codeunit 68422
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins which layout and action kinds a TestPage can name. Compile result (AL0132 "does not contain a
// definition for <name>"), measured on a page declaring each kind:
//  - a label control IS a member of the TestPage; a usercontrol, a group, a systempart, a customaction
//    and a fileuploadaction are NOT (a test cannot name them), while a plain action and a field are.
//  - an action that has no OnAction trigger (and no RunObject or other behaviour) is not on the TestPage:
//    naming it raises "The action with ID = <n> is not found on the page." / TestActionNotFound.
//  - a label reads Visible Yes, Enabled Yes, Editable No, its Caption and Value are the label's caption.
// BC versions: 27.5

table 68420 "Probe Label Table"
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

page 68421 "Probe Label Kinds"
{
    PageType = Card;
    SourceTable = "Probe Label Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            label(Lbl)
            {
                ApplicationArea = All;
                Caption = 'A label';
            }
            group(Grp)
            {
                Caption = 'A group';

                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Plain)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
            customaction(Cust)
            {
                ApplicationArea = All;
                Caption = 'Custom';
            }
        }
    }
}

page 68423 "Probe Label No Trigger"
{
    PageType = Card;
    SourceTable = "Probe Label Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NoTrigger)
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 68422 "Probe Page Label Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Label_IsATestPageMember_WithItsCaption()
    var
        LabelRec: Record "Probe Label Table";
        Kinds: TestPage "Probe Label Kinds";
    begin
        LabelRec.DeleteAll();
        LabelRec.Id := 1;
        LabelRec.Txt := 'a';
        LabelRec.Insert();
        Commit();

        Kinds.OpenView();

        Assert.AreEqual('1', Kinds.Id.Value(), 'field');
        Assert.AreEqual('a', Kinds.Txt.Value(), 'field in a group');
        Assert.IsTrue(Kinds.Plain.Visible(), 'plain action visible');
        Assert.IsTrue(Kinds.Lbl.Visible(), 'label visible');
        Assert.IsTrue(Kinds.Lbl.Enabled(), 'label enabled');
        Assert.IsFalse(Kinds.Lbl.Editable(), 'label editable');
        Assert.AreEqual('A label', Kinds.Lbl.Caption(), 'label caption');
        Assert.AreEqual('A label', Kinds.Lbl.Value(), 'label value');
        Kinds.Close();
    end;

    [Test]
    procedure ActionWithoutAnOnActionTrigger_IsNotOnTheTestPage()
    var
        LabelRec: Record "Probe Label Table";
        NoTrig: TestPage "Probe Label No Trigger";
    begin
        LabelRec.DeleteAll();
        LabelRec.Id := 1;
        LabelRec.Insert();
        Commit();

        NoTrig.OpenView();

        asserterror Assert.IsTrue(NoTrig.NoTrigger.Visible(), 'visible');

        Assert.IsTrue(GetLastErrorText().StartsWith('The action with ID = '), 'text start');
        Assert.IsTrue(GetLastErrorText().EndsWith(' is not found on the page.'), 'text end');
        Assert.AreEqual('TestActionNotFound', GetLastErrorCode(), 'code');
    end;
}
