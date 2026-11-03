// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-xmlport-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: own tables 90120-90125, xmlports 90126-90129 (writer TU); the temporary blob table 87279 (QrXpContainerOccurs.al); tests
//   TU_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: observed on the BC 29.0 SaaS sandbox; every literal asserted in the TU_* tests is what it produced. Other versions: corpus CI
//   matrix (Linux 27.5, 28.5, 29.0).
// Facts: see the header of the TU_* tests in QrXpContainerOccurs.al.
// Objects:
//   90126 "LT TU XP Key Once" / 90127 "LT TU XP Key Unbounded": a temporary table element `p` (three rows) holding two table elements over
//     the same real table, both LinkTable = p WITHOUT LinkFields and MinOccurs = Zero: `c` with SourceTableView = sorting(A), `d` without a
//     SourceTableView. MaxOccurs = Once in 90126, Unbounded in 90127. SetMode chooses what OnPreXmlItem does at which pass (the pass
//     number counts the parent rows): 0 = nothing; 1 = SetCurrentKey(B) at pass 1 only; 2 = SetCurrentKey(B) and Ascending(false) at pass
//     1 only; 3 = SetCurrentKey(B) at pass 2 only; 4 = Reset at pass 1 only; 5 = SetCurrentKey(B) at every pass; 6 = Ascending(false) at
//     pass 1 only.
//   90128 "LT TU XP Nested Real": a reply port. Text element `Result` (MinOccurs = Zero, MaxOccurs = Once) > leaf text elements + temporary
//     table element `Order` (MinOccurs = Zero, MaxOccurs = Once, a required text attribute) > table element `Line` over a real table with no
//     LinkTable (default occurs; OnPreXmlItem filters it on the order) > table element `item` over a real table with no LinkTable
//     (MinOccurs = Once, MaxOccurs = Unbounded; OnPreXmlItem filters it on the line) > table element `slot` over a real table with no
//     LinkTable (MinOccurs = Zero, MaxOccurs = Once; OnPreXmlItem filters it on the item and a kind). SetMode: 0 = every OnPreXmlItem sets
//     its filters; 1 = `item` sets none; 2 = `item` sets its filter at its first pass only; 3 = `slot` sets none.
//   90129 "LT TU XP Nested Temp": temporary table elements with no LinkTable nested in each other: `outer` (default occurs) > `mid`
//     (MinOccurs = Once, MaxOccurs = Unbounded) > `inner` (MinOccurs = Zero, MaxOccurs = Once). SetMode: 0 = no filters; 1 = OnPreXmlItem
//     of `mid` and `inner` filter on the parent row.
// BC versions: 27, 28, 29

