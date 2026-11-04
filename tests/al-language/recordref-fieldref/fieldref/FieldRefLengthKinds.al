// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 73955, table 73956, test codeunit 73957
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 9 (NP Retail blockers): FieldRef.Length of an Enum, Option, Code, Text, Integer, Decimal, Date, Boolean, Guid, BigInteger
// and Blob field; of a Text field with a Text[n] length and; the result or the error text and code.
// BC versions: 27, 28, 29

enum 73955 "LT FLK Enum"
{
    Extensible = true;
    value(0; A) { }
    value(1; LongerValueName) { }
}

table 73956 "LT FLK Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[17]) { }
        field(3; Tx; Text[45]) { }
        field(5; Dc; Decimal) { }
        field(6; Dt; Date) { }
        field(7; Bo; Boolean) { }
        field(8; Gd; Guid) { }
        field(9; Bi; BigInteger) { }
        field(10; Op; Option) { OptionMembers = A,LongerOption; }
        field(11; En; Enum "LT FLK Enum") { }
        field(12; Bl; Blob) { }
        field(13; Tm; Time) { }
        field(14; Du; Duration) { }
        field(15; DtTm; DateTime) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73957 "LT FLK FieldRef Length"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLength(var F: FieldRef; var Res: Text)
    begin
        Res := Format(F.Length());
    end;

    local procedure Show(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok:' + Res);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Probe(var RR: RecordRef; FieldNo: Integer; Observer: Codeunit "Probe Observer")
    var
        F: FieldRef;
        Res: Text;
    begin
        F := RR.Field(FieldNo);
        Res := '';
        Observer.Observe(F.Name, Show(TryLength(F, Res), Res));
    end;

    [Test]
    procedure Length_TextAndCodeKinds()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(Database::"LT FLK Rec");
        Probe(RR, 2, Observer);
        Probe(RR, 3, Observer);
        Observer.Expect('Cd', 'ok:17');
        Observer.Expect('Tx', 'ok:45');
        Observer.Verify();
    end;

    [Test]
    procedure Length_EnumAndOptionKinds()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(Database::"LT FLK Rec");
        Probe(RR, 10, Observer);
        Probe(RR, 11, Observer);
        Observer.Expect('Op', 'ok:4');
        Observer.Expect('En', 'ok:4');
        Observer.Verify();
    end;

    [Test]
    procedure Length_NumericAndOtherKinds()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(Database::"LT FLK Rec");
        Probe(RR, 1, Observer);
        Probe(RR, 5, Observer);
        Probe(RR, 6, Observer);
        Probe(RR, 7, Observer);
        Probe(RR, 8, Observer);
        Probe(RR, 9, Observer);
        Probe(RR, 12, Observer);
        Probe(RR, 13, Observer);
        Probe(RR, 14, Observer);
        Probe(RR, 15, Observer);
        Observer.Expect('Id', 'ok:4');
        Observer.Expect('Dc', 'ok:12');
        Observer.Expect('Dt', 'ok:4');
        Observer.Expect('Bo', 'ok:4');
        Observer.Expect('Gd', 'ok:16');
        Observer.Expect('Bi', 'ok:8');
        Observer.Expect('Bl', 'ok:8');
        Observer.Expect('Tm', 'ok:4');
        Observer.Expect('Du', 'ok:8');
        Observer.Expect('DtTm', 'ok:8');
        Observer.Verify();
    end;
}
