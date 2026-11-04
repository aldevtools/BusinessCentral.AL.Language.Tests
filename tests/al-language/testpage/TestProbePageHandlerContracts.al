// Observe-only probes (writer A). Rows: Confirm/StrMenu defaults, TestPage GetValidationError(0), control not found,
// Guid control text, BlankNumbers, SetValue of the same value, Action ordinals, OnInit before handler lookup,
// RunModal(id, Record) lookup mode, OnInsertRecord BelowxRec and missing exit, FindFirstField misses, tree members.
table 69808 "PA Hdl Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                L: Codeunit "PA Hdl Log";
            begin
                L.Add('table OnValidate Name: ' + Name);
            end;
        }
        field(3; G; Guid) { }
        field(4; Num; Decimal) { }
        field(5; Cd; Code[20]) { }
        field(6; Dt; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 69800 "PA Hdl Card"
{
    PageType = Card;
    SourceTable = "PA Hdl Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    L: Codeunit "PA Hdl Log";
                begin
                    L.Add('page OnValidate Name: ' + Rec.Name);
                end;
            }
            field(G; Rec.G) { ApplicationArea = All; }
            field(Cd; Rec.Cd) { ApplicationArea = All; }
            field(Dt; Rec.Dt) { ApplicationArea = All; }
            field(NumBlankNeg; Rec.Num) { ApplicationArea = All; BlankNumbers = BlankNeg; }
            field(NumBlankNegAndZero; Rec.Num) { ApplicationArea = All; BlankNumbers = BlankNegAndZero; }
            field(NumBlankZero; Rec.Num) { ApplicationArea = All; BlankNumbers = BlankZero; }
            field(NumBlankPos; Rec.Num) { ApplicationArea = All; BlankNumbers = BlankPos; }
            field(NumBlankZeroAndPos; Rec.Num) { ApplicationArea = All; BlankNumbers = BlankZeroAndPos; }
            field(NumPlain; Rec.Num) { ApplicationArea = All; }
            field(HiddenField; Rec.Name) { ApplicationArea = All; Visible = false; }
            field(NoAreaField; Rec.Name) { ApplicationArea = Basic; }
            field(ShowMandatoryField; Rec.Name) { ApplicationArea = All; ShowMandatory = true; }
            field(HideValueField; Rec.Name) { ApplicationArea = All; HideValue = true; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(VisibleAction) { ApplicationArea = All; trigger OnAction() begin end; }
            action(HiddenAction) { ApplicationArea = All; Visible = false; trigger OnAction() begin end; }
        }
    }

    trigger OnInit()
    var
        L: Codeunit "PA Hdl Log";
    begin
        L.Add('card OnInit');
    end;

    trigger OnOpenPage()
    var
        L: Codeunit "PA Hdl Log";
    begin
        L.Add('card OnOpenPage lookupmode=' + Format(CurrPage.LookupMode()));
    end;
}

