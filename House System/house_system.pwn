#include <a_samp>
#include <core>
#include <float>

#include sscanf2
#include a_mysql
#include zcmd
#include GZ_ShapesALS
#include ArrayList

#define TABLE_HOUSE 1
#define TABLE_CAR 2
#define TABLE_BUSINESS 3

#define BYTES_PER_CELL 4

#define COLOUR_HOUSEGREEN 0x9ACD32FF
#define COLOUR_HOUSEBLUE 0x00B9FFFF

#define MAX_STREET_NAME 64

#define MAX_HOUSES 1000

forward RemovePlayerFromHouse(iPlayerID, iHouseID);
forward UnfreezePlayer(iPlayerID);
forward DestroyGZ(iPlayerID);
forward SaveHouses();

new iPlayerGPSMarker[MAX_PLAYERS];

new MySQL:gConn;
new bool:bCreatingHouse[MAX_PLAYERS];
new iHouseLevel[MAX_PLAYERS],
	iHouseTimer[MAX_PLAYERS],
	iHousePrice[MAX_PLAYERS],
	iHouseCancel[MAX_PLAYERS],
	Float:fHouseEnter[MAX_PLAYERS][3],
	Float:fHouseExit[MAX_PLAYERS][3],
	iHouseInterior[MAX_PLAYERS],
	szStreetName[MAX_PLAYERS][MAX_STREET_NAME];

new g_iLoadedHouses;

enum pEnum {
	pMats,
	pCocaine,
	pWeed,
	pGun[10],
	pMoney,
	pLevel
};

new PlayerInfo[MAX_PLAYERS][pEnum];

enum hEnum {
	bool:hExists,
	hLevel,
	hPrice,
	hAlarm,
	hCocaine,
	hCash,
	hWeed,
	hMats,
	hGun[10],
	hInterior,
	Float:hEntrance[3],
	Float:hExit[3],
	hOwner[32],
	hPickup,
	Text3D:hTextLabelExt,
	Text3D:hTextLabelInt,
	hStreetName[32],
	hLock
};
new HouseInfo[MAX_HOUSES][hEnum];

main()
{
	print("\tUS-RP Feature Test\n");
}

stock bool:DoesPlayerOwnHouse(iPlayerID, iHouseID)
{
	new szPlayerName[MAX_PLAYER_NAME],
	 	iUnderscore_Location;

	GetPlayerName(iPlayerID, szPlayerName, sizeof(szPlayerName));
	if(strfind(szPlayerName, "_", true) != -1 && strfind(HouseInfo[iHouseID][hOwner], "_", true) != -1)
	{
	    if(!strcmp(szPlayerName, HouseInfo[iHouseID][hOwner], true)) { return true; }
	    else { return false; }
	}
	else if(strfind(szPlayerName, "_", true) != -1 && strfind(HouseInfo[iHouseID][hOwner], "_", true) == -1)
	{
	    iUnderscore_Location = strfind(szPlayerName, "_", true);
	    szPlayerName[iUnderscore_Location] = ' ';
	    if(!strcmp(szPlayerName, HouseInfo[iHouseID][hOwner], true)) { return true; }
	    else { return false; }
	}
	return false;
}

public OnPlayerConnect(playerid)
{
	iHouseTimer[playerid] = -1;
	iPlayerGPSMarker[playerid] = -1;
	return 1;
}

stock InRangeOfHouse(iPlayerID, bool:bOutside, Float:fRange=5.0)
{
	if(bOutside == true)
	{
		for(new iHouseID; iHouseID < g_iLoadedHouses; iHouseID++)
		{
	    	if(GetPlayerDistanceFromPoint(iPlayerID, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]) < fRange) {
				return iHouseID;
			}
		}
	}
    else
	{
		for(new iHouseID; iHouseID < g_iLoadedHouses; iHouseID++)
		{
	    	if(GetPlayerDistanceFromPoint(iPlayerID, HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2]) < fRange && GetPlayerVirtualWorld(iPlayerID) == iHouseID)
	    	{
				return iHouseID;
			}
		}
	}
    return -1;
}

// ============================================== //
// ================ COMMAND BLOCK =============== //
// ============================================== //

// ========== COMMAND BLOCK - HOUSES ========== //

CMD:enter(playerid, params[])
{
	new iHouseID;
	if(InRangeOfHouse(playerid, true) != -1)
	{
	    iHouseID = InRangeOfHouse(playerid, true);
  	    if(!DoesPlayerOwnHouse(playerid, iHouseID)) {
  	        if(strcmp(HouseInfo[iHouseID][hOwner], "The Market")) {
  	            if(HouseInfo[iHouseID][hLock])
				  	return SendClientMessageEx(playerid, 0xFFFFFF00, "House {FF6347}%d %s{FFFFFF} is locked.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
				else {
				    SendClientMessageEx(playerid, 0xFFFFFF00, "You have entered {FF6347}%d %s{FFFFFF}, owned by {666666}%s{FFFFFF}.", iHouseID+1000, HouseInfo[iHouseID][hStreetName], HouseInfo[iHouseID][hOwner]);
					SetPlayerVirtualWorld(playerid, iHouseID);
		    		SetPlayerInterior(playerid, HouseInfo[iHouseID][hInterior]);
		   	 		SetPlayerPos(playerid, HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2]);
				}
			  	return 1;
			}
			else {
			    SendClientMessageEx(playerid, 0xFFFFFF00, "As {9ACD32}%d %s{FFFFFF} is not owned, you are allowed in for {FFFF00}15 seconds{FFFFFF} to look around.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
			    iHouseTimer[playerid] = SetTimerEx("RemovePlayerFromHouse", 15000, 0, "dd", playerid, iHouseID);
			    SetPlayerVirtualWorld(playerid, iHouseID);
			    SetPlayerInterior(playerid, HouseInfo[iHouseID][hInterior]);
			    SetPlayerPos(playerid, HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2]);
			}
		}
		else {
		    SendClientMessageEx(playerid, 0xFFFFFF00, "You have entered {9ACD32}%d %s{FFFFFF}, owned by you.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
			SetPlayerVirtualWorld(playerid, iHouseID);
		    SetPlayerInterior(playerid, HouseInfo[iHouseID][hInterior]);
		    SetPlayerPos(playerid, HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2]);
	    }
	}
	return 1;
}

