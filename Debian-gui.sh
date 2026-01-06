#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🔹 Updating Termux..."
pkg update -y && pkg upgrade -y

echo "🔹 Checking required Termux packages..."

install_pkg() {
    if pkg list-installed | grep -q "^$1/"; then
        echo "✅ $1 already installed"
    else
        echo "📦 Installing $1..."
        pkg install -y $1
    fi
}

install_pkg proot-distro
install_pkg x11-repo

echo "🔹 Checking Debian installation..."

DEBIAN_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/debian"

if [ -d "$DEBIAN_ROOT" ]; then
    echo "✅ Debian already installed, skipping"
else
    echo "📦 Installing Debian..."
    proot-distro install debian
fi

echo "🔹 Configuring Debian GUI & VNC..."

proot-distro login debian -- bash << 'EOF'
set -e

echo "🔹 Updating Debian..."
apt update -y && apt upgrade -y

install_apt() {
    if dpkg -s "$1" >/dev/null 2>&1; then
        echo "✅ $1 already installed"
    else
        echo "📦 Installing $1"
        apt install -y $1
    fi
}

install_apt xfce4
install_apt xfce4-goodies
install_apt tigervnc-standalone-server
install_apt dbus-x11
install_apt nano

echo "🔹 Setting up VNC..."

mkdir -p ~/.vnc

if [ ! -f ~/.vnc/xstartup ]; then
cat << 'EOT' > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4 &
EOT
chmod +x ~/.vnc/xstartup
echo "✅ xstartup created"
else
echo "✅ xstartup already exists"
fi

if [ ! -f ~/.config/tigervnc/passwd ]; then
echo "🔐 Setting VNC password (123456)"
printf "123456\n123456\nn\n" | vncpasswd
else
echo "✅ VNC password already set"
fi

echo "🔹 Starting VNC server once for verification..."
vncserver -localhost no :1

echo "🔹 Stopping VNC server..."
vncserver -kill :1

echo "🔹 Debian setup completed. Exiting Debian..."
exit
EOF

echo ""
echo "✅ INSTALLATION SUCCESSFUL!"
echo ""
echo "📌 MANUAL USAGE GUIDE"
echo "────────────────────────────"
echo "👉 Login to Debian:"
echo "   proot-distro login debian"
echo ""
echo "👉 Start VNC server:"
echo "   proot-distro login debian -- vncserver -localhost no :1"
echo ""
echo "👉 Kill VNC server:"
echo "   proot-distro login debian -- vncserver -kill :1"
echo ""
echo "👉 Open VNC Viewer and connect to:"
echo "   localhost:5901"
echo ""
echo "👉 Password : 123456"
echo ""
echo "⚠️ Keep Termux running while using VNC"
echo "🎉 DONE!"