page 69801 "PA Hdl List"
{
    PageType = List;
    SourceTable = "PA Hdl Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Cd; Rec.Cd) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        L: Codeunit "PA Hdl Log";
    begin
        L.Add('list OnOpenPage lookupmode=' + Format(CurrPage.LookupMode()));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        L: Codeunit "PA Hdl Log";
    begin
        L.Add('list OnInsertRecord BelowxRec=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    var
        L: Codeunit "PA Hdl Log";
    begin
        L.Add('list OnModifyRecord');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        L: Codeunit "PA Hdl Log";
    begin
        L.Add('list OnQueryClosePage action=' + Format(CloseAction, 0, 1));
    end;
}

page 69802 "PA Hdl OnInit Error"
{
    PageType = Card;
    SourceTable = "PA Hdl Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnInit()
    begin
        Error('error raised in OnInit');
    end;
}

codeunit 69816 "PA Page Handler Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HLog: Text;

    local procedure Seed(Id: Integer; Name: Text[30])
    var
        R: Record "PA Hdl Row";
    begin
        R.Id := Id;
        R.Name := Name;
        R.Insert(false);
    end;

    local procedure Start(var L: Codeunit "PA Hdl Log")
    var
        R: Record "PA Hdl Row";
    begin
        R.DeleteAll();
        L.Reset();
        HLog := '';
    end;

    // ------------------------------------------------------------ Confirm / StrMenu
    [Test]
    [HandlerFunctions('ConfirmH')]
    procedure Confirm_OmittedDefault()
    var
        O: Codeunit "Probe Observer";
        R: Boolean;
    begin
        HLog := '';
        R := Confirm('Q omitted default');
        O.Observe('result_omitted', Format(R));
        R := Confirm('Q default true', true);
        O.Observe('result_true', Format(R));
        R := Confirm('Q default false', false);
        O.Observe('result_false', Format(R));
        O.Observe('handler_log', HLog);
        O.Expect('result_omitted', 'No');
        O.Expect('result_true', 'Yes');
        O.Expect('result_false', 'No');
        O.Expect('handler_log', '[Q omitted default: reply_initial=No] [Q default true: reply_initial=Yes] [Q default false: reply_initial=No] ');
        O.Verify();
    end;

    [ConfirmHandler]
    procedure ConfirmH(Question: Text[1024]; var Reply: Boolean)
    begin
        HLog += '[' + Question + ': reply_initial=' + Format(Reply) + '] ';
    end;

    [Test]
    [HandlerFunctions('StrMenuH')]
    procedure StrMenu_OmittedDefaults()
    var
        O: Codeunit "Probe Observer";
        R: Integer;
    begin
        HLog := '';
        R := StrMenu('a,b,c');
        O.Observe('result_omitted', Format(R));
        R := StrMenu('a,b,c', 3);
        O.Observe('result_default3', Format(R));
        R := StrMenu('a,b,c', 2, 'Pick one');
        O.Observe('result_default2_instruction', Format(R));
        R := StrMenu('a,b,c', 0);
        O.Observe('result_default0', Format(R));
        R := StrMenu('a,b,c', 9);
        O.Observe('result_default9', Format(R));
        O.Observe('handler_log', HLog);
        O.Expect('result_omitted', '1');
        O.Expect('result_default3', '3');
        O.Expect('result_default2_instruction', '2');
        O.Expect('result_default0', '0');
        O.Expect('result_default9', '9');
        O.Expect('handler_log', '[options=a,b,c choice_initial=1 instruction=] [options=a,b,c choice_initial=3 instruction=] [options=a,b,c choice_initial=2 instruction=Pick one] [options=a,b,c choice_initial=0 instruction=] [options=a,b,c choice_initial=9 instruction=] ');
        O.Verify();
    end;

    [StrMenuHandler]
    procedure StrMenuH(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        HLog += '[options=' + Options + ' choice_initial=' + Format(Choice) + ' instruction=' + Instruction + '] ';
    end;

    // ------------------------------------------------------------ TestPage
    [Test]
    procedure TestPage_GetValidationError_Index0()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        P: TestPage "PA Hdl Card";
        T: Text;
    begin
        Start(L);
        Seed(1, 'a');
        P.OpenEdit();
        asserterror T := P.GetValidationError(0);
        O.ObserveError('getvalidationerror_0_with_no_error');
        asserterror T := P.GetValidationError(1);
        O.ObserveError('getvalidationerror_1_with_no_error');
        P.Close();
        O.Expect('getvalidationerror_0_with_no_error|text', 'Index out of bounds.');
        O.Expect('getvalidationerror_0_with_no_error|code', 'IndexOutOfBounds');
        O.Expect('getvalidationerror_1_with_no_error|text', 'Index out of bounds.');
        O.Expect('getvalidationerror_1_with_no_error|code', 'IndexOutOfBounds');
        O.Verify();
    end;

    local procedure TryVisible(var P: TestPage "PA Hdl Card"): Text
    begin
        if TryVisibleF(P) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryVisibleF(var P: TestPage "PA Hdl Card")
    var
        B: Boolean;
    begin
        B := P.HiddenField.Visible();
    end;

    [Test]
    procedure TestPage_GuidControlCase()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        R: Record "PA Hdl Row";
        P: TestPage "PA Hdl Card";
        G: Guid;
    begin
        Start(L);
        Evaluate(G, '{ABCDEF01-2345-6789-ABCD-EF0123456789}');
        R.Id := 1;
        R.G := G;
        R.Insert();
        P.OpenEdit();
        O.Observe('guid_control', P.G.Value());
        P.G.SetValue('{FEDCBA98-7654-3210-FEDC-BA9876543210}');
        P.Next();
        P.Previous();
        R.Get(1);
        O.Observe('guid_after_setvalue_upper_in_record', Format(R.G));
        O.Observe('guid_control_after', P.G.Value());
        P.Close();
        O.Expect('guid_control', '{abcdef01-2345-6789-abcd-ef0123456789}');
        O.Expect('guid_after_setvalue_upper_in_record', '{FEDCBA98-7654-3210-FEDC-BA9876543210}');
        O.Expect('guid_control_after', '{fedcba98-7654-3210-fedc-ba9876543210}');
        O.Verify();
    end;

    [Test]
    procedure TestPage_BlankNumbers_AllMembers()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        R: Record "PA Hdl Row";
        P: TestPage "PA Hdl Card";
        V: Decimal;
        Vals: List of [Decimal];
    begin
        Start(L);
        Vals.Add(-1.5);
        Vals.Add(0);
        Vals.Add(2.5);
        foreach V in Vals do begin
            R.DeleteAll();
            R.Id := 1;
            R.Num := V;
            R.Insert();
            P.OpenView();
            O.Observe('v=' + Format(V) + ' BlankNeg', '[' + P.NumBlankNeg.Value() + ']');
            O.Observe('v=' + Format(V) + ' BlankNegAndZero', '[' + P.NumBlankNegAndZero.Value() + ']');
            O.Observe('v=' + Format(V) + ' BlankZero', '[' + P.NumBlankZero.Value() + ']');
            O.Observe('v=' + Format(V) + ' BlankPos', '[' + P.NumBlankPos.Value() + ']');
            O.Observe('v=' + Format(V) + ' BlankZeroAndPos', '[' + P.NumBlankZeroAndPos.Value() + ']');
            O.Observe('v=' + Format(V) + ' Plain', '[' + P.NumPlain.Value() + ']');
            P.Close();
        end;
        O.Expect('v=-1.5 BlankNeg', '[]');
        O.Expect('v=-1.5 BlankNegAndZero', '[]');
        O.Expect('v=-1.5 BlankZero', '[-1.50]');
        O.Expect('v=-1.5 BlankPos', '[-1.50]');
        O.Expect('v=-1.5 BlankZeroAndPos', '[-1.50]');
        O.Expect('v=-1.5 Plain', '[-1.50]');
        O.Expect('v=0 BlankNeg', '[0.00]');
        O.Expect('v=0 BlankNegAndZero', '[]');
        O.Expect('v=0 BlankZero', '[]');
        O.Expect('v=0 BlankPos', '[0.00]');
        O.Expect('v=0 BlankZeroAndPos', '[]');
        O.Expect('v=0 Plain', '[0.00]');
        O.Expect('v=2.5 BlankNeg', '[2.50]');
        O.Expect('v=2.5 BlankNegAndZero', '[2.50]');
        O.Expect('v=2.5 BlankZero', '[2.50]');
        O.Expect('v=2.5 BlankPos', '[]');
        O.Expect('v=2.5 BlankZeroAndPos', '[]');
        O.Expect('v=2.5 Plain', '[2.50]');
        O.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_SameValue()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        P: TestPage "PA Hdl Card";
    begin
        Start(L);
        Seed(1, 'same');
        P.OpenEdit();
        L.Reset();
        P.Name.SetValue('same');
        O.Observe('same_value', L.Text() + '<end>');
        L.Reset();
        P.Name.SetValue('different');
        O.Observe('different_value', L.Text());
        L.Reset();
        P.Name.SetValue('DIFFERENT');
        O.Observe('case_change_only', L.Text() + '<end>');
        L.Reset();
        P.Name.SetValue('');
        O.Observe('to_empty', L.Text() + '<end>');
        P.Close();
        O.Expect('same_value', 'table OnValidate Name: same ; page OnValidate Name: same ; <end>');
        O.Expect('different_value', 'table OnValidate Name: different ; page OnValidate Name: different ; ');
        O.Expect('case_change_only', 'table OnValidate Name: DIFFERENT ; page OnValidate Name: DIFFERENT ; <end>');
        O.Expect('to_empty', 'table OnValidate Name:  ; page OnValidate Name:  ; <end>');
        O.Verify();
    end;

    [Test]
    procedure TestPage_Members_ShowMandatoryHideValue_Defaults()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        P: TestPage "PA Hdl Card";
    begin
        Start(L);
        Seed(1, 'a');
        P.OpenEdit();
        O.Observe('name_showmandatory', Format(P.Name.ShowMandatory()));
        O.Observe('literal_showmandatory_true', Format(P.ShowMandatoryField.ShowMandatory()));
        O.Observe('name_hidevalue', Format(P.Name.HideValue()));
        O.Observe('literal_hidevalue_true', Format(P.HideValueField.HideValue()));
        O.Observe('hidevalue_field_value', '[' + P.HideValueField.Value() + ']');
        O.Observe('card_isexpanded', TryExpanded(P));
        P.Close();
        O.Expect('name_showmandatory', 'Yes');
        O.Expect('literal_showmandatory_true', 'Yes');
        O.Expect('name_hidevalue', 'No');
        O.Expect('literal_hidevalue_true', 'Yes');
        O.Expect('hidevalue_field_value', '[]');
        O.Expect('card_isexpanded', 'ok');
        O.Verify();
    end;

    local procedure TryExpanded(var P: TestPage "PA Hdl Card"): Text
    begin
        if TryExpandedF(P) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryExpandedF(var P: TestPage "PA Hdl Card")
    begin
        P.Expand(true);
    end;

    [Test]
    procedure Action_Ordinals()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('None', Format(Action::None, 0, 1));
        O.Observe('OK', Format(Action::OK, 0, 1));
        O.Observe('Cancel', Format(Action::Cancel, 0, 1));
        O.Observe('LookupOK', Format(Action::LookupOK, 0, 1));
        O.Observe('LookupCancel', Format(Action::LookupCancel, 0, 1));
        O.Observe('Yes', Format(Action::Yes, 0, 1));
        O.Observe('No', Format(Action::No, 0, 1));
        O.Observe('RunObject', Format(Action::RunObject, 0, 1));
        O.Observe('RunSystem', Format(Action::RunSystem, 0, 1));
        O.Expect('None', 'None');
        O.Expect('OK', 'OK');
        O.Expect('Cancel', 'Cancel');
        O.Expect('LookupOK', 'LookupOK');
        O.Expect('LookupCancel', 'LookupCancel');
        O.Expect('Yes', 'Yes');
        O.Expect('No', 'No');
        O.Expect('RunObject', 'RunObject');
        O.Expect('RunSystem', 'RunSystem');
        O.Verify();
    end;

    [Test]
    procedure OnInit_RunsBeforeHandlerLookup()
    var
        O: Codeunit "Probe Observer";
        Ac: Action;
    begin
        asserterror Ac := Page.RunModal(Page::"PA Hdl OnInit Error");
        O.ObserveError('runmodal_oninit_error_no_handler');
        asserterror Page.Run(Page::"PA Hdl OnInit Error");
        O.ObserveError('run_oninit_error_no_handler');
        O.Expect('runmodal_oninit_error_no_handler|text', 'error raised in OnInit');
        O.Expect('runmodal_oninit_error_no_handler|code', 'Dialog');
        O.Expect('run_oninit_error_no_handler|text', 'error raised in OnInit');
        O.Expect('run_oninit_error_no_handler|code', 'Dialog');
        O.Verify();
    end;

    [Test]
    procedure RunModal_NoHandler_ErrorText()
    var
        O: Codeunit "Probe Observer";
        Ac: Action;
    begin
        asserterror Ac := Page.RunModal(Page::"PA Hdl Card");
        O.ObserveError('runmodal_no_handler');
        asserterror Page.Run(Page::"PA Hdl Card");
        O.ObserveError('run_no_handler');
        O.Expect('runmodal_no_handler|text', 'Unhandled UI: ModalPage 69800');
        O.Expect('runmodal_no_handler|code', 'MissingUIHandler');
        O.Expect('run_no_handler|text', 'Unhandled UI: Page 69800');
        O.Expect('run_no_handler|code', 'MissingUIHandler');
        O.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalOK')]
    procedure RunModal_WithRecord_LookupMode()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        R: Record "PA Hdl Row";
        Ac: Action;
    begin
        Start(L);
        Seed(1, 'a');
        R.FindFirst();
        Ac := Page.RunModal(Page::"PA Hdl List", R);
        O.Observe('result_with_record', Format(Ac, 0, 1) + ' ' + Format(Ac));
        O.Observe('log', L.Text());
        L.Reset();
        Ac := Page.RunModal(Page::"PA Hdl List");
        O.Observe('result_without_record', Format(Ac, 0, 1) + ' ' + Format(Ac));
        O.Observe('log_without_record', L.Text());
        O.Expect('result_with_record', 'LookupOK LookupOK');
        O.Expect('log', 'list OnOpenPage lookupmode=Yes ; list OnQueryClosePage action=LookupOK ; ');
        O.Expect('result_without_record', 'LookupOK LookupOK');
        O.Expect('log_without_record', 'list OnOpenPage lookupmode=Yes ; list OnQueryClosePage action=LookupOK ; ');
        O.Verify();
    end;

    [ModalPageHandler]
    procedure ListModalOK(var P: TestPage "PA Hdl List")
    begin
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ListModalCancel')]
    procedure RunModal_Cancel_Results()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        R: Record "PA Hdl Row";
        Ac: Action;
    begin
        Start(L);
        Seed(1, 'a');
        R.FindFirst();
        Ac := Page.RunModal(Page::"PA Hdl List", R);
        O.Observe('result_with_record', Format(Ac, 0, 1));
        Ac := Page.RunModal(Page::"PA Hdl List");
        O.Observe('result_without_record', Format(Ac, 0, 1));
        O.Expect('result_with_record', 'LookupCancel');
        O.Expect('result_without_record', 'LookupCancel');
        O.Verify();
    end;

    [ModalPageHandler]
    procedure ListModalCancel(var P: TestPage "PA Hdl List")
    begin
        P.Cancel().Invoke();
    end;

    [Test]
    procedure List_NewRow_BelowxRec_And_NoExit()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        R: Record "PA Hdl Row";
        P: TestPage "PA Hdl List";
    begin
        Start(L);
        Seed(1, 'a');
        P.OpenEdit();
        L.Reset();
        P.New();
        P.Id.SetValue(2);
        P.Name.SetValue('new');
        P.Next();
        O.Observe('log_after_new', L.Text());
        O.Observe('row_count_after_new', Format(R.Count()));
        O.Observe('row_2_exists', Format(R.Get(2)));
        L.Reset();
        P.First();
        P.Name.SetValue('modified');
        P.Next();
        O.Observe('log_after_modify', L.Text());
        R.Get(1);
        O.Observe('name_after_modify', R.Name);
        L.Reset();
        P.Close();
        O.Observe('log_after_close', L.Text());
        O.Expect('log_after_new', 'list OnInsertRecord BelowxRec=Yes ; table OnValidate Name: new ; list OnModifyRecord ; ');
        O.Expect('row_count_after_new', '2');
        O.Expect('row_2_exists', 'Yes');
        O.Expect('log_after_modify', 'table OnValidate Name: modified ; list OnModifyRecord ; ');
        O.Expect('name_after_modify', 'modified');
        O.Expect('log_after_close', 'list OnQueryClosePage action=OK ; ');
        O.Verify();
    end;

    [Test]
    procedure List_FindFirstField_Misses()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        P: TestPage "PA Hdl List";
        R: Record "PA Hdl Row";
    begin
        Start(L);
        Seed(1, 'a');
        Seed(2, 'b');
        Seed(3, 'c');
        R.Get(1);
        R.Cd := 'CODE2';
        R.Modify();
        R.Get(2);
        R.Cd := 'CODE3';
        R.Modify();
        P.OpenView();
        P.GoToKey(2);
        O.Observe('start_id', P.Id.Value());
        O.Observe('findfirstfield_miss', Format(P.FindFirstField(Name, 'zz')));
        O.Observe('id_after_miss', P.Id.Value());
        O.Observe('findnextfield_miss', Format(P.FindNextField(Name, 'zz')));
        O.Observe('id_after_next_miss', P.Id.Value());
        O.Observe('findpreviousfield_miss', Format(P.FindPreviousField(Name, 'zz')));
        O.Observe('id_after_prev_miss', P.Id.Value());
        O.Observe('findfirstfield_hit', Format(P.FindFirstField(Name, 'c')));
        O.Observe('id_after_hit', P.Id.Value());
        O.Observe('findfirstfield_code_by_text_case', Format(P.FindFirstField(Cd, 'code2')));
        O.Observe('id_after_code_hit', P.Id.Value());
        O.Observe('findfirstfield_code_upper', Format(P.FindFirstField(Cd, 'CODE3')));
        O.Observe('id_after_code_upper_hit', P.Id.Value());
        P.Close();
        O.Expect('start_id', '2');
        O.Expect('findfirstfield_miss', 'No');
        O.Expect('id_after_miss', '2');
        O.Expect('findnextfield_miss', 'No');
        O.Expect('id_after_next_miss', '2');
        O.Expect('findpreviousfield_miss', 'No');
        O.Expect('id_after_prev_miss', '2');
        O.Expect('findfirstfield_hit', 'Yes');
        O.Expect('id_after_hit', '3');
        O.Expect('findfirstfield_code_by_text_case', 'No');
        O.Expect('id_after_code_hit', '3');
        O.Expect('findfirstfield_code_upper', 'Yes');
        O.Expect('id_after_code_upper_hit', '2');
        O.Verify();
    end;

    [Test]
    procedure List_GoToKey_PopulatesPassedRows()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Hdl Log";
        P: TestPage "PA Hdl List";
    begin
        Start(L);
        Seed(1, 'a');
        Seed(2, 'b');
        Seed(3, 'c');
        P.OpenView();
        L.Reset();
        O.Observe('gotokey_3', Format(P.GoToKey(3)));
        O.Observe('log', L.Text() + '<end>');
        O.Observe('gotokey_missing', Format(P.GoToKey(99)));
        O.Observe('id_after_missing', P.Id.Value());
        P.Close();
        O.Expect('gotokey_3', 'Yes');
        O.Expect('log', '<end>');
        O.Expect('gotokey_missing', 'No');
        O.Expect('id_after_missing', '3');
        O.Verify();
    end;
}

codeunit 69822 "PA Hdl Log"
{
    SingleInstance = true;
    var
        Lines: List of [Text];

    procedure Add(T: Text)
    begin
        Lines.Add(T);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Text(): Text
    var
        L: Text;
        R: Text;
    begin
        foreach L in Lines do
            R += L + ' ; ';
        exit(R);
    end;
}
