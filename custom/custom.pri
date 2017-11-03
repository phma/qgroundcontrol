message("Adding Yuneec Typhoon H520 plugin")

#-- Version control
#   Major and minor versions are defined here (manually)

#-- IMPORTANT: When changing these, make sure to update s3_deploy.sh and update_manifest.sh

DATA_PILOT_VER_MAJOR = 1
DATA_PILOT_VER_MINOR = 2
DATA_PILOT_VER_FIRST_BUILD = 3564

#   Build number is automatic

DATA_PILOT_VER_BUILD = $$system(git --git-dir ../.git rev-list master --first-parent --count)
win32 {
    DATA_PILOT_VER_BUILD = $$system("set /a $$DATA_PILOT_VER_BUILD - $$DATA_PILOT_VER_FIRST_BUILD")
} else {
    DATA_PILOT_VER_BUILD = $$system("echo $(($$DATA_PILOT_VER_BUILD - $$DATA_PILOT_VER_FIRST_BUILD))")
}
DATA_PILOT_VERSION = $${DATA_PILOT_VER_MAJOR}.$${DATA_PILOT_VER_MINOR}.$${DATA_PILOT_VER_BUILD}

DEFINES -= GIT_VERSION=\"\\\"$$GIT_VERSION\\\"\"
DEFINES += GIT_VERSION=\"\\\"$$DATA_PILOT_VERSION\\\"\"

message(DataPilot Version: $${DATA_PILOT_VERSION})

#-- Platform definitions
linux : android-g++ {
    DEFINES += NO_SERIAL_LINK
    CONFIG  += DISABLE_BUILTIN_ANDROID
    CONFIG  += MobileBuild
    CONFIG  += NoSerialBuild
    equals(ANDROID_TARGET_ARCH, x86)  {
        message("Using ST16 specific Android interface")
        PlayStoreBuild|DeveloperBuild {
            CONFIG -= debug
            CONFIG -= debug_and_release
            CONFIG += release
            message(Build Android Package)
        }
    } else {
        message("Unsuported Android toolchain, limited functionality for development only")
    }
} else {
    SimulatedMobile {
        message("Simulated mobile build")
        DEFINES += __mobile__
        DEFINES += NO_SERIAL_LINK
        CONFIG  += MobileBuild
        CONFIG  += NoSerialBuild
    } else {
        message("Desktop build")
    }
}

DesktopPlanner {
    message("Desktop Planner Build")
    DEFINES += __mobile__
    DEFINES += __planner__
    DEFINES += NO_SERIAL_LINK
    CONFIG  += DISABLE_VIDEOSTREAMING
    CONFIG  += MobileBuild
    CONFIG  += NoSerialBuild
}

DEFINES += CUSTOMHEADER=\"\\\"TyphoonHPlugin.h\\\"\"
DEFINES += CUSTOMCLASS=TyphoonHPlugin

CONFIG  += QGC_DISABLE_APM_PLUGIN QGC_DISABLE_APM_PLUGIN_FACTORY QGC_DISABLE_PX4_PLUGIN_FACTORY

DesktopInstall {
    CONFIG  += QGC_DISABLE_BUILD_SETUP
}

DEFINES += NO_UDP_VIDEO
DEFINES += QGC_DISABLE_BLUETOOTH
DEFINES += QGC_DISABLE_UVC
DEFINES += DISABLE_ZEROCONF

DesktopPlanner {
    TARGET   = DataPilotPlanner
    DEFINES += QGC_APPLICATION_NAME=\"\\\"DataPilotPlanner\\\"\"
} else {
    TARGET   = DataPilot
    DEFINES += QGC_APPLICATION_NAME=\"\\\"DataPilot\\\"\"
}

DEFINES += QGC_ORG_NAME=\"\\\"Yuneec.com\\\"\"
DEFINES += QGC_ORG_DOMAIN=\"\\\"com.yuneec\\\"\"

RESOURCES += \
    $$QGCROOT/custom/typhoonh_common.qrc

DesktopPlanner {
    RESOURCES += \
        $$QGCROOT/custom/typhoonh_planner.qrc
} else {
    RESOURCES += \
        $$QGCROOT/custom/typhoonh.qrc
}

MacBuild {
    QMAKE_INFO_PLIST    = $$PWD/macOS/YuneecInfo.plist
    ICON                = $$PWD/macOS/icon.icns
    OTHER_FILES        -= $$QGCROOT/Custom-Info.plist
    OTHER_FILES        += $$PWD/macOS/Info.plist
}

