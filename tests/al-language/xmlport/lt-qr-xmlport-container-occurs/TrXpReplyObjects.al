// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: own tables 90060-90063, xmlports 90064-90066, runner codeunit 90067 (writer TR); the temporary blob table 87279
//   (QrXpContainerOccurs.al); tests TR_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: observed on the BC 29.0 SaaS sandbox (the Windows 29.0 container was down); every literal asserted in the TR_* tests is what it
//   produced. Other versions: corpus CI matrix (Linux 27.5, 28.5, 29.0).
// Facts (BC 29): an unlinked temporary table element inside a text element writes the rows its table holds when the element is reached, so
//   an outer row's OnAfterGetRecord that empties and refills it gives each outer row its own inner rows (sorted by SourceTableView).
//   A table element with MinOccurs = Once and no rows still writes one element from its record variable as it is (empty before any read,
//   else the last row read, with the globals the earlier rows left); its OnAfterGetRecord does not run, its children's OnBeforePassVariable
//   do. A table element with MaxOccurs = Once and two rows writes only the first. MinOccurs = Zero with no rows: element left out, an
//   optional text element around it is written empty (`<details />`, `<addmember />`). An empty Required text attribute is written as
//   `Type=""`, an empty Optional one is left out; an Optional Decimal field attribute writes `0.00`. Trigger order per row:
//   OnAfterGetRecord, then text attributes, then child text elements (`pass unitprice;pass kind_is;pass kind_id;`: element before its attribute).
//   Import: `<x />` runs a leaf text element's OnAfterAssignVariable twice, `<x></x>`, `<x> </x>` and `<x>v</x>` once; a field element's
//   OnAfterAssignField and a container's OnAfterAssignVariable run once for both forms.
// Objects:
//   90064 "LT TR XP Booking": a request/reply port (UseDefaultNamespace). The request part (a required text element with a required text
//     attribute over a temporary table element of field attributes) is imported, then the same instance exports it together with the reply:
//     a temporary table element (MaxOccurs = Once, MinOccurs = Zero) > leaf text element + field elements + text element `details`
//     (MinOccurs = Zero, MaxOccurs = Once, no triggers) > temporary table element `line` with NO link to the reply (MinOccurs = Zero) with
//     field attributes and text attributes set in OnBeforePassVariable + text element `parts` (MinOccurs = Zero, MaxOccurs = Once) >
//     temporary table element `Part` with no link (MinOccurs = Once, MaxOccurs = Unbounded, SourceTableView sorted by a secondary key) >
//     field attribute, text element `Slot` (a field attribute, 8 text attributes, an inner text element `kind_is` with only a text attribute,
//     both with OnBeforePassVariable), leaf text element `Description` (MinOccurs = Once). The OnAfterGetRecord of `line` empties `Part`
//     and fills it from a source table for that line, as reply ports commonly do.
//   90065 "LT TR XP Member Reply": request part (temporary table element, MaxOccurs = Once, MinOccurs = Zero) and reply part: temporary table
//     element (MaxOccurs = Once, MinOccurs = Zero) > text attribute with OnBeforePassVariable, leaf text elements set from outside, text
//     element `member` (MaxOccurs = Once, MinOccurs = Zero) > 2 field elements + temporary table element `card` with no link (MaxOccurs =
//     Once, MinOccurs = Zero) of field elements.
//   90066 "LT TR XP Empty Leaf": import of empty leaf elements written as `<x />` and as `<x></x>`: a leaf text element below the root, and
//     below a table element a field element, a leaf text element and a leaf text element inside a text element; every
//     OnAfterAssignVariable / OnAfterAssignField logs, so the log counts how often each runs.
// BC versions: 27, 28, 29

table 90060 "LT TR XP Result"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Integer) { }
        field(3; Status; Boolean) { }
        field(4; Message; Text[50]) { }
        field(5; Token; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90061 "LT TR XP Part"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Integer) { }
        field(3; Code; Code[20]) { }
        field(4; ExtNo; Integer) { }
        field(5; Kind; Option) { OptionMembers = " ",Timed,Open,Skipped; }
        field(6; Amount; Decimal) { }
        field(7; Description; Text[50]) { }
        field(8; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByKind; Kind) { }
    }
}

