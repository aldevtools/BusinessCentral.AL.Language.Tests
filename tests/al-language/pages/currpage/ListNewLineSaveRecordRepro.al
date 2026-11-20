// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// local object: the table field's OnValidate that inserts the page's new line, and the pages of the reporter's repro, are what is
//   under test
// Fixtures used: own table 97510, pages 97511 to 97514, opener codeunit 97515, test codeunit 97516
// Probe (al-runner issue 8285, the reporter's repro as filed, object names and ids changed only): ListNewLineSaveRecordUpdate.al
//   measures CurrPage.SaveRecord() then CurrPage.Update(false), and CurrPage.Update(true), on a List page's new line that the
//   table field's OnValidate inserted, on its own pages, whose code logs each step. This file keeps the repro's own pages and
//   table, whose code differs: no log, no ApplicationArea on the controls, a FactBox host whose OnAfterGetRecord counts rows.
//   Each page is opened with Page.RunModal on a record filtered to one group with one row before the new line; the handler
//   starts a new line, sets Name (the table field inserts the row, the control's OnValidate saves and refreshes), reads Name
//   back, sets Value and invokes OK. Readings: the Name the page shows after the refresh, and the rows the group holds after OK.
//   Measured on a local BC 29.1 OnPrem w1 container.
// BC versions: 27, 28, 29

table 97510 "LT NR Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[10]) { }
        field(2; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(3; Name; Text[30])
        {
            trigger OnValidate()
            begin
                if "Entry No." = 0 then
                    Insert(true);
            end;
        }
        field(4; Value; Text[30]) { }
    }

    keys
    {
        key(PK; "Group Code", "Entry No.") { Clustered = true; }
    }
}

page 97511 "LT NR Line FactBox"
{
    PageType = CardPart;
    SourceTable = "LT NR Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { }
        }
    }
}

page 97512 "LT NR Lines With FactBox"
{
    PageType = List;
    SourceTable = "LT NR Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
                }
                field(Value; Rec.Value) { }
            }
        }
        area(FactBoxes)
        {
            part(LineFactBox; "LT NR Line FactBox")
            {
                SubPageLink = "Group Code" = field("Group Code"), "Entry No." = field("Entry No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RowsRead += 1;
    end;

    var
        RowsRead: Integer;
}

page 97513 "LT NR Lines Save Update"
{
    PageType = List;
    SourceTable = "LT NR Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
                }
                field(Value; Rec.Value) { }
            }
        }
    }
}

page 97514 "LT NR Lines Update True"
{
    PageType = List;
    SourceTable = "LT NR Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Value; Rec.Value) { }
            }
        }
    }
}

codeunit 97515 "LT NR Opener"
{
    procedure Open(PageId: Integer; GroupCode: Code[10])
    var
        Line: Record "LT NR Line";
    begin
        Line.SetRange("Group Code", GroupCode);
        Page.RunModal(PageId, Line);
    end;
}

codeunit 97516 "LT NR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        NameShownAfterUpdate: Text;

    [Test]
    [HandlerFunctions('WithFactBoxHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ListNewLineRepro_SaveRecordUpdateFalse_WithFactBox_ShowsAndSavesTheLine()
    begin
        RunWithOneRow(Page::"LT NR Lines With FactBox", 'G1');
    end;

    [Test]
    [HandlerFunctions('SaveUpdateHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ListNewLineRepro_SaveRecordUpdateFalse_WithoutParts_ShowsAndSavesTheLine()
    begin
        RunWithOneRow(Page::"LT NR Lines Save Update", 'G2');
    end;

    [Test]
    [HandlerFunctions('UpdateTrueHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ListNewLineRepro_UpdateTrue_WithoutParts_ShowsAndSavesTheLine()
    begin
        RunWithOneRow(Page::"LT NR Lines Update True", 'G3');
    end;

    // One row 'A' in the group before the new line; after OK the group holds 'A' with no Value and the new line 'X' with Value 'V'.
    local procedure RunWithOneRow(PageId: Integer; GroupCode: Code[10])
    var
        Line: Record "LT NR Line";
        Opener: Codeunit "LT NR Opener";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Group Code" := GroupCode;
        Line.Name := 'A';
        Line.Insert(true);
        Commit();
        NameShownAfterUpdate := '';

        Opener.Open(PageId, GroupCode);

        Line.Reset();
        Line.SetRange("Group Code", GroupCode);
        Assert.AreEqual(2, Line.Count(), 'rows in the group');
        Line.SetRange(Name, 'X');
        Assert.IsTrue(Line.FindFirst(), 'the new line X is stored');
        Assert.AreEqual('V', Line.Value, 'Value of the new line');
        Line.SetRange(Name, 'A');
        Line.FindFirst();
        Assert.AreEqual('', Line.Value, 'Value of the row before');
        Assert.AreEqual('X', NameShownAfterUpdate, 'Name the page shows after the refresh');
    end;

    [ModalPageHandler]
    procedure WithFactBoxHandler(var Lines: TestPage "LT NR Lines With FactBox")
    begin
        Lines.New();
        Lines.Name.SetValue('X');
        NameShownAfterUpdate := Lines.Name.Value();
        Lines.Value.SetValue('V');
        Lines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SaveUpdateHandler(var Lines: TestPage "LT NR Lines Save Update")
    begin
        Lines.New();
        Lines.Name.SetValue('X');
        NameShownAfterUpdate := Lines.Name.Value();
        Lines.Value.SetValue('V');
        Lines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure UpdateTrueHandler(var Lines: TestPage "LT NR Lines Update True")
    begin
        Lines.New();
        Lines.Name.SetValue('X');
        NameShownAfterUpdate := Lines.Name.Value();
        Lines.Value.SetValue('V');
        Lines.OK().Invoke();
    end;
}
