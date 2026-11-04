// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70087
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams: Blob.Length of a Blob not loaded with CalcFields is the content length plus 6
// Facts: Blob.Length before and after CalcFields for stored sizes 0, 1, 2, 5, 100, 10000 and 100000 bytes
// BC versions: 29 (27 and 28 by CI)

codeunit 70093 "LT PnA Blob Length"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Measure(var Observer: Codeunit "Probe Observer"; N: Integer)
    var
        Rec: Record "LT PnA Blob";
        Got: Record "LT PnA Blob";
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Code := 'K';
        if N > 0 then begin
            Rec.Data.CreateOutStream(OutS);
            OutS.WriteText(PadStr('', N, 'x'));
        end;
        Rec.Insert();
        Got.Get('K');
        Observer.Observe('unloaded-' + Format(N), Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Got.CalcFields(Data);
        Observer.Observe('loaded-' + Format(N), Format(Got.Data.Length()) + '|' + Format(Got.Data.HasValue()));
        Rec.DeleteAll();
    end;

#if BC29PLUS
    [Test]
    procedure Length_ByStoredSize()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Measure(Observer, 0);
        Measure(Observer, 1);
        Measure(Observer, 2);
        Measure(Observer, 5);
        Measure(Observer, 100);
        Measure(Observer, 10000);
        Measure(Observer, 100000);
        Observer.Expect('unloaded-0', '0|No');
        Observer.Expect('loaded-0', '0|No');
        Observer.Expect('unloaded-1', '7|Yes');
        Observer.Expect('loaded-1', '1|Yes');
        Observer.Expect('unloaded-2', '8|Yes');
        Observer.Expect('loaded-2', '2|Yes');
        Observer.Expect('unloaded-5', '11|Yes');
        Observer.Expect('loaded-5', '5|Yes');
        Observer.Expect('unloaded-100', '10|Yes');
        Observer.Expect('loaded-100', '100|Yes');
        Observer.Expect('unloaded-10000', '31|Yes');
        Observer.Expect('loaded-10000', '10000|Yes');
        Observer.Expect('unloaded-100000', '118|Yes');
        Observer.Expect('loaded-100000', '100000|Yes');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Length_InMemoryAndFindVariants()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnA Blob";
        Got: Record "LT PnA Blob";
        Tmp: Record "LT PnA Blob" temporary;
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Code := 'K';
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText('hello');
        Observer.Observe('in-memory-before-insert', Format(Rec.Data.Length()));
        Rec.Insert();
        Observer.Observe('in-memory-after-insert', Format(Rec.Data.Length()));
        Got.FindFirst();
        Observer.Observe('findfirst-unloaded', Format(Got.Data.Length()));
        Got.SetAutoCalcFields(Data);
        Got.FindFirst();
        Observer.Observe('findfirst-autocalc', Format(Got.Data.Length()));
        Tmp.Code := 'T';
        Tmp.Data.CreateOutStream(OutS);
        OutS.WriteText('hello');
        Tmp.Insert();
        Tmp.Get('T');
        Observer.Observe('temporary-regot', Format(Tmp.Data.Length()));
        Rec.DeleteAll();
        Observer.Expect('in-memory-before-insert', '5');
        Observer.Expect('in-memory-after-insert', '5');
        Observer.Expect('findfirst-unloaded', '11');
        Observer.Expect('findfirst-autocalc', '5');
        Observer.Expect('temporary-regot', '5');
        Observer.Verify();
    end;
}
