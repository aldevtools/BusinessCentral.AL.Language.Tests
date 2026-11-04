// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Query "REFUSED: query variables (persistence across calls), an OnBeforeOpen with statements (when it runs relative to the filters), several groups of an aggregated query with no OrderBy"
// BC versions: 29 (27 and 28 by CI)

codeunit 71147 "LT PnC Log 8"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

query 71093 "LT PnC Qry"
{
    QueryType = Normal;

    elements
    {
        dataitem(Src; "LT PnC Rec")
        {
            column(NoCol; "No.") { }
            column(OtherCol; Other) { }
            column(CodeCol; "Code Value") { }
        }
    }

    var
        Counter: Integer;
        Mode: Integer;
        Log: Codeunit "LT PnC Log 8";

    trigger OnBeforeOpen()
    begin
        Counter += 1;
        Log.Add('BeforeOpen' + Format(Counter) + ':mode' + Format(Mode));
        case Mode of
            1:
                SetRange(NoCol, 4);
            2:
                SetFilter(NoCol, '>3');
            3:
                SetRange(OtherCol, 20, 30);
        end;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

query 71094 "LT PnC Qry Agg"
{
    QueryType = Normal;

    elements
    {
        dataitem(Src; "LT PnC Rec")
        {
            column(CodeCol; "Code Value") { }
            column(Cnt) { Method = Count; }
            column(SumOther; Other) { Method = Sum; }
            column(MaxOther; Other) { Method = Max; }
        }
    }
}

codeunit 71132 "LT PnC Query Vars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 6 do begin
            R.Init();
            R."No." := i;
            R.Other := i * 10;
            R."Code Value" := 'C' + Format(i mod 3);
            R.Insert();
        end;
    end;

    local procedure Rows(var Q: Query "LT PnC Qry"): Text
    var
        Result: Text;
    begin
        while Q.Read() do begin
            Result += Format(Q.NoCol) + ',';
        end;
        exit(Result);
    end;

    [Test]
    procedure Variables_Persist_AcrossOpens()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 8";
        Q: Query "LT PnC Qry";
    begin
        Seed();
        Log.Reset();
        Observer.Observe('counter.initial', Format(Q.GetCounter()));
        Q.Open();
        Observer.Observe('counter.afterOpen', Format(Q.GetCounter()));
        Observer.Observe('rows', Rows(Q));
        Q.Close();
        Q.Open();
        Observer.Observe('counter.afterReopen', Format(Q.GetCounter()));
        Q.Close();
        Clear(Q);
        Observer.Observe('counter.afterClear', Format(Q.GetCounter()));
        Q.Open();
        Observer.Observe('counter.afterClearOpen', Format(Q.GetCounter()));
        Q.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Expect('counter.initial', '0');
        Observer.Expect('counter.afterOpen', '1');
        Observer.Expect('rows', '1,2,3,4,5,6,');
        Observer.Expect('counter.afterReopen', '2');
        Observer.Expect('counter.afterClear', '0');
        Observer.Expect('counter.afterClearOpen', '1');
        Observer.Expect('log', 'BeforeOpen1:mode0|BeforeOpen2:mode0|BeforeOpen1:mode0');
        Observer.Verify();
    end;

    [Test]
    procedure Mode_SetBeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnC Qry";
    begin
        Seed();
        Q.SetMode(1);
        Q.Open();
        Observer.Observe('mode1.rows', Rows(Q));
        Q.Close();
        Q.SetMode(2);
        Q.Open();
        Observer.Observe('mode2.rows', Rows(Q));
        Q.Close();
        Observer.Expect('mode1.rows', '4,');
        Observer.Expect('mode2.rows', '4,5,6,');
        Observer.Verify();
    end;

    [Test]
    procedure OnBeforeOpen_Filters_VsCaller()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnC Qry";
    begin
        Seed();
        Q.SetMode(1);
        Q.SetRange(NoCol, 1, 2);
        Q.Open();
        Observer.Observe('callerRange.triggerSetRangeSameColumn', Rows(Q));
        Q.Close();
        Clear(Q);
        Q.SetMode(3);
        Q.SetRange(NoCol, 1, 3);
        Q.Open();
        Observer.Observe('callerNo.triggerOtherColumn', Rows(Q));
        Q.Close();
        Clear(Q);
        Q.SetMode(2);
        Q.SetFilter(NoCol, '<6');
        Q.Open();
        Observer.Observe('callerFilter.triggerFilterSameColumn', Rows(Q));
        Q.Close();
        Observer.Expect('callerRange.triggerSetRangeSameColumn', '4,');
        Observer.Expect('callerNo.triggerOtherColumn', '2,3,');
        Observer.Expect('callerFilter.triggerFilterSameColumn', '4,5,6,');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_SeveralGroups_NoOrderBy()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnC Qry Agg";
        n: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            n += 1;
            Observer.Observe('row' + Format(n), Q.CodeCol + '|' + Format(Q.Cnt) + '|' + Format(Q.SumOther) + '|' + Format(Q.MaxOther));
        end;
        Q.Close();
        Observer.Observe('rows', Format(n));
        Observer.Expect('row1', 'C0|2|90|60');
        Observer.Expect('row2', 'C1|2|50|40');
        Observer.Expect('row3', 'C2|2|70|50');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_FilteredGroups()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnC Qry Agg";
        n: Integer;
    begin
        Seed();
        Q.SetRange(CodeCol, 'C1', 'C2');
        Q.Open();
        while Q.Read() do begin
            n += 1;
            Observer.Observe('row' + Format(n), Q.CodeCol + '|' + Format(Q.Cnt) + '|' + Format(Q.SumOther));
        end;
        Q.Close();
        Observer.Expect('row1', 'C1|2|50');
        Observer.Expect('row2', 'C2|2|70');
        Observer.Verify();
    end;
}
