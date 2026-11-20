// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97150..97159 (XRC Line, XRC Line Ext, XRC Cfg, XRC Subscriber A,
//   XRC Subscriber B, XRC Planner, XRC Runner, XRC Report, XRC Tests, XRC Other)
// local object: the tables, the table extension procedures, the field triggers, the event subscribers and the callers of the
//   Validate are what is under test.
// Probe (al-runner issues 8284 and 8306, follow-up to XRecTableProcThroughSubscriber.al): who calls the Validate, and how many
//   subscribers an event has, when a procedure of a table or of its table extension reads xRec from a subscriber. Base
//   Application's planning validates the Requisition Line from codeunit code a report starts through Codeunit.Run (Calculate
//   Plan - Plan. Wksh. commits and runs Calc. Item Plan - Plan Wksh. guarded -> Inventory Profile Offsetting.MaintainPlanningLine),
//   and two codeunits subscribe to OnValidateReplenishmentSystemCaseElse(var RequisitionLine; var StockkeepingUnit) (Asm.
//   Requisition Line, which declares only the record and does nothing for a production order, and Mfg. Requisition Line, which
//   reads xRec). Every cell logs the trigger's own xRec ('T' for Mode, 'I' for "Item No.", 'V' for
//   ViaCodeunit, 'E' for EventField), then what each procedure read of xRec ('X' the table extension procedure, 'P' the table
//   procedure from subscriber B; 'XA' and 'PA' from subscriber A; 'C' through a codeunit the trigger calls; 'XE' from an
//   OnAfterValidateEvent subscriber). A record is logged as Mode ordinal/Series/"Item No.". Before the Validate the stored row
//   holds 0/OLD/I1 and the record variable 0/NEW/I1, so a read of the stored row shows apart from the record's before-image.
// Cells:
//   - the Validate of Mode, whose trigger raises an integration event with one subscriber, called from a codeunit procedure,
//     from a codeunit's OnRun through Codeunit.Run, from a TryFunction (its result used, and called as a statement), and from a
//     processing-only report's OnAfterGetRecord through Codeunit.Run, as a statement and guarded after a Commit;
//   - the Validate of "Item No.", whose trigger nests the Validate of Mode through two table procedures, called from a codeunit
//     procedure, through Codeunit.Run, and through Codeunit.Run on a line the codeunit read by FindLast and gave a new key by
//     Init (Base Application's MaintainPlanningLine), also from a report, as a statement and guarded;
//   - the event with two subscribers: the first does nothing and the second reads; both read; the first assigns xRec in the
//     table extension procedure before the second reads; the nested Validate with the first doing nothing, through
//     Codeunit.Run, and on the MaintainLine chain from a report, also from a test procedure that names a handler;
//   - an event with two var parameters whose first subscriber declares only the record and does nothing: the Validate from the
//     test, nested, and on the MaintainLine chain from a report that runs the codeunit guarded, also from a test procedure
//     that names a handler;
//   - a codeunit the field trigger hands Rec to, with the Validate called from a codeunit procedure;
//   - an OnAfterValidateEvent subscriber calling the table extension procedure on Rec, with the Validate called from a codeunit
//     procedure, through Codeunit.Run and from a TryFunction.
// Facts (measured on 29.1):
//   - every procedure reads the xRec the Validate hands its trigger (the record before the Validate with the old value; for
//     the one-argument Validate the record as it is, the new value in), not the stored row, whoever calls the Validate: a
//     codeunit procedure, a codeunit's OnRun through Codeunit.Run, a TryFunction, or a report's OnAfterGetRecord through
//     Codeunit.Run (also guarded after a Commit), also with the line read by FindLast and given a new key by Init;
//   - under the Validate the table's code nests, the inner trigger and the procedures read the outer Validate's xRec;
//   - with two subscribers both read that xRec, and an assignment to xRec in the first one's table extension procedure shows
//     in the second one's reads: one xRec for the Validate; a first subscriber that declares only the record changes nothing;
//   - a codeunit the trigger hands Rec to, and an OnAfterValidateEvent subscriber's Rec.Proc(), read it too, from a codeunit
//     procedure, through Codeunit.Run and from a TryFunction.
// BC versions: 27.5, 28.5, 29.0

