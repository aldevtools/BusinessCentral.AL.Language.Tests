// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97090..97096 (XRS Line, XRS Line Ext, XRS Cfg, XRS Subscriber,
//   XRS Helper, XRS Tests, XRS Other Row)
// local object: the table and table extension procedures, the field triggers and the event subscribers that read xRec are what is under
//   test.
// Probe (al-runner issues 8284 and 8306): what xRec a procedure of a table or of its table extension reads when an event subscriber or a codeunit
//   calls it on the record that a field OnValidate trigger hands on as a var parameter. Base Application's path: the OnValidate of
//   Requisition Line "Replenishment System" raises OnValidateReplenishmentSystemCaseElse(Rec, StockkeepingUnit), and the subscriber in
//   codeunit "Mfg. Requisition Line" calls the table extension procedure SetReplenishmentSystemFromProdOrder, which reads xRec. Every
//   cell logs the trigger's own xRec ('T' for Mode, 'I' for "Item No.", 'V' for ViaCodeunit; 'T after', 'I after' and 'V after' once
//   the call returned), then what each procedure read of xRec ('X' the table extension procedure, 'P' the table procedure; 'X2' and
//   'P2' through the event with two var parameters; 'XV' and 'PV' on the by-value copy; 'XA' and 'PA' from an OnAfterValidateEvent
//   subscriber, 'A' its xRec parameter; 'C' the table extension procedure and 'CP' the table procedure through a codeunit; 'XS' the
//   table extension procedure that then assigns xRec.Series := 'SET'). A record is logged as Mode ordinal/Series/"Item No.". Before
//   the Validate the stored row holds 0/OLD/I1 and the record variable 0/NEW/I1, so a read of the stored row shows apart from the
//   record's before-image.
// Cells:
//   - the subscriber of an integration event the table raises from a field OnValidate with var Rec calls a table extension procedure
//     and a table procedure on it: after Insert, after Get, after FindLast, FindFirst, FindSet, Find('=') and Next, on a fresh record,
//     on a temporary record; the event with a second var record parameter of another table, as Base Application's;
//   - the same Validate nested by the table's own code: "Item No." OnValidate changes Series, then calls Validate(Mode) itself, or
//     through one, two or three table procedures; the two-procedure case also after Get, after FindLast, after an earlier Validate of
//     another field, and on a line FindLast read and Init then gave a new key, validated with the value already in the field (Base
//     Application's planning: Inventory Profile Offsetting.MaintainPlanningLine);
//   - the table extension procedure assigning xRec, directly under the Mode Validate and nested in the "Item No." Validate;
//   - a field OnValidate handing Rec to a codeunit that calls a table extension procedure (also assigning xRec) or a table procedure;
//   - neighbors: the event's record parameter by value; an OnAfterValidateEvent subscriber calling the same procedures on Rec;
//   - (al-runner issue 8306) OnAfterValidateEvent and OnBeforeValidateEvent subscribers calling them on Rec: after Insert, Get,
//     FindFirst, fresh, temporary, a subscriber that does not declare xRec, the table extension procedure assigning xRec.
// Facts (measured on 29.1):
//   - a table extension procedure and a table procedure that an event subscriber calls on the var record the field trigger raised the
//     event with read the trigger's xRec (0/NEW/I1, the record before the Validate, not the stored row), after Insert, after Get,
//     after FindLast, FindFirst, FindSet, Find('=') and Next, on a fresh record and on a temporary record, with one or two var
//     parameters;
//   - a Validate that the field trigger nests, itself or through one, two or three table procedures, in another field's OnValidate:
//     the inner trigger and the procedures the subscriber calls read the before-image of the outer Validate (0/NEW/I1, not 0/MID/I1;
//     0/NEW/I2 on the new line);
//   - xRec assigned in the table extension procedure is what the trigger reads after the call; nested, both triggers read it;
//   - a codeunit the field trigger hands Rec to: the table extension procedure and the table procedure it calls read the trigger's
//     xRec, not the stored row, and an assignment shows in the trigger;
//   - the event's record parameter by value: the procedures called on the copy read a blank xRec (0//);
//   - an OnAfterValidateEvent subscriber: its xRec parameter and the procedures it calls on Rec read the trigger's xRec, also after
//     Get, on a fresh record and when the subscriber does not declare xRec; xRec assigned in the table extension procedure is
//     what the subscriber's xRec parameter reads after the call; an OnBeforeValidateEvent subscriber: the same, before the
//     trigger runs.
// BC versions: 27.5, 28.5, 29.0

