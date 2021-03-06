
----------------------------------------------------------------
--  Title     : scc.vhd
--  Function  : Sound Creation Chip (KONAMI)
--  Date      : 28th,August,2000
--  Revision  : 1.01
--  Author    : Kazuhiro TSUJIKAWA (ESE Artists' factory)
----------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity cscc is
  port(
    pSltClk     : IN std_logic;
    pSltRst_n   : IN std_logic;
    pSltSltsl_n : IN std_logic;
    pSltIorq_n  : IN std_logic;
    pSltRd_n    : IN std_logic;
    pSltWr_n    : IN std_logic;
    pSltAdr     : IN std_logic_vector(15 downto 0);
    pSltDat     : INOUT std_logic_vector(7 downto 0);
    pSltBdir_n  : OUT std_logic;

    pSltCs1     : IN std_logic;
    pSltCs2     : IN std_logic;
    pSltCs12    : IN std_logic;
    pSltRfsh_n  : IN std_logic;
    pSltWait_n  : IN std_logic;
    pSltInt_n   : IN std_logic;
    pSltM1_n    : IN std_logic;
    pSltMerq_n  : IN std_logic;

    pSltClk2    : IN std_logic;
    pSltRsv5    : OUT std_logic;
    pSltRsv16   : OUT std_logic;

    pSltSndL    : OUT std_logic;
    pSltSndR    : OUT std_logic;
    pSltSound   : OUT std_logic;
    
-- FLASH ROM interface
	pFlAdr		: OUT std_logic_vector(22 downto 0);
	pFlDat		: INOUT std_logic_vector(7 downto 0);
	pFlDatH		: IN std_logic_vector(6 downto 0);
	pFlCS_n		: OUT std_logic;
	pFlOE_n		: OUT std_logic;
	pFlW_n		: OUT std_logic;
	pFlBYTE_n	: OUT std_logic;
	pFlRP_n		: OUT std_logic;
	pFlRB_b		: IN std_logic;
	pFlVpp		: OUT std_logic;
-- First start after power on detected
	iFsts		: INOUT std_logic
--	iFsts		: IN std_logic
 );
end cscc;

architecture RTL of cscc is

  component scc_wave
    port(
      pSltClk_n : IN std_logic;
      pSltRst_n : IN std_logic;
      pSltAdr   : IN std_logic_vector(7 downto 0);
      pSltDat   : INOUT std_logic_vector(7 downto 0);
      SccAmp    : OUT std_logic_vector(7 downto 0);

      SccRegWe  : IN std_logic;
      SccModWe  : IN std_logic;
      SccWavCe  : IN std_logic;
      SccWavOe  : IN std_logic;
      SccWavWe  : IN std_logic;
      SccWavWx  : IN std_logic;
      SccWavAdr : IN std_logic_vector(4 downto 0);
      SccWavDat : IN std_logic_vector(7 downto 0);
      pFlOE_nt		: IN std_logic;
      pFlDat		: INOUT std_logic_vector(7 downto 0)
    );
  end component;

  signal pSltClk_n   : std_logic;
  signal DevHit      : std_logic;
  signal Dec1FFE     : std_logic;
  signal DecSccA     : std_logic;
  signal DecSccB     : std_logic;

  signal SccBank0    : std_logic_vector(7 downto 0);
  signal SccBank1    : std_logic_vector(7 downto 0);
  signal SccBank2    : std_logic_vector(7 downto 0);
  signal SccBank3    : std_logic_vector(7 downto 0);
  signal SccModeA    : std_logic_vector(7 downto 0);
  signal SccModeB    : std_logic_vector(7 downto 0);

  signal SccRegWe    : std_logic;
  signal SccModWe    : std_logic;
  signal SccWavCe    : std_logic;
  signal SccWavOe    : std_logic;
  signal SccWavWe    : std_logic;
  signal SccWavWx    : std_logic;
  signal SccWavAdr   : std_logic_vector(4 downto 0);
  signal SccWavDat   : std_logic_vector(7 downto 0);

  signal SccAmp      : std_logic_vector(7 downto 0);

-- Multimode card register

  signal CardMDR     : std_logic_vector(7 downto 0);
  signal AddrM0      : std_logic_vector(7 downto 0);
  signal AddrM1      : std_logic_vector(7 downto 0);
  signal AddrM2		 : std_logic_vector(6 downto 0);
  signal AddrFR	     : std_logic_vector(6 downto 0);

  signal R1Mask	     : std_logic_vector(7 downto 0);
  signal R1Addr	     : std_logic_vector(7 downto 0);
  signal R1Reg     : std_logic_vector(7 downto 0);
  signal R1Mult      : std_logic_vector(7 downto 0);
  signal B1MaskR     : std_logic_vector(7 downto 0);
  signal B1AdrD      : std_logic_vector(7 downto 0);

  signal R2Mask	     : std_logic_vector(7 downto 0);
  signal R2Addr	     : std_logic_vector(7 downto 0);
  signal R2Reg     : std_logic_vector(7 downto 0);
  signal R2Mult      : std_logic_vector(7 downto 0);
  signal B2MaskR     : std_logic_vector(7 downto 0);
  signal B2AdrD      : std_logic_vector(7 downto 0);
 
  signal R3Mask	     : std_logic_vector(7 downto 0);
  signal R3Addr	     : std_logic_vector(7 downto 0);
  signal R3Reg     : std_logic_vector(7 downto 0);
  signal R3Mult      : std_logic_vector(7 downto 0);
  signal B3MaskR     : std_logic_vector(7 downto 0);
  signal B3AdrD      : std_logic_vector(7 downto 0);
  
  signal R4Mask	     : std_logic_vector(7 downto 0);
  signal R4Addr	     : std_logic_vector(7 downto 0);
  signal R4Reg     : std_logic_vector(7 downto 0);
  signal R4Mult      : std_logic_vector(7 downto 0);
  signal B4MaskR     : std_logic_vector(7 downto 0);
  signal B4AdrD      : std_logic_vector(7 downto 0);
 
  signal aAddrFR     : std_logic_vector(6 downto 0);
  
  signal aR1Mask	     : std_logic_vector(7 downto 0);
  signal aR1Addr	     : std_logic_vector(7 downto 0);
  signal aR1Reg     : std_logic_vector(7 downto 0);
  signal aR1Mult      : std_logic_vector(7 downto 0);
  signal aB1MaskR     : std_logic_vector(7 downto 0);
  signal aB1AdrD      : std_logic_vector(7 downto 0);

  signal aR2Mask	     : std_logic_vector(7 downto 0);
  signal aR2Addr	     : std_logic_vector(7 downto 0);
  signal aR2Reg     : std_logic_vector(7 downto 0);
  signal aR2Mult      : std_logic_vector(7 downto 0);
  signal aB2MaskR     : std_logic_vector(7 downto 0);
  signal aB2AdrD      : std_logic_vector(7 downto 0);
 
  signal aR3Mask	     : std_logic_vector(7 downto 0);
  signal aR3Addr	     : std_logic_vector(7 downto 0);
  signal aR3Reg     : std_logic_vector(7 downto 0);
  signal aR3Mult      : std_logic_vector(7 downto 0);
  signal aB3MaskR     : std_logic_vector(7 downto 0);
  signal aB3AdrD      : std_logic_vector(7 downto 0);
  
  signal aR4Mask	     : std_logic_vector(7 downto 0);
  signal aR4Addr	     : std_logic_vector(7 downto 0);
  signal aR4Reg     : std_logic_vector(7 downto 0);
  signal aR4Mult      : std_logic_vector(7 downto 0);
  signal aB4MaskR     : std_logic_vector(7 downto 0);
  signal aB4AdrD      : std_logic_vector(7 downto 0);

 
  signal ConfFl		 : std_logic_vector(2 downto 0);
  
  signal DecMDR      : std_logic;
  signal DirFlW      : std_logic; 
  signal Maddr       : std_logic_vector(22 downto 0);
  signal MR1A		 : std_logic_vector(3 downto 0);
  signal MR2A		 : std_logic_vector(3 downto 0);
  signal MR3A		 : std_logic_vector(3 downto 0);
  signal MR4A		 : std_logic_vector(3 downto 0);
  signal pFlOE_nt    : std_logic;
  signal RloadEn     : std_logic;
begin

  ----------------------------------------------------------------
  -- Dummy pin
  ----------------------------------------------------------------
  pSltRsv5  <= '1';
  pSltRsv16 <= '1';

  pSltClk_n <= not pSltClk;

  pSltBdir_n <= '0' when pSltSltsl_n = '0' and pSltRd_n = '0' else '1';

  pFlBYTE_n	<= ConfFl(2);
  pFlRP_n <= ConfFl(1);
  pFlVpp <= ConfFl(0);



  ----------------------------------------------------------------
  -- Slot access control
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n, pSltIorq_n, pSltSltsl_n, pSltRd_n, pSltWr_n)

    variable DevAcs0 : std_logic;
    variable DevAcs1 : std_logic;

  begin

    if ((pSltIorq_n = '0' or pSltSltsl_n = '0') and (pSltRd_n = '0' or pSltWr_n = '0')) then
      DevAcs0 := '1';
    else
      DevAcs0 := '0';
    end if;

    if (DevAcs0 = '1' and DevAcs1 = '0') then
      DevHit <= '1';
    else
      DevHit <= '0';
    end if;

    if (pSltRst_n = '0') then
      DevAcs1 := '0';
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      DevAcs1 := DevAcs0;
    end if;

  end process;

  Dec1FFE <= '1' when pSltAdr(12 downto 1) = "111111111111" 
                      and CardMDR(4) = '1' 
                 else '0';
  DecSccA <= '1' when pSltAdr(15 downto 11) = "10011" and SccModeB(4) = '0' and SccBank2(5 downto 0) = "111111"
                      and CardMDR(4) = '1'
                 else '0';
  DecSccB <= '1' when pSltAdr(15 downto 11) = "10111" and SccModeB(4) = '1' and SccBank3(7) = '1'
                      and CardMDR(4) = '1'
                 else '0';
  
  DecMDR <= '1'  when pSltSltsl_n = '0' and pSltAdr(13 downto 6) = "00111110" and
                      CardMDR(7) = '0' and pSltAdr (15 downto 14) = CardMDR (6 downto 5)
				 else '0';
  RloadEn <= '1' when CardMDR(3) = '0' 
                      or (CardMDR(2) = '0' and pSltAdr(15 downto 0) = "0000000000000000" and pSltM1_n = '0' and pSltRd_n = '0')
                      or (CardMDR(2) = '1' and pSltAdr(15 downto 4) = "010000000000" and pSltRd_n = '0')
                 else '0';
  iFsts	 <= CardMDR(0) when CardMDR(1)  = '1' and pSltRst_n = '1' else ('Z');
  ----------------------------------------------------------------
  -- Conf register 
  ----------------------------------------------------------------
  
  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then
 --     R1Reg <= aR1Reg; R2Reg <= aR2Reg; R3Reg <= aR3Reg; R4Reg <= aR4Reg;
       
         CardMDR   <= "00100011"; -- 7b - disable is conf.regs; 
							   -- 6,5b - addr r.conf=0F80/4F80/8F80/CF80
                               -- 4b - enable SCC, 
                               -- 3b - delayed reconfiguration (bank registers only)
                               -- 2b - select activate bank configurations 0=of start/jmp0/rst0 1= read(400Xh)
                               -- 1b - Fsts enable
                               -- 0b - Fsts = 1 - 1st Start Full Reset , = 0 - Second Reset   
         ConfFl    <= "010";      
         AddrFR    <= "0000000";  -- shift  addr Flash Rom x 64��
         aAddrFR    <= "0000000";
         R1Mult    <= "10000101"; -- 7b - enable page register bank 1
                               -- 6b - 
							   -- 5b - RAM (select RAM or atlernative ROM...)
							   -- 4b - enable write to bank
							   -- 3b - disable bank ( read and write )
							   -- 2b,1b,0b - bank size
							   -- 111 - 64kbyte
							   -- 110 - 32 
                               -- 101 - 16
                               -- 100 - 8
                               -- 011 - 4
                               -- other - disable bank
         aR1Mult    <= "10000101";
         R1Mask    <= "11111000"; -- 0000h-07FFh + |
	     aR1Mask    <= "11111000"; 
         R1Addr    <= "01010000"; -- 5000h         | = 5000h-57FFh
         aR1Addr    <= "01010000";
         R1Reg     <= "00000000"; -- Page 0 (Relative)
         aR1Reg     <= "00000000";
         B1MaskR   <= "00000011"; -- Size "Cartrige" 4 Page ( 4 Page x 16 Kbyte )
	     aB1MaskR   <= "00000011";
         B1AdrD    <= "01000000"; -- Bank Addr 4000h
         aB1AdrD    <= "01000000";
      
         R2Mult    <= "00000000"; -- Disable B2, B3, B4
         aR2Mult    <= "00000000";
         R3Mult    <= "00000000";
         aR3Mult    <= "00000000";
         R4Mult    <= "00000000";
         aR4Mult    <= "00000000";
       
    elsif (pSltClk_n'event and pSltClk_n = '1') then

          -- Mapped I/O port access on 8F80 ( 0F80, 4F80, CF80 ) Cart mode resister write
      if (DecMDR = '1' and pSltWr_n = '0' ) then 
        if (pSltAdr(5 downto 0) = "000000") then CardMDR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "000001") then AddrM0  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "000010") then AddrM1  <= pSltDat ; end if;         
        if (pSltAdr(5 downto 0) = "000011") then AddrM2  <= pSltDat(6 downto 0) ; end if;
