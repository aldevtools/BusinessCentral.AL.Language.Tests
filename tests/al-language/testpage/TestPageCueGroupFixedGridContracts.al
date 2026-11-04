// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-cue-groups
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/controls/devenv-fixed-control
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68350, pages 68351..68355, codeunit 68356
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins how a TestPage sees the control kinds cuegroup, fixed and grid:
//  - The compiler gives a TestPage no member for the cuegroup, fixed, grid or group control itself
//    (AL0132 "does not contain a definition"), so a test cannot read or hide one. Their fields are
//    members of the page (a part's fields are members of the part), and so is a cuegroup action.
//  - A field inside a cuegroup reads its value, Visible() and Editable() like any field. A field with
//    Visible = false, and every field inside a cuegroup with Visible = false, is not on the page: reading
//    the value or Visible() raises "The field with ID = <n> is not found on the page." / TestFieldNotFound.
//  - SetValue on a cuegroup field does nothing and raises nothing: neither the page nor the table sees the
//    new value, even though Editable() says Yes. In an Editable = false cuegroup Editable() says No and
//    SetValue is as silent.
//  - A field in a fixed or grid control reads and takes SetValue like a list field; a repeater inside a
//    fixed control moves between rows like a list.
//  - Invoke on a cuegroup action runs its trigger, on the page and on a part page.
// BC versions: 27.5

table 68350 "Probe Cue Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Amt; Decimal) { }
        field(4; Flag; Boolean) { }
        field(5; Cnt; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68351 "Probe Cue Card"
{
    PageType = Card;
    SourceTable = "Probe Cue Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            cuegroup(CG)
            {
                Caption = 'Cue caption';
                field(Cnt; Rec.Cnt) { ApplicationArea = All; }
                field(Amt; Rec.Amt) { ApplicationArea = All; Visible = false; }
                actions
                {
                    action(CueAct)
                    {
                        ApplicationArea = All;
                        trigger OnAction()
                        begin
                            Message('cue action');
                        end;
                    }
                }
            }
            cuegroup(CGHidden)
            {
                Visible = false;
                field(Flag; Rec.Flag) { ApplicationArea = All; }
            }
            cuegroup(CGReadOnly)
            {
                Editable = false;
                field(Cnt2; Rec.Cnt) { ApplicationArea = All; }
            }
        }
    }
}

page 68352 "Probe Cue Fixed Grid List"
{
    PageType = List;
    SourceTable = "Probe Cue Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
            fixed(FX)
            {
                field(Txt; Rec.Txt) { ApplicationArea = All; }
                field(Amt; Rec.Amt) { ApplicationArea = All; }
            }
            grid(GR)
            {
                GridLayout = Rows;
                group(GRA)
                {
                    field(Flag; Rec.Flag) { ApplicationArea = All; }
                }
            }
        }
    }
}

page 68353 "Probe Cue Part"
{
    PageType = CardPart;
    SourceTable = "Probe Cue Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            cuegroup(PartCG)
            {
                field(Cnt; Rec.Cnt) { ApplicationArea = All; }
                actions
                {
                    action(PartAct)
                    {
                        ApplicationArea = All;
                        trigger OnAction()
                        begin
                            Message('part action');
                        end;
                    }
                }
            }
        }
    }
}

page 68354 "Probe Cue Host"
{
    PageType = Card;
    SourceTable = "Probe Cue Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "Probe Cue Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

page 68355 "Probe Cue Fixed Repeater"
{
    PageType = List;
    SourceTable = "Probe Cue Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            fixed(FX2)
            {
                repeater(RR)
                {
                    field(Cnt; Rec.Cnt) { ApplicationArea = All; }
                    field(Txt; Rec.Txt) { ApplicationArea = All; Visible = false; }
                }
            }
        }
    }
}