table 97090 "XRS Line"
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
                Cfg: Codeunit "XRS Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T x=' + Cfg.Fmt(xRec));
                case Cfg.Get() of
                    'sub', 'nested', 'nested-direct', 'nested-three', 'nested-one', 'nested-get', 'sub-assign', 'nested-assign':
                        OnValidateModeCaseElse(Rec);
                    'sub-byvalue':
                        OnValidateModeByValue(Rec);
                    'sub-two':
                        OnValidateModeWithOther(Rec, OtherRow);
                end;
                if Cfg.Get() in ['sub-assign', 'nested-assign'] then
                    Cfg.Add('T after x=' + Cfg.Fmt(xRec));
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRS Cfg";
            begin
                if not (Cfg.Get() in ['nested', 'nested-direct', 'nested-three', 'nested-one', 'nested-get', 'nested-assign']) then
                    exit;
                Cfg.Add('I x=' + Cfg.Fmt(xRec));
                Series := 'MID';
                case Cfg.Get() of
                    'nested', 'nested-get', 'nested-assign':
                        CopyFromItem();
                    'nested-direct':
                        Validate(Mode, Mode::Production);
                    'nested-three':
                        PrepareFromItem();
                    'nested-one':
                        UpdateMode();
                end;
                if Cfg.Get() = 'nested-assign' then
                    Cfg.Add('I after x=' + Cfg.Fmt(xRec));
            end;
        }
        field(5; ViaCodeunit; Boolean)
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XRS Cfg";
                Helper: Codeunit "XRS Helper";
            begin
                if not (Cfg.Get() in ['codeunit', 'codeunit-base', 'codeunit-assign']) then
                    exit;
                Cfg.Add('V x=' + Cfg.Fmt(xRec));
                case Cfg.Get() of
                    'codeunit':
                        Helper.CallExtProc(Rec);
                    'codeunit-base':
                        Helper.CallTableProc(Rec);
                    'codeunit-assign':
                        begin
                            Helper.CallExtProcAssign(Rec);
                            Cfg.Add('V after x=' + Cfg.Fmt(xRec));
                        end;
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    var
        OtherRow: Record "XRS Other Row";

    local procedure PrepareFromItem()
    begin
        CopyFromItem();
    end;

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
        Cfg: Codeunit "XRS Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateModeCaseElse(var Line: Record "XRS Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateModeByValue(Line: Record "XRS Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateModeWithOther(var Line: Record "XRS Line"; var Other: Record "XRS Other Row")
    begin
    end;
}

table 97096 "XRS Other Row"
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

tableextension 97091 "XRS Line Ext" extends "XRS Line"
{
    procedure ExtProcRead(Tag: Text)
    var
        Cfg: Codeunit "XRS Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Cfg.Fmt(xRec));
    end;

    procedure ExtProcAssign()
    var
        Cfg: Codeunit "XRS Cfg";
    begin
        Cfg.Add('XS x=' + Cfg.Fmt(xRec));
        xRec.Series := 'SET';
    end;
}

