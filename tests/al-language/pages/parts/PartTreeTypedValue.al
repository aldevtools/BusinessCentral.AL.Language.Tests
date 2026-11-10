// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-showastree-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62700 62701, log codeunit 62702, part pages 62703..62709, host pages
//   62710..62716, test codeunit 62717
// Probe: observe-only. Area: a value typed on the row a part's own action inserted and moved Rec to, when the control's OnValidate
//   runs CurrPage.Update(false) (al-runner issue 6889). R6889RealShape.al pins that BC keeps the typed value only when the repeater
//   has ShowAsTree = true together with IndentationColumn and TreeInitialState = ExpandAll, and drops it on a plain repeater. Not
//   pinned: which of the three tree properties decides (ShowAsTree alone, ShowAsTree with IndentationColumn, TreeInitialState =
//   CollapseAll, IndentationColumn without ShowAsTree), the tree part read in another key, and the read order on an empty part with
//   and without First() before the action (R6889RealShape.al has one such case, without First()).
// The action NewLine inserts a line after the last one (on an empty part: a root line 10000 and a child 20000) and runs Rec.Next().
// Steps: the action from the last row (Rec ends on the new line), from the first row (Rec ends on a line that was already shown),
//   on the empty part, and on the empty part after First(). Then SetValue on Type (Resource) and on "No.", whose table trigger logs
//   the Type it sees.
// Observed: the row the part shows, the stored lines (Line No.:Level:Type:No.) and the log (HC host OnAfterGetCurrRecord, R and C
//   part OnAfterGetRecord and OnAfterGetCurrRecord, ACT action, I and M table OnInsert and OnModify, NoV the "No." trigger).
// local object: the repeater properties of the parts and the triggers are what the test checks
// BC versions: 27, 28, 29

table 62700 "PG TS Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 62701 "PG TS Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; Level; Integer) { DataClassification = SystemMetadata; }
        field(4; Type; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = Item,Resource;
        }
        field(5; "No."; Code[20])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PG TS Log";
            begin
                Log.Add('NoV' + Format("Line No.") + ':' + Format(Type));
            end;
        }
        field(6; "Order No."; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
        key(Order; "Head No.", "Order No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('I' + Format("Line No."));
    end;

    trigger OnModify()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('M' + Format("Line No.") + ':' + Format(Type));
    end;
}

codeunit 62702 "PG TS Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentHead: Code[10];

    // The host row the test works on; the action inserts its lines there.
    procedure SetHead(HeadNo: Code[10])
    begin
        CurrentHead := HeadNo;
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;

    procedure NewLine(var Rec: Record "PG TS Line")
    var
        Line: Record "PG TS Line";
        HeadNo: Code[10];
        LastNo: Integer;
    begin
        HeadNo := CurrentHead;
        Line.SetRange("Head No.", HeadNo);
        if Line.FindLast() then
            LastNo := Line."Line No."
        else begin
            Insert(HeadNo, 10000, 0);
            LastNo := 10000;
        end;
        Insert(HeadNo, LastNo + 10000, 1);
    end;

    local procedure Insert(HeadNo: Code[10]; LineNo: Integer; Level: Integer)
    var
        Line: Record "PG TS Line";
    begin
        Line.Init();
        Line."Head No." := HeadNo;
        Line."Line No." := LineNo;
        Line."Order No." := LineNo;
        Line.Level := Level;
        Line.Insert(true);
    end;
}

page 62703 "PG TS Part Plain"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
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
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62710 "PG TS Host Plain"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

page 62704 "PG TS Part TreeFull"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
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
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62711 "PG TS Host TreeFull"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part TreeFull")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

page 62705 "PG TS Part TreeOnly"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62712 "PG TS Host TreeOnly"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part TreeOnly")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

page 62706 "PG TS Part TreeIndent"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Level;
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62713 "PG TS Host TreeIndent"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part TreeIndent")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

page 62707 "PG TS Part TreeCollapsed"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Level;
                TreeInitialState = CollapseAll;
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62714 "PG TS Host TreeCollapsed"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part TreeCollapsed")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

page 62708 "PG TS Part IndentOnly"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Level;
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62715 "PG TS Host IndentOnly"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part IndentOnly")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

page 62709 "PG TS Part TreeFullOrderKey"
{
    PageType = ListPart;
    SourceTable = "PG TS Line";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = sorting("Head No.", "Order No.");

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Level;
                TreeInitialState = ExpandAll;
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
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
            action(NewLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('ACT');
                    Log.NewLine(Rec);
                    Log.Add('next=' + Format(Rec.Next()));
                end;
            }
        }
    }

    var
        Log: Codeunit "PG TS Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;
}

