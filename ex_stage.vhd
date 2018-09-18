library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.cpu_pkg.all;

entity ex_stage is
	
	port
	(
		msg_ex_in : in stage_msg_t;
		msg_ex_out : out stage_msg_t;
		ctrl_in : in control_t;
	
		clk: in std_logic;
		reset : in std_logic;
		
		--koriste se u mem/wb fazama
		instruction_is_load: out std_logic;
		instruction_is_store: out std_logic;
		write_in_rd: out std_logic;
		
		--op1 i op2 su vrednosti koje salje id
		operand1: in word_t;
		operand2: in word_t;
		dest_address_in : in word_t;
		dest_address_out : out word_t;
		
		rd_addr_ex_in: in reg_index;
		rd_addr_ex_out: out reg_index;

		result : out word_t;
		
		id_ex_jmp_msg: in jump_pred_msg;
		ex_mem_jmp_msg: out jump_pred_msg;
		
		--signali koji komuniciraju sa control unit-om
		rd_ex_control_unit: out reg_index; --koji je destinacioni registar
		rd_en_ex: out std_logic; --vrednost koja se salje je  validna
		--signal koji javlja da li je podatak spreman, sluzi da generise stall kada je load u ex fazi
		is_ready: out std_logic; 
		data_ex_control_unit: out word_t; --vrednost registra koja se salje u control unit
		
		stall: in std_logic;
		
		--vrednost prosledjene iz control unit-a
		data_control_unit_in1: in word_t;
		data_control_unit_in2: in word_t;
		--signali koji odredjuju da li se koriste vrednosti poslate iz id ili iz control unit-a
		rs1_found: in std_logic;
		rs2_found: in std_logic;
		
		--sluzi da zaustavi procesor ako je HALT ili exception
		stop_ex_out : out std_logic
		
		
	);
end ex_stage;



architecture rtl of ex_stage is

function SelekcioniSignal(control: control_t) return integer is

begin
if(control.load_o='1')then return 1;
elsif (control.store_o='1')then return 2;
elsif (control.mov_o='1')then return 3;
elsif (control.movi_o='1')then return 4;
elsif (control.add_o='1')then return 5;
elsif (control.sub_o='1')then return 6;
elsif (control.addi_o='1')then return 7;
elsif (control.subi_o='1')then return 8;
elsif (control.and_o='1')then return 9;
elsif (control.xor_o='1')then return 10;
elsif (control.not_o='1')then return 11;
elsif (control.or_o='1')then return 12;
elsif (control.shl_o='1')then return 13;
elsif (control.shr_o='1')then return 14;
elsif (control.sar_o='1')then return 15;
elsif (control.rol_o='1')then return 16;
elsif (control.ror_o='1')then return 17;
elsif (control.jmp_o='1')then return 18;
elsif (control.jsr_o='1')then return 19;
elsif (control.rts_o='1')then return 20;
elsif (control.push_o='1')then return 21;
elsif (control.pop_o='1')then return 22;
elsif (control.beq_o='1')then return 23;
elsif (control.bnq_o='1')then return 24;
elsif (control.bgt_o='1')then return 25;
elsif (control.blt_o='1')then return 26;
elsif (control.bge_o='1')then return 27;
elsif (control.ble_o='1')then return 28;
elsif (control.halt_o='1')then return 29; 
else return 0;
end if;
end function SelekcioniSignal;

--STEK je vidljiv samo u ex fazi jer samo ta faza komunicira
constant STACK_SIZE : integer :=  2**5;
type stack_t is array (natural range 0 to STACK_SIZE - 1) of word_t;

signal stack_reg : stack_t;
signal stack_next : stack_t;
signal sp_reg:integer:=STACK_SIZE-1;
signal sp_next:integer;
signal dest_address_out_reg: word_t;
signal dest_address_out_next: word_t;
signal result_reg: word_t;
signal result_next: word_t;
signal instruction_is_load_next: std_logic;
signal instruction_is_store_next: std_logic;
signal instruction_is_load_reg:std_logic;
signal instruction_is_store_reg:std_logic;
signal write_in_rd_reg: std_logic;
signal write_in_rd_next: std_logic;
signal rd_addr_ex_out_next: reg_index;
signal rd_addr_ex_out_reg:  reg_index;
signal flush_reg: integer:=0;
signal flush_next: integer;
signal ex_mem_jmp_msg_reg: jump_pred_msg;
signal ex_mem_jmp_msg_next: jump_pred_msg;
signal stop_ex_out_next: std_logic;
signal stop_ex_out_reg:std_logic; 

