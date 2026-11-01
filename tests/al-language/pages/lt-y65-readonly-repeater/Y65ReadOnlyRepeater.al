// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-next-method
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); table 93346, pages 93359-93365, test codeunit 93346
// Probe (al-runner issue 6674; the implicit new-row line of an editable list, a page with Editable = false and InsertAllowed = false is
//   handlers/TestPageModalNewRowLine_Tests.al and handlers/TestPageLastNewRowLine_Tests.al): does a list whose REPEATER says Editable
//   (false, a page variable that is false, a page variable that is true) show the blank new-row line? Next() past the last row, Last(),
//   First() on an empty table, the Editable() of a field, New(), for a List, a Worksheet, a List whose fields are all Editable = false,
//   a ListPart in a Card, OpenEdit and OpenView, and the reporter's Page.Run with a PageHandler.
// BC versions: 27, 28, 29

table 93346 "LT Y65 RO Task"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 93359 "LT Y65 RO List"
{
    PageType = List;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 93360 "LT Y65 RO List VarFalse"
{
    PageType = List;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = RowsEditable;
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    var
        RowsEditable: Boolean;
}

page 93361 "LT Y65 RO List VarTrue"
{
    PageType = List;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = RowsEditable;
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    var
        RowsEditable: Boolean;

    trigger OnInit()
    begin
        RowsEditable := true;
    end;
}

page 93362 "LT Y65 RO List Fields"
{
    PageType = List;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field(Description; Rec.Description) { ApplicationArea = All; Editable = false; }
            }
        }
    }
}

page 93363 "LT Y65 RO Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 93364 "LT Y65 RO ListPart"
{
    PageType = ListPart;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 93365 "LT Y65 RO Host"
{
    PageType = Card;
    SourceTable = "LT Y65 RO Task";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            part(Tasks; "LT Y65 RO ListPart") { ApplicationArea = All; }
        }
    }
}

