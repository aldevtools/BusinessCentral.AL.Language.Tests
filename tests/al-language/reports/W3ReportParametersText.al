//sub:report
// The text Report.RunRequestPage returns and the text it takes back (md:218, md:219), and the data item of a TestRequestPage (md:221, md:17 ShowFilter).

enum 67736 "W3 Params Enum"
{
    Extensible = true;

    value(0; Zero) { }
    value(5; Five) { }
    value(9; Nine) { }
}

codeunit 67737 "W3 Params Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 67738 "W3 Params Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            DataItemTableView = sorting(Name) order(descending);
            RequestFilterFields = Id, Name, Amount, Flag;
        }
        dataitem(Child; "W3 Child")
        {
            DataItemTableView = sorting(ParentId, Id);
            RequestFilterFields = ParentId;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal) { ApplicationArea = All; }
                field(DecCtl; DecVal) { ApplicationArea = All; }
                field(TxtCtl; TxtVal) { ApplicationArea = All; }
                field(CodeCtl; CodeVal) { ApplicationArea = All; }
                field(BoolCtl; BoolVal) { ApplicationArea = All; }
                field(DateCtl; DateVal) { ApplicationArea = All; }
                field(TimeCtl; TimeVal) { ApplicationArea = All; }
                field(DtCtl; DtVal) { ApplicationArea = All; }
                field(OptCtl; OptVal) { ApplicationArea = All; }
                field(EnumCtl; EnumVal) { ApplicationArea = All; }
                field(BigCtl; BigVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            L.Add('RP OnInit ' + Values());
        end;

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage ' + Values());
        end;
    }

    var
        IntVal: Integer;
        DecVal: Decimal;
        TxtVal: Text[30];
        CodeVal: Code[10];
        BoolVal: Boolean;
        DateVal: Date;
        TimeVal: Time;
        DtVal: DateTime;
        OptVal: Option Alpha,Beta,Gamma;
        EnumVal: Enum "W3 Params Enum";
        BigVal: BigInteger;
        L: Codeunit "W3 Params Log";

    local procedure Values(): Text
    begin
        exit('int=' + Format(IntVal) + ' dec=' + Format(DecVal) + ' txt=[' + TxtVal + '] code=[' + CodeVal + '] bool=' + Format(BoolVal) + ' opt=' + Format(OptVal) +
            ' enum=' + Format(EnumVal) + ' big=' + Format(BigVal));
    end;

    trigger OnPreReport()
    begin
        L.Add('PreReport ' + Values());
    end;
}

// A request page with ShowFilter = false.
report 67739 "W3 NoFilter Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('Row pre filter=[' + Row.GetFilter(Id) + ']');
            end;
        }
    }

    requestpage
    {
        ShowFilter = false;

        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal) { ApplicationArea = All; }
            }
        }
    }

    var
        IntVal: Integer;
        L: Codeunit "W3 Params Log";
}

