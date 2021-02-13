#include <sourcemod>
#include <cstrike>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required


#define STEAMAPIURL "https://api.steamchina.com"
#define CHECK_HOUR_API "IPlayerService/GetOwnedGames/v0001/?key=%s&include_played_free_games=1&appids_filter[0]=730&steamid=%s&format=json"
#define PLUGIN_VERSION "1.0"

ConVar g_cSteamApiKey,g_cHour;

public Plugin myinfo = 
{
	name = "时长检测",
	author = "宇宙遨游",
	description = "时长检测",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_CSGO)
	{
		SetFailState("This plugin was made for use with Counter-Strike: Global Offensive only.");
	}
	
	g_cSteamApiKey = CreateConVar("check_apikey", "", "填写steam apikey可参考buff获取");
	g_cHour = CreateConVar("check_hour", "300", "允许多少小时以上的玩家进入");
	
	AutoExecConfig(true, "checkhour");
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (!IsValidClient(client))return;
	char steam[40];
	if(!GetClientAuthId(client, AuthId_SteamID64, steam, sizeof(steam))){
		KickClient(client, "steam认证失败!");
		return;
	}
	
	HTTPClient http = new HTTPClient(STEAMAPIURL);
	char api[255],apiKey[64];
	g_cSteamApiKey.GetString(apiKey, sizeof(apiKey));
	Format(api, sizeof(api), CHECK_HOUR_API, apiKey, steam);
	http.Get(api, OnHourReceived, client);
}

public void OnHourReceived(HTTPResponse response,int client){
	if (!IsValidClient(client))return;
	if(response.Status != HTTPStatus_OK || response.Data == null)
	{
		KickClient(client, "数据获取失败");
		return;
	}
	JSONObject json = view_as<JSONObject>(response.Data);
	char data[255];
	response.Data.ToString(data,sizeof(data));
	if (StrContains(data, "game_count") == -1)
	{
		KickClient(client, "请公开个人资料且不要勾选隐藏时长哦");
	}
	else
	{
		int hour = view_as<JSONObject>(view_as<JSONArray>(view_as<JSONObject>(json.Get("response")).Get("games")).Get(0)).GetInt("playtime_forever")/60;
		if(hour <= g_cHour.IntValue)
		{
			KickClient(client, "本服只允许游戏时间 %d 小时以上的玩家加入", g_cHour.IntValue);
		}
	}
}

stock bool IsValidClient( int client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( IsFakeClient( client )) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

