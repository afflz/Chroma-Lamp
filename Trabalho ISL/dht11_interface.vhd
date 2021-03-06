LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY DHT11_INTERFACE IS
PORT (
	BARRAMENTO : INOUT STD_LOGIC;
	CLOCK : IN STD_LOGIC;
	TEMP_I : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
	HUMI_I : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
	CONVERTENDO: OUT STD_LOGIC);
END DHT11_INTERFACE;

ARCHITECTURE BEHAVIOR OF DHT11_INTERFACE IS

-- CLOCK ADEQUADO DE 50 MhZ----------------------------------------------------
	CONSTANT CLK_RATE_1us   :INTEGER := 67;
	CONSTANT CLK_RATE_10us  :INTEGER := 10  * CLK_RATE_1us;
	CONSTANT CLK_RATE_20us  :INTEGER := 20  * CLK_RATE_1us;
	CONSTANT CLK_RATE_26us  :INTEGER := 26  * CLK_RATE_1us;
	CONSTANT CLK_RATE_28us  :INTEGER := 28  * CLK_RATE_1us;
	CONSTANT CLK_RATE_50us  :INTEGER := 50  * CLK_RATE_1us;
	CONSTANT CLK_RATE_70us  :INTEGER := 70  * CLK_RATE_1us;
	CONSTANT CLK_RATE_80us  :INTEGER := 80  * CLK_RATE_1us;
	CONSTANT CLK_RATE_100us :INTEGER := 100 * CLK_RATE_1us;
	CONSTANT CLK_RATE_1ms   :INTEGER := 1000 * CLK_RATE_1us;
	CONSTANT CLK_RATE_20ms  :INTEGER := 20000 * CLK_RATE_1us;
-- TIPO GERAL------------------------------------------------------------------
	TYPE BUS_STATE IS (RESET,SETUP,READING,READING_SETUP,ANALYSIS);
-- TIPO READING SETUP ---------------------------------------------------------	
	TYPE RS_STATE IS (LOW_READING,HIGH_READING);
-- TIPOS READING --------------------------------------------------------------	
	TYPE R_STATE IS (HOST,SLAVE);	
	TYPE BIT_POSITION IS (C1,C2,C3,C4,C5,C6,C7,C8);
	TYPE BYTE_POSITION IS (TI,TF,HI,HF,BP);
-- SINAIS GERAIS --------------------------------------------------------------
	SIGNAL COUNT : INTEGER := 0;
	SIGNAL COUNT_BIT : INTEGER := 0;
	SIGNAL STATE : BUS_STATE:= SETUP;
	SIGNAL RS : RS_STATE:= LOW_READING;
	SIGNAL LEITURA : R_STATE:= HOST;
	SIGNAL BIT_P : BIT_POSITION := C8;
	SIGNAL BYTE_P : BYTE_POSITION := HI;
---- REGISTRADORES TEMPORARIOS ------------------------------------------------
	SIGNAL TEMP_I_T : STD_LOGIC_VECTOR (8 DOWNTO 1);
	SIGNAL HUMI_I_T : STD_LOGIC_VECTOR (8 DOWNTO 1);
	SIGNAL BIT_PAR : STD_LOGIC_VECTOR (8 DOWNTO 1);
-------------------------------------------------------------------------------
BEGIN
-------------------------------------------------------------------------------------
	PROCESS (CLOCK)
	BEGIN
		 IF (RISING_EDGE(CLOCK)) THEN
			CASE STATE IS
-----------------------------------------------------------------------------------------	
				WHEN RESET =>
					IF (COUNT < CLK_RATE_1ms) THEN
						BARRAMENTO <=  '1';
						COUNT <= COUNT + 1;
					ELSIF ( COUNT >= CLK_RATE_1ms) THEN
						COUNT <= 1;
						STATE <= SETUP;
						CONVERTENDO <= '1';
					END IF;
-----------------------------------------------------------------------------------------	
				WHEN SETUP =>
					IF (COUNT < CLK_RATE_20ms) THEN
						COUNT <= COUNT + 1;
						BARRAMENTO <=  '0';
					ELSIF ( COUNT >= CLK_RATE_20ms) THEN
						COUNT <= 1;
						STATE <= READING_SETUP;
						BARRAMENTO <= 'Z';
					END IF;
-----------------------------------------------------------------------------------------		
				WHEN READING_SETUP =>
					CASE RS IS
				-------------------------------------------------		
						WHEN LOW_READING =>
							IF (BARRAMENTO = '0') THEN				
									COUNT <= COUNT + 1;
								IF (COUNT >= CLK_RATE_80us) THEN
									RS <= HIGH_READING;
									COUNT <= 0;
								END IF;
							END IF;
				-------------------------------------------------
						WHEN HIGH_READING =>
							IF (BARRAMENTO = '1') THEN	
									CONVERTENDO <= '0';			
									COUNT <= COUNT + 1;
								IF (COUNT >= CLK_RATE_80us-1) THEN
									RS <= LOW_READING;
									STATE <= READING;
									COUNT <= 0;
									LEITURA <= HOST;
									BYTE_P <= HI;
									BIT_P <= C8;
								END IF;
							END IF;
					END CASE;						
