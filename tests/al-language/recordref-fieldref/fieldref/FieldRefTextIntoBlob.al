// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope. Assigning a Text (plain, empty, non-ASCII, through a Variant) and an Integer to a Blob field through FieldRef.Value, on a record that is not inserted and on an inserted one, and what the Blob then holds.
// Fixtures used: Probe Observer (codeunit 69160); own table 77811 (FC Dots Row, from record/filters/FilterDotsOnlyTypes.al); own codeunit 77813 (FieldRef Text Into Blob)
// Probe: from al-runner issue 8213, part 2 (Text into a Blob through a FieldRef). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: assigning Text through FieldRef.Value to a Blob field raises an error on every major; the text of the error differs: BC 27 'Invalid Conversion. Source: NavVariant, Destination: NavBLOB.', BC 28 and later 'The value ... can't be evaluated into type BLOB.' (guarded with #if BC28PLUS).
// BC versions: 27, 28, 29

codeunit 77813 "FieldRef Text Into Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAssign(var RecRef: RecordRef; Value: Variant)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(11);
        Fld.Value := Value;
    end;

    local procedure ReadBody(var Row: Record "FC Dots Row"): Text
    var
        InS: InStream;
        Content: Text;
        Bytes: Integer;
        B: Byte;
    begin
        if not Row.Body.HasValue() then
            exit('no value');
        Row.Body.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Content);
        Row.Body.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Bytes += 1;
        end;
        exit('text=' + Content + ' bytes=' + Format(Bytes));
    end;

    local procedure Unsaved(Value: Variant): Text
    var
        Row: Record "FC Dots Row";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"FC Dots Row");
        RecRef.Init();
        if not TryAssign(RecRef, Value) then
            exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
        RecRef.SetTable(Row);
        exit(ReadBody(Row));
    end;

    [Test]
    procedure FieldRefValue_TextIntoBlob_NotInserted()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Txt: Text;
    begin
        Observer.Observe('plain', Unsaved('some text'));
        Observer.Observe('empty', Unsaved(''));
        Observer.Observe('nonAscii', Unsaved('Ærø å'));
        Txt := 'via variant';
        V := Txt;
        Observer.Observe('variantText', Unsaved(V));
        Observer.Observe('integer', Unsaved(42));
#if BC28PLUS
        Observer.Expect('plain', 'error: The value "some text" can''t be evaluated into type BLOB. | Evaluate:Argument');
#else
        Observer.Expect('plain', 'error: Invalid Conversion. Source: NavVariant, Destination: NavBLOB. | Argument');
#endif
#if BC28PLUS
        Observer.Expect('empty', 'error: The value "" can''t be evaluated into type BLOB. | Evaluate:Argument');
#else
        Observer.Expect('empty', 'error: Invalid Conversion. Source: NavVariant, Destination: NavBLOB. | Argument');
#endif
#if BC28PLUS
        Observer.Expect('nonAscii', 'error: The value "Ærø å" can''t be evaluated into type BLOB. | Evaluate:Argument');
#else
        Observer.Expect('nonAscii', 'error: Invalid Conversion. Source: NavVariant, Destination: NavBLOB. | Argument');
#endif
#if BC28PLUS
        Observer.Expect('variantText', 'error: The value "via variant" can''t be evaluated into type BLOB. | Evaluate:Argument');
#else
        Observer.Expect('variantText', 'error: Invalid Conversion. Source: NavVariant, Destination: NavBLOB. | Argument');
#endif
#if BC28PLUS
        Observer.Expect('integer', 'error: The value "42" can''t be evaluated into type BLOB. | Evaluate:Argument');
#else
        Observer.Expect('integer', 'error: Invalid Conversion. Source: NavVariant, Destination: NavBLOB. | Argument');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefValue_TextIntoBlob_InsertedThenModified()
    var
        Row: Record "FC Dots Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"FC Dots Row");
        RecRef.Init();
        RecRef.Field(1).Value := 'K1';
        RecRef.Insert();
        if TryAssign(RecRef, 'stored text') then begin
            RecRef.Modify();
            Row.Get('K1');
            Observer.Observe('afterGet', ReadBody(Row));
            Row.CalcFields(Body);
            Observer.Observe('afterCalcFields', ReadBody(Row));
        end else
            Observer.Observe('assign', 'error: ' + GetLastErrorText());
#if BC28PLUS
        Observer.Expect('assign', 'error: The value "stored text" can''t be evaluated into type BLOB.');
#else
        Observer.Expect('assign', 'error: Invalid Conversion. Source: NavVariant, Destination: NavBLOB.');
#endif
        Observer.Verify();
    end;
}
