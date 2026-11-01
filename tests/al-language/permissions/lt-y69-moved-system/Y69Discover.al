// TEMPORARY discovery probe (writer Y69), removed before the PR.
codeunit 93739 "LT Y69 Discover"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y69_SystemObjects_0()
    begin
        Slice(0, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_1()
    begin
        Slice(30, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_2()
    begin
        Slice(60, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_3()
    begin
        Slice(90, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_4()
    begin
        Slice(120, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_5()
    begin
        Slice(150, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_6()
    begin
        Slice(180, 30);
    end;

    [Test]
    procedure Y69_SystemObjects_7()
    begin
        Slice(210, 30);
    end;

    local procedure Slice(Skip: Integer; Take: Integer)
    var
        Observer: Codeunit "Probe Observer";
        AllObj: Record AllObj;
        Result: Text;
        n: Integer;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::System);
        Observer.Observe('count', Format(AllObj.Count()));
        if AllObj.FindSet() then
            repeat
                n += 1;
                if (n > Skip) and (n <= Skip + Take) then
                    Result += Format(AllObj."Object ID") + '=' + AllObj."Object Name" + ';';
            until AllObj.Next() = 0;
        Observer.Observe('rows', Result);
        Observer.Finish();
    end;
}
