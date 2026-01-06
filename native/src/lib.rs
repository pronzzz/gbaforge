pub mod structures;
pub mod state;
pub mod api;
pub mod compression;
pub mod graphics;
pub mod space_manager;
pub mod scripting;

use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init_app() {
    // Default utilities - e.g. logging
    flutter_rust_bridge::setup_default_user_utils();
}
