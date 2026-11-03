// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71502 "LT RcA NotFoundErrors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure NotFound_Errors_Main_Table()
    var
        R: Record "LT RcA Main";
    begin
        R.DeleteAll();
        asserterror R.Get(1);
        Observer.ObserveError('getEmpty');
        asserterror R.FindFirst();
        Observer.ObserveError('findFirstEmpty');
        asserterror R.FindLast();
        Observer.ObserveError('findLastEmpty');
        asserterror R.FindSet();
        Observer.ObserveError('findSetEmpty');
        asserterror R.FindSet(true);
        Observer.ObserveError('findSetUpdateEmpty');
        asserterror R.Find('-');
        Observer.ObserveError('findMinusEmpty');
        asserterror R.Find('=');
        Observer.ObserveError('findEqEmpty');
        R.Next();
        Observer.Observe('nextEmpty', 'no error');
        Observer.Expect('getEmpty|text', 'The LT RcA Main does not exist. Identification fields and values: No=''1''');
        Observer.Expect('getEmpty|code', 'DB:RecordNotFound');
        Observer.Expect('findFirstEmpty|text', 'The LT RcA Main table is empty.');
        Observer.Expect('findFirstEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findLastEmpty|text', 'The LT RcA Main table is empty.');
        Observer.Expect('findLastEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findSetEmpty|text', 'The LT RcA Main table is empty.');
        Observer.Expect('findSetEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findSetUpdateEmpty|text', 'The LT RcA Main table is empty.');
        Observer.Expect('findSetUpdateEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findMinusEmpty|text', 'The LT RcA Main table is empty.');
        Observer.Expect('findMinusEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findEqEmpty|text', 'The LT RcA Main does not exist. Identification fields and values: No=''0''');
        Observer.Expect('findEqEmpty|code', 'DB:RecordNotFound');
        Observer.Expect('nextEmpty', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure NotFound_Errors_With_Filters()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(No, 999);
        asserterror R.FindFirst();
        Observer.ObserveError('findFirstFiltered');
        R.SetRange(No);
        R.SetFilter(Name, 'zzz');
        asserterror R.FindFirst();
        Observer.ObserveError('findFirstTextFilter');
        R.Reset();
        R.SetRange(Cd, 'C1');
        R.SetRange(Flag, true);
        R.SetRange(Dt, DMY2Date(1, 1, 1999));
        asserterror R.FindFirst();
        Observer.ObserveError('findFirstThreeFilters');
        asserterror R.FindLast();
        Observer.ObserveError('findLastFiltered');
        asserterror R.FindSet();
        Observer.ObserveError('findSetFiltered');
        Observer.Expect('findFirstFiltered|text', 'There is no LT RcA Main within the filter.\\Filters: No: 999');
        Observer.Expect('findFirstFiltered|code', 'DB:NothingInsideFilter');
        Observer.Expect('findFirstTextFilter|text', 'There is no LT RcA Main within the filter.\\Filters: Name: zzz');
        Observer.Expect('findFirstTextFilter|code', 'DB:NothingInsideFilter');
        Observer.Expect('findFirstThreeFilters|text', 'There is no LT RcA Main within the filter.\\Filters: Cd: C1, Dt: 01/01/99, Flag: Yes');
        Observer.Expect('findFirstThreeFilters|code', 'DB:NothingInsideFilter');
        Observer.Expect('findLastFiltered|text', 'There is no LT RcA Main within the filter.\\Filters: Cd: C1, Dt: 01/01/99, Flag: Yes');
        Observer.Expect('findLastFiltered|code', 'DB:NothingInsideFilter');
        Observer.Expect('findSetFiltered|text', 'There is no LT RcA Main within the filter.\\Filters: Cd: C1, Dt: 01/01/99, Flag: Yes');
        Observer.Expect('findSetFiltered|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure NotFound_Errors_Get_Key_Shapes()
    var
        CK: Record "LT RcA CodeKey";
        TK: Record "LT RcA TextKey";
        DK: Record "LT RcA DecKey";
        DtK: Record "LT RcA DateKey";
        BK: Record "LT RcA BoolKey";
        OK: Record "LT RcA OptKey";
        EK: Record "LT RcA EnumKey";
        MK: Record "LT RcA Multi";
    begin
        Seed.Keys();
        asserterror CK.Get('nope');
        Observer.ObserveError('code');
        asserterror TK.Get('nope');
        Observer.ObserveError('text');
        asserterror DK.Get(77.7);
        Observer.ObserveError('decimal');
        asserterror DtK.Get(DMY2Date(9, 9, 2029));
        Observer.ObserveError('date');
        BK.DeleteAll();
        asserterror BK.Get(true);
        Observer.ObserveError('boolean');
        OK.DeleteAll();
        asserterror OK.Get(OK.Op::Beta);
        Observer.ObserveError('option');
        EK.DeleteAll();
        asserterror EK.Get(EK.En::Nine);
        Observer.ObserveError('enum');
        asserterror MK.Get('Z', 1, 0D);
        Observer.ObserveError('multi');
        asserterror CK.Get('');
        Observer.ObserveError('blankCode');
        Observer.Expect('code|text', 'The LT RcA CodeKey does not exist. Identification fields and values: Cd=''NOPE''');
        Observer.Expect('code|code', 'DB:RecordNotFound');
        Observer.Expect('text|text', 'The LT RcA TextKey does not exist. Identification fields and values: Tx=''nope''');
        Observer.Expect('text|code', 'DB:RecordNotFound');
        Observer.Expect('decimal|text', 'The LT RcA DecKey does not exist. Identification fields and values: Dc=''77.7''');
        Observer.Expect('decimal|code', 'DB:RecordNotFound');
        Observer.Expect('date|text', 'The LT RcA DateKey does not exist. Identification fields and values: Dt=''09/09/29''');
        Observer.Expect('date|code', 'DB:RecordNotFound');
        Observer.Expect('boolean|text', 'The LT RcA BoolKey does not exist. Identification fields and values: Bl=''Yes''');
        Observer.Expect('boolean|code', 'DB:RecordNotFound');
        Observer.Expect('option|text', 'The LT RcA OptKey does not exist. Identification fields and values: Op=''Beta''');
        Observer.Expect('option|code', 'DB:RecordNotFound');
        Observer.Expect('enum|text', 'The LT RcA EnumKey does not exist. Identification fields and values: En=''Nine''');
        Observer.Expect('enum|code', 'DB:RecordNotFound');
        Observer.Expect('multi|text', 'The LT RcA Multi does not exist. Identification fields and values: A=''Z'',B=''1'',C=''''');
        Observer.Expect('multi|code', 'DB:RecordNotFound');
        Observer.Expect('blankCode|text', 'The LT RcA CodeKey does not exist. Identification fields and values: Cd=''''');
        Observer.Expect('blankCode|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure NotFound_Errors_Get_With_Filters_Set()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(No, 500);
        Observer.Observe('getIgnoresFilter', Format(R.Get(20)));
        R.SetFilter(Name, 'zzz');
        asserterror R.Get(999);
        Observer.ObserveError('getMissFiltered');
        Observer.Expect('getIgnoresFilter', 'Yes');
        Observer.Expect('getMissFiltered|text', 'The LT RcA Main does not exist. Identification fields and values: No=''999''');
        Observer.Expect('getMissFiltered|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure NotFound_Errors_Without_Error_Using_Boolean_Form()
    var
        R: Record "LT RcA Main";
    begin
        R.DeleteAll();
        Observer.Observe('getBool', Format(R.Get(1)));
        Observer.Observe('getErrorEmpty', GetLastErrorText());
        Observer.Observe('findBool', Format(R.FindFirst()));
        Observer.Observe('findErrorEmpty', GetLastErrorText());
        Observer.Expect('getBool', 'No');
        Observer.Expect('getErrorEmpty', '');
        Observer.Expect('findBool', 'No');
        Observer.Expect('findErrorEmpty', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Read_Related()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(20);
        R.TestField(Name);
        R.TestField(Name, 'N9');
        asserterror R.TestField(Name, 'wrong');
        Observer.ObserveError('wrongValue');
        asserterror R.TestField(Amt, 0);
        Observer.ObserveError('amtNotZero');
        R.Amt := 0;
        asserterror R.TestField(Amt);
        Observer.ObserveError('amtZero');
        R.Tx := '';
        asserterror R.TestField(Tx);
        Observer.ObserveError('txBlank');
        R.Dt := 0D;
        asserterror R.TestField(Dt);
        Observer.ObserveError('dtBlank');
        R.Flag := false;
        asserterror R.TestField(Flag);
        Observer.ObserveError('flagFalse');
        R.Flag := true;
        R.TestField(Flag, true);
        asserterror R.TestField(Flag, false);
        Observer.ObserveError('flagWrongValue');
        R.Opt := R.Opt::Alpha;
        asserterror R.TestField(Opt);
        Observer.ObserveError('optFirst');
        asserterror R.TestField(Opt, R.Opt::Gamma);
        Observer.ObserveError('optWrong');
        R.En := R.En::Zero;
        asserterror R.TestField(En);
        Observer.ObserveError('enumZero');
        asserterror R.TestField(En, R.En::Nine);
        Observer.ObserveError('enumWrong');
        R.Cd := '';
        asserterror R.TestField(Cd);
        Observer.ObserveError('codeBlank');
        asserterror R.TestField(Cd, 'X');
        Observer.ObserveError('codeWrong');
        Observer.Expect('wrongValue|text', 'Name must be equal to ''wrong''  in LT RcA Main: No=20. Current value is ''N9''.');
        Observer.Expect('wrongValue|code', 'TestField');
        Observer.Expect('amtNotZero|text', 'Amt must be equal to ''0''  in LT RcA Main: No=20. Current value is ''3''.');
        Observer.Expect('amtNotZero|code', 'TestField');
        Observer.Expect('amtZero|text', 'Amt must have a value in LT RcA Main: No=20. It cannot be zero or empty.');
        Observer.Expect('amtZero|code', 'TestField');
        Observer.Expect('txBlank|text', 'Tx must have a value in LT RcA Main: No=20. It cannot be zero or empty.');
        Observer.Expect('txBlank|code', 'TestField');
        Observer.Expect('dtBlank|text', 'Dt must have a value in LT RcA Main: No=20. It cannot be zero or empty.');
        Observer.Expect('dtBlank|code', 'TestField');
        Observer.Expect('flagFalse|text', 'Flag must have a value in LT RcA Main: No=20. It cannot be zero or empty.');
        Observer.Expect('flagFalse|code', 'TestField');
        Observer.Expect('flagWrongValue|text', 'Flag must be equal to ''No''  in LT RcA Main: No=20. Current value is ''Yes''.');
        Observer.Expect('flagWrongValue|code', 'TestField');
        Observer.Expect('optFirst|text', 'Opt must not be Alpha in LT RcA Main: No=20');
        Observer.Expect('optFirst|code', 'TestField');
        Observer.Expect('optWrong|text', 'Opt must be equal to ''Gamma''  in LT RcA Main: No=20. Current value is ''Alpha''.');
        Observer.Expect('optWrong|code', 'TestField');
        Observer.Expect('enumZero|text', 'En must not be Zero in LT RcA Main: No=20');
        Observer.Expect('enumZero|code', 'TestField');
        Observer.Expect('enumWrong|text', 'En must be equal to ''Nine''  in LT RcA Main: No=20. Current value is ''Zero''.');
        Observer.Expect('enumWrong|code', 'TestField');
        Observer.Expect('codeBlank|text', 'Cd must have a value in LT RcA Main: No=20. It cannot be zero or empty.');
        Observer.Expect('codeBlank|code', 'TestField');
        Observer.Expect('codeWrong|text', 'Cd must be equal to ''X''  in LT RcA Main: No=20. Current value is ''''.');
        Observer.Expect('codeWrong|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Extra_Overloads()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(20);
        asserterror R.TestField(Name, 'x', ErrorInfo.Create('custom'));
        Observer.ObserveError('errorInfo');
        Observer.Expect('errorInfo|text', 'Name must be equal to ''x''  in LT RcA Main: No=20. Current value is ''N9''.');
        Observer.Expect('errorInfo|code', 'TestField');
        Observer.Verify();
    end;
}
