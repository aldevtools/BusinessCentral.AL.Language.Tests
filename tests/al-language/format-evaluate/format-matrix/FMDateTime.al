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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
    end;

    [Test]
    procedure Format_DateTime_0D_123456T_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(0D, 123456T);
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
        O.Finish();
    end;

    [Test]
    procedure Format_DateTime_0D_123456T_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(0D, 123456T);
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
        O.Finish();
    end;

    [Test]
    procedure Format_DateTime_0D_123456T_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: DateTime;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := CreateDateTime(0D, 123456T);
        CellS(O, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', V, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>');
        CellS(O, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>', V, '<Day>. <Month Text> <Year4> <Hours24,2>:<Minutes,2>');
        CellS(O, '<Closing><Day> <Month Text>, <Year4>', V, '<Closing><Day> <Month Text>, <Year4>');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        GlobalLanguage(Saved);
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
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
        O.Finish();
    end;
}
