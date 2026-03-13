#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>

public Plugin myinfo = 
{
    name = "Watermark",
    author = "'rudy",
    description = "Watermark",
    version = "4.0"
};

enum { RED = 0, GREEN, BLUE }

ConVar g_cvarRGB, g_cvarW1, g_cvarW2, g_cvarW3, g_cvarYPos;
Handle g_hSyncHUD, g_hCookie;
int g_iColors[3];
bool g_bEnabled[MAXPLAYERS + 1];

public void OnPluginStart()
{
    g_hCookie = RegClientCookie("watermark_status", "", CookieAccess_Protected);
    
    g_cvarW1 = CreateConVar("sm_wm_line1", "SERVER-NAME.COM", "");
    g_cvarW2 = CreateConVar("sm_wm_line2", "!DISCORD !SHOP", "");
    g_cvarW3 = CreateConVar("sm_wm_line3", "!RULES !CASES", "");
    
    g_cvarRGB = CreateConVar("sm_wm_rgb", "0,255,255", "");
    g_cvarYPos = CreateConVar("sm_wm_y", "0.05", "");

    AutoExecConfig(true, "watermark");

    g_cvarRGB.AddChangeHook(OnCvarChanged);
    UpdateColors();

    g_hSyncHUD = CreateHudSynchronizer();
    CreateTimer(1.0, Timer_DisplayHUD, _, TIMER_REPEAT);
    
    RegConsoleCmd("sm_watermark", Command_Hud);
    
    for(int i = 1; i <= MaxClients; i++) 
        if(IsClientInGame(i)) OnClientPutInServer(i);
}

public void OnCvarChanged(ConVar convar, const char[] oldVal, const char[] newVal) { UpdateColors(); }

void UpdateColors()
{
    char buffer[16], parts[3][4];
    g_cvarRGB.GetString(buffer, sizeof(buffer));
    ExplodeString(buffer, ",", parts, 3, 4);
    for(int i = 0; i < 3; i++) g_iColors[i] = StringToInt(parts[i]);
}

public void OnClientPutInServer(int client)
{
    if(AreClientCookiesCached(client)) LoadCookie(client);
}

public void OnClientCookiesCached(int client) { LoadCookie(client); }

void LoadCookie(int client)
{
    char buffer[4];
    GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));
    g_bEnabled[client] = (buffer[0] == '\0' || StringToInt(buffer) == 1);
}

public Action Command_Hud(int client, int args)
{
    g_bEnabled[client] = !g_bEnabled[client];
    SetClientCookie(client, g_hCookie, g_bEnabled[client] ? "1" : "0");
    PrintToChat(client, " Watermark: %s", g_bEnabled[client] ? "\x04Enabled" : "\x02Disabled");
    return Plugin_Handled;
}

public Action Timer_DisplayHUD(Handle timer)
{
    char s1[128], s2[128], s3[128], fullMsg[512];
    g_cvarW1.GetString(s1, sizeof(s1));
    g_cvarW2.GetString(s2, sizeof(s2));
    g_cvarW3.GetString(s3, sizeof(s3));
    
    float yPos = g_cvarYPos.FloatValue;
    Format(fullMsg, sizeof(fullMsg), "%s\n%s\n%s", s1, s2, s3);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i) && g_bEnabled[i])
        {
            SetHudTextParams(-1.0, yPos, 1.1, g_iColors[RED], g_iColors[GREEN], g_iColors[BLUE], 255, 0, 0.0, 0.0, 0.0);
            ShowSyncHudText(i, g_hSyncHUD, fullMsg);
        }
    }
    return Plugin_Continue;
}