--      if (pSltAdr(5 downto 0) = "000100") then DatM0   <= pSltDat ; end if; -- transit
        if (pSltAdr(5 downto 0) = "000101") then aAddrFR  <= pSltDat(6 downto 0) ; end if;
----------------------------------------------------------------------------------------
        if (pSltAdr(5 downto 0) = "000110") then aR1Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "000111") then aR1Addr  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001000") then aR1Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001001") then aR1Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001010") then aB1MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001011") then aB1AdrD  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001100") then aR2Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001101") then aR2Addr  <= pSltDat ; end if; 
        if (pSltAdr(5 downto 0) = "001110") then aR2Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001111") then aR2Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010000") then aB2MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010001") then aB2AdrD  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010010") then aR3Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010011") then aR3Addr  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010100") then aR3Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010101") then aR3Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010110") then aB3MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010111") then aB3AdrD  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011000") then aR4Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011001") then aR4Addr  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011010") then aR4Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011011") then aR4Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011100") then aB4MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011101") then aB4AdrD  <= pSltDat ; end if;
--                                 011110

        if (pSltAdr(5 downto 0) = "011111") then CardMDR <= pSltDat ; end if;
 ---------------------------------------------------------------------------------------       
        if (pSltAdr(5 downto 0) = "100000") then ConfFl  <= pSltDat(2 downto 0); end if;
        
      end if;
 -- delayed reconfiguration
     if RloadEn = '1' then

      AddrFR  <= aAddrFR;
      R1Mask  <= aR1Mask;
      R1Addr  <= aR1Addr;
      R1Reg   <= aR1Reg;
      R1Mult  <= aR1Mult;
      B1MaskR <= aB1MaskR;
      B1AdrD  <= aB1AdrD;

      R2Mask  <= aR2Mask;
      R2Addr  <= aR2Addr;
      R2Reg   <= aR2Reg;
      R2Mult  <= aR2Mult;
      B2MaskR <= aB2MaskR;
      B2AdrD  <= aB2AdrD;

      R3Mask  <= aR3Mask;
      R3Addr  <= aR3Addr;
      R3Reg   <= aR3Reg;
      R3Mult  <= aR3Mult;
      B3MaskR <= aB3MaskR;
      B3AdrD  <= aB3AdrD;
     
      R4Mask  <= aR4Mask;
      R4Addr  <= aR4Addr;
      R4Reg   <= aR4Reg;
      R4Mult  <= aR4Mult;
      B4MaskR <= aB4MaskR;
      B4AdrD  <= aB4AdrD;      
      end if;
    
              -- Mapped I/O port access on R1 Bank resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and R1Mult(7) = '1' and DecMDR = '0'
			                and ( pSltAdr(15) = R1Addr(7) or R1Mask(7) = '0' )
							and ( pSltAdr(14) = R1Addr(6) or R1Mask(6) = '0' )
							and ( pSltAdr(13) = R1Addr(5) or R1Mask(5) = '0' )
							and ( pSltAdr(12) = R1Addr(4) or R1Mask(4) = '0' )
							and ( pSltAdr(11) = R1Addr(3) or R1Mask(3) = '0' )
							and ( pSltAdr(10) = R1Addr(2) or R1Mask(2) = '0' )
							and ( pSltAdr(9)  = R1Addr(1) or R1Mask(1) = '0' )
							and ( pSltAdr(8)  = R1Addr(0) or R1Mask(0) = '0' )
															       )
      then
        R1Reg <= pSltDat; aR1Reg <= pSltDat;
      end if;
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and R2Mult(7) = '1' and DecMDR = '0' 
							and ( pSltAdr(15) = R2Addr(7) or R2Mask(7) = '0' )
							and ( pSltAdr(14) = R2Addr(6) or R2Mask(6) = '0' )
							and ( pSltAdr(13) = R2Addr(5) or R2Mask(5) = '0' )
							and ( pSltAdr(12) = R2Addr(4) or R2Mask(4) = '0' )
							and ( pSltAdr(11) = R2Addr(3) or R2Mask(3) = '0' )
							and ( pSltAdr(10) = R2Addr(2) or R2Mask(2) = '0' )
							and ( pSltAdr(9)  = R2Addr(1) or R2Mask(1) = '0' )
							and ( pSltAdr(8)  = R2Addr(0) or R2Mask(0) = '0' )
															       )
      then
        R2Reg <= pSltDat; aR2Reg <= pSltDat;
      end if;
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and R3Mult(7) = '1' and DecMDR = '0' 
							and ( pSltAdr(15) = R3Addr(7) or R3Mask(7) = '0' )
							and ( pSltAdr(14) = R3Addr(6) or R3Mask(6) = '0' )
							and ( pSltAdr(13) = R3Addr(5) or R3Mask(5) = '0' )
							and ( pSltAdr(12) = R3Addr(4) or R3Mask(4) = '0' )
							and ( pSltAdr(11) = R3Addr(3) or R3Mask(3) = '0' )
							and ( pSltAdr(10) = R3Addr(2) or R3Mask(2) = '0' )
							and ( pSltAdr(9)  = R3Addr(1) or R3Mask(1) = '0' )
							and ( pSltAdr(8)  = R3Addr(0) or R3Mask(0) = '0' )
															       )
      then
        R3Reg <= pSltDat; aR3Reg <= pSltDat;
      end if;
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and R4Mult(7) = '1' and DecMDR = '0' 
							and ( pSltAdr(15) = R4Addr(7) or R4Mask(7) = '0' )
							and ( pSltAdr(14) = R4Addr(6) or R4Mask(6) = '0' )
							and ( pSltAdr(13) = R4Addr(5) or R4Mask(5) = '0' )
							and ( pSltAdr(12) = R4Addr(4) or R4Mask(4) = '0' )
							and ( pSltAdr(11) = R4Addr(3) or R4Mask(3) = '0' )
							and ( pSltAdr(10) = R4Addr(2) or R4Mask(2) = '0' )
							and ( pSltAdr(9)  = R4Addr(1) or R4Mask(1) = '0' )
							and ( pSltAdr(8)  = R4Addr(0) or R4Mask(0) = '0' )
															       )
      then
        R4Reg <= pSltDat; aR4Reg <= pSltDat;
      end if;
       
    end if;

  end process;
  ----------------------------------------------------------------
  -- Flash ROM interface 
  ---------------------------------------------------------------- 
  -- Flash DataWrite
  pFlDat <= pSltDat when pSltSltsl_n = '0' and pSltRd_n = '1' else
            (others => 'Z');
  -- Flash -ChipSelect
  pFlCS_n <= '0' when DecMDR = '1' or (MR1A(3) = '0' and R1Mult(5) = '0') or (MR2A(3) = '0' and R2Mult(5) = '0')
					 		       or (MR3A(3) = '0' and R3Mult(5) = '0') or (MR4A(3) = '0' and R4Mult(5) = '0')
				 else
             '1';
  -- Flash -OutputEnable (-Gate)
  pFlOE_n <= pFlOE_nt;
  pFlOE_nt <= '0' when pSltSltsl_n = '0' and pSltRd_n = '0' and ((DecMDR = '1' and pSltAdr(5 downto 0) = "000100")   	-- DatM0
					 		               or MR1A(3) = '0'  								-- Bank1
					 		               or MR2A(3) = '0' 									-- Bank2
					 		               or MR3A(3) = '0' 									-- Bank3
					 		               or MR4A(3) = '0')   							-- Bank4
				  else
             '1'; 
  -- Flash -Write
  pFlW_n  <= '0' when pSltWr_n = '0' and pSltSltsl_n = '0' and ((DecMDR = '1' and pSltAdr(5 downto 0) = "000100")  	-- DatM0
					 		               or (MR1A(3) = '0' and R1Mult(4) = '1' and DecMDR = '0') 			-- Bank1
					 		               or (MR2A(3) = '0' and R2Mult(4) = '1' and DecMDR = '0')			-- Bank2
					 		               or (MR3A(3) = '0' and R3Mult(4) = '1' and DecMDR = '0') 			-- Bank3
					 		               or (MR4A(3) = '0' and R4Mult(4) = '1' and DecMDR = '0'))					-- Bank4 
			     else
            '1';
            
  pFlAdr(22 downto 0) <= AddrM2(6 downto 0) & AddrM1(7 downto 0) & AddrM0(7 downto 0) 
                         when (DecMDR = '1' and pSltAdr(5 downto 0) = "000100")
			else
			(AddrFR(6 downto 0) + Maddr(22 downto 16)) & Maddr(15 downto 0);
  
            
  Maddr(11 downto 0) <=pSltAdr(11 downto 0);
  MR1A <= "0111" when R1Mult(2 downto 0) = "111" and R1Mult(3) = '0' else -- 64k
          "0110" when R1Mult(2 downto 0) = "110" and R1Mult(3) = '0' and B1AdrD(7) = pSltAdr(15) else -- 32k
          "0101" when R1Mult(2 downto 0) = "101" and R1Mult(3) = '0' and B1AdrD(7 downto 6) = pSltAdr(15 downto 14) else -- 16k
          "0100" when R1Mult(2 downto 0) = "100" and R1Mult(3) = '0' and (B1AdrD(7) = pSltAdr(15) or R1Mult(6) = '0') and B1AdrD(6 downto 5) = pSltAdr(14 downto 13) else -- 8k
          "0011" when R1Mult(2 downto 0) = "011" and R1Mult(3) = '0' and (B1AdrD(7 downto 6) = pSltAdr(15 downto 14) or R1Mult(6) = '0') and B1AdrD(5 downto 4) = pSltAdr(13 downto 12) else -- 4k
     --     "0010" when R1Mult(2 downto 0) = "010" and R1Mult(7) = '1' and B1AdrD(7 downto 3) = pSltAdr(15 downto 11)else
     --     "0001" when R1Mult(2 downto 0) = "001" and R1Mult(7) = '1' and B1AdrD(7 downto 2) = pSltAdr(15 downto 10)else
     --     "0000" when R1Mult(2 downto 0) = "000" and R1Mult(7) = '1' and B1AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;

  MR2A <= "0111" when R2Mult(2 downto 0) = "111" and R2Mult(3) = '0' else
          "0110" when R2Mult(2 downto 0) = "110" and R2Mult(3) = '0' and B2AdrD(7) = pSltAdr(15) else
          "0101" when R2Mult(2 downto 0) = "101" and R2Mult(3) = '0' and B2AdrD(7 downto 6) = pSltAdr(15 downto 14) else
          "0100" when R2Mult(2 downto 0) = "100" and R2Mult(3) = '0' and (B2AdrD(7) = pSltAdr(15) or R2Mult(6) = '0') and B2AdrD(6 downto 5) = pSltAdr(14 downto 13) else
          "0011" when R2Mult(2 downto 0) = "011" and R2Mult(3) = '0' and (B2AdrD(7 downto 6) = pSltAdr(15 downto 14) or R2Mult(6) = '0') and B2AdrD(5 downto 4) = pSltAdr(13 downto 12) else
