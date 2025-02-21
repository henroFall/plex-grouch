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
```

If you are already running as `root`, you can omit `sudo`:
```bash
git clone https://github.com/YOUR_USERNAME/plex-grouch.git && cd plex-grouch && ./install.sh
```

## 🔑 Getting Your Plex API Token
Plex-Grouch requires a **Plex API Token** to interact with your Plex server. Follow these steps to get it:

1. Open Plex in a web browser and log in.
2. Right-click anywhere on the page and select **Inspect** (or press `F12` in most browsers).
3. Go to the **Network** tab.
4. Refresh the page (`F5`) and look for requests to `plex.tv`.
5. Click on any request and find the `X-Plex-Token` in the **Headers** section.
6. Copy this token and provide it when prompted during installation.

## 🚀 Usage
- **Check logs**:
   ```bash
   sudo cat /var/log/plex-grouch.log
   ```
   If running as root:
   ```bash
   cat /var/log/plex-grouch.log
   ```

## ⚙️ Configuration
- The NAS directories are stored in `/etc/plex-grouch.conf`.
- The Plex API Token is stored in `/etc/plex-grouch.env` after installation.
- To update the Plex API Token manually, edit `/etc/plex-grouch.env` and restart the service:
  ```bash
  sudo systemctl restart plex-grouch.service
  ```
  If running as root:
  ```bash
  systemctl restart plex-grouch.service
  ```

## 🛑 Uninstall
To completely remove Plex-Grouch, run this one-liner:
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/plex-grouch/main/uninstall.sh && sudo bash uninstall.sh
```

If running as root:
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/plex-grouch/main/uninstall.sh && bash uninstall.sh
```
