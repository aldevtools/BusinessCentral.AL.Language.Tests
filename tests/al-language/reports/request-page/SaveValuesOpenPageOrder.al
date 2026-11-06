// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 96100, codeunit 96100 (log), reports 96100-96103, test codeunit 96101
// local object: the table needs Code/Name/Qty fields of its own so the data item views and filters can name them; the reports need own
// request pages (SaveValues, OnOpenPage, Editable = false) and own data items.
// Probe (reporter question, al-runner issue 6924): (1) a SaveValues request page whose Editable = false field is bound to a report global that
// the request page's OnOpenPage computes from a value the caller passed through a report procedure before RunModal; the handler only sets
// another control and presses OK. Are the saved values restored before or after OnOpenPage, and what does OnPreReport see on each run?
// The same without an OnOpenPage recompute. (2) GetFilters / GetView of data items declared with DataItemTableView = where(...), with and
// without RequestFilterFields and a user filter from the request page, read in OnPreReport and in OnPreDataItem.
// Related existing tests: P147SaveValuesText.al (caller value against stored value, no OnOpenPage), TestReportRequestPageSaveValues.al.
// Facts (identical on 27.5, 28.5, 29.0): the saved values are restored BEFORE the request page's OnOpenPage runs (OnOpenPage sees the previous run's
// confirmed values), and OnOpenPage then overwrites an Editable = false global, so OnPreReport of the second run sees the OnOpenPage value, not the saved
// one; a control the handler did not touch keeps the saved value. Without an OnOpenPage the caller's procedure value wins over the saved one, and a run
// without a procedure call shows the saved value. DataItemTableView where(...) is not part of GetFilters or GetView in OnPreReport or OnPreDataItem
// (only its SORTING is); user request filters are, and they replace the where() of the view in GetView.
// BC versions: 27-29

table 96100 "LT SVO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 96100 "LT SVO Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

// OnOpenPage recomputes the Editable = false global from the value the caller passed.
report 96100 "LT SVO With OpenPage"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(Loc; LocTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Other; OtherTxt)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        var
            Log: Codeunit "LT SVO Log";
        begin
            Log.Add('open.before loc=[' + LocTxt + '] other=[' + OtherTxt + ']');
            LocTxt := 'computed(' + InputTxt + ')';
            Log.Add('open.after loc=[' + LocTxt + ']');
        end;
    }

    procedure SetX(NewInput: Text[30])
    begin
        InputTxt := NewInput;
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT SVO Log";
    begin
        Log.Add('pre loc=[' + LocTxt + '] other=[' + OtherTxt + '] input=[' + InputTxt + ']');
    end;

    var
        LocTxt: Text[60];
        OtherTxt: Text[30];
        InputTxt: Text[30];
}

// No OnOpenPage: the caller's procedure sets the Editable = false global directly.
report 96101 "LT SVO Without OpenPage"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(Loc; LocTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Other; OtherTxt)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetLoc(NewLoc: Text[60])
    begin
        LocTxt := NewLoc;
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT SVO Log";
    begin
        Log.Add('pre loc=[' + LocTxt + '] other=[' + OtherTxt + ']');
    end;

    var
        LocTxt: Text[60];
        OtherTxt: Text[30];
}

// Data items with a DataItemTableView, with and without request filter fields.
report 96102 "LT SVO View Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(DiView; "LT SVO Row")
        {
            DataItemTableView = where(Qty = filter(> 2));

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT SVO Log";
            begin
                Log.Add('preDi DiView filters=[' + DiView.GetFilters() + '] view=[' + DiView.GetView() + '] view(false)=[' + DiView.GetView(false) + ']');
            end;
        }
        dataitem(DiBoth; "LT SVO Row")
        {
            DataItemTableView = sorting(Name) where(Qty = filter(< 10));
            RequestFilterFields = Code;

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT SVO Log";
            begin
                Log.Add('preDi DiBoth filters=[' + DiBoth.GetFilters() + '] view=[' + DiBoth.GetView() + '] view(false)=[' + DiBoth.GetView(false) + ']');
            end;
        }
        dataitem(DiPlain; "LT SVO Row")
        {
            RequestFilterFields = Code;

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT SVO Log";
            begin
                Log.Add('preDi DiPlain filters=[' + DiPlain.GetFilters() + '] view=[' + DiPlain.GetView() + '] view(false)=[' + DiPlain.GetView(false) + ']');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Marker; MarkerTxt)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnPreReport()
    var
        Log: Codeunit "LT SVO Log";
    begin
        Log.Add('pre DiView filters=[' + DiView.GetFilters() + '] view=[' + DiView.GetView() + '] view(false)=[' + DiView.GetView(false) + ']');
        Log.Add('pre DiBoth filters=[' + DiBoth.GetFilters() + '] view=[' + DiBoth.GetView() + '] view(false)=[' + DiBoth.GetView(false) + ']');
        Log.Add('pre DiPlain filters=[' + DiPlain.GetFilters() + '] view=[' + DiPlain.GetView() + '] view(false)=[' + DiPlain.GetView(false) + ']');
    end;

    var
        MarkerTxt: Text[10];
}

