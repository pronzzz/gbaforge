mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

pub mod api;
pub mod compression;
pub mod graphics;
pub mod scripting;
pub mod space_manager;
pub mod state;
pub mod structures;

use flutter_rust_bridge::frb;

#[allow(unexpected_cfgs)]
#[frb(init)]
pub fn init_app() {
    // Default utilities - e.g. logging
    flutter_rust_bridge::setup_default_user_utils();
}
