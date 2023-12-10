STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	WINDOW_WIDTH DW 140h                 ;el ancho de la ventana (320 pixels)
	WINDOW_HEIGHT DW 0C8h                ;el alto de la ventana (200 pixels)
	WINDOW_BOUNDS DW 6                   ;variable usado para comprobar colisiones tempranas
	
	TIME_AUX DB 0                        ;variable usada para comprobar si el tiempo ha cambiado
	GAME_ACTIVE DB 1                     ;el juego esta activo? (1 -> si, 0 -> No (game over))
	EXITING_GAME DB 0
	WINNER_INDEX DB 0                    ;el indice del ganador (1 -> jugador 1, 2 -> jugador)
	CURRENT_SCENE DB 0                   ;indice de la escena actual (0 -> menu principal, 1 -> juego)
	
	TEXT_PLAYER_ONE_POINTS DB '0','$'    ;texto para los puntos del jugador 1
	TEXT_PLAYER_TWO_POINTS DB '0','$'    ;texto para los puntos del jugador 2
	TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' ;Texto con el título del menú Game Over.
	TEXT_GAME_OVER_WINNER DB 'Jugador 0 ganaste','$' ;texto con el ganador
	TEXT_GAME_OVER_PLAY_AGAIN DB 'Presiona R para reanudar','$' ;texto con el mensaje de jugar de nuevo
	TEXT_GAME_OVER_MAIN_MENU DB 'Presiona E para salir','$' ;texto con el mensaje del menu de game over
	TEXT_MAIN_MENU_TITLE DB 'BIENVENIDO','$' ;text with the main menu title
	TEXT_MAIN_MENU_US DB 'Guadalupe - Carlos','$' ; texto de los estudiantes
	TEXT_MAIN_MENU_MULTIPLAYER DB 'Empieza - S','$' ;texto de empezar juego
	TEXT_MAIN_MENU_EXIT DB 'Salir - E','$' ;texto con el mensaje de salir del juego
	
	BALL_ORIGINAL_X DW 0A0h              ;posicion X al inicio del juego
	BALL_ORIGINAL_Y DW 64h               ;posicion Y al inicio del juego
	BALL_X DW 0A0h                       ;Posicion actual X (columna) de la bola
	BALL_Y DW 64h                        ;Posicion actual Y (fila) de la bola
	BALL_SIZE DW 06h                     ;tamaño de la bola (cuantos pixeles tiene de ancho y alto)
	BALL_VELOCITY_X DW 05h               ;Velocidad X (horizontal)de la bola
	BALL_VELOCITY_Y DW 02h               ;Velocidad Y (vertical)de la bola
	
	PADDLE_LEFT_X DW 0Ah                 ;posicion actual X de la raqueta izquierda
	PADDLE_LEFT_Y DW 55h                 ;posicion actual Y de la raqueta izquierda
	PLAYER_ONE_POINTS DB 0               ;puntos actuales del juegador de la izquierda (jugador 1)
	
	PADDLE_RIGHT_X DW 130h               ;posicion actual X de la raqueta derecha
	PADDLE_RIGHT_Y DW 55h                ;posicion actual Y de la raqueta derecha
	PLAYER_TWO_POINTS DB 0             ;puntos actuales del juegador de la derecha (jugador 2)
	
	PADDLE_WIDTH DW 06h                  ;ancho de la raqueta predeterminado
	PADDLE_HEIGHT DW 25h                 ;alto de la raqueta predeterminado
	PADDLE_VELOCITY DW 0Fh               ;velocidad de la raqueta predeterminada

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK      ;asocia data, code y stack a sus registros ds,cs y ss, respectivamente
	PUSH DS                              ;Le hace push al ds en la pila
	SUB AX,AX                            ;limpia el registro AX
	PUSH AX                              ;le hace push al AX en la pila
	MOV AX,DATA                          ;guarda en el AX la data
	MOV DS,AX                            ;guarda ds lo que esta en AX
	POP AX                               ;se le hace pop a la pila para guardarlo en AX
	POP AX                               ;se le hace pop a la pila para guardarlo en AX
		
		CALL CLEAR_SCREEN                ;pone las configuraciones iniciales del modo video
		
		CHECK_TIME:                      ;loop para comprobar el tiempo
			
			CMP EXITING_GAME,01h
			JE START_EXIT_PROCESS
			
			CMP CURRENT_SCENE,00h
			JE SHOW_MAIN_MENU
			
			CMP GAME_ACTIVE,00h
			JE SHOW_GAME_OVER
			
			MOV AH,2Ch 					 ;obtiene la hora del sistema
			INT 21h    					 ;CH = hora CL = minuto DH = segundo DL = 1/100 segundo
			
			CMP DL,TIME_AUX  			 ;la hora actual es igual a la anterior(TIME_AUX)?
			JE CHECK_TIME    		     ;si es la misma, comprobar de nuevo
			
