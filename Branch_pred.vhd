library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;



entity Branch_pred is
	
	port
	(
		--adresa na kojoj je procitana instrukcija skoka
		BrP_tag_in : in word_t;
		--predikcija skoka
		BrP_pred_out : out word_t;
		
		clk : in std_logic;
		reset : in std_logic;
		wr : in std_logic;
		mispred: out std_logic;
		
		wb_bp_jmp_msg: in jump_pred_msg
		);
end Branch_pred;

architecture BrP_arch of Branch_pred is

--memorija u kojoj se pamte predikcije
type Cache_type is array (0 to CACHE_SIZE - 1) of BrP_set;
signal Cache_reg : Cache_type;
signal Cache_next : Cache_type;
--pokazivac na sledecu slobodnu lokaciju u prediktoru
signal head_reg : integer:=0;
signal head_next : integer;

begin

process (clk, reset)
begin

if (reset='1') then

	for i in 0 to CACHE_SIZE - 1 loop
	Cache_reg(i).Tag<=(others=>'0');
	Cache_reg(i).PC_pred<=(others=>'0');
	Cache_reg(i).State<=0;
	head_reg<=0;
	end loop;
	elsif(rising_edge(clk))  then
	Cache_reg<=Cache_next;
	head_reg<=head_next;
	end if;

end process;

process(wr,Cache_reg,head_reg,BrP_tag_in, wb_bp_jmp_msg)
	 variable cnt : integer:=0;
	 --variabla koja govori da li je potrebno azurirati ili upisati novi red u prediktoru
	 variable found: std_logic:='0';
    
	 begin  
	 found:='0';
	 --mispred=0 znaci da vrednost nije pronadjena u prediktoru
	 mispred<='0'; 
	 BrP_pred_out<=(others=>'0');
	 Cache_next<=Cache_reg;
	 head_next<=head_reg;
	 
	 --trazenje da li trenutna vrednost pc postoji u prediktoru
	 for cnt in 0 to CACHE_SIZE - 1 loop
	 if(Cache_reg(cnt).Tag=BrP_tag_in and (Cache_reg(cnt).State=2 or Cache_reg(cnt).State=3)) then 
	 BrP_pred_out<=Cache_reg(cnt).PC_pred;
	 mispred<='1';
	 exit;
	 end if;
	 end loop;
	
	if(wr='1') then
	
	--da li se stranje povecava
	if(wb_bp_jmp_msg.state_change='1')then
	for cnt in 0 to CACHE_SIZE - 1 loop
	if(Cache_reg(cnt).Tag=wb_bp_jmp_msg.pc) then
	
	--ako je stanje manje od 3 povecava se
	if(Cache_reg(cnt).State<3)then
	Cache_next(cnt).State<=Cache_reg(cnt).State+1;
	else Cache_next(cnt).State<=Cache_reg(cnt).State;
	end if;	
	--podatak je pronadjen i azuriran, pa se prekida dalja pretraga 
	found:='1';
	exit;
   end if;
	end loop;
	
	--stanje se smanjuje
	else
   for cnt in 0 to CACHE_SIZE - 1 loop
	if(Cache_reg(cnt).Tag=wb_bp_jmp_msg.pc) then
	
	if(Cache_reg(cnt).State>0)then
	Cache_next(cnt).State<=Cache_reg(cnt).State-1;
	else Cache_next(cnt).State<=Cache_reg(cnt).State;
	end if;	
	found:='1';
	exit;
	end if;
	end loop;
	end if;
	
	--ako podatak ne postoji u prediktoru,skok je uslovan i uslov je ispunjen upisuje se novi red u prediktoru
	--(stavljeno je da bi se izbeglo upisivanje kada prvi put dodje uslovan skok,a uslov nije ispunjen)
	--ILI
	--podatak ne postoji u prediktoru i skok je bezuslovan, upisuje se novi red
	if((found='0' and wb_bp_jmp_msg.state_change='1' and wb_bp_jmp_msg.unconditional='0') or (found='0' and wb_bp_jmp_msg.unconditional='1') )then
	Cache_next(head_reg).Tag <= wb_bp_jmp_msg.pc;
	Cache_next(head_reg).PC_pred <= wb_bp_jmp_msg.pc_next_pred;
	Cache_next(head_reg).State <= 2; --izabrano je da pocetno stanje bude 2
	head_next<=(head_reg+1) mod CACHE_SIZE; --prediktor upisuje po FIFO principu
	end if;
	end if;
		
   end process;
	
end BrP_arch;