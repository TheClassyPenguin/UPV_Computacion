debug(3).

// Name of the manager
manager("Manager").

// Team of troop.
team("ALLIED").
// Type of troop.
type("CLASS_MEDIC").




{ include("jgomas.asl") }




// Plans


/*******************************
*
* Actions definitions
*
*******************************/

/////////////////////////////////
//  GET AGENT TO AIM 
/////////////////////////////////  
/**
 * Calculates if there is an enemy at sight.
 *
 * This plan scans the list <tt> m_FOVObjects</tt> (objects in the Field
 * Of View of the agent) looking for an enemy. If an enemy agent is found, a
 * value of aimed("true") is returned. Note that there is no criterion (proximity, etc.) for the
 * enemy found. Otherwise, the return value is aimed("false")
 *
 * <em> It's very useful to overload this plan. </em>
 * 
 */
+!get_agent_to_aim
<-  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
?fovObjects(FOVObjects);
.length(FOVObjects, Length);

?debug(Mode); if (Mode<=1) { .println("El numero de objetos es:", Length); }

if (Length > 0) {
    +bucle(0);
    +comprobarAliado(0);
    
    -+aimed("false");
    
    while (aimed("false") & bucle(X) & (X < Length)) {
        
        //.println("En el bucle, y X vale:", X);
        
        .nth(X, FOVObjects, Object);
        // Object structure
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        .nth(2, Object, Type);
        
        ?debug(Mode); if (Mode<=2) { .println("Objeto Analizado: ", Object); }
        
        if (Type > 1000) {
            ?debug(Mode); if (Mode<=2) { .println("I found some object."); }
        } else {
            // Object may be an enemy
            .nth(1, Object, Team);
            ?my_formattedTeam(MyTeam);
            
            if (Team == 200) {  // Only if I'm ALLIED
				
                ?debug(Mode); if (Mode<=2) { .println("Aiming an enemy. . .", MyTeam, " ", .number(MyTeam) , " ", Team, " ", .number(Team)); }
                +aimed_agent(Object);
                -+aimed("true");
				+comprobarAliado(0);

                while (aimed("true") & comprobarAliado(Z) & (Z<Length)) {
                   
					.nth(X2, FOVObjects, Object2);
					.nth(2, Object2, Type2);
					.nth(1, Object2, Team2);
					if (Type2>1000 & Team2==100){
			   			?my_position(MyPosX, _, MyPosZ);
						.nth(6,Object,EnemyPos);
						.nth(0,EnemyPos,EnemyPosX);
						.nth(2,EnemyPos,EnemyPosZ);
						.nth(6,Object2,SomeonePos);
						.nth(0,SomeonePos,SomeonePosX);
						.nth(2,EnemyPos,SomeonePosZ);
						//check if pos of this ally is in line with you an the aimed objective
						// is in line if distanceMeAimed>=distanceMeAlly+distanceAllyEnemy
						if( ((EnemyPosX-MyPosX)**2+(EnemyPosY-MyPosY)**2)**0.5+5>=((SomeonePosX-MyPosX)**2+(SomeonePosY-MyPosY)**2)**0.5 +((SomeonePosX-EnemyPosX)**2+(SomeonePosY-EnemyPosY)**2)**0.5 ){
							-aimed_agent(Object);
							-+aimed("false");
						}
					}
					-+comprobarAliado(Z+1);
                }
				-comprobarAliado(_);
            }
            
        }
        
        -+bucle(X+1);
        
    }
    
   
}

-bucle(_).

/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ///?debug(Mode); if (Mode<=1) { .println("HAY ", Length, " OBJETOS A MI ALREDEDOR:\n", FOVObjects); }
        };    
        -look_response(_)[source(M)];
        -+fovObjects(FOVObjects);
        //.//;
        !look.
      
        
/////////////////////////////////
//  PERFORM ACTIONS
/////////////////////////////////
/**
* Action to do when agent has an enemy at sight.
* 
* This plan is called when agent has looked and has found an enemy,
* calculating (in agreement to the enemy position) the new direction where
* is aiming.
*
*  It's very useful to overload this plan.
* 
*/
+!perform_aim_action
    <-  // Aimed agents have the following format:
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        ?aimed_agent(AimedAgent);
        ?debug(Mode); if (Mode<=1) { .println("AimedAgent ", AimedAgent); }
        .nth(1, AimedAgent, AimedAgentTeam);
        ?debug(Mode); if (Mode<=2) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam);             }
        ?my_formattedTeam(MyTeam);


        if (AimedAgentTeam == 200) {
    
                .nth(6, AimedAgent, NewDestination);
                ?debug(Mode); if (Mode<=1) { .println("NUEVO DESTINO DEBERIA SER: ", NewDestination); }
          
            }
 .


/////////////////////////////////
//  SETUP PRIORITIES
/////////////////////////////////
/**  You can change initial priorities if you want to change the behaviour of each agent  **/+!setup_priorities
    <-  +task_priority("TASK_NONE",0);
        +task_priority("TASK_GIVE_MEDICPAKS", 2000);
        +task_priority("TASK_GIVE_AMMOPAKS", 0);
        +task_priority("TASK_GIVE_BACKUP", 0);
        +task_priority("TASK_GET_OBJECTIVE",1000);
        +task_priority("TASK_ATTACK", 1000);
        +task_priority("TASK_RUN_AWAY", 1500);
        +task_priority("TASK_GOTO_POSITION", 750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 1750).   