begin

process(clk, reset)
variable i: integer;
begin
if(reset='1') then
sp_reg<=STACK_SIZE-1;
dest_address_out_reg<=(others=>'0');
result_reg<=(others=>'0');
instruction_is_store_reg<= '0';
instruction_is_load_reg<='0';
write_in_rd_reg<='0';
rd_addr_ex_out_reg<=(others => '0');
flush_reg<=0;
for i in 0 to STACK_SIZE-1 loop
stack_reg(i)<=(others=>'0');
end loop;

ex_mem_jmp_msg_reg.pc<=(others=>'0');
ex_mem_jmp_msg_reg.pc_next_pred<=(others=>'0');
ex_mem_jmp_msg_reg.jump<='0';
ex_mem_jmp_msg_reg.state_change<='0';
ex_mem_jmp_msg_reg.unconditional<='0';

stop_ex_out_reg<='0';

elsif (rising_edge(clk)) then
sp_reg<=sp_next;
rd_addr_ex_out_reg<=rd_addr_ex_out_next;
stack_reg<=stack_next;
write_in_rd_reg<=write_in_rd_next;
instruction_is_load_reg<=instruction_is_load_next;
instruction_is_store_reg<=instruction_is_store_next;
dest_address_out_reg<=dest_address_out_next;
result_reg<=result_next;
flush_reg<=flush_next;

ex_mem_jmp_msg_reg<=ex_mem_jmp_msg_next;

stop_ex_out_reg<=stop_ex_out_next;

end if;
end process;

process(rs1_found, rs2_found, data_control_unit_in1, data_control_unit_in2, stall, id_ex_jmp_msg, ex_mem_jmp_msg_reg,ctrl_in,flush_reg,rd_addr_ex_out_reg,rd_addr_ex_in ,operand1,operand2, write_in_rd_reg, msg_ex_in, instruction_is_load_reg, instruction_is_store_reg, dest_address_in, stack_reg, sp_reg, dest_address_out_reg, result_reg)

variable sel_temp: integer; --govori koja je instrukcija u pitanju
variable operand1_temp: word_t;
variable operand2_temp: word_t;
variable overF: unsigned(WORD_SIZE downto 0);
variable abs_imm:signed(WORD_SIZE-1 downto 0);
variable exception: std_logic:='0';
variable sign_temp:std_logic:='0';

variable sabirac_result : word_t;
variable jump_dest_addr_temp: word_t;

--pomocna procedura za uslovne skokove kada je uslov ispunjen
procedure JumpOK is
begin
		ex_mem_jmp_msg_next.state_change<='1'; --signalizira da treba pojacati stanje u branch prediktoru
      dest_address_out_next<=dest_address_in;
		msg_ex_out.instruction_is_jump<='1';--pali se samo kada se desi stvarni skok
		
		--ako predikcija nije bila dobra 2 sledece instrukcije se flush-uju
		if(id_ex_jmp_msg.pc_next_pred /= dest_address_in) then
		flush_next<=2;
		msg_ex_out.flush<='1';
		msg_ex_out.pc_next<=dest_address_in; --javlja if fazi koja je sledeca adresa
		ex_mem_jmp_msg_next.jump<='1'; --sluzi da signalizira wb da treba da upisuje u branch prediktor
		else 				
		ex_mem_jmp_msg_next.jump<='1';
		end if;

end procedure JumpOK; 

