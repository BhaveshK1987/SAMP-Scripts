//Forklift job
#include a_samp
#include streamer

#define FORKLIFT 	530

#define LIGHTBLUE 	0x33CCFF00
#define GREY		0xAFAFAF00

#define MAX_BOXES   9 // 9 boxes spawned at one time - ~9 people max doing job simultaneously
#define BOX_OBJECT	1558

#define g_fForkliftSpace[%1] g_aForkliftSpawn[%1][0], g_aForkliftSpawn[%1][1], g_aForkliftSpawn[%1][2]

//Information for Lawless script
//g_fMaterialsMultiplier[playerid] is to be put into the materials factory pickup function. Add to their materials using += (250*g_fMaterialsMultiplier[playerid]); It defaults at 1.0 @ OnPlayerConnect
//Objects by Tony, uses Incognito's 0.3x streamer.
//Forklift Operator (name can be changed) needs adding to /join and /findjob. Coordinates are (2424.3030, -2098.8564, 13.7151)


new
	Float:g_fBoxPos[MAX_BOXES][3],
	bool:g_bIsPlayerForklifting[MAX_PLAYERS],
	bool:g_bIsBoxTaken[MAX_BOXES],
	g_iPlayerBoxID[MAX_PLAYERS],
	g_iBoxObjID[MAX_BOXES],
	g_iForkliftID[MAX_BOXES],
	g_iForkliftTruckNumber[MAX_VEHICLES],
	Float:g_aBoxSpaces[MAX_BOXES][3] = { // More boxes? Add more box spawn coordinates.
		{2645.1135,-2136.2703,13.1146},
		{2645.2485,-2138.3137,13.1146},
		{2644.7598,-2140.3379,13.1146},
		{2637.2166,-2104.0190,13.1146},
		{2637.2166,-2102.0635,13.1146},
		{2637.2166,-2099.9968,13.1146},
		{2637.2166,-2097.8271,13.1146},
		{2637.2166,-2096.2373,13.1146},
		{2637.2166,-2094.3455,13.1146}
	},
	Float:g_aForkliftSpawn[MAX_BOXES][3] = { //More boxes? Add more forklift spawn coordinates.
	    {2458.0894,-2118.7822,13.3103},
		{2460.5295,-2118.7822,13.3103},
		{2463.1433,-2118.7822,13.3104},
		{2481.8218,-2118.7822,13.3107},
		{2484.5767,-2118.7822,13.3108},
		{2487.6199,-2118.7822,13.3108},
		{2505.8230,-2118.7822,13.3111},
		{2508.8750,-2118.7822,13.3713},
		{2511.5403,-2118.7822,13.3731}
	},
	bool:g_bCollectingBox[MAX_PLAYERS],
	g_iPlayerForkliftSkill[MAX_PLAYERS],
	g_iPlayerForkliftLevel[MAX_PLAYERS],
	Float:g_fMaterialsMultiplier[MAX_PLAYERS]; // Put this in the Lawless script @ materials factory pickup checkpoint
	
public OnPlayerConnect(playerid) {
	g_bIsPlayerForklifting[playerid] = false;
	g_iPlayerBoxID[playerid] = -1;
	g_bCollectingBox[playerid] = false;
	g_fMaterialsMultiplier[playerid] = 1.0; // This needs to be saved & loaded to a player's SQL row. I added this rather than based on level to open up possibilities for it in the future. Eg 2x materials for a day as an event prize?
	return 1;
}

