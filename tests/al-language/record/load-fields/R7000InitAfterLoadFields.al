// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 95628 (lines), 95629 (log), test codeunit 95631
// Probe (al-runner issue 7000): Init on a record that a SetLoadFields fetch filled partially, then a new primary key, Validate of fields
//   whose OnValidate reads and writes fields that were not loaded, and Insert(true). With and without SetLoadFields() before Init, with the
//   key kept, a direct read of a not-loaded field after Init, AreFieldsLoaded after Init, and a plain Insert after Init.
//   Facts: the field values after Init, what the OnValidate and OnInsert triggers read, the rows stored afterwards.
// BC versions: 27, 28, 29

table 95628 "LT R7000 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document Type"; Option) { OptionMembers = Quote,"Order"; }
        field(3; "Document No."; Code[20]) { }
        field(4; "Line No."; Integer) { }
        field(5; Type; Option)
        {
            OptionMembers = " ",Item,Resource;

            trigger OnValidate()
            var
                Log: Record "LT R7000 Log";
            begin
                Log.Add('Type validate: No=' + "No." + ' Descr=' + Description + ' Qty=' + Format(Quantity) + ' Note=' + Note);
                "No." := '';
            end;
        }
        field(6; "No."; Code[20])
        {
            trigger OnValidate()
            var
                Log: Record "LT R7000 Log";
            begin
                Log.Add('No validate: Descr=' + Description + ' Qty=' + Format(Quantity) + ' Amount=' + Format(Amount) + ' Note=' + Note);
                Description := 'Item ' + "No.";
                Amount := Quantity * 10;
            end;
        }
        field(7; Description; Text[50]) { }
        field(8; Quantity; Decimal) { InitValue = 1; }
        field(9; Amount; Decimal) { }
        field(10; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "Document Type", "Document No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Record "LT R7000 Log";
    begin
        Log.Add('insert: ' + Dump());
    end;

    procedure Dump(): Text
    begin
        exit(Format("Document Type") + '/' + "Document No." + '/' + Format("Line No.") + ' Type=' + Format(Type) + ' No=' + "No." +
            ' Descr=' + Description + ' Qty=' + Format(Quantity) + ' Amount=' + Format(Amount) + ' Note=' + Note);
    end;
}

table 95629 "LT R7000 Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; Msg; Text[250]) { }
    }

    keys
    {
        key(PK; Seq) { Clustered = true; }
    }

    procedure Add(Text: Text)
    var
        Log: Record "LT R7000 Log";
    begin
        Log.Init();
        Log.Seq := 0;
        Log.Msg := CopyStr(Text, 1, MaxStrLen(Log.Msg));
        Log.Insert();
    end;

    procedure Dump(): Text
    var
        Log: Record "LT R7000 Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                Result += Log.Msg + ';';
            until Log.Next() = 0;
        exit(Result);
    end;
}

codeunit 95631 "LT R7000 Init After LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Line: Record "LT R7000 Line";
        Log: Record "LT R7000 Log";
    begin
        Line.DeleteAll();
        Log.DeleteAll();
        AddLine(10000, 'old10', 5, 'n10');
        AddLine(20000, 'old20', 7, 'n20');
    end;

    local procedure AddLine(LineNo: Integer; Descr: Text[50]; Qty: Decimal; Note: Text[30])
    var
        Line: Record "LT R7000 Line";
    begin
        Line.Init();
        Line."Document Type" := Line."Document Type"::"Order";
        Line."Document No." := 'D1';
        Line."Line No." := LineNo;
        Line.Type := Line.Type::Resource;
        Line."No." := 'R1';
        Line.Description := Descr;
        Line.Quantity := Qty;
        Line.Amount := Qty * 10;
        Line.Note := Note;
        Line.Insert();
    end;

    local procedure Rows(): Text
    var
        Line: Record "LT R7000 Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line.Dump() + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure FetchLast(var Line: Record "LT R7000 Line"): Integer
    begin
        Line.SetLoadFields("Line No.");
        Line.SetRange("Document Type", Line."Document Type"::"Order");
        Line.SetRange("Document No.", 'D1');
        if Line.FindLast() then
            exit(Line."Line No.");
    end;

    [Test]
    procedure Init_AfterLoadFieldsReset_NewKey_Validate_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT R7000 Line";
        Log: Record "LT R7000 Log";
        LineNo: Integer;
    begin
        Seed();
        LineNo := FetchLast(Line);
        Line.SetLoadFields();
        LineNo += 10000;
        Line.Init();
        Observer.Observe('after init', Line.Dump());
        Line."Document Type" := Line."Document Type"::"Order";
        Line."Document No." := 'D1';
        Line."Line No." := LineNo;
        Observer.Observe('after key', Line.Dump());
        Line.Validate(Type, Line.Type::Item);
        Line.Validate("No.", 'I1');
        Observer.Observe('after validate', Line.Dump());
        Line.Insert(true);
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Init_StillPartial_NewKey_Validate_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT R7000 Line";
        Log: Record "LT R7000 Log";
        LineNo: Integer;
    begin
        Seed();
        LineNo := FetchLast(Line);
        LineNo += 10000;
        Line.Init();
        Observer.Observe('after init', Line.Dump());
        Line."Line No." := LineNo;
        Line.Validate(Type, Line.Type::Item);
        Line.Validate("No.", 'I1');
        Line.Insert(true);
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Init_AfterLoadFields_KeyKept_Reads()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT R7000 Line";
    begin
        Seed();
        FetchLast(Line);
        Line.Init();
        Observer.Observe('note loaded after init', Format(Line.AreFieldsLoaded(Note)));
        Observer.Observe('line no loaded after init', Format(Line.AreFieldsLoaded("Line No.")));
        Observer.Observe('after init', Line.Dump());
        Observer.Observe('note loaded after read', Format(Line.AreFieldsLoaded(Note)));
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Init_AfterLoadFields_NewKey_DirectRead()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT R7000 Line";
    begin
        Seed();
        FetchLast(Line);
        Line.Init();
        Line."Line No." := 30000;
        Observer.Observe('note', Line.Note);
        Observer.Observe('qty', Format(Line.Quantity));
        Observer.Observe('descr', Line.Description);
        Observer.Finish();
    end;

    [Test]
    procedure Init_AfterLoadFields_NewKey_PlainInsert()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT R7000 Line";
        Log: Record "LT R7000 Log";
    begin
        Seed();
        FetchLast(Line);
        Line.Init();
        Line."Line No." := 30000;
        Line.Insert();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure Init_AfterLoadFields_NewKey_AssignNotLoaded_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT R7000 Line";
        Log: Record "LT R7000 Log";
    begin
        Seed();
        FetchLast(Line);
        Line.SetLoadFields();
        Line.Init();
        Line."Line No." := 30000;
        Line.Note := 'new';
        Line.Validate("No.", 'I2');
        Line.Insert(true);
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;
}
