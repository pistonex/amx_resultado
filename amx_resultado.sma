/*
*
*
*     AMX Mod X script. 
*     
*     (c) Copyright 2008-2009, Insides > Linux
*     
*     
*     Script para la adiministracion semi-automatica de un cerrado en Counter-Strike
*     Lleva un conteo de las rondas ganadas por ambos equipos y da el resultado
*     de las mismas mediante el comando "say /resultado y mensajes HUD" .
*
*     Al finalizar la primera mitad hace el cambio de teams automatico y muestra el resultado
*     Al completarse las 16 rondas, finaliza el cerrado mediante mensajes HUD.
*
*     Como usarlo:
*
*     Poner la Cvar "amx_resultado 1" en la cfg de cerrado, y 0 en las demas.
*     
*     El plugin contiene un comando "amx_vale" por lo tanto para que funcione 
*     NO usar ninguna vale.cfg simplemente escribir "amx_vale" en la consola
*
*     IMPORTANTE: para evitar conflictos recomiendo borrar el vale.cfg o crear una que 
*     solo contenga el comando "amx_vale" en su interior.
*
*     Opcionalmente se puede usar el plugin para que cuando todos los players
*     Escriban /ready por say, se envie el vale automaticamente una ves que la totalidad de los players escribieron /ready.
*     Esto viene desactivado por default Para que esto funcione se debe poner la cvar "amx_ready 1" en el archivo cerrado.cfg
*
*     Opcionalmente se puede blockear el comando SAY mediante la CVAR amx_nosay 1|0
*     En este caso los clientes no podran usar el comando say solo podran usar el comando say pausa para pedir pausar el game.
*     Admines con flag ADMIN_CFG podran usar el say libremente.
*
*     Comandos Cliente :
*
*     say /ready  : para informar que estas listo
*     say /noready  : para informar que no estas listo
*     say /resultado  : informa los valores de resultado
*     say /pass  : informa el valor de la cvar sv_password
*     say /nopass :  quita el password
*     say /rr  :  Restart Round
*     say /cerrado  ;  ejecuta cfg cerrado
*     say /publico  :  ejecuta cfg publico
*     say /vale  :  ejecuta cfg vale
*     say /poss  :  ejecuta la cfg poss
*     say /practica  :  ejecuta cfg practica
*     say pausa  :  Pedir pausear el Game
*
*
*
*
*
*     COMANDOS Server:
*
*     amx_vale    =    Comienza el cerrrado, resetea los contadores.
*     
*     amx_nuevo   =    Borra todos los contadores para comenzar un nuevo cerrado
*                      es IMPORTANTE poner este comando en el archivo publico.cfg
*
*
*     IMPORTANTE *
*
*     Todos los mensajes salen con el TAG del server, para cambiar este modificar la variable SRVTAG "[Insides]" linea "83".
*
*
*     Adicionales:
*     
*     Si se ejecuta el comando amx_vale y el server se encuentra sin pass se pone la pass por default "tetas" la misma puede ser cambiada
*     en la linea "82" modificando su valor.
*
*     Si alguien escribe la palabra "pass" se  muestra el contenido de la cvar sv_password.
*
*     Al comenzar el cerrado se desactiva el AMX automaticamente. Se vuelve a activar al concluir ambas mitades.
*     Al comenzar el cerrado se blockea el cambio de teams hasta que concluya el mismo.
*
*     Al Finalizar el cerrado se Informa los players que mas Frags obtuvieron en la primera Mitad y en la Segunda Mitad.
*
*
*     
*     Agradecimientos:
*     
*     DAM , [Lo]Phreak^n^c , JON , V3x
*
*
*     Dudas y Consultas : MSN : linux@insides.com.ar
*                         WEB : www.insides.com.ar/foro
*
*     
*     Live free or Die !
*     Debian GNU/Linux Usuario #220572
*     
*     IMPORTANTE:
*     Este script es de libre distribucion siempre y cuando se mantengan la fuente y el autor.
*     
*     Fecha de publicacion : 08/10/2008
*
*
*/


#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN "Resultado Cerrados"
#define VERSION "4.7"
#define AUTHOR "!ns - Linux"

