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
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session, UTC) on 2026-11-28 with an invented app holding
//   these objects (AL 18.0.43.1464, run by al runtests of AL tool 18.1.43.24897); the values are those readings, turned into
//   Expect and Verify by convert.py verbatim. BC 27.5.54899.59044 was measured by this pull request's CI observe run 46137073537
//   (both 27.5 legs alike): it equals BC 29 in every cell but the two DateTime-into-Option cells, where 27.5 gives 'Unable to
//   convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.' (Conversion); those two tests keep #if BC28PLUS /
//   #else, the other four have one block.
//   Facts (BC 29.0.54011.57673):
//   - The field's DecimalPlaces does not shape the text: 1234.5 gives 1,234.5 with DecimalPlaces 2:2 and with 0:0, and 1234 gives
//     1,234 with 0:0, the same through exit into Code[20] and Text and through T := FR.Value().
//   - 9999-12-31 23:59:59.999 cannot be stored: 'Cannot write the value 12/31/9999 11:59 PM to the field DtF in the table LT FDP
//     Row because the value is either too long or the content is invalid.' (NDBCS:BadCSideData), raised by the Insert or the read
//     right after it. 9999-12-30 23:59:59.999 reads back as 12/31/9999 12:00 AM (the milliseconds round up to the next day): into a
//     Duration it gives P3652424DT0H0M0.001S, into an Option 'The value "12/31/9999 12:00 AM" can't be evaluated into type
//     Option.' (Evaluate:Conversion).
//   - 0DT into an Option " ",A,B: 'The value "" can't be evaluated into type Option.' (Evaluate:Conversion), as into A,B,C.
//   - 9999-12-31 23:59:59, the end of the range the field takes: into a Duration P3652424DT23H59M59.001S, into an Option 'The value
//     "12/31/9999 11:59 PM" can't be evaluated into type Option.' (Evaluate:Conversion). Measured on BC 29 only: asserted on BC 28
//     and later; on BC 27.5 EndOfRangeDateTime_DurationOption is an observe round, red on purpose (#else ends with Finish()).
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
        Observer.Expect('exit_code20', 'ok: 1,234.5');
        Observer.Expect('exit_text', 'ok: 1,234.5');
        Observer.Expect('assign_text', 'ok: 1,234.5');
        Observer.Verify();
    end;

    // 1234.5 in a field with DecimalPlaces = 0:0.
    [Test]
    procedure DecimalPlaces00()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecimalCells(Observer, 3);
        Observer.Expect('exit_code20', 'ok: 1,234.5');
        Observer.Expect('exit_text', 'ok: 1,234.5');
        Observer.Expect('assign_text', 'ok: 1,234.5');
        Observer.Verify();
    end;

    // 1234 in a field with DecimalPlaces = 0:0.
    [Test]
    procedure DecimalPlaces00Whole()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DecimalCells(Observer, 4);
        Observer.Expect('exit_code20', 'ok: 1,234');
        Observer.Expect('exit_text', 'ok: 1,234');
        Observer.Expect('assign_text', 'ok: 1,234');
        Observer.Verify();
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
        Observer.Expect('insert|text', 'Cannot write the value 12/31/9999 11:59 PM to the field DtF in the table LT FDP Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    // A late DateTime, 9999-12-30 23:59:59.999, into a Duration and an Option A,B,C.
    [Test]
    procedure LateDateTime_DurationOption()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FDP Probe";
    begin
        Probe.Cell(Observer, 5, CreateDateTime(99991230D, 235959.999T), 'duration');
        Probe.Cell(Observer, 5, CreateDateTime(99991230D, 235959.999T), 'option');
#if BC28PLUS
        Observer.Expect('duration', 'ok: P3652424DT0H0M0.001S');
        Observer.Expect('option', 'E: The value "12/31/9999 12:00 AM" can''t be evaluated into type Option. | Evaluate:Conversion');
        Observer.Verify();
#else // BC 27.5 gives another result, measured by this PR's CI run 46137073537 on 27.5 (both 27.5 legs agree)
        Observer.Expect('duration', 'ok: P3652424DT0H0M0.001S');
        Observer.Expect('option', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32. | Conversion');
        Observer.Verify();
#endif
    end;

    // 0DT into an Option " ",A,B.
    [Test]
    procedure BlankDateTime_BlankOption()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FDP Probe";
    begin
        Probe.Cell(Observer, 5, 0DT, 'option_blank');
#if BC28PLUS
        Observer.Expect('option_blank', 'E: The value "" can''t be evaluated into type Option. | Evaluate:Conversion');
        Observer.Verify();
#else // BC 27.5 gives another result, measured by this PR's CI run 46137073537 on 27.5 (both 27.5 legs agree)
        Observer.Expect('option_blank', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32. | Conversion');
        Observer.Verify();
#endif
    end;

    // The end of the range a table field takes, 9999-12-31 23:59:59 (no milliseconds), into a Duration and an Option A,B,C.
    [Test]
    procedure EndOfRangeDateTime_DurationOption()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FDP Probe";
    begin
        Probe.Cell(Observer, 5, CreateDateTime(99991231D, 235959T), 'duration');
        Probe.Cell(Observer, 5, CreateDateTime(99991231D, 235959T), 'option');
#if BC28PLUS
        Observer.Expect('duration', 'ok: P3652424DT23H59M59.001S');
        Observer.Expect('option', 'E: The value "12/31/9999 11:59 PM" can''t be evaluated into type Option. | Evaluate:Conversion');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;
}
