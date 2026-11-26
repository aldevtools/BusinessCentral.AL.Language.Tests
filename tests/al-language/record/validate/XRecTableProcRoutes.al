// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97164..97171 (XRR Line, XRR Line Ext, XRR Cfg, XRR Subscriber,
//   XRR Helper, XRR Tests, XRR Report, XRR Other Subscriber)
// local object: the table and table extension procedures, the field triggers, the event subscribers and the callers of the
//   Validate are what is under test.
// Probe (al-runner issue 8974, follow-up to XRecTableProcThroughSubscriber.al and XRecTableProcCallers.al): what xRec a
//   procedure of a table or of its table extension reads when code other than the table's own calls it on the record while a
//   Validate of that record runs, on the routes those probes did not take. Every cell logs the trigger's own xRec ('T' for
//   Mode, 'I' for "Item No.", 'N' for Note), then what each procedure read of xRec ('PA' and 'XA' the table and table
//   extension procedure from an OnAfterValidateEvent subscriber, 'A' its xRec parameter; 'HP' and 'HX' through a procedure of
//   the subscriber's codeunit; 'HR' through one that takes only the record; 'PS' after the subscriber assigned Rec; 'X' and
//   'P' from the subscriber of an integration event the trigger raises; 'C' through a codeunit the trigger calls; 'CV' and
//   'CO' after that codeunit validated another field, 'CO' through a table procedure that reads xRec in a local procedure
//   it calls; 'J' for "Planned No.", whose trigger runs Init, assigns Series and nests Validate(Mode) through two table
//   procedures; 'X2' and 'P2' from the subscriber of an event with a second var record parameter that a second subscriber,
//   declaring only the record, also subscribes to; 'H' for Heavy, whose trigger runs Init, nests Validate(Note) and calls a
//   table procedure itself ('HP'); 'CH' and 'CH2' through a table procedure that reads xRec in a local procedure, after the
//   codeunit validated Heavy and called a table procedure that assigns, and after it assigned a field). A record is logged as Mode ordinal/Series/"Item No."/Note. Before the Validate the stored row holds
//   0/OLD/I1/ and the record variable 0/NEW/I1/, so a read of the stored row and a copy of Rec show apart from the
//   record's before-image.
// Cells:
//   - an OnAfterValidateEvent subscriber calls a table procedure and a table extension procedure on Rec after the field
//     trigger assigned another field (Series := 'TRG'), directly or through a procedure of its own codeunit that takes Rec and
//     xRec by var; through a procedure that takes only Rec; without the trigger's assignment; with the assignment made in a
//     table procedure the trigger calls, or in a codeunit the trigger calls; with the subscriber assigning a field of Rec
//     before the call;
//   - the subscriber of an integration event the trigger raises after the same assignment, also assigning a field of Rec
//     itself before the calls;
//   - a codeunit the trigger hands Rec to after the same assignment, also assigning a field of Rec itself before the call;
//     that codeunit validating another field of the record
//     before it calls the table procedure, also through a table procedure that reads xRec in a local procedure;
//   - (Base Application's planning: Requisition Line "Replenishment System" raising OnValidateReplenishmentSystemCaseElse
//     to the Mfg. and Asm. subscribers) the trigger assigns, then raises an event with two subscribers; the same Validate
//     nested by "Planned No." after Init, validated by the test, by a codeunit procedure and by a report's OnAfterGetRecord;
//   - (Base Application's Purchase Line "Item Reference No." and Item Reference Management.ValidatePurchaseReferenceNo)
//     the trigger assigns, then hands Rec to a codeunit that validates a field whose trigger runs Init, nests a Validate
//     and calls a table procedure, calls a table procedure that assigns, reads through a table procedure, assigns, reads
//     again; validated by the test and by a codeunit procedure;
//   - callers of the Validate: a test procedure that also carries [Scope('OnPrem')], with and without a handler; a report run
//     from test code (UseRequestPage(false), Run) whose OnAfterGetRecord calls a report procedure that validates; the
//     subscriber of an integration event a codeunit raises, validating the record it is handed.
// Facts: what each table procedure (and the field trigger) reads of xRec, and the record after the Validate, per cell (the
//   Expect lines of each test).
// BC versions: 27.5, 28.5, 29.0

