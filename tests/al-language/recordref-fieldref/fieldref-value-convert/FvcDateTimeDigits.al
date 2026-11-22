// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value of a Text or Code field holding a digit string assigned to a DateTime, Date or Time (runner issue 8662).
//   Compact date and time forms: 8, 14, 12, 6 and 4 digits and short numbers. DateTime targets use the four shapes of FvcDateTimeShapes,
//   Date and Time targets a var parameter and a plain local.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
}
