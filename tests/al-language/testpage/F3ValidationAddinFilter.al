// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-getvalidationerror-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Row / Log Mgt / List (F3Fixtures.al); own objects 67116 - 67122, 67127
// Probe: (1) TestPage.GetValidationError() without an index after no error, one error and two errors; (2) TestFilter.SetFilter(Field, '') on a TestPage list: does it clear the filter;
//        (3) calls to a control add-in procedure from AL (no-op or error), whether an event fires,, from a page that ran and from a Page variable that never ran.

table 67116 "LT F3 Valid"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; A; Integer)
        {
            trigger OnValidate()
            begin
                if A < 0 then
                    Error('A must not be negative');
            end;
        }
        field(3; B; Integer)
        {
            trigger OnValidate()
            begin
                if B < 0 then
                    Error('B must not be negative');
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 67117 "LT F3 Valid Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT F3 Valid";

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(ACtl; Rec.A) { ApplicationArea = All; }
            field(BCtl; Rec.B) { ApplicationArea = All; }
        }
    }
}

controladdin "LT F3 Addin"
{
    RequestedHeight = 100;
    RequestedWidth = 100;

    event Ready();
    event Clicked(Value: Text);

    procedure SetLocale(Locale: Text);
    procedure Load(Payload: JsonObject);
}

// In-memory log for the add-in page triggers; used by one test codeunit only.
codeunit 67127 "LT F3 Addin Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Clear()
    begin
        if Entries.Count() > 0 then
            Entries.RemoveRange(1, Entries.Count());
    end;

    procedure Add(Value: Text)
    begin
        Entries.Add(Value);
    end;

    procedure Dump(): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Entries do
            Result += Entry + ' | ';
        exit(Result);
    end;
}

page 67119 "LT F3 Addin Page"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            usercontrol(Host; "LT F3 Addin")
            {
                ApplicationArea = All;

                trigger Ready()
                var
                    Log: Codeunit "LT F3 Addin Log";
                begin
                    Log.Add('Addin.Ready');
                end;

                trigger Clicked(Value: Text)
                var
                    Log: Codeunit "LT F3 Addin Log";
                begin
                    Log.Add('Addin.Clicked(' + Value + ')');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Addin Log";
    begin
        CurrPage.Host.SetLocale('de-DE');
        Log.Add('OnOpenPage after SetLocale');
    end;

    procedure CallSetLocale(Locale: Text)
    begin
        CurrPage.Host.SetLocale(Locale);
    end;

    procedure CallLoad()
    var
        Payload: JsonObject;
    begin
        Payload.Add('k', 1);
        CurrPage.Host.Load(Payload);
    end;
}

