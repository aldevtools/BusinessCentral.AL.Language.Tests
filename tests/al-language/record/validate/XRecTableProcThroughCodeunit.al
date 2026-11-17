// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78700..78706 (XTC Item, XTC Item Ext, XTC Item Card, XTC Cfg, XTC Mover,
//   XTC Iface Mover, XTC XRec Through Cu Tests) and the interface XTC IMover
// local object: the table procedures, table extension triggers and codeunits that read and write xRec are what is under test.
// Probe (al-runner issue 8189): what xRec a table procedure sees when it is called on a record that a codeunit procedure got as a var
//   parameter, while a trigger of that record runs. Every cell logs the trigger's own xRec ('T'), then what the procedure read of xRec
//   ('C' through the plain codeunit, 'I' through the interface, 'R' for Rec.Proc() from a trigger, 'X' for a table extension
//   procedure), and what a field trigger that reads xRec logged ('O'). The record held Value 10 before the change to 15. Cells:
//   - the reporter's ways 3 and 4 (a table procedure that is no trigger calls a plain codeunit, or a codeunit behind an interface, with
//     Rec; the codeunit calls a table procedure on it), after Insert and after Get of the row the transaction inserted;
//   - neighbors: the codeunit called from the field trigger directly; a fresh record that was never inserted; the Validate from a
//     TestPage; FieldRef.Validate; the procedure assigning xRec and the trigger reading it after the call; a Validate of another field
//     inside the procedure and inside the codeunit;
//   - OnInsert, OnModify and OnDelete as the running trigger, through the codeunit, and Rec.Proc() called directly from them (the
//     procedure reads xRec, and the procedure validates a field whose trigger reads xRec);
//   - a table extension: its field's OnValidate calling the codeunit that calls a base table procedure and Rec.Proc() from it; the
//     base field's OnValidate calling the codeunit that calls a table extension procedure; the table extension's OnBeforeModify
//     trigger calling Rec.Proc() and the codeunit;
//   - the measured chain on a temporary record, on a record read with FindFirst, on Get of a committed row, and on Get of a row the open
//     transaction modified through another variable (a committed row, and a row the transaction inserted).
// Already pinned elsewhere, not repeated: Rec.Proc(), this.Proc() and Proc() called from a field's OnValidate
//   (record/validate/XRecTableProcCalls.al).
// Facts (the same on 27.5, 28.5 and 29.0):
//   - a table procedure called through a codeunit (plain or behind an interface) on the var Rec of a running field trigger reads the
//     trigger's xRec (10), after Insert, after Get, on a fresh record, from a TestPage SetValue and from FieldRef.Validate, on a
//     temporary record, after FindFirst and after Get of a committed row or of a row another variable modified;
//   - xRec assigned in that procedure (99) is what the trigger reads after the call;
//   - Rec.Validate of another field inside the table procedure: that field's trigger reads the outer trigger's xRec (10); the same
//     Validate written in the codeunit on its var parameter: that trigger reads the record as it was at the call (15);
//   - in OnInsert the xRec is the inserted record (10); in OnModify and OnDelete called from code it equals Rec (15); a procedure
//     reached from those triggers, directly or through the codeunit, reads the same xRec as the trigger;
//   - a table extension field trigger and OnBeforeModify behave the same as the base triggers; a table extension procedure called
//     through the codeunit reads the base trigger's xRec.
// BC versions: 27.5, 28.5, 29.0

