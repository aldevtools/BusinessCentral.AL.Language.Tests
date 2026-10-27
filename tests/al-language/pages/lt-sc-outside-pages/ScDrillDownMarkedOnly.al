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

    // ---- Writer SF, al-runner issue 5886 (follow-up to 5844): the same Worksheet with a part, a ListPart with a SubPageLink, in the
    // content area (page 89323) or in the FactBoxes area (page 89324), next to the page without a part (BothTriggersListAndGoTo above). Objects 89320 to 89324
    // at the end of this file.

    [Test]
    procedure SF_WithPart_ListAndGoTo()
    var
        Operation20: Record "LT SF Operation";
        Operations: TestPage "LT SF Ops With Part";
        Listed: Text;
    begin
        SfSetup();
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
    procedure SF_WithPart_GoToRecordMissesTheUnmarkedRow()
    var
        Operation20: Record "LT SF Operation";
        Operations: TestPage "LT SF Ops With Part";
    begin
        SfSetup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Operations.MarkedCount.Drilldown();
        Assert.IsFalse(Operations.GoToRecord(Operation20), 'Operation 20 is listed after the drilldown marked only operation 10.');
        Operations.Close();
    end;

    [Test]
    procedure SF_WithFactBox_ListAndGoTo()
    var
        Operation20: Record "LT SF Operation";
        Operations: TestPage "LT SF Ops With FactBox";
        Listed: Text;
    begin
        SfSetup();
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
    procedure SF_WithFactBox_GoToRecordMissesTheUnmarkedRow()
    var
        Operation20: Record "LT SF Operation";
        Operations: TestPage "LT SF Ops With FactBox";
    begin
        SfSetup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Operations.MarkedCount.Drilldown();
        Assert.IsFalse(Operations.GoToRecord(Operation20), 'Operation 20 is listed after the drilldown marked only operation 10.');
        Operations.Close();
    end;

    local procedure SfSetup()
    var
        Operation: Record "LT SF Operation";
        Component: Record "LT SF Component";
    begin
        Operation.DeleteAll();
        Component.DeleteAll();
        Operation."Operation No." := '10';
        Operation."Order No." := 'A';
        Operation.Insert();
        Operation."Operation No." := '20';
        Operation."Order No." := 'A';
        Operation.Insert();
        Component."Order No." := 'A';
        Component."Line No." := 10000;
        Component.Insert();
    end;
}

// Writer SF (al-runner issue 5886): the operation table with an order number, the component table, the ListPart and the three
// Worksheets of the SF_* tests in codeunit 89016.
table 89320 "LT SF Operation"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Operation No."; Code[10]) { }
        field(2; "Order No."; Code[20]) { }
    }
    keys
    {
        key(PK; "Operation No.") { }
    }
}

table 89321 "LT SF Component"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Order No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }
    keys
    {
        key(PK; "Order No.", "Line No.") { }
    }
}

page 89322 "LT SF Components Part"
{
    PageType = ListPart;
    SourceTable = "LT SF Component";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 89323 "LT SF Ops With Part"
{
    PageType = Worksheet;
    SourceTable = "LT SF Operation";
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
            part(Components; "LT SF Components Part")
            {
                ApplicationArea = All;
                SubPageLink = "Order No." = field("Order No.");
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

page 89324 "LT SF Ops With FactBox"
{
    PageType = Worksheet;
    SourceTable = "LT SF Operation";
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
        area(FactBoxes)
        {
            part(Components; "LT SF Components Part")
            {
                ApplicationArea = All;
                SubPageLink = "Order No." = field("Order No.");
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
