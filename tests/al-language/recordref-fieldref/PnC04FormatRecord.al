// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Child (71081)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Format(Record) "a FlowFilter field is left out of the text; a Blob read from the table and not loaded shows * ..." (probe batch 6, item 4); also TableFilter "Format of a TableFilter field nobody set is the empty text"
// BC versions: 29 (27 and 28 by CI)

codeunit 71105 "LT PnC Format Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Visible(Value: Text): Text
    begin
        exit(Value);
    end;

    [Test]
    procedure FlowFilter_InTheText()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
        RR: RecordRef;
    begin
        R.DeleteAll();
        R."No." := 1;
        R.Name := 'x';
        R.Insert();
        R.Get(1);
        Observer.Observe('plain', Visible(Format(R)));
        R.SetRange("Flow Flt", 5);
        Observer.Observe('flowFilterSet', Visible(Format(R)));
        R.SetRange("Flow Flt");
        Observer.Observe('flowFilterCleared', Visible(Format(R)));
        RR.GetTable(R);
        Observer.Observe('recordRef', Visible(Format(RR)));
        Observer.Expect('plain', '1\tx\t\t0\t0\t \t\tOpen\t0\t0');
        Observer.Expect('flowFilterSet', '1\tx\t\t0\t0\t \t\tOpen\t0\t0');
        Observer.Expect('flowFilterCleared', '1\tx\t\t0\t0\t \t\tOpen\t0\t0');
        Observer.Expect('recordRef', '1\tx\t\t0\t0\t \t\tOpen\t0\t0');
        Observer.Verify();
    end;

    [Test]
    procedure BlobNotLoaded_AfterGet()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
        W: Record "LT PnC Rec";
        OutS: OutStream;
    begin
        R.DeleteAll();
        R."No." := 1;
        R.Note.CreateOutStream(OutS);
        OutS.WriteText('abc');
        R.Insert();
        R."No." := 2;
        R.Insert();
        W.Get(1);
        Observer.Observe('filledBlob.afterGet', Visible(Format(W)));
        W.CalcFields(Note);
        Observer.Observe('filledBlob.afterCalcFields', Visible(Format(W)));
        W.Get(2);
        Observer.Observe('emptyBlob.afterGet', Visible(Format(W)));
        W.CalcFields(Note);
        Observer.Observe('emptyBlob.afterCalcFields', Visible(Format(W)));
        Observer.Expect('filledBlob.afterGet', '1\t\t\t0\t0\t*\t\tOpen\t0\t0');
        Observer.Expect('filledBlob.afterCalcFields', '1\t\t\t0\t0\t*\t\tOpen\t0\t0');
        Observer.Expect('emptyBlob.afterGet', '2\t\t\t0\t0\t*\t\tOpen\t0\t0');
        Observer.Expect('emptyBlob.afterCalcFields', '2\t\t\t0\t0\t*\t\tOpen\t0\t0');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCopiedByAssignment()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
        W: Record "LT PnC Rec";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        R.DeleteAll();
        R."No." := 1;
        R.Note.CreateOutStream(OutS);
        OutS.WriteText('abc');
        R.Insert();
        R.Get(1);
        W := R;
        Observer.Observe('copy', Visible(Format(W)));
        W.CalcFields(Note);
        W.Note.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('copyBytes', Txt);
        Observer.Observe('copyHasValue', Format(W.Note.HasValue()));
        Observer.Expect('copy', '1\t\t\t0\t0\t*\t\tOpen\t0\t0');
        Observer.Expect('copyBytes', 'abc');
        Observer.Expect('copyHasValue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterField_Unset()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.DeleteAll();
        R."No." := 1;
        R.Insert();
        R.Get(1);
        Observer.Observe('formatField', Format(R."Table Flt"));
        Observer.Observe('formatField.len', Format(StrLen(Format(R."Table Flt"))));
        RR.GetTable(R);
        FR := RR.Field(9);
        Observer.Observe('fieldRef', Format(FR.Value));
        Observer.Observe('fieldRef.type', Format(FR.Type));
        Observer.Observe('fieldRef.class', Format(FR.Class));
        Observer.Expect('formatField', '');
        Observer.Expect('formatField.len', '0');
        Observer.Expect('fieldRef', '');
        Observer.Expect('fieldRef.type', 'TableFilter');
        Observer.Expect('fieldRef.class', 'Normal');
        Observer.Verify();
    end;
}
