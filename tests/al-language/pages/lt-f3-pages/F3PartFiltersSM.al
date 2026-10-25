// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables LT F3 Head / LT F3 Line, LT F3 Part Log and LT F3 Part Data of F3PartFixtures.al; own pages 89250 - 89253, test codeunit 89254
// Facts: the neighbour F3PartTests.al pins the reads of a part whose SubPageView names its linked field (filter('H1|H2'), <> 'H3', const('ZZZ')).
//   This file pins the filters the part's Rec holds in each filter group (0 to 7) for the linked field and GetFilters, read in OnFindRecord and
//   OnOpenPage, and the rows the TestPage part shows, on host H1 and after the host moves to H3 (outside the view of the filter and <> hosts).
// BC versions: 27, 28, 29

page 89250 "LT SM F3 Filter Part"
{
    PageType = ListPart;
    SourceTable = "LT F3 Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadCtl; Rec."Head Code") { ApplicationArea = All; }
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Add('Open' + Groups());
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT F3 Part Log";
        Found: Boolean;
    begin
        Log.Add('Find' + Groups());
        Found := Rec.Find(Which);
        exit(Found);
    end;

    local procedure Groups(): Text
    var
        Saved: Integer;
        G: Integer;
        Result: Text;
    begin
        Saved := Rec.FilterGroup();
        for G := 0 to 7 do begin
            Rec.FilterGroup(G);
            if Rec.GetFilter("Head Code") <> '' then
                Result += ' g' + Format(G) + '=[' + Rec.GetFilter("Head Code") + ']';
        end;
        Rec.FilterGroup(Saved);
        exit('(group ' + Format(Saved) + Result + ' all=[' + Rec.GetFilters() + '])');
    end;
}

page 89251 "LT SM F3 Host Filter"
{
    PageType = Card;
    SourceTable = "LT F3 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT SM F3 Filter Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('H1|H2'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }
}

page 89252 "LT SM F3 Host NotEqual"
{
    PageType = Card;
    SourceTable = "LT F3 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT SM F3 Filter Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter(<> 'H3'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }
}

page 89253 "LT SM F3 Host Const"
{
    PageType = Card;
    SourceTable = "LT F3 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT SM F3 Filter Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = const('ZZZ'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }
}

codeunit 89254 "LT SM F3 Part Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Observer.Observe(Name, Log.Dump());
        Log.Reset();
    end;

    [Test]
    procedure FilterView_GroupsAndRows()
    var
        Observer: Codeunit "Probe Observer";
        Data: Codeunit "LT F3 Part Data";
        Doc: TestPage "LT SM F3 Host Filter";
        Rows: Text;
    begin
        Data.Seed(3);
        Doc.OpenView();
        Step(Observer, 'open');
        Rows := '';
        if Doc.Lines.First() then
            repeat
                Rows += ' ' + Doc.Lines.HeadCtl.Value() + '/' + Doc.Lines.LineNoCtl.Value();
            until not Doc.Lines.Next();
        Observer.Observe('rows H1', Rows);
        Step(Observer, 'after rows H1');
        Doc.Last();
        Step(Observer, 'move to H3');
        Rows := '';
        if Doc.Lines.First() then
            repeat
                Rows += ' ' + Doc.Lines.HeadCtl.Value() + '/' + Doc.Lines.LineNoCtl.Value();
            until not Doc.Lines.Next();
        Observer.Observe('rows H3', Rows);
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NotEqualView_GroupsAndRows()
    var
        Observer: Codeunit "Probe Observer";
        Data: Codeunit "LT F3 Part Data";
        Doc: TestPage "LT SM F3 Host NotEqual";
        Rows: Text;
    begin
        Data.Seed(3);
        Doc.OpenView();
        Step(Observer, 'open');
        Rows := '';
        if Doc.Lines.First() then
            repeat
                Rows += ' ' + Doc.Lines.HeadCtl.Value() + '/' + Doc.Lines.LineNoCtl.Value();
            until not Doc.Lines.Next();
        Observer.Observe('rows H1', Rows);
        Step(Observer, 'after rows H1');
        Doc.Last();
        Step(Observer, 'move to H3');
        Rows := '';
        if Doc.Lines.First() then
            repeat
                Rows += ' ' + Doc.Lines.HeadCtl.Value() + '/' + Doc.Lines.LineNoCtl.Value();
            until not Doc.Lines.Next();
        Observer.Observe('rows H3', Rows);
        Doc.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ConstView_GroupsAndRows()
    var
        Observer: Codeunit "Probe Observer";
        Data: Codeunit "LT F3 Part Data";
        Doc: TestPage "LT SM F3 Host Const";
        Rows: Text;
    begin
        Data.Seed(3);
        Doc.OpenView();
        Step(Observer, 'open');
        Rows := '';
        if Doc.Lines.First() then
            repeat
                Rows += ' ' + Doc.Lines.HeadCtl.Value() + '/' + Doc.Lines.LineNoCtl.Value();
            until not Doc.Lines.Next();
        Observer.Observe('rows H1', Rows);
        Step(Observer, 'after rows H1');
        Doc.Close();
        Observer.Finish();
    end;
}
