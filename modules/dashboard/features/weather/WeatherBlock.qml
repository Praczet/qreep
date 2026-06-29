import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: rootWeatherBlock

    required property QtObject theme
    property var config: ({})

    implicitHeight: weatherLayout.implicitHeight

    WeatherService {
        id: weatherService

        config: rootWeatherBlock.config
    }

    function numberValue(value, fallback) {
        return Number.isFinite(Number(value)) ? Number(value) : fallback;
    }

    function defaultForecast() {
        return [
            { day: "Sat, Jun 27", low: 20, high: 38, icon: "weather-overcast-symbolic" },
            { day: "Sun, Jun 28", low: 24, high: 33, icon: "weather-clouds-symbolic" },
            { day: "Mon, Jun 29", low: 19, high: 25, icon: "weather-few-clouds-symbolic" },
            { day: "Tue, Jun 30", low: 16, high: 26, icon: "weather-showers-symbolic" },
            { day: "Wed, Jul 01", low: 15, high: 25, icon: "weather-clear-symbolic" },
            { day: "Thu, Jul 02", low: 16, high: 26, icon: "weather-clear-symbolic" },
            { day: "Fri, Jul 03", low: 17, high: 24, icon: "weather-showers-symbolic" }
        ];
    }

    readonly property var displayForecast: weatherService.forecast.length > 0 ? weatherService.forecast : defaultForecast()
    readonly property real currentTemperature: weatherService.currentTemperature
    readonly property real maxTemperatureDelta: forecastMaxDelta(displayForecast)

    function forecastMaxDelta(items) {
        let value = 1;

        for (let index = 0; index < items.length; index++) {
            value = Math.max(value, Math.abs(numberValue(items[index].low, currentTemperature) - currentTemperature));
            value = Math.max(value, Math.abs(numberValue(items[index].high, currentTemperature) - currentTemperature));
        }

        return value;
    }

    function temperatureX(value, width) {
        const center = width / 2;
        const delta = numberValue(value, currentTemperature) - currentTemperature;
        const normalized = Math.max(-1, Math.min(1, delta / maxTemperatureDelta));

        return Math.max(0, Math.min(width, center + normalized * center));
    }

    Column {
        id: weatherLayout

        width: parent.width
        spacing: 14

        Column {
            width: parent.width
            spacing: 6

            Text {
                width: parent.width
                text: weatherService.location
                color: rootWeatherBlock.theme.secondaryText
                font.pixelSize: rootWeatherBlock.theme.modules.dashboard.metaPixelSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Image {
                    width: 38
                    height: 38
                    anchors.verticalCenter: parent.verticalCenter
                    source: Quickshell.iconPath(weatherService.icon, "weather-overcast-symbolic")
                    sourceSize.width: width
                    sourceSize.height: height
                    opacity: 0.9
                }

                Text {
                    text: weatherService.temperature
                    color: rootWeatherBlock.theme.borg.errorColor
                    font.pixelSize: 34
                    font.weight: Font.DemiBold
                }
            }

            Text {
                width: parent.width
                text: weatherService.loading && weatherService.forecast.length === 0 ? "Updating..." : weatherService.condition
                color: rootWeatherBlock.theme.calendarDayText
                font.pixelSize: rootWeatherBlock.theme.modules.dashboard.bodyPixelSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: weatherService.error.length > 0 ? weatherService.error : weatherService.wind
                color: rootWeatherBlock.theme.secondaryText
                font.pixelSize: rootWeatherBlock.theme.modules.dashboard.metaPixelSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Column {
            width: parent.width
            spacing: 5

            Repeater {
                model: rootWeatherBlock.displayForecast

                RowLayout {
                    required property var modelData

                    width: parent.width
                    height: 18
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 92
                        Layout.alignment: Qt.AlignVCenter
                        text: String(parent.modelData.day || "")
                        color: rootWeatherBlock.theme.calendarDayText
                        font.pixelSize: rootWeatherBlock.theme.modules.dashboard.metaPixelSize
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.preferredWidth: 92
                        Layout.alignment: Qt.AlignVCenter
                        text: "[" + rootWeatherBlock.numberValue(parent.modelData.low, 0) + "°C, " + rootWeatherBlock.numberValue(parent.modelData.high, 0) + "°C]"
                        color: rootWeatherBlock.theme.eventIndicator
                        font.pixelSize: rootWeatherBlock.theme.modules.dashboard.metaPixelSize
                        elide: Text.ElideRight
                    }

                    Item {
                        id: rangeChart

                        Layout.fillWidth: true
                        Layout.preferredWidth: 110
                        height: 12
                        Layout.alignment: Qt.AlignVCenter

                        readonly property real lowX: rootWeatherBlock.temperatureX(parent.modelData.low, rangeChart.width)
                        readonly property real highX: rootWeatherBlock.temperatureX(parent.modelData.high, rangeChart.width)
                        readonly property real currentX: rootWeatherBlock.temperatureX(rootWeatherBlock.currentTemperature, width)
                        readonly property real normalStartX: Math.min(lowX, currentX)
                        readonly property real normalEndX: Math.min(highX, currentX)
                        readonly property real warmStartX: Math.max(lowX, currentX)
                        readonly property real warmEndX: Math.max(highX, currentX)

                        Rectangle {
                            visible: rangeChart.normalEndX > rangeChart.normalStartX
                            x: rangeChart.normalStartX
                            anchors.verticalCenter: parent.verticalCenter
                            width: rangeChart.normalEndX - rangeChart.normalStartX
                            height: 3
                            radius: height / 2
                            color: rootWeatherBlock.theme.eventIndicator
                            opacity: 0.9
                        }

                        Rectangle {
                            visible: rangeChart.warmEndX > rangeChart.warmStartX
                            x: rangeChart.warmStartX
                            anchors.verticalCenter: parent.verticalCenter
                            width: rangeChart.warmEndX - rangeChart.warmStartX
                            height: 3
                            radius: height / 2
                            color: rootWeatherBlock.theme.borg.errorColor
                            opacity: 0.85
                        }

                        Rectangle {
                            x: Math.max(0, Math.min(rangeChart.width - width, rangeChart.currentX - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: 10
                            radius: 1
                            color: rootWeatherBlock.theme.secondaryText
                            opacity: 0.9
                        }
                    }

                    Image {
                        width: 16
                        height: 16
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        source: Quickshell.iconPath(String(parent.modelData.icon || "weather-overcast-symbolic"), "weather-overcast-symbolic")
                        sourceSize.width: width
                        sourceSize.height: height
                        opacity: 0.85
                    }
                }
            }
        }
    }
}