CMD:exit(playerid, params[])
{
	new iHouseID;
	if(InRangeOfHouse(playerid, false) != -1)
	{
	    iHouseID = InRangeOfHouse(playerid, false);
	    printf("GetPlayerVirtualWorld(playerid): %d     iHouseID: %d", GetPlayerVirtualWorld(playerid), iHouseID);
	    if(GetPlayerVirtualWorld(playerid) == iHouseID)
	    {
		    SendClientMessageEx(playerid, 0xFFFFFF00, "You have exited {9ACD32}%d %s{FFFFFF}.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
		    SetPlayerVirtualWorld(playerid, 0);
		    SetPlayerInterior(playerid, 0);
		    SetPlayerPos(playerid, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]);
		    if(iHouseTimer[playerid] != -1) {
				SendClientMessageEx(playerid, 0xFFFFFF00, "The Landlord says: Hope you buy %d %s!", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
				KillTimer(iHouseTimer[playerid]);
				iHouseTimer[playerid] = -1;
			}
		}
	}
	return 1;
}

stock SendClientMessageEx(playerid, color, fstring[], {Float, _}:...)
{
    static const STATIC_ARGS = 3;
    new n = (numargs() - STATIC_ARGS) * BYTES_PER_CELL;
    if(n)
    {
        new message[144],arg_start,arg_end;
        #emit CONST.alt        fstring
        #emit LCTRL          5
        #emit ADD
        #emit STOR.S.pri        arg_start

        #emit LOAD.S.alt        n
        #emit ADD
        #emit STOR.S.pri        arg_end
        do
        {
            #emit LOAD.I
            #emit PUSH.pri
            arg_end -= BYTES_PER_CELL;
            #emit LOAD.S.pri      arg_end
        }
        while(arg_end > arg_start);

        #emit PUSH.S          fstring
        #emit PUSH.C          144
        #emit PUSH.ADR         message

        n += BYTES_PER_CELL * 3;
        #emit PUSH.S          n
        #emit SYSREQ.C         format

        n += BYTES_PER_CELL;
        #emit LCTRL          4
        #emit LOAD.S.alt        n
        #emit ADD
        #emit SCTRL          4

        if(playerid == INVALID_PLAYER_ID)
        {
            #pragma unused playerid
            return SendClientMessageToAll(color, message);
        } else {
            return SendClientMessage(playerid, color, message);
        }
    } else {
        if(playerid == INVALID_PLAYER_ID)
        {
            #pragma unused playerid
            return SendClientMessageToAll(color, fstring);
        } else {
            return SendClientMessage(playerid, color, fstring);
        }
    }
}

CMD:gotohouse(playerid, params[])
{
	new iHouseID;
	if(!sscanf(params, "d", iHouseID))
	{
	    if(iHouseID >= 1000) iHouseID -= 1000;
		if(!HouseInfo[iHouseID][hExists]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} This house doesn't exist.");
		SetPlayerPos(playerid, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]);
		if(iHouseID >= 1000) { SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Teleported to house: {9ACD32}%d %s", iHouseID, HouseInfo[iHouseID][hStreetName]); }
		if(iHouseID < 1000) { SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Teleported to house: {9ACD32}%d %s", iHouseID+1000, HouseInfo[iHouseID][hStreetName]); }
		return 1;
	}
	else return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /gotohouse [House ID].");
}

CMD:edithouse(playerid, params[])
{
	new iHouseID,
		szOption[32],
		szParam[32];

	if(!sscanf(params, "ds[32]s[32]", iHouseID, szOption, szParam))
	{
	    if(iHouseID >= 1000) iHouseID -= 1000;
		if(!HouseInfo[iHouseID][hExists]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} This house doesn't exist.");
		if(!strcmp(szOption, "name"))
		{
		    format(HouseInfo[iHouseID][hStreetName], 32, szParam);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Edited name to: {9ACD32}%d %s", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
			Delete3DTextLabel(HouseInfo[iHouseID][hTextLabelExt]);
			DestroyPickup(HouseInfo[iHouseID][hPickup]);
			CreateHousePickup(iHouseID);
			SaveHouses();
		}
		else if(!strcmp(szOption, "price"))
		{
		    HouseInfo[iHouseID][hPrice] = strval(szParam);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Edited price to: {9ACD32}$%d", HouseInfo[iHouseID][hPrice]);
			Delete3DTextLabel(HouseInfo[iHouseID][hTextLabelExt]);
			DestroyPickup(HouseInfo[iHouseID][hPickup]);
			CreateHousePickup(iHouseID);
			SaveHouses();
		}
		else if(!strcmp(szOption, "level"))
		{
		    HouseInfo[iHouseID][hLevel] = strval(szParam);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Edited level to: {9ACD32}%d", HouseInfo[iHouseID][hLevel]);
			Delete3DTextLabel(HouseInfo[iHouseID][hTextLabelExt]);
			DestroyPickup(HouseInfo[iHouseID][hPickup]);
			CreateHousePickup(iHouseID);
			SaveHouses();
		}
		else if(!strcmp(szOption, "owner"))
		{
		    format(HouseInfo[iHouseID][hOwner], 32, szParam);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Edited owner to: {9ACD32}%s", HouseInfo[iHouseID][hOwner]);
			Delete3DTextLabel(HouseInfo[iHouseID][hTextLabelExt]);
			DestroyPickup(HouseInfo[iHouseID][hPickup]);
			CreateHousePickup(iHouseID);
			SaveHouses();
		}
		return 1;
	}
	else return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /edithouse [House ID] [Name/Price/Level] [Value].");
}

CMD:housesforsale(playerid, params[])
{
	SendClientMessage(playerid, 0xFFFFFF00, "Finding houses for sale on Eyefind.info...");
	FindAvailableHouse(playerid);
	return 1;
}

CMD:setskin(playerid, params[])
{
	new iSkin;
	if(!sscanf(params, "d", iSkin))
	{
		return SetPlayerSkin(playerid, iSkin);
	}
	return 1;
}

CMD:sethouse(playerid, params[])
{
	new szOption[32],
		szVal[32];

	if(bCreatingHouse[playerid] == false)
	    return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Not creating house. Use {9ACD32}/createhouse start{FFFFFF} to begin.");

    if(sscanf(params, "s[32]S(-1)[32]", szOption, szVal))
	    return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Use {9ACD32}/sethouse [enter/exit/price/level/name]{FFFFFF} to set parameters.");
    else
    {
		printf("szOption = '%s'\nszVal = '%s'", szOption, szVal);
        if(!strcmp(szOption, "enter", true))
        {
			GetPlayerPos(playerid, fHouseEnter[playerid][0], fHouseEnter[playerid][1], fHouseEnter[playerid][2]);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House entrance set to {9ACD32}%.2f{FFFFFF}, {9ACD32}%.2f{FFFFFF}, {9ACD32}%.2f{FFFFFF}", fHouseEnter[playerid][0], fHouseEnter[playerid][1], fHouseEnter[playerid][2]);
			return 1;
        }
        if(!strcmp(szOption, "exit", true))
        {
			GetPlayerPos(playerid, fHouseExit[playerid][0], fHouseExit[playerid][1], fHouseExit[playerid][2]);
			iHouseInterior[playerid] = GetPlayerInterior(playerid);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House exit set to {9ACD32}%.2f{FFFFFF}, {9ACD32}%.2f{FFFFFF}, {9ACD32}%.2f{FFFFFF}, interior: %d", fHouseEnter[playerid][0], fHouseEnter[playerid][1], fHouseEnter[playerid][2], iHouseInterior[playerid]);
			return 1;
        }
        if(!strcmp(szOption, "name", true))
        {
            format(szStreetName[playerid], MAX_STREET_NAME, szVal);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Street Name set to {9ACD32}%s{FFFFFF}", szVal);
			return 1;
        }
        if(!strcmp(szOption, "price", true))
        {
			if(strval(szVal) <= 0)
			    return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Use {9ACD32}/sethouse price [price - must be above 0]{FFFFFF} to set price.");

			iHousePrice[playerid] = strval(szVal);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House price set to $%d.", strval(szVal));
			return 1;
        }
        if(!strcmp(szOption, "level", true))
        {
			if(strval(szVal) <= 0)
			    return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Use {9ACD32}/sethouse level [level - must be above 0]{FFFFFF} to set purchasing level.");

			iHouseLevel[playerid] = strval(szVal);
			SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House purchase level set to %d.", strval(szVal));
			return 1;
        }
    }
	return 1;
}

CMD:deletehouse(playerid, params[])
{
    new iHouseID;
	if(!sscanf(params, "d", iHouseID))
	{
	    if(iHouseID >= 1000) iHouseID -= 1000;
	    Delete3DTextLabel(HouseInfo[iHouseID][hTextLabelExt]);
		DestroyPickup(HouseInfo[iHouseID][hPickup]);
		HouseInfo[iHouseID][hExists] = false;
		SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Destroyed house {9ACD32}%d %s{FFFFFF}.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
		SaveHouses();
		
		new szQuery[256];
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `house_exists` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hExists], iHouseID);
		mysql_tquery(gConn, szQuery);
		printf("%s", szQuery);
	}
	return 1;
}

