from ultralytics import YOLO
import cv2

# Cargar el modelo entrenado (ajusta la ruta si es necesario)
from pathlib import Path

ruta_modelo = Path("C:/Users/alber/Desktop/tyreProject/runs/detect/train/weights/best.pt")
modelo = YOLO(str(ruta_modelo))
 # Verifica la ruta correcta
# Inicializar la cámara
cap = cv2.VideoCapture(0)  # Cambia a 1 si usas otra cámara externa

# Verificar si la cámara está funcionando
if not cap.isOpened():
    print("❌ Error: No se pudo abrir la cámara.")
    exit()

while True:
    ret, frame = cap.read()
    if not ret:
        print("❌ Error: No se pudo capturar el cuadro de la cámara.")
        break

    # Redimensionar la imagen para mejorar rendimiento
    frame = cv2.resize(frame, (640, 480))

    # Realizar detección con un umbral de confianza más bajo
    resultados = modelo(frame, conf=0.3)  # Ajusta conf para mejorar detección

    # Dibujar las detecciones sobre la imagen
    frame_resultado = resultados[0].plot()

    # Mostrar imagen con detecciones
    cv2.imshow("CLASSIFY X ARM (YOLOv8 - CV2)", frame_resultado)

    # Presiona 'q' para salir
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Liberar la cámara y cerrar ventanas
cap.release()
cv2.destroyAllWindows()
