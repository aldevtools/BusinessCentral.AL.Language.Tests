// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-dataitem-properties
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70590 is used only by test codeunit 70598
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed row: Report | `DataItemLink` with the enclosing item filters the child by SetRange on each link field for every parent row; the filter
// stays on the child record after the loop; a filter on a link field set before or during the run; DataItemLinkReference, CalcFields, MaxIteration,
// a link naming another item.
// BC versions: 29 (27 and 28 by CI)

codeunit 70590 "LT PnH Link Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;

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

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;
}

// Two link fields; the filters of the child at its OnPreDataItem, in each row and after the loop.
report 70591 "LT PnH LinkMulti"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            dataitem(Child; "LT PnH Child")
            {
                DataItemLink = ParentId = field(Id), Grp = field(Grp);

                trigger OnPreDataItem()
                begin
                    L.Add('child pre of ' + Format(Row.Id) + ' filters=[' + Child.GetFilters() + '] parent=[' + Child.GetFilter(ParentId) + '] grp=[' + Child.GetFilter(Grp) + ']');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('child ' + Format(Child.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('child post filters=[' + Child.GetFilters() + ']');
                end;
            }

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('row post child filters=[' + Child.GetFilters() + '] count=' + Format(Child.Count()));
            end;
        }
    }

    trigger OnPostReport()
    begin
        L.Add('report post child filters=[' + Child.GetFilters() + '] row filters=[' + Row.GetFilters() + ']');
    end;

    var
        L: Codeunit "LT PnH Link Log";
}

// The child changes its own filters in OnPreDataItem / OnAfterGetRecord (the mode says how).
report 70592 "LT PnH LinkPreSet"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            dataitem(Child; "LT PnH Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnPreDataItem()
                begin
                    case L.GetMode() of
                        'SetRangeGrp1':
                            Child.SetRange(Grp, 1);
                        'SetRangeParent99':
                            Child.SetRange(ParentId, 99);
                        'SetFilterParentAll':
                            Child.SetFilter(ParentId, '>0');
                        'Reset':
                            Child.Reset();
                        'SetRangeIdOnly':
                            Child.SetRange(Id, 11, 12);
                    end;
                    L.Add('pre of ' + Format(Row.Id) + ' filters=[' + Child.GetFilters() + ']');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('child ' + Format(Child.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "LT PnH Link Log";
}

report 70593 "LT PnH CalcFields"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            CalcFields = ChildCnt;

            trigger OnPreDataItem()
            begin
                L.Add('pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id) + ' cnt=' + Format(Row.ChildCnt));
            end;
        }
    }

    var
        L: Codeunit "LT PnH Link Log";
}

report 70594 "LT PnH NoCalcFields"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id) + ' cnt=' + Format(Row.ChildCnt));
            end;
        }
    }

    var
        L: Codeunit "LT PnH Link Log";
}

report 70595 "LT PnH MaxIter"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            MaxIteration = 3;

            trigger OnAfterGetRecord()
            begin
                L.Add('num ' + Format(Num.Number));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('num post');
            end;
        }
    }

    var
        L: Codeunit "LT PnH Link Log";
}

report 70596 "LT PnH MaxIterFew"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            MaxIteration = 5;

            trigger OnAfterGetRecord()
            begin
                L.Add('num ' + Format(Num.Number));
            end;
        }
    }

    var
        L: Codeunit "LT PnH Link Log";
}

// Nested Integer item with MaxIteration under a table item: once per parent row.
report 70597 "LT PnH MaxIterNested"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            dataitem(Num; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                MaxIteration = 2;

                trigger OnAfterGetRecord()
                begin
                    L.Add('row ' + Format(Row.Id) + ' num ' + Format(Num.Number));
                end;
            }
        }
    }

    var
        L: Codeunit "LT PnH Link Log";
}

