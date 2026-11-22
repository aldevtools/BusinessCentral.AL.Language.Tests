// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-formatregion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al); SingleInstance log 96383 is used only by test codeunit 96385
// Probe: written against a local BC 27.5 service tier (Windows); every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Value, Length [, FormatNumber]) inside OnPreReport of a processing-only report after CurrReport.FormatRegion := 'de-DE', 'en-US' or
//   without setting it: Decimal, Integer, Date, undefined Date, Text, Duration and Time with positive and negative lengths; and the same Decimal
//   formatted by a codeunit the report calls.
// Results (BC 27.5): inside OnPreReport, after CurrReport.FormatRegion := 'de-DE', a length cuts and pads the de-DE text (Format(1234.5, 10) = '   1.234,5',
//   Format(1234.5, 3) = '1.2', Format(1234.5, 10, 1) = '    1234,5'); format 9 is not affected. CurrReport.FormatRegion := 'en-US' reads back as ''.
//   A codeunit called from the report formats with the report's region too.
// BC versions: 27.5 measured on a local Windows container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

codeunit 96383 "FLN Region Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        Region: Text;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Take(var Result: List of [Text])
    begin
        Result := Entries;
        Clear(Entries);
    end;

    procedure SetRegion(NewRegion: Text)
    begin
        Region := NewRegion;
    end;

    procedure GetRegion(): Text
    begin
        exit(Region);
    end;
}

report 96384 "FLN Region Lengths"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    trigger OnPreReport()
    var
        F: Codeunit "FLN Fmt";
        N: Integer;
    begin
        if L.GetRegion() <> '' then
            CurrReport.FormatRegion := L.GetRegion();
        L.Add('region=[' + CurrReport.FormatRegion() + ']');
        for N := 1 to 24 do
            L.Add(Cell(N));
        L.Add('codeunit dec 1234.5 L=10=' + F.Decimal(1234.5, 10, -1));
        L.Add('codeunit dec 1234.5 L=-10=' + F.Decimal(1234.5, -10, -1));
    end;

    local procedure Cell(N: Integer): Text
    var
        Name: Text;
        Result: Text;
    begin
        Name := CellName(N);
        Got := '';
        if TryCell(N) then
            exit(Name + '=[' + Got + ']');
        Result := Name + '=ERR ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure CellName(N: Integer): Text
    begin
        case N of
            1:
                exit('dec 1234.5 L=0');
            2:
                exit('dec 1234.5 L=3');
            3:
                exit('dec 1234.5 L=10');
            4:
                exit('dec 1234.5 L=30');
            5:
                exit('dec 1234.5 L=-3');
            6:
                exit('dec 1234.5 L=-10');
            7:
                exit('dec 1234.5 L=-30');
            8:
                exit('dec 1234.5 L=10 N=9');
            9:
                exit('dec 1234.5 L=-10 N=9');
            10:
                exit('dec 1234.5 L=10 N=1');
            11:
                exit('int 1234567 L=0');
            12:
                exit('int 1234567 L=3');
            13:
                exit('int 1234567 L=10');
            14:
                exit('int 1234567 L=-10');
            15:
                exit('date L=0');
            16:
                exit('date L=3');
            17:
                exit('date L=10');
            18:
                exit('date L=30');
            19:
                exit('date L=-10');
            20:
                exit('0D L=10');
            21:
                exit('0D L=10 N=9');
            22:
                exit('text ab L=5');
            23:
                exit('dur L=30');
            24:
                exit('time L=30');
        end;
    end;

    [TryFunction]
    local procedure TryCell(N: Integer)
    var
        Dec: Decimal;
        Int: Integer;
        D: Date;
        Dur: Duration;
        T: Time;
    begin
        Dec := 1234.5;
        Int := 1234567;
        D := DMY2Date(15, 1, 2024);
        Dur := 3723004;
        T := 134501T;
        case N of
            1:
                Got := Format(Dec);
            2:
                Got := Format(Dec, 3);
            3:
                Got := Format(Dec, 10);
            4:
                Got := Format(Dec, 30);
            5:
                Got := Format(Dec, -3);
            6:
                Got := Format(Dec, -10);
            7:
                Got := Format(Dec, -30);
            8:
                Got := Format(Dec, 10, 9);
            9:
                Got := Format(Dec, -10, 9);
            10:
                Got := Format(Dec, 10, 1);
            11:
                Got := Format(Int);
            12:
                Got := Format(Int, 3);
            13:
                Got := Format(Int, 10);
            14:
                Got := Format(Int, -10);
            15:
                Got := Format(D);
            16:
                Got := Format(D, 3);
            17:
                Got := Format(D, 10);
            18:
                Got := Format(D, 30);
            19:
                Got := Format(D, -10);
            20:
                Got := Format(0D, 10);
            21:
                Got := Format(0D, 10, 9);
            22:
                Got := Format('ab', 5);
            23:
                Got := Format(Dur, 30);
            24:
                Got := Format(T, 30);
        end;
    end;

    var
        L: Codeunit "FLN Region Log";
        Got: Text;
}

