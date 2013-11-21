//Forklift job
#include a_samp

#define FORKLIFT 	530
#define LIGHTBLUE 	0x33CCFF00
#define LIGHTRED 	0xFF634700
#define MAX_BOXES   20 // 20 boxes spawned at one time - ~20 people max doing job simultaneously

new
	Float:g_BoxPos[MAX_BOXES][3],
	bool:g_IsForklifting[MAX_PLAYERS],
	bool:g_IsBoxTaken[MAX_BOXES],
	g_PlayerBoxID[MAX_PLAYERS];
	
public OnPlayerConnect(playerid) {
	g_IsForklifting[playerid] = false;
	g_PlayerBoxID[playerid] = -1;
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
}

public OnFilterScriptExit() {
    for(new iPlayer; iPlayer < MAX_PLAYERS; iPlayer++) {
		g_IsForklifting[iPlayer] = false;
		g_PlayerBoxID[iPlayer] = -1;
	}
	for(new iBoxID; iBoxID < MAX_BOXES; iBoxID++) {
	    g_IsBoxTaken[iBoxID] = false;
	    g_BoxPos[iBoxID][0] = 0.0;
	    g_BoxPos[iBoxID][1] = 0.0;
	    g_BoxPos[iBoxID][2] = 0.0;
	}

}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	if(IsAForklifter(vehicleid)) {
		if(GetPVarInt(playerid, "pJob") == 25) { //forklifter
			SendClientMessage(playerid, LIGHTBLUE, "* Welcome to your forklift! The box that needs moving has been highlighted on your GPS.");
			new iBoxID;	NextAvailableBox(iBoxID);
			SetPlayerCheckpoint(playerid, g_BoxPos[iBoxID][0], g_BoxPos[iBoxID][1], g_BoxPos[iBoxID][2], 5.0);
			g_PlayerBoxID[playerid] = iBoxID;
			g_IsForklifting[playerid] = true;
		}
		else {
			SendClientMessage(playerid,COLOR_GREY,"   You're not a forklifter!");
			RemovePlayerFromVehicle(playerid);
			new Float:f_evX, Float:f_evY, Float:f_evZ;
			GetPlayerPos(playerid, f_evX, f_evY, f_evZ);
			SetPlayerPos(playerid, f_evX, f_evY, f_evZ);
			NOPCheck(playerid);
			g_IsForklifting[playerid] = false;
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid) {
	if(IsPlayerInRangeOfPoint(playerid,
}

stock NextAvailableBox(&iBoxID) {
	for(iBoxID < MAX_BOXES; iBoxID++) {
	    if(g_IsBoxTaken[iBoxID] == false) {
	        g_IsBoxTaken[iBoxID] = true;
	        break;
		}
	}
	return 1;
}
