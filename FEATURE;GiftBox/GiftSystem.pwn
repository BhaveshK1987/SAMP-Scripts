#define MAX_GIFTS 50
#define GIFTDIALOGQUESTIONID 1200
#define GIFTDIALOGANSWERID 1201
#define GIFTDIALOGREWARDID 1202
#define GIFTDIALOGPQUESTIONID 1203

enum eGiftInfo {
    szGCreator[MAX_PLAYER_NAME],
    iGInterior,
    iGVW,
    szGQuestion[120],
    szGAnswer[40],
    iGReward,
    iGID,
    Float:fGX, Float:fGY, Float:fGZ,
    bool:bGCreated,
    iGObject,
    Text3D:iG3DTextLabel,
    bool:bGBeingOpened
};

new g_aGiftInfo[MAX_GIFTS][eGiftInfo];
new g_iPlayerGiftStep[MAX_PLAYERS];
new g_iEditingGift[MAX_PLAYERS];
new g_iPlayerOpeningGift[MAX_PLAYERS];

stock FindFreeGiftSlot() {
    for(new iGiftSlotID; iGiftSlotID < MAX_GIFTS; iGiftSlotID++) {
        if(!g_aGiftInfo[iGiftSlotID][bGCreated])
            return iGiftSlotID;
    }
    return -1;
}
    
stock RemoveGift(playerid, giftid) {
    new szGiftDeletedMessage[40];
    format(g_aGiftInfo[giftid][szGCreator], 24, "None");
    g_aGiftInfo[giftid][iGInterior] = 0;
    g_aGiftInfo[giftid][iGVW] = 0;
    g_aGiftInfo[giftid][fGX] = 0.0; 
    g_aGiftInfo[giftid][fGY] = 0.0; 
    g_aGiftInfo[giftid][fGZ] = 0.0;
    g_aGiftInfo[giftid][bGCreated] = false;
    format(g_aGiftInfo[giftid][szGQuestion], 120, "None");
    format(g_aGiftInfo[giftid][szGAnswer], 120, "None");
    Delete3DTextLabel(g_aGiftInfo[giftid][iG3DTextLabel]);
    format(szGiftDeletedMessage, sizeof(szGiftDeletedMessage), "[GIFT] Gift ID %d is now removed.", giftid);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftDeletedMessage);
    DestroyObject(g_aGiftInfo[giftid][iGObject]);
    g_iEditingGift[playerid] = -1;
    return 1;
}
    
