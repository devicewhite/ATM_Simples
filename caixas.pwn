#define FILTERSCRIPT

#include	<a_samp>
#include	<sscanf2>
#include	<streamer>

/*
PARA OBTER O VALOR QUE O JOGADOR TEM NO CAIXA USE:
		GetPVarInt(playerid, "banco");

PARA SETAR O VALOR QUE O JOGADOR TEM NO CAIXA USE:
		SetPVarInt(playerid, "banco", valor);
*/

#if defined MODO_TESTE
public OnPlayerConnect(playerid)
{
	GivePlayerMoney(playerid, 5000);
	return 1;
}
#endif

public OnFilterScriptInit()
{
	new File:handle = fopen("atm_save.txt", io_read);
	if(handle)
	{
		new tmpstr[128];
		while(fread(handle, tmpstr))
		{
			static Float:x, Float:y, Float:z, Float:a;
			if(sscanf(tmpstr, "ffff", x, y, z, a)) continue;
			CriarATM(x, y, z, a, false);
		}

		fclose(handle);
	}
	else fclose(fopen("atm_save.txt"));
	
	print("ATM FS: carregado...");
	return 1;
}

public OnFilterScriptExit()
{
	print("ATM FS: descarregado...");
	return 1;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	static tmpstr[64];
	format(tmpstr, sizeof tmpstr, "Saldo atual: %d$", GetPVarInt(playerid, "banco"));

	switch(dialogid)
	{
		case 1001:
		{
			if(response && listitem == 0)
			{
				ShowPlayerDialog(playerid, 1002, 1, tmpstr, "Insira o valor que deseja sacar:", "Sacar", "Voltar");
			}
			else if(response && listitem == 1)
			{
				ShowPlayerDialog(playerid, 1003, 1, tmpstr, "Insira o valor que deseja depositar:", "depositar", "Voltar");
			}
		}

		case 1002:
		{
			if(!response) return 1;
	
			static grana; grana = strval(inputtext);
			if(grana <= 0) return SendClientMessage(playerid, -1, "Valor inserjdo e incorreto");
			
			if(GetPVarInt(playerid, "banco") >= grana)
			{
				GivePlayerMoney(playerid, grana);
				SetPVarInt(playerid, "banco", (GetPVarInt(playerid, "banco") - grana));
			}
			else SendClientMessage(playerid, -1, "Voce nao tem esse dinheiro guardado");
		}
		
		case 1003:
		{
			if(!response) return 1;
	
			static grana; grana = strval(inputtext);
			if(grana <= 0) return SendClientMessage(playerid, -1, "Valor inserjdo e incorreto");

			if(GetPlayerMoney(playerid) >= grana)
			{
				GivePlayerMoney(playerid, -grana);
				SetPVarInt(playerid, "banco", (GetPVarInt(playerid, "banco") + grana));
			}
			else SendClientMessage(playerid, -1, "Voce nao tem esse dinheiro em maos");
		}
		
		default: return 0;
	}
	
	if(1002 <= dialogid <= 1003)
	{
		format(tmpstr, sizeof tmpstr, "Saldo atual: %d$", GetPVarInt(playerid, "banco"));
		ShowPlayerDialog(playerid, 1001, 2, tmpstr, "Sacar\nDepositar", "OK", "Fechar");
	}
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	printf("ATM FS: %s", cmdtext);

	if(strcmp(cmdtext, "/criarcaixa") == 0)
	{
		static Float:a, Float:x, Float:y, Float:z;
		GetPlayerFacingAngle(playerid, a);
		GetPlayerPos(playerid, x, y, z);
	
		CreateDynamicObject(19324, x, y, (z - 0.5), 0.0, 0.0, a);
		SendClientMessage(playerid, -1, "Info: o caixa foi criado com sucesso!");
	}
	else if(strcmp(cmdtext, "/removercaixa") == 0)
	{
		static id;
		id = ObterATM(playerid);
	
		if(IsValidDynamicObject(id))
		{
			SendClientMessage(playerid, -1, "Info: o caixa mais perto foi removido!");
			DestroyDynamicObject(id);

			static File:handle;
			handle = fopen("atm_save.txt", io_write);
			if(handle)
			{
				static tmpstr[128], i;
				for(i = Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); i; --i)
				{
					if(19324 == Streamer_GetIntData(STREAMER_TYPE_OBJECT, i, E_STREAMER_MODEL_ID))
					{
						static Float:x, Float:y, Float:z, Float:a;
						GetDynamicObjectRot(i, x, y, a);
						GetDynamicObjectPos(i, x, y, z);
		
						format(tmpstr, sizeof tmpstr, "%f %f %f %f\n", x, y, z, a);
						fwrite(handle, tmpstr);
					}
				}
		
				fclose(handle);
			}
		}
		else SendClientMessage(playerid, -1, "Erro: voce nao esta perto de um caixa");
	}
	else if(strcmp(cmdtext, "/salvarcaixas") == 0)
	{
		SetTimer("OnGameModeExit", 100, 0);
		SendClientMessage(playerid, -1, "Info: Todos os caixas foram salvos");
	}
	else if(strcmp(cmdtext, "/atm") == 0)
	{
		if(ObterATM(playerid))
		{
			static tmpstr[64];
			format(tmpstr, sizeof tmpstr, "Saldo atual: %d$", GetPVarInt(playerid, "banco"));
			ShowPlayerDialog(playerid, 1001, 2, tmpstr, "Sacar\nDepositar", "OK", "Fechar");
		}
	}
	else SendClientMessage(playerid, -1, "Esse comando nao existe");
	return 1;
}

CriarATM(Float:x, Float:y, Float:z, Float:a, bool:salvar)
{
	static id;
	id = CreateDynamicObject(19324, x, y, z, 0.0, 0.0, a);
	if(salvar)
	{
		static File:handle, tmpstr[128];
		handle = fopen("atm_save.txt", io_append);
		if(handle)
		{
			format(tmpstr, sizeof tmpstr, "%f %f %f %f\n", x, y, z, a);
			fwrite(handle, tmpstr);
			fclose(handle);
		}
	}
	return IsValidDynamicObject(id);
}

ObterATM(playerid)
{
	static Float:x, Float:y, Float:z;
	if(!GetPlayerPos(playerid, x, y, z)) return 0;

	static Float:distance[2], STREAMER_TAG_OBJECT:closestid;
	distance[0] = 6.0, closestid = INVALID_STREAMER_ID;

	static STREAMER_TAG_OBJECT:i;
	for(i = Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); i; --i)
	{
		if(!IsValidDynamicObject(i)) continue;
		if(19324 == Streamer_GetIntData(STREAMER_TYPE_OBJECT, i, E_STREAMER_MODEL_ID))
		{
			Streamer_GetDistanceToItem(x, y, z, STREAMER_TYPE_OBJECT, i, distance[1]);
			if(distance[1] >= distance[0]) continue;
	
			distance[0] = distance[1];
			closestid = i;
		}
	}

	return closestid;
}

	