;           si alcanza este punto es porque el tiempo ha pasado
  
			MOV TIME_AUX,DL              ;actualizar el tiempo
			
			CALL CLEAR_SCREEN            ;limpiar la pantalla reiniciando el modo de video
			
			CALL MOVE_BALL               ;mover la bola
			CALL DRAW_BALL               ;dibujar la bola
			
			CALL MOVE_PADDLES            ;mover las raquetas (comprobar si se presionan teclas)
			CALL DRAW_PADDLES            ;dibujar las dos raquetas con las posiciones actualizadas
			
			CALL DRAW_UI                 ;dibuja la interfaz de usuario
			
			JMP CHECK_TIME               ;Despues de todo comprobar el tiempo de nuevo
			
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU
				JMP CHECK_TIME
				
			SHOW_MAIN_MENU:
				CALL DRAW_MAIN_MENU
				JMP CHECK_TIME
				
			START_EXIT_PROCESS:
				CALL CONCLUDE_EXIT_GAME
				
		RET		
	MAIN ENDP
	
	MOVE_BALL PROC NEAR                  ;procedimiento para controlar el movimiento de la bola
		
;       mueve la bola horizontalmente
		MOV AX,BALL_VELOCITY_X    
		ADD BALL_X,AX                   
		
;       comprueba si la bola ha pasado el limite izquierdo (BALL_X < 0 + WINDOW_BOUNDS)
;       Si esta colisionando reinicia su posicion		
		MOV AX,WINDOW_BOUNDS
		CMP BALL_X,AX                    ;BALL_X esta siendo comparada con el limite izquierdo de la pantalla (0 + WINDOW_BOUNDS)          
		JL GIVE_POINT_TO_PLAYER_TWO      ;si es menor, darle un punto al jugador 2 y reiniciar la posicion de la bola
		
