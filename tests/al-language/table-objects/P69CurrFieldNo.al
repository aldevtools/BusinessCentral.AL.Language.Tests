// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-currfieldno-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71169, codeunits 71170 (log), 71171 and 71172, tableextension 82359 (misc/lt-bo2-odd-leads)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): CurrFieldNo := FieldNo(X) and CurrFieldNo passed to a var parameter
// Facts: CurrFieldNo read in OnValidate and OnModify after being assigned in the caller, passed to a var parameter, and reset by a Validate call
// BC versions: 29 (27 and 28 by CI)

table 71169 "LT P69 Curr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P69 Curr Log";
            begin
                Log.Add('validate Amount CurrFieldNo=' + Format(CurrFieldNo));
            end;
        }
        field(3; Note; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P69 Curr Log";
            begin
                Log.Add('validate Note CurrFieldNo=' + Format(CurrFieldNo));
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT P69 Curr Log";
    begin
        Log.Add('insert CurrFieldNo=' + Format(CurrFieldNo));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT P69 Curr Log";
    begin
        Log.Add('modify CurrFieldNo=' + Format(CurrFieldNo));
    end;

    procedure ReadCurrFieldNo(): Integer
    begin
        exit(CurrFieldNo);
    end;

    procedure PassCurrFieldNo(var Value: Integer)
    begin
        Value := CurrFieldNo;
    end;

    procedure AssignAndRead(FieldNumber: Integer): Integer
    begin
        CurrFieldNo := FieldNumber;
        exit(CurrFieldNo);
    end;

    procedure AssignFieldNoOf(Which: Integer; var Seen: Integer)
    begin
        if Which = 1 then
            CurrFieldNo := FieldNo(Amount)
        else
            CurrFieldNo := FieldNo(Note);
        PassCurrFieldNo(Seen);
    end;

    procedure AssignThenModify(FieldNumber: Integer)
    begin
        CurrFieldNo := FieldNumber;
        Modify(true);
    end;

    procedure AssignThenValidate(FieldNumber: Integer)
    begin
        CurrFieldNo := FieldNumber;
        Validate(Amount, 6);
        PassAfterValidate := CurrFieldNo;
    end;

    procedure AssignThenInsert(FieldNumber: Integer)
    begin
        CurrFieldNo := FieldNumber;
        Insert(true);
    end;

    procedure AfterValidate(): Integer
    begin
        exit(PassAfterValidate);
    end;

    var
        PassAfterValidate: Integer;
}

codeunit 71170 "LT P69 Curr Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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