--pomocna procedura za uslovne skokove kada uslov nije ispunjen
procedure JumpNotOK is
begin
		ex_mem_jmp_msg_next.jump<='1'; 
      
		--flash-uje se ukoliko smo predvideli skok, a nece se desiti
		if(id_ex_jmp_msg.pc_next_pred = dest_address_in)then
		flush_next<=2;
		msg_ex_out.flush<='1';
		msg_ex_out.pc_next<=	std_logic_vector(unsigned(id_ex_jmp_msg.pc)+ 1); --nema skoka, pa se u pc upisuje pc+1
		msg_ex_out.instruction_is_jump<='1';
		end if;

end procedure JumpNotOK;

function Sabirac(p1: integer; p2: integer) return word_t is
begin
return std_logic_vector(To_signed((p1 + p2),WORD_SIZE));
end function Sabirac;

begin

stop_ex_out_next<='0';
overF:= (others => '0');
abs_imm:=(others=>'0');
exception:='0';
sign_temp:='0';
sp_next<= sp_reg;
stack_next<=stack_reg;
result_next<=result_reg;
rd_addr_ex_out_next<=rd_addr_ex_in;
instruction_is_store_next<='0';
instruction_is_load_next<= '0';
write_in_rd_next<='0';
dest_address_out_next<=dest_address_out_reg;
flush_next<=flush_reg;
msg_ex_out.pc<=msg_ex_in.pc;
msg_ex_out.pc_next<=msg_ex_in.pc_next;
msg_ex_out.instruction_is_jump<=msg_ex_in.instruction_is_jump;
msg_ex_out.flush<= msg_ex_in.flush;
ex_mem_jmp_msg_next<=id_ex_jmp_msg;
ex_mem_jmp_msg_next.jump<='0';
ex_mem_jmp_msg_next.state_change<='0';
ex_mem_jmp_msg_next.unconditional<='0';
rd_ex_control_unit<=rd_addr_ex_in;
rd_en_ex<='0';
is_ready<='0';
data_ex_control_unit<=(others=>'0');

--ako je doslo do flush ili stall ne izvrsava se ni jedna instrukcija, x instr ne radi nista
if(flush_reg > 0 or stall='1') then 
sel_temp:=0;  
if (flush_reg> 0 and stall='0') then
flush_next<=flush_reg-1; 
end if;
else 
sel_temp:=SelekcioniSignal(ctrl_in);
end if;

if(rs1_found='1') then 
operand1_temp:=data_control_unit_in1;
else operand1_temp:=operand1;
end if;

if(rs2_found='1') then 
operand2_temp:=data_control_unit_in2;
else operand2_temp:=operand2;
end if;

case sel_temp is