-----------------------------------------------------------------------------------------		
				WHEN READING =>
					CASE LEITURA IS
					---------------------------------------------------------------------
						WHEN HOST =>
							IF (BARRAMENTO = '1') THEN
								LEITURA <= SLAVE;
								COUNT_BIT <= 1;
							END IF;
					---------------------------------------------------------------------		
						WHEN SLAVE =>
							IF (BARRAMENTO = '1') THEN
								COUNT_BIT <= COUNT_BIT + 1;
							ELSIF (BARRAMENTO = '0') THEN
								LEITURA <= HOST;
								IF (COUNT_BIT >= CLK_RATE_26us-1 AND COUNT_BIT <= CLK_RATE_28us-1) THEN
									CASE BYTE_P IS
										WHEN HI =>
											CASE BIT_P IS
												WHEN C8 => HUMI_I_T(8) <= '0'; BIT_P <= C7;			
												WHEN C7 => HUMI_I_T(7) <= '0'; BIT_P <= C6;			
												WHEN C6 => HUMI_I_T(6) <= '0'; BIT_P <= C5;			
												WHEN C5 => HUMI_I_T(5) <= '0'; BIT_P <= C4;														
												WHEN C4 => HUMI_I_T(4) <= '0'; BIT_P <= C3;			 										
												WHEN C3 => HUMI_I_T(3) <= '0'; BIT_P <= C2;			
												WHEN C2 => HUMI_I_T(2) <= '0'; BIT_P <= C1;			
												WHEN C1 => HUMI_I_T(1) <= '0'; BIT_P <= C8; 
																			  BYTE_P <= HF;			
											END CASE;
										WHEN HF =>
											CASE BIT_P IS
												WHEN C8 => NULL; BIT_P <= C7;			
												WHEN C7 => NULL; BIT_P <= C6;			
												WHEN C6 => NULL; BIT_P <= C5;			
												WHEN C5 => NULL; BIT_P <= C4;														
												WHEN C4 => NULL; BIT_P <= C3;			 										
												WHEN C3 => NULL; BIT_P <= C2;			
												WHEN C2 => NULL; BIT_P <= C1;			
												WHEN C1 => NULL; BIT_P <= C8; 
																			  BYTE_P <= TI;			
											END CASE;
										WHEN TI =>
											CASE BIT_P IS
												WHEN C8 => TEMP_I_T(8) <= '0'; BIT_P <= C7;			
												WHEN C7 => TEMP_I_T(7) <= '0'; BIT_P <= C6;			
												WHEN C6 => TEMP_I_T(6) <= '0'; BIT_P <= C5;			
												WHEN C5 => TEMP_I_T(5) <= '0'; BIT_P <= C4;														
												WHEN C4 => TEMP_I_T(4) <= '0'; BIT_P <= C3;			 										
												WHEN C3 => TEMP_I_T(3) <= '0'; BIT_P <= C2;			
												WHEN C2 => TEMP_I_T(2) <= '0'; BIT_P <= C1;			
												WHEN C1 => TEMP_I_T(1) <= '0'; BIT_P <= C8; 
																			  BYTE_P <= TF;			
											END CASE;
										WHEN TF =>
											CASE BIT_P IS
												WHEN C8 => NULL; BIT_P <= C7;			
												WHEN C7 => NULL; BIT_P <= C6;			
												WHEN C6 => NULL; BIT_P <= C5;			
												WHEN C5 => NULL; BIT_P <= C4;														
												WHEN C4 => NULL; BIT_P <= C3;			 										
												WHEN C3 => NULL; BIT_P <= C2;			
												WHEN C2 => NULL; BIT_P <= C1;			
												WHEN C1 => NULL; BIT_P <= C8;  
																			  BYTE_P <= BP;			
											END CASE;
										WHEN BP =>
											CASE BIT_P IS
												WHEN C8 => BIT_PAR(8) <= '0'; BIT_P <= C7;			
												WHEN C7 => BIT_PAR(7) <= '0'; BIT_P <= C6;			
												WHEN C6 => BIT_PAR(6) <= '0'; BIT_P <= C5;			
												WHEN C5 => BIT_PAR(5) <= '0'; BIT_P <= C4;														
												WHEN C4 => BIT_PAR(4) <= '0'; BIT_P <= C3;			 										
												WHEN C3 => BIT_PAR(3) <= '0'; BIT_P <= C2;			
												WHEN C2 => BIT_PAR(2) <= '0'; BIT_P <= C1;			
												WHEN C1 => BIT_PAR(1) <= '0'; BIT_P <= C8; 
																			 BYTE_P <= HI;
																		STATE <= ANALYSIS; 			
											END CASE;
									END CASE;
								ELSIF (COUNT_BIT = CLK_RATE_70us) THEN
									CASE BYTE_P IS
										WHEN HI =>
											CASE BIT_P IS
												WHEN C8 => HUMI_I_T(8) <= '1'; BIT_P <= C7;			
												WHEN C7 => HUMI_I_T(7) <= '1'; BIT_P <= C6;			
												WHEN C6 => HUMI_I_T(6) <= '1'; BIT_P <= C5;			
												WHEN C5 => HUMI_I_T(5) <= '1'; BIT_P <= C4;														
												WHEN C4 => HUMI_I_T(4) <= '1'; BIT_P <= C3;			 										
												WHEN C3 => HUMI_I_T(3) <= '1'; BIT_P <= C2;			
												WHEN C2 => HUMI_I_T(2) <= '1'; BIT_P <= C1;			
												WHEN C1 => HUMI_I_T(1) <= '1'; BIT_P <= C8; 
																			  BYTE_P <= HF;			
											END CASE;
										WHEN HF =>
											CASE BIT_P IS
												WHEN C8 => NULL; BIT_P <= C7;			
												WHEN C7 => NULL; BIT_P <= C6;			
												WHEN C6 => NULL; BIT_P <= C5;			
												WHEN C5 => NULL; BIT_P <= C4;														
												WHEN C4 => NULL; BIT_P <= C3;			 										
												WHEN C3 => NULL; BIT_P <= C2;			
												WHEN C2 => NULL; BIT_P <= C1;			
												WHEN C1 => NULL; BIT_P <= C8; 
																			  BYTE_P <= TI;			
											END CASE;
										WHEN TI =>
											CASE BIT_P IS
												WHEN C8 => TEMP_I_T(8) <= '1'; BIT_P <= C7;			
												WHEN C7 => TEMP_I_T(7) <= '1'; BIT_P <= C6;			
												WHEN C6 => TEMP_I_T(6) <= '1'; BIT_P <= C5;			
												WHEN C5 => TEMP_I_T(5) <= '1'; BIT_P <= C4;														
												WHEN C4 => TEMP_I_T(4) <= '1'; BIT_P <= C3;			 										
												WHEN C3 => TEMP_I_T(3) <= '1'; BIT_P <= C2;			
												WHEN C2 => TEMP_I_T(2) <= '1'; BIT_P <= C1;			
												WHEN C1 => TEMP_I_T(1) <= '1'; BIT_P <= C8; 
																			  BYTE_P <= TF;			
											END CASE;
										WHEN TF =>
											CASE BIT_P IS
												WHEN C8 => NULL; BIT_P <= C7;			
												WHEN C7 => NULL; BIT_P <= C6;			
												WHEN C6 => NULL; BIT_P <= C5;			
												WHEN C5 => NULL; BIT_P <= C4;														
												WHEN C4 => NULL; BIT_P <= C3;			 										
												WHEN C3 => NULL; BIT_P <= C2;			
												WHEN C2 => NULL; BIT_P <= C1;			
												WHEN C1 => NULL; BIT_P <= C8; 
																			  BYTE_P <= BP;			
											END CASE;
										WHEN BP =>
											CASE BIT_P IS
												WHEN C8 => BIT_PAR(8) <= '1'; BIT_P <= C7;			
												WHEN C7 => BIT_PAR(7) <= '1'; BIT_P <= C6;			
												WHEN C6 => BIT_PAR(6) <= '1'; BIT_P <= C5;			
												WHEN C5 => BIT_PAR(5) <= '1'; BIT_P <= C4;														
												WHEN C4 => BIT_PAR(4) <= '1'; BIT_P <= C3;			 										
												WHEN C3 => BIT_PAR(3) <= '1'; BIT_P <= C2;			
												WHEN C2 => BIT_PAR(2) <= '1'; BIT_P <= C1;			
												WHEN C1 => BIT_PAR(1) <= '1'; BIT_P <= C8; 
																			 BYTE_P <= HI;
																		STATE <= ANALYSIS; 			
											END CASE;
									END CASE;
								END IF;
							END IF;		
					END CASE;
-----------------------------------------------------------------------------------------
				WHEN ANALYSIS =>
					IF ((HUMI_I_T + TEMP_I_T) = BIT_PAR) THEN
							TEMP_I <= TEMP_I_T;
							HUMI_I <= HUMI_I_T;
					END IF;
					CONVERTENDO <= '1';
					STATE <= RESET;
			END CASE;
		END IF;
	END PROCESS;
------------------------------------------------------------------------------------------	 		
END ARCHITECTURE;