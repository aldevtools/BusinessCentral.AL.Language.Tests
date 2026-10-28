// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sublink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT PartReads Host / Parts / Log (PartReadsFixtures.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: AGR/OnOpenPage reads of each of six distinct parts (plain, linked, SubPageView, same-field view and link, hidden, view-filtered) in OpenView/OpenEdit/OpenNew, after host Next/Last/Previous/First, rows each part shows
// BC versions: 29 (27 and 28 by CI)

codeunit 71290 "LT PartReads Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT PartReads Head";
        Line: Record "LT PartReads Line";
        Log: Codeunit "LT PartReads Log";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Log.SetShowHidden(false);
        Log.Reset();
        Head."Code" := 'H1';
        Head.Insert();
        Head."Code" := 'H2';
        Head.Insert();
        Head."Code" := 'H3';
        Head.Insert();
        AddLine('H1', 10000);
        AddLine('H1', 20000);
        AddLine('H1', 30000);
        AddLine('H2', 10000);
        AddLine('H2', 20000);
        AddLine('H3', 10000);
    end;

    local procedure AddLine(HeadCode: Code[20]; LineNo: Integer)
    var
        Line: Record "LT PartReads Line";
    begin
        Line."Head Code" := HeadCode;
        Line."Line No." := LineNo;
        Line.Descr := HeadCode + ' line ' + Format(LineNo);
        Line.Insert();
    end;

    local procedure ObserveLong(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        Part: Integer;
    begin
        if StrLen(Value) <= 800 then begin
            Observer.Observe(Name, Value);
            exit;
        end;
        while Value <> '' do begin
            Part += 1;
            Observer.Observe(Name + '-' + Format(Part), CopyStr(Value, 1, 800));
            Value := CopyStr(Value, 801);
        end;
    end;

    local procedure ObserveParts(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Log: Codeunit "LT PartReads Log";
    begin
        ObserveLong(Observer, Tag + '-host', Log.DumpHost());
        ObserveLong(Observer, Tag + '-Plain', Log.DumpOf('Plain'));
        Observer.Observe(Tag + '-Plain-count', Format(Log.CountOf('Plain')));
        ObserveLong(Observer, Tag + '-Linked', Log.DumpOf('Linked'));
        Observer.Observe(Tag + '-Linked-count', Format(Log.CountOf('Linked')));
        ObserveLong(Observer, Tag + '-View', Log.DumpOf('View'));
        Observer.Observe(Tag + '-View-count', Format(Log.CountOf('View')));
        ObserveLong(Observer, Tag + '-Same', Log.DumpOf('Same'));
        Observer.Observe(Tag + '-Same-count', Format(Log.CountOf('Same')));
        ObserveLong(Observer, Tag + '-Hidden', Log.DumpOf('Hidden'));
        Observer.Observe(Tag + '-Hidden-count', Format(Log.CountOf('Hidden')));
        ObserveLong(Observer, Tag + '-Filtered', Log.DumpOf('Filtered'));
        Observer.Observe(Tag + '-Filtered-count', Format(Log.CountOf('Filtered')));
        Observer.Observe(Tag + '-total', Format(Log.Count()));
    end;

    local procedure ObserveRows(var Observer: Codeunit "Probe Observer"; var Doc: TestPage "LT PartReads Host"; Tag: Text)
    var
        RowsText: Text;
    begin
        RowsText := '';
        if Doc.PlainP.First() then
            repeat
                RowsText += Doc.PlainP.HeadCtl.Value() + '/' + Doc.PlainP.LineNoCtl.Value() + ',';
            until not Doc.PlainP.Next();
        Observer.Observe(Tag + '-rows-Plain', RowsText);
        RowsText := '';
        if Doc.LinkedP.First() then
            repeat
                RowsText += Doc.LinkedP.HeadCtl.Value() + '/' + Doc.LinkedP.LineNoCtl.Value() + ',';
            until not Doc.LinkedP.Next();
        Observer.Observe(Tag + '-rows-Linked', RowsText);
        RowsText := '';
        if Doc.ViewP.First() then
            repeat
                RowsText += Doc.ViewP.HeadCtl.Value() + '/' + Doc.ViewP.LineNoCtl.Value() + ',';
            until not Doc.ViewP.Next();
        Observer.Observe(Tag + '-rows-View', RowsText);
        RowsText := '';
        if Doc.SameP.First() then
            repeat
                RowsText += Doc.SameP.HeadCtl.Value() + '/' + Doc.SameP.LineNoCtl.Value() + ',';
            until not Doc.SameP.Next();
        Observer.Observe(Tag + '-rows-Same', RowsText);
        RowsText := '';
        if Doc.FilteredP.First() then
            repeat
                RowsText += Doc.FilteredP.HeadCtl.Value() + '/' + Doc.FilteredP.LineNoCtl.Value() + ',';
            until not Doc.FilteredP.Next();
        Observer.Observe(Tag + '-rows-Filtered', RowsText);
    end;

    [Test]
    procedure OpenView_SixParts_ReadsPerPartLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Log.Reset();
        Doc.OpenView();
        ObserveParts(Observer, 'open');
        Doc.Close();
        Observer.Expect('open-host', 'AGR(H1)');
        Observer.Expect('open-Plain', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H2/10000);AGR(H2/20000);AGR(H3/10000);AGR(H1/10000)');
        Observer.Expect('open-Plain-count', '8');
        Observer.Expect('open-Linked', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H1/10000)');
        Observer.Expect('open-Linked-count', '5');
        Observer.Expect('open-View', 'OnOpenPage(|);AGR(H1/20000);AGR(H2/20000);AGR(H1/20000)');
        Observer.Expect('open-View-count', '4');
        Observer.Expect('open-Same', 'OnOpenPage(|);AGR(H1/30000);AGR(H1/20000);AGR(H1/10000)');
        Observer.Expect('open-Same-count', '4');
        Observer.Expect('open-Hidden', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H1/10000)');
        Observer.Expect('open-Hidden-count', '5');
        Observer.Expect('open-Filtered', 'OnOpenPage(|);AGR(H1/20000);AGR(H1/30000);AGR(H1/20000)');
        Observer.Expect('open-Filtered-count', '4');
        Observer.Expect('open-total', '31');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_SixParts_ReadsPerPartLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Log.Reset();
        Doc.OpenEdit();
        ObserveParts(Observer, 'open');
        Doc.Close();
        Observer.Expect('open-host', 'AGR(H1)');
        Observer.Expect('open-Plain', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H2/10000);AGR(H2/20000);AGR(H3/10000);AGR(H1/10000)');
        Observer.Expect('open-Plain-count', '8');
        Observer.Expect('open-Linked', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H1/10000)');
        Observer.Expect('open-Linked-count', '5');
        Observer.Expect('open-View', 'OnOpenPage(|);AGR(H1/20000);AGR(H2/20000);AGR(H1/20000)');
        Observer.Expect('open-View-count', '4');
        Observer.Expect('open-Same', 'OnOpenPage(|);AGR(H1/30000);AGR(H1/20000);AGR(H1/10000)');
        Observer.Expect('open-Same-count', '4');
        Observer.Expect('open-Hidden', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H1/10000)');
        Observer.Expect('open-Hidden-count', '5');
        Observer.Expect('open-Filtered', 'OnOpenPage(|);AGR(H1/20000);AGR(H1/30000);AGR(H1/20000)');
        Observer.Expect('open-Filtered-count', '4');
        Observer.Expect('open-total', '31');
        Observer.Verify();
    end;

    [Test]
    procedure OpenNew_SixParts_ReadsPerPartLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Log.Reset();
        Doc.OpenNew();
        ObserveParts(Observer, 'open');
        Doc.Close();
        Observer.Expect('open-host', '');
        Observer.Expect('open-Plain', 'OnOpenPage(|);AGR(H1/10000);AGR(H1/20000);AGR(H1/30000);AGR(H2/10000);AGR(H2/20000);AGR(H3/10000);AGR(H1/10000)');
        Observer.Expect('open-Plain-count', '8');
        Observer.Expect('open-Linked', 'OnOpenPage(|)');
        Observer.Expect('open-Linked-count', '1');
        Observer.Expect('open-View', 'OnOpenPage(|);AGR(H1/20000);AGR(H2/20000);AGR(H1/20000)');
        Observer.Expect('open-View-count', '4');
        Observer.Expect('open-Same', 'OnOpenPage(|)');
        Observer.Expect('open-Same-count', '1');
        Observer.Expect('open-Hidden', 'OnOpenPage(|)');
        Observer.Expect('open-Hidden-count', '1');
        Observer.Expect('open-Filtered', 'OnOpenPage(|)');
        Observer.Expect('open-Filtered-count', '1');
        Observer.Expect('open-total', '16');
        Observer.Verify();
    end;

    [Test]
    procedure Next_SixParts_ReadsPerPartAfterHostMove()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Doc.OpenView();
        Log.Reset();
        Observer.Observe('next-1', Format(Doc.Next()));
        ObserveParts(Observer, 'next-1');
        Log.Reset();
        Observer.Observe('next-2', Format(Doc.Next()));
        ObserveParts(Observer, 'next-2');
        Log.Reset();
        Observer.Observe('next-3', Format(Doc.Next()));
        ObserveParts(Observer, 'next-3');
        Doc.Close();
        Observer.Expect('next-1', 'Yes');
        Observer.Expect('next-1-host', 'AGR(H2)');
        Observer.Expect('next-1-Plain', '');
        Observer.Expect('next-1-Plain-count', '0');
        Observer.Expect('next-1-Linked', 'AGR(H2/10000);AGR(H2/20000);AGR(H2/10000)');
        Observer.Expect('next-1-Linked-count', '3');
        Observer.Expect('next-1-View', '');
        Observer.Expect('next-1-View-count', '0');
        Observer.Expect('next-1-Same', 'AGR(H2/10000);AGR(H2/20000);AGR(H2/10000)');
        Observer.Expect('next-1-Same-count', '3');
        Observer.Expect('next-1-Hidden', 'AGR(H2/10000);AGR(H2/20000);AGR(H2/10000)');
        Observer.Expect('next-1-Hidden-count', '3');
        Observer.Expect('next-1-Filtered', 'AGR(H2/20000)');
        Observer.Expect('next-1-Filtered-count', '1');
        Observer.Expect('next-1-total', '11');
        Observer.Expect('next-2', 'Yes');
        Observer.Expect('next-2-host', 'AGR(H3)');
        Observer.Expect('next-2-Plain', '');
        Observer.Expect('next-2-Plain-count', '0');
        Observer.Expect('next-2-Linked', 'AGR(H3/10000)');
        Observer.Expect('next-2-Linked-count', '1');
        Observer.Expect('next-2-View', '');
        Observer.Expect('next-2-View-count', '0');
        Observer.Expect('next-2-Same', 'AGR(H3/10000)');
        Observer.Expect('next-2-Same-count', '1');
        Observer.Expect('next-2-Hidden', 'AGR(H3/10000)');
        Observer.Expect('next-2-Hidden-count', '1');
        Observer.Expect('next-2-Filtered', '');
        Observer.Expect('next-2-Filtered-count', '0');
        Observer.Expect('next-2-total', '4');
        Observer.Expect('next-3', 'No');
        Observer.Expect('next-3-host', '');
        Observer.Expect('next-3-Plain', '');
        Observer.Expect('next-3-Plain-count', '0');
        Observer.Expect('next-3-Linked', '');
        Observer.Expect('next-3-Linked-count', '0');
        Observer.Expect('next-3-View', '');
        Observer.Expect('next-3-View-count', '0');
        Observer.Expect('next-3-Same', '');
        Observer.Expect('next-3-Same-count', '0');
        Observer.Expect('next-3-Hidden', '');
        Observer.Expect('next-3-Hidden-count', '0');
        Observer.Expect('next-3-Filtered', '');
        Observer.Expect('next-3-Filtered-count', '0');
        Observer.Expect('next-3-total', '0');
        Observer.Verify();
    end;

    [Test]
    procedure LastPrevious_SixParts_ReadsPerPartAfterHostMove()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Doc.OpenView();
        Log.Reset();
        Observer.Observe('last', Format(Doc.Last()));
        ObserveParts(Observer, 'last');
        Log.Reset();
        Observer.Observe('previous', Format(Doc.Previous()));
        ObserveParts(Observer, 'previous');
        Log.Reset();
        Observer.Observe('first', Format(Doc.First()));
        ObserveParts(Observer, 'first');
        Doc.Close();
        Observer.Expect('last', 'Yes');
        Observer.Expect('last-host', 'AGR(H3)');
        Observer.Expect('last-Plain', '');
        Observer.Expect('last-Plain-count', '0');
        Observer.Expect('last-Linked', 'AGR(H3/10000)');
        Observer.Expect('last-Linked-count', '1');
        Observer.Expect('last-View', '');
        Observer.Expect('last-View-count', '0');
        Observer.Expect('last-Same', 'AGR(H3/10000)');
        Observer.Expect('last-Same-count', '1');
        Observer.Expect('last-Hidden', 'AGR(H3/10000)');
        Observer.Expect('last-Hidden-count', '1');
        Observer.Expect('last-Filtered', '');
        Observer.Expect('last-Filtered-count', '0');
        Observer.Expect('last-total', '4');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('previous-host', 'AGR(H2)');
        Observer.Expect('previous-Plain', '');
        Observer.Expect('previous-Plain-count', '0');
        Observer.Expect('previous-Linked', 'AGR(H2/20000);AGR(H2/10000)');
        Observer.Expect('previous-Linked-count', '2');
        Observer.Expect('previous-View', '');
        Observer.Expect('previous-View-count', '0');
        Observer.Expect('previous-Same', 'AGR(H2/20000);AGR(H2/10000)');
        Observer.Expect('previous-Same-count', '2');
        Observer.Expect('previous-Hidden', 'AGR(H2/20000);AGR(H2/10000)');
        Observer.Expect('previous-Hidden-count', '2');
        Observer.Expect('previous-Filtered', 'AGR(H2/20000)');
        Observer.Expect('previous-Filtered-count', '1');
        Observer.Expect('previous-total', '8');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-host', 'AGR(H1)');
        Observer.Expect('first-Plain', '');
        Observer.Expect('first-Plain-count', '0');
        Observer.Expect('first-Linked', 'AGR(H1/30000);AGR(H1/20000);AGR(H1/10000)');
        Observer.Expect('first-Linked-count', '3');
        Observer.Expect('first-View', '');
        Observer.Expect('first-View-count', '0');
        Observer.Expect('first-Same', 'AGR(H1/30000);AGR(H1/20000);AGR(H1/10000)');
        Observer.Expect('first-Same-count', '3');
        Observer.Expect('first-Hidden', 'AGR(H1/30000);AGR(H1/20000);AGR(H1/10000)');
        Observer.Expect('first-Hidden-count', '3');
        Observer.Expect('first-Filtered', 'AGR(H1/30000);AGR(H1/20000)');
        Observer.Expect('first-Filtered-count', '2');
        Observer.Expect('first-total', '12');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_SixParts_RowsPerPartAtEachHostRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Doc.OpenView();
        ObserveRows(Observer, Doc, 'h1');
        Doc.Next();
        ObserveRows(Observer, Doc, 'h2');
        Doc.Next();
        ObserveRows(Observer, Doc, 'h3');
        Doc.Close();
        Observer.Expect('h1-rows-Plain', 'H1/10000,H1/20000,H1/30000,H2/10000,H2/20000,H3/10000,');
        Observer.Expect('h1-rows-Linked', 'H1/10000,H1/20000,H1/30000,');
        Observer.Expect('h1-rows-View', 'H1/20000,H2/20000,');
        Observer.Expect('h1-rows-Same', 'H1/10000,H1/20000,H1/30000,');
        Observer.Expect('h1-rows-Filtered', 'H1/20000,H1/30000,');
        Observer.Expect('h2-rows-Plain', 'H1/10000,H1/20000,H1/30000,H2/10000,H2/20000,H3/10000,');
        Observer.Expect('h2-rows-Linked', 'H2/10000,H2/20000,');
        Observer.Expect('h2-rows-View', 'H1/20000,H2/20000,');
        Observer.Expect('h2-rows-Same', 'H2/10000,H2/20000,');
        Observer.Expect('h2-rows-Filtered', 'H2/20000,');
        Observer.Expect('h3-rows-Plain', 'H1/10000,H1/20000,H1/30000,H2/10000,H2/20000,H3/10000,');
        Observer.Expect('h3-rows-Linked', 'H3/10000,');
        Observer.Expect('h3-rows-View', 'H1/20000,H2/20000,');
        Observer.Expect('h3-rows-Same', 'H3/10000,');
        Observer.Expect('h3-rows-Filtered', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_SixParts_ReadsAfterPartNavigation()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PartReads Log";
        Doc: TestPage "LT PartReads Host";
    begin
        Seed();
        Doc.OpenView();
        Log.Reset();
        Observer.Observe('linked-first', Format(Doc.LinkedP.First()));
        Observer.Observe('linked-next', Format(Doc.LinkedP.Next()));
        Observer.Observe('linked-last', Format(Doc.LinkedP.Last()));
        ObserveParts(Observer, 'nav');
        Doc.Close();
        Observer.Expect('linked-first', 'Yes');
        Observer.Expect('linked-next', 'Yes');
        Observer.Expect('linked-last', 'Yes');
        Observer.Expect('nav-host', '');
        Observer.Expect('nav-Plain', '');
        Observer.Expect('nav-Plain-count', '0');
        Observer.Expect('nav-Linked', '');
        Observer.Expect('nav-Linked-count', '0');
        Observer.Expect('nav-View', '');
        Observer.Expect('nav-View-count', '0');
        Observer.Expect('nav-Same', '');
        Observer.Expect('nav-Same-count', '0');
        Observer.Expect('nav-Hidden', '');
        Observer.Expect('nav-Hidden-count', '0');
        Observer.Expect('nav-Filtered', '');
        Observer.Expect('nav-Filtered-count', '0');
        Observer.Expect('nav-total', '0');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5959: a FactBox part that serves its rows from OnFindRecord/OnNextRecord over a temporary buffer (the
    // shape of page 9126 "Lot Numbers by Bin FactBox" on page 7351 "Movement Worksheet"), linked to the current line of a Worksheet host.
    // What the part shows and which Which/Steps it gets when the host moves back (First, Previous) and forward (Next, Last). The log
    // entries are FR.Find(<Which>|<link filter>), FR.Next(<Steps>), FR.AGR(<code>), Host.AGR(<head>/<line>).

    local procedure ShFrStep(var Observer: Codeunit "Probe Observer"; var Ws: TestPage "LT SH FR Host"; Tag: Text)
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Observer.Observe(Tag + ' host', Ws.HeadCtl.Value() + '/' + Ws.LineNoCtl.Value());
        Observer.Observe(Tag + ' part', Ws.GroupPart.DescrCtl.Value());
        Observer.Observe(Tag + ' part log', Log.DumpOf('FR'));
        Log.Reset();
    end;

    [Test]
    procedure SH_FindRecordPart_HostFirstAfterGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        Ws: TestPage "LT SH FR Host";
    begin
        Seed();
        Ws.OpenEdit();
        ShFrStep(Observer, Ws, 'open');
        Ws.GoToKey('H2', 10000);
        ShFrStep(Observer, Ws, 'gotokey H2/10000');
        Ws.First();
        ShFrStep(Observer, Ws, 'first');
        Ws.Close();
        Observer.Expect('open host', 'H1/10000');
        Observer.Expect('open part', 'Filled for H1');
        Observer.Expect('open part log', 'Find(=><|);AGR(H1);Next(1);Next(-1)');
        Observer.Expect('gotokey H2/10000 host', 'H2/10000');
        Observer.Expect('gotokey H2/10000 part', 'Filled for H2');
        Observer.Expect('gotokey H2/10000 part log', 'Find(=><|);AGR(H2);Next(1);Next(-1)');
        Observer.Expect('first host', 'H1/10000');
        Observer.Expect('first part', 'Filled for H1');
        Observer.Expect('first part log', 'Find(=><|);AGR(H1);Next(1);Next(-1)');
        Observer.Verify();
    end;

    [Test]
    procedure SH_FindRecordPart_HostNextLastPrevious()
    var
        Observer: Codeunit "Probe Observer";
        Ws: TestPage "LT SH FR Host";
    begin
        Seed();
        Ws.OpenEdit();
        ShFrStep(Observer, Ws, 'open');
        Ws.Next();
        Ws.Next();
        Ws.Next();
        ShFrStep(Observer, Ws, 'next x3');
        Ws.Last();
        ShFrStep(Observer, Ws, 'last');
        Ws.Previous();
        ShFrStep(Observer, Ws, 'previous');
        Ws.Close();
        Observer.Expect('open host', 'H1/10000');
        Observer.Expect('open part', 'Filled for H1');
        Observer.Expect('open part log', 'Find(=><|);AGR(H1);Next(1);Next(-1)');
        Observer.Expect('next x3 host', 'H2/10000');
        Observer.Expect('next x3 part', 'Filled for H2');
        Observer.Expect('next x3 part log', 'Find(=><|);AGR(H2);Next(1);Next(-1)');
        Observer.Expect('last host', 'H3/10000');
        Observer.Expect('last part', 'Filled for H3');
        Observer.Expect('last part log', 'Find(=><|);AGR(H3);Next(1);Next(-1)');
        Observer.Expect('previous host', 'H2/20000');
        Observer.Expect('previous part', 'Filled for H2');
        Observer.Expect('previous part log', 'Find(=><|);AGR(H2);Next(1);Next(-1)');
        Observer.Verify();
    end;
}

page 89440 "LT SH FR Host"
{
    PageType = Worksheet;
    SourceTable = "LT PartReads Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(HeadCtl; Rec."Head Code") { ApplicationArea = All; }
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(GroupPart; "LT SH FR Part")
            {
                ApplicationArea = All;
                SubPageLink = "Code" = field("Head Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Host.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 89441 "LT SH FR Part"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Head";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('FR.Find(' + Which + '|' + Rec.GetFilter("Code") + ')');
        Rec.DeleteAll();
        Rec.Init();
        Rec."Code" := CopyStr(Rec.GetRangeMin("Code"), 1, MaxStrLen(Rec."Code"));
        Rec.Descr := 'Filled for ' + Rec."Code";
        Rec.Insert();
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('FR.Next(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('FR.AGR(' + Rec."Code" + ')');
    end;
}