public OnFilterScriptInit() {
	printf("Box filterscript loaded, MAX_BOXES = %d", MAX_BOXES);
	for(new iBoxID; iBoxID < MAX_BOXES; iBoxID++) {
		g_bIsBoxTaken[iBoxID] = false;
		for(new iCoordID; iCoordID < 3; iCoordID++) {
			g_fBoxPos[iBoxID][iCoordID] = 0.0;
		}
	}
	for(new iForkliftID; iForkliftID < MAX_BOXES; iForkliftID++) {
	    g_iForkliftID[iForkliftID] = CreateVehicle(FORKLIFT, g_fForkliftSpace[iForkliftID], 0.0, 6, 0, 300000);
	    g_iForkliftTruckNumber[g_iForkliftID[iForkliftID]] = iForkliftID; // Used for setting checkpoint to load the box unique to each forklift.
	}
	CreateDynamicPickup(1239, 1, 2424.3030,-2098.8564,13.7151, -1, -1, -1, 100.0); //
	CreateDynamicObject(3258,2429.9360400,-2122.1701700,12.1875000,356.8584000,0.0000000,3.1415900); //
	CreateDynamicObject(3865,2427.3557100,-2106.0253900,14.2786200,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(10984,2448.2036100,-2106.1379400,11.7208000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1684,2495.9892600,-2123.6064500,14.0713000,0.0000000,0.0000000,180.0000000); //
	CreateDynamicObject(1685,2470.7548800,-2101.2290000,13.3406000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1685,2468.8732900,-2101.2290000,13.3406000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1685,2469.8132300,-2101.2290000,14.8440000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3578,2477.8532700,-2101.0210000,13.2863700,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1233,2418.9492200,-2100.5349100,14.0580000,0.0000000,0.0000000,-90.0000000); //
	CreateDynamicObject(2567,2449.4216300,-2120.1225600,14.4419000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3566,2538.6970200,-2100.2736800,14.9572000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3565,2426.2705100,-2117.1279300,13.8634000,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(16601,2538.5161100,-2077.9587400,12.2405900,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(16601,2538.4733900,-2081.9619100,17.2497400,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(5299,2566.5705600,-2106.6789600,12.0546900,356.8584000,0.0000000,3.1415900); //
	CreateDynamicObject(3571,2438.3352100,-2079.0781300,15.4831000,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(3631,2468.9982900,-2067.4580100,13.1172000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3631,2468.9982900,-2067.4580100,14.2772500,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3631,2461.3352100,-2067.4580100,13.1172000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3577,2538.9470200,-2123.6452600,13.2976000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3577,2562.7585400,-2113.1511200,13.2976000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3631,2581.3850100,-2120.5793500,13.1176000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3633,2471.8447300,-2067.3586400,15.3261000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3569,2457.2002000,-2075.8623000,14.9572000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(10984,2522.5261200,-2106.8012700,12.1799900,0.0000000,0.0000000,-109.4999900); //
	CreateDynamicObject(10984,2655.7480500,-2130.6298800,11.7477500,0.0000000,0.0000000,-203.4599200); //
	CreateDynamicObject(3577,2521.1186500,-2137.8874500,13.2976000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3577,2444.8557100,-2137.9980500,13.2976000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3577,2444.9880400,-2119.9575200,13.2976000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3504,2425.4577600,-2077.8669400,13.8862000,0.0000000,0.0000000,-90.0000000); //
	CreateDynamicObject(3504,2425.4577600,-2075.9970700,13.8862000,0.0000000,0.0000000,-90.0000000); //
	CreateDynamicObject(1278,2425.4064900,-2067.2209500,26.3777500,0.0000000,0.0000000,-324.4799800); //
	CreateDynamicObject(1278,2539.8151900,-2138.5329600,26.3777500,0.0000000,0.0000000,-225.8398600); //
	CreateDynamicObject(3630,2701.3483900,-2126.0759300,14.0074000,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(3630,2701.3483900,-2115.5466300,14.0074000,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(3631,2688.3501000,-2067.7011700,13.1176000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1278,2701.7512200,-2067.1796900,26.3777500,0.0000000,0.0000000,-45.0597300); //
	CreateDynamicObject(1278,2625.0920400,-2143.3127400,26.3777500,0.0000000,0.0000000,-214.7397300); //
	CreateDynamicObject(2567,2449.4216300,1.0000000,14.4419000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2567,2473.0539600,-2120.1225600,14.4419000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1685,2518.4147900,-2101.1367200,13.3406000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3578,2510.1650400,-2082.2375500,13.2863700,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1685,2637.1062000,-2143.0512700,13.2814800,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3631,2631.9716800,-2143.1474600,13.1176000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3578,2613.4350600,-2113.3159200,13.2863700,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3578,2654.6782200,-2100.0920400,13.2863700,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3578,2682.6772500,-2132.2448700,13.2863700,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3577,2626.1613800,-2068.2146000,13.2976000,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(3865,2701.2326700,-2073.5979000,14.4365000,0.0000000,0.0000000,0.0000000); //
	return 1;
}

public OnFilterScriptExit() {
	for(new iPlayer; iPlayer < MAX_PLAYERS; iPlayer++) {
		g_bIsPlayerForklifting[iPlayer] = false;
		g_iPlayerBoxID[iPlayer] = -1;
		g_bCollectingBox[iPlayer] = false;
	}
	for(new iBoxID; iBoxID < MAX_BOXES; iBoxID++) {
		g_bIsBoxTaken[iBoxID] = false;
		g_fBoxPos[iBoxID][0] = 0.0;
		g_fBoxPos[iBoxID][1] = 0.0;
		g_fBoxPos[iBoxID][2] = 0.0;
		DestroyVehicle(g_iForkliftID[iBoxID]);
  		DestroyDynamicObject(g_iBoxObjID[iBoxID]);
	}
	return 1;
}

public OnPlayerUpdate(playerid) {
    new Float:fX, Float:fY, Float:fZ;
	GetPlayerPos(playerid, fX, fY, fZ);
	if(g_bIsPlayerForklifting[playerid] == true) {
		if(fX < 2423.9375) {
            SetVehicleToRespawn(GetPlayerVehicleID(playerid));
      		DestroyDynamicObject(g_iBoxObjID[g_iPlayerBoxID[playerid]]);
      		DisablePlayerCheckpoint(playerid);
      		g_bCollectingBox[playerid] = false;
      		g_iPlayerBoxID[playerid] = -1;
      		g_bIsPlayerForklifting[playerid] = false;
      		SendClientMessage(playerid, GREY, "* You are not allowed outside the Fossil Fuel Company grounds! Your forklift was returned.");
		}
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	if(IsAForklifter(vehicleid)) {
		if(GetPVarInt(playerid, "pJob") == 25) { //Change this an unused job ID in the Lawless script
			new iBoxID;
			if(NextAvailableBox(iBoxID) == 0) {
				return SendClientMessage(playerid, GREY, "* Welcome to your forklift! We are sorry, but there are no available boxes!");
			}
			SendClientMessage(playerid, LIGHTBLUE, "* Welcome to your forklift! The box that needs moving has been highlighted on your GPS.");
			SetPlayerCheckpoint(playerid, g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2], 5.0);
			g_iPlayerBoxID[playerid] = iBoxID;
			g_bIsPlayerForklifting[playerid] = true;
			g_bCollectingBox[playerid] = true;
		}
		else {
			SendClientMessage(playerid,GREY,"* You're not a forklifter!");
			RemovePlayerFromVehicle(playerid);
			new Float:f_evX, Float:f_evY, Float:f_evZ;
			GetPlayerPos(playerid, f_evX, f_evY, f_evZ);
			SetPlayerPos(playerid, f_evX, f_evY, f_evZ);
			//NOPCheck(playerid);
			g_bIsPlayerForklifting[playerid] = false;
			g_bCollectingBox[playerid] = false;
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid) {
    if(g_bIsPlayerForklifting[playerid] == true) {
		if(IsAForklifter(vehicleid)) {
      		SetVehicleToRespawn(vehicleid);
      		DestroyDynamicObject(g_iBoxObjID[g_iPlayerBoxID[playerid]]);
      		DisablePlayerCheckpoint(playerid);
      		g_bCollectingBox[playerid] = false;
      		g_iPlayerBoxID[playerid] = -1;
      		g_bIsPlayerForklifting[playerid] = false;
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid) {
	if(g_bIsPlayerForklifting[playerid] == true) {
		if(IsAForklifter(GetPlayerVehicleID(playerid))) {
      		new iBoxID = g_iPlayerBoxID[playerid];
			if(g_bCollectingBox[playerid] == true) {
                GetObjectPos(g_iBoxObjID[iBoxID], g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2]);
				if(IsPlayerInRangeOfPoint(playerid, 10.0, g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2])) {
				    AttachObjectToVehicle(g_iBoxObjID[iBoxID], GetPlayerVehicleID(playerid), 0.000000,0.599999,0.449999,0.000000,0.000000,0.000000);
					SendClientMessage(playerid, LIGHTBLUE, "* Lift up your box using your truck's forks! Use {00AA00}NumPad8{33CCFF} and {FFAA00}NumPad2{33CCFF} (default) to operate the forks.");
				    SendClientMessage(playerid, LIGHTBLUE, "* When you've done that, go drop off your box for some great American dollar!");
				    DisablePlayerCheckpoint(playerid);
					g_bCollectingBox[playerid] = false;
					SetPlayerCheckpoint(playerid, g_fForkliftSpace[g_iForkliftTruckNumber[GetPlayerVehicleID(playerid)]], 5.0);
				}
				else
					return SendClientMessage(playerid, GREY, "* Something went wrong. Post a bug report or try again! {00AA00}(Bug report info: Collecting)");
			}
			else {
			    if(IsPlayerInRangeOfPoint(playerid, 7.0, g_fForkliftSpace[g_iForkliftTruckNumber[GetPlayerVehicleID(playerid)]]) == 0) {
					return SendClientMessage(playerid, GREY, "* Something went wrong. Post a bug report or try again! {00AA00}(Bug report info: Dropping off)");
				}
				if(IsValidObject(g_iBoxObjID[iBoxID])) {
					new
						iRandCash = ((1000 + random(1000))*(g_iPlayerForkliftLevel[playerid]/5)), // min $200 max $400 for level 1, min $400 max $800 for level 2, et cetera
						szString[64];
					format(szString, sizeof(szString), "~g~+$%d", iRandCash);
					GameTextForPlayer(playerid, szString, 5000, 1);
					format(szString, sizeof(szString), "* Well done, you earned {00AA00}$%d{33CCFF} for your delivery!", iRandCash);
					PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
					SendClientMessage(playerid, LIGHTBLUE, szString);
					GivePlayerMoney(playerid, iRandCash);
					DestroyDynamicObject(g_iBoxObjID[iBoxID]);
					g_bIsBoxTaken[iBoxID] = false;
					g_fBoxPos[iBoxID][0] = 0.0;
					g_fBoxPos[iBoxID][1] = 0.0;
					g_fBoxPos[iBoxID][2] = 0.0;
					g_iPlayerBoxID[playerid] = -1;
					for(new iPlayer; iPlayer < MAX_PLAYERS; iPlayer++) {
					    if(iPlayer != playerid)
					    {
							if(!IsPlayerConnected(iPlayer))
								break;
							if(g_iPlayerBoxID[iPlayer] == iBoxID) {
								SendClientMessage(iPlayer, GREY, "* Your box was already dropped off - post a bug report!");
								DisablePlayerCheckpoint(iPlayer);
								if(NextAvailableBox(iBoxID) == 0) {
								    SetVehicleToRespawn(GetPlayerVehicleID(iPlayer));
						      		DestroyDynamicObject(g_iBoxObjID[g_iPlayerBoxID[iPlayer]]);
						      		DisablePlayerCheckpoint(iPlayer);
						      		g_bCollectingBox[iPlayer] = false;
						      		g_iPlayerBoxID[iPlayer] = -1;
						      		g_bIsPlayerForklifting[iPlayer] = false;
									return SendClientMessage(iPlayer, GREY, "* There are no available boxes!");
								}
								SendClientMessage(iPlayer, LIGHTBLUE, "* The next box that needs moving has been highlighted on your GPS.");
								SetPlayerCheckpoint(iPlayer, g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2], 5.0);
								g_iPlayerBoxID[iPlayer] = iBoxID;
							}
						}
					}
					DisablePlayerCheckpoint(playerid);
					if(NextAvailableBox(iBoxID) == 0) {
						SetVehicleToRespawn(GetPlayerVehicleID(playerid));
			      		DestroyDynamicObject(g_iBoxObjID[g_iPlayerBoxID[playerid]]);
			      		DisablePlayerCheckpoint(playerid);
			      		g_bCollectingBox[playerid] = false;
			      		g_iPlayerBoxID[playerid] = -1;
			      		g_bIsPlayerForklifting[playerid] = false;
				  		return SendClientMessage(playerid, GREY, "* There are no available boxes! (20/20 used)");
					}
					SendClientMessage(playerid, LIGHTBLUE, "* The next box that needs moving has been highlighted on your GPS.");
					SetPlayerCheckpoint(playerid, g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2], 5.0);
					g_iPlayerBoxID[playerid] = iBoxID;
					g_bCollectingBox[playerid] = true;
					g_iPlayerForkliftSkill[playerid] ++;
					if(g_iPlayerForkliftSkill[playerid] == 50) { // 50 points
					    g_iPlayerForkliftLevel[playerid] = 2;
					    SendClientMessage(playerid, 0xFFFF00AA, "* Your forklifting skill is now level 2. Your maximum pay went up from $400 to $800!");
					    SendClientMessage(playerid, 0xFFFF00AA, "* You also now get 10%% extra materials from your packages! (275 per package)");
					    g_fMaterialsMultiplier[playerid] = 1.1;
					}
					else if(g_iPlayerForkliftSkill[playerid] == 125) { // 75 points
					    g_iPlayerForkliftLevel[playerid] = 3;
					    SendClientMessage(playerid, 0xFFFF00AA, "* Your forklifting skill is now level 3. Your maximum pay went up from $800 to $1200!");
					    SendClientMessage(playerid, 0xFFFF00AA, "* You also now get 20%% extra materials from your packages! (300 per package)");
					    g_fMaterialsMultiplier[playerid] = 1.2;
					}
					else if(g_iPlayerForkliftSkill[playerid] == 225) { // 100 points
					    g_iPlayerForkliftLevel[playerid] = 4;
					    SendClientMessage(playerid, 0xFFFF00AA, "* Your forklifting skill is now level 4. Your maximum pay went up from $1200 to $1600!");
					    SendClientMessage(playerid, 0xFFFF00AA, "* You also now get 30%% extra materials from your packages! (325 per package)");
					    g_fMaterialsMultiplier[playerid] = 1.3;
					}
					else if(g_iPlayerForkliftSkill[playerid] == 350) { // 125 points
					    g_iPlayerForkliftLevel[playerid] = 5;
					    SendClientMessage(playerid, 0xFFFF00AA, "* Your forklifting skill is now level 5. Your maximum pay went up from $1600 to $2000!");
					    SendClientMessage(playerid, 0xFFFF00AA, "* You also now get 50%% extra materials from your packages! (375 per package)");
					    g_fMaterialsMultiplier[playerid] = 1.5;
					}
				}
				else
					SendClientMessage(playerid, GREY, "* Your box is not within 7 meters of your forklift!");
			}
		}
		else
			SendClientMessage(playerid, GREY, "* This vehicle is not a forklift truck!");
	}
	else
		SendClientMessage(playerid, GREY, "* You are not currently on a forklifting mission!");
	return 1;
}

stock IsAForklifter(iVehicleID) {
	for(new iForkliftID; iForkliftID < MAX_BOXES; iForkliftID ++) {
		if(g_iForkliftID[iForkliftID] == iVehicleID)
			return true;
		else
		    continue;
	}
	return false;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	/*if(!strcmp(cmdtext, "/join", true)) {
	    if(IsPlayerInRangeOfPoint(playerid, 5.0, 2424.3030,-2098.8564,13.7151)) {
			SendClientMessage(playerid, LIGHTBLUE, "* Congratulations on your new job as a Forklifter!");
			return SetPVarInt(playerid, "pJob", 25);
		}
		else
		    return SendClientMessage(playerid, GREY, "* You are not close enough to a job join point!");
	}*/
	return 0;
}

stock NextAvailableBox(&iBoxID) {
	new iBoxTakenCount;
	for(iBoxID = 0; iBoxID < MAX_BOXES; iBoxID++) {
		if(g_bIsBoxTaken[iBoxID] == false) {
			g_bIsBoxTaken[iBoxID] = true;
			if(IsValidObject(g_iBoxObjID[iBoxID]) == 0) {
				g_iBoxObjID[iBoxID] = CreateDynamicObject(BOX_OBJECT, g_aBoxSpaces[iBoxID][0], g_aBoxSpaces[iBoxID][1], g_aBoxSpaces[iBoxID][2], 0.0, 0.0, 0.0, -1, -1, -1, 100.0);
				printf("Creating object %d for boxID %d", g_iBoxObjID[iBoxID], iBoxID);
				GetObjectPos(g_iBoxObjID[iBoxID], g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2]);
				return 1;
			}
			else if(g_fBoxPos[iBoxID][0] == 0.0 || g_fBoxPos[iBoxID][1] == 0.0 || g_fBoxPos[iBoxID][2] == 0.0)
				GetObjectPos(g_iBoxObjID[iBoxID], g_fBoxPos[iBoxID][0], g_fBoxPos[iBoxID][1], g_fBoxPos[iBoxID][2]);
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