codeunit 70598 "LT PnH Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH Link Log";
        Helper: Codeunit "LT PnH Helper";

    local procedure Start()
    begin
        Helper.Seed();
        L.Take();
        L.SetMode('');
    end;

    [TryFunction]
    local procedure TryRunPreSet()
    begin
        Report.Run(Report::"LT PnH LinkPreSet");
    end;

    local procedure RunPreSet(Mode: Text; Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        L.SetMode(Mode);
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryRunPreSet()));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name, L.Take());
        L.SetMode('');
    end;

    [Test]
    procedure Link_TwoFields_FiltersPerParentRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH LinkMulti");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'row 1;child pre of 1 filters=[] parent=[] grp=[];child 10;child post filters=[];row 2;child pre of 2 filters=[] parent=[] grp=[];child 12;child post filters=[];row 3;child pre of 3 filters=[] parent=[] grp=[];child 13;child post filters=[];row post child filters=[] count=1;report post child filters=[] row filters=[];');
        Observer.Verify();
    end;

    [Test]
    procedure Link_TwoFields_ParentFiltered()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH LinkMulti";
        Row: Record "LT PnH Row";
    begin
        Start();
        Row.SetRange(Grp, 1);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'row 1;child pre of 1 filters=[] parent=[] grp=[];child 10;child post filters=[];row 2;child pre of 2 filters=[] parent=[] grp=[];child 12;child post filters=[];row post child filters=[] count=1;report post child filters=[] row filters=[Grp: 1];');
        Observer.Verify();
    end;

    [Test]
    procedure Link_ChildSetsOwnFilters_InPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        RunPreSet('', 'none', Observer);
        RunPreSet('SetRangeGrp1', 'range grp', Observer);
        RunPreSet('SetRangeIdOnly', 'range id', Observer);
        RunPreSet('SetFilterParentAll', 'setfilter parent', Observer);
        RunPreSet('SetRangeParent99', 'range parent', Observer);
        RunPreSet('Reset', 'reset', Observer);
        Observer.Expect('none ok', 'Yes');
        Observer.Expect('none err|text', '');
        Observer.Expect('none err|code', '');
        Observer.Expect('none', 'pre of 1 filters=[];child 10;child 11;pre of 2 filters=[];child 12;pre of 3 filters=[];child 13;');
        Observer.Expect('range grp ok', 'Yes');
        Observer.Expect('range grp err|text', '');
        Observer.Expect('range grp err|code', '');
        Observer.Expect('range grp', 'pre of 1 filters=[Grp: 1];child 10;pre of 2 filters=[Grp: 1];child 12;pre of 3 filters=[Grp: 1];');
        Observer.Expect('range id ok', 'Yes');
        Observer.Expect('range id err|text', '');
        Observer.Expect('range id err|code', '');
        Observer.Expect('range id', 'pre of 1 filters=[Id: 11..12];child 11;pre of 2 filters=[Id: 11..12];child 12;pre of 3 filters=[Id: 11..12];');
        Observer.Expect('setfilter parent ok', 'Yes');
        Observer.Expect('setfilter parent err|text', '');
        Observer.Expect('setfilter parent err|code', '');
        Observer.Expect('setfilter parent', 'pre of 1 filters=[ParentId: >0];child 10;child 11;pre of 2 filters=[ParentId: >0];child 12;pre of 3 filters=[ParentId: >0];child 13;');
        Observer.Expect('range parent ok', 'Yes');
        Observer.Expect('range parent err|text', '');
        Observer.Expect('range parent err|code', '');
        Observer.Expect('range parent', 'pre of 1 filters=[ParentId: 99];pre of 2 filters=[ParentId: 99];pre of 3 filters=[ParentId: 99];');
        Observer.Expect('reset ok', 'Yes');
        Observer.Expect('reset err|text', '');
        Observer.Expect('reset err|code', '');
        Observer.Expect('reset', 'pre of 1 filters=[];child 10;child 11;child 12;child 13;pre of 2 filters=[];child 10;child 11;child 12;child 13;pre of 3 filters=[];child 10;child 11;child 12;child 13;');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_Property_CalculatesTheFlowField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH CalcFields");
        Observer.Observe('with CalcFields', L.Take());
        Report.Run(Report::"LT PnH NoCalcFields");
        Observer.Observe('without CalcFields', L.Take());
        Observer.Expect('with CalcFields', 'pre;row 1 cnt=2;row 2 cnt=1;row 3 cnt=1;');
        Observer.Expect('without CalcFields', 'row 1 cnt=0;row 2 cnt=0;row 3 cnt=0;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIteration_StopsTheIntegerItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH MaxIter");
        Observer.Observe('max 3 of unbounded', L.Take());
        Report.Run(Report::"LT PnH MaxIterFew");
        Observer.Observe('max 5 of 2', L.Take());
        Observer.Expect('max 3 of unbounded', 'num 1;num 2;num 3;num post;');
        Observer.Expect('max 5 of 2', 'num 1;num 2;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIteration_NestedPerParentRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH MaxIterNested");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'row 1 num 1;row 1 num 2;row 2 num 1;row 2 num 2;row 3 num 1;row 3 num 2;');
        Observer.Verify();
    end;
}