--LOAD---------------------------
when 1 =>
         if(signed(dest_address_in)>=0)then
			overF:=resize(unsigned(operand1_temp), overF'length) + unsigned(dest_address_in);
			sign_temp:='1';
			if(overF(WORD_SIZE)='1') then exception:='1'; 
			end if;
			else 
			sign_temp:='0';
			abs_imm:=signed(dest_address_in);
			abs_imm:=abs(abs_imm);
			if(unsigned(operand1_temp)< to_integer(abs_imm)) then exception:='1';
			end if;
			end if;
			
			if(exception='1') 
         then 
			stop_ex_out_next<='1';
			else
			instruction_is_load_next<='1';
			write_in_rd_next<='1';
			rd_en_ex<='1';
			  
			--sabira se vrednost operanda i neposredna vrednost poslata iz id faze
			if(sign_temp='1') then
			dest_address_out_next<=std_logic_vector(unsigned(operand1_temp)+ unsigned(dest_address_in));
		   else 
			dest_address_out_next<=std_logic_vector(unsigned(operand1_temp) -to_integer(abs_imm));
			end if;
			  
			end if;
			
			
--STORE---------------------------
when 2 => 
			if(signed(dest_address_in)>=0)then
			overF:=resize(unsigned(operand1_temp), overF'length) + unsigned(dest_address_in);
			sign_temp:='1';
			if(overF(WORD_SIZE)='1') then exception:='1'; 
			end if;
			else 
			sign_temp:='0';
			abs_imm:=signed(dest_address_in);
			abs_imm:=abs(abs_imm);
			if(unsigned(operand1_temp)< to_integer(abs_imm)) then exception:='1';
			end if;
			end if;
			
			if(exception='1') then 
			stop_ex_out_next<='1';
			else
			instruction_is_store_next<='1';
			result_next<=operand2_temp;	
	  
		   if(sign_temp='1') then
			dest_address_out_next<=std_logic_vector(unsigned(operand1_temp)+ unsigned(dest_address_in));
		   else 
			dest_address_out_next<=std_logic_vector(unsigned(operand1_temp)-to_integer(abs_imm));
			end if;
			  
			end if;

			 
--MOV---------------------------	
when 3 => 
			 result_next<=operand1_temp;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=operand1_temp; 
			 is_ready<='1'; 
			 
--MOVI---------------------------			 
when 4 => 
			 result_next<=operand1;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=operand1;
			 is_ready<='1'; 

--ADD---------------------------
when 5 => 
          sabirac_result:=Sabirac(to_integer(signed(operand1_temp)),to_integer(signed(operand2_temp)));
			 result_next<=sabirac_result;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=sabirac_result;
			 is_ready<='1'; 

--SUB---------------------------
when 6 => 
          sabirac_result:=Sabirac(to_integer(signed(operand1_temp)),(-to_integer(signed(operand2_temp))));
			 result_next<=sabirac_result;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=sabirac_result; 
			 is_ready<='1'; 
			 
--ADDI---------------------------			 
when 7 => 
			 sabirac_result:=Sabirac(to_integer(signed(operand1_temp)),to_integer(signed(operand2)));
			 result_next<=sabirac_result;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=sabirac_result;
			 is_ready<='1'; 

--SUBI---------------------------			 
when 8 => 
			 sabirac_result:=Sabirac(to_integer(signed(operand1_temp)),(-to_integer(signed(operand2))));
			 result_next<=sabirac_result;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=sabirac_result;
			 is_ready<='1'; 
			 
--AND---------------------------			 
when 9 => 
			 result_next<=operand1_temp AND operand2_temp;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=operand1_temp AND operand2_temp;
			 is_ready<='1'; 

--XOR---------------------------			 
when 10 => 
			 result_next<=operand1_temp XOR operand2_temp;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=operand1_temp XOR operand2_temp;
			 is_ready<='1'; 

--NOT---------------------------
when 11 => 
			 result_next<=NOT operand1_temp;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=NOT operand1_temp;
			 is_ready<='1'; 

--OR---------------------------
when 12 => 
			 result_next<=operand1_temp OR operand2_temp;
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=operand1_temp OR operand2_temp;
			 is_ready<='1'; 

--SHIFT LEFT---------------------------
when 13 => 
			 result_next<=to_stdlogicvector(to_bitvector(operand1_temp) sll to_integer(unsigned(operand2)));
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=to_stdlogicvector(to_bitvector(operand1_temp) sll to_integer(unsigned(operand2)));
			 is_ready<='1'; 

--SHIFT RIGHT---------------------------
when 14 => 
			 result_next<=to_stdlogicvector(to_bitvector(operand1_temp) srl to_integer(unsigned(operand2)));
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=to_stdlogicvector(to_bitvector(operand1_temp) srl to_integer(unsigned(operand2)));
			 is_ready<='1'; 
			 
--SHIFT ARITHM RIGHT---------------------------			 
when 15 => 
			 result_next<=to_stdlogicvector(to_bitvector(operand1_temp) sra to_integer(unsigned(operand2)));
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=to_stdlogicvector(to_bitvector(operand1_temp) sra to_integer(unsigned(operand2)));
			 is_ready<='1'; 

--ROL---------------------------			 
when 16 => 
			 result_next<=to_stdlogicvector(to_bitvector(operand1_temp) rol to_integer(unsigned(operand2)));
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=to_stdlogicvector(to_bitvector(operand1_temp) rol to_integer(unsigned(operand2)));
			 is_ready<='1'; 

--ROR---------------------------			 
when 17 => 
			 result_next<=to_stdlogicvector(to_bitvector(operand1_temp) ror to_integer(unsigned(operand2)));
			 write_in_rd_next<='1';
			 rd_en_ex<='1';
			 data_ex_control_unit<=to_stdlogicvector(to_bitvector(operand1_temp) ror to_integer(unsigned(operand2)));
			 is_ready<='1'; 

--JMP---------------------------			 
when 18 => 		
			if(signed(dest_address_in)>=0)then
			overF:=resize(unsigned(operand1_temp), overF'length) + unsigned(dest_address_in);
			sign_temp:='1';
			if(overF(WORD_SIZE)='1') then exception:='1'; 
			end if;
			else 
			sign_temp:='0';
			abs_imm:=signed(dest_address_in);
			abs_imm:=abs(abs_imm);
			if(unsigned(operand1_temp)< to_integer(abs_imm)) then exception:='1';
			end if;
			end if;
			
			if(exception='1') 
         then 
			stop_ex_out_next<='1';
			else
			  
			if(sign_temp='1') then
			jump_dest_addr_temp:=std_logic_vector(unsigned(operand1_temp)+ unsigned(dest_address_in));
		   else 
			jump_dest_addr_temp:=std_logic_vector(unsigned(operand1_temp)-to_integer(abs_imm));
			end if;
			  	
			dest_address_out_next<= jump_dest_addr_temp;
			msg_ex_out.instruction_is_jump<='1';
			ex_mem_jmp_msg_next.jump<='1';
			ex_mem_jmp_msg_next.unconditional<='1'; --pomocni bit za upis u branch prediktor, bezuslvni skok
			
			--ako je predikcija losa flush
			if(id_ex_jmp_msg.pc_next_pred /= jump_dest_addr_temp) then
			flush_next<=2;
			msg_ex_out.pc_next<=jump_dest_addr_temp;
			msg_ex_out.flush<='1'; 
			else 
			ex_mem_jmp_msg_next.state_change<='1';
			end if;
			ex_mem_jmp_msg_next.pc_next_pred<=jump_dest_addr_temp;
			end if;
			
			
--JSR---------------------------
when 19 => 
			if(signed(dest_address_in)>=0)then
			overF:=resize(unsigned(operand1_temp), overF'length) + unsigned(dest_address_in);
			sign_temp:='1';
			if(overF(WORD_SIZE)='1') then exception:='1'; 
			end if;
			else 
			sign_temp:='0';
			abs_imm:=signed(dest_address_in);
			abs_imm:=abs(abs_imm);
			if(unsigned(operand1_temp)< to_integer(abs_imm)) then exception:='1';
			end if;
			end if;
			
			if(exception='1') then 
			stop_ex_out_next<='1';	
         else
			
			if(sign_temp='1') then
			jump_dest_addr_temp:=std_logic_vector(unsigned(operand1_temp)+ unsigned(dest_address_in));
		   else 
			jump_dest_addr_temp:=std_logic_vector(unsigned(operand1_temp)-to_integer(abs_imm));
			end if;
			
		   dest_address_out_next<= jump_dest_addr_temp;
			--adresa povratka iz potprograma se stavlja na stek
			stack_next(sp_reg)<=std_logic_vector(unsigned(id_ex_jmp_msg.pc)+ 1);
			sp_next<=sp_reg-1; 
			msg_ex_out.instruction_is_jump<='1';
			ex_mem_jmp_msg_next.jump<='1';
			ex_mem_jmp_msg_next.unconditional<='1';
			if(id_ex_jmp_msg.pc_next_pred /= jump_dest_addr_temp) then
			flush_next<=2;
			msg_ex_out.pc_next<=jump_dest_addr_temp;
			msg_ex_out.flush<='1';
			else 
			ex_mem_jmp_msg_next.state_change<='1';
			end if;
		   ex_mem_jmp_msg_next.pc_next_pred<=jump_dest_addr_temp;
			end if;
	

--RTS---------------------------				
when 20 =>  
			--ako je stek prazan generise se izuzetak 
			if(sp_reg=(STACK_SIZE - 1)) then 
			stop_ex_out_next<='1';
			else
			sp_next<=sp_reg+1;	
			end if;
		   --RTS uvek radi flush jer se ne upisuje u branch prediktor	
			flush_next<=2;
			msg_ex_out.flush<='1';
			msg_ex_out.instruction_is_jump<='1';
			msg_ex_out.pc_next<=stack_reg(sp_reg + 1);

			
--PUSH---------------------------				
when 21 => 
			--ako je stek pun generise se izuzetak
			if(sp_reg<0)then stop_ex_out_next<='1';
			else
         stack_next(sp_reg)<=operand1_temp; 
			sp_next<=sp_reg-1; 
			end if;
				
				
--POP---------------------------
when 22 =>  
			if(sp_reg=(STACK_SIZE - 1)) then 
			stop_ex_out_next<='1';	
			else
			sp_next<=sp_reg+1; 
			result_next<=stack_reg(sp_reg+1);
			rd_en_ex<='1';
			data_ex_control_unit<=stack_reg(sp_reg+1);	
			write_in_rd_next<='1';
			is_ready<='1'; 
			end if;

				
--B EQUAL---------------------------			  
when 23 =>  				 
			if(id_ex_jmp_msg.overF='1')then stop_ex_out_next<='1';
			else
			if (to_integer(signed(operand1_temp)) = to_integer(signed(operand2_temp))) then
			
			JumpOK;
				
			else
			
			JumpNotOK;
			
			end if;
			ex_mem_jmp_msg_next.pc_next_pred<=dest_address_in;
			end if;

			
--B NOT EQUAL---------------------------
when 24 => 
			if(id_ex_jmp_msg.overF='1')then stop_ex_out_next<='1';
			else
			if (to_integer(signed(operand1_temp)) /= to_integer(signed(operand2_temp))) then 
				
			JumpOK;
				
			else
				
         JumpNotOK;
				
			end if;
			ex_mem_jmp_msg_next.pc_next_pred<=dest_address_in;
			end if;

			
--B GREATER---------------------------				
when 25 => 
			if(id_ex_jmp_msg.overF='1')then stop_ex_out_next<='1';
			else
			if (to_integer(signed(operand1_temp)) > to_integer(signed(operand2_temp))) then 
				
			JumpOK;
				
			else
				
			JumpNotOK;
				
		   end if;
			ex_mem_jmp_msg_next.pc_next_pred<=dest_address_in;	
		   end if;
			
			
--B LESS---------------------------
when 26 => 
			if(id_ex_jmp_msg.overF='1')then stop_ex_out_next<='1';
			else
				
			if (to_integer(signed(operand1_temp)) < to_integer(signed(operand2_temp))) then 
				
			JumpOK;
				
			else
				
			JumpNotOK;
				
			end if;
			ex_mem_jmp_msg_next.pc_next_pred<=dest_address_in;
			end if;

			
--B GREATER OR EQUAL---------------------------				
when 27 => 
			if(id_ex_jmp_msg.overF='1')then stop_ex_out_next<='1';
			else
			if (to_integer(signed(operand1_temp)) >= to_integer(signed(operand2_temp))) then 
				
			JumpOK;
				
			else
				
			JumpNotOK;
				
			end if;
			ex_mem_jmp_msg_next.pc_next_pred<=dest_address_in;
				
			end if;

		
--B LESS OR EQUAL---------------------------
when 28 => 
			if(id_ex_jmp_msg.overF='1')then stop_ex_out_next<='1';
			else	
			if (to_integer(signed(operand1_temp)) <= to_integer(signed(operand2_temp))) then 
				
			JumpOK;
				
			else 
				
			JumpNotOK;
				
			end if;
			ex_mem_jmp_msg_next.pc_next_pred<=dest_address_in;
			end if;

			
--HALT---------------------------				
when 29 => 
			stop_ex_out_next<='1';
				
					
when others => result_next<=(others=>'0'); 
end case;

end process;

ex_mem_jmp_msg<=ex_mem_jmp_msg_reg;
write_in_rd<=write_in_rd_reg;
result<=result_reg;
dest_address_out<=dest_address_out_reg;
instruction_is_load<=instruction_is_load_reg;
instruction_is_store<= instruction_is_store_reg;
rd_addr_ex_out<=rd_addr_ex_out_reg;
stop_ex_out<=stop_ex_out_reg;
end rtl;
