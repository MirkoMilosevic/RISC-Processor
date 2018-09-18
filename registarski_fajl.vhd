library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.cpu_pkg.all;
use ieee.numeric_std.all;

entity registarski_fajl is
	
	port
	(
		clk	: in  std_logic;
		reset	: in  std_logic;
		regs1_addr: in reg_index;
		regs2_addr: in reg_index;
		regd_addr: in reg_index;
		regs1: out word_t;
		regs2: out word_t;
		regd: in word_t;
		regd_en : in std_logic --kontrolni signal za upis
		
	);
end registarski_fajl;

architecture reg_arch of registarski_fajl is

type REG_file_t is array (natural range 0 to REG_NUMBER-1) of word_t;
signal REG_file_reg : REG_file_t;
signal REG_file_next : REG_file_t;

begin

process (clk, reset)
variable i:integer:=0;
	begin
	if (reset='1') then
	for i in 0 to REG_NUMBER-1 loop
	REG_file_reg(i)<=(others=>'0');
	end loop;
	elsif(rising_edge(clk))  then
	REG_file_reg<=REG_file_next;
	end if;
end process;

--upis u reg fajl, sinhrono
process(regd_en, regd_addr, regd, REG_file_reg) 
	begin
	Reg_file_next<=Reg_file_reg;
	if(regd_en='1' ) then
	REG_file_next(to_integer(unsigned(regd_addr)))<=regd;
	end if;
	end process;
	
--citanje iz reg fajla, asinhrono
process(regs1_addr, regs2_addr,REG_file_reg)
	begin
	regs1<=REG_file_reg(to_integer(unsigned(regs1_addr)));
	regs2<=REG_file_reg(to_integer(unsigned(regs2_addr)));
end process;


end reg_arch;