table 97150 "XRC Line"
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
                Cfg: Codeunit "XRC Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T x=' + Cfg.Fmt(xRec));
                case true of
                    Cfg.Get() in ['wide', 'wide-nested', 'wide-maintain']:
                        OnModeWide(Rec, OtherRow);
                    Cfg.Get() in ['two-noop', 'two-both', 'two-assign', 'two-nested', 'two-maintain']:
                        OnModeTwo(Rec);
                    Cfg.Get() <> 'event':
                        OnModeElse(Rec);
                end;
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRC Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I x=' + Cfg.Fmt(xRec));
                Series := 'MID';
                CopyFromItem();
            end;
        }
        field(5; ViaCodeunit; Boolean)
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRC Cfg";
                Planner: Codeunit "XRC Planner";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('V x=' + Cfg.Fmt(xRec));
                Planner.CallExtProc(Rec);
            end;
        }
        field(6; EventField; Integer)
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRC Cfg";
            begin
                if Cfg.Get() <> '' then
                    Cfg.Add('E x=' + Cfg.Fmt(xRec));
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    var
        OtherRow: Record "XRC Other";

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;

    procedure TableProcRead(Tag: Text)
    var
        Cfg: Codeunit "XRC Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModeElse(var Line: Record "XRC Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModeTwo(var Line: Record "XRC Line")
    begin
    end;

    // Base Application's OnValidateReplenishmentSystemCaseElse(var RequisitionLine; var StockkeepingUnit).
    [IntegrationEvent(false, false)]
    local procedure OnModeWide(var Line: Record "XRC Line"; var Other: Record "XRC Other")
    begin
    end;
}

table 97159 "XRC Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

tableextension 97151 "XRC Line Ext" extends "XRC Line"
{
    procedure ExtProcRead(Tag: Text)
    var
        Cfg: Codeunit "XRC Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;

    procedure ExtProcAssign()
    var
        Cfg: Codeunit "XRC Cfg";
    begin
        Cfg.Add('XS x=' + Cfg.Fmt(xRec));
        xRec.Series := 'SET';
    end;
}

codeunit 97152 "XRC Cfg"
{
    SingleInstance = true;

    var
        CfgMode: Text;
        Log: Text;
        GuardedRun: Boolean;

    procedure Set(NewMode: Text)
    begin
        CfgMode := NewMode;
    end;

    procedure Get(): Text
    begin
        exit(CfgMode);
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

    procedure Fmt(Line: Record "XRC Line"): Text
    begin
        exit(Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
    end;

    procedure SetGuarded(NewGuarded: Boolean)
    begin
        GuardedRun := NewGuarded;
    end;

    procedure Guarded(): Boolean
    begin
        exit(GuardedRun);
    end;
}

codeunit 97153 "XRC Subscriber A"
{
    // Base Application's Asm. Requisition Line: it declares only the record and does nothing for a production order.
    [EventSubscriber(ObjectType::Table, Database::"XRC Line", 'OnModeWide', '', false, false)]
    local procedure OnModeWide(var Line: Record "XRC Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRC Line", 'OnModeTwo', '', false, false)]
    local procedure OnModeTwo(var Line: Record "XRC Line")
    var
        Cfg: Codeunit "XRC Cfg";
    begin
        case Cfg.Get() of
            'two-both':
                begin
                    Line.ExtProcRead('XA');
                    Line.TableProcRead('PA');
                end;
            'two-assign':
                Line.ExtProcAssign();
        end;
    end;
}

