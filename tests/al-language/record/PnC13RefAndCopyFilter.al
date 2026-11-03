// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copyfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: RecordRef.Ascending and SetRecFilter (fixes-7) "No corpus test calls them on a RecordRef"; CopyFilter (fixes-7) "CopyFilter inside FilterGroup(2), between a Code and a Text field"
// BC versions: 29 (27 and 28 by CI)

codeunit 71117 "LT PnC RecordRef Ascending"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Init();
            R."No." := i;
            R.Name := 'N' + Format(5 - i);
            R.Insert();
        end;
    end;

    local procedure Order(var RR: RecordRef): Text
    var
        Result: Text;
    begin
        if RR.FindSet() then
            repeat
                Result += Format(RR.Field(1).Value) + ',';
            until RR.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Ascending_Getter_And_Setter()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(71080);
        Observer.Observe('default', Format(RR.Ascending()));
        Observer.Observe('order.default', Order(RR));
        RR.Ascending(false);
        Observer.Observe('afterFalse', Format(RR.Ascending()));
        Observer.Observe('order.desc', Order(RR));
        RR.Ascending(true);
        Observer.Observe('afterTrue', Format(RR.Ascending()));
        Observer.Observe('order.asc', Order(RR));
        RR.Ascending(false);
        RR.Reset();
        Observer.Observe('afterReset', Format(RR.Ascending()));
        RR.Close();
        Observer.Expect('default', 'Yes');
        Observer.Expect('order.default', '1,2,3,4,');
        Observer.Expect('afterFalse', 'No');
        Observer.Expect('order.desc', '4,3,2,1,');
        Observer.Expect('afterTrue', 'Yes');
        Observer.Expect('order.asc', '1,2,3,4,');
        Observer.Expect('afterReset', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetRecFilter_OnRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        R: Record "LT PnC Rec";
    begin
        Seed();
        RR.Open(71080);
        RR.FindSet();
        RR.Next();
        RR.SetRecFilter();
        Observer.Observe('filters', RR.GetFilters());
        Observer.Observe('count', Format(RR.Count()));
        Observer.Observe('view', RR.GetView());
        RR.Reset();
        RR.Field(2).SetRange('N2');
        RR.FindFirst();
        RR.SetRecFilter();
        Observer.Observe('afterOtherFilter.filters', RR.GetFilters());
        Observer.Observe('afterOtherFilter.count', Format(RR.Count()));
        RR.Close();
        R.Get(3);
        R.SetRecFilter();
        Observer.Observe('record.filters', R.GetFilters());
        RR.GetTable(R);
        Observer.Observe('getTable.filters', RR.GetFilters());
        Observer.Expect('filters', 'No.: 2');
        Observer.Expect('count', '1');
        Observer.Expect('view', 'VERSION(1) SORTING(No.) WHERE(No.=FILTER(2))');
        Observer.Expect('afterOtherFilter.filters', 'No.: 3, Name: N2');
        Observer.Expect('afterOtherFilter.count', '1');
        Observer.Expect('record.filters', 'No.: 3');
        Observer.Expect('getTable.filters', 'No.: 3');
        Observer.Verify();
    end;

    [Test]
    procedure SetRecFilter_NoCurrentRow()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(71080);
        RR.SetRecFilter();
        Observer.Observe('fresh.filters', RR.GetFilters());
        Observer.Observe('fresh.count', Format(RR.Count()));
        RR.Close();
        Observer.Expect('fresh.filters', 'No.: 0');
        Observer.Expect('fresh.count', '0');
        Observer.Verify();
    end;
}