table 97164 "XRR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XRR Cfg";
                Helper: Codeunit "XRR Helper";
                Number: Record Integer;
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T x=' + Cfg.Fmt(xRec));
                case Cfg.GetAssign() of
                    'direct':
                        Series := 'TRG';
                    'proc':
                        AssignSeries();
                    'codeunit':
                        Helper.AssignSeries(Rec);
                end;
                case Cfg.Get() of
                    'event', 'event-assign':
                        OnModeElse(Rec);
                    'codeunit':
                        Helper.CallTableProc(Rec);
                    'codeunit-assign':
                        Helper.AssignThenTableProc(Rec);
                    'cu-validate':
                        Helper.ValidateNoteThenTableProc(Rec);
                    'cu-validate-own':
                        Helper.ValidateNoteThenOwnChain(Rec, true, Rec.FieldNo(Mode));
                    'event2':
                        begin
                            Number.Number := 1;
                            OnModeElse2(Rec, Number);
                        end;
                    'cu-heavy':
                        Helper.ValidateHeavyThenOwnChain(Rec);
                end;
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRR Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I x=' + Cfg.Fmt(xRec));
                Series := 'MID';
                CopyFromItem();
            end;
        }
        field(5; Note; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRR Cfg";
            begin
                if Cfg.Get() <> '' then
                    Cfg.Add('N x=' + Cfg.Fmt(xRec));
            end;
        }
        field(6; "Planned No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRR Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('J x=' + Cfg.Fmt(xRec));
                Init();
                Series := 'MID';
                CopyFromItem();
            end;
        }
        field(7; Heavy; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRR Cfg";
                TempLine: Record "XRR Line" temporary;
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('H x=' + Cfg.Fmt(xRec));
                TempLine := Rec;
                Init();
                Series := TempLine.Series;
                Validate(Note, 'HV');
                TableProcRead('HP');
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;

    local procedure AssignSeries()
    begin
        Series := 'TRG';
    end;

    procedure TableProcRead(Tag: Text)
    var
        Cfg: Codeunit "XRR Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;

    procedure TableProcThroughOwn(Tag: Text)
    begin
        ReadInOwnProc(Tag);
    end;

    local procedure ReadInOwnProc(Tag: Text)
    var
        Cfg: Codeunit "XRR Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;

    procedure SetNoteFromProc()
    begin
        Note := 'SP';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModeElse(var Line: Record "XRR Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModeElse2(var Line: Record "XRR Line"; var Number: Record Integer)
    begin
    end;
}

tableextension 97165 "XRR Line Ext" extends "XRR Line"
{
    procedure ExtProcRead(Tag: Text)
    var
        Cfg: Codeunit "XRR Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;
}

report 97170 "XRR Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(LineItem; "XRR Line")
        {
            trigger OnAfterGetRecord()
            begin
                LineItem.Series := 'NEW';
                InsertLine(LineItem);
            end;
        }
    }

    local procedure InsertLine(var Line: Record "XRR Line")
    var
        Cfg: Codeunit "XRR Cfg";
    begin
        if Cfg.Get() = 'event2' then
            Line.Validate("Planned No.", 'P1')
        else
            Line.Validate("Item No.", 'I2');
    end;
}

codeunit 97166 "XRR Cfg"
{
    SingleInstance = true;

    var
        CfgMode: Text;
        AssignMode: Text;
        Log: Text;

    procedure Set(NewMode: Text)
    begin
        CfgMode := NewMode;
    end;

    procedure Get(): Text
    begin
        exit(CfgMode);
    end;

    procedure SetAssign(NewAssign: Text)
    begin
        AssignMode := NewAssign;
    end;

    procedure GetAssign(): Text
    begin
        exit(AssignMode);
    end;

    procedure Add(Value: Text)
    begin
        Log += Value + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure Fmt(Line: Record "XRR Line"): Text
    begin
        exit(Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No." + '/' + Line.Note);
    end;
}

codeunit 97167 "XRR Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"XRR Line", 'OnAfterValidateEvent', 'Mode', false, false)]
    local procedure OnAfterValidateMode(var Rec: Record "XRR Line"; var xRec: Record "XRR Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XRR Cfg";
    begin
        case Cfg.Get() of
            'after-table':
                begin
                    Cfg.Add('A x=' + Cfg.Fmt(xRec));
                    Rec.TableProcRead('PA');
                end;
            'after-ext':
                begin
                    Cfg.Add('A x=' + Cfg.Fmt(xRec));
                    Rec.ExtProcRead('XA');
                end;
            'after-helper-table':
                Helper(Rec, xRec, false);
            'after-helper-ext':
                Helper(Rec, xRec, true);
            'after-helper-reconly':
                HelperRecOnly(Rec);
            'after-subassign':
                begin
                    Rec.Note := 'SUB';
                    Rec.TableProcRead('PS');
                end;
        end;
    end;

    local procedure Helper(var Line: Record "XRR Line"; var xLine: Record "XRR Line"; Ext: Boolean)
    begin
        if Ext then
            Line.ExtProcRead('HX')
        else
            Line.TableProcRead('HP');
    end;

    local procedure HelperRecOnly(var Line: Record "XRR Line")
    begin
        Line.TableProcRead('HR');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRR Line", 'OnModeElse', '', false, false)]
    local procedure OnModeElse(var Line: Record "XRR Line")
    var
        Cfg: Codeunit "XRR Cfg";
    begin
        if Cfg.Get() = 'event-assign' then
            Line.Note := 'SUB';
        Line.ExtProcRead('X');
        Line.TableProcRead('P');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRR Line", 'OnModeElse2', '', false, false)]
    local procedure OnModeElse2(var Line: Record "XRR Line"; var Number: Record Integer)
    begin
        Line.ExtProcRead('X2');
        Line.TableProcRead('P2');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"XRR Helper", 'OnLineRequested', '', false, false)]
    local procedure OnLineRequested(var Line: Record "XRR Line")
    begin
        Line.Validate("Item No.", 'I2');
    end;
}

