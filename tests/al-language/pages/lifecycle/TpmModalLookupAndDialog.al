// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope (Cloud). Modal page handlers only.
// local object: a lookup list, a dialog page with controls bound to page variables (no source table), the logging triggers and the table are what is under test; the log is a SingleInstance codeunit
// Fixtures used: Probe Observer (codeunit 69160); own objects 97500-97507, test codeunit 97507
// Area (TestPage lifecycle matrix, shapes "list run modally in lookup mode" and "page without source table, controls on page variables"):
//   a lookup list over 3 rows and over 25 rows: First, Last, Next, Previous, GoToKey, GoToRecord, OK, Cancel, a handler that returns without
//   either, SetValue on a row field of an editable lookup, an action that inserts or deletes rows, and what RunModal returns and what
//   GetRecord gives afterwards. A StandardDialog: SetValue on controls bound to a Text, a Decimal, a Date and an Enum variable (valid value,
//   a value of another kind, an invalid text, a blank enum member, a failing OnValidate), an action after SetValue, OK, Cancel and the
//   order of OnValidate and OnQueryClosePage. Each cell Observes the returned Action, the shown row, the stored values and the error text.
// BC versions: 27, 28, 29

enum 97500 "TPM Kind"
{
    Extensible = true;

    value(0; Empty)
    {
        Caption = ' ';
    }
    value(1; Replace)
    {
        Caption = 'Replace';
    }
    value(2; Append)
    {
        Caption = 'Append';
    }
}

table 97501 "TPM Look Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "TPM Modal Log";
    begin
        Log.Add('T-M:' + "Code");
    end;
}

page 97502 "TPM Lookup List"
{
    PageType = List;
    SourceTable = "TPM Look Row";
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
            action(AddRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    New: Record "TPM Look Row";
                begin
                    New."Code" := 'R2A';
                    New.Name := 'added';
                    New.Insert(false);
                end;
            }
            action(DeleteCurrent)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "TPM Modal Log";
    begin
        Log.Add('P-OOP:' + Format(CurrPage.LookupMode()));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TPM Modal Log";
    begin
        Log.Add('P-AGC:' + Rec."Code");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "TPM Modal Log";
    begin
        Log.Add('P-QC:' + Format(CloseAction));
        exit(true);
    end;
}

page 97503 "TPM Input Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TextInput; TextValue)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "TPM Modal Log";
                begin
                    Log.Add('V-Text:' + TextValue);
                    if TextValue = 'bad' then
                        Error('Text must not be bad.');
                end;
            }
            field(DecimalInput; DecimalValue)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "TPM Modal Log";
                begin
                    Log.Add('V-Decimal:' + Format(DecimalValue));
                end;
            }
            field(DateInput; DateValue)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "TPM Modal Log";
                begin
                    Log.Add('V-Date:' + Format(DateValue, 0, 9));
                end;
            }
            field(KindInput; KindValue)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "TPM Modal Log";
                begin
                    Log.Add('V-Kind:' + Format(KindValue, 0, 2));
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "TPM Modal Log";
                begin
                    Log.Add('A-Apply:' + TextValue + '/' + Format(DecimalValue) + '/' + Format(KindValue, 0, 2));
                    if TextValue <> '' then
                        DecimalValue := StrLen(TextValue);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "TPM Modal Log";
    begin
        Log.Add('P-QC:' + Format(CloseAction) + ' ' + TextValue + '/' + Format(DecimalValue) + '/' + Format(DateValue, 0, 9) + '/' + Format(KindValue, 0, 2));
        exit(true);
    end;

    procedure Values(): Text
    begin
        exit(TextValue + '/' + Format(DecimalValue) + '/' + Format(DateValue, 0, 9) + '/' + Format(KindValue, 0, 2));
    end;

    var
        TextValue: Text[30];
        DecimalValue: Decimal;
        DateValue: Date;
        KindValue: Enum "TPM Kind";
}

codeunit 97506 "TPM Modal Log"
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
        Result := Entries.TrimEnd();
        Entries := '';
    end;
}