CMD:setstat(playerid, params[])
{
	new szOption[10],
	    iValue,
	    iGun;
	    
    if(!sscanf(params, "s[10]dD(0)", szOption, iValue, iGun)) {
        if(!strcmp(szOption, "mats")) {
			PlayerInfo[playerid][pMats] = iValue;
			SendClientMessageEx(playerid, 0xFFFFFF00, "Given {999999}%d{FFFFFF} materials to yourself.", iValue);
        }
        else if(!strcmp(szOption, "cocaine")) {
            PlayerInfo[playerid][pCocaine] = iValue;
            SendClientMessageEx(playerid, 0xFFFFFF00, "Given {CCCCCC}%dg cocaine{FFFFFF} to yourself.", iValue);
        }
        else if(!strcmp(szOption, "weed")) {
            PlayerInfo[playerid][pWeed] = iValue;
            SendClientMessageEx(playerid, 0xFFFFFF00, "Given {00AA00}%dg weed{FFFFFF} to yourself.", iValue);
        }
        else if(!strcmp(szOption, "money")) {
            PlayerInfo[playerid][pMoney] = iValue;
            GivePlayerMoney(playerid, -GetPlayerMoney(playerid));
            GivePlayerMoney(playerid, iValue);
            SendClientMessageEx(playerid, 0xFFFFFF00, "Given {00AA00}$%d{FFFFFF} to yourself.", iValue);
        }
        else if(!strcmp(szOption, "gun")) {
            PlayerInfo[playerid][pGun][iValue] = iGun;
            ReloadPlayerGuns(playerid);
            SendClientMessageEx(playerid, 0xFFFFFF00, "Given %s (%d) to yourself in slot %d.", GetWeaponNameEx(iGun), iGun, iValue);
        }
    }
    else {
        SendClientMessageEx(playerid, 0xFFFFFF00, "Use {9ACD32}/setstat [mats/cocaine/weed/money/gun] [amount] [gun ID (optional)]");
    }
    return 1;
}

CMD:stats(playerid, params[])
{
	SendClientMessageEx(playerid, 0xFFFFFF00, "| Cash: {00AA00}$%d{FFFFFF} | Materials: {999999}%d{FFFFFF} | Cocaine: {CCCCCC}%dg{FFFFFF} | Weed: {00AA00}%dg{FFFFFF}", PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pMats], PlayerInfo[playerid][pCocaine], PlayerInfo[playerid][pWeed]);
	for(new iGunID = 0; iGunID < 10; iGunID++)
	{
    	 SendClientMessageEx(playerid, 0xFFFFFF00, "| Gun %d: {666666}%s{FFFFFF}", iGunID+1, GetWeaponNameEx(PlayerInfo[playerid][pGun][iGunID]));
	}
	return 1;
}

