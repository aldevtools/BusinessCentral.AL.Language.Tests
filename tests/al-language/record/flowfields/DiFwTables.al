// Fixtures of the FlowField write probes (DiFwWriteTests.al): a parent table with a Count, a Sum, an Exist (Boolean) and a Lookup (Text)
// FlowField and a Date FlowFilter, the child table their CalcFormulas read, a log table the parent's triggers write to, and a table with
// normal fields of the same numbers (TransferFields target and source).

table 86260 "LT DI FW Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Child Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT DI FW Child" where("Parent No." = field("No.")));
            Editable = false;

            trigger OnValidate()
            begin
                Log('OnValidate Child Count Rec=' + Format("Child Count") + ' xRec=' + Format(xRec."Child Count"));
            end;
        }
        field(4; "Child Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT DI FW Child".Amount where("Parent No." = field("No."), "Posting Date" = field("Date Filter")));
            Editable = false;
        }
        field(5; "Has Children"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT DI FW Child" where("Parent No." = field("No.")));
        }
        field(6; "First Child Code"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT DI FW Child".Code where("Parent No." = field("No.")));
        }
        field(7; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log('OnInsert Child Count=' + Format("Child Count"));
    end;

    trigger OnModify()
    begin
        Log('OnModify Rec.Child Count=' + Format("Child Count") + ' xRec.Child Count=' + Format(xRec."Child Count") + ' Rec.Name=' + Name + ' xRec.Name=' + xRec.Name);
    end;

    local procedure Log(Msg: Text)
    var
        LogRow: Record "LT DI FW Log";
    begin
        LogRow.Init();
        LogRow.Msg := CopyStr(Msg, 1, MaxStrLen(LogRow.Msg));
        LogRow.Insert();
    end;
}

table 86261 "LT DI FW Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Parent No."; Integer) { }
        field(3; Code; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; "Posting Date"; Date) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 86262 "LT DI FW Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Msg; Text[250]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 86263 "LT DI FW Copy"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Child Count"; Integer) { }
        field(4; "Child Amount"; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Writer QB (corpus issue #665, question in the second comment): a parent whose Count, Sum, Exist and Lookup FlowFields all have an
// OnValidate trigger, for the one-argument Validate(Field) form. The triggers write to LT DI FW Log.
table 86380 "LT QB FW Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(3; "Child Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT DI FW Child" where("Parent No." = field("No.")));
            Editable = false;

            trigger OnValidate()
            begin
                Log('OnValidate Child Count Rec=' + Format("Child Count") + ' xRec=' + Format(xRec."Child Count"));
            end;
        }
        field(4; "Child Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT DI FW Child".Amount where("Parent No." = field("No.")));
            Editable = false;

            trigger OnValidate()
            begin
                Log('OnValidate Child Amount Rec=' + Format("Child Amount") + ' xRec=' + Format(xRec."Child Amount"));
            end;
        }
        field(5; "Has Children"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT DI FW Child" where("Parent No." = field("No.")));

            trigger OnValidate()
            begin
                Log('OnValidate Has Children Rec=' + Format("Has Children"));
            end;
        }
        field(6; "First Child Code"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT DI FW Child".Code where("Parent No." = field("No.")));

            trigger OnValidate()
            begin
                Log('OnValidate First Child Code Rec=' + "First Child Code");
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    local procedure Log(Msg: Text)
    var
        LogRow: Record "LT DI FW Log";
    begin
        LogRow.Init();
        LogRow.Msg := CopyStr(Msg, 1, MaxStrLen(LogRow.Msg));
        LogRow.Insert();
    end;
}

// Writer SF (al-runner issue 5857): a TableType = Temporary table with a FlowFilter field, the shape of Base Application table 265
// "Document Entry" whose "Document No." codeunit 1018 "Purchase Doc. From Job" reads back from inserted rows.
table 89330 "LT SF FF Temp Buffer"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Document No."; Code[20])
        {
            FieldClass = FlowFilter;
        }
        field(3; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
