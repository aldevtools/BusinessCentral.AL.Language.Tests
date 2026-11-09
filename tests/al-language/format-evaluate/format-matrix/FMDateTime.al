// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on Date, Time, DateTime and Duration. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72840 "LT FM Date Time"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryN(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    [TryFunction]
    local procedure TryS(V: Variant; S: Text; var R: Text)
    begin
        R := Format(V, 0, S);
    end;

    local procedure CellN(var O: Codeunit "Probe Observer"; Name: Text; V: Variant; N: Integer)
    var
        R: Text;
    begin
        ClearLastError();
        if TryN(V, N, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    local procedure CellS(var O: Codeunit "Probe Observer"; Name: Text; V: Variant; S: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryS(V, S, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDmy(D: Date; Part: Integer; var R: Integer)
    begin
        R := Date2DMY(D, Part);
    end;

    [TryFunction]
    local procedure TryDwy(D: Date; Part: Integer; var R: Integer)
    begin
        R := Date2DWY(D, Part);
    end;

    [TryFunction]
    local procedure TryDmy2Date(Day: Integer; Month: Integer; Year: Integer; var R: Date)
    begin
        R := DMY2Date(Day, Month, Year);
    end;

    local procedure DmyCell(var O: Codeunit "Probe Observer"; Name: Text; D: Date; Part: Integer)
    var
        R: Integer;
    begin
        ClearLastError();
        if TryDmy(D, Part, R) then
            O.Observe(Name, 'ok:' + Format(R))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure DwyCell(var O: Codeunit "Probe Observer"; Name: Text; D: Date; Part: Integer)
    var
        R: Integer;
    begin
        ClearLastError();
        if TryDwy(D, Part, R) then
            O.Observe(Name, 'ok:' + Format(R))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure Dmy2Cell(var O: Codeunit "Probe Observer"; Day: Integer; Month: Integer; Year: Integer)
    var
        R: Date;
    begin
        ClearLastError();
        if TryDmy2Date(Day, Month, Year, R) then
            O.Observe(StrSubstNo('%1/%2/%3', Day, Month, Year), 'ok:' + Format(R, 0, 9))
        else
            O.Observe(StrSubstNo('%1/%2/%3', Day, Month, Year), 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure Format_Date_0D_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:');
        O.Expect('n1', 'ok:');
        O.Expect('n2', 'ok:');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:');
        O.Expect('<Day,2>', 'ok:');
        O.Expect('<Day,2><Filler Character,0>', 'ok:');
        O.Expect('<Month>', 'ok:');
        O.Expect('<Month,2>', 'ok:');
        O.Expect('<Month Text>', 'ok:');
        O.Expect('<Month Text,3>', 'ok:');
        O.Expect('<Year>', 'ok:');
        O.Expect('<Year,2>', 'ok:');
        O.Expect('<Year4>', 'ok:');
        O.Expect('<Year4,4>', 'ok:');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:');
        O.Expect('<Weekday>', 'ok:');
        O.Expect('<Weekday Text>', 'ok:');
        O.Expect('<Weekday Text,3>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_0D_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:');
        O.Expect('<Week,2>', 'ok:');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:');
        O.Expect('<Standard Format,1>', 'ok:');
        O.Expect('<Standard Format,4>', 'ok:');
        O.Expect('<Standard Format,9>', 'ok:');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20260309D_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 20260309D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26');
        O.Expect('n1', 'ok:03/09/26');
        O.Expect('n2', 'ok:030926D');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:March');
        O.Expect('<Month Text,3>', 'ok:Mar');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:9');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Weekday Text>', 'ok:Monday');
        O.Expect('<Weekday Text,3>', 'ok:Mon');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20260309D_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 20260309D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:11');
        O.Expect('<Week,2>', 'ok:11');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:03/09/26');
        O.Expect('<Standard Format,1>', 'ok:03/09/26');
        O.Expect('<Standard Format,4>', 'ok:March 9, 2026');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:9.3.2026');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:09.03.26');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:9 March, 2026');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:March 9, 2026');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:9. 3. 2026');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:2026-03-09');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:Monday, 9 March 2026');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20240229D_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 20240229D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:02/29/24');
        O.Expect('n1', 'ok:02/29/24');
        O.Expect('n2', 'ok:022924D');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2024-02-29');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:29');
        O.Expect('<Day,2>', 'ok:29');
        O.Expect('<Day,2><Filler Character,0>', 'ok:29');
        O.Expect('<Month>', 'ok:2');
        O.Expect('<Month,2>', 'ok:02');
        O.Expect('<Month Text>', 'ok:February');
        O.Expect('<Month Text,3>', 'ok:Feb');
        O.Expect('<Year>', 'ok:24');
        O.Expect('<Year,2>', 'ok:24');
        O.Expect('<Year4>', 'ok:2024');
        O.Expect('<Year4,4>', 'ok:2024');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:29');
        O.Expect('<Weekday>', 'ok:4');
        O.Expect('<Weekday Text>', 'ok:Thursday');
        O.Expect('<Weekday Text,3>', 'ok:Thu');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20240229D_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 20240229D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:9');
        O.Expect('<Week,2>', 'ok:09');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:02/29/24');
        O.Expect('<Standard Format,1>', 'ok:02/29/24');
        O.Expect('<Standard Format,4>', 'ok:February 29, 2024');
        O.Expect('<Standard Format,9>', 'ok:2024-02-29');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:2/29/2024');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:29.2.2024');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:29.02.24');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:29 February, 2024');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:February 29, 2024');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:29. 2. 2024');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:2024-02-29');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:Thursday, 29 February 2024');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20261231D_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 20261231D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12/31/26');
        O.Expect('n1', 'ok:12/31/26');
        O.Expect('n2', 'ok:123126D');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-12-31');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:31');
        O.Expect('<Day,2>', 'ok:31');
        O.Expect('<Day,2><Filler Character,0>', 'ok:31');
        O.Expect('<Month>', 'ok:12');
        O.Expect('<Month,2>', 'ok:12');
        O.Expect('<Month Text>', 'ok:December');
        O.Expect('<Month Text,3>', 'ok:Dec');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:31');
        O.Expect('<Weekday>', 'ok:4');
        O.Expect('<Weekday Text>', 'ok:Thursday');
        O.Expect('<Weekday Text,3>', 'ok:Thu');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20261231D_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 20261231D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:53');
        O.Expect('<Week,2>', 'ok:53');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:12/31/26');
        O.Expect('<Standard Format,1>', 'ok:12/31/26');
        O.Expect('<Standard Format,4>', 'ok:December 31, 2026');
        O.Expect('<Standard Format,9>', 'ok:2026-12-31');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:12/31/2026');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:31.12.2026');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:31.12.26');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:31 December, 2026');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:December 31, 2026');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:31. 12. 2026');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:2026-12-31');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:Thursday, 31 December 2026');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_17530101D_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 17530101D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:01/01/1753');
        O.Expect('n1', 'ok:01/01/1753');
        O.Expect('n2', 'ok:01011753D');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:1753-01-01');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:1');
        O.Expect('<Day,2>', 'ok:01');
        O.Expect('<Day,2><Filler Character,0>', 'ok:01');
        O.Expect('<Month>', 'ok:1');
        O.Expect('<Month,2>', 'ok:01');
        O.Expect('<Month Text>', 'ok:January');
        O.Expect('<Month Text,3>', 'ok:Jan');
        O.Expect('<Year>', 'ok:1753');
        O.Expect('<Year,2>', 'ok:**');
        O.Expect('<Year4>', 'ok:1753');
        O.Expect('<Year4,4>', 'ok:1753');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:1');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Weekday Text>', 'ok:Monday');
        O.Expect('<Weekday Text,3>', 'ok:Mon');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_17530101D_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 17530101D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:1');
        O.Expect('<Week,2>', 'ok:01');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:01/01/1753');
        O.Expect('<Standard Format,1>', 'ok:01/01/1753');
        O.Expect('<Standard Format,4>', 'ok:January 1, 1753');
        O.Expect('<Standard Format,9>', 'ok:1753-01-01');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:1/1/1753');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:1.1.1753');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:01.01.**');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:1 January, 1753');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:January 1, 1753');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:1. 1. 1753');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:1753-01-01');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:Monday, 1 January 1753');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_99991231D_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 99991231D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12/31/9999');
        O.Expect('n1', 'ok:12/31/9999');
        O.Expect('n2', 'ok:12319999D');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:9999-12-31');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:31');
        O.Expect('<Day,2>', 'ok:31');
        O.Expect('<Day,2><Filler Character,0>', 'ok:31');
        O.Expect('<Month>', 'ok:12');
        O.Expect('<Month,2>', 'ok:12');
        O.Expect('<Month Text>', 'ok:December');
        O.Expect('<Month Text,3>', 'ok:Dec');
        O.Expect('<Year>', 'ok:9999');
        O.Expect('<Year,2>', 'ok:**');
        O.Expect('<Year4>', 'ok:9999');
        O.Expect('<Year4,4>', 'ok:9999');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:31');
        O.Expect('<Weekday>', 'ok:5');
        O.Expect('<Weekday Text>', 'ok:Friday');
        O.Expect('<Weekday Text,3>', 'ok:Fri');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_99991231D_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 99991231D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:52');
        O.Expect('<Week,2>', 'ok:52');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:12/31/9999');
        O.Expect('<Standard Format,1>', 'ok:12/31/9999');
        O.Expect('<Standard Format,4>', 'ok:December 31, 9999');
        O.Expect('<Standard Format,9>', 'ok:9999-12-31');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:12/31/9999');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:31.12.9999');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:31.12.**');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:31 December, 9999');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:December 31, 9999');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:31. 12. 9999');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:9999-12-31');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:Friday, 31 December 9999');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20260309D_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 20260309D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26');
        O.Expect('n1', 'ok:03/09/26');
        O.Expect('n2', 'ok:030926D');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:März');
        O.Expect('<Month Text,3>', 'ok:Mär');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:9');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Weekday Text>', 'ok:Montag');
        O.Expect('<Weekday Text,3>', 'ok:Mon');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_20260309D_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 20260309D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:11');
        O.Expect('<Week,2>', 'ok:11');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:03/09/26');
        O.Expect('<Standard Format,1>', 'ok:03/09/26');
        O.Expect('<Standard Format,4>', 'ok:März 9, 2026');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:9.3.2026');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:09.03.26');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:9 März, 2026');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:März 9, 2026');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:9. 3. 2026');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:2026-03-09');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:Montag, 9 März 2026');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_0D_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 0D;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Weekday Text>', V, '<Weekday Text>');
        CellS(O, '<Weekday Text,3>', V, '<Weekday Text,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:');
        O.Expect('n1', 'ok:');
        O.Expect('n2', 'ok:');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:');
        O.Expect('<Day,2>', 'ok:');
        O.Expect('<Day,2><Filler Character,0>', 'ok:');
        O.Expect('<Month>', 'ok:');
        O.Expect('<Month,2>', 'ok:');
        O.Expect('<Month Text>', 'ok:');
        O.Expect('<Month Text,3>', 'ok:');
        O.Expect('<Year>', 'ok:');
        O.Expect('<Year,2>', 'ok:');
        O.Expect('<Year4>', 'ok:');
        O.Expect('<Year4,4>', 'ok:');
        O.Expect('<Closing>', 'ok:');
        O.Expect('<Closing><Day>', 'ok:');
        O.Expect('<Weekday>', 'ok:');
        O.Expect('<Weekday Text>', 'ok:');
        O.Expect('<Weekday Text,3>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Date_0D_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 0D;
        CellS(O, '<Week>', V, '<Week>');
        CellS(O, '<Week,2>', V, '<Week,2>');
        CellS(O, '<Day Text>', V, '<Day Text>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Day>.<Month>.<Year4>', V, '<Day>.<Month>.<Year4>');
        CellS(O, '<Day,2>.<Month,2>.<Year,2>', V, '<Day,2>.<Month,2>.<Year,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Month Text> <Closing><Day>, <Year4>', V, '<Month Text> <Closing><Day>, <Year4>');
        CellS(O, '<Day>. <Month>. <Year4>', V, '<Day>. <Month>. <Year4>');
        CellS(O, '<Year4>-<Month,2>-<Day,2>', V, '<Year4>-<Month,2>-<Day,2>');
        CellS(O, '<Weekday Text>, <Day> <Month Text> <Year4>', V, '<Weekday Text>, <Day> <Month Text> <Year4>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Week>', 'ok:');
        O.Expect('<Week,2>', 'ok:');
        O.Expect('<Day Text>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:');
        O.Expect('<Standard Format,1>', 'ok:');
        O.Expect('<Standard Format,4>', 'ok:');
        O.Expect('<Standard Format,9>', 'ok:');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:');
        O.Expect('<Day>.<Month>.<Year4>', 'ok:');
        O.Expect('<Day,2>.<Month,2>.<Year,2>', 'ok:');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'ok:');
        O.Expect('<Month Text> <Closing><Day>, <Year4>', 'ok:');
        O.Expect('<Day>. <Month>. <Year4>', 'ok:');
        O.Expect('<Year4>-<Month,2>-<Day,2>', 'ok:');
        O.Expect('<Weekday Text>, <Day> <Month Text> <Year4>', 'ok:');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_0T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:');
        O.Expect('n1', 'ok:');
        O.Expect('n2', 'ok:');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:0');
        O.Expect('<Hours24,2>', 'ok: 0');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:00');
        O.Expect('<Hours12>', 'ok:12');
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes>', 'ok:0');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds>', 'ok:0');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Thousands,3>', 'ok:  0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<Second dec.,2>', 'ok:00');
        O.Expect('<AM/PM>', 'ok:AM');
        O.Expect('<AM/PM,1>', 'ok:A');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_0T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok: 0:00:00');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok: 0:00:00.  0');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok:12:00 AM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:12:00AM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:12:00:00 AM');
        O.Expect('<Hour,2>', 'ok: 0');
        O.Expect('<Hour>', 'ok:0');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:12:00:00 AM');
        O.Expect('<Standard Format,1>', 'ok:12:00:00 AM');
        O.Expect('<Standard Format,2>', 'ok:000000T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:00:00:00');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_123456T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 123456T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12:34:56 PM');
        O.Expect('n1', 'ok:12:34:56 PM');
        O.Expect('n2', 'ok:123456T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:12:34:56');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:12');
        O.Expect('<Hours24,2>', 'ok:12');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:12');
        O.Expect('<Hours12>', 'ok:12');
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes>', 'ok:34');
        O.Expect('<Minutes,2>', 'ok:34');
        O.Expect('<Seconds>', 'ok:56');
        O.Expect('<Seconds,2>', 'ok:56');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Thousands,3>', 'ok:  0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<Second dec.,2>', 'ok:00');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<AM/PM,1>', 'ok:P');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_123456T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 123456T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:12:34:56');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:12:34:56.  0');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok:12:34 PM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:12:34PM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:12:34:56 PM');
        O.Expect('<Hour,2>', 'ok:12');
        O.Expect('<Hour>', 'ok:12');
        O.Expect('<Minute,2>', 'ok:34');
        O.Expect('<Second,2>', 'ok:56');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:12:34:56 PM');
        O.Expect('<Standard Format,1>', 'ok:12:34:56 PM');
        O.Expect('<Standard Format,2>', 'ok:123456T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:12:34:56');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_235959_999T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 235959.999T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:11:59:59 PM');
        O.Expect('n1', 'ok:11:59:59.999 PM');
        O.Expect('n2', 'ok:235959.999T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:23:59:59.999');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:23');
        O.Expect('<Hours24,2>', 'ok:23');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:23');
        O.Expect('<Hours12>', 'ok:11');
        O.Expect('<Hours12,2>', 'ok:11');
        O.Expect('<Minutes>', 'ok:59');
        O.Expect('<Minutes,2>', 'ok:59');
        O.Expect('<Seconds>', 'ok:59');
        O.Expect('<Seconds,2>', 'ok:59');
        O.Expect('<Thousands>', 'ok:999');
        O.Expect('<Thousands,3>', 'ok:999');
        O.Expect('<Second dec.>', 'ok:.999');
        O.Expect('<Second dec.,2>', 'ok:**');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<AM/PM,1>', 'ok:P');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_235959_999T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 235959.999T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:23:59:59');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:23:59:59.999');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok:11:59 PM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:11:59PM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:11:59:59 PM');
        O.Expect('<Hour,2>', 'ok:23');
        O.Expect('<Hour>', 'ok:23');
        O.Expect('<Minute,2>', 'ok:59');
        O.Expect('<Second,2>', 'ok:59');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:11:59:59 PM');
        O.Expect('<Standard Format,1>', 'ok:11:59:59.999 PM');
        O.Expect('<Standard Format,2>', 'ok:235959.999T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:23:59:59.999');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_120000T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 120000T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12:00:00 PM');
        O.Expect('n1', 'ok:12:00:00 PM');
        O.Expect('n2', 'ok:120000T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:12:00:00');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:12');
        O.Expect('<Hours24,2>', 'ok:12');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:12');
        O.Expect('<Hours12>', 'ok:12');
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes>', 'ok:0');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds>', 'ok:0');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Thousands,3>', 'ok:  0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<Second dec.,2>', 'ok:00');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<AM/PM,1>', 'ok:P');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_120000T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 120000T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:12:00:00');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:12:00:00.  0');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok:12:00 PM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:12:00PM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:12:00:00 PM');
        O.Expect('<Hour,2>', 'ok:12');
        O.Expect('<Hour>', 'ok:12');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:12:00:00 PM');
        O.Expect('<Standard Format,1>', 'ok:12:00:00 PM');
        O.Expect('<Standard Format,2>', 'ok:120000T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:12:00:00');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_000000_001T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 000000.001T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12:00:00 AM');
        O.Expect('n1', 'ok:12:00:00.001 AM');
        O.Expect('n2', 'ok:000000.001T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:00:00:00.001');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:0');
        O.Expect('<Hours24,2>', 'ok: 0');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:00');
        O.Expect('<Hours12>', 'ok:12');
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes>', 'ok:0');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds>', 'ok:0');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:1');
        O.Expect('<Thousands,3>', 'ok:  1');
        O.Expect('<Second dec.>', 'ok:.001');
        O.Expect('<Second dec.,2>', 'ok:**');
        O.Expect('<AM/PM>', 'ok:AM');
        O.Expect('<AM/PM,1>', 'ok:A');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_000000_001T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 000000.001T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok: 0:00:00');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok: 0:00:00.  1');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok:12:00 AM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:12:00AM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:12:00:00 AM');
        O.Expect('<Hour,2>', 'ok: 0');
        O.Expect('<Hour>', 'ok:0');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:12:00:00 AM');
        O.Expect('<Standard Format,1>', 'ok:12:00:00.001 AM');
        O.Expect('<Standard Format,2>', 'ok:000000.001T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:00:00:00.001');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_130000T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 130000T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok: 1:00:00 PM');
        O.Expect('n1', 'ok: 1:00:00 PM');
        O.Expect('n2', 'ok:130000T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:13:00:00');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:13');
        O.Expect('<Hours24,2>', 'ok:13');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:13');
        O.Expect('<Hours12>', 'ok:1');
        O.Expect('<Hours12,2>', 'ok: 1');
        O.Expect('<Minutes>', 'ok:0');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds>', 'ok:0');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Thousands,3>', 'ok:  0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<Second dec.,2>', 'ok:00');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<AM/PM,1>', 'ok:P');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_130000T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 130000T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:13:00:00');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:13:00:00.  0');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok: 1:00 PM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:1:00PM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok: 1:00:00 PM');
        O.Expect('<Hour,2>', 'ok:13');
        O.Expect('<Hour>', 'ok:13');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok: 1:00:00 PM');
        O.Expect('<Standard Format,1>', 'ok: 1:00:00 PM');
        O.Expect('<Standard Format,2>', 'ok:130000T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:13:00:00');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_000500T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 000500T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12:05:00 AM');
        O.Expect('n1', 'ok:12:05:00 AM');
        O.Expect('n2', 'ok:000500T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:00:05:00');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:0');
        O.Expect('<Hours24,2>', 'ok: 0');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:00');
        O.Expect('<Hours12>', 'ok:12');
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes>', 'ok:5');
        O.Expect('<Minutes,2>', 'ok:05');
        O.Expect('<Seconds>', 'ok:0');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Thousands,3>', 'ok:  0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<Second dec.,2>', 'ok:00');
        O.Expect('<AM/PM>', 'ok:AM');
        O.Expect('<AM/PM,1>', 'ok:A');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_000500T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 000500T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok: 0:05:00');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok: 0:05:00.  0');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok:12:05 AM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:12:05AM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:12:05:00 AM');
        O.Expect('<Hour,2>', 'ok: 0');
        O.Expect('<Hour>', 'ok:0');
        O.Expect('<Minute,2>', 'ok:05');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:12:05:00 AM');
        O.Expect('<Standard Format,1>', 'ok:12:05:00 AM');
        O.Expect('<Standard Format,2>', 'ok:000500T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:00:05:00');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_130456_789T_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 130456.789T;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Hours24,2>', V, '<Hours24,2>');
        CellS(O, '<Hours24,2><Filler Character,0>', V, '<Hours24,2><Filler Character,0>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Thousands,3>', V, '<Thousands,3>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<Second dec.,2>', V, '<Second dec.,2>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<AM/PM,1>', V, '<AM/PM,1>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok: 1:04:56 PM');
        O.Expect('n1', 'ok: 1:04:56.789 PM');
        O.Expect('n2', 'ok:130456.789T');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:13:04:56.789');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Hours24>', 'ok:13');
        O.Expect('<Hours24,2>', 'ok:13');
        O.Expect('<Hours24,2><Filler Character,0>', 'ok:13');
        O.Expect('<Hours12>', 'ok:1');
        O.Expect('<Hours12,2>', 'ok: 1');
        O.Expect('<Minutes>', 'ok:4');
        O.Expect('<Minutes,2>', 'ok:04');
        O.Expect('<Seconds>', 'ok:56');
        O.Expect('<Seconds,2>', 'ok:56');
        O.Expect('<Thousands>', 'ok:789');
        O.Expect('<Thousands,3>', 'ok:789');
        O.Expect('<Second dec.>', 'ok:.789');
        O.Expect('<Second dec.,2>', 'ok:**');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<AM/PM,1>', 'ok:P');
        O.Verify();
    end;

    [Test]
    procedure Format_Time_130456_789T_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Time;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 130456.789T;
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Hours12,2>:<Minutes,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2> <AM/PM>');
        CellS(O, '<Hours12>:<Minutes,2><AM/PM>', V, '<Hours12>:<Minutes,2><AM/PM>');
        CellS(O, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Comma,.>', V, '<Comma,.>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:13:04:56');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:13:04:56.789');
        O.Expect('<Hours12,2>:<Minutes,2> <AM/PM>', 'ok: 1:04 PM');
        O.Expect('<Hours12>:<Minutes,2><AM/PM>', 'ok:1:04PM');
        O.Expect('<Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok: 1:04:56 PM');
        O.Expect('<Hour,2>', 'ok:13');
        O.Expect('<Hour>', 'ok:13');
        O.Expect('<Minute,2>', 'ok:04');
        O.Expect('<Second,2>', 'ok:56');
        O.Expect('<Comma,.>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok: 1:04:56 PM');
        O.Expect('<Standard Format,1>', 'ok: 1:04:56.789 PM');
        O.Expect('<Standard Format,2>', 'ok:130456.789T');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:13:04:56.789');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_0DT_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0DT;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:');
        O.Expect('n1', 'ok:');
        O.Expect('n2', 'ok:');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:');
        O.Expect('<Day,2>', 'ok:');
        O.Expect('<Day,2><Filler Character,0>', 'ok:');
        O.Expect('<Month>', 'ok:');
        O.Expect('<Month,2>', 'ok:');
        O.Expect('<Month Text>', 'ok:');
        O.Expect('<Month Text,3>', 'ok:');
        O.Expect('<Year>', 'ok:');
        O.Expect('<Year,2>', 'ok:');
        O.Expect('<Year4>', 'ok:');
        O.Expect('<Year4,4>', 'ok:');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:');
        O.Expect('<Hours12>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_0DT_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0DT;
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:');
        O.Expect('<Minutes,2>', 'ok:');
        O.Expect('<Seconds,2>', 'ok:');
        O.Expect('<Thousands>', 'ok:');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<AM/PM>', 'ok:');
        O.Expect('<Hour,2>', 'ok:');
        O.Expect('<Hour>', 'ok:');
        O.Expect('<Minute,2>', 'ok:');
        O.Expect('<Second,2>', 'ok:');
        O.Expect('<Standard Format,0>', 'ok:');
        O.Expect('<Standard Format,1>', 'ok:');
        O.Expect('<Standard Format,2>', 'ok:');
        O.Expect('<Standard Format,3>', 'ok:');
        O.Expect('<Standard Format,4>', 'ok:');
        O.Expect('<Standard Format,9>', 'ok:');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_0DT_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0DT;
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_134512_123T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 134512.123T);
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26 01:45 PM');
        O.Expect('n1', 'ok:03/09/26 01:45:12.123 PM');
        O.Expect('n2', 'ok:03/09/26 01:45 PM');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09T13:45:12.123Z');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:March');
        O.Expect('<Month Text,3>', 'ok:Mar');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:13:45:12');
        O.Expect('<Hours12>', 'ok:1');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_134512_123T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 134512.123T);
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:01');
        O.Expect('<Minutes,2>', 'ok:45');
        O.Expect('<Seconds,2>', 'ok:12');
        O.Expect('<Thousands>', 'ok:123');
        O.Expect('<Second dec.>', 'ok:.123');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<Hour,2>', 'ok:13');
        O.Expect('<Hour>', 'ok:13');
        O.Expect('<Minute,2>', 'ok:45');
        O.Expect('<Second,2>', 'ok:12');
        O.Expect('<Standard Format,0>', 'ok:03/09/26 01:45 PM');
        O.Expect('<Standard Format,1>', 'ok:03/09/26 01:45:12.123 PM');
        O.Expect('<Standard Format,2>', 'ok:03/09/26 01:45 PM');
        O.Expect('<Standard Format,3>', 'ok:03/09/26 01:45:12 PM');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09T13:45:12.123Z');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:2026/03/09 13:45:12 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:2026/03/09 01:45:12 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:2026/03/09 13:45:12');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_134512_123T_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 134512.123T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:2026-03-09T13:45:12.123');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:9. March 2026 13:45');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_000000T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 000000T);
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26 12:00 AM');
        O.Expect('n1', 'ok:03/09/26 12:00:00 AM');
        O.Expect('n2', 'ok:03/09/26 12:00 AM');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09T00:00:00Z');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:March');
        O.Expect('<Month Text,3>', 'ok:Mar');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:00:00:00');
        O.Expect('<Hours12>', 'ok:12');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_000000T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 000000T);
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<AM/PM>', 'ok:AM');
        O.Expect('<Hour,2>', 'ok:00');
        O.Expect('<Hour>', 'ok:0');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Standard Format,0>', 'ok:03/09/26 12:00 AM');
        O.Expect('<Standard Format,1>', 'ok:03/09/26 12:00:00 AM');
        O.Expect('<Standard Format,2>', 'ok:03/09/26 12:00 AM');
        O.Expect('<Standard Format,3>', 'ok:03/09/26 12:00:00 AM');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09T00:00:00Z');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:2026/03/09 00:00:00 AM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:2026/03/09 12:00:00 AM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:2026/03/09 00:00:00');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_000000T_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 000000T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:2026-03-09T00:00:00.000');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:9. March 2026 00:00');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20261231D_235959_999T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20261231D, 235959.999T);
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:12/31/26 11:59 PM');
        O.Expect('n1', 'ok:12/31/26 11:59:59.999 PM');
        O.Expect('n2', 'ok:12/31/26 11:59 PM');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-12-31T23:59:59.999Z');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:31');
        O.Expect('<Day,2>', 'ok:31');
        O.Expect('<Day,2><Filler Character,0>', 'ok:31');
        O.Expect('<Month>', 'ok:12');
        O.Expect('<Month,2>', 'ok:12');
        O.Expect('<Month Text>', 'ok:December');
        O.Expect('<Month Text,3>', 'ok:Dec');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:4');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:23:59:59');
        O.Expect('<Hours12>', 'ok:11');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20261231D_235959_999T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20261231D, 235959.999T);
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:11');
        O.Expect('<Minutes,2>', 'ok:59');
        O.Expect('<Seconds,2>', 'ok:59');
        O.Expect('<Thousands>', 'ok:999');
        O.Expect('<Second dec.>', 'ok:.999');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<Hour,2>', 'ok:23');
        O.Expect('<Hour>', 'ok:23');
        O.Expect('<Minute,2>', 'ok:59');
        O.Expect('<Second,2>', 'ok:59');
        O.Expect('<Standard Format,0>', 'ok:12/31/26 11:59 PM');
        O.Expect('<Standard Format,1>', 'ok:12/31/26 11:59:59.999 PM');
        O.Expect('<Standard Format,2>', 'ok:12/31/26 11:59 PM');
        O.Expect('<Standard Format,3>', 'ok:12/31/26 11:59:59 PM');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:2026-12-31T23:59:59.999Z');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:12/31/2026');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:2026/12/31 23:59:59 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:2026/12/31 11:59:59 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:2026/12/31 23:59:59');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20261231D_235959_999T_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20261231D, 235959.999T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:2026-12-31T23:59:59.999');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:31. December 2026 23:59');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_120000T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 120000T);
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26 12:00 PM');
        O.Expect('n1', 'ok:03/09/26 12:00:00 PM');
        O.Expect('n2', 'ok:03/09/26 12:00 PM');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09T12:00:00Z');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:March');
        O.Expect('<Month Text,3>', 'ok:Mar');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:12:00:00');
        O.Expect('<Hours12>', 'ok:12');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_120000T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 120000T);
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<Hour,2>', 'ok:12');
        O.Expect('<Hour>', 'ok:12');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Standard Format,0>', 'ok:03/09/26 12:00 PM');
        O.Expect('<Standard Format,1>', 'ok:03/09/26 12:00:00 PM');
        O.Expect('<Standard Format,2>', 'ok:03/09/26 12:00 PM');
        O.Expect('<Standard Format,3>', 'ok:03/09/26 12:00:00 PM');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09T12:00:00Z');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:2026/03/09 12:00:00 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:2026/03/09 12:00:00 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:2026/03/09 12:00:00');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_120000T_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 120000T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:2026-03-09T12:00:00.000');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:9. March 2026 12:00');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_0T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 0T);
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26 12:00 AM');
        O.Expect('n1', 'ok:03/09/26 12:00:00 AM');
        O.Expect('n2', 'ok:03/09/26 12:00 AM');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09T00:00:00Z');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:March');
        O.Expect('<Month Text,3>', 'ok:Mar');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:00:00:00');
        O.Expect('<Hours12>', 'ok:12');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_0T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 0T);
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:12');
        O.Expect('<Minutes,2>', 'ok:00');
        O.Expect('<Seconds,2>', 'ok:00');
        O.Expect('<Thousands>', 'ok:0');
        O.Expect('<Second dec.>', 'ok:');
        O.Expect('<AM/PM>', 'ok:AM');
        O.Expect('<Hour,2>', 'ok:00');
        O.Expect('<Hour>', 'ok:0');
        O.Expect('<Minute,2>', 'ok:00');
        O.Expect('<Second,2>', 'ok:00');
        O.Expect('<Standard Format,0>', 'ok:03/09/26 12:00 AM');
        O.Expect('<Standard Format,1>', 'ok:03/09/26 12:00:00 AM');
        O.Expect('<Standard Format,2>', 'ok:03/09/26 12:00 AM');
        O.Expect('<Standard Format,3>', 'ok:03/09/26 12:00:00 AM');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09T00:00:00Z');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:2026/03/09 00:00:00 AM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:2026/03/09 12:00:00 AM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:2026/03/09 00:00:00');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_0T_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(20260309D, 0T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:2026-03-09T00:00:00.000');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:9. March 2026 00:00');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure CreateDateTime_0D_WithTime_Raises()
    var
        O: Codeunit "Probe Observer";
        V: DateTime;
    begin
        // CreateDateTime(0D, a time other than 0T) raises "The date is not valid." on BC 27.5, 28.5 and 29.0
        // (CI subset runs 42636879122, 42636918830, 42636961473), so no Format cell exists for that DateTime.
        asserterror V := CreateDateTime(0D, 123456T);
        O.Observe('create_0D_123456T', GetLastErrorText());
        O.Expect('create_0D_123456T', 'The date is not valid.');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_134512_123T_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := CreateDateTime(20260309D, 134512.123T);
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Day,2>', V, '<Day,2>');
        CellS(O, '<Day,2><Filler Character,0>', V, '<Day,2><Filler Character,0>');
        CellS(O, '<Month>', V, '<Month>');
        CellS(O, '<Month,2>', V, '<Month,2>');
        CellS(O, '<Month Text>', V, '<Month Text>');
        CellS(O, '<Month Text,3>', V, '<Month Text,3>');
        CellS(O, '<Year>', V, '<Year>');
        CellS(O, '<Year,2>', V, '<Year,2>');
        CellS(O, '<Year4>', V, '<Year4>');
        CellS(O, '<Year4,4>', V, '<Year4,4>');
        CellS(O, '<Closing>', V, '<Closing>');
        CellS(O, '<Closing><Day>', V, '<Closing><Day>');
        CellS(O, '<Weekday>', V, '<Weekday>');
        CellS(O, '<Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        CellS(O, '<Hours12>', V, '<Hours12>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:03/09/26 01:45 PM');
        O.Expect('n1', 'ok:03/09/26 01:45:12.123 PM');
        O.Expect('n2', 'ok:03/09/26 01:45 PM');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:2026-03-09T13:45:12.123Z');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Day>', 'ok:9');
        O.Expect('<Day,2>', 'ok:09');
        O.Expect('<Day,2><Filler Character,0>', 'ok:09');
        O.Expect('<Month>', 'ok:3');
        O.Expect('<Month,2>', 'ok:03');
        O.Expect('<Month Text>', 'ok:März');
        O.Expect('<Month Text,3>', 'ok:Mär');
        O.Expect('<Year>', 'ok:26');
        O.Expect('<Year,2>', 'ok:26');
        O.Expect('<Year4>', 'ok:2026');
        O.Expect('<Year4,4>', 'ok:2026');
        O.Expect('<Closing>', 'err:InvalidFormatString');
        O.Expect('<Closing><Day>', 'err:InvalidFormatString');
        O.Expect('<Weekday>', 'ok:1');
        O.Expect('<Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:13:45:12');
        O.Expect('<Hours12>', 'ok:1');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_134512_123T_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := CreateDateTime(20260309D, 134512.123T);
        CellS(O, '<Hours12,2>', V, '<Hours12,2>');
        CellS(O, '<Minutes,2>', V, '<Minutes,2>');
        CellS(O, '<Seconds,2>', V, '<Seconds,2>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Second dec.>', V, '<Second dec.>');
        CellS(O, '<AM/PM>', V, '<AM/PM>');
        CellS(O, '<Hour,2>', V, '<Hour,2>');
        CellS(O, '<Hour>', V, '<Hour>');
        CellS(O, '<Minute,2>', V, '<Minute,2>');
        CellS(O, '<Second,2>', V, '<Second,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Month>/<Day>/<Year4>', V, '<Month>/<Day>/<Year4>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', V, '<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>');
        CellS(O, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', V, '<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
        GlobalLanguage(Saved);
        O.Expect('<Hours12,2>', 'ok:01');
        O.Expect('<Minutes,2>', 'ok:45');
        O.Expect('<Seconds,2>', 'ok:12');
        O.Expect('<Thousands>', 'ok:123');
        O.Expect('<Second dec.>', 'ok:.123');
        O.Expect('<AM/PM>', 'ok:PM');
        O.Expect('<Hour,2>', 'ok:13');
        O.Expect('<Hour>', 'ok:13');
        O.Expect('<Minute,2>', 'ok:45');
        O.Expect('<Second,2>', 'ok:12');
        O.Expect('<Standard Format,0>', 'ok:03/09/26 01:45 PM');
        O.Expect('<Standard Format,1>', 'ok:03/09/26 01:45:12.123 PM');
        O.Expect('<Standard Format,2>', 'ok:03/09/26 01:45 PM');
        O.Expect('<Standard Format,3>', 'ok:03/09/26 01:45:12 PM');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:2026-03-09T13:45:12.123Z');
        O.Expect('<Month>/<Day>/<Year4>', 'ok:3/9/2026');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hour,2>:<Minute,2>:<Second,2> <AM/PM>', 'ok:2026/03/09 13:45:12 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours12,2>:<Minutes,2>:<Seconds,2> <AM/PM>', 'ok:2026/03/09 01:45:12 PM');
        O.Expect('<Year4>/<Month,2>/<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>', 'ok:2026/03/09 13:45:12');
        O.Verify();
    end;

    [Test]
    procedure Format_DateTime_20260309D_134512_123T_de_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := CreateDateTime(20260309D, 134512.123T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', 'ok:2026-03-09T13:45:12.123');
        O.Expect('<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', 'ok:9. März 2026 13:45');
        O.Expect('<Closing><Day> <Month Text>, <Year4>', 'err:InvalidFormatString');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_0_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:');
        O.Expect('n1', 'ok:');
        O.Expect('n2', 'ok:');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P0DT0H0M0.0S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:');
        O.Expect('<Standard Format,1>', 'ok:');
        O.Expect('<Standard Format,2>', 'ok:');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_0_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P0DT0H0M0.0S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_1_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 millisecond');
        O.Expect('n1', 'ok:1 millisecond');
        O.Expect('n2', 'ok:1 8');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P0DT0H0M0.001S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 millisecond');
        O.Expect('<Standard Format,1>', 'ok:1 millisecond');
        O.Expect('<Standard Format,2>', 'ok:1 8');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_1_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P0DT0H0M0.001S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_neg1_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:-1 millisecond');
        O.Expect('n1', 'ok:-1 millisecond');
        O.Expect('n2', 'ok:-1 8');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:-P0DT0H0M0.001S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:-1 millisecond');
        O.Expect('<Standard Format,1>', 'ok:-1 millisecond');
        O.Expect('<Standard Format,2>', 'ok:-1 8');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_neg1_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:-P0DT0H0M0.001S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_1000_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1000;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 second');
        O.Expect('n1', 'ok:1 second');
        O.Expect('n2', 'ok:1 6');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P0DT0H0M1.0S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 second');
        O.Expect('<Standard Format,1>', 'ok:1 second');
        O.Expect('<Standard Format,2>', 'ok:1 6');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_1000_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1000;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P0DT0H0M1.0S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_60000_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 60000;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 minute');
        O.Expect('n1', 'ok:1 minute');
        O.Expect('n2', 'ok:1 4');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P0DT0H1M0.0S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 minute');
        O.Expect('<Standard Format,1>', 'ok:1 minute');
        O.Expect('<Standard Format,2>', 'ok:1 4');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_60000_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 60000;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P0DT0H1M0.0S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_3723000_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 3723000;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 hour 2 minutes 3 seconds');
        O.Expect('n1', 'ok:1 hour 2 minutes 3 seconds');
        O.Expect('n2', 'ok:1 2 2 5 3 7');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P0DT1H2M3.0S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 hour 2 minutes 3 seconds');
        O.Expect('<Standard Format,1>', 'ok:1 hour 2 minutes 3 seconds');
        O.Expect('<Standard Format,2>', 'ok:1 2 2 5 3 7');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_3723000_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 3723000;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P0DT1H2M3.0S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_90061001_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 90061001;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('n1', 'ok:1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('n2', 'ok:1 0 1 2 1 4 1 6 1 8');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P1DT1H1M1.001S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('<Standard Format,1>', 'ok:1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('<Standard Format,2>', 'ok:1 0 1 2 1 4 1 6 1 8');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_90061001_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 90061001;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P1DT1H1M1.001S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_neg90061001_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -90061001;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:-1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('n1', 'ok:-1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('n2', 'ok:-1 0 1 2 1 4 1 6 1 8');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:-P1DT1H1M1.001S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:-1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('<Standard Format,1>', 'ok:-1 day 1 hour 1 minute 1 second 1 millisecond');
        O.Expect('<Standard Format,2>', 'ok:-1 0 1 2 1 4 1 6 1 8');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_neg90061001_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -90061001;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:-P1DT1H1M1.001S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_3600000_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 3600000;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 hour');
        O.Expect('n1', 'ok:1 hour');
        O.Expect('n2', 'ok:1 2');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P0DT1H0M0.0S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 hour');
        O.Expect('<Standard Format,1>', 'ok:1 hour');
        O.Expect('<Standard Format,2>', 'ok:1 2');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_3600000_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 3600000;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P0DT1H0M0.0S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_90061001_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 90061001;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Days>', V, '<Days>');
        CellS(O, '<Hours>', V, '<Hours>');
        CellS(O, '<Minutes>', V, '<Minutes>');
        CellS(O, '<Seconds>', V, '<Seconds>');
        CellS(O, '<Thousands>', V, '<Thousands>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:1 Tag 1 Stunde 1 Minute 1 Sekunde 1 Millisekunde');
        O.Expect('n1', 'ok:1 Tag 1 Stunde 1 Minute 1 Sekunde 1 Millisekunde');
        O.Expect('n2', 'ok:1 0 1 2 1 4 1 6 1 8');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:P1DT1H1M1.001S');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Days>', 'err:InvalidFormatString');
        O.Expect('<Hours>', 'err:InvalidFormatString');
        O.Expect('<Minutes>', 'err:InvalidFormatString');
        O.Expect('<Seconds>', 'err:InvalidFormatString');
        O.Expect('<Thousands>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer Thousand>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Sign><Integer>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:1 Tag 1 Stunde 1 Minute 1 Sekunde 1 Millisekunde');
        O.Expect('<Standard Format,1>', 'ok:1 Tag 1 Stunde 1 Minute 1 Sekunde 1 Millisekunde');
        O.Expect('<Standard Format,2>', 'ok:1 0 1 2 1 4 1 6 1 8');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Duration_90061001_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 90061001;
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,9>', 'ok:P1DT1H1M1.001S');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Date2DMY_Date2DWY_0D()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        D: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        D := 0D;
        DmyCell(O, 'dmy0', D, 0);
        DmyCell(O, 'dmy1', D, 1);
        DmyCell(O, 'dmy2', D, 2);
        DmyCell(O, 'dmy3', D, 3);
        DmyCell(O, 'dmy4', D, 4);
        DmyCell(O, 'dmy5', D, 5);
        DwyCell(O, 'dwy0', D, 0);
        DwyCell(O, 'dwy1', D, 1);
        DwyCell(O, 'dwy2', D, 2);
        DwyCell(O, 'dwy3', D, 3);
        DwyCell(O, 'dwy4', D, 4);
        DwyCell(O, 'dwy5', D, 5);
        GlobalLanguage(Saved);
        O.Expect('dmy0', 'err:DateInvalid:The date is not valid.');
        O.Expect('dmy1', 'err:DateInvalid:The date is not valid.');
        O.Expect('dmy2', 'err:DateInvalid:The date is not valid.');
        O.Expect('dmy3', 'err:DateInvalid:The date is not valid.');
        O.Expect('dmy4', 'err:DateInvalid:The date is not valid.');
        O.Expect('dmy5', 'err:DateInvalid:The date is not valid.');
        O.Expect('dwy0', 'err:DateInvalid:The date is not valid.');
        O.Expect('dwy1', 'err:DateInvalid:The date is not valid.');
        O.Expect('dwy2', 'err:DateInvalid:The date is not valid.');
        O.Expect('dwy3', 'err:DateInvalid:The date is not valid.');
        O.Expect('dwy4', 'err:DateInvalid:The date is not valid.');
        O.Expect('dwy5', 'err:DateInvalid:The date is not valid.');
        O.Verify();
    end;

    [Test]
    procedure Date2DMY_Date2DWY_20260309D()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        D: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        D := 20260309D;
        DmyCell(O, 'dmy0', D, 0);
        DmyCell(O, 'dmy1', D, 1);
        DmyCell(O, 'dmy2', D, 2);
        DmyCell(O, 'dmy3', D, 3);
        DmyCell(O, 'dmy4', D, 4);
        DmyCell(O, 'dmy5', D, 5);
        DwyCell(O, 'dwy0', D, 0);
        DwyCell(O, 'dwy1', D, 1);
        DwyCell(O, 'dwy2', D, 2);
        DwyCell(O, 'dwy3', D, 3);
        DwyCell(O, 'dwy4', D, 4);
        DwyCell(O, 'dwy5', D, 5);
        GlobalLanguage(Saved);
        O.Expect('dmy0', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('dmy1', 'ok:9');
        O.Expect('dmy2', 'ok:3');
        O.Expect('dmy3', 'ok:2026');
        O.Expect('dmy4', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('dmy5', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        O.Expect('dwy0', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('dwy1', 'ok:1');
        O.Expect('dwy2', 'ok:11');
        O.Expect('dwy3', 'ok:2026');
        O.Expect('dwy4', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('dwy5', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        O.Verify();
    end;

    [Test]
    procedure Date2DMY_Date2DWY_17530101D()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        D: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        D := 17530101D;
        DmyCell(O, 'dmy0', D, 0);
        DmyCell(O, 'dmy1', D, 1);
        DmyCell(O, 'dmy2', D, 2);
        DmyCell(O, 'dmy3', D, 3);
        DmyCell(O, 'dmy4', D, 4);
        DmyCell(O, 'dmy5', D, 5);
        DwyCell(O, 'dwy0', D, 0);
        DwyCell(O, 'dwy1', D, 1);
        DwyCell(O, 'dwy2', D, 2);
        DwyCell(O, 'dwy3', D, 3);
        DwyCell(O, 'dwy4', D, 4);
        DwyCell(O, 'dwy5', D, 5);
        GlobalLanguage(Saved);
        O.Expect('dmy0', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('dmy1', 'ok:1');
        O.Expect('dmy2', 'ok:1');
        O.Expect('dmy3', 'ok:1753');
        O.Expect('dmy4', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('dmy5', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        O.Expect('dwy0', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('dwy1', 'ok:1');
        O.Expect('dwy2', 'ok:1');
        O.Expect('dwy3', 'ok:1753');
        O.Expect('dwy4', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('dwy5', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        O.Verify();
    end;

    [Test]
    procedure Date2DMY_Date2DWY_99991231D()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        D: Date;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        D := 99991231D;
        DmyCell(O, 'dmy0', D, 0);
        DmyCell(O, 'dmy1', D, 1);
        DmyCell(O, 'dmy2', D, 2);
        DmyCell(O, 'dmy3', D, 3);
        DmyCell(O, 'dmy4', D, 4);
        DmyCell(O, 'dmy5', D, 5);
        DwyCell(O, 'dwy0', D, 0);
        DwyCell(O, 'dwy1', D, 1);
        DwyCell(O, 'dwy2', D, 2);
        DwyCell(O, 'dwy3', D, 3);
        DwyCell(O, 'dwy4', D, 4);
        DwyCell(O, 'dwy5', D, 5);
        GlobalLanguage(Saved);
        O.Expect('dmy0', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('dmy1', 'ok:31');
        O.Expect('dmy2', 'ok:12');
        O.Expect('dmy3', 'ok:9999');
        O.Expect('dmy4', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('dmy5', 'err:OutsidePermittedRange:The value of DATE2DMY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        O.Expect('dwy0', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        O.Expect('dwy1', 'ok:5');
        O.Expect('dwy2', 'ok:52');
        O.Expect('dwy3', 'ok:9999');
        O.Expect('dwy4', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 3.');
        O.Expect('dwy5', 'err:OutsidePermittedRange:The value of DATE2DWY parameter 2 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        O.Verify();
    end;

    [Test]
    procedure DMY2Date_EdgeValues()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Dmy2Cell(O, 1, 1, 2026);
        Dmy2Cell(O, 0, 1, 2026);
        Dmy2Cell(O, 32, 1, 2026);
        Dmy2Cell(O, 31, 4, 2026);
        Dmy2Cell(O, 29, 2, 2026);
        Dmy2Cell(O, 29, 2, 2024);
        Dmy2Cell(O, 1, 0, 2026);
        Dmy2Cell(O, 1, 13, 2026);
        Dmy2Cell(O, 1, 1, 0);
        Dmy2Cell(O, 1, 1, 1752);
        Dmy2Cell(O, 1, 1, 1753);
        Dmy2Cell(O, 31, 12, 9999);
        Dmy2Cell(O, 1, 1, 10000);
        Dmy2Cell(O, 0, 0, 0);
        Dmy2Cell(O, 1, 1, -1);
        GlobalLanguage(Saved);
        O.Expect('1/1/2026', 'ok:2026-01-01');
        O.Expect('0/1/2026', 'err:OutsidePermittedRange:The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 31.');
        O.Expect('32/1/2026', 'err:OutsidePermittedRange:The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 32. The permitted range is: from 1 to 31.');
        O.Expect('31/4/2026', 'err:OutsidePermittedRange:The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 31. The permitted range is: from 1 to 30.');
        O.Expect('29/2/2026', 'err:OutsidePermittedRange:The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 29. The permitted range is: from 1 to 28.');
        O.Expect('29/2/2024', 'ok:2024-02-29');
        O.Expect('1/0/2026', 'err:OutsidePermittedRange:The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.');
        O.Expect('1/13/2026', 'err:OutsidePermittedRange:The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 13. The permitted range is: from 1 to 12.');
        O.Expect('1/1/0', 'ok:0001-01-02');
        O.Expect('1/1/1752', 'ok:1752-01-01');
        O.Expect('1/1/1753', 'ok:1753-01-01');
        O.Expect('31/12/9999', 'ok:9999-12-31');
        O.Expect('1/1/10000', 'err:OutsidePermittedRange:The value of DMY2Date parameter 3 is outside of the permitted range. The current value is: 10000. The permitted range is: from 1 to 9999.');
        O.Expect('0/0/0', 'err:OutsidePermittedRange:The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.');
        O.Expect('1/1/-1', 'err:OutsidePermittedRange:The value of DMY2Date parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 9999.');
        O.Verify();
    end;
}