table 90062 "LT TR XP Member"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; MemberNo; Code[20]) { }
        field(3; FirstName; Text[50]) { }
        field(4; Email; Text[80]) { }
        field(5; Store; Code[10]) { }
        field(6; GuardianNo; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90063 "LT TR XP Card"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; CardNo; Text[50]) { }
        field(3; ValidUntil; Date) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

xmlport 90064 "LT TR XP Booking"
{
    Format = Xml;
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(bookings)
        {
            MaxOccurs = Once;
            textelement(request)
            {
                MaxOccurs = Once;
                MinOccurs = Once;
                textattribute(token)
                {
                    Occurrence = Required;
                }
                tableelement(ticket; "LT TR XP Part")
                {
                    UseTemporary = true;
                    fieldattribute(code; ticket.Code)
                    {
                    }
                    fieldattribute(line_no; ticket.Ref)
                    {
                    }
                    fieldattribute(qty; ticket.Qty)
                    {
                    }
                    fieldattribute(amount; ticket.Amount)
                    {
                        Occurrence = Optional;
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        TicketCount += 1;
                        ticket."Entry No." := TicketCount;
                        Log += 'insert ticket ' + ticket.Code + ';';
                    end;
                }
            }
            tableelement(result; "LT TR XP Result")
            {
                XmlName = 'results';
                MaxOccurs = Once;
                MinOccurs = Zero;
                UseTemporary = true;
                textelement(state)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass state;';
                        state := Format(result.Status, 0, 9);
                    end;
                }
                fieldelement(token; result.Token)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                }
                fieldelement(message; result.Message)
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
                        fieldattribute(status; detail.Status)
                        {
                        }
                        fieldattribute(message; detail.Message)
                        {
                        }
                        textattribute(price)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log += 'pass price;';
                                price := Format(LinePrice, 0, 9);
                            end;
                        }
                        textattribute(quantity)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log += 'pass quantity;';
                                quantity := Format(LineQuantity, 0, 9);
                            end;
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
                                fieldattribute(PartCode; part.Code)
                                {
                                    XmlName = 'Code';
                                    Occurrence = Required;
                                }
                                textelement(slot)
                                {
                                    XmlName = 'Slot';
                                    fieldattribute(ExtNo; part.ExtNo)
                                    {
                                        XmlName = 'ExtNo';
                                        Occurrence = Required;
                                    }
                                    textattribute(slottype)
                                    {
                                        XmlName = 'Type';
                                        Occurrence = Required;
                                    }
                                    textattribute(slotdate)
                                    {
                                        XmlName = 'Date';
                                        Occurrence = Optional;
                                    }
                                    textattribute(starttime)
                                    {
                                        XmlName = 'StartTime';
                                        Occurrence = Optional;
                                    }
                                    textattribute(endtime)
                                    {
                                        XmlName = 'EndTime';
                                        Occurrence = Optional;
                                    }
                                    textattribute(validfrom)
                                    {
                                        XmlName = 'ValidFrom';
                                        Occurrence = Optional;
                                    }
                                    textattribute(validuntil)
                                    {
                                        XmlName = 'ValidUntil';
                                        Occurrence = Optional;
                                    }
                                    textattribute(canmove)
                                    {
                                        XmlName = 'CanMove';
                                        Occurrence = Required;
                                    }
                                    textattribute(unitprice)
                                    {
                                        XmlName = 'UnitPrice';

                                        trigger OnBeforePassVariable()
                                        begin
                                            Log += 'pass unitprice;';
                                            unitprice := Format(part.Amount, 0, 9);
                                        end;
                                    }
                                    textelement(kind_is)
                                    {
                                        textattribute(kind_id)
                                        {
                                            XmlName = 'option_value';

                                            trigger OnBeforePassVariable()
                                            begin
                                                Log += 'pass kind_id;';
                                                kind_id := Format(part.Kind, 0, 9);
                                            end;
                                        }

                                        trigger OnBeforePassVariable()
                                        begin
                                            Log += 'pass kind_is;';
                                            kind_is := Format(part.Kind);
                                        end;
                                    }
                                }
                                textelement(partdesc)
                                {
                                    XmlName = 'Description';
                                    MinOccurs = Once;
                                    MaxOccurs = Once;
                                }

                                trigger OnAfterGetRecord()
                                begin
                                    Log += 'get part ' + part.Code + ';';
                                    slottype := 'Open';
                                    partdesc := part.Description;
                                    slotdate := '';
                                    starttime := '';
                                    endtime := '';
                                    validfrom := '';
                                    validuntil := '';
                                    canmove := Format(part.Kind = part.Kind::Timed);
                                    if part.Kind = part.Kind::Timed then begin
                                        slottype := 'Timed';
                                        slotdate := '2026-03-0' + Format(part.ExtNo mod 10);
                                        starttime := '10:00:00';
                                        endtime := '11:30:00';
                                    end else
                                        validfrom := Format(0D, 0, 9);
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
                    Log += 'get result;';
                end;
            }
        }
    }

    var
        PartSource: Record "LT TR XP Part" temporary;
        Log: Text;
        TicketCount: Integer;
        LinePrice: Decimal;
        LineQuantity: Integer;

    local procedure FillParts(LineRef: Integer)
    begin
        LinePrice := 0;
        LineQuantity := 0;
        PartSource.SetRange(Ref, LineRef);
        if PartSource.FindSet() then
            repeat
                part := PartSource;
                part.Insert();
                LinePrice += PartSource.Amount;
                LineQuantity += 1;
            until PartSource.Next() = 0;
        PartSource.Reset();
    end;

    procedure AddPart(EntryNo: Integer; LineRef: Integer; NewCode: Code[20]; NewExtNo: Integer; NewKind: Option; NewAmount: Decimal; NewDescription: Text[50])
    begin
        PartSource.Init();
        PartSource."Entry No." := EntryNo;
        PartSource.Ref := LineRef;
        PartSource.Code := NewCode;
        PartSource.ExtNo := NewExtNo;
        PartSource.Kind := NewKind;
        PartSource.Amount := NewAmount;
        PartSource.Description := NewDescription;
        PartSource.Insert();
    end;

    procedure AddLine(EntryNo: Integer; LineRef: Integer; NewStatus: Boolean; NewMessage: Text[50])
    begin
        Clear(detail);
        detail."Entry No." := EntryNo;
        detail.Ref := LineRef;
        detail.Status := NewStatus;
        detail.Message := NewMessage;
        if detail.Status and (detail.Message = '') then
            detail.Message := 'OK';
        detail.Insert();
    end;

    procedure SetResult(EntryNo: Integer; NewToken: Text[30]; NewStatus: Boolean; NewMessage: Text[50])
    begin
        result.Init();
        result."Entry No." := EntryNo;
        result.Token := NewToken;
        result.Status := NewStatus;
        result.Message := NewMessage;
        result.Insert();
        result.Reset();
    end;

    procedure SetErrorResult(NewToken: Text[30]; Reason: Text)
    begin
        result.DeleteAll();
        result.Init();
        result.Token := NewToken;
        result.Message := CopyStr(Reason, 1, MaxStrLen(result.Message));
        result.Insert();
    end;

    procedure ResultMessage(): Text
    begin
        exit('token=' + result.Token + ' message=' + result.Message + ' state=' + state);
    end;

    procedure GetToken(): Text
    begin
        exit(token);
    end;

    procedure Tickets() Rows: Text
    begin
        ticket.Reset();
        if ticket.FindSet() then
            repeat
                Rows += Format(ticket."Entry No.") + ':' + ticket.Code + '/' + Format(ticket.Ref) + '/' + Format(ticket.Qty) + '/' + Format(ticket.Amount, 0, 9) + ';';
            until ticket.Next() = 0;
    end;

    procedure PartRows() Rows: Text
    begin
        part.Reset();
        if part.FindSet() then
            repeat
                Rows += part.Code + ';';
            until part.Next() = 0;
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