codeunit 96101 "LT SVO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerRun: Integer;
        UserFilterCode: Text;

    local procedure TakeLog(): Text
    var
        Log: Codeunit "LT SVO Log";
    begin
        exit(Log.Take());
    end;

    local procedure RunWithOpenPage(Input: Text[30]; UseInput: Boolean)
    var
        Rep: Report "LT SVO With OpenPage";
    begin
        if UseInput then
            Rep.SetX(Input);
        Rep.RunModal();
    end;

    local procedure RunWithoutOpenPage(Loc: Text[60]; UseLoc: Boolean)
    var
        Rep: Report "LT SVO Without OpenPage";
    begin
        if UseLoc then
            Rep.SetLoc(Loc);
        Rep.RunModal();
    end;

    [Test]
    [HandlerFunctions('OpenPageHandler')]
    procedure SaveValues_OpenPageRecompute_SecondRunOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HandlerRun := 0;
        TakeLog();
        RunWithOpenPage('A', true);
        Observer.Observe('run1', TakeLog());
        RunWithOpenPage('B', true);
        Observer.Observe('run2', TakeLog());
        RunWithOpenPage('', false);
        Observer.Observe('run3 no SetX', TakeLog());
        Observer.Expect('run1', 'open.before loc=[] other=[];open.after loc=[computed(A)];handler loc=[computed(A)] other=[];pre loc=[computed(A)] other=[o1] input=[A];');
        Observer.Expect('run2', 'open.before loc=[computed(A)] other=[o1];open.after loc=[computed(B)];handler loc=[computed(B)] other=[o1];pre loc=[computed(B)] other=[o2] input=[B];');
        Observer.Expect('run3 no SetX', 'open.before loc=[computed(B)] other=[o2];open.after loc=[computed()];handler loc=[computed()] other=[o2];pre loc=[computed()] other=[o3] input=[];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoOpenPageHandler')]
    procedure SaveValues_CallerProcedureOnly_EditableFalse_SecondRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HandlerRun := 0;
        TakeLog();
        RunWithoutOpenPage('first', true);
        Observer.Observe('run1', TakeLog());
        RunWithoutOpenPage('second', true);
        Observer.Observe('run2', TakeLog());
        RunWithoutOpenPage('', false);
        Observer.Observe('run3 no SetLoc', TakeLog());
        Observer.Expect('run1', 'handler loc=[first] other=[];pre loc=[first] other=[o1];');
        Observer.Expect('run2', 'handler loc=[second] other=[o1];pre loc=[second] other=[o2];');
        Observer.Expect('run3 no SetLoc', 'handler loc=[second] other=[o2];pre loc=[second] other=[o3];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure DataItemTableView_GetFiltersAndGetView_InPreReport()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT SVO View Report";
        Rep2: Report "LT SVO View Report";
    begin
        TakeLog();
        UserFilterCode := '';
        Rep.RunModal();
        Observer.Observe('no user filter', TakeLog());
        UserFilterCode := 'A*';
        Rep2.RunModal();
        Observer.Observe('user filter Code A*', TakeLog());
        Observer.Expect('no user filter', 'pre DiView filters=[] view=[VERSION(1) SORTING(Code)] view(false)=[VERSION(1) SORTING(Field1)];pre DiBoth filters=[] view=[VERSION(1) SORTING(Name)] view(false)=[VERSION(1) SORTING(Field2)];pre DiPlain filters=[] view=[VERSION(1) SORTING(Code)] view(false)=[VERSION(1) SORTING(Field1)];preDi DiView filters=[] view=[VERSION(1) SORTING(Code)] view(false)=[VERSION(1) SORTING(Field1)];preDi DiBoth filters=[] view=[VERSION(1) SORTING(Name)] view(false)=[VERSION(1) SORTING(Field2)];preDi DiPlain filters=[] view=[VERSION(1) SORTING(Code)] view(false)=[VERSION(1) SORTING(Field1)];');
        Observer.Expect('user filter Code A*', 'pre DiView filters=[] view=[VERSION(1) SORTING(Code)] view(false)=[VERSION(1) SORTING(Field1)];pre DiBoth filters=[Code: A*] view=[VERSION(1) SORTING(Name) WHERE(Code=FILTER(A*))] view(false)=[VERSION(1) SORTING(Field2) WHERE(Field1=1(A*))];pre DiPlain filters=[Code: A*] view=[VERSION(1) SORTING(Code) WHERE(Code=FILTER(A*))] view(false)=[VERSION(1) SORTING(Field1) WHERE(Field1=1(A*))];preDi DiView filters=[] view=[VERSION(1) SORTING(Code)] view(false)=[VERSION(1) SORTING(Field1)];preDi DiBoth filters=[Code: A*] view=[VERSION(1) SORTING(Name) WHERE(Code=FILTER(A*))] view(false)=[VERSION(1) SORTING(Field2) WHERE(Field1=1(A*))];preDi DiPlain filters=[Code: A*] view=[VERSION(1) SORTING(Code) WHERE(Code=FILTER(A*))] view(false)=[VERSION(1) SORTING(Field1) WHERE(Field1=1(A*))];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OpenPageHandler(var RP: TestRequestPage "LT SVO With OpenPage")
    var
        Log: Codeunit "LT SVO Log";
    begin
        HandlerRun += 1;
        Log.Add('handler loc=[' + RP.Loc.Value() + '] other=[' + RP.Other.Value() + ']');
        RP.Other.SetValue('o' + Format(HandlerRun));
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure NoOpenPageHandler(var RP: TestRequestPage "LT SVO Without OpenPage")
    var
        Log: Codeunit "LT SVO Log";
    begin
        HandlerRun += 1;
        Log.Add('handler loc=[' + RP.Loc.Value() + '] other=[' + RP.Other.Value() + ']');
        RP.Other.SetValue('o' + Format(HandlerRun));
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ViewHandler(var RP: TestRequestPage "LT SVO View Report")
    begin
        if UserFilterCode <> '' then begin
            RP.DiBoth.SetFilter(Code, UserFilterCode);
            RP.DiPlain.SetFilter(Code, UserFilterCode);
        end;
        RP.OK().Invoke();
    end;
}