;       comprueba si la bola ha pasado el limite derecho (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)
;       Si esta colisionando reinicia su posicion		
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX	                ;BALL_X esta siendo comparada con el limite derecho de la pantalla (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)  
		JG GIVE_POINT_TO_PLAYER_ONE     ;si es mayor, darle un punto al jugador 1 y reiniciar la posicion de la bola
		JMP MOVE_BALL_VERTICALLY
		
		GIVE_POINT_TO_PLAYER_ONE:		 ;Darle un punto al jugador 1 y reiniciar la posicion de la bola
			INC PLAYER_ONE_POINTS       ;incrementar los puntos del jugador 1
			CALL RESET_BALL_POSITION     ;reiniciar la posicion de la bola al centro de la pantalla
			
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS ;actualizar el texto de los puntos del jugador 1
			
			CMP PLAYER_ONE_POINTS,05h   ;comprueba si el jugador 1 ha alcanzado 5 puntos
			JGE GAME_OVER                ;si el jugador tiene 5 o mas, el juego se acaba
			RET
		
		GIVE_POINT_TO_PLAYER_TWO:        ;Darle un punto al jugador 2 y reiniciar la posicion de la bola
			INC PLAYER_TWO_POINTS      ;incrementar los puntos del jugador  2
			CALL RESET_BALL_POSITION     ;reiniciar la posicion de la bola al centro de la pantalla
			
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS ;actualizar el texto de los puntos del jugador 1
			
			CMP PLAYER_TWO_POINTS,05h  ;comprueba si el jugador 2 ha alcanzado 5 puntos
			JGE GAME_OVER                ;si el jugador tiene 5 o mas, el juego se acaba
			RET
			
		GAME_OVER:                       ;alguien ha alcanzado 5 puntos
			CMP PLAYER_ONE_POINTS,05h    ;Comprueba si el jugador uno tiene 5 o mas puntos
			JNL WINNER_IS_PLAYER_ONE     ;Si el jugador 1 no tiene menos de 5 puntos es el ganador
			JMP WINNER_IS_PLAYER_TWO     ;Si no, el jugador 2 es el ganador
			
			WINNER_IS_PLAYER_ONE:
				MOV WINNER_INDEX,01h     ;Actualiza el indice del ganador con el indice del jugador 1
				JMP CONTINUE_GAME_OVER
			WINNER_IS_PLAYER_TWO:
				MOV WINNER_INDEX,02h     ;Actualiza el indice del ganador con el indice del jugador 2
				JMP CONTINUE_GAME_OVER
				
			CONTINUE_GAME_OVER:
				MOV PLAYER_ONE_POINTS,00h   ;reinicia los puntos del jugador 1
				MOV PLAYER_TWO_POINTS,00h  ;reinicia los puntos del jugador 2
				CALL UPDATE_TEXT_PLAYER_ONE_POINTS
				CALL UPDATE_TEXT_PLAYER_TWO_POINTS
				MOV GAME_ACTIVE,00h            ;Detiene el juego
				RET	

;       Mueve la bola verticalmente		
		MOVE_BALL_VERTICALLY:		
			MOV AX,BALL_VELOCITY_Y
			ADD BALL_Y,AX             
		
;       comprueba si la bola ha pasado el limite superior (BALL_Y < 0 + WINDOW_BOUNDS)
;       si esta chochando, revertir la velocidad
		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                    ;BALL_Y esta siendo comparada con el limite superior de la pantalla (0 + WINDOW_BOUNDS)
		JL NEG_VELOCITY_Y                ;Si es menor revertir la velocidad en Y

