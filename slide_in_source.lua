--[[
**
** slide_in_source.lua -- Skrip Slide-In Source dengan Ease Out
** FINAL FIX: Menghilangkan pengecekan settings yang mengganggu alur inisialisasi hook.
**
--]]

-- global OBS API
local obs = obslua

-- global context information
local ctx = {
    propsSet     = nil,
    propsVal     = {},
    targetItem   = nil,
    isSliding    = false,
    startTime    = 0,
    duration     = 0.5, -- Nilai default aman
    startPos     = {x = 0, y = 0},
    endPos       = {x = 0, y = 0},
}

-- Helper function: logging (menggunakan obs.script_log yang aman)
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
-- A. FUNGSI EASE OUT SINUSOIDAL
-- =================================================================

-- Fungsi easing out (melambat di akhir) menggunakan kurva sinus
local function easeOutSine(t)
    return math.sin(t * math.pi / 2)
end

-- =================================================================
-- B. FUNGSI SLIDE UTAMA
-- =================================================================

-- Fungsi yang dipanggil setiap frame untuk memperbarui posisi
local function slide_update()
    if not ctx.isSliding then
        obs.timer_remove(slide_update)
        return
    end

    local currentTime = obs.os_gettime() / 1000.0
    local elapsed = currentTime - ctx.startTime
    
    local t = math.min(1.0, elapsed / ctx.duration)
    
    local eased_t = easeOutSine(t)

    local newX = ctx.startPos.x + (ctx.endPos.x - ctx.startPos.x) * eased_t
    local newY = ctx.startPos.y + (ctx.endPos.y - ctx.startPos.y) * eased_t

    local transform = obs.obs_transform_info()
    obs.obs_sceneitem_get_info(ctx.targetItem, transform)
    
    transform.pos.x = newX
    transform.pos.y = newY

    obs.obs_sceneitem_set_info(ctx.targetItem, transform)
    
    if t >= 1.0 then
        ctx.isSliding = false
        obs.timer_remove(slide_update)
        log_status("info", "Gerakan 'Slide-In' selesai.")
        
        if ctx.targetItem then
            obs.obs_sceneitem_release(ctx.targetItem)
            ctx.targetItem = nil
        end
    end
end

-- Fungsi yang memicu dimulainya gerakan
local function trigger_slide()
    -- 1. Dapatkan referensi adegan saat ini (Source)
    local currentSceneSource = obs.obs_frontend_get_current_scene() 
    if not currentSceneSource then
        log_status("error", "Tidak ada adegan yang aktif.")
        return
    end
    
    -- 2. Konversi Source menjadi Scene Base (OBS Scene)
    local sceneBase = obs.obs_scene_from_source(currentSceneSource) 

    if not sceneBase then
        log_status("error", "Gagal mendapatkan objek Scene Base dari adegan aktif.")
        obs.obs_source_release(currentSceneSource)
        return
    end
    
    -- 3. Cari Item Sumber 
    local item = obs.find_source_in_scene(sceneBase, ctx.propsVal.source_name) 

    if not item then
        log_status("error", "Item sumber '" .. ctx.propsVal.source_name .. "' tidak ditemukan di adegan saat ini.")
        obs.obs_source_release(currentSceneSource)
        return
    end

    -- 4. Lanjutkan proses slide
    
    local transform = obs.obs_transform_info()
    obs.obs_sceneitem_get_info(item, transform)
    
    -- Simpan posisi Awal dan Akhir
    ctx.startPos.x = ctx.propsVal.start_x
    ctx.startPos.y = transform.pos.y
    ctx.endPos.x   = transform.pos.x
    ctx.endPos.y   = transform.pos.y
    
    -- Atur kembali item ke posisi awal (di luar frame) sebelum memulai slide
    transform.pos.x = ctx.startPos.x
    obs.obs_sceneitem_set_info(item, transform)
    
    -- 5. Inisialisasi status gerakan
    ctx.targetItem = item
    ctx.isSliding = true
    ctx.startTime = obs.os_gettime() / 1000.0
    -- ctx.duration sudah diisi di script_update
    
    -- 6. Mulai timer pembaruan
    obs.timer_add(slide_update, 1) 
    
    log_status("info", string.format("Memulai Slide-In untuk '%s' dari X=%.0f ke X=%.0f.", 
        ctx.propsVal.source_name, ctx.startPos.x, ctx.endPos.x))
    
    -- 7. Pelepasan Sumber Daya
    obs.obs_source_release(currentSceneSource)
