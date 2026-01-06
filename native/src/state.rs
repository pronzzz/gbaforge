use crate::structures::RomHeader;
use once_cell::sync::Lazy;
use std::collections::BTreeMap;
use std::sync::RwLock;

// Global state required for FFI - accessed via RwLock for thread safety
pub static APP_STATE: Lazy<RwLock<Option<RomState>>> = Lazy::new(|| RwLock::new(None));

pub struct RomState {
    pub data: Vec<u8>,
    pub header: RomHeader,
    // We will Implement TableOffsets later
    pub modifications: BTreeMap<u32, Vec<u8>>,
}

impl RomState {
    pub fn new(data: Vec<u8>, header: RomHeader) -> Self {
        Self {
            data,
            header,
            modifications: BTreeMap::new(),
        }
    }
}