codeunit 71118 "LT PnC CopyFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CopyFilter_Basics()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT PnC Rec";
        Tgt: Record "LT PnC Rec";
    begin
        Src.SetRange(Other, 5, 9);
        Src.CopyFilter(Other, Tgt.Other);
        Observer.Observe('copied', Tgt.GetFilters());
        Tgt.SetRange(Other, 100);
        Src.CopyFilter(Other, Tgt.Other);
        Observer.Observe('replaced', Tgt.GetFilters());
        Src.Reset();
        Src.CopyFilter(Other, Tgt.Other);
        Observer.Observe('unfilteredSource', '[' + Tgt.GetFilters() + ']');
        Src.SetFilter(Other, '<3|>7');
        asserterror Src.CopyFilter(Other, Tgt.Amount);
        Observer.ObserveError('af129');
        Observer.Observe('intToDecimal', Tgt.GetFilters());
        Tgt.Reset();
        Src.CopyFilter(Other, Tgt."No.");
        Observer.Observe('otherField', Tgt.GetFilters());
        Tgt.Reset();
        Tgt.SetRange(Name, 'keep');
        Src.CopyFilter(Other, Tgt."No.");
        Observer.Observe('keepsOtherFields', Tgt.GetFilters());
        Observer.Expect('copied', 'Other: 5..9');
        Observer.Expect('replaced', 'Other: 5..9');
        Observer.Expect('unfilteredSource', '[]');
        Observer.Expect('af129|text', 'The type of the constant must be compatible with that of the Amount field, and the length of the constant must not exceed the length of the field.\\Type: Decimal <-- Integer\Field: Amount <-- Other\Table: LT PnC Rec');
        Observer.Expect('af129|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('intToDecimal', '');
        Observer.Expect('otherField', 'No.: <3|>7');
        Observer.Expect('keepsOtherFields', 'No.: <3|>7, Name: keep');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_CodeToText()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT PnC Rec";
        Tgt: Record "LT PnC Rec";
    begin
        Src.SetRange("Code Value", 'A', 'M');
        asserterror Src.CopyFilter("Code Value", Tgt.Name);
        Observer.ObserveError('af150');
        Observer.Observe('codeToText', Tgt.GetFilters());
        Tgt.Reset();
        Src.SetFilter("Code Value", '@abc*');
        asserterror Src.CopyFilter("Code Value", Tgt.Name);
        Observer.ObserveError('af155');
        Observer.Observe('wildcardToText', Tgt.GetFilters());
        Tgt.Reset();
        Src.Reset();
        Src.SetRange(Name, 'x');
        asserterror Src.CopyFilter(Name, Tgt."Code Value");
        Observer.ObserveError('textToCode');
        Observer.Expect('af150|text', 'The type of the constant must be compatible with that of the Name field, and the length of the constant must not exceed the length of the field.\\Type: Text <-- Code\Field: Name <-- Code Value\Table: LT PnC Rec');
        Observer.Expect('af150|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('codeToText', '');
        Observer.Expect('af155|text', 'The type of the constant must be compatible with that of the Name field, and the length of the constant must not exceed the length of the field.\\Type: Text <-- Code\Field: Name <-- Code Value\Table: LT PnC Rec');
        Observer.Expect('af155|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('wildcardToText', '');
        Observer.Expect('textToCode|text', 'The type of the constant must be compatible with that of the Code Value field, and the length of the constant must not exceed the length of the field.\\Type: Code <-- Text\Field: Code Value <-- Name\Table: LT PnC Rec');
        Observer.Expect('textToCode|code', 'NCLCSRTS:TableEqualValue');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_DifferentTypes()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT PnC Rec";
        Tgt: Record "LT PnC Rec";
    begin
        Src.SetRange(Other, 5);
        asserterror Src.CopyFilter(Other, Tgt.Name);
        Observer.ObserveError('intToText');
        Observer.Observe('intToText.filters', '[' + Tgt.GetFilters() + ']');
        Src.Reset();
        Src.SetRange(Name, 'x');
        asserterror Src.CopyFilter(Name, Tgt.Other);
        Observer.ObserveError('textToInt');
        Src.Reset();
        Src.SetRange(Status, Src.Status::Closed);
        asserterror Src.CopyFilter(Status, Tgt.Other);
        Observer.ObserveError('optionToInt');
        Observer.Expect('intToText|text', 'The type of the constant must be compatible with that of the Name field, and the length of the constant must not exceed the length of the field.\\Type: Text <-- Integer\Field: Name <-- Other\Table: LT PnC Rec');
        Observer.Expect('intToText|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('intToText.filters', '[]');
        Observer.Expect('textToInt|text', 'The type of the constant must be compatible with that of the Other field, and the length of the constant must not exceed the length of the field.\\Type: Integer <-- Text\Field: Other <-- Name\Table: LT PnC Rec');
        Observer.Expect('textToInt|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('optionToInt|text', 'The type of the constant must be compatible with that of the Other field, and the length of the constant must not exceed the length of the field.\\Type: Integer <-- Option\Field: Other <-- Status\Table: LT PnC Rec');
        Observer.Expect('optionToInt|code', 'NCLCSRTS:TableEqualValue');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_FilterGroups()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT PnC Rec";
        Tgt: Record "LT PnC Rec";
    begin
        Src.FilterGroup(2);
        Src.SetRange(Other, 7);
        Src.FilterGroup(0);
        Src.CopyFilter(Other, Tgt.Other);
        Observer.Observe('sourceGroup2.copyFromGroup0', '[' + Tgt.GetFilters() + ']');
        Src.FilterGroup(2);
        Src.CopyFilter(Other, Tgt.Other);
        Observer.Observe('sourceInGroup2.copy', '[' + Tgt.GetFilters() + ']');
        Src.FilterGroup(0);
        Tgt.Reset();
        Src.SetRange(Other, 3);
        Tgt.FilterGroup(2);
        Src.CopyFilter(Other, Tgt.Other);
        Observer.Observe('targetGroup2.group2', '[' + Tgt.GetFilters() + ']');
        Tgt.FilterGroup(0);
        Observer.Observe('targetGroup2.group0', '[' + Tgt.GetFilters() + ']');
        Observer.Observe('filterGroupNow', Format(Tgt.FilterGroup()));
        Tgt.FilterGroup(4);
        Observer.Observe('targetGroup4.group4', '[' + Tgt.GetFilters() + ']');
        Tgt.FilterGroup(0);
        Observer.Expect('sourceGroup2.copyFromGroup0', '[]');
        Observer.Expect('sourceInGroup2.copy', '[Other: 7]');
        Observer.Expect('targetGroup2.group2', '[Other: 3]');
        Observer.Expect('targetGroup2.group0', '[]');
        Observer.Expect('filterGroupNow', '0');
        Observer.Expect('targetGroup4.group4', '[]');
        Observer.Verify();
    end;
}
