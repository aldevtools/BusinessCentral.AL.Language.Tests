// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-application-overview
// Scope: in-scope, but ONLY for a Target = OnPrem app - see the header note below
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// Probe: written against a real BC 27.5 service tier started by bc-linux; every literal below is what
// that tier produced. Other BC versions and other hosts were not measured.
// BC versions: 27.5
//
// WHY THIS FILE IS IN THE ONPREM APP
//   Most members of the System Application codeunit "Server Setting", and
//   "Environment Information".GetEnvironmentSetting, are declared Scope = OnPrem. A Target = Cloud
//   app cannot name them (AL0296), so only an OnPrem-target app can ask what they answer.
//
// WHAT THIS PINS
//   The values of the server configuration (ALConfigSettings) that these wrappers read, as the
//   bc-linux service tier is configured: the API flags and limits, the test automation flag, the
//   extension and permission set flags. GetEnvironmentSetting returns an empty text for any name.

codeunit 61230 "Test Server Setting Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ServerSetting_Flags_AsConfigured()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        Assert.IsFalse(ServerSetting.GetEnableSaaSExtensionInstallSetting(), 'GetEnableSaaSExtensionInstallSetting');
        Assert.IsFalse(ServerSetting.GetIsSaasExcelAddinEnabled(), 'GetIsSaasExcelAddinEnabled');
        // GetEnableEntraGroupsOnPrem exists from 27.3 on (BC 27.0 does not compile it) and reads false on the CI image; left out so that every minor compiles.
        Assert.IsTrue(ServerSetting.GetApiServicesEnabled(), 'GetApiServicesEnabled');
        Assert.IsTrue(ServerSetting.GetApiSubscriptionsEnabled(), 'GetApiSubscriptionsEnabled');
        Assert.IsTrue(ServerSetting.GetTestAutomationEnabled(), 'GetTestAutomationEnabled');
        Assert.IsTrue(ServerSetting.GetUsePermissionSetsFromExtensions(), 'GetUsePermissionSetsFromExtensions');
        Assert.IsFalse(ServerSetting.GetEnableMembershipEntitlement(), 'GetEnableMembershipEntitlement');
    end;

    [Test]
    procedure ServerSetting_ApiSubscriptionLimits_AsConfigured()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        Assert.AreEqual(30000, ServerSetting.GetApiSubscriptionSendingNotificationTimeout(), 'GetApiSubscriptionSendingNotificationTimeout');
        Assert.AreEqual(1000, ServerSetting.GetApiSubscriptionMaxNumberOfNotifications(), 'GetApiSubscriptionMaxNumberOfNotifications');
        Assert.AreEqual(30000, ServerSetting.GetApiSubscriptionDelayTime(), 'GetApiSubscriptionDelayTime');
    end;

    [Test]
    procedure EnvironmentInformation_GetEnvironmentSetting_IsEmptyForAnyName()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.AreEqual('', EnvironmentInformation.GetEnvironmentSetting('EnvironmentName'), 'a name BC knows');
        Assert.AreEqual('', EnvironmentInformation.GetEnvironmentSetting('NoSuchSetting'), 'a name it does not');
    end;
}
