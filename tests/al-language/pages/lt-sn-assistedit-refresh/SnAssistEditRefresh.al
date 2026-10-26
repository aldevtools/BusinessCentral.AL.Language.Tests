// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-assistedit-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 89272, pages 89273 and 89274, log codeunit 89275, test codeunit 89276
// Probe: writer SN (2026-10-25), runtime hand-off refuse-errors "AssistEdit on a List page: does OnAfterGetRecord run again". P82Lookups.al
//   pins OnAssistEdit;OnAfterGetRecord(L1) on a Card page for a page-variable control; P129CallstackPageControls.al shows no OnAfterGetRecord
//   after AssistEdit on a List page for a field control (but logs OnAfterGetRecord only for Id 1). Here the same table, the same trigger
//   bodies and a log of every OnAfterGetRecord/OnAfterGetCurrRecord, on a Card and on a List page, for a field control and a page-variable control.
// BC versions: 29 (27 and 28 by CI)

table 89272 "LT SN AE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 89275 "LT SN AE Log"
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

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 89273 "LT SN AE Card"
{
    PageType = Card;
    SourceTable = "LT SN AE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        Log.Add('OnAssistEdit(Name)');
                    end;
                }
                field(VarCtl; VarText)
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        Log.Add('OnAssistEdit(Var)');
                    end;
                }
                field(SetCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        Log.Add('OnAssistEdit(Set)');
                        Rec.Name := 'assisted';
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT SN AE Log";
        VarText: Text;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord(' + Rec.Code + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord(' + Rec.Code + ')');
    end;
}

page 89274 "LT SN AE List"
{
    PageType = List;
    SourceTable = "LT SN AE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        Log.Add('OnAssistEdit(Name)');
                    end;
                }
                field(VarCtl; VarText)
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        Log.Add('OnAssistEdit(Var)');
                    end;
                }
                field(SetCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        Log.Add('OnAssistEdit(Set)');
                        Rec.Name := 'assisted';
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT SN AE Log";
        VarText: Text;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord(' + Rec.Code + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord(' + Rec.Code + ')');
    end;
}

codeunit 89276 "LT SN AE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SN AE Log";

    local procedure Seed()
    var
        Row: Record "LT SN AE Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Name := 'alpha';
        Row.Insert();
        Row.Code := 'B';
        Row.Name := 'beta';
        Row.Insert();
        Log.Take();
    end;

    [Test]
    procedure AssistEdit_Card_Refresh()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT SN AE Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey('B');
        Observer.Observe('open', Log.Take());
        Pg.NameCtl.AssistEdit();
        Observer.Observe('field', Log.Take());
        Pg.VarCtl.AssistEdit();
        Observer.Observe('var', Log.Take());
        Pg.SetCtl.AssistEdit();
        Observer.Observe('set', Log.Take());
        Observer.Observe('set_value', Pg.NameCtl.Value());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'OnAfterGetRecord(A);OnAfterGetCurrRecord(A);OnAfterGetRecord(A);OnAfterGetCurrRecord(A);OnAfterGetRecord(B);OnAfterGetCurrRecord(B)');
        Observer.Expect('field', 'OnAssistEdit(Name);OnAfterGetRecord(B);OnAfterGetCurrRecord(B)');
        Observer.Expect('var', 'OnAssistEdit(Var);OnAfterGetRecord(B);OnAfterGetCurrRecord(B)');
        Observer.Expect('set', 'OnAssistEdit(Set)');
        Observer.Expect('set_value', 'assisted');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure AssistEdit_List_Refresh()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT SN AE List";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey('B');
        Observer.Observe('open', Log.Take());
        Pg.NameCtl.AssistEdit();
        Observer.Observe('field', Log.Take());
        Pg.VarCtl.AssistEdit();
        Observer.Observe('var', Log.Take());
        Pg.SetCtl.AssistEdit();
        Observer.Observe('set', Log.Take());
        Observer.Observe('set_value', Pg.NameCtl.Value());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'OnAfterGetRecord(A);OnAfterGetRecord(B);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetCurrRecord(A);OnAfterGetRecord(B);OnAfterGetRecord(B);OnAfterGetCurrRecord(B)');
        Observer.Expect('field', 'OnAssistEdit(Name);OnAfterGetRecord(B);OnAfterGetCurrRecord(B)');
        Observer.Expect('var', 'OnAssistEdit(Var);OnAfterGetRecord(B);OnAfterGetCurrRecord(B)');
        Observer.Expect('set', 'OnAssistEdit(Set)');
        Observer.Expect('set_value', 'assisted');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure AssistEdit_List_ViewMode_Refresh()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT SN AE List";
    begin
        Seed();
        Pg.OpenView();
        Pg.First();
        Observer.Observe('open', Log.Take());
        Pg.NameCtl.AssistEdit();
        Observer.Observe('field', Log.Take());
        Pg.VarCtl.AssistEdit();
        Observer.Observe('var', Log.Take());
        Pg.Close();
        Observer.Expect('open', 'OnAfterGetRecord(A);OnAfterGetRecord(B);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetCurrRecord(A)');
        Observer.Expect('field', 'OnAssistEdit(Name);OnAfterGetRecord(A);OnAfterGetCurrRecord(A)');
        Observer.Expect('var', 'OnAssistEdit(Var);OnAfterGetRecord(A);OnAfterGetCurrRecord(A)');
        Observer.Verify();
    end;
}
