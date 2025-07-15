library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_adc_display is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        JA_p        : in  STD_LOGIC;
        JA_n        : in  STD_LOGIC;
        clk_2MHz    : out STD_LOGIC;
        clk_40kHz   : out STD_LOGIC;
        clk_40kHz_s1: out STD_LOGIC;
        clk_40kHz_s2: out STD_LOGIC;
        clk_40kHz_s3: out STD_LOGIC;
        clk_40kHz_s4: out STD_LOGIC;
        clk_40kHz_s5: out STD_LOGIC;
        clk_40kHz_s6: out STD_LOGIC;
        led         : out STD_LOGIC_VECTOR(15 downto 0);
        seg         : out STD_LOGIC_VECTOR(6 downto 0);
        an          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top_adc_display;

architecture Behavioral of top_adc_display is

    component xadc_wiz_0
        PORT (
            di_in        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            daddr_in     : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
            den_in       : IN  STD_LOGIC;
            dwe_in       : IN  STD_LOGIC;
            drdy_out     : OUT STD_LOGIC;
            do_out       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            dclk_in      : IN  STD_LOGIC;
            reset_in     : IN  STD_LOGIC;
            convst_in    : IN  STD_LOGIC;
            vp_in        : IN  STD_LOGIC;
            vn_in        : IN  STD_LOGIC;
            vauxp5       : IN  STD_LOGIC;
            vauxn5       : IN  STD_LOGIC;
            channel_out  : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            eoc_out      : OUT STD_LOGIC;
            alarm_out    : OUT STD_LOGIC;
            eos_out      : OUT STD_LOGIC;
            busy_out     : OUT STD_LOGIC
        );
    end component;

    constant N_2MHz : integer := 50;
    signal count_2MHz : integer range 0 to N_2MHz-1 := 0;
    signal clk2MHz : STD_LOGIC := '0';

    constant N_40kHz : integer := 50;
    signal count_40kHz : integer range 0 to N_40kHz-1 := 0;

    signal clk40kHz,clk40kHz_s1, clk40kHz_s2, clk40kHz_s3  : STD_LOGIC := '0';
    signal clk40kHz_s4, clk40kHz_s5, clk40kHz_s6 : STD_LOGIC := '0';

    -- Variables internas
    signal daddr_in     : STD_LOGIC_VECTOR(6 downto 0);
    signal channel_out  : STD_LOGIC_VECTOR(4 downto 0);
    signal do_out       : STD_LOGIC_VECTOR(15 downto 0);
    signal eoc_out      : STD_LOGIC;
    signal convst       : STD_LOGIC;
    signal analog_p     : STD_LOGIC;
    signal analog_n     : STD_LOGIC;

    signal adc_value    : INTEGER range 0 to 4095 := 0;
    signal delta : integer range 0 to 49 := 0;
    signal grados : integer range 0 to 359 := 0;
    signal digit0, digit1, digit2, digit3 : INTEGER range 0 to 9;
    
    type int_array is array(0 to 6) of integer range 0 to 49;
    signal delay : int_array := (others => 0);
    signal delay_stable : int_array := (others => 0);

    -- Multiplexación
    signal refresh_count : INTEGER range 0 to 50000 := 0;
    signal refresh_state : INTEGER range 0 to 3 := 0;
    signal display_sel   : STD_LOGIC_VECTOR(3 downto 0) := "1110";

    -- Función para convertir entero a vector de 7 segmentos
    function digito(numero: INTEGER) return STD_LOGIC_VECTOR is
        variable salida : STD_LOGIC_VECTOR(6 downto 0);
    begin
        case numero is
            when 0 => salida := "1000000";
            when 1 => salida := "1111001";
            when 2 => salida := "0100100";
            when 3 => salida := "0110000";
            when 4 => salida := "0011001";
            when 5 => salida := "0010010";
            when 6 => salida := "0000010";
            when 7 => salida := "1111000";
            when 8 => salida := "0000000";
            when 9 => salida := "0010000";
            when others => salida := "ZZZZZZZ";
        end case;
        return salida;
    end digito;

