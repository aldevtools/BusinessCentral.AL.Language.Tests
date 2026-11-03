// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-controls
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 94940-94943
// Probe (al-runner issue 6858): a page whose control is named exactly like a field of the source table, beside another control on the same field.
//   What does a bare name in field(<Control>; <Source>) bind to when a control of that name exists: the source field or the control? Names with a
//   space ("Container location"), with a dot ("Doc no."), a one-word name (Status) and a control that has the field's name but another source
//   ("Other value" shows "No."). Read through a TestPage (both controls), written by SetValue through each control, in Visible and Editable
//   expressions, in the control's OnValidate trigger, in OnAfterGetRecord and in a page extension. CurrPage.<field control> does not compile (AL0118 on 27.5), so it is not probed.
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
        field(6; "Plain field"; Code[10]) { }
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
          group(General)
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
        addlast(General)
        {
            field(ExtSource; "Container location") { }
            field(ctlExtStatus; Status) { }
            field(ExtBarePlain; "Plain field") { }
            field(ExtRecPlain; Rec."Plain field") { }
            field(ExtRecContainer; Rec."Container location") { }
        }
    }
}
#pragma warning restore AL0604

codeunit 94943 "LT R6858 Control Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

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
        Rec."Plain field" := 'PLAIN';
        Rec.Insert();
    end;

    [Test]
    procedure R6858_Read_ctlContainerlocation()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlContainerlocation', Card.ctlContainerlocation.Value());
        Card.Close();
        Observer.Expect('ctlContainerlocation', 'DOCK');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_ContainerLocation()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ContainerLocation', Card."Container location".Value());
        Card.Close();
        Observer.Expect('ContainerLocation', 'DOCK');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_ctlStatus()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlStatus', Card.ctlStatus.Value());
        Card.Close();
        Observer.Expect('ctlStatus', 'OPEN');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_NamedStatus()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('Status', Card.Status.Value());
        Card.Close();
        Observer.Expect('Status', 'OPEN');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_ctlOther()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlOther', Card.ctlOther.Value());
        Card.Close();
        Observer.Expect('ctlOther', 'OTHERVAL');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_OtherValue()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('OtherValue', Card."Other value".Value());
        Card.Close();
        Observer.Expect('OtherValue', 'R1');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_Docno()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('Docno', Card.Docno.Value());
        Card.Close();
        Observer.Expect('Docno', 'DOC1');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_NamedDocNo()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('DocNo', Card."Doc no.".Value());
        Card.Close();
        Observer.Expect('DocNo', 'DOC1');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_ctlGuarded()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlGuarded', Card.ctlGuarded.Value());
        Card.Close();
        Observer.Expect('ctlGuarded', 'OPEN');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_ctlSeen()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlSeen', Card.ctlSeen.Value());
        Card.Close();
        Observer.Expect('ctlSeen', 'DOCK/OPEN/DOC1');
        Observer.Verify();
    end;

    [Test]
    procedure R6858_Read_ExtSource()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ExtSource', Card.ExtSource.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Read_ctlExtStatus()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ctlExtStatus', Card.ctlExtStatus.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Read_ExtBarePlain()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ExtBarePlain', Card.ExtBarePlain.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Read_ExtRecPlain()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ExtRecPlain', Card.ExtRecPlain.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure R6858_Read_ExtRecContainer()
    var
        Card: TestPage "LT R6858 Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('ExtRecContainer', Card.ExtRecContainer.Value());
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
        Observer.Expect('ctlContainerlocation visible', 'Yes');
        Observer.Expect('Container location visible', 'Yes');
        Observer.Expect('Container location editable', 'Yes');
        Observer.Expect('ctlGuarded editable', 'Yes');
        Observer.Expect('ctlGuarded visible', 'Yes');
        Observer.Expect('ctlGuarded editable after YARD', 'No');
        Observer.Verify();
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
        Observer.Expect('named: other control', 'BYNAME');
        Observer.Expect('named: validate', 'named:BYNAME:OPEN');
        Observer.Expect('ctl: other control', 'BYCTL');
        Observer.Expect('ctl: validate', 'named:BYNAME:OPEN');
        Observer.Expect('ctlStatus: Status control', 'CLOSED');
        Observer.Expect('ctlStatus: validate', 'ctlStatus:CLOSED');
        Observer.Expect('Status: ctlStatus', 'BACK');
        Observer.Expect('ctlOther: Other value control', 'R1');
        Observer.Expect('Docno: Doc no. control', 'DOC2');
        Observer.Expect('stored container', 'BYCTL');
        Observer.Expect('stored status', 'BACK');
        Observer.Expect('stored other value', 'CHANGED');
        Observer.Expect('stored doc no', 'DOC2');
        Observer.Verify();
    end;
}