/////////////////////////////////
//  UPDATE TARGETS
/////////////////////////////////
/**
 * Action to do when an agent is thinking about what to do.
 *
 * This plan is called at the beginning of the state "standing"
 * The user can add or eliminate targets adding or removing tasks or changing priorities
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!update_targets
	<-	?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR UPDATE_TARGETS GOES HERE.") }

		?objectivePackTaken(Flag);
		?objective(ObjectiveX,_,ObjectiveY);
		.my_team("comandante", C);
		.my_name(N);
		//Si es el comandante da la orden de atacar
		if(N==C){
		!al_ataque(ObjectiveX,0,ObjectiveY,"ALLIED");
		}
		

		
		//Comprueba si tiene la bandera
		if(Flag==on){
			.my_team("ALLIED", T1);
			?base_position(X,Y,Z);
			//Reagrupamiento
			.concat("retirada(",ObjectiveX,",",0,",",ObjectiveZ,",",X,",",0,",",Z,")",VamosAMachacarlos);
			.send_msg_with_conversation_id(T1,tell,VamosAMachacarlos,"INT");

			//Curación
			.concat("soltar_medicinas(true)",Heal);
			.send_msg_with_conversation_id(T1, tell, Heal, "INT");
			
		
		}
	.
	
//Solo el comandante
+!a_formar(Batallon) 
	<- 
	?my_position(X,Y,Z);
	.my_team(Batallon, Unidades);
	.nth(0,Unidades,Tropa1);
	.nth(1,Unidades,Tropa2);
	.nth(2,Unidades,Tropa3);
	.nth(3,Unidades,Tropa4);
	.nth(4,Unidades,Tropa5);
	.nth(5,Unidades,Tropa6);
	.nth(6,Unidades,Tropa7);
	.concat("en_posicion(",X+5,",",Y,",",Z-5,")",FrenteIzq);
	.concat("en_posicion(",X+5,",",Y,",",Z,")",Frente);
	.concat("en_posicion(",X+5,",",Y,",",Z+5,")",FrenteDer);
	.concat("en_posicion(",X,",",Y,",",Z-10,")",AlaIzq);
	.concat("en_posicion(",X,",",Y,",",Z+10,")",AlaDer);
	.concat("en_posicion(",X-5,",",Y,",",Z-5,")",RetaIzq);
	.concat("en_posicion(",X-5,",",Y,",",Z+5,")",RetaDer);
	.send_msg_with_conversation_id(Tropa1,tell,FrenteIzq,"INT");
	.send_msg_with_conversation_id(Tropa2,tell,Frente2,"INT");
	.send_msg_with_conversation_id(Tropa3,tell,FrenteDer,"INT");
	.send_msg_with_conversation_id(Tropa4,tell,AlaIzq,"INT");
	.send_msg_with_conversation_id(Tropa5,tell,AlaDer,"INT");
	.send_msg_with_conversation_id(Tropa6,tell,RetaIzq,"INT");
	.send_msg_with_conversation_id(Tropa7,tell,RetaDer,"INT");
	.
	
+!al_ataque(X,Y,Z,Batallon) 
	<-	.my_team(Batallon, Unidades);
		.nth(0,Unidades,Tropa1);
		.nth(1,Unidades,Tropa2);
		.nth(2,Unidades,Tropa3);
		.nth(3,Unidades,Tropa4);
		.nth(4,Unidades,Tropa5);
		.nth(5,Unidades,Tropa6);
		.nth(6,Unidades,Tropa7);
		.concat("en_posicion(",X+5,",",Y,",",Z-5,")",FrenteIzq);
		.concat("en_posicion(",X+5,",",Y,",",Z,")",Frente);
		.concat("en_posicion(",X+5,",",Y,",",Z+5,")",FrenteDer);
		.concat("en_posicion(",X,",",Y,",",Z-10,")",AlaIzq);
		.concat("en_posicion(",X,",",Y,",",Z+10,")",AlaDer);
		.concat("en_posicion(",X-5,",",Y,",",Z-5,")",RetaIzq);
		.concat("en_posicion(",X-5,",",Y,",",Z+5,")",RetaDer);
		.send_msg_with_conversation_id(Tropa1,tell,FrenteIzq,"INT");
		.send_msg_with_conversation_id(Tropa2,tell,Frente2,"INT");
		.send_msg_with_conversation_id(Tropa3,tell,FrenteDer,"INT");
		.send_msg_with_conversation_id(Tropa4,tell,AlaIzq,"INT");
		.send_msg_with_conversation_id(Tropa5,tell,AlaDer,"INT");
		.send_msg_with_conversation_id(Tropa6,tell,RetaIzq,"INT");
		.send_msg_with_conversation_id(Tropa7,tell,RetaDer,"INT");
		.my_name(N);
		!add_task(task(3000,"TASK_GOTO_POSITION_2",N,pos(X,Y,Z),""))
	.
+en_posicion(X,Y,Z)[source(A)] 
	<-	-en_posicion(_,_,_);
    	!add_task(task(5500,"TASK_GOTO_POSITION_1",A,pos(X,Y,Z),""));
		-+state(standing)
	.
	
+retirada(X,Y,Z,X1,Y1,Z1)[source(A)]
	<-	.println("Volvemos a la base")
		-+tasks([]);
		-+state(standing);
		!add_task(task(5000,"TASK_GOTO_POSITION",A,pos(X1,Y1,Z1),""));
		-+state(standing);
		
	.
	
/////////////////////////////////
//  Initialize variables
/////////////////////////////////

+!init
   <-  	?debug(Mode); if (Mode<=1) { .println("Codigo de inicializacion")};
   		?my_position(X,Y,Z);
		+base_positon(X,Y,Z);
		-+objectivePackTaken(off);
		.my_name(N);
		if(N==A1){
			.register("JGOMAS","comandante_ALLIED");
		}
		
		.my_team("comandante_ALLIED", C);
		if(N==C){
			!a_formar("ALLIED");
		}
		-+tasks([]);
	.
		
