// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93805, codeunits 93806-93808 (writer Y71, gap cycle 7 spec G7-02)
// Probe: two InStreams created over one Temp Blob, one handed to a procedure by value (or by var) and read there with Read(Text, 4000), the other
//        read line by line with ReadText afterwards; the Temp Blob copied through a codeunit global and through an event subscriber of a bound
//        manual instance; Read(Text, 4000) on a stream shorter than 4000; one InStream variable created twice; the same on a table Blob field.
//        The lines are written the way the Microsoft test writes them: WriteText(Line) then WriteText() on an OutStream passed by value.
//        Per read: return value, text length, number of CR and LF characters, EOS before and after, each line of the loop.

table 93805 "LT Y71 Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93806 "LT Y71 TB Pub"
{
    [IntegrationEvent(false, false)]
    local procedure OnGetBlob(var TB: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnKeepBlob(var TB: Codeunit "Temp Blob")
    begin
    end;

    procedure GetBlob(var TB: Codeunit "Temp Blob")
    begin
        OnGetBlob(TB);
    end;

    procedure KeepBlob(var TB: Codeunit "Temp Blob")
    begin
        OnKeepBlob(TB);
    end;
}

codeunit 93807 "LT Y71 TB Holder"
{
    EventSubscriberInstance = Manual;

    var
        Held: Codeunit "Temp Blob";

    procedure Keep(var TB: Codeunit "Temp Blob")
    begin
        Held := TB;
    end;

    procedure Give(var TB: Codeunit "Temp Blob")
    begin
        TB := Held;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y71 TB Pub", 'OnGetBlob', '', false, false)]
    local procedure OnGetBlob(var TB: Codeunit "Temp Blob")
    begin
        TB := Held;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y71 TB Pub", 'OnKeepBlob', '', false, false)]
    local procedure OnKeepBlob(var TB: Codeunit "Temp Blob")
    begin
        Held := TB;
    end;
}

codeunit 93808 "LT Y71 Two InStreams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure WriteLine(O: OutStream; Line: Text)
    begin
        O.WriteText(Line);
        O.WriteText();
    end;

    local procedure Fill(var TB: Codeunit "Temp Blob")
    var
        O: OutStream;
    begin
        TB.CreateOutStream(O);
        WriteLine(O, 'Date;Description;Amount');
        WriteLine(O, '01.01.2024;First;10,5');
        WriteLine(O, '02.01.2024;Second;20,25');
    end;

    local procedure ReadSepByValue(S: InStream): Text
    var
        Start: Text;
    begin
        S.Read(Start, 4000);
        exit(Start);
    end;

    local procedure ReadSepByVar(var S: InStream): Text
    var
        Start: Text;
    begin
        S.Read(Start, 4000);
        exit(Start);
    end;

    local procedure Count(Value: Text; Ch: Char): Integer
    var
        i: Integer;
        N: Integer;
    begin
        for i := 1 to StrLen(Value) do
            if Value[i] = Ch then
                N += 1;
        exit(N);
    end;

    local procedure Describe(Value: Text): Text
    begin
        exit(StrSubstNo('len=%1 cr=%2 lf=%3', StrLen(Value), Count(Value, 13), Count(Value, 10)));
    end;

    local procedure Lines(Name: Text; var S: InStream)
    var
        Line: Text;
        N: Integer;
    begin
        while not S.EOS() do begin
            N += 1;
            S.ReadText(Line);
            Obs.Observe(Name + '|line' + Format(N), Line);
        end;
        Obs.Observe(Name + '|lines', Format(N));
    end;

    local procedure TwoStreams(Name: Text; var TB: Codeunit "Temp Blob"; Mode: Integer)
    var
        A: InStream;
        B: InStream;
        Direct: Text;
        Sep: Text;
    begin
        TB.CreateInStream(A);
        TB.CreateInStream(B);
        case Mode of
            1:
                Sep := ReadSepByValue(B);
            2:
                Sep := ReadSepByVar(B);
            3:
                begin
                    B.Read(Direct, 4000);
                    Sep := Direct;
                end;
        end;
        Obs.Observe(Name + '|sep', Describe(Sep));
        Obs.Observe(Name + '|a_eos_before', Format(A.EOS()));
        Obs.Observe(Name + '|b_eos', Format(B.EOS()));
        Lines(Name, A);
        Obs.Observe(Name + '|a_eos_after', Format(A.EOS()));
        Obs.Observe(Name + '|b_eos_after', Format(B.EOS()));
    end;

    [Test]
    procedure TwoInStreams_SameTempBlob_ReadInTurn()
    var
        TB: Codeunit "Temp Blob";
    begin
        Fill(TB);
        Obs.Observe('has_value', Format(TB.HasValue()));
        Obs.Observe('length', Format(TB.Length()));
        TwoStreams('by_value', TB, 1);
        Obs.Finish();
    end;

    [Test]
    procedure TwoInStreams_Var_And_Direct()
    var
        TB: Codeunit "Temp Blob";
        TB2: Codeunit "Temp Blob";
    begin
        Fill(TB);
        TwoStreams('by_var', TB, 2);
        Fill(TB2);
        TwoStreams('direct', TB2, 3);
        Obs.Finish();
    end;

    [Test]
    procedure TempBlob_CopiedThroughCodeunitGlobal()
    var
        TB: Codeunit "Temp Blob";
        TB2: Codeunit "Temp Blob";
        Holder: Codeunit "LT Y71 TB Holder";
    begin
        Fill(TB);
        Holder.Keep(TB);
        Holder.Give(TB2);
        Obs.Observe('has_value', Format(TB2.HasValue()));
        Obs.Observe('length', Format(TB2.Length()));
        TwoStreams('copied', TB2, 1);
        Obs.Finish();
    end;

    [Test]
    procedure TempBlob_CopiedThroughSubscriberOfBoundInstance()
    var
        TB: Codeunit "Temp Blob";
        TB2: Codeunit "Temp Blob";
        Holder: Codeunit "LT Y71 TB Holder";
        Pub: Codeunit "LT Y71 TB Pub";
    begin
        BindSubscription(Holder);
        Fill(TB);
        Pub.KeepBlob(TB);
        Pub.GetBlob(TB2);
        UnbindSubscription(Holder);
        Obs.Observe('has_value', Format(TB2.HasValue()));
        Obs.Observe('length', Format(TB2.Length()));
        TwoStreams('event', TB2, 1);
        Obs.Finish();
    end;

    [Test]
    procedure TempBlob_KeepInPlace_ThenCopyBack_ReadOriginal()
    var
        TB: Codeunit "Temp Blob";
        TB2: Codeunit "Temp Blob";
        Holder: Codeunit "LT Y71 TB Holder";
    begin
        Fill(TB);
        Holder.Keep(TB);
        Holder.Give(TB2);
        TwoStreams('original', TB, 1);
        Obs.Observe('copy_length_after', Format(TB2.Length()));
        Obs.Finish();
    end;

    [Test]
    procedure Read_LongerThanStream()
    var
        TB: Codeunit "Temp Blob";
        O: OutStream;
        S: InStream;
        T: Text;
        Count: Integer;
    begin
        TB.CreateOutStream(O);
        O.WriteText('abcdefghij0123456789');
        TB.CreateInStream(S);
        Count := S.Read(T, 4000);
        Obs.Observe('first_count', Format(Count));
        Obs.Observe('first_text', T);
        Obs.Observe('eos_after', Format(S.EOS()));
        T := 'kept';
        Count := S.Read(T, 4000);
        Obs.Observe('second_count', Format(Count));
        Obs.Observe('second_text', T);
        Obs.Observe('eos_after_second', Format(S.EOS()));
        Clear(S);
        TB.CreateInStream(S);
        Count := S.Read(T, 5);
        Obs.Observe('five_count', Format(Count));
        Obs.Observe('five_text', T);
        Obs.Finish();
    end;

    [Test]
    procedure SameInStreamVariable_CreatedTwice()
    var
        TB: Codeunit "Temp Blob";
        A: InStream;
        Line: Text;
    begin
        Fill(TB);
        TB.CreateInStream(A);
        A.ReadText(Line);
        Obs.Observe('first', Line);
        TB.CreateInStream(A);
        A.ReadText(Line);
        Obs.Observe('after_recreate', Line);
        A.ReadText(Line);
        Obs.Observe('next', Line);
        Obs.Finish();
    end;

    [Test]
    procedure BlobField_TwoInStreams_CreatedTwice()
    var
        Row: Record "LT Y71 Blob Row";
        O: OutStream;
        A: InStream;
        B: InStream;
        Line: Text;
        Start: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Data.CreateOutStream(O);
        WriteLine(O, 'Date;Description;Amount');
        WriteLine(O, '01.01.2024;First;10,5');
        Row.Insert();
        Row.Get(1);
        Row.CalcFields(Data);
        Row.Data.CreateInStream(A);
        Row.Data.CreateInStream(B);
        B.Read(Start, 4000);
        Obs.Observe('sep', Describe(Start));
        A.ReadText(Line);
        Obs.Observe('line_a', Line);
        Row.Data.CreateInStream(A);
        A.ReadText(Line);
        Obs.Observe('line_a_again', Line);
        Obs.Finish();
    end;
}
