// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72896, page 72897, log codeunit 72898 (used by codeunit 72899 only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Lookup() on three controls over one field: no control trigger, a control OnLookup answering true, a control OnLookup answering false; the log of Text at entry, table OnLookup and OnValidate; the row after Close
// BC versions: 29 (27 and 28 by CI)

codeunit 72898 "LT FLook Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Reset()
    begin
        Log := '';
    end;

    procedure Add(S: Text)
    begin
        Log += S + ';';
    end;

    procedure Get(): Text
    begin
        exit(Log);
    end;
}

table 72896 "LT FLook Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pick; Text[30])
        {
            trigger OnLookup()
            var
                L: Codeunit "LT FLook Log";
            begin
                L.Add('tblLookup(' + Rec.Pick + ')');
                Rec.Pick := 'FromTable';
            end;

            trigger OnValidate()
            var
                L: Codeunit "LT FLook Log";
            begin
                L.Add('validate(' + Rec.Pick + ')');
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 72897 "LT FLook Card"
{
    PageType = Card;
    SourceTable = "LT FLook Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(PickTbl; Rec.Pick) { ApplicationArea = All; }
            field(PickTrue; Rec.Pick)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    L: Codeunit "LT FLook Log";
                begin
                    L.Add('ctlTrue(' + Text + ')');
                    Text := 'FromCtl';
                    exit(true);
                end;
            }
            field(PickFalse; Rec.Pick)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    L: Codeunit "LT FLook Log";
                begin
                    L.Add('ctlFalse(' + Text + ')');
                    Text := 'Ignored';
                    exit(false);
                end;
            }
        }
    }
}

codeunit 72899 "LT FLook Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLookup(var TP: TestPage "LT FLook Card"; Which: Integer)
    begin
        case Which of
            1:
                TP.PickTbl.Lookup();
            2:
                TP.PickTrue.Lookup();
            3:
                TP.PickFalse.Lookup();
        end;
    end;

    local procedure Open(var TP: TestPage "LT FLook Card"; Initial: Text)
    var
        Row: Record "LT FLook Row";
        L: Codeunit "LT FLook Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Pick := CopyStr(Initial, 1, 30);
        Row.Insert();
        L.Reset();
        TP.OpenEdit();
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Which: Integer; Initial: Text; Typed: Text)
    var
        TP: TestPage "LT FLook Card";
        L: Codeunit "LT FLook Log";
        Row: Record "LT FLook Row";
    begin
        Open(TP, Initial);
        if Typed <> '' then
            TP.PickTbl.SetValue(Typed);
        L.Reset();
        if TryLookup(TP, Which) then
            Observer.Observe(Name + '.result', 'log=' + L.Get() + ' shows=[' + TP.PickTbl.Value() + ']')
        else
            Observer.ObserveError(Name + '.result');
        TP.Close();
        Row.Get(1);
        Observer.Observe(Name + '.row', '[' + Row.Pick + ']');
    end;

    [Test]
    procedure Lookup_NoControlTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'tbl_initial', 1, 'Start', '');
        Run(Observer, 'tbl_typed', 1, 'Start', 'Typed');
        Run(Observer, 'tbl_empty', 1, '', '');
        Observer.Expect('tbl_initial.result', 'log=tblLookup(Start); shows=[FromTable]');
        Observer.Expect('tbl_initial.row', '[FromTable]');
        Observer.Expect('tbl_typed.result', 'log=tblLookup(Typed); shows=[FromTable]');
        Observer.Expect('tbl_typed.row', '[FromTable]');
        Observer.Expect('tbl_empty.result', 'log=tblLookup(); shows=[FromTable]');
        Observer.Expect('tbl_empty.row', '[FromTable]');
        Observer.Verify();
    end;

    [Test]
    procedure Lookup_ControlTriggerTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'true_initial', 2, 'Start', '');
        Run(Observer, 'true_typed', 2, 'Start', 'Typed');
        Run(Observer, 'true_empty', 2, '', '');
        Observer.Expect('true_initial.result', 'log=ctlTrue(Start);validate(FromCtl); shows=[FromCtl]');
        Observer.Expect('true_initial.row', '[FromCtl]');
        Observer.Expect('true_typed.result', 'log=ctlTrue(Typed);validate(FromCtl); shows=[FromCtl]');
        Observer.Expect('true_typed.row', '[FromCtl]');
        Observer.Expect('true_empty.result', 'log=ctlTrue();validate(FromCtl); shows=[FromCtl]');
        Observer.Expect('true_empty.row', '[FromCtl]');
        Observer.Verify();
    end;

    [Test]
    procedure Lookup_ControlTriggerFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'false_initial', 3, 'Start', '');
        Run(Observer, 'false_typed', 3, 'Start', 'Typed');
        Observer.Expect('false_initial.result', 'log=ctlFalse(Start); shows=[Start]');
        Observer.Expect('false_initial.row', '[Start]');
        Observer.Expect('false_typed.result', 'log=ctlFalse(Typed); shows=[Typed]');
        Observer.Expect('false_typed.row', '[Typed]');
        Observer.Verify();
    end;
}
