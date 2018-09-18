library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;



entity if_stage is
	port
	(	
		stall: in std_logic;
	
		clk: in std_logic;
		reset: in std_logic;
		if_in: in word_t;
		mispred:in std_logic; --da li je pc next=pc+1 ili vrednost iz prediktora
		branch_addr: in word_t;
		if_msg_in: in stage_msg_t;
		if_msg : out stage_msg_t;
		if_id_jmp_msg: out jump_pred_msg;
		pc: out word_t
		
	);
end if_stage;



architecture if_stage_arch of if_stage is
signal pc_reg, pc_next : word_t;
signal if_id_jmp_msg_reg: jump_pred_msg;
signal if_id_jmp_msg_next: jump_pred_msg;

signal first_instr: std_logic;

begin

process(clk, reset)
begin
if (reset = '1') then
			pc_reg <= (others=>'0');
			if_id_jmp_msg_reg.pc<=(others=>'0');
			if_id_jmp_msg_reg.pc_next_pred<=(others=>'0');
			if_id_jmp_msg_reg.jump<='0';
			if_id_jmp_msg_reg.unconditional<='0';
			if_id_jmp_msg_reg.state_change<='0';
			first_instr<='1';
			


		elsif (rising_edge(clk)) then
			pc_reg <= pc_next;
			if_id_jmp_msg_reg<=if_id_jmp_msg_next;
			first_instr<='0';
		
			end if;
end process;	

process(first_instr, stall, if_msg_in, pc_reg, branch_addr, mispred, if_in, if_id_jmp_msg_reg)

variable pc_temp:word_t;

begin 

--kada je stall zadrzava se stara vrednost u sledecem clk-u
if(stall='1') then
pc_next<=pc_reg;
if_id_jmp_msg_next<=if_id_jmp_msg_reg;

if_msg.instruction_is_jump<='0';
if_msg.flush<='0';
if_msg.pc_next<=(others=>'0');
if_msg.pc<=(others=>'0');

else
pc_next<=pc_reg;
if_id_jmp_msg_next<=if_id_jmp_msg_reg;
if_msg.pc_next<=(others=>'0');
if_msg.flush<= if_msg_in.flush;

--pocetak rada, pc uzima vrednost iz fajla
if(first_instr='1') then 
	pc_next<=if_in;  
	if_msg.instruction_is_jump<='0';
	if_msg.flush<='0';
	if_id_jmp_msg_next.pc_next_pred<=if_in;
	
	--mispred=0 znaci da trenutna vrednost pc nije upisana u branch prediktor
	elsif(mispred='0')then
				pc_temp:=std_logic_vector(unsigned(pc_reg)+ 1);
				pc_next<= pc_temp;
				if_msg.pc_next <= pc_temp;
				if_id_jmp_msg_next.pc_next_pred<=pc_temp;
				
--vrednost pc-ja je nadjena u prediktoru (skok) i stanje je vece od 1
   else				
	pc_next<= branch_addr;
	if_msg.pc_next<=branch_addr;
	if_id_jmp_msg_next.pc_next_pred<=branch_addr;
end if;

if_msg.pc <= pc_reg;

--u ex fazi je bio skok, a predikcija je bila losa ili je nije bilo, pa se u pc ucitava vrednost na koju se skace
if(if_msg_in.instruction_is_jump='1' and if_msg_in.flush='1') then
if_msg.pc_next<=if_msg_in.pc_next;
pc_next<=if_msg_in.pc_next;
if_msg.instruction_is_jump<='0';
if_id_jmp_msg_next.pc_next_pred<=if_msg_in.pc_next;
if_msg.flush<='0';

--ako nije ispunjen ceo uslov, gase se signali
else 
if_msg.instruction_is_jump<='0';
if_msg.flush<='0';

end if;		

if_id_jmp_msg_next.pc<=pc_reg;

end if;

end process;

if_id_jmp_msg<=if_id_jmp_msg_reg;
pc<=pc_reg;

end if_stage_arch;


