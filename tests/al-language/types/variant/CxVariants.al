// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 85482, 85483, test codeunit 85484
// Probe: written against the local BC 29.0 test loop; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Corpus issue 670 (lead list E), items 77, 78, 79, 83, 85 and 86 (writer CX):
//   77 a ternary with a Variant branch (microsoft/AL#7926, #8151);
//   78 a Record assigned to a RecordRef and passed to a RecordRef parameter, a Variant from a RecordRef back into a RecordRef (microsoft/AL#8239;
//      Variant from a Record into a RecordRef is pinned in types/lt-variant/VaTConvert.al:255; Codeunit.Run with a RecordRef is must-not-compile 1786/1787);
//   79 a Variant var parameter that holds a Record: do filters and values set in the callee reach the caller (microsoft/AL#5030;
//      passing the Record itself is must-not-compile case 1784);
//   83 a RecordRef passed by value, also inside a Variant: Get, Close, Open on the callee's copy (microsoft/AL#7312);
//   85 a Variant from and to XmlDocument, XmlElement, XmlNamespaceManager (microsoft/AL#1006);
//   86 a Variant holding a Blob value assigned to a Blob field (microsoft/AL#4399).
// BC versions: 27, 28, 29

table 85482 "LT CX VRow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Blb; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 85483 "LT CX VOther"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 85484 "LT CX Variants"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT CX VRow";
        Other: Record "LT CX VOther";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Insert();
        Other.Code := 'X';
        Other.Descr := 'other x';
        Other.Insert();
    end;

    local procedure Kind(V: Variant): Text
    begin
        case true of
            V.IsInteger():
                exit('Integer');
            V.IsCode():
                exit('Code');
            V.IsText():
                exit('Text');
            V.IsRecord():
                exit('Record');
            V.IsRecordRef():
                exit('RecordRef');
        end;
        exit('other');
    end;

    local procedure GetVariant(Value: Variant): Variant
    begin
        exit(Value);
    end;

    [TryFunction]
    local procedure TryTextFirst(Value: Variant; var Result: Variant)
    begin
        Result := false ? 'Bar' : GetVariant(Value);
    end;

    [TryFunction]
    local procedure TryVariantFirst(Value: Variant; var Result: Variant)
    begin
        Result := false ? GetVariant(Value) : 'Bar';
    end;

    [TryFunction]
    local procedure TryVariantTaken(Value: Variant; var Result: Variant)
    begin
        Result := true ? GetVariant(Value) : 'Bar';
    end;

    [TryFunction]
    local procedure TryIntegerBranch(Value: Variant; var Result: Variant)
    begin
        Result := false ? 1 : GetVariant(Value);
    end;

    local procedure Out(Ok: Boolean; Result: Variant): Text
    begin
        if Ok then
            exit('ok:' + Kind(Result) + ':' + Format(Result));
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure Ternary_WithVariantBranch()
    var
        Observer: Codeunit "Probe Observer";
        Result: Variant;
        Ok: Boolean;
        C: Code[10];
    begin
        ClearLastError();
        Ok := TryTextFirst(1234, Result);
        Observer.Observe('text_first_holds_integer', Out(Ok, Result));
        ClearLastError();
        Ok := TryTextFirst('Foo', Result);
        Observer.Observe('text_first_holds_text', Out(Ok, Result));
        C := 'cd';
        ClearLastError();
        Ok := TryTextFirst(C, Result);
        Observer.Observe('text_first_holds_code', Out(Ok, Result));
        ClearLastError();
        Ok := TryVariantFirst(1234, Result);
        Observer.Observe('variant_first_not_taken', Out(Ok, Result));
        ClearLastError();
        Ok := TryVariantTaken(1234, Result);
        Observer.Observe('variant_first_taken_integer', Out(Ok, Result));
        ClearLastError();
        Ok := TryIntegerBranch(1234, Result);
        Observer.Observe('integer_branch_holds_integer', Out(Ok, Result));
        ClearLastError();
        Ok := TryIntegerBranch('Foo', Result);
        Observer.Observe('integer_branch_holds_text', Out(Ok, Result));
        Observer.Expect('text_first_holds_integer', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('text_first_holds_text', 'ok:Text:Foo');
        Observer.Expect('text_first_holds_code', 'ok:Text:CD');
        Observer.Expect('variant_first_not_taken', 'ok:Text:Bar');
        Observer.Expect('variant_first_taken_integer', 'ok:Integer:1234');
        Observer.Expect('integer_branch_holds_integer', 'ok:Integer:1234');
        Observer.Expect('integer_branch_holds_text', 'error:TypeConversion:Format:The expression Variant cannot be type-converted to a Integer value.');
        Observer.Verify();
    end;

    local procedure RefInfo(RR: RecordRef): Text
    begin
        exit(Format(RR.Number) + '|' + Format(RR.Field(1).Value) + '|' + Format(RR.Count()));
    end;

    [Test]
    procedure RecordToRecordRef_Implicit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CX VRow";
        Back: Record "LT CX VRow";
        RR: RecordRef;
        RR2: RecordRef;
        V: Variant;
    begin
        Seed();
        Row.SetRange(Id, 2, 3);
        Row.FindFirst();
        RR := Row;
        Observer.Observe('assigned', RefInfo(RR));
        Observer.Observe('assigned_filters', RR.GetFilters());
        Observer.Observe('param', RefInfo(Row));
        RR.Field(2).Value := 'changed';
        Observer.Observe('record_after_ref_change', Row.Name);
        Row.Name := 'record side';
        Observer.Observe('ref_after_record_change', Format(RR.Field(2).Value));
        V := RR;
        Observer.Observe('variant_kind', Kind(V));
        RR2 := V;
        Observer.Observe('variant_back', RefInfo(RR2));
        RR2.Field(2).Value := 'via variant';
        Observer.Observe('first_ref_after_second_change', Format(RR.Field(2).Value));
        RR.SetTable(Back);
        Observer.Observe('settable', Format(Back.Id) + '|' + Back.Name);
        Observer.Expect('assigned', '85482|2|2');
        Observer.Expect('assigned_filters', 'Id: 2..3');
        Observer.Expect('param', '85482|2|2');
        Observer.Expect('record_after_ref_change', 'two');
        Observer.Expect('ref_after_record_change', 'changed');
        Observer.Expect('variant_kind', 'RecordRef');
        Observer.Expect('variant_back', '85482|2|2');
        Observer.Expect('first_ref_after_second_change', 'via variant');
        Observer.Expect('settable', '2|via variant');
        Observer.Verify();
    end;

    local procedure FilterThroughVariant(var V: Variant)
    var
        Row: Record "LT CX VRow";
    begin
        Row := V;
        Row.SetRange(Id, 3);
        Row.FindFirst();
        Row.Name := 'set in callee';
        V := Row;
    end;

    local procedure ChangeWithoutWriteBack(var V: Variant)
    var
        Row: Record "LT CX VRow";
    begin
        Row := V;
        Row.SetRange(Id, 1);
        Row.Name := 'not written back';
    end;

    [TryFunction]
    local procedure TryToOther(V: Variant; var Other: Record "LT CX VOther")
    begin
        Other := V;
    end;

    [Test]
    procedure VariantVarParameter_HoldingRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CX VRow";
        Other: Record "LT CX VOther";
        V: Variant;
    begin
        Seed();
        Row.Get(2);
        V := Row;
        FilterThroughVariant(V);
        Row := V;
        Observer.Observe('written_back_values', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('written_back_filters', Row.GetFilters());
        Observer.Observe('written_back_count', Format(Row.Count()));
        Row.Reset();
        Row.Get(2);
        V := Row;
        ChangeWithoutWriteBack(V);
        Row := V;
        Observer.Observe('no_write_back_values', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('no_write_back_filters', Row.GetFilters());
        ClearLastError();
        Observer.Observe('to_other_table_ok', Format(TryToOther(V, Other)));
        Observer.Observe('to_other_table_error', GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Observe('to_other_table_value', Other.Code + '|' + Other.Descr);
        Observer.Expect('written_back_values', '3|set in callee');
        Observer.Expect('written_back_filters', '');
        Observer.Expect('written_back_count', '3');
        Observer.Expect('no_write_back_values', '2|two');
        Observer.Expect('no_write_back_filters', '');
        Observer.Expect('to_other_table_ok', 'No');
        Observer.Expect('to_other_table_error', 'NotSupportedOperation:The requested operation is not supported.');
        Observer.Expect('to_other_table_value', '|');
        Observer.Verify();
    end;

    local procedure GetInCallee(RR: RecordRef; RowKey: Integer)
    var
        Row: Record "LT CX VRow";
    begin
        Row.Get(RowKey);
        RR.Get(Row.RecordId);
    end;

    local procedure CloseInCallee(RR: RecordRef)
    begin
        RR.Close();
    end;

    local procedure OpenOtherInCallee(RR: RecordRef)
    begin
        RR.Close();
        RR.Open(Database::"LT CX VOther");
        RR.FindFirst();
    end;

    local procedure OpenOtherThroughVariant(V: Variant)
    var
        RR2: RecordRef;
    begin
        RR2 := V;
        RR2.Close();
        RR2.Open(Database::"LT CX VOther");
        RR2.FindFirst();
    end;

    local procedure GetThroughVariant(V: Variant; RowKey: Integer)
    var
        RR2: RecordRef;
        Row: Record "LT CX VRow";
    begin
        RR2 := V;
        Row.Get(RowKey);
        RR2.Get(Row.RecordId);
    end;

    local procedure GetTableInCallee(RR: RecordRef)
    var
        Other: Record "LT CX VOther";
    begin
        Other.FindFirst();
        RR.GetTable(Other);
    end;

    local procedure Info(var RR: RecordRef): Text
    begin
        if RR.Number = 0 then
            exit('closed');
        exit(Format(RR.Number = Database::"LT CX VRow", 0, 2) + '|' + Format(RR.Field(1).Value));
    end;

    [Test]
    procedure RecordRefByValue_CalleeChanges()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Dup: RecordRef;
    begin
        Seed();
        RR.Open(Database::"LT CX VRow");
        RR.FindFirst();
        Observer.Observe('start', Info(RR));
        GetInCallee(RR, 3);
        Observer.Observe('after_get', Info(RR));
        GetThroughVariant(RR, 2);
        Observer.Observe('after_get_through_variant', Info(RR));
        Dup := RR.Duplicate();
        GetInCallee(Dup, 1);
        Observer.Observe('original_after_duplicate_get', Info(RR));
        Observer.Observe('duplicate_after_get', Info(Dup));
        OpenOtherInCallee(RR);
        Observer.Observe('after_open_other', Info(RR));
        RR.Close();
        RR.Open(Database::"LT CX VRow");
        RR.FindFirst();
        OpenOtherThroughVariant(RR);
        Observer.Observe('after_open_other_through_variant', Info(RR));
        RR.Close();
        RR.Open(Database::"LT CX VRow");
        RR.FindFirst();
        GetTableInCallee(RR);
        Observer.Observe('after_gettable_other', Info(RR));
        RR.Close();
        RR.Open(Database::"LT CX VRow");
        RR.FindFirst();
        CloseInCallee(RR);
        Observer.Observe('after_close', Info(RR));
        Observer.Expect('start', '1|1');
        Observer.Expect('after_get', '1|3');
        Observer.Expect('after_get_through_variant', '1|2');
        Observer.Expect('original_after_duplicate_get', '1|2');
        Observer.Expect('duplicate_after_get', '1|1');
        Observer.Expect('after_open_other', '1|2');
        Observer.Expect('after_open_other_through_variant', '1|1');
        Observer.Expect('after_gettable_other', '0|X');
        Observer.Expect('after_close', '1|1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryToDocument(V: Variant; var D: XmlDocument)
    begin
        D := V;
    end;

    [TryFunction]
    local procedure TryToElement(V: Variant; var E: XmlElement)
    begin
        E := V;
    end;

    [TryFunction]
    local procedure TryToNsMgr(V: Variant; var N: XmlNamespaceManager)
    begin
        N := V;
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure Variant_XmlTypes_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        D2: XmlDocument;
        E: XmlElement;
        E2: XmlElement;
        N: XmlNamespaceManager;
        N2: XmlNamespaceManager;
        V: Variant;
        Prefix: Text;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<root><a/></root>', D);
        V := D;
        if TryToDocument(V, D2) then begin
            D2.GetRoot(E2);
            E2.Add(XmlElement.Create('added'));
            D.WriteTo(Txt);
            Observer.Observe('document_back', 'ok:' + Txt);
        end else
            Observer.Observe('document_back', Err());
        E := XmlElement.Create('el');
        V := E;
        if TryToElement(V, E2) then begin
            E2.SetAttribute('k', 'v');
            E.WriteTo(Txt);
            Observer.Observe('element_back', 'ok:' + Txt);
        end else
            Observer.Observe('element_back', Err());
        N.AddNamespace('p', 'urn:x');
        V := N;
        if TryToNsMgr(V, N2) then begin
            N2.LookupPrefix('urn:x', Prefix);
            Observer.Observe('nsmgr_back', 'ok:' + Prefix);
        end else
            Observer.Observe('nsmgr_back', Err());
        ClearLastError();
        V := E;
        if TryToDocument(V, D2) then
            Observer.Observe('element_to_document', 'ok')
        else
            Observer.Observe('element_to_document', Err());
        ClearLastError();
        V := D;
        if TryToElement(V, E2) then
            Observer.Observe('document_to_element', 'ok')
        else
            Observer.Observe('document_to_element', Err());
        ClearLastError();
        V := N;
        if TryToDocument(V, D2) then
            Observer.Observe('nsmgr_to_document', 'ok')
        else
            Observer.Observe('nsmgr_to_document', Err());
        ClearLastError();
        V := 'text';
        if TryToElement(V, E2) then
            Observer.Observe('text_to_element', 'ok')
        else
            Observer.Observe('text_to_element', Err());
        Observer.Expect('document_back', 'ok:<?xml version="1.0" encoding="utf-16"?>\r\n<root>\r\n  <a />\r\n  <added />\r\n</root>');
        Observer.Expect('element_back', 'ok:<el k="v" />');
        Observer.Expect('nsmgr_back', 'ok:p');
        Observer.Expect('element_to_document', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavXmlDocument value.');
        Observer.Expect('document_to_element', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavXmlElement value.');
        Observer.Expect('nsmgr_to_document', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavXmlDocument value.');
        Observer.Expect('text_to_element', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavXmlElement value.');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryToBlob(V: Variant; var Row: Record "LT CX VRow")
    begin
        Row.Blb := V;
    end;

    local procedure BlobText(var Row: Record "LT CX VRow"): Text
    var
        InS: InStream;
        T: Text;
    begin
        if not Row.Blb.HasValue() then
            exit('<no value>');
        Row.Blb.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;

    [Test]
    procedure Variant_BlobToBlobField()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT CX VRow";
        Target: Record "LT CX VRow";
        OutS: OutStream;
        V: Variant;
    begin
        Source.Blb.CreateOutStream(OutS);
        OutS.WriteText('blob content');
        V := Source.Blb;
        ClearLastError();
        if TryToBlob(V, Target) then
            Observer.Observe('blob_variant_to_field', 'ok:' + BlobText(Target))
        else
            Observer.Observe('blob_variant_to_field', Err());
        Clear(Target);
        V := 'plain text';
        ClearLastError();
        if TryToBlob(V, Target) then
            Observer.Observe('text_variant_to_field', 'ok:' + BlobText(Target))
        else
            Observer.Observe('text_variant_to_field', Err());
        Clear(Target);
        V := 42;
        ClearLastError();
        if TryToBlob(V, Target) then
            Observer.Observe('integer_variant_to_field', 'ok:' + BlobText(Target))
        else
            Observer.Observe('integer_variant_to_field', Err());
        Observer.Expect('blob_variant_to_field', 'ok:blob content');
        Observer.Expect('text_variant_to_field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavBLOB value.');
        Observer.Expect('integer_variant_to_field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavBLOB value.');
        Observer.Verify();
    end;
}