#define pwDEF "salemix"
#define SRVTAG "[Insides Team]"

#define TASK_LISTA 001
#define TASK_CHE 002
#define TASK_MENSAJE 003
#define TASK_CAMBIO 004
#define TASK_PRINT 005
#define TASK_MSG 006

#define PlugActivo (get_pcvar_num(g_RESULTADO))
#define HudGris set_hudmessage(64, 64, 64, -1.0, 0.20, 2, 0.02, 12.00, 0.01, 0.1, -1)
#define HudNaR set_hudmessage(200, 100, 0, -1.0, -1.0, 1)

new tt_win, ct_win, total, totalCT, totalTT, globalCT, globalTT, g_RESULTADO, g_READY, g_SAY, ReadyCont, FraMitad, FraFinal, MasFraguer1, MasFraguer2

new bool:EstoyReady[33]
new bool:BorraLista
new bool:mitad = false
new bool:end = false
new bool:pasarse = false
new bool:ready = false
new bool:ready2 = false

 
public plugin_init() {

	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_concmd("amx_vale", "cmdVale", ADMIN_CVAR, "Empieza cerrado")
	register_concmd("amx_nuevo", "cmdNuevo", ADMIN_CVAR, "Limpia todo")
	register_concmd("say /nopass","cmdNopass",ADMIN_CFG)
	register_concmd("say /vale","cmdVale",ADMIN_CFG)
	register_concmd("say /cerrado","cmdCerrado",ADMIN_CFG)
	register_concmd("say /practica","cmdPractica", ADMIN_CFG)
	register_concmd("say /rr","cmdRR",ADMIN_CFG)
	register_concmd("say /poss","cmdPoss",ADMIN_CFG)
	register_concmd("say /publico","cmdPublico",ADMIN_CFG)  
	register_clcmd("say /resultado","say_resultado")
	register_clcmd("say_team /resultado","say_resultado")
	register_clcmd("say_team /ready", "menu_ready")
	register_clcmd("say /ready", "menu_ready")
	register_clcmd("say_team","sayPass")  
	register_clcmd("say","sayPass")
	register_clcmd("say","nosay")
	register_clcmd("chooseteam", "cmdCambioTeam")
	register_logevent("round_end", 2, "1=Round_End")  
	register_event("HLTV", "nuevo_round", "a", "1=0", "2=0") 
	register_event("TeamScore","captura_score","a")
	g_RESULTADO = register_cvar("amx_resultado","0") 
	g_READY = register_cvar("amx_ready","0") 
	g_SAY = register_cvar("amx_nosay","0") 
	register_cvar("[Resultado] by Linux", "v4.7", FCVAR_SPONLY|FCVAR_SERVER)

	set_task(180.0,"CheckSlots",_,_,_,"b")

	return PLUGIN_CONTINUE
}

public client_disconnect(id) { 
    
    if(EstoyReady[id]) {
		EstoyReady[id] = false;
		ReadyCont--;
	}
} 

public plugin_cfg() {

	if(is_plugin_loaded("Pause Plugins") != -1)
		server_cmd("amx_pausecfg add ^"%s^"", PLUGIN)
}

public off() {
	
	server_cmd("amx_off")
}

public captura_score() {

	if PlugActivo {

	new team[16],Float:score
	read_data(1,team,15)
	read_data(2,score)
	 
	if(equal(team,"CT"))
  		ct_win = floatround(score)
 	
	
	if(equal(team,"TERRORIST"))
  		tt_win = floatround(score)
	
	total = ct_win + tt_win	
	}
}

public nuevo_round(id){

	if (get_pcvar_num(g_READY)) {
		ready = true
		ready2 = true
}
	else if (!get_pcvar_num(g_READY)) {
		ready = false
}
	if (ready) {
	
	set_task(1.0, "ActualizaLista", TASK_LISTA, _, _, "b")
	set_task(1.0, "CheckLista", TASK_CHE, _, _, "b")
	set_task(2.0, "mensaje", TASK_MENSAJE)
	client_cmd(id,"say /ready")
	}
}