page 62716 "PG TS Host TreeFullOrderKey"
{
    PageType = ListPlus;
    SourceTable = "PG TS Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG TS Part TreeFullOrderKey")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG TS Log";
    begin
        Log.Add('HC');
    end;
}

codeunit 62717 "PG TS Tree Typed Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG TS Log";

    local procedure Seed()
    var
        Head: Record "PG TS Head";
        Line: Record "PG TS Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        Head."No." := 'H2';
        Head.Insert();
        AddLine(10000, 0);
        AddLine(20000, 1);
        Log.Take();
    end;

    local procedure AddLine(LineNo: Integer; Level: Integer)
    var
        Line: Record "PG TS Line";
    begin
        Line.Init();
        Line."Head No." := 'H1';
        Line."Line No." := LineNo;
        Line."Order No." := LineNo;
        Line.Level := Level;
        Line.Insert();
    end;

    local procedure Stored(HeadNo: Code[10]) Result: Text
    var
        Line: Record "PG TS Line";
    begin
        Line.SetRange("Head No.", HeadNo);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + ':' + Format(Line.Level) + ':' + Format(Line.Type) + ':' + Line."No." + ' ';
            until Line.Next() = 0;
        Result := '[' + Result + ']';
    end;

    [Test]
    procedure Plain_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host Plain";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '30000:Item');
        Observer.Expect('log action', '[R20000 ACT I30000 next=1 R30000 R30000 R20000 R10000 R30000 R30000 C30000]');
        Observer.Expect('row after Type', '30000:Item');
        Observer.Expect('log Type', '[HC R30000 R20000 R10000 R30000 R30000 C30000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: 30000:1:Item: ]');
        Observer.Expect('row after No.', '30000:Item:R1');
        Observer.Expect('log No.', '[NoV30000:Item]');
        Observer.Expect('log close', '[M30000:Item]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Item: 30000:1:Item:R1 ]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host Plain";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Item');
        Observer.Expect('log Type', '[HC R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Item:R1');
        Observer.Expect('log No.', '[NoV20000:Item]');
        Observer.Expect('log close', '[M20000:Item]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Item:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host Plain";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Item');
        Observer.Expect('log Type', '[HC R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Item:R1');
        Observer.Expect('log No.', '[NoV10000:Item]');
        Observer.Expect('log close', '[M10000:Item]');
        Observer.Expect('stored', '[10000:0:Item:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host Plain";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Item');
        Observer.Expect('log Type', '[HC R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Item:R1');
        Observer.Expect('log No.', '[NoV10000:Item]');
        Observer.Expect('log close', '[M10000:Item]');
        Observer.Expect('stored', '[10000:0:Item:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFull_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host TreeFull";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFull_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host TreeFull";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFull_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host TreeFull";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFull_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host TreeFull";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeOnly_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host TreeOnly";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '30000:Item');
        Observer.Expect('log action', '[R20000 ACT I30000 next=1 R30000 R30000 R20000 R10000 R30000 R30000 C30000]');
        Observer.Expect('row after Type', '30000:Item');
        Observer.Expect('log Type', '[HC R30000 R20000 R10000 R30000 R30000 C30000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: 30000:1:Item: ]');
        Observer.Expect('row after No.', '30000:Item:R1');
        Observer.Expect('log No.', '[NoV30000:Item]');
        Observer.Expect('log close', '[M30000:Item]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Item: 30000:1:Item:R1 ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeOnly_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host TreeOnly";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Item');
        Observer.Expect('log Type', '[HC R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Item:R1');
        Observer.Expect('log No.', '[NoV20000:Item]');
        Observer.Expect('log close', '[M20000:Item]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Item:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeOnly_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host TreeOnly";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Item');
        Observer.Expect('log Type', '[HC R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Item:R1');
        Observer.Expect('log No.', '[NoV10000:Item]');
        Observer.Expect('log close', '[M10000:Item]');
        Observer.Expect('stored', '[10000:0:Item:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeOnly_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host TreeOnly";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Item');
        Observer.Expect('log Type', '[HC R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Item:R1');
        Observer.Expect('log No.', '[NoV10000:Item]');
        Observer.Expect('log close', '[M10000:Item]');
        Observer.Expect('stored', '[10000:0:Item:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeIndent_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host TreeIndent";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeIndent_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host TreeIndent";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeIndent_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host TreeIndent";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeIndent_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host TreeIndent";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeCollapsed_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host TreeCollapsed";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeCollapsed_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host TreeCollapsed";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeCollapsed_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host TreeCollapsed";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeCollapsed_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host TreeCollapsed";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure IndentOnly_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host IndentOnly";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '30000:Item');
        Observer.Expect('log action', '[R20000 ACT I30000 next=1 R30000 R30000 R20000 R10000 R30000 R30000 C30000]');
        Observer.Expect('row after Type', '30000:Item');
        Observer.Expect('log Type', '[HC R30000 R20000 R10000 R30000 R30000 C30000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: 30000:1:Item: ]');
        Observer.Expect('row after No.', '30000:Item:R1');
        Observer.Expect('log No.', '[NoV30000:Item]');
        Observer.Expect('log close', '[M30000:Item]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Item: 30000:1:Item:R1 ]');
        Observer.Verify();
    end;

    [Test]
    procedure IndentOnly_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host IndentOnly";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Item');
        Observer.Expect('log Type', '[HC R20000 R30000 R20000 R10000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Item:R1');
        Observer.Expect('log No.', '[NoV20000:Item]');
        Observer.Expect('log close', '[M20000:Item]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Item:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure IndentOnly_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host IndentOnly";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Item');
        Observer.Expect('log Type', '[HC R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Item:R1');
        Observer.Expect('log No.', '[NoV10000:Item]');
        Observer.Expect('log close', '[M10000:Item]');
        Observer.Expect('stored', '[10000:0:Item:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure IndentOnly_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host IndentOnly";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Item');
        Observer.Expect('log Type', '[HC R10000 R20000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Item:R1');
        Observer.Expect('log No.', '[NoV10000:Item]');
        Observer.Expect('log close', '[M10000:Item]');
        Observer.Expect('stored', '[10000:0:Item:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFullOrderKey_ActionFromLastRow()
    var
        Card: TestPage "PG TS Host TreeFullOrderKey";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R20000 R30000 R20000 R10000 R20000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R20000 R30000 R20000 R10000 R20000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFullOrderKey_ActionFromFirstRow()
    var
        Card: TestPage "PG TS Host TreeFullOrderKey";
    begin
        Seed();
        Log.SetHead('H1');
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H1'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H1'));
        Observer.Expect('row after action', '20000:Item');
        Observer.Expect('log action', '[R10000 ACT I30000 next=1 R20000 R20000 R20000 R30000 R20000 R10000 R20000 R20000 R20000 C20000]');
        Observer.Expect('row after Type', '20000:Resource');
        Observer.Expect('log Type', '[HC M20000:Resource R20000 R20000 R30000 R20000 R10000 R20000 R20000 R20000 C20000]');
        Observer.Expect('stored after Type', '[10000:0:Item: 20000:1:Resource: 30000:1:Item: ]');
        Observer.Expect('row after No.', '20000:Resource:R1');
        Observer.Expect('log No.', '[NoV20000:Resource]');
        Observer.Expect('log close', '[M20000:Resource]');
        Observer.Expect('stored', '[10000:0:Item: 20000:1:Resource:R1 30000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFullOrderKey_ActionOnEmptyPart()
    var
        Card: TestPage "PG TS Host TreeFullOrderKey";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R10000 R20000 R10000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R10000 R20000 R10000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

    [Test]
    procedure TreeFullOrderKey_ActionOnEmptyPartAfterFirst()
    var
        Card: TestPage "PG TS Host TreeFullOrderKey";
    begin
        Seed();
        Log.SetHead('H2');
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('First', Format(Card.Lines.First()));
        Log.Take();
        Card.Lines.NewLine.Invoke();
        Observer.Observe('row after action', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log action', Log.Take());
        Card.Lines.Type.SetValue('Resource');
        Observer.Observe('row after Type', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value);
        Observer.Observe('log Type', Log.Take());
        Observer.Observe('stored after Type', Stored('H2'));
        Card.Lines."No.".SetValue('R1');
        Observer.Observe('row after No.', Card.Lines."Line No.".Value + ':' + Card.Lines.Type.Value + ':' + Card.Lines."No.".Value);
        Observer.Observe('log No.', Log.Take());
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('stored', Stored('H2'));
        Observer.Expect('First', 'No');
        Observer.Expect('row after action', '10000:Item');
        Observer.Expect('log action', '[ACT I10000 I20000 next=1 R10000 R10000 R10000 R20000 R10000 R10000 R10000 C10000]');
        Observer.Expect('row after Type', '10000:Resource');
        Observer.Expect('log Type', '[HC M10000:Resource R10000 R10000 R20000 R10000 R10000 R10000 C10000]');
        Observer.Expect('stored after Type', '[10000:0:Resource: 20000:1:Item: ]');
        Observer.Expect('row after No.', '10000:Resource:R1');
        Observer.Expect('log No.', '[NoV10000:Resource]');
        Observer.Expect('log close', '[M10000:Resource]');
        Observer.Expect('stored', '[10000:0:Resource:R1 20000:1:Item: ]');
        Observer.Verify();
    end;

}
