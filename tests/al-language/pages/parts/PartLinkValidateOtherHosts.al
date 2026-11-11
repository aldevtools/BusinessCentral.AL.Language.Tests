// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 64740 64741 64742, log codeunit 64743, part pages 64744..64747, host pages
//   64748..64752, test codeunit 64753
// Probe: observe-only. Area: a part whose link value fails its validation when the host opens on a row without lines. Pinned only for a
//   Document host and a part with both AutoSplitKey and DelayedInsert or neither (pages/parts/QjPartPropagation.al:3766
//   QT_ValPartSplit_Empty_Last_KeyValidateErrors, :3825): the error is swallowed, OnNewRecord and OnAfterGetCurrRecord run once on the
//   stamped line, Last() answers No and a write raises TestRowNotFound. Not pinned: a Card host, a ListPlus host, a part with only
//   AutoSplitKey or only DelayedInsert, and a part linked through Provider to a part that shows no row, whose link field validation fails
//   for the blank value (Page.Run of a Card on a new header, al-runner issue 7392).
// Steps: open (OpenEdit and GoToKey, or Page.Run with a PageHandler), Last() on the part, SetValue on the part, Close; the stored lines.
// Observed: ok or the error text and code of each step, and the log (V = the link field's OnValidate in the table, NEW/AGCR = the part's
//   OnNewRecord and OnAfterGetCurrRecord, I = the table's OnInsert).
// local object: the part shapes, their links and the failing link validation are what the test checks
// BC versions: 27, 28, 29

table 64740 "PGA LV Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 64741 "PGA LV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PGA LV Log";
            begin
                Log.Add('V(' + "Head Code" + ' ln=' + Format("Line No.") + ')');
                if Log.Fail() then
                    Error('The link value %1 is refused.', "Head Code");
            end;
        }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; Descr; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('I(' + "Head Code" + ' ' + Format("Line No.") + ')');
    end;
}

table 64742 "PGA LV Filter"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PGA LV Log";
            begin
                Log.Add('FV(' + "Head Code" + ' ln=' + Format("Line No.") + ')');
                TestField("Line No.");
            end;
        }
        field(3; "Filter No."; Integer) { DataClassification = SystemMetadata; }
        field(4; Descr; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.", "Filter No.") { Clustered = true; }
    }
}

codeunit 64743 "PGA LV Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        FailLink: Boolean;

    procedure Reset(NewFail: Boolean)
    begin
        Entries := '';
        FailLink := NewFail;
    end;

    procedure Fail(): Boolean
    begin
        exit(FailLink);
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 64744 "PGA LV Part Split"
{
    PageType = ListPart;
    SourceTable = "PGA LV Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('P.NEW(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('P.AGCR(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;
}

page 64745 "PGA LV Part Delayed"
{
    PageType = ListPart;
    SourceTable = "PGA LV Line";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('P.NEW(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('P.AGCR(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;
}

page 64746 "PGA LV Part Both"
{
    PageType = ListPart;
    SourceTable = "PGA LV Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('P.NEW(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('P.AGCR(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;
}

page 64747 "PGA LV Filter Part"
{
    PageType = ListPart;
    SourceTable = "PGA LV Filter";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('F.NEW(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PGA LV Log";
    begin
        Log.Add('F.AGCR(' + Rec."Head Code" + ' ' + Format(Rec."Line No.") + ')');
    end;
}

page 64748 "PGA LV Card Split"
{
    PageType = Card;
    SourceTable = "PGA LV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
            part(Lines; "PGA LV Part Split")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
                UpdatePropagation = Both;
            }
        }
    }
}

page 64749 "PGA LV Card Delayed"
{
    PageType = Card;
    SourceTable = "PGA LV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
            part(Lines; "PGA LV Part Delayed")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
                UpdatePropagation = Both;
            }
        }
    }
}

page 64750 "PGA LV Card Both"
{
    PageType = Card;
    SourceTable = "PGA LV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
            part(Lines; "PGA LV Part Both")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
                UpdatePropagation = Both;
            }
        }
    }
}

page 64751 "PGA LV ListPlus Both"
{
    PageType = ListPlus;
    SourceTable = "PGA LV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
            part(Lines; "PGA LV Part Both")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
                UpdatePropagation = Both;
            }
        }
    }
}

page 64752 "PGA LV Card Provider"
{
    PageType = Card;
    SourceTable = "PGA LV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
            part(Lines; "PGA LV Part Split")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
                UpdatePropagation = Both;
            }
            part(Filters; "PGA LV Filter Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Head Code" = field("Head Code"), "Line No." = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}