codeunit 97507 "TPM Modal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TPM Modal Log";
        Case_: Text;

    local procedure Seed(Count: Integer)
    var
        Row: Record "TPM Look Row";
        i: Integer;
    begin
        Row.DeleteAll(false);
        for i := 1 to Count do begin
            Row.Init();
            Row."Code" := 'R' + Format(i);
            Row.Name := 'name' + Format(i);
            Row.Insert(false);
        end;
        Log.Take();
    end;

    local procedure Rows(): Text
    var
        Row: Record "TPM Look Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure ShownLook(var P: TestPage "TPM Lookup List"): Text
    begin
        exit(P."Code".Value() + '|' + P.Name.Value());
    end;

    local procedure RunLookup(CaseName: Text; LookupMode: Boolean): Text
    var
        Look: Page "TPM Lookup List";
        Row: Record "TPM Look Row";
        Result: Action;
    begin
        Case_ := CaseName;
        Look.LookupMode(LookupMode);
        Result := Look.RunModal();
        Look.GetRecord(Row);
        exit(Format(Result) + ' GetRecord=' + Row."Code");
    end;

    [TryFunction]
    local procedure TryLookName(var P: TestPage "TPM Lookup List"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    // Lookup list run modally

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_Ok_OnFirstRow_ReturnsLookupOkAndFirstRecord()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('ok-first', true));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_Ok_AfterNext_ReturnsSecondRecord()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('ok-next', true));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_Cancel_ReturnsLookupCancel()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('cancel-next', true));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_HandlerReturnsWithoutOkOrCancel_ResultAndRecord()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('neither', true));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_NotInLookupMode_OkAndCancelResult()
    begin
        Seed(3);
        Observer.Observe('result ok', RunLookup('ok-next', false));
        Observer.Observe('log ok', Log.Take());
        Observer.Observe('result cancel', RunLookup('cancel-next', false));
        Observer.Observe('log cancel', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_Navigation_LastNextPreviousFirstGoToKey()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('walk', true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_SetValueOnRow_ThenOk_RowModified()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('edit', true));
        Observer.Observe('log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_ActionInsertsAndDeletes_ThenGoToKeyAndOk()
    begin
        Seed(3);
        Observer.Observe('result', RunLookup('actions', true));
        Observer.Observe('log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure TPM_Lookup_25Rows_WalkGoToKeyAndOkOnLastRow()
    begin
        Seed(25);
        Observer.Observe('result', RunLookup('long', true));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure LookupHandler(var P: TestPage "TPM Lookup List")
    var
        Count: Integer;
    begin
        Observer.Observe(Case_ + ' shown on open', ShownLook(P));
        case Case_ of
            'ok-first':
                P.OK().Invoke();
            'ok-next':
                begin
                    Observer.Observe(Case_ + ' Next', Format(P.Next()) + ' ' + ShownLook(P));
                    P.OK().Invoke();
                end;
            'cancel-next':
                begin
                    P.Next();
                    P.Cancel().Invoke();
                end;
            'neither':
                P.Next();
            'walk':
                begin
                    Observer.Observe(Case_ + ' Last', Format(P.Last()) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' Next past the end', Format(P.Next()) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' Previous', Format(P.Previous()) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' First', Format(P.First()) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' Previous before the start', Format(P.Previous()) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' GoToKey R3', Format(P.GoToKey('R3')) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' GoToKey missing', Format(P.GoToKey('NOPE')) + ' ' + ShownLook(P));
                    P.OK().Invoke();
                end;
            'edit':
                begin
                    P.GoToKey('R2');
                    Observer.Observe(Case_ + ' Name ok', Format(TryLookName(P, 'changed')));
                    Observer.Observe(Case_ + ' log after SetValue', Log.Take());
                    P.OK().Invoke();
                end;
            'actions':
                begin
                    P.GoToKey('R2');
                    P.AddRow.Invoke();
                    Observer.Observe(Case_ + ' shown after AddRow', ShownLook(P));
                    Observer.Observe(Case_ + ' GoToKey R2A', Format(P.GoToKey('R2A')) + ' ' + ShownLook(P));
                    P.DeleteCurrent.Invoke();
                    Observer.Observe(Case_ + ' shown after DeleteCurrent', ShownLook(P));
                    P.OK().Invoke();
                end;
            'long':
                begin
                    Observer.Observe(Case_ + ' Last', Format(P.Last()) + ' ' + ShownLook(P));
                    Observer.Observe(Case_ + ' GoToKey R12', Format(P.GoToKey('R12')) + ' ' + ShownLook(P));
                    P.First();
                    Count := 1;
                    while P.Next() do
                        Count += 1;
                    Observer.Observe(Case_ + ' rows walked with Next', Format(Count));
                    P.OK().Invoke();
                end;
        end;
    end;

    // Dialog with controls on page variables, no source table

    local procedure RunDialog(CaseName: Text): Text
    var
        Dialog: Page "TPM Input Dialog";
        Result: Action;
    begin
        Case_ := CaseName;
        Result := Dialog.RunModal();
        exit(Format(Result) + ' ' + Dialog.Values());
    end;

    [TryFunction]
    local procedure TryText(var D: TestPage "TPM Input Dialog"; Value: Variant)
    begin
        D.TextInput.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryDecimal(var D: TestPage "TPM Input Dialog"; Value: Variant)
    begin
        D.DecimalInput.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryDate(var D: TestPage "TPM Input Dialog"; Value: Variant)
    begin
        D.DateInput.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryKind(var D: TestPage "TPM Input Dialog"; Value: Variant)
    begin
        D.KindInput.SetValue(Value);
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_SetValueOnEveryControl_ThenOk_ValuesStored()
    begin
        Observer.Observe('result', RunDialog('all'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_SetValueOnEveryControl_ThenCancel_ValuesAndOnQueryClosePage()
    begin
        Observer.Observe('result', RunDialog('cancel'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_SetValueOfAnotherKind_DecimalIntoTextAndDateIntoDecimal()
    begin
        Observer.Observe('result', RunDialog('kinds'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_SetValueInvalid_TextForDateAndDecimalAndEnum_ErrorTexts()
    begin
        Observer.Observe('result', RunDialog('invalid'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_BlankEnumMember_ValueOfBlankCaption()
    begin
        Observer.Observe('result', RunDialog('blank-enum'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_FailingOnValidate_ErrorTextValueKept()
    begin
        Observer.Observe('result', RunDialog('failing-validate'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure TPM_Dialog_ActionAfterSetValue_ReadsVariablesAndControlsRefresh()
    begin
        Observer.Observe('result', RunDialog('action'));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure DialogHandler(var D: TestPage "TPM Input Dialog")
    begin
        Observer.Observe(Case_ + ' on open', D.TextInput.Value() + '/' + D.DecimalInput.Value() + '/' + D.DateInput.Value() + '/' + D.KindInput.Value());
        case Case_ of
            'all':
                begin
                    Observer.Observe(Case_ + ' text ok', Format(TryText(D, 'hello')));
                    Observer.Observe(Case_ + ' decimal ok', Format(TryDecimal(D, '12,5')));
                    Observer.Observe(Case_ + ' date ok', Format(TryDate(D, '2026-03-04')));
                    Observer.Observe(Case_ + ' kind ok', Format(TryKind(D, 'Append')));
                    Observer.Observe(Case_ + ' shown', D.TextInput.Value() + '/' + D.DecimalInput.Value() + '/' + D.DateInput.Value() + '/' + D.KindInput.Value());
                    D.OK().Invoke();
                end;
            'cancel':
                begin
                    TryText(D, 'hello');
                    TryDecimal(D, '12,5');
                    D.Cancel().Invoke();
                end;
            'kinds':
                begin
                    Observer.Observe(Case_ + ' decimal value into text', Format(TryText(D, 1.5)));
                    if GetLastErrorText() <> '' then
                        Observer.ObserveError(Case_ + ' decimal value into text');
                    Observer.Observe(Case_ + ' shown text', D.TextInput.Value());
                    Observer.Observe(Case_ + ' integer into decimal', Format(TryDecimal(D, 7)));
                    Observer.Observe(Case_ + ' shown decimal', D.DecimalInput.Value());
                    Observer.Observe(Case_ + ' date value into text', Format(TryText(D, DMY2Date(4, 3, 2026))));
                    Observer.Observe(Case_ + ' shown text', D.TextInput.Value());
                    Observer.Observe(Case_ + ' date value into date', Format(TryDate(D, DMY2Date(4, 3, 2026))));
                    Observer.Observe(Case_ + ' shown date', D.DateInput.Value());
                    Observer.Observe(Case_ + ' enum value into kind', Format(TryKind(D, Enum::"TPM Kind"::Replace)));
                    Observer.Observe(Case_ + ' shown kind', D.KindInput.Value());
                    D.OK().Invoke();
                end;
            'invalid':
                begin
                    if not TryDate(D, 'not a date') then
                        Observer.ObserveError(Case_ + ' date');
                    if not TryDecimal(D, 'abc') then
                        Observer.ObserveError(Case_ + ' decimal');
                    if not TryKind(D, 'Nope') then
                        Observer.ObserveError(Case_ + ' kind');
                    Observer.Observe(Case_ + ' shown', D.TextInput.Value() + '/' + D.DecimalInput.Value() + '/' + D.DateInput.Value() + '/' + D.KindInput.Value());
                    D.OK().Invoke();
                end;
            'blank-enum':
                begin
                    Observer.Observe(Case_ + ' Replace', Format(TryKind(D, Format(Enum::"TPM Kind"::Replace))));
                    Observer.Observe(Case_ + ' blank member', Format(TryKind(D, Format(Enum::"TPM Kind"::Empty))));
                    Observer.Observe(Case_ + ' shown', '[' + D.KindInput.Value() + ']');
                    Observer.Observe(Case_ + ' empty text', Format(TryKind(D, '')));
                    Observer.Observe(Case_ + ' shown', '[' + D.KindInput.Value() + ']');
                    D.OK().Invoke();
                end;
            'failing-validate':
                begin
                    TryText(D, 'fine');
                    if not TryText(D, 'bad') then
                        Observer.ObserveError(Case_ + ' bad');
                    Observer.Observe(Case_ + ' shown', D.TextInput.Value());
                    D.OK().Invoke();
                end;
            'action':
                begin
                    TryText(D, 'hello');
                    TryKind(D, 'Append');
                    D.Apply.Invoke();
                    Observer.Observe(Case_ + ' decimal after Apply', D.DecimalInput.Value());
                    Observer.Observe(Case_ + ' Apply enabled', Format(D.Apply.Enabled()));
                    D.OK().Invoke();
                end;
        end;
    end;
}
