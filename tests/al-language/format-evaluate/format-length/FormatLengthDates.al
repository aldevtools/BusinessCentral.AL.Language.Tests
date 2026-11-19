// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al); own temporary table 96381
// Probe: written against a local BC 27.5 service tier (Windows); every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Value, Length [, FormatNumber | FormatString]) of an undefined Date (0D), an undefined DateTime (0DT), a closing Date and a defined
//   Date or DateTime, for positive and negative lengths shorter than, equal to and longer than the text; as a variable, a literal and a table field
//   (the shape Format(Rec."Some Date", 10, 9) of Base Application codeunit "Onboarding Signal").
// Results (BC 27.5): an undefined Date (0D) and an undefined DateTime (0DT) format with a positive length L as L blanks, with a negative length as ''.
//   This holds for Format(0D, L), Format(0D, L, 0 | 1 | 2 | 9), a format string, a literal and a table field: Format(Rec."Some Date", 10, 9) of a 0D field is
//   10 blanks (the shape of Base Application codeunit "Onboarding Signal"). A closing Date and a defined Date or DateTime: a positive length longer than the
//   text right-aligns it (padded on the left), a negative length longer than the text keeps the text, and any length shorter than the text cuts it to its
//   first |L| characters (Format(ClosingDate(D), 10) = ' C01/15/24', Format(D, 8, 9) = '2024-01-'). ClosingDate(0D) raises "The date is not valid." (DateInvalid).
// BC versions: 27.5 measured on a local Windows container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

