// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 96232-96238 (LT WF3 *)
// local object: the page's Editable/ModifyAllowed shape and the table's lookup FlowField are what the test checks, and the action's code commits
// Probe: from al-runner issue 7193 (sibling of R7114EditableBlobAction.al, with a FlowField instead of a Blob): an editable List and an editable
//   Card over a table with a lookup FlowField and a FlowFilter. An action runs Rec.CalcFields(FlowField) (or sets a FlowFilter on Rec), then calls
//   a codeunit that Gets the same row into its own record variable, sets Link Code and runs Modify(true), without and with a Commit; contrast: the
//   same action without the CalcFields. Observed: the stored Link Code after the action and after Close, the log of the page's OnModifyRecord
//   (P.MODR) and the table's OnModify (T.MOD), and what the page shows after the action.
// Facts: see the assertions below.
// BC versions: 27+ (tested by the corpus CI matrix)

table 96232 "LT WF3 Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Status; Option) { OptionMembers = Open,Certified; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 96233 "LT WF3 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Link Code"; Code[20]) { }
        field(4; "Head Status"; Option)
        {
            OptionMembers = Open,Certified;
            FieldClass = FlowField;
            CalcFormula = lookup("LT WF3 Head".Status where("No." = field("Head No.")));
        }
        field(5; "Head Filter"; Code[20]) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('T.MOD(' + "Link Code" + ')');
    end;
}

codeunit 96234 "LT WF3 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

codeunit 96235 "LT WF3 Line Mgt"
{
    procedure SetLinkCode(HeadNo: Code[20]; LineNo: Integer; DoCommit: Boolean)
    var
        Line: Record "LT WF3 Line";
    begin
        Line.Get(HeadNo, LineNo);
        Line."Link Code" := 'L1';
        Line.Modify(true);
        if DoCommit then
            Commit();
    end;
}

page 96236 "LT WF3 List"
{
    PageType = List;
    SourceTable = "LT WF3 Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Head No."; Rec."Head No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Link Code"; Rec."Link Code") { ApplicationArea = All; }
                field("Head Status"; Rec."Head Status") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StampAfterCalcFields)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    Rec.CalcFields("Head Status");
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", false);
                end;
            }
            action(StampAfterCalcFieldsCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    Rec.CalcFields("Head Status");
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", true);
                end;
            }
            action(StampAfterFlowFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    Rec.SetRange("Head Filter", 'H1');
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", false);
                end;
            }
            action(StampOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", false);
                end;
            }
            action(StampOnlyCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", true);
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('P.MODR(' + Rec."Link Code" + ')');
        exit(true);
    end;
}

page 96237 "LT WF3 Card"
{
    PageType = Card;
    SourceTable = "LT WF3 Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Head No."; Rec."Head No.") { ApplicationArea = All; }
            field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            field("Link Code"; Rec."Link Code") { ApplicationArea = All; }
            field("Head Status"; Rec."Head Status") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StampAfterCalcFields)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    Rec.CalcFields("Head Status");
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", false);
                end;
            }
            action(StampAfterCalcFieldsCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    Rec.CalcFields("Head Status");
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", true);
                end;
            }
            action(StampAfterFlowFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    Rec.SetRange("Head Filter", 'H1');
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", false);
                end;
            }
            action(StampOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", false);
                end;
            }
            action(StampOnlyCommit)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mgt: Codeunit "LT WF3 Line Mgt";
                begin
                    
                    Mgt.SetLinkCode(Rec."Head No.", Rec."Line No.", true);
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('P.MODR(' + Rec."Link Code" + ')');
        exit(true);
    end;
}

codeunit 96238 "LT WF3 Flowfield Action"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Head: Record "LT WF3 Head";
        Line: Record "LT WF3 Line";
        Log: Codeunit "LT WF3 Log";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'H1';
        Head.Status := Head.Status::Certified;
        Head.Insert();
        Line."Head No." := 'H1';
        Line."Line No." := 10000;
        Line.Insert();
        Log.Reset();
    end;

    local procedure Stored(): Text
    var
        Line: Record "LT WF3 Line";
    begin
        Line.Get('H1', 10000);
        exit(Line."Link Code");
    end;

    local procedure RunList(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "LT WF3 List";
        Log: Codeunit "LT WF3 Log";
    begin
        P.OpenEdit();
        P.GoToKey('H1', 10000);
        Log.Reset();
        case Act of
            1:
                P.StampAfterCalcFields.Invoke();
            2:
                P.StampAfterCalcFieldsCommit.Invoke();
            3:
                P.StampAfterFlowFilter.Invoke();
            4:
                P.StampOnly.Invoke();
            5:
                P.StampOnlyCommit.Invoke();
        end;
        Observer.Observe('stored after action', Stored());
        Observer.Observe('log action', Log.Get());
        Observer.Observe('shown after action', P."Link Code".Value() + '/' + P."Head Status".Value());
        Log.Reset();
        P.Close();
        Observer.Observe('stored after close', Stored());
        Observer.Observe('log close', Log.Get());
    end;

    local procedure RunCard(var Observer: Codeunit "Probe Observer"; Act: Integer)
    var
        P: TestPage "LT WF3 Card";
        Log: Codeunit "LT WF3 Log";
    begin
        P.OpenEdit();
        P.GoToKey('H1', 10000);
        Log.Reset();
        case Act of
            1:
                P.StampAfterCalcFields.Invoke();
            2:
                P.StampAfterCalcFieldsCommit.Invoke();
            3:
                P.StampAfterFlowFilter.Invoke();
            4:
                P.StampOnly.Invoke();
            5:
                P.StampOnlyCommit.Invoke();
        end;
        Observer.Observe('stored after action', Stored());
        Observer.Observe('log action', Log.Get());
        Observer.Observe('shown after action', P."Link Code".Value() + '/' + P."Head Status".Value());
        Log.Reset();
        P.Close();
        Observer.Observe('stored after close', Stored());
        Observer.Observe('log close', Log.Get());
    end;

    [Test]
    procedure WF3_EditableList_StampAfterCalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableList_StampAfterCalcFieldsCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableList_StampAfterFlowFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableList_StampOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableList_StampOnlyCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunList(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableCard_StampAfterCalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableCard_StampAfterCalcFieldsCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableCard_StampAfterFlowFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableCard_StampOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_EditableCard_StampOnlyCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 5);
        Observer.Finish();
    end;
}
