import bluetooth

# Set up the server to listen on RFCOMM channel 1
server_socket = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
server_socket.bind(("", bluetooth.PORT_ANY))
server_socket.listen(1)

print("Waiting for connection on RFCOMM channel 1...")

# Accept the incoming connection
client_socket, client_address = server_socket.accept()
print(f"Accepted connection from {client_address}")

# Listen for messages from the client
try:
    while True:
        data = client_socket.recv(1024)  # Receive up to 1024 bytes
        if data:
            print(f"Received message: {data.decode('utf-8')}")
        else:
            break
except Exception as e:
    print(f"Error: {e}")
finally:
    client_socket.close()
    server_socket.close()

