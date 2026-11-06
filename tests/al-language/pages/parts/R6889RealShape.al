// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT R6877 Doc (pages/lt-th-part-update-cursor/R6877PartBothLaterRow.al); own objects
//   96130-96141 (PG R6889 RS *)
// local object: the part's action, the host's OnAfterGetCurrRecord and the table triggers are what the test checks
// Probe: from al-runner issue 6889, second round (follow-up of R6889PartActionNewLine.al, where the typed Type is dropped on the line the
//   part's own action inserted). The reporter's real pages keep the value on BC 28. His differences are added one at a time, cumulatively:
//   step 0 control: the earlier shape with an enum Type (InitValue) and table OnInsert/OnModify checks, host part UpdatePropagation = Both.
//   step 1: + host OnAfterGetCurrRecord calls CurrPage.Lines.Page.SetEditable(true) (the part procedure only runs CurrPage.Update(false)),
//           host part Editable = a host variable.
//   step 2: + part SourceTableView sorting("Header No.", "Order No."), Level field with ShowAsTree / IndentationColumn = Rec.Level /
//           TreeInitialState = ExpandAll, AutoSplitKey with InsertAllowed = DeleteAllowed = false; the action inserts the child and
//           renumbers Order No. of all lines inline, then Rec.Next().
//   step 3: + the action passes Rec as var to a codeunit that Modify(true)s the current line, Insert(true)s the new line, renumbers Order
//           No. (Modify on every line) and Gets Rec again; then Rec.Next().
//   step 4: + the part is empty at the first action call (no First() before Invoke(); the codeunit creates a root and a child), the host is
//           opened with OpenEdit, Filter.SetFilter("No.", ..), GoToRecord(..); the part has fields whose Editable depends on Type through
//           variables set in OnAfterGetRecord; the table's Type OnValidate resets those fields when Type changes (switched on by
//           the Log codeunit flag, so steps 0 to 3 run the same trigger without the reset).
//   Each step: SetValue on Type (Resource), then on No.; observed are the part's row after the action and after each SetValue, the trigger
//   log (HR/HC host, R/C part, SE part SetEditable, T.INS/M/NoV/TV table, CU codeunit, ACT action) and the stored lines after Close.
// Result: see the Expect lines.
// BC versions: 27+ (tested by the corpus CI matrix)

enum 96130 "PG R6889 RS Kind"
{
    Extensible = false;

    value(0; Item) { }
    value(1; Resource) { }
    value(2; Note) { }
}

