//sub:filterpage
// FilterPageBuilder (md:224): default PageCaption, Format, error texts, copy of the record filters, unused results and RunModal with a FilterPageHandler.

codeunit 67763 "W3 FilterPage Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;
        HandlerAnswer: Boolean;

    [TryFunction]
    local procedure TryAddFieldUnknown(var FPB: FilterPageBuilder)
    var
        Row: Record "W3 Row";
    begin
        FPB.AddField('nope', Row.Id);
    end;

    [TryFunction]
    local procedure TrySetViewEmpty(var FPB: FilterPageBuilder)
    begin
        FPB.SetView('Rows', '');
    end;

    [TryFunction]
    local procedure TryAddTableTwice(var FPB: FilterPageBuilder)
    begin
        FPB.AddTable('Rows', Database::"W3 Child");
    end;

    [TryFunction]
    local procedure TrySetViewUnknown(var FPB: FilterPageBuilder)
    begin
        FPB.SetView('nope', 'SORTING(Id) WHERE(Id=1(1))');
    end;

    [Test]
    procedure PageCaption_DefaultOfAFreshBuilder()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
    begin
        Observer.Observe('PageCaption', FPB.PageCaption());
        Observer.Observe('is empty', Format(FPB.PageCaption() = ''));
        Observer.Observe('Format', Format(FPB));
        Observer.Observe('Count', Format(FPB.Count()));
        Observer.Expect('PageCaption', 'Filter Page');
        Observer.Expect('is empty', 'No');
        Observer.Expect('Format', '');
        Observer.Expect('Count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Errors_SameNameForASecondTable()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Ok: Boolean;
    begin
        FPB.AddTable('Rows', Database::"W3 Row");
        Ok := TryAddTableTwice(FPB);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('Count', Format(FPB.Count()));
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'A table that has the name Rows already exists with a different ID.');
        Observer.Expect('error|code', 'Argument');
        Observer.Expect('Count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Errors_SetViewOnUnknownControl()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Ok: Boolean;
    begin
        FPB.AddTable('Rows', Database::"W3 Row");
        Ok := TrySetViewUnknown(FPB);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Filter control nope is not defined in the FilterPageBuilder variable.');
        Observer.Expect('error|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure UnusedResult_AddFieldOnUnknownControl()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Ok: Boolean;
    begin
        FPB.AddTable('Rows', Database::"W3 Row");
        Ok := TryAddFieldUnknown(FPB);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Filter control nope is not defined in the FilterPageBuilder variable.');
        Observer.Expect('error|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure UnusedResult_SetViewWithAnEmptyView()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Ok: Boolean;
    begin
        FPB.AddTable('Rows', Database::"W3 Row");
        Ok := TrySetViewEmpty(FPB);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'The filter page view cannot be empty.');
        Observer.Expect('error|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure AddRecord_CopiesTheFiltersOfTheRecord()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Row: Record "W3 Row";
        RecRef: RecordRef;
    begin
        Row.SetFilter(Id, '1..3');
        FPB.AddRecord('Rec', Row);
        Row.SetFilter(Id, '5');
        Observer.Observe('record view after change', Row.GetView());
        Observer.Observe('builder view after record change', FPB.GetView('Rec'));
        FPB.SetView('Rec', 'SORTING(Id) WHERE(Id=1(7))');
        Observer.Observe('record filter after SetView', Row.GetFilter(Id));
        Observer.Observe('builder view after SetView', FPB.GetView('Rec'));
        Row.Reset();
        Row.SetFilter(Id, '2');
        RecRef.GetTable(Row);
        FPB.AddRecordRef('Ref', RecRef);
        RecRef.Reset();
        RecRef.Field(1).SetFilter('9');
        Observer.Observe('RecordRef view after change', RecRef.GetView());
        Observer.Observe('builder view of the RecordRef copy', FPB.GetView('Ref'));
        Observer.Expect('record view after change', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(5))');
        Observer.Expect('builder view after record change', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1..3))');
        Observer.Expect('record filter after SetView', '5');
        Observer.Expect('builder view after SetView', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(7))');
        Observer.Expect('RecordRef view after change', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(9))');
        Observer.Expect('builder view of the RecordRef copy', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(9))');
        Observer.Verify();
    end;

    [FilterPageHandler]
    procedure ConfirmHandler(var Rows: RecordRef): Boolean
    begin
        HandlerLog += 'handler table=' + Format(Rows.Number() = Database::"W3 Row") + ' view=[' + Rows.GetView() + ']';
        Rows.Field(1).SetFilter('4..6');
        exit(HandlerAnswer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RunModal_WithAFilterPageHandler_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Row: Record "W3 Row";
        Answer: Boolean;
    begin
        HandlerLog := '';
        HandlerAnswer := true;
        Row.SetFilter(Id, '1..3');
        FPB.AddRecord('Rows', Row);
        FPB.AddField('Rows', Row.Id);
        Answer := FPB.RunModal();
        Observer.Observe('RunModal', Format(Answer));
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('builder view', FPB.GetView('Rows'));
        Observer.Observe('record filter', Row.GetFilter(Id));
        Observer.Expect('RunModal', 'Yes');
        Observer.Expect('handler', 'handler table=Yes view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(1..3))]');
        Observer.Expect('builder view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(4..6))');
        Observer.Expect('record filter', '1..3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RunModal_WithAFilterPageHandler_Cancelled()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Row: Record "W3 Row";
        Answer: Boolean;
    begin
        HandlerLog := '';
        HandlerAnswer := false;
        Row.SetFilter(Id, '1..3');
        FPB.AddRecord('Rows', Row);
        FPB.AddField('Rows', Row.Id);
        Answer := FPB.RunModal();
        Observer.Observe('RunModal', Format(Answer));
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('builder view', FPB.GetView('Rows'));
        Observer.Expect('RunModal', 'No');
        Observer.Expect('handler', 'handler table=Yes view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(1..3))]');
        Observer.Expect('builder view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(4..6))');
        Observer.Verify();
    end;
}