table 96381 "FLN Date Holder"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Start Date"; Date) { }
        field(3; "Start DateTime"; DateTime) { }
        field(4; "Defined Date"; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96380 "FLN Date Lengths"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Got: Text;

    [Test]
    procedure UndefinedDate_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := 0D;
        Observer.Observe('plain', '[' + Format(D) + ']');
        Observer.Observe('0D L=1', F.Date(D, 1, -1));
        Observer.Observe('0D L=3', F.Date(D, 3, -1));
        Observer.Observe('0D L=8', F.Date(D, 8, -1));
        Observer.Observe('0D L=10', F.Date(D, 10, -1));
        Observer.Observe('0D L=30', F.Date(D, 30, -1));
        Observer.Observe('0D L=-1', F.Date(D, -1, -1));
        Observer.Observe('0D L=-3', F.Date(D, -3, -1));
        Observer.Observe('0D L=-8', F.Date(D, -8, -1));
        Observer.Observe('0D L=-10', F.Date(D, -10, -1));
        Observer.Observe('0D L=-30', F.Date(D, -30, -1));
        Observer.Expect('plain', '[]');
        Observer.Expect('0D L=1', '[ ]');
        Observer.Expect('0D L=3', '[   ]');
        Observer.Expect('0D L=8', '[        ]');
        Observer.Expect('0D L=10', '[          ]');
        Observer.Expect('0D L=30', '[                              ]');
        Observer.Expect('0D L=-1', '[]');
        Observer.Expect('0D L=-3', '[]');
        Observer.Expect('0D L=-8', '[]');
        Observer.Expect('0D L=-10', '[]');
        Observer.Expect('0D L=-30', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDate_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := 0D;
        Observer.Observe('0D L=1 N=9', F.Date(D, 1, 9));
        Observer.Observe('0D L=3 N=9', F.Date(D, 3, 9));
        Observer.Observe('0D L=8 N=9', F.Date(D, 8, 9));
        Observer.Observe('0D L=10 N=9', F.Date(D, 10, 9));
        Observer.Observe('0D L=30 N=9', F.Date(D, 30, 9));
        Observer.Observe('0D L=-1 N=9', F.Date(D, -1, 9));
        Observer.Observe('0D L=-3 N=9', F.Date(D, -3, 9));
        Observer.Observe('0D L=-8 N=9', F.Date(D, -8, 9));
        Observer.Observe('0D L=-10 N=9', F.Date(D, -10, 9));
        Observer.Observe('0D L=-30 N=9', F.Date(D, -30, 9));
        Observer.Observe('0D L=3 N=0', F.Date(D, 3, 0));
        Observer.Observe('0D L=10 N=0', F.Date(D, 10, 0));
        Observer.Observe('0D L=-10 N=0', F.Date(D, -10, 0));
        Observer.Observe('0D L=10 N=1', F.Date(D, 10, 1));
        Observer.Observe('0D L=10 N=2', F.Date(D, 10, 2));
        Observer.Expect('0D L=1 N=9', '[ ]');
        Observer.Expect('0D L=3 N=9', '[   ]');
        Observer.Expect('0D L=8 N=9', '[        ]');
        Observer.Expect('0D L=10 N=9', '[          ]');
        Observer.Expect('0D L=30 N=9', '[                              ]');
        Observer.Expect('0D L=-1 N=9', '[]');
        Observer.Expect('0D L=-3 N=9', '[]');
        Observer.Expect('0D L=-8 N=9', '[]');
        Observer.Expect('0D L=-10 N=9', '[]');
        Observer.Expect('0D L=-30 N=9', '[]');
        Observer.Expect('0D L=3 N=0', '[   ]');
        Observer.Expect('0D L=10 N=0', '[          ]');
        Observer.Expect('0D L=-10 N=0', '[]');
        Observer.Expect('0D L=10 N=1', '[          ]');
        Observer.Expect('0D L=10 N=2', '[          ]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDate_Length_String()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := 0D;
        Observer.Observe('0D L=3 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, 3, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('0D L=10 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, 10, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('0D L=30 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, 30, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('0D L=-3 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, -3, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('0D L=-10 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, -10, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('0D L=10 S=<Closing><Day>', F.DateS(D, 10, '<Closing><Day>'));
        Observer.Observe('0D L=0 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, 0, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Expect('0D L=3 S=<Year4>-<Month,2>-<Day,2>', '[   ]');
        Observer.Expect('0D L=10 S=<Year4>-<Month,2>-<Day,2>', '[          ]');
        Observer.Expect('0D L=30 S=<Year4>-<Month,2>-<Day,2>', '[                              ]');
        Observer.Expect('0D L=-3 S=<Year4>-<Month,2>-<Day,2>', '[]');
        Observer.Expect('0D L=-10 S=<Year4>-<Month,2>-<Day,2>', '[]');
        Observer.Expect('0D L=10 S=<Closing><Day>', '[          ]');
        Observer.Expect('0D L=0 S=<Year4>-<Month,2>-<Day,2>', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Literal_And_Field_Forms()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";

    begin
        Observer.Observe('Format(0D, 10)', Lit(1));
        Observer.Observe('Format(0D, 10, 9)', Lit(2));
        Observer.Observe('Format(0D, -10)', Lit(3));
        Observer.Observe('Format(0D, -10, 9)', Lit(4));
        Observer.Observe('Format(0D, 3)', Lit(5));
        Observer.Observe('Format(0D, 1)', Lit(6));
        Observer.Observe('Format(0D, 10, 0)', Lit(7));
        Observer.Observe('Format(0DT, 10)', Lit(8));
        Observer.Observe('Format(0DT, 10, 9)', Lit(9));
        Observer.Observe('Format(0DT, -10)', Lit(10));
        Observer.Observe('Format(ClosingDate(20241231D), 10)', Lit(11));
        Observer.Observe('Format(ClosingDate(20241231D), 10, 9)', Lit(12));
        Observer.Observe('Format(ClosingDate(20241231D), -10)', Lit(13));
        Observer.Expect('Format(0D, 10)', '[          ]');
        Observer.Expect('Format(0D, 10, 9)', '[          ]');
        Observer.Expect('Format(0D, -10)', '[]');
        Observer.Expect('Format(0D, -10, 9)', '[]');
        Observer.Expect('Format(0D, 3)', '[   ]');
        Observer.Expect('Format(0D, 1)', '[ ]');
        Observer.Expect('Format(0D, 10, 0)', '[          ]');
        Observer.Expect('Format(0DT, 10)', '[          ]');
        Observer.Expect('Format(0DT, 10, 9)', '[          ]');
        Observer.Expect('Format(0DT, -10)', '[]');
        Observer.Expect('Format(ClosingDate(20241231D), 10)', '[ C12/31/24]');
        Observer.Expect('Format(ClosingDate(20241231D), 10, 9)', '[2024-12-31]');
        Observer.Expect('Format(ClosingDate(20241231D), -10)', '[C12/31/24]');
        Observer.Verify();
    end;

    // The shape of a Microsoft ERM test: Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'), a format string whose text is exactly 10 characters.
    [Test]
    procedure FormatString_Year4_Length()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Plain: Text;
    begin
        D := 20240115D;
        Observer.Observe('Format(D, 10, S)', '[' + Format(D, 10, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, 8, S)', '[' + Format(D, 8, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, 12, S)', '[' + Format(D, 12, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, 9, S)', '[' + Format(D, 9, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, 11, S)', '[' + Format(D, 11, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, 0, S)', '[' + Format(D, 0, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, -10, S)', '[' + Format(D, -10, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, -8, S)', '[' + Format(D, -8, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(D, -12, S)', '[' + Format(D, -12, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('literal Format(20240115D, 10, S)', '[' + Format(20240115D, 10, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(0D, 10, S)', '[' + Format(0D, 10, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(0D, -10, S)', '[' + Format(0D, -10, '<Year4>-<Month,2>-<Day,2>') + ']');
        Observer.Observe('Format(ClosingDate(D), 10, S)', '[' + Format(ClosingDate(D), 10, '<Year4>-<Month,2>-<Day,2>') + ']');
        Plain := Format(WorkDate(), 0, '<Year4>-<Month,2>-<Day,2>');
        Observer.Observe('WorkDate: StrLen(Format(WorkDate(), 0, S))', Format(StrLen(Plain)));
        Observer.Observe('WorkDate: Format(WorkDate(), 10, S) = Format(WorkDate(), 0, S)', Format(Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>') = Plain));
        Observer.Observe('WorkDate: Format(WorkDate(), 8, S) = CopyStr(plain, 1, 8)', Format(Format(WorkDate(), 8, '<Year4>-<Month,2>-<Day,2>') = CopyStr(Plain, 1, 8)));
        Observer.Observe('WorkDate: Format(WorkDate(), 12, S) = two blanks + plain', Format(Format(WorkDate(), 12, '<Year4>-<Month,2>-<Day,2>') = '  ' + Plain));
        Observer.Observe('WorkDate: Format(WorkDate(), -12, S) = plain', Format(Format(WorkDate(), -12, '<Year4>-<Month,2>-<Day,2>') = Plain));
        Observer.Finish();
    end;

    [Test]
    procedure Field_Forms()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";

    begin
        Observer.Observe('field 0D (10, 9)', Lit(14));
        Observer.Observe('field 0D (10)', Lit(15));
        Observer.Observe('field 0D (-10, 9)', Lit(16));
        Observer.Observe('field 0D (3, 9)', Lit(17));
        Observer.Observe('field 0DT (10, 9)', Lit(18));
        Observer.Observe('field 0DT (10)', Lit(19));
        Observer.Observe('field 2024-01-15 (10, 9)', Lit(20));
        Observer.Observe('field 2024-01-15 (8, 9)', Lit(21));
        Observer.Observe('field 2024-01-15 (-12, 9)', Lit(22));
        Observer.Observe('field 2024-01-15 (10)', Lit(23));
        Observer.Expect('field 0D (10, 9)', '[          ]');
        Observer.Expect('field 0D (10)', '[          ]');
        Observer.Expect('field 0D (-10, 9)', '[]');
        Observer.Expect('field 0D (3, 9)', '[   ]');
        Observer.Expect('field 0DT (10, 9)', '[          ]');
        Observer.Expect('field 0DT (10)', '[          ]');
        Observer.Expect('field 2024-01-15 (10, 9)', '[2024-01-15]');
        Observer.Expect('field 2024-01-15 (8, 9)', '[2024-01-]');
        Observer.Expect('field 2024-01-15 (-12, 9)', '[2024-01-15]');
        Observer.Expect('field 2024-01-15 (10)', '[  01/15/24]');
        Observer.Verify();
    end;

    [Test]
    procedure ClosingDate_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := ClosingDate(DMY2Date(15, 1, 2024));
        Observer.Observe('plain', '[' + Format(D) + ']');
        Observer.Observe('C L=1', F.Date(D, 1, -1));
        Observer.Observe('C L=3', F.Date(D, 3, -1));
        Observer.Observe('C L=8', F.Date(D, 8, -1));
        Observer.Observe('C L=10', F.Date(D, 10, -1));
        Observer.Observe('C L=30', F.Date(D, 30, -1));
        Observer.Observe('C L=-1', F.Date(D, -1, -1));
        Observer.Observe('C L=-3', F.Date(D, -3, -1));
        Observer.Observe('C L=-8', F.Date(D, -8, -1));
        Observer.Observe('C L=-10', F.Date(D, -10, -1));
        Observer.Observe('C L=-30', F.Date(D, -30, -1));
        Observer.Observe('C L=exact', F.Date(D, StrLen(Format(D)), -1));
        Observer.Observe('C L=-exact', F.Date(D, -StrLen(Format(D)), -1));
        Observer.Expect('plain', '[C01/15/24]');
        Observer.Expect('C L=1', '[C]');
        Observer.Expect('C L=3', '[C01]');
        Observer.Expect('C L=8', '[C01/15/2]');
        Observer.Expect('C L=10', '[ C01/15/24]');
        Observer.Expect('C L=30', '[                     C01/15/24]');
        Observer.Expect('C L=-1', '[C]');
        Observer.Expect('C L=-3', '[C01]');
        Observer.Expect('C L=-8', '[C01/15/2]');
        Observer.Expect('C L=-10', '[C01/15/24]');
        Observer.Expect('C L=-30', '[C01/15/24]');
        Observer.Expect('C L=exact', '[C01/15/24]');
        Observer.Expect('C L=-exact', '[C01/15/24]');
        Observer.Verify();
    end;

    [Test]
    procedure ClosingDate_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := ClosingDate(DMY2Date(15, 1, 2024));
        Observer.Observe('plain N=9', '[' + Format(D, 0, 9) + ']');
        Observer.Observe('C L=3 N=9', F.Date(D, 3, 9));
        Observer.Observe('C L=10 N=9', F.Date(D, 10, 9));
        Observer.Observe('C L=11 N=9', F.Date(D, 11, 9));
        Observer.Observe('C L=30 N=9', F.Date(D, 30, 9));
        Observer.Observe('C L=-3 N=9', F.Date(D, -3, 9));
        Observer.Observe('C L=-10 N=9', F.Date(D, -10, 9));
        Observer.Observe('C L=-11 N=9', F.Date(D, -11, 9));
        Observer.Observe('C L=-30 N=9', F.Date(D, -30, 9));
        Observer.Observe('C L=10 S=<Closing><Day>', F.DateS(D, 10, '<Closing><Day>'));
        Observer.Observe('C L=-10 S=<Closing><Day>', F.DateS(D, -10, '<Closing><Day>'));
        Observer.Expect('plain N=9', '[2024-01-15]');
        Observer.Expect('C L=3 N=9', '[202]');
        Observer.Expect('C L=10 N=9', '[2024-01-15]');
        Observer.Expect('C L=11 N=9', '[ 2024-01-15]');
        Observer.Expect('C L=30 N=9', '[                    2024-01-15]');
        Observer.Expect('C L=-3 N=9', '[202]');
        Observer.Expect('C L=-10 N=9', '[2024-01-15]');
        Observer.Expect('C L=-11 N=9', '[2024-01-15]');
        Observer.Expect('C L=-30 N=9', '[2024-01-15]');
        Observer.Expect('C L=10 S=<Closing><Day>', '[       C15]');
        Observer.Expect('C L=-10 S=<Closing><Day>', '[C15]');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        DT: DateTime;
    begin
        DT := 0DT;
        Observer.Observe('plain', '[' + Format(DT) + ']');
        Observer.Observe('0DT L=1', F.DateTime(DT, 1, -1));
        Observer.Observe('0DT L=3', F.DateTime(DT, 3, -1));
        Observer.Observe('0DT L=8', F.DateTime(DT, 8, -1));
        Observer.Observe('0DT L=10', F.DateTime(DT, 10, -1));
        Observer.Observe('0DT L=30', F.DateTime(DT, 30, -1));
        Observer.Observe('0DT L=-1', F.DateTime(DT, -1, -1));
        Observer.Observe('0DT L=-3', F.DateTime(DT, -3, -1));
        Observer.Observe('0DT L=-8', F.DateTime(DT, -8, -1));
        Observer.Observe('0DT L=-10', F.DateTime(DT, -10, -1));
        Observer.Observe('0DT L=-30', F.DateTime(DT, -30, -1));
        Observer.Observe('0DT L=3 N=9', F.DateTime(DT, 3, 9));
        Observer.Observe('0DT L=10 N=9', F.DateTime(DT, 10, 9));
        Observer.Observe('0DT L=30 N=9', F.DateTime(DT, 30, 9));
        Observer.Observe('0DT L=-3 N=9', F.DateTime(DT, -3, 9));
        Observer.Observe('0DT L=-30 N=9', F.DateTime(DT, -30, 9));
        Observer.Expect('plain', '[]');
        Observer.Expect('0DT L=1', '[ ]');
        Observer.Expect('0DT L=3', '[   ]');
        Observer.Expect('0DT L=8', '[        ]');
        Observer.Expect('0DT L=10', '[          ]');
        Observer.Expect('0DT L=30', '[                              ]');
        Observer.Expect('0DT L=-1', '[]');
        Observer.Expect('0DT L=-3', '[]');
        Observer.Expect('0DT L=-8', '[]');
        Observer.Expect('0DT L=-10', '[]');
        Observer.Expect('0DT L=-30', '[]');
        Observer.Expect('0DT L=3 N=9', '[   ]');
        Observer.Expect('0DT L=10 N=9', '[          ]');
        Observer.Expect('0DT L=30 N=9', '[                              ]');
        Observer.Expect('0DT L=-3 N=9', '[]');
        Observer.Expect('0DT L=-30 N=9', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure DefinedDate_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('plain', '[' + Format(D) + ']');
        Observer.Observe('D L=1', F.Date(D, 1, -1));
        Observer.Observe('D L=3', F.Date(D, 3, -1));
        Observer.Observe('D L=8', F.Date(D, 8, -1));
        Observer.Observe('D L=10', F.Date(D, 10, -1));
        Observer.Observe('D L=30', F.Date(D, 30, -1));
        Observer.Observe('D L=-1', F.Date(D, -1, -1));
        Observer.Observe('D L=-3', F.Date(D, -3, -1));
        Observer.Observe('D L=-8', F.Date(D, -8, -1));
        Observer.Observe('D L=-10', F.Date(D, -10, -1));
        Observer.Observe('D L=-30', F.Date(D, -30, -1));
        Observer.Observe('D L=exact', F.Date(D, StrLen(Format(D)), -1));
        Observer.Observe('D L=-exact', F.Date(D, -StrLen(Format(D)), -1));
        Observer.Expect('plain', '[01/15/24]');
        Observer.Expect('D L=1', '[0]');
        Observer.Expect('D L=3', '[01/]');
        Observer.Expect('D L=8', '[01/15/24]');
        Observer.Expect('D L=10', '[  01/15/24]');
        Observer.Expect('D L=30', '[                      01/15/24]');
        Observer.Expect('D L=-1', '[0]');
        Observer.Expect('D L=-3', '[01/]');
        Observer.Expect('D L=-8', '[01/15/24]');
        Observer.Expect('D L=-10', '[01/15/24]');
        Observer.Expect('D L=-30', '[01/15/24]');
        Observer.Expect('D L=exact', '[01/15/24]');
        Observer.Expect('D L=-exact', '[01/15/24]');
        Observer.Verify();
    end;

    [Test]
    procedure DefinedDate_Length_Number()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('D L=3 N=9', F.Date(D, 3, 9));
        Observer.Observe('D L=8 N=9', F.Date(D, 8, 9));
        Observer.Observe('D L=10 N=9', F.Date(D, 10, 9));
        Observer.Observe('D L=12 N=9', F.Date(D, 12, 9));
        Observer.Observe('D L=30 N=9', F.Date(D, 30, 9));
        Observer.Observe('D L=-3 N=9', F.Date(D, -3, 9));
        Observer.Observe('D L=-8 N=9', F.Date(D, -8, 9));
        Observer.Observe('D L=-10 N=9', F.Date(D, -10, 9));
        Observer.Observe('D L=-12 N=9', F.Date(D, -12, 9));
        Observer.Observe('D L=-30 N=9', F.Date(D, -30, 9));
        Observer.Observe('D L=3 N=0', F.Date(D, 3, 0));
        Observer.Observe('D L=-3 N=0', F.Date(D, -3, 0));
        Observer.Observe('D L=30 N=0', F.Date(D, 30, 0));
        Observer.Observe('D L=3 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, 3, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('D L=10 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, 10, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('D L=-3 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, -3, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('D L=-10 S=<Year4>-<Month,2>-<Day,2>', F.DateS(D, -10, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Expect('D L=3 N=9', '[202]');
        Observer.Expect('D L=8 N=9', '[2024-01-]');
        Observer.Expect('D L=10 N=9', '[2024-01-15]');
        Observer.Expect('D L=12 N=9', '[  2024-01-15]');
        Observer.Expect('D L=30 N=9', '[                    2024-01-15]');
        Observer.Expect('D L=-3 N=9', '[202]');
        Observer.Expect('D L=-8 N=9', '[2024-01-]');
        Observer.Expect('D L=-10 N=9', '[2024-01-15]');
        Observer.Expect('D L=-12 N=9', '[2024-01-15]');
        Observer.Expect('D L=-30 N=9', '[2024-01-15]');
        Observer.Expect('D L=3 N=0', '[01/]');
        Observer.Expect('D L=-3 N=0', '[01/]');
        Observer.Expect('D L=30 N=0', '[                      01/15/24]');
        Observer.Expect('D L=3 S=<Year4>-<Month,2>-<Day,2>', '[202]');
        Observer.Expect('D L=10 S=<Year4>-<Month,2>-<Day,2>', '[2024-01-15]');
        Observer.Expect('D L=-3 S=<Year4>-<Month,2>-<Day,2>', '[202]');
        Observer.Expect('D L=-10 S=<Year4>-<Month,2>-<Day,2>', '[2024-01-15]');
        Observer.Verify();
    end;

    [Test]
    procedure DefinedDateTime_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 1, 2024), 134501T);
        Observer.Observe('plain', '[' + Format(DT) + ']');
        Observer.Observe('DT L=3', F.DateTime(DT, 3, -1));
        Observer.Observe('DT L=10', F.DateTime(DT, 10, -1));
        Observer.Observe('DT L=30', F.DateTime(DT, 30, -1));
        Observer.Observe('DT L=-3', F.DateTime(DT, -3, -1));
        Observer.Observe('DT L=-10', F.DateTime(DT, -10, -1));
        Observer.Observe('DT L=-30', F.DateTime(DT, -30, -1));
        Observer.Observe('DT L=exact', F.DateTime(DT, StrLen(Format(DT)), -1));
        Observer.Observe('DT L=-exact', F.DateTime(DT, -StrLen(Format(DT)), -1));
        Observer.Expect('plain', '[01/15/24 01:45 PM]');
        Observer.Expect('DT L=3', '[01/]');
        Observer.Expect('DT L=10', '[01/15/24 0]');
        Observer.Expect('DT L=30', '[             01/15/24 01:45 PM]');
        Observer.Expect('DT L=-3', '[01/]');
        Observer.Expect('DT L=-10', '[01/15/24 0]');
        Observer.Expect('DT L=-30', '[01/15/24 01:45 PM]');
        Observer.Expect('DT L=exact', '[01/15/24 01:45 PM]');
        Observer.Expect('DT L=-exact', '[01/15/24 01:45 PM]');
        Observer.Verify();
    end;

    [Test]
    procedure ClosingDate_Undefined()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";

    begin
        Observer.Observe('ClosingDate(0D)', Lit(24));
        Observer.Observe('ClosingDate(0D) L=10', Lit(25));
        Observer.Expect('ClosingDate(0D)', 'ERR The date is not valid. | DateInvalid');
        Observer.Expect('ClosingDate(0D) L=10', 'ERR The date is not valid. | DateInvalid');
        Observer.Verify();
    end;

    // The literal and field forms, each inside a TryFunction (a raised error is recorded as ERR text | code).
    local procedure Lit(N: Integer): Text
    var
        Result: Text;
    begin
        Got := '';
        if TryLit(N) then
            exit('[' + Got + ']');
        Result := 'ERR ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryLit(N: Integer)
    var
        Holder: Record "FLN Date Holder";
    begin
        Holder.Init();
        Holder."Defined Date" := DMY2Date(15, 1, 2024);
        case N of
            1:
                Got := Format(0D, 10);
            2:
                Got := Format(0D, 10, 9);
            3:
                Got := Format(0D, -10);
            4:
                Got := Format(0D, -10, 9);
            5:
                Got := Format(0D, 3);
            6:
                Got := Format(0D, 1);
            7:
                Got := Format(0D, 10, 0);
            8:
                Got := Format(0DT, 10);
            9:
                Got := Format(0DT, 10, 9);
            10:
                Got := Format(0DT, -10);
            11:
                Got := Format(ClosingDate(DMY2Date(31, 12, 2024)), 10);
            12:
                Got := Format(ClosingDate(DMY2Date(31, 12, 2024)), 10, 9);
            13:
                Got := Format(ClosingDate(DMY2Date(31, 12, 2024)), -10);
            14:
                Got := Format(Holder."Start Date", 10, 9);
            15:
                Got := Format(Holder."Start Date", 10);
            16:
                Got := Format(Holder."Start Date", -10, 9);
            17:
                Got := Format(Holder."Start Date", 3, 9);
            18:
                Got := Format(Holder."Start DateTime", 10, 9);
            19:
                Got := Format(Holder."Start DateTime", 10);
            20:
                Got := Format(Holder."Defined Date", 10, 9);
            21:
                Got := Format(Holder."Defined Date", 8, 9);
            22:
                Got := Format(Holder."Defined Date", -12, 9);
            23:
                Got := Format(Holder."Defined Date", 10);
            24:
                Got := Format(ClosingDate(0D));
            25:
                Got := Format(ClosingDate(0D), 10);
        end;
    end;
}