table 96131 "PG R6889 RS Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Order No."; Integer) { }
        field(4; Level; Integer) { }
        field(5; Type; Enum "PG R6889 RS Kind")
        {
            InitValue = Item;

            trigger OnValidate()
            var
                Log: Codeunit "PG R6889 RS Log";
            begin
                Log.Add('TV');
                if Log.ResetOnType() and (Type <> xRec.Type) then begin
                    "Item Code" := '';
                    "Start Time" := 0T;
                    "End Time" := 0T;
                end;
            end;
        }
        field(6; "No."; Code[20])
        {
            trigger OnValidate()
            var
                Log: Codeunit "PG R6889 RS Log";
            begin
                Log.Add('NoV(' + Format(Type) + ')');
            end;
        }
        field(7; "Item Code"; Code[10]) { }
        field(8; "Start Time"; Time) { }
        field(9; "End Time"; Time) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
        key(OrderKey; "Header No.", "Order No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        TestField("Header No.");
        if "No." = '' then
            "No." := 'N' + Format("Line No." div 1000);
        Log.Add('T.INS(' + Format("Line No." div 1000) + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        TestField("Header No.");
        Log.Add('M' + Format("Line No." div 1000) + ':' + Format(Type) + '/' + "No.");
    end;
}

codeunit 96132 "PG R6889 RS Lines"
{
    // Hands out the next free Line No. and renumbers Order No. as 10000, 20000, ... in key order, one Modify per changed line.
    procedure Renumber(HeaderNo: Code[20])
    var
        Lines: Record "PG R6889 RS Line";
        LineNos: List of [Integer];
        LineNo: Integer;
        Order: Integer;
    begin
        Lines.SetCurrentKey("Header No.", "Order No.");
        Lines.SetRange("Header No.", HeaderNo);
        if Lines.FindSet() then
            repeat
                LineNos.Add(Lines."Line No.");
            until Lines.Next() = 0;
        foreach LineNo in LineNos do begin
            Order += 10000;
            Lines.Get(HeaderNo, LineNo);
            if Lines."Order No." <> Order then begin
                Lines."Order No." := Order;
                Lines.Modify();
            end;
        end;
    end;

    procedure LastLineNo(HeaderNo: Code[20]): Integer
    var
        Lines: Record "PG R6889 RS Line";
    begin
        Lines.SetRange("Header No.", HeaderNo);
        if Lines.FindLast() then
            exit(Lines."Line No.");
    end;

    // The reporter's shape: Rec comes in as var, the current line is modified through a second variable, the new line is inserted,
    // Order No. is renumbered on all lines, Rec is read again. An empty part (Rec without a Line No.) first gets a root line.
    procedure NewChildLine(var Rec: Record "PG R6889 RS Line")
    var
        Cur: Record "PG R6889 RS Line";
        New: Record "PG R6889 RS Line";
        Log: Codeunit "PG R6889 RS Log";
        HeaderNo: Code[20];
        RootNo: Integer;
    begin
        Log.Add('CU');
        HeaderNo := Rec."Header No.";
        if HeaderNo = '' then
            HeaderNo := Rec.GetRangeMin("Header No.");
        if Rec."Line No." = 0 then begin
            New.Init();
            New."Header No." := HeaderNo;
            New."Line No." := LastLineNo(HeaderNo) + 10000;
            New."Order No." := 10000;
            New.Level := 0;
            New.Insert(true);
            Rec.Get(HeaderNo, New."Line No.");
        end;
        RootNo := Rec."Line No.";
        Cur.Get(HeaderNo, RootNo);
        Cur.Modify(true);
        New.Init();
        New."Header No." := HeaderNo;
        New."Line No." := LastLineNo(HeaderNo) + 10000;
        New."Order No." := Cur."Order No." + 1;
        New.Level := Cur.Level + 1;
        New.Insert(true);
        Renumber(HeaderNo);
        Rec.Get(HeaderNo, RootNo);
    end;
}

page 96133 "PG R6889 RS Part1"
{
    PageType = ListPart;
    SourceTable = "PG R6889 RS Line";
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
                        Log: Codeunit "PG R6889 RS Log";
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
                    Line: Record "PG R6889 RS Line";
                    Log: Codeunit "PG R6889 RS Log";
                begin
                    Log.Add('ACT');
                    Line.SetRange("Header No.", Rec."Header No.");
                    Line.FindLast();
                    Line."Line No." += 10000;
                    Line.Type := Line.Type::Item;
                    Line."No." := '';
                    Line.Insert(true);
                    Rec.Next();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 1000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 1000));
    end;

    procedure SetEditable(NewEditable: Boolean)
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('SE');
        CurrPage.Update(false);
    end;
}

// Part of steps 2 and 3: sorted by the Order key, tree, AutoSplitKey, no insert or delete from the UI.
page 96134 "PG R6889 RS Part2"
{
    PageType = ListPart;
    SourceTable = "PG R6889 RS Line";
    SourceTableView = sorting("Header No.", "Order No.");
    AutoSplitKey = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Level;
                TreeInitialState = ExpandAll;

                field(Level; Rec.Level) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG R6889 RS Log";
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
            // step 2: inline insert and renumber, then Rec.Next()
            action(NewChildInline)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    New: Record "PG R6889 RS Line";
                    Lines: Codeunit "PG R6889 RS Lines";
                    Log: Codeunit "PG R6889 RS Log";
                begin
                    Log.Add('ACT');
                    New.Init();
                    New."Header No." := Rec."Header No.";
                    New."Line No." := Lines.LastLineNo(Rec."Header No.") + 10000;
                    New."Order No." := Rec."Order No." + 1;
                    New.Level := Rec.Level + 1;
                    New.Insert(true);
                    Lines.Renumber(Rec."Header No.");
                    Rec.Next();
                end;
            }
            // step 3: Rec as var to a codeunit, then Rec.Next()
            action(NewChildCodeunit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Lines: Codeunit "PG R6889 RS Lines";
                    Log: Codeunit "PG R6889 RS Log";
                begin
                    Log.Add('ACT');
                    Lines.NewChildLine(Rec);
                    Rec.Next();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 1000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 1000));
    end;

    procedure SetEditable(NewEditable: Boolean)
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('SE');
        CurrPage.Update(false);
    end;
}

