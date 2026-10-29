// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-filter-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 90270, codeunit 90271, pages 90272-90273, queries 90274-90275
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Facts: Text and Code field filter values that hold > < & | = .. ( ) or an apostrophe (a>b, >b, a>, <64Y>, Diana's (Meals), A|B, 'A|B', A'&B, A'=B, A'..B, A'<B):
//   GetFilter / GetFilters / GetView after SetRange and after SetFilter(Field, '%1', Value); the rows each selects; the rows selected by
//   SetFilter(Field, GetFilter) and SetView(GetView) on a second record; filter('>B') in SourceTableView and DataItemTableFilter, and
//   SetView with FILTER('>B') on a Code and a Text field.
//   Rows 1-11 hold the eleven values in both fields (the Code field upper-cases them), rows 12-16 hold B, A, C, zzz and >B.
// BC versions: 27, 28, 29

table 90270 "LT UC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[30]) { }
        field(3; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 90272 "LT UC Cd Page"
{
    PageType = List;
    SourceTable = "LT UC Row";
    SourceTableView = where(Cd = filter('>B'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Cd; Rec.Cd) { ApplicationArea = All; }
            }
        }
    }
}

page 90273 "LT UC Txt Page"
{
    PageType = List;
    SourceTable = "LT UC Row";
    SourceTableView = where(Txt = filter('>B'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }
}

query 90274 "LT UC Cd Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT UC Row")
        {
            DataItemTableFilter = Cd = filter('>B');
            column(Id; Id) { }
        }
    }
}

query 90275 "LT UC Txt Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT UC Row")
        {
            DataItemTableFilter = Txt = filter('>B');
            column(Id; Id) { }
        }
    }
}

