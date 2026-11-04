// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-copylinks-method
// Scope: in-scope
// Fixtures used: tables 72694-72695, codeunit 72696 (P107Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CopyLinks overloads between TEMPORARY records only (no Record Link rows exist or are written); DeleteLink with a missing id on a temporary record
// BC versions: 29 (27 and 28 by CI)

codeunit 72698 "LT P107 CopyLinks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_CopyLinksTemporary()
    var
        Observer: Codeunit "Probe Observer";
        SrcRec: Record "LT P107 Rec" temporary;
        DstRec: Record "LT P107 Rec" temporary;
        SrcRef: RecordRef;
        DstRef: RecordRef;
        V: Variant;
    begin
        SrcRec.Code := 'S1';
        SrcRec.Insert();
        DstRec.Code := 'D1';
        DstRec.Insert();
        SrcRef.GetTable(SrcRec);
        DstRef.GetTable(DstRec);
        DstRef.CopyLinks(SrcRec);
        Observer.Observe('recordref_from_record', Format(DstRef.HasLinks()));
        DstRef.CopyLinks(SrcRef);
        Observer.Observe('recordref_from_recordref', Format(DstRef.HasLinks()));
        V := SrcRec;
        DstRef.CopyLinks(V);
        Observer.Observe('recordref_from_variant_record', Format(DstRef.HasLinks()));
        V := SrcRef;
        DstRef.CopyLinks(V);
        Observer.Observe('recordref_from_variant_recordref', Format(DstRef.HasLinks()));
        DstRec.CopyLinks(SrcRef);
        Observer.Observe('record_from_recordref', Format(DstRec.HasLinks()));
        DstRec.CopyLinks(SrcRec);
        Observer.Observe('record_from_record', Format(DstRec.HasLinks()));
        Observer.Expect('recordref_from_record', 'No');
        Observer.Expect('recordref_from_recordref', 'No');
        Observer.Expect('recordref_from_variant_record', 'No');
        Observer.Expect('recordref_from_variant_recordref', 'No');
        Observer.Expect('record_from_recordref', 'No');
        Observer.Expect('record_from_record', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P107_CopyLinksErrors()
    var
        Observer: Codeunit "Probe Observer";
        SrcRec: Record "LT P107 Rec" temporary;
        DstRef: RecordRef;
        Dest: Record "LT P107 Dest" temporary;
        V: Variant;
        Txt: Text;
    begin
        SrcRec.Code := 'S1';
        SrcRec.Insert();
        DstRef.Open(72695, true);
        DstRef.CopyLinks(SrcRec);
        Observer.Observe('other_table_record', 'no error');
        Txt := 'x';
        V := Txt;
        asserterror DstRef.CopyLinks(V);
        Observer.ObserveError('variant_text');
        Clear(V);
        asserterror DstRef.CopyLinks(V);
        Observer.ObserveError('variant_empty');
        Observer.Expect('other_table_record', 'no error');
        Observer.Expect('variant_text|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.');
        Observer.Expect('variant_text|code', 'Conversion');
        Observer.Expect('variant_empty|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('variant_empty|code', 'NotInitialized');
        Observer.Verify();
    end;
}
