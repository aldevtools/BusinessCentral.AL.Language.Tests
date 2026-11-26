// Probe (observing): from al-runner issue 8970, guarded Codeunit.Run(Id, Rec) with a filtered record argument.

table 88984 "GRQ X"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 88985 "GRQ Y"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 88986 "GRQ Z"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The steps the inner codeunit runs, and a log the caller writes (a SingleInstance codeunit is not rolled back).
codeunit 88987 "GRQ Mode"
{
    SingleInstance = true;

    var
        Steps: Text;
        LogText: Text;

    procedure Set(NewSteps: Text)
    begin
        Steps := NewSteps;
        LogText := '';
    end;

    procedure Get(): Text
    begin
        exit(Steps);
    end;

    procedure Log(Line: Text)
    begin
        LogText += Line + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

// The step interpreter: runs the steps of "GRQ Mode", comma separated.
//   startx: insert a row into GRQ X and mark GRQ X from the same local variable (the preview state shape).
//   fxa, fya, fyc: Consistent(false) on a local variable of DoSteps for GRQ X, GRQ Y (a), GRQ Y (c).
//   frec: Consistent(false) on the record argument of the run. commit: Commit. err: Error('inner failed').
codeunit 88988 "GRQ Steps"
{
    procedure DoSteps(var RecX: Record "GRQ X"; var RecY: Record "GRQ Y"; var RecZ: Record "GRQ Z"; Which: Text)
    var
        Mode: Codeunit "GRQ Mode";
        XA: Record "GRQ X";
        YA: Record "GRQ Y";
        YC: Record "GRQ Y";
        Step: Text;
    begin
        foreach Step in Mode.Get().Split(',') do
            case Step of
                'startx':
                    StartX();
                'fxa':
                    XA.Consistent(false);
                'fya':
                    YA.Consistent(false);
                'fyc':
                    YC.Consistent(false);
                'frec':
                    case Which of
                        'x':
                            RecX.Consistent(false);
                        'y':
                            RecY.Consistent(false);
                        'z':
                            RecZ.Consistent(false);
                    end;
                'commit':
                    Commit();
                'err':
                    Error('inner failed');
            end;
    end;

    local procedure StartX()
    var
        X: Record "GRQ X";
    begin
        X.Init();
        X.Id := 50;
        X.Name := 'state';
        X.Insert();
        X.Consistent(false);
    end;
}

// The inner codeunit for a record of GRQ X. It logs the filters and the row count it sees on its argument.
codeunit 88989 "GRQ Inner X"
{
    TableNo = "GRQ X";

    trigger OnRun()
    var
        Steps: Codeunit "GRQ Steps";
        Mode: Codeunit "GRQ Mode";
        NoY: Record "GRQ Y";
        NoZ: Record "GRQ Z";
    begin
        Mode.Log('inner filters=' + Rec.GetFilters() + ' count=' + Format(Rec.Count()));
        Steps.DoSteps(Rec, NoY, NoZ, 'x');
    end;
}

// The inner codeunit for a record of GRQ Y. It logs the filters and the row count it sees on its argument.
codeunit 88990 "GRQ Inner Y"
{
    TableNo = "GRQ Y";

    trigger OnRun()
    var
        Steps: Codeunit "GRQ Steps";
        Mode: Codeunit "GRQ Mode";
        NoX: Record "GRQ X";
        NoZ: Record "GRQ Z";
    begin
        Mode.Log('inner filters=' + Rec.GetFilters() + ' count=' + Format(Rec.Count()));
        Steps.DoSteps(NoX, Rec, NoZ, 'y');
    end;
}

// The inner codeunit for a record of GRQ Z. It logs the filters and the row count it sees on its argument.
codeunit 88991 "GRQ Inner Z"
{
    TableNo = "GRQ Z";

    trigger OnRun()
    var
        Steps: Codeunit "GRQ Steps";
        Mode: Codeunit "GRQ Mode";
        NoX: Record "GRQ X";
        NoY: Record "GRQ Y";
    begin
        Mode.Log('inner filters=' + Rec.GetFilters() + ' count=' + Format(Rec.Count()));
        Steps.DoSteps(NoX, NoY, Rec, 'z');
    end;
}

codeunit 88992 "GRQ Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Codeunit "GRQ Mode";

    // Every cell starts with two committed rows in each table: Id 1 'caller' and Id 2 'other'. The run gets the first one.
    local procedure Initialize(Steps: Text)
    var
        X: Record "GRQ X";
        Y: Record "GRQ Y";
        Z: Record "GRQ Z";
    begin
        X.Consistent(true);
        Y.Consistent(true);
        Z.Consistent(true);
        X.DeleteAll();
        Y.DeleteAll();
        Z.DeleteAll();
        X.Init();
        X.Id := 1;
        X.Name := 'caller';
        X.Insert();
        X.Id := 2;
        X.Name := 'other';
        X.Insert();
        Y.Init();
        Y.Id := 1;
        Y.Name := 'caller';
        Y.Insert();
        Y.Id := 2;
        Y.Name := 'other';
        Y.Insert();
        Z.Init();
        Z.Id := 1;
        Z.Name := 'caller';
        Z.Insert();
        Z.Id := 2;
        Z.Name := 'other';
        Z.Insert();
        Commit();
        ClearLastError();
        Mode.Set(Steps);
    end;

    local procedure Rows(): Text
    var
        X: Record "GRQ X";
        Y: Record "GRQ Y";
        Z: Record "GRQ Z";
        XNames: Text;
        YNames: Text;
        ZNames: Text;
    begin
        if X.FindSet() then
            repeat
                XNames += X.Name + ';';
            until X.Next() = 0;
        if Y.FindSet() then
            repeat
                YNames += Y.Name + ';';
            until Y.Next() = 0;
        if Z.FindSet() then
            repeat
                ZNames += Z.Name + ';';
            until Z.Next() = 0;
        exit('x=[' + XNames + '] y=[' + YNames + '] z=[' + ZNames + ']');
    end;

    // The rows a commit made durable: an unrelated error undoes every write since the last commit.
    local procedure DurableRows(): Text
    begin
        asserterror Error('unrelated');
        ClearLastError();
        exit(Rows());
    end;

    local procedure Describe(var RecRef: RecordRef): Text
    begin
        exit('filters=' + RecRef.GetFilters() + ' markedonly=' + Format(RecRef.MarkedOnly()) + ' count=' + Format(RecRef.Count()));
    end;

    // Runs the inner codeunit. Kind: z, x, y = a database record of GRQ Z / X / Y; tx = a temporary GRQ X record with the same two rows.
    // Filter: none, key, name, flt (SetFilter), marked (Mark the row, then MarkedOnly). The argument is on the row 'caller'.
    local procedure RunRec(Kind: Text; Filter: Text; var ArgName: Text; var ArgState: Text) Ok: Boolean
    var
        X: Record "GRQ X";
        Y: Record "GRQ Y";
        Z: Record "GRQ Z";
        TempX: Record "GRQ X" temporary;
        RecRef: RecordRef;
    begin
        case Kind of
            'z':
                begin
                    PrepareZ(Z, Filter);
                    Ok := Codeunit.Run(Codeunit::"GRQ Inner Z", Z);
                    ArgName := Z.Name;
                    RecRef.GetTable(Z);
                end;
            'x':
                begin
                    PrepareX(X, Filter);
                    Ok := Codeunit.Run(Codeunit::"GRQ Inner X", X);
                    ArgName := X.Name;
                    RecRef.GetTable(X);
                end;
            'y':
                begin
                    PrepareY(Y, Filter);
                    Ok := Codeunit.Run(Codeunit::"GRQ Inner Y", Y);
                    ArgName := Y.Name;
                    RecRef.GetTable(Y);
                end;
            'tx':
                begin
                    TempX.Init();
                    TempX.Id := 1;
                    TempX.Name := 'caller';
                    TempX.Insert();
                    TempX.Id := 2;
                    TempX.Name := 'other';
                    TempX.Insert();
                    PrepareX(TempX, Filter);
                    Ok := Codeunit.Run(Codeunit::"GRQ Inner X", TempX);
                    ArgName := TempX.Name;
                    RecRef.GetTable(TempX);
                end;
        end;
        ArgState := Describe(RecRef);
    end;

    local procedure PrepareX(var Rec: Record "GRQ X"; Filter: Text)
    begin
        case Filter of
            'key':
                Rec.SetRange(Id, 1);
            'name':
                Rec.SetRange(Name, 'caller');
            'flt':
                Rec.SetFilter(Name, 'call*|zzz');
            'marked':
                begin
                    Rec.FindFirst();
                    Rec.Mark(true);
                    Rec.MarkedOnly(true);
                end
        end;
        Rec.FindFirst();
    end;

    local procedure PrepareY(var Rec: Record "GRQ Y"; Filter: Text)
    begin
        case Filter of
            'key':
                Rec.SetRange(Id, 1);
            'name':
                Rec.SetRange(Name, 'caller');
            'flt':
                Rec.SetFilter(Name, 'call*|zzz');
            'marked':
                begin
                    Rec.FindFirst();
                    Rec.Mark(true);
                    Rec.MarkedOnly(true);
                end
        end;
        Rec.FindFirst();
    end;

    local procedure PrepareZ(var Rec: Record "GRQ Z"; Filter: Text)
    begin
        case Filter of
            'key':
                Rec.SetRange(Id, 1);
            'name':
                Rec.SetRange(Name, 'caller');
            'flt':
                Rec.SetFilter(Name, 'call*|zzz');
            'marked':
                begin
                    Rec.FindFirst();
                    Rec.Mark(true);
                    Rec.MarkedOnly(true);
                end
        end;
        Rec.FindFirst();
    end;

    local procedure RunThenEnd(Kind: Text; Filter: Text)
    var
        Ok: Boolean;
        ArgName: Text;
        ArgState: Text;
    begin
        Ok := RunRec(Kind, Filter, ArgName, ArgState);
        Mode.Log('run=' + Format(Ok));
        Mode.Log('text=' + GetLastErrorText());
        Mode.Log('code=' + GetLastErrorCode());
        Mode.Log('arg=' + ArgName);
        Mode.Log('argstate ' + ArgState);
        ClearLastError();
        Error('END');
    end;

    local procedure CommitThenEnd()
    begin
        Commit();
        Error('END');
    end;

    local procedure RecCell(var Observer: Codeunit "Probe Observer"; Kind: Text; Filter: Text; Steps: Text)
    begin
        Initialize(Steps);
        asserterror RunThenEnd(Kind, Filter);
        Observer.ObserveError('run end');
        Observer.Observe('log', Mode.GetLog());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
    end;

    // The run as a plain statement (no asserterror around it).
    local procedure PlainCell(var Observer: Codeunit "Probe Observer"; Kind: Text; Filter: Text; Steps: Text)
    var
        Ok: Boolean;
        ArgName: Text;
        ArgState: Text;
    begin
        Initialize(Steps);
        Ok := RunRec(Kind, Filter, ArgName, ArgState);
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('arg', ArgName);
        Observer.Observe('argstate', ArgState);
        Observer.Observe('rows after run', Rows());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
    end;

    [Test]
    procedure RecZ_NoFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'none', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'none', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'none', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'none', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeKey_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'key', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeKey_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'key', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeKey_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'key', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeKey_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'key', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeKey_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'key', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeName_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'name', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeName_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'name', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeName_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'name', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetRangeName_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'name', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'flt', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'flt', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'flt', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'flt', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_SetFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'flt', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_MarkedOnly_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'marked', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_MarkedOnly_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'marked', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_MarkedOnly_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'marked', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_MarkedOnly_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'marked', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'none', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'none', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'none', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'none', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeKey_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'key', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeKey_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'key', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeKey_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'key', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeKey_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'key', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeKey_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'key', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeName_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'name', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeName_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'name', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeName_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'name', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetRangeName_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'name', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'flt', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'flt', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'flt', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'flt', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_SetFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'flt', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_MarkedOnly_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'marked', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_MarkedOnly_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'marked', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_MarkedOnly_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'marked', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_MarkedOnly_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'marked', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_NoFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'none', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_NoFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'none', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_NoFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'none', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_NoFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'none', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeKey_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'key', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeKey_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'key', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeKey_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'key', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeKey_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'key', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeKey_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'key', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeName_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'name', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeName_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'name', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeName_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'name', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetRangeName_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'name', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'flt', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'flt', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'flt', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'flt', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_SetFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'flt', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_MarkedOnly_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'marked', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_MarkedOnly_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'marked', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_MarkedOnly_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'marked', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecY_MarkedOnly_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'y', 'marked', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_NoFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'none', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_NoFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'none', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_NoFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'none', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_NoFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'none', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeKey_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'key', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeKey_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'key', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeKey_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'key', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeKey_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'key', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeKey_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'key', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeName_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'name', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeName_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'name', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeName_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'name', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetRangeName_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'name', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetFilter_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'flt', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'flt', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetFilter_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'flt', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetFilter_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'flt', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_SetFilter_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'flt', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_MarkedOnly_StartX_MarkYByA_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'marked', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_MarkedOnly_StartX_MarkYByA_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'marked', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_MarkedOnly_MarkXByA_MarkYByA_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'marked', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecTempX_MarkedOnly_MarkRec_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'tx', 'marked', 'frec,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecZ_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'z', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecZ_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'z', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecZ_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'z', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecX_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'x', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecX_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'x', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecX_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'x', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecY_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'y', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecY_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'y', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecY_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'y', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecTempX_NoFilter_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'tx', 'none', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecTempX_SetRangeName_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'tx', 'name', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_RecTempX_MarkedOnly_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'tx', 'marked', 'startx,fya,fyc,err');
        Observer.Finish();
    end;
}
