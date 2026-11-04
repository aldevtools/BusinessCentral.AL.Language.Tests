// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-dataitem-properties
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70600 is used only by test codeunit 70604
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed row: Report | `DataItemLink` ... `DataItemLinkReference`, a link naming another item (the grandparent, a preceding sibling).
// Kept apart from PnH3Link.al: if the sibling form does not compile, drop only this file.
// BC versions: 29 (27 and 28 by CI)

codeunit 70600 "LT PnH LinkRef Log"
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

report 70601 "LT PnH LinkRefGrand"
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

                dataitem(Grand; "LT PnH Child")
                {
                    DataItemLinkReference = Row;
                    DataItemLink = Grp = field(Grp);

                    trigger OnPreDataItem()
                    begin
                        L.Add('grand pre row=' + Format(Row.Id) + ' child=' + Format(Child.Id) + ' filters=[' + Grand.GetFilters() + ']');
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        L.Add('grand ' + Format(Grand.Id));
                    end;
                }
            }
        }
    }

    var
        L: Codeunit "LT PnH LinkRef Log";
}

report 70602 "LT PnH LinkRefSibling"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
        dataitem(Child; "LT PnH Child")
        {
            DataItemLinkReference = Row;
            DataItemLink = ParentId = field(Id);

            trigger OnPreDataItem()
            begin
                L.Add('child pre filters=[' + Child.GetFilters() + '] row=' + Format(Row.Id));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('child ' + Format(Child.Id));
            end;
        }
    }

    var
        L: Codeunit "LT PnH LinkRef Log";
}

codeunit 70604 "LT PnH LinkRef Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH LinkRef Log";
        Helper: Codeunit "LT PnH Helper";

    [Test]
    procedure LinkReference_Grandparent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT PnH LinkRefGrand");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'grand pre row=1 child=10 filters=[];grand 10;grand 12;grand pre row=1 child=11 filters=[];grand 10;grand 12;grand pre row=2 child=12 filters=[];grand 10;grand 12;grand pre row=3 child=13 filters=[];grand 11;grand 13;');
        Observer.Verify();
    end;

    [Test]
    procedure LinkReference_PrecedingSibling()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT PnH LinkRefSibling");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'row 1;row 2;row 3;child pre filters=[] row=3;child 13;');
        Observer.Verify();
    end;
}
