// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
// Scope: in-scope
// Fixtures used: own table 90080, xmlports 90081-90086 and 90088, runner codeunit 90087 (writer TS); tables 90060-90063 and xmlports 90064-90065
//   (TrXpReplyObjects.al); the temporary blob table 87279 (QrXpContainerOccurs.al); tests TS_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: FACTS_PLACEHOLDER
// Objects:
//   90081 "LT TS XP Booking Again": the reply part of a reply port: a temporary table element (MaxOccurs = Once, MinOccurs = Zero) > field
//     element + text element `details` (MinOccurs = Zero, MaxOccurs = Once) > temporary table element `line` with no link (MinOccurs = Zero)
//     > text element `parts` (MinOccurs = Zero, MaxOccurs = Once) > temporary table element `Part` with no link (MinOccurs = Once,
//     MaxOccurs = Unbounded, SourceTableView sorted by a secondary key) of field attributes and a text attribute with the end of the
//     record's SystemId (each source row has a fixed SystemId that ends in its Entry No.). The OnAfterGetRecord of
//     `line` empties `Part` and fills it from a source table (record assignment + Insert). Procedures between two Export calls on the same
//     instance assign the Part record, fill it with TransferFields(From, true), Init it, change its key, or filter the line table.
//   90082 "LT TS XP Linked Unbounded": a temporary table element > linked temporary table element (LinkTable, MinOccurs = Zero and an
//     explicit MaxOccurs = Unbounded) with a text attribute, a leaf field element with OnBeforePassField and a leaf text element with
//     OnBeforePassVariable. 90083 "LT TS XP Linked Default" is the same port without the explicit MaxOccurs.
//   90084 "LT TS XP Cards Default": a temporary table element (MaxOccurs = Once, MinOccurs = Zero) > two leaf field elements + text element
//     `cards` with the default MinOccurs and MaxOccurs > temporary table element `card` with no link (MaxOccurs = Once, MinOccurs = Zero)
//     of field elements.
//   90085 "LT TS XP Root Once": the root text element has an explicit MinOccurs = Once.
//   90086 "LT TS XP Guid": FormatEvaluate = Xml, a Guid field as field element and as field attribute.
//   90088 "LT TS XP View Again": a temporary table element with SourceTableView = sorting(Kind) where(Qty = filter(> 0)); procedures set
//     a key, filters or Reset on its record before or between Export calls.
//   90087 "LT TS XP Runner": runs an import of 90082, 90083, 90085 or 90086 inside Codeunit.Run, so a failed import does not end the test.
// BC versions: 27, 28, 29

table 90080 "LT TS XP Guid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; G; Guid) { }
        field(3; G2; Guid) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