codeunit 97171 "XRR Other Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"XRR Line", 'OnModeElse2', '', false, false)]
    local procedure OnModeElse2(var Line: Record "XRR Line")
    begin
        if Line.Note = 'ASM' then
            Line.TableProcRead('Z');
    end;
}

codeunit 97168 "XRR Helper"
{
    procedure CallTableProc(var Line: Record "XRR Line")
    begin
        Line.TableProcRead('C');
    end;

    procedure AssignThenTableProc(var Line: Record "XRR Line")
    begin
        Line.Note := 'CU';
        Line.TableProcRead('CA');
    end;

    procedure ValidateNoteThenTableProc(var Line: Record "XRR Line")
    begin
        Line.Validate(Note, 'V');
        Line.TableProcRead('CV');
    end;

    procedure ValidateNoteThenOwnChain(var Line: Record "XRR Line"; Search: Boolean; CallerFieldNo: Integer)
    begin
        Line.Validate(Note, 'V');
        Line.TableProcThroughOwn('CO');
    end;

    procedure ValidateHeavyThenOwnChain(var Line: Record "XRR Line")
    begin
        Line.Validate(Heavy, 'H');
        Line.SetNoteFromProc();
        Line.TableProcThroughOwn('CH');
        Line.Note := 'CU';
        Line.TableProcThroughOwn('CH2');
    end;

    procedure ValidateMode(var Line: Record "XRR Line")
    begin
        Line.Validate(Mode, Line.Mode::Production);
    end;

    procedure ValidatePlanned(var Line: Record "XRR Line")
    begin
        Line.Validate("Planned No.", 'P1');
    end;

    procedure AssignSeries(var Line: Record "XRR Line")
    begin
        Line.Series := 'TRG';
    end;

    procedure RequestLine(var Line: Record "XRR Line")
    begin
        OnLineRequested(Line);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLineRequested(var Line: Record "XRR Line")
    begin
    end;
}

