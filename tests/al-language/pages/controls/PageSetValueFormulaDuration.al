// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72877, page 72878
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField.SetValue on a DateFormula control and a Duration control with many spellings; what the control shows afterwards or the error text and code
// BC versions: 29 (27 and 28 by CI)

table 72877 "LT SetVal Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; DF; DateFormula) { }
        field(3; Dur; Duration) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 72878 "LT SetVal Card"
{
    PageType = Card;
    SourceTable = "LT SetVal Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(DF; Rec.DF) { ApplicationArea = All; }
            field(Dur; Rec.Dur) { ApplicationArea = All; }
        }
    }
}

codeunit 72879 "LT SetVal Formula"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetDF(var TP: TestPage "LT SetVal Card"; Txt: Text)
    begin
        TP.DF.SetValue(Txt);
    end;

    [TryFunction]
    local procedure TrySetDur(var TP: TestPage "LT SetVal Card"; Txt: Text)
    begin
        TP.Dur.SetValue(Txt);
    end;

    local procedure Open(var TP: TestPage "LT SetVal Card")
    var
        Row: Record "LT SetVal Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        TP.OpenEdit();
    end;

    local procedure DF(var Observer: Codeunit "Probe Observer"; var TP: TestPage "LT SetVal Card"; Name: Text; Txt: Text)
    begin
        if TrySetDF(TP, Txt) then
            Observer.Observe(Name, 'in=[' + Txt + '] shows=[' + TP.DF.Value() + ']')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Dur(var Observer: Codeunit "Probe Observer"; var TP: TestPage "LT SetVal Card"; Name: Text; Txt: Text)
    begin
        if TrySetDur(TP, Txt) then
            Observer.Observe(Name, 'in=[' + Txt + '] shows=[' + TP.Dur.Value() + ']')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure DateFormulaControl_Spellings()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT SetVal Card";
    begin
        Open(TP);
        DF(Observer, TP, 'df01', '1D');
        DF(Observer, TP, 'df02', '<1D>');
        DF(Observer, TP, 'df03', '1d');
        DF(Observer, TP, 'df04', 'CM');
        DF(Observer, TP, 'df05', '<CM>');
        DF(Observer, TP, 'df06', '-1W');
        DF(Observer, TP, 'df07', '1D+1W');
        DF(Observer, TP, 'df08', '<1D+1W>');
        DF(Observer, TP, 'df09', '1M-1D');
        DF(Observer, TP, 'df10', '1Y2M');
        DF(Observer, TP, 'df11', '<-CM>');
        DF(Observer, TP, 'df12', 'CM+1D');
        DF(Observer, TP, 'df13', ' 1D ');
        DF(Observer, TP, 'df14', '');
        DF(Observer, TP, 'df15', '<>');
        DF(Observer, TP, 'df16', 'abc');
        DF(Observer, TP, 'df17', '1D abc');
        DF(Observer, TP, 'df18', 'D1');
        DF(Observer, TP, 'df19', '1D1W');
        DF(Observer, TP, 'df20', '1X');
        Observer.Expect('df01', 'in=[1D] shows=[1D]');
        Observer.Expect('df02', 'in=[<1D>] shows=[1D]');
        Observer.Expect('df03', 'in=[1d] shows=[1D]');
        Observer.Expect('df04', 'in=[CM] shows=[CM]');
        Observer.Expect('df05', 'in=[<CM>] shows=[CM]');
        Observer.Expect('df06', 'in=[-1W] shows=[-1W]');
        Observer.Expect('df07', 'in=[1D+1W] shows=[1D+1W]');
        Observer.Expect('df08', 'in=[<1D+1W>] shows=[1D+1W]');
        Observer.Expect('df09', 'in=[1M-1D] shows=[1M-1D]');
        Observer.Expect('df10|text', 'Validation error for Field: DF,  Message = ''Your entry of ''1Y2M'' is not an acceptable value for ''DF''. The date formula ''1Y2M'' must include plus (+) or minus (-). (Select Refresh to discard errors)''');
        Observer.Expect('df10|code', 'TestValidation');
        Observer.Expect('df11', 'in=[<-CM>] shows=[-CM]');
        Observer.Expect('df12', 'in=[CM+1D] shows=[CM+1D]');
        Observer.Expect('df13', 'in=[ 1D ] shows=[1D]');
        Observer.Expect('df14', 'in=[] shows=[]');
        Observer.Expect('df15', 'in=[<>] shows=[]');
        Observer.Expect('df16|text', 'Validation error for Field: DF,  Message = ''Your entry of ''abc'' is not an acceptable value for ''DF''. The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit. (Select Refresh to discard errors)''');
        Observer.Expect('df16|code', 'TestValidation');
        Observer.Expect('df17|text', 'Validation error for Field: DF,  Message = ''Your entry of ''1D abc'' is not an acceptable value for ''DF''. The date formula ''1D ABC'' must include plus (+) or minus (-). (Select Refresh to discard errors)''');
        Observer.Expect('df17|code', 'TestValidation');
        Observer.Expect('df18', 'in=[D1] shows=[D1]');
        Observer.Expect('df19|text', 'Validation error for Field: DF,  Message = ''Your entry of ''1D1W'' is not an acceptable value for ''DF''. The date formula ''1D1W'' must include plus (+) or minus (-). (Select Refresh to discard errors)''');
        Observer.Expect('df19|code', 'TestValidation');
        Observer.Expect('df20|text', 'Validation error for Field: DF,  Message = ''Your entry of ''1X'' is not an acceptable value for ''DF''. The date formula ''1X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit. (Select Refresh to discard errors)''');
        Observer.Expect('df20|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure DurationControl_Spellings()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT SetVal Card";
    begin
        Open(TP);
        Dur(Observer, TP, 'du01', '1 hour');
        Dur(Observer, TP, 'du02', '1 hour 2 minutes 3 seconds');
        Dur(Observer, TP, 'du03', '1 hours');
        Dur(Observer, TP, 'du04', '1h');
        Dur(Observer, TP, 'du05', '1:00');
        Dur(Observer, TP, 'du06', '3600000');
        Dur(Observer, TP, 'du07', '-1 hour');
        Dur(Observer, TP, 'du08', '1 day');
        Dur(Observer, TP, 'du09', '1 day 2 hours');
        Dur(Observer, TP, 'du10', '1.5 hours');
        Dur(Observer, TP, 'du11', '0');
        Dur(Observer, TP, 'du12', '');
        Dur(Observer, TP, 'du13', 'abc');
        Dur(Observer, TP, 'du14', '90 minutes');
        Dur(Observer, TP, 'du15', '1 second');
        Dur(Observer, TP, 'du16', '2 seconds');
        Dur(Observer, TP, 'du17', '1 minute');
        Dur(Observer, TP, 'du18', '1 millisecond');
        Dur(Observer, TP, 'du19', '500 milliseconds');
        Dur(Observer, TP, 'du20', '1 HOUR');
        Dur(Observer, TP, 'du21', '1 hour 30');
        Dur(Observer, TP, 'du22', ' 1 hour ');
        Observer.Expect('du01', 'in=[1 hour] shows=[1 hour]');
        Observer.Expect('du02', 'in=[1 hour 2 minutes 3 seconds] shows=[1 hour 2 minutes 3 seconds]');
        Observer.Expect('du03', 'in=[1 hours] shows=[1 hour]');
        Observer.Expect('du04', 'in=[1h] shows=[1 hour]');
        Observer.Expect('du05|text', 'Validation error for Field: Dur,  Message = ''Your entry of ''1:00'' is not an acceptable value for ''Dur''. The value "1:00" can''t be evaluated into type Duration. (Select Refresh to discard errors)''');
        Observer.Expect('du05|code', 'TestValidation');
        Observer.Expect('du06', 'in=[3600000] shows=[150000 days]');
        Observer.Expect('du07', 'in=[-1 hour] shows=[-1 hour]');
        Observer.Expect('du08', 'in=[1 day] shows=[1 day]');
        Observer.Expect('du09', 'in=[1 day 2 hours] shows=[1 day 2 hours]');
        Observer.Expect('du10', 'in=[1.5 hours] shows=[1 hour 30 minutes]');
        Observer.Expect('du11', 'in=[0] shows=[]');
        Observer.Expect('du12', 'in=[] shows=[]');
        Observer.Expect('du13|text', 'Validation error for Field: Dur,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Dur''. The value "abc" can''t be evaluated into type Duration. (Select Refresh to discard errors)''');
        Observer.Expect('du13|code', 'TestValidation');
        Observer.Expect('du14', 'in=[90 minutes] shows=[1 hour 30 minutes]');
        Observer.Expect('du15', 'in=[1 second] shows=[1 second]');
        Observer.Expect('du16', 'in=[2 seconds] shows=[2 seconds]');
        Observer.Expect('du17', 'in=[1 minute] shows=[1 minute]');
        Observer.Expect('du18', 'in=[1 millisecond] shows=[1 millisecond]');
        Observer.Expect('du19', 'in=[500 milliseconds] shows=[500 milliseconds]');
        Observer.Expect('du20', 'in=[1 HOUR] shows=[1 hour]');
        Observer.Expect('du21|text', 'Validation error for Field: Dur,  Message = ''Your entry of ''1 hour 30'' is not an acceptable value for ''Dur''. The value "1 hour 30" can''t be evaluated into type Duration. (Select Refresh to discard errors)''');
        Observer.Expect('du21|code', 'TestValidation');
        Observer.Expect('du22|text', 'Validation error for Field: Dur,  Message = ''Your entry of '' 1 hour '' is not an acceptable value for ''Dur''. The value "1 hour " can''t be evaluated into type Duration. (Select Refresh to discard errors)''');
        Observer.Expect('du22|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaControl_StoredAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT SetVal Card";
        Row: Record "LT SetVal Row";
    begin
        Open(TP);
        TP.DF.SetValue('1D+1W');
        TP.Dur.SetValue('1 hour 2 minutes 3 seconds');
        TP.Close();
        Row.Get(1);
        Observer.Observe('df', Format(Row.DF));
        Observer.Observe('dur', Format(Row.Dur));
        Observer.Observe('durMs', Format(Row.Dur, 0, 2));
        Observer.Expect('df', '1D+1W');
        Observer.Expect('dur', '1 hour 2 minutes 3 seconds');
        Observer.Expect('durMs', '1 2 2 5 3 7');
        Observer.Verify();
    end;
}
