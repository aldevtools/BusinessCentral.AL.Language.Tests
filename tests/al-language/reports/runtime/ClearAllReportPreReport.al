// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 73356, codeunits 73357 (log, SingleInstance, used only by test codeunit 73361), 73358 (SingleInstance state), 73359 (plain state), report 73360, test codeunit 73361
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: ClearAll() called in OnPreReport of a report that holds globals of Integer, Text, Boolean, Record (with a filter), a plain Codeunit and a SingleInstance Codeunit type, a request page variable and a data item: which globals are reset, whether the SingleInstance state is kept, whether the data item record keeps its row and filters, and how the data item loop continues (rows read, triggers run).
// BC versions: 29 (27 and 28 by CI)

table 73356 "LT CAR Pre Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73357 "LT CAR Pre Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        RunMode: Integer;

    procedure Reset(NewMode: Integer)
    begin
        Clear(Entries);
        RunMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(RunMode);
    end;

    procedure Add(Value: Text)
    begin
        Entries.Add(Value);
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        exit(Entries.Get(Index));
    end;
}

codeunit 73358 "LT CAR Pre Single"
{
    SingleInstance = true;

    var
        Stored: Integer;

    procedure SetValue(NewValue: Integer)
    begin
        Stored := NewValue;
    end;

    procedure GetValue(): Integer
    begin
        exit(Stored);
    end;
}

codeunit 73359 "LT CAR Pre Plain"
{
    var
        Stored: Integer;

    procedure SetValue(NewValue: Integer)
    begin
        Stored := NewValue;
    end;

    procedure GetValue(): Integer
    begin
        exit(Stored);
    end;
}

report 73360 "LT CAR Pre Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; "LT CAR Pre Row")
        {
            trigger OnPreDataItem()
            var
                Log: Codeunit "LT CAR Pre Log";
            begin
                Item.SetRange(Id, 1, 3);
                Snap('predi-before');
                if Log.Mode() = 6 then begin
                    ClearAll();
                    Snap('predi-after');
                end;
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT CAR Pre Log";
            begin
                Counter += 1;
                Snap('row ' + Format(Item.Id));
                if (Log.Mode() in [7, 8, 9]) and (Item.Id = 2) then begin
                    ClearAll();
                    Snap('row-after');
                    if Log.Mode() = 8 then
                        CurrReport.Skip();
                    if Log.Mode() = 9 then
                        CurrReport.Break();
                end;
            end;

            trigger OnPostDataItem()
            begin
                Snap('postdi');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqTextField; ReqText)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Counter: Integer;
        Title: Text;
        Flag: Boolean;
        ReqText: Text;
        Extra: Record "LT CAR Pre Row";
        PlainCu: Codeunit "LT CAR Pre Plain";
        SingleCu: Codeunit "LT CAR Pre Single";

    procedure SetReq(NewValue: Text)
    begin
        ReqText := NewValue;
    end;

    local procedure Snap(Where: Text)
    var
        Log: Codeunit "LT CAR Pre Log";
    begin
        Log.Add(Where + ' C=' + Format(Counter) + ' T=' + Title + ' F=' + Format(Flag) + ' X=' + Format(Extra.Id) + '/' + Extra.GetFilters() + ' P=' + Format(PlainCu.GetValue()) + ' S=' + Format(SingleCu.GetValue()) + ' Q=' + ReqText + ' I=' + Format(Item.Id) + '/' + Item.GetFilters());
    end;

    local procedure DoClear(Where: Text)
    begin
        Snap(Where + '-before');
        ClearAll();
        Snap(Where + '-after');
    end;

    trigger OnInitReport()
    var
        Log: Codeunit "LT CAR Pre Log";
    begin
        Counter := 5;
        Title := 'init';
        Flag := true;
        Extra.Id := 9;
        Extra.SetRange(Id, 3);
        PlainCu.SetValue(7);
        SingleCu.SetValue(7);
        Snap('init-before');
        if Log.Mode() = 1 then begin
            ClearAll();
            Snap('init-after');
        end;
        if Log.Mode() = 10 then
            DoClear('initproc');
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT CAR Pre Log";
    begin
        Snap('pre-before');
        if Log.Mode() = 2 then begin
            ClearAll();
            Snap('pre-after');
        end;
        if Log.Mode() = 4 then
            DoClear('preproc');
    end;

    trigger OnPostReport()
    var
        Log: Codeunit "LT CAR Pre Log";
    begin
        Snap('post-before');
        if Log.Mode() = 3 then begin
            ClearAll();
            Snap('post-after');
        end;
        if Log.Mode() = 5 then
            DoClear('postproc');
    end;
}

codeunit 73361 "LT CAR Pre Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Mode: Integer)
    var
        Row: Record "LT CAR Pre Row";
        Log: Codeunit "LT CAR Pre Log";
        SingleCu: Codeunit "LT CAR Pre Single";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 4 do begin
            Row.Id := i;
            Row.Name := 'row' + Format(i);
            Row.Insert();
        end;
        Log.Reset(Mode);
        SingleCu.SetValue(0);
    end;

    [TryFunction]
    local procedure TryRun()
    var
        Rpt: Report "LT CAR Pre Report";
    begin
        Rpt.SetReq('req');
        Rpt.UseRequestPage(false);
        Rpt.Run();
    end;

    local procedure RunAndObserve(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT CAR Pre Log";
        SingleCu: Codeunit "LT CAR Pre Single";
        i: Integer;
    begin
        Seed(Mode);
        Observer.Observe('ran', Format(TryRun()));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('entries', Format(Log.Count()));
        for i := 1 to Log.Count() do
            Observer.Observe('e' + Format(i), Log.Get(i));
        Observer.Observe('single_after_run', Format(SingleCu.GetValue()));
    end;

    [Test]
    procedure ClearAll_InOnPreReport_Observed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAndObserve(2, Observer);
        Observer.Expect('ran', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('entries', '9');
        Observer.Expect('e1', 'init-before C=5 T=init F=Yes X=9/Id: 3 P=7 S=7 Q= I=0/');
        Observer.Expect('e2', 'pre-before C=5 T=init F=Yes X=9/Id: 3 P=7 S=7 Q=req I=0/');
        Observer.Expect('e3', 'pre-after C=0 T= F=No X=0/ P=0 S=7 Q= I=0/');
        Observer.Expect('e4', 'predi-before C=0 T= F=No X=0/ P=0 S=7 Q= I=0/Id: 1..3');
        Observer.Expect('e5', 'row 1 C=1 T= F=No X=0/ P=0 S=7 Q= I=1/Id: 1..3');
        Observer.Expect('e6', 'row 2 C=2 T= F=No X=0/ P=0 S=7 Q= I=2/Id: 1..3');
        Observer.Expect('e7', 'row 3 C=3 T= F=No X=0/ P=0 S=7 Q= I=3/Id: 1..3');
        Observer.Expect('e8', 'postdi C=3 T= F=No X=0/ P=0 S=7 Q= I=3/Id: 1..3');
        Observer.Expect('e9', 'post-before C=3 T= F=No X=0/ P=0 S=7 Q= I=3/Id: 1..3');
        Observer.Expect('single_after_run', '7');
        Observer.Verify();
    end;

}
