// Fixture for "SPLG Tests" (60232): what each SPLG part read from its own Rec, per filter group,
// in OnAfterGetCurrRecord. SingleInstance so the observation outlives the page and a modal run.
codeunit 60231 "SPLG Probe"
{
    SingleInstance = true;

    var
        LinkFired: Integer;
        LinkGroup4Line: Text;
        LinkGroup4Header: Text;
        LinkGroup0Line: Text;
        LinkGroup0Header: Text;
        OwnFired: Integer;
        OwnGroup4Header: Text;
        OwnGroup4Line: Text;
        OwnGroup0Line: Text;

    procedure Reset()
    begin
        LinkFired := 0;
        LinkGroup4Line := '';
        LinkGroup4Header := '';
        LinkGroup0Line := '';
        LinkGroup0Header := '';
        OwnFired := 0;
        OwnGroup4Header := '';
        OwnGroup4Line := '';
        OwnGroup0Line := '';
    end;

    procedure ObserveLink(G4Line: Text; G4Header: Text; G0Line: Text; G0Header: Text)
    begin
        LinkFired += 1;
        LinkGroup4Line := G4Line;
        LinkGroup4Header := G4Header;
        LinkGroup0Line := G0Line;
        LinkGroup0Header := G0Header;
    end;

    procedure ObserveOwn(G4Header: Text; G4Line: Text; G0Line: Text)
    begin
        OwnFired += 1;
        OwnGroup4Header := G4Header;
        OwnGroup4Line := G4Line;
        OwnGroup0Line := G0Line;
    end;

    procedure LinkFiredCount(): Integer begin exit(LinkFired); end;
    procedure LinkG4Line(): Text begin exit(LinkGroup4Line); end;
    procedure LinkG4Header(): Text begin exit(LinkGroup4Header); end;
    procedure LinkG0Line(): Text begin exit(LinkGroup0Line); end;
    procedure LinkG0Header(): Text begin exit(LinkGroup0Header); end;
    procedure OwnFiredCount(): Integer begin exit(OwnFired); end;
    procedure OwnG4Header(): Text begin exit(OwnGroup4Header); end;
    procedure OwnG4Line(): Text begin exit(OwnGroup4Line); end;
    procedure OwnG0Line(): Text begin exit(OwnGroup0Line); end;
}