;       comprueba si la bola ha pasado el limite inferior (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
;       si esta chochando, revertir la velocidad		
		MOV AX,WINDOW_HEIGHT	
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                    ;BALL_Yesta siendo comparada con el limite inferior de la pantalla (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
		JG NEG_VELOCITY_Y		         ;Si es mayor revertir la velocidad en Y
		
;       Comprobar si la bola esta chocando con la raqueta derecha 
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE  ;Si no hay colision revisa con la raqueta izquierda
		
		MOV AX,PADDLE_RIGHT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE  ;Si no hay colision revisa con la raqueta izquierda
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE  ;Si no hay colision revisa con la raqueta izquierda
		
		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE  ;Si no hay colision revisa con la raqueta izquierda
		
;       si alcanza este punto, la bola esta chocando con la raqueta derecha

		JMP NEG_VELOCITY_X

;       Comprobar si la bola esta chocando con la raqueta derecha 
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_X
		JNG EXIT_COLLISION_CHECK  ;Si no esta chocando salir del procedimiento
		
		MOV AX,PADDLE_LEFT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL EXIT_COLLISION_CHECK  ;Si no esta chocando salir del procedimiento
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_Y
		JNG EXIT_COLLISION_CHECK  ;Si no esta chocando salir del procedimiento
		
		MOV AX,PADDLE_LEFT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL EXIT_COLLISION_CHECK  ;Si no esta chocando salir del procedimiento
		
;      Si alcanza este punto, la bola esta chocando con la raqueta izquierda

		JMP NEG_VELOCITY_X
		
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y   ;revertir la velocidad en Y de la bola (BALL_VELOCITY_Y = - BALL_VELOCITY_Y)
			RET
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X              ;revertir la velocidad horizontal de la bola
			RET                              
			
		EXIT_COLLISION_CHECK:
			RET
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR               ;procedimiento para el movimiento de las raquetas
		
;       Movimiento de la raqueta izquierda
		
		;Comprueba si alguna tecla esta siendo presionada (si no, comprobar la otra raqueta)
		MOV AH,01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT ;ZF = 1, JZ -> Jump If Zero
		
		;comprobar cual tecla esta siendo presionada (AL = Caracter ASCII)
		MOV AH,00h
		INT 16h
		
		;si es 'w' o 'W' mover arriba
		CMP AL,77h ;'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h ;'W'
		JE MOVE_LEFT_PADDLE_UP
		
		;si es 's' o 'S' mover abajo
		CMP AL,73h ;'s'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h ;'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		
;       Movimiento de la raqueta derecha
		CHECK_RIGHT_PADDLE_MOVEMENT:
		
			;si es 'o' or 'O' mover arriba
			CMP AL,6Fh ;'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4Fh ;'O'
			JE MOVE_RIGHT_PADDLE_UP
			
			;si es 'l' or 'L' mover abajo
			CMP AL,6Ch ;'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4Ch ;'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			

			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
		
		EXIT_PADDLE_MOVEMENT:
		
			RET
		
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR        ;Reinicia la posicion de la bola
		
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		
		NEG BALL_VELOCITY_X
		NEG BALL_VELOCITY_Y
		
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_BALL PROC NEAR                  
		
		MOV CX,BALL_X                    ;ajusta la columna inicial(X)
		MOV DX,BALL_Y                    ;ajusta la fila inicial (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch                   ;ajusta la configuracion para escribir un pixel
			MOV AL,04h 					 ;Se escoge el color rojo
			MOV BH,00h 					 ;ajusta el numero de la pagina
			INT 10h    					 ;ejecuta la configuracion
			
			INC CX     					 ;CX = CX + 1
			MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> Pasa a la siguiente fila,N -> pasa a la siguiente columna
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X 				 ;El registro CX va de nuevo a la columna inicial
			INC DX       				 ;se avanza una fila
			
			MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> salimos del procedimiento,N -> continuamos a la siguiente fila
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		
		RET
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
		
		MOV CX,PADDLE_LEFT_X 			 ;ajusta la columna inicial (X)
		MOV DX,PADDLE_LEFT_Y 			 ;ajusta la fila inicial (Y)
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch 					 ;ajusta la configuracion para escribir un pixel
			MOV AL,0Fh 					 ;se escoge el color blanco
			MOV BH,00h 					 ;se elige el numero de pagina
			INT 10h    					 ;ejecuta la configuracion anterior
			
			INC CX     				 	 ;CX = CX + 1
			MOV AX,CX         			 ;CX - PADDLE_LEFT_X > PADDLE_WIDTH (Y -> Pasamos a la siguiente fila,N -> pasamos a la siguiente columna
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			MOV CX,PADDLE_LEFT_X 		 ;El registro CX va de nuevo a la columna inicial
			INC DX       				 ;se avanza una fila
			
			MOV AX,DX            	     ;DX - PADDLE_LEFT_Y > PADDLE_HEIGHT (Y -> salimos del procedimiento,N -> continuamos a la siguiente fila
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			
		MOV CX,PADDLE_RIGHT_X 			 ;ajusta la columna inicial (X)
		MOV DX,PADDLE_RIGHT_Y 			 ;ajusta la fila inicial (Y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0Ch 					 ;ajusta la configuracion para escribir un pixel
			MOV AL,0Fh 					  ;se escoge el color blanco
			MOV BH,00h 					 ;se elige el numero de pagina 
			INT 10h    					 ;ejecuta la configuracion anterior
			
			INC CX     					 ;CX = CX + 1
			MOV AX,CX         			 ;CX - PADDLE_RIGHT_X > PADDLE_WIDTH (Y -> Pasamos a la siguiente fila,N -> pasamos a la siguiente columna
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX,PADDLE_RIGHT_X		 ;El registro CX va de nuevo a la columna inicial
			INC DX       				 ;se avanza una fila
			
			MOV AX,DX            	     ;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Y -> salimos del procedimiento,N -> continuamos a la siguiente fila 
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
		RET
	DRAW_PADDLES ENDP
	
	DRAW_UI PROC NEAR
		
;       Dibuja los puntos del jugador de la izquierda (Jugador 1)
		
		MOV AH,02h                       ;Posiciona el cursor
		MOV BH,00h                       ;posiciona el numero de pagina
		MOV DH,04h                       ;seleccionar fila
		MOV DL,06h						 ;seleccionar columna
		INT 10h							 
		
		MOV AH,09h                       ;Escribir el string con la salida estandar
		LEA DX,TEXT_PLAYER_ONE_POINTS    ;darle a DX el string : TEXT_PLAYER_ONE_POINTS
		INT 21h                          ;Imprimir el string
		
;       Dibuja los puntos del jugador de la izquierda (Jugador 1)
		
		MOV AH,02h                       ;Posiciona el curso
		MOV BH,00h                       ;posiciona el numero de pagina
		MOV DH,04h                       ;seleccionar fila
		MOV DL,1Fh						 ;seleccionar columna
		INT 10h							 
		
		MOV AH,09h                       ;Escribir el string con la salida estandar
		LEA DX,TEXT_PLAYER_TWO_POINTS    ;darle a DX el string : TEXT_PLAYER_ONE_POINTS
		INT 21h                          ;Imprimir el string 
		
		RET
	DRAW_UI ENDP
	
	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
		
		XOR AX,AX
		MOV AL,PLAYER_ONE_POINTS ;por ejemplo que Jugador1 -> 2 puntos => AL,2
		
		;now, before printing to the screen, we need to convert the decimal value to the ascii code character 
		;we can do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		ADD AL,30h                       ;AL,'2'
		MOV [TEXT_PLAYER_ONE_POINTS],AL
		
		RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
	
	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
		
		XOR AX,AX
		MOV AL,PLAYER_TWO_POINTS ;given, for example that P2 -> 2 points => AL,2
		
		;ahora,antes de imprimir a la pantalla, necesitamos convertir el valor decimal al caracter ascii
		;podemos hacerlo sumando 30h (numero a ASCII)
		;y restando 30h (ASCII a numero)
		; 30h = 48d
		ADD AL,30h                       ;AL,'2'
		MOV [TEXT_PLAYER_TWO_POINTS],AL
		
		RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
	
	DRAW_GAME_OVER_MENU PROC NEAR        ;Dibuja el menu de game over
		
		CALL CLEAR_SCREEN                ;limpia la pantalla

;       Muestra el menu 
;		MOV AH,02h                       ;pone el cursor en posicion
;		MOV BH,00h                       ;selecciona el numero de pagina
;		MOV DH,04h                       ;selecciona la fila  
;		MOV DL,04h						 ;selecciona la columna
;		INT 10h							 
;		
;		MOV AH,09h                       ;Escribe el string con la salida standar
;		LEA DX,TEXT_GAME_OVER_TITLE      ;
;		INT 21h                          ;imprime el string

;       Muestra el ganador
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,06h                       ;selecciona la fila  
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 
		
		CALL UPDATE_WINNER_TEXT
		
		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_GAME_OVER_WINNER      
		INT 21h                          ;imprime el string
		
;       Muestra el mensaje de jugar de nuevo
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,08h                       ;selecciona la fila 
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 

		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_GAME_OVER_PLAY_AGAIN       
		INT 21h                          ;imprime el mensaje
		
;        Muestra el menu principal
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,0Ah                       ;selecciona la fila
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 

		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_GAME_OVER_MAIN_MENU      ;se le da a DX un apuntador
		INT 21h                          ;imprime el mensaje
		
;       esperar por el presionado de teclas
		MOV AH,00h
		INT 16h

;       si la tecla es 'R' o 'r', reinicia el juego	
		CMP AL,'R'
		JE RESTART_GAME
		CMP AL,'r'
		JE RESTART_GAME
;       si la tecla es 'E' or 'e', salir al menu principal
		CMP AL,'E'
		JE EXIT_TO_MAIN_MENU
		CMP AL,'e'
		JE EXIT_TO_MAIN_MENU
		RET
		
		RESTART_GAME:
			MOV GAME_ACTIVE,01h
			RET
		
		EXIT_TO_MAIN_MENU:
			MOV GAME_ACTIVE,00h
			MOV CURRENT_SCENE,00h
			RET
			
	DRAW_GAME_OVER_MENU ENDP
	
	DRAW_MAIN_MENU PROC NEAR
		
		CALL CLEAR_SCREEN
		
;       muestra el menu
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,04h                       ;selecciona la fila
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 
		
		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_MAIN_MENU_TITLE      ;darle a DX un apuntador 
		INT 21h                          ;Imprimir el string
		
;       Shows the ESTUDIANTES message
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,06h                       ;selecciona la fila
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 
		
		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_MAIN_MENU_US       
		INT 21h                          ;Imprimir el string
		
;       Muestra el mensaje de empezar juego
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,08h                       ;selecciona la fila
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 
		
		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_MAIN_MENU_MULTIPLAYER      ;darle a DX un apuntador
		INT 21h                          ;Imprimir el string
		
;       Muestra el mensaje de salida
		MOV AH,02h                       ;pone el cursor en posicion
		MOV BH,00h                       ;selecciona el numero de pagina
		MOV DH,0Ah                       ;selecciona la fila
		MOV DL,04h						 ;selecciona la columna
		INT 10h							 
		
		MOV AH,09h                       ;Escribe el string con la salida standar
		LEA DX,TEXT_MAIN_MENU_EXIT      ;darle a DX un apuntador 
		INT 21h                          ;Imprimir el string
		
		MAIN_MENU_WAIT_FOR_KEY:
;       Espera por  el presionado de teclas
			MOV AH,00h
			INT 16h
		
;       comprueba cual tecla fue pulsada
			CMP AL,'S'
			JE START_MULTIPLAYER
			CMP AL,'s'
			JE START_MULTIPLAYER
			CMP AL,'E'
			JE EXIT_GAME
			CMP AL,'e'
			JE EXIT_GAME
			JMP MAIN_MENU_WAIT_FOR_KEY
		
		START_MULTIPLAYER:
			MOV CURRENT_SCENE,01h
			MOV GAME_ACTIVE,01h
			RET
		
		EXIT_GAME:
			MOV EXITING_GAME,01h
			RET

	DRAW_MAIN_MENU ENDP
	
	UPDATE_WINNER_TEXT PROC NEAR
		
		MOV AL,WINNER_INDEX              ;ej: si el indice del ganador es 1 => AL,1
		ADD AL,30h                       ;AL,31h => AL,'1'
		MOV [TEXT_GAME_OVER_WINNER+8],AL ;actualiza el indice en el texto con el caracter
		
		RET
	UPDATE_WINNER_TEXT ENDP
	
	CLEAR_SCREEN PROC NEAR               ;limpia la pantalla reiniciando el modo de video
	
			MOV AH,00h                   ;colocar la configuracion en modo video
			MOV AL,13h                   ;elegir el modo de video
			INT 10h    					 ;ejecutar la configuracion
		
			MOV AH,0Bh 					 ;ajustar la configuracion
			MOV BH,00h 					 ;Al fondo
			MOV BL,00h 					 ;seleccionar el color negro
			INT 10h    					 ;ejecutar la configuracion
			
			RET
			
	CLEAR_SCREEN ENDP
	
	CONCLUDE_EXIT_GAME PROC NEAR         ;Vuelve al modo de texto
		
		MOV AH,00h                   ;colocar la configuracion en modo video
		MOV AL,02h                   ;elegir el modo de video
		INT 10h    					 ;ejecutar la configuracion
		
		MOV AH,4Ch                   ;terminar el programa
		INT 21h

	CONCLUDE_EXIT_GAME ENDP

CODE ENDS
END
