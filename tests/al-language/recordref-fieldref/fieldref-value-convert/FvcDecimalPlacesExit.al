// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-decimalplaces-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73384, helper codeunit 73384, test codeunit 73385
// Probe (AL Runner pull requests 9325 and 9326, the follow-up cells the review of corpus pull request 1641 asks for), next to
//   FvcExitValueMore.al and FvcTemporalIntoNumberMore.al of corpus pull request 1641 (this file uses none of their objects):
//   - A Decimal field with DecimalPlaces = 2:2 and one with 0:0, holding 1234.5 (and the 0:0 field also 1234): exit(FR.Value())
//     from a procedure that returns Code[20] or Text, and T := FR.Value() into a Text, for comparison. Does the field's
//     DecimalPlaces shape the text (1,234.50 / 1,235) or is it the plain Format of the value (1,234.5)?
//   - The DateTime 9999-12-31 23:59:59.999 (which a table field does not take: the Insert's error) and 9999-12-30 23:59:59.999
//     into a Duration and an Option, the late end of the DateTime cells.
//   - 0DT into an Option " ",A,B.
//   Each cell runs in a TryFunction and records "ok: <result>" (Format(.., 0, 9) for Duration and Option) or "E: <GetLastErrorText> |
//   <GetLastErrorCode>".
//   Observe round: every test ends with Observer.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
// BC versions: 27, 28, 29 by CI
table 73384 "LT FDP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dec22; Decimal) { DecimalPlaces = 2 : 2; }
        field(3; Dec00; Decimal) { DecimalPlaces = 0 : 0; }
        field(4; Dec00Whole; Decimal) { DecimalPlaces = 0 : 0; }
        field(5; DtF; DateTime) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73384 "LT FDP Probe"
{
    local procedure ExitCode20(var FR: FieldRef): Code[20]
    begin
        exit(FR.Value());
    end;

    local procedure ExitText(var FR: FieldRef): Text
    begin
        exit(FR.Value());
    end;

    [TryFunction]
    local procedure TryRead(var FR: FieldRef; Target: Text; var Result: Text)
    var
        T: Text;
        Dur: Duration;
        Opt: Option A,B,C;
        OptBlank: Option " ",A,B;
    begin
        case Target of
            'exit_code20':
                Result := ExitCode20(FR);
            'exit_text':
                Result := ExitText(FR);
            'assign_text':
                begin
                    T := FR.Value();
                    Result := T;
                end;
            'duration':
                begin
                    Dur := FR.Value();
                    Result := Format(Dur, 0, 9);
                end;
            'option':
                begin
                    Opt := FR.Value();
                    Result := Format(Opt, 0, 9);
                end;
            'option_blank':
                begin
                    OptBlank := FR.Value();
                    Result := Format(OptBlank, 0, 9);
                end;
        end;
    end;

    procedure Cell(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Dt: DateTime; Target: Text)
    var
        Row: Record "LT FDP Row";
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
        T: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Dec22 := 1234.5;
        Row.Dec00 := 1234.5;
        Row.Dec00Whole := 1234;
        Row.DtF := Dt;
        Row.Insert();
        RR.Open(Database::"LT FDP Row");
        RR.FindFirst();
        FR := RR.Field(FieldNo);
        ClearLastError();
        if TryRead(FR, Target, Result) then
            T := 'ok: ' + Result
        else
            T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        Observer.Observe(Target, T);
    end;
}

codeunit 73385 "LT FDP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DecimalCells(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    var
        Probe: Codeunit "LT FDP Probe";
    begin
        Probe.Cell(Observer, FieldNo, 0DT, 'exit_code20');
        Probe.Cell(Observer, FieldNo, 0DT, 'exit_text');
        Probe.Cell(Observer, FieldNo, 0DT, 'assign_text');
    end;

    // 1234.5 in a field with DecimalPlaces = 2:2.
    [Test]
    procedure DecimalPlaces22()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecimalCells(Observer, 2);
        Observer.Finish();
    end;

    // 1234.5 in a field with DecimalPlaces = 0:0.
    [Test]
    procedure DecimalPlaces00()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecimalCells(Observer, 3);
        Observer.Finish();
    end;

    // 1234 in a field with DecimalPlaces = 0:0.
    [Test]
    procedure DecimalPlaces00Whole()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecimalCells(Observer, 4);
        Observer.Finish();
    end;

    // Insert, then a read of the table: the Insert is sent to the database at the latest when the table is read.
    local procedure InsertAndRead(var Row: Record "LT FDP Row")
    var
        Again: Record "LT FDP Row";
    begin
        Row.Insert();
        Again.FindFirst();
    end;

    // The DateTime 9999-12-31 23:59:59.999 cannot be stored in a table field: the error of the Insert and the read after it
    // (asserterror rolls the row back).
    [Test]
    procedure LateDateTime_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FDP Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.DtF := CreateDateTime(99991231D, 235959.999T);
        asserterror InsertAndRead(Row);
        Observer.ObserveError('insert');
        Observer.Finish();
    end;

    // The latest DateTime the field takes here, 9999-12-30 23:59:59.999, into a Duration and an Option A,B,C.
    [Test]
    procedure LateDateTime_DurationOption()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FDP Probe";
    begin
        Probe.Cell(Observer, 5, CreateDateTime(99991230D, 235959.999T), 'duration');
        Probe.Cell(Observer, 5, CreateDateTime(99991230D, 235959.999T), 'option');
        Observer.Finish();
    end;

    // 0DT into an Option " ",A,B.
    [Test]
    procedure BlankDateTime_BlankOption()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FDP Probe";
    begin
        Probe.Cell(Observer, 5, 0DT, 'option_blank');
        Observer.Finish();
    end;
}
