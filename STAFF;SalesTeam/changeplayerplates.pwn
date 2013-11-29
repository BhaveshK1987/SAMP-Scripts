/* Add to Lawless script */

CMD:changeplayerplates(playerid, params[]) {
	if(AdminDuty[playerid] == 1) {
  		SendClientMessage(playerid,COLOR_WHITE, "You can't use this command while on-duty as admin.");
		return true;
	}

	if(PlayerInfo[playerid][pAdmin] < 5 && PlayerInfo[playerid][pSalesTeam] == 0)
		return SendClientMessage(playerid, COLOR_GRAD1, "You're not authorized to use that command!");

	new
		iTargetID,
		szColor[32],
		szPlate[32];

	if(sscanf(params, "us[32]s[32]", iTargetID, szColor, szPlate))
	{
		SendClientMessage(playerid, COLOR_WHITE, "USAGE: /changeplayerplates [playerid] [color] [new plate]");
		SendClientMessage(playerid, COLOR_GREY, "Available colors: {EFEFEF}default, black, white, blue, red, green, purple");
		SendClientMessage(playerid, COLOR_GREY, "{EFEFEF}yellow, lightblue, darkgreen, darkblue, darkgrey, darkbrown, pink");
		return true;
	}
	new
		Float: fVehicleHealth,
		iCount;

	for(new d = 0 ; d < MAX_PLAYERVEHICLES; d++) {
		if(IsPlayerInVehicle(iTargetID, PlayerVehicleInfo[iTargetID][d][pvId])) {
			iCount = 1;

			GetVehicleHealth(PlayerVehicleInfo[iTargetID][d][pvId], fVehicleHealth);

			if(fVehicleHealth < 800)
				return SendClientMessage(playerid, COLOR_GREY, "The vehicle needs to have 800 HP before you can change the plates on it.");

			if(strlen(szPlate) > 12)
				return SendClientMessage(playerid, COLOR_GREY, "The license plate can not be longer than 12 characters!");

			mysql_real_escape_string(szPlate, szPlate, g_MySQLConnections[0]);

			if(strcmp(szColor, "black", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{000000}%s", szPlate);
			else if(strcmp(szColor, "white", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{FFFFFF}%s", szPlate);
			else if(strcmp(szColor, "blue", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{2641FE}%s", szPlate);
			else if(strcmp(szColor, "red", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{AA3333}%s", szPlate);
			else if(strcmp(szColor, "green", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{33AA33}%s", szPlate);
			else if(strcmp(szColor, "purple", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{C2A2DA}%s", szPlate);
			else if(strcmp(szColor, "yellow", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{FFFF00}%s", szPlate);
			else if(strcmp(szColor, "lightblue", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{33CCFF}%s", szPlate);
			else if(strcmp(szColor, "darkgreen", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{2D6F00}%s", szPlate);
			else if(strcmp(szColor, "darkblue", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{0B006F}%s", szPlate);
			else if(strcmp(szColor, "darkgrey", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{525252}%s", szPlate);
			else if(strcmp(szColor, "gold", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{B46F00}%s", szPlate);
			else if(strcmp(szColor, "darkbrown", true)==0||strcmp(szColor, "dennell", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{814F00}%s", szPlate);
			else if(strcmp(szColor, "darkred", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{750A00}%s", szPlate);
			else if(strcmp(szColor, "pink", true)==0) format(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], 32, "{FF51F1}%s", szPlate);
			else strmid(PlayerVehicleInfo[iTargetID][d][pvNumberPlate], szPlate, 0, strlen(szPlate), 32);

			GetPlayerPos(PlayerVehicleInfo[iTargetID][d][pvId], PlayerInfo[iTargetID][pPos_x], PlayerInfo[iTargetID][pPos_y], PlayerInfo[iTargetID][pPos_z]);
			GetVehicleZAngle(PlayerVehicleInfo[iTargetID][d][pvId], PlayerInfo[iTargetID][pPos_r]);

			cmd_park(iTargetID, params);
			
			new
				szSalesStr[128];	
			format(szSalesStr, sizeof(szSalesStr), "AdmCmd: %s has set %s's number plate to %s.", szPlayerName, szTargetName, szPlate);
			Log("logs/salesteam.log", szSalesStr);
		}
	}

	if(iCount != 1)
		return SendClientMessage(playerid, COLOR_GREY, "The player needs to be in the car to have its number plate modified.");

	return true;
}
