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
        Dump(1, 10);
    end;

    [Test]
    procedure Rows011()
    begin
        Dump(11, 20);
    end;

    [Test]
    procedure Rows021()
    begin
        Dump(21, 30);
    end;

    [Test]
    procedure Rows031()
    begin
        Dump(31, 40);
    end;

    [Test]
    procedure Rows041()
    begin
        Dump(41, 50);
    end;

    [Test]
    procedure Rows051()
    begin
        Dump(51, 60);
    end;

    [Test]
    procedure Rows061()
    begin
        Dump(61, 70);
    end;

    [Test]
    procedure Rows071()
    begin
        Dump(71, 80);
    end;

    [Test]
    procedure Rows081()
    begin
        Dump(81, 90);
    end;

    [Test]
    procedure Rows091()
    begin
        Dump(91, 100);
    end;

    [Test]
    procedure Rows101()
    begin
        Dump(101, 110);
    end;

    [Test]
    procedure Rows111()
    begin
        Dump(111, 120);
    end;

    [Test]
    procedure Rows121()
    begin
        Dump(121, 130);
    end;

    [Test]
    procedure Rows131()
    begin
        Dump(131, 140);
    end;

    [Test]
    procedure Rows141()
    begin
        Dump(141, 146);
    end;
}
