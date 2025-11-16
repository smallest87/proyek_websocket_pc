--[[
**
** dynamic_timer_config.lua -- Skrip Timer Dinamis dengan Konfigurasi UI
** Final Fix: Menggunakan obs.script_log() untuk logging yang terjamin konsisten.
**
--]]

-- global OBS API
local obs = obslua

-- global context information
local ctx = {
    propsSet = nil,  -- property settings (model)
    propsVal = {},   -- property values
}

-- Helper function: set status message (menggunakan obs.script_log yang aman)
local function log_status(type, message)
    if type == "error" then
        obs.script_log(obs.LOG_ERROR, message)
    elseif type == "warning" then
        obs.script_log(obs.LOG_WARNING, message)
    else
        obs.script_log(obs.LOG_INFO, message)
    end
end

-- =================================================================
-- A. FUNGSI UTAMA OBS API
-- =================================================================

-- Fungsi yang dipanggil oleh timer untuk memperbarui teks
local function update_text()
    -- Ambil pengaturan dari konteks global
    local source_name = ctx.propsVal.source_name
    
    if source_name and source_name ~= "" then
        local source = obs.obs_get_source_by_name(source_name)
        
        if source then
            local settings = obs.obs_source_get_settings(source)
            
            -- Buat teks baru (menampilkan jam/waktu saat ini)
            local current_time = os.date("%H:%M:%S")
            local new_text = "OBS Active Time: " .. current_time
            
            -- Terapkan teks baru
            obs.obs_data_set_string(settings, "text", new_text)
            obs.obs_source_update(source, settings)
            
            -- PENTING: Melepaskan sumber daya
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
            
            log_status("info", "Teks diperbarui: " .. new_text)
            
        else
            log_status("warning", "Sumber teks '" .. source_name .. "' tidak ditemukan. Periksa nama di Pengaturan Skrip.")
        end
    else
        log_status("warning", "Nama Sumber Teks belum diatur di Pengaturan Skrip.")
    end
end

-- =================================================================
-- B. FUNGSI LIFECYCLE (HOOKS)
-- =================================================================

-- 1. script hook: deskripsi ditampilkan pada jendela skrip
function script_description()
    return [[
        <h2>Timer Dinamis Terstruktur</h2>

        <p>Skrip dasar: Memperbarui sumber teks secara berkala
        menggunakan UI konfigurasi dengan standar kode canggih.</p>
    ]]
end

-- 2. script hook: mendefinisikan properti UI
function script_properties()
    -- [1] Membuat objek properti utama
    local props = obs.obs_properties_create()
    
    -- [2] Menambahkan kotak teks untuk Nama Sumber
    obs.obs_properties_add_text(props, "source_name", "Nama Sumber Teks (Text Source)", obs.OBS_TEXT_DEFAULT)
    
    -- [3] Menambahkan kotak angka untuk Interval
    obs.obs_properties_add_int(props, "interval", "Interval Pembaruan (detik)", 1, 3600, 1)
    
    -- Menerapkan nilai ke definisi (pola dari skrip kloning)
    if ctx.propsSet then
        obs.obs_properties_apply_settings(props, ctx.propsSet)
    end
    
    return props
end

-- 3. script hook: mendefinisikan nilai default properti
function script_defaults(settings)
    -- Menyediakan nilai default
    obs.obs_data_set_default_string(settings, "source_name", "Countdown_Text")
    obs.obs_data_set_default_int(settings, "interval", 5)
end

-- 4. script hook: nilai properti telah diperbarui
function script_update(settings)
    -- Mengingat pengaturan untuk digunakan di script_properties
    ctx.propsSet = settings

    -- Mengambil nilai properti dan menyimpannya ke konteks global
    ctx.propsVal.source_name = obs.obs_data_get_string(settings, "source_name")
    ctx.propsVal.interval    = obs.obs_data_get_int(settings, "interval")
    
    -- Menghentikan timer lama dan memulai yang baru dengan interval yang baru
    obs.timer_remove(update_text)
    
    local interval_ms = ctx.propsVal.interval * 1000
    if interval_ms > 0 then
        obs.timer_add(update_text, interval_ms)
        log_status("info", "Timer diatur ulang. Interval: " .. interval_ms .. "ms.")
    else
        log_status("warning", "Interval pembaruan tidak valid. Timer tidak diaktifkan.")
    end
end

-- 5. script hook: bereaksi pada saat skrip dimuat
function script_load(settings)
    log_status("info", "Skrip Dimuat. Menunggu konfigurasi...")
end

-- 6. script hook: bereaksi pada saat skrip dibongkar
function script_unload()
    obs.timer_remove(update_text)
    log_status("info", "Skrip dibongkar. Timer dihentikan.")
end