--          "0010" when R2Mult(2 downto 0) = "010" and R2Mult(7) = '1' and B2AdrD(7 downto 3) = pSltAdr(15 downto 11)else
--          "0001" when R2Mult(2 downto 0) = "001" and R2Mult(7) = '1' and B2AdrD(7 downto 2) = pSltAdr(15 downto 10)else
--          "0000" when R2Mult(2 downto 0) = "000" and R2Mult(7) = '1' and B2AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;
 
  MR3A <= "0111" when R3Mult(2 downto 0) = "111" and R3Mult(3) = '0' else
          "0110" when R3Mult(2 downto 0) = "110" and R3Mult(3) = '0' and B3AdrD(0) = pSltAdr(15) else
          "0101" when R3Mult(2 downto 0) = "101" and R3Mult(3) = '0' and B3AdrD(7 downto 6) = pSltAdr(15 downto 14) else
          "0100" when R3Mult(2 downto 0) = "100" and R3Mult(3) = '0' and (B3AdrD(7) = pSltAdr(15) or R3Mult(6) = '0') and B3AdrD(6 downto 5) = pSltAdr(14 downto 13) else
          "0011" when R3Mult(2 downto 0) = "011" and R3Mult(3) = '0' and (B3AdrD(7 downto 6) = pSltAdr(15 downto 14) or R3Mult(6) = '0') and B3AdrD(5 downto 4) = pSltAdr(13 downto 12) else
