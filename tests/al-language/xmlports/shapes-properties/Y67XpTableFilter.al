// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93547, xmlports 93548, codeunit 93549 (writer Y67, gap cycle 6 follow-up)
// Probe: a TableFilter field of a table (the field of the Permission Import Export shape: Tenant Permission."Security Filter") in a field element of an
//   Xml xmlport and a VariableText xmlport, export and import: a filter set by Evaluate, no filter, a filter on a text field with an or; the same
//   field read with Format at format 0 and 9; Evaluate into a TableFilter FIELD from the table-qualified text, a text that names another table,
//   an unqualified text, an empty text, a text with two fields, and Evaluate into a Variant holding the field value.
//   The RecordRef route (TableFilterField_SetFromText) is pinned by records/W4PlatformAndMeta.al:272-340; Evaluate with the Security Filter of
//   Tenant Permission by permissions/lt-y48-security-filter/Y48ExpandedSecurityFilter.al:104,209.
// BC versions: 27, 28, 29

table 93547 "LT Y67 TF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Filt; TableFilter) { }
        field(3; Note; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 93548 "LT Y67 TF Export"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(R; "LT Y67 TF Row")
            {
                MinOccurs = Zero;
                fieldelement(Id; R.Id) { }
                fieldelement(Filter; R.Filt) { MinOccurs = Zero; }
                fieldelement(Note; R.Note) { MinOccurs = Zero; }
            }
        }
    }
}

codeunit 93549 "LT Y67 TF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y67 TF Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Evaluate(Row.Filt, 'LT Y67 TF Row: Id=2..5');
        Row.Note := 'range';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Note := 'none';
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Evaluate(Row.Filt, 'LT Y67 TF Row: Note=a|b');
        Row.Note := 'quote';
        Row.Insert();
    end;

    local procedure ExportText(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT Y67 TF Export", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryImport(Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT Y67 TF Export", InS);
    end;

    [TryFunction]
    local procedure TryEval(Text_: Text; var Row: Record "LT Y67 TF Row")
    begin
        Evaluate(Row.Filt, Text_);
    end;

    local procedure Back(Id: Integer): Text
    var
        Row: Record "LT Y67 TF Row";
    begin
        if not Row.Get(Id) then
            exit('missing');
        exit('[' + Format(Row.Filt) + ']|[' + Format(Row.Filt, 0, 9) + ']');
    end;

    [Test]
    procedure TableFilterField_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('xml', ExportText());
        Observer.Observe('row1 format', Back(1));
        Observer.Observe('row2 format', Back(2));
        Observer.Observe('row3 format', Back(3));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <R>|    <Id>1</Id>|    <Filter>LT Y67 TF Row: Id=2..5</Filter>|    <Note>range</Note>|  </R>|  <R>|    <Id>2</Id>|    <Filter />|    <Note>none</Note>|  </R>|  <R>|    <Id>3</Id>|    <Filter>LT Y67 TF Row: Note=a|b</Filter>|    <Note>quote</Note>|  </R>|</Root>|');
        Observer.Expect('row1 format', '[LT Y67 TF Row: Id=2..5]|[LT Y67 TF Row: Id=2..5]');
        Observer.Expect('row2 format', '[]|[]');
        Observer.Expect('row3 format', '[LT Y67 TF Row: Note=a|b]|[LT Y67 TF Row: Note=a|b]');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterField_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        if TryImport('<Root><R><Id>10</Id><Filter>LT Y67 TF Row: Id=1..9</Filter><Note>n10</Note></R></Root>') then
            Observer.Observe('qualified', Back(10))
        else
            Observer.Observe('qualified', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryImport('<Root><R><Id>11</Id><Filter>Id: 1..9</Filter></R></Root>') then
            Observer.Observe('unqualified', Back(11))
        else
            Observer.Observe('unqualified', 'error ' + Format(GetLastErrorText().Contains('The metadata object Table -1 was not found')) + '|' + GetLastErrorCode());
        ClearLastError();
        if TryImport('<Root><R><Id>12</Id><Filter /></R></Root>') then
            Observer.Observe('empty', Back(12))
        else
            Observer.Observe('empty', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryImport('<Root><R><Id>13</Id><Filter>Customer: No.=1</Filter></R></Root>') then
            Observer.Observe('other table', Back(13))
        else
            Observer.Observe('other table', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('qualified', '[LT Y67 TF Row: Id=1..9]|[LT Y67 TF Row: Id=1..9]');
        Observer.Expect('unqualified', 'error Yes|Evaluate:MetadataNotFound');
        Observer.Expect('empty', '[]|[]');
        Observer.Expect('other table', '[Customer: No.=1]|[Customer: No.=1]');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterField_Evaluate_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 TF Row";
        V: Variant;
        Texts: List of [Text];
        T: Text;
        i: Integer;
    begin
        Texts.Add('LT Y67 TF Row: Id=1..5');
        Texts.Add('LT Y67 TF Row: Id=1..5,Note=a');
        Texts.Add('LT Y67 TF Row: Id=1..5|Note=a');
        Texts.Add('LT Y67 TF Row: Id=''1''');
        Texts.Add('Customer: No.=1');
        Texts.Add('Id=1..5');
        Texts.Add('');
        Texts.Add('LT Y67 TF Row: ');
        Texts.Add('LT Y67 TF Row: Unknown=1');
        foreach T in Texts do begin
            i += 1;
            Clear(Row);
            ClearLastError();
            if TryEval(T, Row) then
                Observer.Observe(Format(i) + ' [' + T + ']', 'ok [' + Format(Row.Filt) + ']|[' + Format(Row.Filt, 0, 9) + ']')
            else
                Observer.Observe(Format(i) + ' [' + T + ']', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Clear(Row);
        Evaluate(Row.Filt, 'LT Y67 TF Row: Id=1..5');
        V := Row.Filt;
        Observer.Observe('variant', Format(V));
        Observer.Expect('1 [LT Y67 TF Row: Id=1..5]', 'ok [LT Y67 TF Row: Id=1..5]|[LT Y67 TF Row: Id=1..5]');
        Observer.Expect('2 [LT Y67 TF Row: Id=1..5,Note=a]', 'ok [LT Y67 TF Row: Id=1..5,Note=a]|[LT Y67 TF Row: Id=1..5,Note=a]');
        Observer.Expect('3 [LT Y67 TF Row: Id=1..5|Note=a]', 'error The value "LT Y67 TF Row: Id=1..5|Note=a" can''t be evaluated into type TableFilter. The value "Note" can''t be evaluated into type Integer.|Evaluate:InvalidFilterExpression');
        Observer.Expect('4 [LT Y67 TF Row: Id=''1'']', 'ok [LT Y67 TF Row: Id=1]|[LT Y67 TF Row: Id=1]');
        Observer.Expect('5 [Customer: No.=1]', 'ok [Customer: No.=1]|[Customer: No.=1]');
        Observer.Expect('6 [Id=1..5]', 'error The value "Id=1..5" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('7 []', 'ok []|[]');
        Observer.Expect('8 [LT Y67 TF Row: ]', 'ok [LT Y67 TF Row: ]|[LT Y67 TF Row: ]');
        Observer.Expect('9 [LT Y67 TF Row: Unknown=1]', 'error The value "LT Y67 TF Row: Unknown=1" can''t be evaluated into type TableFilter. The supplied field number ''Unknown'' cannot be found in the ''LT Y67 TF Row'' table.|Evaluate:FieldNotFound');
        Observer.Expect('variant', 'LT Y67 TF Row: Id=1..5');
        Observer.Verify();
    end;
}
