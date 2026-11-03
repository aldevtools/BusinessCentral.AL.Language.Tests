// Probe: BelowxRec passed to OnNewRecord and OnInsertRecord of a list when the new row is not added at the end.
// Settles: md:377 (row added in the middle; the end case is pinned by handlers/TestPageRuntimeContracts.al:208).

table 68722 "W2 Below Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68723 "W2 Below Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 68724 "W2 Below List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Below Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "W2 Below Log";
    begin
        Log.Add('OnNewRecord(below=' + Format(BelowxRec) + ',xRec=' + Format(xRec.Id) + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "W2 Below Log";
    begin
        Log.Add('OnInsertRecord(below=' + Format(BelowxRec) + ',id=' + Format(Rec.Id) + ',xRec=' + Format(xRec.Id) + ')');
        exit(true);
    end;
}

codeunit 68725 "W2 Below Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "W2 Below Row";
        Log: Codeunit "W2 Below Log";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.Insert();
        Row.Id := 20;
        Row.Insert();
        Row.Id := 30;
        Row.Insert();
        Log.Take();
    end;

    local procedure Order(): Text
    var
        Row: Record "W2 Below Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure NewAtTheEnd_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Below Log";
        Pg: TestPage "W2 Below List";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Last();
        Log.Take();
        Pg.New();
        Observer.Observe('after_new', Log.Take());
        Pg.Id.SetValue(40);
        Observer.Observe('after_key', Log.Take());
        Pg.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Observe('rows', Order());
        Observer.Expect('after_new', 'OnNewRecord(below=Yes,xRec=30);');
        Observer.Expect('after_key', '');
        Observer.Expect('after_close', 'OnInsertRecord(below=Yes,id=40,xRec=30);');
        Observer.Expect('rows', '10,20,30,40,');
        Observer.Verify();
    end;

    [Test]
    procedure NewInTheMiddle_CursorOnFirstRow_KeyBetween()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Below Log";
        Pg: TestPage "W2 Below List";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(10);
        Log.Take();
        Pg.New();
        Observer.Observe('after_new', Log.Take());
        Pg.Id.SetValue(15);
        Observer.Observe('after_key', Log.Take());
        Pg.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Observe('rows', Order());
        Observer.Expect('after_new', 'OnNewRecord(below=Yes,xRec=30);');
        Observer.Expect('after_key', '');
        Observer.Expect('after_close', 'OnInsertRecord(below=Yes,id=15,xRec=10);');
        Observer.Expect('rows', '10,15,20,30,');
        Observer.Verify();
    end;

    [Test]
    procedure NewInTheMiddle_CursorOnMiddleRow_KeyBefore()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Below Log";
        Pg: TestPage "W2 Below List";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(20);
        Log.Take();
        Pg.New();
        Observer.Observe('after_new', Log.Take());
        Pg.Id.SetValue(5);
        Observer.Observe('after_key', Log.Take());
        Pg.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Observe('rows', Order());
        Observer.Expect('after_new', 'OnNewRecord(below=Yes,xRec=30);');
        Observer.Expect('after_key', '');
        Observer.Expect('after_close', 'OnInsertRecord(below=Yes,id=5,xRec=20);');
        Observer.Expect('rows', '5,10,20,30,');
        Observer.Verify();
    end;

    [Test]
    procedure NewInTheMiddle_SavedByMovingToAnotherRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Below Log";
        Pg: TestPage "W2 Below List";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(10);
        Pg.New();
        Pg.Id.SetValue(15);
        Log.Take();
        Pg.GoToKey(30);
        Observer.Observe('after_move', Log.Take());
        Pg.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Observe('rows', Order());
        Observer.Expect('after_move', 'OnInsertRecord(below=Yes,id=15,xRec=10);');
        Observer.Expect('after_close', '');
        Observer.Expect('rows', '10,15,20,30,');
        Observer.Verify();
    end;

    [Test]
    procedure NewTwice_InTheMiddle()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Below Log";
        Pg: TestPage "W2 Below List";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(10);
        Pg.New();
        Pg.Id.SetValue(12);
        Pg.New();
        Pg.Id.SetValue(14);
        Pg.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Observe('rows', Order());
        Observer.Expect('after_close', 'OnNewRecord(below=Yes,xRec=30);OnInsertRecord(below=Yes,id=12,xRec=10);OnNewRecord(below=Yes,xRec=30);OnInsertRecord(below=Yes,id=14,xRec=12);');
        Observer.Expect('rows', '10,12,14,20,30,');
        Observer.Verify();
    end;
}
