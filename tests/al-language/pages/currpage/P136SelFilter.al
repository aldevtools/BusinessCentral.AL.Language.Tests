// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74347 of P136Report.al; page 74357, codeunits 74358 74359
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.SetSelectionFilter and Page.SetSelectionFilter into a record that already has filters (another field, the same field, a filter in FilterGroup 2, marks with MarkedOnly, a current key set, a descending order): the filters, the key and the row count the record has afterwards; into a record without filters as the baseline
// BC versions: 29 (27 and 28 by CI)

codeunit 74358 "LT P136 Sel Log"
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
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;

    procedure Describe(var Target: Record "LT P136 Item"): Text
    var
        G0: Text;
        G2: Text;
    begin
        G0 := Target.GetFilters();
        Target.FilterGroup(2);
        G2 := Target.GetFilters();
        Target.FilterGroup(0);
        exit('f=[' + G0 + '] g2=[' + G2 + '] n=' + Format(Target.Count()) + ' key=' + Target.CurrentKey() + ' asc=' + Format(Target.Ascending()) + ' marked=' + Format(Target.MarkedOnly()));
    end;
}

page 74357 "LT P136 Sel List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P136 Item";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelPlain)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('plain ' + Log.Describe(Target));
                end;
            }
            action(SelOtherField)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    Target.SetFilter(Qty, '>=20');
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('otherField ' + Log.Describe(Target));
                end;
            }
            action(SelSameField)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    Target.SetRange(Id, 1, 2);
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('sameField ' + Log.Describe(Target));
                end;
            }
            action(SelGroup2)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    Target.FilterGroup(2);
                    Target.SetFilter(Qty, '>=20');
                    Target.FilterGroup(0);
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('group2 ' + Log.Describe(Target));
                end;
            }
            action(SelMarked)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    Target.Get(1);
                    Target.Mark(true);
                    Target.MarkedOnly(true);
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('marked ' + Log.Describe(Target));
                end;
            }
            action(SelKeyDescending)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    Target.SetCurrentKey(Qty);
                    Target.Ascending(false);
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('keyDesc ' + Log.Describe(Target));
                end;
            }
            action(SelTwice)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Target: Record "LT P136 Item";
                    Log: Codeunit "LT P136 Sel Log";
                begin
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('twiceFirst ' + Log.Describe(Target));
                    CurrPage.SetSelectionFilter(Target);
                    Log.Add('twiceSecond ' + Log.Describe(Target));
                end;
            }
        }
    }
}

codeunit 74359 "LT P136 Sel Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P136 Sel Log";

    local procedure Seed()
    var
        Item: Record "LT P136 Item";
    begin
        Item.DeleteAll();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Qty := 10;
        Item.Insert();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Qty := 20;
        Item.Insert();
        Item.Id := 3;
        Item.Name := 'three';
        Item.Qty := 30;
        Item.Insert();
        Log.Take();
    end;

    [Test]
    procedure P136_SelectionFilter_IntoRecordWithAndWithoutFilters()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P136 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey(2);
        List.SelPlain.Invoke();
        Observer.Observe('plain', Log.Take());
        List.SelOtherField.Invoke();
        Observer.Observe('otherField', Log.Take());
        List.SelSameField.Invoke();
        Observer.Observe('sameField', Log.Take());
        List.SelGroup2.Invoke();
        Observer.Observe('group2', Log.Take());
        List.SelMarked.Invoke();
        Observer.Observe('marked', Log.Take());
        List.SelKeyDescending.Invoke();
        Observer.Observe('keyDescending', Log.Take());
        List.SelTwice.Invoke();
        Observer.Observe('twice', Log.Take());
        List.Close();
        Observer.Expect('plain', 'plain f=[Id: 2] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('otherField', 'otherField f=[Id: 2] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('sameField', 'sameField f=[Id: 2] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('group2', 'group2 f=[Id: 2] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('marked', 'marked f=[Marked: Yes, Id: 2] g2=[Marked: Yes] n=1 key=Id asc=Yes marked=Yes;');
        Observer.Expect('keyDescending', 'keyDesc f=[Id: 2] g2=[] n=1 key=Qty asc=No marked=No;');
        Observer.Expect('twice', 'twiceFirst f=[Id: 2] g2=[] n=1 key=Id asc=Yes marked=No;twiceSecond f=[Id: 2] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P136_SelectionFilter_OtherFieldSelectedRowOutsideFilter()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P136 Sel List";
    begin
        Seed();
        List.OpenView();
        // row 1 has Qty 10: the target filter Qty >= 20 excludes it
        List.GoToKey(1);
        List.SelOtherField.Invoke();
        Observer.Observe('otherFieldRow1', Log.Take());
        List.SelSameField.Invoke();
        Observer.Observe('sameFieldRow1', Log.Take());
        // row 3 is outside Id 1..2
        List.GoToKey(3);
        List.SelSameField.Invoke();
        Observer.Observe('sameFieldRow3', Log.Take());
        List.SelOtherField.Invoke();
        Observer.Observe('otherFieldRow3', Log.Take());
        List.Close();
        Observer.Expect('otherFieldRow1', 'otherField f=[Id: 1] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('sameFieldRow1', 'sameField f=[Id: 1] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('sameFieldRow3', 'sameField f=[Id: 3] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Expect('otherFieldRow3', 'otherField f=[Id: 3] g2=[] n=1 key=Id asc=Yes marked=No;');
        Observer.Verify();
    end;
}