stock ShowGiftStats(playerid, giftid) {
    SendClientMessage(playerid, 0xFFFF00AA, "Lawless Gift System - Stats");
    SendClientMessage(playerid, 0xFFFF00AA, "___________________________");
    new szGiftStatsMessage[140];
    format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "ID: %d", g_aGiftInfo[giftid][iGID]);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Creator: %s.", g_aGiftInfo[giftid][szGCreator]);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Interior ID: %d | Virtual World ID: %d.", g_aGiftInfo[giftid][iGInterior], g_aGiftInfo[giftid][iGVW]);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Position: %f, %f, %f.", g_aGiftInfo[giftid][fGX], g_aGiftInfo[giftid][fGY], g_aGiftInfo[giftid][fGZ]);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Question: %s", g_aGiftInfo[giftid][szGQuestion]);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Answer: %s.", g_aGiftInfo[giftid][szGAnswer]);
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    switch(g_aGiftInfo[giftid][iGReward]) {
        case 1:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Daisy (14 days).");
        case 2:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Rose (14 days).");
        case 3: 
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Ivy (14 days).");
        case 4: 
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Drugs (20G pot, 10G crack, 4G chemicals).");
        case 5: 
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Double Experience (2 hours).");
        case 6:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Weapon(s) (random).");
        case 7:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Custom Vehicle.");
        case 8:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: MP3.");
        case 9:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Custom license plate.");
        case 10:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Kick.");
        case 11:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Bomb.");
        case 12:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: $25,000.");
        case 13:
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Forum Usertitle.");
        case 14: 
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: RP (4 respect points).");
        case 15: 
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Boombox.");
        case 16: 
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Reward: Dynamic Door.");
    }
    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
    return 1;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{
    new Float:oldX, Float:oldY, Float:oldZ,
    Float:oldRotX, Float:oldRotY, Float:oldRotZ;
    GetObjectPos(objectid, oldX, oldY, oldZ);
    GetObjectRot(objectid, oldRotX, oldRotY, oldRotZ);
    if(!playerobject) {
        if(!IsValidObject(objectid))
            return 1;
        MoveObject(objectid, fX, fY, fZ, 10.0, fRotX, fRotY, fRotZ);
    }
    if(response == EDIT_RESPONSE_FINAL)    {
        if(g_iPlayerGiftStep[playerid] == 2) {
            for(new iGiftID; iGiftID < MAX_GIFTS; iGiftID++) {
                if(g_aGiftInfo[iGiftID][iGObject] == objectid) {
                    g_aGiftInfo[iGiftID][fGX] = fX;
                    g_aGiftInfo[iGiftID][fGY] = fY;
                    g_aGiftInfo[iGiftID][fGZ] = fZ;
                    g_iPlayerGiftStep[playerid] = 3;
                    ShowPlayerDialog(playerid, GIFTDIALOGQUESTIONID, DIALOG_STYLE_INPUT, "Lawless Gift System", "Please type a specific question for the players to answer.\nWhen they answer it correctly they will be rewarded.", "Save", "Cancel");
                }
                else
                    continue;
            }
        }
    }
    if(response == EDIT_RESPONSE_CANCEL) {
        if(g_iPlayerGiftStep[playerid] == 2) {
            for(new iGiftID; iGiftID < MAX_GIFTS; iGiftID++) {
                if(g_aGiftInfo[iGiftID][iGObject] == objectid) {
                    RemoveGift(playerid, iGiftID);
                    g_iPlayerGiftStep[playerid] = 0;
                    g_iEditingGift[playerid] = 0;
                }
            }
        }
        if(!playerobject) {
            SetObjectPos(objectid, oldX, oldY, oldZ);
            SetObjectRot(objectid, oldRotX, oldRotY, oldRotZ);
        }
        else {
            SetPlayerObjectPos(playerid, objectid, oldX, oldY, oldZ);
            SetPlayerObjectRot(playerid, objectid, oldRotX, oldRotY, oldRotZ);
        }
    }
}

CMD:opengift(playerid, params[]) {
    #pragma unused params
    for(new iGiftID; iGiftID < MAX_GIFTS; iGiftID++) {
        if(IsPlayerInRangeOfPoint(playerid, 5.0, g_aGiftInfo[iGiftID][fGX], g_aGiftInfo[iGiftID][fGY], g_aGiftInfo[iGiftID][fGZ]) && GetPlayerInterior(playerid) == g_aGiftInfo[iGiftID][iGInterior] && GetPlayerVirtualWorld(playerid) == g_aGiftInfo[iGiftID][iGVW] && g_aGiftInfo[iGiftID][bGBeingOpened] == false) {
            new szGiftFoundMsg[160];
            format(szGiftFoundMsg, sizeof(szGiftFoundMsg), "Congratulations!\nYou found a gift box.\nPlease answer the following question in order to open the gift.\nQuestion: %s", g_aGiftInfo[iGiftID][szGQuestion]);
            ShowPlayerDialog(playerid, GIFTDIALOGPQUESTIONID, DIALOG_STYLE_INPUT, "Lawless Gift System", szGiftFoundMsg, "Done", "Cancel");
            g_iPlayerOpeningGift[playerid] = iGiftID;
            g_aGiftInfo[iGiftID][bGBeingOpened] = true;
        }
        else
            continue;
      }
    return 1;
}

