// Probe (observe round): the caption of a list or card page with DataCaptionFields over a field with a TableRelation. Header written after measurement.
codeunit 92891 "LT Y45 List Caption Relation"
{
    Subtype = Test;

    local procedure Init(Std: Boolean)
    var
        Ref: Record "LT Y45 Ref";
        Row: Record "LT Y45 Cap Row";
    begin
        Ref.DeleteAll();
        Row.DeleteAll();
        AddRef('R1', 'Ref One', 'extra one');
        AddRef('R2', '', 'extra two');
        AddRef('R3', 'Ref Three', '');
        AddRow(1, 'R1', 'P1');
        AddRow(2, 'R1', 'P1');
        AddRow(3, 'R2', 'P2');
        AddRow(4, 'R3', 'P1');
        AddRow(5, 'R9', 'P3');
        AddRefDcf('D1', 'Dcf One');
        AddRefDesc('E1', 'Desc One');
        Row.Get(1);
        Row.RefDcf := 'D1';
        Row.RefDesc := 'E1';
        Row.Modify();
    end;

    local procedure AddRef(No: Code[20]; Name: Text[50]; Extra: Text[50])
    var
        Ref: Record "LT Y45 Ref";
    begin
        Ref."No." := No;
        Ref.Name := Name;
        Ref.Extra := Extra;
        Ref.Insert();
    end;

    local procedure AddRefDcf(No: Code[20]; Name: Text[50])
    var
        Ref: Record "LT Y45 Ref Dcf";
    begin
        Ref.DeleteAll();
        Ref."No." := No;
        Ref.Name := Name;
        Ref.Insert();
    end;

    local procedure AddRefDesc(No: Code[20]; Description: Text[50])
    var
        Ref: Record "LT Y45 Ref Desc";
    begin
        Ref.DeleteAll();
        Ref."No." := No;
        Ref.Description := Description;
        Ref.Insert();
    end;

    local procedure AddRow(Id: Integer; RefNo: Code[20]; Plain: Code[20])
    var
        Row: Record "LT Y45 Cap Row";
    begin
        Row.Id := Id;
        Row.RefNo := RefNo;
        Row.Plain := Plain;
        Row.Insert();
    end;

    [Test]
    procedure List_NoDcf_FilterRefNo_Caption()
    var
        TP: TestPage "LT Y45 Cap List";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap List');
        Observer.Verify();
    end;

    [Test]
    procedure List_NoDcf_Unfiltered_Caption()
    var
        TP: TestPage "LT Y45 Cap List";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap List');
        Observer.Verify();
    end;

    [Test]
    procedure List_NoDcf_FilterPlain_Caption()
    var
        TP: TestPage "LT Y45 Cap List";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(Plain, 'P1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap List');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_FilterRefNo_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF - R1');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_FilterRefNoMissingRef_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R9');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_FilterRefNoBlankName_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R2');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF - R2');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_FilterRefNoTwoValues_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R1|R3');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_FilterRefNoRange_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R1..R3');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_Unfiltered_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_FilterOtherField_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(Plain, 'P1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_SetFilterOnTestPage_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenView();
        TP.Filter.SetFilter(RefNo, 'R1');
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF - R1');
        Observer.Verify();
    end;

    [Test]
    procedure List_Dcf_OpenViewUnfiltered_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        TP.OpenView();
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap DCF');
        Observer.Verify();
    end;

    [Test]
    procedure List_DcfPlain_FilterPlain_Caption()
    var
        TP: TestPage "LT Y45 Cap List Plain";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(Plain, 'P1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List Plain", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap Plain - P1');
        Observer.Verify();
    end;

    [Test]
    procedure List_DcfTwo_FilterRefNo_Caption()
    var
        TP: TestPage "LT Y45 Cap List Two";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List Two", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap Two - R1');
        Observer.Verify();
    end;

    [Test]
    procedure Card_Dcf_OnRow_Caption()
    var
        TP: TestPage "LT Y45 Cap Card DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.Get(2);
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap Card DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap Card - 2');
        Observer.Verify();
    end;

    [Test]
    procedure Card_Dcf_FilterRefNo_Caption()
    var
        TP: TestPage "LT Y45 Cap Card DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefNo, 'R1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap Card DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap Card - 1');
        Observer.Verify();
    end;

    [Test]
    procedure Card_Dcf_OnRowNext_Caption()
    var
        TP: TestPage "LT Y45 Cap Card DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.Get(2);
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap Card DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Next();
        Observer.Observe('caption after next', TP.Caption());
        TP.Close();
        Observer.Expect('caption', 'Y45 Cap Card - 2');
        Observer.Expect('caption after next', 'Y45 Cap Card - 3');
        Observer.Verify();
    end;

    [Test]
    procedure List_DcfRelatedTableDcf_Filter_Caption()
    var
        TP: TestPage "LT Y45 Cap List RefDcf";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefDcf, 'D1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List RefDcf", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_DcfRelatedDescription_Filter_Caption()
    var
        TP: TestPage "LT Y45 Cap List RefDesc";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetFilter(RefDesc, 'E1');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List RefDesc", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_Dcf_SetRangeRefNo_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetRange(RefNo, 'R3');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_Dcf_FilterMissingRefNoRow_Caption()
    var
        TP: TestPage "LT Y45 Cap List DCF";
        Row: Record "LT Y45 Cap Row";
        Observer: Codeunit "Probe Observer";
    begin
        Init(true);
        Row.SetRange(RefNo, 'R7');
        TP.Trap();
        Page.Run(Page::"LT Y45 Cap List DCF", Row);
        Observer.Observe('caption', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;
}
