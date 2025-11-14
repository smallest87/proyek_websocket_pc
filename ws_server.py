# Nama File: ws_server.py
# Server WebSocket Python untuk komunikasi real-time antara Control Room dan Output Client.
# IP: 0.0.0.0, Port: 8080 (Mendengarkan di semua antarmuka, termasuk 192.168.0.123)

import asyncio
import websockets
import logging

# Konfigurasi logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Set untuk menyimpan semua koneksi Output Client
OUTPUT_CLIENTS = set()

async def register_client(websocket):
    """Menambahkan koneksi baru ke set OUTPUT_CLIENTS."""
    OUTPUT_CLIENTS.add(websocket)
    logging.info(f"Client baru terhubung. Total Output Clients: {len(OUTPUT_CLIENTS)}")

async def unregister_client(websocket):
    """Menghapus koneksi dari set OUTPUT_CLIENTS."""
    OUTPUT_CLIENTS.remove(websocket)
    logging.info(f"Client terputus. Total Output Clients: {len(OUTPUT_CLIENTS)}")

async def broadcast_message(message):
    """Mengirim pesan ke semua Output Client yang terhubung."""
    if OUTPUT_CLIENTS:
        # Perbaikan: Mengganti coroutine dengan task eksplisit
        # untuk mematuhi aturan asyncio.wait pada versi Python modern.
        send_tasks = [asyncio.create_task(client.send(message)) for client in OUTPUT_CLIENTS]
        
        # Tunggu hingga semua pesan berhasil dikirim
        await asyncio.wait(send_tasks)
        
        logging.info(f"Pesan '{message}' dikirim ke {len(OUTPUT_CLIENTS)} Output Client.")

async def handler(websocket, path=None):
    """
    Menangani koneksi dan pesan masuk.
    Perbaikan: Menjadikan 'path' opsional untuk menyelesaikan TypeError jika library tidak menyediakannya.
    """
    await register_client(websocket)
    try:
        async for message in websocket:
            # Asumsi: Setiap pesan yang diterima dari koneksi adalah data dari Control Room
            # yang perlu disiarkan ke Output Clients.
            logging.info(f"Menerima pesan dari Control: {message}")
            await broadcast_message(message)
    except websockets.exceptions.ConnectionClosed:
        logging.warning("Koneksi ditutup.")
    finally:
        await unregister_client(websocket)

async def main():
    """Fungsi utama untuk menjalankan server WebSocket."""
    host = '0.0.0.0'
    port = 8080
    logging.info(f"Memulai server WebSocket di ws://{host}:{port}")

    # Start the server
    async with websockets.serve(handler, host, port):
        # Jalankan server tanpa batas waktu
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Server dihentikan oleh pengguna.")
    except Exception as e:
        logging.error(f"Terjadi kesalahan: {e}")