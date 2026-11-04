// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73159, report 73160, log 73161 (SingleInstance, used only by test codeunit 73162), test codeunit 73162
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: ClearAll() called inside a report: in OnPreReport, in OnAfterGetRecord of the second row, in OnPostReport. What it resets of the report's globals (Integer, Text, Boolean, Decimal,
// a List, a global Record with a filter, the data item's record with its filters) and how the data item loop continues. Codeunits and pages are pinned in record/ProbeClearAllSetKeyHyperlink.al.
// BC versions: 29 (27 and 28 by CI)

table 73159 "LT P128 CA Row"
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

codeunit 73161 "LT P128 CA Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        RunMode: Integer;

    procedure Reset(NewMode: Integer)
    begin
        Lines := '';
        RunMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(RunMode);
    end;

    procedure Add(Value: Text)
    begin
        Lines += Value + ' || ';
    end;

    procedure Joined(): Text
    begin
        exit(Lines);
    end;
}

report 73160 "LT P128 ClearAll Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Item; "LT P128 CA Row")
        {
            trigger OnPreDataItem()
            var
                Log: Codeunit "LT P128 CA Log";
            begin
                Log.Add('predataitem item filters=[' + Item.GetFilters() + ']');
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P128 CA Log";
            begin
                Counter += 1;
                Log.Add('row ' + Format(Item.Id) + ' counter=' + Format(Counter));
                if (Log.Mode() = 2) and (Item.Id = 2) then begin
                    ClearAll();
                    Snapshot('after clearall in row');
                end;
            end;

            trigger OnPostDataItem()
            var
                Log: Codeunit "LT P128 CA Log";
            begin
                Log.Add('postdataitem counter=' + Format(Counter));
            end;
        }
    }

    var
        Counter: Integer;
        Name: Text;
        Flag: Boolean;
        Dec: Decimal;
        Extra: Record "LT P128 CA Row";
        Items: List of [Text];

    local procedure Snapshot(Where: Text)
    var
        Log: Codeunit "LT P128 CA Log";
    begin
        Log.Add(Where + ': counter=' + Format(Counter) + ' name=[' + Name + '] flag=' + Format(Flag) + ' dec=' + Format(Dec) +
                ' extra filters=[' + Extra.GetFilters() + '] items=' + Format(Items.Count()) + ' item filters=[' + Item.GetFilters() + ']');
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT P128 CA Log";
    begin
        Counter := 7;
        Name := 'x';
        Flag := true;
        Dec := 1.5;
        Extra.SetRange(Id, 3);
        Items.Add('a');
        Snapshot('before');
        if Log.Mode() = 1 then begin
            ClearAll();
            Snapshot('after clearall in prereport');
        end;
    end;

    trigger OnPostReport()
    var
        Log: Codeunit "LT P128 CA Log";
    begin
        Snapshot('postreport before');
        if Log.Mode() = 3 then begin
            ClearAll();
            Snapshot('after clearall in postreport');
        end;
    end;
}

codeunit 73162 "LT P128 ClearAll Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Mode: Integer)
    var
        Row: Record "LT P128 CA Row";
        Log: Codeunit "LT P128 CA Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Insert();
        Log.Reset(Mode);
    end;

    [TryFunction]
    local procedure TryRun()
    var
        Rpt: Report "LT P128 ClearAll Rpt";
    begin
        Rpt.Run();
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        Log: Codeunit "LT P128 CA Log";
    begin
        if Ok then
            exit('ok || ' + Log.Joined());
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' || ' + Log.Joined());
    end;

    [Test]
    procedure P128_ClearAll_NotCalled_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(0);
        Observer.Observe('control run', Outcome(TryRun()));
        Observer.Expect('control run', 'ok || before: counter=7 name=[x] flag=Yes dec=1.5 extra filters=[Id: 3] items=1 item filters=[] || predataitem item filters=[] || row 1 counter=8 || row 2 counter=9 || row 3 counter=10 || postdataitem counter=10 || postreport before: counter=10 name=[x] flag=Yes dec=1.5 extra filters=[Id: 3] items=1 item filters=[] || ');
        Observer.Verify();
    end;

    [Test]
    procedure P128_ClearAll_InOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(1);
        Observer.Observe('run', Outcome(TryRun()));
        Observer.Expect('run', 'ok || before: counter=7 name=[x] flag=Yes dec=1.5 extra filters=[Id: 3] items=1 item filters=[] || after clearall in prereport: counter=0 name=[] flag=No dec=0 extra filters=[] items=0 item filters=[] || predataitem item filters=[] || row 1 counter=1 || row 2 counter=2 || row 3 counter=3 || postdataitem counter=3 || postreport before: counter=3 name=[] flag=No dec=0 extra filters=[] items=0 item filters=[] || ');
        Observer.Verify();
    end;
}
