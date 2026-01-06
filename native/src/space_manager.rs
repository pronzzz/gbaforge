use anyhow::{Result, bail};

pub struct SpaceManager {
    // We don't necessarily need to store the whole map if we scan on demand,
    // but caching free blocks is faster. 
    // For now, let's just scan on demand for simplicity and correctness.
}

impl SpaceManager {
    /// Scans the ROM data for a contiguous block of `needed_size` bytes of `0xFF`.
    /// Returns the offset of the start of the block.
    /// `search_start` is usually where the ROM ends (0x800000 + used size) or a safe offset (0x700000).
    /// For FireRed, typically free space begins after the data.
    /// Safest approach: Start searching from 0x720000 or allow user config.
    /// Here we scan from a safe default.
    pub fn find_free_space(data: &[u8], needed_size: usize, search_start: usize) -> Result<usize> {
        let mut consecutive_ff = 0;
        let mut start_index = 0;

        // Ensure we don't go out of bounds
        if search_start >= data.len() {
             bail!("Search start index out of bounds");
        }

        // Align search to 4 bytes (word alignment) is often good practice for GBA
        let aligned_start = (search_start + 3) & !3;

        for (i, &byte) in data.iter().enumerate().skip(aligned_start) {
            if byte == 0xFF {
                if consecutive_ff == 0 {
                    start_index = i;
                }
                consecutive_ff += 1;
                
                if consecutive_ff >= needed_size {
                    return Ok(start_index);
                }
            } else {
                consecutive_ff = 0;
            }
        }

        bail!("Not enough free space found for {} bytes", needed_size);
    }
}
