// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT R6877 Doc (pages/lt-th-part-update-cursor/R6877PartBothLaterRow.al); own objects
//   95974-95979 (PG R6889 *)
// local object: the part's actions and the Type control's OnValidate (CurrPage.Update(false)) are what the test checks
// Probe: from al-runner issue 6889 (follow-up of 6877): a ListPlus host with a ListPart (SubPageLink, with and without UpdatePropagation =
//   Both) over two lines. A part action inserts a line after the last one (from the last line, then Rec.Next()) or before the first one (from
//   the first line, then Rec.Next(-1)); contrasts: an action that only moves Rec to the next existing line, and the inserted line reached
//   again by Previous() and Next(). Then SetValue on Type (its OnValidate runs CurrPage.Update(false)) and on No. (its OnValidate logs the
//   Type it sees). Observed: the part's Line No. and Type after each SetValue, the trigger log (T.MOD, NoV(Type) of the table; R/C of the
//   part; HR/HC of the host) and the stored lines after Close.
// Result (BC 27.5, 28.5 and 29.0 alike): in this shape the typed Type is dropped on the line the action inserted and moved Rec to, as
//   on an existing line: after the SetValue the part shows Type Item on the same line, No.'s OnValidate sees Item, and the line is stored
//   with Type Item at Close. With Both the host reads first (HR;HC), then the part reads from its row back to the first and the row
//   twice; without Both the host is not read. After the action the part reads from the new row in the same way.
// BC versions: 27+ (tested by the corpus CI matrix)

table 95974 "PG R6889 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Type; Option)
        {
            OptionMembers = Item,Resource;
            InitValue = Item;
        }
        field(4; "No."; Code[20])
        {
            trigger OnValidate()
            var
                Log: Codeunit "PG R6889 Log";
            begin
                Log.Add('NoV(' + Format(Type) + ')');
            end;
        }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('T.MOD(' + Format("Line No." div 1000) + ':' + Format(Type) + '/' + "No." + ')');
    end;
}

page 95975 "PG R6889 Part"
{
    PageType = ListPart;
    SourceTable = "PG R6889 Line";
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG R6889 Log";
                    begin
                        Log.Add('TY.V');
                        CurrPage.Update(false);
                        Log.Add('TY.V.end');
                    end;
                }
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewLineAfter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Line: Record "PG R6889 Line";
                    Log: Codeunit "PG R6889 Log";
                begin
                    Log.Add('ACT');
                    Line.SetRange("Header No.", Rec."Header No.");
                    Line.FindLast();
                    Line."Line No." += 10000;
                    Line.Type := Line.Type::Item;
                    Line."No." := '';
                    Line.Insert();
                    Rec.Next();
                end;
            }
            action(NewLineBefore)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Line: Record "PG R6889 Line";
                    Log: Codeunit "PG R6889 Log";
                begin
                    Log.Add('ACT');
                    Line."Header No." := Rec."Header No.";
                    Line."Line No." := 5000;
                    Line.Insert();
                    Rec.Next(-1);
                end;
            }
            action(NextExisting)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "PG R6889 Log";
                begin
                    Log.Add('ACT');
                    Rec.Next();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 1000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 1000));
    end;
}

page 95976 "PG R6889 Both"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R6889 Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('HC');
    end;
}

page 95977 "PG R6889 Plain"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R6889 Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 Log";
    begin
        Log.Add('HC');
    end;
}

