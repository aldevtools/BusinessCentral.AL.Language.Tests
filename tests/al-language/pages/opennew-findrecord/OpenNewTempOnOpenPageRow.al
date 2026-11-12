// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-opennew-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope (Cloud). TestPage.
// Fixtures used: Probe Observer (codeunit 69160); own tables 64860 and 64861, log codeunit 64862, pages 64863 to 64868,
//   test codeunit 64869
// Probe: observe-only. Area: TestPage.OpenNew() on a page whose OnOpenPage inserted a blank row into Rec (al-runner issue 7811;
//   the shape of Microsoft's SMTP Account Wizard, a NavigatePage over a temporary source whose OnOpenPage runs
//   `Rec.Init(); Rec.Insert();`). Cells: page type NavigatePage and Card; source temporary and a database table; the page's
//   only trigger OnOpenPage, or OnOpenPage with logging row triggers (OnNewRecord, OnAfterGetCurrRecord, OnInsertRecord,
//   OnModifyRecord, OnClosePage); OnOpenPage inserting one row or two rows.
//   Pinned nearby: testpage/CfPageLeads.al:241 Card_OnNewRecordInserts_OpenNewSetClose (OnNewRecord inserts on a database
//   Card), pages/opennew-findrecord/OpenNewFindRecord.al (OpenNew with OnFindRecord). Not pinned: the cells above.
// Observed: Editable(), the value shown after the open, whether SetValue on a non-key field raises an error (text and code),
//   the value shown after it, the row triggers that ran (N new record, C current record, I insert, M modify, X close with
//   the rows of Rec), and the rows of the database table at the end.
// local object: the page types, triggers and the temporary property are what the test checks
// BC versions: 27, 28, 29

table 64860 "PGON Setting"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Guid) { DataClassification = SystemMetadata; }
        field(2; Label; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 64861 "PGON Numbered"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { DataClassification = SystemMetadata; }
        field(2; Label; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys { key(PK; No) { Clustered = true; } }
}

codeunit 64862 "PGON Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 64863 "PGON Nav Temp"
{
    PageType = NavigatePage;
    SourceTable = "PGON Setting";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert();
    end;
}

page 64864 "PGON Nav Temp Logged"
{
    PageType = NavigatePage;
    SourceTable = "PGON Setting";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Label);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec.Label);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec.Label);
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X:' + Format(Rec.Count()) + ':' + Rec.Label);
    end;

    var
        Log: Codeunit "PGON Log";
}

page 64865 "PGON Card Temp"
{
    PageType = Card;
    SourceTable = "PGON Setting";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert();
    end;
}

page 64866 "PGON Nav Db"
{
    PageType = NavigatePage;
    SourceTable = "PGON Setting";

    layout
    {
        area(Content)
        {
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert();
    end;
}

page 64867 "PGON Nav Temp Two"
{
    PageType = NavigatePage;
    SourceTable = "PGON Numbered";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(No; Rec.No) { ApplicationArea = All; }
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.No := 1;
        Rec.Label := 'first';
        Rec.Insert();
        Rec.Init();
        Rec.No := 2;
        Rec.Label := 'second';
        Rec.Insert();
    end;

    trigger OnClosePage()
    begin
        Log.Add('X:' + Format(Rec.Count()) + ':' + Format(Rec.No) + ':' + Rec.Label);
    end;

    var
        Log: Codeunit "PGON Log";
}

page 64868 "PGON Card Temp Logged"
{
    PageType = Card;
    SourceTable = "PGON Setting";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Label);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec.Label);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec.Label);
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X:' + Format(Rec.Count()) + ':' + Rec.Label);
    end;

    var
        Log: Codeunit "PGON Log";
}

