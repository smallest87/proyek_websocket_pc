package main

import (
	"log"
	"net/http"
	"github.com/gorilla/websocket"
)

// Menentukan Upgrader untuk mengubah koneksi HTTP menjadi WebSocket
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Izinkan koneksi dari semua Origin (hati-hati di lingkungan produksi)
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

// Fungsi utama untuk menangani koneksi WebSocket
func handleConnections(w http.ResponseWriter, r *http.Request) {
	// Upgrade koneksi HTTP ke WebSocket
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Gagal upgrade koneksi:", err)
		return
	}
	defer ws.Close() // Pastikan koneksi ditutup saat fungsi selesai

	log.Println("Klien baru terhubung.")

	for {
		// Baca pesan dari klien
		messageType, p, err := ws.ReadMessage()
		if err != nil {
			log.Println("Klien terputus:", err)
			break
		}
		
		log.Printf("Menerima pesan: %s\n", p)

		// Kirim kembali pesan (Echo)
		if err := ws.WriteMessage(messageType, p); err != nil {
			log.Println("Gagal mengirim pesan:", err)
			break
		}
	}
}

func main() {
	log.Println("Server Go WebSocket Standalone dimulai di http://localhost:8080")

	// Daftarkan handler WebSocket pada endpoint /ws
	http.HandleFunc("/ws", handleConnections)

	// Mulai server di port 8080
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("ListenAndServe Gagal: ", err)
	}
}