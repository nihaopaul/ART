// Ripped out from the NetUSB 8051 uC source.

#ifndef cc1100_driver_h
#define cc1100_driver_h

//--------------------------------------------------------------
//<RF-Configuration-Register values (ordered by register number)
#define IOCFG2        0x0B//0x07       
#define IOCFG1        0x46 //?     
#define IOCFG0        0x06//0x29       
#define FIFOTHR       0x07 //?   
#define SYNC1         0xd3 //?       
#define SYNC0         0x91 //?       
#define PKTLEN        0xff      
#define PKTCTRL1      0x04      
#define PKTCTRL0      0x05       
#define ADDR          0x00 // broadcast!           
#define CHANNR        0x00     
#define FSCTRL1       0x08       
#define FSCTRL0       0x00       
#define FREQ2         0x10
#define FREQ1         0xa7       
#define FREQ0         0x62   
#define MDMCFG4       0x5b//0x7b       
#define MDMCFG3       0xf8//0x83  
#define MDMCFG2       0x03       
#define MDMCFG1       0x22       
#define MDMCFG0       0xf8       
#define DEVIATN       0x47       
#define MCSM2         0x07  // ?      
#define MCSM1         0x3f  // ?     
#define MCSM0         0x18        
#define FOCCFG        0x1d       
#define BSCFG         0x1c       
#define AGCCTRL2      0xc7    
#define AGCCTRL1      0x00     
#define AGCCTRL0      0xb2      
#define WOREVT1       0x87    
#define WOREVT0       0x6b   
#define WORCTRL       0x71      
#define FREND1        0xb6      
#define FREND0        0x10       
#define FSCAL3        0xea    
#define FSCAL2        0x2a      
#define FSCAL1        0x00       
#define FSCAL0        0x1f     

#define FSTEST        0x59    

#define TEST2         0x81      
#define TEST1         0x35       
#define TEST0         0x0b    

byte cc1100regcfg[39]={
IOCFG2,IOCFG1,IOCFG0,FIFOTHR,SYNC1,SYNC0,PKTLEN,PKTCTRL1,PKTCTRL0,ADDR,CHANNR,FSCTRL1,FSCTRL0,
FREQ2,FREQ1,FREQ0,MDMCFG4,MDMCFG3,MDMCFG2,MDMCFG1,MDMCFG0,DEVIATN,MCSM2,MCSM1,MCSM0,FOCCFG,BSCFG,
AGCCTRL2,AGCCTRL1,AGCCTRL0,WOREVT1,WOREVT0,WORCTRL,FREND1,FREND0,FSCAL3,FSCAL2,FSCAL1,FSCAL0};

//-----------------------------------------------------------
// Register addresses
#define ADDR_IOCFG2      0x00         
#define ADDR_IOCFG1      0x01         
#define ADDR_IOCFG0      0x02         
#define ADDR_FIFOTHR     0x03         
#define ADDR_SYNC1       0x04         
#define ADDR_SYNC0       0x05         
#define ADDR_PKTLEN      0x06         
#define ADDR_PKTCTRL1    0x07         
#define ADDR_PKTCTRL0    0x08         
#define ADDR_ADDR        0x09         
#define ADDR_CHANNR      0x0a         
#define ADDR_FSCTRL1     0x0b         
#define ADDR_FSCTRL0     0x0c         
#define ADDR_FREQ2       0x0d         
#define ADDR_FREQ1       0x0e         
#define ADDR_FREQ0       0x0f         
#define ADDR_MDMCFG4     0x10         
#define ADDR_MDMCFG3     0x11         
#define ADDR_MDMCFG2     0x12        
#define ADDR_MDMCFG1     0x13        
#define ADDR_MDMCFG0     0x14       
#define ADDR_DEVIATN     0x15       
#define ADDR_MCSM2       0x16        
#define ADDR_MCSM1       0x17         
#define ADDR_MCSM0       0x18        
#define ADDR_FOCCFG      0x19         
#define ADDR_BSCFG       0x1a        
#define ADDR_AGCCTRL2    0x1b        
#define ADDR_AGCCTRL1    0x1c         
#define ADDR_AGCCTRL0    0x1d        
#define ADDR_WOREVT1     0x1e        
#define ADDR_WOREVT0     0x1f         
#define ADDR_WORCTRL     0x20       
#define ADDR_FREND1      0x21       
#define ADDR_FREND0      0x22        
#define ADDR_FSCAL3      0x23        
#define ADDR_FSCAL2      0x24         
#define ADDR_FSCAL1      0x25         
#define ADDR_FSCAL0      0x26         
#define ADDR_RCCTRL1     0x27
#define ADDR_RCCTRL0     0x28 
#define ADDR_FSTEST      0x29         
#define ADDR_FSTEST       0x29        // Frequency synthesizer calibration control
#define ADDR_PTEST        0x2A        // Production test
#define ADDR_AGCTEST      0x2B        // AGC test
#define ADDR_TEST2        0x2C        // Various test settings
#define ADDR_TEST1        0x2D        // Various test settings
#define ADDR_TEST0        0x2E        // Various test settings

