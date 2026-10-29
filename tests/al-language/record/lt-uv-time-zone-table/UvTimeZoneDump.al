// Dump of the whole "Time Zone" table (2000000164) for the observe run; replaced by assertions afterwards.
codeunit 90530 "LT UV Time Zone Dump"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(FromNo: Integer; ToNo: Integer)
    var
        TimeZone: Record "Time Zone";
        Result: Text;
        No: Integer;
    begin
        for No := FromNo to ToNo do
            if TimeZone.Get(No) then
                Result += Format(No) + '|' + TimeZone.ID + '|' + TimeZone."Display Name" + '~'
            else
                Result += Format(No) + '|absent~';
        Error('DUMP:' + Result);
    end;

    [Test]
    procedure Count()
    var
        TimeZone: Record "Time Zone";
    begin
        Error('DUMP:count=' + Format(TimeZone.Count()));
    end;

    [Test]
    procedure Rows001()
    begin
        Dump(1, 6);
    end;

    [Test]
    procedure Rows007()
    begin
        Dump(7, 12);
    end;

    [Test]
    procedure Rows013()
    begin
        Dump(13, 18);
    end;

    [Test]
    procedure Rows019()
    begin
        Dump(19, 24);
    end;

    [Test]
    procedure Rows025()
    begin
        Dump(25, 30);
    end;

    [Test]
    procedure Rows031()
    begin
        Dump(31, 36);
    end;

    [Test]
    procedure Rows037()
    begin
        Dump(37, 42);
    end;

    [Test]
    procedure Rows043()
    begin
        Dump(43, 48);
    end;

    [Test]
    procedure Rows049()
    begin
        Dump(49, 54);
    end;

    [Test]
    procedure Rows055()
    begin
        Dump(55, 60);
    end;

    [Test]
    procedure Rows061()
    begin
        Dump(61, 66);
    end;

    [Test]
    procedure Rows067()
    begin
        Dump(67, 72);
    end;

    [Test]
    procedure Rows073()
    begin
        Dump(73, 78);
    end;

    [Test]
    procedure Rows079()
    begin
        Dump(79, 84);
    end;

    [Test]
    procedure Rows085()
    begin
        Dump(85, 90);
    end;

    [Test]
    procedure Rows091()
    begin
        Dump(91, 96);
    end;

    [Test]
    procedure Rows097()
    begin
        Dump(97, 102);
    end;

    [Test]
    procedure Rows103()
    begin
        Dump(103, 108);
    end;

    [Test]
    procedure Rows109()
    begin
        Dump(109, 114);
    end;

    [Test]
    procedure Rows115()
    begin
        Dump(115, 120);
    end;

    [Test]
    procedure Rows121()
    begin
        Dump(121, 126);
    end;

    [Test]
    procedure Rows127()
    begin
        Dump(127, 132);
    end;

    [Test]
    procedure Rows133()
    begin
        Dump(133, 138);
    end;

    [Test]
    procedure Rows139()
    begin
        Dump(139, 144);
    end;

    [Test]
    procedure Rows145()
    begin
        Dump(145, 150);
    end;

}
