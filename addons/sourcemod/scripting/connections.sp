#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define UPDATE_URL "https://raw.githubusercontent.com/issari-tf/Connections/main/updater.txt"

#define PLUGIN_VERSION "0.0.4"

ConVar gCV_Enable;
ConVar gCV_AutoUpdate;

public Plugin myinfo = 
{
  name        = "Favorite Connections",
  author      = "Aidan Sanders",
  description = "Detect when a player connects to the server via favorites.",
  version     = PLUGIN_VERSION,
  url         = ""
};

public void OnPluginStart()
{
  CreateConVar("favoriteconnections_version", PLUGIN_VERSION, "Favorite Connections Version", 
    FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);

  gCV_Enable = CreateConVar("connections_enable", "1", "Enable the plugin? 1 = Enable, 0 = Disable", FCVAR_NOTIFY);
  gCV_AutoUpdate = CreateConVar("connections_auto_update", "1", "automatically update when newest versions are available. Does nothing if updater plugin isn't used.", FCVAR_NONE, true, 0.0, true, 1.0);
}

public void OnLibraryAdded(const char[] name) {
#if defined _updater_included
	if( !strcmp(name, "updater") )
		Updater_AddPlugin(UPDATE_URL);
#endif
}

/// UPDATER Stuff
public void OnAllPluginsLoaded() {
#if defined _updater_included
	if( LibraryExists("updater") )
		Updater_AddPlugin(UPDATE_URL);
#endif
}

#if defined _updater_included
public Action Updater_OnPluginDownloading() {
	if( !gCV_AutoUpdate.BoolValue ) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Updater_OnPluginUpdated()  {
	char filename[64]; GetPluginFilename(null, filename, sizeof(filename));
	ServerCommand("sm plugins unload %s", filename);
	ServerCommand("sm plugins load %s", filename);
}
#endif

public void OnClientConnected(int iClient) {
  if (IsFakeClient(iClient) || !gCV_Enable.BoolValue)
    return;
  
  char sConnectMethod[32];
  if (GetClientInfo(iClient, "cl_connectmethod", sConnectMethod, sizeof(sConnectMethod)))
  {
    if (StrEqual(sConnectMethod, "serverbrowser_favorites"))
    {
      char sName[MAX_NAME_LENGTH];
      GetClientName(iClient, sName, sizeof(sName));
      PrintToServer("[Connections] %N connected via Favorites.", iClient);
      PrintToChatAll("[Connections] %N connected via Favorites.", iClient);
    }
  }
}