CMD:house(playerid, params[])
{
	new szOption[10],
	    szParam[24],
		iParamTwo,
		iHouseID = GetPlayerVirtualWorld(playerid);
	    
	if(!sscanf(params, "s[10]S(-1)[24]D(0)", szOption, szParam, iParamTwo)) {
	    if(!strcmp(szOption, "store")) {
     		if(iHouseID == 0) {
		    	return SendClientMessageEx(playerid, 0xFFFFFF00, "You are not in a house.");
			}
			if(!DoesPlayerOwnHouse(playerid, iHouseID)) {
				return SendClientMessageEx(playerid, 0xFFFFFF00, "You do not own {FF6347}%d %s{FFFFFF} so cannot use /house here.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
			}
            if(!strcmp(szParam, "cash")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house store cash [1-999999999]");
				else if(iParamTwo > PlayerInfo[playerid][pMoney]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't store more money than you have on you!");
				else if(iParamTwo <= PlayerInfo[playerid][pMoney] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hCash] += iParamTwo;
				    PlayerInfo[playerid][pMoney] -= iParamTwo;
				    GivePlayerMoney(playerid, -iParamTwo);
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Stored {00AA00}$%d{FFFFFF}!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "mats")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house store mats [1-999999999]");
				else if(iParamTwo > PlayerInfo[playerid][pMats]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't store more materials than you have on you!");
				else if(iParamTwo <= PlayerInfo[playerid][pMats] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hMats] += iParamTwo;
				    PlayerInfo[playerid][pMats] -= iParamTwo;
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Stored {666666}%d{FFFFFF} materials!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "cocaine")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house store cocaine [1-999999999]");
				else if(iParamTwo > PlayerInfo[playerid][pCocaine]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't store more cocaine than you have on you!");
				else if(iParamTwo <= PlayerInfo[playerid][pCocaine] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hCocaine] += iParamTwo;
				    PlayerInfo[playerid][pCocaine] -= iParamTwo;
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Stored {CCCCCC}%dg{FFFFFF} of cocaine!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "weed")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house store weed [1-999999999]");
				else if(iParamTwo > PlayerInfo[playerid][pWeed]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't store more weed than you have on you!");
				else if(iParamTwo <= PlayerInfo[playerid][pWeed] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hWeed] += iParamTwo;
				    PlayerInfo[playerid][pWeed] -= iParamTwo;
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Stored {CCCCCC}%dg{FFFFFF} of weed!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "gun")) {
				if(UnstorableGun(playerid, iParamTwo) == 1) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house store gun [gun ID]");
				else if(UnstorableGun(playerid, iParamTwo) == 2) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't store a weapon that you don't have on you!");
				else if(UnstorableGun(playerid, iParamTwo) == 0) {
				    PlayerInfo[playerid][pGun][GetGunSlot(playerid, iParamTwo)] = 0;
				    printf("NextGunSlot(iHouseID) = %d", NextGunSlot(iHouseID));
				    HouseInfo[iHouseID][hGun][NextGunSlot(iHouseID)] = iParamTwo;
					ReloadPlayerGuns(playerid);
					SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Stored {999999}%s{FFFFFF}!", GetWeaponNameEx(iParamTwo));
				}
	    	}
	    	else {
				return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house store [cash/cocaine/weed/mats/gun]");
	    	}
	    } else if(!strcmp(szOption, "withdraw")) {
	    	if(iHouseID == 0) {
		    	return SendClientMessageEx(playerid, 0xFFFFFF00, "You are not in a house.");
			}
			if(!DoesPlayerOwnHouse(playerid, iHouseID)) {
				return SendClientMessageEx(playerid, 0xFFFFFF00, "You do not own {FF6347}%d %s{FFFFFF} so cannot use /house here.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
			}
	    	if(!strcmp(szParam, "cash")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house withdraw cash [1-999999999]");
				else if(iParamTwo > HouseInfo[iHouseID][hCash]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't withdraw more money than you have stored!");
				else if(iParamTwo <= HouseInfo[iHouseID][hCash] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hCash] -= iParamTwo;
				    PlayerInfo[playerid][pMoney] += iParamTwo;
				    GivePlayerMoney(playerid, iParamTwo);
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Withdrew {00AA00}$%d{FFFFFF}!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "mats")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house withdraw mats [1-999999999]");
				else if(iParamTwo > HouseInfo[iHouseID][hMats]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't withdraw more materials than you have stored!");
				else if(iParamTwo <= HouseInfo[iHouseID][hMats] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hMats] -= iParamTwo;
				    PlayerInfo[playerid][pMats] += iParamTwo;
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Withdrew {666666}%d{FFFFFF} materials!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "cocaine")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house withdraw cocaine [1-999999999]");
				else if(iParamTwo > HouseInfo[iHouseID][hCocaine]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't withdraw more cocaine than you have stored!");
				else if(iParamTwo <= HouseInfo[iHouseID][hCocaine] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hCocaine] -= iParamTwo;
				    PlayerInfo[playerid][pCocaine] += iParamTwo;
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Withdrew {CCCCCC}%dg{FFFFFF} of cocaine!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "weed")) {
				if(iParamTwo <= 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house withdraw weed [1-999999999]");
				else if(iParamTwo > HouseInfo[iHouseID][hWeed]) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't withdraw more weed than you have stored!");
				else if(iParamTwo <= HouseInfo[iHouseID][hWeed] && iParamTwo > 0) {
				    HouseInfo[iHouseID][hWeed] -= iParamTwo;
				    PlayerInfo[playerid][pWeed] += iParamTwo;
				    SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Withdrew {9ACD32}%dg{FFFFFF} of weed!", iParamTwo);
				}
	    	}
	    	if(!strcmp(szParam, "gun")) {
				if(HouseInfo[iHouseID][hGun][iParamTwo] == 0) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You can't withdraw a weapon that you don't have stored!");
				else if(TakeableGun(iHouseID, iParamTwo) == 1) {
				    PlayerInfo[playerid][pGun][NextGunSlot(playerid, true)] = HouseInfo[iHouseID][hGun][iParamTwo];
				    HouseInfo[iHouseID][hGun][iParamTwo] = 0;
					ReloadPlayerGuns(playerid);
					SaveHouse(iHouseID);
				    return SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Withdrew {999999}%s{FFFFFF}!", GetWeaponNameEx(HouseInfo[iHouseID][hGun][iParamTwo]));
				}
	    	}
	    	else {
				return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house withdraw [cash/cocaine/weed/mats/gun]");
	    	}
	    } else if(!strcmp(szOption, "find")) {
	        if(iPlayerGPSMarker[playerid] != -1) {
	            return SendClientMessage(playerid, 0xFFFFFF00, "You already have an active search. Wait until it's done.");
	        }
	        SendClientMessageEx(playerid, 0xFFFFFF00, "Searching for {9ACD32}\"%s\"{FFFFFF} in your GPS...", szParam);
			FindHouseByName(playerid, szParam);
	    } else if(!strcmp(szOption, "info")) {
			if(iHouseID == 0) {
			   	return SendClientMessageEx(playerid, 0xFFFFFF00, "You are not in a house.");
			}
			SendClientMessageEx(playerid, 0xFFFFFF00, "|_______________ INVENTORY OF {9ACD32}%d %s{FFFFFF} _______________|", iHouseID, HouseInfo[iHouseID][hStreetName]);
			SendClientMessageEx(playerid, 0xFFFFFF00, "Cash: {00AA00}$%d{FFFFFF} | Materials: {999999}%d{FFFFFF} | Cocaine: {CCCCCC}%dg{FFFFFF} | Weed: {00AA00}%dg{FFFFFF}", HouseInfo[iHouseID][hCash], HouseInfo[iHouseID][hMats], PlayerInfo[playerid][pCocaine], HouseInfo[iHouseID][hWeed]);
			for(new iGunID = 0; iGunID < 10; iGunID++)
			{
    			SendClientMessageEx(playerid, 0xFFFFFF00, "| Gun %d: {666666}%s{FFFFFF}", iGunID+1, GetWeaponNameEx(HouseInfo[iHouseID][hGun][iGunID]));
			}
			return 1;
	    } else return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house [store/withdraw/find/info]");
	}
	else {
	    return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /house [store/withdraw/find/info]");
	}
	return 1;
}

stock FindHouseByName(iPlayerID, szHouseName[])
{
	new ArrayList:aHouseNum = NewArrayList<INTEGER>(20);
	for(new iHouseID; iHouseID < g_iLoadedHouses; iHouseID++) {
		if(strfind(HouseInfo[iHouseID][hStreetName],szHouseName,true) != -1) {
			ArrayList::Add(aHouseNum, iHouseID);
	 	}
	}
	new iHouseID = ArrayList::Get(aHouseNum, random(ArrayList::Size(aHouseNum)));
	iPlayerGPSMarker[iPlayerID] = GZ_ShapeCreate(CIRCLE, HouseInfo[iHouseID][hEntrance][0]+randomEx(-50,50), HouseInfo[iHouseID][hEntrance][1]+randomEx(-50,50), 150);
	GZ_ShapeShowForPlayer(iPlayerID, iPlayerGPSMarker[iPlayerID], 0xFF0000CC);
	GZ_ShapeFlashForPlayer(iPlayerID, iPlayerGPSMarker[iPlayerID], 0x0000AACC);
	SendClientMessageEx(iPlayerID, 0xFFFFFF00, "First match: {9ACD32}%s{FFFFFF}. A 150m area is now flashing on your GPS for 20 seconds.", HouseInfo[iHouseID][hStreetName]);
	SetTimerEx("DestroyGZ", 20000, 0, "d", iPlayerID);
	return iHouseID;
}

stock FindAvailableHouse(iPlayerID)
{
	new ArrayList:aHouseNum = NewArrayList<INTEGER>(50);
	for(new iHouseID; iHouseID < g_iLoadedHouses; iHouseID++) {
		if(!strcmp(HouseInfo[iHouseID][hOwner],"The Market",true)) {
			ArrayList::Add(aHouseNum, iHouseID);
	 	}
	}
	new iHouseID = ArrayList::Get(aHouseNum, random(ArrayList::Size(aHouseNum)));
	iPlayerGPSMarker[iPlayerID] = GZ_ShapeCreate(CIRCLE, HouseInfo[iHouseID][hEntrance][0]+randomEx(-50,50), HouseInfo[iHouseID][hEntrance][1]+randomEx(-50,50), 150);
	GZ_ShapeShowForPlayer(iPlayerID, iPlayerGPSMarker[iPlayerID], 0xFF0000CC);
	GZ_ShapeFlashForPlayer(iPlayerID, iPlayerGPSMarker[iPlayerID], 0x0000AACC);
	SendClientMessageEx(iPlayerID, 0xFFFFFF00, "Match: {9ACD32}%s{FFFFFF}. A 150m area is now flashing on your GPS for 20 seconds.", HouseInfo[iHouseID][hStreetName]);
	SetTimerEx("DestroyGZ", 20000, 0, "d", iPlayerID);
	return iHouseID;
}

stock randomEx(min, max)
{
    new rand = random(max-min)+min;
    return rand;
}

public DestroyGZ(iPlayerID)
{
    GZ_ShapeDestroy(iPlayerGPSMarker[iPlayerID]);
    iPlayerGPSMarker[iPlayerID] = -1;
	return 1;
}

stock TakeableGun(iHouseID, iWeaponID)
{
	if(iWeaponID < 0) return 0;
	switch(iWeaponID)
	{
	    case 0,35..46: return 0; // If trying to store fists or admin guns, computer says no
	}
	for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns player has in stats (so no admin-given guns)
	{
	    if(HouseInfo[iHouseID][hGun][iIdx] == iWeaponID) { return 1; } // If house has one of these weapons, allow them to be withdrawn.
	}
	return 2; // Didn't find weapon in house
}

stock UnstorableGun(iPlayerID, iWeaponID)
{
	if(iWeaponID < 0) return 0;
	switch(iWeaponID)
	{
	    case 0,35..46: return 0; // If trying to withdraw fists or admin guns, computer says no
	}
	for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns player has in stats (so no admin-given guns)
	{
	    if(PlayerInfo[iPlayerID][pGun][iIdx] == iWeaponID) { return 0; } // If player has one of these weapons, allow them to be stored.
	}
	return 2; // Didn't try to store an unstorable weapon; don't have a gun in stats; player does not have weapon - cannot store.
}

stock GetGunSlot(iPlayerID, iWeaponID, bool:bOnPlayer=true)
{
	if(bOnPlayer == true) {
	    for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns player has in stats (so no admin-given guns)
		{
		    if(PlayerInfo[iPlayerID][pGun][iIdx] == iWeaponID) { return iIdx; } // If player has one of these weapons, return what slot it's in.
		}
	}
	else if(bOnPlayer == false) {
	    for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns house has in stats
		{
		    if(HouseInfo[iPlayerID][hGun][iIdx] == iWeaponID) { return iIdx; } // If house has one of these weapons, return what slot it's in.
		}
	}
	return -1;
}

stock NextGunSlot(iHouseID, bool:bCheckPlayer=false)
{
	if(bCheckPlayer == false)
	{
	    for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns house has in stats
		{
		    if(HouseInfo[iHouseID][hGun][iIdx] == 0) { return iIdx; } // If house has an empty slot, return slot ID.
		}
	}
	else if(bCheckPlayer == true)
	{
	    for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns player has in stats (so no admin-given guns)
		{
		    if(PlayerInfo[iHouseID][pGun][iIdx] == 0) { return iIdx; } // If player has an empty slot, return slot ID.
		}
	}
	return -1;
}

stock ReloadPlayerGuns(iPlayerID)
{
	ResetPlayerWeapons(iPlayerID);
	for(new iIdx; iIdx < 10; iIdx++) // Loop through all guns player has in stats (so no admin-given guns)
	{
	    if(PlayerInfo[iPlayerID][pGun][iIdx] > 0) { GivePlayerWeapon(iPlayerID, PlayerInfo[iPlayerID][pGun][iIdx], 100000); } // If player has weapon in stats, give.
	}
	return 1;
}

stock GetWeaponNameEx(iWeaponID)
{
	new szWeaponName[32];
	if(iWeaponID == 0) { format(szWeaponName, sizeof(szWeaponName), "None"); return szWeaponName; }
	GetWeaponName(iWeaponID, szWeaponName, sizeof(szWeaponName));
	return szWeaponName;
}

CMD:tp(playerid, params[])
{
	new iTP;
	if(!sscanf(params, "d", iTP))
	{
	    switch(iTP) {
	        case 1: { SetPlayerPos(playerid, 235.508994, 1189.169897, 1080.339966); SetPlayerInterior(playerid, 3); SendClientMessage(playerid, 0xFFFFFF00, "House 1. Value: 350,000 - 550,000"); }
	        case 2: { SetPlayerPos(playerid, 225.756989, 1240.000000, 1082.149902); SetPlayerInterior(playerid, 2); SendClientMessage(playerid, 0xFFFFFF00, "House 2. Value: 150,000 - 350,000"); }
	        case 3: { SetPlayerPos(playerid, 223.043991, 1289.259888, 1082.199951); SetPlayerInterior(playerid, 1); SendClientMessage(playerid, 0xFFFFFF00, "House 3. Value: 90,000 - 150,000"); }
	        case 4: { SetPlayerPos(playerid, 225.630997, 1022.479980, 1084.069946); SetPlayerInterior(playerid, 7); SendClientMessage(playerid, 0xFFFFFF00, "House 4. Value: 550,000 - 1,000,000"); }
	        case 5: { SetPlayerPos(playerid, 295.138977, 1474.469971, 1080.519897); SetPlayerInterior(playerid, 15); SendClientMessage(playerid, 0xFFFFFF00, "House 5. Value: 150,000 - 350,000"); }
	        case 6: { SetPlayerPos(playerid, 328.493988, 1480.589966, 1084.449951); SetPlayerInterior(playerid, 15); SendClientMessage(playerid, 0xFFFFFF00, "House 6. Value: 120,000 - 300,000"); }
	        case 7: { SetPlayerPos(playerid, 385.80398, 1471.769897, 1080.209961); SetPlayerInterior(playerid, 15); SendClientMessage(playerid, 0xFFFFFF00, "House 7. Value: 100,000 - 200,000"); }
	        case 8: { SetPlayerPos(playerid, 2567.52, -1294.59, 1063.25); SetPlayerInterior(playerid, 2); SendClientMessage(playerid, 0xFFFFFF00, "Big Smoke's. Value: 550,000 - 850,000"); }
	        case 9: { SetPlayerPos(playerid, 2807.63, -1170.15, 1025.57); SetPlayerInterior(playerid, 8); SendClientMessage(playerid, 0xFFFFFF00, "Colonel Furhberger's. Value: 150,000 - 350,000"); }
	        case 10: { SetPlayerPos(playerid, -2170.3, 641, 1057); SetPlayerInterior(playerid, 1); SendClientMessage(playerid, 0xFFFFFF00, "Woozie's Apartment. Value: 250,000 - 450,000"); }
	        case 11: { SetPlayerPos(playerid, 318.565, 1115.210, 1082.98); SetPlayerInterior(playerid, 5); SendClientMessage(playerid, 0xFFFFFF00, "Crack Den. Value: 50,000 - 150,000"); }
	        case 12: { SetPlayerPos(playerid, 2269.9385,-1210.4886,1047.5625); SetPlayerInterior(playerid, 10); SendClientMessage(playerid, 0xFFFFFF00, "House 8. Value: 250,000 - 400,000"); }
	        case 13: { SetPlayerPos(playerid, 1299.14, -794.77, 1084.00); SetPlayerInterior(playerid, 5); SendClientMessage(playerid, 0xFFFFFF00, "Madd Dogg's. Value: 1,500,000 - 3,500,000"); }
	        case 14: { SetPlayerPos(playerid, 2262.83, -1137.71, 1050.63); SetPlayerInterior(playerid, 10); SendClientMessage(playerid, 0xFFFFFF00, "Motel Room. Value: 30,000 - 65,000"); }
	        case 15: { SetPlayerPos(playerid, 2365.101, -1134.85, 1050.88); SetPlayerInterior(playerid, 8); SendClientMessage(playerid, 0xFFFFFF00, "House 9. Value: 250,000 - 450,000"); }
	        case 16: { SetPlayerPos(playerid, 2324.33, -1148.7, 1050.71); SetPlayerInterior(playerid, 12); SendClientMessage(playerid, 0xFFFFFF00, "House 10. Value: 150,000 - 350,000"); }
			default: {
				SendClientMessage(playerid, 0xFFFFFF00, "/tp [House ID]");
				SendClientMessage(playerid, 0xFFFFFF00, "1. House1 {FFAA00}($450k){FFFFFF}		|		9. Furhberger {FFFF00}($250k)");
				SendClientMessage(playerid, 0xFFFFFF00, "2. House2 {FFFF00}($250k){FFFFFF}		|		10. Woozie {FFFF00}($350k)");
				SendClientMessage(playerid, 0xFFFFFF00, "3. House3 {00FF00}($120k){FFFFFF}		|		11. CrackDen {00AA00}($50k)");
				SendClientMessage(playerid, 0xFFFFFF00, "4. House4 {AA6600}($800k){FFFFFF}		|		12. House8 {FFFF00}($325k)");
				SendClientMessage(playerid, 0xFFFFFF00, "5. House5 {FFFF00}($250k){FFFFFF}		|		13. MaddDogg {AA0000}($2.5m)");
				SendClientMessage(playerid, 0xFFFFFF00, "6. House6 {FFFF00}($200k){FFFFFF}		|		14. Motel {00AA00}($30k)");
				SendClientMessage(playerid, 0xFFFFFF00, "7. House7 {00FF00}($150k){FFFFFF}		|		15. House9 {FFFF00}($350k)");
				SendClientMessage(playerid, 0xFFFFFF00, "8. BigSmoke {FF9900}($600k){FFFFFF}	|		16. House10 {FFFF00}($250k)");
			}
		}
	}
	return 1;
}

stock GetPlayerNameEx(iPlayerID)
{
	new szPlayerName[24];
	GetPlayerName(iPlayerID, szPlayerName, 24);
	return szPlayerName;
}

CMD:lock(playerid, params[])
{
	new iHouseID = InRangeOfHouse(playerid, true);
	if(iHouseID == -1) return SendClientMessage(playerid, 0xFFFFFFFF, "You are not near a house.");
	if(!strcmp(GetPlayerNameEx(playerid), HouseInfo[iHouseID][hOwner])) {
	    if(!HouseInfo[iHouseID][hLock]) {
			HouseInfo[iHouseID][hLock] = 1;
			SendClientMessageEx(playerid, 0xFFFFFFFF, "House {FF6347}%d %s{FFFFFF} locked.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
		}
        if(HouseInfo[iHouseID][hLock]) {
            HouseInfo[iHouseID][hLock] = 0;
            SendClientMessageEx(playerid, 0xFFFFFFFF, "House {9ACD32}%d %s{FFFFFF} unlocked.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
		}
	} else {
	    if(!HouseInfo[iHouseID][hLock])
		    return SendClientMessageEx(playerid, 0xFFFFFFFF, "{9ACD32}%d %s{FFFFFF} is {00FF00}unlocked{FFFFFF}.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
        if(HouseInfo[iHouseID][hLock])
		    return SendClientMessageEx(playerid, 0xFFFFFFFF, "{9ACD32}%d %s{FFFFFF} is {FF0000}locked{FFFFFF}.", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
	}
	return 1;
}

CMD:createhouse(playerid, params[])
{
	printf("/////// CREATEHOUSE USED BY PLAYER %d ///////", playerid);
	new szOrder[6],
		iHouseID;
	if(!sscanf(params, "s[6]", szOrder))
	{
		printf("szOrder = '%s'", szOrder);
	    if(!strcmp(szOrder, "start", true))
	    {
			if(bCreatingHouse[playerid] == true)
				return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You are already creating a house.");
			bCreatingHouse[playerid] = true;
			SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Now creating house. Use {9ACD32}/sethouse [enter/exit/price/level]{FFFFFF} to set parameters.");
			SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Use {9ACD32}/createhouse stop{FFFFFF} to stop.");
		}
		else if(!strcmp(szOrder, "stop", true))
		{
		    if(bCreatingHouse[playerid] == false) return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You are not creating a house.");
		    printf("iHouseCancel[%d] = %d\niHouseLevel = %d\niHousePrice = %d\nfHouseEnter = %.2f %.2f %.2f\nfHouseExit = %.2f %.2f %.2f", playerid, iHouseCancel[playerid], iHouseLevel[playerid], iHousePrice[playerid], fHouseEnter[playerid][0], fHouseEnter[playerid][1], fHouseEnter[playerid][2], fHouseExit[playerid][0], fHouseExit[playerid][1], fHouseExit[playerid][2]);
		    if(iHouseCancel[playerid] == 1)
		    {
		        if(iHouseLevel[playerid] && iHousePrice[playerid] && fHouseEnter[playerid][0] && fHouseEnter[playerid][1] && fHouseEnter[playerid][2] && fHouseExit[playerid][0] && fHouseExit[playerid][1] && fHouseExit[playerid][2])
				{
				    iHouseID = CreateHouse(playerid, iHouseLevel[playerid], iHousePrice[playerid], fHouseEnter[playerid][0], fHouseEnter[playerid][1], fHouseEnter[playerid][2], fHouseExit[playerid][0], fHouseExit[playerid][1], fHouseExit[playerid][2], iHouseInterior[playerid], szStreetName[playerid]);
					SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House ID %d created with name {9ACD32}%d %s{FFFFFF}.", iHouseID, iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
					iHouseCancel[playerid] = 0;
					bCreatingHouse[playerid] = false;
					SetPlayerVirtualWorld(playerid, iHouseID);
				}
				else
				{
					bCreatingHouse[playerid] = false;
			        iHouseLevel[playerid] = 0;
			        iHousePrice[playerid] = 0;
			        iHouseCancel[playerid] = 0;
			        printf("/////// HOUSE CREATION CANCELLED ///////", iHouseID);
	                return SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House creation cancelled.");
                }
		    }
		    else if(iHouseCancel[playerid] == 0)
			{
				if(!iHouseLevel[playerid] || !iHousePrice[playerid] || !fHouseEnter[playerid][0] || !fHouseEnter[playerid][1] || !fHouseEnter[playerid][2] || !fHouseExit[playerid][0] || !fHouseExit[playerid][1] || !fHouseExit[playerid][2])
				{
                    printf("/////// HOUSE CANCEL MESSAGE TRIGGERED ///////", iHouseID);
   				    iHouseCancel[playerid] = 1;
			        SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} You have not set all parameters for the house. Either set them all, or type the command again to cancel creating a house.");
				}
				else
				{
   				    iHouseID = CreateHouse(playerid, iHouseLevel[playerid], iHousePrice[playerid], fHouseEnter[playerid][0], fHouseEnter[playerid][1], fHouseEnter[playerid][2], fHouseExit[playerid][0], fHouseExit[playerid][1], fHouseExit[playerid][2], iHouseInterior[playerid], szStreetName[playerid]);
					SendClientMessageEx(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} House ID %d created with name {9ACD32}%d %s{FFFFFF}.", iHouseID, iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
					bCreatingHouse[playerid] = false;
					SetPlayerVirtualWorld(playerid, iHouseID);
					printf("/////// HOUSE CREATED WITH iHouseID = %d ///////", iHouseID);
				}
			}
		}
		else SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /createhouse [start/stop]");
 	}
	else SendClientMessage(playerid, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} /createhouse [start/stop]");
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	SetPlayerPos(playerid, 1529.6,-1691.2,13.3);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
   	return 1;
}

SetupPlayerForClassSelection(playerid)
{
 	SetPlayerInterior(playerid,14);
	SetPlayerPos(playerid,258.4893,-41.4008,1002.0234);
	SetPlayerFacingAngle(playerid, 270.0);
	SetPlayerCameraPos(playerid,256.0815,-43.0475,1004.0234);
	SetPlayerCameraLookAt(playerid,258.4893,-41.4008,1002.0234);
}

public OnPlayerRequestClass(playerid, classid)
{
	SetupPlayerForClassSelection(playerid);
	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
    SetPlayerPos(playerid, fX, fY, fZ);
    return 1;
}

public OnGameModeInit()
{
	mysql_log(ALL);

    UsePlayerPedAnims();
    DisableInteriorEnterExits();

	gConn = mysql_connect("localhost", "root", "usrp2k19!", "usrp");

	if(mysql_errno(gConn) != 0)
    {
        printf("** [MySQL] Couldn't connect to the database (%d).", mysql_errno(gConn));
        new szError[256];
        mysql_error(szError, sizeof (szError), gConn);
	    printf("[ERROR] '%s'", szError);
    }
    else
    {
        printf("** [MySQL] Connected to the database successfully (%d).", _:gConn);
    }

	//PopulateTable(TABLE_HOUSE);
	// Already done
	LoadHouses();
	
	SetTimer("SaveHouses", 600000, 1);

	SetGameModeText("US-RP Feature Test");
	ShowPlayerMarkers(0);
	ShowNameTags(1);

	AddPlayerClass(280,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	return 1;
}

stock CreateHouse(iPlayerID, iLevel, iPrice, Float:fEnterX, Float:fEnterY, Float:fEnterZ, Float:fExitX, Float:fExitY, Float:fExitZ, iInt, szStreet[MAX_STREET_NAME])
{
	new iHouseID = GetNextHouseID();

	if(iHouseID == -1)
	    return SendClientMessage(iPlayerID, COLOUR_HOUSEGREEN, "HOUSE:{FFFFFF} Unable to create house. Max of 1000 houses already exist?");

	HouseInfo[iHouseID][hLevel] = iLevel;
	HouseInfo[iHouseID][hPrice] = iPrice;

	HouseInfo[iHouseID][hEntrance][0] = fEnterX;
	HouseInfo[iHouseID][hEntrance][1] = fEnterY;
	HouseInfo[iHouseID][hEntrance][2] = fEnterZ;

    HouseInfo[iHouseID][hExit][0] = fExitX;
    HouseInfo[iHouseID][hExit][1] = fExitY;
    HouseInfo[iHouseID][hExit][2] = fExitZ;

    HouseInfo[iHouseID][hInterior] = iInt;

    HouseInfo[iHouseID][hCocaine] = 0;
    HouseInfo[iHouseID][hWeed] = 0;
    HouseInfo[iHouseID][hMats] = 0;
    HouseInfo[iHouseID][hCash] = 0;

	format(HouseInfo[iHouseID][hStreetName], 32, szStreet);

    for(new iGun; iGun < 10; iGun++)
	{
	    HouseInfo[iHouseID][hGun][iGun] = 0;
	}

	format(HouseInfo[iHouseID][hOwner], 32, "The Market");

	HouseInfo[iHouseID][hExists] = true;

	CreateHousePickup(iHouseID);

    SaveHouses();


	return iHouseID;
}

stock LoadHouses()
{
	new szQuery[256],
		iRowCount,
		szRowString[256],
		iHouseID,
		Cache:iCacheID;

	format(szQuery, sizeof(szQuery), "SELECT * FROM `houses` WHERE house_exists = 1");
	iCacheID = mysql_query(gConn, szQuery, true);
	cache_get_row_count(iRowCount);
	printf("Loading houses...\n");
	for(new iInt = 0; iInt < iRowCount; iInt++)
	{
		cache_get_value_name_int(iInt, "house_id", iHouseID);

		cache_get_value_name_int(iInt, "level", HouseInfo[iHouseID][hLevel]);
		cache_get_value_name_int(iInt, "price", HouseInfo[iHouseID][hPrice]);

		cache_get_value_name(iInt, "entrance", szRowString);
		szRowString[0] = ' ';
		szRowString[strlen(szRowString)-1] = ' ';
		sscanf(szRowString, "fff", HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]);

 		cache_get_value_name(iInt, "exit", szRowString);
		szRowString[0] = ' ';
		szRowString[strlen(szRowString)-1] = ' ';
		sscanf(szRowString, "fff", HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2]);

		cache_get_value_name_int(iInt, "cash", HouseInfo[iHouseID][hCash]);
		cache_get_value_name_int(iInt, "alarm", HouseInfo[iHouseID][hAlarm]);
		cache_get_value_name_int(iInt, "mats", HouseInfo[iHouseID][hMats]);
		cache_get_value_name_int(iInt, "cocaine", HouseInfo[iHouseID][hCocaine]);
		cache_get_value_name_int(iInt, "weed", HouseInfo[iHouseID][hWeed]);

		cache_get_value_name(iInt, "guns", szRowString);
		szRowString[0] = ' ';
		szRowString[strlen(szRowString)-1] = ' ';
		sscanf(szRowString, "a<i>[10]", HouseInfo[iHouseID][hGun]);

		cache_get_value_name_int(iInt, "interior", HouseInfo[iHouseID][hInterior]);

		cache_get_value_name(iInt, "owner", szRowString);
		format(HouseInfo[iHouseID][hOwner], 32, szRowString);

		cache_get_value_name(iInt, "streetname", szRowString);
		format(HouseInfo[iHouseID][hStreetName], 32, szRowString);

		printf("House %d loaded:\nhLevel: %d\nhPrice: %d\nEntrance: %.2f %.2f %.2f\nExit: %.2f %.2f %.2f\nCash: $%d\nAlarm: %d\nMaterials: %d",
		iHouseID, HouseInfo[iHouseID][hLevel], HouseInfo[iHouseID][hPrice], HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2], \
		HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2], HouseInfo[iHouseID][hCash], HouseInfo[iHouseID][hAlarm], HouseInfo[iHouseID][hMats]);
		printf("Cocaine: %d\nWeed: %d\nInterior: %d\nOwner: %s", HouseInfo[iHouseID][hCocaine], HouseInfo[iHouseID][hWeed], HouseInfo[iHouseID][hInterior], HouseInfo[iHouseID][hOwner]);
		printf("Guns: %d %d %d %d %d %d %d %d %d %d\nStreet Name: %s\n", HouseInfo[iHouseID][hGun][0], HouseInfo[iHouseID][hGun][1], HouseInfo[iHouseID][hGun][2], \
		HouseInfo[iHouseID][hGun][3], HouseInfo[iHouseID][hGun][4], HouseInfo[iHouseID][hGun][5], HouseInfo[iHouseID][hGun][6], HouseInfo[iHouseID][hGun][7], \
		HouseInfo[iHouseID][hGun][8], HouseInfo[iHouseID][hGun][9], HouseInfo[iHouseID][hStreetName]);
		HouseInfo[iHouseID][hExists] = true;
		CreateHousePickup(iHouseID);
	}
	printf("...%d houses loaded", iRowCount);
	g_iLoadedHouses = iRowCount;
	cache_delete(iCacheID);
	return 1;
}

stock CreateHousePickup(iHouseID)
{
	new szLabelString[128];
	if(HouseInfo[iHouseID][hExists] == false) return 0;
	if(!strcmp(HouseInfo[iHouseID][hOwner], "The Market", true))
	{
		format(szLabelString, sizeof(szLabelString), "%d %s\n{00AA00}FOR SALE!\n{9ACD32}Price: {00AA00}$%d", iHouseID+1000, HouseInfo[iHouseID][hStreetName], HouseInfo[iHouseID][hPrice]);
		HouseInfo[iHouseID][hTextLabelExt] = Create3DTextLabel(szLabelString, COLOUR_HOUSEGREEN, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2], 20, 0, 1);
	    HouseInfo[iHouseID][hTextLabelInt] = Create3DTextLabel("Exit Door", COLOUR_HOUSEGREEN, HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2], 5, iHouseID, 1);
		HouseInfo[iHouseID][hPickup] = CreatePickup(1273, 1, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]);
	}
	else
	{
	    format(szLabelString, sizeof(szLabelString), "%d %s\nOwned by: %s\nEstimated Value: {00AA00}$%d", iHouseID+1000, HouseInfo[iHouseID][hStreetName], HouseInfo[iHouseID][hOwner], HouseInfo[iHouseID][hPrice]);
 		HouseInfo[iHouseID][hTextLabelExt] = Create3DTextLabel(szLabelString, COLOUR_HOUSEBLUE, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2], 20, 0, 1);
 		HouseInfo[iHouseID][hTextLabelInt] = Create3DTextLabel("Exit Door", COLOUR_HOUSEBLUE, HouseInfo[iHouseID][hExit][0], HouseInfo[iHouseID][hExit][1], HouseInfo[iHouseID][hExit][2], 5, iHouseID, 1);
		HouseInfo[iHouseID][hPickup] = CreatePickup(1272, 1, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]);
	}
	return 1;
}

