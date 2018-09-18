library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;
use IEEE.NUMERIC_STD.ALL;


entity id_stage is
	

	port
	(
		stall: in std_logic;
			
		clk: in std_logic;
		reset: in std_logic;
		rs1_addr: out reg_index;
		rs2_addr: out reg_index;
		msg_id_in : in stage_msg_t;
		msg_id: out stage_msg_t;
		id_in : in  word_t;
		ctrl_out: out control_t; --koja je instr u pitanju
		operand1_in: in word_t;
		operand2_in: in word_t;
		operand1_out: out word_t;
		operand2_out: out word_t;
		dest_addr: out word_t; --koristimo liniju i za neke imm vrednosti
		rd_addr_id: out reg_index;
		instr_addr: out word_t;
		if_id_jmp_msg: in jump_pred_msg;
		id_ex_jmp_msg: out jump_pred_msg;
		
		--vrednosti koje odmah javljaju control unit-u koji registri se koriste
		use_rs1: out std_logic;
		use_rs2: out std_logic
		
			
	);
end id_stage;



architecture id_stage_arch of id_stage is
signal operand1_out_reg: word_t;
signal operand1_out_next: word_t;
signal operand2_out_reg: word_t;
signal operand2_out_next: word_t;
signal dest_addr_reg:word_t;
signal dest_addr_next:word_t;
signal instr_addr_reg:word_t;
signal instr_addr_next:word_t;
signal ctrl_out_next: control_t;
signal ctrl_out_reg: control_t;
signal rd_addr_reg: reg_index;
signal rd_addr_next: reg_index;

signal id_ex_jmp_msg_reg: jump_pred_msg;
signal id_ex_jmp_msg_next: jump_pred_msg;

--signali koji sluze da se zapamte stare vrednosti kada se desi stall
------------------------
signal rs1_addr_reg:  reg_index;
signal rs2_addr_reg:  reg_index;
signal rs1_addr_next:  reg_index;
signal rs2_addr_next:  reg_index;
signal use_rs1_reg: std_logic;
signal use_rs2_reg: std_logic;
signal use_rs1_next: std_logic;
signal use_rs2_next: std_logic;
------------------------

begin

process(clk, reset)
begin
if(reset='1') then
operand1_out_reg<=(others=>'0');
operand2_out_reg<=(others=>'0');
dest_addr_reg<= (others=>'0');
instr_addr_reg<= (others=>'0');
ctrl_out_reg<= (others=>'0');
rd_addr_reg<=(others=>'0');

id_ex_jmp_msg_reg.pc<=(others=>'0');
id_ex_jmp_msg_reg.pc_next_pred<=(others=>'0');
id_ex_jmp_msg_reg.jump<='0';
id_ex_jmp_msg_reg.state_change<='0';
id_ex_jmp_msg_reg.unconditional<='0';

rs1_addr_reg<=(others=>'0');
rs2_addr_reg<=(others=>'0');
use_rs2_reg<='0';
use_rs1_reg<='0';


elsif (rising_edge(clk)) then
operand2_out_reg<=operand2_out_next;
operand1_out_reg<=operand1_out_next;
dest_addr_reg<= dest_addr_next;
instr_addr_reg<=instr_addr_next;
ctrl_out_reg<=ctrl_out_next;
rd_addr_reg<=rd_addr_next;

id_ex_jmp_msg_reg<=id_ex_jmp_msg_next;

rs1_addr_reg<=rs1_addr_next;
rs2_addr_reg<=rs2_addr_next;
use_rs2_reg<=use_rs2_next;
use_rs1_reg<=use_rs1_next;


end if;
end process;


process(use_rs1_reg, use_rs2_reg, rs1_addr_reg, rs2_addr_reg, stall, instr_addr_reg, if_id_jmp_msg, msg_id_in, rd_addr_reg, operand1_out_reg, ctrl_out_reg, operand2_out_reg, id_in, operand1_in, operand2_in, dest_addr_reg, id_ex_jmp_msg_reg)
variable id_in_temp : instruction_t;

--koriste se za proveru prekoracenja i racunanje adrese
variable overF: unsigned(WORD_SIZE downto 0); 
variable abs_imm:signed(WORD_SIZE-1 downto 0);
variable exception: std_logic:='0';
variable sign_temp:std_logic:='0';
 
begin

overF:=(others=>'0');
abs_imm:=(others=>'0');
exception:='0';
sign_temp:='0';

