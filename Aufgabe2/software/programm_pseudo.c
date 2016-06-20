
void comm_receive() {
    switch (RXDSTATE) {
        case RXDIDLE:
            if (input(COM_Port) & IOR == 0) {
                RXDSTATE = RXDSTART;
                RXDCNTR = 0x08;
            }
            break;
        case RXDSTART:
            if (--RXDCNTR == 0) {
                if (input(COM_Port) & IOR == 0) {
                    RXDSTATE = RXDWORK;
                    RXDCNTR = 0x10;
                    SAVEDBITS = 0x08;
                    READBYTE = 0x00;
                } else {
                    RXDSTATE = RXDIDLE;
                }
            }
            break;
        case RXDWORK:
            if (--RXDCNTR == 0) {
                RXDCNTR = 0x10;
                READBYTE = (READBYTE << 1) | (input(COM_Port) & IOR);
                if (--SAVEDBITS == 0) {
                    BYTECNT_RXD++;
                    RXDSTATE = RXDIDLE;
                    if (char_check(READBYTE)) {
                        VALIDBYTES++;
                        
                        store_char(READBYTE, ADDR_RXD++);
                    }
                    if (BYTECNT_RXD == BLOCKLEN) {
                        AVAILABLE_BYTES += VALIDBYTES;
                        VALIDBYTES = 0;
                        BYTECNT_RXD = 0;
                    }
                }
            }
            break;
    }
}

void comm_send() {
    switch (TXDSTATE) {
        case TXDIDLE:
            output(COM_Port, 0x01);
            if (AVAILABLE_BYTES != 0) {
                TXDSTATE = TXDSTART;
                TXDCNTR = 0x10;
                BYTECNT_TXD = AVAILABLE_BYTES;
                ADDR_TXD = ADDR_RXD;
            }
            break;
        case TXDSTART:
            output(COM_Port, 0x00);
            if (--TXDCNTR == 0) {
                TXDCNTR = 0x10;
                SENTBITS = 0x08;
                SENDBUF = read_char(ADDR_TXD + BYTECNT_TXD);
                TXDSTATE = TXDWORK;
            }
            break;
        case TXDWORK:
            output(COM_Port, SENDBUF);
            if (--TXDCNTR == 0) {
                SENDBUF = SENDBUF << 1;
                TXDCNTR = 0x10;
                if (--SENTBITS) {
                    TXDSTATE = TXDSTOP;
                }
            }
            break;
        case TXDSTOP:
            output(COM_Port, 0x01);
            if (--TXDCNTR == 0) {
                TXDCNTR = 0x10;
                AVAILABLE_BYTES--;
                if (--BYTECNT_TXD == 0) {
                    TXDSTATE = TXDIDLE;
                } else {
                    TXDSTATE = TXDSTART;
                }
            }
            break;
    }
}
