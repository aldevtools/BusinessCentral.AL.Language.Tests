// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value of a Text or Code field holding a digit string assigned to a DateTime, Date or Time (runner issue 8662).
//   Compact date and time forms: 8, 14, 12, 6 and 4 digits and short numbers. DateTime targets use the four shapes of FvcDateTimeShapes,
//   Date and Time targets a var parameter and a plain local.
//   Result: no digit string converts, in any shape, on BC 27.5, 28.5 and 29.0. Date targets raise the 'format of the Date ... does not match your device's date settings' text on BC 28 and later; Time and DateTime targets the Evaluate text.
//   BC 27 raises 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText (or NavCode) to System.DateTime.' for all three targets, Date and Time included.
// BC versions: see the asserted values; a version guard is used only where the versions differ.

codeunit 75987 "FVC DateTime Digits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TextField_To_DateTime_Digits1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '20260115';
        Shapes(Observer, FR, '20260115');
        FR.Value := '20260115120000';
        Shapes(Observer, FR, '20260115120000');
        FR.Value := '202601151200';
        Shapes(Observer, FR, '202601151200');
        FR.Value := '120000';
        Shapes(Observer, FR, '120000');
        FR.Value := '1200';
        Shapes(Observer, FR, '1200');
#if BC28PLUS
        Observer.Expect('20260115 var', 'error Evaluate:Conversion | The value "20260115" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('20260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('20260115 local', 'same as var');
        Observer.Expect('20260115 byval', 'same as var');
        Observer.Expect('20260115 named', 'same as var');
        Observer.Expect('20260115 plain var', 'same as var');
        Observer.Expect('20260115 plain local', 'same as var');
        Observer.Expect('20260115 plain byval', 'same as var');
        Observer.Expect('20260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('20260115120000 var', 'error Evaluate:Conversion | The value "20260115120000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('20260115120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('20260115120000 local', 'same as var');
        Observer.Expect('20260115120000 byval', 'same as var');
        Observer.Expect('20260115120000 named', 'same as var');
        Observer.Expect('20260115120000 plain var', 'same as var');
        Observer.Expect('20260115120000 plain local', 'same as var');
        Observer.Expect('20260115120000 plain byval', 'same as var');
        Observer.Expect('20260115120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('202601151200 var', 'error Evaluate:Conversion | The value "202601151200" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('202601151200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('202601151200 local', 'same as var');
        Observer.Expect('202601151200 byval', 'same as var');
        Observer.Expect('202601151200 named', 'same as var');
        Observer.Expect('202601151200 plain var', 'same as var');
        Observer.Expect('202601151200 plain local', 'same as var');
        Observer.Expect('202601151200 plain byval', 'same as var');
        Observer.Expect('202601151200 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('120000 var', 'error Evaluate:Conversion | The value "120000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('120000 local', 'same as var');
        Observer.Expect('120000 byval', 'same as var');
        Observer.Expect('120000 named', 'same as var');
        Observer.Expect('120000 plain var', 'same as var');
        Observer.Expect('120000 plain local', 'same as var');
        Observer.Expect('120000 plain byval', 'same as var');
        Observer.Expect('120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1200 var', 'error Evaluate:Conversion | The value "1200" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('1200 local', 'same as var');
        Observer.Expect('1200 byval', 'same as var');
        Observer.Expect('1200 named', 'same as var');
        Observer.Expect('1200 plain var', 'same as var');
        Observer.Expect('1200 plain local', 'same as var');
        Observer.Expect('1200 plain byval', 'same as var');
        Observer.Expect('1200 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_DateTime_Digits2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '0115';
        Shapes(Observer, FR, '0115');
        FR.Value := '01152026';
        Shapes(Observer, FR, '01152026');
        FR.Value := '260115';
        Shapes(Observer, FR, '260115');
        FR.Value := '1';
        Shapes(Observer, FR, '1');
        FR.Value := '0';
        Shapes(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0115 var', 'error Evaluate:Conversion | The value "0115" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('0115 local', 'same as var');
        Observer.Expect('0115 byval', 'same as var');
        Observer.Expect('0115 named', 'same as var');
        Observer.Expect('0115 plain var', 'same as var');
        Observer.Expect('0115 plain local', 'same as var');
        Observer.Expect('0115 plain byval', 'same as var');
        Observer.Expect('0115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('01152026 var', 'error Evaluate:Conversion | The value "01152026" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('01152026 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('01152026 local', 'same as var');
        Observer.Expect('01152026 byval', 'same as var');
        Observer.Expect('01152026 named', 'same as var');
        Observer.Expect('01152026 plain var', 'same as var');
        Observer.Expect('01152026 plain local', 'same as var');
        Observer.Expect('01152026 plain byval', 'same as var');
        Observer.Expect('01152026 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('260115 var', 'error Evaluate:Conversion | The value "260115" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('260115 local', 'same as var');
        Observer.Expect('260115 byval', 'same as var');
        Observer.Expect('260115 named', 'same as var');
        Observer.Expect('260115 plain var', 'same as var');
        Observer.Expect('260115 plain local', 'same as var');
        Observer.Expect('260115 plain byval', 'same as var');
        Observer.Expect('260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 byval', 'same as var');
        Observer.Expect('1 named', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "0" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 byval', 'same as var');
        Observer.Expect('0 named', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_DateTime_Digits1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '20260115';
        Shapes(Observer, FR, '20260115');
        FR.Value := '20260115120000';
        Shapes(Observer, FR, '20260115120000');
        FR.Value := '202601151200';
        Shapes(Observer, FR, '202601151200');
        FR.Value := '120000';
        Shapes(Observer, FR, '120000');
        FR.Value := '1200';
        Shapes(Observer, FR, '1200');
#if BC28PLUS
        Observer.Expect('20260115 var', 'error Evaluate:Conversion | The value "20260115" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('20260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('20260115 local', 'same as var');
        Observer.Expect('20260115 byval', 'same as var');
        Observer.Expect('20260115 named', 'same as var');
        Observer.Expect('20260115 plain var', 'same as var');
        Observer.Expect('20260115 plain local', 'same as var');
        Observer.Expect('20260115 plain byval', 'same as var');
        Observer.Expect('20260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('20260115120000 var', 'error Evaluate:Conversion | The value "20260115120000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('20260115120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('20260115120000 local', 'same as var');
        Observer.Expect('20260115120000 byval', 'same as var');
        Observer.Expect('20260115120000 named', 'same as var');
        Observer.Expect('20260115120000 plain var', 'same as var');
        Observer.Expect('20260115120000 plain local', 'same as var');
        Observer.Expect('20260115120000 plain byval', 'same as var');
        Observer.Expect('20260115120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('202601151200 var', 'error Evaluate:Conversion | The value "202601151200" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('202601151200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('202601151200 local', 'same as var');
        Observer.Expect('202601151200 byval', 'same as var');
        Observer.Expect('202601151200 named', 'same as var');
        Observer.Expect('202601151200 plain var', 'same as var');
        Observer.Expect('202601151200 plain local', 'same as var');
        Observer.Expect('202601151200 plain byval', 'same as var');
        Observer.Expect('202601151200 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('120000 var', 'error Evaluate:Conversion | The value "120000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('120000 local', 'same as var');
        Observer.Expect('120000 byval', 'same as var');
        Observer.Expect('120000 named', 'same as var');
        Observer.Expect('120000 plain var', 'same as var');
        Observer.Expect('120000 plain local', 'same as var');
        Observer.Expect('120000 plain byval', 'same as var');
        Observer.Expect('120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1200 var', 'error Evaluate:Conversion | The value "1200" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('1200 local', 'same as var');
        Observer.Expect('1200 byval', 'same as var');
        Observer.Expect('1200 named', 'same as var');
        Observer.Expect('1200 plain var', 'same as var');
        Observer.Expect('1200 plain local', 'same as var');
        Observer.Expect('1200 plain byval', 'same as var');
        Observer.Expect('1200 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_DateTime_Digits2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '0115';
        Shapes(Observer, FR, '0115');
        FR.Value := '01152026';
        Shapes(Observer, FR, '01152026');
        FR.Value := '260115';
        Shapes(Observer, FR, '260115');
        FR.Value := '1';
        Shapes(Observer, FR, '1');
        FR.Value := '0';
        Shapes(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0115 var', 'error Evaluate:Conversion | The value "0115" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('0115 local', 'same as var');
        Observer.Expect('0115 byval', 'same as var');
        Observer.Expect('0115 named', 'same as var');
        Observer.Expect('0115 plain var', 'same as var');
        Observer.Expect('0115 plain local', 'same as var');
        Observer.Expect('0115 plain byval', 'same as var');
        Observer.Expect('0115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('01152026 var', 'error Evaluate:Conversion | The value "01152026" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('01152026 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('01152026 local', 'same as var');
        Observer.Expect('01152026 byval', 'same as var');
        Observer.Expect('01152026 named', 'same as var');
        Observer.Expect('01152026 plain var', 'same as var');
        Observer.Expect('01152026 plain local', 'same as var');
        Observer.Expect('01152026 plain byval', 'same as var');
        Observer.Expect('01152026 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('260115 var', 'error Evaluate:Conversion | The value "260115" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('260115 local', 'same as var');
        Observer.Expect('260115 byval', 'same as var');
        Observer.Expect('260115 named', 'same as var');
        Observer.Expect('260115 plain var', 'same as var');
        Observer.Expect('260115 plain local', 'same as var');
        Observer.Expect('260115 plain byval', 'same as var');
        Observer.Expect('260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 byval', 'same as var');
        Observer.Expect('1 named', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "0" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 byval', 'same as var');
        Observer.Expect('0 named', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_Date_Digits1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '20260115';
        ShapesDate(Observer, FR, '20260115');
        FR.Value := '20260115120000';
        ShapesDate(Observer, FR, '20260115120000');
        FR.Value := '202601151200';
        ShapesDate(Observer, FR, '202601151200');
#if BC28PLUS
        Observer.Expect('20260115 var', 'error Evaluate:Conversion | The format of the Date ''20260115'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('20260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('20260115 local', 'same as var');
        Observer.Expect('20260115 plain var', 'same as var');
        Observer.Expect('20260115 plain local', 'same as var');
        Observer.Expect('20260115 plain byval', 'same as var');
        Observer.Expect('20260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('20260115120000 var', 'error Evaluate:Conversion | The format of the Date ''20260115120000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('20260115120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('20260115120000 local', 'same as var');
        Observer.Expect('20260115120000 plain var', 'same as var');
        Observer.Expect('20260115120000 plain local', 'same as var');
        Observer.Expect('20260115120000 plain byval', 'same as var');
        Observer.Expect('20260115120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('202601151200 var', 'error Evaluate:Conversion | The format of the Date ''202601151200'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('202601151200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('202601151200 local', 'same as var');
        Observer.Expect('202601151200 plain var', 'same as var');
        Observer.Expect('202601151200 plain local', 'same as var');
        Observer.Expect('202601151200 plain byval', 'same as var');
        Observer.Expect('202601151200 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_Date_Digits2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '120000';
        ShapesDate(Observer, FR, '120000');
        FR.Value := '1200';
        ShapesDate(Observer, FR, '1200');
        FR.Value := '0115';
        ShapesDate(Observer, FR, '0115');
#if BC28PLUS
        Observer.Expect('120000 var', 'error Evaluate:Conversion | The format of the Date ''120000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('120000 local', 'same as var');
        Observer.Expect('120000 plain var', 'same as var');
        Observer.Expect('120000 plain local', 'same as var');
        Observer.Expect('120000 plain byval', 'same as var');
        Observer.Expect('120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1200 var', 'error Evaluate:Conversion | The format of the Date ''1200'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('1200 local', 'same as var');
        Observer.Expect('1200 plain var', 'same as var');
        Observer.Expect('1200 plain local', 'same as var');
        Observer.Expect('1200 plain byval', 'same as var');
        Observer.Expect('1200 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0115 var', 'error Evaluate:Conversion | The format of the Date ''0115'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('0115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('0115 local', 'same as var');
        Observer.Expect('0115 plain var', 'same as var');
        Observer.Expect('0115 plain local', 'same as var');
        Observer.Expect('0115 plain byval', 'same as var');
        Observer.Expect('0115 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_Date_Digits3()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '01152026';
        ShapesDate(Observer, FR, '01152026');
        FR.Value := '260115';
        ShapesDate(Observer, FR, '260115');
        FR.Value := '1';
        ShapesDate(Observer, FR, '1');
#if BC28PLUS
        Observer.Expect('01152026 var', 'error Evaluate:Conversion | The format of the Date ''01152026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('01152026 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('01152026 local', 'same as var');
        Observer.Expect('01152026 plain var', 'same as var');
        Observer.Expect('01152026 plain local', 'same as var');
        Observer.Expect('01152026 plain byval', 'same as var');
        Observer.Expect('01152026 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('260115 var', 'error Evaluate:Conversion | The format of the Date ''260115'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('260115 local', 'same as var');
        Observer.Expect('260115 plain var', 'same as var');
        Observer.Expect('260115 plain local', 'same as var');
        Observer.Expect('260115 plain byval', 'same as var');
        Observer.Expect('260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The format of the Date ''1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_Date_Digits4()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '0';
        ShapesDate(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_Time_Digits1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '20260115';
        ShapesTime(Observer, FR, '20260115');
        FR.Value := '20260115120000';
        ShapesTime(Observer, FR, '20260115120000');
        FR.Value := '202601151200';
        ShapesTime(Observer, FR, '202601151200');
        FR.Value := '120000';
        ShapesTime(Observer, FR, '120000');
        FR.Value := '1200';
        ShapesTime(Observer, FR, '1200');
#if BC28PLUS
        Observer.Expect('20260115 var', 'error Evaluate:Conversion | The value "20260115" can''t be evaluated into type Time.');
#else
        Observer.Expect('20260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('20260115 local', 'same as var');
        Observer.Expect('20260115 plain var', 'same as var');
        Observer.Expect('20260115 plain local', 'same as var');
        Observer.Expect('20260115 plain byval', 'same as var');
        Observer.Expect('20260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('20260115120000 var', 'error Evaluate:Conversion | The value "20260115120000" can''t be evaluated into type Time.');
#else
        Observer.Expect('20260115120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('20260115120000 local', 'same as var');
        Observer.Expect('20260115120000 plain var', 'same as var');
        Observer.Expect('20260115120000 plain local', 'same as var');
        Observer.Expect('20260115120000 plain byval', 'same as var');
        Observer.Expect('20260115120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('202601151200 var', 'error Evaluate:Conversion | The value "202601151200" can''t be evaluated into type Time.');
#else
        Observer.Expect('202601151200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('202601151200 local', 'same as var');
        Observer.Expect('202601151200 plain var', 'same as var');
        Observer.Expect('202601151200 plain local', 'same as var');
        Observer.Expect('202601151200 plain byval', 'same as var');
        Observer.Expect('202601151200 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('120000 var', 'error Evaluate:Conversion | The value "120000" can''t be evaluated into type Time.');
#else
        Observer.Expect('120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('120000 local', 'same as var');
        Observer.Expect('120000 plain var', 'same as var');
        Observer.Expect('120000 plain local', 'same as var');
        Observer.Expect('120000 plain byval', 'same as var');
        Observer.Expect('120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1200 var', 'error Evaluate:Conversion | The value "1200" can''t be evaluated into type Time.');
#else
        Observer.Expect('1200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('1200 local', 'same as var');
        Observer.Expect('1200 plain var', 'same as var');
        Observer.Expect('1200 plain local', 'same as var');
        Observer.Expect('1200 plain byval', 'same as var');
        Observer.Expect('1200 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_To_Time_Digits2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TextF));
        FR.Value := '0115';
        ShapesTime(Observer, FR, '0115');
        FR.Value := '01152026';
        ShapesTime(Observer, FR, '01152026');
        FR.Value := '260115';
        ShapesTime(Observer, FR, '260115');
        FR.Value := '1';
        ShapesTime(Observer, FR, '1');
        FR.Value := '0';
        ShapesTime(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0115 var', 'error Evaluate:Conversion | The value "0115" can''t be evaluated into type Time.');
#else
        Observer.Expect('0115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('0115 local', 'same as var');
        Observer.Expect('0115 plain var', 'same as var');
        Observer.Expect('0115 plain local', 'same as var');
        Observer.Expect('0115 plain byval', 'same as var');
        Observer.Expect('0115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('01152026 var', 'error Evaluate:Conversion | The value "01152026" can''t be evaluated into type Time.');
#else
        Observer.Expect('01152026 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('01152026 local', 'same as var');
        Observer.Expect('01152026 plain var', 'same as var');
        Observer.Expect('01152026 plain local', 'same as var');
        Observer.Expect('01152026 plain byval', 'same as var');
        Observer.Expect('01152026 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('260115 var', 'error Evaluate:Conversion | The value "260115" can''t be evaluated into type Time.');
#else
        Observer.Expect('260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('260115 local', 'same as var');
        Observer.Expect('260115 plain var', 'same as var');
        Observer.Expect('260115 plain local', 'same as var');
        Observer.Expect('260115 plain byval', 'same as var');
        Observer.Expect('260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type Time.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "0" can''t be evaluated into type Time.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_Date_Digits1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '20260115';
        ShapesDate(Observer, FR, '20260115');
        FR.Value := '20260115120000';
        ShapesDate(Observer, FR, '20260115120000');
        FR.Value := '202601151200';
        ShapesDate(Observer, FR, '202601151200');
#if BC28PLUS
        Observer.Expect('20260115 var', 'error Evaluate:Conversion | The format of the Date ''20260115'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('20260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('20260115 local', 'same as var');
        Observer.Expect('20260115 plain var', 'same as var');
        Observer.Expect('20260115 plain local', 'same as var');
        Observer.Expect('20260115 plain byval', 'same as var');
        Observer.Expect('20260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('20260115120000 var', 'error Evaluate:Conversion | The format of the Date ''20260115120000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('20260115120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('20260115120000 local', 'same as var');
        Observer.Expect('20260115120000 plain var', 'same as var');
        Observer.Expect('20260115120000 plain local', 'same as var');
        Observer.Expect('20260115120000 plain byval', 'same as var');
        Observer.Expect('20260115120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('202601151200 var', 'error Evaluate:Conversion | The format of the Date ''202601151200'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('202601151200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('202601151200 local', 'same as var');
        Observer.Expect('202601151200 plain var', 'same as var');
        Observer.Expect('202601151200 plain local', 'same as var');
        Observer.Expect('202601151200 plain byval', 'same as var');
        Observer.Expect('202601151200 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_Date_Digits2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '120000';
        ShapesDate(Observer, FR, '120000');
        FR.Value := '1200';
        ShapesDate(Observer, FR, '1200');
        FR.Value := '0115';
        ShapesDate(Observer, FR, '0115');
#if BC28PLUS
        Observer.Expect('120000 var', 'error Evaluate:Conversion | The format of the Date ''120000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('120000 local', 'same as var');
        Observer.Expect('120000 plain var', 'same as var');
        Observer.Expect('120000 plain local', 'same as var');
        Observer.Expect('120000 plain byval', 'same as var');
        Observer.Expect('120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1200 var', 'error Evaluate:Conversion | The format of the Date ''1200'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('1200 local', 'same as var');
        Observer.Expect('1200 plain var', 'same as var');
        Observer.Expect('1200 plain local', 'same as var');
        Observer.Expect('1200 plain byval', 'same as var');
        Observer.Expect('1200 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0115 var', 'error Evaluate:Conversion | The format of the Date ''0115'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('0115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('0115 local', 'same as var');
        Observer.Expect('0115 plain var', 'same as var');
        Observer.Expect('0115 plain local', 'same as var');
        Observer.Expect('0115 plain byval', 'same as var');
        Observer.Expect('0115 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_Date_Digits3()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '01152026';
        ShapesDate(Observer, FR, '01152026');
        FR.Value := '260115';
        ShapesDate(Observer, FR, '260115');
        FR.Value := '1';
        ShapesDate(Observer, FR, '1');
#if BC28PLUS
        Observer.Expect('01152026 var', 'error Evaluate:Conversion | The format of the Date ''01152026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('01152026 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('01152026 local', 'same as var');
        Observer.Expect('01152026 plain var', 'same as var');
        Observer.Expect('01152026 plain local', 'same as var');
        Observer.Expect('01152026 plain byval', 'same as var');
        Observer.Expect('01152026 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('260115 var', 'error Evaluate:Conversion | The format of the Date ''260115'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('260115 local', 'same as var');
        Observer.Expect('260115 plain var', 'same as var');
        Observer.Expect('260115 plain local', 'same as var');
        Observer.Expect('260115 plain byval', 'same as var');
        Observer.Expect('260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The format of the Date ''1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_Date_Digits4()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '0';
        ShapesDate(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_Time_Digits1()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '20260115';
        ShapesTime(Observer, FR, '20260115');
        FR.Value := '20260115120000';
        ShapesTime(Observer, FR, '20260115120000');
        FR.Value := '202601151200';
        ShapesTime(Observer, FR, '202601151200');
        FR.Value := '120000';
        ShapesTime(Observer, FR, '120000');
        FR.Value := '1200';
        ShapesTime(Observer, FR, '1200');
#if BC28PLUS
        Observer.Expect('20260115 var', 'error Evaluate:Conversion | The value "20260115" can''t be evaluated into type Time.');
#else
        Observer.Expect('20260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('20260115 local', 'same as var');
        Observer.Expect('20260115 plain var', 'same as var');
        Observer.Expect('20260115 plain local', 'same as var');
        Observer.Expect('20260115 plain byval', 'same as var');
        Observer.Expect('20260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('20260115120000 var', 'error Evaluate:Conversion | The value "20260115120000" can''t be evaluated into type Time.');
#else
        Observer.Expect('20260115120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('20260115120000 local', 'same as var');
        Observer.Expect('20260115120000 plain var', 'same as var');
        Observer.Expect('20260115120000 plain local', 'same as var');
        Observer.Expect('20260115120000 plain byval', 'same as var');
        Observer.Expect('20260115120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('202601151200 var', 'error Evaluate:Conversion | The value "202601151200" can''t be evaluated into type Time.');
#else
        Observer.Expect('202601151200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('202601151200 local', 'same as var');
        Observer.Expect('202601151200 plain var', 'same as var');
        Observer.Expect('202601151200 plain local', 'same as var');
        Observer.Expect('202601151200 plain byval', 'same as var');
        Observer.Expect('202601151200 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('120000 var', 'error Evaluate:Conversion | The value "120000" can''t be evaluated into type Time.');
#else
        Observer.Expect('120000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('120000 local', 'same as var');
        Observer.Expect('120000 plain var', 'same as var');
        Observer.Expect('120000 plain local', 'same as var');
        Observer.Expect('120000 plain byval', 'same as var');
        Observer.Expect('120000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1200 var', 'error Evaluate:Conversion | The value "1200" can''t be evaluated into type Time.');
#else
        Observer.Expect('1200 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('1200 local', 'same as var');
        Observer.Expect('1200 plain var', 'same as var');
        Observer.Expect('1200 plain local', 'same as var');
        Observer.Expect('1200 plain byval', 'same as var');
        Observer.Expect('1200 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_To_Time_Digits2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(CodeF));
        FR.Value := '0115';
        ShapesTime(Observer, FR, '0115');
        FR.Value := '01152026';
        ShapesTime(Observer, FR, '01152026');
        FR.Value := '260115';
        ShapesTime(Observer, FR, '260115');
        FR.Value := '1';
        ShapesTime(Observer, FR, '1');
        FR.Value := '0';
        ShapesTime(Observer, FR, '0');
#if BC28PLUS
        Observer.Expect('0115 var', 'error Evaluate:Conversion | The value "0115" can''t be evaluated into type Time.');
#else
        Observer.Expect('0115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('0115 local', 'same as var');
        Observer.Expect('0115 plain var', 'same as var');
        Observer.Expect('0115 plain local', 'same as var');
        Observer.Expect('0115 plain byval', 'same as var');
        Observer.Expect('0115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('01152026 var', 'error Evaluate:Conversion | The value "01152026" can''t be evaluated into type Time.');
#else
        Observer.Expect('01152026 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('01152026 local', 'same as var');
        Observer.Expect('01152026 plain var', 'same as var');
        Observer.Expect('01152026 plain local', 'same as var');
        Observer.Expect('01152026 plain byval', 'same as var');
        Observer.Expect('01152026 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('260115 var', 'error Evaluate:Conversion | The value "260115" can''t be evaluated into type Time.');
#else
        Observer.Expect('260115 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('260115 local', 'same as var');
        Observer.Expect('260115 plain var', 'same as var');
        Observer.Expect('260115 plain local', 'same as var');
        Observer.Expect('260115 plain byval', 'same as var');
        Observer.Expect('260115 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type Time.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "0" can''t be evaluated into type Time.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
        Observer.Verify();
    end;

    local procedure Shapes(var Observer: Codeunit "Probe Observer"; var FR: FieldRef; Label: Text)
    var
        Base: Text;
        Other: Text;
        Ok: Boolean;
    begin
        Other := '';
        Ok := TryVarParam(FR, Other);
        Base := Outcome(Ok, Other);
        Observer.Observe(Label + ' var', Base);
        Other := '';
        Ok := TryLocal(FR, Other);
        Report(Observer, Label + ' local', Base, Outcome(Ok, Other));
        Other := '';
        Ok := TryByValue(FR, Other);
        Report(Observer, Label + ' byval', Base, Outcome(Ok, Other));
        Other := '';
        Ok := TryNamedReturn(FR, Other);
        Report(Observer, Label + ' named', Base, Outcome(Ok, Other));
        Report(Observer, Label + ' plain var', Base, PlainVar(FR));
        Report(Observer, Label + ' plain local', Base, PlainLocal(FR));
        Report(Observer, Label + ' plain byval', Base, PlainByValue(FR));
        Report(Observer, Label + ' plain named', Base, PlainNamed(FR));
    end;

    local procedure Outcome(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok ' + Res);
        exit('error ' + GetLastErrorCode() + ' | ' + GetLastErrorText());
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Label: Text; Base: Text; Got: Text)
    begin
        if Got = Base then
            Observer.Observe(Label, 'same as var')
        else
            Observer.Observe(Label, Got);
    end;

    [TryFunction]
    local procedure TryVarParam(var FR: FieldRef; var Res: Text)
    var
        P: DateTime;
    begin
        FillVar(FR, P);
        Res := Format(P, 0, 9);
    end;

    local procedure FillVar(var FR: FieldRef; var R: DateTime)
    begin
        R := FR.Value;
    end;

    [TryFunction]
    local procedure TryLocal(var FR: FieldRef; var Res: Text)
    var
        L: DateTime;
    begin
        L := FR.Value;
        Res := Format(L, 0, 9);
    end;

    [TryFunction]
    local procedure TryByValue(var FR: FieldRef; var Res: Text)
    begin
        Res := FillByValue(FR, 0DT);
    end;

    local procedure FillByValue(var FR: FieldRef; R: DateTime): Text
    begin
        R := FR.Value;
        exit(Format(R, 0, 9));
    end;

    [TryFunction]
    local procedure TryNamedReturn(var FR: FieldRef; var Res: Text)
    begin
        Res := Format(NamedReturn(FR), 0, 9);
    end;

    local procedure NamedReturn(var FR: FieldRef) R: DateTime
    begin
        R := FR.Value;
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

    local procedure PlainVar(var FR: FieldRef): Text
    var
        P: DateTime;
    begin
        asserterror FillVar(FR, P);
        exit(Outcome(false, ''));
    end;

    local procedure PlainLocal(var FR: FieldRef): Text
    begin
        asserterror PlainLocalBody(FR);
        exit(Outcome(false, ''));
    end;

    local procedure PlainLocalBody(var FR: FieldRef)
    var
        L: DateTime;
    begin
        L := FR.Value;
    end;

    local procedure PlainByValue(var FR: FieldRef): Text
    begin
        asserterror FillByValue(FR, 0DT);
        exit(Outcome(false, ''));
    end;

    local procedure PlainNamed(var FR: FieldRef): Text
    begin
        asserterror NamedReturn(FR);
        exit(Outcome(false, ''));
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
}