--          "0010" when R3Mult(2 downto 0) = "010" and R3Mult(7) = '1' and B3AdrD(7 downto 3) = pSltAdr(15 downto 11)else
--          "0001" when R3Mult(2 downto 0) = "001" and R3Mult(7) = '1' and B3AdrD(7 downto 2) = pSltAdr(15 downto 10)else
--          "0000" when R3Mult(2 downto 0) = "000" and R3Mult(7) = '1' and B3AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;
 
  MR4A <= "0111" when R4Mult(2 downto 0) = "111" and R4Mult(3) = '0' else
          "0110" when R4Mult(2 downto 0) = "110" and R4Mult(3) = '0' and B4AdrD(7) = pSltAdr(15) else
          "0101" when R4Mult(2 downto 0) = "101" and R4Mult(3) = '0' and B4AdrD(7 downto 6) = pSltAdr(15 downto 14) else
          "0100" when R4Mult(2 downto 0) = "100" and R4Mult(3) = '0' and (B4AdrD(7) = pSltAdr(15) or R4Mult(6) = '0') and B4AdrD(6 downto 5) = pSltAdr(14 downto 13) else
          "0011" when R4Mult(2 downto 0) = "011" and R4Mult(3) = '0' and (B4AdrD(7 downto 6) = pSltAdr(15 downto 14) or R4Mult(6) = '0') and B4AdrD(5 downto 4) = pSltAdr(13 downto 12) else