--cuvaju se stare vrednosti
if(stall='1') then
operand1_out_next<=operand1_out_reg;
operand2_out_next<= operand2_out_reg;
dest_addr_next<= dest_addr_reg;
instr_addr_next<=instr_addr_reg;
ctrl_out_next<=ctrl_out_reg;
rd_addr_next<=rd_addr_reg;
id_ex_jmp_msg_next<=id_ex_jmp_msg_reg;
msg_id<=msg_id_in;

rs1_addr<=rs1_addr_reg;
rs2_addr<=rs2_addr_reg;
rs1_addr_next<=rs1_addr_reg;
rs2_addr_next<=rs2_addr_reg;
use_rs1<=use_rs1_reg;
use_rs2<=use_rs2_reg;
use_rs1_next<=use_rs1_reg;
use_rs2_next<=use_rs2_reg;


else



id_ex_jmp_msg_next<=if_id_jmp_msg;
id_ex_jmp_msg_next.overF<='0';

rs1_addr<=(others=>'0');
rs2_addr<=(others=>'0');
rd_addr_next<=rd_addr_reg; 
instr_addr_next<=msg_id_in.pc;
dest_addr_next<= dest_addr_reg; 
operand1_out_next<=operand1_out_reg;
operand2_out_next<= operand2_out_reg;
ctrl_out_next<=(others=>'0');
msg_id<=msg_id_in;

--secemo procitanu rec iz instrukcijske mem
id_in_temp.opcode1:= id_in(31 downto 29);
id_in_temp.opcode2:= id_in(28 downto 26);
id_in_temp.rd:= id_in(25 downto 21);
id_in_temp.rs1:= id_in(20 downto 16);
id_in_temp.rs2:= id_in(15 downto 11);
id_in_temp.imm:= id_in(10 downto 0);

use_rs1<='0';
use_rs2<='0';

use_rs1_next<='0';
use_rs2_next<='0';
rs1_addr_next<=(others=>'0');
rs2_addr_next<=(others=>'0');

case id_in_temp.opcode1 is
when "000" => case id_in_temp.opcode2 is

