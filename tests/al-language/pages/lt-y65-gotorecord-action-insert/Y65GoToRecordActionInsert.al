// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// Fixtures used: Probe Observer (codeunit 69160); table 93344, pages 93351-93355, test codeunit 93344
// Probe (al-runner issue 6671): a page is open on row B; an action inserts row A (before the current row) or C (after it) with
//   CurrPage.Update(), CurrPage.Update(false) or no update; then TestPage.GoToRecord of the new row. Also the test itself inserts the row while
//   the page is open (no action). Pages: Worksheet with OnAfterGetRecord and OnAfterGetCurrRecord (the reporter's shape, empty triggers),
//   Worksheet with neither, with only one of them, and a List with both. Outcome: ok and the Description shown, or the error text and code.
// BC versions: 27, 28, 29

table 93344 "LT Y65 GTR Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    procedure AddRow(NewNo: Code[20])
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item."No." := NewNo;
        Item.Description := 'Inserted ' + NewNo;
        Item.Insert();
    end;
}

page 93351 "LT Y65 GTR Both"
{
    PageType = Worksheet;
    SourceTable = "LT Y65 GTR Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsAUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsAUpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update(false);
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsCUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('C');
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 93352 "LT Y65 GTR None"
{
    PageType = Worksheet;
    SourceTable = "LT Y65 GTR Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsAUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsAUpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update(false);
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsCUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('C');
                    CurrPage.Update();
                end;
            }
        }
    }
}

page 93353 "LT Y65 GTR GetRecord"
{
    PageType = Worksheet;
    SourceTable = "LT Y65 GTR Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsAUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsAUpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update(false);
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsCUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('C');
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;
}

