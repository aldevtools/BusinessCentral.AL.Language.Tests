// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onnewrecord-page-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagemode-property
// Scope: in-scope
// Fixtures used: ARPX Row (67030), ARPX Host Row (67031), ARPX Probe (67032), ARPX Card (67033),
//                ARPX Dialog (67034), ARPX Host (67035), Assert (60021)
//
/// <summary>
/// Pins what a page's OnNewRecord(BelowxRec) trigger receives when the page OPENS on a new
/// record: the BelowxRec argument, the key xRec stands on, and the key Rec stands on -- together
/// with which of the page's triggers ran, in order ('open' for OnOpenPage, 'new:...' for
/// OnNewRecord).
///
/// Six routes open a page on a new record, each asked on a table holding two rows ('A', 'B')
/// and on an empty table (the "no row positioned yet" case):
///     TestPage.OpenNew()
///     an action with RunPageMode = Create on a Card target, answered by a [PageHandler]
///     the same, with nothing bound
///     the same, caught by TestPage.Trap()
///     an action with RunPageMode = Create on a StandardDialog target, answered by a
///         [ModalPageHandler]
///     the same, with nothing bound -- which BC refuses with its no-handler error
///
/// The host page stands on a table of its own, so the target's table can be empty.
///
/// Written by agent stma-auto-3, an automated implementation agent acting on the account
/// holder's behalf, for AL Runner issues StefanMaron/BusinessCentral.AL.Runner#5014 (whether a
/// dialog target opened in Create mode with no handler runs OnNewRecord before BC's refusal)
/// and StefanMaron/BusinessCentral.AL.Runner#5015 (the BelowxRec argument and xRec on a
/// Create-mode open). The corpus read BelowxRec nowhere.
/// </summary>

table 67030 "ARPX Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 67031 "ARPX Host Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 67032 "ARPX Probe"
{
    SingleInstance = true;

    var
        Trail: Text;

    procedure Reset()
    begin
        Trail := '';
    end;

    procedure Note(TriggerName: Text)
    begin
        if Trail <> '' then
            Trail += ',';
        Trail += TriggerName;
    end;

    procedure NoteNewRecord(BelowxRec: Boolean; XNo: Code[20]; No: Code[20])
    begin
        Note('new:below=' + Format(BelowxRec) + ',x=' + XNo + ',no=' + No);
    end;

    procedure Triggers(): Text
    begin
        exit(Trail);
    end;
}

page 67033 "ARPX Card"
{
    PageType = Card;
    SourceTable = "ARPX Row";
    ApplicationArea = All;
    Caption = 'ARPX Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Probe: Codeunit "ARPX Probe";
    begin
        Probe.Note('open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Probe: Codeunit "ARPX Probe";
    begin
        Probe.NoteNewRecord(BelowxRec, xRec."No.", Rec."No.");
    end;
}

page 67034 "ARPX Dialog"
{
    PageType = StandardDialog;
    SourceTable = "ARPX Row";
    ApplicationArea = All;
    Caption = 'ARPX Dialog';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Probe: Codeunit "ARPX Probe";
    begin
        Probe.Note('open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Probe: Codeunit "ARPX Probe";
    begin
        Probe.NoteNewRecord(BelowxRec, xRec."No.", Rec."No.");
    end;
}

page 67035 "ARPX Host"
{
    PageType = Card;
    SourceTable = "ARPX Host Row";
    ApplicationArea = All;
    Caption = 'ARPX Host';

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCreate)
            {
                ApplicationArea = All;
                Caption = 'Open Create';
                RunObject = page "ARPX Card";
                RunPageMode = Create;
            }
            action(OpenCreateDialog)
            {
                ApplicationArea = All;
                Caption = 'Open Create Dialog';
                RunObject = page "ARPX Dialog";
                RunPageMode = Create;
            }
        }
    }
}

