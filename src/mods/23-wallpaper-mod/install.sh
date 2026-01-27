set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Cleaning and reinstalling wallpaper"
rm /usr/share/gnome-background-properties/* -rf
rm /usr/share/backgrounds/* -rf
mv ./Planet-explosion-darker.png /usr/share/backgrounds/
mv ./Planet-explosion-dark.png /usr/share/backgrounds/
cat << EOF > /usr/share/gnome-background-properties/planet-explosion.dark.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
<wallpaper deleted="false">
<name>Planet Explosion Dark</name>
<filename>/usr/share/backgrounds/Planet-explosion-darker.png</filename>
<options>zoom</options>
<shade_type>solid</shade_type>
</wallpaper>
</wallpapers>
EOF
cat << EOF > /usr/share/gnome-background-properties/planet-explosion.light.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
<wallpaper deleted="false">
    <name>Planet Explosion Light</name>
    <filename>/usr/share/backgrounds/Planet-explosion-dark.png</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
</wallpaper>
</wallpapers>
EOF
judge "Clean and reinstall wallpaper"