WindowsBuild {
    RC_ICONS            = $$PWD/Windows/icon.ico
    VERSION             = $${DATA_PILOT_VERSION}.0
    ReleaseBuild {
        QMAKE_CFLAGS_RELEASE   += /Gy /Ox
        QMAKE_CXXFLAGS_RELEASE += /Gy /Ox
        # Eliminate duplicate COMDATs
        QMAKE_LFLAGS_RELEASE   += /OPT:ICF /LTCG
    }
}

SOURCES += \
    $$PWD/src/TyphoonHPlugin.cc \

!DesktopPlanner {
    SOURCES += \
        $$PWD/src/m4serial.cc \
        $$PWD/src/m4util.cc \
        $$PWD/src/TyphoonHM4Interface.cc \
        $$PWD/src/TyphoonHQuickInterface.cc \
        $$PWD/src/UTMConverter.cc \
        $$PWD/src/YExportFiles.cc \
}

AndroidBuild {
    SOURCES += \
        $$PWD/src/TyphoonHJNI.cc \
}

HEADERS += \
    $$PWD/src/TyphoonHPlugin.h \

!DesktopPlanner {
    HEADERS += \
        $$PWD/src/m4channeldata.h \
        $$PWD/src/m4def.h \
        $$PWD/src/m4serial.h \
        $$PWD/src/m4util.h \
        $$PWD/src/TyphoonHCommon.h \
        $$PWD/src/TyphoonHM4Interface.h \
        $$PWD/src/TyphoonHQuickInterface.h \
        $$PWD/src/UTMConverter.h \
        $$PWD/src/YExportFiles.h \
}

INCLUDEPATH += \
    $$PWD/src \

equals(QT_MAJOR_VERSION, 5) {
    greaterThan(QT_MINOR_VERSION, 5) {
        ReleaseBuild {
            AndroidBuild {
                QT      += qml-private
                CONFIG  += qtquickcompiler
                message("Using Qt Quick Compiler")
            } else {
                CONFIG  -= qtquickcompiler
            }
        }
    }
}

QT += \
    multimedia

#-------------------------------------------------------------------------------------
# Firmware/AutoPilot Plugin

INCLUDEPATH += \
    $$PWD/src/FirmwarePlugin \
    $$PWD/src/AutoPilotPlugin

HEADERS+= \
    $$PWD/src/AutoPilotPlugin/YuneecAutoPilotPlugin.h \
    $$PWD/src/AutoPilotPlugin/GimbalComponent.h \
    $$PWD/src/AutoPilotPlugin/ChannelComponent.h \
    $$PWD/src/AutoPilotPlugin/HealthComponent.h \
    $$PWD/src/AutoPilotPlugin/YuneecSafetyComponent.h \
    $$PWD/src/FirmwarePlugin/YuneecFirmwarePlugin.h \
    $$PWD/src/FirmwarePlugin/YuneecFirmwarePluginFactory.h \

!DesktopPlanner {
    HEADERS+= \
        $$PWD/src/FirmwarePlugin/YuneecCameraControl.h \
        $$PWD/src/FirmwarePlugin/YuneecCameraManager.h \
}

SOURCES += \
    $$PWD/src/AutoPilotPlugin/YuneecAutoPilotPlugin.cc \
    $$PWD/src/AutoPilotPlugin/GimbalComponent.cc \
    $$PWD/src/AutoPilotPlugin/ChannelComponent.cc \
    $$PWD/src/AutoPilotPlugin/HealthComponent.cc \
    $$PWD/src/AutoPilotPlugin/YuneecSafetyComponent.cc \
    $$PWD/src/FirmwarePlugin/YuneecFirmwarePlugin.cc \
    $$PWD/src/FirmwarePlugin/YuneecFirmwarePluginFactory.cc \

!DesktopPlanner {
    SOURCES += \
        $$PWD/src/FirmwarePlugin/YuneecCameraControl.cc \
        $$PWD/src/FirmwarePlugin/YuneecCameraManager.cc \
}

#-------------------------------------------------------------------------------------
# Android