codeunit 97154 "XRC Subscriber B"
{
    [EventSubscriber(ObjectType::Table, Database::"XRC Line", 'OnModeElse', '', false, false)]
    local procedure OnModeElse(var Line: Record "XRC Line")
    begin
        Line.ExtProcRead('X');
        Line.TableProcRead('P');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRC Line", 'OnModeTwo', '', false, false)]
    local procedure OnModeTwo(var Line: Record "XRC Line")
    begin
        Line.ExtProcRead('X');
        Line.TableProcRead('P');
    end;

    // Base Application's Mfg. Requisition Line: it declares both parameters and reads xRec.
    [EventSubscriber(ObjectType::Table, Database::"XRC Line", 'OnModeWide', '', false, false)]
    local procedure OnModeWide(var Line: Record "XRC Line"; var Other: Record "XRC Other")
    begin
        Line.ExtProcRead('X');
        Line.TableProcRead('P');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRC Line", 'OnAfterValidateEvent', 'EventField', false, false)]
    local procedure OnAfterValidateEventField(var Rec: Record "XRC Line"; var xRec: Record "XRC Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XRC Cfg";
    begin
        if Cfg.Get() <> 'event' then
            exit;
        Cfg.Add('A x=' + Cfg.Fmt(xRec));
        Rec.ExtProcRead('XE');
    end;
}

codeunit 97155 "XRC Planner"
{
    procedure ValidateMode(var Line: Record "XRC Line")
    begin
        Line.Validate(Mode, Line.Mode::Production);
    end;

    procedure ValidateItem(var Line: Record "XRC Line")
    begin
        Line.Validate("Item No.", 'I2');
    end;

    procedure ValidateViaCodeunit(var Line: Record "XRC Line")
    begin
        Line.Validate(ViaCodeunit, true);
    end;

    procedure ValidateEventField(var Line: Record "XRC Line")
    begin
        Line.Validate(EventField, 1);
    end;

    [TryFunction]
    procedure TryValidateMode(var Line: Record "XRC Line")
    begin
        Line.Validate(Mode, Line.Mode::Production);
    end;

    [TryFunction]
    procedure TryValidateEventField(var Line: Record "XRC Line")
    begin
        Line.Validate(EventField, 1);
    end;

    // Base Application's Inventory Profile Offsetting.MaintainPlanningLine: a line read by FindLast, a new key by Init, the
    // value put in the field, then the one-argument Validate.
    procedure MaintainLine()
    var
        Line: Record "XRC Line";
        Cfg: Codeunit "XRC Cfg";
    begin
        Line.FindLast();
        Line.Init();
        Line."Line No." += 1;
        Line.Series := 'NEW';
        Line."Item No." := 'I2';
        Line.Validate("Item No.");
        Cfg.Add('R ' + Cfg.Fmt(Line));
    end;

    procedure CallExtProc(var Line: Record "XRC Line")
    begin
        Line.ExtProcRead('C');
    end;
}

codeunit 97156 "XRC Runner"
{
    TableNo = "XRC Line";

    trigger OnRun()
    var
        Cfg: Codeunit "XRC Cfg";
        Planner: Codeunit "XRC Planner";
    begin
        case Cfg.Get() of
            'sub', 'wide':
                Rec.Validate(Mode, Rec.Mode::Production);
            'nested', 'two-nested', 'wide-nested':
                Rec.Validate("Item No.", 'I2');
            'maintain', 'two-maintain', 'wide-maintain':
                Planner.MaintainLine();
            'event':
                Rec.Validate(EventField, 1);
        end;
    end;
}

report 97157 "XRC Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Line; "XRC Line")
        {
            trigger OnAfterGetRecord()
            var
                Cfg: Codeunit "XRC Cfg";
            begin
                Line.Series := 'NEW';
                // Base Application's Calculate Plan - Plan. Wksh. commits, then runs the codeunit guarded.
                if Cfg.Guarded() then begin
                    Commit();
                    if Codeunit.Run(Codeunit::"XRC Runner", Line) then
                        Cfg.Add('run ok');
                end else
                    Codeunit.Run(Codeunit::"XRC Runner", Line);
                Cfg.Add('report ' + Cfg.Fmt(Line));
            end;
        }
    }
}

