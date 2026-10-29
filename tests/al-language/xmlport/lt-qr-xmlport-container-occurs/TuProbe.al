codeunit 90139 "LT TU XP Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ToRead(var Buffer: Record "LT QR XP Blob" temporary): Text
    var
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    local procedure TuExportKeyOnce(var Port: XmlPort "LT TU XP Key Once"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure TuExportKeyUnbounded(var Port: XmlPort "LT TU XP Key Unbounded"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure TuExportReal(var Port: XmlPort "LT TU XP Nested Real"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure TuExportTemp(var Port: XmlPort "LT TU XP Nested Temp"): Text
    var
        Buffer: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ToRead(Buffer));
    end;

    local procedure TuSeedKeys()
    var
        Child: Record "LT TU XP KChild";
    begin
        // Id order 1,2,3; A order 2,3,1; B order 3,1,2
        Child.DeleteAll();
        Child.Id := 1;
        Child.A := 30;
        Child.B := 20;
        Child.Insert();
        Child.Id := 2;
        Child.A := 10;
        Child.B := 30;
        Child.Insert();
        Child.Id := 3;
        Child.A := 20;
        Child.B := 10;
        Child.Insert();
    end;

    local procedure TuKeyRun(Mode: Integer; var XmlOnce: Text; var LogOnce: Text; var XmlUnbounded: Text; var LogUnbounded: Text)
    var
        PortOnce: XmlPort "LT TU XP Key Once";
        PortUnbounded: XmlPort "LT TU XP Key Unbounded";
    begin
        TuSeedKeys();
        PortOnce.AddParent(1);
        PortOnce.AddParent(2);
        PortOnce.AddParent(3);
        PortOnce.SetMode(Mode);
        XmlOnce := TuExportKeyOnce(PortOnce);
        LogOnce := PortOnce.GetLog();
        PortUnbounded.AddParent(1);
        PortUnbounded.AddParent(2);
        PortUnbounded.AddParent(3);
        PortUnbounded.SetMode(Mode);
        XmlUnbounded := TuExportKeyUnbounded(PortUnbounded);
        LogUnbounded := PortUnbounded.GetLog();
    end;

    local procedure TuSeedReal()
    var
        Line: Record "LT TU XP Line";
        Item: Record "LT TU XP Item";
        Slot: Record "LT TU XP Slot";
    begin
        // order Ref 10: lines 1 (items 11, 12) and 2 (no item); order Ref 20: line 3 (item 13); order Ref 40: line 4 (item 14, slot 104)
        // item 11: slots 101 (Reservation), 102 (Reservation), 103 (Admitted); item 12: slot 105 (Admitted only); item 13: slot 106
        Line.DeleteAll();
        Item.DeleteAll();
        Slot.DeleteAll();
        TuLine(1, 10, 'L1');
        TuLine(2, 10, 'L2');
        TuLine(3, 20, 'L3');
        TuLine(4, 40, 'L4');
        TuItem(11, 1, 'A', 2);
        TuItem(12, 1, 'B', 1);
        TuItem(13, 3, 'C', 5);
        TuItem(14, 4, 'D', 1);
        TuSlot(101, 11, Slot.Kind::Reservation, 7001);
        TuSlot(102, 11, Slot.Kind::Reservation, 7002);
        TuSlot(103, 11, Slot.Kind::Admitted, 7003);
        TuSlot(104, 14, Slot.Kind::Reservation, 7004);
        TuSlot(105, 12, Slot.Kind::Admitted, 7005);
        TuSlot(106, 13, Slot.Kind::Reservation, 7006);
    end;

    local procedure TuLine(EntryNo: Integer; HeadNo: Integer; ExtCode: Code[20])
    var
        Line: Record "LT TU XP Line";
    begin
        Line."Entry No." := EntryNo;
        Line.HeadNo := HeadNo;
        Line.ExtCode := ExtCode;
        Line.Insert();
    end;

    local procedure TuItem(EntryNo: Integer; LineNo: Integer; ItemCode: Code[20]; Qty: Integer)
    var
        Item: Record "LT TU XP Item";
    begin
        Item."Entry No." := EntryNo;
        Item.LineNo := LineNo;
        Item.ItemCode := ItemCode;
        Item.Qty := Qty;
        Item.Insert();
    end;

    local procedure TuSlot(EntryNo: Integer; ItemNo: Integer; Kind: Option; ExtNo: Integer)
    var
        Slot: Record "LT TU XP Slot";
    begin
        Slot."Entry No." := EntryNo;
        Slot.ItemNo := ItemNo;
        Slot.Kind := Kind;
        Slot.ExtNo := ExtNo;
        Slot.Insert();
    end;

    local procedure TuTemp(Mode: Integer; Outers: Text; Mids: Text; Inners: Text; var Log: Text): Text
    var
        Port: XmlPort "LT TU XP Nested Temp";
        Parts: List of [Text];
        Part: Text;
        Id: Integer;
        Parent: Integer;
    begin
        // Outers: 'id,id'; Mids and Inners: 'id:parent,id:parent'
        Port.SetMode(Mode);
        if Outers <> '' then
            foreach Part in Outers.Split(',') do begin
                Evaluate(Id, Part);
                Port.AddOuter(Id);
            end;
        if Mids <> '' then
            foreach Part in Mids.Split(',') do begin
                Parts := Part.Split(':');
                Evaluate(Id, Parts.Get(1));
                Evaluate(Parent, Parts.Get(2));
                Port.AddMid(Id, Parent);
            end;
        if Inners <> '' then
            foreach Part in Inners.Split(',') do begin
                Parts := Part.Split(':');
                Evaluate(Id, Parts.Get(1));
                Evaluate(Parent, Parts.Get(2));
                Port.AddInner(Id, Parent);
            end;
        Part := TuExportTemp(Port);
        Log := Port.GetLog();
        exit(Part);
    end;

    [TryFunction]
    local procedure TuTryFormatTime(Value: Time; Length: Integer; FormatString: Text; var Result: Text)
    begin
        Result := Format(Value, Length, FormatString);
    end;

    [TryFunction]
    local procedure TuTryFormatDateTime(Value: DateTime; Length: Integer; FormatString: Text; var Result: Text)
    begin
        Result := Format(Value, Length, FormatString);
    end;

    local procedure TuFormatTime(Value: Time; Length: Integer; FormatString: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TuTryFormatTime(Value, Length, FormatString, Result) then
            exit('[' + Result + ']');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    local procedure TuFormatDateTime(Value: DateTime; Length: Integer; FormatString: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TuTryFormatDateTime(Value, Length, FormatString, Result) then
            exit('[' + Result + ']');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    local procedure TuExportTimes(XmlPortId: Integer): Text
    var
        Row: Record "PW FE Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Row.DeleteAll();
        TuTimeRow(1, 123456.789T);
        TuTimeRow(2, 123456.78T);
        TuTimeRow(3, 123456.007T);
        TuTimeRow(4, 000000.001T);
        TuTimeRow(5, 235959.999T);
        TuTimeRow(6, 0T);
        TuTimeRow(7, 123456.5T);
        TuTimeRow(8, 000000T);
        Commit();
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(XmlPortId, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure TuTimeRow(NewId: Integer; NewTime: Time)
    var
        Row: Record "PW FE Table";
    begin
        Row.Id := NewId;
        Row.Tm := NewTime;
        if NewTime <> 0T then
            Row.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), NewTime);
        Row.Insert();
    end;

    local procedure TuExportTimesTemp(): Text
    var
        Port: XmlPort "LT TU XP Time Temp";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Port.AddRow(1, 123456.789T);
        Port.AddRow(2, 123456.78T);
        Port.AddRow(3, 123456.007T);
        Port.AddRow(4, 000000.001T);
        Port.AddRow(5, 235959.999T);
        Port.AddRow(6, 0T);
        Port.AddRow(7, 123456.5T);
        Port.AddRow(8, 000000T);
        Port.AddRow(9, 123456.1T);
        Port.AddRow(10, 123456.01T);
        TempBlob.CreateOutStream(OutStr);
        Port.SetDestination(OutStr);
        Port.Export();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure TU_LinkedKey_NoChange()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: nothing. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(0, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_NoChange_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_NoChange_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_NoChange_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtFirstPass()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: SetCurrentKey(B) at pass 1 only. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(1, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtFirstPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtFirstPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtFirstPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyDescendingAtFirstPass()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: SetCurrentKey(B) and Ascending(false) at pass 1 only. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(2, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_KeyDescendingAtFirstPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyDescendingAtFirstPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyDescendingAtFirstPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtSecondPass()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: SetCurrentKey(B) at pass 2 only. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(3, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtSecondPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtSecondPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtSecondPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_ResetAtFirstPass()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: Reset at pass 1 only. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(4, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_ResetAtFirstPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_ResetAtFirstPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_ResetAtFirstPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtEveryPass()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: SetCurrentKey(B) at every pass. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(5, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtEveryPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtEveryPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_KeyAtEveryPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_DescendingAtFirstPass()
    var
        XmlOnce: Text;
        LogOnce: Text;
        XmlUnbounded: Text;
        LogUnbounded: Text;
    begin
        Observer.Discard();
        // Three parent rows; OnPreXmlItem of `c` (SourceTableView sorting(A)) and `d` (no view) does: Ascending(false) at pass 1 only. Child rows: Id 1,2,3; by A 2,3,1; by B 3,1,2
        TuKeyRun(6, XmlOnce, LogOnce, XmlUnbounded, LogUnbounded);
        Observer.Observe('xml once', XmlOnce);
        Observer.Observe('log once', LogOnce);
        Observer.Observe('xml unbounded', XmlUnbounded);
        Observer.Observe('log unbounded', LogUnbounded);
        Observer.Finish();
    end;

    [Test]
    procedure TU_LinkedKey_DescendingAtFirstPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_DescendingAtFirstPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_LinkedKey_DescendingAtFirstPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_Np()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // every OnPreXmlItem sets its filters; order Ref 10: line 1 with items 11 (2 reservations, 1 admitted) and 12 (admitted only), line 2 without items
        TuSeedReal();
        Port.SetHead(1, 10, 'ORD-10');
        Port.SetResponse('OK', '');
        Port.SetMode(0);
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_Np_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_Np_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_Np_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_ItemNoFilter()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // `item` sets no filter in OnPreXmlItem: unlinked, it sees every item row at each line
        TuSeedReal();
        Port.SetHead(1, 10, 'ORD-10');
        Port.SetResponse('OK', '');
        Port.SetMode(1);
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_ItemNoFilter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_ItemNoFilter_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_ItemNoFilter_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_ItemFilterFirstPass()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // `item` sets its filter at its first pass only: does the filter stay at the second line?
        TuSeedReal();
        Port.SetHead(1, 10, 'ORD-10');
        Port.SetResponse('OK', '');
        Port.SetMode(2);
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_ItemFilterFirstPass_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_ItemFilterFirstPass_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_ItemFilterFirstPass_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_SlotNoFilter()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // `slot` sets no filter (MaxOccurs = Once: the first slot row of the table at each item)
        TuSeedReal();
        Port.SetHead(1, 10, 'ORD-10');
        Port.SetResponse('OK', '');
        Port.SetMode(3);
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_SlotNoFilter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_SlotNoFilter_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_SlotNoFilter_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_OneEach()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // order Ref 40: one line, one item, one slot
        TuSeedReal();
        Port.SetHead(1, 40, 'ORD-40');
        Port.SetResponse('OK', '');
        Port.SetMode(0);
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_OneEach_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_OneEach_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_OneEach_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_NoLines()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // order Ref 30 has no line: the default-occurs `Line` without rows, `item` (MinOccurs = Once) below it
        TuSeedReal();
        Port.SetHead(1, 30, 'BAD');
        Port.SetResponse('ERROR', 'Invalid token');
        Port.SetMode(0);
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_NoLines_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_NoLines_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_NoLines_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_NoOrder()
    var
        Port: XmlPort "LT TU XP Nested Real";
    begin
        Observer.Discard();
        // no row in the temporary `Order` (MinOccurs = Zero): only the response texts
        TuSeedReal();
        Port.SetResponse('ERROR', 'Nothing');
        Observer.Observe('xml', TuExportReal(Port));
        Observer.Observe('log', Port.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedReal_NoOrder_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_NoOrder_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedReal_NoOrder_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_None()
    var
        Log: Text;
    begin
        Observer.Discard();
        // no row at any level
        Observer.Observe('xml', TuTemp(0, '', '', '', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_None_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_None_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_None_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneOuter()
    var
        Log: Text;
    begin
        Observer.Discard();
        // one outer row, no mid row (MinOccurs = Once), no inner row
        Observer.Observe('xml', TuTemp(0, '1', '', '', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_OneOuter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneOuter_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneOuter_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneOneNone()
    var
        Log: Text;
    begin
        Observer.Discard();
        // one outer, one mid, no inner
        Observer.Observe('xml', TuTemp(0, '1', '11:1', '', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_OneOneNone_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneOneNone_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneOneNone_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneEach()
    var
        Log: Text;
    begin
        Observer.Discard();
        // one row at each level
        Observer.Observe('xml', TuTemp(0, '1', '11:1', '21:11', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_OneEach_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneEach_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneEach_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneTwoTwo()
    var
        Log: Text;
    begin
        Observer.Discard();
        // one outer, two mids, two inners (MaxOccurs = Once)
        Observer.Observe('xml', TuTemp(0, '1', '11:1,12:1', '21:11,22:12', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_OneTwoTwo_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneTwoTwo_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_OneTwoTwo_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwo()
    var
        Log: Text;
    begin
        Observer.Discard();
        // two rows at each level, no filters: every outer row writes every mid row
        Observer.Observe('xml', TuTemp(0, '1,2', '11:1,12:2', '21:11,22:12', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwo_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwo_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwo_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwoFiltered()
    var
        Log: Text;
    begin
        Observer.Discard();
        // two rows at each level, OnPreXmlItem filters on the parent; both inner rows under mid 11
        Observer.Observe('xml', TuTemp(1, '1,2', '11:1,12:2', '21:11,22:11', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwoFiltered_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwoFiltered_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoTwoFiltered_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoNoneTwo()
    var
        Log: Text;
    begin
        Observer.Discard();
        // two outer rows, no mid row, two inner rows
        Observer.Observe('xml', TuTemp(0, '1,2', '', '21:11,22:12', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_TwoNoneTwo_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoNoneTwo_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoNoneTwo_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoNoneFiltered()
    var
        Log: Text;
    begin
        Observer.Discard();
        // filtered: outer 2 has no mid row (MinOccurs = Once)
        Observer.Observe('xml', TuTemp(1, '1,2', '11:1,12:1', '', Log));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoNoneFiltered_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoNoneFiltered_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_NestedTemp_TwoTwoNoneFiltered_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_Time_Format_CodeNames()
    var
        Unused: Text;
    begin
        Observer.Discard();
        // Format of a Time with code names with a length: <Hours,2> (not Hours24/Hours12), unknown names, and the Length argument 8.
        // Each value is [text] or 'error: <text> | <code>'.
        Unused := '';
        Observer.Observe('0905 <Hours>', TuFormatTime(090503.007T, 0, '<Hours>'));
        Observer.Observe('1345 <Hours>', TuFormatTime(134506.078T, 0, '<Hours>'));
        Observer.Observe('0905 len8 <Hours>', TuFormatTime(090503.007T, 8, '<Hours>'));
        Observer.Observe('0905 <Hours,2>', TuFormatTime(090503.007T, 0, '<Hours,2>'));
        Observer.Observe('1345 <Hours,2>', TuFormatTime(134506.078T, 0, '<Hours,2>'));
        Observer.Observe('0905 len8 <Hours,2>', TuFormatTime(090503.007T, 8, '<Hours,2>'));
        Observer.Observe('0905 <Hours,1>', TuFormatTime(090503.007T, 0, '<Hours,1>'));
        Observer.Observe('1345 <Hours,1>', TuFormatTime(134506.078T, 0, '<Hours,1>'));
        Observer.Observe('0905 len8 <Hours,1>', TuFormatTime(090503.007T, 8, '<Hours,1>'));
        Observer.Observe('0905 <Hours,3>', TuFormatTime(090503.007T, 0, '<Hours,3>'));
        Observer.Observe('1345 <Hours,3>', TuFormatTime(134506.078T, 0, '<Hours,3>'));
        Observer.Observe('0905 len8 <Hours,3>', TuFormatTime(090503.007T, 8, '<Hours,3>'));
        Observer.Observe('0905 <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 0, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('1345 <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(134506.078T, 0, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 len8 <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 <Hour>', TuFormatTime(090503.007T, 0, '<Hour>'));
        Observer.Observe('1345 <Hour>', TuFormatTime(134506.078T, 0, '<Hour>'));
        Observer.Observe('0905 len8 <Hour>', TuFormatTime(090503.007T, 8, '<Hour>'));
        Observer.Observe('0905 <Minute>', TuFormatTime(090503.007T, 0, '<Minute>'));
        Observer.Observe('1345 <Minute>', TuFormatTime(134506.078T, 0, '<Minute>'));
        Observer.Observe('0905 len8 <Minute>', TuFormatTime(090503.007T, 8, '<Minute>'));
        Observer.Observe('0905 <Second>', TuFormatTime(090503.007T, 0, '<Second>'));
        Observer.Observe('1345 <Second>', TuFormatTime(134506.078T, 0, '<Second>'));
        Observer.Observe('0905 len8 <Second>', TuFormatTime(090503.007T, 8, '<Second>'));
        Observer.Observe('0905 <Hours24,2>', TuFormatTime(090503.007T, 0, '<Hours24,2>'));
        Observer.Observe('1345 <Hours24,2>', TuFormatTime(134506.078T, 0, '<Hours24,2>'));
        Observer.Observe('0905 len8 <Hours24,2>', TuFormatTime(090503.007T, 8, '<Hours24,2>'));
        Observer.Observe('0905 <Hours12>', TuFormatTime(090503.007T, 0, '<Hours12>'));
        Observer.Observe('1345 <Hours12>', TuFormatTime(134506.078T, 0, '<Hours12>'));
        Observer.Observe('0905 len8 <Hours12>', TuFormatTime(090503.007T, 8, '<Hours12>'));
        Observer.Observe('0905 <Thousands>', TuFormatTime(090503.007T, 0, '<Thousands>'));
        Observer.Observe('1345 <Thousands>', TuFormatTime(134506.078T, 0, '<Thousands>'));
        Observer.Observe('0905 len8 <Thousands>', TuFormatTime(090503.007T, 8, '<Thousands>'));
        Observer.Observe('0905 <AM/PM>', TuFormatTime(090503.007T, 0, '<AM/PM>'));
        Observer.Observe('1345 <AM/PM>', TuFormatTime(134506.078T, 0, '<AM/PM>'));
        Observer.Observe('0905 len8 <AM/PM>', TuFormatTime(090503.007T, 8, '<AM/PM>'));
        Observer.Observe('0905 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('1345 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(134506.078T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 len8 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 8, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', TuFormatTime(090503.007T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('1345 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', TuFormatTime(134506.078T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('0905 len8 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', TuFormatTime(090503.007T, 8, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('0905 <HOURS,2>', TuFormatTime(090503.007T, 0, '<HOURS,2>'));
        Observer.Observe('1345 <HOURS,2>', TuFormatTime(134506.078T, 0, '<HOURS,2>'));
        Observer.Observe('0905 len8 <HOURS,2>', TuFormatTime(090503.007T, 8, '<HOURS,2>'));
        Observer.Observe('midnight <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(000000T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0T <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(0T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('len5 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503T, 5, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('dt <Hours,2>', TuFormatDateTime(CreateDateTime(DMY2Date(5, 3, 2024), 090503T), 0, '<Hours,2>'));
        Observer.Observe('dt <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatDateTime(CreateDateTime(DMY2Date(5, 3, 2024), 090503T), 0, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 <Ho>', TuFormatTime(090503.007T, 0, '<Ho>'));
        Observer.Observe('0905 <H>', TuFormatTime(090503.007T, 0, '<H>'));
        Observer.Observe('0905 <Min>', TuFormatTime(090503.007T, 0, '<Min>'));
        Observer.Observe('0905 <Sec>', TuFormatTime(090503.007T, 0, '<Sec>'));
        Observer.Observe('0905 <Thou>', TuFormatTime(090503.007T, 0, '<Thou>'));
        Observer.Observe('0905 <Hourz>', TuFormatTime(090503.007T, 0, '<Hourz>'));
        Observer.Observe('0905 <Hours24x,2>', TuFormatTime(090503.007T, 0, '<Hours24x,2>'));
        Observer.Observe('0905 <Hours 24>', TuFormatTime(090503.007T, 0, '<Hours 24>'));
        Observer.Observe('0905 <Hours,0>', TuFormatTime(090503.007T, 0, '<Hours,0>'));
        Observer.Observe('0905 <hours,2>', TuFormatTime(090503.007T, 0, '<hours,2>'));
        Observer.Observe('0905 len8 time()-like ms', TuFormatTime(090503.457T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('2359 len8', TuFormatTime(235959.999T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Finish();
    end;

    [Test]
    procedure TU_Time_Format_CodeNames_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_Time_Format_CodeNames_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_Time_Format_CodeNames_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_Export_TimeMilliseconds()
    var
        Unused: Text;
    begin
        Observer.Discard();
        // Rows with Time 12:34:56.789, .78, .007, 00:00:00.001, 23:59:59.999, 0T, .5 and 00:00:00, exported with FormatEvaluate = Xml and Legacy
        Unused := '';
        Observer.Observe('export_xml', TuExportTimes(Xmlport::"PW FE Xml"));
        Observer.Observe('export_legacy', TuExportTimes(Xmlport::"PW FE Legacy"));
        Observer.Observe('export_xml_temporary', TuExportTimesTemp());
        Observer.Finish();
    end;

    [Test]
    procedure TU_Export_TimeMilliseconds_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_Export_TimeMilliseconds_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TU_Export_TimeMilliseconds_More3()
    begin
        Observer.More();
    end;
}