stock PopulateTable(tType)
{
	new szQuery[512];
	if(tType == TABLE_HOUSE)
	{
		for(new iHouseID; iHouseID < MAX_HOUSES; iHouseID++)
		{
			format(szQuery, sizeof(szQuery), "INSERT INTO houses (house_id, house_exists) VALUES (%d, 0)", iHouseID);
			mysql_tquery(gConn, szQuery);
		}
	}
	return 1;
}

public SaveHouses()
{
	new szQuery[512],
		iCount,
		szHouseEntrance[128],
		szHouseExit[128],
		szHouseGuns[32],
		szGunString[5];

	for(new iHouseID; iHouseID < MAX_HOUSES; iHouseID++)
	{
	    if(HouseInfo[iHouseID][hExists] == true)
	    {
			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `level` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hLevel], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `house_exists` = %d WHERE `house_id` = %d", BoolToInt(HouseInfo[iHouseID][hExists]), iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `interior` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hInterior], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `price` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hPrice], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szHouseEntrance, sizeof(szHouseEntrance), "[%f %f %f]", HouseInfo[iHouseID][hEntrance][0],HouseInfo[iHouseID][hEntrance][1],HouseInfo[iHouseID][hEntrance][2]);
			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `entrance` = '%s' WHERE `house_id` = %d", szHouseEntrance, iHouseID);
			mysql_tquery(gConn, szQuery);


            format(szHouseExit, sizeof(szHouseExit), "[%f %f %f]", HouseInfo[iHouseID][hExit][0],HouseInfo[iHouseID][hExit][1],HouseInfo[iHouseID][hExit][2]);
			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `exit` = '%s' WHERE `house_id` = %d", szHouseExit, iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `alarm` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hAlarm], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `cash` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hCash], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `cocaine` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hCocaine], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `weed` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hWeed], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `mats` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hMats], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `owner` = '%s' WHERE `house_id` = %d", HouseInfo[iHouseID][hOwner], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `streetname` = '%s' WHERE `house_id` = %d", HouseInfo[iHouseID][hStreetName], iHouseID);
			mysql_tquery(gConn, szQuery);


			format(szHouseGuns, sizeof(szHouseGuns), "[%d ", HouseInfo[iHouseID][hGun][0]);
			for(new iGun = 1; iGun < 9; iGun++)
			{
			    format(szGunString, sizeof(szGunString), "%d ", HouseInfo[iHouseID][hGun][iGun]);
			    strcat(szHouseGuns, szGunString);
			}
		    format(szGunString, sizeof(szGunString), "%d]", HouseInfo[iHouseID][hGun][9]);
		    strcat(szHouseGuns, szGunString);
			format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `guns` = '%s' WHERE `house_id` = %d", szHouseGuns, iHouseID);
			mysql_tquery(gConn, szQuery);
			printf("===============================");
			iCount++;
		}
	}
	g_iLoadedHouses = iCount;
	return printf("\n\n%d/%d houses saved and currently active.", iCount, g_iLoadedHouses);
}

