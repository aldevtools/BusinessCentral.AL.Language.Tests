// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: the page's OnFindRecord and OnNextRecord triggers (and the row filter of a second page) are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 99940, pages 99941 and 99942, test codeunit 99943
// Probe (al-runner issue 7409): TestPage.GoToRecord and GoToKey on a row that the page's OnFindRecord and OnNextRecord skip (ShowRecord false),
//   with the skipped row alone, first, in the middle and last; the same on a page whose SourceTableView leaves the row out. The reading is the
//   result (found true or false, or the error text and code), the row the page shows afterwards, and the rows First / Next walk through.
// BC versions: 27, 28, 29

table 99940 "LT K12 Plan Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Outstanding Quantity"; Decimal) { }
        field(3; "Reserved Quantity"; Decimal) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 99941 "LT K12 Plan List"
{
    PageType = List;
    SourceTable = "LT K12 Plan Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Outstanding Quantity"; Rec."Outstanding Quantity") { ApplicationArea = All; }
                field("Reserved Quantity"; Rec."Reserved Quantity") { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then begin
            SavedLine := Rec;
            while true do begin
                if ShowRecord() then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := SavedLine;
                    if Rec.Find(Which) then
                        while true do begin
                            if ShowRecord() then
                                exit(true);
                            if Rec.Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        NextSteps: Integer;
        RealSteps: Integer;
    begin
        if Steps = 0 then
            exit;
        SavedLine := Rec;
        repeat
            NextSteps := Rec.Next(Steps div Abs(Steps));
            if ShowRecord() then begin
                RealSteps += NextSteps;
                SavedLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := SavedLine;
        Rec.Find();
        exit(RealSteps);
    end;

    local procedure ShowRecord(): Boolean
    begin
        exit(Rec."Reserved Quantity" < Rec."Outstanding Quantity");
    end;

    var
        SavedLine: Record "LT K12 Plan Line";
}

page 99942 "LT K12 Plan View List"
{
    PageType = List;
    SourceTable = "LT K12 Plan Line";
    SourceTableView = where("No." = filter('..2'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Outstanding Quantity"; Rec."Outstanding Quantity") { ApplicationArea = All; }
            }
        }
    }
}

page 99944 "LT K12 Plan Find Only"
{
    PageType = List;
    SourceTable = "LT K12 Plan Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not Rec.Find(Which) then
            exit(false);
        while Rec."Reserved Quantity" >= Rec."Outstanding Quantity" do
            if Rec.Next(1) = 0 then
                exit(false);
        exit(true);
    end;
}

page 99945 "LT K12 Plan Afterget"
{
    PageType = List;
    SourceTable = "LT K12 Plan Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Rec.Next(Steps));
    end;
}

