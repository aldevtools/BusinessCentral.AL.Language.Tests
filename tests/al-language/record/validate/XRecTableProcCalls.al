// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 76720..76723
// local object: the table procedures and the table extension triggers that read and write xRec are what is under test
// Probe (al-runner issues 7785, 7792): what xRec a table procedure sees when a field's OnValidate trigger calls it, and whether an
//   assignment to xRec in the procedure shows in the trigger afterwards. Cells: the call as `Rec.Proc()`, `this.Proc()` and `Proc()`;
//   a record read from the database (xRec holds the stored values) and a fresh record after Init (xRec equals a blank record); and the
//   same three calls from a table extension: its own field's OnValidate and the OnAfterValidate of a base field, calling the base
//   table's procedure. Each cell logs what the procedure read of xRec ('P'), what the trigger read of xRec after the call ('T' or 'E').
// BC versions: 27, 28, 29

codeunit 76720 "XTP Cfg"
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

table 76721 "XTP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; A; Text[30])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XTP Cfg";
            begin
                case Cfg.Get() of
                    'rec':
                        Rec.ProcWrite();
                    'this':
                        this.ProcWrite();
                    'plain':
                        ProcWrite();
                    else
                        exit;
                end;
                Cfg.Add('T x=' + xRec."Code" + '/' + xRec.A + '/' + xRec.Note);
            end;
        }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }

    procedure ProcWrite()
    var
        Cfg: Codeunit "XTP Cfg";
    begin
        Cfg.Add('P x=' + xRec."Code" + '/' + xRec.A + '/' + xRec.Note);
        xRec.Note := 'FROMPROC';
    end;
}

tableextension 76722 "XTP Row Ext" extends "XTP Row"
{
    fields
    {
        field(76720; ExtA; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Cfg: Codeunit "XTP Cfg";
            begin
                case Cfg.Get() of
                    'ext-rec':
                        Rec.ProcWrite();
                    'ext-this':
                        this.ProcWrite();
                    'ext-plain':
                        ProcWrite();
                    else
                        exit;
                end;
                Cfg.Add('E x=' + xRec."Code" + '/' + xRec.A + '/' + xRec.Note);
            end;
        }
        modify(A)
        {
            trigger OnAfterValidate()
            var
                Cfg: Codeunit "XTP Cfg";
            begin
                case Cfg.Get() of
                    'after-rec':
                        Rec.ProcWrite();
                    'after-this':
                        this.ProcWrite();
                    'after-plain':
                        ProcWrite();
                    else
                        exit;
                end;
                Cfg.Add('E x=' + xRec."Code" + '/' + xRec.A + '/' + xRec.Note);
            end;
        }
    }
}

codeunit 76723 "XTP XRec Table Proc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "XTP Cfg";

    // Validate on a row read from the database: xRec holds the stored values.
    local procedure Stored(var Observer: Codeunit "Probe Observer"; Mode: Text; Ext: Boolean)
    var
        Row: Record "XTP Row";
        Old: Record "XTP Row";
    begin
        Old.DeleteAll();
        Old.Init();
        Old."Code" := 'R1';
        Old.A := 'stored';
        Old.Note := 'note';
        Old.Insert();
        Row.Get('R1');
        Row.Note := 'changed';
        Cfg.Set(Mode);
        if Ext then
            Row.Validate(ExtA, 'v')
        else
            Row.Validate(A, 'v');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('rec after', Row."Code" + '/' + Row.A + '/' + Row.Note);
        Cfg.Set('');
        Old.DeleteAll();
        Observer.Finish();
    end;

    // Validate on a fresh record after Init: xRec equals a blank record.
    local procedure Fresh(var Observer: Codeunit "Probe Observer"; Mode: Text; Ext: Boolean)
    var
        Row: Record "XTP Row";
    begin
        Row.Init();
        Cfg.Set(Mode);
        if Ext then
            Row.Validate(ExtA, 'v')
        else
            Row.Validate(A, 'v');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('rec after', Row."Code" + '/' + Row.A + '/' + Row.Note);
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Stored_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'rec', false);
    end;

    [Test]
    procedure Stored_ThisProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'this', false);
    end;

    [Test]
    procedure Stored_PlainProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'plain', false);
    end;

    [Test]
    procedure Fresh_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Observer, 'rec', false);
    end;

    [Test]
    procedure Fresh_ThisProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Observer, 'this', false);
    end;

    [Test]
    procedure Fresh_PlainProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Observer, 'plain', false);
    end;

    [Test]
    procedure Stored_ExtField_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'ext-rec', true);
    end;

    [Test]
    procedure Stored_ExtField_ThisProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'ext-this', true);
    end;

    [Test]
    procedure Stored_ExtField_PlainProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'ext-plain', true);
    end;

    [Test]
    procedure Stored_ExtAfterValidate_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'after-rec', false);
    end;

    [Test]
    procedure Stored_ExtAfterValidate_ThisProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'after-this', false);
    end;

    [Test]
    procedure Stored_ExtAfterValidate_PlainProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Stored(Observer, 'after-plain', false);
    end;

    [Test]
    procedure Fresh_ExtField_PlainProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Observer, 'ext-plain', true);
    end;

    [Test]
    procedure Fresh_ExtAfterValidate_RecProc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Observer, 'after-rec', false);
    end;
}
