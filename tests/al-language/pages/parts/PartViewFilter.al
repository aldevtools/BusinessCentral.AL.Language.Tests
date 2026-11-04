// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sublink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SubPageView = where("Line No." = filter(>10)) on an own table: rows read at open, with and without SubPageLink, other comparison filters
// BC versions: 29 (27 and 28 by CI)

table 71272 "LT PartView Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Head Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }
}

codeunit 71273 "LT PartView Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Dump(PartName: Text): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Entries do
            if Entry.StartsWith(PartName + '.') then begin
                if Result <> '' then
                    Result += ';';
                Result += Entry.Substring(StrLen(PartName) + 2);
            end;
        exit(Result);
    end;
}

page 71274 "LT PartView GtOnly"
{
    PageType = ListPart;
    SourceTable = "LT PartView Line";
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
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('GtOnly.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('GtOnly.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71275 "LT PartView GtLinked"
{
    PageType = ListPart;
    SourceTable = "LT PartView Line";
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
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('GtLinked.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('GtLinked.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71276 "LT PartView LeAndGt"
{
    PageType = ListPart;
    SourceTable = "LT PartView Line";
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
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('LeAndGt.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('LeAndGt.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71277 "LT PartView ConstTen"
{
    PageType = ListPart;
    SourceTable = "LT PartView Line";
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
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('ConstTen.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartView Log";
    begin
        Log.Add('ConstTen.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71278 "LT PartView Host"
{
    PageType = Document;
    SourceTable = "LT PartReads Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(GtOnlyP; "LT PartView GtOnly")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = filter('>10'));
            }
            part(GtLinkedP; "LT PartView GtLinked")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = filter('>10'));
                SubPageLink = "Head Code" = field("Code");
            }
            part(LeAndGtP; "LT PartView LeAndGt")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = filter('>10&<=20'));
                SubPageLink = "Head Code" = field("Code");
            }
            part(ConstTenP; "LT PartView ConstTen")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = const(10));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }
}

codeunit 71279 "LT PartView Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT PartReads Head";
        Line: Record "LT PartView Line";
        Log: Codeunit "LT PartView Log";
        i: Integer;
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Log.Reset();
        Head."Code" := 'H1';
        Head.Insert();
        Head."Code" := 'H2';
        Head.Insert();
        for i := 1 to 5 do begin
            Line."Head Code" := 'H1';
            Line."Line No." := i * 5;
            Line.Insert();
        end;
        Line."Head Code" := 'H2';
        Line."Line No." := 10;
        Line.Insert();
        Line."Line No." := 30;
        Line.Insert();
    end;

    local procedure ObserveReads(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Log: Codeunit "LT PartView Log";
    begin
        Observer.Observe(Tag + '-GtOnly', Log.Dump('GtOnly'));
        Observer.Observe(Tag + '-GtLinked', Log.Dump('GtLinked'));
        Observer.Observe(Tag + '-LeAndGt', Log.Dump('LeAndGt'));
        Observer.Observe(Tag + '-ConstTen', Log.Dump('ConstTen'));
    end;

    local procedure ObserveRows(var Observer: Codeunit "Probe Observer"; var Doc: TestPage "LT PartView Host"; Tag: Text)
    var
        RowsText: Text;
    begin
        RowsText := '';
        if Doc.GtOnlyP.First() then
            repeat
                RowsText += Doc.GtOnlyP.HeadCtl.Value() + '/' + Doc.GtOnlyP.LineNoCtl.Value() + ',';
            until not Doc.GtOnlyP.Next();
        Observer.Observe(Tag + '-rows-GtOnly', RowsText);
        RowsText := '';
        if Doc.GtLinkedP.First() then
            repeat
                RowsText += Doc.GtLinkedP.HeadCtl.Value() + '/' + Doc.GtLinkedP.LineNoCtl.Value() + ',';
            until not Doc.GtLinkedP.Next();
        Observer.Observe(Tag + '-rows-GtLinked', RowsText);
        RowsText := '';
        if Doc.LeAndGtP.First() then
            repeat
                RowsText += Doc.LeAndGtP.HeadCtl.Value() + '/' + Doc.LeAndGtP.LineNoCtl.Value() + ',';
            until not Doc.LeAndGtP.Next();
        Observer.Observe(Tag + '-rows-LeAndGt', RowsText);
        RowsText := '';
        if Doc.ConstTenP.First() then
            repeat
                RowsText += Doc.ConstTenP.HeadCtl.Value() + '/' + Doc.ConstTenP.LineNoCtl.Value() + ',';
            until not Doc.ConstTenP.Next();
        Observer.Observe(Tag + '-rows-ConstTen', RowsText);
    end;

    [Test]
    procedure OpenView_GreaterThanTenView_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartView Log";
        Doc: TestPage "LT PartView Host";
    begin
        Seed();
        Log.Reset();
        Doc.OpenView();
        ObserveReads(Observer, 'open');
        Doc.Close();
        Observer.Expect('open-GtOnly', 'OnOpenPage(|);AGR(H1/15);AGR(H1/20);AGR(H1/25);AGR(H2/30);AGR(H1/15)');
        Observer.Expect('open-GtLinked', 'OnOpenPage(|);AGR(H1/15);AGR(H1/20);AGR(H1/25);AGR(H1/15)');
        Observer.Expect('open-LeAndGt', 'OnOpenPage(|);AGR(H1/15);AGR(H1/20);AGR(H1/15)');
        Observer.Expect('open-ConstTen', 'OnOpenPage(|);AGR(H1/10)');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_GreaterThanTenView_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartView Log";
        Doc: TestPage "LT PartView Host";
    begin
        Seed();
        Log.Reset();
        Doc.OpenEdit();
        ObserveReads(Observer, 'open');
        Doc.Close();
        Observer.Expect('open-GtOnly', 'OnOpenPage(|);AGR(H1/15);AGR(H1/20);AGR(H1/25);AGR(H2/30);AGR(H1/15)');
        Observer.Expect('open-GtLinked', 'OnOpenPage(|);AGR(H1/15);AGR(H1/20);AGR(H1/25);AGR(H1/15)');
        Observer.Expect('open-LeAndGt', 'OnOpenPage(|);AGR(H1/15);AGR(H1/20);AGR(H1/15)');
        Observer.Expect('open-ConstTen', 'OnOpenPage(|);AGR(H1/10)');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_GreaterThanTenView_RowsShownPerHostRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartView Log";
        Doc: TestPage "LT PartView Host";
    begin
        Seed();
        Doc.OpenView();
        ObserveRows(Observer, Doc, 'h1');
        Doc.Next();
        ObserveRows(Observer, Doc, 'h2');
        Doc.Close();
        Observer.Expect('h1-rows-GtOnly', 'H1/15,H1/20,H1/25,H2/30,');
        Observer.Expect('h1-rows-GtLinked', 'H1/15,H1/20,H1/25,');
        Observer.Expect('h1-rows-LeAndGt', 'H1/15,H1/20,');
        Observer.Expect('h1-rows-ConstTen', 'H1/10,');
        Observer.Expect('h2-rows-GtOnly', 'H1/15,H1/20,H1/25,H2/30,');
        Observer.Expect('h2-rows-GtLinked', 'H2/30,');
        Observer.Expect('h2-rows-LeAndGt', '');
        Observer.Expect('h2-rows-ConstTen', 'H2/10,');
        Observer.Verify();
    end;

    [Test]
    procedure Next_GreaterThanTenView_ReadsAfterHostMove()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartView Log";
        Doc: TestPage "LT PartView Host";
    begin
        Seed();
        Doc.OpenView();
        Log.Reset();
        Observer.Observe('next', Format(Doc.Next()));
        ObserveReads(Observer, 'next');
        Log.Reset();
        Observer.Observe('previous', Format(Doc.Previous()));
        ObserveReads(Observer, 'previous');
        Doc.Close();
        Observer.Expect('next', 'Yes');
        Observer.Expect('next-GtOnly', '');
        Observer.Expect('next-GtLinked', 'AGR(H2/30)');
        Observer.Expect('next-LeAndGt', '');
        Observer.Expect('next-ConstTen', 'AGR(H2/10)');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('previous-GtOnly', '');
        Observer.Expect('previous-GtLinked', 'AGR(H1/25);AGR(H1/20);AGR(H1/15)');
        Observer.Expect('previous-LeAndGt', 'AGR(H1/20);AGR(H1/15)');
        Observer.Expect('previous-ConstTen', 'AGR(H1/10)');
        Observer.Verify();
    end;

}