CMD:spawngift(playerid, params[]) {
    #pragma unused params
    if(g_iPlayerGiftStep[playerid] == 0) {
        SendClientMessage(playerid, 0xFFFFFFAA, "[GIFT]: You are now setting up a gift box, please go to the desired location and type /spawngift again.");
        g_iPlayerGiftStep[playerid] = 1;
    }
    else if(g_iPlayerGiftStep[playerid] == 1) {
        new iGift = FindFreeGiftSlot();
        new szGiftSpawnMessage[34];
        g_aGiftInfo[iGift][iGObject] = CreateObject(19055, fX + 5.0, fY, fZ, 0.0, 0.0, 0.0, 15.0);
        g_iPlayerGiftStep[playerid] = 2;
        format(szGiftSpawnMessage, sizeof(szGiftSpawnMessage), "[GIFT]: Gift ID %d was spawned.", iGift);
        g_iEditingGift[playerid] = iGift;
        SendClientMessage(playerid, 0xFF0000AA, szGiftSpawnMessage);
        GetPlayerName(playerid, g_aGiftInfo[iGift][szGCreator], sizeof(g_aGiftInfo[iGift][szGCreator]));
        g_aGiftInfo[iGift][iGInterior] = GetPlayerInterior(playerid);
        g_aGiftInfo[iGift][iGVW] = GetPlayerVirtualWorld(playerid);
        g_aGiftInfo[iGift][iGID] = iGift;
        GetPlayerPos(playerid, g_aGiftInfo[iGift][fGX], g_aGiftInfo[iGift][fGY], g_aGiftInfo[iGift][fGZ]);
        g_aGiftInfo[iGift][bGBeingOpened] = true;
        g_aGiftInfo[iGift][bGCreated] = true;
        EditObject(playerid, g_aGiftInfo[iGift][iGObject]);
        SendClientMessage(playerid, 0xFFFFFFAA, "[GIFT]: Please edit the object to your needs.");
    }
    return 1;
}

CMD:deletegift(playerid, params[]) {
    new iGiftID;
    if (sscanf(params, "i", iGiftID))
         return SendClientMessage(playerid, 0xFFFFFF00, "USAGE: /deletegift [ID].");
    else if (!IsValidObject(g_aGiftInfo[GiftID][iGObject]) || GiftID > 50)
         return SendClientMessage(playerid, 0xAFAFAF00, "This gift does not exist.");
    else
        RemoveGift(playerid, GiftID);
    return 1;
}
    
CMD:listgifts(playerid, params[]) {
    SendClientMessage(playerid, 0xFFFF00AA, "Lawless Gift System - Stats");
    SendClientMessage(playerid, 0xFFFF00AA, "___________________________");
    new szGiftStatsMessage[140], szGiftReward[140];
    for(new i; i < MAX_GIFTS; i++) {
        if(g_aGiftInfo[i][bGCreated] == true) {
            switch(g_aGiftInfo[i][iGReward]) {
                case 1: {
                    format(szGiftReward, 140, "Reward: Daisy ( 14 days ).");
                }
                case 2: {
                    format(szGiftReward, 140, "Reward: Rose ( 14 days ).");
                }
                case 3: {
                    format(szGiftReward, 140, "Reward: Ivy ( 14 days ).");
                }
                case 4: {
                    format(szGiftReward, 140, "Reward: Drugs ( 20G pot, 10G crack, 4G chemicals ).");
                }
                case 5: {
                    format(szGiftReward, 140, "Reward: Double Experience ( 2 hours ).");
                }
                case 6: {
                    format(szGiftReward, 140, "Reward: Weapon(s) ( random ).");
                }
                case 7: {
                    format(szGiftReward, 140, "Reward: Custom Vehicle.");
                }
                case 8: {
                    format(szGiftReward, 140, "Reward: MP3.");
                }
                case 9: {
                    format(szGiftReward, 140, "Reward: Custom license plate.");
                }
                case 10: {
                    format(szGiftReward, 140, "Reward: Kick.");
                }
                case 11: {
                    format(szGiftReward, 140, "Reward: Bomb.");
                }
                case 12: {
                    format(szGiftReward, 140, "Reward: $25,000.");
                }
                case 13: {
                    format(szGiftReward, 140, "Reward: Forum Usertitle.");
                }
                case 14: {
                    format(szGiftReward, 140, "Reward: RP ( 4 Respect points ).");
                }
                case 15: {
                    format(szGiftReward, 140, "Reward: Boombox.");
                }
                case 16: {
                    format(szGiftReward, 140, "Reward: Dynamic Door.");
                }
            }
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "ID: %d | Creator: %s | Positions: %f, %f, %f | %s", g_aGiftInfo[i][iGID], g_aGiftInfo[i][szGCreator], g_aGiftInfo[i][fGX], g_aGiftInfo[i][fGY], g_aGiftInfo[i][fGZ], szGiftReward);
            SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "ID: %d | Question: %s | Answer: %s", g_aGiftInfo[i][iGID], g_aGiftInfo[i][szGQuestion], g_aGiftInfo[i][szGAnswer]);
            SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
         }
    }
    return 1;
}

