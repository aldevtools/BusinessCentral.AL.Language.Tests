// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95950
// Probe: written against real BC; every literal asserted below is what BC produced (corpus CI matrix, BC 27.5, 28.5 and 29.0).
// Facts: Target.Blob := Source.Blob leaves two independent values (Clear, new write on either side), through a Variant, a by-value and a var parameter, for temporary and stored tables; contrast with Record := Record; importer shape of one reused buffer record
// BC versions: 27.5+

codeunit 95951 "LT BFA Blob Assign Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SetBody(var Rec: Record "LT BFA Rec"; Txt: Text)
    var
        OutS: OutStream;
    begin
        Rec.Body.CreateOutStream(OutS);
        OutS.WriteText(Txt);
    end;

    local procedure Read(var B: Record "LT BFA Rec"; Which: Integer): Text
    var
        InS: InStream;
        T: Text;
    begin
        if Which = 1 then begin
            if not B.Body.HasValue() then
                exit('<no value>');
            B.Body.CreateInStream(InS);
        end else begin
            if not B.Other.HasValue() then
                exit('<no value>');
            B.Other.CreateInStream(InS);
        end;
        InS.ReadText(T);
        exit(T);
    end;

    local procedure ReadBody(var B: Record "LT BFA Rec"): Text
    begin
        exit(Read(B, 1));
    end;

    local procedure ReadOther(var B: Record "LT BFA Rec"): Text
    begin
        exit(Read(B, 2));
    end;

    local procedure Fresh(var Src: Record "LT BFA Rec"; var Dst: Record "LT BFA Rec")
    begin
        Src.DeleteAll();
        Dst.DeleteAll();
        Src.Init();
        Src."Key" := 1;
        SetBody(Src, 'src');
        Src.Insert();
        Src.CalcFields(Body);
        Dst.Init();
        Dst."Key" := 2;
        Dst.Insert();
    end;

    local procedure AssignByValue(Value: Record "LT BFA Rec"; var Dst: Record "LT BFA Rec")
    begin
        Dst.Other := Value.Body;
    end;

    local procedure AssignByVar(var Value: Record "LT BFA Rec"; var Dst: Record "LT BFA Rec")
    begin
        Dst.Other := Value.Body;
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; var Src: Record "LT BFA Rec"; var Dst: Record "LT BFA Rec"; P: Text)
    var
        OutS: OutStream;
    begin
        // 1 and 2: Clear the source, then write the source again
        Fresh(Src, Dst);
        Dst.Body := Src.Body;
        Observer.Observe(P + '-assign-target', ReadBody(Dst));
        Clear(Src.Body);
        Observer.Observe(P + '-clear-source-target', ReadBody(Dst));
        Observer.Observe(P + '-clear-source-source', ReadBody(Src));
        Src.Body.CreateOutStream(OutS);
        OutS.WriteText('new');
        Observer.Observe(P + '-rewrite-source-target', ReadBody(Dst));
        Observer.Observe(P + '-rewrite-source-source', ReadBody(Src));

        // 3: write the target
        Fresh(Src, Dst);
        Dst.Body := Src.Body;
        SetBody(Dst, 'dst');
        Observer.Observe(P + '-write-target-source', ReadBody(Src));
        Observer.Observe(P + '-write-target-target', ReadBody(Dst));

        // 3b: Clear the target
        Fresh(Src, Dst);
        Dst.Body := Src.Body;
        Clear(Dst.Body);
        Observer.Observe(P + '-clear-target-source', ReadBody(Src));
        Observer.Observe(P + '-clear-target-target', ReadBody(Dst));

        // 4: Variant, by value, var
        Fresh(Src, Dst);
        AssignByValue(Src, Dst);
        Clear(Src.Body);
        Observer.Observe(P + '-byvalue-clear-source-target', ReadOther(Dst));
        Fresh(Src, Dst);
        AssignByVar(Src, Dst);
        Clear(Src.Body);
        Observer.Observe(P + '-byvar-clear-source-target', ReadOther(Dst));
        Fresh(Src, Dst);
        AssignVariant(Src, Dst);
        Clear(Src.Body);
        Observer.Observe(P + '-variant-clear-source-target', ReadOther(Dst));

        // 5: Record := Record contrast
        Fresh(Src, Dst);
        Dst := Src;
        Clear(Src.Body);
        Observer.Observe(P + '-recassign-clear-source-target', ReadBody(Dst));
        Observer.Observe(P + '-recassign-clear-source-source', ReadBody(Src));
        Fresh(Src, Dst);
        Dst := Src;
        SetBody(Dst, 'dst');
        Observer.Observe(P + '-recassign-write-target-source', ReadBody(Src));
    end;

    local procedure AssignVariant(var Src: Record "LT BFA Rec"; var Dst: Record "LT BFA Rec")
    var
        V: Variant;
    begin
        V := Src.Body;
        Dst.Other := V;
    end;

    local procedure Importer(var Observer: Codeunit "Probe Observer"; var Buf: Record "LT BFA Rec"; var Line: Record "LT BFA Rec"; P: Text)
    begin
        SetBody(Buf, 'first');
        Line.Body := Buf.Body;
        // second node is missing: the importer clears the buffer
        Clear(Buf.Body);
        Line.Other := Buf.Body;
        Observer.Observe(P + '-importer-body', ReadBody(Line));
        Observer.Observe(P + '-importer-other', ReadOther(Line));
        Observer.Observe(P + '-importer-buffer', ReadBody(Buf));
        // the buffer is reused with a new value
        SetBody(Buf, 'second');
        Line.Other := Buf.Body;
        Observer.Observe(P + '-importer-reuse-body', ReadBody(Line));
        Observer.Observe(P + '-importer-reuse-other', ReadOther(Line));
    end;

    local procedure ExpectAll(var Observer: Codeunit "Probe Observer"; P: Text)
    begin
        Observer.Expect(P + '-assign-target', 'src');
        Observer.Expect(P + '-clear-source-target', 'src');
        Observer.Expect(P + '-clear-source-source', '<no value>');
        Observer.Expect(P + '-rewrite-source-target', 'src');
        Observer.Expect(P + '-rewrite-source-source', 'new');
        Observer.Expect(P + '-write-target-source', 'src');
        Observer.Expect(P + '-write-target-target', 'dst');
        Observer.Expect(P + '-clear-target-source', 'src');
        Observer.Expect(P + '-clear-target-target', '<no value>');
        Observer.Expect(P + '-byvalue-clear-source-target', 'src');
        Observer.Expect(P + '-byvar-clear-source-target', 'src');
        Observer.Expect(P + '-variant-clear-source-target', 'src');
        Observer.Expect(P + '-recassign-clear-source-target', 'src');
        Observer.Expect(P + '-recassign-clear-source-source', '<no value>');
        Observer.Expect(P + '-recassign-write-target-source', 'src');
        Observer.Expect(P + '-importer-body', 'first');
        Observer.Expect(P + '-importer-other', '<no value>');
        Observer.Expect(P + '-importer-buffer', '<no value>');
        Observer.Expect(P + '-importer-reuse-body', 'first');
        Observer.Expect(P + '-importer-reuse-other', 'second');
    end;

    [Test]
    procedure Temporary_Tables()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFA Rec" temporary;
        Dst: Record "LT BFA Rec" temporary;
        Buf: Record "LT BFA Rec" temporary;
        Line: Record "LT BFA Rec" temporary;
    begin
        RunCase(Observer, Src, Dst, 'tmp');
        Importer(Observer, Buf, Line, 'tmp');
        ExpectAll(Observer, 'tmp');
        Observer.Verify();
    end;

    [Test]
    procedure Stored_Tables()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFA Rec";
        Dst: Record "LT BFA Rec";
        Buf: Record "LT BFA Rec";
        Line: Record "LT BFA Rec";
    begin
        RunCase(Observer, Src, Dst, 'db');
        Importer(Observer, Buf, Line, 'db');
        ExpectAll(Observer, 'db');
        Observer.Verify();
    end;
}