// Part of step 4: Part2 plus fields whose Editable depends on Type through variables set in OnAfterGetRecord.
page 96135 "PG R6889 RS Part4"
{
    PageType = ListPart;
    SourceTable = "PG R6889 RS Line";
    SourceTableView = sorting("Header No.", "Order No.");
    AutoSplitKey = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Level;
                TreeInitialState = ExpandAll;

                field(Level; Rec.Level) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG R6889 RS Log";
                    begin
                        Log.Add('TY.V');
                        CurrPage.Update(false);
                        Log.Add('TY.V.end');
                    end;
                }
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code")
                {
                    ApplicationArea = All;
                    Editable = CodeEditable;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    Editable = TimeEditable;
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    Editable = TimeEditable;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewChildCodeunit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Lines: Codeunit "PG R6889 RS Lines";
                    Log: Codeunit "PG R6889 RS Log";
                begin
                    Log.Add('ACT');
                    Lines.NewChildLine(Rec);
                    Rec.Next();
                end;
            }
        }
    }

    var
        CodeEditable: Boolean;
        TimeEditable: Boolean;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        CodeEditable := Rec.Type = Rec.Type::Resource;
        TimeEditable := Rec.Type <> Rec.Type::Item;
        Log.Add('R' + Format(Rec."Line No." div 1000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 1000));
    end;

    procedure SetEditable(NewEditable: Boolean)
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('SE');
        CurrPage.Update(false);
    end;
}

// step 0: host without the OnAfterGetCurrRecord call, part UpdatePropagation = Both
page 96136 "PG R6889 RS Host0"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R6889 RS Part1")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HC');
    end;
}

// step 1: host OnAfterGetCurrRecord calls the part procedure, part Editable = host variable
page 96137 "PG R6889 RS Host1"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R6889 RS Part1")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                UpdatePropagation = Both;
                Editable = EditableG;
            }
        }
    }

    var
        EditableG: Boolean;

    trigger OnOpenPage()
    begin
        EditableG := true;
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HC');
        CurrPage.Lines.Page.SetEditable(true);
    end;
}

// steps 2 and 3: as Host1 over Part2
page 96138 "PG R6889 RS Host2"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R6889 RS Part2")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                UpdatePropagation = Both;
                Editable = EditableG;
            }
        }
    }

    var
        EditableG: Boolean;

    trigger OnOpenPage()
    begin
        EditableG := true;
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HC');
        CurrPage.Lines.Page.SetEditable(true);
    end;
}

// step 4: as Host2 over Part4
page 96139 "PG R6889 RS Host4"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R6889 RS Part4")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
                UpdatePropagation = Both;
                Editable = EditableG;
            }
        }
    }

    var
        EditableG: Boolean;

    trigger OnOpenPage()
    begin
        EditableG := true;
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.Add('HC');
        CurrPage.Lines.Page.SetEditable(true);
    end;
}

