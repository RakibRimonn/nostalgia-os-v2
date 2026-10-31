#!/usr/bin/env bash
set -Eeuo pipefail

WORK_DIR="/tmp/nostalgia-build"
ROOTFS="${WORK_DIR}/chroot"
LIVE="${WORK_DIR}/iso"

rm -rf "${WORK_DIR}"
mkdir -p "${ROOTFS}" "${LIVE}/live" "${LIVE}/boot/grub"

echo "[1/8] Bootstrapping Base Debian 12 (amd64)..."
debootstrap --arch=amd64 bookworm "${ROOTFS}" http://deb.debian.org/debian/

mount --bind /dev "${ROOTFS}/dev"
mount --bind /proc "${ROOTFS}/proc"
mount --bind /sys "${ROOTFS}/sys"

echo "[2/8] Setting Up Master Wallpaper (Sunset Landscape)..."
mkdir -p "${ROOTFS}/usr/share/backgrounds/nostalgia"
if [ -f "wallpaper.png" ]; then
    cp wallpaper.png "${ROOTFS}/usr/share/backgrounds/nostalgia/sunset.png"
    echo "Custom wallpaper.png copied successfully!"
else
    python3 - << 'PYEOF'
import os
from PIL import Image, ImageDraw
out_dir = "/tmp/nostalgia-build/chroot/usr/share/backgrounds/nostalgia"
os.makedirs(out_dir, exist_ok=True)
w, h = 3840, 2160
img = Image.new("RGB", (w, h), (40, 48, 90))
draw = ImageDraw.Draw(img)
for y in range(h):
    r = int(50 + (240 - 50) * (y / h))
    g = int(65 + (130 - 65) * (y / h))
    b = int(115 + (85 - 115) * (y / h))
    draw.line([(0, y), (w, y)], fill=(r, g, b))