table 78701 "XTC Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Value; Integer)
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XTC Cfg";
                Mover: Codeunit "XTC Mover";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T x=' + Format(xRec.Value));
                case Cfg.Get() of
                    'way3':
                        CallPlain();
                    'way4':
                        CallIface();
                    'direct':
                        Mover.Handle(Rec);
                    'assign':
                        begin
                            CallPlainAssign();
                            Cfg.Add('T after x=' + Format(xRec.Value));
                        end;
                    'validate-in-proc':
                        CallPlainValidatingProc();
                    'validate-in-cu':
                        CallPlainValidateDirect();
                    'base-cu-ext':
                        Mover.HandleExt(Rec);
                end;
            end;
        }
        field(3; Other; Integer)
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XTC Cfg";
            begin
                Cfg.Add('O x=' + Format(xRec.Value) + '/' + Format(xRec.Other));
            end;
        }
        field(4; Note; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    begin
        RunWriteTrigger('ins');
    end;

    trigger OnModify()
    begin
        RunWriteTrigger('mod');
    end;

    trigger OnDelete()
    begin
        RunWriteTrigger('del');
    end;

    local procedure RunWriteTrigger(Prefix: Text)
    var
        Cfg: Codeunit "XTC Cfg";
    begin
        if not Cfg.Get().StartsWith(Prefix + '-') then
            exit;
        Cfg.Add('T x=' + Format(xRec.Value));
        case Cfg.Get() of
            Prefix + '-cu':
                CallPlain();
            Prefix + '-proc':
                Rec.ProcRead('R');
            Prefix + '-proc-val':
                Rec.ProcValidateOther();
        end;
    end;

    procedure ProcRead(Tag: Text)
    var
        Cfg: Codeunit "XTC Cfg";
    begin
        Cfg.Add(Tag + ' x=' + Format(xRec.Value));
    end;

    procedure ProcAssign()
    var
        Cfg: Codeunit "XTC Cfg";
    begin
        Cfg.Add('C x=' + Format(xRec.Value));
        xRec.Value := 99;
    end;

    procedure ProcValidateOther()
    begin
        Rec.Validate(Other, 5);
    end;

    local procedure CallPlain()
    var
        Mover: Codeunit "XTC Mover";
    begin
        Mover.Handle(Rec);
    end;

    local procedure CallIface()
    var
        Mover: Interface "XTC IMover";
        IfaceMover: Codeunit "XTC Iface Mover";
    begin
        Mover := IfaceMover;
        Mover.Handle(Rec, xRec);
    end;

    local procedure CallPlainAssign()
    var
        Mover: Codeunit "XTC Mover";
    begin
        Mover.HandleAssign(Rec);
    end;

    local procedure CallPlainValidatingProc()
    var
        Mover: Codeunit "XTC Mover";
    begin
        Mover.HandleValidatingProc(Rec);
    end;

    local procedure CallPlainValidateDirect()
    var
        Mover: Codeunit "XTC Mover";
    begin
        Mover.HandleValidateDirect(Rec);
    end;
}

tableextension 78702 "XTC Item Ext" extends "XTC Item"
{
    fields
    {
        field(78700; ExtTrig; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Cfg: Codeunit "XTC Cfg";
                Mover: Codeunit "XTC Mover";
            begin
                if not Cfg.Get().StartsWith('ext-') then
                    exit;
                Cfg.Add('E x=' + Format(xRec.Value));
                case Cfg.Get() of
                    'ext-cu':
                        Mover.Handle(Rec);
                    'ext-proc':
                        Rec.ProcRead('R');
                    'ext-proc-val':
                        Rec.ProcValidateOther();
                end;
            end;
        }
    }

    trigger OnBeforeModify()
    var
        Cfg: Codeunit "XTC Cfg";
        Mover: Codeunit "XTC Mover";
    begin
        if not Cfg.Get().StartsWith('extmod-') then
            exit;
        Cfg.Add('E x=' + Format(xRec.Value));
        case Cfg.Get() of
            'extmod-cu':
                Mover.Handle(Rec);
            'extmod-proc':
                Rec.ProcRead('R');
            'extmod-proc-val':
                Rec.ProcValidateOther();
        end;
    end;

    procedure ExtProcRead()
    var
        Cfg: Codeunit "XTC Cfg";
    begin
        Cfg.Add('X x=' + Format(xRec.Value));
    end;
}

