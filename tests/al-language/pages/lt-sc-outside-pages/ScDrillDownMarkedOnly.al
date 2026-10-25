// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-markedonly-method
// Scope: in-scope
// Fixtures used: own table 89010, pages 89011 to 89015, test codeunit 89016
// Probe: from al-runner issue 5844 (reporter's real-BC run on 29.0.54011.55407); every literal asserted below is what
//   BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Worksheet page (InsertAllowed and DeleteAllowed false) over a table with rows 10 and 20; a header field's
//   OnDrillDown does Rec.ClearMarks(), marks row 10, Rec.MarkedOnly(true) and CurrPage.Update(false). After
//   TestField.Drilldown(): the rows First/Next list and GoToRecord on row 20. Pages differ only in their (empty)
//   triggers: OnAfterGetRecord and OnAfterGetCurrRecord, neither, only OnAfterGetRecord, only OnAfterGetCurrRecord;
//   and one page with no triggers whose OnDrillDown does not call CurrPage.Update.
//   BC answers: with CurrPage.Update(false) every page lists only row 10 (the triggers make no difference);
//   without the Update the page still lists 10 and 20.
// BC versions: all (CI)

table 89010 "LT SC Operation"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Operation No."; Code[10]) { }
    }
    keys
    {
        key(PK; "Operation No.") { }
    }
}

page 89011 "LT SC Operations Both"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        MarkedCount: Integer;
}

page 89012 "LT SC Operations None"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    var
        MarkedCount: Integer;
}

page 89013 "LT SC Operations AGR"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        MarkedCount: Integer;
}

page 89014 "LT SC Operations AGCR"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        MarkedCount: Integer;
}

page 89015 "LT SC Operations No Update"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    var
        MarkedCount: Integer;
}

codeunit 89016 "LT SC Marked DrillDown Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // The reporter's four tests (issue 5844), with the object names of this file.

    [Test]
    procedure GoToRecordAfterDrilldownMissesTheUnmarkedRow()
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations Both";
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        if not Operations.GoToRecord(Operation20) then
            Error('Operation 20 is not listed before the drilldown.');
        Operations.MarkedCount.Drilldown();
        if Operations.GoToRecord(Operation20) then
            Error('Operation 20 is listed after the drilldown marked only operation 10.');
        Operations.Close();
    end;

    [Test]
    procedure ListAfterDrilldownShowsOnlyTheMarkedRow()
    var
        Operations: TestPage "LT SC Operations Both";
        Listed: Text;
    begin
        Setup();
        Operations.OpenEdit();
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        if Listed <> ' 10' then
            Error('Listed after the drilldown:%1', Listed);
        Operations.Close();
    end;

    [Test]
    procedure ControlWithoutTriggersShowsOnlyTheMarkedRow()
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations None";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        if Listed <> ' 10' then
            Error('Listed after the drilldown:%1', Listed);
        if Operations.GoToRecord(Operation20) then
            Error('Operation 20 is listed after the drilldown marked only operation 10.');
        Operations.Close();
    end;

    [Test]
    procedure OnAfterGetRecordOnlyListShowsOnlyTheMarkedRow()
    var
        Operations: TestPage "LT SC Operations AGR";
        Listed: Text;
    begin
        Setup();
        Operations.OpenEdit();
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        if Listed <> ' 10' then
            Error('Listed after the drilldown:%1', Listed);
        Operations.Close();
    end;

    // Neighbours: every page, the list and GoToRecord on row 20 in one test.

    [Test]
    procedure BothTriggersListAndGoTo()
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations Both";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Assert.IsTrue(Operations.GoToRecord(Operation20), 'Operation 20 is not listed before the drilldown.');
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Assert.AreEqual('listed=[ 10] goto20=No', 'listed=[' + Listed + '] goto20=' + Format(Operations.GoToRecord(Operation20)), 'rows after the drilldown');
        Operations.Close();
    end;

    [Test]
    procedure NoTriggersListAndGoTo()
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations None";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Assert.IsTrue(Operations.GoToRecord(Operation20), 'Operation 20 is not listed before the drilldown.');
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Assert.AreEqual('listed=[ 10] goto20=No', 'listed=[' + Listed + '] goto20=' + Format(Operations.GoToRecord(Operation20)), 'rows after the drilldown');
        Operations.Close();
    end;

    [Test]
    procedure OnAfterGetRecordOnlyListAndGoTo()
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations AGR";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Assert.IsTrue(Operations.GoToRecord(Operation20), 'Operation 20 is not listed before the drilldown.');
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Assert.AreEqual('listed=[ 10] goto20=No', 'listed=[' + Listed + '] goto20=' + Format(Operations.GoToRecord(Operation20)), 'rows after the drilldown');
        Operations.Close();
    end;

    [Test]
    procedure OnAfterGetCurrRecordOnlyListAndGoTo()
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations AGCR";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Assert.IsTrue(Operations.GoToRecord(Operation20), 'Operation 20 is not listed before the drilldown.');
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Assert.AreEqual('listed=[ 10] goto20=No', 'listed=[' + Listed + '] goto20=' + Format(Operations.GoToRecord(Operation20)), 'rows after the drilldown');
        Operations.Close();
    end;

    [Test]
    procedure DrilldownWithoutUpdateListAndGoTo()
    // BC: without CurrPage.Update the page keeps listing both rows after MarkedOnly(true) in OnDrillDown.
    var
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SC Operations No Update";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Assert.IsTrue(Operations.GoToRecord(Operation20), 'Operation 20 is not listed before the drilldown.');
        Operations.MarkedCount.Drilldown();
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Assert.AreEqual('listed=[ 10 20] goto20=Yes', 'listed=[' + Listed + '] goto20=' + Format(Operations.GoToRecord(Operation20)), 'rows after the drilldown');
        Operations.Close();
    end;

    local procedure Setup()
    var
        Operation: Record "LT SC Operation";
    begin
        Operation.DeleteAll();
        Operation."Operation No." := '10';
        Operation.Insert();
        Operation."Operation No." := '20';
        Operation.Insert();
    end;
}