begin
    -- Asignaciones básicas
    analog_p <= JA_p;
    analog_n <= JA_n;
    daddr_in <= "00" & channel_out;
    led <= do_out;
    clk_2MHz       <= clk2MHz;
    clk_40kHz      <= clk40kHz;
    clk_40kHz_s1   <= clk40kHz_s1;
    clk_40kHz_s2   <= clk40kHz_s2;
    clk_40kHz_s3   <= clk40kHz_s3;
    clk_40kHz_s4   <= clk40kHz_s4;
    clk_40kHz_s5   <= clk40kHz_s5;
    clk_40kHz_s6   <= clk40kHz_s6;

    -- Instancia del XADC
    XADC_inst : xadc_wiz_0
        PORT MAP (
            di_in       => (others => '0'),
            daddr_in    => daddr_in,
            den_in      => eoc_out,
            dwe_in      => '0',
            drdy_out    => open,
            do_out      => do_out,
            dclk_in     => clk,
            reset_in    => reset,
            convst_in   => convst,
            vp_in       => '0',
            vn_in       => '0',
            vauxp5      => analog_p,
            vauxn5      => analog_n,
            channel_out => channel_out,
            eoc_out     => eoc_out,
            alarm_out   => open,
            eos_out     => open,
            busy_out    => open
        );

    -- Generar señal convst a 200 kHz (100MHz / (2 * 200kHz) = 250)
    process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if count < 249 then
                count := count + 1;
                convst <= '0';
            else
                count := 0;
                convst <= '1';
            end if;
        end if;
    end process;
    
  -- Generador de 2MHz
    process(clk)
    begin
        if rising_edge(clk) then
            count_2MHz <= (count_2MHz + 1) mod 25;
            if count_2MHz = 0 then
                clk2MHz <= not clk2MHz;
            end if;
        end if;
    end process;   
   
    -- Convertir ADC de 12 bits a 4 dígitos decimales
    process(do_out)
        variable val : INTEGER;
    begin
        val := to_integer(unsigned(do_out(15 downto 4)));  -- 12 bits
        adc_value <= val;
        
    --Mapeo del ADC    
    case adc_value is
        when 0    to 157   => delta <= 0;   --7°
        when 158  to 315   => delta <= 1;   --14°
        when 316  to 473   => delta <= 2;
        when 474  to 631   => delta <= 3;
        when 632  to 789   => delta <= 4;
        when 790  to 947   => delta <= 5;
        when 948  to 1105  => delta <= 6;
        when 1106 to 1263  => delta <= 7;
        when 1264 to 1421  => delta <= 8;
        when 1422 to 1579  => delta <= 9;
        when 1580 to 1737  => delta <= 10;
        when 1738 to 1895  => delta <= 11;
        when 1896 to 2053  => delta <= 12;
        when 2054 to 2211  => delta <= 13;
        when 2212 to 2369  => delta <= 14;
        when 2370 to 2527  => delta <= 15;
        when 2528 to 2685  => delta <= 16;
        when 2686 to 2843  => delta <= 17;
        when 2844 to 3001  => delta <= 18;
        when 3002 to 3159  => delta <= 19;
        when 3160 to 3317  => delta <= 20;
        when 3318 to 3475  => delta <= 21;
        when 3476 to 3633  => delta <= 22;
        when 3634 to 3791  => delta <= 23;
        when 3792 to 3949  => delta <= 24;
        when 3950 to 4095  => delta <= 25;
    end case;
        --convertir a grados
        grados <= delta * 72 / 10; -- grados = delta * 7.2        
        digit0 <= grados MOD 10;
        digit1 <= (grados / 10) MOD 10;
        digit2 <= (grados / 100) MOD 10;
        digit3 <= (grados / 1000) MOD 10;
    end process;
    
-- Generar señales de 40 kHz desfasadas desde reloj de 2 MHz
  process(clk2MHz)
  begin
    if rising_edge(clk2MHz) then
      if reset = '1' then
        count_40kHz <= 0;
        clk40kHz <= '0';
      else
        count_40kHz <= (count_40kHz + 1) mod N_40kHz;
        -- Señal base (sin desfase)
        if count_40kHz = 0 then
            clk40kHz <= '1';
        elsif count_40kHz = 25 then
            clk40kHz <= '0';
        end if;

        if count_40kHz = (0 + delta*1) mod 50 then
            clk40kHz_s1 <= '1';
        elsif count_40kHz = (25 + delta*1) mod 50 then
            clk40kHz_s1 <= '0';
        end if;

        if count_40kHz = (0 + delta*2) mod 50 then
            clk40kHz_s2 <= '1';
        elsif count_40kHz = (25 + delta*2) mod 50 then
            clk40kHz_s2 <= '0';
        end if;

        if count_40kHz = (0 + delta*3) mod 50 then
            clk40kHz_s3 <= '1';
        elsif count_40kHz = (25 + delta*3) mod 50 then
            clk40kHz_s3 <= '0';
        end if;

        if count_40kHz = (0 + delta*4) mod 50 then
            clk40kHz_s4 <= '1';
        elsif count_40kHz = (25 + delta*4) mod 50 then
            clk40kHz_s4 <= '0';
        end if;

        if count_40kHz = (0 + delta*5) mod 50 then
            clk40kHz_s5 <= '1';
        elsif count_40kHz = (25 + delta*5) mod 50 then
            clk40kHz_s5 <= '0';
        end if;

        if count_40kHz = (0 + delta*6) mod 50 then
            clk40kHz_s6 <= '1';
        elsif count_40kHz = (25 + delta*6) mod 50 then
            clk40kHz_s6 <= '0';
        end if;
      end if;
    end if;
  end process;

    -- Multiplexación de displays
    process(clk)
    begin
        if rising_edge(clk) then
            if refresh_count < 50000 then   --1ms
                refresh_count <= refresh_count + 1;
            else
                refresh_count <= 0;
                refresh_state <= (refresh_state + 1) MOD 4;
            end if;
        end if;
    end process;

    -- Control de displays y segmentos
    process(refresh_state, display_sel)
    begin
        case refresh_state is
            when 0 =>display_sel <= "1110"; 
            when 1 =>display_sel <= "1101";
            when 2 =>display_sel <= "1011";
            when 3 =>display_sel <= "0111";
            when others =>display_sel <= "1111";
        end case;
        case display_sel is 
            when "1110" => seg <= digito(digit0);
            when "1101" => seg <= digito(digit1);
            when "1011" => seg <= digito(digit2);
            when "0111" => seg <= digito(digit3);
            when others => seg <= "ZZZZZZZ";
         end case;
    end process;
    
        -- Salidas finales
    an <= display_sel;

end Behavioral;
