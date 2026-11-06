// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 96320 - 96327 in this file (table, three List pages, one page extension, two helper codeunits, tests in codeunit 96327)
// Probe: al-runner issue 6924 (waldo): a List page whose OnOpenPage positions Rec with Get, directly (Rec.Get('C')) or through a table
//   procedure that calls a codeunit taking the record var (FindSet on it, CopyFilters to a second record, SetFilter, FindFirst on the second,
//   then Rec.Get(second's key)). Same in the OnOpenPage of a page extension (the base trigger runs first or last, which one is in the log),
//   on a page with SourceTableView sorting(Name) descending, opened by TestPage OpenView / OpenEdit and by Page.Run with a filter on Rec
//   (No. B..D, No. A..B, Name <> bravo). Observed: the row the page shows (No.|Name), the triggers on the way (log), Next and Previous.
//   Log: F:<filters of Rec at the start of the first OnOpenPage>, B: / E0: / E: = Rec at the end of the base trigger, at the start and at the end of the
//   extension trigger, O: = Rec at the end of OnOpenPage of a page without extension, R: = OnAfterGetRecord, C: = OnAfterGetCurrRecord.
//   Rows: A 'delta', B 'charlie', C 'bravo', D 'alpha' (key No. orders A..D, key ByName D..A). Modes: 0 nothing, 1 Get('C'), 2 table procedure chain.
// BC versions: 27, 28, 29

table 96320 "LT OG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByName; Name) { }
    }

    procedure PositionLater()
    var
        Picker: Codeunit "LT OG Picker";
    begin
        Picker.Pick(Rec);
    end;
}

