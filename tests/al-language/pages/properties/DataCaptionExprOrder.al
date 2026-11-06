// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 96260, log 96261, page 96260, tests 96262
// Facts: al-runner issue 6924 (waldo): a page whose DataCaptionExpression calls a local procedure that assigns page globals from Rec.GetFilter,
//   shown by field controls that OnOpenPage never assigns. When the expression runs relative to OnInit, OnOpenPage, OnFindRecord,
//   OnAfterGetRecord, OnAfterGetCurrRecord and the handler, how often it runs (open, Next, CurrPage.Update, close), with rows and with an
//   empty table, through Page.RunModal (from a table procedure), Page.Run and TestPage.OpenView / OpenEdit, and what TestPage.Caption returns.

table 96260 "LT DCE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Item No.") { Clustered = true; }
    }

    procedure OpenModal()
    begin
        Page.RunModal(Page::"LT DCE Page", Rec);
    end;
}

codeunit 96261 "LT DCE Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Wipe()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit(Result);
    end;
}

page 96260 "LT DCE Page"
{
    PageType = Card;
    SourceTable = "LT DCE Row";
    Caption = 'LT DCE';
    DataCaptionExpression = GetCaption();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ItemNoFilterCtl; ItemNoFilter) { ApplicationArea = All; }
            field(ItemNoCtl; Rec."Item No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT DCE Log";
        ItemNoFilter: Text;

    local procedure GetCaption(): Text
    begin
        ItemNoFilter := Rec.GetFilter("Item No.");
        Log.Add('DC(filter=' + ItemNoFilter + ' rec=' + Rec."Item No." + ')');
        exit('Cap ' + ItemNoFilter);
    end;

    trigger OnInit()
    begin
        Log.Add('OnInit(ctl=' + ItemNoFilter + ')');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage(ctl=' + ItemNoFilter + ')');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('OnFindRecord(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        Log.Add('OnNextRecord(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord(' + Rec."Item No." + ' ctl=' + ItemNoFilter + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord(' + Rec."Item No." + ' ctl=' + ItemNoFilter + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('OnQueryClosePage');
        exit(true);
    end;
}

codeunit 96262 "LT DCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DCE Log";

    local procedure Seed(WithRows: Boolean)
    var
        Row: Record "LT DCE Row";
    begin
        Row.DeleteAll();
        if not WithRows then
            exit;
        Row."Item No." := 'I1';
        Row.Name := 'Alpha';
        Row.Insert();
        Row."Item No." := 'I2';
        Row.Name := 'Beta';
        Row.Insert();
        Row."Item No." := 'I3';
        Row.Name := 'Gamma';
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('ModalHandler')]
    procedure DCE_RunModal_TableProcedure_Rows()
    var
        Row: Record "LT DCE Row";
    begin
        Seed(true);
        Log.Wipe();
        Row.SetFilter("Item No.", 'I1|I2');
        Row.OpenModal();
        Log.Add('after run');
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log',
            'OnInit(ctl=)' +
            ' | OnOpenPage(ctl=)' +
            ' | OnFindRecord(=)' +
            ' | OnFindRecord(=><)' +
            ' | OnAfterGetRecord(I1 ctl=)' +
            ' | DC(filter=I1|I2 rec=I1)' +
            ' | OnAfterGetCurrRecord(I1 ctl=)' +
            ' | DC(filter=I1|I2 rec=I1)' +
            ' | H open cap=LT DCE - Cap I1|I2 ctl=' +
            ' | OnNextRecord(1)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | OnAfterGetCurrRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | H next cap=LT DCE - Cap I1|I2 ctl=I1|I2 item=I2' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | OnAfterGetRecord( ctl=I1|I2)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | OnFindRecord(=)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | OnAfterGetCurrRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | H update cap=LT DCE - Cap I1|I2 ctl=I1|I2' +
            ' | OnQueryClosePage' +
            ' | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalEmptyHandler')]
    procedure DCE_RunModal_TableProcedure_Empty()
    var
        Row: Record "LT DCE Row";
    begin
        Seed(false);
        Log.Wipe();
        Row.SetFilter("Item No.", 'I9');
        Row.OpenModal();
        Log.Add('after run');
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log',
            'OnInit(ctl=)' +
            ' | OnOpenPage(ctl=)' +
            ' | OnFindRecord(=)' +
            ' | OnFindRecord(=><)' +
            ' | DC(filter=I9 rec=I9)' +
            ' | OnAfterGetCurrRecord(I9 ctl=)' +
            ' | DC(filter=I9 rec=I9)' +
            ' | H open cap=LT DCE ctl=' +
            ' | OnAfterGetRecord( ctl=I9)' +
            ' | OnQueryClosePage' +
            ' | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalHandler')]
    procedure DCE_RunModal_NoFilter_Rows()
    var
        Row: Record "LT DCE Row";
    begin
        Seed(true);
        Log.Wipe();
        Row.OpenModal();
        Log.Add('after run');
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log',
            'OnInit(ctl=)' +
            ' | OnOpenPage(ctl=)' +
            ' | OnFindRecord(=)' +
            ' | OnFindRecord(=><)' +
            ' | OnAfterGetRecord(I1 ctl=)' +
            ' | DC(filter= rec=I1)' +
            ' | OnAfterGetCurrRecord(I1 ctl=)' +
            ' | DC(filter= rec=I1)' +
            ' | H open cap=LT DCE - Cap ctl=' +
            ' | OnNextRecord(1)' +
            ' | OnAfterGetRecord(I2 ctl=)' +
            ' | DC(filter= rec=I2)' +
            ' | OnAfterGetCurrRecord(I2 ctl=)' +
            ' | DC(filter= rec=I2)' +
            ' | H next cap=LT DCE - Cap ctl= item=I2' +
            ' | OnAfterGetRecord(I2 ctl=)' +
            ' | OnAfterGetRecord(I2 ctl=)' +
            ' | DC(filter= rec=I2)' +
            ' | OnAfterGetRecord( ctl=)' +
            ' | OnAfterGetRecord(I2 ctl=)' +
            ' | OnFindRecord(=)' +
            ' | OnAfterGetRecord(I2 ctl=)' +
            ' | DC(filter= rec=I2)' +
            ' | OnAfterGetCurrRecord(I2 ctl=)' +
            ' | DC(filter= rec=I2)' +
            ' | H update cap=LT DCE - Cap ctl=' +
            ' | OnQueryClosePage' +
            ' | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageRunHandler')]
    procedure DCE_PageRun_Rows()
    var
        Row: Record "LT DCE Row";
    begin
        Seed(true);
        Log.Wipe();
        Row.SetFilter("Item No.", 'I1|I2');
        Page.Run(Page::"LT DCE Page", Row);
        Log.Add('after run');
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log',
            'OnInit(ctl=)' +
            ' | OnOpenPage(ctl=)' +
            ' | OnFindRecord(=><)' +
            ' | OnAfterGetRecord(I1 ctl=)' +
            ' | DC(filter=I1|I2 rec=I1)' +
            ' | OnAfterGetCurrRecord(I1 ctl=)' +
            ' | DC(filter=I1|I2 rec=I1)' +
            ' | H open cap=LT DCE - Cap I1|I2 ctl=' +
            ' | OnNextRecord(1)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | OnAfterGetCurrRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | H next cap=LT DCE - Cap I1|I2 ctl=I1|I2 item=I2' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | OnFindRecord(=)' +
            ' | OnAfterGetRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | OnAfterGetCurrRecord(I2 ctl=I1|I2)' +
            ' | DC(filter=I1|I2 rec=I2)' +
            ' | H update cap=LT DCE - Cap I1|I2 ctl=I1|I2' +
            ' | OnQueryClosePage' +
            ' | after run');
        Observer.Verify();
    end;

    [Test]
    procedure DCE_TestPage_OpenView_Rows()
    var
        Card: TestPage "LT DCE Page";
    begin
        Seed(true);
        Log.Wipe();
        Card.OpenView();
        Log.Add('H open cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        Card.Filter.SetFilter("Item No.", 'I1|I2');
        Log.Add('H filtered cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        if Card.Next() then
            Log.Add('H next cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value + ' item=' + Card.ItemNoCtl.Value);
        Card.UpdateAct.Invoke();
        Log.Add('H update cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        Card.Close();
        Log.Add('after close');
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure DCE_TestPage_OpenEdit_Rows()
    var
        Card: TestPage "LT DCE Page";
    begin
        Seed(true);
        Log.Wipe();
        Card.OpenEdit();
        Log.Add('H open cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        Card.Filter.SetFilter("Item No.", 'I1|I2');
        Log.Add('H filtered cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        Card.Close();
        Log.Add('after close');
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    procedure DCE_TestPage_OpenView_Empty()
    var
        Card: TestPage "LT DCE Page";
    begin
        Seed(false);
        Log.Wipe();
        Card.OpenView();
        Log.Add('H open cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        Card.Filter.SetFilter("Item No.", 'I9');
        Log.Add('H filtered cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        Card.Close();
        Log.Add('after close');
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ModalHandler(var Card: TestPage "LT DCE Page")
    begin
        Log.Add('H open cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        if Card.Next() then
            Log.Add('H next cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value + ' item=' + Card.ItemNoCtl.Value);
        Card.UpdateAct.Invoke();
        Log.Add('H update cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
    end;

    [ModalPageHandler]
    procedure ModalEmptyHandler(var Card: TestPage "LT DCE Page")
    begin
        Log.Add('H open cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
    end;

    [PageHandler]
    procedure PageRunHandler(var Card: TestPage "LT DCE Page")
    begin
        Log.Add('H open cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
        if Card.Next() then
            Log.Add('H next cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value + ' item=' + Card.ItemNoCtl.Value);
        Card.UpdateAct.Invoke();
        Log.Add('H update cap=' + Card.Caption() + ' ctl=' + Card.ItemNoFilterCtl.Value);
    end;
}
