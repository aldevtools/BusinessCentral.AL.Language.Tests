// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-loadpackagedata-method
// Scope: in-scope
// Fixtures used: tests/al-language-xapp-a/Y88XaPackageData.al (tables 94680-94690, enum 94685, event subscribers 94691) with the data files TAB94680 and
//   TAB94683-TAB94690.navxdata, the install codeunit 94682 in Y8XaInstallOrder.al, and the Y85 package data (tables 94441); Probe Observer (69160).
// Probe (writer Y88, needs-probe list of the al-runner navx lane): what NavApp.LoadPackageData does with table events, with a DateFormula it loaded
//   (Format 0/1/2, CalcDate), and with values in the data file that the field cannot hold (undefined Option and Enum ordinals, the last Date and Decimal at the ends
//   of the range). Loading from upgrade code cannot be observed: an upgrade codeunit does not run on the first install of the corpus app.
// BC versions: 27 - 29
codeunit 94700 "LT Y88 Package Data"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LogText(Kind: Text; Subject: Text): Text
    var
        Log: Record "LT Y88 Pkg Log";
        T: Text;
    begin
        Log.SetRange(Kind, Kind);
        if Subject <> '' then
            Log.SetRange(Subject, Subject);
        if Log.FindSet() then
            repeat
                T += Log.Subject + ' -> ' + Log.Detail + ';';
            until Log.Next() = 0;
        exit(T);
    end;

    [Test]
    procedure Y88_Events_LoadRaisesNoTableEvent()
    var
        Row: Record "LT Y88 Pkg Events";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('load', LogText('load', 'events'));
        Observer.Observe('events during load', LogText('event', ''));
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Expect('load', 'events -> ok;');
        Observer.Expect('events during load', '');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Events_SubscribersWorkForOrdinaryWrites()
    var
        Row: Record "LT Y88 Pkg Events";
        Log: Record "LT Y88 Pkg Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetRange(Kind, 'event');
        Log.DeleteAll();
        Row.Get('A1');
        Row.Validate(Description, 'changed');
        Row.Modify(true);
        Row."No." := 'A3';
        Row.Insert(true);
        Observer.Observe('events', LogText('event', ''));
        Log.SetRange(Kind, 'event');
        Log.DeleteAll();
        Row.Delete();
        Row.Get('A1');
        Row.Description := 'one';
        Row.Modify();
        Observer.Expect('events', 'before validate -> A1=changed;after validate -> A1=changed;before modify Yes -> A1=changed;before insert Yes -> A3=changed;after insert Yes -> A3=changed;');
        Observer.Verify();
    end;

    local procedure DfmText(No: Code[20]): Text
    var
        Row: Record "LT Y85 Pkg Types";
        Formula: DateFormula;
    begin
        Row.Get(No);
        Formula := Row.Dfm;
        exit(Format(Row.Dfm) + '|' + Format(Row.Dfm, 0, 1) + '|' + Format(Row.Dfm, 0, 2) + '|' + Format(Row.Dfm, 0, 9) + '|' + Format(Formula) + '|' + Format(Formula, 0, 1));
    end;

    [TryFunction]
    local procedure TryCalc(No: Code[20]; Base: Date; var Result: Date)
    var
        Row: Record "LT Y85 Pkg Types";
    begin
        Row.Get(No);
        Result := CalcDate(Row.Dfm, Base);
    end;

    local procedure CalcText(No: Code[20]; Base: Date): Text
    var
        Result: Date;
    begin
        ClearLastError();
        if TryCalc(No, Base, Result) then
            exit(Format(Result, 0, 9));
        exit('error ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

    [Test]
    procedure Y88_DateFormula_Format()
    var
        Observer: Codeunit "Probe Observer";
        Formula: DateFormula;
    begin
        Observer.Observe('T1 loaded <CM+1D>', DfmText('T1'));
        Observer.Observe('T2 loaded 1D', DfmText('T2'));
        Observer.Observe('T3 loaded empty', DfmText('T3'));
        Evaluate(Formula, '<CM+1D>');
        Observer.Observe('evaluated <CM+1D>', Format(Formula) + '|' + Format(Formula, 0, 1) + '|' + Format(Formula, 0, 2) + '|' + Format(Formula, 0, 9));
        Evaluate(Formula, '1D');
        Observer.Observe('evaluated 1D', Format(Formula) + '|' + Format(Formula, 0, 1) + '|' + Format(Formula, 0, 2) + '|' + Format(Formula, 0, 9));
        Observer.Expect('T1 loaded <CM+1D>', '<CM+1D>|<CM+1D>|<<CM+1D>>|<CM+1D>|<CM+1D>|<CM+1D>');
        Observer.Expect('T2 loaded 1D', '1D|1D|<1D>|1D|1D|1D');
        Observer.Expect('T3 loaded empty', '||<>|||');
        Observer.Expect('evaluated <CM+1D>', 'CM+1D|CM+1D|<CM+1D>|CM+1D');
        Observer.Expect('evaluated 1D', '1D|1D|<1D>|1D');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_DateFormula_CalcDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T1 from 2025-01-15', CalcText('T1', DMY2Date(15, 1, 2025)));
        Observer.Observe('T1 from 2025-01-31', CalcText('T1', DMY2Date(31, 1, 2025)));
        Observer.Observe('T2 from 2025-01-15', CalcText('T2', DMY2Date(15, 1, 2025)));
        Observer.Observe('T2 from 2025-01-31', CalcText('T2', DMY2Date(31, 1, 2025)));
        Observer.Observe('T3 from 2025-01-15', CalcText('T3', DMY2Date(15, 1, 2025)));
        Observer.Observe('T3 from 0D', CalcText('T3', 0D));
        Observer.Finish();
    end;

    local procedure OptionText(): Text
    var
        Row: Record "LT Y88 Pkg Option";
        T: Text;
    begin
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Format(Row.Opt, 0, 9) + '/' + Format(Row.Opt) + '/' + Format(Row.Opt, 0, 2) + ';';
            until Row.Next() = 0;
        exit(T);
    end;

    local procedure EnumText(): Text
    var
        Row: Record "LT Y88 Pkg Enum Table";
        T: Text;
    begin
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Format(Row.Enm, 0, 9) + '/' + Format(Row.Enm) + '/' + Format(Row.Enm.AsInteger()) + ';';
            until Row.Next() = 0;
        exit(T);
    end;

    [Test]
    procedure Y88_Option_UndefinedOrdinal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('load', LogText('load', 'option'));
        Observer.Observe('rows', OptionText());
        Observer.Expect('load', 'option -> ok;');
        Observer.Expect('rows', 'R0=1/One/1;R1=7/7/7;R2=2/Two/2;');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Enum_UndefinedOrdinal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('load', LogText('load', 'enum'));
        Observer.Observe('rows', EnumText());
        Observer.Expect('load', 'enum -> ok;');
        Observer.Expect('rows', 'E0=5/Five/5;E1=9/9/9;E2=7/Seven Up/7;E3=-1/-1/-1;E4=0/Zero/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Date_LastDay()
    var
        High: Record "LT Y88 Pkg Date High";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('high load', LogText('load', 'date high'));
        if High.FindSet() then
            repeat
                T += High."No." + '=' + Format(High.Dat, 0, 9) + ';';
            until High.Next() = 0;
        Observer.Observe('high rows', T);
        Observer.Expect('high load', 'date high -> ok;');
        Observer.Expect('high rows', 'D0=2025-06-01;D1=9999-12-31;D2=2025-06-02;');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Decimal_OutOfRange()
    var
        Tiny: Record "LT Y88 Pkg Dec Tiny";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('tiny load', LogText('load', 'decimal tiny'));
        T := '';
        if Tiny.FindSet() then
            repeat
                T += Tiny."No." + '=' + Format(Tiny.Dec, 0, 9) + ';';
            until Tiny.Next() = 0;
        Observer.Observe('tiny rows', T);
        Observer.Expect('tiny load', 'decimal tiny -> ok;');
        Observer.Expect('tiny rows', 'C0=5;C1=0;C2=6;');
        Observer.Verify();
    end;
}
