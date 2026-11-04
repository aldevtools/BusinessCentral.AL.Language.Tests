// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT Y17 AF *); System tables Currency and General Ledger Setup
// Probe (gap cycle 1, G5): Format in code of a table field with AutoFormatType 1 or 2 whose AutoFormatExpression is a PROCEDURE of the table that
//   returns a currency code (the Reminder Line GetCurrencyCodeFromHeader, G/L Entry GetAdditionalReportingCurrencyCode and Bank Acc.
//   Reconciliation GetCurrencyCode shapes): whether, how often and on which record the procedure runs, the text, StrSubstNo and Format(x, 0, n),
//   DecimalPlaces beside an AutoFormat, a plain page control over such a field, and an error inside the procedure.
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 91790 "LT Y17 AF Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Currency Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 91792 "LT Y17 AF Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Currency Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 91791 "LT Y17 AF Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; A1Hdr; Decimal) { AutoFormatType = 1; AutoFormatExpression = GetCurrencyCodeFromHeader(); }
        field(4; A2Hdr; Decimal) { AutoFormatType = 2; AutoFormatExpression = GetCurrencyCodeFromHeader(); }
        field(5; A2Local; Decimal) { AutoFormatType = 2; AutoFormatExpression = LocalCurrency(); }
        field(6; A1Setup; Decimal) { AutoFormatType = 1; AutoFormatExpression = GetSetupCurrency(); }
        field(7; A1Dp; Decimal) { DecimalPlaces = 2 : 5; AutoFormatType = 1; AutoFormatExpression = Rec."Doc Currency"; }
        field(8; A1DpProc; Decimal) { DecimalPlaces = 0 : 5; AutoFormatType = 1; AutoFormatExpression = GetCurrencyCodeFromHeader(); }
        field(9; "Doc Currency"; Code[10]) { }
        field(10; AErr; Decimal) { AutoFormatType = 1; AutoFormatExpression = FailingCurrency(); }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    var
        Hdr: Record "LT Y17 AF Header";
        Setup: Record "LT Y17 AF Setup";
        SetupRead: Boolean;

    procedure GetCurrencyCodeFromHeader(): Code[10]
    var
        Log: Codeunit "LT Y17 AF Log";
    begin
        Log.Add('hdr(' + Rec."Doc No." + ')');
        if Rec."Doc No." = Hdr."No." then
            exit(Hdr."Currency Code");
        if Hdr.Get(Rec."Doc No.") then
            exit(Hdr."Currency Code");
        exit('');
    end;

    local procedure LocalCurrency(): Code[10]
    var
        LocalHdr: Record "LT Y17 AF Header";
        Log: Codeunit "LT Y17 AF Log";
    begin
        Log.Add('local(' + Rec."Doc No." + ')');
        if LocalHdr.Get(Rec."Doc No.") then
            exit(LocalHdr."Currency Code");
        exit('');
    end;

    procedure GetSetupCurrency(): Code[10]
    var
        Log: Codeunit "LT Y17 AF Log";
    begin
        Log.Add('setup(' + Rec."Doc No." + ')');
        if not SetupRead then begin
            Setup.Get();
            SetupRead := true;
            Log.Add('setupget');
        end;
        exit(Setup."Currency Code");
    end;

    procedure FailingCurrency(): Code[10]
    var
        Log: Codeunit "LT Y17 AF Log";
    begin
        Log.Add('fail(' + Rec."Doc No." + ')');
        if Rec."Doc No." = 'HE' then
            Error('AF failed');
        exit('');
    end;
}

codeunit 91793 "LT Y17 AF Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 91794 "LT Y17 AF Line Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 AF Line";

    layout
    {
        area(Content)
        {
            field(DocNo; Rec."Doc No.") { ApplicationArea = All; }
            field(A1Hdr; Rec.A1Hdr) { ApplicationArea = All; }
            field(A2Hdr; Rec.A2Hdr) { ApplicationArea = All; }
        }
    }
}

