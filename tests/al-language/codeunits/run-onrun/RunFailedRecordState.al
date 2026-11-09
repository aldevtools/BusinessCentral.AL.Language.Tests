// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: what the caller's record looks like after Codeunit.Run(Rec) of a codeunit with TableNo failed, compared with a run that succeeded
//   (aldevtools/BusinessCentral.AL.Runner#6924). Matrix: way of calling x change made inside OnRun x kind of failure x temporary record x state of the
//   codeunit variable. Related: RunCommitClear.al CodeunitRun_RecordByReference (the asserterror shape with a plain field change only).
// local object: tables 67420 and 67421 are needed because the probe changes the keys, filters and a FlowField of the record that goes into the run, and
//   codeunits 67422 to 67426 (runner with TableNo, publisher, subscriber) because the failing OnRun, the failing nested procedure and the failing subscriber are the
//   variables of the probe. LT SyT Runner (RunCommitClear.al) has one change and one failure only.
// BC versions: 27.5+

table 67420 "LT RFR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Amount; Decimal) { InitValue = 7; }
        field(3; Name; Text[30]) { }
        field(4; Qty; Integer) { }
        field(5; Mode; Text[30]) { }
        field(6; Kids; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RFR Child" where("Parent Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(ByName; Name, Code) { }
    }
}

table 67421 "LT RFR Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Parent Code"; Code[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67425 "LT RFR Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnFail(var Row: Record "LT RFR Row")
    begin
    end;
}

codeunit 67426 "LT RFR Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT RFR Publisher", 'OnFail', '', false, false)]
    local procedure FailInSubscriber(var Row: Record "LT RFR Row")
    begin
        Row.Amount := 77;
        Error('subscriber boom');
    end;
}

codeunit 67422 "LT RFR Runner"
{
    TableNo = "LT RFR Row";

    var
        Calls: Integer;
        Trail: Text;

    // Rec.Mode is '<change>|<failure>'.
    trigger OnRun()
    var
        Pos: Integer;
        Change: Text;
        Failure: Text;
    begin
        Pos := StrPos(Rec.Mode, '|');
        Change := CopyStr(Rec.Mode, 1, Pos - 1);
        Failure := CopyStr(Rec.Mode, Pos + 1);
        Calls += 1;
        Trail += Change + ';';
        ApplyChange(Change);
        RaiseFailure(Failure);
    end;

    local procedure ApplyChange(Change: Text)
    begin
        case Change of
            'fields':
                begin
                    Rec.Amount := 99;
                    Rec.Name := 'changed';
                end;
            'modify':
                begin
                    Rec.Amount := 99;
                    Rec.Name := 'changed';
                    Rec.Modify();
                end;
            'insert':
                begin
                    Rec.Code := 'NEW';
                    Rec.Amount := 99;
                    Rec.Insert();
                end;
            'delete':
                Rec.Delete();
            'rename':
                Rec.Rename('R');
            'setrange':
                Rec.SetRange(Code, 'A', 'B');
            'setfilter':
                Rec.SetFilter(Name, 'a*|b*');
            'setkey':
                Rec.SetCurrentKey(Name);
            'get':
                Rec.Get('B');
            'init':
                Rec.Init();
            'validate':
                Rec.Validate(Amount, 55);
            'marks':
                begin
                    Rec.Mark(true);
                    Rec.MarkedOnly(true);
                end;
            'calcfields':
                Rec.CalcFields(Kids);
        end;
    end;

    local procedure RaiseFailure(Failure: Text)
    var
        Publisher: Codeunit "LT RFR Publisher";
    begin
        case Failure of
            'error':
                Error('boom');
            'empty':
                Error('');
            'nested':
                NestedBoom();
            'sub':
                Publisher.OnFail(Rec);
        end;
    end;

    local procedure NestedBoom()
    begin
        Rec.Amount := 88;
        Error('nested boom');
    end;

    procedure GetCalls(): Integer
    begin
        exit(Calls);
    end;

    procedure GetTrail(): Text
    begin
        exit(Trail);
    end;
}

