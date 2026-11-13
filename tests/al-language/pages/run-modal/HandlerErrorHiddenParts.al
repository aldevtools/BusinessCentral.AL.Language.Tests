// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages (ModalPageHandler)
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope (Cloud). Page.RunModal with a ModalPageHandler that raises an error.
// Fixtures used: Probe Observer (codeunit 69160); own tables 64755 64756, log codeunit 64757, part pages 64758 64759, host pages 64760
//   64761, test codeunit 64762
// Probe (values from the CI runs on BC 27.5, 28.5 and 29.0, the same on all three). Area: a ModalPageHandler that raises an error on a Document page that has parts with OnQueryClosePage and a part
//   that is not visible (a Visible expression that is false, or Visible = false), and the same with an unsaved row (a typed value with
//   no CurrPage.Update). The error comes from the table's OnModify through a control's OnValidate with CurrPage.Update() (al-runner issue
//   7473), or from Error() in the handler after a typed value. Pinned: a page with open parts that refuses the close
//   (pages/triggers/PageModalQueryCloseVeto.al:478) and a close allowed in lookup mode (ui-handlers/WbModalHandlerCloseTests.al). Not
//   pinned: a hidden part, an unsaved row, a close allowed outside lookup mode.
// Observed: the error RunModal raises (text and code), the log of the close triggers (HQ/HC host OnQueryClosePage/OnClosePage, LQ/LC
//   lines part, IQ/IC info part, M = table OnModify) and the stored row after the run.
// local object: the pages, their parts and close triggers are what the test checks
// BC versions: 27, 28, 29

table 64755 "PGA HE Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Status; Code[10]) { DataClassification = SystemMetadata; }
        field(3; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "PGA HE Log";
    begin
        Log.Add('M(' + xRec.Status + '>' + Status + ')');
        if xRec.Status = 'FINAL' then
            Error('Documents with the status %1 cannot be modified.', xRec.Status);
    end;
}

table 64756 "PGA HE Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