codeunit 91795 "LT Y17 AF Procedure"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y17 AF Log";
        SavedAmountPlaces: Text;
        SavedUnitPlaces: Text;
        SavedShowCurrency: Enum "Show Currency";

    local procedure SetSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        SavedAmountPlaces := GLSetup."Amount Decimal Places";
        SavedUnitPlaces := GLSetup."Unit-Amount Decimal Places";
        SavedShowCurrency := GLSetup."Show Currency";
        GLSetup."Amount Decimal Places" := '2:2';
        GLSetup."Unit-Amount Decimal Places" := '2:5';
        GLSetup."Show Currency" := "Show Currency"::Never;
        GLSetup.Modify();
    end;

    // The BC 27.5 test runner commits what a test leaves (autoformat/PWAutoFormatTypes.al RestoreSetup), so every test puts the setup back.
    local procedure RestoreSetup()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if Currency.Get('Y17C') then
            Currency.Delete();
        if not GLSetup.Get() then
            exit;
        GLSetup."Amount Decimal Places" := CopyStr(SavedAmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(SavedUnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := SavedShowCurrency;
        GLSetup.Modify();
    end;

    local procedure Seed()
    var
        Currency: Record Currency;
        Hdr: Record "LT Y17 AF Header";
        Line: Record "LT Y17 AF Line";
        Setup: Record "LT Y17 AF Setup";
    begin
        SetSetup();
        if Currency.Get('Y17C') then
            Currency.Delete();
        Currency.Init();
        Currency.Code := 'Y17C';
        Currency."Amount Decimal Places" := '3:3';
        Currency."Unit-Amount Decimal Places" := '4:4';
        Currency.Insert();
        if Currency.Get('Y17NOPE') then
            Currency.Delete();
        Hdr.DeleteAll();
        Line.DeleteAll();
        Setup.DeleteAll();
        AddHdr('H1', 'Y17C');
        AddHdr('H2', '');
        AddHdr('H3', 'Y17NOPE');
        Setup.Init();
        Setup."Currency Code" := 'Y17C';
        Setup.Insert();
        AddLine('H1', 'Y17C');
        AddLine('H2', '');
        AddLine('H3', 'Y17NOPE');
        AddLine('HX', '');
        AddLine('HE', '');
        Log.Reset();
    end;

    local procedure AddHdr(No: Code[20]; CurrencyCode: Code[10])
    var
        Hdr: Record "LT Y17 AF Header";
    begin
        Hdr.Init();
        Hdr."No." := No;
        Hdr."Currency Code" := CurrencyCode;
        Hdr.Insert();
    end;

    local procedure AddLine(DocNo: Code[20]; DocCurrency: Code[10])
    var
        Line: Record "LT Y17 AF Line";
    begin
        Line.Init();
        Line."Doc No." := DocNo;
        Line."Line No." := 1;
        Line.A1Hdr := 1234.56789;
        Line.A2Hdr := 1234.56789;
        Line.A2Local := 1234.56789;
        Line.A1Setup := 1234.56789;
        Line.A1Dp := 1234.56789;
        Line.A1DpProc := 1234.56789;
        Line.AErr := 1234.56789;
        Line."Doc Currency" := DocCurrency;
        Line.Insert();
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Tag: Text; Value: Text)
    begin
        Observer.Observe(Tag, Value);
        Observer.Observe(Tag + ' log', Log.Take());
    end;

    [Test]
    procedure AF_Proc_T1_Header()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.SetFilter("Doc No.", '<>HE');
        Line.FindSet();
        Log.Reset();
        repeat
            Obs(Observer, 'A1Hdr ' + Line."Doc No.", Format(Line.A1Hdr));
        until Line.Next() = 0;
        RestoreSetup();
        Observer.Expect('A1Hdr H1', '1,234.568');
        Observer.Expect('A1Hdr H1 log', 'hdr(H1);');
        Observer.Expect('A1Hdr H2', '1,234.57');
        Observer.Expect('A1Hdr H2 log', 'hdr(H2);');
        Observer.Expect('A1Hdr H3', '1,234.57');
        Observer.Expect('A1Hdr H3 log', 'hdr(H3);');
        Observer.Expect('A1Hdr HX', '1,234.57');
        Observer.Expect('A1Hdr HX log', 'hdr(HX);');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Proc_T2_Header()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.SetFilter("Doc No.", '<>HE');
        Line.FindSet();
        Log.Reset();
        repeat
            Obs(Observer, 'A2Hdr ' + Line."Doc No.", Format(Line.A2Hdr));
        until Line.Next() = 0;
        RestoreSetup();
        Observer.Expect('A2Hdr H1', '1,234.5679');
        Observer.Expect('A2Hdr H1 log', 'hdr(H1);');
        Observer.Expect('A2Hdr H2', '1,234.56789');
        Observer.Expect('A2Hdr H2 log', 'hdr(H2);');
        Observer.Expect('A2Hdr H3', '1,234.56789');
        Observer.Expect('A2Hdr H3 log', 'hdr(H3);');
        Observer.Expect('A2Hdr HX', '1,234.56789');
        Observer.Expect('A2Hdr HX log', 'hdr(HX);');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Proc_T2_LocalProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.SetFilter("Doc No.", '<>HE');
        Line.FindSet();
        Log.Reset();
        repeat
            Obs(Observer, 'A2Local ' + Line."Doc No.", Format(Line.A2Local));
        until Line.Next() = 0;
        RestoreSetup();
        Observer.Expect('A2Local H1', '1,234.5679');
        Observer.Expect('A2Local H1 log', 'local(H1);');
        Observer.Expect('A2Local H2', '1,234.56789');
        Observer.Expect('A2Local H2 log', 'local(H2);');
        Observer.Expect('A2Local H3', '1,234.56789');
        Observer.Expect('A2Local H3 log', 'local(H3);');
        Observer.Expect('A2Local HX', '1,234.56789');
        Observer.Expect('A2Local HX log', 'local(HX);');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Proc_T1_SetupCached()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
        Line2: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.Get('H1', 1);
        Line2.Get('H2', 1);
        Log.Reset();
        Obs(Observer, 'first', Format(Line.A1Setup));
        Obs(Observer, 'second same var', Format(Line.A1Setup));
        Obs(Observer, 'other var', Format(Line2.A1Setup));
        Obs(Observer, 'direct call same var', Line.GetSetupCurrency());
        RestoreSetup();
        Observer.Expect('first', '1,234.568');
        Observer.Expect('first log', 'setup(H1);setupget;');
        Observer.Expect('second same var', '1,234.568');
        Observer.Expect('second same var log', 'setup(H1);');
        Observer.Expect('other var', '1,234.568');
        Observer.Expect('other var log', 'setup(H2);setupget;');
        Observer.Expect('direct call same var', 'Y17C');
        Observer.Expect('direct call same var log', 'setup(H1);');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Proc_StrSubstNo()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.Get('H1', 1);
        Log.Reset();
        Obs(Observer, 'strsubstno', StrSubstNo('%1', Line.A1Hdr));
        Obs(Observer, 'format 0 1', Format(Line.A1Hdr, 0, 1));
        Obs(Observer, 'format 0 2', Format(Line.A1Hdr, 0, 2));
        Obs(Observer, 'format 0 9', Format(Line.A1Hdr, 0, 9));
        Obs(Observer, 'format t2 strsubstno', StrSubstNo('%1', Line.A2Hdr));
        RestoreSetup();
        Observer.Expect('strsubstno', '1,234.568');
        Observer.Expect('strsubstno log', 'hdr(H1);');
        Observer.Expect('format 0 1', '1234.568');
        Observer.Expect('format 0 1 log', 'hdr(H1);');
        Observer.Expect('format 0 2', '1234.568');
        Observer.Expect('format 0 2 log', 'hdr(H1);');
        Observer.Expect('format 0 9', '1234.568');
        Observer.Expect('format 0 9 log', 'hdr(H1);');
        Observer.Expect('format t2 strsubstno', '1,234.5679');
        Observer.Expect('format t2 strsubstno log', 'hdr(H1);');
        Observer.Verify();
    end;

    [Test]
    procedure AF_DecimalPlaces_T1_FieldOfRow()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.Get('H1', 1);
        Obs(Observer, 'cur Y17C', Format(Line.A1Dp));
        Line."Doc Currency" := '';
        Obs(Observer, 'cur blank', Format(Line.A1Dp));
        Line."Doc Currency" := 'Y17NOPE';
        Obs(Observer, 'cur nope', Format(Line.A1Dp));
        Line.A1Dp := 0.01;
        Line."Doc Currency" := 'Y17C';
        Obs(Observer, '0.01 cur Y17C', Format(Line.A1Dp));
        Line."Doc Currency" := '';
        Obs(Observer, '0.01 cur blank', Format(Line.A1Dp));
        Line.A1Dp := 0.00001;
        Obs(Observer, '0.00001 cur blank', Format(Line.A1Dp));
        Line."Doc Currency" := 'Y17C';
        Obs(Observer, '0.00001 cur Y17C', Format(Line.A1Dp));
        RestoreSetup();
        Observer.Expect('cur Y17C', '1,234.568');
        Observer.Expect('cur Y17C log', '');
        Observer.Expect('cur blank', '1,234.57');
        Observer.Expect('cur blank log', '');
        Observer.Expect('cur nope', '1,234.57');
        Observer.Expect('cur nope log', '');
        Observer.Expect('0.01 cur Y17C', '0.010');
        Observer.Expect('0.01 cur Y17C log', '');
        Observer.Expect('0.01 cur blank', '0.01');
        Observer.Expect('0.01 cur blank log', '');
        Observer.Expect('0.00001 cur blank', '0.00');
        Observer.Expect('0.00001 cur blank log', '');
        Observer.Expect('0.00001 cur Y17C', '0.000');
        Observer.Expect('0.00001 cur Y17C log', '');
        Observer.Verify();
    end;

    [Test]
    procedure AF_DecimalPlaces_T1_Procedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
    begin
        Seed();
        Line.Get('H1', 1);
        Log.Reset();
        Obs(Observer, 'H1', Format(Line.A1DpProc));
        Line.Get('H2', 1);
        Obs(Observer, 'H2', Format(Line.A1DpProc));
        Line.A1DpProc := 0.00001;
        Obs(Observer, 'H2 0.00001', Format(Line.A1DpProc));
        RestoreSetup();
        Observer.Expect('H1', '1,234.568');
        Observer.Expect('H1 log', 'hdr(H1);');
        Observer.Expect('H2', '1,234.57');
        Observer.Expect('H2 log', 'hdr(H2);');
        Observer.Expect('H2 0.00001', '0.00');
        Observer.Expect('H2 0.00001 log', 'hdr(H2);');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Proc_Control_Card()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
        Card: TestPage "LT Y17 AF Line Card";
    begin
        Seed();
        Line.SetFilter("Doc No.", 'H1|H2');
        Log.Reset();
        Card.Trap();
        Page.Run(Page::"LT Y17 AF Line Card", Line);
        Observer.Observe('after open', Log.Take());
        Obs(Observer, 'row', Card.DocNo.Value());
        Obs(Observer, 'A1Hdr', Card.A1Hdr.Value());
        Obs(Observer, 'A2Hdr', Card.A2Hdr.Value());
        Obs(Observer, 'next', Format(Card.Next()));
        Obs(Observer, 'row2', Card.DocNo.Value());
        Obs(Observer, 'A1Hdr row2', Card.A1Hdr.Value());
        Obs(Observer, 'A2Hdr row2', Card.A2Hdr.Value());
        Card.Close();
        Observer.Observe('after close', Log.Take());
        RestoreSetup();
        Observer.Expect('after open', 'hdr();hdr();hdr(H1);hdr(H1);');
        Observer.Expect('row', 'H1');
        Observer.Expect('row log', '');
        Observer.Expect('A1Hdr', '1,234.568');
        Observer.Expect('A1Hdr log', '');
        Observer.Expect('A2Hdr', '1,234.5679');
        Observer.Expect('A2Hdr log', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', 'hdr(H2);hdr(H2);');
        Observer.Expect('row2', 'H2');
        Observer.Expect('row2 log', '');
        Observer.Expect('A1Hdr row2', '1,234.57');
        Observer.Expect('A1Hdr row2 log', '');
        Observer.Expect('A2Hdr row2', '1,234.56789');
        Observer.Expect('A2Hdr row2 log', '');
        Observer.Expect('after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Proc_Error()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT Y17 AF Line";
        Other: Record "LT Y17 AF Line";
        Txt: Text;
    begin
        Seed();
        Other.Get('H1', 1);
        Line.Get('HE', 1);
        Log.Reset();
        Txt := 'unset';
        ClearLastError();
        asserterror Txt := Format(Line.AErr);
        Observer.ObserveError('format error');
        Observer.Observe('txt', Txt);
        Observer.Observe('log', Log.Take());
        Obs(Observer, 'no error row', Format(Other.AErr));
        RestoreSetup();
        Observer.Expect('format error|text', 'AF failed');
        Observer.Expect('format error|code', 'Dialog');
        Observer.Expect('txt', 'unset');
        Observer.Expect('log', 'fail(HE);');
        Observer.Expect('no error row', '1,234.57');
        Observer.Expect('no error row log', 'fail(H1);');
        Observer.Verify();
    end;
}
