// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-expand-method
// Scope: in-scope
// Fixtures used: own objects 90159 - 90162 (writer TW); Assert (60021)
// Probe: al-runner issue 6119 (reporter's real-BC 29.0 run, 3/3 green), objects renamed. A List page over a TableType = Temporary table,
//   Editable = false, SourceTableView = sorting(Id); the repeater has ShowAsTree, IndentationColumn = Rec.Indentation,
//   IndentationControls = Kind, TreeInitialState = ExpandAll. OnOpenPage inserts 1 ROOT1 (level 0), 2 PARENT (0), 3 CHILD (1), 4 ROOT2 (0).
//   OnAfterGetRecord sets the global RowLabel := 'L' + Id (a column) and logs R<Id>; OnAfterGetCurrRecord logs C<Id>.
//   Each step reads <Id>/<Kind>/<RowLabel>:<trigger log since the last step>; T/F = what Next() returned.
// Facts: Expand(true) and Expand(false) run no row trigger and keep the current row and its RowLabel. After Expand(true) on row 2, Next()
//   lands on the child row 3 (R3;R3;C3). After Expand(false) on row 2, Next() skips the hidden child and lands on row 4; the next Next()
//   returns false and runs nothing. A ModalPageHandler on Page.RunModal gives the same log as OpenView.
// Neighbours: P82TestPage.al (Expand on a tree page without row triggers).
// BC versions: 27, 28, 29

table 90159 "LT TW Tree Row"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Code[20]) { }
        field(3; Indentation; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 90160 "LT TW Tree Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 90161 "LT TW Tree List"
{
    PageType = List;
    SourceTable = "LT TW Tree Row";
    SourceTableView = sorting(Id);
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Kind;
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field(Id; Rec.Id) { }
                field(Kind; Rec.Kind) { }
                field(RowLabel; RowLabel) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        AddRow(1, 'ROOT1', 0);
        AddRow(2, 'PARENT', 0);
        AddRow(3, 'CHILD', 1);
        AddRow(4, 'ROOT2', 0);
    end;

    trigger OnAfterGetRecord()
    begin
        RowLabel := 'L' + Format(Rec.Id);
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    local procedure AddRow(NewId: Integer; NewKind: Code[20]; NewIndentation: Integer)
    begin
        Rec.Init();
        Rec.Id := NewId;
        Rec.Kind := NewKind;
        Rec.Indentation := NewIndentation;
        Rec.Insert();
    end;

    var
        Log: Codeunit "LT TW Tree Log";
        RowLabel: Text;
}

codeunit 90162 "LT TW Tree Expand Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Log: Codeunit "LT TW Tree Log";
        HandlerObserved: Text;

    [Test]
    procedure ExpandRowWithChildThenWalk()
    var
        P: TestPage "LT TW Tree List";
        Observed: Text;
    begin
        Log.Take();
        P.OpenView();
        Observed := 'open=' + Row(P);
        Observed += ' ' + Walk(P);
        P.Close();
        Assert.AreEqual('open=4/ROOT2/L4:R4;R3;R2;R1;R4;R4;C4; first=1/ROOT1/L1:R1;R1;C1; next=T/2/PARENT/L2:R2;R2;C2; expand=2/PARENT/L2: next=T/3/CHILD/L3:R3;R3;C3; next=T/4/ROOT2/L4:R4;R4;C4; end=F/4/ROOT2/L4:', Observed, 'Expand(true) on a row with a child, then Next to the end.');
    end;

    [Test]
    procedure ExpandThenCollapse()
    var
        P: TestPage "LT TW Tree List";
        Observed: Text;
    begin
        Log.Take();
        P.OpenView();
        Observed := 'open=' + Row(P);
        P.First();
        Observed += ' first=' + Row(P);
        P.Next();
        Observed += ' next=' + Row(P);
        P.Expand(true);
        Observed += ' expand=' + Row(P);
        P.Next();
        Observed += ' next=' + Row(P);
        P.Previous();
        Observed += ' previous=' + Row(P);
        P.Expand(false);
        Observed += ' collapse=' + Row(P);
        P.Next();
        Observed += ' next=' + Row(P);
        Observed += ' end=' + B(P.Next()) + '/' + Row(P);
        P.Close();
        Assert.AreEqual('open=4/ROOT2/L4:R4;R3;R2;R1;R4;R4;C4; first=1/ROOT1/L1:R1;R1;C1; next=2/PARENT/L2:R2;R2;C2; expand=2/PARENT/L2: next=3/CHILD/L3:R3;R3;C3; previous=2/PARENT/L2:R2;R2;C2; collapse=2/PARENT/L2: next=4/ROOT2/L4:R4;R4;C4; end=F/4/ROOT2/L4:', Observed, 'Expand(true), then Expand(false), then Next.');
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure ExpandInModalHandler()
    begin
        Log.Take();
        HandlerObserved := '';
        Page.RunModal(Page::"LT TW Tree List");
        Assert.AreEqual('open=4/ROOT2/L4:R4;R3;R2;R1;R4;R4;C4; first=1/ROOT1/L1:R1;R1;C1; next=T/2/PARENT/L2:R2;R2;C2; expand=2/PARENT/L2: next=T/3/CHILD/L3:R3;R3;C3; next=T/4/ROOT2/L4:R4;R4;C4; end=F/4/ROOT2/L4:', HandlerObserved, 'Expand(true) inside a ModalPageHandler, then Next to the end.');
    end;

    [ModalPageHandler]
    procedure WalkHandler(var P: TestPage "LT TW Tree List")
    begin
        HandlerObserved := 'open=' + Row(P);
        HandlerObserved += ' ' + Walk(P);
    end;

    local procedure Walk(var P: TestPage "LT TW Tree List") Observed: Text
    begin
        P.First();
        Observed := 'first=' + Row(P);
        Observed += ' next=' + B(P.Next()) + '/' + Row(P);
        P.Expand(true);
        Observed += ' expand=' + Row(P);
        Observed += ' next=' + B(P.Next()) + '/' + Row(P);
        Observed += ' next=' + B(P.Next()) + '/' + Row(P);
        Observed += ' end=' + B(P.Next()) + '/' + Row(P);
    end;

    local procedure B(Value: Boolean): Text
    begin
        if Value then
            exit('T');
        exit('F');
    end;

    local procedure Row(var P: TestPage "LT TW Tree List"): Text
    begin
        exit(P.Id.Value() + '/' + P.Kind.Value() + '/' + P.RowLabel.Value() + ':' + Log.Take());
    end;
}