public round_end(id){


	if PlugActivo   {	

	if (total == 15 && (!mitad)) {

	totalCT = tt_win
	totalTT = ct_win
	
	FraMitad = El_mas_Frager();	
	MasFraguer1 = get_user_frags(FraMitad)

	if (ready2) {
	set_pcvar_num (g_READY, 1)
}
	set_task(1.0, "cambio_teams", TASK_CAMBIO)
	server_cmd("sv_restart 2")	
	
	mitad = true
	
	client_print(0,print_chat,"%s  Resultado : PRIMERA MITAD FINALIZADA",SRVTAG)
	client_print(0,print_chat,"%s  Resultado Parcial  CTs: %i - Terroristas : %i", SRVTAG, totalTT, totalCT )
	server_cmd("amx_on")
	set_task(4.0, "mitadmsg")
	
	globalCT = totalCT
	globalTT = totalTT
	tt_win = 0
	ct_win = 0

	}
}
	if (mitad && PlugActivo) {

		if (ct_win + totalCT == 16){
			client_print(0,print_chat,"%s  Resultado : CTs GANAN EL MAPA",SRVTAG)
			HudNaR
			show_hudmessage(0, "GAME OVER ^nCTs GANAN EL MAPA")	

			end = true
			mitad = false
		}
		else if (tt_win + totalTT == 16)
		{
			client_print(0,print_chat,"%s  Resultado : FINAL DEL CERRADO ^nTTs GANAN EL MAPA",SRVTAG)
			HudNaR
			show_hudmessage(0, "GAME OVER ^nTerroristas GANAN EL MAPA")
			
			end = true
			mitad = false
		}
		else if (tt_win + totalTT == 15 && ct_win + totalCT == 15)
		{
			client_print(0,print_chat,"%s  Resultado :  MAPA EMPATADO",SRVTAG)	
			HudNaR
			show_hudmessage(0, "GAME OVER ^nMAPA EMPATADO")

			end = true
			mitad = false
		}
		if (end){

		client_print(0,print_chat,"%s  Resultado : FINAL Parcial CTs: %i - Terroristas : %i", SRVTAG , ct_win, tt_win )
		client_print(0,print_chat,"%s  Resultado : FINAL GLOBAL CTs: %i - Terroristas : %i", SRVTAG, ct_win + totalCT, tt_win + totalTT )

		FraFinal = El_mas_Frager();
		MasFraguer2 = get_user_frags(FraFinal)		

		set_task(11.0, "mas_fraguero1")
		set_task(11.0, "mas_fraguero2")
		set_task(7.0, "hud_final")

		globalCT = totalCT + ct_win
		globalTT = totalTT + tt_win
		
		end = false
		pasarse = false

		}
	}
}

public cmdVale(id, level, cid) {

	if( !cmd_access( id, level, cid, 0 ) )

        return PLUGIN_HANDLED;

	pasarse = true
	remove_task(TASK_LISTA)
	remove_task(TASK_CHE)
	set_pcvar_num (g_READY, 0)
	EstoyReady[id] = false
	ReadyCont = 0
	
	new pass[32]
	get_cvar_string("sv_password",pass,sizeof(pass) - 1)

   	if(equal(pass,"")) {
		
         server_cmd("sv_password %s", pwDEF)
}
	if(!mitad) {	

		tt_win = 0
		ct_win = 0
		total = 0
		totalCT = 0
		totalTT = 0
		end = false
				    
		set_task(0.1, "print", TASK_PRINT)
	}

	else if (mitad) {
		
		tt_win = 0
		ct_win = 0
		ready2 = false
		set_task(0.1, "print", TASK_PRINT)   
	}
	return PLUGIN_HANDLED
}

public cmdNuevo (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	tt_win = 0
	ct_win = 0
	total = 0
	totalCT = 0
	totalTT = 0
	globalCT = 0
	globalTT = 0
	end = false
	mitad = false
	EstoyReady[id] = false
	ReadyCont = 0
	set_pcvar_num (g_READY, 0)
	
    	set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 6.0, 5.0)
        show_hudmessage(0, "NUEVO CERRADO")

	server_cmd("sv_restart 2")

	return PLUGIN_HANDLED;
}

public cmdCerrado (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	server_cmd("amx_cfg cerrado.cfg")

	return PLUGIN_HANDLED;
}