codeunit 99943 "LT K12 GoTo Skipped Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Rows: 1..3, outstanding 5; a row is hidden by the triggers when it is fully reserved (reserved 5).
    local procedure Seed(Hidden: Text)
    var
        Line: Record "LT K12 Plan Line";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to 3 do begin
            Line."No." := i;
            Line."Outstanding Quantity" := 5;
            Line."Reserved Quantity" := 0;
            if ('|' + Hidden + '|').Contains('|' + Format(i) + '|') then
                Line."Reserved Quantity" := 5;
            Line.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryRecord(var P: TestPage "LT K12 Plan List"; RowNo: Integer; var Found: Boolean)
    var
        Line: Record "LT K12 Plan Line";
    begin
        Line.Get(RowNo);
        Found := P.GoToRecord(Line);
    end;

    [TryFunction]
    local procedure TryKey(var P: TestPage "LT K12 Plan List"; RowNo: Integer; var Found: Boolean)
    begin
        Found := P.GoToKey(RowNo);
    end;

    [TryFunction]
    local procedure TryViewRecord(var P: TestPage "LT K12 Plan View List"; RowNo: Integer; var Found: Boolean)
    var
        Line: Record "LT K12 Plan Line";
    begin
        Line.Get(RowNo);
        Found := P.GoToRecord(Line);
    end;

    [TryFunction]
    local procedure TryViewKey(var P: TestPage "LT K12 Plan View List"; RowNo: Integer; var Found: Boolean)
    begin
        Found := P.GoToKey(RowNo);
    end;

    local procedure Walk(var P: TestPage "LT K12 Plan List"): Text
    var
        Result: Text;
    begin
        if P.First() then
            repeat
                Result += P."No.".Value() + ',';
            until not P.Next();
        exit(Result);
    end;

    local procedure Reading(Ok: Boolean; Found: Boolean): Text
    begin
        if Ok then
            exit('found=' + Format(Found));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Go(Hidden: Text; Target: Integer; ByRecord: Boolean): Text
    var
        P: TestPage "LT K12 Plan List";
        Found: Boolean;
        Ok: Boolean;
        Shown: Text;
    begin
        Seed(Hidden);
        P.OpenView();
        ClearLastError();
        if ByRecord then
            Ok := TryRecord(P, Target, Found)
        else
            Ok := TryKey(P, Target, Found);
        Shown := Reading(Ok, Found);
        exit(Shown + ' now=' + P."No.".Value() + ' rows=' + Walk(P));
    end;

    [Test]
    procedure Y7409_SingleLine_Hidden()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Plan List";
        Line: Record "LT K12 Plan Line";
        Found: Boolean;
        Ok: Boolean;
    begin
        // the only line is fully reserved (the shape of the report)
        Line.DeleteAll();
        Line."No." := 1;
        Line."Outstanding Quantity" := 5;
        Line."Reserved Quantity" := 5;
        Line.Insert();
        P.OpenView();
        Observer.Observe('open: first row shown', Format(P.First()));
        ClearLastError();
        Ok := TryRecord(P, 1, Found);
        Observer.Observe('GoToRecord of the hidden only line', Reading(Ok, Found));
        ClearLastError();
        Ok := TryKey(P, 1, Found);
        Observer.Observe('GoToKey of the hidden only line', Reading(Ok, Found));
        Observer.Finish();
    end;

    [Test]
    procedure Y7409_ThreeLines_MiddleHidden()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GoToRecord 2 (hidden)', Go('2', 2, true));
        Observer.Observe('GoToKey 2 (hidden)', Go('2', 2, false));
        Observer.Observe('GoToRecord 3 (shown)', Go('2', 3, true));
        Observer.Observe('GoToKey 3 (shown)', Go('2', 3, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y7409_ThreeLines_FirstHidden()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GoToRecord 1 (hidden first)', Go('1', 1, true));
        Observer.Observe('GoToKey 1 (hidden first)', Go('1', 1, false));
        Observer.Observe('GoToRecord 2 (shown)', Go('1', 2, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y7409_ThreeLines_LastHidden()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GoToRecord 3 (hidden last)', Go('3', 3, true));
        Observer.Observe('GoToKey 3 (hidden last)', Go('3', 3, false));
        Observer.Observe('GoToRecord 2 (shown)', Go('3', 2, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y7409_ThreeLines_TwoHidden_And_NoneHidden()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GoToRecord 2, rows 1 and 2 hidden', Go('1|2', 2, true));
        Observer.Observe('GoToRecord 3, rows 1 and 2 hidden', Go('1|2', 3, true));
        Observer.Observe('GoToRecord 2, none hidden', Go('', 2, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y7409_SourceTableView_LeavesRowOut()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Plan View List";
        Found: Boolean;
        Ok: Boolean;
    begin
        Seed('');
        P.OpenView();
        ClearLastError();
        Ok := TryViewRecord(P, 3, Found);
        Observer.Observe('GoToRecord 3 outside SourceTableView', Reading(Ok, Found) + ' now=' + P."No.".Value());
        ClearLastError();
        Ok := TryViewKey(P, 3, Found);
        Observer.Observe('GoToKey 3 outside SourceTableView', Reading(Ok, Found) + ' now=' + P."No.".Value());
        ClearLastError();
        Ok := TryViewKey(P, 2, Found);
        Observer.Observe('GoToKey 2 inside SourceTableView', Reading(Ok, Found) + ' now=' + P."No.".Value());
        Observer.Finish();
    end;

    [Test]
    procedure Y7409_FindOnlyPage_And_NextOnlyPage_And_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        F: TestPage "LT K12 Plan Find Only";
        N: TestPage "LT K12 Plan Afterget";
        E: TestPage "LT K12 Plan List";
        Line: Record "LT K12 Plan Line";
        Found: Boolean;
    begin
        Seed('2');
        Line.Get(2);
        F.OpenView();
        Observer.Observe('find-only page: GoToKey of the hidden row', FindOnlyKey(F, 2));
        Observer.Observe('find-only page: GoToKey of a shown row', FindOnlyKey(F, 3));
        N.OpenView();
        Found := N.GoToRecord(Line);
        Observer.Observe('next-only page (shows every row): GoToRecord of row 2', Format(Found) + ' now=' + N."No.".Value());
        E.OpenEdit();
        ClearLastError();
        Observer.Observe('OpenEdit: GoToRecord of the hidden row', Reading(TryRecord(E, 2, Found), Found));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryFindOnlyKey(var P: TestPage "LT K12 Plan Find Only"; RowNo: Integer; var Found: Boolean)
    begin
        Found := P.GoToKey(RowNo);
    end;

    local procedure FindOnlyKey(var P: TestPage "LT K12 Plan Find Only"; RowNo: Integer): Text
    var
        Found: Boolean;
    begin
        ClearLastError();
        exit(Reading(TryFindOnlyKey(P, RowNo, Found), Found));
    end;
}