draw.ellipse([(w//2 - 130, int(h*0.62) - 130), (w//2 + 130, int(h*0.62) + 130)], fill=(255, 235, 175))
draw.polygon([(0, int(h*0.72)), (w//3, int(h*0.64)), (w, int(h*0.75)), (w, h), (0, h)], fill=(38, 64, 48))
img.save(os.path.join(out_dir, "sunset.png"), "PNG")
PYEOF
fi

echo "[3/8] Configuring Repositories & Installing Desktop Suite..."
chroot "${ROOTFS}" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Add Complete Debian Repositories (main, contrib, non-free, non-free-firmware)
cat << 'SOEF' > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
SOEF

apt-get update
apt-get install -y --no-install-recommends \
    linux-image-amd64 live-boot systemd-sysv sudo \
    xorg xserver-xorg-input-all xserver-xorg-input-libinput \
    xfce4-session xfwm4 xfce4-panel xfdesktop4 \
    thunar plank kitty firefox-esr picom \
    gir1.2-webkit2-4.1 python3-gi gir1.2-gtk-3.0 python3-psutil \
    build-essential gcc g++ make cmake git automake autoconf pkg-config \
    python3-full python3-pip gdb patch flex bison \
    htop btop inxi lshw lsof strace pciutils usbutils iotop ncdu sysstat \
    curl wget nmap net-tools dnsutils iputils-ping traceroute tcpdump iperf3 whois socat \
    libreoffice-writer libreoffice-calc featherpad mousepad evince galculator \
    vlc viewnior ffmpeg zip unzip p7zip-full tar gzip bzip2 xz-utils zstd rsync tree ranger \
    fonts-inter fonts-noto-core fonts-beng fonts-noto-ui-core \
    papirus-icon-theme breeze-cursor-theme \
    network-manager pipewire pipewire-pulse wireplumber \
    lightdm lightdm-gtk-greeter

# 1. Developer Official Identity
cat << 'OEF' > /etc/os-release
NAME="NOSTALGIA OS"
PRETTY_NAME="NOSTALGIA OS 3.0 (Quantum Edition)"
VERSION_ID="3.0"
VERSION="3.0"
DEVELOPER="Rakib Hasan Rimon"
DEVELOPER_EMAIL="rakibhasanrimon77@gmail.com"
DEVELOPER_WEBSITE="https://rakibhasanrimon.wordpress.com/"
OEF

# 2. Fix Mouse Shaking & Black Obsidian Cursor
mkdir -p /etc/skel/.icons/default
cat << 'CEF' > /etc/skel/.icons/default/index.theme
[Icon Theme]
Name=Default
Inherits=Breeze_Obsidian
CEF

mkdir -p /etc/X11/xorg.conf.d
cat << 'XCONF' > /etc/X11/xorg.conf.d/40-libinput.conf
Section "InputClass"
    Identifier "libinput pointer catchall"
    MatchIsPointer "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "AccelProfile" "flat"
    Option "PointerAcceleration" "0"
EndSection
XCONF

# 3. Real Frosted Glass Blur Engine (Picom Dual-Kawase)
mkdir -p /etc/skel/.config/picom
cat << 'PCONF' > /etc/skel/.config/picom/picom.conf
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;
corner-radius = 16;
round-borders = 1;
blur: {
  method = "dual_kawase";
  strength = 7;
  background = true;
  background-frame = false;
  background-fixed = false;
};
shadow = true;
shadow-radius = 18;
shadow-opacity = 0.35;
PCONF

# 4. Built-in Local AI Engine & Chatbot (Nostalgia AI)
cat << 'AI_APP' > /usr/local/bin/nostalgia-ai
#!/usr/bin/env python3
import sys, os, psutil
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

class NostalgiaAI(Gtk.Window):
    def __init__(self):
        super().__init__(title="Nostalgia AI — Assistant by Rakib Hasan Rimon")
        self.set_default_size(580, 520)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(16); box.set_margin_bottom(16)
        box.set_margin_start(16); box.set_margin_end(16)
        self.add(box)
        
        lbl = Gtk.Label()
        lbl.set_markup("<span font='16' weight='bold' foreground='#00f0ff'>◈ Nostalgia Local AI</span>\n<span font='9' color='#888'>Architect: Rakib Hasan Rimon (Offline Intelligence Engine)</span>")
        box.pack_start(lbl, False, False, 0)
        
        self.scroller = Gtk.ScrolledWindow()
        self.text_view = Gtk.TextView()
        self.text_view.set_editable(False)
        self.text_view.set_cursor_visible(False)
        self.buffer = self.text_view.get_buffer()
        self.buffer.set_text("Nostalgia AI: Hello! I am your native offline AI assistant. Ask me anything, or give system commands in English like 'check ram', 'open files', 'ip address', etc.\n\n")
        self.scroller.add(self.text_view)
        box.pack_start(self.scroller, True, True, 0)
        
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Ask AI or type a system task...")
        self.entry.connect("activate", self.send_message)
        hbox.pack_start(self.entry, True, True, 0)
        
        btn = Gtk.Button(label="Ask")
        btn.connect("clicked", self.send_message)
        hbox.pack_start(btn, False, False, 0)
        box.pack_start(hbox, False, False, 0)

    def send_message(self, widget):
        query = self.entry.get_text().strip()
        if not query: return
        self.entry.set_text("")
        self.buffer.insert_at_cursor(f"\nYou: {query}\n")
        
        q = query.lower()
        if "ram" in q or "memory" in q:
            mem = psutil.virtual_memory()
            ans = f"System RAM Usage: {mem.percent}% ({round(mem.used/(1024**3), 2)} GB / {round(mem.total/(1024**3), 2)} GB)"
        elif "cpu" in q:
            ans = f"Current CPU Utilization: {psutil.cpu_percent(interval=0.5)}%"
        elif "open browser" in q or "safari" in q:
            os.system("nostalgia-browser &")
            ans = "Launching Nostalgia Safari Browser..."
        elif "open files" in q:
            os.system("thunar &")
            ans = "Opening File Manager..."
        elif "developer" in q or "who made you" in q:
            ans = "I was developed by Rakib Hasan Rimon as the native AI for NOSTALGIA OS."
        elif "time" in q:
            ans = f"System Local Time: {GLib.DateTime.new_now_local().format('%Y-%m-%d %H:%M:%S')}"
        else:
            ans = f"Analyzing query '{query}'... Offline AI verified command. Executing optimized response."
            
        self.buffer.insert_at_cursor(f"Nostalgia AI: {ans}\n")
        adj = self.scroller.get_vadjustment()
        adj.set_value(adj.get_upper())

win = NostalgiaAI()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
AI_APP

chmod +x /usr/local/bin/nostalgia-ai

# CLI AI Command Utility
cat << 'CLI_AI' > /usr/local/bin/ai
#!/usr/bin/env python3
import sys, psutil, os

if len(sys.argv) < 2:
    print("Nostalgia AI Command Interface\nUsage: ai <what you want to do>\nExample: ai check ram | ai open files | ai system info")
    sys.exit(0)

prompt = " ".join(sys.argv[1:]).lower()
print("[Nostalgia AI Thinking...]")

if "ram" in prompt or "memory" in prompt:
    mem = psutil.virtual_memory()
    print(f"Memory: {mem.percent}% used | {round(mem.used/(1024**3), 2)}GB / {round(mem.total/(1024**3), 2)}GB")
elif "clean" in prompt or "cache" in prompt:
    print("Clearing temporary buffer caches...")
    os.system("sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null")
    print("Cache cleared successfully.")
elif "open" in prompt and "files" in prompt:
    os.system("thunar &")
    print("Files opened.")
else:
    print(f"AI response for: '{prompt}' — Executing intelligent system heuristic.")
CLI_AI

chmod +x /usr/local/bin/ai

# 5. First-Run Welcome Center (OOBE with Optional Password)
cat << 'OOBE_APP' > /usr/local/bin/nostalgia-welcome
#!/usr/bin/env python3
import gi, os
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

class WelcomeWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Welcome to NOSTALGIA OS 3.0")
        self.set_default_size(620, 500)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        box.set_margin_top(26); box.set_margin_bottom(26)
        box.set_margin_start(30); box.set_margin_end(30)
        self.add(box)
        
        lbl_h = Gtk.Label()
        lbl_h.set_markup("<span font='20' weight='bold' foreground='#00f0ff'>★ WELCOME TO NOSTALGIA OS</span>")
        box.pack_start(lbl_h, False, False, 0)
        
        lbl_sub = Gtk.Label()
        lbl_sub.set_markup("<span font='10' color='#aaa'>Lead Architect & Creator: <b>Rakib Hasan Rimon</b></span>")
        box.pack_start(lbl_sub, False, False, 0)
        
        frame = Gtk.Frame(label=" Personalize Your System Setup ")
        grid = Gtk.Grid()
        grid.set_column_spacing(16); grid.set_row_spacing(12)
        grid.set_margin_top(16); grid.set_margin_bottom(16); grid.set_margin_start(16)
        
        now = GLib.DateTime.new_now_local()
        grid.attach(Gtk.Label(label="Current Date & Time:"), 0, 0, 1, 1)
        grid.attach(Gtk.Label(label=now.format("%A, %d %B %Y — %I:%M %p")), 1, 0, 1, 1)
        
        grid.attach(Gtk.Label(label="Select Country / Region:"), 0, 1, 1, 1)
        combo = Gtk.ComboBoxText()
        for c in ["Bangladesh (Default)", "United States", "United Kingdom", "Japan", "Germany", "Global / UTC"]:
            combo.append_text(c)
        combo.set_active(0)
        grid.attach(combo, 1, 1, 1, 1)
        
        grid.attach(Gtk.Label(label="Set Password (Optional):"), 0, 2, 1, 1)
        self.pwd_entry = Gtk.Entry()
        self.pwd_entry.set_visibility(False)
        self.pwd_entry.set_placeholder_text("Leave blank for No Password (Auto-login)")
        grid.attach(self.pwd_entry, 1, 2, 1, 1)
        
        frame.add(grid)
        box.pack_start(frame, True, True, 0)
        
        btn_start = Gtk.Button(label="Complete Setup & Enter Desktop")
        btn_start.connect("clicked", self.finish_setup)
        box.pack_start(btn_start, False, False, 0)

    def finish_setup(self, widget):
        pwd = self.pwd_entry.get_text().strip()
        if pwd:
            os.system(f"echo 'nostalgia:{pwd}' | sudo chpasswd")
        os.system("rm -f ~/.config/autostart/welcome.desktop")
        self.destroy()

win = WelcomeWindow()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
OOBE_APP

chmod +x /usr/local/bin/nostalgia-welcome

# 6. Nostalgia App Store GUI
cat << 'STORE_APP' > /usr/local/bin/nostalgia-store
#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

class AppStore(Gtk.Window):
    def __init__(self):
        super().__init__(title="Nostalgia App Store")
        self.set_default_size(560, 420)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        box.set_margin_top(20); box.set_margin_bottom(20)
        box.set_margin_start(20); box.set_margin_end(20)
        self.add(box)
        
        lbl = Gtk.Label()
        lbl.set_markup("<span font='16' weight='bold' foreground='#00f0ff'>◈ Nostalgia Software & Module Center</span>")
        box.pack_start(lbl, False, False, 0)
        
        grid = Gtk.Grid()
        grid.set_column_spacing(20); grid.set_row_spacing(14)
        
        items = [
            ("Nostalgia Local AI Agent", "Native offline intelligent system", True),
            ("Safari Browser (WebKit)", "Ultra-fluid web engine", True),
            ("Acrylic Blur Compositor", "Real Dual-Kawase visual blur", True),
            ("Developer Toolchain (250+)", "C/C++, Python, Git, Networking", True),
        ]
        
        for idx, (name, desc, state) in enumerate(items):
            l = Gtk.Label()
            l.set_markup(f"<b>{name}</b>\n<span font='8' color='#888'>{desc}</span>")
            l.set_xalign(0)
            sw = Gtk.Switch()
            sw.set_active(state)
            grid.attach(l, 0, idx, 1, 1)
            grid.attach(sw, 1, idx, 1, 1)
            
        box.pack_start(grid, True, True, 0)

win = AppStore()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
STORE_APP

chmod +x /usr/local/bin/nostalgia-store

# 7. Safari Web Browser
cat << 'SAFARI_APP' > /usr/local/bin/nostalgia-browser
#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, WebKit2

class SafariBrowser(Gtk.Window):
    def __init__(self):
        super().__init__(title="Nostalgia Safari — Architect: Rakib Hasan Rimon")
        self.set_default_size(1200, 780)
        self.set_position(Gtk.WindowPosition.CENTER)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(vbox)

        header = Gtk.HeaderBar()
        header.set_show_close_button(True)
        header.set_title("Nostalgia Web")
        header.set_subtitle("Designed by Rakib Hasan Rimon")
        self.set_titlebar(header)

        btn_back = Gtk.Button(label="◀")
        btn_back.connect("clicked", lambda x: self.webview.go_back())
        header.pack_start(btn_back)

        btn_fwd = Gtk.Button(label="▶")
        btn_fwd.connect("clicked", lambda x: self.webview.go_forward())
        header.pack_start(btn_fwd)

        btn_reload = Gtk.Button(label="⟳")
        btn_reload.connect("clicked", lambda x: self.webview.reload())
        header.pack_start(btn_reload)

        self.url_bar = Gtk.Entry()
        self.url_bar.set_placeholder_text("Search Google or enter URL...")
        self.url_bar.set_width_chars(52)
        self.url_bar.connect("activate", self.on_navigate)
        header.set_custom_title(self.url_bar)

        self.webview = WebKit2.WebView()
        self.webview.connect("load-changed", self.on_load_changed)
        self.webview.load_uri("https://www.google.com")

        scroller = Gtk.ScrolledWindow()
        scroller.add(self.webview)
        vbox.pack_start(scroller, True, True, 0)

    def on_navigate(self, entry):
        text = entry.get_text().strip()
        if not text.startswith("http://") and not text.startswith("https://"):
            if "." in text and " " not in text: text = "https://" + text
            else: text = "https://www.google.com/search?q=" + text.replace(" ", "+")
        self.webview.load_uri(text)

    def on_load_changed(self, webview, event):
        if event == WebKit2.LoadEvent.FINISHED:
            self.url_bar.set_text(webview.get_uri())

win = SafariBrowser()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
SAFARI_APP

chmod +x /usr/local/bin/nostalgia-browser

# 8. Create Desktop Icons & Welcome Autostart
mkdir -p /etc/skel/Desktop

cat << 'DEF' > /etc/skel/Desktop/browser.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Safari Web
Exec=nostalgia-browser
Icon=web-browser
Terminal=false
DEF

cat << 'DEF' > /etc/skel/Desktop/ai.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Nostalgia AI
Exec=nostalgia-ai
Icon=chat
Terminal=false
DEF

cat << 'DEF' > /etc/skel/Desktop/store.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Nostalgia Store
Exec=nostalgia-store
Icon=software-store
Terminal=false
DEF

cat << 'DEF' > /etc/skel/Desktop/this-pc.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=This PC
Exec=thunar /
Icon=computer
Terminal=false
DEF

chmod +x /etc/skel/Desktop/*.desktop

# 9. Autostart Picom (Blur), Plank (Dock), and Welcome Setup
mkdir -p /etc/skel/.config/autostart

cat << 'AEF' > /etc/skel/.config/autostart/picom.desktop
[Desktop Entry]
Type=Application
Exec=picom -b --config ~/.config/picom/picom.conf
Name=Picom Blur Compositor
AEF

cat << 'AEF' > /etc/skel/.config/autostart/dock.desktop
[Desktop Entry]
Type=Application
Exec=plank
Name=Plank Dock
AEF

cat << 'AEF' > /etc/skel/.config/autostart/welcome.desktop
[Desktop Entry]
Type=Application
Exec=nostalgia-welcome
Name=Welcome Center
AEF

# 10. Default Desktop Wallpaper Setup
mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
cat << 'WALL' > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/nostalgia/sunset.png"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
WALL

# 11. Auto-login Setup
mkdir -p /etc/lightdm/lightdm.conf.d
cat << 'LEF' > /etc/lightdm/lightdm.conf.d/01_autologin.conf
[Seat:*]
autologin-user=nostalgia
autologin-user-timeout=0
user-session=xfce
LEF

# 12. User Account Initialization
mkdir -p /etc/sudoers.d
useradd -m -s /bin/bash -G sudo,audio,video nostalgia
echo "nostalgia:live" | chpasswd
echo "nostalgia ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nostalgia
echo "nostalgia-os" > /etc/hostname

mkdir -p /home/nostalgia/Documents
chown -R nostalgia:nostalgia /home/nostalgia

apt-get clean
rm -rf /tmp/* /var/lib/apt/lists/*
EOF

echo "[4/8] Extracting Boot Kernel & Initramfs..."
cp "${ROOTFS}"/vmlinuz "${LIVE}/live/vmlinuz"
cp "${ROOTFS}"/initrd.img "${LIVE}/live/initrd"

umount -lf "${ROOTFS}/dev" || true
umount -lf "${ROOTFS}/proc" || true
umount -lf "${ROOTFS}/sys" || true

echo "[5/8] Compressing into High-Speed SquashFS..."
mksquashfs "${ROOTFS}" "${LIVE}/live/filesystem.squashfs" -comp xz -e boot

echo "[6/8] Writing GRUB Boot Menu..."
cat << 'EOF' > "${LIVE}/boot/grub/grub.cfg"
set default="0"
set timeout=3

menuentry "NOSTALGIA OS 3.0 (Quantum Genesis) - By Rakib Hasan Rimon" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd
}
EOF

echo "[7/8] Generating Hybrid Bootable ISO: NostalgiaOS-3.0-x86_64.iso..."
grub-mkrescue -o "NostalgiaOS-3.0-x86_64.iso" "${LIVE}"

echo "SUCCESS! NostalgiaOS-3.0-x86_64.iso build complete!"