end

-- =================================================================
-- C. FUNGSI LIFECYCLE (HOOKS)
-- =================================================================

-- 1. script hook: deskripsi
function script_description()
    return [[
        <h2>Slide-In Source (Ease Out)</h2>

        <p>Menggerakkan item sumber dari posisi awal (di luar frame)
        ke posisi akhirnya dengan efek <b>Ease Out Sinusoidal</b>.</p>
        <p>Tekan tombol <b>Picu Slide IN</b> di bawah untuk memicu gerakan.</p>
    ]]
end

-- 2. script hook: mendefinisikan properti UI
function script_properties()
    local props = obs.obs_properties_create()
    
    obs.obs_properties_add_text(props, "source_name", "Nama Item Sumber", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_float(props, "duration", "Durasi (detik)", 0.1, 5.0, 0.1)
    obs.obs_properties_add_int(props, "start_x", "Posisi X Awal (Diluar Frame)", -5000, 5000, 100)
    obs.obs_properties_add_button(props, "slide_button", "Picu Slide IN", trigger_slide)
    
    if ctx.propsSet then
        obs.obs_properties_apply_settings(props, ctx.propsSet)
    end
    
    return props
end

-- 3. script hook: mendefinisikan nilai default properti
function script_defaults(settings)
    -- *** FIX 1: Hapus semua pengecekan 'nil'. Biarkan OBS yang mengelola settings. ***
    
    -- Baris 182 (sebelumnya): seharusnya aman sekarang
    obs.obs_data_set_default_string(settings, "source_name", "Text Source")
    obs.obs_data_set_default_double(settings, "duration", 0.5)
    obs.obs_data_set_default_int(settings, "start_x", -1000)
end

-- 4. script hook: nilai properti telah diperbarui
function script_update(settings)
    -- *** FIX 2: Pengecekan payload yang aman di sini ***
    if type(settings) ~= "userdata" then 
        log_status("warning", "Settings payload is invalid/missing in script_update. Aborting read.")
        return 
    end
    
    ctx.propsSet = settings
    
    -- Mengambil nilai properti dan menyimpannya ke konteks global
    ctx.propsVal.source_name = obs.obs_data_get_string(settings, "source_name")
    
    -- Baris 200 (sebelumnya): Sekarang aman karena kita cek 'type(settings)' di atas
    -- Gunakan fallback jika nilai yang dibaca entah kenapa 'nil'
    local duration_val = obs.obs_data_get_double(settings, "duration")
    ctx.propsVal.duration = duration_val or 0.5
    
    ctx.propsVal.start_x = obs.obs_data_get_int(settings, "start_x")

    -- Pastikan ctx.duration menggunakan nilai dari propsVal
    if ctx.propsVal.duration <= 0 then
        ctx.duration = 0.5 -- Fallback final
    else
        ctx.duration = ctx.propsVal.duration
    end
end

-- 5. script hook: bereaksi pada saat skrip dimuat
function script_load(settings)
    -- Biarkan ini bersih.
    log_status("info", "Skrip Slide-In Dimuat. Menunggu konfigurasi...")
end

-- 6. script hook: bereaksi pada saat skrip dibongkar
function script_unload()
    obs.timer_remove(slide_update)
    if ctx.targetItem then
        obs.obs_sceneitem_release(ctx.targetItem)
    end
    log_status("info", "Skrip dibongkar.")
end