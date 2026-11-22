// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value of a Decimal or Duration field assigned to a Date or Time (runner issue 8662 neighbors of FvcDateTimeShapes).
//   Two shapes per value: a var parameter and a plain declared local.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
