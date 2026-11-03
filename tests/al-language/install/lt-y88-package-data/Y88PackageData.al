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
        Observer.Finish();
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
        Observer.Finish();
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

    local procedure CalcText(No: Code[20]; Base: Date): Text
    var
        Row: Record "LT Y85 Pkg Types";
        Result: Date;
    begin
        Row.Get(No);
        Result := CalcDate(Row.Dfm, Base);
        exit(Format(Result, 0, 9));
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Y88_Enum_UndefinedOrdinal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('load', LogText('load', 'enum'));
        Observer.Observe('rows', EnumText());
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Y88_Decimal_OutOfRange()
    var
        Huge: Record "LT Y88 Pkg Dec Huge";
        Tiny: Record "LT Y88 Pkg Dec Tiny";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('huge load', LogText('load', 'decimal huge'));
        if Huge.FindSet() then
            repeat
                T += Huge."No." + '=' + Format(Huge.Dec, 0, 9) + ';';
            until Huge.Next() = 0;
        Observer.Observe('huge rows', T);
        Observer.Observe('tiny load', LogText('load', 'decimal tiny'));
        T := '';
        if Tiny.FindSet() then
            repeat
                T += Tiny."No." + '=' + Format(Tiny.Dec, 0, 9) + ';';
            until Tiny.Next() = 0;
        Observer.Observe('tiny rows', T);
        Observer.Finish();
    end;
}