codeunit 64869 "PGON OpenNew Temp Test"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGON Log";

    local procedure Initialize()
    var
        Setting: Record "PGON Setting";
        Numbered: Record "PGON Numbered";
    begin
        Setting.DeleteAll();
        Numbered.DeleteAll();
        Log.Take();
    end;

    local procedure StoredRows(): Text
    var
        Setting: Record "PGON Setting";
    begin
        exit(Format(Setting.Count()));
    end;

    [TryFunction]
    local procedure TrySetNavTemp(var P: TestPage "PGON Nav Temp")
    begin
        P.Label.SetValue('Draft');
    end;

    [TryFunction]
    local procedure TryCloseNavTemp(var P: TestPage "PGON Nav Temp")
    begin
        P.Close();
    end;

    [Test]
    procedure NavTemp_OpenNew_SetValue_Close()
    var
        P: TestPage "PGON Nav Temp";
    begin
        Initialize();
        P.OpenNew();
        Observer.Observe('editable', Format(P.Editable()));
        Observer.Observe('shown after open', P.Label.Value());
        if TrySetNavTemp(P) then
            Observer.Observe('SetValue', 'ok')
        else
            Observer.ObserveError('SetValue error');
        Observer.Observe('shown after SetValue', P.Label.Value());
        if TryCloseNavTemp(P) then
            Observer.Observe('Close', 'ok')
        else
            Observer.ObserveError('Close error');
        Observer.Observe('stored rows', StoredRows());
        Observer.Finish();
    end;

    [Test]
    procedure NavTemp_OpenNew_Close_Twice()
    var
        P: TestPage "PGON Nav Temp";
    begin
        Initialize();
        P.OpenNew();
        P.Close();
        P.OpenNew();
        Observer.Observe('shown after the second open', P.Label.Value());
        P.Close();
        Observer.Observe('stored rows', StoredRows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetNavTempLogged(var P: TestPage "PGON Nav Temp Logged")
    begin
        P.Label.SetValue('Draft');
    end;

    [TryFunction]
    local procedure TryCloseNavTempLogged(var P: TestPage "PGON Nav Temp Logged")
    begin
        P.Close();
    end;

    [Test]
    procedure NavTempLogged_OpenNew_SetValue_Close()
    var
        P: TestPage "PGON Nav Temp Logged";
    begin
        Initialize();
        P.OpenNew();
        Observer.Observe('log of the open', Log.Take());
        Observer.Observe('shown after open', P.Label.Value());
        if TrySetNavTempLogged(P) then
            Observer.Observe('SetValue', 'ok')
        else
            Observer.ObserveError('SetValue error');
        Observer.Observe('log of SetValue', Log.Take());
        Observer.Observe('shown after SetValue', P.Label.Value());
        if TryCloseNavTempLogged(P) then
            Observer.Observe('Close', 'ok')
        else
            Observer.ObserveError('Close error');
        Observer.Observe('log of Close', Log.Take());
        Observer.Observe('stored rows', StoredRows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetCardTemp(var P: TestPage "PGON Card Temp")
    begin
        P.Label.SetValue('Draft');
    end;

    [TryFunction]
    local procedure TryCloseCardTemp(var P: TestPage "PGON Card Temp")
    begin
        P.Close();
    end;

    [Test]
    procedure CardTemp_OpenNew_SetValue_Close()
    var
        P: TestPage "PGON Card Temp";
    begin
        Initialize();
        P.OpenNew();
        Observer.Observe('shown after open', P.Label.Value());
        if TrySetCardTemp(P) then
            Observer.Observe('SetValue', 'ok')
        else
            Observer.ObserveError('SetValue error');
        Observer.Observe('shown after SetValue', P.Label.Value());
        if TryCloseCardTemp(P) then
            Observer.Observe('Close', 'ok')
        else
            Observer.ObserveError('Close error');
        Observer.Observe('stored rows', StoredRows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetCardTempLogged(var P: TestPage "PGON Card Temp Logged")
    begin
        P.Label.SetValue('Draft');
    end;

    [TryFunction]
    local procedure TryCloseCardTempLogged(var P: TestPage "PGON Card Temp Logged")
    begin
        P.Close();
    end;

    [Test]
    procedure CardTempLogged_OpenNew_SetValue_Close()
    var
        P: TestPage "PGON Card Temp Logged";
    begin
        Initialize();
        P.OpenNew();
        Observer.Observe('log of the open', Log.Take());
        if TrySetCardTempLogged(P) then
            Observer.Observe('SetValue', 'ok')
        else
            Observer.ObserveError('SetValue error');
        Observer.Observe('log of SetValue', Log.Take());
        if TryCloseCardTempLogged(P) then
            Observer.Observe('Close', 'ok')
        else
            Observer.ObserveError('Close error');
        Observer.Observe('log of Close', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetNavDb(var P: TestPage "PGON Nav Db")
    begin
        P.Label.SetValue('Draft');
    end;

    [TryFunction]
    local procedure TryCloseNavDb(var P: TestPage "PGON Nav Db")
    begin
        P.Close();
    end;

    [Test]
    procedure NavDb_OpenNew_SetValue_Close()
    var
        P: TestPage "PGON Nav Db";
        Setting: Record "PGON Setting";
    begin
        Initialize();
        P.OpenNew();
        Observer.Observe('stored rows after open', StoredRows());
        if TrySetNavDb(P) then
            Observer.Observe('SetValue', 'ok')
        else
            Observer.ObserveError('SetValue error');
        if TryCloseNavDb(P) then
            Observer.Observe('Close', 'ok')
        else
            Observer.ObserveError('Close error');
        Observer.Observe('stored rows', StoredRows());
        if Setting.FindFirst() then
            Observer.Observe('stored label', Setting.Label);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetNavTempTwo(var P: TestPage "PGON Nav Temp Two")
    begin
        P.Label.SetValue('Draft');
    end;

    [TryFunction]
    local procedure TryCloseNavTempTwo(var P: TestPage "PGON Nav Temp Two")
    begin
        P.Close();
    end;

    [Test]
    procedure NavTempTwo_OpenNew_SetValue_Close()
    var
        P: TestPage "PGON Nav Temp Two";
    begin
        Initialize();
        P.OpenNew();
        Observer.Observe('No shown after open', P.No.Value());
        Observer.Observe('Label shown after open', P.Label.Value());
        if TrySetNavTempTwo(P) then
            Observer.Observe('SetValue', 'ok')
        else
            Observer.ObserveError('SetValue error');
        Observer.Observe('No shown after SetValue', P.No.Value());
        if TryCloseNavTempTwo(P) then
            Observer.Observe('Close', 'ok')
        else
            Observer.ObserveError('Close error');
        Observer.Observe('log of Close', Log.Take());
        Observer.Finish();
    end;
}
