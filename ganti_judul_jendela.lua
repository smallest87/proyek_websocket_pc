-- Menginisialisasi alias untuk library OBS
local obs = obslua

-- Variabel global untuk menyimpan nama sumber teks yang akan kita modifikasi
local text_source_name = "Nama Sumber Teks Anda di OBS" -- GANTI DENGAN NAMA ASLI SUMBER TEKS!

-- Fungsi yang dipanggil saat skrip dimuat
function script_load(settings)
    obs.log(obs.LOG_INFO, "Skrip Pengubah Teks Dinamis dimuat.")
    
    -- Memulai pemanggilan fungsi update_text setiap 5000 milidetik (5 detik)
    obs.timer_add(update_text, 5000)
end

-- Fungsi yang dipanggil oleh timer setiap 5 detik
function update_text()
    -- [1] Mencari Sumber Teks berdasarkan nama
    local source = obs.obs_get_source_by_name(text_source_name)
    
    if source then
        -- [2] Mengambil pengaturan saat ini dari sumber
        local settings = obs.obs_source_get_settings(source)
        
        -- [3] Membuat teks baru
        local new_text = "Status: Aktif (" .. os.date("%H:%M:%S") .. ")"
        
        -- [4] Mengubah nilai properti 'text'
        obs.obs_data_set_string(settings, "text", new_text)
        
        -- [5] Menerapkan pengaturan baru ke sumber
        obs.obs_source_update(source, settings)
        
        -- [6] Melepaskan sumber daya yang kita ambil (PENTING!)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
        
        obs.log(obs.LOG_INFO, "Teks berhasil diperbarui menjadi: " .. new_text)
    else
        obs.log(obs.LOG_WARNING, "PERINGATAN: Sumber teks '" .. text_source_name .. "' tidak ditemukan.")
    end
end

-- Fungsi yang dipanggil saat skrip dibongkar
function script_unload()
    -- Menghentikan timer agar tidak memanggil fungsi lagi setelah skrip dimuat
    obs.timer_remove(update_text) 
    obs.log(obs.LOG_INFO, "Skrip Pengubah Teks Dinamis telah dibongkar. Timer dihentikan.")
end

-- Fungsi untuk deskripsi skrip
function script_description()
    return "Contoh: Mengubah teks pada sumber teks setiap 5 detik menggunakan Timer."
end