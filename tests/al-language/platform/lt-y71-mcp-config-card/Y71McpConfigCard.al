// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 93837 (writer Y71, gap cycle 7 spec G7-10)
// Probe: what the platform procedures of the internal codeunit "MCP Utilities" (GetSystemToolsInDynamicMode, GetSystemToolsInDataQuery) answer, seen through the
//        public surface of the System Application: a configuration created with the codeunit "MCP Config", its server feature list and its system tool
//        list (Tool Name and Tool Description of every row) on the "MCP Config Card" page, for a configuration with Dynamic Tool Mode on, with Data Query
//        Tools on, with both, with API Tools only and the system default configuration (the lists are hidden there).
//        Per step: the rows of the feature list (name, status) and of the system tool list (name, description), or the error text and code.
//        The tool lists can change with the BC build; values that differ between 27.5, 28.5 and 29.0 are guarded.

codeunit 93837 "LT Y71 MCP Config Card"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure FeatureRows(var Card: TestPage "MCP Config Card") Result: Text
    begin
        if Card.ServerFeatureList.First() then
            repeat
                if Result <> '' then
                    Result += ' | ';
                Result += Card.ServerFeatureList.Feature.Value + ' = ' + Card.ServerFeatureList.Status.Value;
            until not Card.ServerFeatureList.Next();
        if Result = '' then
            Result := 'no rows';
    end;

    local procedure ToolRows(var Card: TestPage "MCP Config Card") Result: Text
    begin
        if Card.SystemToolList.First() then
            repeat
                if Result <> '' then
                    Result += ' | ';
                Result += Card.SystemToolList."Tool Name".Value + ' : ' + Card.SystemToolList."Tool Description".Value;
            until not Card.SystemToolList.Next();
        if Result = '' then
            Result := 'no rows';
    end;

    local procedure OpenCard(var Card: TestPage "MCP Config Card"; ConfigName: Text)
    begin
        Card.OpenEdit();
        Card.Filter.SetFilter(Name, ConfigName);
    end;

    local procedure Configure(Name: Text; ApiTools: Boolean; Dynamic: Boolean; DataQuery: Boolean)
    var
        MCPConfig: Codeunit "MCP Config";
        ConfigId: Guid;
    begin
        ConfigId := MCPConfig.CreateConfiguration(CopyStr(Name, 1, 100), 'LT Y71 probe');
        if ApiTools then
            MCPConfig.EnableAPITools(ConfigId, true);
        if Dynamic then
            MCPConfig.EnableDynamicToolMode(ConfigId, true);
        if DataQuery then
            MCPConfig.EnableDataQueryTools(ConfigId, true);
    end;

    local procedure ObserveCard(Name: Text; ConfigName: Text)
    var
        Card: TestPage "MCP Config Card";
    begin
        OpenCard(Card, ConfigName);
        Obs.Observe(Name + '|features', FeatureRows(Card));
        Obs.Observe(Name + '|tools', ToolRows(Card));
        Card.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemTools_DynamicToolMode()
    begin
        Configure('LT Y71 MCP A', true, true, false);
        ObserveCard('dynamic', 'LT Y71 MCP A');
        Obs.Finish();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemTools_DataQueryTools()
    begin
        Configure('LT Y71 MCP B', true, false, true);
        ObserveCard('data_query', 'LT Y71 MCP B');
        Obs.Finish();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemTools_DynamicAndDataQuery()
    begin
        Configure('LT Y71 MCP C', true, true, true);
        ObserveCard('both', 'LT Y71 MCP C');
        Obs.Finish();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemTools_ApiToolsOnly_AndNothing()
    begin
        Configure('LT Y71 MCP D', true, false, false);
        ObserveCard('api_tools_only', 'LT Y71 MCP D');
        Configure('LT Y71 MCP E', false, false, false);
        ObserveCard('nothing', 'LT Y71 MCP E');
        Obs.Finish();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemTools_RepeatedOpen_SameAnswer()
    begin
        Configure('LT Y71 MCP F', true, true, false);
        ObserveCard('first_open', 'LT Y71 MCP F');
        ObserveCard('second_open', 'LT Y71 MCP F');
        Obs.Finish();
    end;
}
