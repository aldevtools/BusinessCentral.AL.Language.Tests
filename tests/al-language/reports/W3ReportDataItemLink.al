//sub:report
// DataItemLink with the enclosing item (md:199, md:376). The link filter of the child, where it lives (filter group 4), what stays on the child
// after the loop, and what happens when the child already has a filter on the link field (from DataItemTableView or SetTableView).

codeunit 67715 "W3 Link Log"
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

report 67716 "W3 Link Plain"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "W3 Row")
        {
            dataitem(Child; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnPreDataItem()
                begin
                    L.Add('C pre ' + Shape());
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('C row ' + Format(Child.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('C post ' + Shape());
                end;
            }

            trigger OnPreDataItem()
            begin
                L.Add('P pre ' + Shape());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('P row ' + Format(Parent.Id) + ' ' + Shape());
            end;

            trigger OnPostDataItem()
            begin
                L.Add('P post ' + Shape());
            end;
        }
    }

    var
        L: Codeunit "W3 Link Log";

    local procedure Shape(): Text
    var
        OldGroup: Integer;
        Link: Text;
    begin
        OldGroup := Child.FilterGroup();
        Child.FilterGroup(4);
        Link := Child.GetFilter(ParentId);
        Child.FilterGroup(OldGroup);
        exit('g=' + Format(OldGroup) + ' f=[' + Child.GetFilter(ParentId) + '] all=[' + Child.GetFilters() + '] g4=[' + Link + ']');
    end;

    trigger OnPreReport()
    begin
        L.Add('PreReport ' + Shape());
    end;
}

// The child already filters the link field in its DataItemTableView.
report 67717 "W3 Link Conflict"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "W3 Row")
        {
            dataitem(Child; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);
                DataItemTableView = where(ParentId = filter(1));

                trigger OnAfterGetRecord()
                begin
                    L.Add('P ' + Format(Parent.Id) + ' C ' + Format(Child.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "W3 Link Log";
}

// The child filters another field than the link field in its DataItemTableView.
report 67718 "W3 Link Other Field"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "W3 Row")
        {
            dataitem(Child; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);
                DataItemTableView = where(Id = filter(2..3));

                trigger OnPreDataItem()
                begin
                    L.Add('C pre all=[' + Child.GetFilters() + ']');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('P ' + Format(Parent.Id) + ' C ' + Format(Child.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "W3 Link Log";
}

codeunit 67719 "W3 Link Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 Link Log";
        Runner: Codeunit "W3 Runner";

    local procedure Seed()
    var
        Row: Record "W3 Row";
        Child: Record "W3 Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Child.Id := 1;
        Child.ParentId := 1;
        Child.Name := 'a1';
        Child.Insert();
        Child.Id := 2;
        Child.ParentId := 1;
        Child.Name := 'b2';
        Child.Insert();
        Child.Id := 3;
        Child.ParentId := 2;
        Child.Name := 'a3';
        Child.Insert();
        Commit();
        L.Take();
    end;

    [TryFunction]
    local procedure TryRun(var Rpt: Report "W3 Link Plain")
    begin
        Rpt.Run();
    end;

    // md:199 and md:376: group 0 and group 4 filters of the child in every trigger, and after the loop (parent 3 has no child).
    [Test]
    procedure Run_LinkFilter_GroupAndLifetime()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 Link Plain");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'PreReport g=0 f=[] all=[] g4=[];P pre g=0 f=[] all=[] g4=[];P row 1 g=0 f=[] all=[] g4=[];C pre g=0 f=[] all=[] g4=[1];C row 1;C row 2;C post g=0 f=[] all=[] g4=[1];P row 2 g=0 f=[] all=[] g4=[1];C pre g=0 f=[] all=[] g4=[2];C row 3;C post g=0 f=[] all=[] g4=[2];P row 3 g=0 f=[] all=[] g4=[2];C pre g=0 f=[] all=[] g4=[3];C post g=0 f=[] all=[] g4=[3];P post g=0 f=[] all=[] g4=[3];');
        Observer.Verify();
    end;

    // md:199: the child's own view filters the link field (REFUSED by the runtime; BC?).
    [Test]
    procedure Run_ChildViewFiltersTheLinkField()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Link Conflict", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'P 1 C 1;P 1 C 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_ChildViewFiltersAnotherField()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Link Other Field", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'C pre all=[];P 1 C 2;C pre all=[];P 2 C 3;C pre all=[];');
        Observer.Verify();
    end;

    // md:199: SetTableView of the caller filters the link field of the child.
    [Test]
    procedure Run_SetTableViewFiltersTheLinkField()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 Link Plain";
        Child: Record "W3 Child";
        Ok: Boolean;
    begin
        Seed();
        Child.SetRange(ParentId, 1);
        Rpt.SetTableView(Child);
        Ok := TryRun(Rpt);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'PreReport g=0 f=[1] all=[ParentId: 1] g4=[];P pre g=0 f=[1] all=[ParentId: 1] g4=[];P row 1 g=0 f=[1] all=[ParentId: 1] g4=[];C pre g=0 f=[1] all=[ParentId: 1] g4=[1];C row 1;C row 2;C post g=0 f=[1] all=[ParentId: 1] g4=[1];P row 2 g=0 f=[1] all=[ParentId: 1] g4=[1];C pre g=0 f=[1] all=[ParentId: 1] g4=[2];C post g=0 f=[1] all=[ParentId: 1] g4=[2];P row 3 g=0 f=[1] all=[ParentId: 1] g4=[2];C pre g=0 f=[1] all=[ParentId: 1] g4=[3];C post g=0 f=[1] all=[ParentId: 1] g4=[3];P post g=0 f=[1] all=[ParentId: 1] g4=[3];');
        Observer.Verify();
    end;

    // The same SetTableView with a filter on another field of the child.
    [Test]
    procedure Run_SetTableViewFiltersAnotherField()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 Link Plain";
        Child: Record "W3 Child";
        Ok: Boolean;
    begin
        Seed();
        Child.SetFilter(Name, 'a*');
        Rpt.SetTableView(Child);
        Ok := TryRun(Rpt);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'PreReport g=0 f=[] all=[Name: a*] g4=[];P pre g=0 f=[] all=[Name: a*] g4=[];P row 1 g=0 f=[] all=[Name: a*] g4=[];C pre g=0 f=[] all=[Name: a*] g4=[1];C row 1;C post g=0 f=[] all=[Name: a*] g4=[1];P row 2 g=0 f=[] all=[Name: a*] g4=[1];C pre g=0 f=[] all=[Name: a*] g4=[2];C row 3;C post g=0 f=[] all=[Name: a*] g4=[2];P row 3 g=0 f=[] all=[Name: a*] g4=[2];C pre g=0 f=[] all=[Name: a*] g4=[3];C post g=0 f=[] all=[Name: a*] g4=[3];P post g=0 f=[] all=[Name: a*] g4=[3];');
        Observer.Verify();
    end;
}
