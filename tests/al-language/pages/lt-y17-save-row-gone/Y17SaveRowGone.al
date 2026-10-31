// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT Y17 SR *)
// Probe (gap cycle 1, G12): what a page does with its changed row when that row is no longer stored under the key it has.
//   A: a StandardDialog over a TEMPORARY source (the Select Sending Options shape) whose field OnValidate changes the primary key
//      (Rec.Code := 'CUSTOM'), run with Page.RunModal(Id, Temp); the handler sets fields and presses OK: what the var record holds after.
//   B: a page action hands Rec to a codeunit that modifies and deletes the stored row (the Make Order / Post shape), after a SetValue.
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 91796 "LT Y17 SR Profile"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Printer; Option) { OptionMembers = No,Yes; }
        field(3; Mail; Boolean) { }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        LogT('T.OnInsert');
    end;

    trigger OnModify()
    begin
        LogT('T.OnModify');
    end;

    trigger OnDelete()
    begin
        LogT('T.OnDelete');
    end;

    trigger OnRename()
    begin
        LogT('T.OnRename');
    end;

    local procedure LogT(Name: Text)
    var
        Log: Codeunit "LT Y17 SR Log";
    begin
        Log.Add(Name + ':' + Rec.Code + ' x=' + xRec.Code + ' temp=' + Format(Rec.IsTemporary()));
    end;
}

codeunit 91803 "LT Y17 SR Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CopyFromReal: Boolean;

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

    procedure SetCopyFromReal(Value: Boolean)
    begin
        CopyFromReal := Value;
    end;

    procedure GetCopyFromReal(): Boolean
    begin
        exit(CopyFromReal);
    end;
}

page 91797 "LT Y17 SR Options"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 SR Profile";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Printer; Rec.Printer)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Rec.Code := 'CUSTOM';
                    Log.Add('P.Printer.OnValidate:' + Rec.Code);
                end;
            }
            field(Mail; Rec.Mail)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Rec.Code := 'CUSTOM';
                    Log.Add('P.Mail.OnValidate:' + Rec.Code);
                end;
            }
            field(Note; Rec.Note) { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "LT Y17 SR Log";

    trigger OnOpenPage()
    begin
        Log.Add('P.OnOpenPage:' + Rec.Code);
        CurrPage.LookupMode := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        Real: Record "LT Y17 SR Profile";
    begin
        Log.Add('P.AGCR:' + Rec.Code);
        if Log.GetCopyFromReal() then
            if Real.Get(Rec.Code) then
                Rec.Copy(Real);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.OnModifyRecord:' + Rec.Code + ' x=' + xRec.Code);
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.OnInsertRecord:' + Rec.Code);
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('P.OnQueryClosePage:' + Format(CloseAction) + ':' + Rec.Code);
        exit(true);
    end;
}

page 91798 "LT Y17 SR Options Stored"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 SR Profile";

    layout
    {
        area(Content)
        {
            field(Printer; Rec.Printer)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Rec.Code := 'CUSTOM';
                    Log.Add('P.Printer.OnValidate:' + Rec.Code);
                end;
            }
            field(Mail; Rec.Mail)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Rec.Code := 'CUSTOM';
                    Log.Add('P.Mail.OnValidate:' + Rec.Code);
                end;
            }
            field(Note; Rec.Note) { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "LT Y17 SR Log";

    trigger OnOpenPage()
    begin
        Log.Add('P.OnOpenPage:' + Rec.Code);
        CurrPage.LookupMode := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR:' + Rec.Code);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.OnModifyRecord:' + Rec.Code + ' x=' + xRec.Code);
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('P.OnQueryClosePage:' + Format(CloseAction) + ':' + Rec.Code);
        exit(true);
    end;
}

table 91799 "LT Y17 SR Doc"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Done; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        LogT('T.OnInsert');
    end;

    trigger OnModify()
    begin
        LogT('T.OnModify');
    end;

    trigger OnDelete()
    begin
        LogT('T.OnDelete');
    end;

    local procedure LogT(Name: Text)
    var
        Log: Codeunit "LT Y17 SR Log";
    begin
        Log.Add(Name + ':' + Rec."No." + '/' + Rec.Name + '/' + Format(Rec.Done));
    end;
}

codeunit 91802 "LT Y17 SR Finish"
{
    TableNo = "LT Y17 SR Doc";

    trigger OnRun()
    var
        Log: Codeunit "LT Y17 SR Log";
    begin
        Log.Add('CB.start:' + Rec."No." + '/' + Rec.Name);
        Rec.Done := true;
        Rec.Modify();
        Rec.Delete();
        Log.Add('CB.end');
    end;
}