public cmdPractica (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	server_cmd("amx_cfg practica.cfg")

	return PLUGIN_HANDLED;
}

public cmdPoss (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	server_cmd("amx_cfg poss.cfg")

	return PLUGIN_HANDLED;
}

public cmdPublico (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	server_cmd("amx_cfg publico.cfg")

	return PLUGIN_HANDLED;
}

public cmdRR (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	server_cmd("sv_restart 1")

	return PLUGIN_HANDLED;
}

public cmdNopass (id, level, cid){

	if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

	set_cvar_string("sv_password", "")

	return PLUGIN_HANDLED;
}

public CheckSlots (id){
	
	new Players = get_playersnum(1)
	if(Players <= 4){
		
	tt_win = 0
	ct_win = 0
	total = 0
	totalCT = 0
	totalTT = 0
	globalCT = 0
	globalTT = 0
	end = false
	mitad = false
	EstoyReady[id] = false
	ReadyCont = 0
	set_pcvar_num (g_READY, 0)

	client_print(0,print_chat,"%s  Resultado :  Se han renovado los datos",SRVTAG)
	}
}

public menu_ready(id) {

	if (!ready) 
	
	return PLUGIN_HANDLED;

	new menu = menu_create("\rListo Para Jugar?", "abre_menu")

	menu_additem(menu, "\wSi Estoy Listo", "1", 0)
	menu_additem(menu, "\wNo Estoy Listo", "2", 0)
    
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)

	return PLUGIN_HANDLED;
}

 public abre_menu(id, menu, item)  {

    if (item == MENU_EXIT) {

        menu_destroy(menu)
        return PLUGIN_HANDLED
}
    new data[6], iName[64]
    new access, callback
    menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

    new key = str_to_num(data)
    switch(key)
    {
        case 1:{
            	
		if(!EstoyReady[id]) {
		EstoyReady[id] = true;
		ReadyCont++;
		}
        }
        case 2:{
            	
		if(EstoyReady[id]) {
		EstoyReady[id] = false;
		ReadyCont--;
		}
        }
    }
    menu_destroy(menu)
    return PLUGIN_HANDLED
 }

El_mas_Frager() {

  	static players[32];
  	new num, i, id;
  	get_players(players, num);

  	new acumfrag;

  	for(i = 0; i < num; i++)
  	{
   		id = players[i];

    		if(!acumfrag) acumfrag = players[0];

   		if(get_user_frags(id) > get_user_frags(acumfrag))
     		
		acumfrag = id;
	}
	return acumfrag;
}

public print(){

    set_task (1.0,"cinco")
    set_task (2.0,"cuatro")
    set_task (3.0,"tres")
    set_task (4.0,"dos")
    set_task (5.0,"uno")
    set_task (6.0,"valeria")

    set_task(7.0, "RR1")
    set_task(9.0, "RR2")
    set_task(11.0, "RR3")
    set_task(13.0, "RR5")
    
    remove_task(TASK_PRINT)
    set_task(19.0, "msg", TASK_MSG)
}

public say_resultado(){
	
	if PlugActivo {

	if(!mitad){

	client_print(0,print_chat,"%s  Resultado : CTs: %i - Terroristas : %i", SRVTAG, ct_win, tt_win )
	}
	else if (mitad) {
	client_print(0,print_chat,"%s  Resultado : CTs: %i - Terroristas : %i", SRVTAG, ct_win + totalCT, tt_win + totalTT )
	
		}
	}
}

public sayPass(){

   new said[192]
   read_args(said,191)
   
   new pass[32]
   get_cvar_string("sv_password",pass,sizeof(pass) - 1)
	
   if(containi(said,"pass") != -1){
		
   client_print(0, print_chat, "%s  La pass es : %s", SRVTAG, pass)
   
	}
}

public nosay(id){
	
   if(!get_pcvar_num(g_SAY))
   return PLUGIN_CONTINUE
 
   if(get_user_flags(id) & ADMIN_CFG)
   return PLUGIN_CONTINUE
   
   new said[192]
   read_args(said,191)
	
   new name[32]
   get_user_name(id, name, 31)
   if(containi(said,"pausa") != -1){		
   client_print(0, print_chat, "El Jugador %s esta pidiendo pausar el juego", name)
   client_print(0, print_chat, "El Jugador %s esta pidiendo pausar el juego", name)
   return PLUGIN_HANDLED
}
	
   client_print(id, print_chat, "%s CHAT Blockeado. Solo puedes escribir PAUSA, para pedir pausear el juego",SRVTAG);
   return PLUGIN_HANDLED

} 

