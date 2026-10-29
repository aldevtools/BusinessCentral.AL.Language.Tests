codeunit 90099 "LT TS XP Probe"
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

    local procedure TrExportBooking(var Port: XmlPort "LT TR XP Booking"): Text
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

    local procedure TrExportMember(var Port: XmlPort "LT TR XP Member Reply"): Text
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

    // Writer TS (NP lane, 2026-10-29): objects 90080-90087 (TsXpObjects.al). A second Export on the same xmlport instance (which rows each
    // export writes, what the table elements' records hold, SourceTableView and filters, after a record assignment, TransferFields or Init in
    // between, SystemId); a linked table element with an explicit MaxOccurs = Unbounded next to the same port without it; a container text
    // element with the default MinOccurs/MaxOccurs over an unlinked temporary table element; MinOccurs = Once on the root text element; import
    // of Guid values with FormatEvaluate = Xml.
    local procedure TsExportAgain(var Port: XmlPort "LT TS XP Booking Again"): Text
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

    local procedure TsSetupAgain(var Port: XmlPort "LT TS XP Booking Again")
    begin
        // lines 1 and 3 get no parts; line 2 gets ZOO (Entry No. 1, Kind Open) and SHOW (Entry No. 2, Kind Timed); SPARE belongs to no line
        Port.SetResult(1, 'T9');
        Port.AddLine(10, 1);
        Port.AddLine(20, 2);
        Port.AddLine(30, 3);
        Port.AddPart(1, 2, 'ZOO', 2, 'Zoo');
        Port.AddPart(2, 2, 'SHOW', 1, 'Show');
        Port.AddPart(9, 9, 'SPARE', 3, 'Spare');
    end;

    local procedure TsExportUnbounded(var Port: XmlPort "LT TS XP Linked Unbounded"): Text
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

    local procedure TsExportLinked(var Port: XmlPort "LT TS XP Linked Default"): Text
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

    local procedure TsExportCards(var Port: XmlPort "LT TS XP Cards Default"): Text
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

    local procedure TsExportRootOnce(var Port: XmlPort "LT TS XP Root Once"): Text
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

    local procedure TsExportGuid(var Port: XmlPort "LT TS XP Guid"): Text
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

    local procedure TsImport(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; Body: Text)
    var
        Runner: Codeunit "LT TS XP Runner";
    begin
        Runner.SetInput(Mode, '<?xml version="1.0" encoding="UTF-8"?>' + Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure TS_Again_SameData()
    var
        Port: XmlPort "LT TS XP Booking Again";
    begin
        Observer.Discard();
        // two exports on one instance with no change in between
        TsSetupAgain(Port);
        Observer.Observe('source sid null', Port.SourceSidNull());
        Observer.Observe('before', Port.State());
        Observer.Observe('export 1', TsExportAgain(Port));
        Observer.Observe('export 1 log', Port.GetLog());
        Observer.Observe('after 1', Port.State());
        Port.ClearLog();
        Observer.Observe('export 2', TsExportAgain(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after 2', Port.State());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_SameData_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_SameData_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_SameData_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_AssignBetween()
    var
        Port: XmlPort "LT TS XP Booking Again";
        Fresh: XmlPort "LT TS XP Booking Again";
    begin
        Observer.Discard();
        // the Part record is assigned from the SPARE row between the exports; Fresh: assigned before its first export
        TsSetupAgain(Port);
        Observer.Observe('export 1', TsExportAgain(Port));
        Port.AssignPart(9);
        Observer.Observe('assigned', Port.State());
        Port.ClearLog();
        Observer.Observe('export 2', TsExportAgain(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after 2', Port.State());
        TsSetupAgain(Fresh);
        Fresh.AssignPart(9);
        Observer.Observe('fresh export', TsExportAgain(Fresh));
        Observer.Observe('fresh log', Fresh.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_AssignBetween_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_AssignBetween_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_AssignBetween_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TransferFieldsBetween()
    var
        Port: XmlPort "LT TS XP Booking Again";
    begin
        Observer.Discard();
        // the Part record is filled with TransferFields(SPARE row, true) between the exports
        TsSetupAgain(Port);
        Observer.Observe('export 1', TsExportAgain(Port));
        Port.TransferPart(9);
        Observer.Observe('transferred', Port.State());
        Port.ClearLog();
        Observer.Observe('export 2', TsExportAgain(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after 2', Port.State());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_TransferFieldsBetween_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TransferFieldsBetween_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TransferFieldsBetween_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_InitBetween()
    var
        Port: XmlPort "LT TS XP Booking Again";
    begin
        Observer.Discard();
        // Init on the Part record between the exports
        TsSetupAgain(Port);
        Observer.Observe('export 1', TsExportAgain(Port));
        Port.InitPart();
        Observer.Observe('init', Port.State());
        Port.ClearLog();
        Observer.Observe('export 2', TsExportAgain(Port));
        Observer.Observe('after 2', Port.State());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_InitBetween_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_InitBetween_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_InitBetween_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_KeyBetween()
    var
        Port: XmlPort "LT TS XP Booking Again";
    begin
        Observer.Discard();
        // SetCurrentKey("Entry No.") on the Part record between the exports: does the second export sort by SourceTableView (Kind) again
        TsSetupAgain(Port);
        Observer.Observe('export 1', TsExportAgain(Port));
        Port.SetPartKeyEntryNo();
        Observer.Observe('key set', Port.State());
        Port.ClearLog();
        Observer.Observe('export 2', TsExportAgain(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after 2', Port.State());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_KeyBetween_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_KeyBetween_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_KeyBetween_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_LineFilter()
    var
        Before: XmlPort "LT TS XP Booking Again";
        Between: XmlPort "LT TS XP Booking Again";
    begin
        Observer.Discard();
        // SetRange(Ref, 2) on the line record (no SourceTableView) before the first export, and between two exports
        TsSetupAgain(Before);
        Before.SetLineFilter(2);
        Observer.Observe('filter before', TsExportAgain(Before));
        Observer.Observe('filter before log', Before.GetLog());
        Observer.Observe('filter before after', Before.State());
        TsSetupAgain(Between);
        Observer.Observe('export 1', TsExportAgain(Between));
        Between.SetLineFilter(2);
        Between.ClearLog();
        Observer.Observe('export 2', TsExportAgain(Between));
        Observer.Observe('export 2 log', Between.GetLog());
        Observer.Observe('after 2', Between.State());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_LineFilter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_LineFilter_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_LineFilter_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TrBooking()
    var
        Port: XmlPort "LT TR XP Booking";
    begin
        Observer.Discard();
        // xmlport 90064: line 1 has no parts, line 2 has ZOO; the same instance exported twice
        Port.SetResult(1, 'T9', true, 'OK');
        Port.AddLine(10, 1, true, '');
        Port.AddLine(20, 2, true, '');
        Port.AddPart(1, 2, 'ZOO', 501, 2, 12.5, 'Zoo entrance');
        Observer.Observe('export 1', TrExportBooking(Port));
        Observer.Observe('export 1 log', Port.GetLog());
        Port.ClearLog();
        Observer.Observe('export 2', TrExportBooking(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Observer.Observe('after', Port.ResultMessage());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_TrBooking_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TrBooking_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TrBooking_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TrMember()
    var
        Port: XmlPort "LT TR XP Member Reply";
    begin
        Observer.Discard();
        // xmlport 90065: two cards (MaxOccurs = Once), exported twice; a card that sorts first is added before the third export
        Port.AddResponse(5, 'M-100', 'ann@example.com');
        Port.AddCard(1, 'CARD-1', DMY2Date(31, 12, 2027));
        Port.AddCard(2, 'CARD-2', 0D);
        Observer.Observe('export 1', TrExportMember(Port));
        Observer.Observe('export 1 log', Port.GetLog());
        Port.ClearLog();
        Observer.Observe('export 2', TrExportMember(Port));
        Observer.Observe('export 2 log', Port.GetLog());
        Port.ClearLog();
        Port.AddCard(0, 'CARD-0', 0D);
        Observer.Observe('export 3', TrExportMember(Port));
        Observer.Observe('export 3 log', Port.GetLog());
        Observer.Observe('after', Port.Response());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Again_TrMember_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TrMember_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Again_TrMember_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export()
    var
        Unbounded: XmlPort "LT TS XP Linked Unbounded";
        Linked: XmlPort "LT TS XP Linked Default";
        UnboundedXml: Text;
        LinkedXml: Text;
    begin
        Observer.Discard();
        // tickets 1, 2, 3 with 0, 1 and 2 linked items, item X linked to no ticket; explicit MaxOccurs = Unbounded and the default side by side
        Unbounded.AddHead(1, 'T1');
        Unbounded.AddHead(2, 'T2');
        Unbounded.AddHead(3, 'T3');
        Unbounded.AddItem(1, 2, 'A', 1);
        Unbounded.AddItem(2, 3, 'B', 2);
        Unbounded.AddItem(3, 3, 'C', 3);
        Unbounded.AddItem(4, 7, 'X', 9);
        Linked.AddHead(1, 'T1');
        Linked.AddHead(2, 'T2');
        Linked.AddHead(3, 'T3');
        Linked.AddItem(1, 2, 'A', 1);
        Linked.AddItem(2, 3, 'B', 2);
        Linked.AddItem(3, 3, 'C', 3);
        Linked.AddItem(4, 7, 'X', 9);
        UnboundedXml := TsExportUnbounded(Unbounded);
        LinkedXml := TsExportLinked(Linked);
        Observer.Observe('unbounded', UnboundedXml);
        Observer.Observe('unbounded log', Unbounded.GetLog());
        Observer.Observe('same xml', Format(UnboundedXml = LinkedXml));
        Observer.Observe('same log', Format(Unbounded.GetLog() = Linked.GetLog()));
        Observer.Finish();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_NoRows()
    var
        Unbounded: XmlPort "LT TS XP Linked Unbounded";
        Linked: XmlPort "LT TS XP Linked Default";
    begin
        Observer.Discard();
        Observer.Observe('unbounded', TsExportUnbounded(Unbounded));
        Observer.Observe('default', TsExportLinked(Linked));
        Observer.Finish();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_NoRows_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_NoRows_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Export_NoRows_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Import()
    var
    begin
        Observer.Discard();
        // the same documents into the explicit-Unbounded port (1) and the default port (2)
        TsImport(Observer, 'unbounded 0/1/2', 1, '<confirm><ticket no="1"><token>T1</token></ticket><ticket no="2"><token>T2</token><item info="i-a"><code>A</code><qty>1</qty><note>na</note></item></ticket><ticket no="3"><token>T3</token><item info="i-b"><code>B</code><qty>2</qty><note>nb</note></item><item info="i-c"><code>C</code><qty>3</qty><note>nc</note></item></ticket></confirm>');
        TsImport(Observer, 'default 0/1/2', 2, '<confirm><ticket no="1"><token>T1</token></ticket><ticket no="2"><token>T2</token><item info="i-a"><code>A</code><qty>1</qty><note>na</note></item></ticket><ticket no="3"><token>T3</token><item info="i-b"><code>B</code><qty>2</qty><note>nb</note></item><item info="i-c"><code>C</code><qty>3</qty><note>nc</note></item></ticket></confirm>');
        TsImport(Observer, 'unbounded no tickets', 1, '<confirm />');
        TsImport(Observer, 'unbounded item missing note', 1, '<confirm><ticket no="1"><token>T1</token><item info="i-a"><code>A</code><qty>1</qty></item></ticket></confirm>');
        TsImport(Observer, 'default item missing note', 2, '<confirm><ticket no="1"><token>T1</token><item info="i-a"><code>A</code><qty>1</qty></item></ticket></confirm>');
        Observer.Finish();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Import_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Import_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Linked_Unbounded_Import_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Cards_DefaultOccurs_Export()
    var
        NoReply: XmlPort "LT TS XP Cards Default";
        NoCard: XmlPort "LT TS XP Cards Default";
        OneCard: XmlPort "LT TS XP Cards Default";
        TwoCards: XmlPort "LT TS XP Cards Default";
    begin
        Observer.Discard();
        // the text element cards (default MinOccurs/MaxOccurs) over an unlinked temporary table element (MaxOccurs = Once, MinOccurs = Zero)
        Observer.Observe('no reply', TsExportCards(NoReply));
        Observer.Observe('no reply log', NoReply.GetLog());
        NoCard.AddResponse(5, 'M-100', 'ann@example.com');
        Observer.Observe('no card', TsExportCards(NoCard));
        Observer.Observe('no card log', NoCard.GetLog());
        OneCard.AddResponse(5, 'M-100', 'ann@example.com');
        OneCard.AddCard(1, 'CARD-1', DMY2Date(31, 12, 2027));
        Observer.Observe('one card', TsExportCards(OneCard));
        Observer.Observe('one card log', OneCard.GetLog());
        TwoCards.AddResponse(5, 'M-100', 'ann@example.com');
        TwoCards.AddCard(1, 'CARD-1', DMY2Date(31, 12, 2027));
        TwoCards.AddCard(2, 'CARD-2', 0D);
        Observer.Observe('two cards', TsExportCards(TwoCards));
        Observer.Observe('two cards log', TwoCards.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TS_Cards_DefaultOccurs_Export_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Cards_DefaultOccurs_Export_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Cards_DefaultOccurs_Export_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_RootOnce_Export()
    var
        Empty: XmlPort "LT TS XP Root Once";
        Filled: XmlPort "LT TS XP Root Once";
    begin
        Observer.Discard();
        Observer.Observe('empty', TsExportRootOnce(Empty));
        Observer.Observe('empty log', Empty.GetLog());
        Filled.SetToken('C1');
        Filled.AddTicket(1, 'ADULT', 2);
        Filled.AddTicket(2, 'CHILD', 1);
        Observer.Observe('filled', TsExportRootOnce(Filled));
        Observer.Observe('filled log', Filled.GetLog());
        Observer.Finish();
    end;

    [Test]
    procedure TS_RootOnce_Export_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_RootOnce_Export_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_RootOnce_Export_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_RootOnce_Import()
    var
    begin
        Observer.Discard();
        TsImport(Observer, 'full', 3, '<changerequest><token>C1</token><ticket code="ADULT" qty="2"/><ticket code="CHILD" qty="1"/></changerequest>');
        TsImport(Observer, 'token only', 3, '<changerequest><token>C1</token></changerequest>');
        TsImport(Observer, 'empty root', 3, '<changerequest />');
        TsImport(Observer, 'open-close root', 3, '<changerequest></changerequest>');
        TsImport(Observer, 'other root', 3, '<other><token>C1</token></other>');
        TsImport(Observer, 'no root', 3, '');
        Observer.Finish();
    end;

    [Test]
    procedure TS_RootOnce_Import_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_RootOnce_Import_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_RootOnce_Import_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Import_Element()
    var
    begin
        Observer.Discard();
        // a Guid field element, FormatEvaluate = Xml
        TsImport(Observer, 'braces upper', 4, '<guids><row no="1"><g>{5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B}</g></row></guids>');
        TsImport(Observer, 'braces lower', 4, '<guids><row no="1"><g>{5a2f6c9e-1b3d-4e8f-9a0b-1c2d3e4f5a6b}</g></row></guids>');
        TsImport(Observer, 'plain upper', 4, '<guids><row no="1"><g>5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B</g></row></guids>');
        TsImport(Observer, 'plain lower', 4, '<guids><row no="1"><g>5a2f6c9e-1b3d-4e8f-9a0b-1c2d3e4f5a6b</g></row></guids>');
        TsImport(Observer, 'mixed case', 4, '<guids><row no="1"><g>5a2F6c9E-1b3D-4e8F-9a0B-1c2D3e4F5a6B</g></row></guids>');
        TsImport(Observer, 'digits only', 4, '<guids><row no="1"><g>5A2F6C9E1B3D4E8F9A0B1C2D3E4F5A6B</g></row></guids>');
        TsImport(Observer, 'parentheses', 4, '<guids><row no="1"><g>(5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B)</g></row></guids>');
        TsImport(Observer, 'surrounding spaces', 4, '<guids><row no="1"><g> 5a2f6c9e-1b3d-4e8f-9a0b-1c2d3e4f5a6b </g></row></guids>');
        TsImport(Observer, 'null guid', 4, '<guids><row no="1"><g>00000000-0000-0000-0000-000000000000</g></row></guids>');
        TsImport(Observer, 'empty open-close', 4, '<guids><row no="1"><g></g></row></guids>');
        TsImport(Observer, 'empty self-closing', 4, '<guids><row no="1"><g /></row></guids>');
        TsImport(Observer, 'missing', 4, '<guids><row no="1"/></guids>');
        TsImport(Observer, 'invalid', 4, '<guids><row no="1"><g>not-a-guid</g></row></guids>');
        TsImport(Observer, 'one digit short', 4, '<guids><row no="1"><g>5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6</g></row></guids>');
        Observer.Finish();
    end;

    [Test]
    procedure TS_Guid_Import_Element_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Import_Element_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Import_Element_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Import_Attribute()
    var
    begin
        Observer.Discard();
        // a Guid field attribute, FormatEvaluate = Xml
        TsImport(Observer, 'braces upper', 4, '<guids><row no="1" ga="{5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B}"/></guids>');
        TsImport(Observer, 'plain lower', 4, '<guids><row no="1" ga="5a2f6c9e-1b3d-4e8f-9a0b-1c2d3e4f5a6b"/></guids>');
        TsImport(Observer, 'digits only', 4, '<guids><row no="1" ga="5A2F6C9E1B3D4E8F9A0B1C2D3E4F5A6B"/></guids>');
        TsImport(Observer, 'empty', 4, '<guids><row no="1" ga=""/></guids>');
        TsImport(Observer, 'invalid', 4, '<guids><row no="1" ga="not-a-guid"/></guids>');
        Observer.Finish();
    end;

    [Test]
    procedure TS_Guid_Import_Attribute_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Import_Attribute_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Import_Attribute_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Export()
    var
        Port: XmlPort "LT TS XP Guid";
        Known: Guid;
        Null: Guid;
    begin
        Observer.Discard();
        Known := '{5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B}';
        Port.AddRow(1, Known, Null);
        Port.AddRow(2, Null, Known);
        Observer.Observe('xml', TsExportGuid(Port));
        Observer.Finish();
    end;

    [Test]
    procedure TS_Guid_Export_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Export_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TS_Guid_Export_More3()
    begin
        Observer.More();
    end;
}
