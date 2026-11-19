// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openedit-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75640, page 75641, log codeunit 75642, test codeunit 75643
// local object: an editable List with no CardPageId, so the built-in View and Edit switch the list itself (as testpage/R6977ListAfterView.al)
// Probe (al-runner 8501): one TestPage variable opens the list, switches it with the built-in View (and Edit back), closes it and opens
//   it again with OpenEdit, OpenView or OpenNew. Neighbors: View only before Close, Edit on a list opened for view, a plain
//   Close/OpenEdit as the contrast, a second switch on the reopened page, a value typed before Close, OpenEdit on a page still open.
// Observed: the trigger log of each step (open = OnOpenPage, agr(N) = OnAfterGetRecord, agcr(N) = OnAfterGetCurrRecord, new =
//   OnNewRecord, close = OnClosePage), Editable of the page and of Description, Enabled of the built-in Edit and View, the row the page
//   stands on, the page global Opens (OnOpenPage counts it up), a First/Next walk (visited rows and count) and the stored rows.
// Facts: (filled from the observation)
// BC versions: 27, 28, 29

table 75640 "RLS Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(2; Description; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 75641 "RLS Lines"
{
    PageType = List;
    SourceTable = "RLS Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Opens; OpenCount) { ApplicationArea = All; Caption = 'Opens'; Editable = false; }
            }
        }
    }

    var
        Log: Codeunit "RLS Log";
        OpenCount: Integer;

    trigger OnOpenPage()
    begin
        OpenCount += 1;
        Log.Add('open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr(' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Format(Rec."Line No.") + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('new');
    end;

    trigger OnClosePage()
    begin
        Log.Add('close');
    end;
}

codeunit 75642 "RLS Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
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
}