public cmdCambioTeam(id){

	if (!get_pcvar_num(g_RESULTADO)) {

	pasarse = false
	}

	if (!pasarse)  
	return PLUGIN_CONTINUE;

	if (cs_get_user_team(id) == CS_TEAM_SPECTATOR)
	return PLUGIN_HANDLED;

	client_print(id, print_chat, "%s No podes cambiar de team en este momento.",SRVTAG);
	return PLUGIN_HANDLED;
}

public cambio_teams(){
	
	new players[32], num
	get_players(players, num)
	
	new player
	for(new i = 0; i < num; i++)
	{
		player = players[i]
		
		if(cs_get_user_team(player) == CS_TEAM_T)
		{
			cs_set_user_team(player, CS_TEAM_CT, CS_CT_SAS);
		}
		else if(cs_get_user_team(player) == CS_TEAM_CT)
		{
			cs_set_user_team(player, CS_TEAM_T, CS_T_LEET);
		}
	}
	remove_task(TASK_CAMBIO)
}

public ActualizaLista()
{
    if(!get_pcvar_num(g_RESULTADO))
	return;
        
    new MsgText[96];
    
    for(new i = 1; i <= 32; i++)
    {
        if(is_user_connected(i) && EstoyReady[i])
        {
            
	new PlayerName[32];
	get_user_name(i, PlayerName, sizeof(PlayerName) - 1)
	
	set_hudmessage(200, 100, 0, 0.020000,0.250000, 0, 0.0, 1.1, 0.0, 0.0, -1)
	show_hudmessage(0, "Players Ready %i de %i:", ReadyCont , TodosLosPlayers())

	format(MsgText, 95, "%s^n%s", MsgText, PlayerName)
        }
    }
    
    set_hudmessage(255, 255, 255, 0.020000,0.250000, 0, 0.0, 1.1, 0.0, 0.0, -1)

    if(ReadyCont > 0)
        show_hudmessage(0, MsgText)
        
    else
	show_hudmessage(0, "Nadie esta ready^nsay /ready")
}

public CheckLista(id)
{
    if(!get_pcvar_num(g_RESULTADO))
        return;
        
    if(ReadyCont != 0 && ReadyCont == TodosLosPlayers() && !BorraLista)
    {
        remove_task(TASK_LISTA)
        
        BorraLista = true;
        set_task (0.1, "cmdVale")
    }
    
    if(BorraLista && ReadyCont != TodosLosPlayers())
    {
        BorraLista = false;
        set_task(1.0, "ActualizaLista", TASK_LISTA, _, _, "b");
    }
}

TodosLosPlayers() {

    new Players;
    
    for(new i = 1; i <= 32; i++)
    {
        if(is_user_connected(i))
            Players++;
    }
    
    return Players;
}  

public RR1()
{
    HudGris
    show_hudmessage(0, "( Primer RR )")
    server_cmd("sv_restart 1")
}

public RR2()
{
    HudGris
    show_hudmessage(0, "( Segundo RR )")
    server_cmd("sv_restart 1")
}

public RR3()
{
    HudGris
    show_hudmessage(0, "( Tercer RR )")
    server_cmd("sv_restart 1")
}
 
public RR5()
{
    HudGris
    show_hudmessage(0, "( Ultimo RR )")
    server_cmd("sv_restart 5")
}

public cinco() {
	
	set_hudmessage(200, 100, 0, -1.0, -1.0, 0, 0.0, 2.0, 0.0, 0.0, 3)
	show_hudmessage(0, "Todos estan listos^n Comienza el CERRADO!^n [ 5 ]")
}