--          "0010" when R4Mult(2 downto 0) = "010" and R4Mult(7) = '1' and B4AdrD(7 downto 3) = pSltAdr(15 downto 11)else
--          "0001" when R4Mult(2 downto 0) = "001" and R4Mult(7) = '1' and B4AdrD(7 downto 2) = pSltAdr(15 downto 10)else
--          "0000" when R4Mult(2 downto 0) = "000" and R4Mult(7) = '1' and B4AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;
                        
  Maddr(22 downto 12) <= (B1MaskR(6 downto 0) and R1Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR1A = "0111" else
                        (B1MaskR and R1Reg) & pSltAdr(14 downto 12) when MR1A = "0110" else
                        "0" & (B1MaskR and R1Reg) & pSltAdr(13 downto 12) when MR1A = "0101" else
                        "00" & (B1MaskR and R1Reg) & pSltAdr(12) when MR1A = "0100" else
                        "000" & (B1MaskR and R1Reg) when MR1A = "0011" else
--                        "0000" & (B1MaskR and R1Reg) & pSltAdr(10 downto 9) when MR1A = "0010" else
--                        "00000" & (B1MaskR and R1Reg) & pSltAdr(9) when MR1A = "0001" else
--                        "000000" & (B1MaskR and R1Reg) when MR1A = "0000" else
                        
                        (B2MaskR(6 downto 0) and R2Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR2A = "0111" else
                        (B2MaskR and R2Reg) & pSltAdr(14 downto 12) when MR2A = "0110" else
                        "0" & (B2MaskR and R2Reg) & pSltAdr(13 downto 12) when MR2A = "0101" else
                        "00" & (B2MaskR and R2Reg) & pSltAdr(12) when MR2A = "0100" else
                        "000" & (B2MaskR and R2Reg) when MR2A = "0011" else
--                        "0000" & (B2MaskR and R2Reg) & pSltAdr(10 downto 9) when MR2A = "0010" else
--                       "00000" & (B2MaskR and R2Reg) & pSltAdr(9) when MR2A = "0001" else
--                        "000000" & (B2MaskR and R2Reg) when MR2A = "0000" else
                        
                        (B3MaskR(6 downto 0) and R3Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR1A = "0111" else
                        (B3MaskR and R3Reg) & pSltAdr(14 downto 12) when MR3A = "0110" else
                        "0" & (B3MaskR and R3Reg) & pSltAdr(13 downto 12) when MR3A = "0101" else
                        "00" & (B3MaskR and R3Reg) & pSltAdr(12) when MR3A = "0100" else
                        "000" & (B3MaskR and R3Reg) when MR3A = "0011" else
--                        "0000" & (B3MaskR and R3Reg) & pSltAdr(10 downto 9) when MR3A = "0010" else
--                        "00000" & (B3MaskR and R3Reg) & pSltAdr(9) when MR3A = "0001" else
--                        "000000" & (B3MaskR and R3Reg) when MR3A = "0000" else
                        
                        (B4MaskR(6 downto 0) and R4Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR4A = "0111" else
                        (B4MaskR and R4Reg) & pSltAdr(14 downto 12) when MR4A = "0110" else
                        "0" & (B4MaskR and R4Reg) & pSltAdr(13 downto 12) when MR4A = "0101" else
                        "00" & (B4MaskR and R4Reg) & pSltAdr(12) when MR4A = "0100" else
                        "000" & (B4MaskR and R4Reg) when MR4A = "0011" -- else
--                        "0000" & (B4MaskR and R4Reg) & pSltAdr(10 downto 9) when MR4A = "0010" else
--                        "00000" & (B4MaskR and R4Reg) & pSltAdr(9) when MR4A = "0001" else
--                        "000000" & (B4MaskR and R4Reg) when MR4A = "0000" 
						;
                        
                        
  -- if(R1Mult(2 downto 0) =  "111") then Maddr(22 downto 8) <= (B1MaskR(6 downto 0) and R1Reg(6 downto 0)) & pSltAdr(15 downto 8);
  -- elsif (R1Mult(2 downto 0) =  "110" and B1AdrD(0) = pSltAdr(15)) then Maddr(22 downto 8) <= (B1MaskR and R1Reg) & pSltAdr(14 downto 8);
  -- elsif (R1Mult(2 downto 0) =  "101" and B1AdrD(1 downto 0) = pSltAdr(15 downto 14)) then Maddr(22 downto 8) <= "0" & (B1MaskR and R1Reg) & pSltAdr(13 downto 8); 
  -- end if;
  
  ----------------------------------------------------------------
  -- SCC register / wave memory access
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then

      SccBank0   <= "00000000";
      SccBank1   <= "00000001";
      SccBank2   <= "00000010";
      SccBank3   <= "00000011";
      SccModeA   <= (others => '0');
      SccModeB   <= (others => '0');

      SccWavWx   <= '0';
      SccWavAdr  <= (others => '0');
      SccWavDat  <= (others => '0');

    elsif (pSltClk_n'event and pSltClk_n = '1') then

          -- Mapped I/O port access on 5000-57FFh ... Bank resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "01010" and
          SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0') then
        SccBank0 <= pSltDat;
      end if;
      -- Mapped I/O port access on 7000-77FFh ... Bank resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "01110" and
          SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0') then
        SccBank1 <= pSltDat;
      end if;
      -- Mapped I/O port access on 9000-97FFh ... Bank resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "10010" and
          SccModeB(4) = '0') then
        SccBank2 <= pSltDat;
      end if;
      -- Mapped I/O port access on B000-B7FFh ... Bank resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "10110" and
          SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0') then
        SccBank3 <= pSltDat;
      end if;

      -- Mapped I/O port access on 7FFE-7FFFh ... Resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 13) = "011" and Dec1FFE = '1' and
          SccModeB(5 downto 4) = "00") then
        SccModeA <= pSltDat;
      end if;

      -- Mapped I/O port access on BFFE-BFFFh ... Resister write
      if (pSltSltsl_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 13) = "101" and Dec1FFE = '1' and
          SccModeA(6) = '0' and SccModeA(4) = '0') then
        SccModeB <= pSltDat;
      end if;

      -- Mapped I/O port access on 9860-987Fh ... Wave memory copy
      if (pSltSltsl_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and pSltAdr(7 downto 5) = "011" and
          DevHit = '1' and SccModeB(4) = '0' and DecSccA = '1') then
        SccWavAdr <= pSltAdr(4 downto 0);
        SccWavDat <= pSltDat;
        SccWavWx  <= '1';
      else
        SccWavWx  <= '0';
      end if;

    end if;

  end process;

  -- Mapped I/O port access on 9800-987Fh / B800-B89Fh ... Wave memory
  SccWavCe <= '1' when pSltSltsl_n = '0' and CardMDR(4) = '1' and DevHit = '1' and SccModeB(4) = '0' and
                       (DecSccA = '1' or DecSccB = '1')
                  else '0';

  -- Mapped I/O port access on 9800-987Fh / B800-B89Fh ... Wave memory
  SccWavOe <= '1' when pSltSltsl_n = '0' and CardMDR(4) = '1' and pSltRd_n = '0' and SccModeB(4) = '0' and
                       ((DecSccA = '1' and pSltAdr(7) = '0') or
                        (DecSccB = '1' and (pSltAdr(7) = '0' or pSltAdr(6 downto 5) = "00")))
                  else '0';

  -- Mapped I/O port access on 9800-987Fh / B800-B89Fh ... Wave memory
  SccWavWe <= '1' when pSltSltsl_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and DevHit = '1' and SccModeB(4) = '0' and
                       ((DecSccA = '1' and pSltAdr(7) = '0') or DecSccB = '1')
                  else '0';

  -- Mapped I/O port access on 9880-988Fh / B8A0-B8AF ... Resister write
  SccRegWe <= '1' when pSltSltsl_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and
                       ((DecSccA = '1' and pSltAdr(7 downto 5) = "100") or
                        (DecSccB = '1' and pSltAdr(7 downto 5) = "101")) and
                       DevHit = '1' and SccModeB(4) = '0'
                  else '0';

  -- Mapped I/O port access on 98C0-98FFh / B8C0-B8DFh ... Resister write
  SccModWe <= '1' when pSltSltsl_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and pSltAdr(7 downto 6) = "11" and
                       (DecSccA = '1' or (pSltAdr(5) = '0' and DecSccB = '1')) and
                       DevHit = '1' and SccModeB(4) = '0'
                  else '0';

  ----------------------------------------------------------------
  -- Connect components
  ----------------------------------------------------------------

  SccCh  : scc_wave
    port map(
      pSltClk_n, pSltRst_n, pSltAdr(7 downto 0), pSltDat, SccAmp,
      SccRegWe, SccModWe, SccWavCe, SccWavOe, SccWavWe, SccWavWx, SccWavAdr, SccWavDat, pFlOE_nt, pFlDat(7 downto 0) 
    );

  ----------------------------------------------------------------
  -- 1 bit D/A  control
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

    variable Amp  : std_logic_vector(7 downto 0);
    variable Acu  : std_logic_vector(8 downto 0);

  begin

    if (pSltRst_n = '0') then

      Amp  := (others => '0');
      Acu  := (others => '0');
      pSltSndL  <= '0';
      pSltSndR  <= '0';
      pSltSound <= '0';

    elsif (pSltClk_n'event and pSltClk_n = '1') then

      Amp  := SccAmp and "11111110";
      Acu  := ('0' & Acu(7 downto 0)) + ('0' & Amp);
      pSltSndL  <= Acu(8);
      pSltSndR  <= Acu(8);
      pSltSound <= Acu(8);

    end if;
  end process;


end RTL;