stock SaveHouse(iHouseID)
{
	new szQuery[512],
		szHouseEntrance[128],
		szHouseExit[128],
		szHouseGuns[32],
		szGunString[5];

    if(HouseInfo[iHouseID][hExists] == true)
    {
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `level` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hLevel], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `house_exists` = %d WHERE `house_id` = %d", BoolToInt(HouseInfo[iHouseID][hExists]), iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `interior` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hInterior], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `price` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hPrice], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szHouseEntrance, sizeof(szHouseEntrance), "[%f %f %f]", HouseInfo[iHouseID][hEntrance][0],HouseInfo[iHouseID][hEntrance][1],HouseInfo[iHouseID][hEntrance][2]);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `entrance` = '%s' WHERE `house_id` = %d", szHouseEntrance, iHouseID);
		mysql_tquery(gConn, szQuery);
        format(szHouseExit, sizeof(szHouseExit), "[%f %f %f]", HouseInfo[iHouseID][hExit][0],HouseInfo[iHouseID][hExit][1],HouseInfo[iHouseID][hExit][2]);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `exit` = '%s' WHERE `house_id` = %d", szHouseExit, iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `alarm` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hAlarm], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `cash` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hCash], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `cocaine` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hCocaine], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `weed` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hWeed], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `mats` = %d WHERE `house_id` = %d", HouseInfo[iHouseID][hMats], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `owner` = '%s' WHERE `house_id` = %d", HouseInfo[iHouseID][hOwner], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `streetname` = '%s' WHERE `house_id` = %d", HouseInfo[iHouseID][hStreetName], iHouseID);
		mysql_tquery(gConn, szQuery);
		format(szHouseGuns, sizeof(szHouseGuns), "[%d ", HouseInfo[iHouseID][hGun][0]);
		for(new iGun = 1; iGun < 9; iGun++)
		{
		    format(szGunString, sizeof(szGunString), "%d ", HouseInfo[iHouseID][hGun][iGun]);
		    strcat(szHouseGuns, szGunString);
		}
	    format(szGunString, sizeof(szGunString), "%d]", HouseInfo[iHouseID][hGun][9]);
	    strcat(szHouseGuns, szGunString);
		format(szQuery, sizeof(szQuery), "UPDATE `houses` SET `guns` = '%s' WHERE `house_id` = %d", szHouseGuns, iHouseID);
		mysql_tquery(gConn, szQuery);
	}
	return printf("=============================\nHouse %d saved and currently active.", iHouseID);
}