AndroidBuild {
    ANDROID_EXTRA_LIBS += $${PLUGIN_SOURCE}
    include($$PWD/AndroidTyphoonH.pri)
    DeveloperBuild {
        message("Preparing Developer Build")
        QMAKE_POST_LINK = echo Start post link for Developer Build
        QMAKE_POST_LINK += && mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && make install INSTALL_ROOT=$${DESTDIR}/android-build/
        QMAKE_POST_LINK += && $$dirname(QMAKE_QMAKE)/androiddeployqt --input android-libDataPilot.so-deployment-settings.json --output $${DESTDIR}/android-build --deployment bundled --gradle
        QMAKE_POST_LINK += && cp $${DESTDIR}/android-build/build/outputs/apk/android-build-debug.apk $${DESTDIR}/package/DataPilotDevel-$${DATA_PILOT_VERSION}.apk
        QMAKE_POST_LINK += && echo && echo "Package in $${DESTDIR}/package/DataPilotDevel-$${DATA_PILOT_VERSION}.apk" &&
    }
    PlayStoreBuild {
        message("Preparing Play Store Build")
        QKEYSTORE_FILE = $$(KEYSTORE_FILE)
        QKEYSTORE_USER = $$(KEYSTORE_USER)
        QKEYSTORE_PWD  = $$(KEYSTORE_PWD)
        QKEY_PWD  = $$(KEY_PWD)
        isEmpty(QKEYSTORE_FILE) {
            error(Please, define the location of the keystore file. export KEYSTORE_FILE=/path/to/your.keystore)
        }
        isEmpty(QKEYSTORE_USER) {
            error(Please, define the user name of yout keystore file. export KEYSTORE_USER=johndoe)
        }
        isEmpty(QKEYSTORE_PWD) {
            error(Please, define the password of your keystore file. export KEYSTORE_PWD=storepass)
        }
        isEmpty(QKEY_PWD) {
            error(Please, define the password of your keystore file. export KEY_PWD=keypass)
        }
        QMAKE_POST_LINK = echo Start post link for App Store Build
        QMAKE_POST_LINK += && mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && make install INSTALL_ROOT=$${DESTDIR}/android-build/
        QMAKE_POST_LINK += && $$dirname(QMAKE_QMAKE)/androiddeployqt --input android-libDataPilot.so-deployment-settings.json --output $${DESTDIR}/android-build --deployment bundled --gradle --sign $$(KEYSTORE_FILE) $$(KEYSTORE_USER) --storepass $$(KEYSTORE_PWD) --keypass $$(KEY_PWD)
        QMAKE_POST_LINK += && cp $${DESTDIR}/android-build/build/outputs/apk/android-build-release-signed.apk $${DESTDIR}/package/DataPilot-$${DATA_PILOT_VERSION}.apk
        QMAKE_POST_LINK += && echo && echo "Package in $${DESTDIR}/package/DataPilot-$${DATA_PILOT_VERSION}.apk" &&
    }
}

#-------------------------------------------------------------------------------------
# Desktop Distribution