page 78705 "XTC Item Card"
{
    PageType = Card;
    SourceTable = "XTC Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 78700 "XTC Cfg"
{
    SingleInstance = true;

    var
        Mode: Text;
        Log: Text;

    procedure Set(NewMode: Text)
    begin
        Mode := NewMode;
        Log := '';
    end;

    procedure Get(): Text
    begin
        exit(Mode);
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
}

interface "XTC IMover"
{
    procedure Handle(var Item: Record "XTC Item"; xItem: Record "XTC Item");
}

codeunit 78703 "XTC Mover"
{
    procedure Handle(var Item: Record "XTC Item")
    begin
        Item.ProcRead('C');
    end;

    procedure HandleAssign(var Item: Record "XTC Item")
    begin
        Item.ProcAssign();
    end;

    procedure HandleValidatingProc(var Item: Record "XTC Item")
    begin
        Item.ProcValidateOther();
    end;

    procedure HandleValidateDirect(var Item: Record "XTC Item")
    begin
        Item.Validate(Other, 7);
    end;

    procedure HandleExt(var Item: Record "XTC Item")
    begin
        Item.ExtProcRead();
    end;
}

codeunit 78704 "XTC Iface Mover" implements "XTC IMover"
{
    procedure Handle(var Item: Record "XTC Item"; xItem: Record "XTC Item")
    begin
        Item.ProcRead('I');
    end;
}

codeunit 78706 "XTC XRec Through Cu Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "XTC Cfg";

    // The row T1 with Value 10, inserted by Item itself (its buffer comes from its own Insert).
    local procedure AfterInsert(var Item: Record "XTC Item")
    begin
        Cfg.Set('');
        Item.DeleteAll();
        Item.Init();
        Item."No." := 'T1';
        Item.Value := 10;
        Item.Insert(false);
    end;

    // The row T1 inserted in this transaction, then read with Get by a cleared variable.
    local procedure AfterGet(var Item: Record "XTC Item")
    begin
        AfterInsert(Item);
        Clear(Item);
        Item.Get('T1');
    end;

    local procedure ValidateAndObserve(var Observer: Codeunit "Probe Observer"; var Item: Record "XTC Item"; Mode: Text)
    begin
        Cfg.Set(Mode);
        Item.Validate(Value, 15);
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('value', Format(Item.Value) + '/' + Format(Item.Other));
        Cfg.Set('');
    end;

    [Test]
    procedure Way3_PlainCodeunit_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterInsert(Item);
        ValidateAndObserve(Observer, Item, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_PlainCodeunit_AfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way4_Interface_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterInsert(Item);
        ValidateAndObserve(Observer, Item, 'way4');
        Observer.Expect('log', 'T x=10;I x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way4_Interface_AfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'way4');
        Observer.Expect('log', 'T x=10;I x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitFromTriggerDirectly_AfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'direct');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_FreshRecord()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        Cfg.Set('');
        Item.DeleteAll();
        Item.Init();
        Item."No." := 'T1';
        Item.Value := 10;
        ValidateAndObserve(Observer, Item, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_TestPageSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
        Card: TestPage "XTC Item Card";
    begin
        AfterInsert(Item);
        Card.OpenEdit();
        Card.GoToKey('T1');
        Cfg.Set('way3');
        Card.Value.SetValue(15);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
        Card.Close();
        Item.Get('T1');
        Observer.Observe('stored value', Format(Item.Value));
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('stored value', '15');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
        RecRef: RecordRef;
    begin
        AfterGet(Item);
        RecRef.GetTable(Item);
        Cfg.Set('way3');
        RecRef.Field(Item.FieldNo(Value)).Validate(15);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
        Observer.Observe('recref value', Format(RecRef.Field(Item.FieldNo(Value)).Value()));
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('recref value', '15');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_ProcAssignsXRec_TriggerReadsAfter()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'assign');
        Observer.Expect('log', 'T x=10;C x=10;T after x=99;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_ValidateInsideProc()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'validate-in-proc');
        Observer.Expect('log', 'T x=10;O x=10/0;');
        Observer.Expect('value', '15/5');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_ValidateInsideCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'validate-in-cu');
        Observer.Expect('log', 'T x=10;O x=15/0;');
        Observer.Expect('value', '15/7');
        Observer.Verify();
    end;

    // OnInsert, OnModify and OnDelete as the running trigger.
    local procedure InsertWith(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Item: Record "XTC Item";
    begin
        Cfg.Set('');
        Item.DeleteAll();
        Item.Init();
        Item."No." := 'T1';
        Item.Value := 10;
        Cfg.Set(Mode);
        Item.Insert(true);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
    end;

    local procedure ModifyWith(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        Item.Value := 15;
        Cfg.Set(Mode);
        Item.Modify(true);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
    end;

    local procedure DeleteWith(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        Item.Value := 15;
        Cfg.Set(Mode);
        Item.Delete(true);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
    end;

    [Test]
    procedure OnInsert_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertWith(Observer, 'ins-cu');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Verify();
    end;

    [Test]
    procedure OnInsert_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertWith(Observer, 'ins-proc');
        Observer.Expect('log', 'T x=10;R x=10;');
        Observer.Verify();
    end;

    [Test]
    procedure OnInsert_RecProcValidates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertWith(Observer, 'ins-proc-val');
        Observer.Expect('log', 'T x=10;O x=10/0;');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWith(Observer, 'mod-cu');
        Observer.Expect('log', 'T x=15;C x=15;');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWith(Observer, 'mod-proc');
        Observer.Expect('log', 'T x=15;R x=15;');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_RecProcValidates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWith(Observer, 'mod-proc-val');
        Observer.Expect('log', 'T x=15;O x=15/0;');
        Observer.Verify();
    end;

    [Test]
    procedure OnDelete_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DeleteWith(Observer, 'del-cu');
        Observer.Expect('log', 'T x=15;C x=15;');
        Observer.Verify();
    end;

    [Test]
    procedure OnDelete_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DeleteWith(Observer, 'del-proc');
        Observer.Expect('log', 'T x=15;R x=15;');
        Observer.Verify();
    end;

    [Test]
    procedure OnDelete_RecProcValidates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DeleteWith(Observer, 'del-proc-val');
        Observer.Expect('log', 'T x=15;O x=15/0;');
        Observer.Verify();
    end;

    // Table extension cells.
    local procedure ValidateExtAndObserve(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        Cfg.Set(Mode);
        Item.Validate(ExtTrig, 1);
        Observer.Observe('log', Cfg.Take());
        Cfg.Set('');
    end;

    [Test]
    procedure ExtField_Codeunit_BaseProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateExtAndObserve(Observer, 'ext-cu');
        Observer.Expect('log', 'E x=10;C x=10;');
        Observer.Verify();
    end;

    [Test]
    procedure ExtField_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateExtAndObserve(Observer, 'ext-proc');
        Observer.Expect('log', 'E x=10;R x=10;');
        Observer.Verify();
    end;

    [Test]
    procedure ExtField_RecProcValidates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateExtAndObserve(Observer, 'ext-proc-val');
        Observer.Expect('log', 'E x=10;O x=10/0;');
        Observer.Verify();
    end;

    [Test]
    procedure BaseField_Codeunit_ExtProc()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
    begin
        AfterGet(Item);
        ValidateAndObserve(Observer, Item, 'base-cu-ext');
        Observer.Expect('log', 'T x=10;X x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure ExtOnBeforeModify_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWith(Observer, 'extmod-cu');
        Observer.Expect('log', 'E x=15;C x=15;');
        Observer.Verify();
    end;

    [Test]
    procedure ExtOnBeforeModify_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWith(Observer, 'extmod-proc');
        Observer.Expect('log', 'E x=15;R x=15;');
        Observer.Verify();
    end;

    [Test]
    procedure ExtOnBeforeModify_RecProcValidates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyWith(Observer, 'extmod-proc-val');
        Observer.Expect('log', 'E x=15;O x=15/0;');
        Observer.Verify();
    end;

    // Record states of the measured chain (way 3).
    [Test]
    procedure Way3_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempItem: Record "XTC Item" temporary;
    begin
        Cfg.Set('');
        TempItem."No." := 'T1';
        TempItem.Value := 10;
        TempItem.Insert(false);
        ValidateAndObserve(Observer, TempItem, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
        Read: Record "XTC Item";
    begin
        AfterInsert(Item);
        Read.FindFirst();
        ValidateAndObserve(Observer, Read, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_GetOfCommittedRow()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
        Read: Record "XTC Item";
    begin
        AfterInsert(Item);
        Commit();
        Read.Get('T1');
        ValidateAndObserve(Observer, Read, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_GetOfCommittedRowModifiedByOther()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
        Other: Record "XTC Item";
        Read: Record "XTC Item";
    begin
        AfterInsert(Item);
        Commit();
        Other.Get('T1');
        Other.Note := 'm';
        Other.Modify(false);
        Read.Get('T1');
        ValidateAndObserve(Observer, Read, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;

    [Test]
    procedure Way3_GetOfInsertedRowModifiedByOther()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "XTC Item";
        Other: Record "XTC Item";
        Read: Record "XTC Item";
    begin
        AfterInsert(Item);
        Other.Get('T1');
        Other.Note := 'm';
        Other.Modify(false);
        Read.Get('T1');
        ValidateAndObserve(Observer, Read, 'way3');
        Observer.Expect('log', 'T x=10;C x=10;');
        Observer.Expect('value', '15/0');
        Observer.Verify();
    end;
}
