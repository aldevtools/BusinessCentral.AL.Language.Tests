// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// local object: the card, its page extension (with the OnQueryClosePage trigger and a field with OnValidate) and the table procedure are the objects under test
// Probe: written against BC 27.5, 28.5 and 29.0 through the corpus CI; every literal asserted below is what those tiers produced (they agree).
//
// TestPageQueryCloseError_Tests.al (60677) pins that an error raised in OnQueryClosePage during TestPage.Close() reaches a test that declares
// no [MessageHandler] as "Unhandled UI: Message <error text>" and says it deliberately leaves out the same close with a [MessageHandler]
// declared. This file pins that case. With a [MessageHandler] declared the platform shows the error as a message, the handler consumes it,
// TestPage.Close() returns without raising, and the error text of OnQueryClosePage is the last error (GetLastErrorText), whether the row is
// clean, dirty from another field, or dirty from a field whose OnValidate asked a Confirm that a [ConfirmHandler] answered.
// Filed from AL Runner issue 7457.
// BC versions: 27+ (tested by the corpus CI matrix)

table 96840 "LT QCM IC"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Active; Boolean) { }
        field(3; InboxType; Integer) { }
        field(4; InboxDetails; Text[30]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }

    procedure CheckSetup()
    begin
        TestField(InboxDetails);
    end;
}

page 96841 "LT QCM IC Card"
{
    PageType = Card;
    SourceTable = "LT QCM IC";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            field(InboxType; Rec.InboxType) { ApplicationArea = All; }
            field(InboxDetails; Rec.InboxDetails) { ApplicationArea = All; }
        }
    }
}

pageextension 96842 "LT QCM IC Card Ext" extends "LT QCM IC Card"
{
    layout
    {
        addlast(Content)
        {
            field(MyActive; Rec.Active)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    if Rec.Active then begin
                        Rec.TestField(InboxType);
                        if not Confirm('LT QCM confirm?') then
                            Error('LT QCM not confirmed');
                    end;
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Rec.Active then
            Rec.CheckSetup();
    end;
}

codeunit 96840 "LT QCM Close Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(ActiveNow: Boolean)
    var
        Row: Record "LT QCM IC";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'GU5';
        Row.InboxType := 1;
        Row.Active := ActiveNow;
        Row.Insert();
    end;

    [ConfirmHandler]
    procedure YesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageSink(Msg: Text)
    begin
    end;

    [Test]
    [HandlerFunctions('YesHandler,MessageSink')]
    procedure CloseAfterConfirmedActivation_WithMessageHandler_ReturnsAndLeavesTheErrorAsLastError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QCM IC";
        Card: TestPage "LT QCM IC Card";
    begin
        Seed(false);
        Row.Get('GU5');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.MyActive.SetValue(true);
        Card.Close();
        Observer.Observe('last error text after Close', GetLastErrorText());
        Observer.Expect('last error text after Close', 'InboxDetails must have a value in LT QCM IC: Code=GU5. It cannot be zero or empty.');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageSink')]
    procedure CloseOfCleanRow_WithMessageHandler_ReturnsAndLeavesTheErrorAsLastError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QCM IC";
        Card: TestPage "LT QCM IC Card";
    begin
        Seed(true);
        Row.Get('GU5');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Close();
        Observer.Observe('last error text after Close', GetLastErrorText());
        Observer.Expect('last error text after Close', 'InboxDetails must have a value in LT QCM IC: Code=GU5. It cannot be zero or empty.');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageSink')]
    procedure CloseAfterEditingAnotherField_WithMessageHandler_ReturnsAndLeavesTheErrorAsLastError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QCM IC";
        Card: TestPage "LT QCM IC Card";
    begin
        Seed(true);
        Row.Get('GU5');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.InboxType.SetValue(2);
        Card.Close();
        Observer.Observe('last error text after Close', GetLastErrorText());
        Observer.Expect('last error text after Close', 'InboxDetails must have a value in LT QCM IC: Code=GU5. It cannot be zero or empty.');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('YesHandler')]
    procedure CloseAfterConfirmedActivation_WithoutMessageHandler_RaisesUnhandledMessage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QCM IC";
        Card: TestPage "LT QCM IC Card";
    begin
        Seed(false);
        Row.Get('GU5');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.MyActive.SetValue(true);
        asserterror Card.Close();
        Observer.ObserveError('Close');
        Observer.Expect('Close|text', 'Unhandled UI: Message InboxDetails must have a value in LT QCM IC: Code=GU5. It cannot be zero or empty.');
        Observer.Expect('Close|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}
