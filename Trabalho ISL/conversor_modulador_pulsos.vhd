LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
--USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.pacote.ALL;

ENTITY conversor_modulador_pulsos IS
GENERIC (PERIOD_RATIO : INTEGER := 6666000;
		 MINIMO_E : INTEGER;  --VALOR MINIMO DA ESCALA DE ENTRADA
	     MAXIMO_E : INTEGER;  --VALOR MAXIMO DA ESCALA DE ENTRADA
	     MINIMO_S : INTEGER;  --VALOR MINIMO DA ESCALA DE SAIDA
	     MAXIMO_S : INTEGER); --VALOR MAXIMO DA ESCALA DE SAIDA
	    
PORT (	 ENTRADA : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	     PULSE_W : OUT INTEGER);
END conversor_modulador_pulsos;

ARCHITECTURE behavior OF conversor_modulador_pulsos IS

SIGNAL ENTRADA_ESCALADA: INTEGER;
SIGNAL SAIDA_TEMPORARIA: INTEGER;

BEGIN

CS1: Scale_change GENERIC MAP(minimo_e, maximo_e, minimo_s, maximo_s) PORT MAP (entrada, entrada_escalada);

PULSE_W <= PERIOD_RATIO * ENTRADA_ESCALADA; 
	


END behavior;