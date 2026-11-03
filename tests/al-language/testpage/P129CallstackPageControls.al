// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73280, SingleInstance log 73281 (used only by test codeunit 73283), page 73282
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from the triggers of a page that earlier probes did not measure: a field control's OnValidate, OnLookup, OnDrillDown and OnAssistEdit,
// the page triggers OnInit, OnNewRecord, OnAfterGetRecord, OnAfterGetCurrRecord, OnQueryClosePage and OnClosePage, a local procedure and a global procedure of the page called from a trigger,
// and an action trigger of a nested group. Each entry is the frames above the test runner, innermost first (frame form, object kind, trigger naming and line numbers are what is measured).
// BC versions: 29 (27 and 28 by CI)

table 73280 "LT P129 CS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73281 "LT P129 CS Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Frames(): Text
    var
        Stack: Text;
        Position: Integer;
    begin
        Stack := SessionInformation.Callstack;
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            exit(CopyStr(Stack, 1, Position - 1));
        exit(Stack);
    end;
}

page 73282 "LT P129 CS Page"
{
    PageType = List;
    SourceTable = "LT P129 CS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        L.Add('Id OnValidate: ' + L.Frames());
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        L.Add('Name OnValidate: ' + L.Frames());
                        LocalProc();
                        GlobalProc();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        L.Add('Name OnLookup: ' + L.Frames());
                        exit(false);
                    end;

                    trigger OnDrillDown()
                    begin
                        L.Add('Name OnDrillDown: ' + L.Frames());
                    end;

                    trigger OnAssistEdit()
                    begin
                        L.Add('Name OnAssistEdit: ' + L.Frames());
                    end;
                }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Nested)
            {
                action(NestedAction)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                        L.Add('nested action: ' + L.Frames());
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        L.Add('OnInit: ' + L.Frames());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('OnNewRecord: ' + L.Frames());
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec.Id = 1 then
            L.Add('OnAfterGetRecord: ' + L.Frames());
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.Id = 1 then
            L.Add('OnAfterGetCurrRecord: ' + L.Frames());
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('OnQueryClosePage: ' + L.Frames());
        exit(true);
    end;

    trigger OnClosePage()
    begin
        L.Add('OnClosePage: ' + L.Frames());
    end;

    local procedure LocalProc()
    begin
        L.Add('local procedure: ' + L.Frames());
    end;

    procedure GlobalProc()
    begin
        L.Add('global procedure: ' + L.Frames());
    end;

    var
        L: Codeunit "LT P129 CS Log";
}

codeunit 73283 "LT P129 CS Page Controls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 CS Log";

    local procedure Seed()
    var
        Row: Record "LT P129 CS Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        L.Take();
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Entries: List of [Text];
        Entry: Text;
        I: Integer;
    begin
        Entries := L.Take().Split('|');
        foreach Entry in Entries do begin
            I += 1;
            if Entry <> '' then
                Observer.Observe(Name + ' ' + Format(I), Entry);
        end;
    end;

    [Test]
    procedure P129_Callstack_PageOpenAndClose_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 CS Page";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Close();
        Show(Observer, 'open and close');
        Observer.Expect('open and close 1', 'OnInit: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnInit(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageOpenAndClose_Triggers line 6 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('open and close 2', 'OnAfterGetRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageOpenAndClose_Triggers line 6 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('open and close 3', 'OnAfterGetRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageOpenAndClose_Triggers line 6 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('open and close 4', 'OnAfterGetCurrRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetCurrRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageOpenAndClose_Triggers line 6 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('open and close 5', 'OnQueryClosePage: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnQueryClosePage(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageOpenAndClose_Triggers line 7 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('open and close 6', 'OnClosePage: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnClosePage(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageOpenAndClose_Triggers line 7 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;





    [Test]
    procedure P129_Callstack_PageFieldTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 CS Page";
    begin
        Seed();
        Pg.OpenEdit();
        L.Take();
        Pg.Id.SetValue(1);
        Show(Observer, 'id validate');
        Pg.Name.SetValue('x');
        Show(Observer, 'name validate');
        Pg.Name.Lookup();
        Show(Observer, 'lookup');
        Pg.Name.Drilldown();
        Show(Observer, 'drilldown');
        Pg.Name.AssistEdit();
        Show(Observer, 'assistedit');
        Pg.Close();
        L.Take();
        Observer.Expect('id validate 1', 'Id OnValidate: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Id - OnValidate"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('name validate 1', 'Name OnValidate: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Name - OnValidate"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 10 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('name validate 2', 'local procedure: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).LocalProc line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Name - OnValidate"(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 10 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('name validate 3', 'global procedure: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).GlobalProc line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Name - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 10 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('lookup 1', 'Name OnLookup: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Name - OnLookup"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 12 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('drilldown 1', 'Name OnDrillDown: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Name - OnDrillDown"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 14 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('assistedit 1', 'Name OnAssistEdit: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."Name - OnAssistEdit"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageFieldTriggers line 16 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;





    [Test]
    procedure P129_Callstack_PageNewRecordAndNestedAction()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 CS Page";
    begin
        Seed();
        Pg.OpenEdit();
        L.Take();
        Pg.NestedAction.Invoke();
        Show(Observer, 'nested action');
        Pg.New();
        Show(Observer, 'new');
        Pg.Close();
        L.Take();
        Observer.Expect('nested action 1', 'OnAfterGetRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('nested action 2', 'nested action: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282)."NestedAction - OnAction"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('nested action 3', 'OnAfterGetRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('nested action 4', 'OnAfterGetRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('nested action 5', 'OnAfterGetRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('nested action 6', 'OnAfterGetCurrRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnAfterGetCurrRecord(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('new 1', 'OnNewRecord: "LT P129 CS Log"(CodeUnit 73281).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page"(Page 73282).OnNewRecord(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Page Controls"(CodeUnit 73283).P129_Callstack_PageNewRecordAndNestedAction line 10 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;




}