CMD:giftstats(playerid, params[]) {
    new iGiftID;
    if (sscanf(params, "i", iGiftID) || GiftID > 50)
         return SendClientMessage(playerid, 0xFFFFFF00, "USAGE: /giftstats [ID].");
    else if (!IsValidObject(g_aGiftInfo[GiftID][iGObject]))
         return SendClientMessage(playerid, 0xAFAFAF00, "This gift does not exist.");
    else
        ShowGiftStats(playerid, GiftID);
    return 1;
}

CMD:gotogift(playerid, params[]) {
    new GiftID, szGiftTeleportMessage[40];
    if (sscanf(params, "i", GiftID))
         return SendClientMessage(playerid, 0xFFFFFF00, "USAGE: /gotogift [ID].");
    else if(!IsValidObject(g_aGiftInfo[GiftID][iGObject]) || GiftID > 50)
        return SendClientMessage(playerid, 0xAFAFAF00, "This gift does not exist.");
    else {
        format(szGiftTeleportMessage, sizeof(szGiftTeleportMessage), "[GIFT]: You teleported to gift ID %d.", GiftID);
        SendClientMessage(playerid, 0xFFFFFFAA, szGiftTeleportMessage);
        SetPlayerPos(playerid, g_aGiftInfo[GiftID][fGX], g_aGiftInfo[GiftID][fGY] + 2.5, g_aGiftInfo[GiftID][fGZ]);
        SetPlayerInterior(playerid, g_aGiftInfo[GiftID][iGInterior]);
        SetPlayerVirtualWorld(playerid, g_aGiftInfo[GiftID][iGVW]);
     }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid == GIFTDIALOGQUESTIONID) {
        if(response) {
            if(strlen(inputtext) == 0)
                return ShowPlayerDialog(playerid, GIFTDIALOGQUESTIONID, DIALOG_STYLE_INPUT, "Lawless Gift System", "Please type a specific question for the players to answer.\nWhen they answer it correctly they will be rewarded.", "Save", "Cancel");
            if(strlen(inputtext) > 120)
                return ShowPlayerDialog(playerid, GIFTDIALOGQUESTIONID, DIALOG_STYLE_INPUT, "Lawless Gift System", "Please type a specific question for the players to answer.\nWhen they answer it correctly they will be rewarded.", "Save", "Cancel");
            else {
                format(g_aGiftInfo[g_iEditingGift[playerid]][szGQuestion], 120, inputtext);
                SendClientMessage(playerid, 0xFFFFFFAA, "[GIFT]: You saved the question.");
                g_iPlayerGiftStep[playerid] = 4;
                ShowPlayerDialog(playerid, GIFTDIALOGANSWERID, DIALOG_STYLE_INPUT, "Lawless Gift System", "You saved the question.\nPlease fill in an answer now.", "Save", "Cancel");
            }
        }
        else if(!response) {
            RemoveGift(playerid, g_iEditingGift[playerid]);
            g_iPlayerGiftStep[playerid] = 0;
            g_iEditingGift[playerid] = 0;
        }    
    }
    else if(dialogid == GIFTDIALOGANSWERID) 
    {
        if(response) {
               if(strlen(inputtext) == 0)
                return ShowPlayerDialog(playerid, GIFTDIALOGANSWERID, DIALOG_STYLE_INPUT, "Lawless Gift System", "You saved the question.\nPlease fill in an answer now.", "Save", "Cancel");
            if(strlen(inputtext) > 120)
                return ShowPlayerDialog(playerid, GIFTDIALOGANSWERID, DIALOG_STYLE_INPUT, "Lawless Gift System", "You saved the question.\nPlease fill in an answer now.", "Save", "Cancel");
            else {
                format(g_aGiftInfo[g_iEditingGift[playerid]][szGAnswer], 120, inputtext);
                SendClientMessage(playerid, 0xFFFFFFAA, "[GIFT]: You saved the answer.");
                g_iPlayerGiftStep[playerid] = 5;
                ShowPlayerDialog(playerid, GIFTDIALOGREWARDID, DIALOG_STYLE_LIST, "Lawless Gift System", "Daisy(14)\nRose(14)\nIvy(14)\nDrugs(20/10/4)\nDouble EXP(2)\nWeapon(s)\nCustom Vehicle\nMP3\nCustom Licenseplate\nKick\nBomb\n$25,000\nForum usertitle\n4 RP\nBoombox\nDD", "Save", "Cancel");
            }
        }
        else if(!response) {
            RemoveGift(playerid, g_iEditingGift[playerid]);
            g_iPlayerGiftStep[playerid] = 0;
            g_iEditingGift[playerid] = 0;
        }
    }
    else if(dialogid == GIFTDIALOGREWARDID) {
        if(response) {
            new iGiftID = g_iEditingGift[playerid];
            g_aGiftInfo[iGiftID][iGReward] = listitem + 1;
            new szFinishedMessage[120];
            format(szFinishedMessage, 120, "[GIFT]: Gift ID %d is now saved.", g_iEditingGift[playerid]);
            SendClientMessage(playerid, 0xFFFFFFAA, szFinishedMessage);
            g_iPlayerGiftStep[playerid] = 0;
            ShowGiftStats(playerid, iGiftID);
            new szGiftLabelMessage[60];
            format(szGiftLabelMessage, sizeof(szGiftLabelMessage), "Gift box\nID: %d\nType /opengift to open it!", g_aGiftInfo[iGiftID][iGID]);
            g_aGiftInfo[iGiftID][iG3DTextLabel] = Create3DTextLabel(szGiftLabelMessage, 0xFFFF00AA, g_aGiftInfo[iGiftID][fGX], g_aGiftInfo[iGiftID][fGY], g_aGiftInfo[iGiftID][fGZ], 15.0, g_aGiftInfo[iGiftID][iGVW], 1);
            g_iEditingGift[playerid] = -1;
            g_aGiftInfo[iGiftID][bGBeingOpened] = false;
        }
        else if(!response) {
            RemoveGift(playerid, g_iEditingGift[playerid]);
            g_iPlayerGiftStep[playerid] = 0;
            g_iEditingGift[playerid] = 0;
        }
    }
    else if(dialogid == GIFTDIALOGPQUESTIONID) {
        if(response) {
            new szGiftStatsMessage[140];
            if(strlen(inputtext) > 0) {
                if(!strcmp(inputtext, g_aGiftInfo[g_iPlayerOpeningGift[playerid]][szGAnswer], true)) {
                    switch(g_aGiftInfo[g_iPlayerOpeningGift[playerid]][iGReward]) {
                        case 1: {
                            if(PlayerInfo[playerid][pDonator] < 1) {
								format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Daisy (14 days).");
								PlayerInfo[playerid][pDonator] = 1;
								PlayerInfo[playerid][pDonatorDays] = 14;
							}
							else {
								PlayerInfo[playerid][pDonatorDays] += 14;
							}
                        }
                        case 2: {
							if(PlayerInfo[playerid][pDonator] < 2) {
								format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Rose (14 days).");
								PlayerInfo[playerid][pDonator] = 2;
								PlayerInfo[playerid][pDonatorDays] = 14;
							}
							else {
								PlayerInfo[playerid][pDonatorDays] += 14;
							}
						}
						case 3: {
							if(PlayerInfo[playerid][pDonator] < 3) {
								format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Ivy (14 days).");
								PlayerInfo[playerid][pDonator] = 3;
								PlayerInfo[playerid][pDonatorDays] = 14;
							}
							else {
								PlayerInfo[playerid][pDonatorDays] += 14;
							}
						}
						case 4: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Drugs (20g pot, 10g crack, 4g chemicals).");
							PlayerInfo[playerid][pChemicals] += 4;
							PlayerInfo[playerid][pCrack] += 10;
							PlayerInfo[playerid][pPot] += 20;
						}
						case 5: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Double experience (2 hours).");
							PlayerInfo[playerid][pDoubleExp] = 2; // idk variable
						}
						case 6: {
                            new 
                                aRandWeapons[1+random(4)],
                                szWeaponStr[32],
                                szWeaponName[24];
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: ");
                            format(szWeaponStr, sizeof(szWeaponStr), "%d weapons (", sizeof(aRandWeapons));
                            strcat(szGiftStatsMessage, szWeaponStr);
                            for(new iWeaponCount; iWeaponCount < sizeof(aRandWeapons); iWeaponCount++)
                            {
                                aRandWeapons[iWeaponCount] = 1+random(33);
                                if(aRandWeapons[iWeaponCount] == 4 || aRandWeapons[iWeaponCount] == 16 || aRandWeapons[iWeaponCount] == 17 || aRandWeapons[iWeaponCount] == 18 \
                                || aRandWeapons[iWeaponCount] == 21 || aRandWeapons[iWeaponCount] == 19 || aRandWeapons[iWeaponCount] == 20) {
                                    aRandWeapons[iWeaponCount] = 1+random(33);
                                }
                                if(iWeaponCount > 0) {
                                    if(aRandWeapons[iWeaponCount-1] == aRandWeapons[iWeaponCount]) {
                                        aRandWeaponsCount[iWeaponCount] = 1+random(33);
                                    }
                                }
                                GivePlayerWeapon(playerid, aRandWeapons[iWeaponCount], 60000);
                                if(iWeaponCount != sizeof(aRandWeapons)-1) {
                                    format(szWeaponStr, sizeof(szWeaponStr), "%s, ", szWeaponName);
                                    strcat(szGiftStatsMessage, szWeaponStr);
                                }
                                else {
                                    format(szWeaponStr, sizeof(szWeaponStr), "%s)", szWeaponName);
                                    strcat(szGiftStatsMessage, szWeaponStr);
                                }
                            }
                        }
                        case 7: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Custom vehicle.");
                            AddFlag(playerid, playerid, "(GIFT) Owed a custom vehicle as a reward.");
                        }
                        case 8: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: MP3.");
                            PlayerInfo[playerid][pMP3] = 1;
                        }
                        case 9: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Custom license plate.");
                            AddFlag(playerid, playerid, "(GIFT) Owed a custom license plate as a reward.");
                        }
                        case 10: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: a kick. Bye!");
                            SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "AdmCmd: %s was kicked by GIFTBOX", szPlayerName);
                            ABroadCast(0xFF634700, szGiftStatsMessage, 1);
                            Kick(playerid);
                        }
                        case 11: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: a bomb (/armbomb).");
                            PlayerInfo[playerid][pBomb] = 1;
                        }
                        case 12: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: $25,000.");
                            GivePlayerCash(playerid, 25000);
                        }
                        case 13: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Custom forum usertitle.");
                            AddFlag(playerid, playerid, "(GIFT) Owed a custom forum usertitle as a reward.");
                        }
                        case 14: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: 4 respect points");
                            PlayerInfo[playerid][pRespect] += 4;
                        }
                        case 15: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Boombox.");
                            PlayerInfo[playerid][pBoombox] = 1;
                        }
                        case 16: {
                            format(szGiftStatsMessage, sizeof(szGiftStatsMessage), "Congratulations! Your reward is: Dynamic Door.");
                            AddFlag(playerid, playerid, "(GIFT) Owed a Dynamic Door as a reward.");
                        }
                    }
                    PlayAudioStreamForPlayer(playerid, "http://noproblo.dayjo.org/ZeldaSounds/ZSS/ZSS_Secret.wav");
                    RemoveGift(playerid, g_aGiftInfo[g_iPlayerOpeningGift[playerid]][iGID]);
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFFFFFF, " ");
                    SendClientMessage(playerid, 0xFFFF00AA, "Lawless Gift System");
                    SendClientMessage(playerid, 0xFFFF00AA, "___________________________");
                    SendClientMessage(playerid, 0xFFFFFFFF, szGiftStatsMessage);
                }
                else {
                    g_aGiftInfo[g_iPlayerOpeningGift[playerid]][bGBeingOpened] = false;
                    g_iPlayerOpeningGift[playerid] = -1;
                    SendClientMessage(playerid, 0xFFFFFFFF, "[GIFT]: Sorry! That's the wrong answer.");
                }
            }
            else {
                g_aGiftInfo[g_iPlayerOpeningGift[playerid]][bGBeingOpened] = false;
            }
        }
        else {
            g_aGiftInfo[g_iPlayerOpeningGift[playerid]][bGBeingOpened] = false;
            g_iPlayerOpeningGift[playerid] = -1;
        }
    }
    return 1;
}