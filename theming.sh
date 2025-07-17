#!/bin/bash

# --- Configuration ---

# List of APT packages for styling and tools
APT_PACKAGES=(
    "gnome-shell-extension-manager" # Provides 'gnome-extensions' command
    "gnome-tweaks"                  # For managing themes and fonts
    "breeze-icon-theme"             # KDE's default icons
    "breeze-cursor-theme"           # KDE's default cursor
    "qt5-gtk-platformtheme"         # Helps Qt apps integrate better with GTK theming
    "qgnomeplatform-qt5"            # Another integration package for Qt apps on GNOME
    "qgnomeplatform-qt6"            # For Qt6 apps
    "wget"                          # Ensure wget is available for downloading wallpaper
    "unzip"                         # Ensure unzip is available for extensions
)

# List of GNOME Extensions (UUIDs and IDs from extensions.gnome.org)
# Format: "Extension Name"="UUID:ID"
# UUIDs are case-sensitive. Verify them on extensions.gnome.org for GNOME Shell 46 (Ubuntu 24.04).
declare -A GNOME_EXTENSIONS=(
    ["Dash to Panel"]="dash-to-panel@jderose.github.com:1160"
    ["Arc Menu"]="arcmenu@arcmenu.com:3628"
    ["AppIndicator and KStatusNotifierItem Support"]="appindicatorsupport@rgcjonas.gmail.com:615"
    ["Desktop Icons NG (DING)"]="ding@rastersoft.com:2087"
    ["User Themes"]="user-theme@gnome-shell-extensions.gcampax.github.com:19" # Essential for custom Shell themes
)

# Path to your custom wallpaper image (system-wide location)
CUSTOM_WALLPAPER_PATH="/usr/share/backgrounds/wisurf_wallpaper.png"

# URL to download the wallpaper from GitHub (raw URL)
WALLPAPER_DOWNLOAD_URL="https://github.com/goldencryer/wisurf/blob/main/Wallpaper.png?raw=true"

# --- Functions ---

log_message() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1"
}

# Function to install APT packages
install_apt_packages() {
    log_message "Updating package lists..."
    sudo apt update || { log_message "Failed to update apt lists. Exiting."; exit 1; }

    log_message "Installing APT packages: ${APT_PACKAGES[*]}"
    for package in "${APT_PACKAGES[@]}"; do
        if ! dpkg -s "$package" &>/dev/null; then
            log_message "Installing $package..."
            sudo apt install -y "$package" || log_message "Warning: Failed to install $package. Continuing."
        else
            log_message "$package is already installed."
        fi
    done
    log_message "APT package installation complete."
}

# Function to install and configure GNOME Extensions
install_and_configure_gnome_extensions() {
    log_message "Installing and configuring GNOME Extensions..."

    for EXTENSION_NAME in "${!GNOME_EXTENSIONS[@]}"; do
        UUID_ID_PAIR="${GNOME_EXTENSIONS[$EXTENSION_NAME]}"
        UUID="${UUID_ID_PAIR%:*}" # Extract UUID
        ID="${UUID_ID_PAIR#*:}"  # Extract ID

        log_message "Processing extension: ${EXTENSION_NAME} (UUID: ${UUID}, ID: ${ID})"

        EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/${UUID}"

        # Check if already installed
        if [ ! -d "$EXTENSION_DIR" ]; then
            log_message "Downloading ${EXTENSION_NAME} (ID: ${ID})..."
            # Direct download URL pattern for extensions.gnome.org
            wget "https://extensions.gnome.org/extension-data/${ID}.shell-extension.zip" -O "/tmp/${UUID}.zip"
            if [ $? -eq 0 ]; then
                log_message "Unzipping ${EXTENSION_NAME} to ${EXTENSION_DIR}..."
                mkdir -p "$EXTENSION_DIR"
                unzip -q "/tmp/${UUID}.zip" -d "$EXTENSION_DIR"
                rm "/tmp/${UUID}.zip"
                log_message "${EXTENSION_NAME} files extracted."
            else
                log_message "Error: Failed to download ${EXTENSION_NAME}. Skipping installation."
                continue
            fi
        else
            log_message "${EXTENSION_NAME} is already installed. Ensuring it's enabled."
        fi

        log_message "Enabling ${EXTENSION_NAME}..."
        # This command is part of gnome-shell-extension-manager
        gnome-extensions enable "${UUID}" || log_message "Warning: Failed to enable ${EXTENSION_NAME}. It might not be compatible or require a Shell restart."

        # --- Configure specific extensions ---
        case "$UUID" in
            "dash-to-panel@jderose.github.com")
                log_message "Configuring Dash to Panel..."
                gsettings set org.gnome.shell.extensions.dash-to-panel position 'BOTTOM'
                gsettings set org.gnome.shell.extensions.dash-to-panel show-show-desktop-button false # Often default for KDE
                gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-button false # Arc Menu will replace this
                gsettings set org.gnome.shell.extensions.dash-to-panel animate-app-menu false # KDE's menu usually appears instantly
                gsettings set org.gnome.shell.extensions.dash-to-panel dot-on-icon false # No running app indicator dot (optional, for cleaner look)
                # Further settings for Dash to Panel can be explored with 'dconf-editor'
                ;;
            "arcmenu@arcmenu.com")
                log_message "Configuring Arc Menu..."
                # These are just examples. Arc Menu has a vast number of configuration options.
                # It's highly recommended to configure it via its GUI settings after installation.
                # Example: Set icon to a generic 'apps' icon or a custom one if placed.
                # gsettings set org.gnome.shell.extensions.arcmenu.general menu-button-icon "gnome-default"
                # gsettings set org.gnome.shell.extensions.arcmenu.general menu-button-icon "custom"
                # gsettings set org.gnome.shell.extensions.arcmenu.general custom-icon-path "/usr/share/icons/gnome/256x256/apps/system-run.png"
                ;;
            "ding@rastersoft.com")
                log_message "Configuring Desktop Icons NG (DING)..."
                gsettings set org.gnome.shell.extensions.ding show-trash true
                gsettings set org.gnome.shell.extensions.ding show-home true
                gsettings set org.gnome.shell.extensions.ding show-volumes true
                gsettings set org.gnome.shell.extensions.ding show-network-removable-devices true # Show mounted network/removable drives
                # You can also set specific positions and alignment for icons
                ;;
            # Add configuration for other extensions here as needed
        esac
    done
    log_message "GNOME Extension installation and basic configuration complete."
}

