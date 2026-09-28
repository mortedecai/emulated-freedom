package dev.daniel.taylor.emulators.chip8;

import dev.daniel.taylor.emulators.chip8.memory.Chip8MemoryManager;
import dev.daniel.taylor.emulators.chip8.memory.EmulatorMemoryException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class Chip8MemoryManagerTest {

    private Chip8MemoryManager manager;

    @BeforeEach
    void setUp() {
        manager = new Chip8MemoryManager();
    }

    @Test
    void constructor_initializesMemoryToZero() throws EmulatorMemoryException {
        for (int i = 0; i < Chip8MemoryManager.MAX_MEMORY_FOOTPRINT; i++) {
            assertEquals(0, manager.readByte(i), "byte at address " + i + " should be zero");
        }
    }

    @Test
    void getMemoryLoadStart_returnsConstant() {
        assertEquals(Chip8MemoryManager.PROGRAM_LOAD_START, manager.getMemoryLoadStart());
    }

    @Test
    void getMemoryLoadStart_returns0x200() {
        assertEquals(0x200, manager.getMemoryLoadStart());
    }

    @Test
    void loadData_returnsTrue() throws EmulatorMemoryException {
        assertTrue(manager.loadData(0, new byte[]{1, 2, 3}));
    }

    @Test
    void loadData_atZero_storesBytes() throws EmulatorMemoryException {
        byte[] data = {0x12, 0x34, 0x56};
        manager.loadData(0, data);
        assertArrayEquals(data, manager.readBytes(0, data.length));
    }

    @Test
    void loadData_atProgramLoadStart_storesBytes() throws EmulatorMemoryException {
        byte[] data = {(byte) 0xA2, 0x00};
        manager.loadData(Chip8MemoryManager.PROGRAM_LOAD_START, data);
        assertArrayEquals(data, manager.readBytes(Chip8MemoryManager.PROGRAM_LOAD_START, data.length));
    }

    @Test
    void loadData_exactlyFillsMemory_doesNotThrow() {
        byte[] data = new byte[Chip8MemoryManager.MAX_MEMORY_FOOTPRINT];
        assertDoesNotThrow(() -> manager.loadData(0, data));
    }

    @Test
    void loadData_dataTooLarge_throwsEmulatorMemoryException() {
        byte[] data = new byte[Chip8MemoryManager.MAX_MEMORY_FOOTPRINT + 1];
        assertThrows(EmulatorMemoryException.class, () -> manager.loadData(0, data));
    }

    @Test
    void loadData_offsetPlusLengthExceedsMemory_throwsEmulatorMemoryException() {
        byte[] data = new byte[Chip8MemoryManager.MAX_MEMORY_FOOTPRINT];
        assertThrows(EmulatorMemoryException.class, () -> manager.loadData(1, data));
    }

    @Test
    void readByte_uninitializedLocation_returnsZero() throws EmulatorMemoryException {
        assertEquals(0, manager.readByte(0x300));
    }

    @Test
    void readByte_afterLoad_returnsStoredValue() throws EmulatorMemoryException {
        manager.loadData(0x100, new byte[]{0x42});
        assertEquals(0x42, manager.readByte(0x100));
    }

    @Test
    void readByte_atLastValidAddress_returnsZero() throws EmulatorMemoryException {
        assertEquals(0, manager.readByte(Chip8MemoryManager.MAX_MEMORY_FOOTPRINT - 1));
    }

    @Test
    void readByte_negativeLocation_throwsEmulatorMemoryException() {
        assertThrows(EmulatorMemoryException.class, () -> manager.readByte(-1));
    }

    @Test
    void readByte_atMaxMemoryFootprint_throwsEmulatorMemoryException() {
        assertThrows(EmulatorMemoryException.class,
                () -> manager.readByte(Chip8MemoryManager.MAX_MEMORY_FOOTPRINT));
    }

    @Test
    void readBytes_afterLoad_returnsStoredValues() throws EmulatorMemoryException {
        byte[] data = {0x10, 0x20, 0x30};
        manager.loadData(0x300, data);
        assertArrayEquals(data, manager.readBytes(0x300, data.length));
    }

    @Test
    void readBytes_uninitializedRange_returnsZeros() throws EmulatorMemoryException {
        assertArrayEquals(new byte[]{0, 0, 0, 0}, manager.readBytes(0x400, 4));
    }

    @Test
    void readBytes_zeroCount_returnsEmptyArray() throws EmulatorMemoryException {
        assertArrayEquals(new byte[0], manager.readBytes(0, 0));
    }
}