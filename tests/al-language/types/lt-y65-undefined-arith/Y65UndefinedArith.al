// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); table 93351, test codeunit 93349; System Application retention policy codeunits
// Probe (al-runner issue 6678; 0DT - 0DT = 0 and the system fields of a record never inserted are
//   types/lt-y62-undefined-date/Y62UndefinedDate.al, Date - 0D, 0D - Date, 0D + 0, 0D + 1 and 0D - 1 are types/lt-datetime/Arithmetic.al,
//   0T - 0T is misc/lt-cq-odd-leads/CqOddLeads.al, 0T - Time is types/PUTimeArithmetic.al): the rest of the arithmetic, comparison and
//   conversion of undefined Date (0D), Time (0T) and DateTime (0DT) values held in variables: 0D - 0D, 0T + n, 0T - n, Time - 0T, 0DT + n,
//   0DT - n, 0DT + 0, DateTime + 0, the Duration of 0DT - 0DT into Integer, BigInteger, Decimal and Duration, comparisons with a defined
//   value, CreateDateTime and DT2Date/DT2Time with undefined parts. And the reporter's Apply Retention Policy with a setup record that was
//   never inserted.
// BC versions: 27, 28, 29

table 93351 "LT Y65 UA Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Logged At"; DateTime) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 93349 "LT Y65 Undefined Arith"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Result: Text;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok:' + Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDateMinusDate(A: Date; B: Date)
    var
        I: Integer;
    begin
        I := A - B;
        Result := Format(I);
    end;

    [TryFunction]
    local procedure TryTimePlus(T: Time; N: Integer)
    begin
        Result := Format(T + N, 0, 9);
    end;

    [TryFunction]
    local procedure TryTimeMinus(T: Time; N: Integer)
    begin
        Result := Format(T - N, 0, 9);
    end;

    [TryFunction]
    local procedure TryTimeMinusTime(A: Time; B: Time)
    var
        I: Integer;
    begin
        I := A - B;
        Result := Format(I);
    end;

    [TryFunction]
    local procedure TryDtPlus(Dt: DateTime; N: BigInteger)
    begin
        Result := Format(Dt + N, 0, 9);
    end;

    [TryFunction]
    local procedure TryDtMinus(Dt: DateTime; N: BigInteger)
    begin
        Result := Format(Dt - N, 0, 9);
    end;

    [TryFunction]
    local procedure TryDtPlusDuration(Dt: DateTime; D: Duration)
    begin
        Result := Format(Dt + D, 0, 9);
    end;

    [TryFunction]
    local procedure TryDtMinusDtInto(A: DateTime; B: DateTime; Kind: Text)
    var
        I: Integer;
        Big: BigInteger;
        Dec: Decimal;
        D: Duration;
    begin
        case Kind of
            'Integer':
                begin
                    I := A - B;
                    Result := Format(I);
                end;
            'BigInteger':
                begin
                    Big := A - B;
                    Result := Format(Big);
                end;
            'Decimal':
                begin
                    Dec := A - B;
                    Result := Format(Dec);
                end;
            'Duration':
                begin
                    D := A - B;
                    Result := Format(D) + '|' + Format(D, 0, 9);
                end;
        end;
    end;

    [TryFunction]
    local procedure TryCreateDateTime(D: Date; T: Time)
    var
        Dt: DateTime;
    begin
        Dt := CreateDateTime(D, T);
        Result := Format(Dt, 0, 9) + '|is0DT=' + Format(Dt = 0DT);
    end;

    [TryFunction]
    local procedure TryDT2Date(Dt: DateTime)
    begin
        Result := Format(DT2Date(Dt), 0, 9) + '|is0D=' + Format(DT2Date(Dt) = 0D);
    end;

    [TryFunction]
    local procedure TryDT2Time(Dt: DateTime)
    begin
        Result := Format(DT2Time(Dt), 0, 9) + '|is0T=' + Format(DT2Time(Dt) = 0T);
    end;

    [Test]
    procedure Y65_UndefinedDate_Arithmetic()
    var
        Undefined: Date;
        Defined: Date;
    begin
        Undefined := 0D;
        Defined := 20240115D;
        Observer.Observe('0D - 0D', Outcome(TryDateMinusDate(Undefined, Undefined)));
        Observer.Observe('0D < D', Format(Undefined < Defined));
        Observer.Observe('0D > D', Format(Undefined > Defined));
        Observer.Observe('0D = 0D', Format(Undefined = 0D));
        Observer.Observe('format 0D', '[' + Format(Undefined) + ']');
        Observer.Finish();
    end;

    [Test]
    procedure Y65_UndefinedTime_Arithmetic()
    var
        Undefined: Time;
        Defined: Time;
    begin
        Undefined := 0T;
        Defined := 100000T;
        Observer.Observe('0T + 1000', Outcome(TryTimePlus(Undefined, 1000)));
        Observer.Observe('0T + 0', Outcome(TryTimePlus(Undefined, 0)));
        Observer.Observe('0T - 1000', Outcome(TryTimeMinus(Undefined, 1000)));
        Observer.Observe('T - 0T', Outcome(TryTimeMinusTime(Defined, Undefined)));
        Observer.Observe('T + 0', Outcome(TryTimePlus(Defined, 0)));
        Observer.Observe('0T < T', Format(Undefined < Defined));
        Observer.Observe('0T < 000000T', Format(Undefined < 000000T));
        Observer.Observe('format 0T', '[' + Format(Undefined) + ']');
        Observer.Finish();
    end;

    [Test]
    procedure Y65_UndefinedDateTime_Arithmetic()
    var
        Undefined: DateTime;
        Defined: DateTime;
        Zero: Duration;
    begin
        Undefined := 0DT;
        Defined := CreateDateTime(20240115D, 100000T);
        Observer.Observe('0DT + 1000', Outcome(TryDtPlus(Undefined, 1000)));
        Observer.Observe('0DT + 0', Outcome(TryDtPlus(Undefined, 0)));
        Observer.Observe('0DT - 1000', Outcome(TryDtMinus(Undefined, 1000)));
        Observer.Observe('0DT - 0', Outcome(TryDtMinus(Undefined, 0)));
        Observer.Observe('0DT + Duration 0', Outcome(TryDtPlusDuration(Undefined, Zero)));
        Observer.Observe('DT + 0', Outcome(TryDtPlus(Defined, 0)));
        Observer.Observe('0DT - 0DT into Integer', Outcome(TryDtMinusDtInto(Undefined, Undefined, 'Integer')));
        Observer.Observe('0DT - 0DT into BigInteger', Outcome(TryDtMinusDtInto(Undefined, Undefined, 'BigInteger')));
        Observer.Observe('0DT - 0DT into Decimal', Outcome(TryDtMinusDtInto(Undefined, Undefined, 'Decimal')));
        Observer.Observe('0DT - 0DT into Duration', Outcome(TryDtMinusDtInto(Undefined, Undefined, 'Duration')));
        Observer.Observe('0DT < DT', Format(Undefined < Defined));
        Observer.Observe('0DT > DT', Format(Undefined > Defined));
        Observer.Observe('0DT = 0DT', Format(Undefined = 0DT));
        Observer.Observe('CreateDateTime(0D, 0T)', Outcome(TryCreateDateTime(0D, 0T)));
        Observer.Observe('CreateDateTime(0D, 120000T)', Outcome(TryCreateDateTime(0D, 120000T)));
        Observer.Observe('CreateDateTime(D, 0T)', Outcome(TryCreateDateTime(20240115D, 0T)));
        Observer.Observe('DT2Date(0DT)', Outcome(TryDT2Date(Undefined)));
        Observer.Observe('DT2Time(0DT)', Outcome(TryDT2Time(Undefined)));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Reporter_SubtractTwoUndefinedDateTimes()
    var
        Earlier: DateTime;
        Later: DateTime;
        Elapsed: Duration;
    begin
        // al-runner issue 6678, the reporter's first test.
        Earlier := 0DT;
        Later := 0DT;
        Elapsed := Later - Earlier;
        Observer.Observe('elapsed = 0', Format(Elapsed = 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Reporter_ApplyRetentionPolicyWithAnUnsavedSetup()
    var
        ReproLog: Record "LT Y65 UA Log";
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RetentionPolicySetupMgt: Codeunit "Retention Policy Setup";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        // al-runner issue 6678, the reporter's second test: the setup record is never inserted, so its SystemCreatedAt and
        // SystemModifiedAt are 0DT, and Apply Retention Policy subtracts them.
        ReproLog.DeleteAll();
        RetenPolAllowedTables.AddAllowedTable(Database::"LT Y65 UA Log", ReproLog.FieldNo("Logged At"));
        ReproLog."Logged At" := CurrentDateTime() - (10 * 86400000);
        ReproLog.Insert();
        ReproLog."Entry No." := 0;
        ReproLog."Logged At" := CurrentDateTime();
        ReproLog.Insert();
        RetentionPolicySetup."Table Id" := Database::"LT Y65 UA Log";
        RetentionPolicySetup."Retention Period" := RetentionPolicySetupMgt.FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Week");
        RetentionPolicySetup."Date Field No." := ReproLog.FieldNo("Logged At");
        RetentionPolicySetup."Apply to all records" := true;
        RetentionPolicySetup.Enabled := true;
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);
        ReproLog.Reset();
        Observer.Observe('rows left', Format(ReproLog.Count()));
        Observer.Finish();
    end;
}