xmlport 90081 "LT TS XP Booking Again"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(bookings)
        {
            MaxOccurs = Once;
            tableelement(result; "LT TR XP Result")
            {
                XmlName = 'results';
                MaxOccurs = Once;
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(token; result.Token)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                }
                textelement(details)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    tableelement(detail; "LT TR XP Result")
                    {
                        XmlName = 'line';
                        MinOccurs = Zero;
                        UseTemporary = true;
                        fieldattribute(line_no; detail.Ref)
                        {
                        }
                        textelement(parts)
                        {
                            MaxOccurs = Once;
                            MinOccurs = Zero;
                            tableelement(part; "LT TR XP Part")
                            {
                                XmlName = 'Part';
                                UseTemporary = true;
                                MinOccurs = Once;
                                MaxOccurs = Unbounded;
                                SourceTableView = sorting(Kind);
                                fieldattribute(PartNo; part."Entry No.")
                                {
                                    XmlName = 'No';
                                }
                                fieldattribute(PartCode; part.Code)
                                {
                                    XmlName = 'Code';
                                }
                                fieldattribute(PartDesc; part.Description)
                                {
                                    XmlName = 'Desc';
                                }
                                textattribute(sid)
                                {
                                    XmlName = 'Sid';

                                    trigger OnBeforePassVariable()
                                    begin
                                        Log += 'pass sid;';
                                        sid := SidState(part);
                                    end;
                                }

                                trigger OnAfterGetRecord()
                                begin
                                    Log += 'get part ' + part.Code + ';';
                                end;
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Log += 'get line ' + Format(detail.Ref) + ';';
                            part.DeleteAll();
                            FillParts(detail.Ref);
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get result ' + result.Token + ';';
                end;
            }
        }
    }

    var
        PartSource: Record "LT TR XP Part" temporary;
        Log: Text;

    local procedure FillParts(LineRef: Integer)
    begin
        PartSource.SetRange(Ref, LineRef);
        if PartSource.FindSet() then
            repeat
                part := PartSource;
                part.Insert();
            until PartSource.Next() = 0;
        PartSource.Reset();
    end;

    local procedure SidState(var Row: Record "LT TR XP Part" temporary): Text
    begin
        // 'null', or the last 12 digits of the SystemId (AddPart gives row N the SystemId ending in N)
        if IsNullGuid(Row.SystemId) then
            exit('null');
        exit(CopyStr(Format(Row.SystemId), 26, 12));
    end;

    procedure AddPart(EntryNo: Integer; LineRef: Integer; NewCode: Code[20]; NewKind: Option; NewDescription: Text[50])
    begin
        PartSource.Init();
        PartSource."Entry No." := EntryNo;
        PartSource.Ref := LineRef;
        PartSource.Code := NewCode;
        PartSource.Kind := NewKind;
        PartSource.Description := NewDescription;
        // a fixed SystemId per row ({00000000-0000-0000-0000-0000000000<EntryNo>}), so the Sid attribute shows which row a record's SystemId came from
        Evaluate(PartSource.SystemId, '{00000000-0000-0000-0000-' + Format(EntryNo, 0, '<Integer,12><Filler Character,0>') + '}');
        PartSource.Insert(false, true);
    end;

    procedure AddLine(EntryNo: Integer; LineRef: Integer)
    begin
        detail.Init();
        detail."Entry No." := EntryNo;
        detail.Ref := LineRef;
        detail.Insert();
    end;

    procedure SetResult(EntryNo: Integer; NewToken: Text[30])
    begin
        result.Init();
        result."Entry No." := EntryNo;
        result.Token := NewToken;
        result.Insert();
    end;

    procedure AssignPart(EntryNo: Integer)
    begin
        PartSource.Get(EntryNo);
        part := PartSource;
    end;

    procedure TransferPart(EntryNo: Integer)
    begin
        PartSource.Get(EntryNo);
        part.TransferFields(PartSource, true);
    end;

    procedure InitPart()
    begin
        part.Init();
    end;

    procedure SetPartKeyEntryNo()
    begin
        part.SetCurrentKey("Entry No.");
    end;

    procedure SetLineFilter(LineRef: Integer)
    begin
        detail.SetRange(Ref, LineRef);
    end;

    procedure SourceSid(): Text
    begin
        PartSource.FindFirst();
        exit(Format(PartSource.SystemId));
    end;

    procedure State(): Text
    begin
        exit('result=' + result.Token + ' line=' + Format(detail.Ref) + ' part=' + Format(part."Entry No.") + ':' + part.Code + '/' + SidState(part) +
            ' parts=' + Format(part.Count()) + ' partview=' + part.GetView(false) + ' lineview=' + detail.GetView(false) + ' resultview=' + result.GetView(false));
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure ClearLog()
    begin
        Log := '';
    end;
}

