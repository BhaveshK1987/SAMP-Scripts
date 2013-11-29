/* Change commands of:
	donators -> donators, setdonator, give boombox, give mp3, set double xp
	businesses -> createbusiness, editbusiness
	lands -> create land, edit land
admin level check to this */

if(PlayerInfo[playerid][pAdmin] >= 5 || PlayerInfo[playerid][pSalesTeam] == 1)



/* Change:
	cmd:createpvehicle
admin level check to this */

if(PlayerInfo[playerid][pAdmin] < 5 && PlayerInfo[playerid][pSalesTeam] == 0)
	return SendClientMessage(playerid, COLOR_GREY, "You're not allowed to use this command.");
	
	
/* Add the following to the end of every sales team-related command (dynamic doors, createpvehicle, createbusiness, et cetera) */
	
	new
		szSalesStr[128],
		szSalesName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, szSalesName, sizeof(szSalesName));
	format(szSalesStr, sizeof(szSalesStr), "AdmCmd: %s has edited/created/deleted a XXXXXX.", szSalesName); // Replace XXXXXXX with Dynamic Door, business, house, et cetera
	Log("logs/salesteam.log", szSalesStr);
	
	/* Or, for player features */
	
	new
		szSalesStr[128],
		szSalesName[MAX_PLAYER_NAME],
		szSalesTName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, szSalesName, sizeof(szSalesName));
	GetPlayerName(iTargetID, szSalesTName, sizeof(szSalesTName));
	format(szSalesStr, sizeof(szSalesStr), "AdmCmd: %s has edited/created/deleted %s's XXXXXX.", szSalesName, szSalesTName); // Replace XXXXXXX with Dynamic Door, business, house, car, et cetera
	Log("logs/salesteam.log", szSalesStr);