public cuatro() {

	set_hudmessage(200, 100, 0, -1.0, -1.0, 0, 0.0, 2.0, 0.0, 0.0, 3)
	show_hudmessage(0, "Todos estan listos^n Comienza el CERRADO!^n [ 4 ]")
	
	new pass[32]
	get_cvar_string("sv_password",pass,sizeof(pass) - 1)

	client_print(0, print_chat, "%s  AMX OFF - Password: %s", SRVTAG, pass)
	client_print(0, print_chat, "%s  AMX OFF - Password: %s", SRVTAG, pass)
	client_print(0, print_chat, "%s  AMX OFF - Password: %s", SRVTAG ,pass)
}

public tres() {

	set_hudmessage(200, 100, 0, -1.0, -1.0, 0, 0.0, 2.0, 0.0, 0.0, 3)
	show_hudmessage(0, "Todos estan listos^n Comienza el CERRADO!^n [ 3 ]")
}

public dos() {
	
	set_hudmessage(200, 100, 0, -1.0, -1.0, 0, 0.0, 2.0, 0.0, 0.0, 3)
	show_hudmessage(0, "Todos estan listos^n Comienza el CERRADO!^n [ 2 ]")
}

public uno() {

	set_hudmessage(200, 100, 0, -1.0, -1.0, 0, 0.0, 2.0, 0.0, 0.0, 3)
	show_hudmessage(0, "Todos estan listos^n Comienza el CERRADO!^n [ 1 ]")
}

public valeria() {

	set_hudmessage(200, 100, 0, -1.0, -1.0, 0, 0.0, 2.0, 0.0, 0.0, 3)
	show_hudmessage(0, "Todos estan listos^n Comienza el CERRADO!^n [ GO ]")
}

public mitadmsg(){

	HudNaR
        show_hudmessage(0, "CAMBIO DE LADO - PRIMER LADO ^nCTs: %i - Terroristas : %i", globalTT, globalCT )
}

public mas_fraguero1() {

	new name[32]
	get_user_name(FraMitad, name, sizeof(name) - 1)

	set_hudmessage(64, 64, 64, -1.0, 0.21, 2, 0.02, 16.00, 0.01, 0.1, -1)
        show_hudmessage(0, "Mas Fraguer primera Mitad ^n%s con %i frags", name, MasFraguer1 )
	client_print(0,print_chat,"%s  Resultado : El player que mas Frags logro en la primera Mitad fue %s con %i frags", SRVTAG, name, MasFraguer1 )
}  

public mas_fraguero2() {

	new name[32]
	get_user_name(FraFinal, name, sizeof(name) - 1)
	
	set_hudmessage(64, 64, 64, -1.0, 0.29, 2, 0.02, 16.00, 0.01, 0.1, -1)
        show_hudmessage(0, "Mas Fraguer segunda Mitad ^n%s con %i frags", name, MasFraguer2 )
	client_print(0,print_chat,"%s  Resultado : El player que mas Frags logro en la Segunda Mitad fue %s con %i frags", SRVTAG, name, MasFraguer2 )
}

public mensaje() {
 
	client_print(0, print_chat, "%s say /ready para informar si estas listo o no.", SRVTAG)

	remove_task(TASK_MENSAJE)
}  

public hud_final(){

	HudNaR
	show_hudmessage(0, "GAME OVER ^nCTs: %i - Terroristas : %i", globalCT, globalTT )
}

public msg(){

	if(!mitad){
	
	new pass[32]
	get_cvar_string("sv_password",pass,sizeof(pass) - 1)	

	HudGris
        show_hudmessage(0, "Comienza el Cerrado [Primera Parte] ^nGL & HF ^nPassword : %s", pass)
	}

	else if (mitad) {

	new pass[32]
	get_cvar_string("sv_password",pass,sizeof(pass) - 1)		

	HudGris
        show_hudmessage(0, "Comienza el Cerrado [Segunda Parte] ^nCT : %i     TT : %i ^nPassword : %s", ct_win + totalCT, tt_win + totalTT, pass )
	}

	client_print(0, print_chat, "%s  VALE GL & HF",SRVTAG)
        client_print(0, print_chat, "%s  NO SAY & NO QUIT",SRVTAG)
	client_print(0, print_chat, "%s  VALE  VALE  VALE",SRVTAG)

	remove_task(TASK_MSG)
        set_task(3.0, "off")
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/
