// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 69030, codeunit 69031 (log), pages 69032..69036, codeunit 69037
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the CloseAction OnQueryClosePage gets:
//  - TestPage.Close() of a Card, a List, a Document, a Worksheet and a ListPlus page: OK for every page type (not only the card);
//  - a list run with LookupMode(true) and RunModal, closed by the handler with OK().Invoke(): LookupOK; with
//    Cancel().Invoke(): LookupCancel.
// BC versions: 27.5

table 69030 "Probe CloseAct Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69031 "Probe CloseAct Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 69032 "Probe CloseAct List"
{
    PageType = List;
    SourceTable = "Probe CloseAct Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CaLog: Codeunit "Probe CloseAct Log";
    begin
        CaLog.Add('List ' + Format(CloseAction));
        exit(true);
    end;
}

page 69033 "Probe CloseAct Document"
{
    PageType = Document;
    SourceTable = "Probe CloseAct Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CaLog: Codeunit "Probe CloseAct Log";
    begin
        CaLog.Add('Document ' + Format(CloseAction));
        exit(true);
    end;
}

page 69034 "Probe CloseAct Worksheet"
{
    PageType = Worksheet;
    SourceTable = "Probe CloseAct Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CaLog: Codeunit "Probe CloseAct Log";
    begin
        CaLog.Add('Worksheet ' + Format(CloseAction));
        exit(true);
    end;
}

page 69035 "Probe CloseAct ListPlus"
{
    PageType = ListPlus;
    SourceTable = "Probe CloseAct Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CaLog: Codeunit "Probe CloseAct Log";
    begin
        CaLog.Add('ListPlus ' + Format(CloseAction));
        exit(true);
    end;
}

page 69036 "Probe CloseAct Card"
{
    PageType = Card;
    SourceTable = "Probe CloseAct Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CaLog: Codeunit "Probe CloseAct Log";
    begin
        CaLog.Add('Card ' + Format(CloseAction));
        exit(true);
    end;
}

codeunit 69037 "Probe Close Action Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CaLog: Codeunit "Probe CloseAct Log";

    local procedure Seed()
    var
        CaRec: Record "Probe CloseAct Table";
    begin
        CaRec.DeleteAll();
        CaRec.Id := 1;
        CaRec.Insert();
        Commit();
        CaLog.Take();
    end;

    [ModalPageHandler]
    procedure OkHandler(var CaPage: TestPage "Probe CloseAct List")
    begin
        CaPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelHandler(var CaPage: TestPage "Probe CloseAct List")
    begin
        CaPage.Cancel().Invoke();
    end;

    [Test]
    procedure TestPageClose_IsOk_ForEveryPageType()
    var
        ListPage: TestPage "Probe CloseAct List";
        DocPage: TestPage "Probe CloseAct Document";
        SheetPage: TestPage "Probe CloseAct Worksheet";
        PlusPage: TestPage "Probe CloseAct ListPlus";
        CardPage: TestPage "Probe CloseAct Card";
    begin
        Seed();

        ListPage.OpenView();
        ListPage.Close();
        DocPage.OpenView();
        DocPage.Close();
        SheetPage.OpenView();
        SheetPage.Close();
        PlusPage.OpenView();
        PlusPage.Close();
        CardPage.OpenView();
        CardPage.Close();

        Assert.AreEqual('List OK;Document OK;Worksheet OK;ListPlus OK;Card OK;', CaLog.Take(), 'log');
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure LookupRunModal_ClosedWithOk_IsLookupOk()
    var
        ListPage: Page "Probe CloseAct List";
        Result: Action;
    begin
        Seed();
        ListPage.LookupMode(true);

        Result := ListPage.RunModal();

        Assert.AreEqual(Action::LookupOK, Result, 'result');
        Assert.AreEqual('List LookupOK;', CaLog.Take(), 'log');
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure LookupRunModal_ClosedWithCancel_IsLookupCancel()
    var
        ListPage: Page "Probe CloseAct List";
        Result: Action;
    begin
        Seed();
        ListPage.LookupMode(true);

        Result := ListPage.RunModal();

        Assert.AreEqual(Action::LookupCancel, Result, 'result');
        Assert.AreEqual('List LookupCancel;', CaLog.Take(), 'log');
    end;
}