page 93354 "LT Y65 GTR GetCurrRecord"
{
    PageType = Worksheet;
    SourceTable = "LT Y65 GTR Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsAUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsAUpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update(false);
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsCUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('C');
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 93355 "LT Y65 GTR List Both"
{
    PageType = List;
    SourceTable = "LT Y65 GTR Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsAUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsAUpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update(false);
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsCUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('C');
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

codeunit 93344 "LT Y65 GTR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item.DeleteAll();
        Item."No." := 'B';
        Item.Description := 'Existing';
        Item.Insert();
    end;

    local procedure Target(Mode: Integer): Code[20]
    begin
        if Mode = 4 then
            exit('C');
        exit('A');
    end;

    [TryFunction]
    local procedure TryGoBoth(var P: TestPage "LT Y65 GTR Both"; Mode: Integer)
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item.Get(Target(Mode));
        P.GoToRecord(Item);
    end;

    local procedure RunBoth(Mode: Integer): Text
    var
        Item: Record "LT Y65 GTR Item";
        P: TestPage "LT Y65 GTR Both";
        Shown: Text;
    begin
        Seed();
        P.OpenEdit();
        case Mode of
            1:
                P.InsAUpdate.Invoke();
            2:
                P.InsAUpdateFalse.Invoke();
            3:
                P.InsANoUpdate.Invoke();
            4:
                P.InsCUpdate.Invoke();
            5:
                Item.AddRow('A');
        end;
        Shown := 'on ' + P."No.".Value() + ' ';
        ClearLastError();
        if TryGoBoth(P, Mode) then
            Shown := 'ok:' + Shown + P.Description.Value()
        else
            Shown := Shown + '|error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + P."No.".Value();
        P.Close();
        exit(Shown);
    end;

    [TryFunction]
    local procedure TryGoNone(var P: TestPage "LT Y65 GTR None"; Mode: Integer)
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item.Get(Target(Mode));
        P.GoToRecord(Item);
    end;

    local procedure RunNone(Mode: Integer): Text
    var
        Item: Record "LT Y65 GTR Item";
        P: TestPage "LT Y65 GTR None";
        Shown: Text;
    begin
        Seed();
        P.OpenEdit();
        case Mode of
            1:
                P.InsAUpdate.Invoke();
            2:
                P.InsAUpdateFalse.Invoke();
            3:
                P.InsANoUpdate.Invoke();
            4:
                P.InsCUpdate.Invoke();
            5:
                Item.AddRow('A');
        end;
        Shown := 'on ' + P."No.".Value() + ' ';
        ClearLastError();
        if TryGoNone(P, Mode) then
            Shown := 'ok:' + Shown + P.Description.Value()
        else
            Shown := Shown + '|error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + P."No.".Value();
        P.Close();
        exit(Shown);
    end;

    [TryFunction]
    local procedure TryGoGetRecord(var P: TestPage "LT Y65 GTR GetRecord"; Mode: Integer)
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item.Get(Target(Mode));
        P.GoToRecord(Item);
    end;

    local procedure RunGetRecord(Mode: Integer): Text
    var
        Item: Record "LT Y65 GTR Item";
        P: TestPage "LT Y65 GTR GetRecord";
        Shown: Text;
    begin
        Seed();
        P.OpenEdit();
        case Mode of
            1:
                P.InsAUpdate.Invoke();
            2:
                P.InsAUpdateFalse.Invoke();
            3:
                P.InsANoUpdate.Invoke();
            4:
                P.InsCUpdate.Invoke();
            5:
                Item.AddRow('A');
        end;
        Shown := 'on ' + P."No.".Value() + ' ';
        ClearLastError();
        if TryGoGetRecord(P, Mode) then
            Shown := 'ok:' + Shown + P.Description.Value()
        else
            Shown := Shown + '|error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + P."No.".Value();
        P.Close();
        exit(Shown);
    end;

    [TryFunction]
    local procedure TryGoGetCurrRecord(var P: TestPage "LT Y65 GTR GetCurrRecord"; Mode: Integer)
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item.Get(Target(Mode));
        P.GoToRecord(Item);
    end;

    local procedure RunGetCurrRecord(Mode: Integer): Text
    var
        Item: Record "LT Y65 GTR Item";
        P: TestPage "LT Y65 GTR GetCurrRecord";
        Shown: Text;
    begin
        Seed();
        P.OpenEdit();
        case Mode of
            1:
                P.InsAUpdate.Invoke();
            2:
                P.InsAUpdateFalse.Invoke();
            3:
                P.InsANoUpdate.Invoke();
            4:
                P.InsCUpdate.Invoke();
            5:
                Item.AddRow('A');
        end;
        Shown := 'on ' + P."No.".Value() + ' ';
        ClearLastError();
        if TryGoGetCurrRecord(P, Mode) then
            Shown := 'ok:' + Shown + P.Description.Value()
        else
            Shown := Shown + '|error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + P."No.".Value();
        P.Close();
        exit(Shown);
    end;

    [TryFunction]
    local procedure TryGoListBoth(var P: TestPage "LT Y65 GTR List Both"; Mode: Integer)
    var
        Item: Record "LT Y65 GTR Item";
    begin
        Item.Get(Target(Mode));
        P.GoToRecord(Item);
    end;

    local procedure RunListBoth(Mode: Integer): Text
    var
        Item: Record "LT Y65 GTR Item";
        P: TestPage "LT Y65 GTR List Both";
        Shown: Text;
    begin
        Seed();
        P.OpenEdit();
        case Mode of
            1:
                P.InsAUpdate.Invoke();
            2:
                P.InsAUpdateFalse.Invoke();
            3:
                P.InsANoUpdate.Invoke();
            4:
                P.InsCUpdate.Invoke();
            5:
                Item.AddRow('A');
        end;
        Shown := 'on ' + P."No.".Value() + ' ';
        ClearLastError();
        if TryGoListBoth(P, Mode) then
            Shown := 'ok:' + Shown + P.Description.Value()
        else
            Shown := Shown + '|error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + P."No.".Value();
        P.Close();
        exit(Shown);
    end;

    [Test]
    procedure Y65_GoToRecord_Both()
    begin
        Observer.Observe('insert A, Update()', RunBoth(1));
        Observer.Observe('insert A, Update(false)', RunBoth(2));
        Observer.Observe('insert A, no Update', RunBoth(3));
        Observer.Observe('insert C, Update()', RunBoth(4));
        Observer.Observe('test inserts A, no action', RunBoth(5));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_GoToRecord_None()
    begin
        Observer.Observe('insert A, Update()', RunNone(1));
        Observer.Observe('insert A, Update(false)', RunNone(2));
        Observer.Observe('insert A, no Update', RunNone(3));
        Observer.Observe('insert C, Update()', RunNone(4));
        Observer.Observe('test inserts A, no action', RunNone(5));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_GoToRecord_GetRecord()
    begin
        Observer.Observe('insert A, Update()', RunGetRecord(1));
        Observer.Observe('insert A, Update(false)', RunGetRecord(2));
        Observer.Observe('insert A, no Update', RunGetRecord(3));
        Observer.Observe('insert C, Update()', RunGetRecord(4));
        Observer.Observe('test inserts A, no action', RunGetRecord(5));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_GoToRecord_GetCurrRecord()
    begin
        Observer.Observe('insert A, Update()', RunGetCurrRecord(1));
        Observer.Observe('insert A, Update(false)', RunGetCurrRecord(2));
        Observer.Observe('insert A, no Update', RunGetCurrRecord(3));
        Observer.Observe('insert C, Update()', RunGetCurrRecord(4));
        Observer.Observe('test inserts A, no action', RunGetCurrRecord(5));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_GoToRecord_ListBoth()
    begin
        Observer.Observe('insert A, Update()', RunListBoth(1));
        Observer.Observe('insert A, Update(false)', RunListBoth(2));
        Observer.Observe('insert A, no Update', RunListBoth(3));
        Observer.Observe('insert C, Update()', RunListBoth(4));
        Observer.Observe('test inserts A, no action', RunListBoth(5));
        Observer.Finish();
    end;
}
