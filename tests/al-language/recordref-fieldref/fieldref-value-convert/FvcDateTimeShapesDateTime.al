// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value of a Decimal or Duration field assigned to a Date or Time (runner issue 8662 neighbors of FvcDateTimeShapes).
//   Two shapes per value: a var parameter and a plain declared local.
//   Result: every cell raises on BC 27.5, 28.5 and 29.0; the local shape gives the same error as the var parameter shape. Version split as in FvcDateTimeShapes (BC 27 names System.DateTime for the Date and Time targets too).
// BC versions: see the asserted values; a version guard is used only where the versions differ.

codeunit 75986 "FVC DateTime Shapes DT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DecField_To_Date_Shapes1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := -0.5;
        ShapesDate(Observer, FR, 'neg half');
        FR.Value := 999.99;
        ShapesDate(Observer, FR, '999.99');
        FR.Value := 1.5;
        ShapesDate(Observer, FR, '1.5');
#if BC28PLUS
        Observer.Expect('neg half var', 'error Evaluate:Conversion | The format of the Date ''-0.5'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('neg half var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('neg half local', 'same as var');
        Observer.Expect('neg half plain var', 'same as var');
        Observer.Expect('neg half plain local', 'same as var');
        Observer.Expect('neg half plain byval', 'same as var');
        Observer.Expect('neg half plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('999.99 var', 'error Evaluate:Conversion | The format of the Date ''999.99'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('999.99 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('999.99 local', 'same as var');
        Observer.Expect('999.99 plain var', 'same as var');
        Observer.Expect('999.99 plain local', 'same as var');
        Observer.Expect('999.99 plain byval', 'same as var');
        Observer.Expect('999.99 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1.5 var', 'error Evaluate:Conversion | The format of the Date ''1.5'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1.5 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('1.5 local', 'same as var');
        Observer.Expect('1.5 plain var', 'same as var');
        Observer.Expect('1.5 plain local', 'same as var');
        Observer.Expect('1.5 plain byval', 'same as var');
        Observer.Expect('1.5 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_Date_Shapes2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1;
        ShapesDate(Observer, FR, 'one');
#if BC28PLUS
        Observer.Expect('one var', 'error Evaluate:Conversion | The format of the Date ''1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('one var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('one local', 'same as var');
        Observer.Expect('one plain var', 'same as var');
        Observer.Expect('one plain local', 'same as var');
        Observer.Expect('one plain byval', 'same as var');
        Observer.Expect('one plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_Date_Shapes1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 1;
        ShapesDate(Observer, FR, '1 ms');
        FR.Value := 65000;
        ShapesDate(Observer, FR, '65000');
        FR.Value := 93780000;
        ShapesDate(Observer, FR, '1 day 2h 3m');
#if BC28PLUS
        Observer.Expect('1 ms var', 'error Evaluate:Conversion | The format of the Date ''1 millisecond'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1 ms var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 ms local', 'same as var');
        Observer.Expect('1 ms plain var', 'same as var');
        Observer.Expect('1 ms plain local', 'same as var');
        Observer.Expect('1 ms plain byval', 'same as var');
        Observer.Expect('1 ms plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('65000 var', 'error Evaluate:Conversion | The format of the Date ''1 minute 5 seconds'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('65000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('65000 local', 'same as var');
        Observer.Expect('65000 plain var', 'same as var');
        Observer.Expect('65000 plain local', 'same as var');
        Observer.Expect('65000 plain byval', 'same as var');
        Observer.Expect('65000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 day 2h 3m var', 'error Evaluate:Conversion | The format of the Date ''1 day 2 hours 3 minutes'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1 day 2h 3m var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 day 2h 3m local', 'same as var');
        Observer.Expect('1 day 2h 3m plain var', 'same as var');
        Observer.Expect('1 day 2h 3m plain local', 'same as var');
        Observer.Expect('1 day 2h 3m plain byval', 'same as var');
        Observer.Expect('1 day 2h 3m plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_Date_Shapes2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 0;
        ShapesDate(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The format of the Date '''' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_Time_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := -0.5;
        ShapesTime(Observer, FR, 'neg half');
        FR.Value := 999.99;
        ShapesTime(Observer, FR, '999.99');
        FR.Value := 1.5;
        ShapesTime(Observer, FR, '1.5');
        FR.Value := 1;
        ShapesTime(Observer, FR, 'one');
#if BC28PLUS
        Observer.Expect('neg half var', 'error Evaluate:Conversion | The value "-0.5" can''t be evaluated into type Time.');
#else
        Observer.Expect('neg half var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('neg half local', 'same as var');
        Observer.Expect('neg half plain var', 'same as var');
        Observer.Expect('neg half plain local', 'same as var');
        Observer.Expect('neg half plain byval', 'same as var');
        Observer.Expect('neg half plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('999.99 var', 'error Evaluate:Conversion | The value "999.99" can''t be evaluated into type Time.');
#else
        Observer.Expect('999.99 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('999.99 local', 'same as var');
        Observer.Expect('999.99 plain var', 'same as var');
        Observer.Expect('999.99 plain local', 'same as var');
        Observer.Expect('999.99 plain byval', 'same as var');
        Observer.Expect('999.99 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1.5 var', 'error Evaluate:Conversion | The value "1.5" can''t be evaluated into type Time.');
#else
        Observer.Expect('1.5 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('1.5 local', 'same as var');
        Observer.Expect('1.5 plain var', 'same as var');
        Observer.Expect('1.5 plain local', 'same as var');
        Observer.Expect('1.5 plain byval', 'same as var');
        Observer.Expect('1.5 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('one var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type Time.');
#else
        Observer.Expect('one var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('one local', 'same as var');
        Observer.Expect('one plain var', 'same as var');
        Observer.Expect('one plain local', 'same as var');
        Observer.Expect('one plain byval', 'same as var');
        Observer.Expect('one plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_Time_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 1;
        ShapesTime(Observer, FR, '1 ms');
        FR.Value := 65000;
        ShapesTime(Observer, FR, '65000');
        FR.Value := 93780000;
        ShapesTime(Observer, FR, '1 day 2h 3m');
        FR.Value := 0;
        ShapesTime(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('1 ms var', 'error Evaluate:Conversion | The value "1 millisecond" can''t be evaluated into type Time.');
#else
        Observer.Expect('1 ms var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 ms local', 'same as var');
        Observer.Expect('1 ms plain var', 'same as var');
        Observer.Expect('1 ms plain local', 'same as var');
        Observer.Expect('1 ms plain byval', 'same as var');
        Observer.Expect('1 ms plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('65000 var', 'error Evaluate:Conversion | The value "1 minute 5 seconds" can''t be evaluated into type Time.');
#else
        Observer.Expect('65000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('65000 local', 'same as var');
        Observer.Expect('65000 plain var', 'same as var');
        Observer.Expect('65000 plain local', 'same as var');
        Observer.Expect('65000 plain byval', 'same as var');
        Observer.Expect('65000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 day 2h 3m var', 'error Evaluate:Conversion | The value "1 day 2 hours 3 minutes" can''t be evaluated into type Time.');
#else
        Observer.Expect('1 day 2h 3m var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 day 2h 3m local', 'same as var');
        Observer.Expect('1 day 2h 3m plain var', 'same as var');
        Observer.Expect('1 day 2h 3m plain local', 'same as var');
        Observer.Expect('1 day 2h 3m plain byval', 'same as var');
        Observer.Expect('1 day 2h 3m plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "" can''t be evaluated into type Time.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_Date_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 1;
        ShapesDate(Observer, FR, '1');
        FR.Value := 1000;
        ShapesDate(Observer, FR, '1000');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The format of the Date ''1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1000 var', 'error Evaluate:Conversion | The format of the Date ''1000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('1000 local', 'same as var');
        Observer.Expect('1000 plain var', 'same as var');
        Observer.Expect('1000 plain local', 'same as var');
        Observer.Expect('1000 plain byval', 'same as var');
        Observer.Expect('1000 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_Time_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 1;
        ShapesTime(Observer, FR, '1');
        FR.Value := 1000;
        ShapesTime(Observer, FR, '1000');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type Time.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1000 var', 'error Evaluate:Conversion | The value "1000" can''t be evaluated into type Time.');
#else
        Observer.Expect('1000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('1000 local', 'same as var');
        Observer.Expect('1000 plain var', 'same as var');
        Observer.Expect('1000 plain local', 'same as var');
        Observer.Expect('1000 plain byval', 'same as var');
        Observer.Expect('1000 plain named', 'same as var');
        Observer.Verify();
    end;

    local procedure ShapesDate(var Observer: Codeunit "Probe Observer"; var FR: FieldRef; Label: Text)
    var
        Base: Text;
        Other: Text;
        Got: Text;
        Ok: Boolean;
    begin
        Other := '';
        Ok := TryVarParamDate(FR, Other);
        Base := OutcomeDate(Ok, Other);
        Observer.Observe(Label + ' var', Base);
        Other := '';
        Ok := TryLocalDate(FR, Other);
        Got := OutcomeDate(Ok, Other);
        if Got = Base then
            Observer.Observe(Label + ' local', 'same as var')
        else
            Observer.Observe(Label + ' local', Got);
        Report(Observer, Label + ' plain var', Base, PlainVarDate(FR));
        Report(Observer, Label + ' plain local', Base, PlainLocalDate(FR));
        Report(Observer, Label + ' plain byval', Base, PlainByValueDate(FR));
        Report(Observer, Label + ' plain named', Base, PlainNamedDate(FR));
    end;

    local procedure OutcomeDate(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok ' + Res);
        exit('error ' + GetLastErrorCode() + ' | ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryVarParamDate(var FR: FieldRef; var Res: Text)
    var
        P: Date;
    begin
        FillVarDate(FR, P);
        Res := Format(P, 0, 9);
    end;

    local procedure FillVarDate(var FR: FieldRef; var R: Date)
    begin
        R := FR.Value;
    end;

    [TryFunction]
    local procedure TryLocalDate(var FR: FieldRef; var Res: Text)
    var
        L: Date;
    begin
        L := FR.Value;
        Res := Format(L, 0, 9);
    end;

    local procedure ShapesTime(var Observer: Codeunit "Probe Observer"; var FR: FieldRef; Label: Text)
    var
        Base: Text;
        Other: Text;
        Got: Text;
        Ok: Boolean;
    begin
        Other := '';
        Ok := TryVarParamTime(FR, Other);
        Base := OutcomeTime(Ok, Other);
        Observer.Observe(Label + ' var', Base);
        Other := '';
        Ok := TryLocalTime(FR, Other);
        Got := OutcomeTime(Ok, Other);
        if Got = Base then
            Observer.Observe(Label + ' local', 'same as var')
        else
            Observer.Observe(Label + ' local', Got);
        Report(Observer, Label + ' plain var', Base, PlainVarTime(FR));
        Report(Observer, Label + ' plain local', Base, PlainLocalTime(FR));
        Report(Observer, Label + ' plain byval', Base, PlainByValueTime(FR));
        Report(Observer, Label + ' plain named', Base, PlainNamedTime(FR));
    end;

    local procedure OutcomeTime(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok ' + Res);
        exit('error ' + GetLastErrorCode() + ' | ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryVarParamTime(var FR: FieldRef; var Res: Text)
    var
        P: Time;
    begin
        FillVarTime(FR, P);
        Res := Format(P, 0, 9);
    end;

    local procedure FillVarTime(var FR: FieldRef; var R: Time)
    begin
        R := FR.Value;
    end;

    [TryFunction]
    local procedure TryLocalTime(var FR: FieldRef; var Res: Text)
    var
        L: Time;
    begin
        L := FR.Value;
        Res := Format(L, 0, 9);
    end;

    local procedure PlainVarDate(var FR: FieldRef): Text
    var
        P: Date;
    begin
        asserterror FillVarDate(FR, P);
        exit(OutcomeDate(false, ''));
    end;

    local procedure PlainLocalDate(var FR: FieldRef): Text
    begin
        asserterror PlainLocalBodyDate(FR);
        exit(OutcomeDate(false, ''));
    end;

    local procedure PlainLocalBodyDate(var FR: FieldRef)
    var
        L: Date;
    begin
        L := FR.Value;
    end;

    local procedure PlainByValueDate(var FR: FieldRef): Text
    begin
        asserterror FillByValueDate(FR, 0D);
        exit(OutcomeDate(false, ''));
    end;

    local procedure FillByValueDate(var FR: FieldRef; R: Date): Text
    begin
        R := FR.Value;
        exit(Format(R, 0, 9));
    end;

    local procedure PlainNamedDate(var FR: FieldRef): Text
    begin
        asserterror NamedReturnDate(FR);
        exit(OutcomeDate(false, ''));
    end;

    local procedure NamedReturnDate(var FR: FieldRef) R: Date
    begin
        R := FR.Value;
    end;

    local procedure PlainVarTime(var FR: FieldRef): Text
    var
        P: Time;
    begin
        asserterror FillVarTime(FR, P);
        exit(OutcomeTime(false, ''));
    end;

    local procedure PlainLocalTime(var FR: FieldRef): Text
    begin
        asserterror PlainLocalBodyTime(FR);
        exit(OutcomeTime(false, ''));
    end;

    local procedure PlainLocalBodyTime(var FR: FieldRef)
    var
        L: Time;
    begin
        L := FR.Value;
    end;

    local procedure PlainByValueTime(var FR: FieldRef): Text
    begin
        asserterror FillByValueTime(FR, 0T);
        exit(OutcomeTime(false, ''));
    end;

    local procedure FillByValueTime(var FR: FieldRef; R: Time): Text
    begin
        R := FR.Value;
        exit(Format(R, 0, 9));
    end;

    local procedure PlainNamedTime(var FR: FieldRef): Text
    begin
        asserterror NamedReturnTime(FR);
        exit(OutcomeTime(false, ''));
    end;

    local procedure NamedReturnTime(var FR: FieldRef) R: Time
    begin
        R := FR.Value;
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Label: Text; Base: Text; Got: Text)
    begin
        if Got = Base then
            Observer.Observe(Label, 'same as var')
        else
            Observer.Observe(Label, Got);
    end;
}