codeunit 90271 "LT UC Quoted Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT UC Row";
        Values: List of [Text];
        Value: Text;
        i: Integer;
    begin
        Row.DeleteAll();
        Values := ValueList();
        foreach Value in Values do begin
            i += 1;
            Add(i, Value);
        end;
        Add(12, 'B');
        Add(13, 'A');
        Add(14, 'C');
        Add(15, 'zzz');
        Add(16, '>B');
    end;

    local procedure ValueList() Values: List of [Text]
    begin
        Values.AddRange('a>b', '>b', 'a>', '<64Y>', 'Diana''s (Meals)', 'A|B', '''A|B''', 'A''&B', 'A''=B', 'A''..B', 'A''<B');
    end;

    local procedure Add(Id: Integer; Value: Text)
    var
        Row: Record "LT UC Row";
    begin
        Row.Id := Id;
        Row.Cd := CopyStr(Value, 1, MaxStrLen(Row.Cd));
        Row.Txt := CopyStr(Value, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;

    local procedure Ids(var Row: Record "LT UC Row"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Describe(Name: Text; var Source: Record "LT UC Row"; FieldNo: Integer; FilterText: Text; var Observer: Codeunit "Probe Observer")
    var
        Other: Record "LT UC Row";
        ViewText: Text;
    begin
        ViewText := Source.GetView();
        Observer.Observe(Name + '_filter', FilterText);
        Observer.Observe(Name + '_filters', Source.GetFilters());
        Observer.Observe(Name + '_view', ViewText);
        Observer.Observe(Name + '_ids', Ids(Source));
        ClearLastError();
        if SetFilterFromText(Other, FieldNo, FilterText) then
            Observer.Observe(Name + '_setfilter_ids', Ids(Other))
        else begin
            Observer.Observe(Name + '_setfilter_ids', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Clear(Other);
        if SetViewFromText(Other, ViewText) then
            Observer.Observe(Name + '_setview_ids', Ids(Other))
        else begin
            Observer.Observe(Name + '_setview_ids', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [TryFunction]
    local procedure SetFilterFromText(var Row: Record "LT UC Row"; FieldNo: Integer; FilterText: Text)
    begin
        if FieldNo = 2 then
            Row.SetFilter(Cd, FilterText)
        else
            Row.SetFilter(Txt, FilterText);
    end;

    [TryFunction]
    local procedure SetViewFromText(var Row: Record "LT UC Row"; ViewText: Text)
    begin
        Row.SetView(ViewText);
    end;

    local procedure ProbeValue(Value: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT UC Row";
    begin
        Seed();
        Row.SetRange(Cd, CopyStr(Value, 1, 30));
        Describe('cd_range', Row, 2, Row.GetFilter(Cd), Observer);
        Row.Reset();
        Row.SetRange(Txt, CopyStr(Value, 1, 30));
        Describe('txt_range', Row, 3, Row.GetFilter(Txt), Observer);
        Row.Reset();
        Row.SetFilter(Cd, '%1', Value);
        Describe('cd_filter', Row, 2, Row.GetFilter(Cd), Observer);
        Row.Reset();
        Row.SetFilter(Txt, '%1', Value);
        Describe('txt_filter', Row, 3, Row.GetFilter(Txt), Observer);
    end;

    [Test]
    procedure Value01_GreaterInMiddle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('a>b', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value02_GreaterLeading()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('>b', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value03_GreaterTrailing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('a>', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value04_DurationLikeLiteral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('<64Y>', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value05_ApostropheAndParens()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('Diana''s (Meals)', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value06_Pipe()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('A|B', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value07_QuotedPipe()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('''A|B''', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value08_ApostropheAmpersand()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('A''&B', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value09_ApostropheEquals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('A''=B', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value10_ApostropheDotDot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('A''..B', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Value11_ApostropheLess()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeValue('A''<B', Observer);
        Observer.Finish();
    end;

    local procedure PageIds(var Page: TestPage "LT UC Cd Page"): Text
    var
        Result: Text;
    begin
        if Page.First() then
            repeat
                Result += Format(Page.Id.Value()) + ',';
            until not Page.Next();
        exit(Result);
    end;

    local procedure PageIdsTxt(var Page: TestPage "LT UC Txt Page"): Text
    var
        Result: Text;
    begin
        if Page.First() then
            repeat
                Result += Format(Page.Id.Value()) + ',';
            until not Page.Next();
        exit(Result);
    end;

    local procedure QueryIds(var Qry: Query "LT UC Cd Query"): Text
    var
        Result: Text;
    begin
        Qry.Open();
        while Qry.Read() do
            Result += Format(Qry.Id) + ',';
        Qry.Close();
        exit(Result);
    end;

    local procedure QueryIdsTxt(var Qry: Query "LT UC Txt Query"): Text
    var
        Result: Text;
    begin
        Qry.Open();
        while Qry.Read() do
            Result += Format(Qry.Id) + ',';
        Qry.Close();
        exit(Result);
    end;

    [Test]
    procedure PageAndQuery_FilterGreaterB()
    var
        Observer: Codeunit "Probe Observer";
        CdPage: TestPage "LT UC Cd Page";
        TxtPage: TestPage "LT UC Txt Page";
        CdQuery: Query "LT UC Cd Query";
        TxtQuery: Query "LT UC Txt Query";
    begin
        Seed();
        CdPage.OpenView();
        Observer.Observe('page_cd_ids', PageIds(CdPage));
        CdPage.Close();
        TxtPage.OpenView();
        Observer.Observe('page_txt_ids', PageIdsTxt(TxtPage));
        TxtPage.Close();
        Observer.Observe('query_cd_ids', QueryIds(CdQuery));
        Observer.Observe('query_txt_ids', QueryIdsTxt(TxtQuery));
        Observer.Finish();
    end;

    [Test]
    procedure SetView_FilterGreaterB()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UC Row";
    begin
        Seed();
        Row.SetView('SORTING(Id) WHERE(Cd=FILTER(''>B''))');
        Observer.Observe('view_cd_ids', Ids(Row));
        Observer.Observe('view_cd_filter', Row.GetFilter(Cd));
        Observer.Observe('view_cd_view', Row.GetView());
        Row.Reset();
        Row.SetView('SORTING(Id) WHERE(Txt=FILTER(''>B''))');
        Observer.Observe('view_txt_ids', Ids(Row));
        Observer.Observe('view_txt_filter', Row.GetFilter(Txt));
        Observer.Observe('view_txt_view', Row.GetView());
        Row.Reset();
        Row.SetView('SORTING(Id) WHERE(Cd=FILTER(>B))');
        Observer.Observe('view_cd_plain_ids', Ids(Row));
        Row.Reset();
        Row.SetView('SORTING(Id) WHERE(Txt=FILTER(>B))');
        Observer.Observe('view_txt_plain_ids', Ids(Row));
        Observer.Finish();
    end;
}
