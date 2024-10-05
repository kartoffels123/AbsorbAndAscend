local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = "AbsorbAndAscend",
    l10n = "AbsorbAndAscend",
    name = 'name',
    description = 'description'
}

I.Settings.registerGroup {
    key = "SettingsAbsorbAndAscend",
    l10n = "AbsorbAndAscend",
    name = "settingsTitle",
    page = "AbsorbAndAscend",
    description = "settingsDesc",
    permanentStorage = false,
    settings = {
        {
            key = "aaaToggle",
            name = "aaaToggleName",
            description = "aaaToggleDesc",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "aaaProtectedItems",
            name = "aaaProtectedItemsName",
            description = "aaaProtectedItemsDesc",
            default = "sunder, keening, wraithguard",
            renderer = "textLine"
        },
        {
            key = "aaaCustomKeyToggle",
            name = "aaaCustomKeyToggleName",
            description = "aaaCustomKeyToggleDesc",
            default = false,
            renderer = "checkbox"
        },
        {
            key = "aaaCustomKey1",
            name = "aaaCustomKey1Name",
            description = "aaaCustomKey1Desc",
            default = "Shift",
            renderer = "textLine"
        },
        {
            key = "aaaCustomKey2",
            name = "aaaCustomKey2Name",
            description = "aaaCustomKey2Desc",
            default = "",
            renderer = "textLine"
        },
    }
}