#define ADDR_TEST2       0x2c        
#define ADDR_TEST1       0x2d         
#define ADDR_TEST0       0x2e   

#define         WRITE_BURST         0x40		
#define 	READ_SINGLE         0x80		
#define 	READ_BURST          0xC0		
#define 	BYTES_IN_RXFIFO     0x7F  		
#define 	CRC_OK              0x80 

// Strobe commands
#define CCxxx0_SRES         0x30        // Reset chip.
#define CCxxx0_SFSTXON      0x31        // Enable and calibrate frequency synthesizer (if MCSM0.FS_AUTOCAL=1).
                                        // If in RX/TX: Go to a wait state where only the synthesizer is
                                        // running (for quick RX / TX turnaround).
#define CCxxx0_SXOFF        0x32        // Turn off crystal oscillator.
#define CCxxx0_SCAL         0x33        // Calibrate frequency synthesizer and turn it off
                                        // (enables quick start).
#define CCxxx0_SRX          0x34        // Enable RX. Perform calibration first if coming from IDLE and
                                        // MCSM0.FS_AUTOCAL=1.
#define CCxxx0_STX          0x35        // In IDLE state: Enable TX. Perform calibration first if
                                        // MCSM0.FS_AUTOCAL=1. If in RX state and CCA is enabled:
                                        // Only go to TX if channel is clear.
#define CCxxx0_SIDLE        0x36        // Exit RX / TX, turn off frequency synthesizer and exit
                                        // Wake-On-Radio mode if applicable.
#define CCxxx0_SAFC         0x37        // Perform AFC adjustment of the frequency synthesizer
#define CCxxx0_SWOR         0x38        // Start automatic RX polling sequence (Wake-on-Radio)
#define CCxxx0_SPWD         0x39        // Enter power down mode when CSn goes high.
#define CCxxx0_SFRX         0x3A        // Flush the RX FIFO buffer.
#define CCxxx0_SFTX         0x3B        // Flush the TX FIFO buffer.
#define CCxxx0_SWORRST      0x3C        // Reset real time clock.
#define CCxxx0_SNOP         0x3D        // No operation. May be used to pad strobe commands to two
                                        // INT8Us for simpler software.
#define CCxxx0_PARTNUM      0x30
#define CCxxx0_VERSION      0x31
#define CCxxx0_FREQEST      0x32
#define CCxxx0_LQI          0x33
#define CCxxx0_RSSI         0x34
#define CCxxx0_MARCSTATE    0x35
#define CCxxx0_WORTIME1     0x36
#define CCxxx0_WORTIME0     0x37
#define CCxxx0_PKTSTATUS    0x38
#define CCxxx0_VCO_VC_DAC   0x39
#define CCxxx0_TXBYTES      0x3A
#define CCxxx0_RXBYTES      0x3B

#define CCxxx0_PATABLE      0x3E
#define CCxxx0_TXFIFO       0x3F
#define CCxxx0_RXFIFO       0x3F

const byte PA_TABLE[8] = {0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0};   //10dBm

#endif  //cc1100_driver_h

		
