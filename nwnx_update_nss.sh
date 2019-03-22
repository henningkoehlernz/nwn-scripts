SOURCE=~/dev/nwnxee
TARGET=~/dev/salvationsource
# copy existing scripts
for plugin in ${SOURCE}/Plugins/*/NWScript/*.nss
do
    if [ -f ${TARGET}/$(basename ${plugin}) ]; then
        echo "copying ${plugin} to ${TARGET}"
        cp ${plugin} $TARGET/
    fi
done