codeunit 71172 "LT P69 Curr Field No"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P69 Curr Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    procedure CurrFieldNo_AssignedAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Curr Row";
        Seen: Integer;
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('default', Format(Row.ReadCurrFieldNo()));
        Observer.Observe('assigned_amount', Format(Row.AssignAndRead(Row.FieldNo(Amount))));
        Observer.Observe('kept_after', Format(Row.ReadCurrFieldNo()));
        Observer.Observe('assigned_note', Format(Row.AssignAndRead(Row.FieldNo(Note))));
        Observer.Observe('reset', Format(Row.AssignAndRead(0)));
        Observer.Observe('arbitrary', Format(Row.AssignAndRead(99)));
        Row.AssignFieldNoOf(1, Seen);
        Observer.Observe('fieldno_amount_var_param', Format(Seen));
        Row.AssignFieldNoOf(2, Seen);
        Observer.Observe('fieldno_note_var_param', Format(Seen));
        Row.PassCurrFieldNo(Seen);
        Observer.Observe('pass_after', Format(Seen));
        Observer.Expect('default', '0');
        Observer.Expect('assigned_amount', '2');
        Observer.Expect('kept_after', '2');
        Observer.Expect('assigned_note', '3');
        Observer.Expect('reset', '0');
        Observer.Expect('arbitrary', '99');
        Observer.Expect('fieldno_amount_var_param', '2');
        Observer.Expect('fieldno_note_var_param', '3');
        Observer.Expect('pass_after', '3');
        Observer.Verify();
    end;

    [Test]
    procedure CurrFieldNo_InValidateAndModify()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P69 Curr Log";
        Row: Record "LT P69 Curr Row";
    begin
        Seed();
        Row.Get(1);
        Log.Take();
        Row.Validate(Amount, 5);
        Observer.Observe('validate', Log.Take());
        Row.AssignThenValidate(Row.FieldNo(Amount));
        Observer.Observe('validate_after_assign', Log.Take());
        Observer.Observe('after_validate_value', Format(Row.AfterValidate()));
        Row.AssignThenModify(Row.FieldNo(Amount));
        Observer.Observe('modify_after_assign', Log.Take());
        Row.AssignThenModify(0);
        Observer.Observe('modify_zero', Log.Take());
        Row.AssignThenModify(Row.FieldNo(Note));
        Observer.Observe('modify_note', Log.Take());
        Row.Modify(true);
        Observer.Observe('modify_plain', Log.Take());
        Observer.Expect('validate', 'validate Amount CurrFieldNo=0;');
        Observer.Expect('validate_after_assign', 'validate Amount CurrFieldNo=2;');
        Observer.Expect('after_validate_value', '2');
        Observer.Expect('modify_after_assign', 'modify CurrFieldNo=2;');
        Observer.Expect('modify_zero', 'modify CurrFieldNo=0;');
        Observer.Expect('modify_note', 'modify CurrFieldNo=3;');
        Observer.Expect('modify_plain', 'modify CurrFieldNo=3;');
        Observer.Verify();
    end;

    [Test]
    procedure CurrFieldNo_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P69 Curr Log";
        Row: Record "LT P69 Curr Row";
    begin
        Seed();
        Log.Take();
        Row.Id := 2;
        Row.AssignThenInsert(Row.FieldNo(Note));
        Observer.Observe('insert_after_assign', Log.Take());
        Row.Id := 3;
        Row.Validate(Note, 'n');
        Row.Insert(true);
        Observer.Observe('validate_then_insert', Log.Take());
        Row.Id := 4;
        Row.Insert(true);
        Observer.Observe('plain_insert', Log.Take());
        Observer.Expect('insert_after_assign', 'insert CurrFieldNo=3;');
        Observer.Expect('validate_then_insert', 'validate Note CurrFieldNo=3;insert CurrFieldNo=3;');
        Observer.Expect('plain_insert', 'insert CurrFieldNo=3;');
        Observer.Verify();
    end;

    // Corpus issue #664 item 111: CurrFieldNo := N in a table extension (tableextension 82359, misc/lt-bo2-odd-leads/BoCurrFieldNoExt.al)
    // compiles and publishes; is the value shared with the base table code of the same record?
    [Test]
    procedure CurrFieldNo_InTableExtension()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Curr Row";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('ext default', Format(Row.LtBoReadInExt()));
        Observer.Observe('ext assign 3', Format(Row.LtBoAssignInExt(3)));
        Observer.Observe('base reads after ext assign', Format(Row.ReadCurrFieldNo()));
        Observer.Observe('base assign 2', Format(Row.AssignAndRead(2)));
        Observer.Observe('ext reads after base assign', Format(Row.LtBoReadInExt()));
        Row.Validate(LtBoExtNum, 5);
        Observer.Observe('ext validate', Row.LtBoSeenInValidate());
        Observer.Observe('after ext validate', Format(Row.ReadCurrFieldNo()));
        Observer.Expect('ext default', '0');
        Observer.Expect('ext assign 3', '3');
        Observer.Expect('base reads after ext assign', '3');
        Observer.Expect('base assign 2', '2');
        Observer.Expect('ext reads after base assign', '2');
        Observer.Expect('ext validate', 'ext validate CurrFieldNo=2 after assign=1');
        Observer.Expect('after ext validate', '1');
        Observer.Verify();
    end;
}
