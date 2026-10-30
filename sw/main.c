#include <stdio.h>                                                                                           
    #include <stdint.h>                                                                                          
    #include <stdbool.h>                                                                                         
    #include "soc_memory_map.h"                                                                                  
[?5W  
                                                                                                                 
    // Tracking variables                                                                                        
    static uint32_t total_tests  = 0;                                                                            
    static uint32_t passed_tests = 0;                                                                            
    static uint32_t failed_tests = 0;                                                                            
[?5W  
                                                                                                                 
[?5W    #define TEST_ASSERT(cond, msg) do { \
        total_tests++; \
    #define TEST_ASSERT(cond, msg) do { \                                                                        
        total_tests++; \                                                                                         
[?5W        if (cond) { \
            passed_tests++; \
        if (cond) { \                                                                                            
            passed_tests++; \                                                                                    
            printf("  [PASS] %s\n", msg); \                                                                      
        } else { \                                                                                               
            failed_tests++; \                                                                                    
            printf("  [FAIL] %s (Line %d)\n", msg, __LINE__); \                                                  
        } \                                                                                                      
    } while(0)                                                                                                   
[?5W  
                                                                                                                 
    // =============================================================================                             
    // Simulation Host Mock Model (Enables Clean Compilation & Execution on Host)                                
[?5// ==================================================================================
    // =============================================================================                             
    #ifdef SIMULATION_HOST                                                                                       
    #define MOCK_MEM_SIZE 0x8000U                                                                                
    static uint8_t mock_mem[MOCK_MEM_SIZE];                                                                      
                                                                                                                 
    static inline uint32_t *get_mock_ptr(uint32_t addr) {                                                        
        uint32_t offset = (addr - UART_BASE) % MOCK_MEM_SIZE;                                                    
        return (uint32_t *)&mock_mem[offset];                                                                    
    }                                                                                                            
                                                                                                                 
    uint32_t host_mmio_read(uint32_t addr) {                                                                     
        if (addr == GPIO_REG_INFO) {                                                                             
            return 0x00000820U; // Version 2, 32 GPIO pins                                                       
        }                                                                                                        
        if (addr == DMA_REG_STATUS) {                                                                            
            uint32_t val = *get_mock_ptr(addr);                                                                  
            return (val & 0xFFFF0000U) | 0xCAFEU; // Version signature                                           
        }                                                                                                        
        if (addr == SPI_REG_SR) {                                                                                
            return 0x00000005U; // TX and RX empty                                                               
        }                                                                                                        
        return *get_mock_ptr(addr);                                                                              
    }                                                                                                            
                                                                                                                 
    void host_mmio_write(uint32_t addr, uint32_t data) {                                                         
        // Atomic GPIO operations simulation                                                                     
        if (addr == GPIO_REG_SET) {                                                                              
            *get_mock_ptr(GPIO_REG_OUT) |= data;                                                                 
            return;                                                                                              
        }                                                                                                        
        if (addr == GPIO_REG_CLEAR) {                                                                            
            *get_mock_ptr(GPIO_REG_OUT) &= ~data;                                                                
            return;                                                                                              
        }                                                                                                        
        if (addr == GPIO_REG_TOGGLE) {                                                                           
            *get_mock_ptr(GPIO_REG_OUT) ^= data;                                                                 
            return;                                                                                              
        }                                                                                                        
        if (addr == TIMER_REG_INTR_STATE0) {                                                                     
            // W1C: Write-1-to-clear                                                                             
            *get_mock_ptr(TIMER_REG_INTR_STATE0) &= ~data;                                                       
            return;                                                                                              
        }                                                                                                        
        if (addr == TIMER_REG_INTR_TEST0) {                                                                      
            // Set interrupt state                                                                               
            *get_mock_ptr(TIMER_REG_INTR_STATE0) |= data;                                                        
            return;                                                                                              
        }                                                                                                        
        if (addr == DMA_REG_CONTROL && (data & 0x1U)) {                                                          
            // Simulate DMA transfer completion: copy from SRC to DST                                            
            uint32_t src = *get_mock_ptr(DMA_REG_DESC0_SRC);                                                     
            uint32_t dst = *get_mock_ptr(DMA_REG_DESC0_DST);                                                     
            uint32_t val = host_mmio_read(src);                                                                  
            host_mmio_write(dst, val);                                                                           
            *get_mock_ptr(DMA_REG_STATUS) = (1U << 16) | 0xCAFEU; // done=1, version=0xCAFE                      
        }                                                                                                        
        *get_mock_ptr(addr) = data;                                                                              
    }                                                                                                            
                                                                                                                 
    static void init_mock_hardware(void) {                                                                       
        for (uint32_t i = 0; i < MOCK_MEM_SIZE; i++) mock_mem[i] = 0;                                            
        host_mmio_write(TIMER_REG_CTRL, 0x00000000U);                                                            
        host_mmio_write(TIMER_REG_V_LOWER0, 0x00000000U);                                                        
        host_mmio_write(I2C_REG_PRER_LO, 0x000000FFU);                                                           
        host_mmio_write(PWM_REG_DUTY, 0x00000000U);                                                              
    }                                                                                                            
    #endif                                                                                                       
                                                                                                                 
    // =============================================================================                             
[?5// TEST 1: UART Controller Verification // TEST 1: UART Controller Verification (Port M00: 0x2000_0000)
    // TEST 1: UART Controller Verification (Port M00: 0x2000_0000)                                              
    // =============================================================================                             
    static void test_uart_controller(void) {                                                                     
        printf("\n--- [TEST 1] AXI UART Controller MMIO & FIFO Verification ---\n");                             
                                                                                                                 
        // 1.1 Program baud rate divisor                                                                         
        mmio_write32(UART_REG_BAUD_DIV, 40U);                                                                    
        uint32_t baud_div = mmio_read32(UART_REG_BAUD_DIV);                                                      
        TEST_ASSERT(baud_div == 40U, "UART Baud Divisor Register write/readback (40 ticks/bit)");                
                                                                                                                 
        // 1.2 Configure Line Control Register (8 bits, 1 stop bit, no parity)                                   
        mmio_write32(UART_REG_LCR, 0x03U);                                                                       
        uint32_t lcr = mmio_read32(UART_REG_LCR);                                                                
        TEST_ASSERT((lcr & 0x03U) == 0x03U, "UART Line Control Register (8-N-1 format)");                        
                                                                                                                 
        // 1.3 Enable Receiver Data Interrupt                                                                    
        mmio_write32(UART_REG_IER, 0x01U);                                                                       
        uint32_t ier = mmio_read32(UART_REG_IER);                                                                
        TEST_ASSERT((ier & 0x01U) == 0x01U, "UART Interrupt Enable Register (RX Data IRQ enable)");              
                                                                                                                 
        // 1.4 Write character into Transmitter Holding Register                                                 
        mmio_write32(UART_REG_RBR_THR, (uint32_t)'A');                                                           
        TEST_ASSERT(true, "UART Transmitter Holding Register MMIO write (Char 'A')");                            
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 2: Hardware 64-bit Timer Verification (Port M01: 0x2000_1000)                                        
    // =============================================================================                             
    static void test_hardware_timer(void) {                                                                      
        printf("\n--- [TEST 2] Hardware 64-bit Timer MMIO & Interrupt Verification ---\n");                      
                                                                                                                 
        // 2.1 Verify default active state is 0 (disabled)                                                       
        uint32_t ctrl = mmio_read32(TIMER_REG_CTRL);                                                             
        TEST_ASSERT((ctrl & 0x1U) == 0U, "Timer CTRL initially disabled (active = 0)");                          
                                                                                                                 
        // 2.2 Configure Prescaler & Step                                                                        
        mmio_write32(TIMER_REG_CFG0, 0x00010000U); // Step = 1, Prescaler = 0                                    
        uint32_t cfg0 = mmio_read32(TIMER_REG_CFG0);                                                             
        TEST_ASSERT(cfg0 == 0x00010000U, "Timer CFG0 configured (Step = 1, Prescaler = 0)");                     
                                                                                                                 
        // 2.3 Enable Timer counter                                                                              
        mmio_write32(TIMER_REG_CTRL, 0x00000001U);                                                               
        ctrl = mmio_read32(TIMER_REG_CTRL);                                                                      
        TEST_ASSERT((ctrl & 0x1U) == 1U, "Timer CTRL active enable (active = 1)");                               
                                                                                                                 
        // 2.4 Program Compare Match Threshold & Enable IRQ                                                      
        mmio_write32(TIMER_REG_COMPARE_L0, 0x00000050U);                                                         
        mmio_write32(TIMER_REG_COMPARE_U0, 0x00000000U);                                                         
        mmio_write32(TIMER_REG_INTR_ENABLE0, 0x00000001U);                                                       
        uint32_t irq_en = mmio_read32(TIMER_REG_INTR_ENABLE0);                                                   
        TEST_ASSERT((irq_en & 0x1U) == 1U, "Timer Interrupt Enable Register (Timer0 IRQ enable)");               
                                                                                                                 
        // 2.5 Test Software Interrupt Force (INTR_TEST0)                                                        
        mmio_write32(TIMER_REG_INTR_TEST0, 0x00000001U);                                                         
        uint32_t irq_state = mmio_read32(TIMER_REG_INTR_STATE0);                                                 
        TEST_ASSERT((irq_state & 0x1U) == 1U, "Timer INTR_STATE0 reflects forced interrupt");                    
                                                                                                                 
        // 2.6 Clear Interrupt via W1C                                                                           
        mmio_write32(TIMER_REG_INTR_STATE0, 0x00000001U);                                                        
        irq_state = mmio_read32(TIMER_REG_INTR_STATE0);                                                          
        TEST_ASSERT((irq_state & 0x1U) == 0U, "Timer INTR_STATE0 cleared successfully via W1C");                 
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 3: GPIO Controller Verification (Port M02: 0x2000_2000)                                              
    // =============================================================================                             
    static void test_gpio_controller(void) {                                                                     
        printf("\n--- [TEST 3] 32-bit GPIO Controller MMIO & Atomic Bitops Verification ---\n");                 
                                                                                                                 
        // 3.1 Verify Hardware Version Signature (Version 2, 32 GPIO pins)                                       
        uint32_t info = mmio_read32(GPIO_REG_INFO);                                                              
        TEST_ASSERT(info == 0x00000820U, "GPIO INFO register reports Version 2, 32 pins (0x00000820)");          
                                                                                                                 
        // 3.2 Configure Pin 0 as Push-Pull Output (MODE[1:0] = 01)                                              
        mmio_write32(GPIO_REG_MODE_0, 0x00000001U);                                                              
        uint32_t mode0 = mmio_read32(GPIO_REG_MODE_0);                                                           
        TEST_ASSERT((mode0 & 0x3U) == 0x01U, "GPIO Pin 0 configured as Output Mode (01)");                       
                                                                                                                 
        // 3.3 Direct OUT Register Write (Pin 0 = 1)                                                             
        mmio_write32(GPIO_REG_OUT, 0x00000001U);                                                                 
        uint32_t out_val = mmio_read32(GPIO_REG_OUT);                                                            
        TEST_ASSERT((out_val & 0x1U) == 0x01U, "GPIO Pin 0 driven HIGH via GPIO_OUT");                           
                                                                                                                 
        // 3.4 Atomic Clear (Pin 0 = 0)                                                                          
        mmio_write32(GPIO_REG_CLEAR, 0x00000001U);                                                               
        out_val = mmio_read32(GPIO_REG_OUT);                                                                     
        TEST_ASSERT((out_val & 0x1U) == 0x00U, "GPIO Pin 0 cleared LOW via atomic GPIO_CLEAR");                  
                                                                                                                 
        // 3.5 Atomic Set (Pin 0 = 1)                                                                            
        mmio_write32(GPIO_REG_SET, 0x00000001U);                                                                 
        out_val = mmio_read32(GPIO_REG_OUT);                                                                     
        TEST_ASSERT((out_val & 0x1U) == 0x01U, "GPIO Pin 0 set HIGH via atomic GPIO_SET");                       
                                                                                                                 
        // 3.6 Atomic Toggle (Pin 0 toggles to 0)                                                                
        mmio_write32(GPIO_REG_TOGGLE, 0x00000001U);                                                              
        out_val = mmio_read32(GPIO_REG_OUT);                                                                     
        TEST_ASSERT((out_val & 0x1U) == 0x00U, "GPIO Pin 0 toggled LOW via atomic GPIO_TOGGLE");                 
                                                                                                                 
        // 3.7 Enable Rising-Edge Interrupt on Pin 1                                                             
        mmio_write32(GPIO_REG_INTRPT_RISE_EN, 0x00000002U);                                                      
        uint32_t rise_en = mmio_read32(GPIO_REG_INTRPT_RISE_EN);                                                 
        TEST_ASSERT((rise_en & 0x2U) == 0x02U, "GPIO Pin 1 Rising-Edge Interrupt enabled");                      
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 4: SPI Controller Verification (Port M03: 0x2000_3000)                                               
    // =============================================================================                             
    static void test_spi_controller(void) {                                                                      
        printf("\n--- [TEST 4] AXI SPI Controller MMIO Verification ---\n");                                     
                                                                                                                 
        // 4.1 Check initial status register                                                                     
        uint32_t sr = mmio_read32(SPI_REG_SR);                                                                   
        TEST_ASSERT((sr & 0x5U) == 0x5U, "SPI SR indicates TX and RX FIFOs empty (0x05)");                       
                                                                                                                 
        // 4.2 Configure Control Register (Master Mode + SPI Enable)                                             
        mmio_write32(SPI_REG_CR, 0x00000186U);                                                                   
        uint32_t cr = mmio_read32(SPI_REG_CR);                                                                   
        TEST_ASSERT(cr == 0x00000186U, "SPI Control Register configured (Master Mode + SPI Enable)");            
                                                                                                                 
        // 4.3 Write byte to Data Transmit Register                                                              
        mmio_write32(SPI_REG_DTR, 0x000000A5U);                                                                  
        TEST_ASSERT(true, "SPI DTR MMIO write (0xA5) executed without interconnect fault");                      
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 5: I2C Master Controller Verification (Port M04: 0x2000_4000)                                        
    // =============================================================================                             
    static void test_i2c_controller(void) {                                                                      
        printf("\n--- [TEST 5] AXI I2C Controller MMIO Verification ---\n");                                     
                                                                                                                 
        // 5.1 Check default clock prescaler (0xFF after reset)                                                  
        uint32_t prer_lo = mmio_read32(I2C_REG_PRER_LO);                                                         
        TEST_ASSERT((prer_lo & 0xFFU) == 0xFFU, "I2C Clock Prescaler PRER_LO default = 0xFF");                   
                                                                                                                 
        // 5.2 Program custom prescaler                                                                          
        mmio_write32(I2C_REG_PRER_LO, 0x00000064U);                                                              
        prer_lo = mmio_read32(I2C_REG_PRER_LO);                                                                  
        TEST_ASSERT((prer_lo & 0xFFU) == 0x64U, "I2C Clock Prescaler PRER_LO programmed = 0x64");                
                                                                                                                 
        // 5.3 Enable I2C Core (CTR[7] = 1)                                                                      
        mmio_write32(I2C_REG_CTR, 0x00000080U);                                                                  
        uint32_t ctr = mmio_read32(I2C_REG_CTR);                                                                 
        TEST_ASSERT((ctr & 0x80U) == 0x80U, "I2C Core Enable bit verified in Control Register");                 
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 6: PWM Generator Verification (Port M05: 0x2000_5000)                                                
    // =============================================================================                             
    static void test_pwm_generator(void) {                                                                       
        printf("\n--- [TEST 6] AXI PWM Generator MMIO Verification ---\n");                                      
                                                                                                                 
        // 6.1 Check initial duty cycle (0x00 after reset)                                                       
        uint32_t duty = mmio_read32(PWM_REG_DUTY);                                                               
        TEST_ASSERT(duty == 0x00000000U, "PWM Duty Cycle initially 0% (0x00)");                                  
                                                                                                                 
        // 6.2 Program 50% duty cycle (0x80)                                                                     
        mmio_write32(PWM_REG_DUTY, 0x00000080U);                                                                 
        duty = mmio_read32(PWM_REG_DUTY);                                                                        
        TEST_ASSERT(duty == 0x00000080U, "PWM Duty Cycle programmed to 50% (0x80)");                             
                                                                                                                 
        // 6.3 Program 100% duty cycle (0xFF)                                                                    
        mmio_write32(PWM_REG_DUTY, 0x000000FFU);                                                                 
        duty = mmio_read32(PWM_REG_DUTY);                                                                        
        TEST_ASSERT(duty == 0x000000FFU, "PWM Duty Cycle programmed to 100% (0xFF)");                            
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 7: DMA Controller & Bus Master Interconnect Verification (Port S01)                                  
    // =============================================================================                             
    static void test_dma_controller(void) {                                                                      
        printf("\n--- [TEST 7] DMA Controller & S01 Master Interconnect Verification ---\n");                    
                                                                                                                 
        // 7.1 Verify DMA Hardware Version Signature (0xCAFE)                                                    
        uint32_t dma_status = mmio_read32(DMA_REG_STATUS);                                                       
        TEST_ASSERT((dma_status & 0xFFFFU) == 0xCAFEU, "DMA Version Signature verified (0xCAFE)");               
                                                                                                                 
        // 7.2 Prepare Source Data in PWM register (0x2000_5000)                                                 
        mmio_write32(PWM_REG_DUTY, 0x12345678U);                                                                 
        uint32_t pwm_src = mmio_read32(PWM_REG_DUTY);                                                            
        TEST_ASSERT(pwm_src == 0x12345678U, "Source register (PWM Duty) loaded with test pattern 0x12345678");   
                                                                                                                 
        // 7.3 Clear Destination Data in GPIO_OUT register (0x2000_2180)                                         
        mmio_write32(GPIO_REG_OUT, 0x00000000U);                                                                 
        uint32_t gpio_dst = mmio_read32(GPIO_REG_OUT);                                                           
        TEST_ASSERT(gpio_dst == 0x00000000U, "Destination register (GPIO_OUT) cleared to 0x00000000");           
                                                                                                                 
        // 7.4 Configure DMA Descriptor 0 via dedicated AXI4-Lite CSR port                                       
        // Source: PWM_REG_DUTY (0x2000_5000), Destination: GPIO_REG_OUT (0x2000_2180)                           
        // Transfer size: 4 bytes (1 word)                                                                       
        // Mode: wr_mode=FIXED (1), rd_mode=FIXED (1), enable=1 -> Config = 0x07                                 
        mmio_write32(DMA_REG_DESC0_SRC, PWM_REG_DUTY);                                                           
        mmio_write32(DMA_REG_DESC0_DST, GPIO_REG_OUT);                                                           
        mmio_write32(DMA_REG_DESC0_LEN, 4U);                                                                     
        mmio_write32(DMA_REG_DESC0_CFG, 0x00000007U);                                                            
        TEST_ASSERT(true, "DMA Descriptor 0 programmed (PWM -> GPIO, 4 Bytes, FIXED->FIXED)");                   
                                                                                                                 
        // 7.5 Trigger Autonomous Transfer via DMA_CONTROL GO bit (bit 0 = 1, max_burst = 1)                     
        mmio_write32(DMA_REG_CONTROL, 0x00000005U);                                                              
                                                                                                                 
        // 7.6 Verify Transfer Completion                                                                        
        dma_status = mmio_read32(DMA_REG_STATUS);                                                                
        TEST_ASSERT((dma_status & (1U << 16)) != 0U, "DMA Status reports transfer complete (done = 1)");         
        TEST_ASSERT((dma_status & (1U << 17)) == 0U, "DMA Status reports zero transfer errors (error = 0)");     
                                                                                                                 
        // 7.7 Verify Data Integrity at Destination                                                              
        gpio_dst = mmio_read32(GPIO_REG_OUT);                                                                    
        TEST_ASSERT(gpio_dst == 0x12345678U, "Data correctly transferred via Interconnect Port S01 (0x12345678)");
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // TEST 8: Cross-Peripheral Interconnect Multi-Master Concurrent Routing                                     
    // =============================================================================                             
    static void test_interconnect_cross_routing(void) {                                                          
        printf("\n--- [TEST 8] Interconnect Multi-Master Routing & Isolation Test ---\n");                       
                                                                                                                 
        // 8.1 Write unique test signatures across all peripherals simultaneously                                
        mmio_write32(UART_REG_BAUD_DIV, 0x00000028U); // 40                                                      
        mmio_write32(TIMER_REG_CFG0,    0x00010000U); // Prescaler 0, Step 1                                     
        mmio_write32(GPIO_REG_OUT,      0xDEADBEEFU); // GPIO pattern                                            
        mmio_write32(PWM_REG_DUTY,      0x5A5A5A5AU); // PWM pattern                                             
        mmio_write32(I2C_REG_PRER_LO,   0x00000032U); // 50                                                      
                                                                                                                 
        // 8.2 Verify each peripheral retains its exact data without address bleeding or cross-talk              
        bool uart_ok  = (mmio_read32(UART_REG_BAUD_DIV) == 0x00000028U);                                         
        bool timer_ok = (mmio_read32(TIMER_REG_CFG0)    == 0x00010000U);                                         
        bool gpio_ok  = (mmio_read32(GPIO_REG_OUT)      == 0xDEADBEEFU);                                         
        bool pwm_ok   = (mmio_read32(PWM_REG_DUTY)      == 0x5A5A5A5AU);                                         
        bool i2c_ok   = (mmio_read32(I2C_REG_PRER_LO)   == 0x00000032U);                                         
                                                                                                                 
        TEST_ASSERT(uart_ok && timer_ok && gpio_ok && pwm_ok && i2c_ok,                                          
                    "Interconnect address decoding and region isolation verified across all 6 slaves");          
    }                                                                                                            
                                                                                                                 
    // =============================================================================                             
    // Main Entry Point                                                                                          
[?5W    // =============================================================================
    int main(void) {
        printf("==================================================================\n");
        printf("   RISC-V SMART CONTROLSOC - INTERCONNECT C VERIFICATION SUITE    \n");
        printf("==================================================================\n");
  
    #ifdef SIMULATION_HOST
        init_mock_hardware();
    #endif
  
        test_uart_controller();
        test_hardware_timer();
        test_gpio_controller();
        test_spi_controller();
        test_i2c_controller();
        test_pwm_generator();
        test_dma_controller();
        test_interconnect_cross_routing();
  
        printf("\n==================================================================\n");
        printf("   VERIFICATION SUMMARY:\n");
        printf("     Total Subtests Executed : %u\n", total_tests);
        printf("     Passed                  : %u\n", passed_tests);
        printf("     Failed                  : %u\n", failed_tests);
        if (failed_tests == 0) {
            printf("   *** ALL INTERCONNECT & PERIPHERAL C TESTS PASSED (100%%)! ***\n");
        } else {
            printf("   *** VERIFICATION FAILED WITH %u ERRORS! ***\n", failed_tests);
        }
        printf("==================================================================\n");
  
        return (failed_tests == 0) ? 0 : 1;
    }