--LOAD---------------------------
when "000" => 
			ctrl_out_next.load_o <= '1' ;	
			rd_addr_next<= id_in_temp.rd;
			rs1_addr<=id_in_temp.rs1;
			use_rs1<='1';
			dest_addr_next(15 downto 0)<=id_in_temp.rs2 & id_in_temp.imm; --neposredna vrednost
			--celu adresu racunamo u ex kada saznamo da li je potrebna vrednost u reg fajlu ili u control unit-u
			dest_addr_next(31 downto 16)<=(others=>id_in_temp.rs2(id_in_temp.rs2'length-1)); 
			operand1_out_next<=operand1_in; --vrednost op1 je procitana iz reg fajla
			
			--use se koristi da javi control unit-u koje registre instrukcija koristi
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			
			
--STORE---------------------------
when "001" =>	
			ctrl_out_next.store_o <= '1' ;
			rs1_addr<=id_in_temp.rs1;
			rs2_addr<=id_in_temp.rs2;
			use_rs1<='1';
			use_rs2<='1';
			dest_addr_next(15 downto 0)<=id_in_temp.rd & id_in_temp.imm;
			dest_addr_next(31 downto 16)<=(others=>id_in_temp.rd(id_in_temp.rd'length-1));
			operand1_out_next<=operand1_in;
			operand2_out_next<=operand2_in;
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			use_rs2_next<='1';
			rs2_addr_next<=id_in_temp.rs2;
			
			
--MOV---------------------------				
when "100" => 
			ctrl_out_next.mov_o <= '1' ;		
			rd_addr_next<= id_in_temp.rd;
			rs1_addr<=id_in_temp.rs1;
			use_rs1<='1';			
			operand1_out_next<=operand1_in;
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			
			
--MOVI---------------------------
when "101" => 
			ctrl_out_next.movi_o <= '1' ;		
			rd_addr_next<= id_in_temp.rd;
			operand1_out_next <= (others => '0');
			operand1_out_next(15 downto 0) <= id_in_temp.rs2 & id_in_temp.imm;
			
when others => ctrl_out_next.x <= '1' ;
			
end case;

when "001" =>
			--zajednicki kod za aritmeticke instrukcije
         rd_addr_next<= id_in_temp.rd;
			rs1_addr<=id_in_temp.rs1;
			operand1_out_next<=operand1_in;
			use_rs1<='1';
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;

 case id_in_temp.opcode2 is

--ADD---------------------------
when "000" => 
			ctrl_out_next.add_o <= '1' ;		
			rs2_addr<=id_in_temp.rs2;
			operand2_out_next<=operand2_in;
			use_rs2<='1';
						
			use_rs2_next<='1';
			rs2_addr_next<=id_in_temp.rs2;
			
			
--SUB---------------------------			
when "001" => 
			ctrl_out_next.sub_o <= '1' ;		
			rs2_addr<=id_in_temp.rs2;
			operand2_out_next<=operand2_in;
			use_rs2<='1';
			
			use_rs2_next<='1';
			rs2_addr_next<=id_in_temp.rs2;
			
			
--ADDI---------------------------			
when "100" => 
			ctrl_out_next.addi_o <= '1' ;		
			operand2_out_next<= (others => id_in(15));
			operand2_out_next(15 downto 0) <= id_in_temp.rs2 & id_in_temp.imm;
			
--SUBI---------------------------			
when "101" => 
			ctrl_out_next.subi_o <= '1' ;		
			operand2_out_next<= (others => id_in(15));
			operand2_out_next(15 downto 0) <= id_in_temp.rs2 & id_in_temp.imm;

--u slucaju da je op kod za aritmeticke instrukcije, gase se signali koji komuniciraju sa control unit-om			
when others => ctrl_out_next.x <= '1' ; use_rs1_next<='0'; use_rs1<='0';

end case;

when "010" =>
         --zajednicki kod za logicke instrukcije
			rd_addr_next<= id_in_temp.rd;
			rs1_addr<=id_in_temp.rs1;
			operand1_out_next<=operand1_in;
			rs2_addr<=id_in_temp.rs2;
			operand2_out_next<=operand2_in;
			use_rs1<='1';
			use_rs2<='1';
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			use_rs2_next<='1';
			rs2_addr_next<=id_in_temp.rs2;
			

case id_in_temp.opcode2 is

--AND---------------------------
when "000" => ctrl_out_next.and_o <= '1' ;
			
--OR---------------------------			
when "001" => ctrl_out_next.or_o <= '1' ;
			
--XOR---------------------------			
when "010" => ctrl_out_next.xor_o <= '1' ;
			
--NOT---------------------------			
when "011" => ctrl_out_next.not_o <= '1' ;
			--uveli smo pretpostavku da NOT barata samo sa operandom1
			use_rs2<='0'; 
			use_rs2_next<='0';
			
			
when others => ctrl_out_next.x <= '1' ; use_rs2<='0'; use_rs2_next<='0'; use_rs1<='0'; use_rs1_next<='0';

end case;

when "011" =>
			--zajednicki kod za pomeracke instrkcije
         rd_addr_next<= id_in_temp.rd;
			rs1_addr<=id_in_temp.rd;
			operand1_out_next<=operand1_in;
			operand2_out_next<= (others=>'0');
			operand2_out_next(4 downto 0)<=id_in_temp.rs2;
			use_rs1<='1';
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rd;
			

case id_in_temp.opcode2 is

--SL---------------------------
when "000" => ctrl_out_next.shl_o <= '1' ;
			
--SR---------------------------			
when "001" => ctrl_out_next.shr_o <= '1' ;
			
--SAR---------------------------			
when "010" => ctrl_out_next.sar_o <= '1' ;
							
--ROL---------------------------			
when "011" => ctrl_out_next.rol_o <= '1' ;
			
--ROR---------------------------			
when "100" => ctrl_out_next.ror_o <= '1' ;
			
when others => ctrl_out_next.x <= '1' ; use_rs1_next<='0'; use_rs1<='0';

end case;

when "100" => case id_in_temp.opcode2 is

--JMP---------------------------
when "000" => 
			ctrl_out_next.jmp_o <= '1' ;
			rs1_addr<=id_in_temp.rs1;
			use_rs1<='1';
			operand1_out_next<=operand1_in;
			--kao kod Load/Store, ovo je neposredna vrednost koja ce se sabrati sa vr registra
			dest_addr_next(15 downto 0)<=id_in_temp.rs2 & id_in_temp.imm;
			dest_addr_next(31 downto 16)<=(others=>id_in_temp.rs2(id_in_temp.rs2'length-1));			
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			
			
--JSR---------------------------		
when "001" => ctrl_out_next.jsr_o <= '1' ;
			
			rs1_addr<=id_in_temp.rs1;
			use_rs1<='1';
			operand1_out_next<=operand1_in;
			dest_addr_next(15 downto 0)<=id_in_temp.rs2 & id_in_temp.imm;
			dest_addr_next(31 downto 16)<=(others=>id_in_temp.rs2(id_in_temp.rs2'length-1));			
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			
			
--RTS---------------------------			
when "010" => ctrl_out_next.rts_o <= '1' ;
	
--PUSH---------------------------
when "100" => 
			ctrl_out_next.push_o <= '1' ;
			rs1_addr<=id_in_temp.rs1;
			operand1_out_next<=operand1_in;
			use_rs1<='1';
		
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			
			
--POP---------------------------			
when "101" => 
			ctrl_out_next.pop_o <= '1' ;	
			rd_addr_next<= id_in_temp.rd;
			
when others => ctrl_out_next.x <= '1' ;

end case;

when "101" =>
         --zajednicki kod za uslovne skokove
			
			--provera da li je pomeraj pozitivan
			if(signed(id_in_temp.rd & id_in_temp.imm)>=0)then
			--provera da li je doslo do prekoracenja u plusu
			overF:=resize(unsigned(if_id_jmp_msg.pc), overF'length) + unsigned(id_in_temp.rd & id_in_temp.imm)+1;
			sign_temp:='1';
			
			if(overF(WORD_SIZE)='1') then exception:='1'; --sluzi da upali stop kasnije 
			end if;
			
			else 
			--provera da li je adresa manja od nule
			sign_temp:='0';
			abs_imm(15 downto 0):=signed(id_in_temp.rd & id_in_temp.imm);
			abs_imm(31 downto 16):=(others=>'1');
			abs_imm:=abs(abs_imm);
			
			if((unsigned(if_id_jmp_msg.pc)+1)< to_integer(abs_imm)) then exception:='1';
			end if;
			
			end if;

         if(exception='1') 
         then id_ex_jmp_msg_next.overF<='1';
			
			else
         rs1_addr<=id_in_temp.rs1;
			operand1_out_next<=operand1_in;
			rs2_addr<=id_in_temp.rs2;
			operand2_out_next<=operand2_in;
			use_rs1<='1';
			use_rs2<='1';
			
			if(sign_temp='1') 
			then dest_addr_next<=std_logic_vector(unsigned(if_id_jmp_msg.pc)+ unsigned(id_in_temp.rd & id_in_temp.imm)+1);
		   else 
			dest_addr_next<=std_logic_vector(unsigned(if_id_jmp_msg.pc)- to_integer(abs_imm)+1);
			end if;
			
			use_rs1_next<='1';
			rs1_addr_next<=id_in_temp.rs1;
			use_rs2_next<='1';
			rs2_addr_next<=id_in_temp.rs2;
			
			end if;
 
 case id_in_temp.opcode2 is


--BEQ---------------------------
when "000" => ctrl_out_next.beq_o <= '1' ;
						
--BNQ---------------------------					
when "001" => ctrl_out_next.bnq_o <= '1' ;
			
--BGT---------------------------			
when "010" => ctrl_out_next.bgt_o <= '1' ;			
			
--BLT---------------------------			
when "011" => ctrl_out_next.blt_o <= '1' ;
			
--BGE---------------------------			
when "100" => ctrl_out_next.bge_o <= '1' ;		
			
--BLE---------------------------			
when "101" => ctrl_out_next.ble_o <= '1' ;		
			
when others => ctrl_out_next.x <= '1' ; use_rs1_next<='0'; use_rs1<='0'; use_rs2_next<='0'; use_rs2<='0';

end case;

when "111" => case id_in_temp.opcode2 is

--HALT---------------------------
when "111" => ctrl_out_next.halt_o <= '1' ;

when others => ctrl_out_next.x <= '1' ;

end case;

when others => ctrl_out_next.x <= '1' ;

end case;

end if;

end process;

id_ex_jmp_msg<=id_ex_jmp_msg_reg;
instr_addr<=instr_addr_reg;
dest_addr<=dest_addr_reg;
operand1_out<=operand1_out_reg;
operand2_out<=operand2_out_reg;
ctrl_out<=ctrl_out_reg;
rd_addr_id<= rd_addr_reg;
end id_stage_arch;


