library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.cpu_pkg.all;


entity instr_mem is

port
	(
			address: in word_t;
			first_pc: out word_t; --vrednost koja se salje if fazi na pocetku rada
			dataout : out word_t --vrednost koja se salje id fazi
				
	);
end instr_mem;

architecture rtl of instr_mem is
--jedan red u instrukcijskoj memoriji 
type line_instr_mem is record 
			i_m_address: word_t; 
			i_m_data:  word_t;
end record;

constant INSTR_MEM_SIZE : integer :=  2**7;

type storage_array is
    array (natural range 0 to INSTR_MEM_SIZE - 1) of line_instr_mem;

signal storage : storage_array;

begin

--citanje asinhrono
process(address, storage)
file f : text;
constant filename: string := "instr_mem.txt";
variable L: line;
variable i: integer;
variable storage_size: integer;
variable j: integer;
variable adr_temp : word_t;
variable data_temp : word_t;
variable first_pc_temp : word_t;

begin

file_open(f,filename,READ_MODE); 
storage_size:=0;
--citanje reda iz fajla
readline(f, l);
--citanje prve heksadecimalne adrese iz reda
hread(l, first_pc_temp);
--upisivanje te vrednosti u first pc
first_pc<=first_pc_temp;

--citanje ostatka fajla i popunjavanje kesa
 for i in 0 to INSTR_MEM_SIZE - 1 loop
 if (endfile(f)) then exit; end if;
readline(f, l);
hread(l, adr_temp);
read(l, data_temp);
storage_size:=storage_size + 1;
storage(i).i_m_address<=adr_temp;
storage(i).i_m_data<=data_temp;
end loop;
file_close(f);
dataout <= (dataout'range => 'Z');

--trazenje instrukcije sa adrese koju zadaje id faza
for j in 0 to storage_size-1 loop
if(storage(j).i_m_address=address) then
dataout<=storage(j).i_m_data;
end if;

end loop;

end process;

end rtl;