page 91800 "LT Y17 SR Doc Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 SR Doc";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Done; Rec.Done) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Finish)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('P.Finish:' + Rec."No." + '/' + Rec.Name);
                    Codeunit.Run(Codeunit::"LT Y17 SR Finish", Rec);
                    Log.Add('P.Finish.after:' + Rec."No." + '/' + Rec.Name + '/' + Format(Rec.Done));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y17 SR Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR:' + Rec."No." + '/' + Rec.Name);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.OnModifyRecord:' + Rec."No." + '/' + Rec.Name);
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.OnInsertRecord:' + Rec."No." + '/' + Rec.Name);
        exit(true);
    end;
}

page 91801 "LT Y17 SR Doc List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 SR Doc";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Done; Rec.Done) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Finish)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('P.Finish:' + Rec."No." + '/' + Rec.Name);
                    Codeunit.Run(Codeunit::"LT Y17 SR Finish", Rec);
                    Log.Add('P.Finish.after:' + Rec."No." + '/' + Rec.Name + '/' + Format(Rec.Done));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y17 SR Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR:' + Rec."No." + '/' + Rec.Name);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.OnModifyRecord:' + Rec."No." + '/' + Rec.Name);
        exit(true);
    end;
}

codeunit 91804 "LT Y17 SR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y17 SR Log";
        Mode: Text;

    local procedure ObserveTemp(var Observer: Codeunit "Probe Observer"; var Temp: Record "LT Y17 SR Profile" temporary)
    begin
        Observer.Observe('temp', Temp.Code + '/' + Format(Temp.Printer) + '/' + Format(Temp.Mail) + '/' + Temp.Note);
        Observer.Observe('temp count', Format(Temp.Count()));
        Observer.Observe('temp get DEF', Format(Temp.Get('DEF')));
        Observer.Observe('temp get CUSTOM', Format(Temp.Get('CUSTOM')));
    end;

    local procedure StoredProfiles(): Text
    var
        Real: Record "LT Y17 SR Profile";
        Result: Text;
    begin
        if Real.FindSet() then
            repeat
                Result += Real.Code + '/' + Format(Real.Printer) + '/' + Format(Real.Mail) + '/' + Real.Note + ';';
            until Real.Next() = 0;
        exit(Result);
    end;

    local procedure StoredDocs(): Text
    var
        Doc: Record "LT Y17 SR Doc";
        Result: Text;
    begin
        if Doc.FindSet() then
            repeat
                Result += Doc."No." + '/' + Doc.Name + '/' + Format(Doc.Done) + ';';
            until Doc.Next() = 0;
        exit(Result);
    end;

    local procedure RunTemp(var Observer: Codeunit "Probe Observer")
    var
        Temp: Record "LT Y17 SR Profile" temporary;
        Result: Action;
    begin
        Temp.Init();
        Temp.Code := 'DEF';
        Temp.Note := 'temp';
        Temp.Insert();
        Commit();
        Observer.Observe('before', Log.Take());
        Result := Page.RunModal(Page::"LT Y17 SR Options", Temp);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        ObserveTemp(Observer, Temp);
        Observer.Observe('stored', StoredProfiles());
    end;

    local procedure Reset()
    var
        Real: Record "LT Y17 SR Profile";
        Doc: Record "LT Y17 SR Doc";
    begin
        Real.DeleteAll();
        Doc.DeleteAll();
        Log.SetCopyFromReal(false);
        Log.Take();
    end;

    [Test]
    [HandlerFunctions('OptionsHandler')]
    procedure PgSave_TempKeyChangedByValidate_LookupOK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Mode := 'set';
        RunTemp(Observer);
        Reset();
        Observer.Expect('before', '');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'P.OnOpenPage:DEF;P.AGCR:DEF;handler:set;P.Printer.OnValidate:CUSTOM;P.Mail.OnValidate:CUSTOM;note=temp;T.OnRename:CUSTOM x=DEF temp=Yes;P.OnQueryClosePage:LookupOK:CUSTOM;handler end;');
        Observer.Expect('temp', 'CUSTOM/Yes/Yes/temp');
        Observer.Expect('temp count', '1');
        Observer.Expect('temp get DEF', 'No');
        Observer.Expect('temp get CUSTOM', 'Yes');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionsHandler')]
    procedure PgSave_TempKeyChangedByValidate_CopyFromReal()
    var
        Observer: Codeunit "Probe Observer";
        Real: Record "LT Y17 SR Profile";
    begin
        Reset();
        Real.Init();
        Real.Code := 'DEF';
        Real.Printer := Real.Printer::No;
        Real.Note := 'stored';
        Real.Insert();
        Log.SetCopyFromReal(true);
        Log.Take();
        Mode := 'set';
        RunTemp(Observer);
        Reset();
        Observer.Expect('before', '');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'P.OnOpenPage:DEF;P.AGCR:DEF;handler:set;P.Printer.OnValidate:CUSTOM;P.Mail.OnValidate:CUSTOM;note=stored;T.OnRename:CUSTOM x=DEF temp=Yes;P.OnQueryClosePage:LookupOK:CUSTOM;handler end;');
        Observer.Expect('temp', 'CUSTOM/Yes/Yes/stored');
        Observer.Expect('temp count', '1');
        Observer.Expect('temp get DEF', 'No');
        Observer.Expect('temp get CUSTOM', 'Yes');
        Observer.Expect('stored', 'DEF/No/No/stored;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionsHandler')]
    procedure PgSave_TempNoKeyChange_ReadOnlyOK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Mode := 'read';
        RunTemp(Observer);
        Reset();
        Observer.Expect('before', '');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'P.OnOpenPage:DEF;P.AGCR:DEF;handler:read;note=temp;P.OnQueryClosePage:LookupOK:DEF;handler end;');
        Observer.Expect('temp', 'DEF/No/No/temp');
        Observer.Expect('temp count', '1');
        Observer.Expect('temp get DEF', 'Yes');
        Observer.Expect('temp get CUSTOM', 'No');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionsHandler')]
    procedure PgSave_TempKeyChangedByValidate_Cancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Mode := 'cancel';
        RunTemp(Observer);
        Reset();
        Observer.Expect('before', '');
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('log', 'P.OnOpenPage:DEF;P.AGCR:DEF;handler:cancel;P.Printer.OnValidate:CUSTOM;T.OnRename:CUSTOM x=DEF temp=Yes;P.AGCR:CUSTOM;P.OnQueryClosePage:LookupCancel:CUSTOM;handler end;');
        Observer.Expect('temp', 'CUSTOM/Yes/No/temp');
        Observer.Expect('temp count', '1');
        Observer.Expect('temp get DEF', 'No');
        Observer.Expect('temp get CUSTOM', 'Yes');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionsStoredHandler')]
    procedure PgSave_StoredKeyChangedByValidate_LookupOK()
    var
        Observer: Codeunit "Probe Observer";
        Real: Record "LT Y17 SR Profile";
        Result: Action;
    begin
        Reset();
        Real.Init();
        Real.Code := 'DEF';
        Real.Note := 'stored';
        Real.Insert();
        Commit();
        Log.Take();
        Real.Get('DEF');
        Result := Page.RunModal(Page::"LT Y17 SR Options Stored", Real);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('var', Real.Code + '/' + Format(Real.Printer) + '/' + Format(Real.Mail) + '/' + Real.Note);
        Observer.Observe('stored', StoredProfiles());
        Reset();
        Commit();
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'P.OnOpenPage:DEF;P.AGCR:DEF;handler;P.Printer.OnValidate:CUSTOM;P.Mail.OnValidate:CUSTOM;T.OnRename:CUSTOM x=DEF temp=No;P.OnQueryClosePage:LookupOK:CUSTOM;handler end;');
        Observer.Expect('var', 'CUSTOM/Yes/Yes/stored');
        Observer.Expect('stored', 'CUSTOM/Yes/Yes/stored;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure OptionsHandler(var P: TestPage "LT Y17 SR Options")
    begin
        Log.Add('handler:' + Mode);
        case Mode of
            'read':
                begin
                    Log.Add('note=' + P.Note.Value());
                    P.OK().Invoke();
                end;
            'cancel':
                begin
                    P.Printer.SetValue('Yes');
                    P.Cancel().Invoke();
                end;
            else begin
                P.Printer.SetValue('Yes');
                P.Mail.SetValue(true);
                Log.Add('note=' + P.Note.Value());
                P.OK().Invoke();
            end;
        end;
        Log.Add('handler end');
    end;

    [ModalPageHandler]
    procedure OptionsStoredHandler(var P: TestPage "LT Y17 SR Options Stored")
    begin
        Log.Add('handler');
        P.Printer.SetValue('Yes');
        P.Mail.SetValue(true);
        P.OK().Invoke();
        Log.Add('handler end');
    end;

    local procedure SeedDocs()
    var
        Doc: Record "LT Y17 SR Doc";
    begin
        Reset();
        Doc.Init();
        Doc."No." := 'A';
        Doc.Name := 'a';
        Doc.Insert();
        Doc.Init();
        Doc."No." := 'B';
        Doc.Name := 'b';
        Doc.Insert();
        Commit();
        Log.Take();
    end;

    [Test]
    procedure PgSave_ActionDeletesEditedRow_Card()
    begin
        CardCase(true);
    end;

    [Test]
    procedure PgSave_ActionDeletesRow_NoEdit_Card()
    begin
        CardCase(false);
    end;

    local procedure CardCase(Edit: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y17 SR Doc Card";
    begin
        SeedDocs();
        P.OpenEdit();
        P.GoToKey('A');
        Observer.Observe('open', Log.Take());
        if Edit then begin
            P.Name.SetValue('edited');
            Observer.Observe('setvalue', Log.Take());
        end;
        ClearLastError();
        Observer.Observe('invoke ok', Format(TryInvoke(P)));
        Observer.ObserveError('invoke');
        Observer.Observe('invoke log', Log.Take());
        Observer.Observe('stored after invoke', StoredDocs());
        Observer.Observe('read ok', Format(TryRead(P)));
        Observer.ObserveError('read');
        Observer.Observe('read log', Log.Take());
        Observer.Observe('close ok', Format(TryClose(P)));
        Observer.ObserveError('close');
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredDocs());
        Reset();
        Observer.Expect('open', 'P.AGCR:A/a;P.AGCR:A/a;');
        if Edit then
            Observer.Expect('setvalue', '');
        Observer.Expect('invoke ok', 'Yes');
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', 'PageCloseRequest');
        if Edit then
            Observer.Expect('invoke log', 'P.OnModifyRecord:A/edited;T.OnModify:A/edited/No;P.Finish:A/edited;CB.start:A/edited;CB.end;P.Finish.after:A/edited/Yes;')
        else
            Observer.Expect('invoke log', 'P.Finish:A/a;CB.start:A/a;CB.end;P.Finish.after:A/a/Yes;');
        Observer.Expect('stored after invoke', 'B/b/No;');
        Observer.Expect('read ok', 'No');
        Observer.Expect('read|text', 'The TestPage is not open.');
        Observer.Expect('read|code', 'TestPageNotOpened');
        Observer.Expect('read log', '');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B/b/No;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryInvoke(var P: TestPage "LT Y17 SR Doc Card")
    begin
        P.Finish.Invoke();
    end;

    [TryFunction]
    local procedure TryRead(var P: TestPage "LT Y17 SR Doc Card")
    begin
        Log.Add('shown=' + P."No.".Value() + '/' + P.Name.Value() + '/' + P.Done.Value());
    end;

    [TryFunction]
    local procedure TryClose(var P: TestPage "LT Y17 SR Doc Card")
    begin
        P.Close();
    end;

    [Test]
    procedure PgSave_ActionDeletesEditedRow_List_Next()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y17 SR Doc List";
    begin
        SeedDocs();
        P.OpenEdit();
        P.GoToKey('A');
        Observer.Observe('open', Log.Take());
        P.Name.SetValue('edited');
        Observer.Observe('setvalue', Log.Take());
        P.Finish.Invoke();
        Observer.Observe('invoke', Log.Take());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('shown', P."No.".Value() + '/' + P.Name.Value() + '/' + P.Done.Value());
        Observer.Observe('read', Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored', StoredDocs());
        Reset();
        Observer.Expect('open', 'P.AGR:A;P.AGR:B;P.AGR:A;P.AGR:A;P.AGCR:A/a;');
        Observer.Expect('setvalue', '');
        Observer.Expect('invoke', 'P.OnModifyRecord:A/edited;T.OnModify:A/edited/No;P.AGR:A;P.Finish:A/edited;CB.start:A/edited;CB.end;P.Finish.after:A/edited/Yes;P.AGR:B;P.AGR:B;P.AGCR:B/b;P.AGR:B;P.AGR:B;P.AGCR:B/b;');
        Observer.Expect('next', 'Yes');
        Observer.Expect('shown', '//No');
        Observer.Expect('read', 'P.AGCR:/;');
        Observer.Expect('close', '');
        Observer.Expect('stored', 'B/b/No;');
        Observer.Verify();
    end;
}
