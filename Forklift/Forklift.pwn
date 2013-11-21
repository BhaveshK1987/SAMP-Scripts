//Forklift job
#include a_samp

#define FORKLIFT 	530

#define LIGHTBLUE 	0x33CCFF00
#define LIGHTRED 	0xFF634700

#define MAX_BOXES   20 // 20 boxes spawned at one time - ~20 people max doing job simultaneously
#define BOX_OBJECT	1558

#define DROPOFF_X   60.0
#define DROPOFF_Y   0.0
#define DROPOFF_Z   2.5

new
	Float:g_BoxPos[MAX_BOXES][3],
	bool:g_IsPlayerForklifting[MAX_PLAYERS],
	bool:g_IsBoxTaken[MAX_BOXES],
	g_PlayerBoxID[MAX_PLAYERS],
	g_BoxObjID[MAX_BOXES],
	g_ForkliftID[MAX_BOXES],
	Float:g_BoxSpaces[6][3] = {
		{0.0, 0.0, 2.5},
		{2.0, 0.0, 2.5},
		{0.0, 2.0, 2.5},
		{4.0, 0.0, 2.5},
		{0.0, 4.0, 2.5},
		{6.0, 0.0, 2.5}
	},
	bool:g_CollectingBox[MAX_PLAYERS];
	
public OnPlayerConnect(playerid) {
	g_IsPlayerForklifting[playerid] = false;
	g_PlayerBoxID[playerid] = -1;
	g_CollectingBox[playerid] = false;
	return 1;
}

public OnFilterScriptInit() {
	printf("Box filterscript loaded, MAX_BOXES = %d", MAX_BOXES);
	for(new iBoxID; iBoxID < MAX_BOXES; iBoxID++) {
		g_IsBoxTaken[iBoxID] = false;
		for(new iCoordID; iCoordID < 3; iCoordID++) {
			g_BoxPos[iBoxID][iCoordID] = 0.0;
		}
	}
	for(new iForkliftID; iForkliftID < MAX_BOXES; iForkliftID++) {
	    g_ForkliftID[iForkliftID] = CreateVehicle(FORKLIFT, ((2*iForkliftID)+15), 0.0, 3.0, 0.0, 6, 0, 300000);
	}
	return 1;
}

