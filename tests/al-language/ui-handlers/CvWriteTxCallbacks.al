// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85369
// Facts: corpus issue 670 (odd AL behavior leads, part E): in a test, a Confirm, a StrMenu and a Page.RunModal raised after a database write and
//   before any Commit, each answered by its handler: no error is raised, the write is still there afterwards, and the handler's page sees it.
//   What the web client does with a client callback inside a write transaction cannot be run in a headless test.
// Leads: microsoft/AL issues 4930, 5028.
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
table 85369 "LT CV Tx Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 85369 "LT CV Tx Card"
{
    PageType = Card;
    SourceTable = "LT CV Tx Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

codeunit 85369 "LT CV Write Tx Callback Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SeenInHandler: Text;

    [Test]
    [HandlerFunctions('YesConfirm,SecondStrMenu,ReadCardModal')]
    procedure CallbacksAfterWriteBeforeCommit()
    var
        Row: Record "LT CV Tx Row";
        Observer: Codeunit "Probe Observer";
        Answer: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'written';
        Row.Insert();
        Observer.Observe('confirm', Format(Confirm('Continue?')));
        Answer := StrMenu('One,Two,Three');
        Observer.Observe('strmenu', Format(Answer));
        Row.Get(1);
        Observer.Observe('runmodal', Format(Page.RunModal(Page::"LT CV Tx Card", Row)));
        Observer.Observe('handler_saw', SeenInHandler);
        Row.Name := 'modified';
        Row.Modify();
        Observer.Observe('after|count', Format(Row.Count()));
        Row.Get(1);
        Observer.Observe('after|name', Row.Name);
        Observer.Expect('confirm', 'Yes');
        Observer.Expect('strmenu', '2');
        Observer.Expect('runmodal', 'LookupOK');
        Observer.Expect('handler_saw', 'written');
        Observer.Expect('after|count', '1');
        Observer.Expect('after|name', 'modified');
        Observer.Verify();
    end;

    [ConfirmHandler]
    procedure YesConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    procedure SecondStrMenu(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;

    [ModalPageHandler]
    procedure ReadCardModal(var Card: TestPage "LT CV Tx Card")
    begin
        SeenInHandler := Card.Name.Value();
        Card.OK().Invoke();
    end;
}