codeunit 67423 "LT RFR Run Failed Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT RFR Row";
        Kid: Record "LT RFR Child";
        I: Integer;
    begin
        Row.DeleteAll();
        Kid.DeleteAll();
        Row.Code := 'A';
        Row.Amount := 10;
        Row.Name := 'a';
        Row.Qty := 1;
        Row.Insert();
        Row.Code := 'B';
        Row.Amount := 20;
        Row.Name := 'b';
        Row.Qty := 2;
        Row.Insert();
        for I := 1 to 2 do begin
            Kid.Id := I;
            Kid."Parent Code" := 'A';
            Kid.Insert();
        end;
        Commit();
    end;

    local procedure CleanUp()
    var
        Row: Record "LT RFR Row";
        Kid: Record "LT RFR Child";
    begin
        Row.DeleteAll();
        Kid.DeleteAll();
        Commit();
    end;

    local procedure Describe(var R: Record "LT RFR Row"): Text
    var
        Cp: Record "LT RFR Row";
        NextOk: Integer;
        Probe: Text;
    begin
        Cp := R;
        NextOk := Cp.Next();
        Probe := StrSubstNo('%1:%2', NextOk, Cp.Code);
        exit(StrSubstNo('code=%1 amt=%2 name=%3 qty=%4 kids=%5 mode=%6 filters=[%7] key=%8 markedonly=%9 mark=%10 next=%11',
            R.Code, R.Amount, R.Name, R.Qty, R.Kids, R.Mode, R.GetFilters(), R.CurrentKey(), R.MarkedOnly(), R.Mark(), Probe));
    end;

    local procedure DbState(): Text
    var
        Row: Record "LT RFR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += StrSubstNo('%1:%2:%3,', Row.Code, Row.Amount, Row.Name);
            until Row.Next() = 0;
        exit(Result + 'n=' + Format(Row.Count()));
    end;

    // Form: 0 Ok := Codeunit.Run(Id, Rec); 1 if not Codeunit.Run(Id, Rec); 2 Ok := Cu.Run(Rec); 3 asserterror Codeunit.Run(Id, Rec);
    // 4 asserterror Cu.Run(Rec).
    local procedure RunCase(Change: Text; Failure: Text; Form: Integer): Text
    var
        Row: Record "LT RFR Row";
        Cu: Codeunit "LT RFR Runner";
        Ok: Boolean;
        Prefix: Text;
    begin
        Seed();
        Row.Get('A');
        Row.Mode := CopyStr(Change + '|' + Failure, 1, MaxStrLen(Row.Mode));
        case Form of
            0:
                Ok := Codeunit.Run(Codeunit::"LT RFR Runner", Row);
            1:
                if Codeunit.Run(Codeunit::"LT RFR Runner", Row) then
                    Ok := true
                else
                    Ok := false;
            2:
                Ok := Cu.Run(Row);
            3:
                asserterror Codeunit.Run(Codeunit::"LT RFR Runner", Row);
            4:
                asserterror Cu.Run(Row);
        end;
        if Form in [3, 4] then begin
            Prefix := StrSubstNo('err=[%1] ', GetLastErrorText());
            ClearLastError();
        end else
            Prefix := StrSubstNo('ok=%1 err=[%2] ', Ok, GetLastErrorText());
        ClearLastError();
        Prefix += StrSubstNo('calls=%1 ', Cu.GetCalls());
        exit(Prefix + Describe(Row) + ' db=' + DbState());
    end;

    local procedure ObserveChange(Observer: Codeunit "Probe Observer"; Change: Text)
    begin
        Observer.Observe(Change + ' fails', RunCase(Change, 'error', 0));
        Observer.Observe(Change + ' succeeds', RunCase(Change, 'none', 0));
    end;

    [Test]
    procedure CodeunitRun_FailedRun_RecordByForm()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('result used, static', RunCase('modify', 'error', 0));
        Observer.Observe('if not, static', RunCase('modify', 'error', 1));
        Observer.Observe('result used, variable', RunCase('modify', 'error', 2));
        Observer.Observe('asserterror, static', RunCase('modify', 'error', 3));
        Observer.Observe('asserterror, variable', RunCase('modify', 'error', 4));
        Observer.Observe('succeeds, static', RunCase('modify', 'none', 0));
        Observer.Observe('succeeds, variable', RunCase('modify', 'none', 2));
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_FailedRun_FieldChanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChange(Observer, 'fields');
        ObserveChange(Observer, 'modify');
        ObserveChange(Observer, 'insert');
        ObserveChange(Observer, 'delete');
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_FailedRun_KeyChanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChange(Observer, 'rename');
        ObserveChange(Observer, 'get');
        ObserveChange(Observer, 'init');
        ObserveChange(Observer, 'validate');
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_FailedRun_FilterChanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChange(Observer, 'setrange');
        ObserveChange(Observer, 'setfilter');
        ObserveChange(Observer, 'setkey');
        ObserveChange(Observer, 'marks');
        ObserveChange(Observer, 'calcfields');
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_FailedRun_KindOfFailure()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Error in OnRun', RunCase('fields', 'error', 0));
        Observer.Observe('Error with empty text', RunCase('fields', 'empty', 0));
        Observer.Observe('Error in nested procedure', RunCase('fields', 'nested', 0));
        Observer.Observe('Error in subscriber', RunCase('fields', 'sub', 0));
        Observer.Observe('no error', RunCase('fields', 'none', 0));
        Observer.Observe('empty text, asserterror', RunCase('fields', 'empty', 3));
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_FailedRun_CodeunitVariableState()
    var
        Observer: Codeunit "Probe Observer";
        Cu: Codeunit "LT RFR Runner";
        Row: Record "LT RFR Row";
        Ok: Boolean;
    begin
        Seed();
        Row.Get('A');
        Row.Mode := 'fields|error';
        Ok := Cu.Run(Row);
        Observer.Observe('after failed run', StrSubstNo('ok=%1 calls=%2 trail=%3', Ok, Cu.GetCalls(), Cu.GetTrail()));
        Row.Mode := 'fields|none';
        Ok := Cu.Run(Row);
        Observer.Observe('after successful run', StrSubstNo('ok=%1 calls=%2 trail=%3', Ok, Cu.GetCalls(), Cu.GetTrail()));
        Row.Mode := 'fields|error';
        Ok := Cu.Run(Row);
        Observer.Observe('after second failed run', StrSubstNo('ok=%1 calls=%2 trail=%3', Ok, Cu.GetCalls(), Cu.GetTrail()));
        CleanUp();
        Observer.Finish();
    end;

    local procedure TempRows(var T: Record "LT RFR Row" temporary): Text
    var
        Cp: Record "LT RFR Row" temporary;
        Result: Text;
    begin
        Cp.Copy(T, true);
        Cp.Reset();
        if Cp.FindSet() then
            repeat
                Result += StrSubstNo('%1:%2:%3,', Cp.Code, Cp.Amount, Cp.Name);
            until Cp.Next() = 0;
        exit(StrSubstNo('code=%1 amt=%2 name=%3 rows=%4n=%5', T.Code, T.Amount, T.Name, Result, Cp.Count()));
    end;

    local procedure TempCase(Change: Text; Failure: Text): Text
    var
        Tmp: Record "LT RFR Row" temporary;
        Ok: Boolean;
    begin
        Tmp.Code := 'A';
        Tmp.Amount := 10;
        Tmp.Name := 'a';
        Tmp.Insert();
        Tmp.Code := 'B';
        Tmp.Amount := 20;
        Tmp.Name := 'b';
        Tmp.Insert();
        Tmp.Get('A');
        Tmp.Mode := CopyStr(Change + '|' + Failure, 1, MaxStrLen(Tmp.Mode));
        Ok := Codeunit.Run(Codeunit::"LT RFR Runner", Tmp);
        ClearLastError();
        exit(StrSubstNo('ok=%1 ', Ok) + TempRows(Tmp));
    end;

    [Test]
    procedure CodeunitRun_FailedRun_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('fields fails', TempCase('fields', 'error'));
        Observer.Observe('fields succeeds', TempCase('fields', 'none'));
        Observer.Observe('modify fails', TempCase('modify', 'error'));
        Observer.Observe('modify succeeds', TempCase('modify', 'none'));
        Observer.Observe('insert fails', TempCase('insert', 'error'));
        Observer.Observe('insert succeeds', TempCase('insert', 'none'));
        Observer.Observe('delete fails', TempCase('delete', 'error'));
        Observer.Observe('delete succeeds', TempCase('delete', 'none'));
        Observer.Observe('rename fails', TempCase('rename', 'error'));
        Observer.Observe('rename succeeds', TempCase('rename', 'none'));
        Observer.Finish();
    end;
}
