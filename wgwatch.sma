/********************************************************************************************\
\********************** [ WG WATCH V4.8 | szk. @CS.LALEAGANE.RO ] ***************************/
/********************************************************************************************\
\*********[ Mail: cs.sezekz@yahoo.com  | Steam: https://steamcommunity.com/id/szkhd ]********/
/********************************************************************************************\
\*------------------------------------------------------------------------------------------*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define DNS "CS.LALEAGANE.RO"    // Numele serverului din wgmenu

#define PREFIX "[WG WATCH]"

#define WG_FLAG ADMIN_KICK

new const PLUGIN[] = "WG WATCH"
new const VERSION[] = "4.8"
new const AUTHOR[] = "szk."

new bool:wgscan[33];
new wg_team

new wg_enable
new wg_ban
new wg_ban_time

new mapname[31];
new userName[32], userIp[32], userSteamid[32];
new adminName[32], adminIp[32], adminSteamid[32];

new CachedUserID, CachedUsername[32]

new wg_log[128]
new const wg_logName[] = "wgwatch";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("WGWATCH", VERSION, FCVAR_SERVER | FCVAR_SPONLY)
	
	register_concmd("amx_wg", "wgon", WG_FLAG, "- <nume>");
	register_concmd("amx_wgoff", "wgoff", WG_FLAG, "- <nume>");
	register_concmd("amx_wgmenu", "wgmenu", WG_FLAG);
	register_concmd("amx_wglist", "wglist", WG_FLAG);
	
	register_clcmd("say /wgmenu", "wgmenu", WG_FLAG);
	register_clcmd("say /wglist", "wglist", WG_FLAG);
	
	register_clcmd("say /wginfo", "wginfo", ADMIN_ALL);
	
	wg_enable = register_cvar("wg_enable", "1")        // (1/0) activeaza / dezactiveaza pluginul
	wg_ban = register_cvar("wg_ban", "1")               // (1/0) activeaza / dezactiveaza auto-ban
	wg_ban_time = register_cvar("wg_ban_time", "0")   // (0 = permanent) durata banului
	
	register_dictionary("wgwatch.txt")
}

public client_connect(id)
{
	wgscan[id] = false
}
 
public client_disconnect(id)
{
	if(wgscan[id] && get_pcvar_num(wg_ban) == 1)
	{
		get_user_name(id, userName, charsmax(userName))
		get_user_ip(id, userIp, charsmax(userIp), 1)
		get_user_authid(id, userSteamid, charsmax(userSteamid))
		get_mapname(mapname,30)
 
		wgscan[id] = false
		server_print("%s", userIp)
		server_cmd("addip %d %s", get_pcvar_num(wg_ban_time), userIp)
		server_exec()
		
		wgChat(0, "%L", LANG_SERVER, "WG_BANNED", PREFIX, userName);
		log_to_file(wg_log,"[WG BANNED] %s [%s - %s] - [%s]^n",
		userName, userIp, userSteamid, mapname)
	}
}

public wgon(id)
{
	if(get_pcvar_num(wg_enable) == 1)
	{
		new arg[32]
		read_argv(1, arg, 31);
	
		new player = cmd_target(id, arg, 8);
	
		if(!player)
		return PLUGIN_HANDLED;
		
		get_user_name(player, userName, charsmax(userName))
		get_user_ip(player, userIp, charsmax(userIp), 1)
		get_user_authid(player, userSteamid, charsmax(userSteamid))
		get_user_name(id, adminName, charsmax(adminName))
		get_user_ip(id, adminIp, charsmax(adminIp), 1)
		get_user_authid(id, adminSteamid, charsmax(adminSteamid))
		get_mapname(mapname,30)
	
		if(wgscan[player])
		{
			wgChat(id, "%L", LANG_SERVER, "WG_EXISTENT",PREFIX, userName);
			return PLUGIN_HANDLED;
		}
	
		wgscan[player] = true;
		wg_team = get_user_team(player)
		user_silentkill(player)
		cs_set_user_team(player, CS_TEAM_SPECTATOR)
	
		wgChat(0, "%L", LANG_SERVER, "WG_ON",PREFIX, userName, adminName);
		log_to_file(wg_log,"[WG REQUEST] %s [%s - %s] - %s [%s - %s] - [%s]^n",
		userName, userIp, userSteamid, adminName, adminIp, adminSteamid, mapname)
	
		wgChat(0, "%L", LANG_SERVER, "WG_LINK", PREFIX)
		wgChat(0, "%L", LANG_SERVER, "WG_INFO", PREFIX)
	
	}
	return PLUGIN_HANDLED;
}

public wgoff(id)
{
	if(get_pcvar_num(wg_enable) == 1)
	{
		new arg[32];
		read_argv(1, arg, 31);
	
		new player = cmd_target(id, arg, 8);
	
		if(!player)
		return PLUGIN_HANDLED;

		get_user_name(player, userName, charsmax(userName))
		get_user_ip(player, userIp, charsmax(userIp), 1)
		get_user_authid(player, userSteamid, charsmax(userSteamid))
		get_user_name(id, adminName, charsmax(adminName))
		get_user_ip(id, adminIp, charsmax(adminIp), 1)
		get_user_authid(id, adminSteamid, charsmax(adminSteamid))
		get_mapname(mapname,30)
		
		if(!wgscan[player])
		{
			wgChat(id, "%L", LANG_SERVER, "WG_INEXISTENT", PREFIX, userName);
			return PLUGIN_HANDLED;
		}
	
		cs_set_user_team(player, wg_team)
		wgscan[player] = false;
	
		wgChat(0, "%L", LANG_SERVER, "WG_OFF", PREFIX, userName);
		log_to_file(wg_log,"[WG VALID] %s [%s - %s] - %s [%s - %s] - [%s]^n",
		userName, userIp, userSteamid, adminName, adminIp, adminSteamid, mapname)
	}
	return PLUGIN_HANDLED;
}

public wgmenu(id, level, cid)
{
	if(!cmd_access(id, level, cid,1,true))
		return PLUGIN_HANDLED
		
	if(get_pcvar_num(wg_enable) == 1)
	{
		static MenuTitle[128], MenuItem[64], GetUserID[32], Name[32]
		static iMenu, iPlayers[32], iNum, iPlayer
	
		get_players(iPlayers, iNum, "ch")
	
		formatex(MenuTitle, charsmax(MenuTitle), "%L", LANG_PLAYER, "WG_MENU", DNS)
		iMenu = menu_create(MenuTitle, "handlewgmenu")
	
		for(new i=0; i < iNum; i++)
		{
			iPlayer = iPlayers[i]		
			get_user_name(iPlayer, Name, charsmax(Name))
			num_to_str(iPlayer, GetUserID, charsmax(GetUserID))
		
			if(wgscan[iPlayer])
				formatex(MenuItem, charsmax(MenuItem), "\w[\r*\w] \y%s \w - \rON WG SCAN", Name)
			else 
				formatex(MenuItem, charsmax(MenuItem), "\w[] \y%s", Name)
			
			menu_additem(iMenu, MenuItem, GetUserID,_, menu_makecallback("wgmenuscan"))
		
		}
	
		formatex(MenuItem, charsmax(MenuItem), "%L", LANG_PLAYER, "WG_NEXT")
		menu_setprop(iMenu, MPROP_NEXTNAME, MenuItem)
	
		formatex(MenuItem, charsmax(MenuItem), "%L", LANG_PLAYER, "WG_BACK")
		menu_setprop(iMenu, MPROP_BACKNAME, MenuItem)
	
		formatex(MenuItem, charsmax(MenuItem), "%L", LANG_PLAYER, "WG_EXIT")
		menu_setprop(iMenu, MPROP_EXITNAME, MenuItem)
	
		menu_display(id,iMenu,0)
	}
	return PLUGIN_HANDLED
}

public wgmenuscan(id, iMenu, iItem)
{
	new iAccess, Info[3], iCallback
	menu_item_getinfo(iMenu, iItem, iAccess, Info, sizeof Info - 1, _, _, iCallback)
	
	new iGetID = str_to_num(Info)
	
	if(get_user_flags(iGetID) & ADMIN_IMMUNITY)
	{
		return ITEM_DISABLED
	} 
	return ITEM_ENABLED
}

public handlewgmenu(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	
	new wgData[6], wgName[64]
	new access, callback
	menu_item_getinfo(iMenu, iItem, access, wgData, charsmax(wgData), wgName, charsmax(wgName), callback)

	CachedUserID = str_to_num(wgData)
	
	get_user_name(CachedUserID, CachedUsername,charsmax(CachedUsername))
	client_cmd(id, "amx_wg %s", CachedUserID)
	
	menu_destroy(iMenu)
	return PLUGIN_HANDLED 
}

public wglist(id, level, cid)
{
	if(!cmd_access(id, level, cid,1,true))
		return PLUGIN_HANDLED
		
	if(get_pcvar_num(wg_enable) == 1)
	{
		static iPlayers[32], iNum, iPlayer, GetUserID[32], Name[32]
	
		get_players(iPlayers, iNum, "ch")
	
		console_print(id, "^n==========[ WG WATCH LIST ]==========^n")
	
		for(new i=0; i < iNum; i++)
		{
			iPlayer = iPlayers[i]
		
			get_user_name(iPlayer, Name, charsmax(Name))
			num_to_str(iPlayer, GetUserID, charsmax(GetUserID))
		
			if(wgscan[iPlayer])
			{
				console_print(id, "[CS] ### %s  -  ON WG SCAN^n", Name)
			}		
		}
		console_print(id,"=================================^n")
		client_cmd(id,"toggleconsole")
	}
	return PLUGIN_HANDLED
}

public wginfo(id)
{
   show_motd(id,"addons/amxmodx/configs/wginfo.html")
}

public plugin_precache()
{
	get_localinfo("amxx_configsdir", wg_log, sizeof(wg_log) -1);
	format(wg_log, sizeof(wg_log) -1, "%s/%s", wg_log, wg_logName);
    
	if(!dir_exists(wg_log))
	mkdir(wg_log);
        
	new wgCurentDate[15];
	get_time("%d-%m-%Y", wgCurentDate , sizeof(wgCurentDate) -1);
    
	format(wg_log, sizeof(wg_log) -1, "%s/%s_%s.txt", wg_log, wg_logName, wgCurentDate);
    
	if(!file_exists(wg_log))
	{
			
		write_file(wg_log, "#============================================================================================#", -1);
		write_file(wg_log, "##=================================[ WG WATCH LOG ]=========================================##", -1);
		write_file(wg_log, "###======= [WG R/V/B] user [ip - steamid] - admin [ip - steamid] - [map name] =============###", -1);
		write_file(wg_log, "####======================================================================================####", -1);
		write_file(wg_log, " ", -1);
		write_file(wg_log, " ", -1);
	}
}

stock wgChat(const id, const input[], any:...)
{
	new Count = 1, Players[32];
	static Msg[191];
	vformat(Msg, 190, input, 3);
 
	replace_all(Msg, 190, "!g", "^4");
	replace_all(Msg, 190, "!y", "^1");
	replace_all(Msg, 190, "!t", "^3");
 
	if(id) Players[0] = id; else get_players(Players, Count, "ch");
	{
		for (new i = 0; i < Count; i++)
		{
			if (is_user_connected(Players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, Players[i]);
				write_byte(Players[i]);
				write_string(Msg);
				message_end();
			}
		}
	}
	return PLUGIN_HANDLED
}
