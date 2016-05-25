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
    
    TYPE tstate IS (IDLE, S0, S1, S2, S3, S4);
    SIGNAL state: tstate := IDLE;
    SIGNAL key: character;
    SIGNAL i: integer;
    SIGNAL j: integer;
    SIGNAL data_j: character;

BEGIN

    PROCESS (rst, clk) IS
    BEGIN
        IF rst = RSTDEF OR (rising_edge(clk) AND strt = '1') THEN
            IF strt = '1' THEN
                state := S0;
            ELSE
                state := IDLE;
            END IF;
            done <= '0';
            WEB  <= '0';
            ENB  <= '0';
            i    <=  0;
            j    <=  0;
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                WHEN S0 =>
                    -- Load a(i) from RAM
                    WEB <= '0';
                    ENB <= '1';
                    ADR <= ...;
                WHEN S1 =>
                    -- key := a(i)
                    
                WHEN S2 =>
                WHEN S3 =>
                WHEN S4 =>
            END CASE;
        END IF;
    END PROCESS;

END verhalten;