codeunit 67036 "ARPX Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        NoHandlerErr: Label 'TestPages that are invoked from a RunObject action must have a handler', Locked = true;

    local procedure Seed(WithRows: Boolean)
    var
        Row: Record "ARPX Row";
        HostRow: Record "ARPX Host Row";
        Probe: Codeunit "ARPX Probe";
    begin
        Probe.Reset();
        Row.DeleteAll();
        HostRow.DeleteAll();
        HostRow.Code := 'H';
        HostRow.Insert();
        if WithRows then begin
            AddRow('A', 'Alpha');
            AddRow('B', 'Bravo');
        end;
    end;

    local procedure AddRow(No: Code[20]; NewName: Text[50])
    var
        Row: Record "ARPX Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure OpenHost(var Host: TestPage "ARPX Host"; WithRows: Boolean)
    begin
        Seed(WithRows);
        Host.OpenEdit();
        Host.GoToKey('H');
    end;

    local procedure Triggers(): Text
    var
        Probe: Codeunit "ARPX Probe";
    begin
        exit(Probe.Triggers());
    end;

    // --- TestPage.OpenNew() ---

    [Test]
    procedure OpenNew_TableWithRows()
    var
        Card: TestPage "ARPX Card";
    begin
        Seed(true);
        Card.OpenNew();
        Card.Close();

        Assert.AreEqual('open,new:below=Yes,x=B,no=', Triggers(),
            'TestPage.OpenNew() on a table with rows: the card''s triggers, with OnNewRecord''s BelowxRec, xRec and Rec keys.');
    end;

    [Test]
    procedure OpenNew_EmptyTable()
    var
        Card: TestPage "ARPX Card";
    begin
        Seed(false);
        Card.OpenNew();
        Card.Close();

        Assert.AreEqual('open,new:below=Yes,x=,no=', Triggers(),
            'TestPage.OpenNew() on an empty table: the card''s triggers, with OnNewRecord''s BelowxRec, xRec and Rec keys.');
    end;

    // --- RunPageMode = Create on a Card target, answered by a [PageHandler] ---

    [Test]
    [HandlerFunctions('CardCloseHandler')]
    procedure ActionCreate_Handler_TableWithRows()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, true);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=B,no=', Triggers(),
            'RunPageMode = Create, [PageHandler] bound, table with rows: the card''s triggers and OnNewRecord''s arguments.');
    end;

    [Test]
    [HandlerFunctions('CardCloseHandler')]
    procedure ActionCreate_Handler_EmptyTable()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, false);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=,no=', Triggers(),
            'RunPageMode = Create, [PageHandler] bound, empty table: the card''s triggers and OnNewRecord''s arguments.');
    end;

    // --- RunPageMode = Create on a Card target, nothing bound ---

    [Test]
    procedure ActionCreate_NoHandler_TableWithRows()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, true);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=B,no=', Triggers(),
            'RunPageMode = Create, nothing bound, table with rows: the card''s triggers and OnNewRecord''s arguments.');
    end;

    [Test]
    procedure ActionCreate_NoHandler_EmptyTable()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, false);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=,no=', Triggers(),
            'RunPageMode = Create, nothing bound, empty table: the card''s triggers and OnNewRecord''s arguments.');
    end;

    // --- RunPageMode = Create on a Card target, caught by TestPage.Trap() ---

    [Test]
    procedure ActionCreate_Trapped_TableWithRows()
    var
        Host: TestPage "ARPX Host";
        Card: TestPage "ARPX Card";
    begin
        OpenHost(Host, true);
        Card.Trap();
        Host.OpenCreate.Invoke();
        Card.Close();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=B,no=', Triggers(),
            'RunPageMode = Create, caught by TestPage.Trap(), table with rows: the card''s triggers and OnNewRecord''s arguments.');
    end;

    [Test]
    procedure ActionCreate_Trapped_EmptyTable()
    var
        Host: TestPage "ARPX Host";
        Card: TestPage "ARPX Card";
    begin
        OpenHost(Host, false);
        Card.Trap();
        Host.OpenCreate.Invoke();
        Card.Close();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=,no=', Triggers(),
            'RunPageMode = Create, caught by TestPage.Trap(), empty table: the card''s triggers and OnNewRecord''s arguments.');
    end;

    // --- RunPageMode = Create on a StandardDialog target, answered by a [ModalPageHandler] ---

    [Test]
    [HandlerFunctions('DialogCancelHandler')]
    procedure DialogCreate_ModalHandler_TableWithRows()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, true);
        Host.OpenCreateDialog.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=B,no=', Triggers(),
            'RunPageMode = Create on a dialog, [ModalPageHandler] bound, table with rows: the dialog''s triggers and OnNewRecord''s arguments.');
    end;

    [Test]
    [HandlerFunctions('DialogCancelHandler')]
    procedure DialogCreate_ModalHandler_EmptyTable()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, false);
        Host.OpenCreateDialog.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:below=Yes,x=,no=', Triggers(),
            'RunPageMode = Create on a dialog, [ModalPageHandler] bound, empty table: the dialog''s triggers and OnNewRecord''s arguments.');
    end;

    // --- RunPageMode = Create on a StandardDialog target, nothing bound ---
    // BC refuses the invoke. The probe is SingleInstance, so what the dialog's triggers noted
    // before the refusal survives the error's rollback.

    [Test]
    procedure DialogCreate_NoHandler_TableWithRows()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, true);
        asserterror Host.OpenCreateDialog.Invoke();
        Assert.ExpectedError(NoHandlerErr);

        Assert.AreEqual('open,new:below=Yes,x=B,no=', Triggers(),
            'RunPageMode = Create on a dialog, nothing bound, table with rows: the dialog''s triggers before BC''s refusal.');
    end;

    [Test]
    procedure DialogCreate_NoHandler_EmptyTable()
    var
        Host: TestPage "ARPX Host";
    begin
        OpenHost(Host, false);
        asserterror Host.OpenCreateDialog.Invoke();
        Assert.ExpectedError(NoHandlerErr);

        Assert.AreEqual('open,new:below=Yes,x=,no=', Triggers(),
            'RunPageMode = Create on a dialog, nothing bound, empty table: the dialog''s triggers before BC''s refusal.');
    end;

    [PageHandler]
    procedure CardCloseHandler(var Card: TestPage "ARPX Card")
    begin
        Card.Close();
    end;

    [ModalPageHandler]
    procedure DialogCancelHandler(var Dialog: TestPage "ARPX Dialog")
    begin
        Dialog.Cancel().Invoke();
    end;
}
