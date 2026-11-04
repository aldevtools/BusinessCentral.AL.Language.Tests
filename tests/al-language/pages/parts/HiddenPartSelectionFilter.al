// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 67556, pages 67557-67559 and 67570, log codeunit 67571, test codeunit 67572
// Probe: CurrPage.SetSelectionFilter called by a procedure of a ListPart whose part control is hidden (Visible = false literal, Visible = a Boolean variable that is false, and, for comparison, a visible part). The filter text, the view and the count of the record that receives the selection, for a separate record variable and for Rec of the part (issue 581 item 1).
// BC versions: 27+

table 67556 "LT HPSF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; Name; Text[20]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67571 "LT HPSF Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 67557 "LT HPSF Part"
{
    PageType = ListPart;
    SourceTable = "LT HPSF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    procedure RunSelectionFilter()
    var
        Log: Codeunit "LT HPSF Log";
        Sel: Record "LT HPSF Row";
    begin
        Log.Add('proc-start');
        CurrPage.SetSelectionFilter(Sel);
        Log.Add('sel-count=' + Format(Sel.Count()));
        Log.Add('sel-filters=' + Sel.GetFilters());
        Log.Add('sel-view=' + Sel.GetView());
        Log.Add('sel-ids=' + Ids(Sel));
        Log.Add('rec-before=' + Rec.GetFilters() + '/' + Format(Rec.Count()));
        CurrPage.SetSelectionFilter(Rec);
        Log.Add('rec-count=' + Format(Rec.Count()));
        Log.Add('rec-filters=' + Rec.GetFilters());
        Log.Add('rec-view=' + Rec.GetView());
        Log.Add('proc-end');
    end;

    local procedure Ids(var Source: Record "LT HPSF Row"): Text
    var
        Result: Text;
    begin
        if Source.FindSet() then
            repeat
                Result += Format(Source.Id) + ',';
            until Source.Next() = 0;
        exit('(' + Result + ')');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT HPSF Log";
    begin
        Log.Add('part-OnOpenPage');
    end;
}

page 67558 "LT HPSF Host Literal"
{
    PageType = Card;
    SourceTable = "LT HPSF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT HPSF Part")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HPSF Log";
    begin
        Log.Add('host-start:' + Format(Rec.Id));
        CurrPage.PartCtl.Page.RunSelectionFilter();
        Log.Add('host-end');
    end;
}

page 67559 "LT HPSF Host Expr"
{
    PageType = Card;
    SourceTable = "LT HPSF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT HPSF Part")
            {
                ApplicationArea = All;
                Visible = ShowPart;
            }
        }
    }

    var
        ShowPart: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HPSF Log";
    begin
        Log.Add('host-start:' + Format(Rec.Id));
        CurrPage.PartCtl.Page.RunSelectionFilter();
        Log.Add('host-end');
    end;
}

page 67570 "LT HPSF Host Visible"
{
    PageType = Card;
    SourceTable = "LT HPSF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT HPSF Part")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HPSF Log";
    begin
        Log.Add('host-start:' + Format(Rec.Id));
        CurrPage.PartCtl.Page.RunSelectionFilter();
        Log.Add('host-end');
    end;
}

codeunit 67572 "LT HPSF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT HPSF Row";
        Log: Codeunit "LT HPSF Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Insert();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenLiteral(var Host: TestPage "LT HPSF Host Literal")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenExpr(var Host: TestPage "LT HPSF Host Expr")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenVisible(var Host: TestPage "LT HPSF Host Visible")
    begin
        Host.OpenEdit();
    end;

    [Test]
    procedure SelectionFilter_HiddenLiteral_FilterAndCount()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT HPSF Log";
        Host: TestPage "LT HPSF Host Literal";
        Opened: Boolean;
    begin
        Seed();
        Opened := TryOpenLiteral(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log after next', Log.Dump());
            Host.Close();
        end;
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('log', '[host-start:1 | proc-start | sel-count=0 | sel-filters=Id: 0 | sel-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | sel-ids=() | rec-before=/3 | rec-count=0 | rec-filters=Id: 0 | rec-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | proc-end | host-end]');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log after next', '[host-start:2 | proc-start | sel-count=0 | sel-filters=Id: 0 | sel-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | sel-ids=() | rec-before=Id: 0/0 | rec-count=0 | rec-filters=Id: 0 | rec-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | proc-end | host-end]');
        Observer.Verify();
    end;

    [Test]
    procedure SelectionFilter_HiddenByVariable_FilterAndCount()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT HPSF Log";
        Host: TestPage "LT HPSF Host Expr";
        Opened: Boolean;
    begin
        Seed();
        Opened := TryOpenExpr(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log after next', Log.Dump());
            Host.Close();
        end;
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('log', '[part-OnOpenPage | host-start:1 | proc-start | sel-count=0 | sel-filters=Id: 0 | sel-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | sel-ids=() | rec-before=/3 | rec-count=0 | rec-filters=Id: 0 | rec-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | proc-end | host-end]');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log after next', '[host-start:2 | proc-start | sel-count=1 | sel-filters=Id: 1 | sel-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(1)) | sel-ids=(1,) | rec-before=/3 | rec-count=1 | rec-filters=Id: 1 | rec-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(1)) | proc-end | host-end]');
        Observer.Verify();
    end;

    [Test]
    procedure SelectionFilter_VisiblePart_FilterAndCount()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT HPSF Log";
        Host: TestPage "LT HPSF Host Visible";
        Opened: Boolean;
    begin
        Seed();
        Opened := TryOpenVisible(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log after next', Log.Dump());
            Host.Close();
        end;
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('log', '[part-OnOpenPage | host-start:1 | proc-start | sel-count=0 | sel-filters=Id: 0 | sel-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | sel-ids=() | rec-before=/3 | rec-count=0 | rec-filters=Id: 0 | rec-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(0)) | proc-end | host-end]');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log after next', '[host-start:2 | proc-start | sel-count=1 | sel-filters=Id: 1 | sel-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(1)) | sel-ids=(1,) | rec-before=/3 | rec-count=1 | rec-filters=Id: 1 | rec-view=VERSION(1) SORTING(Id) WHERE(Id=FILTER(1)) | proc-end | host-end]');
        Observer.Verify();
    end;
}