codeunit 97169 "XRR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "XRR Cfg";

    local procedure Initialize()
    var
        Line: Record "XRR Line";
    begin
        Cfg.Set('');
        Cfg.SetAssign('');
        Cfg.Take();
        Line.DeleteAll();
    end;

    // The row 1 stored as 0/OLD/I1/; the record variable then holds 0/NEW/I1/.
    local procedure AfterInsert(var Line: Record "XRR Line")
    begin
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
    end;

    local procedure ValidateModeAndObserve(var Observer: Codeunit "Probe Observer"; var Line: Record "XRR Line"; CfgMode: Text; Assign: Text)
    begin
        Cfg.Set(CfgMode);
        Cfg.SetAssign(Assign);
        Line.Validate(Mode, Line.Mode::Production);
        Observe(Observer, Line);
    end;

    local procedure Observe(var Observer: Codeunit "Probe Observer"; var Line: Record "XRR Line")
    begin
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Cfg.Fmt(Line));
        Cfg.Set('');
        Cfg.SetAssign('');
    end;

    [Test]
    procedure AfterEvent_TriggerAssigns_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-table', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;A x=0/NEW/I1/;PA x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_TriggerAssigns_ExtProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-ext', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;A x=0/NEW/I1/;XA x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_TriggerAssigns_HelperTableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-helper-table', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;HP x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_TriggerAssigns_HelperExtProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-helper-ext', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;HX x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_Helper_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-helper-table', '');
        Observer.Expect('log', 'T x=0/NEW/I1/;HP x=0/NEW/I1/;');
        Observer.Expect('record', '1/NEW/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_TriggerAssigns_HelperRecOnly()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-helper-reconly', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;HR x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_TriggerAssignsInProc_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-table', 'proc');
        Observer.Expect('log', 'T x=0/NEW/I1/;A x=0/NEW/I1/;PA x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_TriggerAssignsThroughCodeunit_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-table', 'codeunit');
        Observer.Expect('log', 'T x=0/NEW/I1/;A x=0/NEW/I1/;PA x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure AfterEvent_SubscriberAssignsRec_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-subassign', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;PS x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/SUB');
        Observer.Verify();
    end;

    [Test]
    procedure IntegrationEvent_TriggerAssigns()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'event', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;X x=0/NEW/I1/;P x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_TriggerAssigns_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'codeunit', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;C x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure IntegrationEvent_TriggerAndSubscriberAssign()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'event-assign', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;X x=0/NEW/I1/;P x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/SUB');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_TriggerAssigns_CodeunitAssignsThenTableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'codeunit-assign', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;CA x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/CU');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_ValidatesOtherField_TableProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'cu-validate', '');
        Observer.Expect('log', 'T x=0/NEW/I1/;N x=1/NEW/I1/;CV x=0/NEW/I1/;');
        Observer.Expect('record', '1/NEW/I1/V');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_TriggerAssigns_ValidatesOtherField_ThroughOwnProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'cu-validate-own', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;N x=1/TRG/I1/;CO x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/V');
        Observer.Verify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Caller_ScopeOnPremTest_IntegrationEvent()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'event', '');
        Observer.Expect('log', 'T x=0/NEW/I1/;X x=0/NEW/I1/;P x=0/NEW/I1/;');
        Observer.Expect('record', '1/NEW/I1/');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Caller_ScopeOnPremTestWithHandler_Nested()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event');
        Line.Validate("Item No.", 'I2');
        Message('done');
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1/;T x=0/NEW/I1/;X x=0/NEW/I1/;P x=0/NEW/I1/;');
        Observer.Expect('record', '1/MID/I2/');
        Observer.Verify();
    end;

    [Test]
    procedure Caller_ReportRunFromTest_Nested()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event');
        Line.SetRange("Line No.", 1);
        GetLines.SetTableView(Line);
        GetLines.UseRequestPage(false);
        GetLines.Run();
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1/;T x=0/NEW/I1/;X x=0/NEW/I1/;P x=0/NEW/I1/;');
        Observer.Expect('record', '0/NEW/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure Caller_IntegrationEventSubscriber_Nested()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event');
        Helper.RequestLine(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1/;T x=0/NEW/I1/;X x=0/NEW/I1/;P x=0/NEW/I1/;');
        Observer.Expect('record', '1/MID/I2/');
        Observer.Verify();
    end;

    [Test]
    procedure IntegrationEvent_TriggerAssigns_TwoSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'event2', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;X2 x=0/NEW/I1/;P2 x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_InitThenTriggerAssigns_TwoSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event2');
        Cfg.SetAssign('direct');
        Line.Validate("Planned No.", 'P1');
        Observe(Observer, Line);
        Observer.Expect('log', 'J x=0/NEW/I1/;T x=0/NEW/I1/;X2 x=0/NEW/I1/;P2 x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG//');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_InitThenTriggerAssigns_TwoSubscribers_FromCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event2');
        Cfg.SetAssign('direct');
        Helper.ValidatePlanned(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'J x=0/NEW/I1/;T x=0/NEW/I1/;X2 x=0/NEW/I1/;P2 x=0/NEW/I1/;');
        Observer.Expect('record', '1/TRG//');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_InitThenTriggerAssigns_TwoSubscribers_FromReport()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event2');
        Cfg.SetAssign('direct');
        Line.SetRange("Line No.", 1);
        GetLines.SetTableView(Line);
        GetLines.UseRequestPage(false);
        GetLines.Run();
        Observe(Observer, Line);
        Observer.Expect('log', 'J x=0/NEW/I1/;T x=0/NEW/I1/;X2 x=0/NEW/I1/;P2 x=0/NEW/I1/;');
        Observer.Expect('record', '0/NEW/I1/');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_TriggerAssigns_ValidatesHeavyField_ThroughOwnProc()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'cu-heavy', 'direct');
        Observer.Expect('log', 'T x=0/NEW/I1/;H x=1/TRG/I1/;N x=1/TRG/I1/;HP x=1/TRG/I1/;CH x=0/NEW/I1/;CH2 x=0/NEW/I1/;');
        Observer.Expect('record', '0/TRG//CU');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_TriggerAssigns_ValidatesHeavyField_FromCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRR Line";
        Helper: Codeunit "XRR Helper";
        GetLines: Report "XRR Report";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('cu-heavy');
        Cfg.SetAssign('direct');
        Helper.ValidateMode(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1/;H x=1/TRG/I1/;N x=1/TRG/I1/;HP x=1/TRG/I1/;CH x=0/NEW/I1/;CH2 x=0/NEW/I1/;');
        Observer.Expect('record', '0/TRG//CU');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}
