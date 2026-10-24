// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88620 - 88623 (writer RT)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a repeater control with Editable = <page variable> (and a second one with Enabled = <page variable>), the variable set in
//   OnAfterGetRecord from the row (true when "New Start" is blank). What TestPage <control>.Editable() and Enabled() answer after the
//   TestPage moves to another row: GoToRecord (both orders), GoToKey, Next, Previous, First, Last. A Worksheet (InsertAllowed = false,
//   DelayedInsert = true, sorted by "Sequence No.") opened with OpenEdit and OpenView, and a List opened with OpenEdit. The card case is
//   pinned in handlers/TestPageEditable_Tests.al (EditableBoundToPageVariable_FollowsTheRow).
//   Rows: A (Sequence No. 1, New Start set), B (Sequence No. 2, no New Start); the swapped data set: A without, B with New Start.
//   Each read is <row>:<Editable of Sequence No.>/<Enabled of Description>.
// Source: al-runner issue 5808.
// BC versions: 27, 28, 29

table 88620 "LT RT Ed Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Sequence No."; Integer) { }
        field(3; "New Start"; DateTime) { }
        field(4; Description; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(Seq; "Sequence No.") { }
    }
}

page 88621 "LT RT Ed Ws"
{
    PageType = Worksheet;
    SourceTable = "LT RT Ed Row";
    SourceTableView = sorting("Sequence No.");
    InsertAllowed = false;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(SeqCtl; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                    Editable = SequenceEditable;
                }
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description)
                {
                    ApplicationArea = All;
                    Enabled = SequenceEditable;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SequenceEditable := Rec."New Start" = 0DT;
    end;

    var
        SequenceEditable: Boolean;
}

page 88622 "LT RT Ed List"
{
    PageType = List;
    SourceTable = "LT RT Ed Row";
    SourceTableView = sorting("Sequence No.");
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(SeqCtl; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                    Editable = SequenceEditable;
                }
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description)
                {
                    ApplicationArea = All;
                    Enabled = SequenceEditable;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SequenceEditable := Rec."New Start" = 0DT;
    end;

    var
        SequenceEditable: Boolean;
}

codeunit 88623 "LT RT Ed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    // Swapped = false: A has a New Start (not editable), B has none. Swapped = true: the other way round.
    local procedure Seed(Swapped: Boolean)
    var
        Row: Record "LT RT Ed Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row."Sequence No." := 1;
        Row.Description := 'Alpha';
        if not Swapped then
            Row."New Start" := CreateDateTime(DMY2Date(1, 1, 2030), 080000T);
        Row.Insert();
        Clear(Row);
        Row."Code" := 'B';
        Row."Sequence No." := 2;
        Row.Description := 'Bravo';
        if Swapped then
            Row."New Start" := CreateDateTime(DMY2Date(1, 1, 2030), 080000T);
        Row.Insert();
    end;

    local procedure GetRow(RowCode: Code[20]) Row: Record "LT RT Ed Row"
    begin
        Row.Get(RowCode);
    end;

    local procedure ReadWs(var P: TestPage "LT RT Ed Ws"): Text
    begin
        exit(P.CodeCtl.Value() + ':' + Format(P.SeqCtl.Editable()) + '/' + Format(P.DescriptionCtl.Enabled()));
    end;

    local procedure ReadList(var P: TestPage "LT RT Ed List"): Text
    begin
        exit(P.CodeCtl.Value() + ':' + Format(P.SeqCtl.Editable()) + '/' + Format(P.DescriptionCtl.Enabled()));
    end;

    // The reporter's test: OpenEdit, GoToRecord A, then B.
    [Test]
    procedure RT_EdWs_OpenEdit_GoToRecord_AB()
    var
        P: TestPage "LT RT Ed Ws";
    begin
        Seed(false);
        P.OpenEdit();
        Observer.Observe('open', ReadWs(P));
        P.GoToRecord(GetRow('A'));
        Observer.Observe('A', ReadWs(P));
        P.GoToRecord(GetRow('B'));
        Observer.Observe('B', ReadWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RT_EdWs_OpenEdit_GoToRecord_BA()
    var
        P: TestPage "LT RT Ed Ws";
    begin
        Seed(false);
        P.OpenEdit();
        P.GoToRecord(GetRow('B'));
        Observer.Observe('B', ReadWs(P));
        P.GoToRecord(GetRow('A'));
        Observer.Observe('A', ReadWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RT_EdWs_OpenEdit_GoToRecord_Swapped_AB()
    var
        P: TestPage "LT RT Ed Ws";
    begin
        Seed(true);
        P.OpenEdit();
        Observer.Observe('open', ReadWs(P));
        P.GoToRecord(GetRow('A'));
        Observer.Observe('A', ReadWs(P));
        P.GoToRecord(GetRow('B'));
        Observer.Observe('B', ReadWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RT_EdWs_OpenEdit_GoToKey()
    var
        P: TestPage "LT RT Ed Ws";
    begin
        Seed(false);
        P.OpenEdit();
        Observer.Observe('goto B', Format(P.GoToKey('B')) + '|' + ReadWs(P));
        Observer.Observe('goto A', Format(P.GoToKey('A')) + '|' + ReadWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RT_EdWs_OpenEdit_NextPreviousFirstLast()
    var
        P: TestPage "LT RT Ed Ws";
    begin
        Seed(false);
        P.OpenEdit();
        Observer.Observe('open', ReadWs(P));
        Observer.Observe('next', Format(P.Next()) + '|' + ReadWs(P));
        Observer.Observe('previous', Format(P.Previous()) + '|' + ReadWs(P));
        Observer.Observe('last', Format(P.Last()) + '|' + ReadWs(P));
        Observer.Observe('first', Format(P.First()) + '|' + ReadWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RT_EdWs_OpenView_GoToRecord_AB()
    var
        P: TestPage "LT RT Ed Ws";
    begin
        Seed(false);
        P.OpenView();
        Observer.Observe('open', ReadWs(P));
        P.GoToRecord(GetRow('A'));
        Observer.Observe('A', ReadWs(P));
        P.GoToRecord(GetRow('B'));
        Observer.Observe('B', ReadWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RT_EdList_OpenEdit_GoToRecord_AB()
    var
        P: TestPage "LT RT Ed List";
    begin
        Seed(false);
        P.OpenEdit();
        Observer.Observe('open', ReadList(P));
        P.GoToRecord(GetRow('A'));
        Observer.Observe('A', ReadList(P));
        P.GoToRecord(GetRow('B'));
        Observer.Observe('B', ReadList(P));
        Observer.Observe('previous', Format(P.Previous()) + '|' + ReadList(P));
        P.Close();
        Observer.Finish();
    end;
}
