CMD:setsalesmod(playerid, params[]) {
	if(PlayerInfo[playerid][pAdmin] < 4)
		return SendClientMessage(playerid, COLOR_GREY, "You are not authorised to use this command.");
		
	if(AdminDuty[playerid] != 1 && PlayerInfo[playerid][pAdmin] < 5)
		return SendClientMessage(playerid,COLOR_WHITE, "You're not on-duty as admin. To access your admin commands you must be on-duty. Type /aduty to go on-duty.");

	new
		iTargetID,
		iSalesMod;
		
	if(sscanf(params, "ud", iTargetID, iSalesMod)) {
		SendClientMessage(playerid, COLOR_WHITE, "USAGE: /setsalesmod [playerid/partofname] [1 or 0]");
		return SendClientMessage(playerid, COLOR_ORANGE, "WARNING: This gives the player permission to assign donator-only features. Use with care.");
	}
	
	if(iTargetID == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_GREY, "That player is offline.");

	if(iTargetID == playerid)
		return SendClientMessage(playerid, COLOR_GREY, "You may not use this command on yourself to avoid abuse.");
	
	if(strval(iSalesMod) != 1 && strval(iSalesMod) != 0)
		return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /setsalesmod [playerid/partofname] [1 or 0]");

	if(PlayerInfo[iTargetID][pSalesTeam] == strval(iSalesMod))
		return SendClientMessage(playerid, COLOR_GREY, "This player is already this level.");
		
	PlayerInfo[iTargetID][pSalesTeam] = strval(iSalesMod);

	new
		szBoolStr[9],
		szSalesStr[128],
		szPlayerName[MAX_PLAYER_NAME],
		szTargetName[MAX_PLAYER_NAME];
		
	GetPlayerName(playerid, szPlayerName, sizeof(szPlayerName));
	GetPlayerName(iTargetID, szTargetName, sizeof(szTargetName));
		
	szBoolStr = (strval(iSalesMod) == 1) ? "now" : "no longer";

	format(szSalesStr, sizeof(szSalesStr), "You are %s a Sales Team member.", szBoolStr);
	SendClientMessage(iTargetID, COLOR_LIGHTBLUE, szBoolStr);
	SendClientMessage(iTargetID, COLOR_WHITE, "You now have access to /donators, /setdonator, /createpvehicle, land commands, give mp3 and give boombox commands!");
	
	format(szSalesStr, sizeof(szSalesStr), "AdmCmd: %s has set %s to %s be a Sales Team member.", szPlayerName, szTargetName, szBoolStr);
	Log("logs/salesteam.log", szSalesStr);
	return ABroadCast(COLOR_LIGHTRED, szSalesStr, 1);
}