codeunit 64753 "PGA LV Link Validate Hosts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGA LV Log";

    local procedure Initialize(Fail: Boolean)
    var
        Head: Record "PGA LV Head";
        Line: Record "PGA LV Line";
        Flt: Record "PGA LV Filter";
    begin
        Observer.Discard();
        Flt.DeleteAll();
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Init();
        Head."Code" := 'H1';
        Head.Insert();
        Log.Reset(Fail);
    end;

    local procedure Lines(): Text
    var
        Line: Record "PGA LV Line";
        Flt: Record "PGA LV Filter";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Head Code" + ':' + Format(Line."Line No.") + ':' + Line.Descr + ';';
            until Line.Next() = 0;
        if Flt.FindSet() then
            repeat
                Result += 'F' + Flt."Head Code" + ':' + Format(Flt."Line No.") + ':' + Format(Flt."Filter No.") + ';';
            until Flt.Next() = 0;
        exit('[' + Result + ']');
    end;

    [TryFunction]
    local procedure TryOpenCardSplit(var P: TestPage "PGA LV Card Split")
    begin
        P.OpenEdit();
        P.GoToKey('H1');
    end;

    [TryFunction]
    local procedure TryLastCardSplit(var P: TestPage "PGA LV Card Split"; var Result: Boolean)
    begin
        Result := P.Lines.Last();
    end;

    [TryFunction]
    local procedure TryTypeCardSplit(var P: TestPage "PGA LV Card Split")
    begin
        P.Lines.Descr.SetValue('typed');
    end;

    [Test]
    procedure CardSplit_EmptyLines_LinkValidateFails()
    var
        P: TestPage "PGA LV Card Split";
        Result: Boolean;
    begin
        Initialize(true);
        if TryOpenCardSplit(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if TryLastCardSplit(P, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if TryTypeCardSplit(P) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        P.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', Lines());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenCardDelayed(var P: TestPage "PGA LV Card Delayed")
    begin
        P.OpenEdit();
        P.GoToKey('H1');
    end;

    [TryFunction]
    local procedure TryLastCardDelayed(var P: TestPage "PGA LV Card Delayed"; var Result: Boolean)
    begin
        Result := P.Lines.Last();
    end;

    [TryFunction]
    local procedure TryTypeCardDelayed(var P: TestPage "PGA LV Card Delayed")
    begin
        P.Lines.Descr.SetValue('typed');
    end;

    [Test]
    procedure CardDelayed_EmptyLines_LinkValidateFails()
    var
        P: TestPage "PGA LV Card Delayed";
        Result: Boolean;
    begin
        Initialize(true);
        if TryOpenCardDelayed(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if TryLastCardDelayed(P, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if TryTypeCardDelayed(P) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        P.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', Lines());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenCardBoth(var P: TestPage "PGA LV Card Both")
    begin
        P.OpenEdit();
        P.GoToKey('H1');
    end;

    [TryFunction]
    local procedure TryLastCardBoth(var P: TestPage "PGA LV Card Both"; var Result: Boolean)
    begin
        Result := P.Lines.Last();
    end;

    [TryFunction]
    local procedure TryTypeCardBoth(var P: TestPage "PGA LV Card Both")
    begin
        P.Lines.Descr.SetValue('typed');
    end;

    [Test]
    procedure CardBoth_EmptyLines_LinkValidateFails()
    var
        P: TestPage "PGA LV Card Both";
        Result: Boolean;
    begin
        Initialize(true);
        if TryOpenCardBoth(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if TryLastCardBoth(P, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if TryTypeCardBoth(P) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        P.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', Lines());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenListPlusBoth(var P: TestPage "PGA LV ListPlus Both")
    begin
        P.OpenEdit();
        P.GoToKey('H1');
    end;

    [TryFunction]
    local procedure TryLastListPlusBoth(var P: TestPage "PGA LV ListPlus Both"; var Result: Boolean)
    begin
        Result := P.Lines.Last();
    end;

    [TryFunction]
    local procedure TryTypeListPlusBoth(var P: TestPage "PGA LV ListPlus Both")
    begin
        P.Lines.Descr.SetValue('typed');
    end;

    [Test]
    procedure ListPlusBoth_EmptyLines_LinkValidateFails()
    var
        P: TestPage "PGA LV ListPlus Both";
        Result: Boolean;
    begin
        Initialize(true);
        if TryOpenListPlusBoth(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if TryLastListPlusBoth(P, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if TryTypeListPlusBoth(P) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        P.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', Lines());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenCardProvider(var P: TestPage "PGA LV Card Provider")
    begin
        P.OpenEdit();
        P.GoToKey('H1');
    end;

    [TryFunction]
    local procedure TryLastCardProvider(var P: TestPage "PGA LV Card Provider"; var Result: Boolean)
    begin
        Result := P.Lines.Last();
    end;

    [TryFunction]
    local procedure TryTypeCardProvider(var P: TestPage "PGA LV Card Provider")
    begin
        P.Lines.Descr.SetValue('typed');
    end;

    [Test]
    procedure CardProvider_EmptyLines_FilterLinkValidateFails()
    var
        P: TestPage "PGA LV Card Provider";
        Result: Boolean;
    begin
        Initialize(false);
        if TryOpenCardProvider(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log-open', Log.Take());
        if TryLastCardProvider(P, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        Observer.Observe('log-last', Log.Take());
        if TryTypeCardProvider(P) then
            Observer.Observe('type', 'ok')
        else
            Observer.ObserveError('type');
        Observer.Observe('log-type', Log.Take());
        P.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', Lines());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ProviderPageHandler')]
    procedure CardProvider_PageRunOnNewHeader_FilterLinkValidateFails()
    var
        Head: Record "PGA LV Head";
    begin
        Initialize(false);
        Head.Init();
        Head."Code" := 'H2';
        if Head.Insert() then
            Page.Run(Page::"PGA LV Card Provider", Head);
        Observer.Observe('log-run', Log.Take());
        Observer.Observe('lines-after-close', Lines());
        Observer.Finish();
    end;

    [PageHandler]
    procedure ProviderPageHandler(var P: TestPage "PGA LV Card Provider")
    var
        Result: Boolean;
    begin
        Observer.Observe('log-open', Log.Take());
        if TryLastCardProvider(P, Result) then
            Observer.Observe('last', 'ok ' + Format(Result))
        else
            Observer.ObserveError('last');
        P.Close();
    end;
}