xmlport 90082 "LT TS XP Linked Unbounded"
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
            tableelement(head; "LT TR XP Result")
            {
                XmlName = 'ticket';
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(no; head."Entry No.")
                {
                }
                fieldelement(token; head.Token)
                {
                    trigger OnBeforePassField()
                    begin
                        Log += 'pass token ' + head.Token + ';';
                    end;
                }
                tableelement(line; "LT TR XP Part")
                {
                    XmlName = 'item';
                    LinkTable = head;
                    LinkFields = Ref = field("Entry No.");
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    UseTemporary = true;
                    textattribute(info)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass info;';
                            info := line.Code + '#' + Format(line.Qty);
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'info=' + info + ';';
                        end;
                    }
                    fieldelement(code; line.Code)
                    {
                        trigger OnBeforePassField()
                        begin
                            Log += 'pass code;';
                        end;
                    }
                    fieldelement(qty; line.Qty)
                    {
                        trigger OnBeforePassField()
                        begin
                            Log += 'pass qty;';
                        end;
                    }
                    textelement(note)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass note;';
                            note := 'n' + Format(line."Entry No.");
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'note=' + note + ';';
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'get item ' + line.Code + ';';
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        ItemCount += 1;
                        line."Entry No." := ItemCount;
                        Log += 'insert item ' + line.Code + ' ref=' + Format(line.Ref) + ';';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ticket ' + Format(head."Entry No.") + ';';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ticket ' + Format(head."Entry No.") + ';';
                end;
            }
        }
    }

    var
        Log: Text;
        ItemCount: Integer;

    procedure AddHead(EntryNo: Integer; NewToken: Text[30])
    begin
        head.Init();
        head."Entry No." := EntryNo;
        head.Token := NewToken;
        head.Insert();
    end;

    procedure AddItem(EntryNo: Integer; HeadNo: Integer; NewCode: Code[20]; NewQty: Integer)
    begin
        line.Init();
        line."Entry No." := EntryNo;
        line.Ref := HeadNo;
        line.Code := NewCode;
        line.Qty := NewQty;
        line.Insert();
    end;

    procedure Rows() Result: Text
    begin
        head.Reset();
        if head.FindSet() then
            repeat
                Result += 'ticket ' + Format(head."Entry No.") + '/' + head.Token + ';';
            until head.Next() = 0;
        line.Reset();
        if line.FindSet() then
            repeat
                Result += 'item ' + Format(line."Entry No.") + '/' + Format(line.Ref) + '/' + line.Code + '/' + Format(line.Qty) + ';';
            until line.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90083 "LT TS XP Linked Default"
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
            tableelement(head; "LT TR XP Result")
            {
                XmlName = 'ticket';
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(no; head."Entry No.")
                {
                }
                fieldelement(token; head.Token)
                {
                    trigger OnBeforePassField()
                    begin
                        Log += 'pass token ' + head.Token + ';';
                    end;
                }
                tableelement(line; "LT TR XP Part")
                {
                    XmlName = 'item';
                    LinkTable = head;
                    LinkFields = Ref = field("Entry No.");
                    MinOccurs = Zero;
                    UseTemporary = true;
                    textattribute(info)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass info;';
                            info := line.Code + '#' + Format(line.Qty);
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'info=' + info + ';';
                        end;
                    }
                    fieldelement(code; line.Code)
                    {
                        trigger OnBeforePassField()
                        begin
                            Log += 'pass code;';
                        end;
                    }
                    fieldelement(qty; line.Qty)
                    {
                        trigger OnBeforePassField()
                        begin
                            Log += 'pass qty;';
                        end;
                    }
                    textelement(note)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass note;';
                            note := 'n' + Format(line."Entry No.");
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'note=' + note + ';';
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'get item ' + line.Code + ';';
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        ItemCount += 1;
                        line."Entry No." := ItemCount;
                        Log += 'insert item ' + line.Code + ' ref=' + Format(line.Ref) + ';';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ticket ' + Format(head."Entry No.") + ';';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ticket ' + Format(head."Entry No.") + ';';
                end;
            }
        }
    }

    var
        Log: Text;
        ItemCount: Integer;

    procedure AddHead(EntryNo: Integer; NewToken: Text[30])
    begin
        head.Init();
        head."Entry No." := EntryNo;
        head.Token := NewToken;
        head.Insert();
    end;

    procedure AddItem(EntryNo: Integer; HeadNo: Integer; NewCode: Code[20]; NewQty: Integer)
    begin
        line.Init();
        line."Entry No." := EntryNo;
        line.Ref := HeadNo;
        line.Code := NewCode;
        line.Qty := NewQty;
        line.Insert();
    end;

    procedure Rows() Result: Text
    begin
        head.Reset();
        if head.FindSet() then
            repeat
                Result += 'ticket ' + Format(head."Entry No.") + '/' + head.Token + ';';
            until head.Next() = 0;
        line.Reset();
        if line.FindSet() then
            repeat
                Result += 'item ' + Format(line."Entry No.") + '/' + Format(line.Ref) + '/' + line.Code + '/' + Format(line.Qty) + ';';
            until line.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90084 "LT TS XP Cards Default"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(members)
        {
            MaxOccurs = Once;
            tableelement(reply; "LT TR XP Member")
            {
                XmlName = 'response';
                MaxOccurs = Once;
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(membernumber; reply.MemberNo)
                {
                }
                fieldelement(email; reply.Email)
                {
                }
                textelement(cards)
                {
                    tableelement(card; "LT TR XP Card")
                    {
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        UseTemporary = true;
                        fieldelement(cardnumber; card.CardNo)
                        {
                        }
                        fieldelement(expirydate; card.ValidUntil)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Log += 'get card ' + card.CardNo + ';';
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get reply ' + reply.MemberNo + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddResponse(EntryNo: Integer; NewMemberNo: Code[20]; NewEmail: Text[80])
    begin
        reply.Init();
        reply."Entry No." := EntryNo;
        reply.MemberNo := NewMemberNo;
        reply.Email := NewEmail;
        reply.Insert();
    end;

    procedure AddCard(EntryNo: Integer; NewCardNo: Text[50]; NewValidUntil: Date)
    begin
        card.Init();
        card."Entry No." := EntryNo;
        card.CardNo := NewCardNo;
        card.ValidUntil := NewValidUntil;
        card.Insert();
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90085 "LT TS XP Root Once"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(changerequest)
        {
            MinOccurs = Once;
            textelement(token)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;
            }
            tableelement(ticket; "LT TR XP Part")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(code; ticket.Code)
                {
                }
                fieldattribute(qty; ticket.Qty)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ticket ' + ticket.Code + ';';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    TicketCount += 1;
                    ticket."Entry No." := TicketCount;
                    Log += 'insert ticket ' + ticket.Code + ';';
                end;
            }
        }
    }

    var
        Log: Text;
        TicketCount: Integer;

    procedure AddTicket(EntryNo: Integer; NewCode: Code[20]; NewQty: Integer)
    begin
        ticket.Init();
        ticket."Entry No." := EntryNo;
        ticket.Code := NewCode;
        ticket.Qty := NewQty;
        ticket.Insert();
    end;

    procedure SetToken(NewToken: Text)
    begin
        token := NewToken;
    end;

    procedure Rows() Result: Text
    begin
        Result := 'token=' + token + ' log=' + Log + ' rows=';
        ticket.Reset();
        if ticket.FindSet() then
            repeat
                Result += Format(ticket."Entry No.") + ':' + ticket.Code + '/' + Format(ticket.Qty) + ';';
            until ticket.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90086 "LT TS XP Guid"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(guids)
        {
            MaxOccurs = Once;
            tableelement(row; "LT TS XP Guid Row")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(no; row."Entry No.")
                {
                }
                fieldattribute(ga; row.G2)
                {
                    Occurrence = Optional;
                }
                fieldelement(g; row.G)
                {
                    MinOccurs = Zero;
                }
            }
        }
    }

    procedure AddRow(EntryNo: Integer; NewG: Guid; NewG2: Guid)
    begin
        row.Init();
        row."Entry No." := EntryNo;
        row.G := NewG;
        row.G2 := NewG2;
        row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        row.Reset();
        if row.FindSet() then
            repeat
                Result += Format(row."Entry No.") + ':g=' + Format(row.G) + ' ga=' + Format(row.G2) + ';';
            until row.Next() = 0;
    end;
}

