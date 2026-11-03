// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-ui
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Unhandled UI "Unhandled UI: <Kind> <text> ... an error raised inside a Message, Confirm or StrMenu handler gets the code TestWrapped:<code>. Not pinned: the code of an error raised inside a page handler"
// BC versions: 29 (27 and 28 by CI)

page 71087 "LT PnC Card"
{
    PageType = Card;
    SourceTable = "LT PnC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }
}

report 71088 "LT PnC Rpt Req"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Flag; Flag)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Flag: Boolean;
}

codeunit 71111 "LT PnC Unhandled Ui"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Message_Unhandled()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Message('hello');
        Observer.ObserveError('message');
        asserterror Message('');
        Observer.ObserveError('messageEmpty');
        asserterror Message('a %1 b', 5);
        Observer.ObserveError('messageFormatted');
        Observer.Expect('message|text', 'Unhandled UI: Message hello');
        Observer.Expect('message|code', 'MissingUIHandler');
        Observer.Expect('messageEmpty|text', 'Unhandled UI: Message ');
        Observer.Expect('messageEmpty|code', 'MissingUIHandler');
        Observer.Expect('messageFormatted|text', 'Unhandled UI: Message a 5 b');
        Observer.Expect('messageFormatted|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Confirm_Unhandled()
    var
        Observer: Codeunit "Probe Observer";
        b: Boolean;
    begin
        asserterror b := Confirm('Really?');
        Observer.ObserveError('confirm');
        asserterror b := Confirm('Really %1?', true, 'x');
        Observer.ObserveError('confirmDefaultTrue');
        asserterror b := Confirm('');
        Observer.ObserveError('confirmEmpty');
        Observer.Expect('confirm|text', 'Unhandled UI: Confirm Really?');
        Observer.Expect('confirm|code', 'MissingUIHandler');
        Observer.Expect('confirmDefaultTrue|text', 'Unhandled UI: Confirm Really %1?');
        Observer.Expect('confirmDefaultTrue|code', 'MissingUIHandler');
        Observer.Expect('confirmEmpty|text', 'Unhandled UI: Confirm ');
        Observer.Expect('confirmEmpty|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure StrMenu_Unhandled()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        asserterror i := StrMenu('One,Two,Three');
        Observer.ObserveError('strMenu');
        asserterror i := StrMenu('One,Two', 2, 'Pick');
        Observer.ObserveError('strMenuDefaultAndInstruction');
        asserterror i := StrMenu('');
        Observer.ObserveError('strMenuEmpty');
        Observer.Expect('strMenu|text', 'Unhandled UI: StrMenu One,Two,Three');
        Observer.Expect('strMenu|code', 'MissingUIHandler');
        Observer.Expect('strMenuDefaultAndInstruction|text', 'Unhandled UI: StrMenu One,Two');
        Observer.Expect('strMenuDefaultAndInstruction|code', 'MissingUIHandler');
        Observer.Expect('strMenuEmpty|text', 'Unhandled UI: StrMenu ');
        Observer.Expect('strMenuEmpty|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Pages_Unhandled()
    var
        Observer: Codeunit "Probe Observer";
        i: Action;
    begin
        asserterror Page.Run(Page::"LT PnC Card");
        Observer.ObserveError('pageRun');
        asserterror i := Page.RunModal(Page::"LT PnC Card");
        Observer.ObserveError('pageRunModal');
        asserterror Page.Run(Page::"LT PnC List");
        Observer.ObserveError('pageRunList');
        Observer.Expect('pageRun|text', 'Unhandled UI: Page 71087');
        Observer.Expect('pageRun|code', 'MissingUIHandler');
        Observer.Expect('pageRunModal|text', 'Unhandled UI: ModalPage 71087');
        Observer.Expect('pageRunModal|code', 'MissingUIHandler');
        Observer.Expect('pageRunList|text', 'Unhandled UI: Page 71086');
        Observer.Expect('pageRunList|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Report_RequestPage_Unhandled()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Report.Run(Report::"LT PnC Rpt Req");
        Observer.ObserveError('reportRun');
        asserterror Report.RunModal(Report::"LT PnC Rpt Req");
        Observer.ObserveError('reportRunModal');
        Observer.Expect('reportRun|text', 'Unhandled UI: RequestPage 71088');
        Observer.Expect('reportRun|code', 'MissingUIHandler');
        Observer.Expect('reportRunModal|text', 'Unhandled UI: RequestPage 71088');
        Observer.Expect('reportRunModal|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageRaisesError')]
    procedure Handler_Error_Message()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Message('hello');
        Observer.ObserveError('messageHandlerError');
        Observer.Expect('messageHandlerError|text', 'from message handler');
        Observer.Expect('messageHandlerError|code', 'TestWrapped:Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmRaisesError')]
    procedure Handler_Error_Confirm()
    var
        Observer: Codeunit "Probe Observer";
        b: Boolean;
    begin
        asserterror b := Confirm('Really?');
        Observer.ObserveError('confirmHandlerError');
        Observer.Expect('confirmHandlerError|text', 'from confirm handler');
        Observer.Expect('confirmHandlerError|code', 'TestWrapped:Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StrMenuRaisesError')]
    procedure Handler_Error_StrMenu()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        asserterror i := StrMenu('One,Two');
        Observer.ObserveError('strMenuHandlerError');
        Observer.Expect('strMenuHandlerError|text', 'from strmenu handler');
        Observer.Expect('strMenuHandlerError|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageRaisesError')]
    procedure Handler_Error_Page()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Page.Run(Page::"LT PnC Card");
        Observer.ObserveError('pageHandlerError');
        Observer.Expect('pageHandlerError|text', 'from page handler');
        Observer.Expect('pageHandlerError|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalPageRaisesError')]
    procedure Handler_Error_ModalPage()
    var
        Observer: Codeunit "Probe Observer";
        i: Action;
    begin
        asserterror i := Page.RunModal(Page::"LT PnC Card");
        Observer.ObserveError('modalPageHandlerError');
        Observer.Expect('modalPageHandlerError|text', 'from modal page handler');
        Observer.Expect('modalPageHandlerError|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestPageRaisesError')]
    procedure Handler_Error_RequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Report.Run(Report::"LT PnC Rpt Req");
        Observer.ObserveError('requestPageHandlerError');
        Observer.Expect('requestPageHandlerError|text', 'from request page handler');
        Observer.Expect('requestPageHandlerError|code', 'Dialog');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MessageRaisesError(Message: Text[1024])
    begin
        Error('from message handler');
    end;

    [ConfirmHandler]
    procedure ConfirmRaisesError(Question: Text[1024]; var Reply: Boolean)
    begin
        Error('from confirm handler');
    end;

    [StrMenuHandler]
    procedure StrMenuRaisesError(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Error('from strmenu handler');
    end;

    [PageHandler]
    procedure PageRaisesError(var P: TestPage "LT PnC Card")
    begin
        Error('from page handler');
    end;

    [ModalPageHandler]
    procedure ModalPageRaisesError(var P: TestPage "LT PnC Card")
    begin
        Error('from modal page handler');
    end;

    [RequestPageHandler]
    procedure RequestPageRaisesError(var R: TestRequestPage "LT PnC Rpt Req")
    begin
        Error('from request page handler');
    end;
}
