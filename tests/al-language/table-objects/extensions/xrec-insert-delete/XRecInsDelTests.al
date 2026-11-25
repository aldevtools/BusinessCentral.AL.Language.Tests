// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects in XRecInsDelObjects.al (76380-76384, 76387), XApp A table "XA XRE Base Line" (76390)
// Probe (al-runner issue 8986): what xRec holds in the insert triggers (OnBeforeInsert, OnInsert, OnAfterInsert) and delete triggers
//   (OnBeforeDelete, OnDelete, OnAfterDelete) of a table extension, and in the table's own OnInsert and OnDelete, from code.
//   Shapes before Insert(true): plain assigns, Validate, Clear + Validate (the reporter's shape), Get of another row then Validate, Get then
//   Init, two Validates, a second insert from the same variable; on a table without extension too. Readings in the extension: the fields of
//   xRec, Format(xRec) = Format(Rec), the same read in a local procedure of the extension and through Rec.ReadXRec() (a table procedure),
//   xRec.SystemId, xRec.GetFilters, xRec.Count, xRec.Get, xRec := Rec then read; on a temporary record, through RecordRef.Insert(true),
//   through a page (TestPage.OpenNew) and on a duplicate key (the error of the insert comes later). Delete(true) after Get, after Get and
//   assign, after Get and Validate, and the table's OnDelete after the extension's OnBeforeDelete wrote Rec. The two-app shape of the issue:
//   table in XApp A, extension here.
// Facts: OBSERVE (filled in by the observe run)
// BC versions: 27, 28, 29