page 96323 "LT OG List"
{
    PageType = List;
    SourceTable = "LT OG Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('F:' + Rec.GetFilters());
        Log.Move(Rec, Log.BaseMode());
        Log.Add('O:' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT OG Log";
}

page 96324 "LT OG Ext List"
{
    PageType = List;
    SourceTable = "LT OG Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('F:' + Rec.GetFilters());
        Log.Move(Rec, Log.BaseMode());
        Log.Add('B:' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT OG Log";
}

pageextension 96325 "LT OG Ext List Ext" extends "LT OG Ext List"
{
    trigger OnOpenPage()
    begin
        Log.Add('E0:' + Rec."No.");
        Log.Move(Rec, Log.ExtMode());
        Log.Add('E:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT OG Log";
}

page 96326 "LT OG View List"
{
    PageType = List;
    SourceTable = "LT OG Row";
    SourceTableView = sorting(Name) order(descending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('F:' + Rec.GetFilters());
        Log.Move(Rec, Log.BaseMode());
        Log.Add('O:' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT OG Log";
}

codeunit 96321 "LT OG Picker"
{
    // FindSet on the record, CopyFilters to a second record, SetFilter on the second, FindFirst on the second, then Get with the second's key.
    procedure Pick(var Row: Record "LT OG Row")
    var
        Second: Record "LT OG Row";
    begin
        Row.FindSet();
        Second.CopyFilters(Row);
        Second.SetFilter("No.", '>=C');
        Second.FindFirst();
        Row.Get(Second."No.");
    end;
}

codeunit 96322 "LT OG Log"
{
    SingleInstance = true;

    var
        BaseModeValue: Integer;
        ExtModeValue: Integer;
        Entries: Text;

    procedure SetModes(NewBase: Integer; NewExt: Integer)
    begin
        BaseModeValue := NewBase;
        ExtModeValue := NewExt;
        Entries := '';
    end;

    procedure BaseMode(): Integer
    begin
        exit(BaseModeValue);
    end;

    procedure ExtMode(): Integer
    begin
        exit(ExtModeValue);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Fill()
    var
        Row: Record "LT OG Row";
    begin
        Row.DeleteAll();
        Insert(Row, 'A', 'delta');
        Insert(Row, 'B', 'charlie');
        Insert(Row, 'C', 'bravo');
        Insert(Row, 'D', 'alpha');
    end;

    local procedure Insert(var Row: Record "LT OG Row"; No: Code[10]; NewName: Text[30])
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Insert();
    end;

    // 0: nothing; 1: Get('C'); 2: the table procedure chain (FindSet, CopyFilters, SetFilter, FindFirst on the copy, Get of its key).
    procedure Move(var Rec: Record "LT OG Row"; Mode: Integer)
    begin
        case Mode of
            1:
                Rec.Get('C');
            2:
                Rec.PositionLater();
        end;
    end;
}

codeunit 96327 "LT OG Get Chain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT OG Log";

    local procedure ReadList(var P: TestPage "LT OG List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [PageHandler]
    procedure HandlerList(var P: TestPage "LT OG List")
    begin
        ReadList(P);
    end;

    local procedure ReadExtList(var P: TestPage "LT OG Ext List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [PageHandler]
    procedure HandlerExtList(var P: TestPage "LT OG Ext List")
    begin
        ReadExtList(P);
    end;

    local procedure ReadViewList(var P: TestPage "LT OG View List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [PageHandler]
    procedure HandlerViewList(var P: TestPage "LT OG View List")
    begin
        ReadViewList(P);
    end;

    [Test]
    procedure Og_List_OpenView_Mode1()
    var
        P: TestPage "LT OG List";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        P.OpenView();
        ReadList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Og_List_OpenEdit_Mode1()
    var
        P: TestPage "LT OG List";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        P.OpenEdit();
        ReadList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRun_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRunNoBD_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Row.SetRange("No.", 'B', 'D');
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRunNoAB_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Row.SetRange("No.", 'A', 'B');
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRunNameNotBravo_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Row.SetFilter(Name, '<>bravo');
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_List_OpenView_Mode2()
    var
        P: TestPage "LT OG List";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        P.OpenView();
        ReadList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Og_List_OpenEdit_Mode2()
    var
        P: TestPage "LT OG List";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        P.OpenEdit();
        ReadList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRun_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRunNoBD_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Row.SetRange("No.", 'B', 'D');
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRunNoAB_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Row.SetRange("No.", 'A', 'B');
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerList')]
    procedure Og_List_PageRunNameNotBravo_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Row.SetFilter(Name, '<>bravo');
        Page.Run(Page::"LT OG List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenView_Base1Ext0()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        P.OpenView();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRun_Base1Ext0()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenView_Base0Ext1()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(0, 1);
        P.OpenView();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRun_Base0Ext1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(0, 1);
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenView_Base0Ext2()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(0, 2);
        P.OpenView();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRun_Base0Ext2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(0, 2);
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenView_Base2Ext0()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        P.OpenView();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRun_Base2Ext0()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenView_Base1Ext2()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(1, 2);
        P.OpenView();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRun_Base1Ext2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 2);
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenView_Base2Ext1()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(2, 1);
        P.OpenView();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRun_Base2Ext1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 1);
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ExtList_OpenEdit_Base0Ext2()
    var
        P: TestPage "LT OG Ext List";
    begin
        Log.Fill();
        Log.SetModes(0, 2);
        P.OpenEdit();
        ReadExtList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRunNoBD_Base0Ext2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(0, 2);
        Row.SetRange("No.", 'B', 'D');
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRunNoAB_Base0Ext2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(0, 2);
        Row.SetRange("No.", 'A', 'B');
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerExtList')]
    procedure Og_ExtList_PageRunNameNotBravo_Base0Ext2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(0, 2);
        Row.SetFilter(Name, '<>bravo');
        Page.Run(Page::"LT OG Ext List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ViewList_OpenView_Mode1()
    var
        P: TestPage "LT OG View List";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        P.OpenView();
        ReadViewList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerViewList')]
    procedure Og_ViewList_PageRun_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Page.Run(Page::"LT OG View List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerViewList')]
    procedure Og_ViewList_PageRunNoBD_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Row.SetRange("No.", 'B', 'D');
        Page.Run(Page::"LT OG View List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerViewList')]
    procedure Og_ViewList_PageRunNoAB_Mode1()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(1, 0);
        Row.SetRange("No.", 'A', 'B');
        Page.Run(Page::"LT OG View List", Row);
        Observer.Finish();
    end;

    [Test]
    procedure Og_ViewList_OpenView_Mode2()
    var
        P: TestPage "LT OG View List";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        P.OpenView();
        ReadViewList(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerViewList')]
    procedure Og_ViewList_PageRun_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Page.Run(Page::"LT OG View List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerViewList')]
    procedure Og_ViewList_PageRunNoBD_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Row.SetRange("No.", 'B', 'D');
        Page.Run(Page::"LT OG View List", Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandlerViewList')]
    procedure Og_ViewList_PageRunNoAB_Mode2()
    var
        Row: Record "LT OG Row";
    begin
        Log.Fill();
        Log.SetModes(2, 0);
        Row.SetRange("No.", 'A', 'B');
        Page.Run(Page::"LT OG View List", Row);
        Observer.Finish();
    end;
}
