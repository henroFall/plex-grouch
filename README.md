# 🗑️ Plex-Grouch: Oscar Takes Out the Trash!

**Plex-Grouch** is a smart trash cleaner for Plex, ensuring your NAS devices are **connected** before cleaning. If a NAS is missing, Oscar gets grumpy and refuses to take out the trash. 😡

## 🏆 Features
- **Protects your media**: Only cleans trash when all NAS devices are online.
- **User-controlled NAS selection**: Pick the folders you want to monitor.
- **Automated hourly cleanup**: Uses `systemd` to run every hour.
- **Logging included**: View logs in `/var/log/plex-grouch.log`.

## ⚡ Installation (One-Liner)
```bash
git clone https://github.com/YOUR_USERNAME/plex-grouch.git && cd plex-grouch && sudo ./install.sh