codeunit 67740 "W3 Params Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 Params Log";
        Dataset: Codeunit "W3 Dataset";
        Runner: Codeunit "W3 Runner";
        FirstRun: Boolean;

    local procedure Seed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        L.Take();
    end;

    local procedure Handwritten(Options: Text; Items: Text): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 Params Rpt" id="' + Format(Report::"W3 Params Rpt") + '"><Options>' + Options +
            '</Options><DataItems>' + Items + '</DataItems></ReportParameters>');
    end;

    [TryFunction]
    local procedure TryRowSetFilter(var RP: TestRequestPage "W3 NoFilter Rpt")
    begin
        RP.Row.SetFilter(Id, '1..2');
    end;

    [TryFunction]
    local procedure TryRowGetFilter(var RP: TestRequestPage "W3 NoFilter Rpt"; var Answer: Text)
    begin
        Answer := RP.Row.GetFilter(Id);
    end;

    [TryFunction]
    local procedure TryAscending(var RP: TestRequestPage "W3 Params Rpt"; var Answer: Boolean)
    begin
        Answer := RP.Row.Ascending();
    end;

    [TryFunction]
    local procedure TrySetAscending(var RP: TestRequestPage "W3 Params Rpt")
    begin
        RP.Row.Ascending(true);
    end;

    [TryFunction]
    local procedure TryCurrentKey(var RP: TestRequestPage "W3 Params Rpt"; var Answer: Text)
    begin
        Answer := RP.Row.CurrentKey();
    end;

    [TryFunction]
    local procedure TrySetCurrentKey(var RP: TestRequestPage "W3 Params Rpt")
    begin
        RP.Row.SetCurrentKey(Name);
    end;

    // md:218: the start of the text and the id.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RunRequestPage_TextShape_HeaderAndEnd()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        IdText: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Params Rpt");
        IdText := Dataset.Between(Parameters, ' id="', '"');
        Observer.Observe('start', CopyStr(Parameters, 1, Parameters.IndexOf(' id="') - 1));
        Observer.Observe('id is the report id', Format(IdText = Format(Report::"W3 Params Rpt")));
        Observer.Observe('end', CopyStr(Parameters, StrLen(Parameters) - 40));
        Observer.Observe('has Options', Format(Parameters.Contains('<Options>')));
        Observer.Observe('has DataItems', Format(Parameters.Contains('<DataItems>')));
        Observer.Observe('has CR or LF', Format(Parameters.Contains(Dataset.Lf())));
        Observer.Expect('start', '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 Params Rpt"');
        Observer.Expect('id is the report id', 'Yes');
        Observer.Expect('end', '/DataItem></DataItems></ReportParameters>');
        Observer.Expect('has Options', 'Yes');
        Observer.Expect('has DataItems', 'Yes');
        Observer.Expect('has CR or LF', 'No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        RP.OK().Invoke();
    end;

    // md:218: the default values of every control type, and the default view of both items.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RunRequestPage_Defaults_OptionsAndDataItems()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Params Rpt");
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('options', '<Field name="IntVal">0</Field><Field name="DecVal">0</Field><Field name="TxtVal" /><Field name="CodeVal" /><Field name="BoolVal">false</Field><Field name="DateVal" /><Field name="TimeVal" /><Field name="DtVal" /><Field name="OptVal">0</Field><Field name="EnumVal">0</Field><Field name="BigVal">0</Field>');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1) ORDER(1)</DataItem><DataItem name="Child">VERSION(1) SORTING(Field2,Field1)</DataItem>');
        Observer.Verify();
    end;

    // md:218: a value in every control type.
    [Test]
    [HandlerFunctions('SetAllHandler')]
    procedure RunRequestPage_Values_OptionsOfEveryType()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Params Rpt");
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('PreReport', L.Take());
        Observer.Expect('options', '<Field name="IntVal">12</Field><Field name="DecVal">3.5</Field><Field name="TxtVal">a&lt;b&amp;"c"</Field><Field name="CodeVal">X1</Field><Field name="BoolVal">true</Field><Field name="DateVal">2024-03-05</Field><Field name="TimeVal">09:15:30</Field><Field name="DtVal">2024-03-05T09:15:00Z</Field><Field name="OptVal">1</Field><Field name="EnumVal">5</Field><Field name="BigVal">5000000000</Field>');
        Observer.Expect('PreReport', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetAllHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        RP.IntCtl.SetValue(12);
        RP.DecCtl.SetValue(3.5);
        RP.TxtCtl.SetValue('a<b&"c"');
        RP.CodeCtl.SetValue('x1');
        RP.BoolCtl.SetValue(true);
        RP.DateCtl.SetValue(DMY2Date(5, 3, 2024));
        RP.TimeCtl.SetValue(091530T);
        RP.DtCtl.SetValue(CreateDateTime(DMY2Date(5, 3, 2024), 091530T));
        RP.OptCtl.SetValue('Beta');
        RP.EnumCtl.SetValue('Five');
        RP.BigCtl.SetValue(5000000000L);
        RP.OK().Invoke();
    end;

    // md:218: filter forms of the data items: range, list, comparison, not equal, wildcard text, boolean, a second item, sorting and order.
    [Test]
    [HandlerFunctions('FilterAllHandler')]
    procedure RunRequestPage_FilterForms_DataItems()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Params Rpt");
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('handler', L.Take());
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1) ORDER(1) WHERE(Field1=1(1..3|5),Field2=1(@a*),Field3=1(&gt;10),Field4=1(1))</DataItem><DataItem name="Child">VERSION(1) SORTING(Field2,Field1) WHERE(Field2=1(&lt;&gt;2))</DataItem>');
        Observer.Expect('handler', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;id=[1..3|5] name=[@a*] amount=[>10] flag=[Yes] parent=[<>2];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FilterAllHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        RP.Row.SetFilter(Id, '1..3|5');
        RP.Row.SetFilter(Name, '@a*');
        RP.Row.SetFilter(Amount, '>10');
        RP.Row.SetFilter(Flag, 'Yes');
        RP.Child.SetFilter(ParentId, '<>2');
        L.Add('id=[' + RP.Row.GetFilter(Id) + '] name=[' + RP.Row.GetFilter(Name) + '] amount=[' + RP.Row.GetFilter(Amount) + '] flag=[' + RP.Row.GetFilter(Flag) + '] parent=[' + RP.Child.GetFilter(ParentId) + ']');
        RP.OK().Invoke();
    end;

    // md:219: the text of a first run seeds a second one: option values and views are in place before OnInit?
    [Test]
    [HandlerFunctions('SeedFlowHandler')]
    procedure RunRequestPage_SeededWithItsOwnText_ValuesBeforeOnInit()
    var
        Observer: Codeunit "Probe Observer";
        First: Text;
        Second: Text;
    begin
        Seed();
        FirstRun := true;
        First := Report.RunRequestPage(Report::"W3 Params Rpt");
        L.Take();
        FirstRun := false;
        Second := Report.RunRequestPage(Report::"W3 Params Rpt", First);
        Observer.Observe('log', L.Take());
        Observer.Observe('same text', Format(First = Second));
        Observer.Expect('log', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=12 dec=3.5 txt=[abc] code=[] bool=Yes opt=Beta enum=Five big=0;handler int=12 dec=3.50 txt=abc bool=Yes opt=Beta enum=Five view id=[1..3|5];');
        Observer.Expect('same text', 'Yes');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SeedFlowHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        if FirstRun then begin
            RP.IntCtl.SetValue(12);
            RP.DecCtl.SetValue(3.5);
            RP.TxtCtl.SetValue('abc');
            RP.BoolCtl.SetValue(true);
            RP.OptCtl.SetValue('Beta');
            RP.EnumCtl.SetValue('Five');
            RP.Row.SetFilter(Id, '1..3|5');
            RP.OK().Invoke();
        end else
            SeededHandler(RP);
    end;

    local procedure SeededHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        L.Add('handler int=' + RP.IntCtl.Value() + ' dec=' + RP.DecCtl.Value() + ' txt=' + RP.TxtCtl.Value() + ' bool=' + RP.BoolCtl.Value() + ' opt=' + RP.OptCtl.Value() + ' enum=' + RP.EnumCtl.Value() +
            ' view id=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    // md:219: a control name the page does not have, a data item the report does not have, and another report's text.
    [Test]
    [HandlerFunctions('SeedFlowHandler')]
    procedure RunRequestPage_SeededWithUnknownControl()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Params Rpt", 3, Handwritten('<Field name="GoneCtl">5</Field><Field name="IntCtl">7</Field>', ''), Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;handler int=0 dec=0.00 txt= bool=No opt=Alpha enum=Zero view id=[];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SeedFlowHandler')]
    procedure RunRequestPage_SeededWithUnknownDataItem()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Params Rpt", 3, Handwritten('', '<DataItem name="Gone">WHERE(Field1=1(2))</DataItem>'), Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;handler int=0 dec=0.00 txt= bool=No opt=Alpha enum=Zero view id=[];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SeedFlowHandler')]
    procedure RunRequestPage_SeededWithABadValue()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Params Rpt", 3, Handwritten('<Field name="IntCtl">notanumber</Field>', ''), Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;handler int=0 dec=0.00 txt= bool=No opt=Alpha enum=Zero view id=[];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SeedFlowHandler')]
    procedure RunRequestPage_SeededWithTextOfAnotherReport()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Params Rpt", 3, '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 Exec Rpt" id="' + Format(Report::"W3 Exec Rpt") +
            '"><Options><Field name="Opt">3</Field></Options><DataItems></DataItems></ReportParameters>', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;handler int=0 dec=0.00 txt= bool=No opt=Alpha enum=Zero view id=[];');
        Observer.Verify();
    end;

    // md:221: the methods of the data item of a TestRequestPage besides SetFilter and GetFilter.
    [Test]
    [HandlerFunctions('FilterMethodsHandler')]
    procedure TestFilter_AscendingAndKeyMethods()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Params Rpt");
        Observer.Observe('handler', L.Take());
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('handler', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;Ascending() = No;Ascending(true) ok;CurrentKey() = Name,Id;SetCurrentKey(Name) ok;');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1)</DataItem><DataItem name="Child">VERSION(1) SORTING(Field2,Field1)</DataItem>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FilterMethodsHandler(var RP: TestRequestPage "W3 Params Rpt")
    var
        AnswerBool: Boolean;
        AnswerText: Text;
    begin
        if TryAscending(RP, AnswerBool) then
            L.Add('Ascending() = ' + Format(AnswerBool))
        else
            L.Add('Ascending() error=' + GetLastErrorText());
        if TrySetAscending(RP) then
            L.Add('Ascending(true) ok')
        else
            L.Add('Ascending(true) error=' + GetLastErrorText());
        if TryCurrentKey(RP, AnswerText) then
            L.Add('CurrentKey() = ' + AnswerText)
        else
            L.Add('CurrentKey() error=' + GetLastErrorText());
        if TrySetCurrentKey(RP) then
            L.Add('SetCurrentKey(Name) ok')
        else
            L.Add('SetCurrentKey(Name) error=' + GetLastErrorText());
        RP.OK().Invoke();
    end;

    // md:221: SetFilter / GetFilter round trip, a cleared filter, a bad expression and a second SetFilter on the same field.
    [Test]
    [HandlerFunctions('FilterRoundTripHandler')]
    procedure TestFilter_SetFilterGetFilter_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Params Rpt");
        Observer.Observe('handler', L.Take());
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('handler', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;empty=[];set=[1..3];second=[1..3];cleared=[];name=[abc];');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1) ORDER(1) WHERE(Field2=1(abc))</DataItem><DataItem name="Child">VERSION(1) SORTING(Field2,Field1)</DataItem>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FilterRoundTripHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        L.Add('empty=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '1..3');
        L.Add('set=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '5');
        L.Add('second=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '');
        L.Add('cleared=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Name, 'abc');
        L.Add('name=[' + RP.Row.GetFilter(Name) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('BadFilterHandler')]
    procedure TestFilter_SetFilter_BadExpression()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Params Rpt", 2, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('handler', L.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'One or more filters are not valid. Check the filters and correct them as needed. The filter "abc.." is not valid for the Id field on the W3 Row table. The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('error|code', 'TestWrapped');
        Observer.Expect('handler', 'RP OnInit int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;RP OnOpenPage int=0 dec=0 txt=[] code=[] bool=No opt=Alpha enum=Zero big=0;after bad filter=[abc..];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BadFilterHandler(var RP: TestRequestPage "W3 Params Rpt")
    begin
        RP.Row.SetFilter(Id, 'abc..');
        L.Add('after bad filter=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    // md:17: ShowFilter = false. The text of RunRequestPage and what the handler can touch.
    [Test]
    [HandlerFunctions('NoFilterPlainHandler')]
    procedure ShowFilterFalse_ParametersTextStillListsTheDataItem()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 NoFilter Rpt");
        Observer.Observe('options', Dataset.Between(Parameters, '<Options>', '</Options>'));
        Observer.Observe('has DataItems', Format(Parameters.Contains('<DataItems>')));
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('options', '<Field name="IntVal">4</Field>');
        Observer.Expect('has DataItems', 'Yes');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NoFilterPlainHandler(var RP: TestRequestPage "W3 NoFilter Rpt")
    begin
        RP.IntCtl.SetValue(4);
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NoFilterTouchHandler')]
    procedure ShowFilterFalse_HandlerTouchesTheDataItem()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 NoFilter Rpt");
        Observer.Observe('handler', L.Take());
        Observer.Observe('dataitems', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('handler', 'SetFilter ok;GetFilter ok=[1..2];');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(1..2))</DataItem>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NoFilterTouchHandler(var RP: TestRequestPage "W3 NoFilter Rpt")
    var
        Answer: Text;
    begin
        if TryRowSetFilter(RP) then
            L.Add('SetFilter ok')
        else
            L.Add('SetFilter error=' + GetLastErrorText());
        if TryRowGetFilter(RP, Answer) then
            L.Add('GetFilter ok=[' + Answer + ']')
        else
            L.Add('GetFilter error=' + GetLastErrorText());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NoFilterPlainHandler')]
    procedure ShowFilterFalse_RunWithSeededView()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Parameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="W3 NoFilter Rpt" id="' + Format(Report::"W3 NoFilter Rpt") +
            '"><Options></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(1))</DataItem></DataItems></ReportParameters>';
        Ok := Runner.Exec(Report::"W3 NoFilter Rpt", 3, Parameters, Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('dataitems', Dataset.Between(Result, '<DataItems>', '</DataItems>'));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(1))</DataItem>');
        Observer.Verify();
    end;

    // Writer PX (al-runtime-rs probes-needed "Request page" parameters text, PR 333): a Boolean filter on No, a filter in filter group 2,
    // and a key whose fields have different directions (report 86222 in PxReportParametersText.al).
    [Test]
    [HandlerFunctions('PxFlagNoHandler')]
    procedure PX_Params_BooleanFilterOnNo()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PX Params Rpt";
        Row: Record "W3 Row";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT PX Params Rpt");
        Observer.Observe('handler', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('log', L.Take());
        Row.SetRange(Flag, false);
        Rpt.SetTableView(Row);
        Parameters := Rpt.RunRequestPage();
        Observer.Observe('settableview', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Expect('handler', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field4=1(0))</DataItem>');
        Observer.Expect('log', 'flag=[No];');
        Observer.Expect('settableview', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field4=1(0))</DataItem>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxFlagNoHandler(var RP: TestRequestPage "LT PX Params Rpt")
    begin
        if RP.Row.GetFilter(Flag) = '' then
            RP.Row.SetFilter(Flag, 'No');
        L.Add('flag=[' + RP.Row.GetFilter(Flag) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PxParamsLogHandler')]
    procedure PX_Params_FilterGroupTwo()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PX Params Rpt";
        Row: Record "W3 Row";
        Parameters: Text;
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(Id, 1, 5);
        Row.FilterGroup(0);
        Rpt.SetTableView(Row);
        Parameters := Rpt.RunRequestPage();
        Observer.Observe('group2', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('group2 log', L.Take());
        Clear(Rpt);
        Row.Reset();
        Row.FilterGroup(2);
        Row.SetRange(Id, 1, 5);
        Row.FilterGroup(0);
        Row.SetRange(Flag, true);
        Rpt.SetTableView(Row);
        Parameters := Rpt.RunRequestPage();
        Observer.Observe('group2+0', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('group2+0 log', L.Take());
        Observer.Expect('group2', '<DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem>');
        Observer.Expect('group2 log', 'id=[1..5] flag=[];');
        Observer.Expect('group2+0', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field4=1(1))</DataItem>');
        Observer.Expect('group2+0 log', 'id=[1..5] flag=[1];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PxParamsLogHandler')]
    procedure PX_Params_DirectionPerKeyField()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PX Params Rpt";
        Row: Record "W3 Row";
        Parameters: Text;
    begin
        Seed();
        Row.SetCurrentKey(Name, Id);
        Row.SetAscending(Id, false);
        Rpt.SetTableView(Row);
        Parameters := Rpt.RunRequestPage();
        Observer.Observe('second desc', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Clear(Rpt);
        Row.Reset();
        Row.SetCurrentKey(Name, Id);
        Row.SetAscending(Name, false);
        Rpt.SetTableView(Row);
        Parameters := Rpt.RunRequestPage();
        Observer.Observe('first desc', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Clear(Rpt);
        Row.Reset();
        Row.SetCurrentKey(Name, Id);
        Row.Ascending(false);
        Row.SetAscending(Id, true);
        Rpt.SetTableView(Row);
        Parameters := Rpt.RunRequestPage();
        Observer.Observe('desc then second asc', Dataset.Between(Parameters, '<DataItems>', '</DataItems>'));
        Observer.Observe('log', L.Take());
        Observer.Expect('second desc', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1)</DataItem>');
        Observer.Expect('first desc', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1)</DataItem>');
        Observer.Expect('desc then second asc', '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1) ORDER(1)</DataItem>');
        Observer.Expect('log', 'id=[] flag=[];id=[] flag=[];id=[] flag=[];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxParamsLogHandler(var RP: TestRequestPage "LT PX Params Rpt")
    begin
        L.Add('id=[' + RP.Row.GetFilter(Id) + '] flag=[' + RP.Row.GetFilter(Flag) + ']');
        RP.OK().Invoke();
    end;
}