codeunit 68356 "Probe Cue Fixed Grid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LastMessage: Text;

    local procedure Seed()
    var
        CueRec: Record "Probe Cue Table";
    begin
        CueRec.DeleteAll();
        CueRec.Id := 1;
        CueRec.Txt := 'one';
        CueRec.Amt := 1.5;
        CueRec.Flag := true;
        CueRec.Cnt := 11;
        CueRec.Insert();
        CueRec.Id := 2;
        CueRec.Txt := 'two';
        CueRec.Amt := 2.5;
        CueRec.Flag := false;
        CueRec.Cnt := 22;
        CueRec.Insert();
        Commit();
    end;

    local procedure AssertNotFound(Context: Text)
    var
        Text: Text;
    begin
        // The id in the text is derived from the page and the control; it is not pinned here.
        Text := GetLastErrorText();
        Assert.IsTrue(Text.StartsWith('The field with ID = '), Context + ': start');
        Assert.IsTrue(Text.EndsWith(' is not found on the page.'), Context + ': end');
    end;

    [MessageHandler]
    procedure MessageH(Msg: Text[1024])
    begin
        LastMessage := Msg;
    end;

    [Test]
    [HandlerFunctions('MessageH')]
    procedure CueGroup_Fields_ReadAndTheActionRuns()
    var
        Card: TestPage "Probe Cue Card";
    begin
        Seed();
        LastMessage := '';
        Card.OpenEdit();

        Assert.AreEqual('11', Card.Cnt.Value(), 'cue value');
        Assert.IsTrue(Card.Cnt.Visible(), 'cue visible');
        Assert.IsTrue(Card.Cnt.Editable(), 'cue editable');
        Assert.AreEqual('Cnt', Card.Cnt.Caption(), 'cue caption is the field caption');
        Assert.IsTrue(Card.CueAct.Visible(), 'action visible');
        Assert.IsTrue(Card.CueAct.Enabled(), 'action enabled');

        Card.CueAct.Invoke();
        Assert.AreEqual('cue action', LastMessage, 'the action ran');
        Card.Close();
    end;

    [Test]
    procedure CueGroup_HiddenFieldAndHiddenGroup_AreNotOnThePage()
    var
        Card: TestPage "Probe Cue Card";
    begin
        Seed();
        Card.OpenEdit();

        asserterror Assert.AreEqual('', Card.Amt.Value(), 'x');
        AssertNotFound('hidden field value');
        Assert.AreEqual('TestFieldNotFound', GetLastErrorCode(), 'hidden field code');
        asserterror Assert.IsTrue(Card.Amt.Visible(), 'x');
        AssertNotFound('hidden field Visible');

        asserterror Assert.AreEqual('', Card.Flag.Value(), 'x');
        AssertNotFound('field of a hidden cuegroup, value');
        Assert.AreEqual('TestFieldNotFound', GetLastErrorCode(), 'field of a hidden cuegroup, code');
        asserterror Assert.IsTrue(Card.Flag.Visible(), 'x');
        AssertNotFound('field of a hidden cuegroup, Visible');
        Card.Close();
    end;

    [Test]
    procedure CueGroup_SetValue_IsSilentlyIgnored()
    var
        CueRec: Record "Probe Cue Table";
        Card: TestPage "Probe Cue Card";
    begin
        Seed();
        Card.OpenEdit();

        Assert.AreEqual('11', Card.Cnt2.Value(), 'read-only cue value');
        Assert.IsTrue(Card.Cnt2.Visible(), 'read-only cue visible');
        Assert.IsFalse(Card.Cnt2.Editable(), 'a cuegroup with Editable = false');

        Card.Cnt2.SetValue(7);
        Assert.AreEqual('11', Card.Cnt2.Value(), 'SetValue in the read-only cuegroup changed nothing');
        Card.Cnt.SetValue(33);
        Assert.AreEqual('11', Card.Cnt.Value(), 'SetValue in an editable cuegroup changed nothing either');
        Assert.AreEqual('11', Card.Cnt2.Value(), 'and the other control on the field');

        Card.Txt.SetValue('plain');
        Assert.AreEqual('plain', Card.Txt.Value(), 'SetValue on an ordinary field works');
        Card.Close();

        CueRec.Get(1);
        Assert.AreEqual(11, CueRec.Cnt, 'the table kept the cue value');
        Assert.AreEqual('plain', CueRec.Txt, 'and took the ordinary field');
    end;

    [Test]
    procedure FixedAndGrid_Fields_ReadAndTakeSetValueLikeListFields()
    var
        List: TestPage "Probe Cue Fixed Grid List";
    begin
        Seed();
        List.OpenEdit();

        Assert.AreEqual('1', List.Id.Value(), 'repeater field');
        Assert.AreEqual('one', List.Txt.Value(), 'fixed field');
        Assert.AreEqual('1.50', List.Amt.Value(), 'fixed decimal field');
        Assert.AreEqual('Yes', List.Flag.Value(), 'field in a group in a grid');

        List.Txt.SetValue('fixed-set');
        List.Amt.SetValue(9.5);
        Assert.AreEqual('fixed-set', List.Txt.Value(), 'SetValue in the fixed control');
        Assert.AreEqual('9.50', List.Amt.Value(), 'SetValue of the decimal');

        List.Next();
        Assert.AreEqual('2', List.Id.Value(), 'Next');
        Assert.AreEqual('two', List.Txt.Value(), 'fixed field on the second row');
        Assert.AreEqual('No', List.Flag.Value(), 'grid field on the second row');
        List.Close();
    end;

    [Test]
    procedure FixedWithRepeater_MovesBetweenRowsLikeAList()
    var
        List: TestPage "Probe Cue Fixed Repeater";
    begin
        Seed();
        List.OpenView();

        Assert.AreEqual('11', List.Cnt.Value(), 'first row');
        Assert.IsTrue(List.Next(), 'Next');
        Assert.AreEqual('22', List.Cnt.Value(), 'second row');
        Assert.IsTrue(List.Previous(), 'Previous');
        Assert.AreEqual('11', List.Cnt.Value(), 'back on the first row');
        Assert.IsTrue(List.GoToKey(2), 'GoToKey');
        Assert.AreEqual('22', List.Cnt.Value(), 'GoToKey row');
        List.Close();
    end;

    [Test]
    [HandlerFunctions('MessageH')]
    procedure PartPage_WithACueGroup_ReadsAndRunsItsAction()
    var
        Host: TestPage "Probe Cue Host";
    begin
        Seed();
        LastMessage := '';
        Host.OpenEdit();

        Assert.AreEqual('11', Host.PartCtl.Cnt.Value(), 'part cue value');
        Assert.IsTrue(Host.PartCtl.Cnt.Visible(), 'part cue visible');
        Host.PartCtl.PartAct.Invoke();
        Assert.AreEqual('part action', LastMessage, 'part action ran');

        Host.Next();
        Assert.AreEqual('22', Host.PartCtl.Cnt.Value(), 'the part follows the host');
        Host.Close();
    end;
}