codeunit 95978 "PG R6889 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Head: Record "LT R6877 Doc";
        Line: Record "PG R6889 Line";
        Log: Codeunit "PG R6889 Log";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'D1';
        Head.Insert();
        Line."Header No." := 'D1';
        Line."Line No." := 10000;
        Line.Insert();
        Line."Line No." := 20000;
        Line.Insert();
        Log.Reset();
    end;

    local procedure ObserveStored(var Observer: Codeunit "Probe Observer")
    var
        Line: Record "PG R6889 Line";
        Rows: Text;
    begin
        if Line.FindSet() then
            repeat
                Rows += Format(Line."Line No.") + ':' + Format(Line.Type) + '/' + Line."No." + ' ';
            until Line.Next() = 0;
        Observer.Observe('stored', Rows);
    end;

    // Act: 1 = from the last line NewLineAfter (line 30000); 2 = from the first line NewLineBefore (line 5000); 3 = from the first line
    //   NextExisting (line 20000); 4 = as 1, then Previous() and Next().
    local procedure RunBoth(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "PG R6889 Both";
        Log: Codeunit "PG R6889 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        if Act in [1, 4] then
            P.Lines.Next();
        Log.Reset();
        case Act of
            1, 4:
                P.Lines.NewLineAfter.Invoke();
            2:
                P.Lines.NewLineBefore.Invoke();
            3:
                P.Lines.NextExisting.Invoke();
        end;
        Observer.Observe('line after action', P.Lines."Line No.".Value());
        Observer.Observe('log action', Log.Get());
        if Act = 4 then begin
            P.Lines.Previous();
            P.Lines.Next();
            Observer.Observe('line after prev next', P.Lines."Line No.".Value());
        end;
        Log.Reset();
        P.Lines.Type.SetValue('Resource');
        Observer.Observe('after type', P.Lines."Line No.".Value() + ' ' + P.Lines.Type.Value());
        Observer.Observe('log type', Log.Get());
        Log.Reset();
        P.Lines."No.".SetValue('R1');
        Observer.Observe('after no', P.Lines."Line No.".Value() + ' ' + P.Lines.Type.Value());
        Observer.Observe('log no', Log.Get());
        Log.Reset();
        P.Close();
        Observer.Observe('log close', Log.Get());
        ObserveStored(Observer);
    end;

    // Act: 1 = from the last line NewLineAfter (line 30000); 2 = from the first line NewLineBefore (line 5000); 3 = from the first line
    //   NextExisting (line 20000); 4 = as 1, then Previous() and Next().
    local procedure RunPlain(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "PG R6889 Plain";
        Log: Codeunit "PG R6889 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        if Act in [1, 4] then
            P.Lines.Next();
        Log.Reset();
        case Act of
            1, 4:
                P.Lines.NewLineAfter.Invoke();
            2:
                P.Lines.NewLineBefore.Invoke();
            3:
                P.Lines.NextExisting.Invoke();
        end;
        Observer.Observe('line after action', P.Lines."Line No.".Value());
        Observer.Observe('log action', Log.Get());
        if Act = 4 then begin
            P.Lines.Previous();
            P.Lines.Next();
            Observer.Observe('line after prev next', P.Lines."Line No.".Value());
        end;
        Log.Reset();
        P.Lines.Type.SetValue('Resource');
        Observer.Observe('after type', P.Lines."Line No.".Value() + ' ' + P.Lines.Type.Value());
        Observer.Observe('log type', Log.Get());
        Log.Reset();
        P.Lines."No.".SetValue('R1');
        Observer.Observe('after no', P.Lines."Line No.".Value() + ' ' + P.Lines.Type.Value());
        Observer.Observe('log no', Log.Get());
        Log.Reset();
        P.Close();
        Observer.Observe('log close', Log.Get());
        ObserveStored(Observer);
    end;

    [Test]
    procedure PG6889_Both_ActionInsertsAfterLast()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunBoth(Observer, 1);
        Observer.Expect('line after action', '30000');
        Observer.Expect('log action', 'R20;ACT;R30;R30;R20;R10;R30;R30;C30');
        Observer.Expect('after type', '30000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;HR;HC;R30;R20;R10;R30;R30;C30');
        Observer.Expect('after no', '30000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(30:Item/R1)');
        Observer.Expect('stored', '10000:Item/ 20000:Item/ 30000:Item/R1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Both_ActionInsertsBeforeFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunBoth(Observer, 2);
        Observer.Expect('line after action', '5000');
        Observer.Expect('log action', 'R10;ACT;R5;R5;R10;R20;R5;R5;C5');
        Observer.Expect('after type', '5000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;HR;HC;R5;R10;R20;R5;R5;C5');
        Observer.Expect('after no', '5000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(5:Item/R1)');
        Observer.Expect('stored', '5000:Item/R1 10000:Item/ 20000:Item/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Both_ActionMovesToExistingLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunBoth(Observer, 3);
        Observer.Expect('line after action', '20000');
        Observer.Expect('log action', 'R10;ACT;R20;R20;R10;R20;R20;C20');
        Observer.Expect('after type', '20000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;HR;HC;R20;R10;R20;R20;C20');
        Observer.Expect('after no', '20000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(20:Item/R1)');
        Observer.Expect('stored', '10000:Item/ 20000:Item/R1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Both_InsertedLineReachedAgainByPreviousNext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunBoth(Observer, 4);
        Observer.Expect('line after action', '30000');
        Observer.Expect('log action', 'R20;ACT;R30;R30;R20;R10;R30;R30;C30');
        Observer.Expect('line after prev next', '30000');
        Observer.Expect('after type', '30000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;HR;HC;R30;R20;R10;R30;R30;C30');
        Observer.Expect('after no', '30000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(30:Item/R1)');
        Observer.Expect('stored', '10000:Item/ 20000:Item/ 30000:Item/R1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Plain_ActionInsertsAfterLast()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlain(Observer, 1);
        Observer.Expect('line after action', '30000');
        Observer.Expect('log action', 'R20;ACT;R30;R30;R20;R10;R30;R30;C30');
        Observer.Expect('after type', '30000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;R30;R20;R10;R30;R30;C30');
        Observer.Expect('after no', '30000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(30:Item/R1)');
        Observer.Expect('stored', '10000:Item/ 20000:Item/ 30000:Item/R1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Plain_ActionInsertsBeforeFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlain(Observer, 2);
        Observer.Expect('line after action', '5000');
        Observer.Expect('log action', 'R10;ACT;R5;R5;R10;R20;R5;R5;C5');
        Observer.Expect('after type', '5000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;R5;R10;R20;R5;R5;C5');
        Observer.Expect('after no', '5000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(5:Item/R1)');
        Observer.Expect('stored', '5000:Item/R1 10000:Item/ 20000:Item/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Plain_ActionMovesToExistingLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlain(Observer, 3);
        Observer.Expect('line after action', '20000');
        Observer.Expect('log action', 'R10;ACT;R20;R20;R10;R20;R20;C20');
        Observer.Expect('after type', '20000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;R20;R10;R20;R20;C20');
        Observer.Expect('after no', '20000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(20:Item/R1)');
        Observer.Expect('stored', '10000:Item/ 20000:Item/R1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PG6889_Plain_InsertedLineReachedAgainByPreviousNext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlain(Observer, 4);
        Observer.Expect('line after action', '30000');
        Observer.Expect('log action', 'R20;ACT;R30;R30;R20;R10;R30;R30;C30');
        Observer.Expect('line after prev next', '30000');
        Observer.Expect('after type', '30000 Item');
        Observer.Expect('log type', 'TY.V;TY.V.end;R30;R20;R10;R30;R30;C30');
        Observer.Expect('after no', '30000 Item');
        Observer.Expect('log no', 'NoV(Item)');
        Observer.Expect('log close', 'T.MOD(30:Item/R1)');
        Observer.Expect('stored', '10000:Item/ 20000:Item/ 30000:Item/R1 ');
        Observer.Verify();
    end;
}

codeunit 95979 "PG R6889 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}