codeunit 67120 "LT F3 Validation Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGet(var P: TestPage "LT F3 Valid Card"; Index: Integer; var Result: Text)
    begin
        if Index = 0 then
            Result := P.GetValidationError()
        else
            Result := P.GetValidationError(Index);
    end;

    local procedure ObserveGet(var Observer: Codeunit "Probe Observer"; Name: Text; var P: TestPage "LT F3 Valid Card"; Index: Integer)
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryGet(P, Index, Result);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_result', Result);
        if not Ok then begin
            Observer.Observe(Name + '_error', GetLastErrorText());
            Observer.Observe(Name + '_code', GetLastErrorCode());
        end;
    end;

    local procedure Prepare()
    var
        Valid: Record "LT F3 Valid";
    begin
        Valid.DeleteAll();
        Valid.Init();
        Valid."No." := 'V1';
        Valid.Insert();
    end;

    [Test]
    procedure GetValidationError_NoError()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        ObserveGet(Observer, 'noindex', P, 0);
        ObserveGet(Observer, 'index1', P, 1);
        P.Close();
        Observer.Expect('noindex_ok', 'Yes');
        Observer.Expect('noindex_result', '');
        Observer.Expect('index1_ok', 'No');
        Observer.Expect('index1_result', '');
        Observer.Expect('index1_error', 'Index out of bounds.');
        Observer.Expect('index1_code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure GetValidationError_OneError()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        asserterror P.ACtl.SetValue(-1);
        Observer.ObserveError('set_a');
        ObserveGet(Observer, 'noindex', P, 0);
        ObserveGet(Observer, 'index1', P, 1);
        ObserveGet(Observer, 'index2', P, 2);
        P.Close();
        Observer.Expect('set_a|text', 'Validation error for Field: ACtl,  Message = ''A must not be negative (Select Refresh to discard errors)''');
        Observer.Expect('set_a|code', 'TestValidation');
        Observer.Expect('noindex_ok', 'Yes');
        Observer.Expect('noindex_result', 'A must not be negative (Select Refresh to discard errors)');
        Observer.Expect('index1_ok', 'Yes');
        Observer.Expect('index1_result', 'A must not be negative (Select Refresh to discard errors)');
        Observer.Expect('index2_ok', 'No');
        Observer.Expect('index2_result', '');
        Observer.Expect('index2_error', 'Index out of bounds.');
        Observer.Expect('index2_code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure GetValidationError_TwoErrors()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        asserterror P.ACtl.SetValue(-1);
        Observer.ObserveError('set_a');
        asserterror P.BCtl.SetValue(-2);
        Observer.ObserveError('set_b');
        ObserveGet(Observer, 'noindex', P, 0);
        ObserveGet(Observer, 'index1', P, 1);
        ObserveGet(Observer, 'index2', P, 2);
        ObserveGet(Observer, 'index3', P, 3);
        P.Close();
        Observer.Expect('set_a|text', 'Validation error for Field: ACtl,  Message = ''A must not be negative (Select Refresh to discard errors)''');
        Observer.Expect('set_a|code', 'TestValidation');
        Observer.Expect('set_b|text', 'Validation error for Field: BCtl,  Message = ''B must not be negative (Select Refresh to discard errors)''');
        Observer.Expect('set_b|code', 'TestValidation');
        Observer.Expect('noindex_ok', 'Yes');
        Observer.Expect('noindex_result', 'A must not be negative (Select Refresh to discard errors)\r\nB must not be negative (Select Refresh to discard errors)');
        Observer.Expect('index1_ok', 'Yes');
        Observer.Expect('index1_result', 'A must not be negative (Select Refresh to discard errors)');
        Observer.Expect('index2_ok', 'Yes');
        Observer.Expect('index2_result', 'B must not be negative (Select Refresh to discard errors)');
        Observer.Expect('index3_ok', 'No');
        Observer.Expect('index3_result', '');
        Observer.Expect('index3_error', 'Index out of bounds.');
        Observer.Expect('index3_code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure GetValidationError_ErrorThenCorrected()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT F3 Valid Card";
    begin
        Prepare();
        P.OpenEdit();
        asserterror P.ACtl.SetValue(-1);
        Observer.ObserveError('set_bad');
        P.ACtl.SetValue(5);
        ObserveGet(Observer, 'noindex', P, 0);
        P.Close();
        Observer.Expect('set_bad|text', 'Validation error for Field: ACtl,  Message = ''A must not be negative (Select Refresh to discard errors)''');
        Observer.Expect('set_bad|code', 'TestValidation');
        Observer.Expect('noindex_ok', 'Yes');
        Observer.Expect('noindex_result', '');
        Observer.Verify();
    end;
}

codeunit 67121 "LT F3 TestFilter Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestPage_SetFilterEmpty_ClearsFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 List";
        Count: Integer;
    begin
        Log.Seed(5);
        P.OpenView();
        P.Filter.SetFilter(Qty, '>=3');
        Observer.Observe('filter_set', P.Filter.GetFilter(Qty));
        Count := 0;
        if P.First() then
            repeat
                Count += 1;
            until not P.Next();
        Observer.Observe('rows_filtered', Format(Count));
        P.Filter.SetFilter(Qty, '');
        Observer.Observe('filter_empty', P.Filter.GetFilter(Qty));
        Count := 0;
        if P.First() then
            repeat
                Count += 1;
            until not P.Next();
        Observer.Observe('rows_after_empty', Format(Count));
        P.Close();
        Observer.Expect('filter_set', '>=3');
        Observer.Expect('rows_filtered', '3');
        Observer.Expect('filter_empty', '');
        Observer.Expect('rows_after_empty', '5');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetFilterEmptyOnOtherField_KeepsFirst()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        P: TestPage "LT F3 List";
    begin
        Log.Seed(5);
        P.OpenView();
        P.Filter.SetFilter(Qty, '>=3');
        P.Filter.SetFilter(Name, '');
        Observer.Observe('qty_filter', P.Filter.GetFilter(Qty));
        Observer.Observe('name_filter', P.Filter.GetFilter(Name));
        P.Close();
        Observer.Expect('qty_filter', '>=3');
        Observer.Expect('name_filter', '');
        Observer.Verify();
    end;
}

codeunit 67122 "LT F3 Addin Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [PageHandler]
    procedure AddinPageHandler(var P: TestPage "LT F3 Addin Page")
    begin
        Observer.Observe('h_name', P.NameCtl.Value());
    end;

    [TryFunction]
    local procedure TryCall(var Pg: Page "LT F3 Addin Page"; Which: Integer)
    begin
        case Which of
            1:
                Pg.CallSetLocale('de-DE');
            2:
                Pg.CallLoad();
        end;
    end;

    local procedure ObserveCall(Name: Text; var Pg: Page "LT F3 Addin Page"; Which: Integer)
    var
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryCall(Pg, Which);
        Observer.Observe(Name + '_ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + '_error', GetLastErrorText());
            Observer.Observe(Name + '_code', GetLastErrorCode());
        end;
    end;

    [Test]
    [HandlerFunctions('AddinPageHandler')]
    procedure Addin_PageOpened_OnOpenPageCallsProcedure()
    var
        Data: Codeunit "LT F3 Log Mgt";
        Log: Codeunit "LT F3 Addin Log";
        Row: Record "LT F3 Row";
        Ok: Boolean;
    begin
        Data.Seed(1);
        Log.Clear();
        Row.FindFirst();
        ClearLastError();
        Ok := TryRunPage(Row);
        Observer.Observe('ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('error', GetLastErrorText());
            Observer.Observe('code', GetLastErrorCode());
        end;
        Observer.Observe('log', Log.Dump());
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue); the Linux image at dbee8022 gives the same values.
        Observer.Expect('ok', 'No');
        Observer.Expect('error', 'The control add-in on control Host on page LT F3 Addin Page has not been instantiated.');
        Observer.Expect('code', 'DotNetControlAddInNotCreated');
        Observer.Expect('log', '');
        Observer.Verify();
#elif LT_HELD_BCLINUX_133
        // Held on Linux (LT_HELD_BCLINUX_133): these are the Linux values of the image before the bc-linux #133 fix. The image at dbee8022 and
        // Windows BC 28.5/29.0 (Windows runs 2026-10-20, first difference only) give 'The control add-in on control Host on page LT F3 Addin Page
        // has not been instantiated.'; Windows BC 27.5 gives a client callback error. Re-assert after the Windows check (windows-queue), then
        // remove this hold; it does not end with bc-linux #133 (closed).
        Observer.Expect('ok', 'No');
        Observer.Expect('error', 'A call to SetLocale failed with this message: Object reference not set to an instance of an object.');
        Observer.Expect('code', 'DotNetInvoke:NullReference');
        Observer.Expect('log', '');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [TryFunction]
    local procedure TryRunPage(var Row: Record "LT F3 Row")
    begin
        Page.Run(Page::"LT F3 Addin Page", Row);
    end;

    [Test]
    procedure Addin_PageVariableNeverOpened_Calls()
    var
        Pg: Page "LT F3 Addin Page";
        Log: Codeunit "LT F3 Addin Log";
    begin
        Log.Clear();
        ObserveCall('setlocale', Pg, 1);
        ObserveCall('load', Pg, 2);
        Observer.Observe('log', Log.Dump());
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue); the Linux image at dbee8022 gives the same values.
        Observer.Expect('setlocale_ok', 'No');
        Observer.Expect('setlocale_error', 'The control add-in on control Host on page LT F3 Addin Page has not been instantiated.');
        Observer.Expect('setlocale_code', 'DotNetControlAddInNotCreated');
        Observer.Expect('load_ok', 'No');
        Observer.Expect('load_error', 'The control add-in on control Host on page LT F3 Addin Page has not been instantiated.');
        Observer.Expect('load_code', 'DotNetControlAddInNotCreated');
        Observer.Expect('log', '');
        Observer.Verify();
#elif LT_HELD_BCLINUX_133
        // Held on Linux (LT_HELD_BCLINUX_133): these are the Linux values of the image before the bc-linux #133 fix. The image at dbee8022 and
        // Windows BC 28.5/29.0 (Windows runs 2026-10-20, first difference only) give 'The control add-in on control Host on page LT F3 Addin Page
        // has not been instantiated.'; Windows BC 27.5 gives a client callback error. Re-assert after the Windows check (windows-queue), then
        // remove this hold; it does not end with bc-linux #133 (closed).
        Observer.Expect('setlocale_ok', 'No');
        Observer.Expect('setlocale_error', 'A call to SetLocale failed with this message: Object reference not set to an instance of an object.');
        Observer.Expect('setlocale_code', 'DotNetInvoke:NullReference');
        Observer.Expect('load_ok', 'No');
        Observer.Expect('load_error', 'A call to Load failed with this message: Object reference not set to an instance of an object.');
        Observer.Expect('load_code', 'DotNetInvoke:NullReference');
        Observer.Expect('log', '');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;
}