xmlport 90088 "LT TS XP View Again"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(rows)
        {
            MaxOccurs = Once;
            tableelement(row; "LT TR XP Part")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                SourceTableView = sorting(Kind) where(Qty = filter(> 0));
                fieldattribute(no; row."Entry No.")
                {
                }
                fieldattribute(code; row.Code)
                {
                }
            }
        }
    }

    procedure AddRow(EntryNo: Integer; NewCode: Code[20]; NewKind: Option; NewQty: Integer)
    begin
        row.Init();
        row."Entry No." := EntryNo;
        row.Code := NewCode;
        row.Kind := NewKind;
        row.Qty := NewQty;
        row.Insert();
    end;

    procedure SetKeyEntryNo()
    begin
        row.SetCurrentKey("Entry No.");
    end;

    procedure SetCodeFilter(NewFilter: Text)
    begin
        row.SetFilter(Code, NewFilter);
    end;

    procedure SetQtyRange(FromQty: Integer; ToQty: Integer)
    begin
        row.SetRange(Qty, FromQty, ToQty);
    end;

    procedure ResetRow()
    begin
        row.Reset();
    end;

    procedure View(): Text
    begin
        exit(row.GetView(false) + ' count=' + Format(row.Count()));
    end;
}

codeunit 90087 "LT TS XP Runner"
{
    // Imports Input into xmlport 90082 (Mode 1), 90083 (2), 90085 (3) or 90086 (4) inside Codeunit.Run, so a failed import does not end
    // the test. Result gives the rows (and the log) the import made.
    var
        Input: Text;
        Mode: Integer;
        Outcome: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Unbounded: XmlPort "LT TS XP Linked Unbounded";
        Linked: XmlPort "LT TS XP Linked Default";
        RootOnce: XmlPort "LT TS XP Root Once";
        Guids: XmlPort "LT TS XP Guid";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        case Mode of
            1:
                begin
                    Unbounded.SetSource(InS);
                    Unbounded.Import();
                    Outcome := Unbounded.Rows() + ' log=' + Unbounded.GetLog();
                end;
            2:
                begin
                    Linked.SetSource(InS);
                    Linked.Import();
                    Outcome := Linked.Rows() + ' log=' + Linked.GetLog();
                end;
            3:
                begin
                    RootOnce.SetSource(InS);
                    RootOnce.Import();
                    Outcome := RootOnce.Rows();
                end;
            4:
                begin
                    Guids.SetSource(InS);
                    Guids.Import();
                    Outcome := Guids.Rows();
                end;
        end;
    end;

    procedure SetInput(NewMode: Integer; NewInput: Text)
    begin
        Mode := NewMode;
        Input := NewInput;
        Outcome := '';
    end;

    procedure Result(): Text
    begin
        exit(Outcome);
    end;
}
