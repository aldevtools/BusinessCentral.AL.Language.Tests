// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openedit-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74865, log 74896, pages 74865-74867 and 84249 (List, added by writer CC), test codeunit 74895
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a Card, a Document and a ListPlus page over a table without rows, opened with TestPage.OpenEdit and OpenView: the order of OnOpenPage, OnNewRecord,
//   OnAfterGetRecord and OnAfterGetCurrRecord (each logs the Rec fields it sees) and the control values the TestPage shows afterwards. The same pages over a
//   table with one row as the contrast. Settles the assumption listplus-blank-record-on-empty-view.
//   Writer CC (corpus issue 667, "Triggers repeat in edit mode on empty page"): a List page over the empty table runs OnNewRecord and
//   OnAfterGetCurrRecord twice on OpenEdit and neither on OpenView (OnInit and OnOpenPage once each).
// BC versions: all (CI)

table 74865 "LT PTE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { InitValue = 'init'; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 74896 "LT PTE Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

page 74865 "LT PTE Card"
{
    PageType = Card;
    SourceTable = "LT PTE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnOpenPage code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnNewRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetCurrRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;
}

page 74866 "LT PTE Document"
{
    PageType = Document;
    SourceTable = "LT PTE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnOpenPage code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnNewRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetCurrRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;
}

page 74867 "LT PTE ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT PTE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnOpenPage code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnNewRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetCurrRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;
}

page 84249 "LT CC PTE List"
{
    PageType = List;
    SourceTable = "LT PTE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnOpenPage code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnNewRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PTE Log";
    begin
        Log.Add('OnAfterGetCurrRecord code=[' + Rec."Code" + '] name=[' + Rec.Name + ']');
    end;
}

codeunit 74895 "LT PTE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT PTE Log";

    local procedure Prepare(WithRow: Boolean)
    var
        Row: Record "LT PTE Row";
    begin
        Row.DeleteAll();
        if WithRow then begin
            Row.Init();
            Row."Code" := 'R1';
            Row.Name := 'row one';
            Row.Insert();
        end;
        Log.Take();
    end;

    [Test]
    procedure Card_OpenEdit_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE Card";
    begin
        Prepare(false);
        TP.OpenEdit();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        Observer.Observe('codeEditable', Format(TP."Code".Editable()));
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];OnNewRecord code=[] name=[init];OnAfterGetCurrRecord code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('name', '');
        Observer.Expect('codeEditable', 'No');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenView_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE Card";
    begin
        Prepare(false);
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        Observer.Observe('codeEditable', Format(TP."Code".Editable()));
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('name', '');
        Observer.Expect('codeEditable', 'No');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure Document_OpenEdit_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE Document";
    begin
        Prepare(false);
        TP.OpenEdit();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        Observer.Observe('codeEditable', Format(TP."Code".Editable()));
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];OnNewRecord code=[] name=[init];OnAfterGetCurrRecord code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('name', '');
        Observer.Expect('codeEditable', 'No');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure Document_OpenView_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE Document";
    begin
        Prepare(false);
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        Observer.Observe('codeEditable', Format(TP."Code".Editable()));
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('name', '');
        Observer.Expect('codeEditable', 'No');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_OpenEdit_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE ListPlus";
    begin
        Prepare(false);
        TP.OpenEdit();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        Observer.Observe('codeEditable', Format(TP."Code".Editable()));
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];OnNewRecord code=[] name=[init];OnAfterGetCurrRecord code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('name', '');
        Observer.Expect('codeEditable', 'No');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_OpenView_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE ListPlus";
    begin
        Prepare(false);
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        Observer.Observe('codeEditable', Format(TP."Code".Editable()));
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('name', '');
        Observer.Expect('codeEditable', 'No');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenEdit_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE Card";
    begin
        Prepare(true);
        TP.OpenEdit();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        TP.Close();
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];OnAfterGetRecord code=[R1] name=[row one];OnAfterGetCurrRecord code=[R1] name=[row one];');
        Observer.Expect('code', 'R1');
        Observer.Expect('name', 'row one');
        Observer.Verify();
    end;

    [Test]
    procedure Document_OpenView_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE Document";
    begin
        Prepare(true);
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        TP.Close();
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];OnAfterGetRecord code=[R1] name=[row one];OnAfterGetCurrRecord code=[R1] name=[row one];');
        Observer.Expect('code', 'R1');
        Observer.Expect('name', 'row one');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_OpenView_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PTE ListPlus";
    begin
        Prepare(true);
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        Observer.Observe('name', TP.Name.Value());
        TP.Close();
        Observer.Expect('log', 'OnOpenPage code=[] name=[init];OnAfterGetRecord code=[R1] name=[row one];OnAfterGetCurrRecord code=[R1] name=[row one];');
        Observer.Expect('code', 'R1');
        Observer.Expect('name', 'row one');
        Observer.Verify();
    end;

    // Added by writer CC (corpus issue 667, item 37): a List page over the empty table, opened with OpenEdit and OpenView.
    [Test]
    procedure List_OpenEdit_EmptyTable_CC()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT CC PTE List";
    begin
        Prepare(false);
        TP.OpenEdit();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnInit;OnOpenPage code=[] name=[init];OnNewRecord code=[] name=[init];OnAfterGetCurrRecord code=[] name=[init];OnNewRecord code=[] name=[init];OnAfterGetCurrRecord code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenView_EmptyTable_CC()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT CC PTE List";
    begin
        Prepare(false);
        TP.OpenView();
        Observer.Observe('log', Log.Take());
        Observer.Observe('code', TP."Code".Value());
        TP.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Expect('log', 'OnInit;OnOpenPage code=[] name=[init];');
        Observer.Expect('code', '');
        Observer.Expect('logClose', '');
        Observer.Verify();
    end;
}
