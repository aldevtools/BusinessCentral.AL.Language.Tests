// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-xmlport-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method
// Scope: in-scope
// Fixtures used: own tables 90100-90102, xmlports 90103-90106, runner codeunit 90107 (writer TT); table 90060 "LT TR XP Result" and 90061
//   "LT TR XP Part" (TrXpReplyObjects.al); the temporary blob table 87279 (QrXpContainerOccurs.al); tests TT_* in codeunit 87280
//   (QrXpContainerOccurs.al)
// Probe: observed on the BC 29.0 SaaS sandbox (two runs, same values); every literal asserted in the TT_* tests is what it produced. Other
//   versions: corpus CI matrix (Linux 27.5, 28.5, 29.0).
// Facts (BC 29):
//   LinkTable without LinkFields adds no filter to the child record (the child sees no link filter in OnPreXmlItem; only what OnPreXmlItem
//   sets limits the rows). SourceTableView filters sit in a filter group GetFilters does not show, but Count obeys them. A Reset in
//   OnPreXmlItem removes the SourceTableView filters AND its key (the rows then come in primary key order). MaxOccurs = Once writes the
//   first row only; MinOccurs = Zero with no row writes nothing (OnAfterGetRecord does not run). OnPreXmlItem of a nested table element
//   runs once per parent row, after the parent's OnAfterGetRecord and its leaf fields and before the child's rows. A text element (MinOccurs
//   = Zero) inside a table element is always written with its text attributes (OnBeforePassVariable runs), also when the nested
//   MinOccurs = Once table element below it has no row: that element is then written once, empty (fields of the empty record, its text
//   attributes empty, OnAfterGetRecord not run).
//   Import twice on one instance: the second Import reads nothing and inserts nothing; only OnPreXmlPort and OnPostXmlPort run again (not
//   OnInitXmlPort). This holds for the same source, for SetSource on the same stream again and for SetSource on a NEW stream with other
//   rows, with and without Codeunit.Run around it. A first Import reads the whole document even when the stream was read to its end before
//   SetSource; after an Import the source InStream does not report EOS.
//   An optional (MinOccurs = Zero) table element without rows runs only its OnPreXmlItem (no OnBeforePassField / OnBeforePassVariable, no
//   element written). A required (default MinOccurs) one without rows runs OnPreXmlItem and then OnBeforePassField / OnBeforePassVariable of
//   its fields for the empty record and writes it once (no OnAfterGetRecord).
// Objects:
//   90103 "LT TT XP Confirm Reply": a reply port. Optional text element `results` > temporary table element `reply` (no link) > table element
//     `ticket` over a real table, LinkTable = reply WITHOUT LinkFields, MaxOccurs = Unbounded, whose OnPreXmlItem sets its filter from the
//     reply row > table element `admission` (LinkTable + LinkFields, MaxOccurs = Unbounded) > table element `reservation`, LinkTable =
//     admission WITHOUT LinkFields, MaxOccurs = Once, MinOccurs = Zero, SourceTableView sorted by a secondary key with a WHERE on an option
//     field, an OnPreXmlItem and an OnAfterGetRecord that fills text attributes. SetDetailMode chooses what the OnPreXmlItem of
//     `reservation` does: 0 = Reset, then filters on the link field, the option field and Qty > 0; 1 = Reset, then the link field and
//     Qty > 0 only (no option filter); 2 = nothing (only the log).
//   90104 "LT TT XP Change Reply": a temporary table element `Result` (MinOccurs = Zero, MaxOccurs = Once) > text element `ExpiresAt` with a
//     text attribute (OnBeforePassVariable) + text element `Ticket` (MinOccurs = Zero, MaxOccurs = Once) with a required text attribute
//     set before the export and a text attribute with OnBeforePassVariable, holding text element `Admissions` (MinOccurs = Zero,
//     MaxOccurs = Once) > temporary table element `Admission` with no link (MinOccurs = Once, MaxOccurs = Unbounded).
//   90105 "LT TT XP Import Twice": a temporary table element of a field attribute and a field element, with logging triggers; imported
//     twice on one instance.
//   90106 "LT TT XP Optional Unlinked": an optional (MinOccurs = Zero) and a required (default MinOccurs) unlinked temporary table element,
//     each with a field attribute, a field element and a text element whose triggers log; exported with no rows.
//   90107 "LT TT XP Import Runner": holds one instance of 90105; FirstImport imports directly, OnRun runs the second step inside
//     Codeunit.Run, so a failed second import does not end the test.
// BC versions: 27, 28, 29