codeunit 97092 "XRS Cfg"
{
    SingleInstance = true;

    var
        CfgMode: Text;
        Log: Text;

    procedure Set(NewMode: Text)
    begin
        CfgMode := NewMode;
        Log := '';
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

    procedure Fmt(Line: Record "XRS Line"): Text
    begin
        exit(Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
    end;
}

codeunit 97093 "XRS Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"XRS Line", 'OnValidateModeCaseElse', '', false, false)]
    local procedure OnValidateModeCaseElse(var Line: Record "XRS Line")
    var
        Cfg: Codeunit "XRS Cfg";
    begin
        if Cfg.Get() in ['sub-assign', 'nested-assign'] then begin
            Line.ExtProcAssign();
            exit;
        end;
        Line.ExtProcRead('X');
        Line.TableProcRead('P');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRS Line", 'OnValidateModeWithOther', '', false, false)]
    local procedure OnValidateModeWithOther(var Line: Record "XRS Line"; var Other: Record "XRS Other Row")
    begin
        Line.ExtProcRead('X2');
        Line.TableProcRead('P2');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRS Line", 'OnValidateModeByValue', '', false, false)]
    local procedure OnValidateModeByValue(Line: Record "XRS Line")
    begin
        Line.ExtProcRead('XV');
        Line.TableProcRead('PV');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRS Line", 'OnAfterValidateEvent', 'Mode', false, false)]
    local procedure OnAfterValidateMode(var Rec: Record "XRS Line"; var xRec: Record "XRS Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XRS Cfg";
    begin
        if Cfg.Get() = 'after-assign' then begin
            Rec.ExtProcAssign();
            Cfg.Add('A after x=' + Cfg.Fmt(xRec));
            exit;
        end;
        if Cfg.Get() <> 'after-event' then
            exit;
        Cfg.Add('A x=' + Cfg.Fmt(xRec));
        Rec.ExtProcRead('XA');
        Rec.TableProcRead('PA');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRS Line", 'OnBeforeValidateEvent', 'Mode', false, false)]
    local procedure OnBeforeValidateMode(var Rec: Record "XRS Line"; var xRec: Record "XRS Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XRS Cfg";
    begin
        if Cfg.Get() <> 'before-event' then
            exit;
        Cfg.Add('B x=' + Cfg.Fmt(xRec));
        Rec.ExtProcRead('XB');
        Rec.TableProcRead('PB');
    end;

    [EventSubscriber(ObjectType::Table, Database::"XRS Line", 'OnAfterValidateEvent', 'Mode', false, false)]
    local procedure OnAfterValidateModeRecOnly(var Rec: Record "XRS Line")
    var
        Cfg: Codeunit "XRS Cfg";
    begin
        if Cfg.Get() <> 'after-reconly' then
            exit;
        Rec.ExtProcRead('XN');
        Rec.TableProcRead('PN');
    end;
}

codeunit 97094 "XRS Helper"
{
    procedure CallExtProc(var Line: Record "XRS Line")
    begin
        Line.ExtProcRead('C');
    end;

    procedure CallTableProc(var Line: Record "XRS Line")
    begin
        Line.TableProcRead('CP');
    end;

    procedure CallExtProcAssign(var Line: Record "XRS Line")
    begin
        Line.ExtProcAssign();
    end;
}

codeunit 97095 "XRS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "XRS Cfg";

    local procedure Initialize()
    var
        Line: Record "XRS Line";
        OtherRow: Record "XRS Other Row";
    begin
        Cfg.Set('');
        Line.DeleteAll();
        OtherRow.DeleteAll();
    end;

    // The row 1 stored as 0/OLD/I1; the record variable then holds 0/NEW/I1.
    local procedure AfterInsert(var Line: Record "XRS Line")
    begin
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
    end;

    local procedure ValidateModeAndObserve(var Observer: Codeunit "Probe Observer"; var Line: Record "XRS Line"; CfgMode: Text)
    begin
        Cfg.Set(CfgMode);
        Line.Validate(Mode, Line.Mode::Production);
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Cfg.Fmt(Line));
        Cfg.Set('');
    end;

    local procedure ValidateItemAndObserve(var Observer: Codeunit "Probe Observer"; var Line: Record "XRS Line"; CfgMode: Text)
    begin
        Cfg.Set(CfgMode);
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Cfg.Fmt(Line));
        Cfg.Set('');
    end;

    [Test]
    procedure Subscriber_VarRec_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'sub');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_AfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Clear(Line);
        Line.Get(1);
        Line.Series := 'NEW';
        ValidateModeAndObserve(Observer, Line, 'sub');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_FreshRecord()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        Line.Init();
        Line."Line No." := 1;
        Line.Series := 'NEW';
        Line."Item No." := 'I1';
        ValidateModeAndObserve(Observer, Line, 'sub');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempLine: Record "XRS Line" temporary;
    begin
        Initialize();
        AfterInsert(TempLine);
        ValidateModeAndObserve(Observer, TempLine, 'sub');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedValidateInTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateItemAndObserve(Observer, Line, 'nested');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedAfterEarlierValidate()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Line.Validate(Series, 'NEW');
        ValidateItemAndObserve(Observer, Line, 'nested');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_ByValueRec_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'sub-byvalue');
        Observer.Expect('log', 'T x=0/NEW/I1;XV x=0//;PV x=0//;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEventSubscriber_RecProcs_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-event');
        Observer.Expect('log', 'T x=0/NEW/I1;A x=0/NEW/I1;XA x=0/NEW/I1;PA x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_ExtProc_BufferDiffersFromRow()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('codeunit');
        Line.Validate(ViaCodeunit, true);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
        Observer.Expect('log', 'V x=0/NEW/I1;C x=0/NEW/I1;');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedValidateInTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateItemAndObserve(Observer, Line, 'nested-direct');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedValidateInThirdTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateItemAndObserve(Observer, Line, 'nested-three');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedValidateInFirstTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateItemAndObserve(Observer, Line, 'nested-one');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedAfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Clear(Line);
        Line.Get(1);
        Line.Series := 'NEW';
        ValidateItemAndObserve(Observer, Line, 'nested-get');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_TwoVarParams_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'sub-two');
        Observer.Expect('log', 'T x=0/NEW/I1;X2 x=0/NEW/I1;P2 x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_ExtProcAssignsXRec_TriggerReadsAfter()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'sub-assign');
        Observer.Expect('log', 'T x=0/NEW/I1;XS x=0/NEW/I1;T after x=0/SET/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_ExtProcAssignsXRec_Nested_TriggersReadAfter()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateItemAndObserve(Observer, Line, 'nested-assign');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;XS x=0/NEW/I1;T after x=0/SET/I1;I after x=0/SET/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_BaseProc_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('codeunit-base');
        Line.Validate(ViaCodeunit, true);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
        Observer.Expect('log', 'V x=0/NEW/I1;CP x=0/NEW/I1;');
        Observer.Verify();
    end;

    [Test]
    procedure Codeunit_ExtProcAssignsXRec_TriggerReadsAfter()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Cfg.Set('codeunit-assign');
        Line.Validate(ViaCodeunit, true);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
        Observer.Expect('log', 'V x=0/NEW/I1;XS x=0/NEW/I1;V after x=0/SET/I1;');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_ReadByFindLast()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
        Found: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Found.FindLast();
        Found.Series := 'NEW';
        ValidateModeAndObserve(Observer, Found, 'sub');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_NestedReadByFindLast()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
        Found: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Found.FindLast();
        Found.Series := 'NEW';
        ValidateItemAndObserve(Observer, Found, 'nested');
        Observer.Expect('log', 'I x=0/NEW/I1;T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    // Base Application's planning (Inventory Profile Offsetting.MaintainPlanningLine): FindLast, Init, a new key, the fields
    // assigned, then Validate("No.") with the value already in the field.
    [Test]
    procedure Subscriber_VarRec_NestedFoundThenInitNewLine()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
        Found: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Found.FindLast();
        Found.Init();
        Found."Line No." := 2;
        Found.Series := 'NEW';
        Found."Item No." := 'I2';
        Cfg.Set('nested');
        Found.Validate(Found."Item No.");
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Cfg.Fmt(Found));
        Cfg.Set('');
        Observer.Expect('log', 'I x=0/NEW/I2;T x=0/NEW/I2;X x=0/NEW/I2;P x=0/NEW/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    // Row 1 stored as 0/OLD/I1 and row 2 as 0/OLD2/I1; Found reads one of them with Method, then holds Series NEW.
    local procedure ReadWithAndValidate(var Observer: Codeunit "Probe Observer"; Method: Text)
    var
        Line: Record "XRS Line";
        Found: Record "XRS Line";
    begin
        AfterInsert(Line);
        Line."Line No." := 2;
        Line.Series := 'OLD2';
        Line.Insert(false);
        case Method of
            'FindFirst':
                Found.FindFirst();
            'FindSet':
                Found.FindSet();
            'Find=':
                begin
                    Found."Line No." := 2;
                    Found.Find('=');
                end;
            'Next':
                begin
                    Found.FindFirst();
                    Found.Next();
                end;
        end;
        Found.Series := 'NEW';
        ValidateModeAndObserve(Observer, Found, 'sub');
    end;

    [Test]
    procedure Subscriber_VarRec_ReadByFindFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ReadWithAndValidate(Observer, 'FindFirst');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_ReadByFindSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ReadWithAndValidate(Observer, 'FindSet');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_ReadByFindEqual()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ReadWithAndValidate(Observer, 'Find=');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_VarRec_ReadByNext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ReadWithAndValidate(Observer, 'Next');
        Observer.Expect('log', 'T x=0/NEW/I1;X x=0/NEW/I1;P x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    // OnAfterValidateEvent and OnBeforeValidateEvent subscribers calling procedures on Rec (al-runner issue 8306).
    [Test]
    procedure AfterValidateEventSubscriber_RecProcs_AfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Clear(Line);
        Line.Get(1);
        Line.Series := 'NEW';
        ValidateModeAndObserve(Observer, Line, 'after-event');
        Observer.Expect('log', 'T x=0/NEW/I1;A x=0/NEW/I1;XA x=0/NEW/I1;PA x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEventSubscriber_RecProcs_FreshRecord()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        Line.Init();
        Line."Line No." := 1;
        Line.Series := 'NEW';
        Line."Item No." := 'I1';
        ValidateModeAndObserve(Observer, Line, 'after-event');
        Observer.Expect('log', 'T x=0/NEW/I1;A x=0/NEW/I1;XA x=0/NEW/I1;PA x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEventSubscriber_ExtProcAssignsXRec_SubscriberReadsAfter()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-assign');
        Observer.Expect('log', 'T x=0/NEW/I1;XS x=0/NEW/I1;A after x=0/SET/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeValidateEventSubscriber_RecProcs_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'before-event');
        Observer.Expect('log', 'B x=0/NEW/I1;XB x=0/NEW/I1;PB x=0/NEW/I1;T x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEventSubscriberWithoutXRec_RecProcs_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        ValidateModeAndObserve(Observer, Line, 'after-reconly');
        Observer.Expect('log', 'T x=0/NEW/I1;XN x=0/NEW/I1;PN x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEventSubscriber_RecProcs_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempLine: Record "XRS Line" temporary;
    begin
        Initialize();
        AfterInsert(TempLine);
        ValidateModeAndObserve(Observer, TempLine, 'after-event');
        Observer.Expect('log', 'T x=0/NEW/I1;A x=0/NEW/I1;XA x=0/NEW/I1;PA x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateEventSubscriber_RecProcs_ReadByFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XRS Line";
        Found: Record "XRS Line";
    begin
        Initialize();
        AfterInsert(Line);
        Found.FindFirst();
        Found.Series := 'NEW';
        ValidateModeAndObserve(Observer, Found, 'after-event');
        Observer.Expect('log', 'T x=0/NEW/I1;A x=0/NEW/I1;XA x=0/NEW/I1;PA x=0/NEW/I1;');
        Observer.Expect('record', '1/NEW/I1');
        Observer.Verify();
    end;
}
