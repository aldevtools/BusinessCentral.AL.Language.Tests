// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 88077-88078, pages 88143-88145, test codeunit 88094
// Probe: written against BC on the corpus CI matrix and local BC 27.5, 28.5 and 29.0; every literal asserted below is what that tier produced.
// Facts: an empty AutoSplitKey + DelayedInsert list; an action inserts lines 10000 and 20000 into the table, calls
//   CurrPage.Update(false) (or Update(true), or nothing) and positions Rec (FindSet, FindFirst, FindLast, Get, or not at all); then TestPage.New(),
//   SetValue and Close (runner issue 8344: the reporter measured line 15000 after FindSet). Worksheet and List; a test that only reads after the
//   action; a journal-shaped page (key Batch + Line No., OnValidate calls CurrPage.Update()). The table rows after Close and the control values.
// BC versions: all (CI)

table 88077 "TPL Split Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }
}

table 88078 "TPL Split Jnl Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Batch; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Name; Text[50]) { }
    }

    keys { key(PK; Batch, "Line No.") { Clustered = true; } }
}

page 88143 "TPL Split Worksheet"
{
    PageType = Worksheet;
    SourceTable = "TPL Split Row";
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
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Load_NoPosition_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    
                end;
            }
            action(Load_FindSet_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
            action(Load_FindFirst_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.FindFirst();
                end;
            }
            action(Load_FindLast_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.FindLast();
                end;
            }
            action(Load_Get10000_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.Get(10000);
                end;
            }
            action(Load_Get20000_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.Get(20000);
                end;
            }
            action(Load_FindSet_UpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(true);
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
            action(Load_FindSet_NoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
        }
    }

    local procedure LoadLines()
    var
        NewLine: Record "TPL Split Row";
    begin
        NewLine."Line No." := 10000;
        NewLine.Name := 'Loaded 1';
        NewLine.Insert();
        NewLine."Line No." := 20000;
        NewLine.Name := 'Loaded 2';
        NewLine.Insert();
    end;
}

page 88144 "TPL Split List"
{
    PageType = List;
    SourceTable = "TPL Split Row";
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
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Load_NoPosition_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    
                end;
            }
            action(Load_FindSet_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
            action(Load_FindFirst_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.FindFirst();
                end;
            }
            action(Load_FindLast_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.FindLast();
                end;
            }
            action(Load_Get10000_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.Get(10000);
                end;
            }
            action(Load_Get20000_UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(false);
                    Rec.Get(20000);
                end;
            }
            action(Load_FindSet_UpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    CurrPage.Update(true);
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
            action(Load_FindSet_NoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadLines();
                    
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
        }
    }

    local procedure LoadLines()
    var
        NewLine: Record "TPL Split Row";
    begin
        NewLine."Line No." := 10000;
        NewLine.Name := 'Loaded 1';
        NewLine.Insert();
        NewLine."Line No." := 20000;
        NewLine.Name := 'Loaded 2';
        NewLine.Insert();
    end;
}

page 88145 "TPL Split Jnl"
{
    PageType = Worksheet;
    SourceTable = "TPL Split Jnl Row";
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
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadLines)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    NewLine: Record "TPL Split Jnl Row";
                begin
                    NewLine.Batch := 'B1';
                    NewLine."Line No." := 10000;
                    NewLine.Name := 'Loaded 1';
                    NewLine.Insert();
                    NewLine."Line No." := 20000;
                    NewLine.Name := 'Loaded 2';
                    NewLine.Insert();
                    CurrPage.Update(false);
                    if not Rec.IsEmpty() then
                        Rec.FindSet();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Batch, 'B1');
        Rec.FilterGroup(0);
    end;
}

codeunit 88094 "TPL Split Key After Action"
{
    Subtype = Test;

    [Test]
    procedure Worksheet_Load_NoPosition_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_NoPosition_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_FindSet_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_FindFirst_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindFirst_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_FindLast_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindLast_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_Get10000_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_Get10000_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_Get20000_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_Get20000_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_FindSet_UpdateTrue_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_UpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_FindSet_NoUpdate_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_NoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Load_FindSet_UpdateFalse_ReadOnly()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Worksheet";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        Observer.Observe('first', Format(P.First()) + ' ' + P.LineNo.Value());
        Observer.Observe('next', Format(P.Next()) + ' ' + P.LineNo.Value());
        Observer.Observe('nextAgain', Format(P.Next()) + ' ' + P.LineNo.Value());
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_NoPosition_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_NoPosition_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_FindSet_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_FindFirst_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindFirst_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_FindLast_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindLast_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_Get10000_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_Get10000_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_Get20000_UpdateFalse_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_Get20000_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_FindSet_UpdateTrue_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_UpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_FindSet_NoUpdate_New()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_NoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure List_Load_FindSet_UpdateFalse_ReadOnly()
    var
        Row: Record "TPL Split Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split List";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.Load_FindSet_UpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        Observer.Observe('first', Format(P.First()) + ' ' + P.LineNo.Value());
        Observer.Observe('next', Format(P.Next()) + ' ' + P.LineNo.Value());
        Observer.Observe('nextAgain', Format(P.Next()) + ' ' + P.LineNo.Value());
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Journal_Load_FindSet_New_OnValidateUpdate()
    var
        Row: Record "TPL Split Jnl Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Split Jnl";
    begin
        Row.DeleteAll();
        P.OpenEdit();
        P.LoadLines.Invoke();
        Observer.Observe('current', P.LineNo.Value() + ' ' + P.NameF.Value());
        P.New();
        P.NameF.SetValue('Manual');
        P.Close();
        Observer.Observe('rows', JnlRows());
        Observer.Finish();
    end;

    local procedure Rows() Result: Text
    var
        Row: Record "TPL Split Row";
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row."Line No.") + ':' + Row.Name + '|';
            until Row.Next() = 0;
    end;

    local procedure JnlRows() Result: Text
    var
        Row: Record "TPL Split Jnl Row";
    begin
        if Row.FindSet() then
            repeat
                Result += Row.Batch + '/' + Format(Row."Line No.") + ':' + Row.Name + '|';
            until Row.Next() = 0;
    end;
}
