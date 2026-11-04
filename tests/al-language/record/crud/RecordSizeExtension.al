// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// An Insert that fails ends the test with the error (no TryFunction: writes in a TryFunction are refused).
// Fixtures used: Probe Observer (codeunit 69160); own tables 82966, 82967, table extension 82967, test codeunit 82968
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts (corpus issue 668 item 69, writer br): a table whose declared fields need more than 8000 bytes (five Text[2048] fields, 2 bytes per
// character), and a table under 8000 bytes that a table extension pushes past 8000 bytes: both compile and publish; Insert and Modify with every
// field at its full length; the lengths read back.
// BC versions: 27, 28, 29

table 82966 "LT BR Size Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; T1; Text[2048]) { }
        field(3; T2; Text[2048]) { }
        field(4; T3; Text[2048]) { }
        field(5; T4; Text[2048]) { }
        field(6; T5; Text[2048]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 82967 "LT BR Size Ext Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; T1; Text[1900]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 82967 "LT BR Size Ext" extends "LT BR Size Ext Base"
{
    fields
    {
        field(82967; E1; Text[2048]) { DataClassification = SystemMetadata; }
        field(82968; E2; Text[2048]) { DataClassification = SystemMetadata; }
        field(82969; E3; Text[2048]) { DataClassification = SystemMetadata; }
    }
}

codeunit 82968 "LT BR Record Size"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Filled(Len: Integer; Ch: Char): Text
    var
        Builder: TextBuilder;
        i: Integer;
    begin
        for i := 1 to Len do
            Builder.Append(Format(Ch));
        exit(Builder.ToText());
    end;

    local procedure InsertBase(Id: Integer)
    var
        Row: Record "LT BR Size Base";
    begin
        Row.Id := Id;
        Row.T1 := CopyStr(Filled(2048, 'a'), 1, 2048);
        Row.T2 := CopyStr(Filled(2048, 'b'), 1, 2048);
        Row.T3 := CopyStr(Filled(2048, 'c'), 1, 2048);
        Row.T4 := CopyStr(Filled(2048, 'd'), 1, 2048);
        Row.T5 := CopyStr(Filled(2048, 'e'), 1, 2048);
        Row.Insert();
    end;

    local procedure InsertExtended(Id: Integer)
    var
        Row: Record "LT BR Size Ext Base";
    begin
        Row.Id := Id;
        Row.T1 := CopyStr(Filled(1900, 'a'), 1, 1900);
        Row.E1 := CopyStr(Filled(2048, 'b'), 1, 2048);
        Row.E2 := CopyStr(Filled(2048, 'c'), 1, 2048);
        Row.E3 := CopyStr(Filled(2048, 'd'), 1, 2048);
        Row.Insert();
    end;

    [Test]
    procedure RecordSize_BaseTableOver8000Bytes_InsertFullLength()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BR Size Base";
    begin
        Row.DeleteAll();
        InsertBase(1);
        Observer.Observe('insert', 'ok');
        if Row.Get(1) then
            Observer.Observe('read back', Format(StrLen(Row.T1)) + '|' + Format(StrLen(Row.T5)) + '|' + CopyStr(Row.T5, 2048, 1))
        else
            Observer.Observe('read back', 'no row');
        Observer.Expect('insert', 'ok');
        Observer.Expect('read back', '2048|2048|e');
        Observer.Verify();
    end;

    [Test]
    procedure RecordSize_ExtensionPushesPast8000Bytes_InsertAndModifyFullLength()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BR Size Ext Base";
    begin
        Row.DeleteAll();
        InsertExtended(1);
        Observer.Observe('insert', 'ok');
        if Row.Get(1) then begin
            Observer.Observe('read back', Format(StrLen(Row.T1)) + '|' + Format(StrLen(Row.E1)) + '|' + Format(StrLen(Row.E3)) + '|' + CopyStr(Row.E3, 2048, 1));
            Row.E3 := CopyStr(Filled(2048, 'z'), 1, 2048);
            Observer.Observe('modify', Format(Row.Modify()));
            Row.Get(1);
            Observer.Observe('after modify', CopyStr(Row.E3, 1, 1) + '|' + Format(StrLen(Row.E3)));
        end else
            Observer.Observe('read back', 'no row');
        Observer.Expect('insert', 'ok');
        Observer.Expect('read back', '1900|2048|2048|d');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('after modify', 'z|2048');
        Observer.Verify();
    end;
}