codeunit 75643 "RLS Reopen After Switch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RLS Log";

    local procedure Initialize()
    var
        Line: Record "RLS Line";
    begin
        Line.DeleteAll();
        AddLine(10000, 'a');
        AddLine(20000, 'b');
        AddLine(30000, 'c');
        Commit();
        Log.Reset();
        ClearLastError();
    end;

    local procedure AddLine(LineNo: Integer; Descr: Text[30])
    var
        Line: Record "RLS Line";
    begin
        Line.Init();
        Line."Line No." := LineNo;
        Line.Description := Descr;
        Line.Insert();
    end;

    local procedure Stored() Result: Text
    var
        Line: Record "RLS Line";
    begin
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + '/' + Line.Description + ';';
            until Line.Next() = 0;
    end;

    local procedure Step(Name: Text)
    begin
        Observer.Observe(Name, Log.Take());
    end;

    local procedure Modes(var P: TestPage "RLS Lines"; Prefix: Text)
    begin
        Observer.Observe(Prefix + 'page', Format(P.Editable()));
        Observer.Observe(Prefix + 'desc', Format(P.Description.Editable()));
        Observer.Observe(Prefix + 'editEnabled', Format(P.Edit().Enabled()));
        Observer.Observe(Prefix + 'viewEnabled', Format(P.View().Enabled()));
    end;

    local procedure Reads(var P: TestPage "RLS Lines"; Prefix: Text)
    begin
        Modes(P, Prefix);
        Observer.Observe(Prefix + 'row', P."Line No.".Value() + '/' + P.Description.Value());
        Observer.Observe(Prefix + 'opens', P.Opens.Value());
        Step(Prefix + 'reads log');
    end;

    local procedure Walk(var P: TestPage "RLS Lines"; Name: Text)
    var
        Visited: Text;
        Counter: Integer;
    begin
        if P.First() then
            repeat
                Counter += 1;
                Visited += P."Line No.".Value() + '/' + P.Description.Value() + ';';
            until (not P.Next()) or (Counter > 10);
        Observer.Observe(Name, Visited + ' n=' + Format(Counter));
        Step(Name + ' log');
    end;

    local procedure OpenSwitchClose(var P: TestPage "RLS Lines"; WithEdit: Boolean)
    begin
        P.OpenEdit();
        P.First();
        Step('open-1');
        P.View().Invoke();
        Step('view-1');
        if WithEdit then begin
            P.Edit().Invoke();
            Step('edit-1');
        end;
        P.Close();
        Step('close-1');
    end;

    // The reported shape: OpenEdit, View, Edit, Close, then OpenEdit on the same variable.
    [Test]
    procedure ViewEdit_Close_OpenEdit_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, true);
        P.OpenEdit();
        Step('open-2');
        Reads(P, 'reopened|');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure ViewEdit_Close_OpenEdit_Walk()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, true);
        P.OpenEdit();
        Step('open-2');
        Walk(P, 'walk');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    // The reopened page switches again: View, then Edit.
    [Test]
    procedure ViewEdit_Close_OpenEdit_SwitchAgain()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, true);
        P.OpenEdit();
        P.First();
        Step('open-2');
        P.View().Invoke();
        Step('view-2');
        Modes(P, 'view2|');
        P.Edit().Invoke();
        Step('edit-2');
        Modes(P, 'edit2|');
        Observer.Observe('edit2|row', P."Line No.".Value());
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    // A value typed after the switch back is stored at Close and shown by the reopened page.
    [Test]
    procedure ViewEdit_SetValue_Close_OpenEdit_ShowsValue()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        P.OpenEdit();
        P.First();
        P.View().Invoke();
        P.Edit().Invoke();
        P.Description.SetValue('x');
        Step('typed log');
        P.Close();
        Step('close-1');
        Observer.Observe('stored-1', Stored());
        P.OpenEdit();
        Step('open-2');
        Observer.Observe('reopened|row', P."Line No.".Value() + '/' + P.Description.Value());
        P.Description.SetValue('y');
        P.Close();
        Step('close-2');
        Observer.Observe('stored-2', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure ViewEdit_Close_OpenView_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, true);
        P.OpenView();
        Step('open-2');
        Reads(P, 'reopened|');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure ViewEdit_Close_OpenView_WalkThenEdit()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, true);
        P.OpenView();
        Step('open-2');
        Walk(P, 'walk');
        P.First();
        P.Edit().Invoke();
        Step('edit-2');
        Modes(P, 'edit2|');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure ViewEdit_Close_OpenNew_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, true);
        P.OpenNew();
        Step('open-2');
        Reads(P, 'reopened|');
        P."Line No.".SetValue(40000);
        P.Description.SetValue('n');
        Step('typed log');
        P.Close();
        Step('close-2');
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    // View only (the list is still in view when it closes).
    [Test]
    procedure View_Close_OpenEdit_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, false);
        P.OpenEdit();
        Step('open-2');
        Reads(P, 'reopened|');
        Walk(P, 'walk');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure View_Close_OpenView_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, false);
        P.OpenView();
        Step('open-2');
        Reads(P, 'reopened|');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure View_Close_OpenNew_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        OpenSwitchClose(P, false);
        P.OpenNew();
        Step('open-2');
        Reads(P, 'reopened|');
        P.Close();
        Step('close-2');
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    // Opened for view, Edit invoked (it switches nothing on a list opened for view), closed, opened for edit.
    [Test]
    procedure OpenView_Edit_Close_OpenEdit_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        P.OpenView();
        P.First();
        Step('open-1');
        P.Edit().Invoke();
        Step('edit-1');
        Modes(P, 'edit1|');
        P.Close();
        Step('close-1');
        P.OpenEdit();
        Step('open-2');
        Reads(P, 'reopened|');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    // The contrast: no switch before Close.
    [Test]
    procedure Close_OpenEdit_Reads()
    var
        P: TestPage "RLS Lines";
    begin
        Initialize();
        P.OpenEdit();
        P.First();
        Step('open-1');
        P.Close();
        Step('close-1');
        P.OpenEdit();
        Step('open-2');
        Reads(P, 'reopened|');
        Walk(P, 'walk');
        P.Close();
        Step('close-2');
        Observer.Finish();
    end;

    // OpenEdit on the variable while the switched page is still open.
    [Test]
    procedure ViewEdit_OpenEditWithoutClose()
    var
        P: TestPage "RLS Lines";
        Txt: Text;
    begin
        Initialize();
        P.OpenEdit();
        P.First();
        P.View().Invoke();
        P.Edit().Invoke();
        Step('switched log');
        asserterror begin
            P.OpenEdit();
            Error('NO_ERROR');
        end;
        Txt := GetLastErrorText();
        if Txt = 'NO_ERROR' then
            Txt := 'ok';
        ClearLastError();
        Observer.Observe('second open', Txt);
        Step('second open log');
        Modes(P, 'after|');
        P.Close();
        Step('close');
        Observer.Finish();
    end;
}
