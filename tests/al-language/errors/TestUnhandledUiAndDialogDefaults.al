// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained pages 68124, 68125 and codeunit 68126
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the full text and error code of the "Unhandled UI" refusal for each UI call kind, the
// defaults a handler sees for an omitted Confirm default and an omitted StrMenu default/instruction,
// and how an error raised inside a handler reaches the test.
//
// A handler that is declared and never called fails the test with "The following UI handlers
// were not executed: <names>"; that cannot be asserted from a passing test, so it is not here.
// BC versions: 27.5

page 68124 "Probe Ui Card"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 68125 "Probe Ui OnRun Message"
{
    trigger OnRun()
    begin
        Message('from OnRun');
    end;
}

codeunit 68126 "Probe Unhandled Ui"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        Seen: Text;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Seen := '';
    end;

    [Test]
    procedure Message_NoHandler_FullTextAndCode()
    begin
        Initialize();

        asserterror Message('hello %1', 5);

        Assert.AreEqual('Unhandled UI: Message hello 5', GetLastErrorText(), 'text: one space after the kind');
        Assert.AreEqual('MissingUIHandler', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Confirm_NoHandler_FullTextAndCode()
    var
        Reply: Boolean;
    begin
        Initialize();

        asserterror Reply := Confirm('really?', true);
        Assert.AreEqual('Unhandled UI: Confirm really?', GetLastErrorText(), 'text with an explicit default');
        Assert.AreEqual('MissingUIHandler', GetLastErrorCode(), 'code');

        asserterror Reply := Confirm('really?');
        Assert.AreEqual('Unhandled UI: Confirm really?', GetLastErrorText(), 'text with the default omitted');
    end;

    [Test]
    procedure StrMenu_NoHandler_FullTextAndCode()
    var
        Choice: Integer;
    begin
        Initialize();

        asserterror Choice := StrMenu('One,Two,Three', 2, 'Pick');
        Assert.AreEqual('Unhandled UI: StrMenu One,Two,Three', GetLastErrorText(), 'text carries the options only');
        Assert.AreEqual('MissingUIHandler', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Pages_NoHandler_FullTextAndCode()
    begin
        Initialize();

        asserterror Page.RunModal(Page::"Probe Ui Card");
        Assert.AreEqual('Unhandled UI: ModalPage 68124', GetLastErrorText(), 'modal page names the page id');
        Assert.AreEqual('MissingUIHandler', GetLastErrorCode(), 'code');

        asserterror Page.Run(Page::"Probe Ui Card");
        Assert.AreEqual('Unhandled UI: Page 68124', GetLastErrorText(), 'non-modal page names the page id');
    end;

    [Test]
    procedure Message_NoHandler_InsideARunCodeunit_IsRefusedToo()
    begin
        Initialize();

        asserterror Codeunit.Run(Codeunit::"Probe Ui OnRun Message");

        Assert.AreEqual('Unhandled UI: Message from OnRun', GetLastErrorText(), 'text');
        Assert.AreEqual('MissingUIHandler', GetLastErrorCode(), 'code');
    end;

    [Test]
    [HandlerFunctions('ConfirmRecordsAndAccepts,StrMenuRecords')]
    procedure Dialog_Defaults_SeenByTheHandlers()
    // CLAIM: an omitted Confirm default reaches the handler as false; an omitted StrMenu default is 1 and an omitted instruction is empty.
    var
        Reply: Boolean;
        Choice: Integer;
    begin
        Initialize();

        Reply := Confirm('q1');
        Assert.AreEqual('Q=q1 ReplyIn=No', Seen, 'Confirm');
        Assert.IsTrue(Reply, 'the handler''s reply is returned');

        Seen := '';
        Choice := StrMenu('One,Two,Three');
        Assert.AreEqual('Options=One,Two,Three ChoiceIn=1 Instr=[]', Seen, 'StrMenu with defaults');

        Seen := '';
        Choice := StrMenu('One,Two,Three', 3, 'Instr');
        Assert.AreEqual('Options=One,Two,Three ChoiceIn=3 Instr=[Instr]', Seen, 'StrMenu with explicit values');
        Assert.AreEqual(3, Choice, 'the choice the handler left is returned');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerThatErrors')]
    procedure ErrorInsideHandler_ComesOutOfTheMessageCall_AsTestWrappedDialog()
    begin
        Initialize();

        asserterror Message('boom');

        Assert.AreEqual('handler error boom', GetLastErrorText(), 'text');
        Assert.AreEqual('TestWrapped:Dialog', GetLastErrorCode(), 'code');
    end;

    [ConfirmHandler]
    procedure ConfirmRecordsAndAccepts(Question: Text; var Reply: Boolean)
    begin
        Seen += 'Q=' + Question + ' ReplyIn=' + Format(Reply);
        Reply := true;
    end;

    [StrMenuHandler]
    procedure StrMenuRecords(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Seen += 'Options=' + Options + ' ChoiceIn=' + Format(Choice) + ' Instr=[' + Instruction + ']';
    end;

    [MessageHandler]
    procedure MessageHandlerThatErrors(Msg: Text)
    begin
        Error('handler error %1', Msg);
    end;
}
