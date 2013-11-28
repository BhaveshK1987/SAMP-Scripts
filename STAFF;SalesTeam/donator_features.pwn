/* Change commands of:
	donators -> donators, setdonator, give boombox, give mp3
	businesses -> createbusiness, editbusiness
	lands -> create land, edit land
admin level check to this */

if(PlayerInfo[playerid][pAdmin] >= 5 || PlayerInfo[playerid][pSalesTeam] == 1)



/* Change:
	cmd:createpvehicle
admin level check to this */

if(PlayerInfo[playerid][pAdmin] < 5 && PlayerInfo[playerid][pSalesTeam] == 0)
	return SendClientMessage(playerid, COLOR_GREY, "You're not allowed to use this command.");
