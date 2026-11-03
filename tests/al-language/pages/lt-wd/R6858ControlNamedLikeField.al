// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-controls
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 94940-94943
// Probe (al-runner issue 6858): a page whose control is named exactly like a field of the source table, beside another control on the same field.
//   What does a bare name in field(<Control>; <Source>) bind to when a control of that name exists: the source field or the control? Names with a
//   space ("Container location"), with a dot ("Doc no."), a one-word name (Status) and a control that has the field's name but another source
//   ("Other value" shows "No."). Read through a TestPage (both controls), written by SetValue through each control, in Visible and Editable
//   expressions, in the control's OnValidate trigger, in OnAfterGetRecord, through CurrPage.<control> and in a page extension.
// BC versions: 27, 28, 29

table 94940 "LT R6858 Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Container location"; Code[10]) { }
        field(3; Status; Code[10]) { }
        field(4; "Other value"; Text[30]) { }
        field(5; "Doc no."; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

#pragma warning disable AL0604
page 94941 "LT R6858 Card"
{
    PageType = Card;
    SourceTable = "LT R6858 Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { }
            field(ctlContainerlocation; "Container location")
            {
                Visible = ctlContainerlocationVisible;
            }
            field("Container location"; "Container location")
            {
                trigger OnValidate()
                begin
                    ValidateSeen := 'named:' + "Container location" + ':' + Status;
                end;
            }
            field(ctlStatus; Status)
            {
                trigger OnValidate()
                begin
                    ValidateSeen := 'ctlStatus:' + Status;
                end;
            }
            field(Status; Status) { }
            field(ctlOther; "Other value") { }
            field("Other value"; Rec."No.") { }
            field(Docno; "Doc no.") { }
            field("Doc no."; "Doc no.") { }
            field(ctlGuarded; Status)
            {
                Editable = "Container location" = 'DOCK';
                Visible = Status <> 'HIDE';
            }
            field(ctlSeen; TriggerSeen) { }
            field(ctlValidateSeen; ValidateSeen) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplyCurrPage)
            {
                trigger OnAction()
                begin
                    CurrPage."Container location".Editable(false);
                    CurrPage.ctlContainerlocation.Visible(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ctlContainerlocationVisible := true;
    end;

    trigger OnAfterGetRecord()
    begin
        TriggerSeen := "Container location" + '/' + Status + '/' + "Doc no.";
    end;

    var
        ctlContainerlocationVisible: Boolean;
        TriggerSeen: Text[50];
        ValidateSeen: Text[50];
}

pageextension 94942 "LT R6858 Card Ext" extends "LT R6858 Card"
{
    layout
    {
        addlast(Content)
        {
            field(ExtSource; "Container location") { }
            field(ctlExtStatus; Status) { }
        }
    }
}
#pragma warning restore AL0604

codeunit 94943 "LT R6858 Control Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Rec: Record "LT R6858 Rec";
    begin
        Rec.DeleteAll();
        Rec."No." := 'R1';
        Rec."Container location" := 'DOCK';
        Rec.Status := 'OPEN';
        Rec."Other value" := 'OTHERVAL';
        Rec."Doc no." := 'DOC1';
        Rec.Insert();
    end;

    [Test]
    procedure R6858_Card_ReadsEveryControl()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlContainerlocation', Card.ctlContainerlocation.Value());
        Observer.Observe('Container location', Card."Container location".Value());
        Observer.Observe('ctlStatus', Card.ctlStatus.Value());
        Observer.Observe('Status', Card.Status.Value());
        Observer.Observe('ctlOther', Card.ctlOther.Value());
        Observer.Observe('Other value', Card."Other value".Value());
        Observer.Observe('Docno', Card.Docno.Value());
        Observer.Observe('Doc no.', Card."Doc no.".Value());
        Observer.Observe('ctlGuarded', Card.ctlGuarded.Value());
        Observer.Observe('ctlSeen', Card.ctlSeen.Value());
        Observer.Observe('ExtSource', Card.ExtSource.Value());
        Observer.Observe('ctlExtStatus', Card.ctlExtStatus.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Card_PropertiesOfEveryControl()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenEdit();
        Observer.Observe('ctlContainerlocation visible', Format(Card.ctlContainerlocation.Visible()));
        Observer.Observe('Container location visible', Format(Card."Container location".Visible()));
        Observer.Observe('Container location editable', Format(Card."Container location".Editable()));
        Observer.Observe('ctlGuarded editable', Format(Card.ctlGuarded.Editable()));
        Observer.Observe('ctlGuarded visible', Format(Card.ctlGuarded.Visible()));
        Card."Container location".SetValue('YARD');
        Observer.Observe('ctlGuarded editable after YARD', Format(Card.ctlGuarded.Editable()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Card_SetValueThroughEachControl()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT R6858 Rec";
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenEdit();
        Card."Container location".SetValue('BYNAME');
        Observer.Observe('named: other control', Card.ctlContainerlocation.Value());
        Observer.Observe('named: validate', Card.ctlValidateSeen.Value());
        Card.ctlContainerlocation.SetValue('BYCTL');
        Observer.Observe('ctl: other control', Card."Container location".Value());
        Observer.Observe('ctl: validate', Card.ctlValidateSeen.Value());
        Card.ctlStatus.SetValue('CLOSED');
        Observer.Observe('ctlStatus: Status control', Card.Status.Value());
        Observer.Observe('ctlStatus: validate', Card.ctlValidateSeen.Value());
        Card.Status.SetValue('BACK');
        Observer.Observe('Status: ctlStatus', Card.ctlStatus.Value());
        Card.ctlOther.SetValue('CHANGED');
        Observer.Observe('ctlOther: Other value control', Card."Other value".Value());
        Card.Docno.SetValue('DOC2');
        Observer.Observe('Docno: Doc no. control', Card."Doc no.".Value());
        Card.Close();
        Rec.Get('R1');
        Observer.Observe('stored container', Rec."Container location");
        Observer.Observe('stored status', Rec.Status);
        Observer.Observe('stored other value', Rec."Other value");
        Observer.Observe('stored doc no', Rec."Doc no.");
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Card_CurrPageByControlName()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenEdit();
        Card.ApplyCurrPage.Invoke();
        Observer.Observe('Container location editable', Format(Card."Container location".Editable()));
        Observer.Observe('Container location visible', Format(Card."Container location".Visible()));
        Observer.Observe('ctlContainerlocation visible', Format(Card.ctlContainerlocation.Visible()));
        Observer.Observe('ctlContainerlocation editable', Format(Card.ctlContainerlocation.Editable()));
        Card.Close();
        Observer.Finish();
    end;
}