DesktopInstall {

    DEFINES += QGC_INSTALL_RELEASE
    QMAKE_POST_LINK = echo Start post link

    MacBuild {
        VideoEnabled {
            message("Preparing GStreamer Framework")
            QMAKE_POST_LINK += && $$QGCROOT/tools/prepare_gstreamer_framework.sh $${OUT_PWD}/gstwork/ $${DESTDIR}/$${TARGET}.app $${TARGET}
        }
        # Copy non-standard frameworks into app package
        QMAKE_POST_LINK += && rsync -a $$BASEDIR/libs/lib/Frameworks $$DESTDIR/$${TARGET}.app/Contents/
        # SDL2 Framework
        QMAKE_POST_LINK += && install_name_tool -change "@rpath/SDL2.framework/Versions/A/SDL2" "@executable_path/../Frameworks/SDL2.framework/Versions/A/SDL2" $$DESTDIR/$${TARGET}.app/Contents/MacOS/$${TARGET}
        # We cd to release directory so we can run macdeployqt without a path to the
        # qgroundcontrol.app file. If you specify a path to the .app file the symbolic
        # links to plugins will not be created correctly.
        QMAKE_POST_LINK += && mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && cd $${DESTDIR} && $$dirname(QMAKE_QMAKE)/macdeployqt $${TARGET}.app -appstore-compliant -verbose=2 -qmldir=$${BASEDIR}/src
        QMAKE_POST_LINK += && cd $${OUT_PWD}
        QMAKE_POST_LINK += && hdiutil create -verbose -stretch 4g -layout SPUD -srcfolder $${DESTDIR}/$${TARGET}.app -volname $${TARGET} $${DESTDIR}/package/$${TARGET}.dmg
    }

    WindowsBuild {
        BASEDIR_WIN = $$replace(BASEDIR, "/", "\\")
        DESTDIR_WIN = $$replace(DESTDIR, "/", "\\")
        QT_BIN_DIR  = $$dirname(QMAKE_QMAKE)

        # Copy dependencies
        DebugBuild: DLL_QT_DEBUGCHAR = "d"
        ReleaseBuild: DLL_QT_DEBUGCHAR = ""
        COPY_FILE_LIST = \
            $$BASEDIR\\libs\\lib\\sdl2\\msvc\\lib\\x86\\SDL2.dll \
            $$BASEDIR\\deploy\\libeay32.dll

        for(COPY_FILE, COPY_FILE_LIST) {
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"$$COPY_FILE\" \"$$DESTDIR_WIN\"
        }

        ReleaseBuild {
            # Copy Visual Studio DLLs
            # Note that this is only done for release because the debugging versions of these DLLs cannot be redistributed.
            win32-msvc2010 {
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp100.dll\"  \"$$DESTDIR_WIN\"
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr100.dll\"  \"$$DESTDIR_WIN\"

            } else:win32-msvc2012 {
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp110.dll\"  \"$$DESTDIR_WIN\"
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr110.dll\"  \"$$DESTDIR_WIN\"

            } else:win32-msvc2013 {
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp120.dll\"  \"$$DESTDIR_WIN\"
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr120.dll\"  \"$$DESTDIR_WIN\"

            } else:win32-msvc2015 {
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp140.dll\"  \"$$DESTDIR_WIN\"
                QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\vcruntime140.dll\"  \"$$DESTDIR_WIN\"

            } else {
                error("Visual studio version not supported, installation cannot be completed.")
            }
        }

        DEPLOY_TARGET = $$shell_quote($$shell_path($$DESTDIR_WIN\\$${TARGET}.exe))
        message(Deploy Target: $${DEPLOY_TARGET})
        QMAKE_POST_LINK += $$escape_expand(\\n) $$QT_BIN_DIR\\windeployqt --no-compiler-runtime --qmldir=$${BASEDIR_WIN}\\src $${DEPLOY_TARGET}
        #QMAKE_POST_LINK += $$escape_expand(\\n) cd $$BASEDIR_WIN && $$quote("\"C:\\Program Files \(x86\)\\NSIS\\makensis.exe\"" /NOCD "\"/XOutFile $${DESTDIR_WIN}\\$${TARGET}-installer.exe\"" "$$BASEDIR_WIN\\deploy\\qgroundcontrol_installer.nsi")
        #OTHER_FILES += deploy/$${TARGET}_installer.nsi
    }

    LinuxBuild {
        QMAKE_POST_LINK += && mkdir -p $$DESTDIR/Qt/libs && mkdir -p $$DESTDIR/Qt/plugins

        # QT_INSTALL_LIBS
        QT_LIB_LIST = \
            libQt5Core.so.5 \
            libQt5DBus.so.5 \
            libQt5Gui.so.5 \
            libQt5Location.so.5 \
            libQt5Multimedia.so.5 \
            libQt5MultimediaQuick_p.so.5 \
            libQt5Network.so.5 \
            libQt5OpenGL.so.5 \
            libQt5Positioning.so.5 \
            libQt5PrintSupport.so.5 \
            libQt5Qml.so.5 \
            libQt5Quick.so.5 \
            libQt5QuickWidgets.so.5 \
            libQt5SerialPort.so.5 \
            libQt5Sql.so.5 \
            libQt5Svg.so.5 \
            libQt5Test.so.5 \
            libQt5Widgets.so.5 \
            libQt5XcbQpa.so.5 \
            libicudata.so.56 \
            libicui18n.so.56 \
            libicuuc.so.56

        for(QT_LIB, QT_LIB_LIST) {
            QMAKE_POST_LINK += && $$QMAKE_COPY --dereference $$[QT_INSTALL_LIBS]/$$QT_LIB $$DESTDIR/Qt/libs/
        }

        # QT_INSTALL_PLUGINS
        QT_PLUGIN_LIST = \
            bearer \
            geoservices \
            iconengines \
            imageformats \
            platforminputcontexts \
            platforms \
            position \
            sqldrivers \
            xcbglintegrations

        for(QT_PLUGIN, QT_PLUGIN_LIST) {
            QMAKE_POST_LINK += && $$QMAKE_COPY --dereference --recursive $$[QT_INSTALL_PLUGINS]/$$QT_PLUGIN $$DESTDIR/Qt/plugins/
        }

        # QT_INSTALL_QML
        QMAKE_POST_LINK += && $$QMAKE_COPY --dereference --recursive $$[QT_INSTALL_QML] $$DESTDIR/Qt/
        # QGroundControl start script
        QMAKE_POST_LINK += && $$QMAKE_COPY $$BASEDIR/deploy/qgroundcontrol-start.sh $$DESTDIR
        QMAKE_POST_LINK += && $$QMAKE_COPY $$BASEDIR/deploy/qgroundcontrol.desktop $$DESTDIR
        QMAKE_POST_LINK += && $$QMAKE_COPY $$BASEDIR/resources/icons/qgroundcontrol.png $$DESTDIR
        #-- TODO: This uses hardcoded paths. It should use $${DESTDIR}
        QMAKE_POST_LINK += && mkdir -p release/package
        QMAKE_POST_LINK += && tar -cjf release/package/$${TARGET}.tar.bz2 release --exclude='package' --transform 's/release/$${TARGET}/'
    }
}