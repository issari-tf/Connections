#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define UPDATE_URL "https://raw.githubusercontent.com/issari-tf/Connections/main/updater.txt"

#define PLUGIN_VERSION "0.0.3"

ConVar gCV_Enable;
ConVar gCV_AutoUpdate;

GlobalForward gForward_ClientConnectedViaFavorites;

public Plugin myinfo = 
{
  name        = "Favorite Connections",
  author      = "Aidan Sanders",
  description = "Detect when a player connects to the server via favorites.",
  version     = PLUGIN_VERSION,
  url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  char game[32];
  GetGameFolderName(game, sizeof(game));

  if (!StrEqual(game, "tf") && !StrEqual(game, "tf_beta") &&
      !StrEqual(game, "dod") && !StrEqual(game, "hl2mp") &&
      !StrEqual(game, "css"))
  {
    Format(error, err_max, "This plugin only works for TF2, TF2Beta, DoD:S, CS:S and HL2:DM.");
    return APLRes_Failure;
  }

  RegPluginLibrary("favorite_connections");
  return APLRes_Success;
}

public void OnPluginStart()
{
  gForward_ClientConnectedViaFavorites = CreateGlobalForward("ClientConnectedViaFavorites", ET_Event, Param_Cell);

  CreateConVar("favoriteconnections_version", PLUGIN_VERSION, "Favorite Connections Version", 
    FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);

  gCV_Enable = CreateConVar("connections_enable", "1", "Enable the plugin? 1 = Enable, 0 = Disable", FCVAR_NOTIFY);
  gCV_AutoUpdate = CreateConVar("connections_auto_update", "1", "automatically update when newest versions are available. Does nothing if updater plugin isn't used.", FCVAR_NONE, true, 0.0, true, 1.0);

  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i))
    {
      CheckClientConnectionMethod(i);
    }
  }
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

public void OnClientPostAdminCheck(int client)
{
  if (!gCV_Enable.BoolValue)
    return;

  CheckClientConnectionMethod(client);
}

void CheckClientConnectionMethod(int client)
{
  char connectMethod[32];
  if (GetClientInfo(client, "cl_connectmethod", connectMethod, sizeof(connectMethod)))
  {
    if (StrEqual(connectMethod, "serverbrowser_favorites"))
    {
      // Print to server console
      char name[MAX_NAME_LENGTH];
      GetClientName(client, name, sizeof(name));
      PrintToServer("[FavoriteConnections] %N connected via Favorites.", client);

      Action result = Plugin_Continue;
      Call_StartForward(gForward_ClientConnectedViaFavorites);
      Call_PushCell(client);
      Call_Finish(result);
    }
  }
}