table 90100 "LT TT XP Ticket"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; ReqNo; Integer) { }
        field(3; ExtNo; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90101 "LT TT XP Access"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; TicketNo; Integer) { }
        field(3; AdmCode; Code[20]) { }
        field(4; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90102 "LT TT XP Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; AccessNo; Integer) { }
        field(3; Kind; Option) { OptionMembers = " ",Admitted,Reservation; }
        field(4; Qty; Integer) { }
        field(5; ExtSched; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByAccess; AccessNo, Kind, Qty) { }
    }
}

xmlport 90103 "LT TT XP Confirm Reply"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(tickets)
        {
            MaxOccurs = Once;
            textelement(results)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;
                tableelement(reply; "LT TR XP Result")
                {
                    XmlName = 'reply';
                    MinOccurs = Zero;
                    UseTemporary = true;
                    textelement(status)
                    {
                        MinOccurs = Once;
                        MaxOccurs = Once;

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass status;';
                            status := Format(reply.Status, 0, 9);
                        end;
                    }
                    fieldelement(order_uid; reply.Token)
                    {
                    }
                    tableelement(ticket; "LT TT XP Ticket")
                    {
                        XmlName = 'ticket';
                        LinkTable = reply;
                        MinOccurs = Zero;
                        MaxOccurs = Unbounded;
                        textattribute(line_no)
                        {
                            Occurrence = Required;
                        }
                        fieldelement(ticket_uid; ticket.ExtNo)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;

                            trigger OnBeforePassField()
                            begin
                                Log += 'pass uid ' + ticket.ExtNo + ';';
                            end;
                        }
                        textelement(valid_from)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;

                            trigger OnBeforePassVariable()
                            begin
                                Log += 'pass valid;';
                                valid_from := 'V-' + ticket.ExtNo;
                            end;
                        }
                        tableelement(access; "LT TT XP Access")
                        {
                            XmlName = 'admission';
                            LinkTable = ticket;
                            LinkFields = TicketNo = field("Entry No.");
                            MinOccurs = Zero;
                            MaxOccurs = Unbounded;
                            fieldattribute(code; access.AdmCode)
                            {
                            }
                            fieldelement(quantity; access.Qty)
                            {
                                MinOccurs = Zero;
                                MaxOccurs = Once;
                            }
                            tableelement(detail; "LT TT XP Detail")
                            {
                                XmlName = 'reservation';
                                LinkTable = access;
                                MinOccurs = Zero;
                                MaxOccurs = Once;
                                SourceTableView = sorting(AccessNo, Kind, Qty) where(Kind = const(Reservation));
                                fieldattribute(external_id; detail.ExtSched)
                                {
                                }
                                textattribute(start)
                                {
                                    Occurrence = Optional;
                                }
                                textattribute(finish)
                                {
                                    Occurrence = Optional;
                                }

                                trigger OnPreXmlItem()
                                begin
                                    Log += 'pre detail a' + Format(access."Entry No.") + ' filters=' + detail.GetFilters() + ' count=' + Format(detail.Count());
                                    case DetailMode of
                                        0:
                                            begin
                                                detail.Reset();
                                                detail.SetFilter(AccessNo, '=%1', access."Entry No.");
                                                detail.SetFilter(Kind, '=%1', detail.Kind::Reservation);
                                                detail.SetFilter(Qty, '>%1', 0);
                                            end;
                                        1:
                                            begin
                                                detail.Reset();
                                                detail.SetFilter(AccessNo, '=%1', access."Entry No.");
                                                detail.SetFilter(Qty, '>%1', 0);
                                            end;
                                    end;
                                    Log += ' then count=' + Format(detail.Count()) + ';';
                                end;

                                trigger OnAfterGetRecord()
                                begin
                                    Log += 'get detail ' + Format(detail."Entry No.") + ';';
                                    start := 'S' + Format(detail."Entry No.");
                                    finish := 'F' + Format(detail.Qty);
                                end;
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Log += 'get access ' + Format(access."Entry No.") + ';';
                            end;
                        }

                        trigger OnPreXmlItem()
                        begin
                            Log += 'pre ticket filters=' + ticket.GetFilters() + ';';
                            ticket.SetFilter(ReqNo, '=%1', -2);
                            if (reply.Ref <> 0) and reply.Status then
                                ticket.SetFilter(ReqNo, '=%1', reply.Ref);
                        end;

                        trigger OnAfterGetRecord()
                        begin
                            Log += 'get ticket ' + Format(ticket."Entry No.") + ';';
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'get reply ' + Format(reply."Entry No.") + ';';
                        line_no := Format(reply.Ref, 0, 9);
                    end;
                }
            }
        }
    }

    var
        Log: Text;
        DetailMode: Integer;

    procedure AddReply(EntryNo: Integer; Ref: Integer; Confirmed: Boolean; NewToken: Text[30])
    begin
        reply.Init();
        reply."Entry No." := EntryNo;
        reply.Ref := Ref;
        reply.Status := Confirmed;
        reply.Token := NewToken;
        reply.Insert();
    end;

    procedure SetDetailMode(NewMode: Integer)
    begin
        DetailMode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90104 "LT TT XP Change Reply"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Tickets)
        {
            MinOccurs = Once;
            MaxOccurs = Once;
            tableelement(res; "LT TR XP Result")
            {
                XmlName = 'Result';
                UseTemporary = true;
                MinOccurs = Zero;
                MaxOccurs = Once;
                textelement(ResponseCode)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(ExpiresAt)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    textattribute(ExpiresUtc)
                    {
                        XmlName = 'UTC';

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass utc;';
                            ExpiresUtc := 'U' + Format(res."Entry No.");
                        end;
                    }
                }
                textelement(Ticket)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    textattribute(ChangeToken)
                    {
                        XmlName = 'ChangeRequestToken';
                        Occurrence = Required;
                    }
                    textattribute(TicketKind)
                    {
                        XmlName = 'Kind';
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass kind;';
                            TicketKind := 'K' + ChangeToken;
                        end;
                    }
                    textelement(Admissions)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                        tableelement(chg; "LT TR XP Part")
                        {
                            XmlName = 'Admission';
                            UseTemporary = true;
                            MinOccurs = Once;
                            MaxOccurs = Unbounded;
                            fieldattribute(Code; chg.Code)
                            {
                                Occurrence = Required;
                            }
                            textelement(ScheduleEntry)
                            {
                                fieldattribute(EntryNo; chg.ExtNo)
                                {
                                    XmlName = 'ExternalEntryNo';
                                    Occurrence = Required;
                                }
                                textattribute(ReservationType)
                                {
                                    Occurrence = Required;
                                }
                            }
                            textelement(AdmissionDescription)
                            {
                                MinOccurs = Once;
                                MaxOccurs = Once;
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Log += 'get admission ' + chg.Code + ';';
                                ReservationType := 'Open';
                                if chg.ExtNo <> 0 then
                                    ReservationType := 'Reservation';
                                AdmissionDescription := chg.Description;
                            end;
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get result ' + Format(res."Entry No.") + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure SetChange(Token: Text; Rows: Integer)
    var
        i: Integer;
    begin
        res.DeleteAll();
        ChangeToken := Token;
        res.Init();
        res."Entry No." := 1;
        res.Token := CopyStr(Token, 1, 30);
        res.Insert();
        for i := 1 to Rows do begin
            chg.Init();
            chg."Entry No." := i;
            chg.Code := 'ADM-' + Format(i);
            chg.ExtNo := (i - 1) * 100;
            chg.Description := 'Admission ' + Format(i);
            chg.Insert();
        end;
        ResponseCode := 'OK';
    end;

    procedure SetError(Message: Text)
    begin
        res.DeleteAll();
        res.Init();
        res."Entry No." := 1;
        res.Message := CopyStr(Message, 1, 50);
        res.Insert();
        ResponseCode := 'ERROR';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90105 "LT TT XP Import Twice"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(points)
        {
            MaxOccurs = Once;
            tableelement(pt; "LT TR XP Part")
            {
                XmlName = 'point';
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(no; pt."Entry No.")
                {
                }
                fieldelement(code; pt.Code)
                {
                    trigger OnAfterAssignField()
                    begin
                        Log += 'code=' + pt.Code + ';';
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ' + Format(pt."Entry No.") + ';';
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        Log += 'init;';
    end;

    trigger OnPreXmlPort()
    begin
        Log += 'pre;';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post;';
    end;

    var
        Log: Text;

    procedure Rows() Result: Text
    begin
        pt.Reset();
        if pt.FindSet() then
            repeat
                Result += Format(pt."Entry No.") + '/' + pt.Code + ';';
            until pt.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90106 "LT TT XP Optional Unlinked"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(confirm)
        {
            MaxOccurs = Once;
            tableelement(opt; "LT TR XP Result")
            {
                XmlName = 'optional';
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(no; opt."Entry No.")
                {
                    trigger OnBeforePassField()
                    begin
                        Log += 'pass opt no;';
                    end;
                }
                fieldelement(token; opt.Token)
                {
                    trigger OnBeforePassField()
                    begin
                        Log += 'pass opt token;';
                    end;
                }
                textelement(optnote)
                {
                    XmlName = 'note';

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass opt note;';
                        optnote := 'n' + Format(opt."Entry No.");
                    end;
                }

                trigger OnPreXmlItem()
                begin
                    Log += 'pre opt;';
                end;

                trigger OnAfterGetRecord()
                begin
                    Log += 'get opt;';
                end;
            }
            tableelement(req; "LT TR XP Result")
            {
                XmlName = 'required';
                UseTemporary = true;
                fieldattribute(no; req."Entry No.")
                {
                    trigger OnBeforePassField()
                    begin
                        Log += 'pass req no;';
                    end;
                }
                fieldelement(token; req.Token)
                {
                    trigger OnBeforePassField()
                    begin
                        Log += 'pass req token;';
                    end;
                }
                textelement(reqnote)
                {
                    XmlName = 'note';

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass req note;';
                        reqnote := 'n' + Format(req."Entry No.");
                    end;
                }

                trigger OnPreXmlItem()
                begin
                    Log += 'pre req;';
                end;

                trigger OnAfterGetRecord()
                begin
                    Log += 'get req;';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

codeunit 90107 "LT TT XP Import Runner"
{
    // Holds one instance of xmlport 90105. FirstImport imports Input directly. OnRun does the second step inside Codeunit.Run:
    // Mode 1 = Import again (source unchanged), 2 = SetSource on a new stream with Input2, then Import, 3 = SetSource on the first,
    // already read stream again, then Import, 4 = on a fresh instance: a new stream with Input2 read to its end first, then SetSource and
    // Import.
    var
        Port: XmlPort "LT TT XP Import Twice";
        Buffer: Record "LT QR XP Blob" temporary;
        InS: InStream;
        Mode: Integer;
        Input2: Text;

    trigger OnRun()
    var
        Buffer2: Record "LT QR XP Blob" temporary;
        OutS: OutStream;
        InS2: InStream;
        Line: Text;
    begin
        case Mode of
            1:
                Port.Import();
            2:
                begin
                    Buffer2.Id := 2;
                    Buffer2.Data.CreateOutStream(OutS, TextEncoding::UTF8);
                    OutS.WriteText(Input2);
                    Buffer2.Insert();
                    Buffer2.CalcFields(Data);
                    Buffer2.Data.CreateInStream(InS2, TextEncoding::UTF8);
                    Port.SetSource(InS2);
                    Port.Import();
                end;
            3:
                begin
                    Port.SetSource(InS);
                    Port.Import();
                end;
            4:
                begin
                    Buffer2.Id := 2;
                    Buffer2.Data.CreateOutStream(OutS, TextEncoding::UTF8);
                    OutS.WriteText(Input2);
                    Buffer2.Insert();
                    Buffer2.CalcFields(Data);
                    Buffer2.Data.CreateInStream(InS2, TextEncoding::UTF8);
                    while not InS2.EOS() do
                        InS2.ReadText(Line);
                    Port.SetSource(InS2);
                    Port.Import();
                end;
        end;
    end;

    procedure FirstImport(Input: Text)
    var
        OutS: OutStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
    end;

    procedure SetSecond(NewMode: Integer; NewInput2: Text)
    begin
        Mode := NewMode;
        Input2 := NewInput2;
    end;

    procedure SourceAtEnd(): Text
    begin
        exit(Format(InS.EOS()));
    end;

    procedure Rows(): Text
    begin
        exit(Port.Rows());
    end;

    procedure GetLog(): Text
    begin
        exit(Port.GetLog());
    end;
}