codeunit 76388 "LT XRE Ins Del Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT XRE Log";

    local procedure Start()
    var
        Row: Record "LT XRE Row";
        Plain: Record "LT XRE Plain";
        Line: Record "XA XRE Base Line";
    begin
        Row.DeleteAll();
        Plain.DeleteAll();
        Line.DeleteAll();
        Log.Reset();
    end;

    local procedure SeedRow(EntryNo: Integer; Serial: Integer; Name: Text[30])
    var
        Row: Record "LT XRE Row";
    begin
        Row."Entry No." := EntryNo;
        Row.Serial := Serial;
        Row.Name := Name;
        Row.Insert(false);
    end;

    local procedure ObserveLog(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('lines', Format(Log.Count()));
        for i := 1 to Log.Count() do
            Observer.Observe('l' + Format(i), Log.Line(i));
    end;

    [Test]
    procedure Insert_AfterAssigns_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Row.Init();
        Row."Entry No." := 1;
        Row.Serial := 42;
        Row.Name := 'A';
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterValidate_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Name := 'A';
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterClearValidate_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Clear(Row);
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterGetOtherRowThenValidate_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(9, 7, 'OLD');
        Row.Get(9);
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterGetOtherRowThenInit_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(9, 7, 'OLD');
        Row.Get(9);
        Row.Init();
        Row."Entry No." := 1;
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterTwoValidates_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 41);
        Row.Validate(Serial, 42);
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_SecondInsertSameVariable_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Insert(true);
        Log.Reset();
        Row."Entry No." := 2;
        Row.Validate(Serial, 43);
        Row.Name := 'B';
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ModeSystemId_ExtTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Log.SetMode('sid');
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ModeFilters_CallerFilter_ExtTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Log.SetMode('filters');
        Row.SetRange(Serial, 40, 50);
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ModeCount_ExtTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(9, 7, 'OLD');
        Log.SetMode('count');
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ModeGet_ExtTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        Log.SetMode('get');
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Name := 'A';
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ModeAssignXRecFromRec_ExtTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(9, 7, 'OLD');
        Log.SetMode('assign');
        Row.Get(9);
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Name := 'A';
        Row.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Temporary_AfterValidate_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT XRE Row" temporary;
    begin
        Start();
        TempRow.Init();
        TempRow."Entry No." := 1;
        TempRow.Validate(Serial, 42);
        TempRow.Name := 'T';
        TempRow.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_RecordRef_AfterValidate_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Start();
        RecRef.Open(Database::"LT XRE Row");
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Validate(42);
        RecRef.Field(3).Value := 'R';
        RecRef.Insert(true);
        RecRef.Close();
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Page_OpenNew_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
        Card: TestPage "LT XRE Row Card";
    begin
        Start();
        Card.OpenNew();
        Card."Entry No.".SetValue(5);
        Card.Serial.SetValue(42);
        Card.Name.SetValue('P');
        Card.Close();
        ObserveLog(Observer);
        Observer.Observe('stored', Format(Row.Get(5)) + ' ' + Log.Fmt(Row."Entry No.", Row.Serial, Row.Name));
        Observer.Finish();
    end;

    local procedure InsertDuplicateThenRead(var Row: Record "LT XRE Row")
    var
        Other: Record "LT XRE Row";
    begin
        Row.Insert(true);
        Log.Add('after insert call');
        Other.FindFirst();
        Log.Add('after read');
        Error('no error raised');
    end;

    [Test]
    procedure Insert_DuplicateKey_ExtTriggersBeforeTheError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(1, 7, 'OLD');
        Row.Init();
        Row."Entry No." := 1;
        Row.Validate(Serial, 42);
        Row.Name := 'D';
        asserterror InsertDuplicateThenRead(Row);
        Observer.ObserveError('dup');
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_Insert_AfterValidate_TableOnInsert()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "LT XRE Plain";
    begin
        Start();
        Plain.Init();
        Plain."Entry No." := 1;
        Plain.Validate(Serial, 42);
        Plain.Name := 'A';
        Plain.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_Insert_AfterClearValidate_TableOnInsert()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "LT XRE Plain";
    begin
        Start();
        Clear(Plain);
        Plain."Entry No." := 1;
        Plain.Validate(Serial, 42);
        Plain.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_Insert_AfterGetOtherRowThenValidate_TableOnInsert()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "LT XRE Plain";
    begin
        Start();
        Plain."Entry No." := 9;
        Plain.Serial := 7;
        Plain.Name := 'OLD';
        Plain.Insert(false);
        Clear(Plain);
        Plain.Get(9);
        Plain."Entry No." := 1;
        Plain.Validate(Serial, 42);
        Plain.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_Insert_AfterGetOtherRowThenInit_TableOnInsert()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "LT XRE Plain";
    begin
        Start();
        Plain."Entry No." := 9;
        Plain.Serial := 7;
        Plain.Name := 'OLD';
        Plain.Insert(false);
        Clear(Plain);
        Plain.Get(9);
        Plain.Init();
        Plain."Entry No." := 1;
        Plain.Insert(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_AfterGet_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(1, 42, 'A');
        Row.Get(1);
        Row.Delete(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_AfterGetAndAssign_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(1, 42, 'A');
        Row.Get(1);
        Row.Serial := 99;
        Row.Name := 'CHG';
        Row.Delete(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_AfterGetAndValidate_ExtAndTableTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(1, 42, 'A');
        Row.Get(1);
        Row.Validate(Serial, 99);
        Row.Delete(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_ExtOnBeforeDeleteWritesRec_TableOnDelete()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT XRE Row";
    begin
        Start();
        SeedRow(1, 42, 'A');
        Log.SetMode('extwrite');
        Row.Get(1);
        Row.Delete(true);
        ObserveLog(Observer);
        Observer.Observe('caller name after', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure TwoApps_Insert_AfterClearValidate_ReporterShape()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XA XRE Base Line";
        Stored: Record "XA XRE Base Line";
    begin
        Start();
        Clear(Line);
        Line."Entry No." := 1;
        Line.Validate("Serial No.", 42);
        Line.Insert(true);
        ObserveLog(Observer);
        Observer.Observe('caller table field', Format(Line."xRec Serial In Table OnInsert"));
        Observer.Observe('caller ext field', Format(Line."xRec Serial In Ext OnAfterIns"));
        Stored.Get(1);
        Observer.Observe('stored table field', Format(Stored."xRec Serial In Table OnInsert"));
        Observer.Observe('stored ext field', Format(Stored."xRec Serial In Ext OnAfterIns"));
        Observer.Finish();
    end;

    [Test]
    procedure TwoApps_Insert_AfterGetOtherRowThenAssign()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XA XRE Base Line";
    begin
        Start();
        Line."Entry No." := 9;
        Line."Serial No." := 7;
        Line.Insert(false);
        Clear(Line);
        Line.Get(9);
        Line."Entry No." := 1;
        Line."Serial No." := 42;
        Line.Insert(true);
        ObserveLog(Observer);
        Observer.Observe('caller table field', Format(Line."xRec Serial In Table OnInsert"));
        Observer.Observe('caller ext field', Format(Line."xRec Serial In Ext OnAfterIns"));
        Observer.Finish();
    end;

    [Test]
    procedure TwoApps_Delete_AfterGetAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XA XRE Base Line";
    begin
        Start();
        Line."Entry No." := 1;
        Line."Serial No." := 42;
        Line.Insert(false);
        Clear(Line);
        Line.Get(1);
        Line."Serial No." := 99;
        Line.Delete(true);
        ObserveLog(Observer);
        Observer.Finish();
    end;
}
