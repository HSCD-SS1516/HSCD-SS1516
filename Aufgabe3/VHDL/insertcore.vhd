LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY insertcore IS
   GENERIC(RSTDEF: std_logic := '1');
   PORT(rst:   IN  std_logic;  -- reset, RSTDEF active
        clk:   IN  std_logic;  -- clock, rising edge active

        -- handshake signals
        strt:  IN  std_logic;  -- start bit, high active
        done:  OUT std_logic;  -- done bit, high active
        ptr:   IN  std_logic_vector(10 DOWNTO 0); -- pointer to vector
        len:   IN  std_logic_vector( 7 DOWNTO 0); -- length of vector

        WEB:   OUT std_logic; -- Port B Write Enable Output, high active
        ENB:   OUT std_logic; -- Port B RAM Enable, high active
        ADR:   OUT std_logic_vector(10 DOWNTO 0);  -- Port B 11-bit Address Output
        DIB:   IN  std_logic_vector( 7 DOWNTO 0);  -- Port B 8-bit Data Input
        DOB:   OUT std_logic_vector( 7 DOWNTO 0)); -- Port B 8-bit Data Output
END insertcore;

ARCHITECTURE verhalten OF insertcore IS

    CONSTANT MAX_LEN: positive := 256;

    -- Sorting function (reference)
    PROCEDURE sort(a: INOUT string; n: positive) IS
        VARIABLE key: character;
        VARIABLE j: integer;
    BEGIN
        FOR i IN 1 TO n - 1 LOOP        -- S0
            key := a(i);                -- S1
            j := i - 1;
            WHILE j >= 0 LOOP
                IF a(j) <= key THEN     -- S2
                    EXIT;
                END IF;
                a(j + 1) := a(j);       -- S3
                j := j - 1;
            END LOOP;
            a(j + 1) := key;            -- S4
        END LOOP;
    END PROCEDURE;
    
    TYPE tstate IS (IDLE, S0, S0_2, S1, S2, S3, S3_2, S4);
    SIGNAL state: tstate := IDLE;
    SIGNAL key: unsigned(7 DOWNTO 0);
    SIGNAL i: natural;
    SIGNAL j: natural;

BEGIN

    PROCESS (rst, strt, clk) IS
    BEGIN
        IF rst = RSTDEF OR strt = '1' THEN
            IF strt = '1' THEN
                state <= S0;
            ELSE
                state <= IDLE;
            END IF;
            done <= '0';
            WEB  <= '0';
            ENB  <= '0';
            i    <=  1;
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    WEB <= '0';
                    ENB <= '0';
                WHEN S0 =>
                    done <= '0';
                    -- Load a(i) from RAM (available after 2 cycles)
                    WEB <= '0';
                    ENB <= '1';
                    ADR <= conv_std_logic_vector(unsigned(ptr) + i, ADR'LENGTH);
                    state <= S0_2;
                WHEN S0_2 =>
                    -- Load a(j) from RAM (available after 2 cycles)
                    ADR <= conv_std_logic_vector(unsigned(ptr) + i - 1, ADR'LENGTH);
                    state <= S1;
                WHEN S1 =>
                    WEB <= '0';
                    -- key := a(i)
                    key <= unsigned(DIB);
                    j <= i - 1;
                    state <= S2;
                WHEN S2 =>
                    -- IF a(j) <= key THEN go to S4
                    IF unsigned(DIB) <= key THEN
                        --WEB <= '0';
                        --state <= S4;
                        -- NOTE: the algorithm was slightly modified; j is not decremented in the 
                        -- last iteration of the inner WHILE loop
                        -- S4 ----------------------
                        -- a(j) := key
                        WEB <= '1';
                        ADR <= conv_std_logic_vector(unsigned(ptr) + j, ADR'LENGTH);
                        DOB <= conv_std_logic_vector(key, DOB'LENGTH);
                        IF i + 1 < unsigned(len) THEN
                            i <= i + 1;
                            state <= S0;
                        ELSE
                            done <= '1';
                            state <= IDLE;
                        END IF;
                        -- END S4 ------------------
                    ELSE
                        -- a(j + 1) := a(j)
                        WEB <= '1';
                        ADR <= conv_std_logic_vector(unsigned(ptr) + j + 1, ADR'LENGTH);
                        DOB <= DIB;
                        IF j >= 1 THEN
                            j <= j - 1;
                            state <= S3;
                        ELSE
                            state <= S4;
                        END IF;
                    END IF;
                WHEN S3 =>
                    -- Load a(j) from RAM (available after 2 cycles)
                    WEB <= '0';
                    ADR <= conv_std_logic_vector(unsigned(ptr) + j, ADR'LENGTH);
                    state <= S3_2;
                WHEN S3_2 =>
                    state <= S2;
                WHEN S4 =>
                    -- NOTE: the algorithm was slightly modified; j is not decremented in the 
                    -- last iteration of the inner WHILE loop
                    -- a(j) := key
                    WEB <= '1';
                    ADR <= conv_std_logic_vector(unsigned(ptr) + j, ADR'LENGTH);
                    DOB <= conv_std_logic_vector(key, DOB'LENGTH);
                    IF i + 1 < unsigned(len) THEN
                        i <= i + 1;
                        state <= S0;
                    ELSE
                        done <= '1';
                        state <= IDLE;
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

END verhalten;