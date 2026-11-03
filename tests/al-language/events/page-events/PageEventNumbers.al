// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope. Event Subscription virtual table, rows of subscribers to OnAfterActionEvent (page action) and OnAfterValidateEvent (page field).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained objects 67375-67355
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the full "Published Function" text of the Event Subscription row of five action subscribers and five field subscribers on each of two pages
//   (a field whose control name differs from the table field name included). The number after "OnAfterActionEvent - " and "OnAfterValidateEvent - " is the point of this file.
//   Corpus issue 576 item 1.
// BC versions: 27, 28, 29

table 67375 "LT PEN Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Code; Code[10]) { }
        field(5; Description; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 67376 "LT PEN Card"
{
    PageType = Card;
    SourceTable = "LT PEN Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(DescCtl; Rec.Description) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActOne) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActTwo) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActThree) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActFour) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActFive) { ApplicationArea = All; trigger OnAction() begin end; }
        }
    }
}

page 67377 "LT PEN List"
{
    PageType = List;
    SourceTable = "LT PEN Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(IdB; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(AmountB; Rec.Amount) { ApplicationArea = All; }
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DoIt) { ApplicationArea = All; trigger OnAction() begin end; }
            action(Process) { ApplicationArea = All; trigger OnAction() begin end; }
            action(Release) { ApplicationArea = All; trigger OnAction() begin end; }
            action(Reopen) { ApplicationArea = All; trigger OnAction() begin end; }
            action(Post) { ApplicationArea = All; trigger OnAction() begin end; }
        }
    }
}

codeunit 67353 "LT PEN Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterActionEvent', 'ActOne', false, false)]
    local procedure AActActOne()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterActionEvent', 'ActTwo', false, false)]
    local procedure AActActTwo()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterActionEvent', 'ActThree', false, false)]
    local procedure AActActThree()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterActionEvent', 'ActFour', false, false)]
    local procedure AActActFour()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterActionEvent', 'ActFive', false, false)]
    local procedure AActActFive()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterValidateEvent', 'Id', false, false)]
    local procedure AFldId()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterValidateEvent', 'NameCtl', false, false)]
    local procedure AFldNameCtl()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterValidateEvent', 'Amount', false, false)]
    local procedure AFldAmount()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterValidateEvent', 'Code', false, false)]
    local procedure AFldCode()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN Card", 'OnAfterValidateEvent', 'DescCtl', false, false)]
    local procedure AFldDescCtl()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterActionEvent', 'DoIt', false, false)]
    local procedure BActDoIt()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterActionEvent', 'Process', false, false)]
    local procedure BActProcess()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterActionEvent', 'Release', false, false)]
    local procedure BActRelease()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterActionEvent', 'Reopen', false, false)]
    local procedure BActReopen()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterActionEvent', 'Post', false, false)]
    local procedure BActPost()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterValidateEvent', 'IdB', false, false)]
    local procedure BFldIdB()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure BFldName()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterValidateEvent', 'AmountB', false, false)]
    local procedure BFldAmountB()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterValidateEvent', 'CodeCtl', false, false)]
    local procedure BFldCodeCtl()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PEN List", 'OnAfterValidateEvent', 'Description', false, false)]
    local procedure BFldDescription()
    begin
    end;
}

codeunit 67354 "LT PEN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveRows(Prefix: Text; Kind: Text; var Observer: Codeunit "Probe Observer")
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT PEN Subscribers");
        Sub.SetFilter("Subscriber Function", Prefix + Kind + '*');
        Observer.Observe('count', Format(Sub.Count()));
        if Sub.FindSet() then
            repeat
                Observer.Observe(Sub."Subscriber Function", Sub."Published Function");
            until Sub.Next() = 0;
    end;

    [Test]
    procedure PublishedFunction_ActionEvents_CardPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRows('A', 'Act', Observer);
        Observer.Expect('count', '5');
        Observer.Expect('AActActFive', 'OnAfterActionEvent - 1762977804');
        Observer.Expect('AActActFour', 'OnAfterActionEvent - 1637616802');
        Observer.Expect('AActActOne', 'OnAfterActionEvent - 1230864492');
        Observer.Expect('AActActThree', 'OnAfterActionEvent - 964416274');
        Observer.Expect('AActActTwo', 'OnAfterActionEvent - 325473572');
        Observer.Verify();
    end;

    [Test]
    procedure PublishedFunction_ActionEvents_ListPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRows('B', 'Act', Observer);
        Observer.Expect('count', '5');
        Observer.Expect('BActDoIt', 'OnAfterActionEvent - 1237138033');
        Observer.Expect('BActPost', 'OnAfterActionEvent - 729958143');
        Observer.Expect('BActProcess', 'OnAfterActionEvent - 2052478748');
        Observer.Expect('BActRelease', 'OnAfterActionEvent - 709761342');
        Observer.Expect('BActReopen', 'OnAfterActionEvent - 1985144420');
        Observer.Verify();
    end;

    [Test]
    procedure PublishedFunction_FieldValidateEvents_CardPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRows('A', 'Fld', Observer);
        Observer.Expect('count', '5');
        Observer.Expect('AFldAmount', 'OnAfterValidateEvent - 195763894');
        Observer.Expect('AFldCode', 'OnAfterValidateEvent - 1621358379');
        Observer.Expect('AFldDescCtl', 'OnAfterValidateEvent - 1251029156');
        Observer.Expect('AFldId', 'OnAfterValidateEvent - 1598304267');
        Observer.Expect('AFldNameCtl', 'OnAfterValidateEvent - 785226970');
        Observer.Verify();
    end;

    [Test]
    procedure PublishedFunction_FieldValidateEvents_ListPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRows('B', 'Fld', Observer);
        Observer.Expect('count', '5');
        Observer.Expect('BFldAmountB', 'OnAfterValidateEvent - 1752492791');
        Observer.Expect('BFldCodeCtl', 'OnAfterValidateEvent - 919346209');
        Observer.Expect('BFldDescription', 'OnAfterValidateEvent - 593484303');
        Observer.Expect('BFldIdB', 'OnAfterValidateEvent - 2072102672');
        Observer.Expect('BFldName', 'OnAfterValidateEvent - 738282952');
        Observer.Verify();
    end;
}