codeunit 96385 "FLN Region Length Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "FLN Region Log";

    local procedure RunWith(Region: Text; var Observer: Codeunit "Probe Observer")
    var
        Entries: List of [Text];
        Entry: Text;
        Discarded: List of [Text];
        Index: Integer;
    begin
        L.Take(Discarded);
        L.SetRegion(Region);
        Report.Run(Report::"FLN Region Lengths");
        L.SetRegion('');
        L.Take(Entries);
        foreach Entry in Entries do begin
            Index += 1;
            Observer.Observe(Format(Index), Entry);
        end;
    end;

    [Test]
    procedure Region_de_DE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith('de-DE', Observer);
        Observer.Expect('1', 'region=[de-DE]');
        Observer.Expect('2', 'dec 1234.5 L=0=[1.234,5]');
        Observer.Expect('3', 'dec 1234.5 L=3=[1.2]');
        Observer.Expect('4', 'dec 1234.5 L=10=[   1.234,5]');
        Observer.Expect('5', 'dec 1234.5 L=30=[                       1.234,5]');
        Observer.Expect('6', 'dec 1234.5 L=-3=[1.2]');
        Observer.Expect('7', 'dec 1234.5 L=-10=[1.234,5]');
        Observer.Expect('8', 'dec 1234.5 L=-30=[1.234,5]');
        Observer.Expect('9', 'dec 1234.5 L=10 N=9=[    1234.5]');
        Observer.Expect('10', 'dec 1234.5 L=-10 N=9=[1234.5]');
        Observer.Expect('11', 'dec 1234.5 L=10 N=1=[    1234,5]');
        Observer.Expect('12', 'int 1234567 L=0=[1234567]');
        Observer.Expect('13', 'int 1234567 L=3=[123]');
        Observer.Expect('14', 'int 1234567 L=10=[   1234567]');
        Observer.Expect('15', 'int 1234567 L=-10=[1234567]');
        Observer.Expect('16', 'date L=0=[15.01.24]');
        Observer.Expect('17', 'date L=3=[15.]');
        Observer.Expect('18', 'date L=10=[  15.01.24]');
        Observer.Expect('19', 'date L=30=[                      15.01.24]');
        Observer.Expect('20', 'date L=-10=[15.01.24]');
        Observer.Expect('21', '0D L=10=[          ]');
        Observer.Expect('22', '0D L=10 N=9=[          ]');
        Observer.Expect('23', 'text ab L=5=[ab   ]');
        Observer.Expect('24', 'dur L=30=[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('25', 'time L=30=[                      13:45:01]');
        Observer.Expect('26', 'codeunit dec 1234.5 L=10=[   1.234,5]');
        Observer.Expect('27', 'codeunit dec 1234.5 L=-10=[1.234,5]');
        Observer.Verify();
    end;

    [Test]
    procedure Region_en_US()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith('en-US', Observer);
        Observer.Expect('1', 'region=[]');
        Observer.Expect('2', 'dec 1234.5 L=0=[1,234.5]');
        Observer.Expect('3', 'dec 1234.5 L=3=[1,2]');
        Observer.Expect('4', 'dec 1234.5 L=10=[   1,234.5]');
        Observer.Expect('5', 'dec 1234.5 L=30=[                       1,234.5]');
        Observer.Expect('6', 'dec 1234.5 L=-3=[1,2]');
        Observer.Expect('7', 'dec 1234.5 L=-10=[1,234.5]');
        Observer.Expect('8', 'dec 1234.5 L=-30=[1,234.5]');
        Observer.Expect('9', 'dec 1234.5 L=10 N=9=[    1234.5]');
        Observer.Expect('10', 'dec 1234.5 L=-10 N=9=[1234.5]');
        Observer.Expect('11', 'dec 1234.5 L=10 N=1=[    1234.5]');
        Observer.Expect('12', 'int 1234567 L=0=[1234567]');
        Observer.Expect('13', 'int 1234567 L=3=[123]');
        Observer.Expect('14', 'int 1234567 L=10=[   1234567]');
        Observer.Expect('15', 'int 1234567 L=-10=[1234567]');
        Observer.Expect('16', 'date L=0=[01/15/24]');
        Observer.Expect('17', 'date L=3=[01/]');
        Observer.Expect('18', 'date L=10=[  01/15/24]');
        Observer.Expect('19', 'date L=30=[                      01/15/24]');
        Observer.Expect('20', 'date L=-10=[01/15/24]');
        Observer.Expect('21', '0D L=10=[          ]');
        Observer.Expect('22', '0D L=10 N=9=[          ]');
        Observer.Expect('23', 'text ab L=5=[ab   ]');
        Observer.Expect('24', 'dur L=30=[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('25', 'time L=30=[                    1:45:01 PM]');
        Observer.Expect('26', 'codeunit dec 1234.5 L=10=[   1,234.5]');
        Observer.Expect('27', 'codeunit dec 1234.5 L=-10=[1,234.5]');
        Observer.Verify();
    end;

    [Test]
    procedure Region_NotSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith('', Observer);
        Observer.Expect('1', 'region=[]');
        Observer.Expect('2', 'dec 1234.5 L=0=[1,234.5]');
        Observer.Expect('3', 'dec 1234.5 L=3=[1,2]');
        Observer.Expect('4', 'dec 1234.5 L=10=[   1,234.5]');
        Observer.Expect('5', 'dec 1234.5 L=30=[                       1,234.5]');
        Observer.Expect('6', 'dec 1234.5 L=-3=[1,2]');
        Observer.Expect('7', 'dec 1234.5 L=-10=[1,234.5]');
        Observer.Expect('8', 'dec 1234.5 L=-30=[1,234.5]');
        Observer.Expect('9', 'dec 1234.5 L=10 N=9=[    1234.5]');
        Observer.Expect('10', 'dec 1234.5 L=-10 N=9=[1234.5]');
        Observer.Expect('11', 'dec 1234.5 L=10 N=1=[    1234.5]');
        Observer.Expect('12', 'int 1234567 L=0=[1234567]');
        Observer.Expect('13', 'int 1234567 L=3=[123]');
        Observer.Expect('14', 'int 1234567 L=10=[   1234567]');
        Observer.Expect('15', 'int 1234567 L=-10=[1234567]');
        Observer.Expect('16', 'date L=0=[01/15/24]');
        Observer.Expect('17', 'date L=3=[01/]');
        Observer.Expect('18', 'date L=10=[  01/15/24]');
        Observer.Expect('19', 'date L=30=[                      01/15/24]');
        Observer.Expect('20', 'date L=-10=[01/15/24]');
        Observer.Expect('21', '0D L=10=[          ]');
        Observer.Expect('22', '0D L=10 N=9=[          ]');
        Observer.Expect('23', 'text ab L=5=[ab   ]');
        Observer.Expect('24', 'dur L=30=[1 hour 2 minutes 3 seconds 4 m]');
        Observer.Expect('25', 'time L=30=[                    1:45:01 PM]');
        Observer.Expect('26', 'codeunit dec 1234.5 L=10=[   1,234.5]');
        Observer.Expect('27', 'codeunit dec 1234.5 L=-10=[1,234.5]');
        Observer.Verify();
    end;
}