stock GetNextHouseID()
{
	for(new iVal; iVal < MAX_HOUSES; iVal++)
	{
	    if(HouseInfo[iVal][hExists] == false)
			return iVal;
	}
	return -1;
}

stock BoolToInt(bool:bBoolean)
{
	if(bBoolean == true) return 1;
	else return 0;
}

CMD:go(playerid, params[])
{
	new Float:fX, Float:fY, Float:fZ, iInt;
	if(!sscanf(params, "dfff", iInt, fX, fY, fZ))
	{
	    SetPlayerPos(playerid, fX, fY, fZ);
	    SetPlayerInterior(playerid, iInt);
	    return 1;
	}
	return SendClientMessage(playerid, 0xFFFFFF00, "/go [Int] [X] [Y] [Z]");
}

public RemovePlayerFromHouse(iPlayerID, iHouseID)
{
	SendClientMessageEx(iPlayerID, 0xFFFFFF00, "The landlord kicked you out of {FF6347}%d %s{FFFFFF}!", iHouseID+1000, HouseInfo[iHouseID][hStreetName]);
	TogglePlayerControllable(iPlayerID, false);
	SetPlayerPos(iPlayerID, HouseInfo[iHouseID][hEntrance][0], HouseInfo[iHouseID][hEntrance][1], HouseInfo[iHouseID][hEntrance][2]);
	SetPlayerInterior(iPlayerID, 0);
	SetPlayerVirtualWorld(iPlayerID, 0);
	GameTextForPlayer(iPlayerID, "~w~Loading world...", 1500, 4);
	FreezePlayer(iPlayerID);
	return 1;
}

stock FreezePlayer(iPlayerID)
{
	TogglePlayerControllable(iPlayerID, false);
	return SetTimerEx("UnfreezePlayer", 1500, 0, "d", iPlayerID);
}

public UnfreezePlayer(iPlayerID)
{
	return TogglePlayerControllable(iPlayerID, true);
}