codeunit 97158 "XRC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "XRC Cfg";
        Planner: Codeunit "XRC Planner";

    local procedure Initialize()
    var
        Line: Record "XRC Line";
        Other: Record "XRC Other";
    begin
        Cfg.Set('');
        Cfg.SetGuarded(false);
        Cfg.Take();
        Line.DeleteAll();
        Other.DeleteAll();
    end;

    // The row 1 stored as 0/OLD/I1; the record variable then holds 0/NEW/I1.
    local procedure AfterInsert(var Line: Record "XRC Line")
    begin
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
    end;

    local procedure Observe(var Observer: Codeunit "Probe Observer"; var Line: Record "XRC Line")
    begin
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Cfg.Fmt(Line));
        Cfg.Set('');
    end;

    [Test]
    procedure Sub_FromCodeunitProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('sub');
        Planner.ValidateMode(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_FromCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('sub');
        Codeunit.Run(Codeunit::"XRC Runner", Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_FromTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('sub');
        if Planner.TryValidateMode(Line) then
            Cfg.Add('try ok');
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;try ok;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_FromReportThroughCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('sub');
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;report 1/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_FromCodeunitProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('nested');
        Planner.ValidateItem(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_FromCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('nested');
        Codeunit.Run(Codeunit::"XRC Runner", Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_FromReportThroughCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('nested');
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;report 1/MID/I2;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_MaintainLineThroughCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('maintain');
        Codeunit.Run(Codeunit::"XRC Runner", Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_MaintainLineFromReport()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('maintain');
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;report 0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_MaintainLineFromReport()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('two-maintain');
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;report 0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    // The test procedure also names a handler: the same chain as TwoSubscribers_MaintainLineFromReport.
    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TwoSubscribers_MaintainLineFromReport_TestWithHandler()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('two-maintain');
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Message('done');
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;report 0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [Test]
    procedure TwoSubscribers_FirstDoesNothing()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('two-noop');
        Line.Validate(Mode, Line.Mode::Production);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_BothRead()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('two-both');
        Line.Validate(Mode, Line.Mode::Production);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;XA x=0/NEW/I1;PA x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_FirstAssignsXRec()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('two-assign');
        Line.Validate(Mode, Line.Mode::Production);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;XS x=0/NEW/I1;X x=0/SET/I1;P x=0/SET/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSubscribers_Nested_FromCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('two-nested');
        Codeunit.Run(Codeunit::"XRC Runner", Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_FromCodeunitProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('codeunit');
        Planner.ValidateViaCodeunit(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'V x=0/NEW/I1;C x=0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEvent_FromCodeunitProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event');
        Planner.ValidateEventField(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'E x=0/NEW/I1;A x=0/NEW/I1;XE x=0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEvent_FromCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event');
        Codeunit.Run(Codeunit::"XRC Runner", Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'E x=0/NEW/I1;A x=0/NEW/I1;XE x=0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEvent_FromTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('event');
        if Planner.TryValidateEventField(Line) then
            Cfg.Add('try ok');
        Observe(Observer, Line);
        Observer.Expect('log', 'E x=0/NEW/I1;A x=0/NEW/I1;XE x=0/NEW/I1;try ok;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    // The report commits and runs the codeunit guarded (`if Codeunit.Run(...)`), as Calculate Plan - Plan. Wksh. does.
    [Test]
    procedure Sub_FromTryFunctionAsStatement()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('sub');
        Planner.TryValidateMode(Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_FromReportThroughGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('sub');
        Cfg.SetGuarded(true);
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;run ok;report 1/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_MaintainLineFromReportThroughGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('maintain');
        Cfg.SetGuarded(true);
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;run ok;report 0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    // An event with two var parameters and two subscribers, the first declaring only the record (Base Application's
    // OnValidateReplenishmentSystemCaseElse with Asm. and Mfg. Requisition Line).
    [Test]
    procedure Wide_FirstDeclaresOnlyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('wide');
        Line.Validate(Mode, Line.Mode::Production);
        Observe(Observer, Line);
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Wide_Nested()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('wide-nested');
        Line.Validate("Item No.", 'I2');
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Wide_MaintainLineFromReportThroughGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('wide-maintain');
        Cfg.SetGuarded(true);
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;run ok;report 0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure Wide_MaintainLineFromReportThroughGuardedCodeunitRun_TestWithHandler()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRC Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('wide-maintain');
        Cfg.SetGuarded(true);
        Line.SetRange("Line No.", 1);
        Report.Run(Report::"XRC Report", false, false, Line);
        Message('done');
        Observe(Observer, Line);
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;R 1/MID/I2;run ok;report 0/NEW/I1;');
        Observer.Expect('record', '0/NEW/I1');
        Observer.Verify();
    end;
}