codeunit 93346 "LT Y65 RO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(Rows: Integer)
    var
        Task: Record "LT Y65 RO Task";
        I: Integer;
    begin
        Task.DeleteAll();
        for I := 1 to Rows do begin
            Task."Entry No." := I;
            if I = 1 then
                Task.Description := 'First'
            else
                Task.Description := 'Second';
            Task.Insert();
        end;
    end;

    local procedure Count(): Text
    var
        Task: Record "LT Y65 RO Task";
    begin
        exit(Format(Task.Count()));
    end;

    [TryFunction]
    local procedure TryNewList(var P: TestPage "LT Y65 RO List")
    begin
        P.New();
    end;

    local procedure WalkList(View: Boolean): Text
    var
        P: TestPage "LT Y65 RO List";
        R: Text;
    begin
        if View then
            P.OpenView()
        else
            P.OpenEdit();
        R := 'open=' + P.Description.Value();
        R += ' first=' + Format(P.First()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value() + ':' + P."Entry No.".Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' last=' + Format(P.Last()) + ':' + P.Description.Value();
        R += ' prev=' + Format(P.Previous()) + ':' + P.Description.Value();
        R += ' editable=' + Format(P.Description.Editable()) + '/' + Format(P.Editable());
        ClearLastError();
        if TryNewList(P) then
            R += ' new=ok:' + P.Description.Value()
        else
            R += ' new=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        P.Close();
        exit(R + ' rows=' + Count());
    end;

    [Test]
    procedure Y65_RO_List()
    begin
        Seed(2);
        Observer.Observe('edit two rows', WalkList(false));
        Seed(2);
        Observer.Observe('view two rows', WalkList(true));
        Seed(0);
        Observer.Observe('edit empty', WalkList(false));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNewListVarFalse(var P: TestPage "LT Y65 RO List VarFalse")
    begin
        P.New();
    end;

    local procedure WalkListVarFalse(View: Boolean): Text
    var
        P: TestPage "LT Y65 RO List VarFalse";
        R: Text;
    begin
        if View then
            P.OpenView()
        else
            P.OpenEdit();
        R := 'open=' + P.Description.Value();
        R += ' first=' + Format(P.First()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value() + ':' + P."Entry No.".Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' last=' + Format(P.Last()) + ':' + P.Description.Value();
        R += ' prev=' + Format(P.Previous()) + ':' + P.Description.Value();
        R += ' editable=' + Format(P.Description.Editable()) + '/' + Format(P.Editable());
        ClearLastError();
        if TryNewListVarFalse(P) then
            R += ' new=ok:' + P.Description.Value()
        else
            R += ' new=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        P.Close();
        exit(R + ' rows=' + Count());
    end;

    [Test]
    procedure Y65_RO_ListVarFalse()
    begin
        Seed(2);
        Observer.Observe('edit two rows', WalkListVarFalse(false));
        Seed(2);
        Observer.Observe('view two rows', WalkListVarFalse(true));
        Seed(0);
        Observer.Observe('edit empty', WalkListVarFalse(false));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNewListVarTrue(var P: TestPage "LT Y65 RO List VarTrue")
    begin
        P.New();
    end;

    local procedure WalkListVarTrue(View: Boolean): Text
    var
        P: TestPage "LT Y65 RO List VarTrue";
        R: Text;
    begin
        if View then
            P.OpenView()
        else
            P.OpenEdit();
        R := 'open=' + P.Description.Value();
        R += ' first=' + Format(P.First()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value() + ':' + P."Entry No.".Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' last=' + Format(P.Last()) + ':' + P.Description.Value();
        R += ' prev=' + Format(P.Previous()) + ':' + P.Description.Value();
        R += ' editable=' + Format(P.Description.Editable()) + '/' + Format(P.Editable());
        ClearLastError();
        if TryNewListVarTrue(P) then
            R += ' new=ok:' + P.Description.Value()
        else
            R += ' new=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        P.Close();
        exit(R + ' rows=' + Count());
    end;

    [Test]
    procedure Y65_RO_ListVarTrue()
    begin
        Seed(2);
        Observer.Observe('edit two rows', WalkListVarTrue(false));
        Seed(2);
        Observer.Observe('view two rows', WalkListVarTrue(true));
        Seed(0);
        Observer.Observe('edit empty', WalkListVarTrue(false));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNewListFields(var P: TestPage "LT Y65 RO List Fields")
    begin
        P.New();
    end;

    local procedure WalkListFields(View: Boolean): Text
    var
        P: TestPage "LT Y65 RO List Fields";
        R: Text;
    begin
        if View then
            P.OpenView()
        else
            P.OpenEdit();
        R := 'open=' + P.Description.Value();
        R += ' first=' + Format(P.First()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value() + ':' + P."Entry No.".Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' last=' + Format(P.Last()) + ':' + P.Description.Value();
        R += ' prev=' + Format(P.Previous()) + ':' + P.Description.Value();
        R += ' editable=' + Format(P.Description.Editable()) + '/' + Format(P.Editable());
        ClearLastError();
        if TryNewListFields(P) then
            R += ' new=ok:' + P.Description.Value()
        else
            R += ' new=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        P.Close();
        exit(R + ' rows=' + Count());
    end;

    [Test]
    procedure Y65_RO_ListFields()
    begin
        Seed(2);
        Observer.Observe('edit two rows', WalkListFields(false));
        Seed(2);
        Observer.Observe('view two rows', WalkListFields(true));
        Seed(0);
        Observer.Observe('edit empty', WalkListFields(false));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNewWorksheet(var P: TestPage "LT Y65 RO Worksheet")
    begin
        P.New();
    end;

    local procedure WalkWorksheet(View: Boolean): Text
    var
        P: TestPage "LT Y65 RO Worksheet";
        R: Text;
    begin
        if View then
            P.OpenView()
        else
            P.OpenEdit();
        R := 'open=' + P.Description.Value();
        R += ' first=' + Format(P.First()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value() + ':' + P."Entry No.".Value();
        R += ' next=' + Format(P.Next()) + ':' + P.Description.Value();
        R += ' last=' + Format(P.Last()) + ':' + P.Description.Value();
        R += ' prev=' + Format(P.Previous()) + ':' + P.Description.Value();
        R += ' editable=' + Format(P.Description.Editable()) + '/' + Format(P.Editable());
        ClearLastError();
        if TryNewWorksheet(P) then
            R += ' new=ok:' + P.Description.Value()
        else
            R += ' new=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        P.Close();
        exit(R + ' rows=' + Count());
    end;

    [Test]
    procedure Y65_RO_Worksheet()
    begin
        Seed(2);
        Observer.Observe('edit two rows', WalkWorksheet(false));
        Seed(2);
        Observer.Observe('view two rows', WalkWorksheet(true));
        Seed(0);
        Observer.Observe('edit empty', WalkWorksheet(false));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_RO_ListPartInCard()
    var
        Host: TestPage "LT Y65 RO Host";
        R: Text;
    begin
        Seed(2);
        Host.OpenEdit();
        R := 'open=' + Host.Tasks.Description.Value();
        R += ' first=' + Format(Host.Tasks.First()) + ':' + Host.Tasks.Description.Value();
        R += ' next=' + Format(Host.Tasks.Next()) + ':' + Host.Tasks.Description.Value();
        R += ' next=' + Format(Host.Tasks.Next()) + ':' + Host.Tasks.Description.Value();
        R += ' last=' + Format(Host.Tasks.Last()) + ':' + Host.Tasks.Description.Value();
        R += ' editable=' + Format(Host.Tasks.Description.Editable()) + '/' + Format(Host.Tasks.Editable());
        Host.Close();
        Observer.Observe('part', R);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TaskListHandler')]
    procedure Y65_RO_Reporter_PageRun()
    begin
        // al-runner issue 6674, the reporter's shape.
        Seed(2);
        Page.Run(Page::"LT Y65 RO List");
        Observer.Finish();
    end;

    [PageHandler]
    procedure TaskListHandler(var TaskList: TestPage "LT Y65 RO List")
    var
        R: Text;
    begin
        R := 'open=' + TaskList.Description.Value();
        R += ' next=' + Format(TaskList.Next()) + ':' + TaskList.Description.Value();
        R += ' next=' + Format(TaskList.Next()) + ':' + TaskList.Description.Value();
        Observer.Observe('handler', R);
    end;
}