# Function to apply general theming (Icons, Cursors, GTK, Shell)
apply_theming() {
    log_message "Applying KDE-like theming to GNOME..."

    # GTK Theme (Adwaita is default and clean, or find a custom 'Breeze-like' GTK theme)
    # Ubuntu 24.04 uses Yaru, which is also very good.
    # For a KDE-like look, "Adwaita" (default GNOME) or a flat theme is generally suitable.
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru" # Keeping Ubuntu's default or try "Adwaita"

    # Icon Theme (Breeze Icons)
    gsettings set org.gnome.desktop.interface icon-theme "Breeze"

    # Cursor Theme (Breeze Cursors)
    gsettings set org.gnome.desktop.interface cursor-theme "Breeze"

    # Shell Theme (Requires 'User Themes' extension enabled)
    # You'll likely need to download a "Breeze-like" GNOME Shell theme from Gnome-look.org
    # and place it in ~/.themes/ or ~/.local/share/themes/
    # Then you can set it like this:
    # Example: If you downloaded a theme named 'Breeze-Shell'
    # gsettings set org.gnome.shell.extensions.user-theme name "Breeze-Shell"
    log_message "Shell theme will require manual download/placement of a custom theme (e.g., a 'Breeze' styled one from gnome-look.org) and setting via gnome-tweaks or gsettings after enabling 'User Themes' extension."
    log_message "Consider themes like 'Breeze-Dark-Shell' or 'Breeze-Light-Shell' for the best match."

    log_message "Theming applied. Some changes may require a session restart."
}

# Function to set wallpaper
set_desktop_wallpaper() {
    log_message "Setting desktop wallpaper..."

    # Check if the custom wallpaper exists
    if [ ! -f "$CUSTOM_WALLPAPER_PATH" ]; then
        log_message "Custom wallpaper not found at '$CUSTOM_WALLPAPER_PATH'. Attempting to download from '$WALLPAPER_DOWNLOAD_URL'..."
        sudo wget -O "$CUSTOM_WALLPAPER_PATH" "$WALLPAPER_DOWNLOAD_URL"
        if [ $? -ne 0 ]; then
            log_message "Error: Failed to download wallpaper. Skipping wallpaper setting."
            return
        fi
        log_message "Wallpaper downloaded successfully."
    else
        log_message "Custom wallpaper already exists at '$CUSTOM_WALLPAPER_PATH'."
    fi

    # Set wallpaper for current user (GNOME)
    gsettings set org.gnome.desktop.background picture-uri "file://$CUSTOM_WALLPAPER_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$CUSTOM_WALLPAPER_PATH" # For dark theme if applicable
    gsettings set org.gnome.desktop.background picture-options "zoom" # or "stretched", "scaled", "wallpaper", "center", "none"

    log_message "Desktop wallpaper set to $CUSTOM_WALLPAPER_PATH."
}

clean_up() {
    log_message "Cleaning up..."
    sudo apt autoremove -y
    sudo apt clean
    log_message "Cleanup complete."
}

# --- Main Script Execution ---

log_message "Starting Ubuntu 24.04 GNOME to KDE-like setup script."

# 1. Install necessary APT packages
install_apt_packages

# 2. Set desktop wallpaper (downloading from GitHub)
set_desktop_wallpaper

# 3. Install and configure GNOME Extensions
install_and_configure_gnome_extensions

# 4. Apply general theming (Icons, Cursors, GTK, Shell)
apply_theming

# 5. Final cleanup
clean_up

log_message "GNOME desktop customization finished."
log_message "=================================================================="
log_message "IMPORTANT: You need to **log out and log back in** (or reboot) for"
log_message "all changes (especially extensions and themes) to take full effect."
log_message "After logging in, open 'Extensions' app and 'GNOME Tweaks' to"
log_message "fine-tune settings and potentially set a custom Shell Theme."
log_message "=================================================================="
