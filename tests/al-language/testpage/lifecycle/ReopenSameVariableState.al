// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75370, pages 75371 75372 75373, log codeunit 75374, test codeunit 75375
// Probe (al-runner 7645): what a TestPage variable carries into its second open. Each test reaches a state on the first open (an action
//   ran; a save failed in the table's OnModify; a save was aborted by OnModifyRecord returning false; a control bound to a page variable
//   on a page without a source table was set; a row of a temporary list was deleted under the cursor), closes the page, opens the same
//   variable again and repeats the call.
// Observed per step: 'ok' or the error text of the step (each step that can raise runs inside asserterror with a NO_ERROR marker), the
//   log since the last step (open = OnOpenPage, agcr(X) = OnAfterGetCurrRecord, M(X) = OnModifyRecord with the Name, T-mod(X) = the
//   table's OnModify, act(X) = the action on row X, read=V = the variable a no-source action reads, del(X) = the temporary row deleted,
//   close = OnClosePage) and, where it matters, the stored rows.
// local object: the pages are the states under test
// BC versions: 27, 28, 29

table 75370 "PG6 FL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "PG6 FL Log";
    begin
        Log.Add('T-mod(' + Rec."Code" + ' ' + Rec.Name + ')');
        if Rec.Name = 'FAILMOD' then
            Error('PG6 FL table modify refused');
    end;
}

page 75371 "PG6 FL Card"
{
    PageType = Card;
    SourceTable = "PG6 FL Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('act(' + Rec."Code" + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 FL Log";

    trigger OnOpenPage()
    begin
        Log.Add('open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Rec."Code" + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M(' + Rec."Code" + ' ' + Rec.Name + ')');
        exit(Rec.Name <> 'DENY');
    end;

    trigger OnClosePage()
    begin
        Log.Add('close');
    end;
}

page 75372 "PG6 FL No Source"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(VarCtl; Txt) { ApplicationArea = All; Caption = 'Txt'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadVar)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('read=' + Txt);
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 FL Log";
        Txt: Text[30];

    trigger OnOpenPage()
    begin
        Log.Add('open');
    end;

    trigger OnClosePage()
    begin
        Log.Add('close');
    end;
}

