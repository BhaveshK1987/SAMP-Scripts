/* Add to safedeposit */

    SendClientMessage(playerid, COLOR_GRAD2, "Available names: Cash, Materials, Pot, Crack, Chemicals.");

	else if(strcmp(choice,"Chemicals",true) == 0) {
		if(amount > PlayerInfo[playerid][pChemicals] || amount < 1) {
			SendClientMessage(playerid, COLOR_GRAD2, "You don't have that much.");
			return true;
		}
		new year, month,day;
		getdate(year, month, day);
		FamilyInfo[family][FamilyChems] += amount;
		PlayerInfo[playerid][pChemicals] -= amount;
		format(string, sizeof(string), "You have successfully deposited %d chemicals into your family safe", amount);
		SendClientMessage(playerid, COLOR_YELLOW, string);
		format(string,sizeof(string), "* %s takes out some chemicals, and puts them in their safe.", GetPlayerNameEx(playerid));
		ProxDetector(30.0, playerid, string, COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE);
		new szIP[32];
		GetPlayerIp(playerid, szIP, sizeof(szIP));
		format(string,sizeof(string),"%s (IP: %s) has deposited %d chemicals into family safe %d.",GetPlayerNameEx(playerid),szIP,amount,PlayerInfo[playerid][pGang]);
		Log("logs/pay.log", string);
	}
	
/* Add to FamilyInfo enum */

	FamilyChems,
	
/* Add to safewithdraw */

    SendClientMessage(playerid, COLOR_GRAD2, "Available names: Cash, Materials, Pot, Crack.");
    
    else if(strcmp(choice,"Chemicals",true) == 0) {
		if(amount > FamilyInfo[family][FamilyMats] || amount < 1) {
			SendClientMessage(playerid, COLOR_GRAD2, "Your family doesn't have that much.");
			return true;
		}
		new year, month,day;
		getdate(year, month, day);
		FamilyInfo[family][FamilyChems] -= amount;
		PlayerInfo[playerid][pChemicals] += amount;
		format(string, sizeof(string), "You have successfully withdrawn %d chemicals from your family safe.", amount);
		SendClientMessage(playerid, COLOR_YELLOW, string);
		format(string,sizeof(string), "* %s withdraws some chemicals from their family safe.", GetPlayerNameEx(playerid));
		ProxDetector(30.0, playerid, string, COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE);
		new szIP[32];
		GetPlayerIp(playerid, szIP, sizeof(szIP));
		format(string,sizeof(string),"%s (IP: %s) (ID: %d) has withdrawn %d materials from family safe %d.",GetPlayerNameEx(playerid), szIP, PlayerInfo[playerid][pID], amount, PlayerInfo[playerid][pGang]+1);
		Log("logs/family.log", string);
		format(string, sizeof(string), "%d chemicals", amount);
		familyLog(PlayerInfo[playerid][pID], PlayerInfo[playerid][pID], PlayerInfo[playerid][pGang], 5, string);
	}
	
/* Edit safebalance */

    format(string, sizeof(string), " Safe: %s | Gunlockers: %d/10 | Cash: $%d | Pot: %d | Crack: %d | Materials: %d | Chemicals: %d", FamilyInfo[PlayerInfo[playerid][pGang]][FamilyName], weaponsinlocker, FamilyInfo[PlayerInfo[playerid][pGang]][FamilyCash], FamilyInfo[PlayerInfo[playerid][pGang]][FamilyPot], FamilyInfo[PlayerInfo[playerid][pGang]][FamilyCrack], FamilyInfo[PlayerInfo[playerid][pGang]][FamilyMats],FamilyInfo[PlayerInfo[playerid][pGang]][FamilyChems]);
    
/* Add to adjust safe */

    FamilyInfo[family][FamilyChems] = 0;