table 90120 "LT TU XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Integer) { }
        field(3; Token; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90121 "LT TU XP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; HeadNo; Integer) { }
        field(3; ExtCode; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90122 "LT TU XP Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; ItemCode; Code[20]) { }
        field(4; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90123 "LT TU XP Slot"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; ItemNo; Integer) { }
        field(3; Kind; Option) { OptionMembers = " ",Admitted,Reservation; }
        field(4; ExtNo; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 90124 "LT TU XP KParent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 90125 "LT TU XP KChild"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
        field(3; B; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(KA; A) { }
        key(KB; B) { }
    }
}

xmlport 90126 "LT TU XP Key Once"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Direction = Export;

    schema
    {
        textelement(root)
        {
            MaxOccurs = Once;
            tableelement(par; "LT TU XP KParent")
            {
                XmlName = 'p';
                UseTemporary = true;
                fieldattribute(id; par.Id)
                {
                }
                tableelement(c; "LT TU XP KChild")
                {
                    XmlName = 'c';
                    LinkTable = par;
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    SourceTableView = sorting(A);
                    fieldattribute(id; c.Id)
                    {
                    }

                    trigger OnPreXmlItem()
                    begin
                        PassC += 1;
                        Log += 'pre c' + Format(PassC) + ' [' + c.GetView(false) + '] n=' + Format(c.Count());
                        Act(c, PassC);
                        Log += ' then [' + c.GetView(false) + '];';
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'c' + Format(c.Id) + ';';
                    end;
                }
                tableelement(d; "LT TU XP KChild")
                {
                    XmlName = 'd';
                    LinkTable = par;
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    fieldattribute(id; d.Id)
                    {
                    }

                    trigger OnPreXmlItem()
                    begin
                        PassD += 1;
                        Log += 'pre d' + Format(PassD) + ' [' + d.GetView(false) + '] n=' + Format(d.Count());
                        Act(d, PassD);
                        Log += ' then [' + d.GetView(false) + '];';
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'd' + Format(d.Id) + ';';
                    end;
                }
            }
        }
    }

    var
        Log: Text;
        Mode: Integer;
        PassC: Integer;
        PassD: Integer;

    local procedure Act(var Child: Record "LT TU XP KChild"; Pass: Integer)
    begin
        case true of
            (Mode = 1) and (Pass = 1), (Mode = 3) and (Pass = 2), Mode = 5:
                Child.SetCurrentKey(B);
            (Mode = 2) and (Pass = 1):
                begin
                    Child.SetCurrentKey(B);
                    Child.Ascending(false);
                end;
            (Mode = 4) and (Pass = 1):
                Child.Reset();
            (Mode = 6) and (Pass = 1):
                Child.Ascending(false);
        end;
    end;

    procedure AddParent(NewId: Integer)
    begin
        par.Id := NewId;
        par.Insert();
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90127 "LT TU XP Key Unbounded"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Direction = Export;

    schema
    {
        textelement(root)
        {
            MaxOccurs = Once;
            tableelement(par; "LT TU XP KParent")
            {
                XmlName = 'p';
                UseTemporary = true;
                fieldattribute(id; par.Id)
                {
                }
                tableelement(c; "LT TU XP KChild")
                {
                    XmlName = 'c';
                    LinkTable = par;
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    SourceTableView = sorting(A);
                    fieldattribute(id; c.Id)
                    {
                    }

                    trigger OnPreXmlItem()
                    begin
                        PassC += 1;
                        Log += 'pre c' + Format(PassC) + ' [' + c.GetView(false) + '] n=' + Format(c.Count());
                        Act(c, PassC);
                        Log += ' then [' + c.GetView(false) + '];';
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'c' + Format(c.Id) + ';';
                    end;
                }
                tableelement(d; "LT TU XP KChild")
                {
                    XmlName = 'd';
                    LinkTable = par;
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    fieldattribute(id; d.Id)
                    {
                    }

                    trigger OnPreXmlItem()
                    begin
                        PassD += 1;
                        Log += 'pre d' + Format(PassD) + ' [' + d.GetView(false) + '] n=' + Format(d.Count());
                        Act(d, PassD);
                        Log += ' then [' + d.GetView(false) + '];';
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'd' + Format(d.Id) + ';';
                    end;
                }
            }
        }
    }

    var
        Log: Text;
        Mode: Integer;
        PassC: Integer;
        PassD: Integer;

    local procedure Act(var Child: Record "LT TU XP KChild"; Pass: Integer)
    begin
        case true of
            (Mode = 1) and (Pass = 1), (Mode = 3) and (Pass = 2), Mode = 5:
                Child.SetCurrentKey(B);
            (Mode = 2) and (Pass = 1):
                begin
                    Child.SetCurrentKey(B);
                    Child.Ascending(false);
                end;
            (Mode = 4) and (Pass = 1):
                Child.Reset();
            (Mode = 6) and (Pass = 1):
                Child.Ascending(false);
        end;
    end;

    procedure AddParent(NewId: Integer)
    begin
        par.Id := NewId;
        par.Insert();
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90128 "LT TU XP Nested Real"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Direction = Export;

    schema
    {
        textelement(Root)
        {
            MaxOccurs = Once;
            textelement(Result)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;
                textelement(ResponseCode)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(ResponseMessage)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                tableelement(head; "LT TU XP Head")
                {
                    XmlName = 'Order';
                    UseTemporary = true;
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    textattribute(OrderId)
                    {
                        Occurrence = Required;
                    }
                    tableelement(line; "LT TU XP Line")
                    {
                        XmlName = 'Line';
                        textattribute(LineExt)
                        {
                            XmlName = 'ext';
                            Occurrence = Required;
                        }
                        textelement(LineNo)
                        {
                            XmlName = 'line_no';
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        textelement(LineUid)
                        {
                            XmlName = 'uid';
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        textelement(Pin)
                        {
                            XmlName = 'pin';
                        }
                        tableelement(item; "LT TU XP Item")
                        {
                            XmlName = 'item';
                            MinOccurs = Once;
                            MaxOccurs = Unbounded;
                            fieldattribute(code; item.ItemCode)
                            {
                                Occurrence = Required;
                            }
                            fieldelement(qty; item.Qty)
                            {
                                MinOccurs = Zero;
                                MaxOccurs = Once;
                            }
                            tableelement(slot; "LT TU XP Slot")
                            {
                                XmlName = 'slot';
                                MinOccurs = Zero;
                                MaxOccurs = Once;
                                fieldattribute(ext; slot.ExtNo)
                                {
                                    Occurrence = Optional;
                                }
                                textattribute(SlotStart)
                                {
                                    XmlName = 'start';
                                    Occurrence = Optional;
                                }

                                trigger OnPreXmlItem()
                                begin
                                    Log += 'pre slot f=' + slot.GetFilters() + ' at=' + Format(slot."Entry No.") + ';';
                                    if Mode <> 3 then begin
                                        slot.SetFilter(ItemNo, '=%1', item."Entry No.");
                                        slot.SetFilter(Kind, '=%1', slot.Kind::Reservation);
                                    end;
                                end;

                                trigger OnAfterGetRecord()
                                begin
                                    Log += 'get slot ' + Format(slot."Entry No.") + ';';
                                    SlotStart := 'S' + Format(slot."Entry No.");
                                end;
                            }

                            trigger OnPreXmlItem()
                            begin
                                ItemPass += 1;
                                Log += 'pre item f=' + item.GetFilters() + ' at=' + Format(item."Entry No.") + ';';
                                if (Mode = 0) or (Mode = 3) or ((Mode = 2) and (ItemPass = 1)) then
                                    item.SetFilter(LineNo, '=%1', line."Entry No.");
                            end;

                            trigger OnAfterGetRecord()
                            begin
                                Log += 'get item ' + Format(item."Entry No.") + ';';
                            end;
                        }

                        trigger OnPreXmlItem()
                        begin
                            Log += 'pre line f=' + line.GetFilters() + ';';
                            line.SetFilter(HeadNo, '=%1', head.Ref);
                        end;

                        trigger OnAfterGetRecord()
                        begin
                            Log += 'get line ' + Format(line."Entry No.") + ';';
                            LineUid := line.ExtCode;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'get head ' + Format(head."Entry No.") + ';';
                        LineExt := 'X' + Format(head.Ref);
                        LineNo := Format(head.Ref);
                        Pin := 'P' + Format(head.Ref);
                    end;
                }
            }
        }
    }

    var
        Log: Text;
        Mode: Integer;
        ItemPass: Integer;

    procedure SetHead(EntryNo: Integer; NewRef: Integer; NewToken: Text[30])
    begin
        head."Entry No." := EntryNo;
        head.Ref := NewRef;
        head.Token := NewToken;
        head.Insert();
        OrderId := NewToken;
    end;

    procedure SetResponse(NewCode: Text; NewMessage: Text)
    begin
        ResponseCode := NewCode;
        ResponseMessage := NewMessage;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90129 "LT TU XP Nested Temp"
{
    Format = Xml;
    FormatEvaluate = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Direction = Export;

    schema
    {
        textelement(root)
        {
            MaxOccurs = Once;
            tableelement(outer; "LT TU XP Head")
            {
                XmlName = 'outer';
                UseTemporary = true;
                fieldattribute(id; outer."Entry No.")
                {
                }
                tableelement(mid; "LT TU XP Line")
                {
                    XmlName = 'mid';
                    UseTemporary = true;
                    MinOccurs = Once;
                    MaxOccurs = Unbounded;
                    fieldattribute(id; mid."Entry No.")
                    {
                    }
                    fieldattribute(parent; mid.HeadNo)
                    {
                    }
                    tableelement(inner; "LT TU XP Item")
                    {
                        XmlName = 'inner';
                        UseTemporary = true;
                        MinOccurs = Zero;
                        MaxOccurs = Once;
                        fieldattribute(id; inner."Entry No.")
                        {
                        }
                        fieldattribute(parent; inner.LineNo)
                        {
                        }

                        trigger OnPreXmlItem()
                        begin
                            Log += 'pre inner f=' + inner.GetFilters() + ' at=' + Format(inner."Entry No.") + ';';
                            if Mode = 1 then
                                inner.SetRange(LineNo, mid."Entry No.");
                        end;

                        trigger OnAfterGetRecord()
                        begin
                            Log += 'get inner ' + Format(inner."Entry No.") + ';';
                        end;
                    }

                    trigger OnPreXmlItem()
                    begin
                        Log += 'pre mid f=' + mid.GetFilters() + ' at=' + Format(mid."Entry No.") + ';';
                        if Mode = 1 then
                            mid.SetRange(HeadNo, outer."Entry No.");
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log += 'get mid ' + Format(mid."Entry No.") + ';';
                    end;
                }

                trigger OnPreXmlItem()
                begin
                    Log += 'pre outer;';
                end;

                trigger OnAfterGetRecord()
                begin
                    Log += 'get outer ' + Format(outer."Entry No.") + ';';
                end;
            }
        }
    }

    var
        Log: Text;
        Mode: Integer;

    procedure AddOuter(NewId: Integer)
    begin
        outer."Entry No." := NewId;
        outer.Insert();
    end;

    procedure AddMid(NewId: Integer; Parent: Integer)
    begin
        mid."Entry No." := NewId;
        mid.HeadNo := Parent;
        mid.Insert();
    end;

    procedure AddInner(NewId: Integer; Parent: Integer)
    begin
        inner."Entry No." := NewId;
        inner.LineNo := Parent;
        inner.Insert();
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}