xmlport 90065 "LT TR XP Member Reply"
{
    Format = Xml;
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(members)
        {
            MaxOccurs = Once;
            textelement(addmember)
            {
                tableelement(request; "LT TR XP Member")
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    UseTemporary = true;
                    textattribute(instancein)
                    {
                        XmlName = 'instance';
                        Occurrence = Optional;
                    }
                    fieldelement(firstname; request.FirstName)
                    {
                    }
                    fieldelement(email; request.Email)
                    {
                    }
                    fieldelement(store; request.Store)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                    }
                    textelement(guardian)
                    {
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        fieldelement(guardianno; request.GuardianNo)
                        {
                            XmlName = 'membernumber';
                        }
                        textelement(guardianemail)
                        {
                            XmlName = 'email';
                        }
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        request."Entry No." := 1;
                        Log += 'insert request ' + request.FirstName + ' instance=' + instancein + ' guardianemail=' + guardianemail + ';';
                    end;
                }
                tableelement(reply; "LT TR XP Member")
                {
                    XmlName = 'response';
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    UseTemporary = true;
                    textattribute(instanceout)
                    {
                        XmlName = 'instance';

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass instance;';
                            instanceout := 'svc-1';
                        end;
                    }
                    textelement(status)
                    {
                        MaxOccurs = Once;
                    }
                    textelement(errordescription)
                    {
                        MaxOccurs = Once;
                    }
                    textelement(member)
                    {
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        fieldelement(memberno; reply.MemberNo)
                        {
                            XmlName = 'membernumber';
                        }
                        fieldelement(email; reply.Email)
                        {
                        }
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
    }

    var
        Log: Text;

    procedure AddResponse(EntryNo: Integer; NewMemberNo: Code[20]; NewEmail: Text[80])
    begin
        errordescription := '';
        status := '1';
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

    procedure AddErrorResponse(ErrorMessage: Text)
    begin
        errordescription := ErrorMessage;
        status := '0';
        reply.Insert();
    end;

    procedure Response() Result: Text
    begin
        Result := 'status=' + status + ' error=' + errordescription;
        if reply.FindFirst() then
            Result += ' reply=' + Format(reply."Entry No.") + ':' + reply.MemberNo
        else
            Result += ' reply=none';
        if request.FindFirst() then
            Result += ' request=' + request.FirstName + '/' + request.Email + '/' + request.Store + '/' + request.GuardianNo
        else
            Result += ' request=none';
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

xmlport 90066 "LT TR XP Empty Leaf"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            MaxOccurs = Once;
            textelement(top)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'top=[' + top + '];';
                end;
            }
            tableelement(row; "LT TR XP Result")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldattribute(no; row."Entry No.")
                {
                }
                fieldelement(msg; row.Message)
                {
                    MinOccurs = Zero;

                    trigger OnAfterAssignField()
                    begin
                        Log += 'msg=[' + row.Message + '];';
                    end;
                }
                textelement(direct)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'direct=[' + direct + '];';
                    end;
                }
                textelement(box)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    textelement(inner)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'inner=[' + inner + '];';
                        end;
                    }

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'box=[' + box + '];';
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ' + Format(row."Entry No.") + ' msg=[' + row.Message + '];';
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

codeunit 90067 "LT TR XP Leaf Runner"
{
    // Imports Input into xmlport 90066 inside Codeunit.Run, so a failed import does not end the test.
    var
        Input: Text;
        Outcome: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Port: XmlPort "LT TR XP Empty Leaf";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
        Outcome := Port.GetLog();
    end;

    procedure SetInput(NewInput: Text)
    begin
        Input := NewInput;
        Outcome := '';
    end;

    procedure Result(): Text
    begin
        exit(Outcome);
    end;
}
