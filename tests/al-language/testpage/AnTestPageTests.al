// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 79400-79403, log codeunit 79404, pages 79410-79416 (AnObjects.al)
// Probe: every literal asserted below is what BC 29.0.54011.55816 produced in the corpus CI (Linux container); BC 27 and 28 are checked by the CI legs.
// Settles corpus issue 640 (TestPage behavior, part 1), items 1, 2, 8, 10, 11, 14, 15, 16 and 19.
// Facts: SetValue of a Decimal with three decimals outside MinValue/MaxValue of a page variable control (text, code, value afterwards);
// how often and in which order a part's rows are read when the host opens (const and field() SubPageLink, 1 and 5 rows);
// Date control SetValue of 't', 'today', 'workdate', 'W', 'T'; Clear of a TestPage over a part page; OnFindRecord/OnNextRecord/OnAfterGetRecord
// after an action deletes the current row; the start row and result of a TableRelation lookup; Lookup with no lookup page and no handler;
// Duration SetValue of '-' and '1,5 hours'; the caption of a table field whose CaptionClass is 'X,Y'.

codeunit 79450 "LT AN TestPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LookupStart: Text;
        LookupPick: Code[20];

    local procedure Seed()
    var
        Row: Record "LT AN Row";
        Related: Record "LT AN Related";
        Pageless: Record "LT AN Pageless";
        Line: Record "LT AN Line";
        i: Integer;
    begin
        Row.DeleteAll();
        Related.DeleteAll();
        Pageless.DeleteAll();
        Line.DeleteAll();
        Row."Code" := 'FIVE';
        Row.Insert();
        Row."Code" := 'ONE';
        Row.Insert();
        for i := 1 to 5 do begin
            Related."Code" := 'R' + Format(i);
            Related.Name := 'Related ' + Format(i);
            Related.Insert();
        end;
        Pageless."Code" := 'PL-A';
        Pageless.Insert();
        Line.Doc := 'ONE';
        Line."Line No." := 10;
        Line.Insert();
        for i := 1 to 5 do begin
            Line.Doc := 'FIVE';
            Line."Line No." := i * 10;
            Line.Insert();
        end;
    end;

    local procedure OpenCard(var P: TestPage "LT AN Card")
    var
        Row: Record "LT AN Row";
    begin
        Row.Get('ONE');
        P.OpenEdit();
        P.GoToRecord(Row);
    end;

    [TryFunction]
    local procedure TrySetDec(var P: TestPage "LT AN Card"; V: Decimal)
    begin
        P.DecVar.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetDate(var P: TestPage "LT AN Card"; V: Text)
    begin
        P.DateVar.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetDur(var P: TestPage "LT AN Card"; V: Text)
    begin
        P.DurVar.SetValue(V);
    end;

    // ---- item 1: Decimal with more than two decimals outside the bounds of a page variable control (MinValue 2, MaxValue 5) ----

    local procedure Dec(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AN Card"; Name: Text; V: Decimal)
    begin
        P.DecVar.SetValue(3);
        if TrySetDec(P, V) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + '.after', P.DecVar.Value());
    end;

    [Test]
    procedure An01_DecimalBounds_MoreThanTwoDecimals()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Card";
    begin
        Seed();
        // The decimal places of the value in the message follow General Ledger Setup "Amount Decimal Places" as the session first
        // read it (diagnostic runs 39255002308 and 39256045991); SelectLatestVersion makes the test independent of earlier tests
        // that set '2:5' and roll it back (bump 27: 'Value: 1.234.' on BC 27.5 after such a test).
        SelectLatestVersion();
        OpenCard(P);
        Dec(Observer, P, 'below1.234', 1.234);
        Dec(Observer, P, 'below1.996', 1.996);
        Dec(Observer, P, 'above5.004', 5.004);
        Dec(Observer, P, 'above5.006', 5.006);
        Dec(Observer, P, 'inside3.456', 3.456);
        P.Close();
        Observer.Expect('below1.234|text', 'Validation error for Field: DecVar,  Message = ''The value must be greater than or equal to 2. Value: 1.23.''');
        Observer.Expect('below1.234|code', 'TestValidation');
        Observer.Expect('below1.234.after', '3.00');
        Observer.Expect('below1.996', 'ok');
        Observer.Expect('below1.996.after', '2.00');
        Observer.Expect('above5.004', 'ok');
        Observer.Expect('above5.004.after', '5.00');
        Observer.Expect('above5.006|text', 'Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 5. Value: 5.01.''');
        Observer.Expect('above5.006|code', 'TestValidation');
        Observer.Expect('above5.006.after', '3.00');
        Observer.Expect('inside3.456', 'ok');
        Observer.Expect('inside3.456.after', '3.46');
        Observer.Verify();
    end;

    // ---- item 2: how the part's rows are read when the host opens ----

    local procedure RunHost(PageId: Integer; HostCode: Code[20])
    var
        Row: Record "LT AN Row";
    begin
        Row.Get(HostCode);
        Page.Run(PageId, Row);
    end;

    [Test]
    procedure An02_Part_ConstLink_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Const One";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Const One", 'ONE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'P.Open;H.RONE;P.R10;P.R10;P.C10;');
        Observer.Expect('partRow', '10');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure An02_Part_ConstLink_FiveRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Const Five";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Const Five", 'ONE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'P.Open;H.RONE;P.R10;P.R20;P.R30;P.R40;P.R50;P.R10;P.R10;P.C10;');
        Observer.Expect('partRow', '10');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure An02_Part_FieldLink_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Field";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Field", 'ONE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'P.Open;H.RONE;P.R10;P.R10;P.C10;');
        Observer.Expect('partRow', '10');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure An02_Part_FieldLink_FiveRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        Host: TestPage "LT AN Host Field";
    begin
        Seed();
        Log.Take();
        Host.Trap();
        RunHost(Page::"LT AN Host Field", 'FIVE');
        Observer.Observe('open', Log.Take());
        Observer.Observe('partRow', Host.Lines."Line No.".Value());
        Host.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'P.Open;H.RFIVE;P.R10;P.R20;P.R30;P.R40;P.R50;P.R10;P.R10;P.C10;');
        Observer.Expect('partRow', '10');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    // ---- item 8: Date control SetValue of the date shorthands, WorkDate 5 March 2026 ----

    local procedure DateShort(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AN Card"; V: Text)
    var
        D: Date;
    begin
        P.DateVar.SetValue(DMY2Date(1, 1, 2020));
        if not TrySetDate(P, V) then begin
            Observer.ObserveError('[' + V + ']');
            Observer.Observe('[' + V + '].after', P.DateVar.Value());
            exit;
        end;
        D := P.DateVar.AsDate();
        // Today is not asserted as a date (the run date changes); the probe records whether the control holds Today.
        if D = Today() then
            Observer.Observe('[' + V + ']', 'Today')
        else
            Observer.Observe('[' + V + ']', Format(D, 0, 9) + ' shows=' + P.DateVar.Value());
    end;

    [Test]
    procedure An08_DateShorthands()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Card";
        Saved: Date;
    begin
        Seed();
        Saved := WorkDate();
        WorkDate(DMY2Date(5, 3, 2026));
        OpenCard(P);
        DateShort(Observer, P, 't');
        DateShort(Observer, P, 'T');
        DateShort(Observer, P, 'today');
        DateShort(Observer, P, 'TODAY');
        DateShort(Observer, P, 'workdate');
        DateShort(Observer, P, 'w');
        DateShort(Observer, P, 'W');
        P.Close();
        WorkDate(Saved);
        Observer.Expect('[t]', 'Today');
        Observer.Expect('[T]', 'Today');
        Observer.Expect('[today]', 'Today');
        Observer.Expect('[TODAY]', 'Today');
        Observer.Expect('[workdate]', '2026-03-05 shows=3/5/2026');
        Observer.Expect('[w]', '2026-03-05 shows=3/5/2026');
        Observer.Expect('[W]', '2026-03-05 shows=3/5/2026');
        Observer.Verify();
    end;

    // ---- item 10: Clear of a TestPage over a part page ----

    [TryFunction]
    local procedure TryClearPart(var TP: TestPage "LT AN Part")
    begin
        Clear(TP);
    end;

    [TryFunction]
    local procedure TryOpenEditPart(var TP: TestPage "LT AN Part")
    begin
        TP.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenViewPart(var TP: TestPage "LT AN Part")
    begin
        TP.OpenView();
    end;

    [TryFunction]
    local procedure TryClosePart(var TP: TestPage "LT AN Part")
    begin
        TP.Close();
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    var
        Log: Codeunit "LT AN Log";
    begin
        if Ok then
            Observer.Observe(Name, 'ok log=' + Log.Take())
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '.log', Log.Take());
        end;
    end;

    [Test]
    procedure An10_ClearPartTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AN Log";
        TP: TestPage "LT AN Part";
    begin
        Seed();
        Log.Take();
        Step(Observer, 'clearNeverOpened', TryClearPart(TP));
        Step(Observer, 'openView', TryOpenViewPart(TP));
        Step(Observer, 'clearOpen', TryClearPart(TP));
        Step(Observer, 'closeAfterClearOpen', TryClosePart(TP));
        Step(Observer, 'openEditAfterClearOpen', TryOpenEditPart(TP));
        Step(Observer, 'close', TryClosePart(TP));
        Step(Observer, 'clearClosed', TryClearPart(TP));
        Step(Observer, 'openEditAfterClearClosed', TryOpenEditPart(TP));
        Step(Observer, 'closeAgain', TryClosePart(TP));
        Observer.Expect('clearNeverOpened', 'ok log=');
        Observer.Expect('openView', 'ok log=P.Open;P.R10;P.R20;P.R30;P.R40;P.R50;P.R10;P.R10;P.R10;P.C10;');
        Observer.Expect('clearOpen', 'ok log=');
        Observer.Expect('closeAfterClearOpen|text', 'The TestPage is not open.');
        Observer.Expect('closeAfterClearOpen|code', 'TestPageNotOpened');
        Observer.Expect('closeAfterClearOpen.log', '');
        Observer.Expect('openEditAfterClearOpen', 'ok log=P.Open;P.R10;P.R20;P.R30;P.R40;P.R50;P.R10;P.R10;P.R10;P.C10;');
        Observer.Expect('close', 'ok log=');
        Observer.Expect('clearClosed', 'ok log=');
        Observer.Expect('openEditAfterClearClosed', 'ok log=P.Open;P.R10;P.R20;P.R30;P.R40;P.R50;P.R10;P.R10;P.R10;P.C10;');
        Observer.Expect('closeAgain', 'ok log=');
        Observer.Verify();
    end;

    // ---- item 11: an action deletes the current row of a list with OnFindRecord / OnNextRecord ----

    local procedure SeedList(Codes: List of [Code[20]])
    var
        Row: Record "LT AN Row";
        C: Code[20];
    begin
        Row.DeleteAll();
        foreach C in Codes do begin
            Row."Code" := C;
            Row.Insert();
        end;
    end;

    local procedure DeleteAt(var Observer: Codeunit "Probe Observer"; Target: Code[20])
    var
        Log: Codeunit "LT AN Log";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Find List";
    begin
        Log.Take();
        P.OpenEdit();
        Observer.Observe('open', Log.Take());
        P.GoToKey(Target);
        Observer.Observe('goto', Log.Take());
        P.DeleteCurrent.Invoke();
        Observer.Observe('delete', Log.Take());
        Observer.Observe('cursor', P."Code".Value());
        Observer.Observe('stored', Format(Row.Get(Target)));
        Observer.Observe('count', Format(Row.Count()));
        if P.Next() then
            Observer.Observe('next', 'Yes ' + P."Code".Value())
        else
            Observer.Observe('next', 'No ' + P."Code".Value());
        Observer.Observe('nextLog', Log.Take());
        P.Close();
        Observer.Observe('closeLog', Log.Take());
    end;

    [Test]
    procedure An11_DeleteMiddleRow()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Code[20]];
    begin
        Codes.AddRange('A', 'B', 'C', 'D', 'E');
        SeedList(Codes);
        DeleteAt(Observer, 'C');
        Observer.Expect('open', 'F=><>A;RA;N1>1B;RB;N1>1C;RC;N1>1D;RD;N1>1E;RE;N1>0E;RA;N-1>0A;');
        Observer.Expect('goto', '');
        Observer.Expect('delete', 'RC;RC;DelC;N1>1D;RD;F=>>D;RD;N1>1E;RE;N1>0E;RD;N-1>-1B;RB;N-1>-1A;RA;N-1>0A;');
        Observer.Expect('cursor', 'D');
        Observer.Expect('stored', 'No');
        Observer.Expect('count', '4');
        Observer.Expect('next', 'Yes E');
        Observer.Expect('nextLog', '');
        Observer.Expect('closeLog', 'RE;');
        Observer.Verify();
    end;

    [Test]
    procedure An11_DeleteOnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Code[20]];
    begin
        Codes.Add('A');
        SeedList(Codes);
        DeleteAt(Observer, 'A');
        Observer.Expect('open', 'F=><>A;RA;N1>0A;N-1>0A;');
        Observer.Expect('goto', '');
        Observer.Expect('delete', 'RA;DelA;RA;F=>>none;F=><>none;');
        Observer.Expect('cursor', '');
        Observer.Expect('stored', 'No');
        Observer.Expect('count', '0');
        Observer.Expect('next', 'No ');
        Observer.Expect('nextLog', '');
        Observer.Expect('closeLog', '');
        Observer.Verify();
    end;

    [Test]
    procedure An11_DeleteInLongView()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Code[20]];
        i: Integer;
    begin
        for i := 1 to 60 do
            Codes.Add('R' + Format(i, 0, '<Integer,2><Filler Character,0>'));
        SeedList(Codes);
        DeleteAt(Observer, 'R30');
        Observer.Expect('open', 'F=><>R01;RR01;N1>1R02;RR02;N1>1R03;RR03;N1>1R04;RR04;N1>1R05;RR05;N1>1R06;RR06;N1>1R07;RR07;N1>1R08;RR08;N1>1R09;RR09;N1>1R10;RR10;N1>1R11;RR11;N1>1R12;RR12;N1>1R13;RR13;N1>1R14;RR14;N1>1R15;RR15;N1>1R16;RR16;N1>1R17;RR17;N1>1R18;RR18;N1>1R19;RR19;N1>1R20;RR20;RR01;N-1>0R01;');
        Observer.Expect('goto', 'RR19;RR20;N1>1R21;RR21;N1>1R22;RR22;N1>1R23;RR23;N1>1R24;RR24;N1>1R25;RR25;N1>1R26;RR26;N1>1R27;RR27;N1>1R28;RR28;N1>1R29;RR29;N1>1R30;RR30;N1>1R31;RR31;N1>1R32;RR32;N1>1R33;RR33;N1>1R34;RR34;N1>1R35;RR35;N1>1R36;RR36;N1>1R37;RR37;N1>1R38;RR38;N1>1R39;RR39;N1>1R40;RR40;');
        Observer.Expect('delete', 'RR30;RR30;DelR30;N1>1R31;RR31;F=>>R31;RR31;N1>1R32;RR32;N1>1R33;RR33;N1>1R34;RR34;N1>1R35;RR35;N1>1R36;RR36;N1>1R37;RR37;N1>1R38;RR38;N1>1R39;RR39;N1>1R40;RR40;N1>1R41;RR41;N1>1R42;RR42;N1>1R43;RR43;N1>1R44;RR44;N1>1R45;RR45;N1>1R46;RR46;N1>1R47;RR47;N1>1R48;RR48;N1>1R49;RR49;N1>1R50;RR50;RR31;N-1>-1R29;RR29;N-1>-1R28;RR28;N-1>-1R27;RR27;N-1>-1R26;RR26;N-1>-1R25;RR25;N-1>-1R24;RR24;N-1>-1R23;RR23;N-1>-1R22;RR22;N-1>-1R21;RR21;N-1>-1R20;RR20;N-1>-1R19;RR19;N-1>-1R18;RR18;N-1>-1R17;RR17;N-1>-1R16;RR16;N-1>-1R15;RR15;N-1>-1R14;RR14;N-1>-1R13;RR13;N-1>-1R12;RR12;N-1>-1R11;RR11;N-1>-1R10;RR10;');
        Observer.Expect('cursor', 'R31');
        Observer.Expect('stored', 'No');
        Observer.Expect('count', '59');
        Observer.Expect('next', 'Yes R32');
        Observer.Expect('nextLog', '');
        Observer.Expect('closeLog', 'RR32;');
        Observer.Verify();
    end;

    // ---- item 14: TableRelation lookup (no triggers), blank field and a field with a value ----

    [ModalPageHandler]
    procedure RelatedPick(var Modal: TestPage "LT AN Related List")
    begin
        LookupStart := Modal."Code".Value();
        Modal.GoToKey(LookupPick);
        Modal.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RelatedPick')]
    procedure An14_RelationLookup_BlankField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Card";
    begin
        Seed();
        OpenCard(P);
        LookupStart := '<handler not run>';
        LookupPick := 'R3';
        P.Rel.Lookup();
        Observer.Observe('startRow', LookupStart);
        Observer.Observe('after', P.Rel.Value());
        P.Close();
        Row.Get('ONE');
        Observer.Observe('stored', Row.Rel);
        Observer.Expect('startRow', 'R1');
        Observer.Expect('after', 'R3');
        Observer.Expect('stored', 'R3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RelatedPick')]
    procedure An14_RelationLookup_FieldWithValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Card";
    begin
        Seed();
        Row.Get('ONE');
        Row.Rel := 'R2';
        Row.Modify();
        OpenCard(P);
        LookupStart := '<handler not run>';
        LookupPick := 'R4';
        P.Rel.Lookup();
        Observer.Observe('startRow', LookupStart);
        Observer.Observe('after', P.Rel.Value());
        P.Close();
        Row.Get('ONE');
        Observer.Observe('stored', Row.Rel);
        Observer.Expect('startRow', 'R2');
        Observer.Expect('after', 'R4');
        Observer.Expect('stored', 'R4');
        Observer.Verify();
    end;

    // ---- item 15: Lookup on a relation to a table with no LookupPageId / DrillDownPageId and no handler ----

    [Test]
    procedure An15_RelationLookup_NoPage_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Pageless: Record "LT AN Pageless";
        Related: Record "LT AN Related";
        P: TestPage "LT AN Card";
    begin
        Seed();
        Commit();
        Pageless."Code" := 'PL-UNCOMMITTED';
        Pageless.Insert();
        Related."Code" := 'R-UNCOMMITTED';
        Related.Insert();
        OpenCard(P);
        P.NoPg.SetValue('PL-A');
        asserterror P.NoPg.Lookup();
        Observer.ObserveError('lookup');
        Observer.Observe('value', P.NoPg.Value());
        P.Close();
        Observer.Observe('pagelessRowSurvives', Format(Pageless.Get('PL-UNCOMMITTED')));
        Observer.Observe('relatedRowSurvives', Format(Related.Get('R-UNCOMMITTED')));
        Observer.Expect('lookup|text', 'Unhandled UI: ModalPage ');
        Observer.Expect('lookup|code', 'TestWrapped:MissingUIHandler');
        Observer.Expect('value', 'PL-A');
        Observer.Expect('pagelessRowSurvives', 'No');
        Observer.Expect('relatedRowSurvives', 'No');
        Observer.Verify();
    end;

    // ---- item 16: Duration control SetValue ----

    local procedure Dur(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AN Card"; Name: Text; V: Text)
    begin
        P.DurVar.SetValue('2 hours');
        if TrySetDur(P, V) then
            Observer.Observe(Name, 'in=[' + V + '] shows=[' + P.DurVar.Value() + ']')
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '.after', P.DurVar.Value());
        end;
    end;

    [Test]
    procedure An16_DurationSpellings()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Card";
    begin
        Seed();
        OpenCard(P);
        Dur(Observer, P, 'dash', '-');
        Dur(Observer, P, 'commaHours', '1,5 hours');
        Dur(Observer, P, 'commaOnly', '1,5');
        P.Close();
        Observer.Expect('dash', 'in=[-] shows=[]');
        Observer.Expect('commaHours|text', 'Validation error for Field: DurVar,  Message = ''Your entry of ''1,5 hours'' is not an acceptable value for ''DurVar''. The value "1,5 hours" can''t be evaluated into type Duration.''');
        Observer.Expect('commaHours|code', 'TestValidation');
        Observer.Expect('commaHours.after', '2 hours');
        Observer.Expect('commaOnly|text', 'Validation error for Field: DurVar,  Message = ''Your entry of ''1,5'' is not an acceptable value for ''DurVar''. The value "1,5" can''t be evaluated into type Duration.''');
        Observer.Expect('commaOnly|code', 'TestValidation');
        Observer.Expect('commaOnly.after', '2 hours');
        Observer.Verify();
    end;

    // ---- item 19: CaptionClass 'X,Y' (non-numeric area, no subscriber) on a table field ----

    [Test]
    procedure An19_TableFieldCaptionClass_NonNumericArea()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        RecRef: RecordRef;
        P: TestPage "LT AN Card";
    begin
        Seed();
        Observer.Observe('fieldCaption', Row.FieldCaption(Cap));
        RecRef.Open(Database::"LT AN Row");
        Observer.Observe('fieldRefCaption', RecRef.Field(5).Caption());
        OpenCard(P);
        Observer.Observe('testPageCaption', P.Cap.Caption());
        P.Close();
        Observer.Expect('fieldCaption', 'X,Y');
        Observer.Expect('fieldRefCaption', 'X,Y');
        Observer.Expect('testPageCaption', 'X,Y');
        Observer.Verify();
    end;
}
