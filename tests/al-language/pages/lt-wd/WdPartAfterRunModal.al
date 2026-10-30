// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90780-90783
// Probe: written against al-runner issue 6321. Page code that reads CurrPage.<part>.Page after the page's RunModal returned (a dialog with a lines part, as Posted Purchase Document Lines does):
//        what a part procedure answers when the dialog closed with OK, and when it closed with Cancel. Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29

table 90780 "LT WD Choice"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Value; Text[30]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 90781 "LT WD Choice Part"
{
    PageType = ListPart;
    SourceTable = "LT WD Choice";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Value; Rec.Value) { }
            }
        }
    }

    procedure GetCount(): Integer
    begin
        exit(Rec.Count());
    end;

    procedure GetFirstValue(): Text
    begin
        if Rec.FindFirst() then
            exit(Rec.Value);
        exit('<none>');
    end;
}

page 90782 "LT WD Choice Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            part(ChoicePart; "LT WD Choice Part") { }
        }
    }

    procedure GetChoiceCount(): Integer
    begin
        exit(CurrPage.ChoicePart.Page.GetCount());
    end;

    procedure GetChoiceValue(): Text
    begin
        exit(CurrPage.ChoicePart.Page.GetFirstValue());
    end;
}

codeunit 90783 "LT WD Part After RunModal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('AddOneLineHandler')]
    procedure WD_Part_ReadAfterRunModalOK()
    var
        Observer: Codeunit "Probe Observer";
        Dialog: Page "LT WD Choice Dialog";
    begin
        Observer.Observe('RunModal', Format(Dialog.RunModal()));
        Observer.Observe('count', Format(Dialog.GetChoiceCount()));
        Observer.Observe('value', Dialog.GetChoiceValue());
        Observer.Expect('RunModal', 'OK');
        Observer.Expect('count', '1');
        Observer.Expect('value', 'A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AddOneLineCancelHandler')]
    procedure WD_Part_ReadAfterRunModalCancel()
    var
        Observer: Codeunit "Probe Observer";
        Dialog: Page "LT WD Choice Dialog";
    begin
        Observer.Observe('RunModal', Format(Dialog.RunModal()));
        Observer.Observe('count', Format(Dialog.GetChoiceCount()));
        Observer.Observe('value', Dialog.GetChoiceValue());
        Observer.Expect('RunModal', 'Cancel');
        Observer.Expect('count', '1');
        Observer.Expect('value', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure WD_Part_ReadOfAPageNeverRun()
    var
        Observer: Codeunit "Probe Observer";
        Dialog: Page "LT WD Choice Dialog";
    begin
        Observer.Observe('count', Format(Dialog.GetChoiceCount()));
        Observer.Observe('value', Dialog.GetChoiceValue());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure AddOneLineHandler(var Dialog: TestPage "LT WD Choice Dialog")
    begin
        Dialog.ChoicePart.New();
        Dialog.ChoicePart.Value.SetValue('A');
        Dialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddOneLineCancelHandler(var Dialog: TestPage "LT WD Choice Dialog")
    begin
        Dialog.ChoicePart.New();
        Dialog.ChoicePart.Value.SetValue('B');
        Dialog.Cancel().Invoke();
    end;
}