public OnFilterScriptExit() {
	for(new iPlayer; iPlayer < MAX_PLAYERS; iPlayer++) {
		g_IsPlayerForklifting[iPlayer] = false;
		g_PlayerBoxID[iPlayer] = -1;
		g_CollectingBox[iPlayer] = false;
	}
	for(new iBoxID; iBoxID < MAX_BOXES; iBoxID++) {
		g_IsBoxTaken[iBoxID] = false;
		g_BoxPos[iBoxID][0] = 0.0;
		g_BoxPos[iBoxID][1] = 0.0;
		g_BoxPos[iBoxID][2] = 0.0;
		DestroyVehicle(g_ForkliftID[iBoxID]);
  		DestroyObject(g_BoxObjID[iBoxID]);
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	if(IsAForklifter(vehicleid)) {
		if(GetPVarInt(playerid, "pJob") == 25) { //forklifter
			new iBoxID;
			if(NextAvailableBox(iBoxID) == 0) {
				return SendClientMessage(playerid, LIGHTRED, "* Welcome to your forklift! We are sorry, but there are no available boxes! (20/20 used)");
			}
			SendClientMessage(playerid, LIGHTBLUE, "* Welcome to your forklift! The box that needs moving has been highlighted on your GPS.");
			SetPlayerCheckpoint(playerid, g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2], 5.0);
			g_PlayerBoxID[playerid] = iBoxID;
			g_IsPlayerForklifting[playerid] = true;
			g_CollectingBox[playerid] = true;
		}
		else {
			SendClientMessage(playerid,LIGHTRED,"* You're not a forklifter!");
			RemovePlayerFromVehicle(playerid);
			new Float:f_evX, Float:f_evY, Float:f_evZ;
			GetPlayerPos(playerid, f_evX, f_evY, f_evZ);
			SetPlayerPos(playerid, f_evX, f_evY, f_evZ);
			//NOPCheck(playerid);
			g_IsPlayerForklifting[playerid] = false;
			g_CollectingBox[playerid] = false;
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid) {
    if(g_IsPlayerForklifting[playerid] == true) {
		if(IsAForklifter(vehicleid)) {
      		SetVehicleToRespawn(vehicleid);
      		DestroyObject(g_BoxObjID[g_PlayerBoxID[playerid]]);
      		DisablePlayerCheckpoint(playerid);
      		g_CollectingBox[playerid] = false;
      		g_PlayerBoxID[playerid] = -1;
      		g_IsPlayerForklifting[playerid] = false;
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid) {
	if(g_IsPlayerForklifting[playerid] == true) {
		if(IsAForklifter(GetPlayerVehicleID(playerid))) {
      		new iBoxID = g_PlayerBoxID[playerid];
			if(g_CollectingBox[playerid] == true) {
                GetObjectPos(g_BoxObjID[iBoxID], g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2]);
				if(IsPlayerInRangeOfPoint(playerid, 10.0, g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2])) {
				    AttachObjectToVehicle(g_BoxObjID[iBoxID], GetPlayerVehicleID(playerid), 0.000000,0.599999,0.449999,0.000000,0.000000,0.000000);
					SendClientMessage(playerid, LIGHTBLUE, "* Lift up your box using your truck's forks! Use NumPad8 or NumPad2 (default) to operate the forks.");
				    SendClientMessage(playerid, LIGHTBLUE, "* When you've done that, go drop off your box for some great American dollar!");
				    DisablePlayerCheckpoint(playerid);
					g_CollectingBox[playerid] = false;
					SetPlayerCheckpoint(playerid, DROPOFF_X, DROPOFF_Y, DROPOFF_Z, 5.0);
				}
				else
					return SendClientMessage(playerid, LIGHTRED, "* Something went wrong. Post a bug report or try again! {00AA00}(Bug report info: Collecting)");
			}
			else {
			    if(IsPlayerInRangeOfPoint(playerid, 7.0, DROPOFF_X, DROPOFF_Y, DROPOFF_Z) == 0) {
					return SendClientMessage(playerid, LIGHTRED, "* Something went wrong. Post a bug report or try again! {00AA00}(Bug report info: Dropping off)");
				}
				if(IsValidObject(g_BoxObjID[iBoxID])) {
					new
						iRandCash = 179 + random(320), // min $180 max $500
						szString[64];
					format(szString, sizeof(szString), "~g~+$%d", iRandCash);
					GameTextForPlayer(playerid, szString, 5000, 1);
					format(szString, sizeof(szString), "* Well done, you earned {00AA00}$%d{33CCFF} for your delivery!", iRandCash);
					PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
					SendClientMessage(playerid, LIGHTBLUE, szString);
					GivePlayerMoney(playerid, iRandCash);
					DestroyObject(g_BoxObjID[iBoxID]);
					g_IsBoxTaken[iBoxID] = false;
					g_BoxPos[iBoxID][0] = 0.0;
					g_BoxPos[iBoxID][1] = 0.0;
					g_BoxPos[iBoxID][2] = 0.0;
					g_PlayerBoxID[playerid] = -1;
					for(new iPlayer; iPlayer < MAX_PLAYERS; iPlayer++) {
					    if(iPlayer != playerid)
					    {
							if(!IsPlayerConnected(iPlayer))
								break;
							if(g_PlayerBoxID[iPlayer] == iBoxID) {
								SendClientMessage(iPlayer, LIGHTRED, "* Your box was already dropped off - post a bug report!");
								DisablePlayerCheckpoint(iPlayer);
								if(NextAvailableBox(iBoxID) == 0) {
								    SetVehicleToRespawn(GetPlayerVehicleID(iPlayer));
						      		DestroyObject(g_BoxObjID[g_PlayerBoxID[iPlayer]]);
						      		DisablePlayerCheckpoint(iPlayer);
						      		g_CollectingBox[iPlayer] = false;
						      		g_PlayerBoxID[iPlayer] = -1;
						      		g_IsPlayerForklifting[iPlayer] = false;
									return SendClientMessage(iPlayer, LIGHTRED, "* There are no available boxes! (20/20 used)");
								}
								SendClientMessage(iPlayer, LIGHTBLUE, "* The next box that needs moving has been highlighted on your GPS.");
								SetPlayerCheckpoint(iPlayer, g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2], 5.0);
								g_PlayerBoxID[iPlayer] = iBoxID;
							}
						}
					}
					DisablePlayerCheckpoint(playerid);
					if(NextAvailableBox(iBoxID) == 0) {
						SetVehicleToRespawn(vehicleid);
			      		DestroyObject(g_BoxObjID[g_PlayerBoxID[playerid]]);
			      		DisablePlayerCheckpoint(playerid);
			      		g_CollectingBox[playerid] = false;
			      		g_PlayerBoxID[playerid] = -1;
			      		g_IsPlayerForklifting[playerid] = false;
				  		return SendClientMessage(playerid, LIGHTRED, "* There are no available boxes! (20/20 used)");
					}
					SendClientMessage(playerid, LIGHTBLUE, "* The next box that needs moving has been highlighted on your GPS.");
					SetPlayerCheckpoint(playerid, g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2], 5.0);
					g_PlayerBoxID[playerid] = iBoxID;
					g_CollectingBox[playerid] = true;
					PlayerForkliftSkill[playerid] ++;
				}
				else
					SendClientMessage(playerid, LIGHTRED, "* Your box is not within 7 meters of your forklift!");
			}
		}
		else
			SendClientMessage(playerid, LIGHTRED, "* This vehicle is not a forklift truck!");
	}
	else
		SendClientMessage(playerid, LIGHTRED, "* You are not currently on a forklifting mission!");
	return 1;
}