codeunit 96140 "PG R6889 RS Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Two documents, D1 with two lines (Level 0, Order No. 10000 and 20000), D2 without lines (step 4), D3 without lines.
    local procedure Initialize()
    var
        Head: Record "LT R6877 Doc";
        Line: Record "PG R6889 RS Line";
        Log: Codeunit "PG R6889 RS Log";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'D1';
        Head.Insert();
        Head."No." := 'D2';
        Head.Insert();
        Head."No." := 'D3';
        Head.Insert();
        Line."Header No." := 'D1';
        Line."Line No." := 10000;
        Line."Order No." := 10000;
        Line.Insert();
        Line."Line No." := 20000;
        Line."Order No." := 20000;
        Line.Insert();
        Log.Reset();
        Log.SetResetOnType(false);
    end;

    local procedure ObserveStored(var Observer: Codeunit "Probe Observer")
    var
        Line: Record "PG R6889 RS Line";
        Rows: Text;
    begin
        Line.SetCurrentKey("Header No.", "Line No.");
        if Line.FindSet() then
            repeat
                Rows += Line."Header No." + '/' + Format(Line."Line No.") + ':O' + Format(Line."Order No.") + ':L' + Format(Line.Level) + ':' + Format(Line.Type) + '/' + Line."No." + '/' + Line."Item Code" + ' ';
            until Line.Next() = 0;
        Observer.Observe('stored', Rows);
    end;

    // Step 0: Host0, action NewLineAfter from the second line.
    local procedure RunStep0(var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "PG R6889 RS Host0";
        Log: Codeunit "PG R6889 RS Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        P.Lines.Next();
        Log.Reset();
        P.Lines.NewLineAfter.Invoke();
        Observer.Observe('line after action', P.Lines."Line No.".Value());
        Observer.Observe('log action', Log.Get());
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

    // Step 1: Host1 (host calls Part.SetEditable), action NewLineAfter from the second line.
    local procedure RunStep1(var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "PG R6889 RS Host1";
        Log: Codeunit "PG R6889 RS Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        P.Lines.Next();
        Log.Reset();
        P.Lines.NewLineAfter.Invoke();
        Observer.Observe('line after action', P.Lines."Line No.".Value());
        Observer.Observe('log action', Log.Get());
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

    // Steps 2 and 3: Host2; Act 2 = NewChildInline, 3 = NewChildCodeunit, both from the first line (Order No. 10000).
    local procedure RunStep23(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "PG R6889 RS Host2";
        Log: Codeunit "PG R6889 RS Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        Log.Reset();
        if Act = 2 then
            P.Lines.NewChildInline.Invoke()
        else
            P.Lines.NewChildCodeunit.Invoke();
        Observer.Observe('line after action', P.Lines."Line No.".Value() + '/O' + P.Lines."Order No.".Value() + '/L' + P.Lines.Level.Value());
        Observer.Observe('log action', Log.Get());
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

    // Step 4: Host4 opened with OpenEdit, Filter.SetFilter on No., GoToRecord(D2); the part of D2 is empty, no First() before Invoke().
    local procedure RunStep4(var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "PG R6889 RS Host4";
        Doc: Record "LT R6877 Doc";
        Log: Codeunit "PG R6889 RS Log";
    begin
        Log.SetResetOnType(true);
        P.OpenEdit();
        P.Filter.SetFilter("No.", 'D2|D3');
        Doc.Get('D2');
        P.GoToRecord(Doc);
        Observer.Observe('host no', P.Filter.Value());
        Log.Reset();
        P.Lines.NewChildCodeunit.Invoke();
        Observer.Observe('line after action', P.Lines."Line No.".Value() + '/O' + P.Lines."Order No.".Value() + '/L' + P.Lines.Level.Value());
        Observer.Observe('log action', Log.Get());
        Log.Reset();
        P.Lines.Type.SetValue('Resource');
        Observer.Observe('after type', P.Lines."Line No.".Value() + ' ' + P.Lines.Type.Value());
        Observer.Observe('log type', Log.Get());
        Observer.Observe('editable after type', Format(P.Lines."Item Code".Editable()) + '/' + Format(P.Lines."Start Time".Editable()));
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
    procedure PG6889RS_Step0_EnumControl_BothNoHostCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunStep0(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PG6889RS_Step1_HostCallsPartSetEditable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunStep1(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PG6889RS_Step2_OrderKeyTreeAutoSplitKeyInlineRenumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunStep23(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure PG6889RS_Step3_RecAsVarToCodeunitThenNext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunStep23(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure PG6889RS_Step4_EmptyPartFilteredHostTypeResetsFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunStep4(Observer);
        Observer.Finish();
    end;
}

codeunit 96141 "PG R6889 RS Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ResetTypeFields: Boolean;

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

    procedure SetResetOnType(NewValue: Boolean)
    begin
        ResetTypeFields := NewValue;
    end;

    procedure ResetOnType(): Boolean
    begin
        exit(ResetTypeFields);
    end;
}
