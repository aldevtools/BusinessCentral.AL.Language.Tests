// Probe writer-c: page variable Editable open points (docs/probes-needed.md "Page variable Editable").
// Not yet probed there: a View-mode page (page property Editable = false) given Editable(true); CurrPage.Editable read
// before the page opens (OnInit, OnOpenPage). Observe-only.
// Fixtures: table 69710, pages 69711 (editable list), 69712 (Editable = false card), codeunits 69713 (capture), 69714 (tests).

table 69710 "PW PE Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69713 "PW PE Capture"
{
    SingleInstance = true;

    var
        Captured: Text;

    procedure Add(T: Text)
    begin
        Captured += T + ' | ';
    end;

    procedure Get(): Text
    begin
        exit(Captured);
    end;

    procedure Reset()
    begin
        Captured := '';
    end;
}

page 69711 "PW PE Editable Card"
{
    PageType = Card;
    SourceTable = "PW PE Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Cap: Codeunit "PW PE Capture";
    begin
        Cap.Add('OnInit CurrPage.Editable=' + Format(CurrPage.Editable));
    end;

    trigger OnOpenPage()
    var
        Cap: Codeunit "PW PE Capture";
    begin
        Cap.Add('OnOpenPage CurrPage.Editable=' + Format(CurrPage.Editable));
    end;

    trigger OnAfterGetRecord()
    var
        Cap: Codeunit "PW PE Capture";
    begin
        Cap.Add('OnAfterGetRecord CurrPage.Editable=' + Format(CurrPage.Editable));
    end;
}

page 69712 "PW PE View Card"
{
    PageType = Card;
    Editable = false;
    SourceTable = "PW PE Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Cap: Codeunit "PW PE Capture";
    begin
        Cap.Add('OnInit CurrPage.Editable=' + Format(CurrPage.Editable));
    end;

    trigger OnOpenPage()
    var
        Cap: Codeunit "PW PE Capture";
    begin
        Cap.Add('OnOpenPage CurrPage.Editable=' + Format(CurrPage.Editable));
    end;
}

codeunit 69714 "PW Page Editable Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Cap: Codeunit "PW PE Capture";
        SeenEditable: Text;

    local procedure Seed()
    var
        Row: Record "PW PE Table";
    begin
        Row.DeleteAll(false);
        Row.Id := 1;
        Row.Txt := 'one';
        Row.Insert();
        Cap.Reset();
    end;

    [ModalPageHandler]
    procedure CaptureEditable(var Card: TestPage "PW PE Editable Card")
    begin
        SeenEditable := 'page=' + Format(Card.Editable()) + ' field=' + Format(Card.Txt.Editable());
        Card.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CaptureViewEditable(var Card: TestPage "PW PE View Card")
    begin
        SeenEditable := 'page=' + Format(Card.Editable()) + ' field=' + Format(Card.Txt.Editable());
        Card.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CaptureViewEditable')]
    procedure ViewPage_Untouched_EditableOnOpen()
    var
        Row: Record "PW PE Table";
        P: Page "PW PE View Card";
    begin
        Seed();
        Row.FindFirst();
        P.SetRecord(Row);
        P.RunModal();
        Observer.Observe('testpage_editable', SeenEditable);
        Observer.Observe('trigger_values', Cap.Get());
        Observer.Expect('testpage_editable', 'page=No field=No');
        Observer.Expect('trigger_values', 'OnInit CurrPage.Editable=No | OnOpenPage CurrPage.Editable=No | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureViewEditable')]
    procedure ViewPage_EditableTrueBeforeRunModal()
    var
        Row: Record "PW PE Table";
        P: Page "PW PE View Card";
    begin
        Seed();
        Row.FindFirst();
        P.SetRecord(Row);
        Observer.Observe('variable_before_set', Format(P.Editable()));
        P.Editable(true);
        Observer.Observe('variable_after_set_true', Format(P.Editable()));
        P.RunModal();
        Observer.Observe('testpage_editable', SeenEditable);
        Observer.Observe('trigger_values', Cap.Get());
        Observer.Expect('variable_before_set', 'No');
        Observer.Expect('variable_after_set_true', 'Yes');
        Observer.Expect('testpage_editable', 'page=No field=No');
        Observer.Expect('trigger_values', 'OnInit CurrPage.Editable=No | OnOpenPage CurrPage.Editable=No | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureEditable')]
    procedure EditablePage_CurrPageEditableInTriggers()
    var
        Row: Record "PW PE Table";
        P: Page "PW PE Editable Card";
    begin
        Seed();
        Row.FindFirst();
        P.SetRecord(Row);
        P.RunModal();
        Observer.Observe('testpage_editable', SeenEditable);
        Observer.Observe('trigger_values', Cap.Get());
        Observer.Expect('testpage_editable', 'page=Yes field=Yes');
        Observer.Expect('trigger_values', 'OnInit CurrPage.Editable=Yes | OnOpenPage CurrPage.Editable=Yes | OnAfterGetRecord CurrPage.Editable=Yes | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureEditable')]
    procedure EditablePage_EditableFalseBeforeRun_CurrPageEditableInTriggers()
    var
        Row: Record "PW PE Table";
        P: Page "PW PE Editable Card";
    begin
        Seed();
        Row.FindFirst();
        P.SetRecord(Row);
        P.Editable(false);
        P.RunModal();
        Observer.Observe('testpage_editable', SeenEditable);
        Observer.Observe('trigger_values', Cap.Get());
        Observer.Expect('testpage_editable', 'page=No field=No');
        Observer.Expect('trigger_values', 'OnInit CurrPage.Editable=Yes | OnOpenPage CurrPage.Editable=No | OnAfterGetRecord CurrPage.Editable=No | ');
        Observer.Verify();
    end;
}