stock IsAForklifter(iVehicleID) {
	for(new iForkliftID; iForkliftID < MAX_BOXES; iForkliftID ++) {
		if(g_ForkliftID[iForkliftID] == iVehicleID)
			return true;
		else
		    continue;
	}
	return false;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	if(!strcmp(cmdtext, "/givejob", true)) return SetPVarInt(playerid, "pJob", 25);
	return 0;
}

stock NextAvailableBox(&iBoxID) {
	new iBoxTakenCount;
	for(iBoxID = 0; iBoxID < MAX_BOXES; iBoxID++) {
		if(g_IsBoxTaken[iBoxID] == false) {
			g_IsBoxTaken[iBoxID] = true;
			if(IsValidObject(g_BoxObjID[iBoxID]) == 0) {
				g_BoxObjID[iBoxID] = CreateObject(BOX_OBJECT, g_BoxSpaces[iBoxID][0], g_BoxSpaces[iBoxID][1], g_BoxSpaces[iBoxID][2], 0.0, 0.0, 0.0, 100.0);
				printf("Creating object %d for boxID %d", g_BoxObjID[iBoxID], iBoxID);
				GetObjectPos(g_BoxObjID[iBoxID], g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2]);
				return 1;
			}
			else if(g_BoxPos[iBoxID][0] == 0.0 || g_BoxPos[iBoxID][1] == 0.0 || g_BoxPos[iBoxID][2] == 0.0)
				GetObjectPos(g_BoxObjID[iBoxID], g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2]);
			return 1;
		}
		else {
			iBoxTakenCount++;
			if(iBoxTakenCount == 20) {
				return 0;
			}
			continue;
		}
	}
	return 1;
}