page 75373 "PG6 FL Temp List"
{
    PageType = List;
    SourceTable = "PG6 FL Row";
    SourceTableTemporary = true;
    Editable = false;
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

    actions
    {
        area(Processing)
        {
            action(DelCur)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('del(' + Rec."Code" + ')');
                    Rec.Delete();
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 FL Log";

    trigger OnOpenPage()
    var
        Row: Record "PG6 FL Row";
    begin
        if Row.FindSet() then
            repeat
                Rec := Row;
                Rec.Insert();
            until Row.Next() = 0;
        Log.Add('open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Rec."Code" + ')');
    end;

    trigger OnClosePage()
    begin
        Log.Add('close');
    end;
}

codeunit 75374 "PG6 FL Log"
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

codeunit 75375 "PG6 FL Reopen State"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG6 FL Log";

    local procedure Initialize()
    var
        Row: Record "PG6 FL Row";
    begin
        Observer.Discard();
        Row.DeleteAll();
        AddRow('R1', 'one');
        AddRow('R2', 'two');
        AddRow('R3', 'three');
        // asserterror rolls back the uncommitted writes of the test
        Commit();
        Log.Reset();
        ClearLastError();
    end;

    local procedure AddRow(RowCode: Code[10]; RowName: Text[30])
    var
        Row: Record "PG6 FL Row";
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row.Name := RowName;
        Row.Insert();
    end;

    local procedure Names() Result: Text
    var
        Row: Record "PG6 FL Row";
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
    end;

    local procedure Say(Name: Text)
    begin
        Observer.Observe(Name, Log.Take());
    end;

    // The text of the error the asserterror block caught, or ok when it reached the NO_ERROR marker.
    local procedure SayEnd(Name: Text)
    var
        Txt: Text;
    begin
        Txt := GetLastErrorText();
        if Txt = 'NO_ERROR' then
            Txt := 'ok';
        ClearLastError();
        Observer.Observe(Name, Txt + ' ' + Log.Take());
    end;

    [Test]
    procedure ActionRan_CloseReopen_InvokeAgain()
    var
        P: TestPage "PG6 FL Card";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        Say('open-1');
        P.Act.Invoke();
        Say('act-1');
        P.Close();
        Say('close-1');
        P.OpenEdit();
        P.GoToKey('R2');
        Say('open-2');
        P.Act.Invoke();
        Say('act-2');
        P.Next();
        Say('next-2');
        P.Close();
        Say('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure SaveFailed_CloseReopen_SaveAgain()
    var
        P: TestPage "PG6 FL Card";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        Say('open-1');
        P.Name.SetValue('FAILMOD');
        Say('setvalue-1');
        asserterror begin
            P.Next();
            Error('NO_ERROR');
        end;
        SayEnd('next-1');
        asserterror begin
            P.Close();
            Error('NO_ERROR');
        end;
        SayEnd('close-1');
        Observer.Observe('rows-1', Names());
        P.OpenEdit();
        P.GoToKey('R2');
        Say('open-2');
        P.Name.SetValue('edited');
        Say('setvalue-2');
        asserterror begin
            P.Next();
            Observer.Observe('rows-in-2', Names());
            Error('NO_ERROR');
        end;
        SayEnd('next-2');
        asserterror begin
            P.Close();
            Error('NO_ERROR');
        end;
        SayEnd('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure SaveAborted_CloseReopen_SaveAgain()
    var
        P: TestPage "PG6 FL Card";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('R1');
        Say('open-1');
        P.Name.SetValue('DENY');
        Say('setvalue-1');
        asserterror begin
            P.Next();
            Observer.Observe('rows-in-1', Names());
            Error('NO_ERROR');
        end;
        SayEnd('next-1');
        asserterror begin
            P.Close();
            Error('NO_ERROR');
        end;
        SayEnd('close-1');
        P.OpenEdit();
        P.GoToKey('R2');
        Say('open-2');
        P.Name.SetValue('edited');
        Say('setvalue-2');
        asserterror begin
            P.Next();
            Observer.Observe('rows-in-2', Names());
            Error('NO_ERROR');
        end;
        SayEnd('next-2');
        asserterror begin
            P.Close();
            Error('NO_ERROR');
        end;
        SayEnd('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceVariableSet_CloseReopen_ReadAgain()
    var
        P: TestPage "PG6 FL No Source";
    begin
        Initialize();
        P.OpenEdit();
        Say('open-1');
        P.VarCtl.SetValue('first');
        P.ReadVar.Invoke();
        Say('read-1');
        P.Close();
        Say('close-1');
        P.OpenEdit();
        Observer.Observe('value-2', P.VarCtl.Value());
        P.ReadVar.Invoke();
        Say('read-2');
        P.VarCtl.SetValue('second');
        P.ReadVar.Invoke();
        Say('read-2b');
        P.Close();
        Say('close-2');
        Observer.Finish();
    end;

    [Test]
    procedure TempListRowGone_CloseReopen_DeleteAgain()
    var
        P: TestPage "PG6 FL Temp List";
    begin
        Initialize();
        P.OpenView();
        P.GoToKey('R2');
        Say('open-1');
        P.DelCur.Invoke();
        Observer.Observe('cursor-1', P."Code".Value());
        Say('del-1');
        asserterror begin
            P.Next();
            Observer.Observe('next-in-1', P."Code".Value());
            Error('NO_ERROR');
        end;
        SayEnd('next-1');
        P.Close();
        Say('close-1');
        P.OpenView();
        Observer.Observe('first-2', P."Code".Value());
        P.GoToKey('R2');
        Say('open-2');
        P.DelCur.Invoke();
        Observer.Observe('cursor-2', P."Code".Value());
        Say('del-2');
        asserterror begin
            P.Next();
            Observer.Observe('next-in-2', P."Code".Value());
            Error('NO_ERROR');
        end;
        SayEnd('next-2');
        P.Close();
        Say('close-2');
        Observer.Observe('rows', Names());
        Observer.Finish();
    end;
}
