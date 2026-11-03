// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); fixtures of Y91XpFixtures.al, ports of Y91XpPorts.al
// Probe: writer Y91. Empty element forms on XML import: <x />, <x></x>, <x> </x> and other spellings of an empty or blank value, for a text element, a text attribute and a field element, with the variable (or the record field) holding an old value, with and without PreserveWhiteSpace.
// BC versions: 27-29

codeunit 94848 "LT Y91 Empty Forms Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_Empty_Default_1()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('selfclosed', Helper.Import(94833, 0, '<Root><A /><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('openclose', Helper.Import(94833, 0, '<Root><A></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('space', Helper.Import(94833, 0, '<Root><A> </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('twospaces', Helper.Import(94833, 0, '<Root><A>  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('padded', Helper.Import(94833, 0, '<Root><A>  x  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('charref', Helper.Import(94833, 0, '<Root><A>&#32;</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_empty', Helper.Import(94833, 0, '<Root><A><![CDATA[]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_space', Helper.Import(94833, 0, '<Root><A><![CDATA[ ]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('lf', Helper.Import(94833, 0, '<Root><A>' + Lf() + '</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('comment', Helper.Import(94833, 0, '<Root><A><!-- c --></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Empty_Default_2()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('plain', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_selfclosed', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_openclose', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y"></B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y"> </B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty', Helper.Import(94833, 0, '<Root><A>x</A><B Att="">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att=" ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_padded', Helper.Import(94833, 0, '<Root><A>x</A><B Att="  p  ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty_selfclosed', Helper.Import(94833, 0, '<Root><A>x</A><B Att="" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_missing', Helper.Import(94833, 0, '<Root><A>x</A><B>z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_selfclosed', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name /></Item></Root>'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Empty_Default_3()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('n_openclose', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name> </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_padded', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>  x  </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_charref', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>&#32;</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_cdata_space', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name><![CDATA[ ]]></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_missing', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_plain', Helper.Import(94833, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Empty_Preserve_1()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('selfclosed', Helper.Import(94834, 0, '<Root><A /><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('openclose', Helper.Import(94834, 0, '<Root><A></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('space', Helper.Import(94834, 0, '<Root><A> </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('twospaces', Helper.Import(94834, 0, '<Root><A>  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('padded', Helper.Import(94834, 0, '<Root><A>  x  </A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('charref', Helper.Import(94834, 0, '<Root><A>&#32;</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_empty', Helper.Import(94834, 0, '<Root><A><![CDATA[]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('cdata_space', Helper.Import(94834, 0, '<Root><A><![CDATA[ ]]></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('lf', Helper.Import(94834, 0, '<Root><A>' + Lf() + '</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('comment', Helper.Import(94834, 0, '<Root><A><!-- c --></A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Empty_Preserve_2()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('plain', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_selfclosed', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_openclose', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y"></B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('b_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y"> </B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty', Helper.Import(94834, 0, '<Root><A>x</A><B Att="">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att=" ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_padded', Helper.Import(94834, 0, '<Root><A>x</A><B Att="  p  ">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_empty_selfclosed', Helper.Import(94834, 0, '<Root><A>x</A><B Att="" /><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('att_missing', Helper.Import(94834, 0, '<Root><A>x</A><B>z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_selfclosed', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name /></Item></Root>'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Empty_Preserve_3()
    begin
        Helper.Seed();
        Helper.Seed();
        Observer.Observe('n_openclose', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name> </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_padded', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>  x  </Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_charref', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>&#32;</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_cdata_space', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name><![CDATA[ ]]></Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_missing', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id></Item></Root>'));
        Helper.Seed();
        Observer.Observe('n_plain', Helper.Import(94834, 0, '<Root><A>x</A><B Att="y">z</B><Item><Id>5</Id><Name>n</Name></Item></Root>'));
        Observer.Finish();
    end;

    local procedure Lf(): Text
    var
        Result: Text[1];
    begin
        Result[1] := 10;
        exit(Result);
    end;
}

codeunit 94849 "LT Y91 Root Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_Root_Xml_Export()
    begin
        Helper.Seed();
        Observer.Observe('export mode 0', Helper.Export(94836, 0));
        Observer.Observe('export mode 1', Helper.Export(94836, 1));
        Observer.Observe('export mode 2', Helper.Export(94836, 2));
        Observer.Observe('export mode 3', Helper.Export(94836, 3));
        Observer.Observe('export mode 4', Helper.Export(94836, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Root_Xml_Import()
    begin
        Helper.Seed();
        Observer.Observe('import mode 0', Helper.Import(94836, 0, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 1', Helper.Import(94836, 1, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 2', Helper.Import(94836, 2, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 3', Helper.Import(94836, 3, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Helper.Seed();
        Observer.Observe('import mode 4', Helper.Import(94836, 4, '<Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Root_VT_Export()
    begin
        Helper.Seed();
        Observer.Observe('export mode 0', Helper.Export(94837, 0));
        Observer.Observe('export mode 1', Helper.Export(94837, 1));
        Observer.Observe('export mode 2', Helper.Export(94837, 2));
        Observer.Observe('export mode 3', Helper.Export(94837, 3));
        Observer.Observe('export mode 4', Helper.Export(94837, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Root_VT_Import()
    begin
        Helper.Seed();
        Observer.Observe('import mode 0', Helper.Import(94837, 0, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 1', Helper.Import(94837, 1, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 2', Helper.Import(94837, 2, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 3', Helper.Import(94837, 3, '7,seven'));
        Helper.Seed();
        Observer.Observe('import mode 4', Helper.Import(94837, 4, '7,seven'));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Root_Fixed_Export()
    begin
        Helper.Seed();
        Observer.Observe('export mode 0', Helper.Export(94838, 0));
        Observer.Observe('export mode 1', Helper.Export(94838, 1));
        Observer.Observe('export mode 2', Helper.Export(94838, 2));
        Observer.Observe('export mode 3', Helper.Export(94838, 3));
        Observer.Observe('export mode 4', Helper.Export(94838, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Root_Fixed_Import()
    begin
        Helper.Seed();
        Observer.Observe('import mode 0', Helper.Import(94838, 0, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 1', Helper.Import(94838, 1, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 2', Helper.Import(94838, 2, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 3', Helper.Import(94838, 3, '   7seven '));
        Helper.Seed();
        Observer.Observe('import mode 4', Helper.Import(94838, 4, '   7seven '));
        Observer.Finish();
    end;

}

codeunit 94850 "LT Y91 Misc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";

    [Test]
    procedure Y91_Decimal_Export_Negative_Xml()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94839, 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Decimal_Export_Negative_Legacy()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94842, 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Decimal_Export_Negative_VT()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94840, 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Decimal_Export_Negative_Fixed()
    begin
        SeedDecimals();
        Observer.Observe('export', Helper.Export(94841, 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y91_Width_Text_Xml()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.Export(94843, 0));
        Observer.Observe('import long', Helper.Import(94843, 0, '<Root><T3>abcdefghij</T3><T0>abcdefghij</T0><T5 At4="abcdefghij">abcdefghij</T5></Root>'));
        Observer.Observe('import short', Helper.Import(94843, 0, '<Root><T3>a</T3><T0>a</T0><T5 At4="a">a</T5></Root>'));
        Observer.Observe('import empty', Helper.Import(94843, 0, '<Root><T3 /><T0 /><T5 At4="" /></Root>'));
        Observer.Observe('unbound long', Helper.Import(94844, 0, '<Root><Free>abcdefghij</Free></Root>'));
        Observer.Observe('unbound short', Helper.Import(94844, 0, '<Root><Free>a</Free></Root>'));
        Observer.Observe('unbound none', Helper.Import(94844, 0, '<Root></Root>'));
        Observer.Finish();
    end;

    local procedure SeedDecimals()
    var
        Item: Record "LT Y91 Item";
        Amounts: List of [Decimal];
        Amt: Decimal;
        i: Integer;
    begin
        Item.DeleteAll();
        Amounts.Add(-0.005);
        Amounts.Add(0.005);
        Amounts.Add(-0.015);
        Amounts.Add(0.015);
        Amounts.Add(-0.125);
        Amounts.Add(0.125);
        Amounts.Add(-1.005);
        Amounts.Add(-2.004);
        Amounts.Add(-2.5);
        Amounts.Add(-0.0049);
        Amounts.Add(-0.001);
        Amounts.Add(-1234.5678);
        Amounts.Add(-1234567.895);
        Amounts.Add(-0.995);
        Amounts.Add(-99999999.995);
        foreach Amt in Amounts do begin
            i += 1;
            Item.Init();
            Item.Id := i;
            Item.Name := 'd';
            Item.Amt := Amt;
            Item.Amt5 := Amt;
            Item.Insert();
        end;
        Commit();
    end;
}

codeunit 94851 "LT Y91 Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y91 Helper";
        Log: Codeunit "LT Y91 Run Log";

    [Test]
    procedure Y91_Run_WithoutStream()
    begin
        Seed();
        Observer.Observe('both static', RunPort(94845, 1, false));
        Observer.Observe('both static import', RunPort(94845, 1, true));
        Observer.Observe('both instance', RunPort(94845, 2, false));
        Observer.Observe('both view', RunPort(94845, 3, false));
        Observer.Observe('export static', RunPort(94846, 1, false));
        Observer.Observe('export static import', RunPort(94846, 1, true));
        Observer.Observe('export instance', RunPort(94846, 2, false));
        Observer.Observe('export view', RunPort(94846, 3, false));
        Observer.Observe('import static', RunPort(94847, 1, false));
        Observer.Observe('import static import', RunPort(94847, 1, true));
        Observer.Observe('import instance', RunPort(94847, 2, false));
        Observer.Finish();
    end;

    local procedure Seed()
    var
        Item: Record "LT Y91 Item";
    begin
        Item.DeleteAll();
        Item.Init();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Insert();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Insert();
        Commit();
        Log.Take();
    end;

    // ok or error:<text>|<code>, then the hits of the port triggers and the number of rows.
    local procedure RunPort(PortId: Integer; Mode: Integer; ImportFlag: Boolean): Text
    var
        Input: Record "LT Y91 Input" temporary;
        Item: Record "LT Y91 Item";
        Result: Text;
    begin
        Commit();
        Input.Init();
        Input.Id := 1;
        Input.PortId := PortId;
        Input.Mode := Mode;
        Input.ImportFlag := ImportFlag;
        Input.Insert();
        ClearLastError();
        if Codeunit.Run(Codeunit::"LT Y91 Run Runner", Input) then
            Result := 'ok'
        else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        Result += ' hits=' + Log.Take() + ' rows=' + Format(Item.Count());
        exit(Result);
    end;
}

