// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: own table 90040, xmlports 90041, 90042, runner codeunit 90043 (writer TQ); the temporary blob table 87279
//   (QrXpContainerOccurs.al); tests TQ_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: observed on a BC 29.0 service tier; every literal asserted in the TQ_* tests is what that tier produced. Other versions: corpus CI matrix.
// Objects: a response-style port. The root text element holds a temporary table element; each row holds a text element `status`
//   (two leaf text elements) and a text element `membership` with MinOccurs = Zero and MaxOccurs = Once, whose children are field
//   elements (Code, Text, Date, Decimal, Boolean; some MinOccurs = Zero) and leaf text elements (one MinOccurs = Zero).
//   90041: the leaf values are set in triggers (the table element's OnAfterGetRecord, the leaf's own OnBeforePassVariable) or left as
//     a global set from outside; every trigger logs, so the log shows the order.
//   90042: the same shape with UseDefaultNamespace = true and no trigger at all: the leaves are globals set from outside.
// Facts (BC 29): export writes `membership` for every row, also when all its children are empty; an empty field element or leaf
//   text element with MinOccurs = Zero is still written, as `<name />` / `<validuntil />` (not left out); with FormatEvaluate = Xml a
//   Decimal field writes two decimals (`150.50`, `7.00`, `0.00`), 0D writes `<issued />`, a Boolean `true`/`false`. No rows: `<response />`
//   and no trigger runs. Trigger order per row: `get M1;pass status;pass responsemessage;pass membership;pass tier;` (the table element's
//   OnAfterGetRecord, then each text element's OnBeforePassVariable in schema order, the container's before its children's). A leaf no
//   trigger sets is written with its current value in every row. 90042 writes the namespace only on the root element.
//   Import: a missing `membership` is accepted (no trigger of it runs, the fields keep their init values); an empty `<tier />` runs tier's
//   OnAfterAssignVariable twice (log `tier=;tier=;`); a second `membership` fails the schema check (XmlPortInvalidXml).
// BC versions: 27, 28, 29

table 90040 "LT TQ XP Member"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Code; Code[20]) { }
        field(3; Name; Text[50]) { }
        field(4; Issued; Date) { }
        field(5; Points; Decimal) { }
        field(6; Blocked; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

xmlport 90041 "LT TQ XP Response"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(response)
        {
            MaxOccurs = Once;
            tableelement(member; "LT TQ XP Member")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                UseTemporary = true;
                fieldattribute(no; member."No.")
                {
                }
                textelement(status)
                {
                    MaxOccurs = Once;
                    textelement(responsecode)
                    {
                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'responsecode=' + responsecode + ';';
                        end;
                    }
                    textelement(responsemessage)
                    {
                        MaxOccurs = Once;

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass responsemessage;';
                            if member.Code = '' then
                                responsemessage := 'no membership'
                            else
                                responsemessage := '';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass status;';
                    end;
                }
                textelement(membership)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    fieldelement(code; member.Code)
                    {
                    }
                    fieldelement(name; member.Name)
                    {
                        MinOccurs = Zero;
                    }
                    textelement(tier)
                    {
                        MaxOccurs = Once;

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass tier;';
                            if member.Points >= 100 then
                                tier := 'GOLD'
                            else
                                tier := '';
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'tier=' + tier + ';';
                        end;
                    }
                    fieldelement(issued; member.Issued)
                    {
                    }
                    fieldelement(points; member.Points)
                    {
                        MinOccurs = Zero;
                    }
                    textelement(validuntil)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                    }
                    fieldelement(blocked; member.Blocked)
                    {
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass membership;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'membership=' + membership + ';';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ' + member."No." + ';';
                    responsecode := 'OK-' + member."No.";
                end;

                trigger OnAfterInitRecord()
                begin
                    Log += 'init;';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before insert ' + member."No." + ' code=' + member.Code + ' name=' + member.Name + ' issued=' + Format(member.Issued, 0, 9) +
                        ' points=' + Format(member.Points, 0, 9) + ' blocked=' + Format(member.Blocked, 0, 9) + ' validuntil=' + validuntil + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddMember(No: Code[20]; NewCode: Code[20]; NewName: Text[50]; NewIssued: Date; NewPoints: Decimal; NewBlocked: Boolean)
    begin
        member.Init();
        member."No." := No;
        member.Code := NewCode;
        member.Name := NewName;
        member.Issued := NewIssued;
        member.Points := NewPoints;
        member.Blocked := NewBlocked;
        member.Insert();
    end;

    procedure SetValidUntil(Value: Text)
    begin
        validuntil := Value;
    end;

    procedure Rows() Result: Text
    begin
        if member.FindSet() then
            repeat
                Result += member."No." + ':' + member.Code + '/' + member.Name + '/' + Format(member.Issued, 0, 9) + '/' + Format(member.Points, 0, 9) + '/' + Format(member.Blocked, 0, 9) + ';';
            until member.Next() = 0;
    end;

    procedure Values(): Text
    begin
        exit('responsecode=' + responsecode + ' responsemessage=' + responsemessage + ' tier=' + tier + ' validuntil=' + validuntil + ' membership=' + membership + ' status=' + status);
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90042 "LT TQ XP Response Ns"
{
    Format = Xml;
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(response)
        {
            MaxOccurs = Once;
            tableelement(member; "LT TQ XP Member")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                UseTemporary = true;
                textelement(status)
                {
                    MaxOccurs = Once;
                    textelement(responsecode)
                    {
                    }
                    textelement(responsemessage)
                    {
                        MaxOccurs = Once;
                    }
                }
                textelement(membership)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    fieldelement(code; member.Code)
                    {
                    }
                    textelement(tier)
                    {
                        MaxOccurs = Once;
                    }
                    fieldelement(points; member.Points)
                    {
                        MinOccurs = Zero;
                    }
                    textelement(validuntil)
                    {
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                    }
                }
            }
        }
    }

    procedure AddMember(No: Code[20]; NewCode: Code[20]; NewPoints: Decimal)
    begin
        member.Init();
        member."No." := No;
        member.Code := NewCode;
        member.Points := NewPoints;
        member.Insert();
    end;

    procedure SetLeaves(NewCode: Text; NewMessage: Text; NewTier: Text; NewValidUntil: Text)
    begin
        responsecode := NewCode;
        responsemessage := NewMessage;
        tier := NewTier;
        validuntil := NewValidUntil;
    end;
}

codeunit 90043 "LT TQ XP Runner"
{
    // Imports Input into xmlport 90041 inside Codeunit.Run, so a failed import does not end the test.
    var
        Input: Text;
        Outcome: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Port: XmlPort "LT TQ XP Response";
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
        Outcome := 'log=' + Port.GetLog() + ' values: ' + Port.Values() + ' rows=' + Port.Rows();
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
