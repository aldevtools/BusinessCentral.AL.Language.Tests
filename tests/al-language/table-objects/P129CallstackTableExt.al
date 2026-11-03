// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73284, table extension 73285, SingleInstance log 73286 (used only by test codeunit 73287)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from a table extension: its OnInsert, OnModify and OnDelete triggers, the OnValidate of a field it adds, a procedure it adds, and (as the reference) the same triggers of the
// base table. The entries are the frames above the test runner, innermost first.
// BC versions: 29 (27 and 28 by CI)

table 73284 "LT P129 CS Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            begin
                L.Add('base Name OnValidate: ' + L.Frames());
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        L.Add('base OnInsert: ' + L.Frames());
    end;

    trigger OnModify()
    begin
        L.Add('base OnModify: ' + L.Frames());
    end;

    trigger OnDelete()
    begin
        L.Add('base OnDelete: ' + L.Frames());
    end;

    trigger OnRename()
    begin
        L.Add('base OnRename: ' + L.Frames());
    end;

    procedure BaseProcedure()
    begin
        L.Add('base procedure: ' + L.Frames());
    end;

    var
        L: Codeunit "LT P129 CS Log3";
}

tableextension 73285 "LT P129 CS Base Ext" extends "LT P129 CS Base"
{
    fields
    {
        field(73285; ExtField; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                L.Add('ext ExtField OnValidate: ' + L.Frames());
            end;
        }
    }

    trigger OnInsert()
    begin
        L.Add('ext OnInsert: ' + L.Frames());
    end;

    trigger OnModify()
    begin
        L.Add('ext OnModify: ' + L.Frames());
    end;

    trigger OnDelete()
    begin
        L.Add('ext OnDelete: ' + L.Frames());
    end;

    trigger OnRename()
    begin
        L.Add('ext OnRename: ' + L.Frames());
    end;

    procedure ExtProcedure()
    begin
        L.Add('ext procedure: ' + L.Frames());
    end;

    var
        L: Codeunit "LT P129 CS Log3";
}

codeunit 73286 "LT P129 CS Log3"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Frames(): Text
    var
        Stack: Text;
        Position: Integer;
    begin
        Stack := SessionInformation.Callstack;
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            exit(CopyStr(Stack, 1, Position - 1));
        exit(Stack);
    end;
}

codeunit 73287 "LT P129 CS Table Ext"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 CS Log3";

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Entries: List of [Text];
        Entry: Text;
        I: Integer;
    begin
        Entries := L.Take().Split('|');
        foreach Entry in Entries do begin
            I += 1;
            if Entry <> '' then
                Observer.Observe(Name + ' ' + Format(I), Entry);
        end;
    end;

    [Test]
    procedure P129_Callstack_TableExtension_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 CS Base";
    begin
        Row.DeleteAll();
        L.Take();
        Row.Id := 1;
        Row.Insert(true);
        Show(Observer, 'insert');
        Row.Name := 'a';
        Row.Modify(true);
        Show(Observer, 'modify');
        Row.Rename(2);
        Show(Observer, 'rename');
        Row.Delete(true);
        Show(Observer, 'delete');
        Observer.Expect('insert 1', 'base OnInsert: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base"(Table 73284).OnInsert(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('insert 2', 'ext OnInsert: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base Ext"(TableExtension 73285).OnInsert(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('modify 1', 'base OnModify: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base"(Table 73284).OnModify(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 11 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('modify 2', 'ext OnModify: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base Ext"(TableExtension 73285).OnModify(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 11 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('rename 1', 'base OnRename: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base"(Table 73284).OnRename(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 13 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('rename 2', 'ext OnRename: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base Ext"(TableExtension 73285).OnRename(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 13 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('delete 1', 'base OnDelete: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base"(Table 73284).OnDelete(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('delete 2', 'ext OnDelete: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base Ext"(TableExtension 73285).OnDelete(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_Triggers line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;





    [Test]
    procedure P129_Callstack_TableExtension_FieldValidateAndProcedures()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 CS Base";
    begin
        Row.DeleteAll();
        L.Take();
        Row.Validate(Name, 'b');
        Show(Observer, 'base validate');
        Row.Validate(ExtField, 3);
        Show(Observer, 'ext validate');
        Row.BaseProcedure();
        Show(Observer, 'base procedure');
        Row.ExtProcedure();
        Show(Observer, 'ext procedure');
        Observer.Expect('base validate 1', 'base Name OnValidate: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base"(Table 73284)."Name - OnValidate"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_FieldValidateAndProcedures line 7 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('ext validate 1', 'ext ExtField OnValidate: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base Ext"(TableExtension 73285)."ExtField - OnValidate"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_FieldValidateAndProcedures line 9 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('base procedure 1', 'base procedure: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base"(Table 73284).BaseProcedure line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_FieldValidateAndProcedures line 11 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('ext procedure 1', 'ext procedure: "LT P129 CS Log3"(CodeUnit 73286).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Base Ext"(TableExtension 73285).ExtProcedure line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Table Ext"(CodeUnit 73287).P129_Callstack_TableExtension_FieldValidateAndProcedures line 13 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;
}
