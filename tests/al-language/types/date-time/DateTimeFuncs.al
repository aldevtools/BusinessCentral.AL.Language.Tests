// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: CreateDateTime, DT2Date, DT2Time, RoundDateTime
// BC versions: 29 (27 and 28 by CI)

codeunit 73803 "LT DtT DateTimeFuncs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure R(DT: DateTime; Precision: BigInteger; Dir: Text): Text
    begin
        exit(Format(RoundDateTime(DT, Precision, Dir), 0, 9));
    end;

    [Test]
    procedure CreateDateTime_Variants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('normal', Format(CreateDateTime(20240115D, 123456.789T), 0, 9));
        Observer.Observe('date only 0T', Format(CreateDateTime(20240115D, 0T), 0, 9));
        Observer.Observe('date only midnight', Format(CreateDateTime(20240115D, 000000T), 0, 9));
        asserterror Observer.Observe('0D with time', Format(CreateDateTime(0D, 123456T), 0, 9));
        Observer.ObserveError('af26');
        Observer.Observe('0D 0T', Format(CreateDateTime(0D, 0T), 0, 9));
        Observer.Observe('0D 0T = 0DT', Format(CreateDateTime(0D, 0T) = 0DT));
        asserterror Observer.Observe('0D midnight', Format(CreateDateTime(0D, 000000T), 0, 9));
        Observer.ObserveError('af30');
        asserterror Observer.Observe('min', Format(CreateDateTime(00010101D, 000000T), 0, 9));
        Observer.ObserveError('af32');
        Observer.Observe('max', Format(CreateDateTime(99991231D, 235959.999T), 0, 9));
        Observer.Observe('max midnight', Format(CreateDateTime(99991231D, 000000T), 0, 9));
        Observer.Observe('ms precision', Format(CreateDateTime(20240115D, 000000.001T), 0, 9));
        Observer.Observe('0DT format 0', Format(0DT, 0, 0));
        Observer.Observe('0DT format 1', Format(0DT, 0, 1));
        Observer.Observe('0DT format 2', Format(0DT, 0, 2));
        Observer.Expect('normal', '2024-01-15T12:34:56.789Z');
        Observer.Expect('date only 0T', '2024-01-15T00:00:00Z');
        Observer.Expect('date only midnight', '2024-01-15T00:00:00Z');
        Observer.Expect('af26|text', 'The date is not valid.');
        Observer.Expect('af26|code', 'DateInvalid');
        Observer.Expect('0D 0T', '');
        Observer.Expect('0D 0T = 0DT', 'Yes');
        Observer.Expect('af30|text', 'The date is not valid.');
        Observer.Expect('af30|code', 'DateInvalid');
        Observer.Expect('af32|text', 'The date is not valid.');
        Observer.Expect('af32|code', 'DateInvalid');
        Observer.Expect('max', '9999-12-31T23:59:59.999Z');
        Observer.Expect('max midnight', '9999-12-31T00:00:00Z');
        Observer.Expect('ms precision', '2024-01-15T00:00:00.001Z');
        Observer.Expect('0DT format 0', '');
        Observer.Expect('0DT format 1', '');
        Observer.Expect('0DT format 2', '');
        Observer.Verify();
    end;

    [Test]
    procedure DT2Date_DT2Time()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240115D, 123456.789T);
        Observer.Observe('date', Format(DT2Date(DT), 0, 9));
        Observer.Observe('time', Format(DT2Time(DT), 0, 9));
        Observer.Observe('0DT date', Format(DT2Date(0DT), 0, 9));
        Observer.Observe('0DT time', Format(DT2Time(0DT), 0, 9));
        Observer.Observe('0DT date = 0D', Format(DT2Date(0DT) = 0D));
        Observer.Observe('0DT time = 0T', Format(DT2Time(0DT) = 0T));
        asserterror Observer.Observe('min date', Format(DT2Date(CreateDateTime(00010101D, 000000T)), 0, 9));
        Observer.ObserveError('af54');
        asserterror Observer.Observe('min time', Format(DT2Time(CreateDateTime(00010101D, 000000T)), 0, 9));
        Observer.ObserveError('af57');
        Observer.Observe('max date', Format(DT2Date(CreateDateTime(99991231D, 235959.999T)), 0, 9));
        Observer.Observe('max time', Format(DT2Time(CreateDateTime(99991231D, 235959.999T)), 0, 9));
        Observer.Observe('midnight time', Format(DT2Time(CreateDateTime(20240115D, 000000T)), 0, 9));
        Observer.Observe('midnight time = 0T', Format(DT2Time(CreateDateTime(20240115D, 000000T)) = 0T));
        asserterror Observer.Observe('0D with time date', Format(DT2Date(CreateDateTime(0D, 123456T)), 0, 9));
        Observer.ObserveError('af64');
        asserterror Observer.Observe('0D with time time', Format(DT2Time(CreateDateTime(0D, 123456T)), 0, 9));
        Observer.ObserveError('af66');
        Observer.Expect('date', '2024-01-15');
        Observer.Expect('time', '12:34:56.789');
        Observer.Expect('0DT date', '');
        Observer.Expect('0DT time', '');
        Observer.Expect('0DT date = 0D', 'Yes');
        Observer.Expect('0DT time = 0T', 'Yes');
        Observer.Expect('af54|text', 'The date is not valid.');
        Observer.Expect('af54|code', 'DateInvalid');
        Observer.Expect('af57|text', 'The date is not valid.');
        Observer.Expect('af57|code', 'DateInvalid');
        Observer.Expect('max date', '9999-12-31');
        Observer.Expect('max time', '23:59:59.999');
        Observer.Expect('midnight time', '00:00:00');
        Observer.Expect('midnight time = 0T', 'No');
        Observer.Expect('af64|text', 'The date is not valid.');
        Observer.Expect('af64|code', 'DateInvalid');
        Observer.Expect('af66|text', 'The date is not valid.');
        Observer.Expect('af66|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDateTime_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240115D, 123456.789T);
        Observer.Observe('default', Format(RoundDateTime(DT), 0, 9));
        Observer.Observe('precision only 60000', Format(RoundDateTime(DT, 60000), 0, 9));
        Observer.Observe('prec dir =', R(DT, 60000, '='));
        Observer.Observe('prec dir <', R(DT, 60000, '<'));
        Observer.Observe('prec dir >', R(DT, 60000, '>'));
        Observer.Observe('1000 =', R(DT, 1000, '='));
        Observer.Observe('1000 <', R(DT, 1000, '<'));
        Observer.Observe('1000 >', R(DT, 1000, '>'));
        Observer.Observe('3600000 =', R(DT, 3600000, '='));
        Observer.Observe('3600000 <', R(DT, 3600000, '<'));
        Observer.Observe('3600000 >', R(DT, 3600000, '>'));
        Observer.Observe('86400000 =', R(DT, 86400000, '='));
        Observer.Observe('86400000 <', R(DT, 86400000, '<'));
        Observer.Observe('86400000 >', R(DT, 86400000, '>'));
        Observer.Observe('1 =', R(DT, 1, '='));
        Observer.Observe('10 =', R(DT, 10, '='));
        Observer.Observe('100 >', R(DT, 100, '>'));
        Observer.Observe('7 =', R(DT, 7, '='));
        Observer.Observe('900000 =', R(DT, 900000, '='));
        Observer.Observe('300000 >', R(DT, 300000, '>'));
        Observer.Expect('default', '2024-01-15T12:34:57Z');
        Observer.Expect('precision only 60000', '2024-01-15T12:35:00Z');
        Observer.Expect('prec dir =', '2024-01-15T12:35:00Z');
        Observer.Expect('prec dir <', '2024-01-15T12:34:00Z');
        Observer.Expect('prec dir >', '2024-01-15T12:35:00Z');
        Observer.Expect('1000 =', '2024-01-15T12:34:57Z');
        Observer.Expect('1000 <', '2024-01-15T12:34:56Z');
        Observer.Expect('1000 >', '2024-01-15T12:34:57Z');
        Observer.Expect('3600000 =', '2024-01-15T13:00:00Z');
        Observer.Expect('3600000 <', '2024-01-15T12:00:00Z');
        Observer.Expect('3600000 >', '2024-01-15T13:00:00Z');
        Observer.Expect('86400000 =', '2024-01-16T00:00:00Z');
        Observer.Expect('86400000 <', '2024-01-15T00:00:00Z');
        Observer.Expect('86400000 >', '2024-01-16T00:00:00Z');
        Observer.Expect('1 =', '2024-01-15T12:34:56.789Z');
        Observer.Expect('10 =', '2024-01-15T12:34:56.79Z');
        Observer.Expect('100 >', '2024-01-15T12:34:56.8Z');
        Observer.Expect('7 =', '2024-01-15T12:34:56.788Z');
        Observer.Expect('900000 =', '2024-01-15T12:30:00Z');
        Observer.Expect('300000 >', '2024-01-15T12:35:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDateTime_Edges()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240115D, 123000T);
        Observer.Observe('exact =', R(DT, 60000, '='));
        Observer.Observe('exact <', R(DT, 60000, '<'));
        Observer.Observe('exact >', R(DT, 60000, '>'));
        DT := CreateDateTime(20240115D, 123030T);
        Observer.Observe('half =', R(DT, 60000, '='));
        DT := CreateDateTime(20240115D, 123029.999T);
        Observer.Observe('just below half =', R(DT, 60000, '='));
        DT := CreateDateTime(20240115D, 235959.999T);
        Observer.Observe('day end =', R(DT, 1000, '='));
        Observer.Observe('day end >', R(DT, 1000, '>'));
        Observer.Observe('day end 1h >', R(DT, 3600000, '>'));
        Observer.Observe('day end 1d >', R(DT, 86400000, '>'));
        Observer.Observe('0DT =', R(0DT, 1000, '='));
        Observer.Observe('0DT >', R(0DT, 1000, '>'));
        Observer.Observe('0DT <', R(0DT, 1000, '<'));
        asserterror DT := CreateDateTime(00010101D, 000000.500T);
        Observer.ObserveError('af118');
        Observer.Observe('min <', R(DT, 1000, '<'));
        Observer.Observe('min >', R(DT, 1000, '>'));
        Observer.Observe('min =', R(DT, 1000, '='));
        DT := CreateDateTime(99991231D, 235959.500T);
        asserterror Observer.Observe('max =', R(DT, 1000, '='));
        Observer.ObserveError('af126');
        asserterror Observer.Observe('max >', R(DT, 1000, '>'));
        Observer.ObserveError('af130');
        Observer.Expect('exact =', '2024-01-15T12:30:00Z');
        Observer.Expect('exact <', '2024-01-15T12:30:00Z');
        Observer.Expect('exact >', '2024-01-15T12:30:00Z');
        Observer.Expect('half =', '2024-01-15T12:31:00Z');
        Observer.Expect('just below half =', '2024-01-15T12:30:00Z');
        Observer.Expect('day end =', '2024-01-16T00:00:00Z');
        Observer.Expect('day end >', '2024-01-16T00:00:00Z');
        Observer.Expect('day end 1h >', '2024-01-16T00:00:00Z');
        Observer.Expect('day end 1d >', '2024-01-16T00:00:00Z');
        Observer.Expect('0DT =', '');
        Observer.Expect('0DT >', '');
        Observer.Expect('0DT <', '');
        Observer.Expect('af118|text', 'The date is not valid.');
        Observer.Expect('af118|code', 'DateInvalid');
        Observer.Expect('min <', '2024-01-15T23:59:59Z');
        Observer.Expect('min >', '2024-01-16T00:00:00Z');
        Observer.Expect('min =', '2024-01-16T00:00:00Z');
        Observer.Expect('af126|text', 'The date is not valid.');
        Observer.Expect('af126|code', 'DateInvalid');
        Observer.Expect('af130|text', 'The date is not valid.');
        Observer.Expect('af130|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDateTime_Errors()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
        Res: DateTime;
    begin
        DT := CreateDateTime(20240115D, 123456.789T);
        asserterror Res := RoundDateTime(DT, 0);
        Observer.ObserveError('precision 0');
        asserterror Res := RoundDateTime(DT, -1000);
        Observer.ObserveError('precision negative');
        asserterror Res := RoundDateTime(DT, 1000, 'x');
        Observer.ObserveError('direction x');
        asserterror Res := RoundDateTime(DT, 1000, '');
        Observer.ObserveError('direction empty');
        asserterror Res := RoundDateTime(DT, 1000, '<=');
        Observer.ObserveError('direction <=');
        asserterror Res := RoundDateTime(DT, 1000, '==');
        Observer.ObserveError('direction ==');
        asserterror Res := RoundDateTime(CreateDateTime(99991231D, 235959.999T), 86400000, '>');
        Observer.ObserveError('past max');
        Observer.Observe('precision huge', Format(RoundDateTime(DT, 9223372036854775807L), 0, 9));
        Observer.Expect('precision 0|text', 'The contents ''0'' of ROUNDDATETIME parameter number 2 are invalid.');
        Observer.Expect('precision 0|code', 'Argument');
        Observer.Expect('precision negative|text', 'The contents ''-1000'' of ROUNDDATETIME parameter number 2 are invalid.');
        Observer.Expect('precision negative|code', 'Argument');
        Observer.Expect('direction x|text', 'The contents ''x'' of ROUNDDATETIME parameter number 3 are invalid.');
        Observer.Expect('direction x|code', 'Argument');
        Observer.Expect('direction empty|text', 'The contents '''' of ROUNDDATETIME parameter number 3 are invalid.');
        Observer.Expect('direction empty|code', 'Argument');
        Observer.Expect('direction <=|text', 'The contents ''<='' of ROUNDDATETIME parameter number 3 are invalid.');
        Observer.Expect('direction <=|code', 'Argument');
        Observer.Expect('direction ==|text', 'The contents ''=='' of ROUNDDATETIME parameter number 3 are invalid.');
        Observer.Expect('direction ==|code', 'Argument');
        Observer.Expect('past max|text', 'The date is not valid.');
        Observer.Expect('past max|code', 'DateInvalid');
        Observer.Expect('precision huge', '0000-01-01T00:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Parts()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240115D, 123456.789T);
        Observer.Observe('date part', Format(DT2Date(DT), 0, 9));
        Observer.Observe('time hour', Format(DT2Time(DT), 0, '<Hours24,2>'));
        Observer.Observe('time minute', Format(DT2Time(DT), 0, '<Minutes,2>'));
        Observer.Observe('time second', Format(DT2Time(DT), 0, '<Seconds,2>'));
        Observer.Observe('time millis', Format(DT2Time(DT), 0, '<Thousands,3>'));
        Observer.Observe('Date2DMY from dt', Format(Date2DMY(DT2Date(DT), 3)));
        Observer.Observe('dt = recomposed', Format(DT = CreateDateTime(DT2Date(DT), DT2Time(DT))));
        Observer.Expect('date part', '2024-01-15');
        Observer.Expect('time hour', '12');
        Observer.Expect('time minute', '34');
        Observer.Expect('time second', '56');
        Observer.Expect('time millis', '789');
        Observer.Expect('Date2DMY from dt', '2024');
        Observer.Expect('dt = recomposed', 'Yes');
        Observer.Verify();
    end;
}