codeunit 64757 "PGA HE Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ShowInfo: Boolean;
        Step: Text;

    procedure Reset(NewShow: Boolean; NewStep: Text)
    begin
        Entries := '';
        ShowInfo := NewShow;
        Step := NewStep;
    end;

    procedure Show(): Boolean
    begin
        exit(ShowInfo);
    end;

    procedure GetStep(): Text
    begin
        exit(Step);
    end;

    procedure SetStep(NewStep: Text)
    begin
        Step := NewStep;
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 64758 "PGA HE Lines"
{
    PageType = ListPart;
    SourceTable = "PGA HE Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PGA HE Log";

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('LQ(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('LC');
    end;
}

page 64759 "PGA HE Info"
{
    PageType = CardPart;
    SourceTable = "PGA HE Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "PGA HE Log";

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('IQ(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('IC');
    end;
}

page 64760 "PGA HE Doc Expr"
{
    PageType = Document;
    SourceTable = "PGA HE Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
            part(Lines; "PGA HE Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Info; "PGA HE Info")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = InfoVisible;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    var
        Log: Codeunit "PGA HE Log";
        InfoVisible: Boolean;

    trigger OnOpenPage()
    begin
        InfoVisible := Log.Show();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('HQ(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('HC');
    end;
}

page 64761 "PGA HE Doc Literal"
{
    PageType = Document;
    SourceTable = "PGA HE Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
            part(Lines; "PGA HE Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Info; "PGA HE Info")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
        }
    }
}

codeunit 64762 "PGA HE Handler Error Hidden"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGA HE Log";

    local procedure Initialize(Show: Boolean; Step: Text)
    var
        Doc: Record "PGA HE Doc";
        Line: Record "PGA HE Line";
    begin
        Observer.Discard();
        Line.DeleteAll();
        Doc.DeleteAll();
        Doc.Init();
        Doc."No." := 'D1';
        Doc.Status := 'OPEN';
        Doc.Insert();
        Line.Init();
        Line."Doc No." := 'D1';
        Line."Line No." := 10;
        Line.Insert();
        Log.Reset(Show, Step);
    end;

    local procedure Stored(): Text
    var
        Doc: Record "PGA HE Doc";
    begin
        Doc.Get('D1');
        exit(Doc.Status + '|' + Doc.Name);
    end;

    local procedure RunTwice(PageId: Integer; FirstStep: Text; SecondStep: Text)
    var
        Doc: Record "PGA HE Doc";
    begin
        Doc.Get('D1');
        Log.SetStep(FirstStep);
        Observer.Observe('first', Format(Page.RunModal(PageId, Doc)));
        Observer.Observe('log-first', Log.Take());
        Observer.Observe('stored-first', Stored());
        Commit();
        Doc.Get('D1');
        Log.SetStep(SecondStep);
        asserterror Page.RunModal(PageId, Doc);
        Observer.ObserveError('second');
        Observer.Observe('log-second', Log.Take());
        Observer.Observe('stored-second', Stored());
    end;

    [Test]
    [HandlerFunctions('ExprHandler')]
    procedure Expr_InfoHidden_OnModifyErrorThroughUpdate()
    begin
        Initialize(false, '');
        RunTwice(Page::"PGA HE Doc Expr", 'FINAL', 'OTHER');
        Observer.Expect('first', 'LookupCancel');
        Observer.Expect('log-first', 'M(OPEN>FINAL) IQ(None) LQ(None) HQ(LookupCancel) IC LC HC');
        Observer.Expect('stored-first', 'FINAL|');
        Observer.Expect('second|text', 'Validation error for Field: Status,  Message = ''Documents with the status FINAL cannot be modified. (Select Refresh to discard errors)''');
        Observer.Expect('second|code', 'TestValidation');
        Observer.Expect('log-second', 'M(FINAL>OTHER)');
        Observer.Expect('stored-second', 'FINAL|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ExprHandler')]
    procedure Expr_InfoShown_OnModifyErrorThroughUpdate()
    begin
        Initialize(true, '');
        RunTwice(Page::"PGA HE Doc Expr", 'FINAL', 'OTHER');
        Observer.Expect('first', 'LookupCancel');
        Observer.Expect('log-first', 'M(OPEN>FINAL) IQ(None) LQ(None) HQ(LookupCancel) IC LC HC');
        Observer.Expect('stored-first', 'FINAL|');
        Observer.Expect('second|text', 'Validation error for Field: Status,  Message = ''Documents with the status FINAL cannot be modified. (Select Refresh to discard errors)''');
        Observer.Expect('second|code', 'TestValidation');
        Observer.Expect('log-second', 'M(FINAL>OTHER)');
        Observer.Expect('stored-second', 'FINAL|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LiteralHandler')]
    procedure Literal_InfoHidden_OnModifyErrorThroughUpdate()
    begin
        Initialize(false, '');
        RunTwice(Page::"PGA HE Doc Literal", 'FINAL', 'OTHER');
        Observer.Expect('first', 'LookupCancel');
        Observer.Expect('log-first', 'M(OPEN>FINAL) LQ(None) LC');
        Observer.Expect('stored-first', 'FINAL|');
        Observer.Expect('second|text', 'Validation error for Field: Status,  Message = ''Documents with the status FINAL cannot be modified. (Select Refresh to discard errors)''');
        Observer.Expect('second|code', 'TestValidation');
        Observer.Expect('log-second', 'M(FINAL>OTHER)');
        Observer.Expect('stored-second', 'FINAL|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ExprHandler')]
    procedure Expr_InfoHidden_UnsavedRowThenHandlerError()
    begin
        Initialize(false, '');
        RunTwice(Page::"PGA HE Doc Expr", 'NAMEOK', 'NAMEERROR');
        Observer.Expect('first', 'LookupCancel');
        Observer.Expect('log-first', 'M(OPEN>OPEN) IQ(None) LQ(None) HQ(LookupCancel) IC LC HC');
        Observer.Expect('stored-first', 'OPEN|first');
        Observer.Expect('second|text', 'The handler failed.');
        Observer.Expect('second|code', 'Dialog');
        Observer.Expect('log-second', 'M(OPEN>OPEN) IQ(None) LQ(None) HQ(OK) IC LC HC');
        Observer.Expect('stored-second', 'OPEN|first');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ExprHandler')]
    procedure Expr_InfoShown_UnsavedRowThenHandlerError()
    begin
        Initialize(true, '');
        RunTwice(Page::"PGA HE Doc Expr", 'NAMEOK', 'NAMEERROR');
        Observer.Expect('first', 'LookupCancel');
        Observer.Expect('log-first', 'M(OPEN>OPEN) IQ(None) LQ(None) HQ(LookupCancel) IC LC HC');
        Observer.Expect('stored-first', 'OPEN|first');
        Observer.Expect('second|text', 'The handler failed.');
        Observer.Expect('second|code', 'Dialog');
        Observer.Expect('log-second', 'M(OPEN>OPEN) IQ(None) LQ(None) HQ(OK) IC LC HC');
        Observer.Expect('stored-second', 'OPEN|first');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ExprHandler(var P: TestPage "PGA HE Doc Expr")
    begin
        case Log.GetStep() of
            'FINAL', 'OTHER':
                P.Status.SetValue(Log.GetStep());
            'NAMEOK':
                P.Name.SetValue('first');
            'NAMEERROR':
                begin
                    P.Name.SetValue('second');
                    Error('The handler failed.');
                end;
        end;
    end;

    [ModalPageHandler]
    procedure LiteralHandler(var P: TestPage "PGA HE Doc Literal")
    begin
        P.Status.SetValue(Log.GetStep());
    end;
}
